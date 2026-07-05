function report = run_full_angle_trim_envelope_resumable(opts)
%RUN_FULL_ANGLE_TRIM_ENVELOPE_RESUMABLE Run point-by-point trim evidence.
% Completed points are skipped only when the stored input hash still matches.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir, 'model'));
addpath(fullfile(rootDir, 'model', 'wing'));
addpath(fullfile(rootDir, 'analysis'));

if nargin < 1 || isempty(opts)
    opts = struct();
end
opts = apply_defaults(opts, rootDir);
ensure_dir(opts.outputDir);
ensure_dir(fullfile(opts.outputDir, 'points'));

plan = make_plan(opts);
records = repmat(empty_record(), 0, 1);
seedState = struct();
runTimer = tic;
fprintf('\nFull-angle trim envelope resumable run\n');
fprintf('======================================\n');
fprintf('Output directory: %s\n', opts.outputDir);
fprintf('Planned points: %d\n', numel(plan));

for i = 1:numel(plan)
    spec = plan(i);
    [spec, seedState] = attach_seed(spec, seedState, opts.outputDir);
    pointTimer = tic;
    result = run_full_angle_trim_point(spec);
    record = record_from_result(result, spec, toc(pointTimer));
    records(end+1, 1) = record; %#ok<AGROW>
    seedState = update_seed_state(seedState, result);
    fprintf('%3d/%3d beta=%5.1f V=%6.1f %-10s %-30s res=%.3e runtime=%.1fs\n', ...
        i, numel(plan), spec.betaM_deg, spec.V_mps, spec.modelType, ...
        result.status, result.residualNorm, record.controllerRuntime_s);
end

elapsed = toc(runTimer);
[resultsTable, summaryTable, gateTable] = ...
    collect_full_angle_trim_envelope_results(opts.outputDir, plan);
report = struct();
report.outputDir = opts.outputDir;
report.elapsed_s = elapsed;
report.plan = plan;
report.records = records;
report.resultsTable = resultsTable;
report.summaryTable = summaryTable;
report.gateTable = gateTable;
save(fullfile(opts.outputDir, 'full_angle_trim_envelope_run.mat'), ...
    'report', '-v7');
end

function opts = apply_defaults(opts, rootDir)
if ~isfield(opts, 'outputDir')
    opts.outputDir = fullfile(rootDir, 'validation', ...
        'wing_full_angle', 'trim_envelope');
end
if ~isfield(opts, 'models'), opts.models = {'legacy','full_angle'}; end
if ~isfield(opts, 'stages'), opts.stages = {'A','B'}; end
if ~isfield(opts, 'casePrefix'), opts.casePrefix = 'trim_envelope'; end
if ~isfield(opts, 'maxSeedSets'), opts.maxSeedSets = 4; end
if ~isfield(opts, 'customPlan'), opts.customPlan = []; end
if ~isfield(opts, 'forceRerun'), opts.forceRerun = false; end
end

function plan = make_plan(opts)
if ~isempty(opts.customPlan)
    plan = normalize_custom_plan(opts.customPlan, opts);
    return;
end
points = repmat(base_spec(opts), 0, 1);
if any(strcmp(opts.stages, 'A'))
    smoke = [0 12; 15 30; 45 60; 75 100; 90 100];
    points = append_specs(points, smoke, 'stageA_smoke', opts);
end
if any(strcmp(opts.stages, 'B'))
    points = append_specs(points, [zeros(7,1), [0;5;10;15;20;25;30]], ...
        'stageB_beta0', opts);
    points = append_specs(points, [15*ones(6,1), [10;20;30;40;50;60]], ...
        'stageB_beta15', opts);
    points = append_specs(points, [45*ones(5,1), [35;50;65;80;95]], ...
        'stageB_beta45', opts);
    points = append_specs(points, [75*ones(6,1), [70;85;100;115;130;145]], ...
        'stageB_beta75', opts);
    points = append_specs(points, [90*ones(7,1), [70;85;100;115;130;145;150]], ...
        'stageB_beta90', opts);
end
plan = unique_specs(points);
end

function plan = normalize_custom_plan(customPlan, opts)
plan = repmat(base_spec(opts), 0, 1);
for i = 1:numel(customPlan)
    item = customPlan(i);
    models = opts.models;
    if isfield(item, 'modelType') && ~isempty(item.modelType)
        models = {char(item.modelType)};
    end
    for j = 1:numel(models)
        spec = base_spec(opts);
        spec.caseName = field_or(item, 'caseName', opts.casePrefix);
        spec.betaM_deg = item.betaM_deg;
        spec.V_mps = item.V_mps;
        spec.modelType = models{j};
        spec.mode = mode_for_beta(spec.betaM_deg);
        if isfield(item, 'mode') && ~isempty(item.mode)
            spec.mode = char(item.mode);
        end
        plan(end+1, 1) = spec; %#ok<AGROW>
    end
end
plan = unique_specs(plan);
end

function specs = append_specs(specs, betaSpeed, caseName, opts)
for i = 1:size(betaSpeed, 1)
    for j = 1:numel(opts.models)
        spec = base_spec(opts);
        spec.caseName = caseName;
        spec.betaM_deg = betaSpeed(i, 1);
        spec.V_mps = betaSpeed(i, 2);
        spec.modelType = opts.models{j};
        spec.mode = mode_for_beta(spec.betaM_deg);
        specs(end+1, 1) = spec; %#ok<AGROW>
    end
end
end

function spec = base_spec(opts)
spec = struct();
spec.schemaVersion = 1;
spec.caseName = opts.casePrefix;
spec.modelType = 'legacy';
spec.mode = '';
spec.betaM_deg = NaN;
spec.V_mps = NaN;
spec.gamma_deg = 0;
spec.seedSource = 'factory';
spec.seedSet = {};
spec.seedNames = {};
spec.maxSeedSets = opts.maxSeedSets;
spec.forceRerun = opts.forceRerun;
spec.outputDir = opts.outputDir;
end

function specs = unique_specs(specs)
if isempty(specs)
    return;
end
keys = cell(numel(specs), 1);
for i = 1:numel(specs)
    keys{i} = sprintf('%s|%03.9g|%03.9g', ...
        specs(i).modelType, specs(i).betaM_deg, specs(i).V_mps);
end
[~, idx] = unique(keys, 'stable');
specs = specs(sort(idx));
[~, order] = sortrows([[specs.betaM_deg].', [specs.V_mps].', ...
    model_order({specs.modelType})]);
specs = specs(order);
end

function order = model_order(models)
order = zeros(numel(models), 1);
for i = 1:numel(models)
    order(i) = 1 + strcmp(models{i}, 'full_angle');
end
end

function [spec, seedState] = attach_seed(spec, seedState, outputDir)
seeds = {};
names = {};
betaKey = beta_key(spec.betaM_deg);
modelKey = matlab.lang.makeValidName(spec.modelType);
if isfield(seedState, betaKey) && isfield(seedState.(betaKey), modelKey)
    state = seedState.(betaKey).(modelKey);
    if ~isempty(state.lastSeed)
        seeds{end+1} = state.lastSeed; %#ok<AGROW>
        names{end+1} = ['continuation_' spec.modelType]; %#ok<AGROW>
    end
    if ~isempty(state.prevSeed) && numel(state.prevSeed) == numel(state.lastSeed)
        extrap = 2*state.lastSeed - state.prevSeed;
        seeds{end+1} = extrap; %#ok<AGROW>
        names{end+1} = ['two_point_extrapolation_' spec.modelType]; %#ok<AGROW>
    end
end
nearestSeed = nearest_saved_seed(outputDir, spec, spec.modelType);
if ~isempty(nearestSeed)
    seeds{end+1} = nearestSeed; %#ok<AGROW>
    names{end+1} = ['nearest_saved_' spec.modelType]; %#ok<AGROW>
end
if strcmp(spec.modelType, 'full_angle')
    legacySeed = matching_seed(outputDir, spec, 'legacy');
    if ~isempty(legacySeed)
        seeds{end+1} = legacySeed; %#ok<AGROW>
        names{end+1} = 'legacy_same_condition'; %#ok<AGROW>
    end
end
spec.seedSet = seeds;
spec.seedNames = names;
if isempty(names)
    spec.seedSource = 'factory';
else
    spec.seedSource = names{1};
end
end

function seed = nearest_saved_seed(outputDir, spec, modelType)
seed = [];
pointDir = fullfile(outputDir, 'points');
files = dir(fullfile(pointDir, sprintf('beta%03.0f_V*_%s.mat', ...
    spec.betaM_deg, modelType)));
bestDistance = Inf;
for i = 1:numel(files)
    loaded = load(fullfile(files(i).folder, files(i).name), 'result');
    if ~isfield(loaded, 'result') || ~loaded.result.converged
        continue;
    end
    candidateSeed = seed_from_result(loaded.result);
    if isempty(candidateSeed)
        continue;
    end
    distance = abs(loaded.result.V_mps - spec.V_mps);
    if distance < bestDistance && distance > 1e-9
        bestDistance = distance;
        seed = candidateSeed;
    end
end
end

function seed = matching_seed(outputDir, spec, modelType)
seed = [];
path = fullfile(outputDir, 'points', sprintf('beta%03.0f_V%03.0f_%s.mat', ...
    spec.betaM_deg, spec.V_mps, modelType));
if exist(path, 'file') ~= 2
    return;
end
loaded = load(path, 'result');
if ~isfield(loaded, 'result') || ~loaded.result.converged
    return;
end
seed = seed_from_result(loaded.result);
end

function seedState = update_seed_state(seedState, result)
if ~result.converged
    return;
end
seed = seed_from_result(result);
if isempty(seed)
    return;
end
betaKey = beta_key(result.betaM_deg);
modelKey = matlab.lang.makeValidName(result.modelType);
if ~isfield(seedState, betaKey)
    seedState.(betaKey) = struct();
end
if ~isfield(seedState.(betaKey), modelKey)
    seedState.(betaKey).(modelKey) = struct('lastSeed', [], 'prevSeed', []);
end
seedState.(betaKey).(modelKey).prevSeed = ...
    seedState.(betaKey).(modelKey).lastSeed;
seedState.(betaKey).(modelKey).lastSeed = seed;
end

function seed = seed_from_result(result)
seed = [];
if ~isfield(result, 'trimReport') || ~isfield(result.trimReport, 'trimVariables')
    return;
end
seed = zeros(numel(result.unknownNames), 1);
for i = 1:numel(result.unknownNames)
    name = result.unknownNames{i};
    if isfield(result.trimReport.trimVariables, name)
        seed(i) = result.trimReport.trimVariables.(name);
    else
        seed = [];
        return;
    end
end
end

function key = beta_key(betaDeg)
key = sprintf('beta_%03.0f', betaDeg);
end

function record = record_from_result(result, spec, controllerRuntime)
record = empty_record();
record.caseName = spec.caseName;
record.modelType = spec.modelType;
record.betaM_deg = spec.betaM_deg;
record.V_mps = spec.V_mps;
record.mode = spec.mode;
record.status = result.status;
record.actuallyExecuted = result.actuallyExecuted;
record.converged = result.converged;
record.residualNorm = result.residualNorm;
record.controllerRuntime_s = controllerRuntime;
end

function record = empty_record()
record = struct('caseName', '', 'modelType', '', 'betaM_deg', NaN, ...
    'V_mps', NaN, 'mode', '', 'status', '', 'actuallyExecuted', false, ...
    'converged', false, 'residualNorm', NaN, 'controllerRuntime_s', NaN);
end

function value = field_or(s, name, fallback)
if isfield(s, name)
    value = s.(name);
else
    value = fallback;
end
end

function name = mode_for_beta(betaDeg)
if abs(betaDeg) < 1e-9
    name = 'helicopter_longitudinal';
elseif abs(betaDeg - 90) < 1e-9
    name = 'airplane_longitudinal';
else
    name = 'conversion_longitudinal';
end
end

function ensure_dir(path)
if exist(path, 'dir') ~= 7
    mkdir(path);
end
end
