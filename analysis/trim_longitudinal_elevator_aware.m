function result = trim_longitudinal_elevator_aware(P, caseDef, options)
%TRIM_LONGITUDINAL_ELEVATOR_AWARE Opt-in elevator-aware trim candidate.
% This diagnostic path is not registered as a default solver and does not
% change model equations, params_nominal defaults, control limits, GUI
% behavior, or services/run_trim_case behavior.

if nargin < 1 || isempty(P)
    P = params_nominal();
end
if nargin < 2 || isempty(caseDef)
    error('trim_longitudinal_elevator_aware:InvalidCase', ...
        'caseDef must define V, betaM or betaMDeg, and gamma or gammaDeg.');
end
if nargin < 3 || isempty(options)
    options = struct();
end

caseDef = normalize_case(caseDef);
options = apply_defaults(options, P);
controlSet = options.controlSet;
[unknownNames, residualNames] = formulation_names(controlSet);
z0 = initial_values(caseDef, unknownNames);
scale = variable_scales(unknownNames);
bounds = variable_bounds(unknownNames, caseDef, P);
weights = residual_weights(options, residualNames);
regularization = regularization_weights(options, unknownNames);
residualScale = residual_scales(residualNames, P);
seeds = make_seeds(z0, scale, options);

optimOptions = optimset('Display', P.trim.display, ...
    'MaxIter', options.maxIterations, ...
    'MaxFunEvals', 10*options.maxIterations, ...
    'TolX', 1e-8, 'TolFun', 1e-10);

best = struct('cost', Inf, 'z', z0, 'exitflag', -Inf, ...
    'output', struct(), 'seedIndex', 1);
invalidEvalCount = 0;
invalidEvalIdentifiers = {};

for iSeed = 1:size(seeds, 2)
    seed = seeds(:, iSeed);
    [yOpt, fval, exitflag, output] = fminsearch( ...
        @(y) objective(seed + scale.*y(:), z0), ...
        zeros(numel(seed), 1), optimOptions);
    z = seed + scale.*yOpt(:);
    if fval < best.cost
        best.cost = fval;
        best.z = z;
        best.exitflag = exitflag;
        best.output = output;
        best.seedIndex = iSeed;
    end
end

[xTrim, uTrim, residual, xdot, eomOut, finiteEval, allocation] = ...
    evaluate_point(best.z);
limitReport = make_limit_report(unknownNames, best.z, bounds, ...
    uTrim, P, allocation);
scaledResidual = residual./residualScale;
weightedResidual = weights.*scaledResidual;
regularizationCost = sum(regularization.*((best.z-z0)./scale).^2);

result.kind = 'elevator-aware-longitudinal-trim-candidate';
result.enabled = true;
result.guarded = false;
result.candidateName = options.candidateName;
result.controlSet = controlSet;
result.useSchedule = any(strcmp(unknownNames, 'pitchCommand'));
result.classification = 'OPT_IN_DIAGNOSTIC_CANDIDATE';
result.caseDef = caseDef;
result.xTrim = xTrim(:);
result.uTrim = uTrim(:);
result.xdot = xdot(:);
result.loads.Ftotal = eomOut.Ftotal;
result.loads.Mtotal = eomOut.Mtotal;
result.loads.components = eomOut.components;
result.stateNames = get_state_names(P);
result.controlNames = get_control_input_names(P);
result.residual = residual(:);
result.residualLabels = residualNames(:);
result.residualScale = residualScale(:);
result.scaledResidual = scaledResidual(:);
result.weightedResidual = weightedResidual(:);
result.residualNorm = norm(residual);
result.weightedResidualNorm = norm(weightedResidual);
result.rawResidualNorm = result.residualNorm;
result.dominantResidual = dominant_label(residualNames, residual);
result.cost = best.cost;
result.regularizationCost = regularizationCost;
result.regularizationWeights = regularization;
result.residualWeights = weights;
result.exitflag = best.exitflag;
result.output = best.output;
result.solverConverged = best.exitflag > 0;
result.finite = finiteEval && is_real_finite(xTrim) && is_real_finite(uTrim);
result.limitReport = limitReport;
result.withinDefaultLimits = ~limitReport.anyViolation;
result.withinLimits = result.withinDefaultLimits;
result.atLimit = limitReport.anyAtLimit;
result.successTolerance = options.tolerance;
result.success = result.solverConverged && result.finite && ...
    result.residualNorm < options.tolerance && result.withinDefaultLimits && ...
    ~result.atLimit;
result.converged = result.success;
result.unknownNames = unknownNames(:);
result.trimVariables = named_struct(unknownNames, best.z);
result.initialValues = z0;
result.variableScale = scale;
result.bounds = bounds;
result.seedIndex = best.seedIndex;
result.seedCount = size(seeds, 2);
result.objectiveInvalidEvaluationCount = invalidEvalCount;
result.objectiveInvalidEvaluationIdentifiers = unique(invalidEvalIdentifiers);
result.allocation = allocation;
result.cyclicWeight = allocation.cyclicWeight;
result.elevatorWeight = allocation.elevatorWeight;
result.message = make_message(result);

    function J = objective(z, reference)
        penalty = bound_penalty(z, bounds);
        if penalty > 0
            J = 1.0e12 + penalty;
            return;
        end
        try
            [~, ~, R, ~, ~, finite] = evaluate_point(z);
        catch ME
            if is_solver_domain_error(ME)
                invalidEvalCount = invalidEvalCount + 1;
                invalidEvalIdentifiers{end+1} = ME.identifier;
                J = 1.0e30;
                return;
            end
            rethrow(ME);
        end
        if ~finite
            invalidEvalCount = invalidEvalCount + 1;
            invalidEvalIdentifiers{end+1} = ...
                'trim_longitudinal_elevator_aware:NonFiniteObjective';
            J = 1.0e30;
            return;
        end
        Rs = weights.*(R./residualScale);
        y = (z(:)-reference(:))./scale(:);
        J = Rs.'*Rs + sum(regularization.*(y.^2)) + penalty;
    end

    function [x, u, R, xd, out, finite, allocation] = evaluate_point(z)
        stateNames = get_state_names(P);
        controlNames = get_control_input_names(P);
        derivativeNames = derivative_names(P);
        values = named_struct(unknownNames, z);
        theta = values.theta;
        alpha = theta - caseDef.gamma;
        x = zeros(get_state_dimension(P), 1);
        x(strcmp(stateNames, 'theta')) = theta;
        if caseDef.V < 1.0e-10
            x(strcmp(stateNames, 'u')) = 0;
            x(strcmp(stateNames, 'w')) = 0;
        else
            x(strcmp(stateNames, 'u')) = caseDef.V*cos(alpha);
            x(strcmp(stateNames, 'w')) = caseDef.V*sin(alpha);
        end
        if has_nacelle_dynamic_states(P)
            x(strcmp(stateNames, 'betaM')) = caseDef.betaM;
            x(strcmp(stateNames, 'betaM_dot')) = 0;
        end

        u = zeros(numel(controlNames), 1);
        allocation = schedule_values(caseDef.betaM, values, P, options);
        for iName = 1:numel(controlNames)
            name = controlNames{iName};
            if isfield(values, name)
                u(iName) = values.(name);
            elseif isfield(allocation, name)
                u(iName) = allocation.(name);
            end
        end

        [xd, out] = tiltrotor_eom(x, u, caseDef.betaM, P);
        xd = xd(:);
        R = zeros(numel(residualNames), 1);
        for iResidual = 1:numel(residualNames)
            R(iResidual) = xd(strcmp(derivativeNames, ...
                residualNames{iResidual}));
        end
        finite = is_real_finite(R) && is_real_finite(xd);
    end
end

function caseDef = normalize_case(caseDef)
if ~isfield(caseDef, 'V')
    error('trim_longitudinal_elevator_aware:InvalidCase', ...
        'caseDef.V is required.');
end
if isfield(caseDef, 'betaM')
    betaM = caseDef.betaM;
elseif isfield(caseDef, 'betaMDeg')
    betaM = caseDef.betaMDeg*pi/180;
else
    error('trim_longitudinal_elevator_aware:InvalidCase', ...
        'caseDef.betaM or caseDef.betaMDeg is required.');
end
if isfield(caseDef, 'gamma')
    gamma = caseDef.gamma;
elseif isfield(caseDef, 'gammaDeg')
    gamma = caseDef.gammaDeg*pi/180;
else
    gamma = 0;
end
if ~isfield(caseDef, 'name') || isempty(caseDef.name)
    caseDef.name = 'unnamed_case';
end
values = [caseDef.V, betaM, gamma];
if any(~isfinite(values)) || any(~isreal(values)) || caseDef.V < 0 || ...
        betaM < 0 || betaM > pi/2 || abs(gamma) > pi/2
    error('trim_longitudinal_elevator_aware:InvalidCase', ...
        'Case requires V >= 0, betaM in [0, pi/2], and |gamma| <= pi/2.');
end
caseDef.betaM = betaM;
caseDef.betaMDeg = betaM*180/pi;
caseDef.gamma = gamma;
caseDef.gammaDeg = gamma*180/pi;
end

function options = apply_defaults(options, P)
if ~isfield(options, 'candidateName') || isempty(options.candidateName)
    options.candidateName = 'theta_collective_cyclicLong';
end
if ~isfield(options, 'controlSet') || isempty(options.controlSet)
    options.controlSet = options.candidateName;
end
if ~isfield(options, 'useSchedule') || isempty(options.useSchedule)
    options.useSchedule = strcmp(options.controlSet, ...
        'theta_collective_scheduled_pitch');
end
if ~isfield(options, 'maxIterations') || isempty(options.maxIterations)
    options.maxIterations = P.trim.maxIterations;
end
if ~isfield(options, 'tolerance') || isempty(options.tolerance)
    options.tolerance = P.trim.residualTolerance;
end
if ~isfield(options, 'runHeavy') || isempty(options.runHeavy)
    options.runHeavy = true;
end
if ~isfield(options, 'outputDiagnostics') || isempty(options.outputDiagnostics)
    options.outputDiagnostics = true;
end
if ~isfield(options, 'residualWeights') || isempty(options.residualWeights)
    options.residualWeights = [1; 1; 1];
end
if ~isfield(options, 'regularizationWeights') || ...
        isempty(options.regularizationWeights)
    options.regularizationWeights = struct();
end
if ~isfield(options, 'direction') || isempty(options.direction)
    options.direction = struct('cyclicDirection', -1, ...
        'elevatorDirection', -1);
end
end

function [unknownNames, residualNames] = formulation_names(controlSet)
residualNames = {'udot'; 'wdot'; 'qdot'};
switch controlSet
    case 'theta_collective_cyclicLong'
        unknownNames = {'theta'; 'collective'; 'cyclicLong'};
    case 'theta_collective_elevator'
        unknownNames = {'theta'; 'collective'; 'elevator'};
    case 'theta_collective_cyclicLong_elevator_regularized'
        unknownNames = {'theta'; 'collective'; 'cyclicLong'; 'elevator'};
    case 'theta_collective_scheduled_pitch'
        unknownNames = {'theta'; 'collective'; 'pitchCommand'};
    otherwise
        error('trim_longitudinal_elevator_aware:UnsupportedControlSet', ...
            'Unsupported controlSet %s.', controlSet);
end
end

function z0 = initial_values(caseDef, unknownNames)
d2r = pi/180;
z0 = zeros(numel(unknownNames), 1);
for i = 1:numel(unknownNames)
    switch unknownNames{i}
        case 'theta'
            z0(i) = 4*d2r;
        case 'collective'
            if caseDef.betaM < pi/4
                z0(i) = 16*d2r;
            else
                z0(i) = 8*d2r;
            end
        case 'cyclicLong'
            if caseDef.betaM < pi/4
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
scale = 2*d2r*ones(numel(names), 1);
scale(strcmp(names, 'collective')) = 18*d2r;
scale(strcmp(names, 'pitchCommand')) = 0.2;
end

function bounds = variable_bounds(names, caseDef, P)
d2r = pi/180;
bounds = zeros(numel(names), 2);
for i = 1:numel(names)
    switch names{i}
        case 'theta'
            bounds(i,:) = 35*d2r*[-1, 1];
        case 'collective'
            bounds(i,:) = P.control.collectiveLim(:).';
        case {'cyclicLong','diffCyclic','lateralCyclic'}
            bounds(i,:) = P.control.cyclicLim(:).';
        case 'elevator'
            bounds(i,:) = P.control.elevatorLim(:).';
        case 'pitchCommand'
            weights = schedule_weights(caseDef.betaM);
            bounds(i,:) = [-1, 1]/max([weights.cyclicWeight, ...
                weights.elevatorWeight]);
        otherwise
            error('trim_longitudinal_elevator_aware:UnknownVariable', ...
                'Unsupported variable %s.', names{i});
    end
end
end

function weights = schedule_weights(betaM)
weights.cyclicWeight = cos(betaM)^2;
weights.elevatorWeight = sin(betaM)^2;
end

function allocation = schedule_values(betaM, values, P, options)
weights = schedule_weights(betaM);
allocation.cyclicWeight = weights.cyclicWeight;
allocation.elevatorWeight = weights.elevatorWeight;
allocation.pitchCommand = NaN;
allocation.cyclicLong = 0;
allocation.elevator = 0;
if isfield(values, 'pitchCommand')
    pitchCommand = values.pitchCommand;
    allocation.pitchCommand = pitchCommand;
    allocation.cyclicLong = options.direction.cyclicDirection * ...
        weights.cyclicWeight * max(abs(P.control.cyclicLim(:))) * ...
        pitchCommand;
    allocation.elevator = options.direction.elevatorDirection * ...
        weights.elevatorWeight * max(abs(P.control.elevatorLim(:))) * ...
        pitchCommand;
end
end

function weights = residual_weights(options, residualNames)
weights = options.residualWeights(:);
if numel(weights) ~= numel(residualNames)
    error('trim_longitudinal_elevator_aware:InvalidResidualWeights', ...
        'residualWeights must match residualNames length.');
end
if ~is_real_finite(weights) || any(weights <= 0)
    error('trim_longitudinal_elevator_aware:InvalidResidualWeights', ...
        'residualWeights must be finite positive values.');
end
end

function weights = regularization_weights(options, unknownNames)
weights = 1.0e-5*ones(numel(unknownNames), 1);
if isstruct(options.regularizationWeights)
    for i = 1:numel(unknownNames)
        name = unknownNames{i};
        if isfield(options.regularizationWeights, name)
            weights(i) = options.regularizationWeights.(name);
        end
    end
else
    raw = options.regularizationWeights(:);
    if numel(raw) == numel(unknownNames)
        weights = raw;
    end
end
if ~is_real_finite(weights) || any(weights < 0)
    error('trim_longitudinal_elevator_aware:InvalidRegularizationWeights', ...
        'regularizationWeights must be finite nonnegative values.');
end
end

function seeds = make_seeds(z0, scale, options)
seeds = z0(:);
if ~options.runHeavy
    return;
end
offsets = [eye(numel(z0)), -eye(numel(z0))];
seeds = [z0(:), z0(:) + scale(:).*offsets];
end

function scale = residual_scales(names, P)
scale = ones(numel(names), 1);
scale(ismember(names, {'udot','vdot','wdot'})) = P.env.g;
end

function penalty = bound_penalty(values, bounds)
below = max(bounds(:,1)-values(:), 0);
above = max(values(:)-bounds(:,2), 0);
penalty = 1.0e6*sum(below.^2 + above.^2);
end

function report = make_limit_report(names, values, bounds, u, P, allocation)
tol = 1.0e-7;
controlNames = get_control_input_names(P);
items = repmat(struct('name', '', 'value', NaN, 'lower', NaN, ...
    'upper', NaN, 'atLower', false, 'atUpper', false, ...
    'atLimit', false, 'violated', false, 'marginFraction', NaN), ...
    numel(names) + 2, 1);
n = 0;
for i = 1:numel(names)
    n = n + 1;
    items(n) = limit_item(names{i}, values(i), bounds(i,:), tol);
end
extraNames = {'cyclicLong','elevator'};
for iName = 1:numel(extraNames)
    name = extraNames{iName};
    idx = find(strcmp(controlNames, name), 1);
    if ~isempty(idx) && ~any(strcmp(names, name)) && ...
            isfield(allocation, name) && allocation.(name) ~= 0
        n = n + 1;
        items(n) = limit_item(name, u(idx), control_bounds(name, P), tol);
    end
end
items = items(1:n);
report.items = items;
report.anyAtLimit = any([items.atLimit]);
report.anyViolation = any([items.violated]);
report.activeLimitNames = strjoin({items([items.atLimit]).name}, ';');
end

function item = limit_item(name, value, limits, tol)
span = limits(2)-limits(1);
margin = min(value-limits(1), limits(2)-value);
item.name = name;
item.value = value;
item.lower = limits(1);
item.upper = limits(2);
item.atLower = abs(value-limits(1)) <= tol;
item.atUpper = abs(value-limits(2)) <= tol;
item.atLimit = item.atLower || item.atUpper;
item.violated = value < limits(1)-tol || value > limits(2)+tol;
item.marginFraction = 2*margin/span;
end

function bounds = control_bounds(name, P)
switch name
    case 'collective'
        bounds = P.control.collectiveLim(:).';
    case {'cyclicLong','diffCyclic','lateralCyclic'}
        bounds = P.control.cyclicLim(:).';
    case 'elevator'
        bounds = P.control.elevatorLim(:).';
    otherwise
        bounds = [-Inf, Inf];
end
end

function result = named_struct(names, values)
result = struct();
for i = 1:numel(names)
    result.(names{i}) = values(i);
end
end

function names = derivative_names(P)
names = {'udot'; 'vdot'; 'wdot'; 'pdot'; 'qdot'; ...
    'rdot'; 'phidot'; 'thetadot'; 'psidot'};
if has_nacelle_dynamic_states(P)
    names = [names; {'betaM_dot'; 'betaM_ddot'}];
end
end

function label = dominant_label(labels, values)
[~, idx] = max(abs(values));
label = labels{idx};
end

function message = make_message(result)
if result.success
    message = sprintf(['Elevator-aware candidate converged: residual norm ' ...
        '%.3e.'], result.residualNorm);
elseif ~result.finite
    message = 'Elevator-aware candidate failed: non-finite evaluation.';
elseif ~result.withinDefaultLimits
    message = 'Elevator-aware candidate failed: limit violation.';
elseif result.atLimit
    message = 'Elevator-aware candidate failed: solution is at a limit.';
else
    message = sprintf(['Elevator-aware candidate did not meet tolerance: ' ...
        'residual norm %.3e.'], result.residualNorm);
end
end

function tf = is_solver_domain_error(ME)
tf = strcmp(ME.identifier, 'rotor_model_bemt:FlapNotConverged') || ...
    strcmp(ME.identifier, 'rotor_model_bemt:CoupledSolveNotConverged');
end

function tf = is_real_finite(value)
tf = isreal(value) && all(isfinite(value(:)));
end
