%RUN_FULL_ASSESSMENT_BATCH Reproducible batch entry point for the report evidence.
%
% This script deliberately keeps the analysis entry point in the repository so
% that the MATLAB command, options, and generated evidence are auditable.

rootDir = fileparts(fileparts(fileparts(mfilename('fullpath'))));
run(fullfile(rootDir, 'startup.m'));

opts = struct();
opts.fullTrimGrid = true;
outputDir = fullfile(rootDir, 'docs', ...
    'tiltrotor_control_stability_technical_report');

assessment = run_control_stability_assessment(outputDir, opts);
assert(assessment.finiteReal && assessment.allRepresentativeCredible);
fprintf('CONTROL_STABILITY_FULL_ASSESSMENT_OK=1\n');
