function results = run_m1_geometry_source_fidelity_audit(outputDir)
%RUN_M1_GEOMETRY_SOURCE_FIDELITY_AUDIT
% Audit whether the M1-A radial-geometry conclusion is robust to legitimate
% public-source interpretations of XV-15 original-metal-blade chord/twist.
%
% This is a source-fidelity sensitivity study, NOT geometry calibration.
% OARF Run-15 CT/CP/FM are downstream comparison observables only and are
% never used to define or select a geometry case.
%
% Cases
% -----
% CURRENT_RECONSTRUCTION
%   Existing M1-A implementation: 17 in at 0.0875R linearly to 14 in at
%   0.25R, then 14 in; existing fifth-order twist representation.
%
% CURRENT_CHORD_DIRECT_TWISTA
%   Existing chord reconstruction + direct 51-station Appendix-A TWISTA.
%
% TP_TEXT_CHORD_DIRECT_TWISTA
%   NASA/TP-2004-212262 narrative planform: first aerodynamic section is
%   17 in at 0.12R, tapering to 14 in at 0.25R, then constant. Because the
%   present low-order integration begins at 0.0875R, the first stated 17-in
%   chord is transparently held inward from 0.12R to 0.0875R. This inward
%   extension is an audit convention, not claimed measured geometry.
%
% TP_APPENDIX_A_CAMRAD_DIRECT_TWISTA
%   NASA/TP-2004-212262 Appendix-A CAMRAD II aerodynamic CHORD/RPROP input
%   + direct 51-station TWISTA. These are NASA reference-model inputs, not
%   asserted to be OARF Run-15 measured blade geometry.
%
% All four cases use the same M1-A scalar C81, global momentum, Eq.(12)
% first-harmonic inflow and first-harmonic flapping equations.

rootDir = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1 || isempty(outputDir)
    outputDir = fullfile(rootDir,'results','m1_geometry_source_fidelity_audit');
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

caseId = { ...
    'CURRENT_RECONSTRUCTION'; ...
    'CURRENT_CHORD_DIRECT_TWISTA'; ...
    'TP_TEXT_CHORD_DIRECT_TWISTA'; ...
    'TP_APPENDIX_A_CAMRAD_DIRECT_TWISTA'};
chordContract = { ...
    '17IN_AT_0P0875R_LINEAR_TO_14IN_AT_0P25R'; ...
    '17IN_AT_0P0875R_LINEAR_TO_14IN_AT_0P25R'; ...
    '17IN_AT_0P12R_LINEAR_TO_14IN_AT_0P25R_WITH_TRANSPARENT_INBOARD_EXTENSION'; ...
    'TP_APPENDIX_A_CAMRAD_RPROP_CHORD'};
twistContract = { ...
    'EXISTING_FIFTH_ORDER_SOURCE_INFORMED_REPRESENTATION'; ...
    'TP_APPENDIX_A_51_POINT_TWISTA_DIRECT_INTERPOLATION'; ...
    'TP_APPENDIX_A_51_POINT_TWISTA_DIRECT_INTERPOLATION'; ...
    'TP_APPENDIX_A_51_POINT_TWISTA_DIRECT_INTERPOLATION'};
sourceRole = { ...
    'CURRENT_M1A_IMPLEMENTATION'; ...
    'CURRENT_CHORD_PLUS_NASA_REFERENCE_TWIST'; ...
    'TP_TEXT_PLANFORM_PLUS_NASA_REFERENCE_TWIST'; ...
    'NASA_REFERENCE_MODEL_INPUT'};
selectionRule = repmat({'NO_OARF_WADC_BASED_GEOMETRY_SELECTION'},4,1);
caseTable = table(caseId,chordContract,twistContract,sourceRole,selectionRule);
writetable(caseTable,fullfile(outputDir,'M1_GEOMETRY_SOURCE_CASES.csv'));

Ptemplate = Pbase;
Ptemplate.rotor.R = R;
Ptemplate.rotor.Nb = 3;
Ptemplate.rotor.rootCut = rootCut;
Ptemplate.rotor.Ib = Ptemplate.rotor.bladeMass*R^2/3;
Ptemplate.rotor.Sblade = Ptemplate.rotor.bladeMass*R/2;
if ~isfield(Ptemplate.env,'aSound')
    Ptemplate.env.aSound = 340.0;
end

%% Source-only profile and geometry-integral audit
xProfile = linspace(rootCut,1,501).';
profile = table(xProfile, ...
    current_chord(xProfile),tp_text_chord(xProfile), ...
    tp_appendix_a_chord(xProfile),current_twist(xProfile), ...
    direct_twista(xProfile), ...
    'VariableNames',{'r_R','chordCurrent_m','chordTpText_m', ...
    'chordTpAppendix_m','twistCurrent_deg','twistAppendixDirect_deg'});
profile.anchoredTwistDirectMinusCurrent_deg = ...
    (profile.twistAppendixDirect_deg-direct_twista(0.75)) - ...
    (profile.twistCurrent_deg-current_twist(0.75));
writetable(profile,fullfile(outputDir,'M1_GEOMETRY_SOURCE_PROFILES.csv'));

rFine = xProfile*R;
geomRows = table();
for ic = 1:numel(caseId)
    [cFine,tFine] = geometry_profile(xProfile,caseId{ic});
    t75 = geometry_twist_75(caseId{ic});
    anchored = tFine-t75;
    directAnchored = direct_twista(xProfile)-direct_twista(0.75);
    anchoredDiff = anchored-directAnchored;

    bladeArea_m2 = trapz(rFine,cFine);
    integratedSolidity = Ptemplate.rotor.Nb*bladeArea_m2/(pi*R^2);
    int_c_r2_dr_m4 = trapz(rFine,cFine.*rFine.^2);
    int_c_r3_dr_m5 = trapz(rFine,cFine.*rFine.^3);
    twistRMS_deg = sqrt(trapz(rFine,anchoredDiff.^2)/(R*(1-rootCut)));
    wt = cFine.*rFine.^2;
    twistR2WeightedRMS_deg = sqrt(trapz(rFine,wt.*anchoredDiff.^2)/trapz(rFine,wt));
    twistMaxAbs_deg = max(abs(anchoredDiff));

    one = table(caseId(ic),bladeArea_m2,integratedSolidity, ...
        int_c_r2_dr_m4,int_c_r3_dr_m5,t75,twistRMS_deg, ...
        twistR2WeightedRMS_deg,twistMaxAbs_deg, ...
        'VariableNames',{'caseId','bladeArea_m2','integratedSolidity', ...
        'int_c_r2_dr_m4','int_c_r3_dr_m5','sourceTheta75_deg', ...
        'anchoredTwistRMS_vsDirect_deg', ...
        'anchoredTwistR2WeightedRMS_vsDirect_deg', ...
        'anchoredTwistMaxAbs_vsDirect_deg'});
    geomRows = [geomRows;one]; %#ok<AGROW>
end
writetable(geomRows,fullfile(outputDir,'M1_GEOMETRY_SOURCE_GEOMETRY_METRICS.csv'));

%% Same M1-A solver for all source interpretations
pointRows = table();
for ic = 1:numel(caseId)
    for k = 1:numel(collective75_deg)
        P = Ptemplate;
        Vtip_mps = Vtip_fps(k)*0.3048;
        P.rotor.Omega = Vtip_mps/R;
        out = solve_scalar_geometry_hover(P,collective75_deg(k), ...
            caseId{ic},scalarC81);
        A = pi*R^2;
        [CT,CP,FM] = nondim(out,P,A,Vtip_mps);
        one = table(caseId(ic),collective75_deg(k),Vtip_fps(k), ...
            CT_exp(k),CP_exp(k),FM_exp(k),CT,CP,FM, ...
            100*(CT-CT_exp(k))/CT_exp(k), ...
            100*(CP-CP_exp(k))/CP_exp(k), ...
            100*(FM-FM_exp(k))/FM_exp(k), ...
            out.physicalConverged,out.inducedVelocity,out.zFlap(1), ...
            out.zFlap(2),out.zFlap(3),out.closureResidualRelative, ...
            'VariableNames',{'caseId','collective75_deg','Vtip_fps', ...
            'CT_exp','CP_exp','FM_exp','CT_model','CP_model','FM_model', ...
            'CT_relativeError_pct','CP_relativeError_pct','FM_relativeError_pct', ...
            'physicalConverged','inducedVelocity_mps','beta0_rad', ...
            'beta1c_rad','beta1s_rad','closureResidualRelative'});
        pointRows = [pointRows;one]; %#ok<AGROW>
    end
end
writetable(pointRows,fullfile(outputDir,'M1_GEOMETRY_SOURCE_POINTS.csv'));

metricRows = table();
for ic = 1:numel(caseId)
    mask = strcmp(pointRows.caseId,caseId{ic});
    if sum(pointRows.physicalConverged(mask)) ~= 6
        error('run_m1_geometry_source_fidelity_audit:IncompleteCase', ...
            '%s does not have 6/6 physically converged points.',caseId{ic});
    end
    one = table(caseId(ic),6, ...
        mean(abs(pointRows.CT_relativeError_pct(mask))), ...
        mean(abs(pointRows.CP_relativeError_pct(mask))), ...
        mean(abs(pointRows.FM_relativeError_pct(mask))), ...
        mean(pointRows.CT_model(mask)),mean(pointRows.CP_model(mask)), ...
        mean(pointRows.FM_model(mask)), ...
        'VariableNames',{'caseId','supportedPointCount','CT_MAPE_pct', ...
        'CP_MAPE_pct','FM_MAPE_pct','mean_CT_model','mean_CP_model','mean_FM_model'});
    metricRows = [metricRows;one]; %#ok<AGROW>
end

%% Fail-closed identity check against the already formal Stage-1 solver
canonical = run_xv15_actual_geometry_c81_crosscheck( ...
    fullfile(outputDir,'canonical_stage1_recheck'));
refMask = strcmp(cellstr(string(canonical.metrics.window)),'6-11');
if sum(refMask) ~= 1
    error('run_m1_geometry_source_fidelity_audit:CanonicalWindow', ...
        'Expected one canonical 6-11 metric row.');
end
currentMask = strcmp(metricRows.caseId,'CURRENT_RECONSTRUCTION');
currentMetric = [metricRows.CT_MAPE_pct(currentMask), ...
    metricRows.CP_MAPE_pct(currentMask),metricRows.FM_MAPE_pct(currentMask)];
canonicalMetric = [ ...
    canonical.metrics.CT_MAPE_scalarC81_global_pct(refMask), ...
    canonical.metrics.CP_MAPE_scalarC81_global_pct(refMask), ...
    canonical.metrics.FM_MAPE_scalarC81_global_pct(refMask)];
identityDiff_pp = abs(currentMetric-canonicalMetric);
if any(identityDiff_pp > 1e-6)
    error('run_m1_geometry_source_fidelity_audit:BaselineDrift', ...
        'Copied current M1-A branch drifted from canonical Stage-1 solver.');
end

% DIAG_SECTION is a frozen Stage-1 comparison reference. It is not used to
% define any geometry case and is not an optimization objective.
diagSection = [42.8716,51.1184,12.2221];
metricRows.CT_delta_vs_DIAG_SECTION_pp = metricRows.CT_MAPE_pct-diagSection(1);
metricRows.CP_delta_vs_DIAG_SECTION_pp = metricRows.CP_MAPE_pct-diagSection(2);
metricRows.FM_delta_vs_DIAG_SECTION_pp = metricRows.FM_MAPE_pct-diagSection(3);
metricRows.CT_delta_vs_CURRENT_pp = metricRows.CT_MAPE_pct-currentMetric(1);
metricRows.CP_delta_vs_CURRENT_pp = metricRows.CP_MAPE_pct-currentMetric(2);
metricRows.FM_delta_vs_CURRENT_pp = metricRows.FM_MAPE_pct-currentMetric(3);
writetable(metricRows,fullfile(outputDir,'M1_GEOMETRY_SOURCE_METRICS.csv'));

%% Robustness decision; no best-case selection
allImproveCTvsDiag = all(metricRows.CT_delta_vs_DIAG_SECTION_pp < 0);
allImproveCPvsDiag = all(metricRows.CP_delta_vs_DIAG_SECTION_pp < 0);
allImproveFMvsDiag = all(metricRows.FM_delta_vs_DIAG_SECTION_pp < 0);
CTspread_pp = max(metricRows.CT_MAPE_pct)-min(metricRows.CT_MAPE_pct);
CPspread_pp = max(metricRows.CP_MAPE_pct)-min(metricRows.CP_MAPE_pct);
FMspread_pp = max(metricRows.FM_MAPE_pct)-min(metricRows.FM_MAPE_pct);

if allImproveCTvsDiag && allImproveCPvsDiag
    decision = 'ROBUST_DIRECTION_GEOMETRY_CONTRIBUTION_SURVIVES_SOURCE_SEMANTICS_AUDIT';
else
    decision = 'GEOMETRY_CAUSAL_ATTRIBUTION_NOT_ROBUST_DOWNGRADE_TO_GEOMETRY_SENSITIVE_DIAGNOSTIC';
end

decisionTable = table({decision},allImproveCTvsDiag,allImproveCPvsDiag, ...
    allImproveFMvsDiag,CTspread_pp,CPspread_pp,FMspread_pp, ...
    max(identityDiff_pp), ...
    'VariableNames',{'decision','allCasesImproveCTvsDiagSection', ...
    'allCasesImproveCPvsDiagSection','allCasesImproveFMvsDiagSection', ...
    'CT_MAPE_sourceSpread_pp','CP_MAPE_sourceSpread_pp', ...
    'FM_MAPE_sourceSpread_pp','currentM1AIdentityMaxDelta_pp'});
writetable(decisionTable,fullfile(outputDir,'M1_GEOMETRY_SOURCE_DECISION.csv'));

metadataName = { ...
    'stage'; ...
    'source_primary'; ...
    'tp_text_planform'; ...
    'tp_appendix_a_chord'; ...
    'tp_appendix_a_twista'; ...
    'oarf_role'; ...
    'selection_rule'; ...
    'solver_identity'; ...
    'canonical_identity_tolerance_pp'; ...
    'claim_boundary'};
metadataValue = { ...
    'M1_GEOMETRY_SOURCE_FIDELITY_AUDIT'; ...
    'NASA_TP_2004_212262'; ...
    '17IN_AT_0P12R_LINEAR_TO_14IN_AT_0P25R_THEN_CONSTANT'; ...
    'RPROP_0_0P1_0P2_0P3_1_CHORD_FT_1P32125_1P32125_1P17375_1P16625_1P16625'; ...
    '51_STATIONS_RPROP_0_TO_1_STEP_0P02_DIRECT_TWISTA'; ...
    'DEVELOPMENT_EXTERNAL_CORRELATION_COMPARISON_ONLY'; ...
    'NO_OARF_WADC_BASED_GEOMETRY_SELECTION'; ...
    'M1A_SCALAR_C81_GLOBAL_MOMENTUM_EQ12_FLAP_COUPLED'; ...
    '1e-6'; ...
    'SOURCE_FIDELITY_SENSITIVITY_NOT_EXACT_XV15_GEOMETRY_VALIDATION'};
metadataTable = table(metadataName,metadataValue);
writetable(metadataTable,fullfile(outputDir,'M1_GEOMETRY_SOURCE_METADATA.csv'));

results = struct();
results.caseTable = caseTable;
results.profile = profile;
results.geometryMetrics = geomRows;
results.pointTable = pointRows;
results.metricTable = metricRows;
results.decisionTable = decisionTable;
results.identityDiff_pp = identityDiff_pp;
results.metadataTable = metadataTable;
results.claimBoundary = metadataValue{end};
save(fullfile(outputDir,'M1_GEOMETRY_SOURCE_RESULTS.mat'),'results');
end

function out = solve_scalar_geometry_hover(P,theta75_deg,caseId,scalarC81)
R = P.rotor.R;
Omega = P.rotor.Omega;
tipSpeed = Omega*R;
rho = P.env.rho;
A = pi*R^2;
r0 = P.rotor.rootCut*R;
rEdges = linspace(r0,R,P.rotor.nRadial+1);
rMid = 0.5*(rEdges(1:end-1)+rEdges(2:end));
dr = diff(rEdges);
psi = ((0:P.rotor.nAzimuth-1)*(2*pi/P.rotor.nAzimuth)).';
x = rMid/R;
[chord_m,thetaSource_deg] = geometry_profile(x,caseId);
theta75Source_deg = geometry_twist_75(caseId);
thetaBlade = (theta75_deg+thetaSource_deg-theta75Source_deg)*pi/180;
UT = Omega*rMid;

vi = sqrt(max(P.mass.m*P.env.g/2,1)/(2*rho*A));
zFlap = P.rotor.flapInitial(:);
if numel(zFlap) ~= 3
    error('P.rotor.flapInitial must contain [beta0; beta1c; beta1s].');
end

converged = false;
flapInfo = struct('converged',false,'iterations',0,'residualNorm',Inf);
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
closureResidualRelative = abs(loads.T-momentumThrust)/ ...
    max([abs(loads.T),abs(momentumThrust),1]);
physical = converged && flapInfo.converged && loads.T > 0 && ...
    closureResidualRelative <= 2.0e-4;

out.thrust = loads.T;
out.torque = loads.Q;
out.inducedVelocity = vi;
out.zFlap = zFlap;
out.flap = flapInfo;
out.physicalConverged = physical;
out.closureResidualRelative = closureResidualRelative;

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
        CL = scalarC81.CLmax*tanh( ...
            scalarC81.liftSlope*(alpha-scalarC81.alpha0L_rad)/scalarC81.CLmax);
        CD = scalarC81.CD0+scalarC81.kCD*CL.^2;
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
    end
end

function [chord_m,twist_deg] = geometry_profile(x,caseId)
caseId = upper(char(caseId));
switch caseId
    case 'CURRENT_RECONSTRUCTION'
        chord_m = current_chord(x);
        twist_deg = current_twist(x);
    case 'CURRENT_CHORD_DIRECT_TWISTA'
        chord_m = current_chord(x);
        twist_deg = direct_twista(x);
    case 'TP_TEXT_CHORD_DIRECT_TWISTA'
        chord_m = tp_text_chord(x);
        twist_deg = direct_twista(x);
    case 'TP_APPENDIX_A_CAMRAD_DIRECT_TWISTA'
        chord_m = tp_appendix_a_chord(x);
        twist_deg = direct_twista(x);
    otherwise
        error('run_m1_geometry_source_fidelity_audit:UnknownCase', ...
            'Unknown geometry case %s.',caseId);
end
end

function theta75 = geometry_twist_75(caseId)
if strcmpi(caseId,'CURRENT_RECONSTRUCTION')
    theta75 = current_twist(0.75);
else
    theta75 = direct_twista(0.75);
end
end

function chord_m = current_chord(x)
% Exact current Stage-1 algebra retained for fail-closed identity.
chord_in = 14*ones(size(x));
mask = x <= 0.25;
chord_in(mask) = -18.4615*x(mask)+18.6154;
chord_m = chord_in*0.0254;
end

function chord_m = tp_text_chord(x)
chord_in = 14*ones(size(x));
maskRoot = x <= 0.12;
maskTaper = x > 0.12 & x < 0.25;
chord_in(maskRoot) = 17;
chord_in(maskTaper) = 17+(14-17)*(x(maskTaper)-0.12)/(0.25-0.12);
chord_m = chord_in*0.0254;
end

function chord_m = tp_appendix_a_chord(x)
rprop = [0 0.1 0.2 0.3 1.0];
chord_ft = [1.32125 1.32125 1.17375 1.16625 1.16625];
originalSize = size(x);
chord_m = reshape(interp1(rprop,chord_ft,x(:),'linear')*0.3048,originalSize);
end

function theta_deg = current_twist(x)
theta_deg = 289.98*x.^5-892.87*x.^4+987.06*x.^3 ...
    -438.31*x.^2+15.695*x+32.057;
end

function theta_deg = direct_twista(x)
rprop = 0:0.02:1.0;
twista = [34.43 33.49 32.45 31.55 30.79 30.03 29.03 28.03 26.88 ...
    25.58 24.28 23.03 21.78 20.43 18.98 17.53 16.48 15.43 ...
    14.20 12.79 11.38 10.64 9.9 9.03 8.03 7.03 6.43 5.83 ...
    5.19 4.51 3.83 3.31 2.79 2.3 1.84 1.38 0.83 0.27 ...
    -0.27 -0.82 -1.37 -1.86 -2.35 -2.82 -3.27 -3.72 -4.14 ...
    -4.56 -4.98 -5.4 -5.82];
if numel(rprop) ~= numel(twista)
    error('run_m1_geometry_source_fidelity_audit:TwistaLength', ...
        'Appendix-A RPROP/TWISTA lengths do not match.');
end
originalSize = size(x);
theta_deg = reshape(interp1(rprop,twista,x(:),'linear'),originalSize);
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
