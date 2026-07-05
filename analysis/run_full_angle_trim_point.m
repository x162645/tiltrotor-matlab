function result = run_full_angle_trim_point(spec)
%RUN_FULL_ANGLE_TRIM_POINT Execute and persist one full-wing trim point.
% The point file is the atomic evidence unit used by the resumable envelope
% runner. Unstarted points are never represented by fabricated NaN rows.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir, 'model'));
addpath(fullfile(rootDir, 'model', 'wing'));
addpath(fullfile(rootDir, 'analysis'));

if nargin < 1 || isempty(spec)
    spec = struct();
end
spec = apply_defaults(spec, rootDir);
validate_spec(spec);

ensure_dir(spec.outputDir);
ensure_dir(fullfile(spec.outputDir, 'points'));

pointPath = point_mat_path(spec);
summaryCsvPath = strrep(pointPath, '.mat', '.csv');
summaryJsonPath = strrep(pointPath, '.mat', '.json');
expectedHash = input_hash(spec);
if ~spec.forceRerun && exist(pointPath, 'file') == 2
    loaded = load(pointPath, 'result');
    if isfield(loaded, 'result') && isfield(loaded.result, 'inputHash') && ...
            strcmp(loaded.result.inputHash, expectedHash) && ...
            isfield(loaded.result, 'actuallyExecuted') && ...
            loaded.result.actuallyExecuted
        result = loaded.result;
        result.status = 'SKIPPED_EXISTING_VALID_RESULT';
        result.actuallyExecuted = false;
        result.runtime_s = 0;
        return;
    end
end

timer = tic;
result = base_result(spec, expectedHash);
try
    P = params_nominal();
    if strcmp(spec.modelType, 'full_angle')
        P.wing.modelType = 'fullAngle';
        P.wing.fullAngleModelEnabled = 1;
    elseif strcmp(spec.modelType, 'legacy')
        P.wing.modelType = 'legacy';
        P.wing.fullAngleModelEnabled = 0;
    else
        error('run_full_angle_trim_point:InvalidModelType', ...
            'modelType must be legacy or full_angle.');
    end

    condition = struct('V', spec.V_mps, ...
        'betaM', spec.betaM_deg*pi/180, 'gamma', spec.gamma_deg*pi/180);
    definition0 = make_trim_definition(spec.mode, condition, P);
    result.definitionName = definition0.name;
    result.unknownNames = definition0.unknownNames(:);
    result.residualNames = definition0.residualNames(:);
    result.fixedStates = definition0.fixedStates;
    result.fixedControls = definition0.fixedControls;
    result.allocation = allocation_or_empty(definition0);
    result.initialValues = definition0.initialValues(:);
    result.seedSource = spec.seedSource;

    attempts = make_attempts(definition0, spec);
    best = empty_attempt_result();
    for iAttempt = 1:numel(attempts)
        [candidate, score] = execute_attempt(condition, attempts(iAttempt), P);
        candidate.seedSource = attempts(iAttempt).name;
        if score < best.score
            best.score = score;
            best.candidate = candidate;
        end
        if strcmp(candidate.status, 'CONVERGED')
            break;
        end
    end

    if isempty(best.candidate)
        error('run_full_angle_trim_point:NoAttemptExecuted', ...
            'No trim attempts were executed.');
    end
    result = merge_candidate(result, best.candidate);
catch ME
    result.status = classify_error(ME);
    result.errorIdentifier = ME.identifier;
    result.errorMessage = ME.message;
end
result.runtime_s = toc(timer);
result.actuallyExecuted = true;
result.completedAt = datestr(now, 31);

save(pointPath, 'result', '-v7');
write_summary_csv(summaryCsvPath, result);
write_summary_json(summaryJsonPath, result);
end

function spec = apply_defaults(spec, rootDir)
if ~isfield(spec, 'schemaVersion'), spec.schemaVersion = 1; end
if ~isfield(spec, 'caseName'), spec.caseName = 'single_point'; end
if ~isfield(spec, 'modelType'), spec.modelType = 'legacy'; end
if ~isfield(spec, 'mode') || isempty(spec.mode)
    spec.mode = mode_for_beta(spec.betaM_deg);
end
if ~isfield(spec, 'gamma_deg'), spec.gamma_deg = 0; end
if ~isfield(spec, 'seedSource'), spec.seedSource = 'factory'; end
if ~isfield(spec, 'seedSet'), spec.seedSet = {}; end
if ~isfield(spec, 'seedNames'), spec.seedNames = {}; end
if ~isfield(spec, 'maxSeedSets'), spec.maxSeedSets = 4; end
if ~isfield(spec, 'forceRerun'), spec.forceRerun = false; end
if ~isfield(spec, 'outputDir')
    spec.outputDir = fullfile(rootDir, 'validation', ...
        'wing_full_angle', 'trim_envelope');
end
if ~isfield(spec, 'codeCommit'), spec.codeCommit = get_git_sha(rootDir); end
if ~isfield(spec, 'codeDirty'), spec.codeDirty = get_git_dirty(rootDir); end
end

function validate_spec(spec)
check_scalar(spec.V_mps, 'V_mps', @(x) x >= 0);
check_scalar(spec.betaM_deg, 'betaM_deg', @(x) x >= 0 && x <= 90);
check_scalar(spec.gamma_deg, 'gamma_deg', @(x) abs(x) <= 90);
if ~(ischar(spec.modelType) || isstring(spec.modelType))
    error('run_full_angle_trim_point:InvalidSpec', 'modelType must be text.');
end
spec.modelType = char(spec.modelType);
validModels = {'legacy','full_angle'};
if ~any(strcmp(spec.modelType, validModels))
    error('run_full_angle_trim_point:InvalidSpec', ...
        'modelType must be legacy or full_angle.');
end
end

function check_scalar(value, name, predicate)
if ~(isnumeric(value) && isreal(value) && isscalar(value) && ...
        isfinite(value) && predicate(value))
    error('run_full_angle_trim_point:InvalidSpec', ...
        '%s has an invalid value.', name);
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

function result = base_result(spec, hashValue)
result = struct();
result.schemaVersion = spec.schemaVersion;
result.inputHash = hashValue;
result.codeCommit = spec.codeCommit;
result.codeDirty = spec.codeDirty;
result.modelType = char(spec.modelType);
result.caseName = char(spec.caseName);
result.mode = char(spec.mode);
result.definitionName = '';
result.betaM_deg = spec.betaM_deg;
result.V_mps = spec.V_mps;
result.gamma_deg = spec.gamma_deg;
result.seedSource = char(spec.seedSource);
result.initialValues = [];
result.unknownNames = {};
result.residualNames = {};
result.fixedStates = struct();
result.fixedControls = struct();
result.allocation = struct();
result.times = struct('startedAt', datestr(now, 31), 'completedAt', '');
result.runtime_s = NaN;
result.actuallyExecuted = false;
result.converged = false;
result.solverConverged = false;
result.status = 'NOT_STARTED';
result.residualNorm = NaN;
result.fullResidualNorm = NaN;
result.exitflag = NaN;
result.iterations = NaN;
result.functionCount = NaN;
result.theta_deg = NaN;
result.collective_deg = NaN;
result.diffCollective_deg = NaN;
result.cyclicLong_deg = NaN;
result.diffCyclic_deg = NaN;
result.aileron_deg = NaN;
result.elevator_deg = NaN;
result.rudder_deg = NaN;
result.pitchCommand = NaN;
result.xTrim = NaN(9,1);
result.uTrim = NaN(7,1);
result.finiteReal = false;
result.atLimit = false;
result.withinLimits = false;
result.wingFx_N = NaN;
result.wingFy_N = NaN;
result.wingFz_N = NaN;
result.wingMx_Nm = NaN;
result.wingMy_Nm = NaN;
result.wingMz_Nm = NaN;
result.branchWeight = NaN;
result.maxLocalRe = NaN;
result.maxLocalMach = NaN;
result.anyOutOfRangeClamped = false;
result.wakeCoverageMin = NaN;
result.wakeCoverageMax = NaN;
result.databaseSourceClasses = '';
result.errorIdentifier = '';
result.errorMessage = '';
result.trimReport = struct();
result.credibility = struct();
result.forcesMoments = struct();
end

function attempts = make_attempts(definition0, spec)
seeds = {definition0.initialValues(:)};
names = {'factory'};
for i = 1:numel(spec.seedSet)
    z = spec.seedSet{i};
    if isnumeric(z) && numel(z) == numel(definition0.initialValues) && ...
            all(isfinite(z(:)))
        seeds{end+1} = z(:); %#ok<AGROW>
        if i <= numel(spec.seedNames) && ~isempty(spec.seedNames{i})
            names{end+1} = char(spec.seedNames{i}); %#ok<AGROW>
        else
            names{end+1} = sprintf('external_seed_%d', i); %#ok<AGROW>
        end
    end
end
[seeds, names] = unique_seed_list(seeds, names, spec.maxSeedSets);
attempts = repmat(struct('name', '', 'definition', definition0), ...
    numel(seeds), 1);
for i = 1:numel(seeds)
    attempts(i).name = names{i};
    attempts(i).definition = definition0;
    attempts(i).definition.initialValues = seeds{i};
end
end

function [seedsOut, namesOut] = unique_seed_list(seeds, names, maxCount)
keys = {};
seedsOut = {};
namesOut = {};
for i = 1:numel(seeds)
    key = sprintf('%.12g,', seeds{i});
    if any(strcmp(keys, key))
        continue;
    end
    keys{end+1} = key; %#ok<AGROW>
    seedsOut{end+1} = seeds{i}; %#ok<AGROW>
    namesOut{end+1} = names{i}; %#ok<AGROW>
    if numel(seedsOut) >= maxCount
        return;
    end
end
end

function [candidate, score] = execute_attempt(condition, attempt, P)
d2r = pi/180;
candidate = struct();
candidate.definition = attempt.definition;
candidate.xTrim = [];
candidate.uTrim = [];
candidate.trimReport = struct();
candidate.credibility = struct();
candidate.forcesMoments = struct();
candidate.status = 'RUNTIME_ERROR';
candidate.errorIdentifier = '';
candidate.errorMessage = '';
candidate.seedSource = attempt.name;
try
    [xTrim, uTrim, trimReport] = trim_general( ...
        condition, attempt.definition, P);
    credibility = diagnose_trim_credibility( ...
        condition, attempt.definition, xTrim, uTrim, trimReport, P);
    [~, ~, info] = total_forces_moments(xTrim, uTrim, condition.betaM, P);
    finiteReal = is_real_finite(xTrim) && is_real_finite(uTrim) && ...
        is_real_finite(trimReport.residual) && ...
        is_real_finite(trimReport.fullStateDerivative) && ...
        is_real_finite([info.F; info.M]);
    candidate.xTrim = xTrim(:);
    candidate.uTrim = uTrim(:);
    candidate.trimReport = trimReport;
    candidate.credibility = credibility;
    candidate.forcesMoments = info;
    candidate.finiteReal = finiteReal;
    candidate.status = classify_trim_status(trimReport, finiteReal);
    candidate.theta_deg = xTrim(8)/d2r;
    candidate.collective_deg = uTrim(1)/d2r;
    candidate.diffCollective_deg = uTrim(2)/d2r;
    candidate.cyclicLong_deg = uTrim(3)/d2r;
    candidate.diffCyclic_deg = uTrim(4)/d2r;
    candidate.aileron_deg = uTrim(5)/d2r;
    candidate.elevator_deg = uTrim(6)/d2r;
    candidate.rudder_deg = uTrim(7)/d2r;
    candidate.pitchCommand = NaN;
    if isfield(trimReport.trimVariables, 'pitchCommand')
        candidate.pitchCommand = trimReport.trimVariables.pitchCommand;
    end
catch ME
    candidate.status = classify_error(ME);
    candidate.errorIdentifier = ME.identifier;
    candidate.errorMessage = ME.message;
end
score = score_candidate(candidate);
end

function status = classify_trim_status(trimReport, finiteReal)
if ~finiteReal
    status = 'DOMAIN_ERROR';
elseif trimReport.converged
    status = 'CONVERGED';
elseif trimReport.atLimit || ~trimReport.withinLimits
    status = 'FAILED_LIMIT';
elseif ~trimReport.solverConverged
    status = 'FAILED_SOLVER';
else
    status = 'FAILED_RESIDUAL';
end
end

function status = classify_error(ME)
domainIds = {'rotor_model_bemt:FlapNotConverged', ...
    'rotor_model_bemt:CoupledSolveNotConverged', ...
    'pitch_allocation_schedule:InvalidPitchCommand', ...
    'wing_full_angle_lookup:OutOfRange', ...
    'wing_full_angle_lookup:InvalidCoefficient'};
if any(strcmp(ME.identifier, domainIds))
    status = 'DOMAIN_ERROR';
else
    status = 'RUNTIME_ERROR';
end
end

function score = score_candidate(candidate)
if isfield(candidate, 'trimReport') && isfield(candidate.trimReport, 'residualNorm')
    rn = candidate.trimReport.residualNorm;
    fn = candidate.trimReport.fullResidualNorm;
else
    rn = Inf;
    fn = Inf;
end
if strcmp(candidate.status, 'CONVERGED')
    score = rn;
elseif isfinite(rn)
    score = 1e6 + rn + fn;
else
    score = Inf;
end
end

function best = empty_attempt_result()
best = struct('score', Inf, 'candidate', []);
end

function result = merge_candidate(result, candidate)
result.seedSource = candidate.seedSource;
result.initialValues = candidate.definition.initialValues(:);
result.definitionName = candidate.definition.name;
result.unknownNames = candidate.definition.unknownNames(:);
result.residualNames = candidate.definition.residualNames(:);
result.fixedStates = candidate.definition.fixedStates;
result.fixedControls = candidate.definition.fixedControls;
result.allocation = allocation_or_empty(candidate.definition);
result.status = candidate.status;
result.errorIdentifier = candidate.errorIdentifier;
result.errorMessage = candidate.errorMessage;
if isempty(candidate.xTrim)
    return;
end
result.xTrim = candidate.xTrim;
result.uTrim = candidate.uTrim;
result.trimReport = candidate.trimReport;
result.credibility = candidate.credibility;
result.forcesMoments = candidate.forcesMoments;
result.converged = candidate.trimReport.converged;
result.solverConverged = candidate.trimReport.solverConverged;
result.residualNorm = candidate.trimReport.residualNorm;
result.fullResidualNorm = candidate.trimReport.fullResidualNorm;
result.exitflag = candidate.trimReport.exitflag;
result.iterations = get_output_field(candidate.trimReport.output, 'iterations');
result.functionCount = get_output_field(candidate.trimReport.output, 'funcCount');
result.theta_deg = candidate.theta_deg;
result.collective_deg = candidate.collective_deg;
result.diffCollective_deg = candidate.diffCollective_deg;
result.cyclicLong_deg = candidate.cyclicLong_deg;
result.diffCyclic_deg = candidate.diffCyclic_deg;
result.aileron_deg = candidate.aileron_deg;
result.elevator_deg = candidate.elevator_deg;
result.rudder_deg = candidate.rudder_deg;
result.pitchCommand = candidate.pitchCommand;
result.finiteReal = candidate.finiteReal;
result.atLimit = candidate.trimReport.atLimit;
result.withinLimits = candidate.trimReport.withinLimits;
[wing, found] = find_component(candidate.forcesMoments.components, 'wing');
if found
    result.wingFx_N = wing.F(1);
    result.wingFy_N = wing.F(2);
    result.wingFz_N = wing.F(3);
    result.wingMx_Nm = wing.M(1);
    result.wingMy_Nm = wing.M(2);
    result.wingMz_Nm = wing.M(3);
    result.branchWeight = mean_branch_weight(wing.data);
    [result.maxLocalRe, result.maxLocalMach, ...
        result.anyOutOfRangeClamped] = local_db_diagnostics(wing.data);
    [result.wakeCoverageMin, result.wakeCoverageMax] = ...
        wake_coverage_range(wing.data);
    result.databaseSourceClasses = database_source_classes();
end
end

function value = get_output_field(output, name)
if isstruct(output) && isfield(output, name)
    value = output.(name);
else
    value = NaN;
end
end

function allocation = allocation_or_empty(definition)
if isfield(definition, 'allocation')
    allocation = definition.allocation;
else
    allocation = struct();
end
end

function [component, found] = find_component(components, name)
component = struct();
found = false;
if iscell(components)
    for i = 1:numel(components)
        item = components{i};
        if isfield(item, 'name') && strcmp(item.name, name)
            component = item;
            found = true;
            return;
        end
    end
else
    for i = 1:numel(components)
        if strcmp(components(i).name, name)
            component = components(i);
            found = true;
            return;
        end
    end
end
end

function w = mean_branch_weight(data)
values = [];
if isfield(data, 'regions')
    for i = 1:numel(data.regions)
        r = data.regions{i};
        if isfield(r, 'normalFlowBranchWeight')
            values(end+1) = r.normalFlowBranchWeight; %#ok<AGROW>
        end
    end
end
if isempty(values)
    w = 0;
else
    w = mean(values);
end
end

function [maxRe, maxMach, anyClamp] = local_db_diagnostics(data)
maxRe = 0;
maxMach = 0;
anyClamp = false;
if ~isfield(data, 'strips')
    return;
end
for i = 1:numel(data.strips)
    s = data.strips{i};
    names = {'free', 'leftWake', 'rightWake'};
    for j = 1:numel(names)
        if isfield(s, names{j})
            q = s.(names{j});
            if isfield(q, 'Re'), maxRe = max(maxRe, q.Re); end
            if isfield(q, 'Mach'), maxMach = max(maxMach, q.Mach); end
            if isfield(q, 'outOfRangeClamped')
                anyClamp = anyClamp || q.outOfRangeClamped;
            end
        end
    end
end
end

function [mn, mx] = wake_coverage_range(data)
mn = NaN;
mx = NaN;
if isfield(data, 'wakeCoverage') && isfield(data.wakeCoverage, 'total')
    mn = min(data.wakeCoverage.total);
    mx = max(data.wakeCoverage.total);
end
end

function text = database_source_classes()
rootDir = fileparts(fileparts(mfilename('fullpath')));
dbPath = fullfile(rootDir, 'data', 'wing_full_angle', ...
    'full_angle_selected', 'wing_full_angle_database.csv');
if exist(dbPath, 'file') ~= 2
    text = '';
    return;
end
try
    T = readtable(dbPath, 'TextType', 'string');
    if ismember('source_class', T.Properties.VariableNames)
        classes = unique(T.source_class);
        text = strjoin(cellstr(classes(:).'), ';');
    else
        text = '';
    end
catch
    text = '';
end
end

function write_summary_csv(path, result)
row = point_summary_row(result);
writetable(struct2table(row, 'AsArray', true), path);
end

function write_summary_json(path, result)
row = point_summary_row(result);
fid = fopen(path, 'w');
if fid < 0
    error('run_full_angle_trim_point:JsonOpenFailed', ...
        'Cannot write JSON summary: %s', path);
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '%s\n', jsonencode(row));
end

function row = point_summary_row(r)
row = rmfield_for_summary(r);
row.unknownNames = join_names(r.unknownNames);
row.residualNames = join_names(r.residualNames);
row.fixedControls = join_struct(r.fixedControls);
row.fixedStates = join_struct(r.fixedStates);
row.allocation = allocation_summary(r.allocation);
row.initialValues = sprintf('%.12g;', r.initialValues);
end

function row = rmfield_for_summary(r)
fields = {'trimReport','credibility','forcesMoments','xTrim','uTrim', ...
    'times','fixedStates','fixedControls','allocation','unknownNames', ...
    'residualNames','initialValues'};
row = r;
for i = 1:numel(fields)
    if isfield(row, fields{i})
        row = rmfield(row, fields{i});
    end
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

function text = allocation_summary(s)
if isempty(fieldnames(s))
    text = '';
elseif isfield(s, 'type')
    text = s.type;
else
    text = 'allocation_struct';
end
end

function path = point_mat_path(spec)
name = sprintf('beta%03.0f_V%03.0f_%s.mat', ...
    spec.betaM_deg, spec.V_mps, spec.modelType);
path = fullfile(spec.outputDir, 'points', name);
end

function hashValue = input_hash(spec)
hashSpec = struct('schemaVersion', spec.schemaVersion, ...
    'caseName', spec.caseName, 'modelType', spec.modelType, ...
    'mode', spec.mode, 'betaM_deg', spec.betaM_deg, ...
    'V_mps', spec.V_mps, 'gamma_deg', spec.gamma_deg, ...
    'codeCommit', spec.codeCommit);
hashValue = stable_hash(jsonencode(hashSpec));
end

function hash = stable_hash(text)
md = java.security.MessageDigest.getInstance('MD5');
md.update(uint8(text));
bytes = typecast(md.digest(), 'uint8');
hex = dec2hex(bytes).';
hash = lower(hex(:).');
end

function sha = get_git_sha(rootDir)
[status, text] = system(sprintf('git -C "%s" rev-parse HEAD', rootDir));
if status == 0
    sha = strtrim(text);
else
    sha = 'UNKNOWN';
end
end

function dirty = get_git_dirty(rootDir)
[status, text] = system(sprintf('git -C "%s" status --short --untracked-files=no', rootDir));
dirty = status ~= 0 || ~isempty(strtrim(text));
end

function ensure_dir(path)
if exist(path, 'dir') ~= 7
    mkdir(path);
end
end

function tf = is_real_finite(value)
tf = isreal(value) && all(isfinite(value(:)));
end
