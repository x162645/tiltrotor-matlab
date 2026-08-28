function results = run_xv15_frozen_external_correlation(outputDir)
%RUN_XV15_FROZEN_EXTERNAL_CORRELATION Canonical metadata-corrected entry.
%
% This wrapper preserves the numerical calculation performed by
% run_xv15_frozen_low_order_validation, but corrects the evidence metadata
% after the 2026-08-28 Codex handoff audit.
%
% Method boundary:
% - OARF Run 15 has already been used in prior PR #67/#68 diagnostics and
%   therefore is NOT a blind/unseen hold-out data set;
% - the 6--11 deg scoring interval is a fixed reporting window inherited
%   from previously established physical support, not a pre-registered
%   blind window;
% - the underlying production rotor equations are unchanged;
% - no OARF CT/CP/FM value is used to fit C81 parameters or any physical
%   parameter inside this wrapper.
%
% The legacy runner is intentionally retained unchanged as a historical
% record of the MATLAB run that produced the submitted numerical values.
% This wrapper is the canonical reproducible entry for future reporting.

rootDir = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1 || isempty(outputDir)
    outputDir = fullfile(rootDir, 'results', ...
        'xv15_frozen_low_order_validation');
end

results = run_xv15_frozen_low_order_validation(outputDir);

claimBoundary = ['FROZEN_LOW_ORDER_EXTERNAL_CORRELATION_' ...
    'NOT_XV15_REPRODUCTION_NO_OARF_PARAMETER_FIT'];
reportWindow = 'FIXED_REPORT_WINDOW_6_TO_11_DEG';
datasetIndependence = 'NOT_BLIND_USED_IN_PRIOR_DIAGNOSTICS';

% Correct the row-level and metric-level semantic metadata only. Numerical
% predictions, convergence flags, CT/CP/FM values and errors are untouched.
results.validationTable.claimBoundary = repmat( ...
    {claimBoundary}, height(results.validationTable), 1);
results.metricTable.window = {reportWindow};
results.metricTable.claimBoundary = {claimBoundary};

% The original parameter pack used hold-out terminology that is no longer
% methodologically valid. Preserve the source value but correct its role.
idx = strcmp(results.freezeTable.parameter, 'holdout_source');
if nnz(idx) ~= 1
    error('run_xv15_frozen_external_correlation:SourceMetadataMismatch', ...
        'Expected exactly one legacy holdout_source row.');
end
results.freezeTable.parameter{idx} = 'external_correlation_source';
results.freezeTable.status{idx} = 'DEVELOPMENT_EXTERNAL_CORRELATION';

% Add an explicit data-independence contract so downstream tables cannot
% silently reinterpret this data set as blind validation evidence.
newRow = table({'dataset_independence'}, {datasetIndependence}, {'-'}, ...
    {'METHOD_AUDIT_20260828'}, {'EXPLICIT_LIMITATION'}, ...
    'VariableNames', {'parameter','value','unit','provenance','status'});
results.freezeTable = [results.freezeTable; newRow];

results.claimBoundary = claimBoundary;
results.reportWindow = reportWindow;
results.datasetIndependence = datasetIndependence;
results.metadataCorrectionOnly = true;

% Overwrite only the metadata-bearing artifacts with the corrected labels.
writetable(results.validationTable, fullfile(outputDir, ...
    'XV15_FROZEN_LOW_ORDER_VALIDATION.csv'));
writetable(results.metricTable, fullfile(outputDir, ...
    'XV15_FROZEN_LOW_ORDER_METRICS.csv'));
writetable(results.freezeTable, fullfile(outputDir, ...
    'XV15_FROZEN_PARAMETER_PACK.csv'));
save(fullfile(outputDir, 'XV15_FROZEN_LOW_ORDER_RESULTS.mat'), 'results');
end
