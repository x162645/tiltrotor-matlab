function results = run_m1_stage3b_large_angle_local_closure(outputDir)
%RUN_M1_STAGE3B_LARGE_ANGLE_LOCAL_CLOSURE
% Low-cost falsification experiment for a Stahlhut-inspired local inflow
% closure inside the existing component-level rotor methodology.
%
% Scientific control:
%   - frozen M0 is untouched;
%   - production rotor_model_bemt is untouched;
%   - geometry = same source-informed XV-15 metal-blade radial geometry;
%   - section aero = same four-region C81/local-Mach + Corrigan n=1 bundle;
%   - OARF Run 15 values are comparison targets only, never solver inputs;
%   - only the steady axial induced-flow closure is replaced.
%
% The current branch is analysis-only because the published Stahlhut
% equation is explicitly axial-flow. Promotion to the generic production
% rotor is forbidden until this diagnostic is understood and a forward-
% flight extension has an independent physical basis.

rootDir = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1 || isempty(outputDir)
    outputDir = fullfile(rootDir,'results','m1_stage3b_large_angle_local_closure');
end
if ~exist(outputDir,'dir'), mkdir(outputDir); end

% Re-use the already frozen M1-E runner as the component-level control.
legacy = run_m1_stage3_corrigan_stall_delay(fullfile(outputDir,'legacy_m1e_recheck'));
legacyMode = strcmp(legacy.metrics.mode,'CORRIGAN_GENERIC_N1');
if sum(legacyMode) ~= 1
    error('run_m1_stage3b_large_angle_local_closure:LegacyIdentity', ...
        'Could not recover unique frozen Corrigan n=1 control.');
end
legacyMetric = legacy.metrics(legacyMode,:);

P = params_nominal();
R = 3.81;
rootCut = 0.0875;
collective75_deg = [6;7;8;9;10;11];
Vtip_fps = [768.4;768.4;768.4;768.0;768.0;767.7];
CT_exp = [0.009208;0.010104;0.011063;0.012035;0.013089;0.013929];
CP_exp = [0.000796;0.000913;0.001044;0.001188;0.001358;0.001523];
FM_exp = [0.7849;0.7866;0.7881;0.7858;0.7797;0.7632];

P.rotor.R = R; P.rotor.Nb = 3; P.rotor.rootCut = rootCut;
if ~isfield(P.env,'aSound'), P.env.aSound = 340.0; end

rows = table(); radialRows = table();
for k = 1:numel(collective75_deg)
    Vtip_mps = Vtip_fps(k)*0.3048;
    Omega = Vtip_mps/R;
    r0 = rootCut*R;
    rEdges = linspace(r0,R,P.rotor.nRadial+1);
    y = 0.5*(rEdges(1:end-1)+rEdges(2:end));
    dr = diff(rEdges);
    x = y/R;

    chord_in = 14*ones(size(x));
    inboard = x <= 0.25;
    chord_in(inboard) = -18.4615*x(inboard)+18.6154;
    chord_m = chord_in*0.0254;
    twist = nasa_metal_twist_deg(x);
    twist75 = nasa_metal_twist_deg(0.75);
    theta = (collective75_deg(k)+twist-twist75)*pi/180;

    S = struct();
    S.rRatio=x; S.y_m=y; S.dr_m=dr; S.chord_m=chord_m;
    S.theta_rad=theta; S.R_m=R; S.Omega_radps=Omega; S.Nb=3;
    S.rho_kgm3=P.env.rho; S.aSound_mps=P.env.aSound; S.Vinf_mps=0;

    aeroFcn = @(a,M,rr,cc) aero_corrigan_n1(a,M,rr,cc,R);
    la = rotor_inflow_closure_large_angle_local(S,aeroFcn,struct());

    A = pi*R^2;
    CT = la.thrust_N/(P.env.rho*A*Vtip_mps^2);
    CP = la.torque_Nm*Omega/(P.env.rho*A*Vtip_mps^3);
    if CT > 0 && CP > 0, FM = CT^(3/2)/(sqrt(2)*CP); else, FM=NaN; end

    one = table(collective75_deg(k),Vtip_fps(k),CT_exp(k),CT, ...
        100*(CT-CT_exp(k))/CT_exp(k),CP_exp(k),CP, ...
        100*(CP-CP_exp(k))/CP_exp(k),FM_exp(k),FM, ...
        100*(FM-FM_exp(k))/FM_exp(k),la.allSectionsConverged, ...
        la.maxAbsRootResidual,min(la.F),max(la.F), ...
        min(la.phi_rad)*180/pi,max(la.phi_rad)*180/pi, ...
        'VariableNames',{'collective75_deg','Vtip_fps','CT_exp','CT_model', ...
        'CT_relativeError_pct','CP_exp','CP_model','CP_relativeError_pct', ...
        'FM_exp','FM_model','FM_relativeError_pct','physicalConverged', ...
        'maxAbsRootResidual','F_min','F_max','phiMin_deg','phiMax_deg'});
    rows=[rows;one]; %#ok<AGROW>

    n = numel(x);
    rr = table(repmat(collective75_deg(k),n,1),x(:),chord_m(:), ...
        theta(:)*180/pi,la.phi_rad(:)*180/pi,la.alpha_rad(:)*180/pi, ...
        la.U_mps(:),la.vi_mps(:),la.swirl_mps(:),la.CL(:),la.CD(:), ...
        la.Mach(:),la.F(:),la.KT(:),la.KP(:),la.dT_N(:),la.dQ_Nm(:), ...
        string(la.status(:)), ...
        'VariableNames',{'collective75_deg','r_R','chord_m','theta_deg', ...
        'phi_deg','alpha_deg','U_mps','vi_mps','swirl_mps','CL','CD','Mach', ...
        'F','KT','KP','dT_N','dQ_Nm','solveStatus'});
    radialRows=[radialRows;rr]; %#ok<AGROW>
end

writetable(rows,fullfile(outputDir,'M1_STAGE3B_LARGE_ANGLE_POINTS.csv'));
writetable(radialRows,fullfile(outputDir,'M1_STAGE3B_LARGE_ANGLE_RADIAL.csv'));

mask = rows.physicalConverged;
if ~all(mask)
    warning('run_m1_stage3b_large_angle_local_closure:IncompleteSupport', ...
        '%d of %d OARF points have all radial sections converged.',sum(mask),height(rows));
end
metrics = table();
metrics.mode = {'M1_E_FROZEN_CORRIGAN_N1';'M1_G_LARGE_ANGLE_LOCAL_CLOSURE'};
metrics.role = {'FROZEN_COMPONENT_LEVEL_CONTROL';'ANALYSIS_ONLY_MODEL_FORM_TEST'};
metrics.supportedPointCount = [legacyMetric.supportedPointCount;sum(mask)];
metrics.CT_MAPE_pct = [legacyMetric.CT_MAPE_pct;mean(abs(rows.CT_relativeError_pct(mask)))];
metrics.CP_MAPE_pct = [legacyMetric.CP_MAPE_pct;mean(abs(rows.CP_relativeError_pct(mask)))];
metrics.FM_MAPE_pct = [legacyMetric.FM_MAPE_pct;mean(abs(rows.FM_relativeError_pct(mask)))];
metrics.CT_meanSigned_pct = [legacyMetric.CT_meanSigned_pct;mean(rows.CT_relativeError_pct(mask))];
metrics.CP_meanSigned_pct = [legacyMetric.CP_meanSigned_pct;mean(rows.CP_relativeError_pct(mask))];
metrics.FM_meanSigned_pct = [legacyMetric.FM_meanSigned_pct;mean(rows.FM_relativeError_pct(mask))];
metrics.CT_deltaFromFrozenM1E_pp = metrics.CT_MAPE_pct-metrics.CT_MAPE_pct(1);
metrics.CP_deltaFromFrozenM1E_pp = metrics.CP_MAPE_pct-metrics.CP_MAPE_pct(1);
metrics.FM_deltaFromFrozenM1E_pp = metrics.FM_MAPE_pct-metrics.FM_MAPE_pct(1);
writetable(metrics,fullfile(outputDir,'M1_STAGE3B_LARGE_ANGLE_METRICS.csv'));

metadataName = {'model_identity';'base_control';'closure_change';'geometry'; ...
    'section_aero';'rotational_correction';'validation_dataset_role'; ...
    'target_parameter_fit';'flow_domain';'production_model_modified'; ...
    'interpretation_rule'};
metadataValue = {'M1_G_LARGE_ANGLE_LOCAL_CLOSURE_DIAGNOSTIC'; ...
    'M1_E_FROZEN_CORRIGAN_N1'; ...
    'STAHLHUT_INSPIRED_NONLINEAR_LOCAL_INFLOW_WITH_KT_KP_AND_SWIRL'; ...
    'SOURCE_INFORMED_XV15_METAL_RADIAL_CHORD_NONLINEAR_TWIST'; ...
    'NASA_TP_FOUR_REGION_C81_LOCAL_MACH';'CORRIGAN_GENERIC_N1_FROZEN'; ...
    'OARF_RUN15_DEVELOPMENT_EXTERNAL_CORRELATION';'NO'; ...
    'STEADY_AXIAL_HOVER_ONLY';'NO'; ...
    'REPORT_RESULT_EVEN_IF_WORSE_DO_NOT_TUNE_TO_OARF'};
writetable(table(metadataName,metadataValue), ...
    fullfile(outputDir,'M1_STAGE3B_LARGE_ANGLE_METADATA.csv'));

results=struct('points',rows,'radial',radialRows,'metrics',metrics, ...
    'legacy',legacy,'claimBoundary', ...
    'ANALYSIS_ONLY_LARGE_ANGLE_LOCAL_CLOSURE_NO_OARF_FIT_NO_PRODUCTION_CHANGE');
save(fullfile(outputDir,'M1_STAGE3B_LARGE_ANGLE_RESULTS.mat'),'results');
end

function [CL,CD,meta]=aero_corrigan_n1(alpha,Mach,rRatio,chord_m,R)
[CL,CD,meta]=xv15_c81_corrigan_stall_delay(alpha,Mach,rRatio,chord_m,R, ...
    'CORRIGAN_GENERIC_N1');
end
