function report = check_full_angle_trim_envelope_no_placeholder_rows()
%CHECK_FULL_ANGLE_TRIM_ENVELOPE_NO_PLACEHOLDER_ROWS Ensure unrun points vanish.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir, 'analysis'));

outDir = tempname;
plan = struct('caseName', 'unrun_plan', 'modelType', 'legacy', ...
    'betaM_deg', 0, 'V_mps', 12, 'mode', 'helicopter_longitudinal');
[T, S, G] = collect_full_angle_trim_envelope_results(outDir, plan);
assert(height(T) == 0, 'Unrun planned points must not become result rows.');
assert(height(S) == 1 && S.planned(1) == 1 && S.attempted(1) == 0);
assert(~any(strcmp(G.status, 'FAIL')));
report.results = T;
report.summary = S;
report.gates = G;
report.allPassed = true;
fprintf('Full-angle trim envelope no-placeholder check: resultRows=%d\n', height(T));
end
