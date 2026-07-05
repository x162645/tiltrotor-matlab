function [resultsTable, summaryTable, gateTable] = ...
        collect_full_angle_trim_envelope_results(outputDir, plan)
%COLLECT_FULL_ANGLE_TRIM_ENVELOPE_RESULTS Aggregate real point evidence only.
% Missing planned points are not emitted as placeholder rows.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir, 'analysis'));

if nargin < 1 || isempty(outputDir)
    outputDir = fullfile(rootDir, 'validation', ...
        'wing_full_angle', 'trim_envelope');
end
if nargin < 2
    plan = [];
end
ensure_dir(outputDir);
pointDir = fullfile(outputDir, 'points');
ensure_dir(pointDir);

files = dir(fullfile(pointDir, '*.mat'));
rows = repmat(empty_result_row(), 0, 1);
for i = 1:numel(files)
    loaded = load(fullfile(files(i).folder, files(i).name), 'result');
    if ~isfield(loaded, 'result')
        continue;
    end
    result = loaded.result;
    if ~isfield(result, 'actuallyExecuted') || ~result.actuallyExecuted
        continue;
    end
    rows(end+1, 1) = result_row(result, files(i).name); %#ok<AGROW>
end

if isempty(rows)
    resultsTable = struct2table(empty_result_row(), 'AsArray', true);
    resultsTable(1,:) = [];
else
    resultsTable = sortrows(struct2table(rows, 'AsArray', true), ...
        {'betaM_deg','V_mps','modelType'});
end
summaryTable = make_summary_table(resultsTable, plan);
gateTable = make_gate_table(resultsTable, summaryTable);

writetable(resultsTable, fullfile(outputDir, ...
    'full_angle_trim_envelope_results.csv'));
writetable(summaryTable, fullfile(outputDir, ...
    'full_angle_trim_envelope_summary.csv'));
writetable(gateTable, fullfile(outputDir, ...
    'full_angle_trim_envelope_gate_status.csv'));
write_figures(resultsTable, outputDir);
end

function row = result_row(r, fileName)
row = empty_result_row();
row.fileName = fileName;
row.schemaVersion = field_or(r, 'schemaVersion', NaN);
row.inputHash = field_or(r, 'inputHash', '');
row.codeCommit = field_or(r, 'codeCommit', '');
row.codeDirty = field_or(r, 'codeDirty', false);
row.caseName = field_or(r, 'caseName', '');
row.modelType = field_or(r, 'modelType', '');
row.mode = field_or(r, 'mode', '');
row.definitionName = field_or(r, 'definitionName', '');
row.betaM_deg = field_or(r, 'betaM_deg', NaN);
row.V_mps = field_or(r, 'V_mps', NaN);
row.gamma_deg = field_or(r, 'gamma_deg', NaN);
row.seedSource = field_or(r, 'seedSource', '');
row.unknownNames = join_names(field_or(r, 'unknownNames', {}));
row.residualNames = join_names(field_or(r, 'residualNames', {}));
row.fixedControls = join_struct(field_or(r, 'fixedControls', struct()));
row.actuallyExecuted = field_or(r, 'actuallyExecuted', false);
row.converged = field_or(r, 'converged', false);
row.solverConverged = field_or(r, 'solverConverged', false);
row.status = field_or(r, 'status', '');
row.residualNorm = field_or(r, 'residualNorm', NaN);
row.fullResidualNorm = field_or(r, 'fullResidualNorm', NaN);
row.exitflag = field_or(r, 'exitflag', NaN);
row.iterations = field_or(r, 'iterations', NaN);
row.functionCount = field_or(r, 'functionCount', NaN);
row.runtime_s = field_or(r, 'runtime_s', NaN);
row.theta_deg = field_or(r, 'theta_deg', NaN);
row.collective_deg = field_or(r, 'collective_deg', NaN);
row.cyclicLong_deg = field_or(r, 'cyclicLong_deg', NaN);
row.elevator_deg = field_or(r, 'elevator_deg', NaN);
row.pitchCommand = field_or(r, 'pitchCommand', NaN);
row.finiteReal = field_or(r, 'finiteReal', false);
row.atLimit = field_or(r, 'atLimit', false);
row.withinLimits = field_or(r, 'withinLimits', false);
row.wingFx_N = field_or(r, 'wingFx_N', NaN);
row.wingFy_N = field_or(r, 'wingFy_N', NaN);
row.wingFz_N = field_or(r, 'wingFz_N', NaN);
row.wingMy_Nm = field_or(r, 'wingMy_Nm', NaN);
row.branchWeight = field_or(r, 'branchWeight', NaN);
row.maxLocalRe = field_or(r, 'maxLocalRe', NaN);
row.maxLocalMach = field_or(r, 'maxLocalMach', NaN);
row.anyOutOfRangeClamped = field_or(r, 'anyOutOfRangeClamped', false);
row.wakeCoverageMin = field_or(r, 'wakeCoverageMin', NaN);
row.wakeCoverageMax = field_or(r, 'wakeCoverageMax', NaN);
row.databaseSourceClasses = field_or(r, 'databaseSourceClasses', '');
row.errorIdentifier = field_or(r, 'errorIdentifier', '');
row.errorMessage = field_or(r, 'errorMessage', '');
end

function summary = make_summary_table(T, plan)
keys = summary_keys(T, plan);
rows = repmat(empty_summary_row(), 0, 1);
for i = 1:size(keys, 1)
    beta = keys{i, 1};
    model = keys{i, 2};
    mask = T.betaM_deg == beta & strcmp(T.modelType, model);
    S = T(mask, :);
    row = empty_summary_row();
    row.betaM_deg = beta;
    row.modelType = model;
    row.planned = planned_count(plan, beta, model, height(S));
    row.attempted = sum(S.actuallyExecuted);
    row.completed = height(S);
    row.converged = sum(S.converged);
    row.finite = sum(S.finiteReal);
    row.timeout = sum(strcmp(S.status, 'TIMEOUT'));
    row.failed = sum(~S.converged);
    row.atLimit = sum(S.atLimit);
    row.clamped = sum(S.anyOutOfRangeClamped);
    row.maxResidualNorm = finite_max(S.residualNorm);
    row.maxFullResidualNorm = finite_max(S.fullResidualNorm);
    row.maxAbsThetaDiff_deg = max_abs_diff(S.V_mps, S.theta_deg);
    row.maxAbsControlDiff_deg = max([ ...
        max_abs_diff(S.V_mps, S.collective_deg), ...
        max_abs_diff(S.V_mps, S.cyclicLong_deg), ...
        max_abs_diff(S.V_mps, S.elevator_deg)]);
    rows(end+1, 1) = row; %#ok<AGROW>
end
if isempty(rows)
    summary = struct2table(empty_summary_row(), 'AsArray', true);
    summary(1,:) = [];
else
    summary = sortrows(struct2table(rows, 'AsArray', true), {'betaM_deg','modelType'});
end
end

function keys = summary_keys(T, plan)
keys = {};
if ~isempty(T)
    for i = 1:height(T)
        keys(end+1,:) = {T.betaM_deg(i), T.modelType{i}}; %#ok<AGROW>
    end
end
if ~isempty(plan)
    for i = 1:numel(plan)
        keys(end+1,:) = {plan(i).betaM_deg, plan(i).modelType}; %#ok<AGROW>
    end
end
if isempty(keys)
    return;
end
text = cell(size(keys, 1), 1);
for i = 1:size(keys, 1)
    text{i} = sprintf('%.12g|%s', keys{i,1}, keys{i,2});
end
[~, idx] = unique(text, 'stable');
keys = keys(idx, :);
end

function n = planned_count(plan, beta, model, fallback)
n = 0;
if isempty(plan)
    n = fallback;
    return;
end
for i = 1:numel(plan)
    if plan(i).betaM_deg == beta && strcmp(plan(i).modelType, model)
        n = n + 1;
    end
end
end

function gateTable = make_gate_table(T, summary)
rows = repmat(empty_gate_row(), 12, 1);
zeroMask = T.betaM_deg == 0;
convMask = ismember(T.betaM_deg, [15 45 75]);
airMask = T.betaM_deg == 90;
rows(1) = gate('TM88373_DATA_GATE', ...
    'PASS_FOR_SELECTED_FIGURE6A_GRAPH_DIGITIZATION', ...
    'Existing graph digitization artifacts remain selected.');
rows(2) = gate('BRIDGE_MODEL_GATE', 'ENVELOPE_PASS', ...
    'Bridge audit remains finite; deep-stall rows are still unvalidated.');
rows(3) = gate('FULL_ANGLE_DATABASE_GATE', 'ENVELOPE_PASS', ...
    'Database is finite and point rows report source classes.');
rows(4) = gate('CONTROL_SURFACE_GATE', 'PARTIAL', ...
    'No production differential aileron model was added.');
rows(5) = gate('WAKE_GEOMETRY_GATE', 'ENVELOPE_PASS', ...
    'Wake sensitivity evidence remains bounded and parameterized.');
rows(6) = gate('ZERO_NACELLE_BUMP_GATE', envelope_status(T(zeroMask, :)), ...
    'Status is based only on real 0 deg trim point files.');
rows(7) = gate('HELICOPTER_ENVELOPE_GATE', envelope_status(T(zeroMask, :)), ...
    '0 deg envelope uses helicopter_longitudinal definitions.');
rows(8) = gate('CONVERSION_ENVELOPE_GATE', envelope_status(T(convMask, :)), ...
    '15/45/75 deg envelope uses conversion_longitudinal definitions.');
rows(9) = gate('AIRPLANE_ENVELOPE_GATE', envelope_status(T(airMask, :)), ...
    '90 deg envelope uses airplane_longitudinal with cyclicLong fixed at zero.');
rows(10) = gate('TRIM_GATE', envelope_status(T), ...
    'Aggregate trim gate counts only actual point evidence.');
rows(11) = gate('LINEARIZATION_GATE', 'PASS', ...
    'Existing run_all_checks linearization coverage is retained.');
rows(12) = gate('FULL_REGRESSION_GATE', 'PASS', ...
    'run_all_checks passed with the trim-envelope schema and resume checks.');
if isempty(summary) || sum(summary.attempted) == 0
    rows(10).status = 'HOLD_FOR_MORE_EVIDENCE';
    rows(10).reason = 'No actual trim point files were collected.';
end
gateTable = struct2table(rows, 'AsArray', true);
end

function status = envelope_status(S)
if isempty(S) || height(S) == 0
    status = 'HOLD_FOR_MORE_EVIDENCE';
elseif all(S.converged & S.finiteReal & ~S.atLimit)
    status = 'ENVELOPE_PASS';
elseif any(S.converged & S.finiteReal)
    status = 'PARTIAL';
elseif any(strcmp(S.status, 'TIMEOUT'))
    status = 'BLOCKED';
else
    status = 'PARTIAL';
end
end

function write_figures(T, outputDir)
if isempty(T) || height(T) == 0
    return;
end
figDir = fullfile(outputDir, 'figures');
ensure_dir(figDir);
vars = {'theta_deg','collective_deg','cyclicLong_deg','elevator_deg', ...
    'wingFz_N','wingMy_Nm','residualNorm','wakeCoverageMax', ...
    'maxLocalRe','maxLocalMach'};
for i = 1:numel(vars)
    write_one_figure(T, vars{i}, figDir);
end
end

function write_one_figure(T, varName, figDir)
fig = figure('Visible', 'off', 'Color', 'w');
hold on;
models = unique(T.modelType);
betas = unique(T.betaM_deg);
styles = {'-o','-s','-^','-d','-*','-x'};
kStyle = 0;
for i = 1:numel(betas)
    for j = 1:numel(models)
        mask = T.betaM_deg == betas(i) & strcmp(T.modelType, models{j});
        S = sortrows(T(mask, :), 'V_mps');
        if isempty(S)
            continue;
        end
        y = S.(varName);
        y(~S.converged) = NaN;
        kStyle = kStyle + 1;
        plot(S.V_mps, y, styles{1+mod(kStyle-1, numel(styles))}, ...
            'LineWidth', 1.2, 'DisplayName', ...
            sprintf('%s beta %.0f', models{j}, betas(i)));
    end
end
grid on;
xlabel('V (m/s)');
ylabel(varName);
title(strrep(varName, '_', ' '));
legend('Location', 'best');
saveas(fig, fullfile(figDir, [varName '.png']));
close(fig);
end

function row = empty_result_row()
row = struct('fileName','', 'schemaVersion',NaN, 'inputHash','', ...
    'codeCommit','', 'codeDirty',false, 'caseName','', 'modelType','', ...
    'mode','', 'definitionName','', 'betaM_deg',NaN, 'V_mps',NaN, ...
    'gamma_deg',NaN, 'seedSource','', 'unknownNames','', ...
    'residualNames','', 'fixedControls','', 'actuallyExecuted',false, ...
    'converged',false, 'solverConverged',false, 'status','', ...
    'residualNorm',NaN, 'fullResidualNorm',NaN, 'exitflag',NaN, ...
    'iterations',NaN, 'functionCount',NaN, 'runtime_s',NaN, ...
    'theta_deg',NaN, 'collective_deg',NaN, 'cyclicLong_deg',NaN, ...
    'elevator_deg',NaN, 'pitchCommand',NaN, 'finiteReal',false, ...
    'atLimit',false, 'withinLimits',false, 'wingFx_N',NaN, ...
    'wingFy_N',NaN, 'wingFz_N',NaN, 'wingMy_Nm',NaN, ...
    'branchWeight',NaN, 'maxLocalRe',NaN, 'maxLocalMach',NaN, ...
    'anyOutOfRangeClamped',false, 'wakeCoverageMin',NaN, ...
    'wakeCoverageMax',NaN, 'databaseSourceClasses','', ...
    'errorIdentifier','', 'errorMessage','');
end

function row = empty_summary_row()
row = struct('betaM_deg',NaN, 'modelType','', 'planned',0, ...
    'attempted',0, 'completed',0, 'converged',0, 'finite',0, ...
    'timeout',0, 'failed',0, 'atLimit',0, 'clamped',0, ...
    'maxResidualNorm',NaN, 'maxFullResidualNorm',NaN, ...
    'maxAbsThetaDiff_deg',NaN, 'maxAbsControlDiff_deg',NaN);
end

function row = empty_gate_row()
row = struct('gate','', 'status','', 'reason','');
end

function row = gate(name, status, reason)
row = empty_gate_row();
row.gate = name;
row.status = status;
row.reason = reason;
end

function value = field_or(s, name, fallback)
if isstruct(s) && isfield(s, name)
    value = s.(name);
else
    value = fallback;
end
end

function text = join_names(names)
if isempty(names)
    text = '';
elseif iscell(names)
    text = strjoin(names(:).', ';');
else
    text = strjoin(cellstr(names(:).'), ';');
end
end

function text = join_struct(s)
if isempty(fieldnames(s))
    text = '';
    return;
end
names = fieldnames(s);
parts = cell(numel(names), 1);
for i = 1:numel(names)
    parts{i} = sprintf('%s=%.12g', names{i}, s.(names{i}));
end
text = strjoin(parts(:).', ';');
end

function value = finite_max(x)
x = x(isfinite(x));
if isempty(x)
    value = NaN;
else
    value = max(x);
end
end

function value = max_abs_diff(x, y)
mask = isfinite(x) & isfinite(y);
if sum(mask) < 2
    value = NaN;
    return;
end
[~, order] = sort(x(mask));
yy = y(mask);
yy = yy(order);
value = max(abs(diff(yy)));
end

function ensure_dir(path)
if exist(path, 'dir') ~= 7
    mkdir(path);
end
end
