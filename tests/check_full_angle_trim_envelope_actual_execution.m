function report = check_full_angle_trim_envelope_actual_execution()
%CHECK_FULL_ANGLE_TRIM_ENVELOPE_ACTUAL_EXECUTION Verify a real point run.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir, 'analysis'));
addpath(fullfile(rootDir, 'model'));

outDir = tempname;
spec = struct('outputDir', outDir, 'caseName', 'actual_execution', ...
    'modelType', 'full_angle', 'betaM_deg', 0, 'V_mps', 12, ...
    'mode', 'helicopter_longitudinal');
result = run_full_angle_trim_point(spec);
[T, ~, ~] = collect_full_angle_trim_envelope_results(outDir);
assert(result.actuallyExecuted && result.runtime_s > 0);
assert(height(T) == 1 && T.actuallyExecuted(1));
assert(~strcmp(T.status{1}, 'NOT_RUN_AUTONOMOUS_TRIM_TIMEOUT'));
assert(isfinite(T.runtime_s(1)) && T.runtime_s(1) > 0);
report.result = result;
report.table = T;
report.allPassed = true;
fprintf('Full-angle trim envelope actual execution check: status=%s\n', ...
    result.status);
end
