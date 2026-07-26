function [xTrim, uTrim, report] = trim_berger13_symmetric( ...
        condition, P13, opts)
%TRIM_BERGER13_SYMMETRIC Formal straight symmetric 13-state trim wrapper.
% The numerical solve reuses the reviewed legacy longitudinal definition,
% while this opt-in entry constructs and checks the full 13-state point.

if nargin < 2 || isempty(P13)
    P13 = params_berger13();
end
if nargin < 3
    opts = struct();
end
validate_condition(condition);
if ~isfield(opts,'mode') || isempty(opts.mode)
    error('trim_berger13_symmetric:ExplicitModeRequired', ...
        ['opts.mode is required. The three longitudinal trim definitions ' ...
         'are not selected implicitly from betaM because internal handoff ' ...
         'continuity has not been established.']);
end
mode = opts.mode;
definition = make_trim_definition(mode, condition, P13.base);
if isfield(opts, 'initialValues')
    initialValues = opts.initialValues(:);
    if numel(initialValues) ~= numel(definition.initialValues) || ...
            any(~isfinite(initialValues)) || ~isreal(initialValues)
        error('trim_berger13_symmetric:InvalidInitialValues', ...
            'opts.initialValues must match the trim unknown vector.');
    end
    definition.initialValues = clamp_vector( ...
        initialValues, definition.bounds);
end

runMultipleSeeds = get_option(opts, 'runMultipleSeeds', false);
if runMultipleSeeds
    seedOffsets = get_option(opts, 'seedOffsets', ...
        [zeros(numel(definition.initialValues),1), ...
         0.25*ones(numel(definition.initialValues),1), ...
        -0.25*ones(numel(definition.initialValues),1)]);
else
    seedOffsets = zeros(numel(definition.initialValues),1);
end
if size(seedOffsets,1) ~= numel(definition.initialValues) || ...
        any(~isfinite(seedOffsets(:))) || ~isreal(seedOffsets)
    error('trim_berger13_symmetric:InvalidSeedOffsets', ...
        'seedOffsets must have one row per trim unknown.');
end

nSeeds = size(seedOffsets,2);
emptyCandidate = struct('seed', [], 'x9', [], 'u7', [], ...
    'baseReport', [], 'z', [], 'score', Inf, 'errorIdentifier', '', ...
    'errorMessage', '');
candidates = repmat(emptyCandidate, nSeeds, 1);
for k = 1:nSeeds
    candidateDefinition = definition;
    candidateDefinition.initialValues = clamp_vector( ...
        definition.initialValues + ...
        seedOffsets(:,k).*definition.variableScale(:), ...
        definition.bounds);
    candidates(k).seed = candidateDefinition.initialValues;
    try
        [x9, u7, baseReport] = trim_general( ...
            condition, candidateDefinition, P13.base);
        z = named_values(baseReport.trimVariables, ...
            candidateDefinition.unknownNames);
        candidates(k).x9 = x9;
        candidates(k).u7 = u7;
        candidates(k).baseReport = baseReport;
        candidates(k).z = z;
        candidates(k).score = candidate_score(baseReport);
    catch ME
        candidates(k).errorIdentifier = ME.identifier;
        candidates(k).errorMessage = ME.message;
    end
end

[bestScore, bestIndex] = min([candidates.score]);
if ~isfinite(bestScore)
    error('trim_berger13_symmetric:AllSeedsFailed', ...
        'All formal trim seeds failed before producing a finite point.');
end
best = candidates(bestIndex);
point = evaluate_berger13_trim_point( ...
    condition, definition, best.z, P13);
diagnostics = trim_diagnostics(condition, definition, best.z, ...
    point, candidates, P13);

xTrim = point.x13;
uTrim = point.u10Torque;
report.status = diagnostics.status;
report.credible = strcmp(diagnostics.status, 'CREDIBLE');
report.reasons = diagnostics.reasons;
report.condition = condition;
report.mode = mode;
report.definition = definition;
report.trimVariables = best.baseReport.trimVariables;
report.trimVariableVector = best.z;
report.x13 = xTrim;
report.u10Torque = uTrim;
report.fullStateDerivative = point.xdot13;
report.dynamicResidualIndices = [1:6, 10:13];
report.dynamicResidual = point.xdot13(report.dynamicResidualIndices);
report.dynamicResidualNorm = norm(report.dynamicResidual);
report.forceBalanceBody = point.forceBalanceBody;
report.momentBalanceBody = point.momentBalanceBody;
report.baseTrimReport = best.baseReport;
report.selectedSeedIndex = bestIndex;
report.seedResults = candidates;
report.initialConditionSensitivity = diagnostics.initialSensitivity;
report.jacobian = diagnostics.jacobian;
report.singularValues = diagnostics.singularValues;
report.rank = diagnostics.rank;
report.rankTolerance = diagnostics.rankTolerance;
report.conditionNumber = diagnostics.conditionNumber;
report.minimumSingularValue = diagnostics.minimumSingularValue;
report.jacobianStepVariation = diagnostics.jacobianStepVariation;
report.minimumUnknownMarginFraction = diagnostics.minimumMargin;
report.activeLimits = diagnostics.activeLimits;
report.finiteReal = point.finiteReal;
report.physicalConverged = point.physicalConverged;
report.physicalBranchSupported = point.physicalBranchSupported;
report.physicalStatus = point.physicalStatus;
report.appliedControls = applied_controls(point, P13);
report.commandAppliedDifference = ...
    max(abs(report.appliedControls-uTrim));
report.continuation.usedInitialValues = isfield(opts, 'initialValues');
report.continuation.seed = definition.initialValues;
report.continuation.selected = best.z;
report.point = point;
report.parameterBoundary = ['nacelle torque dynamics and limits remain ' ...
    'RESEARCH_PLACEHOLDER; credibility is internal numerical evidence'];
end

function diagnostics = trim_diagnostics( ...
        condition, definition, z, point, candidates, P13)
hScaled = [1e-2; 1e-3; 1e-4];
n = numel(z);
steps = repmat(struct('hScaled', NaN, 'raw', [], 'scaled', [], ...
    'methods', {{}}, 'singularValues', [], 'finiteReal', false), 3, 1);
residualScale = residual_scale(definition.residualNames, P13.base);
for i = 1:3
    raw = zeros(numel(point.residual), n);
    methods = cell(n,1);
    for j = 1:n
        h = hScaled(i)*definition.variableScale(j);
        [raw(:,j), methods{j}] = jacobian_column(condition, ...
            definition, z, j, h, point.residual, P13);
    end
    scaled = diag(1./residualScale)*raw* ...
        diag(definition.variableScale(:));
    finiteReal = isreal(raw) && all(isfinite(raw(:))) && ...
        isreal(scaled) && all(isfinite(scaled(:)));
    steps(i).hScaled = hScaled(i);
    steps(i).raw = raw;
    steps(i).scaled = scaled;
    steps(i).methods = methods;
    steps(i).finiteReal = finiteReal;
    if finiteReal
        steps(i).singularValues = svd(scaled);
    else
        steps(i).singularValues = NaN(n,1);
    end
end

main = steps(2);
s = main.singularValues;
sigmaMax = max(s);
sigmaMin = min(s);
rankTolerance = 1e-8*max(sigmaMax, eps);
effectiveRank = sum(s > rankTolerance);
conditionNumber = sigmaMax/max(sigmaMin, realmin);
variation = zeros(2,1);
comparison = [1,3];
for k = 1:2
    variation(k) = norm(steps(comparison(k)).scaled-main.scaled, 'fro') / ...
        max(norm(main.scaled, 'fro'), eps);
end

[minimumMargin, activeLimits] = unknown_margins(z, definition.bounds);
initialSensitivity = seed_sensitivity(candidates, definition);
[status, reasons] = classify(point, candidates, effectiveRank, n, ...
    conditionNumber, max(variation), minimumMargin, ...
    initialSensitivity, P13);

diagnostics.status = status;
diagnostics.reasons = reasons;
diagnostics.jacobian = main.raw;
diagnostics.scaledJacobian = main.scaled;
diagnostics.steps = steps;
diagnostics.singularValues = s;
diagnostics.rank = effectiveRank;
diagnostics.rankTolerance = rankTolerance;
diagnostics.conditionNumber = conditionNumber;
diagnostics.minimumSingularValue = sigmaMin;
diagnostics.jacobianStepVariation = variation;
diagnostics.minimumMargin = minimumMargin;
diagnostics.activeLimits = activeLimits;
diagnostics.initialSensitivity = initialSensitivity;
end

function [status, reasons] = classify(point, candidates, rankValue, n, ...
        conditionNumber, stepVariation, minimumMargin, sensitivity, P13)
reasons = {};
[~, selectedIndex] = min([candidates.score]);
baseReport = candidates(selectedIndex).baseReport;
if ~point.finiteReal || any(~isfinite(point.x13)) || ...
        any(~isfinite(point.u10Torque))
    status = 'NONPHYSICAL';
    reasons{end+1,1} = 'point contains non-finite, complex, or invalid values';
elseif ~point.physicalConverged
    status = 'UNSUPPORTED_PHYSICAL_BRANCH';
    reasons{end+1,1} = point.physicalStatus;
elseif ~baseReport.solverConverged || ...
        norm(point.residual) >= P13.base.trim.residualTolerance || ...
        max(abs(point.xdot13([1:6,10:13]))) >= ...
        10*P13.base.trim.residualTolerance
    status = 'FAILED';
    reasons{end+1,1} = 'solver or full dynamic-equilibrium residual failed';
elseif minimumMargin <= 0.02 || baseReport.atLimit || ...
        ~baseReport.withinLimits
    status = 'CONVERGED_BUT_BOUNDARY_LIMITED';
    reasons{end+1,1} = 'one or more trim variables are at a bound';
elseif rankValue < n
    status = 'RANK_DEFICIENT';
    reasons{end+1,1} = 'scaled trim Jacobian is rank deficient';
elseif conditionNumber > 1e8 || stepVariation > 1e-2 || ...
        sensitivity.maximumNormalizedDifference > 0.25
    status = 'ILL_CONDITIONED';
    reasons{end+1,1} = ...
        'conditioning, step variation, or seed sensitivity is excessive';
else
    status = 'CREDIBLE';
    reasons{end+1,1} = ['converged interior point with finite full ' ...
        'equilibrium residual and stable full-rank Jacobian'];
end
end

function [column, method] = jacobian_column( ...
        condition, definition, z, j, h, f0, P13)
lower = definition.bounds(j,1);
upper = definition.bounds(j,2);
if z(j)-h < lower
    zp = z;
    zp(j) = zp(j)+h;
    fp = evaluate_berger13_trim_point(condition,definition,zp,P13);
    column = (fp.residual-f0)/h;
    method = 'forward';
elseif z(j)+h > upper
    zm = z;
    zm(j) = zm(j)-h;
    fm = evaluate_berger13_trim_point(condition,definition,zm,P13);
    column = (f0-fm.residual)/h;
    method = 'backward';
else
    zp = z;
    zm = z;
    zp(j) = zp(j)+h;
    zm(j) = zm(j)-h;
    fp = evaluate_berger13_trim_point(condition,definition,zp,P13);
    fm = evaluate_berger13_trim_point(condition,definition,zm,P13);
    column = (fp.residual-fm.residual)/(2*h);
    method = 'central';
end
end

function applied = applied_controls(point, P13)
baseApplied = point.eomOut.components13.baseComponents.appliedControls(:);
applied = [baseApplied(1:4); ...
    point.eomOut.components13.lateralCyclicApplied; ...
    baseApplied(5:7); ...
    min(max(point.u10Torque(9:10),-P13.nacelle.torqueLim), ...
        P13.nacelle.torqueLim)];
end

function sensitivity = seed_sensitivity(candidates, definition)
indices = find(isfinite([candidates.score]));
if numel(indices) < 2
    sensitivity.maximumNormalizedDifference = 0;
    sensitivity.numberOfFiniteSeeds = numel(indices);
    sensitivity.classification = 'NOT_RUN';
    return;
end
Z = zeros(numel(definition.initialValues), numel(indices));
for k = 1:numel(indices)
    Z(:,k) = candidates(indices(k)).z;
end
reference = Z(:,1);
normalized = abs(Z-reference)./definition.variableScale(:);
sensitivity.maximumNormalizedDifference = max(normalized(:));
sensitivity.numberOfFiniteSeeds = numel(indices);
if sensitivity.maximumNormalizedDifference <= 1e-3
    sensitivity.classification = 'STABLE';
else
    sensitivity.classification = 'SENSITIVE';
end
end

function [minimumMargin, active] = unknown_margins(z, bounds)
span = bounds(:,2)-bounds(:,1);
margin = min(z-bounds(:,1), bounds(:,2)-z)./span;
minimumMargin = min(margin);
active = margin <= 0.02;
end

function values = named_values(S, names)
values = zeros(numel(names),1);
for k = 1:numel(names)
    values(k) = S.(names{k});
end
end

function score = candidate_score(report)
score = report.residualNorm + 1e3*double(~report.solverConverged) + ...
    1e3*double(~report.physicalConverged) + ...
    1e2*double(report.atLimit || ~report.withinLimits);
if ~isfinite(score)
    score = Inf;
end
end

function scale = residual_scale(names, P)
scale = ones(numel(names),1);
for k = 1:numel(names)
    if any(strcmp(names{k},{'udot','vdot','wdot'}))
        scale(k) = P.env.g;
    end
end
end

function value = get_option(opts, name, defaultValue)
if isfield(opts, name)
    value = opts.(name);
else
    value = defaultValue;
end
end

function validate_condition(condition)
required = {'V','betaM','gamma'};
for k = 1:numel(required)
    if ~isfield(condition,required{k}) || ...
            ~isscalar(condition.(required{k})) || ...
            ~isreal(condition.(required{k})) || ...
            ~isfinite(condition.(required{k}))
        error('trim_berger13_symmetric:InvalidCondition', ...
            'condition.%s must be a finite real scalar.', required{k});
    end
end
if condition.V < 0 || condition.betaM < 0 || condition.betaM > pi/2
    error('trim_berger13_symmetric:InvalidCondition', ...
        'V must be nonnegative and betaM must be in [0,pi/2].');
end
end

function z = clamp_vector(z, bounds)
z = min(max(z, bounds(:,1)), bounds(:,2));
end
