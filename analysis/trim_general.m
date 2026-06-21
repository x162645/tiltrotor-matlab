function [xTrim, uTrim, report] = trim_general(condition, definition, P, opts)
%TRIM_GENERAL Mode-configurable longitudinal trim using named quantities.
%
% condition requires V [m/s], betaM [rad], and gamma [rad]. The definition
% explicitly names unknowns, residuals, fixed states/controls, numerical
% initial values/scales, and bounds. No mode is inferred from betaM.

if nargin < 4
    opts = struct();
end
validate_condition(condition);
definition = validate_definition(definition);

if definition.compatibilityMode
    validate_legacy_compatibility(definition, P);
    legacyOpts = opts;
    legacyOpts.gamma = condition.gamma;
    if ~isfield(legacyOpts, 'initialDeg')
        legacyOpts.initialDeg = definition.initialValues(:).'*180/pi;
    end
    [xTrim, uTrim, report] = trim_symmetric( ...
        condition.V, condition.betaM, P, legacyOpts);
    report = add_definition_report(report, definition);
    return;
end

stateNames = {'u'; 'v'; 'w'; 'p'; 'q'; 'r'; 'phi'; 'theta'; 'psi'};
controlNames = {'collective'; 'diffCollective'; 'cyclicLong'; ...
    'diffCyclic'; 'aileron'; 'elevator'; 'rudder'};
derivativeNames = {'udot'; 'vdot'; 'wdot'; 'pdot'; 'qdot'; ...
    'rdot'; 'phidot'; 'thetadot'; 'psidot'};

nUnknown = numel(definition.unknownNames);
y0 = ones(nUnknown, 1);
z0 = definition.initialValues(:);
scale = definition.variableScale(:);
bounds = definition.bounds;
options = optimset('Display', P.trim.display, ...
    'MaxIter', P.trim.maxIterations, ...
    'MaxFunEvals', 10*P.trim.maxIterations, ...
    'TolX', 1e-8, 'TolFun', 1e-10);

invalidEvalCount = 0;
invalidEvalIdentifiers = {};
[yOpt, fval, exitflag, output] = fminsearch(@objective, y0, options);
zOpt = from_scaled(yOpt);
[xTrim, uTrim, residual, penalty, xdotFull, eomOut] = build_point(zOpt);
limitReport = make_limit_report(zOpt);
residualScale = residual_scales(definition.residualNames, P);
scaledResidual = residual./residualScale;

report.residual = residual;
report.residualNorm = norm(residual);
report.residualLabels = definition.residualNames;
report.residualScale = residualScale;
report.scaledResidual = scaledResidual;
report.objectiveResidualCost = scaledResidual.'*scaledResidual;
report.cost = fval;
report.penalty = penalty;
report.exitflag = exitflag;
report.output = output;
report.solverConverged = exitflag > 0;
report.fullStateDerivative = xdotFull;
report.fullResidualNorm = norm(xdotFull);
report.fullResidualLabels = derivativeNames;
report.finiteFullStateDerivative = is_real_finite(xdotFull);
report.limitReport = limitReport;
report.atLimit = limitReport.anyAtLimit;
report.withinLimits = ~limitReport.anyViolation;
report.converged = report.solverConverged && ...
    report.residualNorm < P.trim.residualTolerance && ...
    report.finiteFullStateDerivative && ~report.atLimit && report.withinLimits;
report.V = condition.V;
report.betaM = condition.betaM;
report.gamma = condition.gamma;
report.commandedControls = uTrim;
report.appliedControls = eomOut.components.appliedControls;
report.trimVariableScale = scale;
report.trimVariableScaleUnits = 'rad';
report.trimVariableScaleClassification = 'NUMERICAL';
report.searchVariable = 'dimensionless';
report.searchMapping = 'z = initialValues + variableScale.*(y - ones(n,1))';
report.objectiveInvalidEvaluationCount = invalidEvalCount;
report.objectiveInvalidEvaluationIdentifiers = unique(invalidEvalIdentifiers);
report = add_definition_report(report, definition);
report.trimVariables = named_struct(definition.unknownNames, zOpt);

    function z = from_scaled(y)
        z = z0 + scale.*(y(:)-y0);
    end

    function J = objective(y)
        try
            [~, ~, R, thisPenalty] = build_point(from_scaled(y));
        catch ME
            if is_objective_domain_error(ME)
                invalidEvalCount = invalidEvalCount + 1;
                invalidEvalIdentifiers{end+1} = ME.identifier;
                J = 1.0e30;
                return;
            end
            rethrow(ME);
        end
        if ~is_real_finite(R) || ~isfinite(thisPenalty)
            invalidEvalCount = invalidEvalCount + 1;
            invalidEvalIdentifiers{end+1} = 'trim_general:NonFiniteObjective';
            J = 1.0e30;
            return;
        end
        rs = R./residual_scales(definition.residualNames, P);
        J = rs.'*rs + thisPenalty;
    end

    function [x, uCtrl, R, thisPenalty, xd, thisEomOut] = build_point(z)
        x = zeros(9,1);
        uCtrl = zeros(7,1);
        x = apply_named_values(x, stateNames, definition.fixedStates);
        uCtrl = apply_named_values(uCtrl, controlNames, definition.fixedControls);
        for i = 1:nUnknown
            name = definition.unknownNames{i};
            stateIndex = find(strcmp(stateNames, name), 1);
            if ~isempty(stateIndex)
                x(stateIndex) = z(i);
            else
                uCtrl(strcmp(controlNames, name)) = z(i);
            end
        end
        theta = x(strcmp(stateNames, 'theta'));
        alpha = theta-condition.gamma;
        if condition.V < 1e-10
            x(strcmp(stateNames, 'u')) = 0;
            x(strcmp(stateNames, 'w')) = 0;
        else
            x(strcmp(stateNames, 'u')) = condition.V*cos(alpha);
            x(strcmp(stateNames, 'w')) = condition.V*sin(alpha);
        end
        [xd, thisEomOut] = tiltrotor_eom(x, uCtrl, condition.betaM, P);
        xd = xd(:);
        R = zeros(numel(definition.residualNames),1);
        for j = 1:numel(R)
            R(j) = xd(strcmp(derivativeNames, definition.residualNames{j}));
        end
        below = max(bounds(:,1)-z(:), 0);
        above = max(z(:)-bounds(:,2), 0);
        thisPenalty = 100*sum(below.^2 + above.^2);
    end

    function limits = make_limit_report(z)
        tol = 1.0e-8;
        items = repmat(struct('name', '', 'value', NaN, 'lower', NaN, ...
            'upper', NaN, 'atLower', false, 'atUpper', false, ...
            'atLimit', false, 'violated', false), nUnknown, 1);
        for k = 1:nUnknown
            items(k).name = definition.unknownNames{k};
            items(k).value = z(k);
            items(k).lower = bounds(k,1);
            items(k).upper = bounds(k,2);
            items(k).atLower = abs(z(k)-bounds(k,1)) <= tol;
            items(k).atUpper = abs(z(k)-bounds(k,2)) <= tol;
            items(k).atLimit = items(k).atLower || items(k).atUpper;
            items(k).violated = z(k) < bounds(k,1)-tol || ...
                z(k) > bounds(k,2)+tol;
        end
        limits.items = items;
        limits.anyAtLimit = any([items.atLimit]);
        limits.anyViolation = any([items.violated]);
    end
end

function validate_condition(condition)
required = {'V', 'betaM', 'gamma'};
if ~isstruct(condition) || ~all(isfield(condition, required))
    error('trim_general:InvalidDefinition', ...
        'condition must contain V, betaM, and gamma.');
end
for i = 1:numel(required)
    value = condition.(required{i});
    if ~(isnumeric(value) && isreal(value) && isscalar(value) && isfinite(value))
        error('trim_general:InvalidDefinition', ...
            'condition.%s must be a finite real scalar.', required{i});
    end
end
if condition.V < 0 || condition.betaM < 0 || condition.betaM > pi/2
    error('trim_general:InvalidDefinition', ...
        'condition requires V >= 0 and betaM in [0, pi/2].');
end
end

function definition = validate_definition(definition)
required = {'name','mode','unknownNames','residualNames','fixedStates', ...
    'fixedControls','initialValues','variableScale','bounds'};
if ~isstruct(definition) || ~all(isfield(definition, required))
    error('trim_general:InvalidDefinition', ...
        'definition is missing one or more required fields.');
end
if ~(ischar(definition.name) && isrow(definition.name) && ~isempty(definition.name)) || ...
        ~(ischar(definition.mode) && isrow(definition.mode) && ~isempty(definition.mode))
    error('trim_general:InvalidDefinition', ...
        'definition name and mode must be nonempty character vectors.');
end
if ~isfield(definition, 'compatibilityMode')
    definition.compatibilityMode = false;
end
definition.unknownNames = normalize_names(definition.unknownNames, 'unknownNames');
definition.residualNames = normalize_names(definition.residualNames, 'residualNames');
if numel(unique(definition.unknownNames)) ~= numel(definition.unknownNames)
    error('trim_general:InvalidDefinition', 'unknownNames contains duplicates.');
end

stateUnknowns = {'theta'};
controlNames = {'collective','diffCollective','cyclicLong','diffCyclic', ...
    'aileron','elevator','rudder'};
residualNames = {'udot','vdot','wdot','pdot','qdot','rdot', ...
    'phidot','thetadot','psidot'};
if ~all(ismember(definition.unknownNames, [stateUnknowns, controlNames])) || ...
        ~all(ismember(definition.residualNames, residualNames))
    error('trim_general:InvalidDefinition', ...
        'Definition contains an unsupported unknown or residual name.');
end
if ~isstruct(definition.fixedStates) || ~isscalar(definition.fixedStates) || ...
        ~isstruct(definition.fixedControls) || ~isscalar(definition.fixedControls)
    error('trim_general:InvalidDefinition', ...
        'fixedStates and fixedControls must be scalar structs.');
end

fixedStateNames = fieldnames(definition.fixedStates).';
fixedControlNames = fieldnames(definition.fixedControls).';
allowedFixedStates = {'v','p','q','r','phi','theta','psi'};
if ~all(ismember(fixedStateNames, allowedFixedStates)) || ...
        ~all(ismember(fixedControlNames, controlNames))
    error('trim_general:InvalidDefinition', ...
        'Definition contains an unsupported fixed state or control name.');
end
if any(ismember(definition.unknownNames, [fixedStateNames, fixedControlNames]))
    error('trim_general:InvalidDefinition', ...
        'An unknown cannot also be fixed.');
end
validate_fixed_values(definition.fixedStates);
validate_fixed_values(definition.fixedControls);

nUnknown = numel(definition.unknownNames);
nResidual = numel(definition.residualNames);
if nUnknown > nResidual
    if all(ismember({'theta','collective','cyclicLong','elevator'}, ...
            definition.unknownNames)) && nResidual == 3
        error('trim_general:AllocationConstraintRequired', ...
            ['Four longitudinal unknowns with three equilibrium residuals ' ...
            'require an explicit open-loop allocation constraint.']);
    end
    error('trim_general:UnderdeterminedDefinition', ...
        'The definition has more unknowns than residuals.');
elseif nUnknown < nResidual
    error('trim_general:OverdeterminedDefinition', ...
        'The definition has fewer unknowns than residuals.');
end
if ~(isnumeric(definition.initialValues) && isreal(definition.initialValues) && ...
        isvector(definition.initialValues) && numel(definition.initialValues) == nUnknown && ...
        all(isfinite(definition.initialValues(:))))
    error('trim_general:InvalidDefinition', ...
        'initialValues must be a finite real vector matching unknownNames.');
end
if ~(isnumeric(definition.variableScale) && isreal(definition.variableScale) && ...
        isvector(definition.variableScale) && numel(definition.variableScale) == nUnknown && ...
        all(isfinite(definition.variableScale(:))) && all(definition.variableScale(:) > 0))
    error('trim_general:InvalidDefinition', ...
        'variableScale must be a finite positive vector matching unknownNames.');
end
if ~(isnumeric(definition.bounds) && isreal(definition.bounds) && ...
        isequal(size(definition.bounds), [nUnknown, 2]) && ...
        all(isfinite(definition.bounds(:))) && ...
        all(definition.bounds(:,1) < definition.bounds(:,2)))
    error('trim_general:InvalidDefinition', ...
        'bounds must be a finite nUnknown-by-2 matrix with lower < upper.');
end
if ~(islogical(definition.compatibilityMode) && isscalar(definition.compatibilityMode))
    error('trim_general:InvalidDefinition', ...
        'compatibilityMode must be a logical scalar.');
end
end

function validate_legacy_compatibility(definition, P)
d2r = pi/180;
expectedStates = struct('v', 0, 'p', 0, 'q', 0, 'r', 0, ...
    'phi', 0, 'psi', 0);
expectedControls = struct('diffCollective', 0, 'diffCyclic', 0, ...
    'aileron', 0, 'rudder', 0, 'elevator', 0);
expectedBounds = [-35*d2r, 35*d2r; ...
    P.control.collectiveLim(:).'; P.control.cyclicLim(:).'];
valid = strcmp(definition.name, 'legacy_symmetric') && ...
    strcmp(definition.mode, 'legacy_symmetric') && ...
    isequal(definition.unknownNames, {'theta','collective','cyclicLong'}) && ...
    isequal(definition.residualNames, {'udot','wdot','qdot'}) && ...
    isequal(definition.fixedStates, expectedStates) && ...
    isequal(definition.fixedControls, expectedControls) && ...
    isequal(definition.variableScale(:), P.trim.variableScale(:)) && ...
    isequal(definition.bounds, expectedBounds);
if ~valid
    error('trim_general:InvalidDefinition', ...
        ['compatibilityMode is reserved for the canonical legacy_symmetric ' ...
        'schema; modified definitions must use the generic solver.']);
end
end

function names = normalize_names(names, fieldName)
if isstring(names)
    names = cellstr(names(:));
end
if ~iscell(names) || ~isvector(names) || ...
        ~all(cellfun(@(x) ischar(x) && isrow(x) && ~isempty(x), names))
    error('trim_general:InvalidDefinition', ...
        '%s must be a nonempty cell vector of names.', fieldName);
end
names = names(:).';
end

function validate_fixed_values(values)
names = fieldnames(values);
for i = 1:numel(names)
    value = values.(names{i});
    if ~(isnumeric(value) && isreal(value) && isscalar(value) && isfinite(value))
        error('trim_general:InvalidDefinition', ...
            'Every fixed value must be a finite real scalar.');
    end
end
end

function vector = apply_named_values(vector, names, values)
fields = fieldnames(values);
for i = 1:numel(fields)
    vector(strcmp(names, fields{i})) = values.(fields{i});
end
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

function report = add_definition_report(report, definition)
report.definitionName = definition.name;
report.mode = definition.mode;
report.unknownNames = definition.unknownNames(:);
report.fixedStates = definition.fixedStates;
report.fixedControls = definition.fixedControls;
report.compatibilityMode = definition.compatibilityMode;
end

function tf = is_real_finite(value)
tf = isreal(value) && all(isfinite(value(:)));
end

function tf = is_objective_domain_error(ME)
tf = strcmp(ME.identifier, 'rotor_model_bemt:FlapNotConverged') || ...
    strcmp(ME.identifier, 'rotor_model_bemt:CoupledSolveNotConverged');
end
