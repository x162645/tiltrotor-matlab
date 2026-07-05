function report = check_full_angle_trim_envelope_resumable()
%CHECK_FULL_ANGLE_TRIM_ENVELOPE_RESUMABLE Verify existing valid point skip.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir, 'analysis'));
addpath(fullfile(rootDir, 'model'));

outDir = tempname;
plan = struct('caseName', 'resume_skip_test', 'modelType', 'legacy', ...
    'betaM_deg', 0, 'V_mps', 12, 'mode', 'helicopter_longitudinal');
opts = struct('outputDir', outDir, 'customPlan', plan, ...
    'models', {{'legacy'}}, 'stages', {{}});
first = run_full_angle_trim_envelope_resumable(opts);
second = run_full_angle_trim_envelope_resumable(opts);
assert(numel(first.records) == 1 && first.records(1).actuallyExecuted);
assert(numel(second.records) == 1);
assert(strcmp(second.records(1).status, 'SKIPPED_EXISTING_VALID_RESULT'));
assert(~second.records(1).actuallyExecuted);
assert(height(second.resultsTable) == 1);
report.first = first.records;
report.second = second.records;
report.allPassed = true;
fprintf('Full-angle trim envelope resumable check: skip=%s\n', ...
    second.records(1).status);
end
