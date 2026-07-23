function report = check_thesis_nacelle_consolidation()
%CHECK_THESIS_NACELLE_CONSOLIDATION Verify the frozen three-point hierarchy study.
%
% This check reads generated evidence only. It does not modify model
% parameters or rerun the long nonlinear study.

root = fileparts(fileparts(mfilename('fullpath')));
resultDir = fullfile(root, 'results', 'thesis_nacelle_consolidation');
pointFile = fullfile(resultDir, 'MODEL_HIERARCHY_POINT_SUMMARY.csv');
responseFile = fullfile(resultDir, 'MODEL_HIERARCHY_RESPONSE_METRICS.csv');
rateFile = fullfile(resultDir, 'NACELLE_RATE_DIRECT_CONTRIBUTION.csv');

assert(isfile(pointFile), 'Missing model hierarchy point summary.');
assert(isfile(responseFile), 'Missing model hierarchy response metrics.');
assert(isfile(rateFile), 'Missing nacelle rate contribution evidence.');

point = readtable(pointFile);
response = readtable(responseFile);
rate = readtable(rateFile);

assert(height(point) == 3, 'Expected exactly three representative points.');
assert(all(point.quasiStaticStateCount == 9), ...
    'Quasi-static layer must contain nine rigid-body states.');
assert(all(point.dynamicStateCount == 13), ...
    'Dynamic layer must contain thirteen states.');
assert(all(point.addedStateCount == 4), ...
    'Dynamic extension must add four left/right nacelle states.');
assert(all(point.finiteReal == 1), ...
    'All hierarchy matrices and roots must be finite and real-valued.');
numericMask = varfun(@isnumeric, point, 'OutputFormat', 'uniform');
pointNumeric = point{:, numericMask};
assert(all(isfinite(pointNumeric(:))), 'Point summary contains NaN or Inf.');

assert(height(response) == 6, ...
    'Expected symmetric and differential responses at three points.');
assert(all(response.quantitativeClaimAllowed == 1), ...
    'Every archived response must satisfy its validity guard.');
assert(all(response.finiteReal == 1), ...
    'Every archived response must be finite and real-valued.');
assert(max(response.coarseFinePeakChange) <= 0.02, ...
    'Response time-step convergence exceeds the declared 2%% gate.');

assert(height(rate) == 3, 'Expected direct rate contributions at three points.');
assert(all(rate.gyroSymNormNmPerRadPerSec == 0), ...
    'Default zero rotor polar inertia should leave the gyro channel inactive.');
assert(all(rate.gyroDiffNormNmPerRadPerSec == 0), ...
    'Default zero rotor polar inertia should leave the gyro channel inactive.');
assert(all(rate.reactionSymYNmPerRadPerSec == -3200), ...
    'Unexpected symmetric nacelle-rate reaction moment derivative.');

report = struct();
report.name = mfilename;
report.passed = true;
report.pointCount = height(point);
report.layerCount = 3;
report.responseCount = height(response);
report.maximumTimeStepPeakChange = max(response.coarseFinePeakChange);
report.maximumLinearizationStepVariation = max([ ...
    point.maximumStepVariation9; point.maximumStepVariation13]);

fprintf(['Thesis nacelle consolidation check passed: %d points, %d layers, ' ...
    'max dt change %.6f.\n'], report.pointCount, report.layerCount, ...
    report.maximumTimeStepPeakChange);
end
