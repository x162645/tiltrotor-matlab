function results = run_xv15_annular_momentum_diagnostic(outputDir)
%RUN_XV15_ANNULAR_MOMENTUM_DIAGNOSTIC
% Compare the present full-disk induced-velocity closure with a diagnostic
% annular-momentum closure in pure hover.
%
% This is an error-attribution diagnostic, not a production-model change.
% The scalar NASA C81 low-order section parameters, PR67 geometry mapping,
% first-harmonic flapping equations and Eq. (12) azimuthal inflow shape are
% retained. The only changed mechanism is the momentum closure:
%
%   GLOBAL: one viMean for the full rotor disk;
%   ANNULAR: one vi_j per radial annulus, with
%       dT_j = 2*rho*dA_j*vi_j^2.
%
% OARF Run 15 CT/CP/FM are external comparison data only. They do not enter
% the annular closure or any fitted parameter.

rootDir = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1 || isempty(outputDir)
    outputDir = fullfile(rootDir,'results','xv15_section_aero_validation');
end
if ~exist(outputDir,'dir')
    mkdir(outputDir);
end

Pbase = params_nominal();
scalarC81 = build_xv15_c81_low_order_section_aero();
d2r = pi/180;
R = 3.81;
rootCut = 0.0875;

collective75_deg = [6;7;8;9;10;11];
Vtip_fps = [768.4;768.4;768.4;768.0;768.0;767.7];
CT_exp = [0.009208;0.010104;0.011063;0.012035;0.013089;0.013929];
CP_exp = [0.000796;0.000913;0.001044;0.001188;0.001358;0.001523];
FM_exp = [0.7849;0.7866;0.7881;0.7858;0.7797;0.7632];

% Same PR67 geometry reduction used by the preceding validation diagnostics.
xGeom = linspace(rootCut,1,4001).';
chord_in = 14*ones(size(xGeom));
inboard = xGeom <= 0.25;
chord_in(inboard) = -18.4615*xGeom(inboard)+18.6154;
chord_m = chord_in*0.0254;
chordEq_m = trapz(xGeom,chord_m)/(1-rootCut);

thetaSource_deg = nasa_metal_twist_deg(xGeom);
theta75Source_deg = nasa_metal_twist_deg(0.75);
xNorm = (xGeom-rootCut)/(1-rootCut);
x75 = (0.75-rootCut)/(1-rootCut);
shapeCoordinate = xNorm-x75;
shapeTarget = thetaSource_deg-theta75Source_deg;
twistTipEq_deg = trapz(xGeom,shapeCoordinate.*shapeTarget) / ...
    trapz(xGeom,shapeCoordinate.^2);

Ptemplate = Pbase;
Ptemplate.rotor.R = R;
Ptemplate.rotor.Nb = 3;
Ptemplate.rotor.rootCut = rootCut;
Ptemplate.rotor.chord = chordEq_m;
Ptemplate.rotor.twistTip = twistTipEq_deg*d2r;
Ptemplate.rotor.Ib = Ptemplate.rotor.bladeMass*R^2/3;
Ptemplate.rotor.Sblade = Ptemplate.rotor.bladeMass*R/2;

rows = table();
for k = 1:numel(collective75_deg)
    P = Ptemplate;
    Vtip_mps = Vtip_fps(k)*0.3048;
    P.rotor.Omega = Vtip_mps/R;
    modelCollective_deg = collective75_deg(k)-twistTipEq_deg*x75;
    collectiveRad = modelCollective_deg*d2r;

    globalOut = xv15_hover_bemt_section_diagnostic( ...
        P,collectiveRad,'SCALAR_C81_LOW_ORDER',scalarC81);
    annularOut = solve_annular(P,collectiveRad,scalarC81,globalOut.inducedVelocity);

    diskArea = pi*R^2;
    CT_global = globalOut.thrust/(P.env.rho*diskArea*Vtip_mps^2);
    CP_global = globalOut.torque*P.rotor.Omega/(P.env.rho*diskArea*Vtip_mps^3);
    FM_global = figure_of_merit(CT_global,CP_global);

    CT_annular = annularOut.thrust/(P.env.rho*diskArea*Vtip_mps^2);
    CP_annular = annularOut.torque*P.rotor.Omega/(P.env.rho*diskArea*Vtip_mps^3);
    FM_annular = figure_of_merit(CT_annular,CP_annular);

    local = table(collective75_deg(k),Vtip_fps(k), ...
        CT_exp(k),CT_global,CT_annular,CP_exp(k),CP_global,CP_annular, ...
        FM_exp(k),FM_global,FM_annular,annularOut.annularSupported, ...
        annularOut.maxLocalClosureResidualRelative, ...
        min(annularOut.ringThrust_N),min(annularOut.vi_mps),max(annularOut.vi_mps), ...
        'VariableNames',{'collective75_deg','Vtip_fps','CT_exp','CT_global', ...
        'CT_annular','CP_exp','CP_global','CP_annular','FM_exp','FM_global', ...
        'FM_annular','annularSupported','maxLocalClosureResidualRelative', ...
        'minRingThrust_N','minVi_mps','maxVi_mps'});
    rows = [rows;local]; %#ok<AGROW>
end

writetable(rows,fullfile(outputDir,'XV15_ANNULAR_MOMENTUM_MATLAB_DIAGNOSTIC.csv'));

common = rows.annularSupported;
metrics = table();
metrics.commonSupportedPointCount = nnz(common);
metrics.CT_MAPE_global_pct = mape(rows.CT_global,rows.CT_exp,common);
metrics.CT_MAPE_annular_pct = mape(rows.CT_annular,rows.CT_exp,common);
metrics.CP_MAPE_global_pct = mape(rows.CP_global,rows.CP_exp,common);
metrics.CP_MAPE_annular_pct = mape(rows.CP_annular,rows.CP_exp,common);
metrics.FM_MAPE_global_pct = mape(rows.FM_global,rows.FM_exp,common);
metrics.FM_MAPE_annular_pct = mape(rows.FM_annular,rows.FM_exp,common);
writetable(metrics,fullfile(outputDir,'XV15_ANNULAR_MOMENTUM_MATLAB_METRICS.csv'));

% 10 deg radial-grid sensitivity. This is numerical evidence only; it does
% not change the production nRadial default.
gridN = [12;24;48;96];
gridRows = table();
for j = 1:numel(gridN)
    P = Ptemplate;
    P.rotor.nRadial = gridN(j);
    Vtip_mps = 768.0*0.3048;
    P.rotor.Omega = Vtip_mps/R;
    modelCollective_deg = 10-twistTipEq_deg*x75;
    globalOut = xv15_hover_bemt_section_diagnostic( ...
        P,modelCollective_deg*d2r,'SCALAR_C81_LOW_ORDER',scalarC81);
    annularOut = solve_annular(P,modelCollective_deg*d2r,scalarC81,globalOut.inducedVelocity);
    diskArea = pi*R^2;
    CTg = globalOut.thrust/(P.env.rho*diskArea*Vtip_mps^2);
    CPg = globalOut.torque*P.rotor.Omega/(P.env.rho*diskArea*Vtip_mps^3);
    CTa = annularOut.thrust/(P.env.rho*diskArea*Vtip_mps^2);
    CPa = annularOut.torque*P.rotor.Omega/(P.env.rho*diskArea*Vtip_mps^3);
    one = table(gridN(j),CTg,CPg,CTa,CPa,annularOut.annularSupported, ...
        annularOut.maxLocalClosureResidualRelative,min(annularOut.vi_mps), ...
        max(annularOut.vi_mps),'VariableNames',{'nRadial','CT_global','CP_global', ...
        'CT_annular','CP_annular','annularSupported', ...
        'maxLocalClosureResidualRelative','minVi_mps','maxVi_mps'});
    gridRows = [gridRows;one]; %#ok<AGROW>
end
writetable(gridRows,fullfile(outputDir,'XV15_ANNULAR_MOMENTUM_GRID_MATLAB_DIAGNOSTIC.csv'));

results = struct();
results.table = rows;
results.metrics = metrics;
results.grid = gridRows;
results.chordEq_m = chordEq_m;
results.twistTipEq_deg = twistTipEq_deg;
results.claimBoundary = ['ANNULAR_MOMENTUM_HOVER_DIAGNOSTIC_' ...
    'NO_OARF_PARAMETER_FIT_NO_PRODUCTION_MODEL_CHANGE'];
save(fullfile(outputDir,'XV15_ANNULAR_MOMENTUM_DIAGNOSTIC_RESULTS.mat'),'results');
end

function out = solve_annular(P,collectiveRad,scalarC81,viInitial)
R = P.rotor.R;
Omega = P.rotor.Omega;
rho = P.env.rho;
r0 = P.rotor.rootCut*R;
rEdges = linspace(r0,R,P.rotor.nRadial+1);
rMid = 0.5*(rEdges(1:end-1)+rEdges(2:end));
dr = diff(rEdges);
dA = pi*(rEdges(2:end).^2-rEdges(1:end-1).^2);
psi = ((0:P.rotor.nAzimuth-1)*(2*pi/P.rotor.nAzimuth)).';
twist = P.rotor.twistTip*(rMid-r0)/max(R-r0,eps);
thetaBlade = collectiveRad+twist;
UT = Omega*rMid;

vi = viInitial*ones(1,P.rotor.nRadial);
zFlap = P.rotor.flapInitial(:);
relax = P.rotor.inducedRelax;
maxIter = max(100,5*P.rotor.inducedMaxIter);
converged = false;

for iter = 1:maxIter
    [zFlap,flapInfo] = solve_flap(vi,zFlap);
    if ~flapInfo.converged
        break;
    end
    loads = blade_loads(vi,zFlap);
    viTarget = sqrt(max(loads.ringThrust_N,0)./(2*rho*dA));
    viNew = (1-relax)*vi+relax*viTarget;
    err = max(abs(viNew-vi)./max(1,abs(vi)));
    vi = viNew;
    if err < 1.0e-6
        converged = true;
        break;
    end
end

loads = blade_loads(vi,zFlap);
momentumRingThrust = 2*rho*dA.*vi.^2;
localResidual = loads.ringThrust_N-momentumRingThrust;
localScale = max(max(abs(loads.ringThrust_N),abs(momentumRingThrust)),1);
localResidualRelative = abs(localResidual)./localScale;
allRingsPositive = all(loads.ringThrust_N > 0);
closureSatisfied = max(localResidualRelative) <= 2.0e-4;
annularSupported = converged && flapInfo.converged && allRingsPositive && closureSatisfied;

out = struct();
out.thrust = loads.T;
out.torque = loads.Q;
out.vi_mps = vi;
out.ringThrust_N = loads.ringThrust_N;
out.momentumRingThrust_N = momentumRingThrust;
out.localClosureResidualRelative = localResidualRelative;
out.maxLocalClosureResidualRelative = max(localResidualRelative);
out.allRingsPositive = allRingsPositive;
out.annularSupported = annularSupported;
out.iterations = iter;
out.zFlap = zFlap;
out.flap = flapInfo;
out.claimBoundary = ['LOCAL_ANNULAR_MOMENTUM_ONLY_' ...
    'NEGATIVE_RING_THRUST_MARKED_UNSUPPORTED'];

    function [z,info] = solve_flap(viRadial,z0)
        z = z0(:);
        info = struct('converged',false,'iterations',0,'residualNorm',Inf);
        for k = 1:P.rotor.flapMaxIter
            [res,scale] = flap_residual(z,viRadial);
            rn = res/scale;
            if norm(rn) <= P.rotor.flapResidualTol
                info.converged = true;
                info.iterations = k;
                info.residualNorm = norm(rn);
                return;
            end
            J = zeros(3,3);
            for jj = 1:3
                h = P.rotor.flapJacobianStep*max(1,abs(z(jj)));
                zp = z; zm = z;
                zp(jj) = zp(jj)+h; zm(jj) = zm(jj)-h;
                [rp,~] = flap_residual(zp,viRadial);
                [rm,~] = flap_residual(zm,viRadial);
                J(:,jj) = (rp-rm)/(2*h*scale);
            end
            if ~all(isfinite(J(:))) || rcond(J.'*J) < 1e-14
                return;
            end
            reg = P.rotor.flapNewtonRegularization;
            dz = -(J.'*J+reg*eye(3))\(J.'*rn);
            step = 1.0;
            accepted = false;
            for trial = 1:P.rotor.flapLineSearchMaxIter
                zc = z+step*dz;
                betaCheck = zc(1)+zc(2)*cos(psi)+zc(3)*sin(psi);
                if all(isfinite(zc)) && max(abs(betaCheck)) < P.rotor.flapDivergenceAngle
                    [rc,sc] = flap_residual(zc,viRadial);
                    if norm(rc/sc) < norm(rn)
                        z = zc;
                        accepted = true;
                        break;
                    end
                end
                step = step*P.rotor.flapNewtonDamping;
            end
            if ~accepted
                return;
            end
        end
        [res,scale] = flap_residual(z,viRadial);
        info.iterations = P.rotor.flapMaxIter;
        info.residualNorm = norm(res/scale);
    end

    function [res,scale] = flap_residual(z,viRadial)
        ll = blade_loads(viRadial,z);
        gravityMoment = -P.rotor.Sblade*P.env.g*cos(ll.beta);
        inertialRestoring = P.rotor.Ib*ll.betaDDot+P.rotor.Ib*Omega^2*ll.beta;
        byAz = inertialRestoring-ll.flapMomentByAzimuth-gravityMoment;
        res = [mean(byAz);2*mean(byAz.*cos(psi));2*mean(byAz.*sin(psi))];
        scale = max([max(abs(ll.flapMomentByAzimuth)),max(abs(gravityMoment)), ...
            P.rotor.Ib*Omega^2*0.05,1]);
    end

    function ll = blade_loads(viRadial,z)
        betaLocal = z(1)+z(2)*cos(psi)+z(3)*sin(psi);
        betaDotLocal = -Omega*(-z(2)*sin(psi)+z(3)*cos(psi));
        betaDDotLocal = -Omega^2*(z(2)*cos(psi)+z(3)*sin(psi));
        viField = viRadial.*(1+cos(psi).*(rMid/R));
        UP = viField-betaDotLocal.*rMid;
        W = hypot(UT,UP);
        phi = atan2(UP,max(abs(UT),1e-8));
        alpha = thetaBlade-phi;
        CL = scalarC81.CLmax*tanh( ...
            scalarC81.liftSlope*(alpha-scalarC81.alpha0L_rad)/scalarC81.CLmax);
        CD = scalarC81.CD0+scalarC81.kCD*CL.^2;
        q = 0.5*rho*W.^2;
        dL = q*P.rotor.chord.*CL.*dr;
        dD = q*P.rotor.chord.*CD.*dr;
        dT = dL.*cos(phi)-dD.*sin(phi);
        dH = dD.*cos(phi)+dL.*sin(phi);
        dQ = dH.*rMid;
        factor = P.rotor.Nb/P.rotor.nAzimuth;
        ll.ringThrust_N = factor*sum(dT,1);
        ll.ringTorque_Nm = factor*sum(dQ,1);
        ll.T = sum(ll.ringThrust_N);
        ll.Q = sum(ll.ringTorque_Nm);
        ll.flapMomentByAzimuth = sum(dT.*rMid,2);
        ll.beta = betaLocal;
        ll.betaDDot = betaDDotLocal;
    end
end

function value = figure_of_merit(CT,CP)
if CT > 0 && CP > 0
    value = CT^(3/2)/(sqrt(2)*CP);
else
    value = NaN;
end
end

function value = mape(model,experiment,mask)
if ~any(mask)
    value = NaN;
else
    value = 100*mean(abs((model(mask)-experiment(mask))./experiment(mask)));
end
end

function theta_deg = nasa_metal_twist_deg(x)
theta_deg = 289.98*x.^5-892.87*x.^4+987.06*x.^3 ...
    -438.31*x.^2+15.695*x+32.057;
end
