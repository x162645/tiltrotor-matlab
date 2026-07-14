function report = report_independent_nacelle_loads(outputRoot)
%REPORT_INDEPENDENT_NACELLE_LOADS Berger13 independent rotor-load report.

rootDir = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(rootDir);
addpath(fullfile(rootDir, 'model'));
addpath(fullfile(rootDir, 'model', 'berger13'));
addpath(fullfile(rootDir, 'analysis', 'berger13'));

if nargin < 1 || isempty(outputRoot)
    outputRoot = fullfile(rootDir, 'validation', ...
        'berger13_independent_nacelle_loads');
end

d2r = pi/180;
P13 = params_berger13();
xSym = [40; 0; 0; 0; 0; 0; 0; 0; 0; 90*d2r; 90*d2r; 0; 0];
u10 = [8*d2r; 0; 0; 0; 1*d2r; 0; -2*d2r; 0; 0; 0];

legacy = tiltrotor_eom(xSym(1:9), u10(1:8), xSym(10), P13.base);
research = tiltrotor_eom_13x10(xSym, u10, P13);
symDiffNorm = norm(research(1:9)-legacy);

xAsym = xSym;
xAsym(10) = 80*d2r;
xAsym(11) = 90*d2r;
[Fasym, Masym, asymInfo] = total_forces_moments_13x10(xAsym, u10, P13);
forceDeltaNorm = norm(Fasym - asymInfo.averageOnlyF);
momentDeltaNorm = norm(Masym - asymInfo.averageOnlyM);

[A13, B13, lin] = linearize_13x10_numeric(xSym, u10, P13);

report.timestamp = datestr(now, 'yyyymmddTHHMMSS');
report.outputDir = fullfile(outputRoot, report.timestamp);
report.symmetric.betaML = xSym(10);
report.symmetric.betaMR = xSym(11);
report.symmetric.firstNineDerivativeNormDifference = symDiffNorm;
report.asymmetric.betaML = xAsym(10);
report.asymmetric.betaMR = xAsym(11);
report.asymmetric.forceDeltaNorm = forceDeltaNorm;
report.asymmetric.momentDeltaNorm = momentDeltaNorm;
report.asymmetric.rotorLeftBetaMUsed = asymInfo.rotorLeft.betaMUsed;
report.asymmetric.rotorRightBetaMUsed = asymInfo.rotorRight.betaMUsed;
report.asymmetric.usedIndependentRotorAngles = ...
    asymInfo.usedIndependentRotorAngles;
report.asymmetric.usedAverageNonRotorAero = asymInfo.usedAverageNonRotorAero;
report.linearization.ASize = size(A13);
report.linearization.BSize = size(B13);
report.linearization.normAFirstNineBetaML = norm(A13(1:9,10));
report.linearization.normAFirstNineBetaMR = norm(A13(1:9,11));
report.linearization.normAngularBetaColumnDifference = ...
    norm(A13(4:6,10)-A13(4:6,11));
report.linearization.BNacelleTorqueLeft = B13(12,9);
report.linearization.BNacelleTorqueRight = B13(13,10);
report.linearization.finite = lin.finite;

if ~exist(report.outputDir, 'dir')
    mkdir(report.outputDir);
end
write_markdown_report(report);
write_csv_report(report);

fprintf('\nBerger13 independent nacelle-load report\n');
fprintf('========================================\n');
fprintf('Output: %s\n', report.outputDir);
fprintf('Symmetric first-nine derivative norm difference: %.6e\n', ...
    symDiffNorm);
fprintf('Asymmetric force delta norm: %.6e\n', forceDeltaNorm);
fprintf('Asymmetric moment delta norm: %.6e\n', momentDeltaNorm);
fprintf('A13 size: %d x %d\n', size(A13,1), size(A13,2));
fprintf('B13 size: %d x %d\n', size(B13,1), size(B13,2));
end

function write_markdown_report(report)
path = fullfile(report.outputDir, 'berger13_independent_nacelle_loads.md');
fid = fopen(path, 'w');
if fid < 0
    error('report_independent_nacelle_loads:FileOpenFailed', ...
        'Could not open %s for writing.', path);
end
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, '# Berger13 Independent Nacelle Loads\n\n');
fprintf(fid, 'Generated: `%s`\n\n', report.timestamp);
fprintf(fid, 'Independent left/right rotor loads are implemented for the ');
fprintf(fid, 'berger13 research path. Non-rotor aero still uses ');
fprintf(fid, '`betaMAvg = 0.5*(betaML + betaMR)`.\n\n');
fprintf(fid, 'This report is not Berger/XV-15 validation and does not make ');
fprintf(fid, 'a handling-quality conclusion.\n\n');

fprintf(fid, '## Symmetric Case\n\n');
fprintf(fid, '- betaML: %.12g rad\n', report.symmetric.betaML);
fprintf(fid, '- betaMR: %.12g rad\n', report.symmetric.betaMR);
fprintf(fid, '- first 9 derivative norm difference vs legacy opt-in: %.12e\n\n', ...
    report.symmetric.firstNineDerivativeNormDifference);

fprintf(fid, '## Asymmetric Case\n\n');
fprintf(fid, '- betaML: %.12g rad\n', report.asymmetric.betaML);
fprintf(fid, '- betaMR: %.12g rad\n', report.asymmetric.betaMR);
fprintf(fid, '- independent vs betaMAvg-only force difference norm: %.12e\n', ...
    report.asymmetric.forceDeltaNorm);
fprintf(fid, '- independent vs betaMAvg-only moment difference norm: %.12e\n', ...
    report.asymmetric.momentDeltaNorm);
fprintf(fid, '- rotorLeft betaMUsed: %.12g rad\n', ...
    report.asymmetric.rotorLeftBetaMUsed);
fprintf(fid, '- rotorRight betaMUsed: %.12g rad\n', ...
    report.asymmetric.rotorRightBetaMUsed);
fprintf(fid, '- usedIndependentRotorAngles: %s\n', ...
    logical_text(report.asymmetric.usedIndependentRotorAngles));
fprintf(fid, '- usedAverageNonRotorAero: %s\n\n', ...
    logical_text(report.asymmetric.usedAverageNonRotorAero));

fprintf(fid, '## Linearization\n\n');
fprintf(fid, '- A13 size: %d x %d\n', report.linearization.ASize(1), ...
    report.linearization.ASize(2));
fprintf(fid, '- B13 size: %d x %d\n', report.linearization.BSize(1), ...
    report.linearization.BSize(2));
fprintf(fid, '- norm(A13(1:9,10)): %.12e\n', ...
    report.linearization.normAFirstNineBetaML);
fprintf(fid, '- norm(A13(1:9,11)): %.12e\n', ...
    report.linearization.normAFirstNineBetaMR);
fprintf(fid, '- norm(A13(4:6,10)-A13(4:6,11)): %.12e\n', ...
    report.linearization.normAngularBetaColumnDifference);
fprintf(fid, '- B13(12,9): %.12e\n', ...
    report.linearization.BNacelleTorqueLeft);
fprintf(fid, '- B13(13,10): %.12e\n', ...
    report.linearization.BNacelleTorqueRight);
end

function write_csv_report(report)
path = fullfile(report.outputDir, 'berger13_independent_nacelle_loads.csv');
fid = fopen(path, 'w');
if fid < 0
    error('report_independent_nacelle_loads:FileOpenFailed', ...
        'Could not open %s for writing.', path);
end
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, 'metric,value\n');
write_metric(fid, 'symmetric_betaML_rad', report.symmetric.betaML);
write_metric(fid, 'symmetric_betaMR_rad', report.symmetric.betaMR);
write_metric(fid, 'symmetric_first9_derivative_norm_difference', ...
    report.symmetric.firstNineDerivativeNormDifference);
write_metric(fid, 'asymmetric_betaML_rad', report.asymmetric.betaML);
write_metric(fid, 'asymmetric_betaMR_rad', report.asymmetric.betaMR);
write_metric(fid, 'asymmetric_force_delta_norm', ...
    report.asymmetric.forceDeltaNorm);
write_metric(fid, 'asymmetric_moment_delta_norm', ...
    report.asymmetric.momentDeltaNorm);
write_metric(fid, 'rotorLeft_betaMUsed_rad', ...
    report.asymmetric.rotorLeftBetaMUsed);
write_metric(fid, 'rotorRight_betaMUsed_rad', ...
    report.asymmetric.rotorRightBetaMUsed);
write_metric(fid, 'usedIndependentRotorAngles', ...
    double(report.asymmetric.usedIndependentRotorAngles));
write_metric(fid, 'usedAverageNonRotorAero', ...
    double(report.asymmetric.usedAverageNonRotorAero));
write_metric(fid, 'A13_rows', report.linearization.ASize(1));
write_metric(fid, 'A13_cols', report.linearization.ASize(2));
write_metric(fid, 'B13_rows', report.linearization.BSize(1));
write_metric(fid, 'B13_cols', report.linearization.BSize(2));
write_metric(fid, 'norm_A13_1_9_10', ...
    report.linearization.normAFirstNineBetaML);
write_metric(fid, 'norm_A13_1_9_11', ...
    report.linearization.normAFirstNineBetaMR);
write_metric(fid, 'norm_A13_4_6_10_minus_11', ...
    report.linearization.normAngularBetaColumnDifference);
write_metric(fid, 'B13_12_9', report.linearization.BNacelleTorqueLeft);
write_metric(fid, 'B13_13_10', report.linearization.BNacelleTorqueRight);
end

function write_metric(fid, name, value)
fprintf(fid, '%s,%.16g\n', name, value);
end

function text = logical_text(value)
if value
    text = 'true';
else
    text = 'false';
end
end
