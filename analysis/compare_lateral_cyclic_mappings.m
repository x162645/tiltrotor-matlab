function summary = compare_lateral_cyclic_mappings(opts)
%COMPARE_LATERAL_CYCLIC_MAPPINGS Compare theta1c mapping candidates.
% This diagnostic explicitly evaluates each mapping candidate at finite
% representative operating points. It does not claim external validation.

if nargin < 1 || isempty(opts)
    opts = struct();
end

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir, 'model'));
addpath(fullfile(rootDir, 'analysis'));

Pbase = params_nominal();
Pbase.control.enableLateralCyclic = true;

if ~isfield(opts, 'outputRoot') || isempty(opts.outputRoot)
    opts.outputRoot = fullfile(rootDir, 'validation', ...
        'lateral_cyclic_mapping_comparison');
end
if ~isfield(opts, 'timestamp') || isempty(opts.timestamp)
    opts.timestamp = datestr(now, 'yyyymmddTHHMMSS');
end

outputDir = fullfile(opts.outputRoot, opts.timestamp);
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

mappingNames = {'current'; 'rotDir'; 'minusRotDir'};
conditions = representative_conditions();
stateNames = get_state_names(Pbase);
controlNames = get_control_input_names(Pbase);
lateralIndex = find(strcmp(controlNames, 'lateralCyclic'), 1);
latRows = find_name_indices({'v'; 'p'; 'r'}, stateNames);
leakRows = find_name_indices({'u'; 'w'; 'q'}, stateNames);

records = {};
resultIndex = 0;
results = repmat(empty_result(), numel(mappingNames)*numel(conditions), 1);

for i = 1:numel(mappingNames)
    for j = 1:numel(conditions)
        resultIndex = resultIndex + 1;
        Pcase = Pbase;
        Pcase.control.lateralCyclicTheta1cMapping = mappingNames{i};
        result = evaluate_case(Pcase, mappingNames{i}, conditions(j), ...
            stateNames, lateralIndex, latRows, leakRows);
        results(resultIndex) = result;
    end
end

results = classify_results(results, conditions);
for i = 1:numel(results)
    r = results(i);
    records(end+1,:) = {r.condition, r.mapping, r.status, ...
        r.classification, r.reason, r.B_vdot, r.B_pdot, r.B_rdot, ...
        r.B_udot, r.B_wdot, r.B_qdot, r.fullBColumnNorm, ...
        r.maxBRowName, r.maxBValue, r.raw_dFy, r.raw_dMx, r.raw_dMz, ...
        r.rawLoadNorm, r.dTheta1cLeft, r.dTheta1cRight, ...
        r.dBeta1cLeft, r.dBeta1cRight, r.dBeta1sLeft, ...
        r.dBeta1sRight, r.dNDiskYLeft, r.dNDiskYRight, ...
        r.beta1sSameSign, r.nDiskYSameSign, r.lateralTargetNorm, ...
        r.longitudinalLeakNorm, r.ratio}; %#ok<AGROW>
end

T = cell2table(records, 'VariableNames', { ...
    'condition', 'mapping', 'status', 'classification', 'reason', ...
    'B_vdot', 'B_pdot', 'B_rdot', 'B_udot', 'B_wdot', 'B_qdot', ...
    'B_column_norm', 'max_B_row', 'max_B_value', ...
    'raw_dFy', 'raw_dMx', 'raw_dMz', 'raw_load_norm', ...
    'dTheta1c_left', 'dTheta1c_right', 'dBeta1c_left', ...
    'dBeta1c_right', 'dBeta1s_left', 'dBeta1s_right', ...
    'dNDiskY_left', 'dNDiskY_right', 'beta1s_same_sign', ...
    'nDiskY_same_sign', 'lateral_target_norm', ...
    'longitudinal_leak_norm', 'ratio'});

csvFile = fullfile(outputDir, 'lateral_cyclic_mapping_comparison.csv');
reportFile = fullfile(outputDir, 'lateral_cyclic_mapping_comparison_report.md');
writetable(T, csvFile);

recommendation = choose_recommendation(results, mappingNames, conditions);
write_markdown_report(reportFile, T, results, recommendation);

summary.outputDir = outputDir;
summary.reportFile = reportFile;
summary.csvFile = csvFile;
summary.table = T;
summary.results = results;
summary.mappingNames = mappingNames;
summary.recommendation = recommendation;
summary.successCount = sum(strcmp({results.status}, 'OK'));
end

function result = evaluate_case(Pcase, mappingName, condition, stateNames, ...
        lateralIndex, latRows, leakRows)
result = empty_result();
result.mapping = mappingName;
result.condition = condition.name;
result.V = condition.V;
result.betaMDeg = condition.betaMDeg;
result.status = 'FAIL_NONFINITE';
result.reason = '';

try
    [~, B, linReport] = linearize_numeric(condition.x, condition.u, ...
        condition.betaM, Pcase);
    raw = raw_load_derivative(condition.x, condition.u, condition.betaM, ...
        Pcase, lateralIndex);
    rotorDiag = rotor_diagnostics(condition.x, condition.u, ...
        condition.betaM, Pcase, lateralIndex);

    if ~linReport.finite || ~is_real_finite(B) || ~is_real_finite(raw) || ...
            ~rotorDiag.finite
        error('compare_lateral_cyclic_mappings:NonFiniteDerivative', ...
            'Derivative calculation returned non-finite or complex values.');
    end

    bCol = B(:, lateralIndex);
    [~, maxIdx] = max(abs(bCol));
    result.status = 'OK';
    result.reason = 'finite representative operating point';
    result.B_vdot = B(latRows(1), lateralIndex);
    result.B_pdot = B(latRows(2), lateralIndex);
    result.B_rdot = B(latRows(3), lateralIndex);
    result.B_udot = B(leakRows(1), lateralIndex);
    result.B_wdot = B(leakRows(2), lateralIndex);
    result.B_qdot = B(leakRows(3), lateralIndex);
    result.fullBColumnNorm = norm(bCol);
    result.maxBRowName = stateNames{maxIdx};
    result.maxBValue = bCol(maxIdx);
    result.raw_dFy = raw(2);
    result.raw_dMx = raw(4);
    result.raw_dMz = raw(6);
    result.rawLoadNorm = norm(raw);
    result.dTheta1cLeft = rotorDiag.dTheta1cLeft;
    result.dTheta1cRight = rotorDiag.dTheta1cRight;
    result.dBeta1cLeft = rotorDiag.dBeta1cLeft;
    result.dBeta1cRight = rotorDiag.dBeta1cRight;
    result.dBeta1sLeft = rotorDiag.dBeta1sLeft;
    result.dBeta1sRight = rotorDiag.dBeta1sRight;
    result.dNDiskYLeft = rotorDiag.dNDiskYLeft;
    result.dNDiskYRight = rotorDiag.dNDiskYRight;
    result.beta1sSameSign = same_sign(result.dBeta1sLeft, ...
        result.dBeta1sRight);
    result.nDiskYSameSign = same_sign(result.dNDiskYLeft, ...
        result.dNDiskYRight);
    result.lateralTargetNorm = norm([B(latRows, lateralIndex); ...
        raw([2 4 6])]);
    result.longitudinalLeakNorm = norm(B(leakRows, lateralIndex));
    result.ratio = result.lateralTargetNorm / ...
        max(result.longitudinalLeakNorm, eps);
catch ME
    result.reason = sprintf('%s: %s', ME.identifier, ME.message);
end
end

function results = classify_results(results, conditions)
for i = 1:numel(conditions)
    conditionMask = strcmp({results.condition}, conditions(i).name);
    currentMask = conditionMask & strcmp({results.mapping}, 'current');
    currentTarget = max([results(currentMask).lateralTargetNorm], eps);
    currentBLat = norm([results(currentMask).B_vdot; ...
        results(currentMask).B_pdot; results(currentMask).B_rdot]);

    for j = find(conditionMask)
        r = results(j);
        if ~strcmp(r.status, 'OK')
            results(j).classification = 'FAIL_NONFINITE';
            continue;
        end

        bLatNorm = norm([r.B_vdot; r.B_pdot; r.B_rdot]);
        rawTargetNorm = norm([r.raw_dFy; r.raw_dMx; r.raw_dMz]);
        targetNonzero = bLatNorm > 1e-8 || rawTargetNorm > 1e-6;
        strongImprovement = r.lateralTargetNorm > 10*currentTarget && ...
            bLatNorm > max(10*currentBLat, 1e-8);

        if r.fullBColumnNorm <= 1e-10 && r.rawLoadNorm <= 1e-7
            results(j).classification = 'FAIL_ZERO_COLUMN';
            results(j).reason = 'full B column and raw load response are near zero';
        elseif strcmp(r.mapping, 'current') && ...
                (~r.nDiskYSameSign || ~r.beta1sSameSign) && ...
                bLatNorm < 1e-8 && r.longitudinalLeakNorm > 1e-8
            results(j).classification = 'CURRENT_CANCELLATION_CONFIRMED';
            results(j).reason = ['left/right beta1s or nDiskY oppose while ' ...
                'longitudinal/pitch leakage remains'];
        elseif r.nDiskYSameSign && targetNonzero && strongImprovement
            results(j).classification = 'PROMISING_LATERAL_MAPPING';
            results(j).reason = ['left/right nDiskY align and lateral target ' ...
                'response improves over current'];
        elseif r.longitudinalLeakNorm > max(bLatNorm, 1e-12) && ...
                bLatNorm < 1e-8
            results(j).classification = 'LONGITUDINAL_LEAK_DOMINANT';
            results(j).reason = 'full B column is nonzero but u/w/q dominate over v/p/r';
        else
            results(j).classification = 'SIGN_AMBIGUOUS';
            results(j).reason = 'response exists but signs or target dominance are not decisive';
        end
    end
end
end

function recommendation = choose_recommendation(results, mappingNames, conditions)
recommendation.name = 'no-better-candidate';
recommendation.reason = 'no rotDir candidate clearly outperformed current';
recommendation.score = NaN;

bestName = '';
bestScore = -Inf;
for i = 2:numel(mappingNames)
    mapping = mappingNames{i};
    score = 0;
    for j = 1:numel(conditions)
        candidate = results(strcmp({results.mapping}, mapping) & ...
            strcmp({results.condition}, conditions(j).name));
        current = results(strcmp({results.mapping}, 'current') & ...
            strcmp({results.condition}, conditions(j).name));
        if strcmp(candidate.status, 'OK') && strcmp(current.status, 'OK')
            improvement = candidate.lateralTargetNorm / ...
                max(current.lateralTargetNorm, eps);
            score = score + log10(max(improvement, eps));
            if candidate.nDiskYSameSign
                score = score + 1;
            end
            if strcmp(candidate.classification, 'PROMISING_LATERAL_MAPPING')
                score = score + 2;
            end
        end
    end
    if score > bestScore
        bestScore = score;
        bestName = mapping;
    end
end

if bestScore > 2
    recommendation.name = bestName;
    recommendation.score = bestScore;
    recommendation.reason = ['candidate improves lateral target response ' ...
        'and aligns left/right nDiskY in representative conditions'];
end
end

function conditions = representative_conditions()
d2r = pi/180;
conditions = repmat(struct('name', '', 'V', NaN, 'betaMDeg', NaN, ...
    'betaM', NaN, 'x', NaN(9,1), 'u', NaN(8,1)), 4, 1);
conditions(1).name = 'hover_like_beta0';
conditions(1).V = 0;
conditions(1).betaMDeg = 0;
conditions(1).u = [18; 0; 0; 0; 0; 0; 0; 0]*d2r;

conditions(2).name = 'low_speed_helicopter';
conditions(2).V = 20;
conditions(2).betaMDeg = 0;
conditions(2).u = [12; 0; 0; 0; 0; 0; 0; 0]*d2r;

conditions(3).name = 'conversion_mid';
conditions(3).V = 45;
conditions(3).betaMDeg = 45;
conditions(3).u = [10; 0; 0; 0; 0; 0; 0; 0]*d2r;

conditions(4).name = 'airplane_forward';
conditions(4).V = 100;
conditions(4).betaMDeg = 90;
conditions(4).u = [8; 0; 0; 0; 0; 0; -2; 0]*d2r;

for i = 1:numel(conditions)
    conditions(i).betaM = conditions(i).betaMDeg*d2r;
    conditions(i).x = [conditions(i).V; 0; 0; 0; 0; 0; 0; 0; 0];
end
end

function raw = raw_load_derivative(x, u, betaM, P, controlIndex)
h = 1.0e-4;
up = u;
um = u;
up(controlIndex) = up(controlIndex) + h;
um(controlIndex) = um(controlIndex) - h;
[Fp, Mp] = total_forces_moments(x, up, betaM, P);
[Fm, Mm] = total_forces_moments(x, um, betaM, P);
raw = [(Fp-Fm); (Mp-Mm)]/(2*h);
end

function diag = rotor_diagnostics(x, u, betaM, P, controlIndex)
h = 1.0e-4;
up = u;
um = u;
up(controlIndex) = up(controlIndex) + h;
um(controlIndex) = um(controlIndex) - h;
[~, ~, outP] = total_forces_moments(x, up, betaM, P);
[~, ~, outM] = total_forces_moments(x, um, betaM, P);

leftP = outP.rotorLeft;
leftM = outM.rotorLeft;
rightP = outP.rotorRight;
rightM = outM.rotorRight;
diag.dTheta1cLeft = (leftP.theta1c-leftM.theta1c)/(2*h);
diag.dTheta1cRight = (rightP.theta1c-rightM.theta1c)/(2*h);
diag.dBeta1cLeft = (leftP.beta1c-leftM.beta1c)/(2*h);
diag.dBeta1cRight = (rightP.beta1c-rightM.beta1c)/(2*h);
diag.dBeta1sLeft = (leftP.beta1s-leftM.beta1s)/(2*h);
diag.dBeta1sRight = (rightP.beta1s-rightM.beta1s)/(2*h);
diag.dNDiskYLeft = (leftP.nDisk(2)-leftM.nDisk(2))/(2*h);
diag.dNDiskYRight = (rightP.nDisk(2)-rightM.nDisk(2))/(2*h);
values = [diag.dTheta1cLeft; diag.dTheta1cRight; ...
    diag.dBeta1cLeft; diag.dBeta1cRight; diag.dBeta1sLeft; ...
    diag.dBeta1sRight; diag.dNDiskYLeft; diag.dNDiskYRight];
diag.finite = is_real_finite(values);
end

function result = empty_result()
result = struct('condition', '', 'mapping', '', 'status', '', ...
    'classification', '', 'reason', '', 'V', NaN, 'betaMDeg', NaN, ...
    'B_vdot', NaN, 'B_pdot', NaN, 'B_rdot', NaN, 'B_udot', NaN, ...
    'B_wdot', NaN, 'B_qdot', NaN, 'fullBColumnNorm', NaN, ...
    'maxBRowName', '', 'maxBValue', NaN, 'raw_dFy', NaN, ...
    'raw_dMx', NaN, 'raw_dMz', NaN, 'rawLoadNorm', NaN, ...
    'dTheta1cLeft', NaN, 'dTheta1cRight', NaN, ...
    'dBeta1cLeft', NaN, 'dBeta1cRight', NaN, ...
    'dBeta1sLeft', NaN, 'dBeta1sRight', NaN, ...
    'dNDiskYLeft', NaN, 'dNDiskYRight', NaN, ...
    'beta1sSameSign', false, 'nDiskYSameSign', false, ...
    'lateralTargetNorm', NaN, 'longitudinalLeakNorm', NaN, ...
    'ratio', NaN);
end

function write_markdown_report(reportFile, T, results, recommendation)
fid = fopen(reportFile, 'w');
if fid < 0
    error('compare_lateral_cyclic_mappings:CannotOpenReport', ...
        'Cannot open report file for writing.');
end
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, '# Lateral Cyclic Theta1c Mapping Comparison\n\n');
fprintf(fid, 'This diagnostic compares lateralCyclic theta1c mapping candidates ');
fprintf(fid, 'inside the current model. It is not Berger/XV-15 validation and ');
fprintf(fid, 'does not implement 13x10 or nacelle torque.\n\n');

fprintf(fid, '## Problem\n\n');
fprintf(fid, 'The current mapping has a nonzero full B column, but the ');
fprintf(fid, '`v/p/r` target rows and raw `Fy/Mx/Mz` response are small. ');
fprintf(fid, 'The nonzero full B column mainly comes from longitudinal/pitch leakage.\n\n');

fprintf(fid, '## Candidate Mappings\n\n');
fprintf(fid, '- `current`: `theta1c = lateralCyclic`\n');
fprintf(fid, '- `rotDir`: `theta1c = rotDir*lateralCyclic`\n');
fprintf(fid, '- `minusRotDir`: `theta1c = -rotDir*lateralCyclic`\n\n');

fprintf(fid, '## Recommendation\n\n');
fprintf(fid, 'Recommended candidate: `%s`.\n\n', recommendation.name);
fprintf(fid, 'Reason: %s. Score: %.6g.\n\n', recommendation.reason, ...
    recommendation.score);

fprintf(fid, '## Comparison Table\n\n');
fprintf(fid, '|condition|mapping|classification|lateral_target_norm|');
fprintf(fid, 'longitudinal_leak_norm|ratio|B_vdot|B_pdot|B_rdot|');
fprintf(fid, 'raw_dFy|raw_dMx|raw_dMz|dBeta1s_L|dBeta1s_R|');
fprintf(fid, 'dNDiskY_L|dNDiskY_R|max_B_row|reason|\n');
fprintf(fid, '|-|-|-:|-:|-:|-:|-:|-:|-:|-:|-:|-:|-:|-:|-:|-:|-|-|\n');
for i = 1:height(T)
    fprintf(fid, ['|%s|%s|%s|%.6e|%.6e|%.6e|%.6e|%.6e|%.6e|' ...
        '%.6e|%.6e|%.6e|%.6e|%.6e|%.6e|%.6e|%s|%s|\n'], ...
        T.condition{i}, T.mapping{i}, T.classification{i}, ...
        T.lateral_target_norm(i), T.longitudinal_leak_norm(i), ...
        T.ratio(i), T.B_vdot(i), T.B_pdot(i), T.B_rdot(i), ...
        T.raw_dFy(i), T.raw_dMx(i), T.raw_dMz(i), ...
        T.dBeta1s_left(i), T.dBeta1s_right(i), ...
        T.dNDiskY_left(i), T.dNDiskY_right(i), ...
        T.max_B_row{i}, T.reason{i});
end

fprintf(fid, '\n## Mapping Findings\n\n');
write_mapping_summary(fid, results, 'current');
write_mapping_summary(fid, results, 'rotDir');
write_mapping_summary(fid, results, 'minusRotDir');

fprintf(fid, '\n## betaM Sign Variation\n\n');
fprintf(fid, 'A sign change across betaM representative points is not by itself ');
fprintf(fid, 'a bug. Nacelle angle changes rotor-axis and disk-plane projections ');
fprintf(fid, 'into body axes, plus inflow, flapping, moment-arm, and aerodynamic ');
fprintf(fid, 'coupling. This comparison is limited to model-internal effectiveness ');
fprintf(fid, 'of the mapping candidates and does not provide external sign validation.\n');

fprintf(fid, '\n## Limits\n\n');
fprintf(fid, '- This is an internal diagnostic using finite representative points.\n');
fprintf(fid, '- No mass, inertia, geometry, `rotDir`, or `psi` definition is changed.\n');
fprintf(fid, '- No final external sign convention is claimed.\n');
fprintf(fid, '- No 13x10, nacelle torque, or Berger 51-state model is implemented.\n');
end

function write_mapping_summary(fid, results, mapping)
items = results(strcmp({results.mapping}, mapping));
classes = {items.classification};
fprintf(fid, '- `%s`: %d promising, %d current-cancellation, %d leak-dominant, %d ambiguous.\n', ...
    mapping, sum(strcmp(classes, 'PROMISING_LATERAL_MAPPING')), ...
    sum(strcmp(classes, 'CURRENT_CANCELLATION_CONFIRMED')), ...
    sum(strcmp(classes, 'LONGITUDINAL_LEAK_DOMINANT')), ...
    sum(strcmp(classes, 'SIGN_AMBIGUOUS')));
end

function idx = find_name_indices(queryNames, names)
idx = zeros(numel(queryNames), 1);
for k = 1:numel(queryNames)
    idx(k) = find(strcmp(names, queryNames{k}), 1);
    if isempty(idx(k))
        error('compare_lateral_cyclic_mappings:MissingName', ...
            'Missing name %s.', queryNames{k});
    end
end
end

function tf = same_sign(a, b)
tol = 1.0e-10;
tf = abs(a) > tol && abs(b) > tol && sign(a) == sign(b);
end

function tf = is_real_finite(value)
tf = isnumeric(value) && isreal(value) && all(isfinite(value(:)));
end
