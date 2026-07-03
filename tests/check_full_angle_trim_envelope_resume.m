function report = check_full_angle_trim_envelope_resume()
%CHECK_FULL_ANGLE_TRIM_ENVELOPE_RESUME Verify partial directory resumes.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir, 'analysis'));
addpath(fullfile(rootDir, 'model'));

outDir = tempname;
firstSpec = struct('outputDir', outDir, 'caseName', 'resume_test', ...
    'modelType', 'legacy', 'betaM_deg', 0, 'V_mps', 10, ...
    'mode', 'helicopter_longitudinal');
run_full_angle_trim_point(firstSpec);
plan(1) = struct('caseName', 'resume_test', 'modelType', 'legacy', ...
    'betaM_deg', 0, 'V_mps', 10, 'mode', 'helicopter_longitudinal');
plan(2) = struct('caseName', 'resume_test', 'modelType', 'legacy', ...
    'betaM_deg', 0, 'V_mps', 12, 'mode', 'helicopter_longitudinal');
opts = struct('outputDir', outDir, 'customPlan', plan, ...
    'models', {{'legacy'}}, 'stages', {{}});
runReport = run_full_angle_trim_envelope_resumable(opts);
statuses = {runReport.records.status};
assert(any(strcmp(statuses, 'SKIPPED_EXISTING_VALID_RESULT')));
assert(height(runReport.resultsTable) == 2);
assert(all(~strcmp(runReport.resultsTable.status, ...
    'NOT_RUN_AUTONOMOUS_TRIM_TIMEOUT')));
report.records = runReport.records;
report.allPassed = true;
fprintf('Full-angle trim envelope resume check: rows=%d\n', ...
    height(runReport.resultsTable));
end
