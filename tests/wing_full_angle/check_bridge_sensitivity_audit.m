function report = check_bridge_sensitivity_audit()
%CHECK_BRIDGE_SENSITIVITY_AUDIT Verify bridge-candidate audit artifacts.

rootDir = fileparts(fileparts(fileparts(mfilename('fullpath'))));
auditPath = fullfile(rootDir, 'validation', 'wing_full_angle', ...
    'full_angle', 'bridge_candidate_audit.csv');
summaryPath = fullfile(rootDir, 'validation', 'wing_full_angle', ...
    'full_angle', 'bridge_candidate_summary.csv');
sharePath = fullfile(rootDir, 'validation', 'wing_full_angle', ...
    'full_angle', 'source_class_share_audit.csv');

assert(exist(auditPath, 'file') == 2, 'Missing bridge candidate audit.');
assert(exist(summaryPath, 'file') == 2, 'Missing bridge candidate summary.');
assert(exist(sharePath, 'file') == 2, 'Missing source class share audit.');

A = readtable(auditPath, 'FileType', 'text');
S = readtable(summaryPath, 'FileType', 'text');
Q = readtable(sharePath, 'FileType', 'text');
required = {'current_selected'; 'endpoint_linear_pchip_proxy'; ...
    'flat_plate_asymptotic'; 'viterna_type_reference_only'};
for i = 1:numel(required)
    assert(any(strcmp(S.candidate, required{i})), ...
        'Missing bridge candidate %s.', required{i});
end
assert(all(S.min_CD >= 0), 'Bridge candidates must keep CD nonnegative.');
assert(any(strcmp(S.selection_status, 'SELECTED') & ...
    strcmp(S.candidate, 'current_selected')), ...
    'Current bridge candidate must be marked selected.');
bridgeShare = Q.share_percent(strcmp(Q.source_class, 'BRIDGE_MODEL'));
assert(~isempty(bridgeShare) && bridgeShare > 50, ...
    'Bridge share audit should disclose material bridge usage.');
assert(all(isfinite(A.max_delta_from_current_in_bridge)), ...
    'Bridge candidate deltas must be finite.');

report.bridgeSharePercent = bridgeShare;
report.candidateCount = height(S);
report.allPassed = true;
fprintf('Bridge sensitivity candidates=%d bridgeShare=%.6f%%\n', ...
    report.candidateCount, report.bridgeSharePercent);
end
