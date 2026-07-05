function report = check_full_angle_trim_envelope_legacy_full_angle_pairing()
%CHECK_FULL_ANGLE_TRIM_ENVELOPE_LEGACY_FULL_ANGLE_PAIRING Verify paired rows.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir, 'analysis'));
addpath(fullfile(rootDir, 'model'));

outDir = tempname;
plan = struct('caseName', 'pairing_test', 'modelType', '', ...
    'betaM_deg', 0, 'V_mps', 12, 'mode', 'helicopter_longitudinal');
opts = struct('outputDir', outDir, 'customPlan', plan, ...
    'models', {{'legacy','full_angle'}}, 'stages', {{}});
runReport = run_full_angle_trim_envelope_resumable(opts);
T = runReport.resultsTable;
mask = T.betaM_deg == 0 & T.V_mps == 12;
assert(sum(mask) == 2);
assert(any(strcmp(T.modelType(mask), 'legacy')));
assert(any(strcmp(T.modelType(mask), 'full_angle')));
fullRow = T(mask & strcmp(T.modelType, 'full_angle'), :);
assert(strcmp(fullRow.seedSource{1}, 'legacy_same_condition') || ...
    strcmp(fullRow.seedSource{1}, 'factory') || ...
    contains(fullRow.seedSource{1}, 'continuation'));
assert(~any(strcmp(T.status, 'NOT_RUN_AUTONOMOUS_TRIM_TIMEOUT')));
report.table = T;
report.allPassed = true;
fprintf('Full-angle trim envelope pairing check: rows=%d\n', height(T));
end
