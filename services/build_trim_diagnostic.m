function diagnostic = build_trim_diagnostic(trimResult)
%BUILD_TRIM_DIAGNOSTIC Convert a completed trim service result to GUI data.
% The function only reads fields already returned by the trim service/report.

if nargin < 1 || isempty(trimResult)
    error('build_trim_diagnostic:MissingTrimResult', ...
        'A completed trim result structure is required.');
end

report = get_field(trimResult, 'report', struct());
tol = get_first_existing(report, trimResult, ...
    {'residualTolerance', 'trimResidualTolerance'}, NaN);

diagnostic.kind = 'trim-diagnostic';
diagnostic.success = logical(get_field(trimResult, 'success', false));
diagnostic.reasonCodes = make_reason_codes(report, diagnostic.success, tol);
diagnostic.severity = make_severity(diagnostic.success, diagnostic.reasonCodes);
diagnostic.summary = make_summary(diagnostic.success, diagnostic.reasonCodes);
diagnostic.suggestions = make_suggestions(diagnostic.reasonCodes);
diagnostic.overview = make_overview(report, diagnostic.success, tol);
diagnostic.fullResiduals = make_full_residuals(report);
diagnostic.limitItems = make_limit_items(report);
diagnostic.candidates = make_candidates(report);
diagnostic.invalidEvaluationCount = get_field(report, ...
    'objectiveInvalidEvaluationCount', 0);
diagnostic.invalidEvaluationIdentifiers = get_field(report, ...
    'objectiveInvalidEvaluationIdentifiers', {});
end

function overview = make_overview(report, success, tol)
candidates = get_field(report, 'candidates', struct([]));
candidateAcceptance = get_field(report, 'candidateAcceptance', []);
overview.solverConverged = logical(get_field(report, 'solverConverged', false));
overview.accepted = logical(success);
overview.residualNorm = get_field(report, 'residualNorm', NaN);
overview.residualTolerance = tol;
overview.fullResidualNorm = get_field(report, 'fullResidualNorm', NaN);
overview.atLimit = logical(get_field(report, 'atLimit', false));
overview.withinLimits = logical(get_field(report, 'withinLimits', false));
overview.hasLimitViolation = ~overview.withinLimits;
overview.candidateCount = numel(candidates);
if isempty(candidateAcceptance)
    overview.acceptedCandidateCount = count_accepted_candidates(candidates);
else
    overview.acceptedCandidateCount = sum(logical(candidateAcceptance(:)));
end
overview.invalidEvaluationCount = get_field(report, ...
    'objectiveInvalidEvaluationCount', 0);
overview.exitflag = get_field(report, 'exitflag', NaN);
end

function rows = make_full_residuals(report)
names = get_field(report, 'fullResidualLabels', ...
    {'udot'; 'vdot'; 'wdot'; 'pdot'; 'qdot'; 'rdot'; ...
    'phidot'; 'thetadot'; 'psidot'});
values = get_field(report, 'fullStateDerivative', NaN(9,1));
units = {'m/s^2'; 'm/s^2'; 'm/s^2'; 'rad/s^2'; 'rad/s^2'; ...
    'rad/s^2'; 'rad/s'; 'rad/s'; 'rad/s'};
objectiveNames = {'udot', 'wdot', 'qdot'};

values = values(:);
n = max([numel(names), numel(values), numel(units), 9]);
rows = repmat(struct('name', '', 'value', NaN, 'unit', '', ...
    'isObjective', false), n, 1);
for k = 1:n
    rows(k).name = char(get_cell_value(names, k, sprintf('stateDerivative%d', k)));
    rows(k).value = get_numeric_value(values, k, NaN);
    rows(k).unit = char(get_cell_value(units, k, ''));
    rows(k).isObjective = any(strcmp(rows(k).name, objectiveNames));
end
end

function rows = make_limit_items(report)
limitReport = get_field(report, 'limitReport', struct());
items = get_field(limitReport, 'items', struct([]));
rows = repmat(struct('name', '', 'valueDeg', NaN, 'lowerDeg', NaN, ...
    'upperDeg', NaN, 'lowerMarginDeg', NaN, 'upperMarginDeg', NaN, ...
    'atLimit', false, 'violated', false, 'unit', 'deg'), numel(items), 1);
for k = 1:numel(items)
    valueDeg = items(k).value*180/pi;
    lowerDeg = items(k).lower*180/pi;
    upperDeg = items(k).upper*180/pi;
    rows(k).name = items(k).name;
    rows(k).valueDeg = valueDeg;
    rows(k).lowerDeg = lowerDeg;
    rows(k).upperDeg = upperDeg;
    rows(k).lowerMarginDeg = valueDeg - lowerDeg;
    rows(k).upperMarginDeg = upperDeg - valueDeg;
    rows(k).atLimit = logical(items(k).atLimit);
    rows(k).violated = logical(items(k).violated);
end
end

function rows = make_candidates(report)
candidates = get_field(report, 'candidates', struct([]));
rows = repmat(struct('initialThetaDeg', NaN, ...
    'initialCollectiveDeg', NaN, 'initialCyclicLongDeg', NaN, ...
    'finalThetaDeg', NaN, 'finalCollectiveDeg', NaN, ...
    'finalCyclicLongDeg', NaN, 'cost', NaN, 'residualNorm', NaN, ...
    'exitflag', NaN, 'acceptable', false, 'atLimit', false, ...
    'withinLimits', false), numel(candidates), 1);
for k = 1:numel(candidates)
    initialDeg = get_field(candidates(k), 'initialDeg', [NaN NaN NaN]);
    solutionDeg = get_field(candidates(k), 'solutionDeg', [NaN NaN NaN]);
    rows(k).initialThetaDeg = get_numeric_value(initialDeg(:), 1, NaN);
    rows(k).initialCollectiveDeg = get_numeric_value(initialDeg(:), 2, NaN);
    rows(k).initialCyclicLongDeg = get_numeric_value(initialDeg(:), 3, NaN);
    rows(k).finalThetaDeg = get_numeric_value(solutionDeg(:), 1, NaN);
    rows(k).finalCollectiveDeg = get_numeric_value(solutionDeg(:), 2, NaN);
    rows(k).finalCyclicLongDeg = get_numeric_value(solutionDeg(:), 3, NaN);
    rows(k).cost = get_field(candidates(k), 'cost', NaN);
    rows(k).residualNorm = get_field(candidates(k), 'residualNorm', NaN);
    rows(k).exitflag = get_field(candidates(k), 'exitflag', NaN);
    rows(k).acceptable = logical(get_field(candidates(k), 'acceptable', false));
    rows(k).atLimit = logical(get_field(candidates(k), 'atLimit', false));
    rows(k).withinLimits = logical(get_field(candidates(k), 'withinLimits', false));
end
end

function codes = make_reason_codes(report, success, tol)
codes = {};
residualNorm = get_field(report, 'residualNorm', NaN);
invalidCount = get_field(report, 'objectiveInvalidEvaluationCount', 0);
candidates = get_field(report, 'candidates', struct([]));

if success
    codes{end+1,1} = 'TRIM_ACCEPTED';
end
if ~logical(get_field(report, 'solverConverged', false))
    codes{end+1,1} = 'SOLVER_NOT_CONVERGED';
end
if isfinite(tol) && ~(isfinite(residualNorm) && residualNorm < tol)
    codes{end+1,1} = 'OBJECTIVE_RESIDUAL_TOO_LARGE';
end
if ~logical(get_field(report, 'finiteFullStateDerivative', false))
    codes{end+1,1} = 'NONFINITE_FULL_DERIVATIVE';
end
if logical(get_field(report, 'atLimit', false))
    codes{end+1,1} = 'CONTROL_AT_LIMIT';
end
if ~logical(get_field(report, 'withinLimits', false))
    codes{end+1,1} = 'CONTROL_LIMIT_VIOLATION';
end
if invalidCount > 0
    codes{end+1,1} = 'INVALID_MODEL_EVALUATIONS';
end
if count_accepted_candidates(candidates) == 0
    codes{end+1,1} = 'NO_ACCEPTABLE_CANDIDATE';
end
if isempty(codes)
    codes{end+1,1} = 'TRIM_REJECTED';
end
codes = unique(codes, 'stable');
end

function severity = make_severity(success, reasonCodes)
if success
    if any(strcmp(reasonCodes, 'INVALID_MODEL_EVALUATIONS'))
        severity = 'warning';
    else
        severity = 'success';
    end
else
    severity = 'error';
end
end

function summary = make_summary(success, reasonCodes)
if success
    if any(strcmp(reasonCodes, 'INVALID_MODEL_EVALUATIONS'))
        summary = '配平通过，但求解过程中出现过无效计算。';
    else
        summary = '配平通过，残差、限幅和有限性检查均满足要求。';
    end
else
    summary = '配平未通过，请查看残差、限幅和候选初值。';
end
end

function suggestions = make_suggestions(reasonCodes)
suggestions = {};
if any(strcmp(reasonCodes, 'SOLVER_NOT_CONVERGED'))
    suggestions{end+1,1} = '检查求解器退出标志和多初值候选表；必要时调整界面初值。';
end
if any(strcmp(reasonCodes, 'OBJECTIVE_RESIDUAL_TOO_LARGE'))
    suggestions{end+1,1} = '优先查看 udot、wdot、qdot 三个目标残差及其量级。';
end
if any(strcmp(reasonCodes, 'NONFINITE_FULL_DERIVATIVE'))
    suggestions{end+1,1} = '查看九状态导数表，确认是否存在 NaN、Inf 或复数模型输出。';
end
if any(strcmp(reasonCodes, 'CONTROL_AT_LIMIT')) || ...
        any(strcmp(reasonCodes, 'CONTROL_LIMIT_VIOLATION'))
    suggestions{end+1,1} = '查看 theta、collective、cyclicLong 限幅和裕度，不要把触限解当作正式配平。';
end
if any(strcmp(reasonCodes, 'INVALID_MODEL_EVALUATIONS'))
    suggestions{end+1,1} = '保留无效计算标识，用于定位模型域或内部迭代失败。';
end
if any(strcmp(reasonCodes, 'NO_ACCEPTABLE_CANDIDATE'))
    suggestions{end+1,1} = '检查所有候选初值的最终残差、退出标志和限幅状态。';
end
if isempty(suggestions)
    suggestions{end+1,1} = '可以继续运行线性化。';
end
end

function n = count_accepted_candidates(candidates)
n = 0;
for k = 1:numel(candidates)
    if isfield(candidates(k), 'acceptable') && logical(candidates(k).acceptable)
        n = n + 1;
    end
end
end

function value = get_field(S, name, defaultValue)
if isstruct(S) && isfield(S, name)
    value = S.(name);
else
    value = defaultValue;
end
end

function value = get_first_existing(A, B, names, defaultValue)
value = defaultValue;
for k = 1:numel(names)
    if isstruct(A) && isfield(A, names{k})
        value = A.(names{k});
        return;
    end
    if isstruct(B) && isfield(B, names{k})
        value = B.(names{k});
        return;
    end
end
end

function value = get_cell_value(values, index, defaultValue)
if iscell(values) && numel(values) >= index
    value = values{index};
elseif numel(values) >= index
    value = values(index);
else
    value = defaultValue;
end
end

function value = get_numeric_value(values, index, defaultValue)
if isnumeric(values) && numel(values) >= index
    value = values(index);
else
    value = defaultValue;
end
end
