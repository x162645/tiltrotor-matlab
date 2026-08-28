function results = run_xv15_actual_geometry_c81_crosscheck(outputDir)
%RUN_XV15_ACTUAL_GEOMETRY_C81_CROSSCHECK
% Cross-check XV-15 original-metal-blade hover with the public radial chord
% and nonlinear twist retained explicitly, while comparing:
%   1) scalar low-order reduction of NASA C81 inputs + global momentum;
%   2) full four-region C81 lookup with local Mach + global momentum;
%   3) full four-region C81 lookup with local Mach + annular momentum.
%
% This is an error-attribution diagnostic only. OARF Run 15 CT/CP/FM enter
% only as external comparison data. They are not used to fit geometry,
% airfoil tables, inflow shape, momentum closure or any physical parameter.

rootDir = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1 || isempty(outputDir)
    outputDir = fullfile(rootDir,'results','xv15_section_aero_validation');
end
if ~exist(outputDir,'dir')
    mkdir(outputDir);
end

Pbase = params_nominal();
scalarC81 = build_xv15_c81_low_order_section_aero();
R = 3.81;
rootCut = 0.0875;

collective75_deg = [6;7;8;9;10;11];
Vtip_fps = [768.4;768.4;768.4;768.0;768.0;767.7];
CT_exp = [0.009208;0.010104;0.011063;0.012035;0.013089;0.013929];
CP_exp = [0.000796;0.000913;0.001044;0.001188;0.001358;0.001523];
FM_exp = [0.7849;0.7866;0.7881;0.7858;0.7797;0.7632];

Ptemplate = Pbase;
Ptemplate.rotor.R = R;
Ptemplate.rotor.Nb = 3;
Ptemplate.rotor.rootCut = rootCut;
Ptemplate.rotor.Ib = Ptemplate.rotor.bladeMass*R^2/3;
Ptemplate.rotor.Sblade = Ptemplate.rotor.bladeMass*R/2;
if ~isfield(Ptemplate.env,'aSound')
    Ptemplate.env.aSound = 340.0;
end

rows = table();
for k = 1:numel(collective75_deg)
    P = Ptemplate;
    Vtip_mps = Vtip_fps(k)*0.3048;
    P.rotor.Omega = Vtip_mps/R;

    scalarGlobal = solve_actual_geometry_hover( ...
        P,collective75_deg(k),'SCALAR_C81_LOW_ORDER',scalarC81,'GLOBAL',[]);
    fullGlobal = solve_actual_geometry_hover( ...
        P,collective75_deg(k),'SPANWISE_C81_LOCAL_MACH',scalarC81,'GLOBAL',[]);
    fullAnnular = solve_actual_geometry_hover( ...
        P,collective75_deg(k),'SPANWISE_C81_LOCAL_MACH',scalarC81, ...
        'ANNULAR',fullGlobal.inducedVelocity);

    A = pi*R^2;
    [CTs,CPs,FMs] = nondim(scalarGlobal,P,A,Vtip_mps);
    [CTf,CPf,FMf] = nondim(fullGlobal,P,A,Vtip_mps);
    [CTa,CPa,FMa] = nondim(fullAnnular,P,A,Vtip_mps);

    one = table(collective75_deg(k),Vtip_fps(k),CT_exp(k),CP_exp(k),FM_exp(k), ...
        CTs,CPs,FMs,CTf,CPf,FMf,CTa,CPa,FMa, ...
        scalarGlobal.physicalConverged,fullGlobal.physicalConverged, ...
        fullAnnular.physicalConverged,fullGlobal.alphaClampCount, ...
        fullGlobal.machClampCount,fullAnnular.maxLocalClosureResidualRelative, ...
        'VariableNames',{'collective75_deg','Vtip_fps','CT_exp','CP_exp','FM_exp', ...
        'CT_scalarC81_global','CP_scalarC81_global','FM_scalarC81_global', ...
        'CT_fullC81_global','CP_fullC81_global','FM_fullC81_global', ...
        'CT_fullC81_annular','CP_fullC81_annular','FM_fullC81_annular', ...
        'scalarGlobalSupported','fullGlobalSupported','fullAnnularSupported', ...
        'fullGlobalAlphaClampCount','fullGlobalMachClampCount', ...
        'fullAnnularMaxClosureResidualRelative'});
    rows = [rows;one]; %#ok<AGROW>
end

writetable(rows,fullfile(outputDir,'XV15_ACTUAL_GEOMETRY_C81_MATLAB_CROSSCHECK.csv'));

metrics = table();
metrics.window = ["6-11";"9-11"];
maskAll = true(height(rows),1);
maskHigh = rows.collective75_deg >= 9;
metrics.CT_MAPE_scalarC81_global_pct = [ ...
    mape(rows.CT_scalarC81_global,rows.CT_exp,maskAll); ...
    mape(rows.CT_scalarC81_global,rows.CT_exp,maskHigh)];
metrics.CP_MAPE_scalarC81_global_pct = [ ...
    mape(rows.CP_scalarC81_global,rows.CP_exp,maskAll); ...
    mape(rows.CP_scalarC81_global,rows.CP_exp,maskHigh)];
metrics.FM_MAPE_scalarC81_global_pct = [ ...
    mape(rows.FM_scalarC81_global,rows.FM_exp,maskAll); ...
    mape(rows.FM_scalarC81_global,rows.FM_exp,maskHigh)];
metrics.CT_MAPE_fullC81_global_pct = [ ...
    mape(rows.CT_fullC81_global,rows.CT_exp,maskAll); ...
    mape(rows.CT_fullC81_global,rows.CT_exp,maskHigh)];
metrics.CP_MAPE_fullC81_global_pct = [ ...
    mape(rows.CP_fullC81_global,rows.CP_exp,maskAll); ...
    mape(rows.CP_fullC81_global,rows.CP_exp,maskHigh)];
metrics.FM_MAPE_fullC81_global_pct = [ ...
    mape(rows.FM_fullC81_global,rows.FM_exp,maskAll); ...
    mape(rows.FM_fullC81_global,rows.FM_exp,maskHigh)];
metrics.CT_MAPE_fullC81_annular_pct = [ ...
    mape(rows.CT_fullC81_annular,rows.CT_exp,maskAll); ...
    mape(rows.CT_fullC81_annular,rows.CT_exp,maskHigh)];
metrics.CP_MAPE_fullC81_annular_pct = [ ...
    mape(rows.CP_fullC81_annular,rows.CP_exp,maskAll); ...
    mape(rows.CP_fullC81_annular,rows.CP_exp,maskHigh)];
metrics.FM_MAPE_fullC81_annular_pct = [ ...
    mape(rows.FM_fullC81_annular,rows.FM_exp,maskAll); ...
    mape(rows.FM_fullC81_annular,rows.FM_exp,maskHigh)];
writetable(metrics,fullfile(outputDir,'XV15_ACTUAL_GEOMETRY_C81_MATLAB_METRICS.csv'));

results = struct();
results.table = rows;
results.metrics = metrics;
results.claimBoundary = ['ACTUAL_GEOMETRY_C81_CROSSCHECK_DIAGNOSTIC_' ...
    'NO_OARF_FIT_NO_PRODUCTION_MODEL_CHANGE'];
save(fullfile(outputDir,'XV15_ACTUAL_GEOMETRY_C81_CROSSCHECK_RESULTS.mat'),'results');
end

function out = solve_actual_geometry_hover(P,theta75_deg,sectionMode,scalarC81,closureMode,viInitial)
sectionMode = upper(char(sectionMode));
closureMode = upper(char(closureMode));
R = P.rotor.R;
Omega = P.rotor.Omega;
tipSpeed = Omega*R;
rho = P.env.rho;
A = pi*R^2;
r0 = P.rotor.rootCut*R;
rEdges = linspace(r0,R,P.rotor.nRadial+1);
rMid = 0.5*(rEdges(1:end-1)+rEdges(2:end));
dr = diff(rEdges);
dA = pi*(rEdges(2:end).^2-rEdges(1:end-1).^2);
psi = ((0:P.rotor.nAzimuth-1)*(2*pi/P.rotor.nAzimuth)).';

x = rMid/R;
chord_in = 14*ones(size(x));
inboard = x <= 0.25;
chord_in(inboard) = -18.4615*x(inboard)+18.6154;
chord_m = chord_in*0.0254;
thetaSource_deg = nasa_metal_twist_deg(x);
theta75Source_deg = nasa_metal_twist_deg(0.75);
thetaBlade = (theta75_deg + thetaSource_deg-theta75Source_deg)*pi/180;
UT = Omega*rMid;

if isempty(viInitial)
    vi0 = sqrt(max(P.mass.m*P.env.g/2,1)/(2*rho*A));
else
    vi0 = viInitial;
end
zFlap = P.rotor.flapInitial(:);
if numel(zFlap) ~= 3
    error('P.rotor.flapInitial must contain [beta0; beta1c; beta1s].');
end

if strcmp(closureMode,'GLOBAL')
    vi = vi0;
    converged = false;
    for iter = 1:P.rotor.inducedMaxIter
        [zFlap,flapInfo] = solve_flap(vi,zFlap);
        if ~flapInfo.converged
            break;
        end
        loads = blade_loads(vi,zFlap);
        lambda1 = -vi/max(tipSpeed,eps);
        CTiter = max(loads.T,0)/(0.5*rho*A*tipSpeed^2);
        viTarget = tipSpeed*CTiter/(4*max(abs(lambda1),1e-12));
        viNew = 0.5*(vi+viTarget);
        err = abs(viNew-vi)/max(1,abs(vi));
        vi = viNew;
        if err < P.rotor.inducedTol && flapInfo.residualNorm <= P.rotor.flapResidualTol
            converged = true;
            break;
        end
    end
    loads = blade_loads(vi,zFlap);
    lambda1 = -vi/max(tipSpeed,eps);
    momentumThrust = 2*rho*A*tipSpeed*vi*abs(lambda1);
    closureResidualRelative = abs(loads.T-momentumThrust) / ...
        max([abs(loads.T),abs(momentumThrust),1]);
    physical = converged && flapInfo.converged && loads.T > 0 && ...
        closureResidualRelative <= 2.0e-4;
    out.maxLocalClosureResidualRelative = NaN;
else
    vi = vi0*ones(1,P.rotor.nRadial);
    converged = false;
    maxIter = max(100,5*P.rotor.inducedMaxIter);
    for iter = 1:maxIter
        [zFlap,flapInfo] = solve_flap(vi,zFlap);
        if ~flapInfo.converged
            break;
        end
        loads = blade_loads(vi,zFlap);
        viTarget = sqrt(max(loads.ringThrust_N,0)./(2*rho*dA));
        viNew = (1-P.rotor.inducedRelax)*vi + P.rotor.inducedRelax*viTarget;
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
    out.maxLocalClosureResidualRelative = max(localResidualRelative);
    physical = converged && flapInfo.converged && all(loads.ringThrust_N > 0) && ...
        out.maxLocalClosureResidualRelative <= 2.0e-4;
end

out.thrust = loads.T;
out.torque = loads.Q;
out.inducedVelocity = vi;
out.zFlap = zFlap;
out.flap = flapInfo;
out.physicalConverged = physical;
out.alphaClampCount = loads.alphaClampCount;
out.machClampCount = loads.machClampCount;
out.claimBoundary = ['ACTUAL_METAL_BLADE_GEOMETRY_' sectionMode '_' closureMode ...
    '_NO_OARF_PARAMETER_FIT'];

    function [z,info] = solve_flap(viNow,z0)
        z = z0(:);
        info = struct('converged',false,'iterations',0,'residualNorm',Inf);
        for kk = 1:P.rotor.flapMaxIter
            [res,scale] = flap_residual(z,viNow);
            rn = res/scale;
            if norm(rn) <= P.rotor.flapResidualTol
                info.converged = true;
                info.iterations = kk;
                info.residualNorm = norm(rn);
                return;
            end
            J = zeros(3,3);
            for jj = 1:3
                h = P.rotor.flapJacobianStep*max(1,abs(z(jj)));
                zp = z; zm = z;
                zp(jj) = zp(jj)+h; zm(jj) = zm(jj)-h;
                [rp,~] = flap_residual(zp,viNow);
                [rm,~] = flap_residual(zm,viNow);
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
                    [rc,sc] = flap_residual(zc,viNow);
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
        [res,scale] = flap_residual(z,viNow);
        info.iterations = P.rotor.flapMaxIter;
        info.residualNorm = norm(res/scale);
    end

    function [res,scale] = flap_residual(z,viNow)
        ll = blade_loads(viNow,z);
        gravityMoment = -P.rotor.Sblade*P.env.g*cos(ll.beta);
        inertialRestoring = P.rotor.Ib*ll.betaDDot+P.rotor.Ib*Omega^2*ll.beta;
        byAz = inertialRestoring-ll.flapMomentByAzimuth-gravityMoment;
        res = [mean(byAz);2*mean(byAz.*cos(psi));2*mean(byAz.*sin(psi))];
        scale = max([max(abs(ll.flapMomentByAzimuth)),max(abs(gravityMoment)), ...
            P.rotor.Ib*Omega^2*0.05,1]);
    end

    function ll = blade_loads(viNow,z)
        betaLocal = z(1)+z(2)*cos(psi)+z(3)*sin(psi);
        betaDotLocal = -Omega*(-z(2)*sin(psi)+z(3)*cos(psi));
        betaDDotLocal = -Omega^2*(z(2)*cos(psi)+z(3)*sin(psi));
        viField = viNow.*(1+cos(psi).*(rMid/R));
        UP = viField-betaDotLocal.*rMid;
        W = hypot(UT,UP);
        phi = atan2(UP,max(abs(UT),1e-8));
        alpha = thetaBlade-phi;
        Mach = W/P.env.aSound;

        if strcmp(sectionMode,'SCALAR_C81_LOW_ORDER')
            CL = scalarC81.CLmax*tanh( ...
                scalarC81.liftSlope*(alpha-scalarC81.alpha0L_rad)/scalarC81.CLmax);
            CD = scalarC81.CD0+scalarC81.kCD*CL.^2;
            alphaClampCount = 0;
            machClampCount = 0;
        else
            [CL,CD,meta] = xv15_c81_section_lookup(alpha,Mach,rMid/R);
            alphaClampCount = meta.alphaClampCount;
            machClampCount = meta.machClampCount;
        end

        q = 0.5*rho*W.^2;
        dL = q.*chord_m.*CL.*dr;
        dD = q.*chord_m.*CD.*dr;
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
        ll.alphaClampCount = alphaClampCount;
        ll.machClampCount = machClampCount;
    end
end

function [CT,CP,FM] = nondim(out,P,A,Vtip)
CT = out.thrust/(P.env.rho*A*Vtip^2);
CP = out.torque*P.rotor.Omega/(P.env.rho*A*Vtip^3);
if CT > 0 && CP > 0
    FM = CT^(3/2)/(sqrt(2)*CP);
else
    FM = NaN;
end
end

function value = mape(model,experiment,mask)
mask = mask & isfinite(model) & isfinite(experiment) & experiment ~= 0;
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
