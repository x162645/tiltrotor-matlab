function results = run_xv15_v1_run14_external_validation(outputDir)
%RUN_XV15_V1_RUN14_EXTERNAL_VALIDATION Frozen-M0 OARF Run 14 validation.
%
% Purpose
% -------
% Execute a run-level external validation of the already-frozen production
% rotor model M0 against XV-15 original-metal-blade OARF Run 14.  Run 14 was
% not used in the earlier model-diagnostic chain.  The analyst has seen the
% source data during the present evidence audit, so this data set is NOT
% called blind.  No model/parameter change after viewing Run 14 targets is
% permitted in this runner.
%
% Model boundary
% --------------
% - production rotor entry: rotor_model_bemt;
% - same program-aware geometry/control reduction used by the frozen Run 15
%   pure-M0 baseline;
% - generic production section-aero fields are retained;
% - no alpha0L/section-aero wrapper/compressibility/Prandtl/Mangler/wake
%   extension is permitted;
% - no validation-target parameter fitting.
%
% Source
% ------
% NASA CR-2017-219486 Appendix A, Table A-2, XV-15 metal-blade proprotor
% OARF Run 14.  Table A-2 defines the collective column at 3/4 radius.

rootDir = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1 || isempty(outputDir)
    outputDir = fullfile(rootDir, 'results', ...
        'xv15_validation_baseline', 'v1_run14_external_validation');
end
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

% Fail closed if the historical direct-M0 calculation path has drifted.
auditTable = audit_xv15_v1_baseline_model_identity(outputDir);

Pbase = params_nominal();
d2r = pi/180;
R = 3.81;
rootCut = 0.0875;

modelIdentity = 'M0_PRODUCTION_LOW_ORDER';
datasetRole = 'PREVIOUSLY_UNUSED_RUN_LEVEL_EXTERNAL_VALIDATION';
datasetIndependence = ['SAME_OARF_CAMPAIGN_NOT_USED_IN_PRIOR_MODEL_' ...
    'DIAGNOSTICS_ANALYST_HAS_SEEN_DATA_NO_TUNING'];
claimBoundary = ['FROZEN_M0_RUN14_EXTERNAL_VALIDATION_NO_POST_AUDIT_' ...
    'PARAMETER_OR_MODEL_CHANGE'];
reportWindow = 'PREDECLARED_6_TO_11_DEG';

%% NASA OARF Run 14, Appendix A Table A-2
pointId = {'RUN14_POINT15'; 'RUN14_POINT16'; 'RUN14_POINT17'; ...
    'RUN14_POINT18'; 'RUN14_POINT19'; 'RUN14_POINT20'; ...
    'RUN14_POINT21'; 'RUN14_POINT22'; 'RUN14_POINT23'; ...
    'RUN14_POINT24'; 'RUN14_POINT25'; 'RUN14_POINT26'; ...
    'RUN14_POINT27'};
collective75_deg = [-7; -5; -3; -1; 1; 3; 5; 6; 7; 8; 9; 10; 11];
Vtip_fps = [769.4; 769.4; 769.4; 769.4; 769.4; 769.0; 769.0; ...
    768.7; 768.7; 768.4; 768.4; 768.0; 767.7];
CT_exp = [-0.000027; 0.001344; 0.002319; 0.003320; 0.004732; ...
    0.006405; 0.008148; 0.009022; 0.010095; 0.010960; ...
    0.011985; 0.013014; 0.013978];
CP_exp = [0.000241; 0.000185; 0.000214; 0.000277; 0.000382; ...
    0.000521; 0.000703; 0.000815; 0.000942; 0.001076; ...
    0.001242; 0.001427; 0.001615];
FM_exp = [0.0004; 0.1883; 0.3690; 0.4883; 0.6025; 0.6957; ...
    0.7398; 0.7435; 0.7614; 0.7540; 0.7470; 0.7357; 0.7236];

%% Freeze the same low-order XV-15 geometry mapping as the Run 15 baseline.
xGeom = linspace(rootCut, 1, 4001).';
chord_in = 14*ones(size(xGeom));
inboard = xGeom <= 0.25;
chord_in(inboard) = -18.4615*xGeom(inboard) + 18.6154;
chordEq_m = trapz(xGeom, chord_in)/(1-rootCut)*0.0254;

thetaSource_deg = nasa_metal_twist_deg(xGeom);
theta75Source_deg = nasa_metal_twist_deg(0.75);
xNorm = (xGeom-rootCut)/(1-rootCut);
x75 = (0.75-rootCut)/(1-rootCut);
shapeCoordinate = xNorm-x75;
shapeTarget = thetaSource_deg-theta75Source_deg;
twistTipEq_deg = trapz(xGeom, shapeCoordinate.*shapeTarget) / ...
    trapz(xGeom, shapeCoordinate.^2);
twistFit_deg = theta75Source_deg + twistTipEq_deg*shapeCoordinate;
twistRms_deg = sqrt(trapz(xGeom, (thetaSource_deg-twistFit_deg).^2) / ...
    (1-rootCut));
twistMaxAbs_deg = max(abs(thetaSource_deg-twistFit_deg));

Ptemplate = Pbase;
Ptemplate.rotor.R = R;
Ptemplate.rotor.Nb = 3;
Ptemplate.rotor.rootCut = rootCut;
Ptemplate.rotor.chord = chordEq_m;
Ptemplate.rotor.twistTip = twistTipEq_deg*d2r;
% Preserve the generic uniform blade-mass assumption exactly as in Run 15.
Ptemplate.rotor.Ib = Ptemplate.rotor.bladeMass*R^2/3;
Ptemplate.rotor.Sblade = Ptemplate.rotor.bladeMass*R/2;

%% Predict all Run 14 points without target-dependent model changes.
n = numel(collective75_deg);
rows = repmat(empty_row(), n, 1);
for k = 1:n
    P = Ptemplate;
    Vtip_mps = Vtip_fps(k)*0.3048;
    P.rotor.Omega = Vtip_mps/R;
    modelCollective_deg = collective75_deg(k)-twistTipEq_deg*x75;
    ctrl = struct('collective', modelCollective_deg*d2r, 'cyclicLong', 0);

    rows(k).pointId = pointId{k};
    rows(k).collective75_deg = collective75_deg(k);
    rows(k).Vtip_fps = Vtip_fps(k);
    rows(k).rpm = P.rotor.Omega*60/(2*pi);
    rows(k).modelCollective_deg = modelCollective_deg;
    rows(k).CT_exp = CT_exp(k);
    rows(k).CP_exp = CP_exp(k);
    rows(k).FM_exp = FM_exp(k);

    try
        [~, ~, out] = rotor_model_bemt(zeros(9,1), ctrl, 0, -1, zeros(3,1), P);
        rows(k).returned = true;
        rows(k).physicalStatus = out.physicalStatus;
        rows(k).numericalConverged = out.numericalConverged;
        rows(k).physicalConverged = out.physicalConverged;
        rows(k).iterations = out.iterations;
        rows(k).inducedVelocity_mps = out.inducedVelocity;
        rows(k).closureResidualRelative = out.inducedClosureResidualRelative;
        rows(k).thrust_N = out.thrust;
        rows(k).torque_Nm = out.torque;

        A = pi*R^2;
        rows(k).CT_model = out.thrust/(P.env.rho*A*Vtip_mps^2);
        rows(k).CP_model = out.torque*P.rotor.Omega/( ...
            P.env.rho*A*Vtip_mps^3);
        if rows(k).CT_model > 0 && rows(k).CP_model > 0
            rows(k).FM_model = rows(k).CT_model^(3/2)/( ...
                sqrt(2)*rows(k).CP_model);
        end

        if CT_exp(k) ~= 0
            rows(k).CT_relativeError_pct = 100*(rows(k).CT_model-CT_exp(k))/ ...
                abs(CT_exp(k));
        end
        if CP_exp(k) ~= 0
            rows(k).CP_relativeError_pct = 100*(rows(k).CP_model-CP_exp(k))/ ...
                abs(CP_exp(k));
        end
        if isfinite(rows(k).FM_model) && FM_exp(k) ~= 0
            rows(k).FM_relativeError_pct = 100*(rows(k).FM_model-FM_exp(k))/ ...
                abs(FM_exp(k));
        end
    catch ME
        rows(k).physicalStatus = ME.identifier;
        rows(k).errorIdentifier = ME.identifier;
        rows(k).errorMessage = ME.message;
    end
end

T = struct2table(rows);
T.modelIdentity = repmat({modelIdentity}, n, 1);
T.computationPath = repmat({'DIRECT_ROTOR_MODEL_BEMT'}, n, 1);
T.datasetRole = repmat({datasetRole}, n, 1);
T.datasetIndependence = repmat({datasetIndependence}, n, 1);
T.claimBoundary = repmat({claimBoundary}, n, 1);
T.reportMembership = repmat({'OUTSIDE_PREDECLARED_WINDOW'}, n, 1);
fixedWindow = ismember(T.collective75_deg, [6; 7; 8; 9; 10; 11]);
T.reportMembership(fixedWindow) = repmat({reportWindow}, sum(fixedWindow), 1);
writetable(T, fullfile(outputDir, 'XV15_V1_RUN14_M0_POINTS.csv'));

%% Predeclared 6--11 deg score plus all physically supported positive-target points.
allPositiveTargets = CT_exp > 0 & CP_exp > 0 & FM_exp > 0;
metricsAll = build_window_metrics(T, allPositiveTargets, ...
    'ALL_POSITIVE_TARGET_POINTS');
metricsFixed = build_window_metrics(T, fixedWindow, reportWindow);
metricTable = [metricsAll; metricsFixed];
metricTable.modelIdentity = repmat({modelIdentity}, height(metricTable), 1);
metricTable.datasetRole = repmat({datasetRole}, height(metricTable), 1);
metricTable.datasetIndependence = repmat({datasetIndependence}, ...
    height(metricTable), 1);
metricTable.claimBoundary = repmat({claimBoundary}, height(metricTable), 1);
writetable(metricTable, fullfile(outputDir, 'XV15_V1_RUN14_M0_METRICS.csv'));

mappingName = {'R_m'; 'rootCut'; 'chordEq_m'; 'twistTipEq_deg'; ...
    'theta75Source_deg'; 'twistRms_deg'; 'twistMaxAbs_deg'; ...
    'generic_liftSlope_1_per_rad'; 'generic_CLmax'; ...
    'generic_CD0'; 'generic_kCD'};
mappingValue = [R; rootCut; chordEq_m; twistTipEq_deg; ...
    theta75Source_deg; twistRms_deg; twistMaxAbs_deg; ...
    Pbase.rotor.liftSlope; Pbase.rotor.CLmax; Pbase.rotor.CD0; ...
    Pbase.rotor.kCD];
mappingTable = table(mappingName, mappingValue);
writetable(mappingTable, fullfile(outputDir, ...
    'XV15_V1_RUN14_M0_MAPPING.csv'));

metadataName = {'model_identity'; 'dataset_role'; 'dataset_independence'; ...
    'source'; 'collective_reference'; 'primary_report_window'; ...
    'validation_target_parameter_fit'; 'model_change_after_target_audit'; ...
    'same_campaign_as_run15'; 'blind_claim'};
metadataValue = {modelIdentity; datasetRole; datasetIndependence; ...
    'NASA_CR_2017_219486_APPENDIX_A_TABLE_A2_OARF_RUN14'; ...
    'THREE_QUARTER_RADIUS'; reportWindow; 'NO'; 'NO'; 'YES'; 'NO'};
metadataTable = table(metadataName, metadataValue);
writetable(metadataTable, fullfile(outputDir, ...
    'XV15_V1_RUN14_M0_METADATA.csv'));

results = struct();
results.validationTable = T;
results.metricTable = metricTable;
results.mappingTable = mappingTable;
results.metadataTable = metadataTable;
results.auditTable = auditTable;
results.modelIdentity = modelIdentity;
results.datasetRole = datasetRole;
results.datasetIndependence = datasetIndependence;
results.reportWindow = reportWindow;
results.claimBoundary = claimBoundary;
save(fullfile(outputDir, 'XV15_V1_RUN14_M0_RESULTS.mat'), 'results');
end

function metricTable = build_window_metrics(T, candidateMask, windowName)
quantities = {'CT'; 'CP'; 'FM'};
modelFields = {'CT_model'; 'CP_model'; 'FM_model'};
testFields = {'CT_exp'; 'CP_exp'; 'FM_exp'};
window = cell(3,1);
quantity = cell(3,1);
expectedPointCount = zeros(3,1);
validPointCount = zeros(3,1);
MAE = NaN(3,1);
RMSE = NaN(3,1);
MAPE_pct = NaN(3,1);
meanSignedError_pct = NaN(3,1);
maxAbsRelativeError_pct = NaN(3,1);
for k = 1:3
    model = T.(modelFields{k});
    experiment = T.(testFields{k});
    valid = candidateMask & T.physicalConverged & isfinite(model) & ...
        isfinite(experiment) & experiment ~= 0;
    window{k} = windowName;
    quantity{k} = quantities{k};
    expectedPointCount(k) = sum(candidateMask);
    validPointCount(k) = sum(valid);
    if any(valid)
        err = model(valid)-experiment(valid);
        relPct = 100*err./abs(experiment(valid));
        MAE(k) = mean(abs(err));
        RMSE(k) = sqrt(mean(err.^2));
        MAPE_pct(k) = mean(abs(relPct));
        meanSignedError_pct(k) = mean(relPct);
        maxAbsRelativeError_pct(k) = max(abs(relPct));
    end
end
metricTable = table(window, quantity, expectedPointCount, validPointCount, ...
    MAE, RMSE, MAPE_pct, meanSignedError_pct, maxAbsRelativeError_pct);
end

function theta_deg = nasa_metal_twist_deg(x)
theta_deg = 289.98*x.^5 - 892.87*x.^4 + 987.06*x.^3 ...
    - 438.31*x.^2 + 15.695*x + 32.057;
end

function row = empty_row()
row = struct('pointId','','collective75_deg',NaN,'Vtip_fps',NaN, ...
    'rpm',NaN,'modelCollective_deg',NaN,'returned',false, ...
    'numericalConverged',false,'physicalConverged',false, ...
    'physicalStatus','NOT_RUN','errorIdentifier','','errorMessage','', ...
    'iterations',NaN,'inducedVelocity_mps',NaN, ...
    'closureResidualRelative',NaN,'thrust_N',NaN,'torque_Nm',NaN, ...
    'CT_exp',NaN,'CT_model',NaN,'CT_relativeError_pct',NaN, ...
    'CP_exp',NaN,'CP_model',NaN,'CP_relativeError_pct',NaN, ...
    'FM_exp',NaN,'FM_model',NaN,'FM_relativeError_pct',NaN);
end
