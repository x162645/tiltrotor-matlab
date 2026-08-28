function results = run_xv15_mangler_hover_inflow_diagnostic(outputDir)
%RUN_XV15_MANGLER_HOVER_INFLOW_DIAGNOSTIC
% Global-coupled radial-inflow diagnostic for XV-15 metal-blade hover.
%
% PURPOSE
% -------
% Isolate whether a classical globally coupled, nonlinear radial inflow shape
% can explain the remaining hover CT bias after restoring the public XV-15
% metal-blade radial chord/twist geometry and the independently reduced NASA
% C81 scalar section-aerodynamic parameters.
%
% Modes:
%   GLOBAL_UNIFORM_SHAPE
%       vi(r) = viMean.
%
%   MANGLER_MEAN_MATCHED
%       Uses the hover zero-harmonic radial shape obtained from the
%       Mangler-Squire/Bramwell form
%
%         lambda_i = 4*lambda_0*(c0/2 - sum c_n cos(n psi)),
%         c0 = 15*mu0*(1-mu0)/8,
%         mu0 = sqrt(1-(r/R)^2).
%
%       In axisymmetric hover the diagnostic retains only the zero harmonic.
%       Its raw radial factor relative to lambda_0 is
%
%         f_raw = (15/4)*mu0*(1-mu0).
%
%       The full-disk area mean of f_raw is 5/8. To isolate RADIAL SHAPE from
%       a simultaneous change in the global momentum level, this diagnostic
%       divides by 5/8 so that <f>_disk = 1:
%
%         f_MS = 6*mu0*(1-mu0).
%
%       Therefore the same globally solved viMean is redistributed radially,
%       rather than reduced in magnitude.
%
%   MANGLER_RAW_AMPLITUDE_SENSITIVITY
%       Retains f_raw without the mean-match normalization. This is written
%       only as a NON-ISOLATED sensitivity check because it changes both the
%       radial shape and the disk-mean inflow magnitude. It must not be used
%       as the primary error-attribution result.
%
% All modes retain the production Eq. (13)-equivalent global mean-inflow
% update, first-harmonic flapping equations, Eq. (12) azimuthal multiplier,
% actual XV-15 radial chord/twist geometry, and scalar C81 low-order section
% closure. OARF data are external comparison data only; no parameter is fit
% to OARF CT/CP/FM.
%
% SOURCES / CLAIM BOUNDARY
% ------------------------
% - Mangler & Squire, R&M 2642 (1950): lifting-rotor induced-velocity field.
% - Bramwell hover-valid scaling commonly written as 4*lambda0 times the
%   Mangler-Squire Fourier bracket.
% - The mean-match normalization is a CONTROLLED DIAGNOSTIC choice, not a
%   claim that f_MS is a complete finite-blade XV-15 wake model.
% - The Mangler-Squire theory is lightly-loaded / infinite-blade potential
%   theory; finite-blade tip-vortex roll-up and free-wake contraction remain
%   outside this diagnostic.

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
% Radial wake shape is steep near the root/tip. Use 48 stations for the
% primary diagnostic and check 12/24/48/96 below. This does not change the
% production default.
Ptemplate.rotor.nRadial = 48;

theta75Source_deg = nasa_metal_twist_deg(0.75);

rows = table();
for k = 1:numel(collective75_deg)
    P = Ptemplate;
    Vtip_mps = Vtip_fps(k)*0.3048;
    P.rotor.Omega = Vtip_mps/R;

    globalOut = solve_mode(P,collective75_deg(k),theta75Source_deg, ...
        scalarC81,'GLOBAL_UNIFORM_SHAPE');
    manglerOut = solve_mode(P,collective75_deg(k),theta75Source_deg, ...
        scalarC81,'MANGLER_MEAN_MATCHED');
    rawOut = solve_mode(P,collective75_deg(k),theta75Source_deg, ...
        scalarC81,'MANGLER_RAW_AMPLITUDE_SENSITIVITY');

    A = pi*R^2;
    denT = P.env.rho*A*Vtip_mps^2;
    denP = P.env.rho*A*Vtip_mps^3;
    CTg = globalOut.thrust/denT;
    CTm = manglerOut.thrust/denT;
    CTr = rawOut.thrust/denT;
    CPg = globalOut.torque*P.rotor.Omega/denP;
    CPm = manglerOut.torque*P.rotor.Omega/denP;
    CPr = rawOut.torque*P.rotor.Omega/denP;
    FMg = figure_of_merit(CTg,CPg);
    FMm = figure_of_merit(CTm,CPm);
    FMr = figure_of_merit(CTr,CPr);

    local = table(collective75_deg(k),Vtip_fps(k),CT_exp(k),CTg,CTm,CTr, ...
        CP_exp(k),CPg,CPm,CPr,FM_exp(k),FMg,FMm,FMr, ...
        globalOut.viMean_mps,manglerOut.viMean_mps,rawOut.viMean_mps, ...
        min(manglerOut.viRadial_mps),max(manglerOut.viRadial_mps), ...
        manglerOut.rawShapeDiskMean,manglerOut.meanMatchedShapeDiskMean, ...
        globalOut.converged,manglerOut.converged,rawOut.converged, ...
        'VariableNames',{'collective75_deg','Vtip_fps','CT_exp','CT_global', ...
        'CT_manglerMeanMatched','CT_manglerRawSensitivity','CP_exp','CP_global', ...
        'CP_manglerMeanMatched','CP_manglerRawSensitivity','FM_exp','FM_global', ...
        'FM_manglerMeanMatched','FM_manglerRawSensitivity','viMean_global_mps', ...
        'viMean_manglerMeanMatched_mps','viMean_manglerRawSensitivity_mps', ...
        'minVi_manglerMeanMatched_mps','maxVi_manglerMeanMatched_mps', ...
        'rawShapeDiskMean','meanMatchedShapeDiskMean','globalConverged', ...
        'manglerMeanMatchedConverged','manglerRawSensitivityConverged'});
    rows = [rows;local]; %#ok<AGROW>
end

writetable(rows,fullfile(outputDir,'XV15_MANGLER_HOVER_MATLAB_DIAGNOSTIC.csv'));

% Report both the full 6-11 range and the 9-11 range used by the preceding
% actual-geometry x annular-momentum cross-check.
maskAll = rows.globalConverged & rows.manglerMeanMatchedConverged;
maskHigh = maskAll & rows.collective75_deg >= 9;
metrics = table();
metrics.pointCount_6to11 = nnz(maskAll);
metrics.CT_MAPE_global_6to11_pct = mape(rows.CT_global,rows.CT_exp,maskAll);
metrics.CT_MAPE_manglerMeanMatched_6to11_pct = ...
    mape(rows.CT_manglerMeanMatched,rows.CT_exp,maskAll);
metrics.CP_MAPE_global_6to11_pct = mape(rows.CP_global,rows.CP_exp,maskAll);
metrics.CP_MAPE_manglerMeanMatched_6to11_pct = ...
    mape(rows.CP_manglerMeanMatched,rows.CP_exp,maskAll);
metrics.FM_MAPE_global_6to11_pct = mape(rows.FM_global,rows.FM_exp,maskAll);
metrics.FM_MAPE_manglerMeanMatched_6to11_pct = ...
    mape(rows.FM_manglerMeanMatched,rows.FM_exp,maskAll);
metrics.pointCount_9to11 = nnz(maskHigh);
metrics.CT_MAPE_global_9to11_pct = mape(rows.CT_global,rows.CT_exp,maskHigh);
metrics.CT_MAPE_manglerMeanMatched_9to11_pct = ...
    mape(rows.CT_manglerMeanMatched,rows.CT_exp,maskHigh);
metrics.CP_MAPE_global_9to11_pct = mape(rows.CP_global,rows.CP_exp,maskHigh);
metrics.CP_MAPE_manglerMeanMatched_9to11_pct = ...
    mape(rows.CP_manglerMeanMatched,rows.CP_exp,maskHigh);
metrics.FM_MAPE_global_9to11_pct = mape(rows.FM_global,rows.FM_exp,maskHigh);
metrics.FM_MAPE_manglerMeanMatched_9to11_pct = ...
    mape(rows.FM_manglerMeanMatched,rows.FM_exp,maskHigh);
writetable(metrics,fullfile(outputDir,'XV15_MANGLER_HOVER_MATLAB_METRICS.csv'));

% 10-deg radial-grid convergence.
gridN = [12;24;48;96];
gridRows = table();
for j = 1:numel(gridN)
    P = Ptemplate;
    P.rotor.nRadial = gridN(j);
    P.rotor.Omega = (768.0*0.3048)/R;
    gout = solve_mode(P,10,theta75Source_deg,scalarC81,'GLOBAL_UNIFORM_SHAPE');
    mout = solve_mode(P,10,theta75Source_deg,scalarC81,'MANGLER_MEAN_MATCHED');
    Vtip_mps = 768.0*0.3048;
    A = pi*R^2;
    CTg = gout.thrust/(P.env.rho*A*Vtip_mps^2);
    CTm = mout.thrust/(P.env.rho*A*Vtip_mps^2);
    CPg = gout.torque*P.rotor.Omega/(P.env.rho*A*Vtip_mps^3);
    CPm = mout.torque*P.rotor.Omega/(P.env.rho*A*Vtip_mps^3);
    one = table(gridN(j),CTg,CTm,CPg,CPm,min(mout.viRadial_mps), ...
        max(mout.viRadial_mps),gout.converged,mout.converged, ...
        'VariableNames',{'nRadial','CT_global','CT_manglerMeanMatched', ...
        'CP_global','CP_manglerMeanMatched','minVi_mangler_mps', ...
        'maxVi_mangler_mps','globalConverged','manglerConverged'});
    gridRows = [gridRows;one]; %#ok<AGROW>
end
writetable(gridRows,fullfile(outputDir,'XV15_MANGLER_HOVER_GRID_MATLAB_DIAGNOSTIC.csv'));

results = struct();
results.table = rows;
results.metrics = metrics;
results.grid = gridRows;
results.claimBoundary = ['MEAN_MATCHED_MANGLER_ZERO_HARMONIC_DIAGNOSTIC_' ...
    'ACTUAL_RADIAL_GEOMETRY_SCALAR_C81_NO_OARF_FIT_NO_PRODUCTION_CHANGE'];
save(fullfile(outputDir,'XV15_MANGLER_HOVER_DIAGNOSTIC_RESULTS.mat'),'results');
end

function out = solve_mode(P,theta75_deg,theta75Source_deg,scalarC81,mode)
R = P.rotor.R;
Omega = P.rotor.Omega;
tipSpeed = Omega*R;
A = pi*R^2;
rho = P.env.rho;
r0 = P.rotor.rootCut*R;
rEdges = linspace(r0,R,P.rotor.nRadial+1);
rMid = 0.5*(rEdges(1:end-1)+rEdges(2:end));
dr = diff(rEdges);
x = rMid/R;
psi = ((0:P.rotor.nAzimuth-1)*(2*pi/P.rotor.nAzimuth)).';

chord = xv15_metal_chord_m(x);
thetaBlade = (theta75_deg + nasa_metal_twist_deg(x)-theta75Source_deg)*pi/180;
UT = Omega*rMid;

mu0 = sqrt(max(1-x.^2,0));
rawShape = (15/4)*mu0.*(1-mu0);
rawShapeDiskMean = 5/8; % 2*int_0^1 f_raw*x dx
meanMatchedShape = rawShape/rawShapeDiskMean;
meanMatchedShapeDiskMean = 1.0;

mode = upper(char(mode));
if strcmp(mode,'GLOBAL_UNIFORM_SHAPE')
    shape = ones(size(x));
elseif strcmp(mode,'MANGLER_MEAN_MATCHED')
    shape = meanMatchedShape;
elseif strcmp(mode,'MANGLER_RAW_AMPLITUDE_SENSITIVITY')
    shape = rawShape;
else
    error('run_xv15_mangler_hover_inflow_diagnostic:UnknownMode','Unknown mode %s',mode);
end

viMean = sqrt(max(P.mass.m*P.env.g/2,1)/(2*rho*A));
zFlap = P.rotor.flapInitial(:);
converged = false;
viError = Inf;
flapInfo = struct('converged',false,'residualNorm',Inf);
maxIter = max(100,5*P.rotor.inducedMaxIter);

for iter = 1:maxIter
    [zFlap,flapInfo] = solve_flap(viMean,zFlap);
    if ~flapInfo.converged
        break;
    end
    loads = blade_loads(viMean,zFlap);
    lambda1 = -viMean/max(tipSpeed,eps);
    CTiter = max(loads.T,0)/(0.5*rho*A*tipSpeed^2);
    viTarget = tipSpeed*CTiter/(4*max(abs(lambda1),1.0e-12));
    viNew = 0.5*(viMean+viTarget);
    viError = abs(viNew-viMean)/max(1,abs(viMean));
    viMean = viNew;
    if viError < 1.0e-6 && flapInfo.residualNorm <= P.rotor.flapResidualTol
        converged = true;
        break;
    end
end

loads = blade_loads(viMean,zFlap);
out = struct();
out.mode = mode;
out.thrust = loads.T;
out.torque = loads.Q;
out.viMean_mps = viMean;
out.viRadial_mps = viMean*shape;
out.zFlap = zFlap;
out.flap = flapInfo;
out.iterations = iter;
out.viError = viError;
out.converged = converged && flapInfo.converged && loads.T > 0;
out.rawShapeDiskMean = rawShapeDiskMean;
out.meanMatchedShapeDiskMean = meanMatchedShapeDiskMean;
out.rawShape = rawShape;
out.meanMatchedShape = meanMatchedShape;
out.rOverR = x;
out.claimBoundary = ['GLOBAL_MEAN_MOMENTUM_WITH_PRESCRIBED_RADIAL_SHAPE_' ...
    'NO_LOCAL_MOMENTUM_CLOSURE_NO_OARF_FIT'];

    function [z,info] = solve_flap(viNow,z0)
        z = z0(:);
        info = struct('converged',false,'iterations',0,'residualNorm',Inf);
        for k = 1:P.rotor.flapMaxIter
            [res,scale] = flap_residual(z,viNow);
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
                zp(jj)=zp(jj)+h; zm(jj)=zm(jj)-h;
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
        viRadial = viNow*shape;
        % Keep the same Eq. (12) azimuthal multiplier used by the preceding
        % diagnostic chain so that only the radial shape changes here.
        viField = viRadial.*(1+cos(psi).*(rMid/R));
        UP = viField-betaDotLocal.*rMid;
        W = hypot(UT,UP);
        phi = atan2(UP,max(abs(UT),1e-8));
        alpha = thetaBlade-phi;
        CL = scalarC81.CLmax*tanh( ...
            scalarC81.liftSlope*(alpha-scalarC81.alpha0L_rad)/scalarC81.CLmax);
        CD = scalarC81.CD0+scalarC81.kCD*CL.^2;
        q = 0.5*rho*W.^2;
        dL = q.*chord.*CL.*dr;
        dD = q.*chord.*CD.*dr;
        dT = dL.*cos(phi)-dD.*sin(phi);
        dH = dD.*cos(phi)+dL.*sin(phi);
        dQ = dH.*rMid;
        factor = P.rotor.Nb/P.rotor.nAzimuth;
        ll.T = factor*sum(dT(:));
        ll.Q = factor*sum(dQ(:));
        ll.flapMomentByAzimuth = sum(dT.*rMid,2);
        ll.beta = betaLocal;
        ll.betaDDot = betaDDotLocal;
    end
end

function c = xv15_metal_chord_m(x)
cIn = 14*ones(size(x));
mask = x <= 0.25;
cIn(mask) = -18.4615*x(mask)+18.6154;
c = cIn*0.0254;
end

function theta_deg = nasa_metal_twist_deg(x)
theta_deg = 289.98*x.^5-892.87*x.^4+987.06*x.^3 ...
    -438.31*x.^2+15.695*x+32.057;
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
