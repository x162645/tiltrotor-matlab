function [xTrim, uTrim, report] = trim_lateral_directional_balance( ...
        baseTrim, betaM, P, opts)
%TRIM_LATERAL_DIRECTIONAL_BALANCE Balance lateral residuals near a base trim.
%
% The longitudinal state and controls come from an already evaluated
% longitudinal trim point. This solver only adjusts named lateral controls
% and minimizes [vdot; pdot; rdot] with a small control regularization term.

if nargin < 4
    opts = struct();
end
validate_base_trim(baseTrim, P);
if ~(isnumeric(betaM) && isreal(betaM) && isscalar(betaM) && isfinite(betaM))
    error('trim_lateral_directional_balance:InvalidBetaM', ...
        'betaM must be a finite real scalar.');
end

controlNames = get_control_input_names(P);
derivativeNames = derivative_names(P);
residualNames = {'vdot'; 'pdot'; 'rdot'};
selectedControls = lateral_control_set(controlNames);
selectedIndex = control_indices(controlNames, selectedControls);
z0 = baseTrim.uTrim(selectedIndex);
scale = control_scales(selectedControls);
bounds = control_bounds(selectedControls, P);
regularizationWeight = get_option(opts, 'regularizationWeight', 1.0e-4);
tolerance = get_option(opts, 'residualTolerance', P.trim.residualTolerance);
residualScale = residual_scales(residualNames, P);

options = optimset('Display', P.trim.display, ...
    'MaxIter', P.trim.maxIterations, ...
    'MaxFunEvals', 10*P.trim.maxIterations, ...
    'TolX', 1e-8, 'TolFun', 1e-10);

invalidEvalCount = 0;
invalidEvalIdentifiers = {};
[yOpt, fval, exitflag, output] = fminsearch(@objective, ...
    zeros(numel(z0),1), options);
zOpt = z0 + scale.*yOpt(:);
[xTrim, uTrim, residual, xdot, eomOut, finiteResidual] = evaluate(zOpt);
limitReport = make_limit_report(selectedControls, zOpt, bounds);
scaledResidual = residual./residualScale;
controlDelta = zOpt - z0;

report.residual = residual;
report.residualNorm = norm(residual);
report.lateralResidualNorm = report.residualNorm;
report.residualLabels = residualNames(:);
report.residualScale = residualScale;
report.residualScaleUnits = {'m/s^2'; 'rad/s^2'; 'rad/s^2'};
report.scaledResidual = scaledResidual;
report.objectiveResidualCost = scaledResidual.'*scaledResidual;
report.cost = fval;
report.regularizationWeight = regularizationWeight;
report.regularizationCost = regularizationWeight*sum((controlDelta./scale).^2);
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
    report.lateralResidualNorm < tolerance && report.withinLimits && ...
    ~report.atLimit;
report.successTolerance = tolerance;
report.selectedControls = selectedControls(:);
report.controlInitial = z0;
report.controlSolution = zOpt;
report.controlDelta = controlDelta;
report.controlNorm = norm(controlDelta);
report.controlNormDeg = report.controlNorm*180/pi;
report.controlArchitecture = sprintf('%d-input', numel(controlNames));
report.effectiveDegreesOfFreedom = numel(selectedControls) - ...
    numel(residualNames);
report.baseTrimSuccess = logical(baseTrim.success);
report.baseTrimResidualNorm = baseTrim.report.residualNorm;
report.baseTrimKind = baseTrim.kind;
report.V = baseTrim.config.V;
report.betaM = betaM;
report.gamma = baseTrim.config.gammaDeg*pi/180;
report.commandedControls = uTrim;
report.appliedControls = eomOut.components.appliedControls;
report.loads = struct('Ftotal', eomOut.Ftotal, 'Mtotal', eomOut.Mtotal);
report.objectiveInvalidEvaluationCount = invalidEvalCount;
report.objectiveInvalidEvaluationIdentifiers = unique(invalidEvalIdentifiers);
report.definitionName = 'lateral_directional_balance';
report.mode = 'lateral_directional_balance';
report.unknownNames = selectedControls(:);
report.fixedStates = struct('u_w_theta_from_base_trim', true, ...
    'v', baseTrim.xTrim(2), 'p', baseTrim.xTrim(4), ...
    'q', baseTrim.xTrim(5), 'r', baseTrim.xTrim(6));
report.fixedControls = fixed_control_report(controlNames, selectedControls, ...
    uTrim);
report.message = make_message(report);

    function J = objective(y)
        z = z0 + scale.*y(:);
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
                'trim_lateral_directional_balance:NonFiniteObjective';
            J = 1.0e30;
            return;
        end
        Rs = R./residualScale;
        penalty = bound_penalty(z, bounds);
        J = Rs.'*Rs + regularizationWeight*sum((z-z0).^2./scale.^2) + ...
            penalty;
    end

    function [x, u, R, xd, out, finite] = evaluate(z)
        x = baseTrim.xTrim(:);
        u = baseTrim.uTrim(:);
        u(selectedIndex) = z(:);
        [xd, out] = tiltrotor_eom(x, u, betaM, P);
        xd = xd(:);
        R = zeros(numel(residualNames),1);
        for i = 1:numel(residualNames)
            R(i) = xd(strcmp(derivativeNames, residualNames{i}));
        end
        finite = is_real_finite(R) && is_real_finite(xd);
    end
end

function validate_base_trim(baseTrim, P)
required = {'xTrim','uTrim','success','report','kind','config'};
if ~isstruct(baseTrim) || ~all(isfield(baseTrim, required))
    error('trim_lateral_directional_balance:InvalidBaseTrim', ...
        'baseTrim must be a run_trim_case longitudinal result.');
end
if ~baseTrim.success
    error('trim_lateral_directional_balance:UnconvergedBaseTrim', ...
        'A converged longitudinal base trim is required.');
end
if numel(baseTrim.xTrim) ~= get_state_dimension(P) || ...
        numel(baseTrim.uTrim) ~= numel(get_control_input_names(P))
    error('trim_lateral_directional_balance:DimensionMismatch', ...
        'baseTrim dimensions do not match active parameters.');
end
end

function names = lateral_control_set(controlNames)
if any(strcmp(controlNames, 'lateralCyclic'))
    names = {'lateralCyclic'; 'diffCollective'; 'diffCyclic'; ...
        'aileron'; 'rudder'};
else
    names = {'diffCollective'; 'diffCyclic'; 'aileron'; 'rudder'};
end
end

function indices = control_indices(controlNames, selectedControls)
indices = zeros(numel(selectedControls),1);
for i = 1:numel(selectedControls)
    indices(i) = find(strcmp(controlNames, selectedControls{i}), 1);
end
end

function bounds = control_bounds(names, P)
bounds = zeros(numel(names),2);
for i = 1:numel(names)
    bounds(i,:) = named_control_bounds(names{i}, P);
end
end

function scale = control_scales(names)
d2r = pi/180;
scale = 2*d2r*ones(numel(names),1);
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
        error('trim_lateral_directional_balance:UnknownControl', ...
            'Unsupported control %s.', name);
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

function fixed = fixed_control_report(controlNames, selectedControls, u)
fixed = struct();
for i = 1:numel(controlNames)
    if ~any(strcmp(selectedControls, controlNames{i}))
        fixed.(controlNames{i}) = u(i);
    end
end
end

function message = make_message(report)
if report.converged
    message = sprintf(['Lateral-directional balance converged: ' ...
        'lateral residual norm %.3e.'], report.lateralResidualNorm);
elseif ~report.finite
    message = 'Lateral-directional balance failed: non-finite residual.';
elseif ~report.withinLimits
    message = 'Lateral-directional balance failed: control limit violation.';
elseif report.atLimit
    message = 'Lateral-directional balance failed: solution is at a limit.';
else
    message = sprintf(['Lateral-directional balance did not meet tolerance: ' ...
        'lateral residual norm %.3e.'], report.lateralResidualNorm);
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
