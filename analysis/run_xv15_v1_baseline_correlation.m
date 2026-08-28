function results = run_xv15_v1_baseline_correlation(outputDir)
%RUN_XV15_V1_BASELINE_CORRELATION Canonical pure-M0 XV-15 V1 entry.
%
% Research purpose:
%   Characterize the external-correlation error and applicability of the
%   frozen production low-order rotor model M0 against XV-15 original-metal-
%   blade OARF Run 15 data.  This function must not modify production physics
%   or use the observed CT/CP/FM errors to tune model parameters.
%
% Evidence boundary:
%   OARF Run 15 was used in prior diagnostics and is therefore a
%   DEVELOPMENT_EXTERNAL_CORRELATION data set, not a blind hold-out.
%
% Model boundary:
%   The numerical predictions are produced only by the historical pure-M0
%   runner run_xv15_metal_hover_validation, whose rotor call is guarded by
%   audit_xv15_v1_baseline_model_identity.  Known section-aero, Prandtl and
%   wake extensions are prohibited from this baseline path.

rootDir = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1 || isempty(outputDir)
    outputDir = fullfile(rootDir, 'results', ...
        'xv15_validation_baseline', 'v1_hover');
end
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

modelIdentity = 'M0_PRODUCTION_LOW_ORDER';
datasetRole = 'DEVELOPMENT_EXTERNAL_CORRELATION';
datasetIndependence = 'NOT_BLIND_USED_IN_PRIOR_DIAGNOSTICS';
claimBoundary = ['FROZEN_M0_EXTERNAL_CORRELATION_NOT_XV15_REPRODUCTION_' ...
    'NO_VALIDATION_TARGET_PARAMETER_FIT'];
reportWindow = 'FIXED_REPORT_WINDOW_6_TO_11_DEG';

%% 1. Fail closed if the M0 computation path has drifted.
auditTable = audit_xv15_v1_baseline_model_identity(outputDir);

%% 2. Run the already-existing direct-M0 calculation in an isolated folder.
% Historical artifacts retain their original labels for traceability; only
% the canonical artifacts written below may be used for the present study's
% evidence claims.
rawOutputDir = fullfile(outputDir, 'legacy_m0_runner_raw');
raw = run_xv15_metal_hover_validation(rawOutputDir);
T = raw.validationTable;

%% 3. Attach corrected evidence semantics without changing any prediction.
n = height(T);
T.modelIdentity = repmat({modelIdentity}, n, 1);
T.computationPath = repmat({'DIRECT_ROTOR_MODEL_BEMT'}, n, 1);
T.datasetRole = repmat({datasetRole}, n, 1);
T.datasetIndependence = repmat({datasetIndependence}, n, 1);
T.claimBoundary = repmat({claimBoundary}, n, 1);
T.reportMembership = repmat({'OUTSIDE_FIXED_REPORT_WINDOW'}, n, 1);
fixedWindow = ismember(T.collective75_deg, [6; 7; 8; 9; 10; 11]);
T.reportMembership(fixedWindow) = {reportWindow};

writetable(T, fullfile(outputDir, 'XV15_V1_M0_BASELINE_POINTS.csv'));

%% 4. Report both the complete point set and the inherited fixed 6--11 deg window.
% No point is deleted because of its error magnitude.  Quantity-specific
% valid masks require physical convergence and finite model/experimental
% values; unsupported points remain visible in the point table.
allPoints = true(height(T),1);
metricsAll = build_window_metrics(T, allPoints, 'ALL_REPORTED_POINTS');
metricsFixed = build_window_metrics(T, fixedWindow, reportWindow);
metricTable = [metricsAll; metricsFixed];
metricTable.modelIdentity = repmat({modelIdentity}, height(metricTable), 1);
metricTable.datasetRole = repmat({datasetRole}, height(metricTable), 1);
metricTable.datasetIndependence = repmat( ...
    {datasetIndependence}, height(metricTable), 1);
metricTable.claimBoundary = repmat({claimBoundary}, height(metricTable), 1);
writetable(metricTable, fullfile(outputDir, ...
    'XV15_V1_M0_BASELINE_METRICS.csv'));

%% 5. Preserve verification and mapping outputs without reinterpreting them.
convergenceTable = raw.convergenceTable;
mappingTable = raw.mappingTable;
writetable(convergenceTable, fullfile(outputDir, ...
    'XV15_V1_M0_NUMERICAL_CONVERGENCE.csv'));
writetable(mappingTable, fullfile(outputDir, ...
    'XV15_V1_M0_DERIVED_MAPPING.csv'));

metadataName = { ...
    'model_identity'; ...
    'canonical_runner'; ...
    'production_rotor_model'; ...
    'dataset_role'; ...
    'dataset_independence'; ...
    'report_window'; ...
    'claim_boundary'; ...
    'parameter_fit_to_validation_targets'; ...
    'section_aero_extension'; ...
    'prandtl_extension'; ...
    'prescribed_wake_extension'};
metadataValue = { ...
    modelIdentity; ...
    'analysis/run_xv15_v1_baseline_correlation.m'; ...
    'model/rotor_model_bemt.m'; ...
    datasetRole; ...
    datasetIndependence; ...
    reportWindow; ...
    claimBoundary; ...
    'NO'; ...
    'EXCLUDED'; ...
    'EXCLUDED'; ...
    'EXCLUDED'};
metadataTable = table(metadataName, metadataValue);
writetable(metadataTable, fullfile(outputDir, ...
    'XV15_V1_M0_BASELINE_METADATA.csv'));

results = struct();
results.validationTable = T;
results.metricTable = metricTable;
results.convergenceTable = convergenceTable;
results.mappingTable = mappingTable;
results.auditTable = auditTable;
results.metadataTable = metadataTable;
results.modelIdentity = modelIdentity;
results.datasetRole = datasetRole;
results.datasetIndependence = datasetIndependence;
results.reportWindow = reportWindow;
results.claimBoundary = claimBoundary;
results.rawRunnerDirectory = rawOutputDir;
save(fullfile(outputDir, 'XV15_V1_M0_BASELINE_RESULTS.mat'), 'results');
end

function metricTable = build_window_metrics(T, candidateMask, windowName)
quantities = {'CT'; 'CP'; 'FM'};
modelFields = {'CT_model'; 'CP_model'; 'FM_model'};
testFields = {'CT_exp'; 'CP_exp'; 'FM_exp'};

window = cell(numel(quantities),1);
quantity = cell(numel(quantities),1);
expectedPointCount = zeros(numel(quantities),1);
validPointCount = zeros(numel(quantities),1);
MAE = NaN(numel(quantities),1);
RMSE = NaN(numel(quantities),1);
MAPE_pct = NaN(numel(quantities),1);
meanSignedError_pct = NaN(numel(quantities),1);
maxAbsRelativeError_pct = NaN(numel(quantities),1);

for k = 1:numel(quantities)
    model = T.(modelFields{k});
    experiment = T.(testFields{k});
    valid = candidateMask & T.physicalConverged & ...
        isfinite(model) & isfinite(experiment) & experiment ~= 0;

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
