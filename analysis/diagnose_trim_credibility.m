function credibility = diagnose_trim_credibility( ...
        condition, definition, xTrim, uTrim, trimReport, P, opts)
%DIAGNOSE_TRIM_CREDIBILITY Numerical diagnostics for an existing trim.
% This function is read-only with respect to the trim solution. It does not
% alter solver settings, acceptance criteria, model parameters, controls,
% limits, or allocation. Seed and local-condition sensitivity diagnostics are
% optional, default off, and enabled explicitly with runSeedSensitivity and
% runConditionSensitivity.

if nargin < 7
    opts = struct();
end
if ~isstruct(opts) || ~isscalar(opts)
    error('diagnose_trim_credibility:InvalidOptions', ...
        'opts must be a scalar struct.');
end

hScaled = [1e-2; 1e-3; 1e-4];
mainStepIndex = 2;
maxStepReductions = get_option(opts, 'maxStepReductions', 12);
pointTolerance = get_option(opts, 'pointTolerance', 1e-10);
runSeedSensitivity = get_option(opts, 'runSeedSensitivity', false);
runConditionSensitivity = get_option(opts, ...
    'runConditionSensitivity', false);
if ~(isnumeric(maxStepReductions) && isreal(maxStepReductions) && ...
        isscalar(maxStepReductions) && isfinite(maxStepReductions) && ...
        maxStepReductions >= 0 && maxStepReductions == fix(maxStepReductions))
    error('diagnose_trim_credibility:InvalidOptions', ...
        'maxStepReductions must be a nonnegative integer.');
end
if ~(isnumeric(pointTolerance) && isreal(pointTolerance) && ...
        isscalar(pointTolerance) && isfinite(pointTolerance) && ...
        pointTolerance >= 0)
    error('diagnose_trim_credibility:InvalidOptions', ...
        'pointTolerance must be a finite nonnegative scalar.');
end
validate_logical_option(runSeedSensitivity, 'runSeedSensitivity');
validate_logical_option(runConditionSensitivity, ...
    'runConditionSensitivity');
if (runSeedSensitivity || runConditionSensitivity) && ...
        ~is_stage_3_baseline(condition, definition)
    error('diagnose_trim_credibility:InvalidSensitivityBaseline', ...
        ['Stage 3 sensitivities are restricted to conversion_longitudinal ' ...
        'at V=35 m/s, betaM=pi/4, gamma=0.']);
end

unknownNames = definition.unknownNames(:);
residualNames = definition.residualNames(:);
variableScale = definition.variableScale(:);
nUnknown = numel(unknownNames);
zTrim = zeros(nUnknown,1);
for i = 1:nUnknown
    if ~isfield(trimReport.trimVariables, unknownNames{i})
        error('diagnose_trim_credibility:InvalidTrimReport', ...
            'trimReport.trimVariables is missing %s.', unknownNames{i});
    end
    zTrim(i) = trimReport.trimVariables.(unknownNames{i});
end

[xBase, uBase, residualBase, ~, xdotBase, eomOutBase, allocationBase] = ...
    evaluate_trim_definition_point(condition, definition, zTrim, P);
pointStateDifference = max(abs(xBase(:)-xTrim(:)));
pointControlDifference = max(abs(uBase(:)-uTrim(:)));
pointResidualDifference = max(abs(residualBase(:)-trimReport.residual(:)));
if any([pointStateDifference, pointControlDifference, ...
        pointResidualDifference] > pointTolerance)
    error('diagnose_trim_credibility:TrimPointMismatch', ...
        ['The supplied trim does not match the shared trim-definition ' ...
        'point evaluator.']);
end

residualScale = trimReport.residualScale(:);
if numel(residualScale) ~= numel(residualNames) || ...
        ~is_real_finite(residualScale) || any(residualScale <= 0)
    error('diagnose_trim_credibility:InvalidTrimReport', ...
        'trimReport.residualScale must be finite, positive, and sized correctly.');
end

nStep = numel(hScaled);
emptyStep = struct('hScaled', NaN, 'actualPhysicalSteps', [], ...
    'actualScaledSteps', [], 'columnDifferenceMethods', {{}}, ...
    'columnFiniteReal', [], 'rawJacobian', [], 'scaledJacobian', [], ...
    'finiteReal', false, 'singularValues', []);
stepResults = repmat(emptyStep, nStep, 1);
allMethods = cell(nStep, nUnknown);

for iStep = 1:nStep
    rawJacobian = NaN(numel(residualNames), nUnknown);
    actualPhysicalSteps = NaN(nUnknown,1);
    actualScaledSteps = NaN(nUnknown,1);
    methods = cell(nUnknown,1);
    columnFiniteReal = false(nUnknown,1);
    for j = 1:nUnknown
        requestedStep = hScaled(iStep)*variableScale(j);
        [rawJacobian(:,j), actualPhysicalSteps(j), methods{j}, ...
            columnFiniteReal(j)] = difference_column(zTrim, j, ...
            requestedStep, residualBase, condition, definition, P, ...
            maxStepReductions);
        actualScaledSteps(j) = actualPhysicalSteps(j)/variableScale(j);
    end
    scaledJacobian = diag(1./residualScale)*rawJacobian* ...
        diag(variableScale);
    finiteReal = is_real_finite(rawJacobian) && ...
        is_real_finite(scaledJacobian);
    if finiteReal
        singularValues = svd(scaledJacobian);
    else
        singularValues = NaN(nUnknown,1);
    end
    stepResults(iStep).hScaled = hScaled(iStep);
    stepResults(iStep).actualPhysicalSteps = actualPhysicalSteps;
    stepResults(iStep).actualScaledSteps = actualScaledSteps;
    stepResults(iStep).columnDifferenceMethods = methods;
    stepResults(iStep).columnFiniteReal = columnFiniteReal;
    stepResults(iStep).rawJacobian = rawJacobian;
    stepResults(iStep).scaledJacobian = scaledJacobian;
    stepResults(iStep).finiteReal = finiteReal;
    stepResults(iStep).singularValues = singularValues;
    allMethods(iStep,:) = methods(:).';
end

mainStep = stepResults(mainStepIndex);
singularValues = mainStep.singularValues;
if mainStep.finiteReal
    sigmaMax = max(singularValues);
    sigmaMin = min(singularValues);
    if sigmaMin == 0
        conditionNumber = Inf;
    else
        conditionNumber = sigmaMax/sigmaMin;
    end
    defaultRank = rank(mainStep.scaledJacobian);
    rankTolerance = 1e-8*sigmaMax;
    effectiveRank = sum(singularValues > rankTolerance);
else
    sigmaMax = NaN;
    sigmaMin = NaN;
    conditionNumber = Inf;
    defaultRank = 0;
    rankTolerance = NaN;
    effectiveRank = 0;
end

comparisonIndices = [1,3];
emptyVariation = struct('hScaled', NaN, ...
    'frobeniusRelativeDifference', NaN, ...
    'singularValueRelativeChanges', []);
jacobianStepVariation = repmat(emptyVariation, 2, 1);
for i = 1:2
    index = comparisonIndices(i);
    jacobianStepVariation(i).hScaled = hScaled(index);
    if mainStep.finiteReal && stepResults(index).finiteReal
        jacobianStepVariation(i).frobeniusRelativeDifference = ...
            norm(stepResults(index).scaledJacobian- ...
            mainStep.scaledJacobian, 'fro') / ...
            max(norm(mainStep.scaledJacobian, 'fro'), eps);
        jacobianStepVariation(i).singularValueRelativeChanges = ...
            abs(stepResults(index).singularValues-singularValues) ./ ...
            max(abs(singularValues), eps);
    else
        jacobianStepVariation(i).singularValueRelativeChanges = ...
            NaN(nUnknown,1);
    end
end
variationValues = [jacobianStepVariation.frobeniusRelativeDifference];
if all(isfinite(variationValues))
    maximumJacobianStepVariation = max(variationValues);
else
    maximumJacobianStepVariation = Inf;
end

derivativeNames = {'udot'; 'vdot'; 'wdot'; 'pdot'; 'qdot'; ...
    'rdot'; 'phidot'; 'thetadot'; 'psidot'};
scaledFullDerivative = xdotBase(:);
scaledFullDerivative(1:3) = scaledFullDerivative(1:3)/P.env.g;
selectedResidualMask = ismember(derivativeNames, residualNames);
unselectedDerivativeLabels = derivativeNames(~selectedResidualMask);
unselectedDerivativeValues = xdotBase(~selectedResidualMask);
maxScaledFullDerivative = max(abs(scaledFullDerivative));

marginItems = make_margin_items(zTrim, allocationBase, definition, P);
minimumMarginFraction = min([marginItems.marginFraction]);
appliedControls = eomOutBase.components.appliedControls(:);
commandAppliedDifference = max(abs(uBase(:)-appliedControls));

[status, reasons] = classify_credibility(trimReport, xTrim, uTrim, ...
    residualBase, stepResults, mainStepIndex, effectiveRank, nUnknown, ...
    conditionNumber, maximumJacobianStepVariation, marginItems, ...
    commandAppliedDifference, maxScaledFullDerivative, allMethods, P);

credibility.status = status;
credibility.reasons = reasons;
credibility.rawJacobian = mainStep.rawJacobian;
credibility.scaledJacobian = mainStep.scaledJacobian;
credibility.rawJacobians = {stepResults.rawJacobian}.';
credibility.scaledJacobians = {stepResults.scaledJacobian}.';
credibility.stepResults = stepResults;
credibility.hScaled = hScaled;
credibility.mainStepIndex = mainStepIndex;
credibility.mainHScaled = hScaled(mainStepIndex);
credibility.columnDifferenceMethods = allMethods;
credibility.rowLabels = residualNames;
credibility.columnLabels = unknownNames;
credibility.singularValues = singularValues;
credibility.sigmaMax = sigmaMax;
credibility.sigmaMin = sigmaMin;
credibility.defaultRank = defaultRank;
credibility.effectiveRank = effectiveRank;
credibility.rankTolerance = rankTolerance;
credibility.conditionNumber = conditionNumber;
credibility.conditionLevel = condition_level(conditionNumber);
credibility.jacobianStepVariation = jacobianStepVariation;
credibility.maximumJacobianStepVariation = maximumJacobianStepVariation;
credibility.jacobianStepVariationLevel = ...
    variation_level(maximumJacobianStepVariation);
credibility.fullDerivative = xdotBase;
credibility.scaledFullDerivative = scaledFullDerivative;
credibility.maxScaledFullDerivative = maxScaledFullDerivative;
credibility.derivativeLabels = derivativeNames;
credibility.selectedResidualMask = selectedResidualMask;
credibility.selectedDerivativeLabels = derivativeNames(selectedResidualMask);
credibility.unselectedDerivativeLabels = unselectedDerivativeLabels;
credibility.unselectedDerivativeValues = unselectedDerivativeValues;
credibility.marginItems = marginItems;
credibility.minimumMarginFraction = minimumMarginFraction;
credibility.commandedControls = uBase;
credibility.appliedControls = appliedControls;
credibility.commandAppliedDifference = commandAppliedDifference;
credibility.trimVariables = zTrim;
credibility.trimResidual = residualBase;
credibility.trimConverged = trimReport.converged;
credibility.physicalConverged = trimReport.physicalConverged;
credibility.physicalStatus = trimReport.physicalStatus;
credibility.pointReproduction = struct( ...
    'maxStateDifference', pointStateDifference, ...
    'maxControlDifference', pointControlDifference, ...
    'maxResidualDifference', pointResidualDifference);
if runSeedSensitivity
    credibility.seedSensitivity = run_seed_sensitivity( ...
        condition, definition, zTrim, variableScale, xTrim, uTrim, ...
        trimReport, P);
else
    credibility.seedSensitivity = stage_3_not_requested();
end
if runConditionSensitivity
    credibility.conditionSensitivity = run_condition_sensitivity( ...
        definition, zTrim, xTrim, uTrim, P, opts);
else
    credibility.conditionSensitivity = stage_3_not_requested();
end
[credibility.status, credibility.reasons] = merge_sensitivity_status( ...
    credibility.status, credibility.reasons, ...
    credibility.seedSensitivity, credibility.conditionSensitivity);
credibility.classification = 'NUMERICAL_DIAGNOSTIC';
end

function [column, actualStep, method, finiteReal] = difference_column( ...
        z, index, requestedStep, residual0, condition, definition, P, ...
        maxStepReductions)
column = NaN(numel(residual0),1);
actualStep = NaN;
method = 'unavailable';
finiteReal = false;
step = requestedStep;

for attempt = 0:maxStepReductions
    zPlus = z;
    zMinus = z;
    zPlus2 = z;
    zMinus2 = z;
    zPlus(index) = zPlus(index)+step;
    zMinus(index) = zMinus(index)-step;
    zPlus2(index) = zPlus2(index)+2*step;
    zMinus2(index) = zMinus2(index)-2*step;
    [plusLegal, residualPlus] = legal_residual( ...
        zPlus, condition, definition, P);
    [minusLegal, residualMinus] = legal_residual( ...
        zMinus, condition, definition, P);
    if plusLegal && minusLegal
        column = (residualPlus-residualMinus)/(2*step);
        actualStep = step;
        method = 'central';
        finiteReal = is_real_finite(column);
        return;
    end
    [plus2Legal, residualPlus2] = legal_residual( ...
        zPlus2, condition, definition, P);
    if plusLegal && plus2Legal
        column = (-3*residual0+4*residualPlus-residualPlus2)/(2*step);
        actualStep = step;
        method = 'forward-second-order';
        finiteReal = is_real_finite(column);
        return;
    end
    [minus2Legal, residualMinus2] = legal_residual( ...
        zMinus2, condition, definition, P);
    if minusLegal && minus2Legal
        column = (3*residual0-4*residualMinus+residualMinus2)/(2*step);
        actualStep = step;
        method = 'backward-second-order';
        finiteReal = is_real_finite(column);
        return;
    end
    step = step/2;
end
end

function [legal, residual] = legal_residual(z, condition, definition, P)
legal = false;
residual = NaN(numel(definition.residualNames),1);
if any(z < definition.bounds(:,1)) || any(z > definition.bounds(:,2))
    return;
end
try
    [~, ~, residual, ~, xdot, eomOut, allocation] = ...
        evaluate_trim_definition_point(condition, definition, z, P);
catch ME
    if is_diagnostic_domain_error(ME)
        return;
    end
    rethrow(ME);
end
if ~isempty(allocation)
    generatedValues = [allocation.cyclicLong; allocation.elevator];
    generatedBounds = [P.control.cyclicLim(:).'; ...
        P.control.elevatorLim(:).'];
    if any(generatedValues < generatedBounds(:,1)) || ...
            any(generatedValues > generatedBounds(:,2))
        return;
    end
end
legal = is_real_finite(residual) && is_real_finite(xdot) && ...
    eomOut.physicalConverged;
end

function items = make_margin_items(z, allocation, definition, P)
itemNames = definition.unknownNames(:);
itemValues = z(:);
itemBounds = definition.bounds;
if ~isempty(allocation)
    itemNames = [itemNames; {'cyclicLong'; 'elevator'}];
    itemValues = [itemValues; allocation.cyclicLong; allocation.elevator];
    itemBounds = [itemBounds; P.control.cyclicLim(:).'; ...
        P.control.elevatorLim(:).'];
end
items = repmat(struct('name', '', 'value', NaN, 'lower', NaN, ...
    'upper', NaN, 'marginAbsolute', NaN, 'marginFraction', NaN, ...
    'level', '', 'atLimit', false, 'violated', false), ...
    numel(itemNames), 1);
tol = 1e-8;
for i = 1:numel(itemNames)
    marginAbsolute = min(itemValues(i)-itemBounds(i,1), ...
        itemBounds(i,2)-itemValues(i));
    marginFraction = 2*marginAbsolute / ...
        (itemBounds(i,2)-itemBounds(i,1));
    items(i).name = itemNames{i};
    items(i).value = itemValues(i);
    items(i).lower = itemBounds(i,1);
    items(i).upper = itemBounds(i,2);
    items(i).marginAbsolute = marginAbsolute;
    items(i).marginFraction = marginFraction;
    items(i).level = margin_level(marginFraction);
    items(i).atLimit = ...
        abs(itemValues(i)-itemBounds(i,1)) <= tol || ...
        abs(itemValues(i)-itemBounds(i,2)) <= tol;
    items(i).violated = itemValues(i) < itemBounds(i,1)-tol || ...
        itemValues(i) > itemBounds(i,2)+tol;
end
end

function [status, reasons] = classify_credibility(trimReport, xTrim, ...
        uTrim, residual, stepResults, mainStepIndex, effectiveRank, ...
        nUnknown, conditionNumber, maximumVariation, marginItems, ...
        commandDifference, maxFullDerivative, methods, P)
failReasons = {};
cautionReasons = {};
if ~trimReport.converged
    failReasons{end+1} = 'TRIM_NOT_CONVERGED';
end
if ~trimReport.physicalConverged
    failReasons{end+1} = trimReport.physicalStatus;
end
if ~is_real_finite(xTrim) || ~is_real_finite(uTrim) || ...
        ~is_real_finite(residual) || ...
        ~is_real_finite(stepResults(mainStepIndex).scaledJacobian)
    failReasons{end+1} = 'NONFINITE_OR_COMPLEX';
end
if effectiveRank < nUnknown
    failReasons{end+1} = 'EFFECTIVE_RANK_DEFICIENT';
end
if any([marginItems.violated])
    failReasons{end+1} = 'LIMIT_VIOLATION';
end
if commandDifference > 1e-10
    failReasons{end+1} = 'COMMAND_APPLIED_MISMATCH';
end
if maxFullDerivative >= P.trim.residualTolerance
    failReasons{end+1} = 'FULL_DERIVATIVE_EXCEEDS_TOLERANCE';
end
if conditionNumber > 1e3
    cautionReasons{end+1} = 'CONDITION_NUMBER_GT_1E3';
end
if maximumVariation > 0.05
    cautionReasons{end+1} = 'JACOBIAN_STEP_VARIATION_GT_5_PERCENT';
end
if any([marginItems.marginFraction] < 0.10)
    cautionReasons{end+1} = 'LOW_MARGIN';
end
if any(strcmp(methods(:), 'unavailable'))
    cautionReasons{end+1} = 'UNAVAILABLE_JACOBIAN_COLUMN';
end
oneSided = strcmp(methods(:), 'forward-second-order') | ...
    strcmp(methods(:), 'backward-second-order');
if any(oneSided)
    cautionReasons{end+1} = 'ONE_SIDED_DIFFERENCE';
end
if ~isempty(failReasons)
    status = 'FAIL';
    reasons = failReasons(:);
elseif ~isempty(cautionReasons)
    status = 'CAUTION';
    reasons = cautionReasons(:);
else
    status = 'PASS';
    reasons = {'NONE'};
end
end

function value = get_option(opts, name, defaultValue)
if isfield(opts, name)
    value = opts.(name);
else
    value = defaultValue;
end
end

function result = stage_3_not_requested()
result.status = 'NOT_RUN';
result.reason = 'STAGE_3_NOT_REQUESTED';
result.classification = 'NOT_RUN';
end

function sensitivity = run_seed_sensitivity(condition, definition, ...
        zTrim, variableScale, xBaseline, uBaseline, trimReportBaseline, P)
patterns = [1, -1, 1; -1, 1, -1].';
names = {'seedPlus'; 'seedMinus'};
emptyResult = struct('name', '', 'requestedInitialValues', [], ...
    'initialValues', [], 'seedScaleFactor', NaN, 'converged', false, ...
    'residualNorm', NaN, 'maxStateDifferenceFromBaseline', NaN, ...
    'maxControlDifferenceFromBaseline', NaN, ...
    'residualNormDifference', NaN, 'atLimit', true, ...
    'withinLimits', false, 'finiteReal', false, 'xTrim', [], ...
    'uTrim', [], 'runtime', NaN, 'errorIdentifier', '', ...
    'errorMessage', '');
results = repmat(emptyResult, 2, 1);
for i = 1:2
    delta = 0.25*variableScale.*patterns(:,i);
    requestedSeed = zTrim+delta;
    [seed, scaleFactor] = shrink_seed_to_bounds( ...
        zTrim, delta, definition.bounds);
    seededDefinition = definition;
    seededDefinition.initialValues = seed;
    timer = tic;
    results(i).name = names{i};
    results(i).requestedInitialValues = requestedSeed;
    results(i).initialValues = seed;
    results(i).seedScaleFactor = scaleFactor;
    try
        [xSeed, uSeed, reportSeed] = trim_general( ...
            condition, seededDefinition, P);
        results(i).runtime = toc(timer);
        finiteReal = is_real_finite(xSeed) && is_real_finite(uSeed) && ...
            is_real_finite(reportSeed.residual) && ...
            is_real_finite(reportSeed.fullStateDerivative);
        results(i).converged = reportSeed.converged;
        results(i).residualNorm = reportSeed.residualNorm;
        results(i).maxStateDifferenceFromBaseline = ...
            max(abs(xSeed(:)-xBaseline(:)));
        results(i).maxControlDifferenceFromBaseline = ...
            max(abs(uSeed(:)-uBaseline(:)));
        results(i).residualNormDifference = ...
            abs(reportSeed.residualNorm-trimReportBaseline.residualNorm);
        results(i).atLimit = reportSeed.atLimit;
        results(i).withinLimits = reportSeed.withinLimits;
        results(i).finiteReal = finiteReal;
        results(i).xTrim = xSeed;
        results(i).uTrim = uSeed;
    catch ME
        results(i).runtime = toc(timer);
        results(i).errorIdentifier = ME.identifier;
        results(i).errorMessage = ME.message;
    end
end
stateDifferences = [results.maxStateDifferenceFromBaseline];
controlDifferences = [results.maxControlDifferenceFromBaseline];
finiteResults = [results.finiteReal];
violated = ~[results.withinLimits];
notConverged = ~[results.converged];
atLimit = [results.atLimit];
if all(isfinite([stateDifferences, controlDifferences]))
    maximumDifference = max([stateDifferences, controlDifferences]);
else
    maximumDifference = Inf;
end
reasons = {};
if any(~finiteResults)
    classification = 'FAIL';
    reasons{end+1} = 'NONFINITE_SEED_RESULT';
elseif any(violated)
    classification = 'FAIL';
    reasons{end+1} = 'SEED_LIMIT_VIOLATION';
elseif any(notConverged)
    classification = 'FAIL';
    reasons{end+1} = 'SEED_NOT_CONVERGED';
elseif any(atLimit)
    classification = 'CAUTION';
    reasons{end+1} = 'SEED_AT_LIMIT';
elseif maximumDifference > 1e-6
    classification = 'CAUTION';
    reasons{end+1} = 'POSSIBLE_BRANCH_SENSITIVITY';
else
    classification = 'CONSISTENT';
    reasons = {'NONE'};
end
sensitivity.status = 'COMPLETE';
sensitivity.classification = classification;
sensitivity.reasons = reasons(:);
sensitivity.results = results;
sensitivity.maximumStateDifference = max(stateDifferences);
sensitivity.maximumControlDifference = max(controlDifferences);
sensitivity.maximumStateControlDifference = maximumDifference;
sensitivity.consistencyThreshold = 1e-6;
sensitivity.runCount = 2;
end

function sensitivity = run_condition_sensitivity( ...
        baselineDefinition, zTrim, xBaseline, uBaseline, P, parentOpts)
d2r = pi/180;
conditions = [ ...
    struct('name','V34p5_beta45','V',34.5,'betaM',45*d2r,'gamma',0); ...
    struct('name','V35p5_beta45','V',35.5,'betaM',45*d2r,'gamma',0); ...
    struct('name','V35_beta44p5','V',35,'betaM',44.5*d2r,'gamma',0); ...
    struct('name','V35_beta45p5','V',35,'betaM',45.5*d2r,'gamma',0)];
emptyResult = struct('name', '', 'condition', struct(), ...
    'initialValues', [], 'converged', false, 'residualNorm', NaN, ...
    'xTrim', [], 'uTrim', [], 'maxStateDifferenceFromBaseline', NaN, ...
    'maxControlDifferenceFromBaseline', NaN, ...
    'credibilityStatus', 'FAIL', 'credibilityReasons', {{}}, ...
    'conditionNumber', NaN, 'conditionLevel', '', ...
    'minimumMarginFraction', NaN, 'marginItems', struct([]), ...
    'atLimit', true, 'withinLimits', false, ...
    'commandAppliedDifference', NaN, 'finiteReal', false, ...
    'runtime', NaN, 'errorIdentifier', '', 'errorMessage', '');
results = repmat(emptyResult, 4, 1);
childOpts = parentOpts;
childOpts.runSeedSensitivity = false;
childOpts.runConditionSensitivity = false;
for i = 1:4
    condition = rmfield(conditions(i), 'name');
    definition = make_trim_definition( ...
        baselineDefinition.mode, condition, P);
    definition.initialValues = zTrim;
    timer = tic;
    results(i).name = conditions(i).name;
    results(i).condition = condition;
    results(i).initialValues = zTrim;
    try
        [xLocal, uLocal, reportLocal] = trim_general( ...
            condition, definition, P);
        localCredibility = diagnose_trim_credibility(condition, ...
            definition, xLocal, uLocal, reportLocal, P, childOpts);
        results(i).runtime = toc(timer);
        results(i).converged = reportLocal.converged;
        results(i).residualNorm = reportLocal.residualNorm;
        results(i).xTrim = xLocal;
        results(i).uTrim = uLocal;
        results(i).maxStateDifferenceFromBaseline = ...
            max(abs(xLocal(:)-xBaseline(:)));
        results(i).maxControlDifferenceFromBaseline = ...
            max(abs(uLocal(:)-uBaseline(:)));
        results(i).credibilityStatus = localCredibility.status;
        results(i).credibilityReasons = localCredibility.reasons;
        results(i).conditionNumber = localCredibility.conditionNumber;
        results(i).conditionLevel = localCredibility.conditionLevel;
        results(i).minimumMarginFraction = ...
            localCredibility.minimumMarginFraction;
        results(i).marginItems = localCredibility.marginItems;
        results(i).atLimit = reportLocal.atLimit;
        results(i).withinLimits = reportLocal.withinLimits;
        results(i).commandAppliedDifference = ...
            localCredibility.commandAppliedDifference;
        results(i).finiteReal = is_real_finite(xLocal) && ...
            is_real_finite(uLocal) && ...
            is_real_finite(reportLocal.residual) && ...
            is_real_finite(localCredibility.conditionNumber) && ...
            is_real_finite(localCredibility.minimumMarginFraction) && ...
            is_real_finite(localCredibility.commandAppliedDifference);
    catch ME
        results(i).runtime = toc(timer);
        results(i).errorIdentifier = ME.identifier;
        results(i).errorMessage = ME.message;
    end
end
reasons = {};
if any(~[results.finiteReal])
    classification = 'FAIL';
    reasons{end+1} = 'NONFINITE_CONDITION_RESULT';
elseif any(~[results.withinLimits]) || ...
        any(strcmp({results.credibilityStatus}, 'FAIL'))
    classification = 'FAIL';
    reasons{end+1} = 'CONDITION_LIMIT_OR_CREDIBILITY_FAILURE';
elseif any(~[results.converged]) || any([results.atLimit])
    classification = 'CAUTION';
    reasons{end+1} = 'CONDITION_NOT_CONVERGED_OR_AT_LIMIT';
elseif any(strcmp({results.credibilityStatus}, 'CAUTION'))
    classification = 'CAUTION';
    reasons{end+1} = 'LOCAL_CREDIBILITY_CAUTION';
else
    classification = 'PASS';
    reasons = {'NONE'};
end
sensitivity.status = 'COMPLETE';
sensitivity.classification = classification;
sensitivity.reasons = reasons(:);
sensitivity.results = results;
sensitivity.runCount = 4;
sensitivity.maximumStateDifference = ...
    max([results.maxStateDifferenceFromBaseline]);
sensitivity.maximumControlDifference = ...
    max([results.maxControlDifferenceFromBaseline]);
end

function [seed, scaleFactor] = shrink_seed_to_bounds(z, delta, bounds)
scaleFactor = 1;
for i = 1:numel(z)
    if delta(i) > 0
        available = (bounds(i,2)-z(i))/delta(i);
    elseif delta(i) < 0
        available = (bounds(i,1)-z(i))/delta(i);
    else
        available = Inf;
    end
    scaleFactor = min(scaleFactor, available);
end
if scaleFactor < 1
    scaleFactor = max(0, 0.99*scaleFactor);
end
seed = z+scaleFactor*delta;
end

function [status, reasons] = merge_sensitivity_status(status, reasons, ...
        seedSensitivity, conditionSensitivity)
if strcmp(seedSensitivity.status, 'COMPLETE')
    if strcmp(seedSensitivity.classification, 'FAIL')
        status = 'FAIL';
        reasons{end+1,1} = 'SEED_SENSITIVITY_FAIL';
    elseif strcmp(seedSensitivity.classification, 'CAUTION') && ...
            ~strcmp(status, 'FAIL')
        status = 'CAUTION';
        reasons{end+1,1} = 'SEED_SENSITIVITY_CAUTION';
    end
end
if strcmp(conditionSensitivity.status, 'COMPLETE')
    if strcmp(conditionSensitivity.classification, 'FAIL')
        status = 'FAIL';
        reasons{end+1,1} = 'CONDITION_SENSITIVITY_FAIL';
    elseif strcmp(conditionSensitivity.classification, 'CAUTION') && ...
            ~strcmp(status, 'FAIL')
        status = 'CAUTION';
        reasons{end+1,1} = 'CONDITION_SENSITIVITY_CAUTION';
    end
end
reasons = unique(reasons, 'stable');
end

function validate_logical_option(value, name)
if ~(islogical(value) && isscalar(value))
    error('diagnose_trim_credibility:InvalidOptions', ...
        '%s must be a logical scalar.', name);
end
end

function tf = is_stage_3_baseline(condition, definition)
tf = strcmp(definition.mode, 'conversion_longitudinal') && ...
    condition.V == 35 && condition.betaM == pi/4 && condition.gamma == 0;
end

function level = condition_level(value)
if value <= 1e3
    level = 'LOW';
elseif value <= 1e6
    level = 'CAUTION';
else
    level = 'SEVERE';
end
end

function level = variation_level(value)
if value <= 0.05
    level = 'STABLE';
elseif value <= 0.20
    level = 'CAUTION';
else
    level = 'SEVERE';
end
end

function level = margin_level(value)
if value >= 0.10
    level = 'ADEQUATE';
elseif value >= 0.02
    level = 'LOW';
else
    level = 'CRITICAL';
end
end

function tf = is_diagnostic_domain_error(ME)
tf = strcmp(ME.identifier, 'rotor_model_bemt:FlapNotConverged') || ...
    strcmp(ME.identifier, 'rotor_model_bemt:CoupledSolveNotConverged') || ...
    strcmp(ME.identifier, ...
        'pitch_allocation_schedule:InvalidPitchCommand');
end

function tf = is_real_finite(value)
tf = isreal(value) && all(isfinite(value(:)));
end
