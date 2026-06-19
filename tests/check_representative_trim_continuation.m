function report = check_representative_trim_continuation()
%CHECK_REPRESENTATIVE_TRIM_CONTINUATION Five-point helicopter trim screen.
%
% This is a representative sampled check only. It cannot exclude local
% branch changes or multiple solutions between the five sampled speeds.
rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir, 'model'));
addpath(fullfile(rootDir, 'analysis'));

P = params_nominal();
opts = struct();
opts.speeds = [0, 5, 10, 15, 20];
opts.betaM = 0;
opts.gamma = 0;
opts.initialDeg = [0, 18, 0];
opts.useContinuation = true;
opts.useTrimMultiStart = false;
opts.allowRescueInitials = false;
opts.failOnRescueInitial = true;
opts.computeResidualJacobian = false;
opts.computeLinearization = false;

validation = check_option_validation(P, opts);
sweep = trim_sweep_helicopter(P, opts);
points = sweep.points;
adjacent = sweep.adjacent;

checks = struct();
checks.exactlyFivePoints = isequal(sweep.speeds, opts.speeds) && ...
    numel(points) == 5;
checks.allTrimSuccessful = numel(points) == 5 && ...
    all(arrayfun(@(p) p.status.success, points));
checks.oneAttemptPerPoint = numel(points) == 5 && ...
    all(arrayfun(@(p) numel(p.attempts) == 1, points));
checks.oneCandidatePerPoint = numel(points) == 5 && ...
    all(arrayfun(@(p) numel(p.trimInfo.candidates) == 1, points));
checks.noRescue = numel(points) == 5 && ...
    all(~[points.usedRescueInitial]) && sweep.summary.noRescueInitials;
checks.allFiniteReal = numel(points) == 5 && all(arrayfun( ...
    @(p) p.finiteTrim && is_real_finite(p.solutionDeg) && ...
    is_real_finite(p.trimResidual) && is_real_finite(p.fullResidual), points));
checks.reducedResidualsPass = numel(points) == 5 && ...
    all([points.trimResidualNorm] <= P.trim.residualTolerance);
checks.fullResidualsPass = numel(points) == 5 && ...
    all([points.fullResidualNorm] <= sweep.options.fullResidualTolerance);
checks.noTrimVariableAtOrBeyondLimit = numel(points) == 5 && ...
    all(arrayfun(@(p) limits_strictly_inside(p.trimVariableLimits.items), points));
checks.noAppliedControlAtOrBeyondLimit = numel(points) == 5 && ...
    all(arrayfun(@(p) applied_controls_strictly_inside( ...
    p.trimInfo.appliedControls, P), points));
checks.exactContinuationSeeding = exact_continuation_seeding(points, opts.initialDeg);
checks.diagnosticsNotRequested = numel(points) == 5 && all(arrayfun( ...
    @(p) ~p.residualJacobian.requested && ...
    ~p.linearization.requested, points));
checks.diagnosticsNotComputed = numel(points) == 5 && all(arrayfun( ...
    @(p) ~p.residualJacobian.computed && ...
    ~p.linearization.computed && ...
    strcmp(p.residualJacobian.status, 'NOT_REQUESTED') && ...
    strcmp(p.linearization.status, 'NOT_REQUESTED'), points));
checks.zeroDiagnosticCalls = sweep.diagnosticCalls.residualJacobian == 0 && ...
    sweep.diagnosticCalls.linearization == 0;
checks.adjacentChangesComplete = numel(adjacent) == 4 && all(arrayfun( ...
    @(a) is_real_finite(a.deltaThetaDeg) && ...
    numel(a.deltaControlDeg) >= 3 && ...
    is_real_finite(a.deltaControlDeg([1, 3])), adjacent));
checks.noConfiguredJump = numel(adjacent) == 4 && ...
    all(~[adjacent.jumpDetected]);
checks.noSignFlip = numel(adjacent) == 4 && ...
    all(~[adjacent.signFlipDetected]);
checks.defaultThresholdsUnchanged = ...
    sweep.options.maxDeltaThetaDeg == 10 && ...
    sweep.options.maxDeltaControlDeg == 10 && ...
    sweep.options.signFlipThresholdDeg == 0.25;
checks.optionValidation = validation.allPassed;
checks.sweepPassed = sweep.allPassed;

report = struct();
report.scope = ['Five-point representative screening only; this cannot ' ...
    'exclude local changes or multiple trim solutions between samples.'];
report.options = sweep.options;
report.sweep = sweep;
report.checks = checks;
report.optionValidation = validation;
report.highLevelTrimSolveCount = sum(arrayfun(@(p) numel(p.attempts), points));
report.objectiveFunctionEvaluationCount = sum(arrayfun( ...
    @(p) p.trimInfo.output.funcCount, points));
report.residualJacobianCallCount = sweep.diagnosticCalls.residualJacobian;
report.linearizationCallCount = sweep.diagnosticCalls.linearization;
report.pointTable = make_point_table(points);
report.adjacentTable = make_adjacent_table(adjacent);
report.allPassed = all(structfun(@(v) islogical(v) && isscalar(v) && v, checks));

print_report(report, P);
end

function validation = check_option_validation(P, baseOpts)
badJac = baseOpts;
badJac.speeds = 0;
badJac.computeResidualJacobian = 2;
badLin = baseOpts;
badLin.speeds = 0;
badLin.computeLinearization = NaN;
validation.invalidResidualJacobianRejected = expect_error( ...
    @() trim_sweep_helicopter(P, badJac), ...
    'trim_sweep_helicopter:InvalidComputeResidualJacobian');
validation.invalidLinearizationRejected = expect_error( ...
    @() trim_sweep_helicopter(P, badLin), ...
    'trim_sweep_helicopter:InvalidComputeLinearization');
validation.allPassed = validation.invalidResidualJacobianRejected && ...
    validation.invalidLinearizationRejected;
end

function tf = expect_error(fcn, expectedId)
tf = false;
try
    fcn();
catch ME
    tf = strcmp(ME.identifier, expectedId);
end
end

function tf = exact_continuation_seeding(points, initialDeg)
tf = numel(points) == 5 && isequal(points(1).initialDeg, initialDeg);
for k = 2:numel(points)
    tf = tf && points(k-1).status.success && ...
        isequal(points(k).initialDeg, points(k-1).solutionDeg);
end
end

function tf = limits_strictly_inside(items)
values = [items.value];
lower = [items.lower];
upper = [items.upper];
tf = is_real_finite(values) && all(values > lower) && all(values < upper) && ...
    ~any([items.atLimit]) && ~any([items.violated]);
end

function tf = applied_controls_strictly_inside(u, P)
u = u(:);
values = [u(1); u(1)+u(2); u(1)-u(2); ...
    u(3); u(3)+u(4); u(3)-u(4); u(5:7)];
lower = [repmat(P.control.collectiveLim(1), 3, 1); ...
    repmat(P.control.cyclicLim(1), 3, 1); ...
    P.control.aileronLim(1); P.control.elevatorLim(1); P.control.rudderLim(1)];
upper = [repmat(P.control.collectiveLim(2), 3, 1); ...
    repmat(P.control.cyclicLim(2), 3, 1); ...
    P.control.aileronLim(2); P.control.elevatorLim(2); P.control.rudderLim(2)];
tf = is_real_finite(values) && all(values > lower) && all(values < upper);
end

function table = make_point_table(points)
table = repmat(struct('V', NaN, 'thetaDeg', NaN, ...
    'collectiveDeg', NaN, 'cyclicLongDeg', NaN, ...
    'reducedResidualNorm', NaN, 'fullResidualNorm', NaN, ...
    'atOrBeyondLimit', true, 'initialDeg', [NaN, NaN, NaN], ...
    'initialSource', '', 'attemptCount', NaN, ...
    'objectiveFunctionEvaluations', NaN), numel(points), 1);
for k = 1:numel(points)
    p = points(k);
    table(k).V = p.V;
    table(k).thetaDeg = p.solutionDeg(1);
    table(k).collectiveDeg = p.solutionDeg(2);
    table(k).cyclicLongDeg = p.solutionDeg(3);
    table(k).reducedResidualNorm = p.trimResidualNorm;
    table(k).fullResidualNorm = p.fullResidualNorm;
    table(k).atOrBeyondLimit = p.anyLimit;
    table(k).initialDeg = p.initialDeg;
    table(k).initialSource = p.initialSource;
    table(k).attemptCount = numel(p.attempts);
    table(k).objectiveFunctionEvaluations = p.trimInfo.output.funcCount;
end
end

function table = make_adjacent_table(adjacent)
table = repmat(struct('V0', NaN, 'V1', NaN, 'deltaThetaDeg', NaN, ...
    'deltaCollectiveDeg', NaN, 'deltaCyclicLongDeg', NaN, ...
    'jumpDetected', true, 'signFlipDetected', true), numel(adjacent), 1);
for k = 1:numel(adjacent)
    a = adjacent(k);
    table(k).V0 = a.V0;
    table(k).V1 = a.V1;
    table(k).deltaThetaDeg = a.deltaThetaDeg;
    table(k).deltaCollectiveDeg = a.deltaControlDeg(1);
    table(k).deltaCyclicLongDeg = a.deltaControlDeg(3);
    table(k).jumpDetected = a.jumpDetected;
    table(k).signFlipDetected = a.signFlipDetected;
end
end

function print_report(report, P)
fprintf('\nRepresentative helicopter trim continuation check\n');
fprintf('=================================================\n');
fprintf('%s\n', report.scope);
fprintf('Reduced residual tolerance: %.3e\n', P.trim.residualTolerance);
fprintf('Full residual tolerance: %.3e\n', ...
    report.options.fullResidualTolerance);
fprintf(['High-level trims: %d, objective evaluations: %d, ' ...
    'Jacobian calls: %d, linearization calls: %d\n'], ...
    report.highLevelTrimSolveCount, report.objectiveFunctionEvaluationCount, ...
    report.residualJacobianCallCount, report.linearizationCallCount);
fprintf('\n V    theta    collective  cyclicLong   reducedNorm    fullNorm   limit  initSource\n');
for k = 1:numel(report.pointTable)
    p = report.pointTable(k);
    fprintf('%3.0f  %8.4f  %10.4f  %10.4f  %12.4e  %10.4e   %d    %s\n', ...
        p.V, p.thetaDeg, p.collectiveDeg, p.cyclicLongDeg, ...
        p.reducedResidualNorm, p.fullResidualNorm, ...
        p.atOrBeyondLimit, p.initialSource);
    fprintf('     initialDeg = [% .6f % .6f % .6f], attempts=%d, funcCount=%d\n', ...
        p.initialDeg, p.attemptCount, p.objectiveFunctionEvaluations);
end
fprintf('\n V0->V1   dTheta   dCollective  dCyclicLong  jump  signFlip\n');
for k = 1:numel(report.adjacentTable)
    a = report.adjacentTable(k);
    fprintf('%3.0f->%3.0f  %8.4f  %11.4f  %11.4f    %d       %d\n', ...
        a.V0, a.V1, a.deltaThetaDeg, a.deltaCollectiveDeg, ...
        a.deltaCyclicLongDeg, a.jumpDetected, a.signFlipDetected);
end
fprintf('Representative continuation check passed: %d\n', report.allPassed);
end

function tf = is_real_finite(value)
tf = isreal(value) && all(isfinite(value(:)));
end
