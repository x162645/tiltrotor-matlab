function report = report_berger13_linear_derivatives(outputRoot)
%REPORT_BERGER13_LINEAR_DERIVATIVES Internal 13x10 derivative audit.
% The representative points are finite operating points for internal model
% auditing only. They are not trim-envelope, Berger, XV-15, or flight-test
% validation cases.

rootDir = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(rootDir);
addpath(fullfile(rootDir, 'model'));
addpath(fullfile(rootDir, 'model', 'berger13'));
addpath(fullfile(rootDir, 'analysis', 'berger13'));

if nargin < 1 || isempty(outputRoot)
    outputRoot = fullfile(rootDir, 'validation', ...
        'berger13_linear_derivatives');
end

P13 = params_berger13();
cases = representative_cases();
u10 = representative_controls();

report.timestamp = datestr(now, 'yyyymmddTHHMMSS');
report.outputDir = fullfile(outputRoot, report.timestamp);
report.stateNames = get_state_names_13x10();
report.controlNames = get_control_input_names_13x10();
report.notes = { ...
    'internal derivative audit only'; ...
    'not Berger/XV-15 validation'; ...
    'not a handling-quality conclusion'; ...
    'not nonlinear response validation'; ...
    'non-rotor aero and mass properties still use betaMAvg approximation'; ...
    'representative finite operating points are not a full trim envelope'};

caseReports = repmat(empty_case_report(), numel(cases), 1);
for k = 1:numel(cases)
    caseReports(k) = evaluate_case(cases(k), u10, P13);
end
report.cases = caseReports;

if ~exist(report.outputDir, 'dir')
    mkdir(report.outputDir);
end
write_markdown_report(report);
write_csv_report(report);

fprintf('\nBerger13 linear derivative report\n');
fprintf('=================================\n');
fprintf('Output: %s\n', report.outputDir);
for k = 1:numel(report.cases)
    item = report.cases(k);
    fprintf('%-26s A=%dx%d B=%dx%d finite=%d first9Diff=%.6e\n', ...
        item.caseName, item.ASize(1), item.ASize(2), ...
        item.BSize(1), item.BSize(2), item.finite, ...
        item.first9DifferenceNorm);
end
end

function cases = representative_cases()
d2r = pi/180;
cases = struct( ...
    'caseName', {'helicopter_like', 'conversion_mid', ...
        'airplane_like', 'asymmetric_nacelle_probe'}, ...
    'V', {20, 45, 100, 45}, ...
    'betaML', {0*d2r, 45*d2r, 90*d2r, 35*d2r}, ...
    'betaMR', {0*d2r, 45*d2r, 90*d2r, 55*d2r});
end

function u10 = representative_controls()
d2r = pi/180;
u10 = [8*d2r; 0; 0; 0; 1*d2r; 0; -2*d2r; 0; 0; 0];
end

function item = evaluate_case(caseDef, u10, P13)
x13 = [caseDef.V; 0; 0; 0; 0; 0; 0; 0; 0; ...
    caseDef.betaML; caseDef.betaMR; 0; 0];
[A13, B13, lin] = linearize_13x10_numeric(x13, u10, P13);
[xdot, out] = tiltrotor_eom_13x10(x13, u10, P13);
componentInfo = out.components13;

item = empty_case_report();
item.caseName = caseDef.caseName;
item.V = caseDef.V;
item.betaML = componentInfo.betaML;
item.betaMR = componentInfo.betaMR;
item.betaMAvg = componentInfo.betaMAvg;
item.usedIndependentRotorAngles = componentInfo.usedIndependentRotorAngles;
item.usedAverageNonRotorAero = componentInfo.usedAverageNonRotorAero;
item.finite = lin.finite && all(isfinite(xdot(:))) && ...
    all(isfinite(A13(:))) && all(isfinite(B13(:)));
item.ASize = size(A13);
item.BSize = size(B13);
item.ANorm = norm(A13, 'fro');
item.BNorm = norm(B13, 'fro');
item.conditionNumber = lin.conditionNumber;
item.conditionDiagnostic = condition_diagnostic(lin.conditionNumber);
item.normAFirstNineBetaML = norm(A13(1:9,10));
item.normAFirstNineBetaMR = norm(A13(1:9,11));
item.normAAngularBetaML = norm(A13(4:6,10));
item.normAAngularBetaMR = norm(A13(4:6,11));
item.normAAngularBetaDiff = norm(A13(4:6,10)-A13(4:6,11));
item.A10_12 = A13(10,12);
item.A11_13 = A13(11,13);
item.A12_12 = A13(12,12);
item.A13_13 = A13(13,13);
item.controlColumnNorms = zeros(10,1);
for j = 1:10
    item.controlColumnNorms(j) = norm(B13(:,j));
end
item.B12_9 = B13(12,9);
item.B13_10 = B13(13,10);
item.first9DifferenceNorm = legacy_first9_difference( ...
    x13, u10, P13, xdot, componentInfo);
item.forceDeltaNorm = norm(componentInfo.F - componentInfo.averageOnlyF);
item.momentDeltaNorm = norm(componentInfo.M - componentInfo.averageOnlyM);
item.warnings = componentInfo.warnings;
end

function value = legacy_first9_difference(x13, u10, P13, xdot, info)
if abs(info.betaML-info.betaMR) < 1e-12
    legacy = tiltrotor_eom(x13(1:9), u10(1:8), info.betaMAvg, P13.base);
    value = norm(xdot(1:9)-legacy);
else
    value = NaN;
end
end

function label = condition_diagnostic(conditionNumber)
if conditionNumber <= 1e3
    label = 'LOW';
elseif conditionNumber <= 1e6
    label = 'CAUTION';
else
    label = 'SEVERE';
end
end

function item = empty_case_report()
item = struct( ...
    'caseName', '', ...
    'V', NaN, ...
    'betaML', NaN, ...
    'betaMR', NaN, ...
    'betaMAvg', NaN, ...
    'usedIndependentRotorAngles', false, ...
    'usedAverageNonRotorAero', false, ...
    'finite', false, ...
    'ASize', [NaN NaN], ...
    'BSize', [NaN NaN], ...
    'ANorm', NaN, ...
    'BNorm', NaN, ...
    'conditionNumber', NaN, ...
    'conditionDiagnostic', '', ...
    'normAFirstNineBetaML', NaN, ...
    'normAFirstNineBetaMR', NaN, ...
    'normAAngularBetaML', NaN, ...
    'normAAngularBetaMR', NaN, ...
    'normAAngularBetaDiff', NaN, ...
    'A10_12', NaN, ...
    'A11_13', NaN, ...
    'A12_12', NaN, ...
    'A13_13', NaN, ...
    'controlColumnNorms', NaN(10,1), ...
    'B12_9', NaN, ...
    'B13_10', NaN, ...
    'first9DifferenceNorm', NaN, ...
    'forceDeltaNorm', NaN, ...
    'momentDeltaNorm', NaN, ...
    'warnings', {{}} );
end

function write_markdown_report(report)
path = fullfile(report.outputDir, 'berger13_linear_derivatives_report.md');
fid = fopen(path, 'w');
if fid < 0
    error('report_berger13_linear_derivatives:FileOpenFailed', ...
        'Could not open %s for writing.', path);
end
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, '# Berger13 Linear Derivative Internal Audit\n\n');
fprintf(fid, 'Generated: `%s`\n\n', report.timestamp);
fprintf(fid, 'This is an internal derivative audit for the isolated ');
fprintf(fid, 'berger13 13x10 research model. It is not Berger/XV-15 ');
fprintf(fid, 'validation, not a handling-quality conclusion, and not ');
fprintf(fid, 'nonlinear response validation. The representative points are ');
fprintf(fid, 'finite operating points, not a full trim envelope.\n\n');
fprintf(fid, 'Non-rotor aero and mass properties still use ');
fprintf(fid, '`betaMAvg = 0.5*(betaML + betaMR)`.\n\n');

fprintf(fid, '## Cases\n\n');
for k = 1:numel(report.cases)
    item = report.cases(k);
    fprintf(fid, '### %s\n\n', item.caseName);
    fprintf(fid, '- V: %.12g m/s\n', item.V);
    fprintf(fid, '- betaML: %.12g rad\n', item.betaML);
    fprintf(fid, '- betaMR: %.12g rad\n', item.betaMR);
    fprintf(fid, '- betaMAvg: %.12g rad\n', item.betaMAvg);
    fprintf(fid, '- usedIndependentRotorAngles: %s\n', ...
        logical_text(item.usedIndependentRotorAngles));
    fprintf(fid, '- usedAverageNonRotorAero: %s\n', ...
        logical_text(item.usedAverageNonRotorAero));
    fprintf(fid, '- A size: %d x %d\n', item.ASize(1), item.ASize(2));
    fprintf(fid, '- B size: %d x %d\n', item.BSize(1), item.BSize(2));
    fprintf(fid, '- norm(A): %.12e\n', item.ANorm);
    fprintf(fid, '- norm(B): %.12e\n', item.BNorm);
    fprintf(fid, '- conditionNumber: %.12e (%s)\n', ...
        item.conditionNumber, item.conditionDiagnostic);
    fprintf(fid, '- norm(A13(1:9,10)): %.12e\n', ...
        item.normAFirstNineBetaML);
    fprintf(fid, '- norm(A13(1:9,11)): %.12e\n', ...
        item.normAFirstNineBetaMR);
    fprintf(fid, '- norm(A13(4:6,10)): %.12e\n', ...
        item.normAAngularBetaML);
    fprintf(fid, '- norm(A13(4:6,11)): %.12e\n', ...
        item.normAAngularBetaMR);
    fprintf(fid, '- norm(A13(4:6,10)-A13(4:6,11)): %.12e\n', ...
        item.normAAngularBetaDiff);
    fprintf(fid, '- A13(10,12): %.12e\n', item.A10_12);
    fprintf(fid, '- A13(11,13): %.12e\n', item.A11_13);
    fprintf(fid, '- A13(12,12): %.12e\n', item.A12_12);
    fprintf(fid, '- A13(13,13): %.12e\n', item.A13_13);
    fprintf(fid, '- first9DifferenceNorm vs legacy opt-in: %.12e\n', ...
        item.first9DifferenceNorm);
    fprintf(fid, '- independent vs betaMAvg-only force delta norm: %.12e\n', ...
        item.forceDeltaNorm);
    fprintf(fid, '- independent vs betaMAvg-only moment delta norm: %.12e\n\n', ...
        item.momentDeltaNorm);

    fprintf(fid, '| Control | norm(B column) |\n');
    fprintf(fid, '|-|-:|\n');
    for j = 1:numel(report.controlNames)
        fprintf(fid, '| %s | %.12e |\n', report.controlNames{j}, ...
            item.controlColumnNorms(j));
    end
    fprintf(fid, '\n');
    fprintf(fid, '- B13(12,9): %.12e\n', item.B12_9);
    fprintf(fid, '- B13(13,10): %.12e\n\n', item.B13_10);
end
end

function write_csv_report(report)
path = fullfile(report.outputDir, 'berger13_linear_derivatives.csv');
fid = fopen(path, 'w');
if fid < 0
    error('report_berger13_linear_derivatives:FileOpenFailed', ...
        'Could not open %s for writing.', path);
end
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, 'caseName,metric,value\n');
for k = 1:numel(report.cases)
    item = report.cases(k);
    write_metric(fid, item.caseName, 'V_mps', item.V);
    write_metric(fid, item.caseName, 'betaML_rad', item.betaML);
    write_metric(fid, item.caseName, 'betaMR_rad', item.betaMR);
    write_metric(fid, item.caseName, 'betaMAvg_rad', item.betaMAvg);
    write_metric(fid, item.caseName, 'usedIndependentRotorAngles', ...
        double(item.usedIndependentRotorAngles));
    write_metric(fid, item.caseName, 'usedAverageNonRotorAero', ...
        double(item.usedAverageNonRotorAero));
    write_metric(fid, item.caseName, 'finite', double(item.finite));
    write_metric(fid, item.caseName, 'A13_rows', item.ASize(1));
    write_metric(fid, item.caseName, 'A13_cols', item.ASize(2));
    write_metric(fid, item.caseName, 'B13_rows', item.BSize(1));
    write_metric(fid, item.caseName, 'B13_cols', item.BSize(2));
    write_metric(fid, item.caseName, 'norm_A13', item.ANorm);
    write_metric(fid, item.caseName, 'norm_B13', item.BNorm);
    write_metric(fid, item.caseName, 'conditionNumber', ...
        item.conditionNumber);
    write_metric(fid, item.caseName, 'norm_A13_1_9_10', ...
        item.normAFirstNineBetaML);
    write_metric(fid, item.caseName, 'norm_A13_1_9_11', ...
        item.normAFirstNineBetaMR);
    write_metric(fid, item.caseName, 'norm_A13_4_6_10', ...
        item.normAAngularBetaML);
    write_metric(fid, item.caseName, 'norm_A13_4_6_11', ...
        item.normAAngularBetaMR);
    write_metric(fid, item.caseName, 'norm_A13_4_6_10_minus_11', ...
        item.normAAngularBetaDiff);
    write_metric(fid, item.caseName, 'A13_10_12', item.A10_12);
    write_metric(fid, item.caseName, 'A13_11_13', item.A11_13);
    write_metric(fid, item.caseName, 'A13_12_12', item.A12_12);
    write_metric(fid, item.caseName, 'A13_13_13', item.A13_13);
    for j = 1:numel(report.controlNames)
        write_metric(fid, item.caseName, ...
            ['norm_B13_col_' report.controlNames{j}], ...
            item.controlColumnNorms(j));
    end
    write_metric(fid, item.caseName, 'B13_12_9', item.B12_9);
    write_metric(fid, item.caseName, 'B13_13_10', item.B13_10);
    write_metric(fid, item.caseName, 'first9DifferenceNorm', ...
        item.first9DifferenceNorm);
    write_metric(fid, item.caseName, 'forceDeltaNorm', ...
        item.forceDeltaNorm);
    write_metric(fid, item.caseName, 'momentDeltaNorm', ...
        item.momentDeltaNorm);
end
end

function write_metric(fid, caseName, metric, value)
fprintf(fid, '%s,%s,%.16g\n', caseName, metric, value);
end

function text = logical_text(value)
if value
    text = 'true';
else
    text = 'false';
end
end
