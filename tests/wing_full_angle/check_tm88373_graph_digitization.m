function report = check_tm88373_graph_digitization()
%CHECK_TM88373_GRAPH_DIGITIZATION Verify Figure 6a graph digitization artifacts.

rootDir = fileparts(fileparts(fileparts(mfilename('fullpath'))));
dataDir = fullfile(rootDir, 'data', 'wing_full_angle', 'tm88373_digitized');
csvPath = fullfile(dataDir, 'tm88373_figure6a_graph_digitization_pass1.csv');
repeatPath = fullfile(dataDir, 'tm88373_figure6a_graph_digitization_pass2.csv');
summaryPath = fullfile(dataDir, 'tm88373_digitization_uncertainty_summary.csv');
calPath = fullfile(dataDir, 'tm88373_figure6a_axis_calibration.json');
overlayPath = fullfile(dataDir, 'overlays', ...
    'tm88373_figure6a_digitized_points_overlay.png');

assert(exist(csvPath, 'file') == 2, 'Missing TM88373 graph digitization CSV.');
assert(exist(repeatPath, 'file') == 2, 'Missing TM88373 repeat digitization CSV.');
assert(exist(summaryPath, 'file') == 2, 'Missing TM88373 uncertainty summary.');
assert(exist(calPath, 'file') == 2, 'Missing TM88373 calibration JSON.');
assert(exist(overlayPath, 'file') == 2, 'Missing TM88373 digitization overlay.');

T = readtable(csvPath, 'FileType', 'text');
R = readtable(repeatPath, 'FileType', 'text');
S = readtable(summaryPath, 'FileType', 'text');

assert(height(T) == 6*3*7, 'Unexpected TM88373 digitized point count.');
assert(height(R) == height(T), 'Repeat digitization point count mismatch.');
assert(all(strcmp(T.source_class, 'TM88373_DIGITIZED_GRAPH')), ...
    'TM88373 graph CSV must use graph digitization source class.');
assert(all(T.pdf_page == 32) && all(T.original_page == 28), ...
    'TM88373 graph page traceability mismatch.');
assert(all(T.uncertainty_alpha_deg > 0) && all(T.uncertainty_value > 0), ...
    'TM88373 graph uncertainties must be positive.');
assert(all(S.rms_repeat_difference < 0.02), ...
    'TM88373 repeat digitization RMS difference is too large.');
assert(all(S.max_abs_repeat_difference < 0.02), ...
    'TM88373 repeat digitization max difference is too large.');

dbPath = fullfile(rootDir, 'data', 'wing_full_angle', ...
    'full_angle_selected', 'wing_full_angle_database.csv');
D = readtable(dbPath, 'FileType', 'text');
assert(any(strcmp(D.source_class, 'TM88373_DIGITIZED_GRAPH')), ...
    'Selected database does not contain TM88373 graph rows.');
assert(~any(strcmp(D.source_class, 'TM88373_DIGITIZED_TEXT_CONSTRAINED')), ...
    'Selected database still contains text-constrained TM88373 rows.');

report.pointCount = height(T);
report.maxRepeatDifference = max(S.max_abs_repeat_difference);
report.allPassed = true;
fprintf('TM88373 graph digitization points=%d maxRepeat=%.12e\n', ...
    report.pointCount, report.maxRepeatDifference);
end
