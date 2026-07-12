function [xTrim, uTrim, report] = trim_full_6dof_straight(condition, P, opts)
%TRIM_FULL_6DOF_STRAIGHT Solve straight steady six-DOF rigid-body trim.
%
% The flight task fixes V, betaM, gamma, v=0, p=q=r=0, and psi=0. The
% solver adjusts theta, phi, and a mode-dependent control set to minimize
% [udot; vdot; wdot; pdot; qdot; rdot]. This is not a coordinated-turn or
% nacelle-conversion dynamic trim.

if nargin < 3
    opts = struct();
end
validate_condition(condition);

controlNames = get_control_input_names(P);
stateNames = get_state_names(P);
derivativeNames = derivative_names(P);
residualNames = {'udot'; 'vdot'; 'wdot'; 'pdot'; 'qdot'; 'rdot'};
unknownNames = full_unknown_set(controlNames);
initialValues = initial_guess(condition, P, opts, unknownNames);
scale = variable_scales(unknownNames);
bounds = variable_bounds(unknownNames, P, opts);
tolerance = get_option(opts, 'residualTolerance', P.trim.residualTolerance);
regularizationWeight = get_option(opts, 'regularizationWeight', 1.0e-6);
residualScale = residual_scales(residualNames, P);

options = optimset('Display', P.trim.display, ...
    'MaxIter', P.trim.maxIterations, ...
    'MaxFunEvals', 10*P.trim.maxIterations, ...
    'TolX', 1e-8, 'TolFun', 1e-10);

invalidEvalCount = 0;
invalidEvalIdentifiers = {};
[yOpt, fval, exitflag, output] = fminsearch(@objective, ...
    zeros(numel(initialValues),1), options);
zOpt = initialValues + scale.*yOpt(:);
[xTrim, uTrim, residual, xdot, eomOut, finiteResidual] = evaluate(zOpt);
limitReport = make_limit_report(unknownNames, zOpt, bounds);
scaledResidual = residual./residualScale;

report.residual = residual;
report.residualNorm = norm(residual);
report.primaryResidualNorm = report.residualNorm;
report.residualLabels = residualNames(:);
report.residualScale = residualScale;
report.residualScaleUnits = {'m/s^2'; 'm/s^2'; 'm/s^2'; ...
    'rad/s^2'; 'rad/s^2'; 'rad/s^2'};
report.scaledResidual = scaledResidual;
report.objectiveResidualCost = scaledResidual.'*scaledResidual;
report.cost = fval;
report.regularizationWeight = regularizationWeight;
report.regularizationCost = regularizationWeight* ...
    sum(((zOpt-initialValues)./scale).^2);
report.exitflag = exitflag;
report.output = output;
report.solverConverged = exitflag > 0;
report.fullStateDerivative = xdot;
report.fullResidualNorm = norm(xdot);
report.fullResidualLabels = derivativeNames;
report.finiteFullStateDerivative = is_real_finite(xdot);
report.finite = finiteResidual && report.finiteFullStateDerivative && ...
    is_real_finite(xTrim) && is_real_finite(uTrim);
report.limitReport = limitReport;
report.atLimit = limitReport.anyAtLimit;
report.withinLimits = ~limitReport.anyViolation;
report.converged = report.solverConverged && report.finite && ...
    report.primaryResidualNorm < tolerance && report.withinLimits && ...
    ~report.atLimit;
report.successTolerance = tolerance;
report.unknownNames = unknownNames(:);
report.trimVariables = named_struct(unknownNames, zOpt);
report.initialValues = initialValues;
report.variableScale = scale;
report.bounds = bounds;
report.controlArchitecture = sprintf('%d-input', numel(controlNames));
report.selectedControls = intersect_preserve(unknownNames, controlNames);
report.V = condition.V;
report.betaM = condition.betaM;
report.gamma = condition.gamma;
report.commandedControls = uTrim;
report.appliedControls = eomOut.components.appliedControls;
report.loads = struct('Ftotal', eomOut.Ftotal, 'Mtotal', eomOut.Mtotal);
report.objectiveInvalidEvaluationCount = invalidEvalCount;
report.objectiveInvalidEvaluationIdentifiers = unique(invalidEvalIdentifiers);
report.definitionName = 'full_6dof_straight_trim';
report.mode = 'full_6dof_straight_trim';
report.fixedStates = struct('V', condition.V, 'gamma', condition.gamma, ...
    'v', 0, 'p', 0, 'q', 0, 'r', 0, 'psi', 0);
report.fixedControls = fixed_control_report(controlNames, unknownNames, uTrim);
report.message = make_message(report);

    function J = objective(y)
        z = initialValues + scale.*y(:);
        try
            [~, ~, R, ~, ~, finite] = evaluate(z);
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
                'trim_full_6dof_straight:NonFiniteObjective';
            J = 1.0e30;
            return;
        end
        Rs = R./residualScale;
        J = Rs.'*Rs + regularizationWeight*sum(y(:).^2) + ...
            bound_penalty(z, bounds);
    end

    function [x, u, R, xd, out, finite] = evaluate(z)
        values = named_struct(unknownNames, z);
        theta = values.theta;
        phi = values.phi;
        alpha = theta - condition.gamma;
        x = zeros(get_state_dimension(P),1);
        x(strcmp(stateNames, 'phi')) = phi;
        x(strcmp(stateNames, 'theta')) = theta;
        if condition.V < 1.0e-10
            x(strcmp(stateNames, 'u')) = 0;
            x(strcmp(stateNames, 'w')) = 0;
        else
            x(strcmp(stateNames, 'u')) = condition.V*cos(alpha);
            x(strcmp(stateNames, 'w')) = condition.V*sin(alpha);
        end
        if has_nacelle_dynamic_states(P)
            x(strcmp(stateNames, 'betaM')) = condition.betaM;
            x(strcmp(stateNames, 'betaM_dot')) = 0;
        end
        u = zeros(numel(controlNames),1);
        for i = 1:numel(controlNames)
            if isfield(values, controlNames{i})
                u(i) = values.(controlNames{i});
            end
        end
        [xd, out] = tiltrotor_eom(x, u, condition.betaM, P);
        xd = xd(:);
        R = zeros(numel(residualNames),1);
        for i = 1:numel(residualNames)
            R(i) = xd(strcmp(derivativeNames, residualNames{i}));
        end
        finite = is_real_finite(R) && is_real_finite(xd);
    end
end

function validate_condition(condition)
required = {'V','betaM','gamma'};
if ~isstruct(condition) || ~all(isfield(condition, required))
    error('trim_full_6dof_straight:InvalidCondition', ...
        'condition must contain V, betaM, and gamma.');
end
for i = 1:numel(required)
    value = condition.(required{i});
    if ~(isnumeric(value) && isreal(value) && isscalar(value) && ...
            isfinite(value))
        error('trim_full_6dof_straight:InvalidCondition', ...
            'condition.%s must be a finite real scalar.', required{i});
    end
end
if condition.V < 0 || condition.betaM < 0 || condition.betaM > pi/2 || ...
        abs(condition.gamma) > pi/2
    error('trim_full_6dof_straight:InvalidCondition', ...
        'condition requires V >= 0, betaM in [0, pi/2], and |gamma| <= pi/2.');
end
end

function names = full_unknown_set(controlNames)
if any(strcmp(controlNames, 'lateralCyclic'))
    names = {'theta'; 'phi'; 'collective'; 'cyclicLong'; ...
        'lateralCyclic'; 'rudder'};
else
    names = {'theta'; 'phi'; 'collective'; 'cyclicLong'; ...
        'aileron'; 'rudder'};
end
end

function z0 = initial_guess(condition, P, opts, unknownNames)
d2r = pi/180;
if isfield(opts, 'baseTrim') && isstruct(opts.baseTrim) && ...
        isfield(opts.baseTrim, 'success') && opts.baseTrim.success
    base = opts.baseTrim;
else
    trimOpts.gamma = condition.gamma;
    trimOpts.useMultiStart = false;
    trimOpts.alwaysMultiStart = false;
    [xBase, uBase, reportBase] = trim_symmetric( ...
        condition.V, condition.betaM, P, trimOpts);
    base = struct('xTrim', xBase, 'uTrim', uBase, 'report', reportBase, ...
        'success', reportBase.converged);
end
stateNames = get_state_names(P);
controlNames = get_control_input_names(P);
z0 = zeros(numel(unknownNames),1);
for i = 1:numel(unknownNames)
    stateIndex = find(strcmp(stateNames, unknownNames{i}), 1);
    controlIndex = find(strcmp(controlNames, unknownNames{i}), 1);
    if ~isempty(stateIndex)
        z0(i) = base.xTrim(stateIndex);
    elseif ~isempty(controlIndex)
        z0(i) = base.uTrim(controlIndex);
    end
end
if any(strcmp(unknownNames, 'phi'))
    z0(strcmp(unknownNames, 'phi')) = 0;
end
if ~isfield(opts, 'baseTrim') && condition.V >= 1 && ~base.success
    z0(strcmp(unknownNames, 'theta')) = 4*d2r;
    z0(strcmp(unknownNames, 'collective')) = 12*d2r;
end
end

function scale = variable_scales(names)
d2r = pi/180;
scale = zeros(numel(names),1);
for i = 1:numel(names)
    switch names{i}
        case 'collective'
            scale(i) = 18*d2r;
        otherwise
            scale(i) = 2*d2r;
    end
end
end

function bounds = variable_bounds(names, P, opts)
d2r = pi/180;
thetaLimitDeg = get_option(opts, 'thetaLimitDeg', 35);
phiLimitDeg = get_option(opts, 'phiLimitDeg', 30);
bounds = zeros(numel(names),2);
for i = 1:numel(names)
    switch names{i}
        case 'theta'
            bounds(i,:) = thetaLimitDeg*d2r*[-1, 1];
        case 'phi'
            bounds(i,:) = phiLimitDeg*d2r*[-1, 1];
        otherwise
            bounds(i,:) = named_control_bounds(names{i}, P);
    end
end
end

function limits = named_control_bounds(name, P)
switch name
    case 'collective'
        limits = P.control.collectiveLim(:).';
    case 'diffCollective'
        limits = max(abs(P.control.collectiveLim(:)))*[-1, 1];
    case {'cyclicLong','diffCyclic','lateralCyclic'}
        limits = P.control.cyclicLim(:).';
    case 'aileron'
        limits = P.control.aileronLim(:).';
    case 'elevator'
        limits = P.control.elevatorLim(:).';
    case 'rudder'
        limits = P.control.rudderLim(:).';
    otherwise
        error('trim_full_6dof_straight:UnknownVariable', ...
            'Unsupported trim variable %s.', name);
end
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
    'atLimit', false, 'violated', false, 'marginFraction', NaN), ...
    numel(names), 1);
for i = 1:numel(names)
    span = bounds(i,2)-bounds(i,1);
    margin = min(values(i)-bounds(i,1), bounds(i,2)-values(i));
    items(i).name = names{i};
    items(i).value = values(i);
    items(i).lower = bounds(i,1);
    items(i).upper = bounds(i,2);
    items(i).atLower = abs(values(i)-bounds(i,1)) <= tol;
    items(i).atUpper = abs(values(i)-bounds(i,2)) <= tol;
    items(i).atLimit = items(i).atLower || items(i).atUpper;
    items(i).violated = values(i) < bounds(i,1)-tol || ...
        values(i) > bounds(i,2)+tol;
    items(i).marginFraction = 2*margin/span;
end
report.items = items;
report.anyAtLimit = any([items.atLimit]);
report.anyViolation = any([items.violated]);
end

function scale = residual_scales(names, P)
scale = ones(numel(names),1);
scale(ismember(names, {'udot','vdot','wdot'})) = P.env.g;
end

function result = named_struct(names, values)
result = struct();
for i = 1:numel(names)
    result.(names{i}) = values(i);
end
end

function names = intersect_preserve(a, b)
names = {};
for i = 1:numel(a)
    if any(strcmp(b, a{i}))
        names{end+1,1} = a{i}; %#ok<AGROW>
    end
end
end

function fixed = fixed_control_report(controlNames, unknownNames, u)
fixed = struct();
for i = 1:numel(controlNames)
    if ~any(strcmp(unknownNames, controlNames{i}))
        fixed.(controlNames{i}) = u(i);
    end
end
end

function message = make_message(report)
if report.converged
    message = sprintf('Full 6-DOF straight trim converged: residual norm %.3e.', ...
        report.primaryResidualNorm);
elseif ~report.finite
    message = 'Full 6-DOF straight trim failed: non-finite residual.';
elseif ~report.withinLimits
    message = 'Full 6-DOF straight trim failed: limit violation.';
elseif report.atLimit
    message = 'Full 6-DOF straight trim failed: solution is at a limit.';
else
    message = sprintf(['Full 6-DOF straight trim did not meet tolerance: ' ...
        'residual norm %.3e.'], report.primaryResidualNorm);
end
end

function value = get_option(opts, name, defaultValue)
if isfield(opts, name) && ~isempty(opts.(name))
    value = opts.(name);
else
    value = defaultValue;
end
end

function names = derivative_names(P)
names = {'udot'; 'vdot'; 'wdot'; 'pdot'; 'qdot'; ...
    'rdot'; 'phidot'; 'thetadot'; 'psidot'};
if has_nacelle_dynamic_states(P)
    names = [names; {'betaM_dot'; 'betaM_ddot'}];
end
end

function tf = is_solver_domain_error(ME)
tf = strcmp(ME.identifier, 'rotor_model_bemt:FlapNotConverged') || ...
    strcmp(ME.identifier, 'rotor_model_bemt:CoupledSolveNotConverged');
end

function tf = is_real_finite(value)
tf = isreal(value) && all(isfinite(value(:)));
end
