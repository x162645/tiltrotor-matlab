%RUN_REUSE_ASSESSMENT_BATCH Re-run post-processing from a saved trim grid.
%
% This entry point is used only after a full run has generated the nine-point
% database. It permits report post-processing changes to be verified without
% repeating the expensive trim scan.

rootDir = fileparts(fileparts(fileparts(mfilename('fullpath'))));
run(fullfile(rootDir, 'startup.m'));
outputDir = fullfile(rootDir, 'docs', ...
    'tiltrotor_control_stability_technical_report');
saved = load(fullfile(outputDir, ...
    'CONTROL_STABILITY_TRIM_DATABASE.mat'), 'trimDatabase');

opts = struct();
opts.fullTrimGrid = false;
opts.trimDatabase = saved.trimDatabase;
assessment = run_control_stability_assessment(outputDir, opts);
assert(assessment.finiteReal && assessment.allRepresentativeCredible);
fprintf('CONTROL_STABILITY_REUSED_TRIM_DATABASE_OK=1\n');
