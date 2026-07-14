function audit = audit_longitudinal_trim_robustness(opts)
%AUDIT_LONGITUDINAL_TRIM_ROBUSTNESS Probe longitudinal trim failure causes.
% This is an opt-in diagnostic. It does not change solver defaults, model
% equations, params_nominal defaults, control limits, or GUI behavior.

if nargin < 1 || isempty(opts)
    opts = struct();
end

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir, 'model'));
addpath(fullfile(rootDir, 'analysis'));
addpath(fullfile(rootDir, 'services'));

opts = apply_defaults(opts, rootDir);
if exist(opts.outputDir, 'dir') ~= 7
    mkdir(opts.outputDir);
end

cases = opts.cases;
candidates = candidate_plan(opts.runHeavy);
evidence = load_existing_evidence(rootDir);
records = repmat(empty_record(), 0, 1);

for iCase = 1:numel(cases)
    for iCand = 1:numel(candidates)
        fprintf('Longitudinal trim audit: case=%s candidate=%s\n', ...
            cases(iCase).name, candidates(iCand).name);
        record = run_candidate(cases(iCase), candidates(iCand), opts);
        records(end+1,1) = record; %#ok<AGROW>
    end
end

records = assign_diagnoses(records, opts);
caseSummary = build_case_summary(records);
auditMatrix = build_audit_matrix(records);

audit.outputDir = opts.outputDir;
audit.reportFile = fullfile(opts.outputDir, ...
    'LONGITUDINAL_TRIM_ROBUSTNESS_AUDIT.md');
audit.summaryCsvFile = fullfile(opts.outputDir, ...
    'longitudinal_trim_robustness_summary.csv');
audit.summaryJsonFile = fullfile(opts.outputDir, ...
    'longitudinal_trim_robustness_summary.json');
audit.casesCsvFile = fullfile(opts.outputDir, ...
    'longitudinal_trim_robustness_cases.csv');
audit.records = records;
audit.summaryTable = struct2table(records);
audit.caseSummary = caseSummary;
audit.caseSummaryTable = struct2table(caseSummary);
audit.auditMatrix = auditMatrix;
audit.auditMatrixTable = struct2table(auditMatrix);
audit.evidence = evidence;
audit.thresholds = opts.thresholds;
audit.runHeavy = opts.runHeavy;
audit.recordCount = numel(records);
audit.caseCount = numel(cases);
audit.candidateCount = numel(candidates);
audit.runErrorCount = sum([records.run_error]);

writetable(audit.summaryTable, audit.summaryCsvFile);
writetable(audit.caseSummaryTable, audit.casesCsvFile);
write_json(audit.summaryJsonFile, audit);
write_markdown(audit.reportFile, audit);

fprintf('\nLongitudinal trim robustness audit\n');
fprintf('==================================\n');
fprintf('Output directory: %s\n', audit.outputDir);
fprintf('Records: %d, cases: %d, candidates: %d, run errors: %d\n', ...
    audit.recordCount, audit.caseCount, audit.candidateCount, ...
    audit.runErrorCount);
end

function opts = apply_defaults(opts, rootDir)
if ~isfield(opts, 'runHeavy') || isempty(opts.runHeavy)
    opts.runHeavy = true;
end
if ~isfield(opts, 'timestamp') || isempty(opts.timestamp)
    opts.timestamp = datestr(now, 'yyyymmddTHHMMSS');
end
if ~isfield(opts, 'outputDir') || isempty(opts.outputDir)
    outputRoot = fullfile(rootDir, 'validation', ...
        'longitudinal_trim_robustness');
    opts.outputDir = fullfile(outputRoot, opts.timestamp);
end
if ~isfield(opts, 'cases') || isempty(opts.cases)
    opts.cases = default_cases();
end
if ~isfield(opts, 'thresholds') || isempty(opts.thresholds)
    opts.thresholds.meaningfulImprovement = 0.50;
    opts.thresholds.strongImprovement = 0.80;
    opts.thresholds.nearMissRatio = 10;
    opts.thresholds.farRatio = 100;
end
if ~isfield(opts, 'localMaxIterations') || isempty(opts.localMaxIterations)
    if opts.runHeavy
        opts.localMaxIterations = [];
    else
        opts.localMaxIterations = 180;
    end
end
end

function cases = default_cases()
cases = repmat(struct('name', '', 'V', NaN, 'betaMDeg', NaN, ...
    'gammaDeg', 0), 4, 1);
cases(1).name = 'helicopter_low_speed';
cases(1).V = 20;
cases(1).betaMDeg = 0;
cases(2).name = 'conversion_mid';
cases(2).V = 45;
cases(2).betaMDeg = 45;
cases(3).name = 'airplane_like';
cases(3).V = 100;
cases(3).betaMDeg = 90;
cases(4).name = 'conversion_high';
cases(4).V = 70;
cases(4).betaMDeg = 75;
end

function candidates = candidate_plan(runHeavy)
candidates = [
    make_candidate('baseline_longitudinal', 'baseline', ...
    'longitudinal_symmetric', 'service_longitudinal')
    make_candidate('cyclicLong_limit_35deg', 'cyclic_limit', ...
    'longitudinal_symmetric', 'service_longitudinal')
    make_candidate('longitudinal_theta_collective_cyclicLong_elevator', ...
    'elevator_unknown', 'longitudinal_candidate', 'generic_longitudinal')
    make_candidate('baseline_multistart_small', 'multistart', ...
    'longitudinal_candidate', 'generic_longitudinal')
    make_candidate('baseline_force_priority', 'scaling_weighting', ...
    'longitudinal_candidate', 'generic_longitudinal')
    make_candidate('current_full6dof', 'full6dof_comparison', ...
    'full_6dof_straight_trim', 'service_full6dof')
    ];

if runHeavy
    more = [
        make_candidate('cyclicLong_limit_25deg', 'cyclic_limit', ...
        'longitudinal_symmetric', 'service_longitudinal')
        make_candidate('cyclicLong_limit_45deg', 'cyclic_limit', ...
        'longitudinal_symmetric', 'service_longitudinal')
        make_candidate('cyclicLong_limit_60deg', 'cyclic_limit', ...
        'longitudinal_symmetric', 'service_longitudinal')
        make_candidate('longitudinal_theta_collective_elevator', ...
        'elevator_unknown', 'longitudinal_candidate', ...
        'generic_longitudinal')
        make_candidate(['longitudinal_theta_collective_cyclicLong_' ...
        'with_elevator_regularized'], 'elevator_unknown', ...
        'longitudinal_candidate', 'generic_longitudinal')
        make_candidate('baseline_multistart_medium', 'multistart', ...
        'longitudinal_candidate', 'generic_longitudinal')
        make_candidate('elevator_candidate_multistart', 'multistart', ...
        'longitudinal_candidate', 'generic_longitudinal')
        make_candidate('baseline_scaled_udot_wdot_qdot', ...
        'scaling_weighting', 'longitudinal_candidate', ...
        'generic_longitudinal')
        make_candidate('baseline_moment_priority', 'scaling_weighting', ...
        'longitudinal_candidate', 'generic_longitudinal')
        make_candidate('elevator_candidate_scaled', 'scaling_weighting', ...
        'longitudinal_candidate', 'generic_longitudinal')
        make_candidate('full6dof_with_elevator', 'full6dof_comparison', ...
        'full6dof_candidate', 'generic_full6dof')
        make_candidate('full6dof_with_theta_phi_collective_cyclicLong_elevator_rudder', ...
        'full6dof_comparison', 'full6dof_candidate', ...
        'generic_full6dof')
        make_candidate('full6dof_8input_with_lateralCyclic_and_elevator', ...
        'full6dof_comparison', 'full6dof_candidate', 'generic_full6dof')
        ];
    candidates = [candidates; more];
end

for i = 1:numel(candidates)
    candidates(i) = configure_candidate(candidates(i));
end
end

function c = make_candidate(name, family, trimMode, engine)
c = struct('name', name, 'family', family, 'trim_mode', trimMode, ...
    'engine', engine, 'unknown_set', '', 'selected_controls', '', ...
    'cyclicLimitDeg', NaN, 'enableLateralCyclic', false, ...
    'unknownNames', {{}}, 'residualNames', {{}}, ...
    'weights', [], 'regularizationWeight', 1.0e-6, ...
    'multiStart', false, 'seedLevel', 'none');
end

function c = configure_candidate(c)
switch c.name
    case 'baseline_longitudinal'
        c.unknownNames = {'theta','collective','cyclicLong'};
        c.residualNames = {'udot','wdot','qdot'};
    case 'cyclicLong_limit_25deg'
        c.cyclicLimitDeg = 25;
    case 'cyclicLong_limit_35deg'
        c.cyclicLimitDeg = 35;
    case 'cyclicLong_limit_45deg'
        c.cyclicLimitDeg = 45;
    case 'cyclicLong_limit_60deg'
        c.cyclicLimitDeg = 60;
    case 'longitudinal_theta_collective_cyclicLong_elevator'
        c.unknownNames = {'theta','collective','cyclicLong','elevator'};
        c.residualNames = {'udot','wdot','qdot'};
        c.regularizationWeight = 1.0e-4;
    case 'longitudinal_theta_collective_elevator'
        c.unknownNames = {'theta','collective','elevator'};
        c.residualNames = {'udot','wdot','qdot'};
        c.regularizationWeight = 1.0e-5;
    case 'longitudinal_theta_collective_cyclicLong_with_elevator_regularized'
        c.unknownNames = {'theta','collective','cyclicLong','elevator'};
        c.residualNames = {'udot','wdot','qdot'};
        c.regularizationWeight = 5.0e-3;
    case 'baseline_multistart_small'
        c.unknownNames = {'theta','collective','cyclicLong'};
        c.residualNames = {'udot','wdot','qdot'};
        c.multiStart = true;
        c.seedLevel = 'small';
    case 'baseline_multistart_medium'
        c.unknownNames = {'theta','collective','cyclicLong'};
        c.residualNames = {'udot','wdot','qdot'};
        c.multiStart = true;
        c.seedLevel = 'medium';
    case 'elevator_candidate_multistart'
        c.unknownNames = {'theta','collective','cyclicLong','elevator'};
        c.residualNames = {'udot','wdot','qdot'};
        c.multiStart = true;
        c.seedLevel = 'medium';
        c.regularizationWeight = 1.0e-4;
    case 'baseline_force_priority'
        c.unknownNames = {'theta','collective','cyclicLong'};
        c.residualNames = {'udot','wdot','qdot'};
        c.weights = [2; 2; 0.5];
    case 'baseline_scaled_udot_wdot_qdot'
        c.unknownNames = {'theta','collective','cyclicLong'};
        c.residualNames = {'udot','wdot','qdot'};
        c.weights = [1; 1; 1];
    case 'baseline_moment_priority'
        c.unknownNames = {'theta','collective','cyclicLong'};
        c.residualNames = {'udot','wdot','qdot'};
        c.weights = [0.75; 0.75; 2.0];
    case 'elevator_candidate_scaled'
        c.unknownNames = {'theta','collective','cyclicLong','elevator'};
        c.residualNames = {'udot','wdot','qdot'};
        c.weights = [1; 1; 1];
        c.regularizationWeight = 1.0e-4;
    case 'current_full6dof'
        c.unknownNames = {'theta','phi','collective','cyclicLong', ...
            'aileron','rudder'};
        c.residualNames = {'udot','vdot','wdot','pdot','qdot','rdot'};
    case 'full6dof_with_elevator'
        c.unknownNames = {'theta','phi','collective','cyclicLong', ...
            'elevator','rudder'};
        c.residualNames = {'udot','vdot','wdot','pdot','qdot','rdot'};
        c.regularizationWeight = 1.0e-5;
    case 'full6dof_with_theta_phi_collective_cyclicLong_elevator_rudder'
        c.unknownNames = {'theta','phi','collective','cyclicLong', ...
            'elevator','rudder'};
        c.residualNames = {'udot','vdot','wdot','pdot','qdot','rdot'};
        c.multiStart = true;
        c.seedLevel = 'small';
        c.regularizationWeight = 1.0e-5;
    case 'full6dof_8input_with_lateralCyclic_and_elevator'
        c.enableLateralCyclic = true;
        c.unknownNames = {'theta','phi','collective','cyclicLong', ...
            'lateralCyclic','elevator'};
        c.residualNames = {'udot','vdot','wdot','pdot','qdot','rdot'};
        c.regularizationWeight = 1.0e-5;
end
if isnan(c.cyclicLimitDeg)
    c.cyclicLimitDeg = 35;
end
if isempty(c.unknownNames)
    c.unknownNames = {'theta','collective','cyclicLong'};
end
if isempty(c.residualNames)
    c.residualNames = {'udot','wdot','qdot'};
end
if isempty(c.weights)
    c.weights = ones(numel(c.residualNames), 1);
end
c.unknown_set = strjoin(c.unknownNames, ';');
c.selected_controls = selected_controls(c.unknownNames);
end

function text = selected_controls(names)
controls = {'collective','diffCollective','cyclicLong','diffCyclic', ...
    'lateralCyclic','aileron','elevator','rudder'};
text = strjoin(names(ismember(names, controls)), ';');
end

function record = run_candidate(caseDef, candidate, opts)
P = params_nominal();
if candidate.enableLateralCyclic
    P.control.enableLateralCyclic = true;
end
if candidate.cyclicLimitDeg ~= 35
    P.control.cyclicLim = candidate.cyclicLimitDeg*pi/180*[-1, 1];
end

record = empty_record();
record.case_name = caseDef.name;
record.V_mps = caseDef.V;
record.betaM_deg = caseDef.betaMDeg;
record.gamma_deg = caseDef.gammaDeg;
record.candidate_name = candidate.name;
record.candidate_family = candidate.family;
record.trim_mode = candidate.trim_mode;
record.unknown_set = candidate.unknown_set;
record.selected_controls = candidate.selected_controls;
record.architecture = sprintf('%d-input', numel(get_control_input_names(P)));
record.tolerance = P.trim.residualTolerance;
if strcmp(candidate.family, 'full6dof_comparison')
    record.family_base = 'full6dof';
end

try
    switch candidate.engine
        case 'service_longitudinal'
            result = run_service_longitudinal(caseDef, P);
            record = fill_from_result(record, result, P, candidate);
        case 'service_full6dof'
            result = run_service_full6dof(caseDef, P);
            record = fill_from_result(record, result, P, candidate);
        otherwise
            if ~isempty(opts.localMaxIterations)
                P.trim.maxIterations = opts.localMaxIterations;
            end
            result = solve_generic_candidate(caseDef, candidate, P);
            record = fill_from_generic(record, result, P, candidate);
    end
catch ME
    record.run_error = true;
    record.success = false;
    record.solver_converged = false;
    record.message = sprintf('%s: %s', ME.identifier, ME.message);
    record.suspected_interpretation = 'candidate did not run; inspect error message';
    record.diagnosis_label = 'NOT_RUN_WITH_REASON';
end
end

function result = run_service_longitudinal(caseDef, P)
config = service_config(caseDef, 'longitudinal_symmetric');
result = run_trim_case(config, P);
end

function result = run_service_full6dof(caseDef, P)
config = service_config(caseDef, 'full_6dof_straight_trim');
result = run_trim_case(config, P);
end

function config = service_config(caseDef, mode)
config = struct('V', caseDef.V, 'betaMDeg', caseDef.betaMDeg, ...
    'gammaDeg', caseDef.gammaDeg, 'initialThetaDeg', 0, ...
    'initialCollectiveDeg', 18, 'initialCyclicLongDeg', 0, ...
    'thetaLimitDeg', 35, 'useMultiStart', false, ...
    'alwaysMultiStart', false, 'trimMode', mode);
end

function result = solve_generic_candidate(caseDef, candidate, P)
condition = struct('V', caseDef.V, 'betaM', caseDef.betaMDeg*pi/180, ...
    'gamma', caseDef.gammaDeg*pi/180);
unknownNames = candidate.unknownNames(:);
residualNames = candidate.residualNames(:);
z0 = initial_values(condition, unknownNames);
scale = variable_scales(unknownNames);
bounds = variable_bounds(unknownNames, P);
residualScale = residual_scales(residualNames, P);
weights = candidate.weights(:);
if numel(weights) ~= numel(residualNames)
    weights = ones(numel(residualNames), 1);
end
seeds = make_seeds(z0, scale, candidate);

options = optimset('Display', P.trim.display, ...
    'MaxIter', P.trim.maxIterations, ...
    'MaxFunEvals', 10*P.trim.maxIterations, ...
    'TolX', 1e-8, 'TolFun', 1e-10);

bestCost = Inf;
best = struct();
invalidEvalCount = 0;
invalidIds = {};
for iSeed = 1:size(seeds, 2)
    seed = seeds(:, iSeed);
    [yOpt, fval, exitflag, output] = fminsearch( ...
        @(y) objective(seed + scale.*y(:)), zeros(numel(seed),1), options);
    z = seed + scale.*yOpt(:);
    [x, u, residual, xdot, eomOut, finite] = evaluate_candidate( ...
        condition, unknownNames, residualNames, z, P);
    limitReport = make_limit_report(unknownNames, z, bounds);
    regularizationCost = candidate.regularizationWeight* ...
        sum(((z-z0)./scale).^2);
    totalCost = fval;
    if totalCost < bestCost
        bestCost = totalCost;
        best = struct('z', z, 'xTrim', x, 'uTrim', u, ...
            'residual', residual, 'xdot', xdot, 'eomOut', eomOut, ...
            'finite', finite, 'limitReport', limitReport, ...
            'fval', fval, 'exitflag', exitflag, 'output', output, ...
            'regularizationCost', regularizationCost, ...
            'seedIndex', iSeed, 'seedCount', size(seeds, 2));
    end
end

result = best;
result.residualNames = residualNames;
result.residualScale = residualScale;
result.scaledResidual = best.residual./residualScale;
result.weightedScaledResidual = weights.*result.scaledResidual;
result.unknownNames = unknownNames;
result.bounds = bounds;
result.initialValues = z0;
result.variableScale = scale;
result.weights = weights;
result.regularizationWeight = candidate.regularizationWeight;
result.invalidEvalCount = invalidEvalCount;
result.invalidEvalIdentifiers = unique(invalidIds);

    function J = objective(z)
        try
            [~, ~, R, ~, ~, finite] = evaluate_candidate( ...
                condition, unknownNames, residualNames, z, P);
        catch ME
            if is_solver_domain_error(ME)
                invalidEvalCount = invalidEvalCount + 1;
                invalidIds{invalidEvalCount} = ME.identifier;
                J = 1.0e30;
                return;
            end
            rethrow(ME);
        end
        if ~finite
            invalidEvalCount = invalidEvalCount + 1;
            invalidIds{invalidEvalCount} = ...
                'audit_longitudinal_trim_robustness:NonFiniteObjective';
            J = 1.0e30;
            return;
        end
        scaled = weights.*(R./residualScale);
        J = scaled.'*scaled + candidate.regularizationWeight* ...
            sum(((z-z0)./scale).^2) + bound_penalty(z, bounds);
    end
end

function z0 = initial_values(condition, unknownNames)
d2r = pi/180;
z0 = zeros(numel(unknownNames), 1);
for i = 1:numel(unknownNames)
    switch unknownNames{i}
        case 'theta'
            z0(i) = 4*d2r;
        case 'collective'
            if condition.betaM < pi/4
                z0(i) = 16*d2r;
            else
                z0(i) = 8*d2r;
            end
        case 'cyclicLong'
            if condition.betaM < pi/4
                z0(i) = 2*d2r;
            else
                z0(i) = -4*d2r;
            end
        otherwise
            z0(i) = 0;
    end
end
end

function scale = variable_scales(names)
d2r = pi/180;
scale = 2*d2r*ones(numel(names),1);
scale(strcmp(names, 'collective')) = 18*d2r;
end

function bounds = variable_bounds(names, P)
d2r = pi/180;
bounds = zeros(numel(names), 2);
for i = 1:numel(names)
    switch names{i}
        case 'theta'
            bounds(i,:) = 35*d2r*[-1, 1];
        case 'phi'
            bounds(i,:) = 30*d2r*[-1, 1];
        case 'collective'
            bounds(i,:) = P.control.collectiveLim(:).';
        case {'cyclicLong','diffCyclic','lateralCyclic'}
            bounds(i,:) = P.control.cyclicLim(:).';
        case 'diffCollective'
            bounds(i,:) = max(abs(P.control.collectiveLim(:)))*[-1, 1];
        case 'aileron'
            bounds(i,:) = P.control.aileronLim(:).';
        case 'elevator'
            bounds(i,:) = P.control.elevatorLim(:).';
        case 'rudder'
            bounds(i,:) = P.control.rudderLim(:).';
        otherwise
            error('audit_longitudinal_trim_robustness:UnknownUnknown', ...
                'Unsupported unknown %s.', names{i});
    end
end
end

function seeds = make_seeds(z0, scale, candidate)
seeds = z0(:);
if ~candidate.multiStart
    return;
end
if strcmp(candidate.seedLevel, 'medium')
    offsets = [zeros(numel(z0),1), eye(numel(z0)), -eye(numel(z0)), ...
        2*eye(numel(z0)), -2*eye(numel(z0))];
else
    offsets = [zeros(numel(z0),1), eye(numel(z0)), -eye(numel(z0))];
end
seeds = z0(:) + scale(:).*offsets;
end

function [x, u, residual, xdot, eomOut, finite] = evaluate_candidate( ...
        condition, unknownNames, residualNames, z, P)
stateNames = get_state_names(P);
controlNames = get_control_input_names(P);
derivativeNames = derivative_names(P);
x = zeros(get_state_dimension(P), 1);
u = zeros(numel(controlNames), 1);
for i = 1:numel(unknownNames)
    stateIndex = find(strcmp(stateNames, unknownNames{i}), 1);
    controlIndex = find(strcmp(controlNames, unknownNames{i}), 1);
    if ~isempty(stateIndex)
        x(stateIndex) = z(i);
    elseif ~isempty(controlIndex)
        u(controlIndex) = z(i);
    end
end
if has_nacelle_dynamic_states(P)
    x(strcmp(stateNames, 'betaM')) = condition.betaM;
    x(strcmp(stateNames, 'betaM_dot')) = 0;
end
theta = x(strcmp(stateNames, 'theta'));
alpha = theta - condition.gamma;
if condition.V < 1.0e-10
    x(strcmp(stateNames, 'u')) = 0;
    x(strcmp(stateNames, 'w')) = 0;
else
    x(strcmp(stateNames, 'u')) = condition.V*cos(alpha);
    x(strcmp(stateNames, 'w')) = condition.V*sin(alpha);
end
[xdot, eomOut] = tiltrotor_eom(x, u, condition.betaM, P);
xdot = xdot(:);
residual = zeros(numel(residualNames), 1);
for i = 1:numel(residualNames)
    residual(i) = xdot(strcmp(derivativeNames, residualNames{i}));
end
finite = is_real_finite(residual) && is_real_finite(xdot) && ...
    is_real_finite(x) && is_real_finite(u);
end

function scale = residual_scales(names, P)
scale = ones(numel(names),1);
scale(ismember(names, {'udot','vdot','wdot'})) = P.env.g;
end

function penalty = bound_penalty(values, bounds)
below = max(bounds(:,1)-values(:), 0);
above = max(values(:)-bounds(:,2), 0);
penalty = 1.0e6*sum(below.^2 + above.^2);
end

function report = make_limit_report(names, values, bounds)
tol = 1.0e-8;
items = repmat(struct('name', '', 'value', NaN, 'lower', NaN, ...
    'upper', NaN, 'atLower', false, 'atUpper', false, ...
    'atLimit', false, 'violated', false), numel(names), 1);
for i = 1:numel(names)
    items(i).name = names{i};
    items(i).value = values(i);
    items(i).lower = bounds(i,1);
    items(i).upper = bounds(i,2);
    items(i).atLower = abs(values(i)-bounds(i,1)) <= tol;
    items(i).atUpper = abs(values(i)-bounds(i,2)) <= tol;
    items(i).atLimit = items(i).atLower || items(i).atUpper;
    items(i).violated = values(i) < bounds(i,1)-tol || ...
        values(i) > bounds(i,2)+tol;
end
report.items = items;
report.anyAtLimit = any([items.atLimit]);
report.anyViolation = any([items.violated]);
end

function record = fill_from_result(record, result, P, candidate)
record.success = logical(result.success);
record.solver_converged = logical(get_report_field(result, ...
    'solverConverged', get_report_field(result, 'converged', false)));
record.message = result_message(result);
record.residual_norm = get_report_field(result, 'residualNorm', NaN);
record.tolerance = get_report_field(result, 'successTolerance', ...
    P.trim.residualTolerance);
record.residual_to_tolerance = safe_ratio(record.residual_norm, ...
    record.tolerance);
labels = cellstr_list(get_report_field(result, 'residualLabels', {}));
values = get_report_field(result, 'residual', NaN);
record = fill_residual_fields(record, labels, values);
record.full_residual_norm = get_report_field(result, 'fullResidualNorm', ...
    vector_norm(get_field(result, 'xdot', NaN)));
record = fill_state_control_fields(record, get_field(result, 'xTrim', []), ...
    get_field(result, 'uTrim', []), P);
limitReport = get_report_field(result, 'limitReport', struct());
record.at_limit = logical(get_field(limitReport, 'anyAtLimit', ...
    get_report_field(result, 'atLimit', false)));
record.within_limits = ~logical(get_field(limitReport, 'anyViolation', ...
    ~get_report_field(result, 'withinLimits', true)));
record.active_limit_names = active_limit_names(limitReport);
record.suspected_interpretation = default_interpretation(record, candidate);
end

function record = fill_from_generic(record, result, P, candidate)
record.success = result.exitflag > 0 && result.finite && ...
    norm(result.residual) < P.trim.residualTolerance && ...
    ~result.limitReport.anyAtLimit && ~result.limitReport.anyViolation;
record.solver_converged = result.exitflag > 0;
record.message = generic_message(record.success, result);
record.residual_norm = norm(result.residual);
record.tolerance = P.trim.residualTolerance;
record.residual_to_tolerance = safe_ratio(record.residual_norm, ...
    record.tolerance);
record = fill_residual_fields(record, result.residualNames, ...
    result.residual);
record.full_residual_norm = norm(result.xdot);
record = fill_state_control_fields(record, result.xTrim, result.uTrim, P);
record.at_limit = result.limitReport.anyAtLimit;
record.within_limits = ~result.limitReport.anyViolation;
record.active_limit_names = active_limit_names(result.limitReport);
record.suspected_interpretation = default_interpretation(record, candidate);
end

function message = generic_message(success, result)
if success
    message = sprintf('audit candidate converged: residual norm %.3e.', ...
        norm(result.residual));
elseif ~result.finite
    message = 'audit candidate failed: non-finite residual.';
elseif result.limitReport.anyViolation
    message = 'audit candidate failed: limit violation.';
elseif result.limitReport.anyAtLimit
    message = 'audit candidate did not meet success: active limit.';
else
    message = sprintf(['audit candidate did not meet tolerance: residual ' ...
        'norm %.3e.'], norm(result.residual));
end
end

function record = fill_residual_fields(record, labels, values)
record.residual_labels = strjoin(labels(:).', ';');
record.residual_values = number_list(values);
[label, value] = dominant_residual(labels, values);
record.dominant_residual_label = label;
record.dominant_residual_value = value;
record.udot = residual_value(labels, values, 'udot');
record.wdot = residual_value(labels, values, 'wdot');
record.qdot = residual_value(labels, values, 'qdot');
end

function record = fill_state_control_fields(record, x, u, P)
stateNames = get_state_names(P);
controlNames = get_control_input_names(P);
record.theta_deg = state_or_nan(x, stateNames, 'theta')*180/pi;
record.phi_deg = state_or_nan(x, stateNames, 'phi')*180/pi;
record.collective_deg = control_or_nan(u, controlNames, 'collective')*180/pi;
record.cyclicLong_deg = control_or_nan(u, controlNames, 'cyclicLong')*180/pi;
record.elevator_deg = control_or_nan(u, controlNames, 'elevator')*180/pi;
record.aileron_deg = control_or_nan(u, controlNames, 'aileron')*180/pi;
record.rudder_deg = control_or_nan(u, controlNames, 'rudder')*180/pi;
record.lateralCyclic_deg = control_or_nan(u, controlNames, ...
    'lateralCyclic')*180/pi;
end

function records = assign_diagnoses(records, opts)
for i = 1:numel(records)
    base = find_baseline(records, records(i).case_name, records(i).family_base);
    records(i).baseline_residual_norm = base.residual_norm;
    records(i).improvement_fraction = improvement_fraction( ...
        base.residual_norm, records(i).residual_norm);
    records(i).diagnosis_label = classify_record(records(i), opts.thresholds);
    records(i).suspected_interpretation = interpretation_for_label( ...
        records(i));
end
end

function base = find_baseline(records, caseName, familyBase)
if strcmp(familyBase, 'full6dof')
    idx = strcmp({records.case_name}, caseName) & ...
        strcmp({records.candidate_name}, 'current_full6dof');
else
    idx = strcmp({records.case_name}, caseName) & ...
        strcmp({records.candidate_name}, 'baseline_longitudinal');
end
if any(idx)
    base = records(find(idx, 1));
else
    base = empty_record();
end
end

function label = classify_record(r, thresholds)
if r.run_error
    label = 'NOT_RUN_WITH_REASON';
    return;
end
switch r.candidate_family
    case 'baseline'
        label = 'BASELINE_REPRODUCED';
    case 'cyclic_limit'
        if r.improvement_fraction >= thresholds.meaningfulImprovement
            label = 'CYCLIC_LIMIT_SENSITIVE';
        else
            label = 'NOT_CYCLIC_LIMIT_ONLY';
        end
    case 'elevator_unknown'
        if r.improvement_fraction >= thresholds.meaningfulImprovement
            label = 'ELEVATOR_CANDIDATE_IMPROVES';
        else
            label = 'ELEVATOR_CANDIDATE_NOT_ENOUGH';
        end
    case 'multistart'
        if r.improvement_fraction >= thresholds.meaningfulImprovement || ...
                r.success
            label = 'MULTISTART_SENSITIVE';
        else
            label = 'MULTISTART_NOT_ENOUGH';
        end
    case 'scaling_weighting'
        if r.improvement_fraction >= thresholds.meaningfulImprovement || ...
                r.success
            label = 'SCALING_WEIGHTING_SENSITIVE';
        else
            label = 'FORMULATION_LIMITATION_LIKELY';
        end
    case 'full6dof_comparison'
        if r.improvement_fraction >= thresholds.meaningfulImprovement
            label = 'CONTROL_SET_LIMITATION_LIKELY';
        else
            label = 'FORMULATION_LIMITATION_LIKELY';
        end
    otherwise
        label = 'UNKNOWN_FAILURE';
end
end

function text = interpretation_for_label(r)
switch r.diagnosis_label
    case 'BASELINE_REPRODUCED'
        text = 'baseline reproduces the PR44/45 failure or success pattern';
    case 'CYCLIC_LIMIT_SENSITIVE'
        text = 'virtual cyclicLong authority change materially lowers residual';
    case 'NOT_CYCLIC_LIMIT_ONLY'
        text = 'residual remains high; cyclicLong limit is not the only cause';
    case 'ELEVATOR_CANDIDATE_IMPROVES'
        text = ['elevator candidate lowers residual; this is a hypothesis ' ...
            'only and not a proven default fix'];
    case 'ELEVATOR_CANDIDATE_NOT_ENOUGH'
        text = 'elevator candidate is insufficient by this diagnostic threshold';
    case 'MULTISTART_SENSITIVE'
        text = 'different initial seeds materially improve the local result';
    case 'MULTISTART_NOT_ENOUGH'
        text = 'deterministic multistart does not materially improve residual';
    case 'SCALING_WEIGHTING_SENSITIVE'
        text = 'residual weighting materially changes the candidate outcome';
    case 'CONTROL_SET_LIMITATION_LIKELY'
        text = 'adding a candidate control set materially improves residual';
    otherwise
        text = 'candidate outcome points to a deeper formulation limitation';
end
end

function text = default_interpretation(record, candidate)
if record.run_error
    text = 'candidate did not run';
else
    text = sprintf('%s candidate evaluated with residual %.3e', ...
        candidate.family, record.residual_norm);
end
end

function caseSummary = build_case_summary(records)
caseNames = unique_cell({records.case_name});
families = {'baseline','cyclic_limit','elevator_unknown', ...
    'multistart','scaling_weighting','full6dof_comparison'};
caseSummary = repmat(struct('case_name', '', 'family', '', ...
    'best_candidate', '', 'best_residual_norm', NaN, ...
    'best_improvement_fraction', NaN, 'diagnosis_label', ''), ...
    numel(caseNames)*numel(families), 1);
k = 0;
for iCase = 1:numel(caseNames)
    for iFamily = 1:numel(families)
        k = k + 1;
        idx = strcmp({records.case_name}, caseNames{iCase}) & ...
            strcmp({records.candidate_family}, families{iFamily});
        sub = records(idx);
        caseSummary(k).case_name = caseNames{iCase};
        caseSummary(k).family = families{iFamily};
        if isempty(sub)
            continue;
        end
        [~, bestIdx] = min([sub.residual_norm]);
        best = sub(bestIdx);
        caseSummary(k).best_candidate = best.candidate_name;
        caseSummary(k).best_residual_norm = best.residual_norm;
        caseSummary(k).best_improvement_fraction = ...
            best.improvement_fraction;
        caseSummary(k).diagnosis_label = best.diagnosis_label;
    end
end
end

function matrix = build_audit_matrix(records)
caseNames = unique_cell({records.case_name});
matrix = repmat(struct('case_name', '', 'baseline', '', ...
    'cyclic_limit', '', 'elevator_unknown', '', 'multistart', '', ...
    'scaling_weighting', '', 'full6dof_comparison', ''), ...
    numel(caseNames), 1);
families = {'baseline','cyclic_limit','elevator_unknown', ...
    'multistart','scaling_weighting','full6dof_comparison'};
for i = 1:numel(caseNames)
    matrix(i).case_name = caseNames{i};
    for j = 1:numel(families)
        matrix(i).(families{j}) = family_label(records, caseNames{i}, ...
            families{j});
    end
end
end

function label = family_label(records, caseName, family)
idx = strcmp({records.case_name}, caseName) & ...
    strcmp({records.candidate_family}, family);
if ~any(idx)
    label = 'NOT_RUN_WITH_REASON';
    return;
end
sub = records(idx);
[~, bestIdx] = min([sub.residual_norm]);
label = sub(bestIdx).diagnosis_label;
end

function evidence = load_existing_evidence(rootDir)
evidence.evidenceDir = fullfile(rootDir, 'validation', ...
    'trim_solver_evidence', '20260713T164911');
evidence.diagnosticDir = fullfile(rootDir, 'validation', ...
    'trim_solver_failure_diagnostic', '20260714T021057');
evidence.totalRecords = NaN;
evidence.successCount = NaN;
evidence.failureCount = NaN;
evidence.runErrorCount = NaN;
try
    t = readtable(fullfile(evidence.evidenceDir, ...
        'trim_solver_evidence.csv'));
    evidence.totalRecords = height(t);
    evidence.successCount = sum(t.success);
    evidence.failureCount = sum(~t.success);
    evidence.runErrorCount = sum(t.run_error);
catch
end
end

function row = empty_record()
row = struct('case_name', '', 'V_mps', NaN, 'betaM_deg', NaN, ...
    'gamma_deg', NaN, 'candidate_name', '', 'candidate_family', '', ...
    'trim_mode', '', 'unknown_set', '', 'selected_controls', '', ...
    'architecture', '7-input', 'success', false, ...
    'solver_converged', false, 'residual_norm', NaN, ...
    'baseline_residual_norm', NaN, 'improvement_fraction', NaN, ...
    'tolerance', NaN, 'residual_to_tolerance', NaN, ...
    'dominant_residual_label', 'NA', 'dominant_residual_value', NaN, ...
    'udot', NaN, 'wdot', NaN, 'qdot', NaN, ...
    'residual_labels', '', 'residual_values', '', ...
    'full_residual_norm', NaN, 'theta_deg', NaN, 'phi_deg', NaN, ...
    'collective_deg', NaN, 'cyclicLong_deg', NaN, ...
    'elevator_deg', NaN, 'aileron_deg', NaN, 'rudder_deg', NaN, ...
    'lateralCyclic_deg', NaN, 'at_limit', false, ...
    'within_limits', false, 'active_limit_names', '', ...
    'message', '', 'suspected_interpretation', '', ...
    'diagnosis_label', '', 'run_error', false, ...
    'family_base', 'longitudinal');
end

function [label, value] = dominant_residual(labels, values)
if isempty(labels) || isempty(values) || numel(labels) ~= numel(values)
    label = 'NA';
    value = NaN;
    return;
end
[~, idx] = max(abs(values));
label = labels{idx};
value = values(idx);
end

function value = residual_value(labels, values, name)
idx = find(strcmp(labels, name), 1);
if isempty(idx)
    value = NaN;
else
    value = values(idx);
end
end

function list = active_limit_names(limitReport)
list = '';
if ~isstruct(limitReport)
    return;
end
if isfield(limitReport, 'items')
    items = limitReport.items;
elseif isfield(limitReport, 'entries')
    items = limitReport.entries;
else
    items = [];
end
names = {};
for i = 1:numel(items)
    if get_field(items(i), 'atLimit', false) || ...
            get_field(items(i), 'violated', false)
        names{end+1} = get_field(items(i), 'name', ''); %#ok<AGROW>
    end
end
list = strjoin(names, ';');
end

function value = improvement_fraction(baseResidual, residual)
if isfinite(baseResidual) && isfinite(residual) && baseResidual > 0
    value = (baseResidual - residual)/baseResidual;
else
    value = NaN;
end
end

function ratio = safe_ratio(a, b)
if isfinite(a) && isfinite(b) && b > 0
    ratio = a/b;
else
    ratio = NaN;
end
end

function value = state_or_nan(x, names, name)
idx = find(strcmp(names, name), 1);
value = vector_or_nan(x, idx);
end

function value = control_or_nan(u, names, name)
idx = find(strcmp(names, name), 1);
value = vector_or_nan(u, idx);
end

function value = vector_or_nan(v, idx)
if isempty(idx) || ~isnumeric(v) || numel(v) < idx
    value = NaN;
else
    value = v(idx);
end
end

function value = vector_norm(v)
if isnumeric(v) && ~isempty(v)
    value = norm(v(:));
else
    value = NaN;
end
end

function value = get_field(s, name, defaultValue)
if isstruct(s) && isfield(s, name)
    value = s.(name);
else
    value = defaultValue;
end
end

function value = get_report_field(result, name, defaultValue)
if isfield(result, 'report') && isstruct(result.report) && ...
        isfield(result.report, name)
    value = result.report.(name);
else
    value = defaultValue;
end
end

function text = result_message(result)
if isfield(result, 'message') && ~isempty(result.message)
    text = char(result.message);
elseif isfield(result, 'report') && isfield(result.report, 'message') && ...
        ~isempty(result.report.message)
    text = char(result.report.message);
elseif isfield(result, 'success') && result.success
    text = 'success';
else
    text = 'no message';
end
end

function items = cellstr_list(value)
if isempty(value)
    items = {};
elseif ischar(value)
    items = cellstr(value);
elseif isstring(value)
    items = cellstr(value(:));
elseif iscell(value)
    items = value(:);
else
    items = cellstr(string(value(:)));
end
end

function text = number_list(value)
if ~(isnumeric(value) || islogical(value)) || isempty(value)
    text = '';
    return;
end
items = cell(numel(value),1);
for i = 1:numel(value)
    items{i} = sprintf('%.12g', value(i));
end
text = strjoin(items(:).', ';');
end

function items = unique_cell(items)
if isempty(items)
    items = {};
    return;
end
items = items(~cellfun(@isempty, items));
[~, idx] = unique(items, 'stable');
items = items(sort(idx));
end

function tf = is_solver_domain_error(ME)
tf = strcmp(ME.identifier, 'rotor_model_bemt:FlapNotConverged') || ...
    strcmp(ME.identifier, 'rotor_model_bemt:CoupledSolveNotConverged');
end

function tf = is_real_finite(value)
tf = isreal(value) && all(isfinite(value(:)));
end

function names = derivative_names(P)
names = {'udot'; 'vdot'; 'wdot'; 'pdot'; 'qdot'; ...
    'rdot'; 'phidot'; 'thetadot'; 'psidot'};
if has_nacelle_dynamic_states(P)
    names = [names; {'betaM_dot'; 'betaM_ddot'}];
end
end

function write_json(jsonFile, audit)
payload.scope = ['Internal longitudinal trim robustness diagnostic; not ' ...
    'external validation and not a solver default change.'];
payload.outputDir = audit.outputDir;
payload.runHeavy = audit.runHeavy;
payload.thresholds = audit.thresholds;
payload.recordCount = audit.recordCount;
payload.runErrorCount = audit.runErrorCount;
payload.evidence = audit.evidence;
payload.caseSummary = audit.caseSummary;
payload.auditMatrix = audit.auditMatrix;
payload.records = audit.records;
text = jsonencode(payload, 'PrettyPrint', true);
fid = fopen(jsonFile, 'w');
if fid < 0
    error('audit_longitudinal_trim_robustness:CannotOpenJson', ...
        'Cannot open JSON output file.');
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '%s\n', text);
end

function write_markdown(reportFile, audit)
fid = fopen(reportFile, 'w');
if fid < 0
    error('audit_longitudinal_trim_robustness:CannotOpenMarkdown', ...
        'Cannot open Markdown output file.');
end
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, '# Longitudinal Trim Robustness Audit\n\n');
fprintf(fid, '## 1. Executive Summary\n\n');
fprintf(fid, ['This is an audit, not a solver fix. It does not change ' ...
    'default model equations, params_nominal defaults, GUI behavior, ' ...
    'control limits, trim convergence criteria, or default lateralCyclic ' ...
    'enablement.\n\n']);
fprintf(fid, ['The audit investigates PR #44/#45 conversion and high-speed ' ...
    'longitudinal/full6DOF failures using opt-in candidate formulations. ' ...
    'The committed evidence input has %d total rows, %d successes, %d ' ...
    'failure/non-converged rows, and %d run errors.\n\n'], ...
    audit.evidence.totalRecords, audit.evidence.successCount, ...
    audit.evidence.failureCount, audit.evidence.runErrorCount);
fprintf(fid, ['Improvement thresholds: meaningful >= %.0f%% residual ' ...
    'reduction, strong >= %.0f%% residual reduction, near miss when ' ...
    'residual/tolerance < %.0f, far from tolerance when ratio >= %.0f.\n\n'], ...
    100*audit.thresholds.meaningfulImprovement, ...
    100*audit.thresholds.strongImprovement, ...
    audit.thresholds.nearMissRatio, audit.thresholds.farRatio);

write_matrix_table(fid, audit.auditMatrix);
write_section_table(fid, '## 2. Baseline Reproduction', audit.records, ...
    'baseline', {'case_name','residual_norm','dominant_residual_label', ...
    'active_limit_names','diagnosis_label'});
write_section_table(fid, '## 3. CyclicLong Limit Sensitivity', ...
    audit.records, 'cyclic_limit', {'case_name','candidate_name', ...
    'residual_norm','improvement_fraction','active_limit_names', ...
    'diagnosis_label'});
write_section_table(fid, '## 4. Elevator Unknown-Set Hypothesis', ...
    audit.records, 'elevator_unknown', {'case_name','candidate_name', ...
    'residual_norm','improvement_fraction','dominant_residual_label', ...
    'diagnosis_label'});
fprintf(fid, ['\nElevator entry is a diagnostic hypothesis only, not a ' ...
    'proven fix, and not implemented as default.\n\n']);
write_section_table(fid, '## 5. Multi-start Sensitivity', ...
    audit.records, 'multistart', {'case_name','candidate_name', ...
    'residual_norm','improvement_fraction','diagnosis_label'});
write_section_table(fid, '## 6. Scaling / Weighting Sensitivity', ...
    audit.records, 'scaling_weighting', {'case_name','candidate_name', ...
    'residual_norm','improvement_fraction','diagnosis_label'});
write_section_table(fid, '## 7. Full 6-DOF Formulation Comparison', ...
    audit.records, 'full6dof_comparison', {'case_name','candidate_name', ...
    'architecture','residual_norm','improvement_fraction', ...
    'dominant_residual_label','diagnosis_label'});

fprintf(fid, '## 8. Root Cause Ranking\n\n');
write_case_summary(fid, audit.caseSummary);

fprintf(fid, '## 9. Recommended Next Implementation PR\n\n');
fprintf(fid, ['- If elevator candidates materially improve a case, add a ' ...
    'future opt-in elevator-aware longitudinal/full6DOF trim mode and ' ...
    'test it before changing defaults.\n']);
fprintf(fid, ['- If cyclicLong limit sensitivity appears, audit physical ' ...
    'control authority, sign, units, and limit sources rather than ' ...
    'directly widening default limits.\n']);
fprintf(fid, ['- If multistart sensitivity appears, improve solver robustness ' ...
    'in a separate PR without relabeling failures as success.\n']);
fprintf(fid, ['- If scaling sensitivity appears, audit residual normalization ' ...
    'separately.\n']);
fprintf(fid, ['- If none of these candidates is enough, audit the force/moment ' ...
    'chain, wing/tail/rotor coupling, and representative condition ' ...
    'definition.\n\n']);

fprintf(fid, '## 10. What Not To Claim\n\n');
fprintf(fid, '- No external validation passed.\n');
fprintf(fid, '- No all-envelope trim reliability is proven.\n');
fprintf(fid, '- No NUAA/Berger/XV-15 match is claimed.\n');
fprintf(fid, ['- Do not claim the elevator fix is proven without a later ' ...
    'implementation and validation PR.\n']);
fprintf(fid, '- Do not claim default cyclicLong limits should be widened.\n');
fprintf(fid, ['- Do not claim model equations are wrong solely from ' ...
    'non-convergence.\n']);
fprintf(fid, '- Do not claim lateralCyclic is ineffective.\n');
end

function write_matrix_table(fid, matrix)
fprintf(fid, '## Audit Matrix\n\n');
fprintf(fid, ['|case|baseline|cyclic limit|elevator unknown|' ...
    'multistart|scaling/weighting|full6DOF|\n']);
fprintf(fid, '|-|-|-|-|-|-|-|\n');
for i = 1:numel(matrix)
    fprintf(fid, '|%s|%s|%s|%s|%s|%s|%s|\n', matrix(i).case_name, ...
        matrix(i).baseline, matrix(i).cyclic_limit, ...
        matrix(i).elevator_unknown, matrix(i).multistart, ...
        matrix(i).scaling_weighting, matrix(i).full6dof_comparison);
end
fprintf(fid, '\n');
end

function write_section_table(fid, title, records, family, fields)
fprintf(fid, '%s\n\n', title);
fprintf(fid, '|%s|\n', strjoin(fields, '|'));
fprintf(fid, '|%s|\n', strjoin(repmat({'-'}, size(fields)), '|'));
idx = strcmp({records.candidate_family}, family);
sub = records(idx);
for i = 1:numel(sub)
    values = cell(1, numel(fields));
    for j = 1:numel(fields)
        values{j} = format_value(sub(i).(fields{j}));
    end
    fprintf(fid, '|%s|\n', strjoin(values, '|'));
end
fprintf(fid, '\n');
end

function write_case_summary(fid, rows)
fprintf(fid, '|case|family|best candidate|best residual|improvement|diagnosis|\n');
fprintf(fid, '|-|-|-|-:|-:|-|\n');
for i = 1:numel(rows)
    fprintf(fid, '|%s|%s|%s|%.6g|%.6g|%s|\n', rows(i).case_name, ...
        rows(i).family, rows(i).best_candidate, ...
        rows(i).best_residual_norm, rows(i).best_improvement_fraction, ...
        rows(i).diagnosis_label);
end
fprintf(fid, '\n');
end

function text = format_value(value)
if islogical(value)
    text = char(string(value));
elseif isnumeric(value)
    if isnan(value)
        text = 'NaN';
    elseif isinf(value)
        text = 'Inf';
    else
        text = sprintf('%.6g', value);
    end
else
    text = char(value);
end
text = strrep(text, '|', '/');
text = strrep(text, newline, ' ');
end
