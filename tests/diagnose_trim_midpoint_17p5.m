function report = diagnose_trim_midpoint_17p5()
%DIAGNOSE_TRIM_MIDPOINT_17P5 Two-seed single-start trim at 17.5 m/s.
rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir, 'model'));
addpath(fullfile(rootDir, 'analysis'));

P = params_nominal();
V = 17.5;
betaM = 0;
gamma = 0;
d2r = pi/180;
seedLabels = {'lowSide15mps'; 'highSide20mps'};
seedDeg = [
    4.555587, 15.593765,  0.769241;
    3.110700, 15.168400, -1.391800];
rootToleranceDeg = 1.0e-4;
nearBlendFraction = 0.10;

solveTemplate = struct( ...
    'label', '', 'requestedInitialDeg', [NaN, NaN, NaN], ...
    'actualCandidateInitialDeg', [NaN, NaN, NaN], ...
    'finalDeg', [NaN, NaN, NaN], 'xTrim', [], 'uTrim', [], ...
    'exitflag', NaN, 'reducedResidual', [], ...
    'reducedResidualNorm', NaN, 'fullResidual', [], ...
    'fullResidualNorm', NaN, 'objectiveCost', NaN, ...
    'objectiveFunctionEvaluations', NaN, 'candidateCount', NaN, ...
    'limitReport', struct(), 'atLimit', true, 'withinLimits', false, ...
    'appliedControls', [], 'appliedControlLimits', struct([]), ...
    'appliedControlAtOrBeyondLimit', true, ...
    'usedMultiStart', false, 'alwaysMultiStart', false, ...
    'usedRescue', false, 'finiteReal', false, 'validRoot', false, ...
    'wing', struct(), 'rotors', struct());
solves = repmat(solveTemplate, 2, 1);

highLevelTrimSolveCount = 0;
postTrimEomCallCount = 0;
timerId = tic;
for k = 1:2
    opts = struct();
    opts.gamma = gamma;
    opts.initialDeg = seedDeg(k, :);
    opts.useMultiStart = false;
    opts.alwaysMultiStart = false;

    highLevelTrimSolveCount = highLevelTrimSolveCount + 1;
    [xTrim, uTrim, info] = trim_symmetric(V, betaM, P, opts);

    % Exactly one explicit post-trim EOM call for each final solution.
    postTrimEomCallCount = postTrimEomCallCount + 1;
    [fullResidual, eomOut] = tiltrotor_eom(xTrim, uTrim, betaM, P);

    item = solveTemplate;
    item.label = seedLabels{k};
    item.requestedInitialDeg = seedDeg(k, :);
    item.actualCandidateInitialDeg = info.candidates(1).initialDeg;
    item.finalDeg = [xTrim(8), uTrim(1), uTrim(3)]/d2r;
    item.xTrim = xTrim(:);
    item.uTrim = uTrim(:);
    item.exitflag = info.exitflag;
    item.reducedResidual = info.residual(:);
    item.reducedResidualNorm = info.residualNorm;
    item.fullResidual = fullResidual(:);
    item.fullResidualNorm = norm(fullResidual);
    item.objectiveCost = info.cost;
    item.objectiveFunctionEvaluations = info.output.funcCount;
    item.candidateCount = numel(info.candidates);
    item.limitReport = info.limitReport;
    item.atLimit = info.atLimit;
    item.withinLimits = info.withinLimits;
    item.appliedControls = eomOut.components.appliedControls(:);
    item.appliedControlLimits = applied_control_limits(item.appliedControls, P);
    item.appliedControlAtOrBeyondLimit = ...
        any([item.appliedControlLimits.atOrBeyondLimit]);
    item.usedMultiStart = opts.useMultiStart || item.candidateCount > 1;
    item.alwaysMultiStart = opts.alwaysMultiStart;
    item.usedRescue = false;
    item.finiteReal = is_real_finite(xTrim) && is_real_finite(uTrim) && ...
        is_real_finite(info.residual) && is_real_finite(fullResidual) && ...
        is_real_finite(item.appliedControls);
    item.validRoot = info.exitflag > 0 && item.finiteReal && ...
        item.reducedResidualNorm <= P.trim.residualTolerance && ...
        item.fullResidualNorm <= P.trim.residualTolerance && ...
        ~item.atLimit && item.withinLimits && ...
        ~item.appliedControlAtOrBeyondLimit;
    item.wing = summarize_wing(eomOut.components.wing, nearBlendFraction);
    item.rotors.left = summarize_rotor(eomOut.components.rotorLeft);
    item.rotors.right = summarize_rotor(eomOut.components.rotorRight);
    solves(k) = item;
end

elapsedSeconds = toc(timerId);
componentDifferenceDeg = solves(2).finalDeg - solves(1).finalDeg;
euclideanDifferenceDeg = norm(componentDifferenceDeg);
if ~all([solves.validRoot])
    conclusion = 'SOLVE_FAILED';
elseif euclideanDifferenceDeg <= rootToleranceDeg
    conclusion = 'SAME_NUMERICAL_ROOT';
else
    conclusion = 'DISTINCT_NUMERICAL_ROOTS';
end

report = struct();
report.V = V;
report.betaM = betaM;
report.gamma = gamma;
report.seedPrecisionNote = [ ...
    'Seeds use the highest precision persisted in repository evidence; ' ...
    'the 15 m/s seed has six decimals and the 20 m/s seed has four.'];
report.solves = solves;
report.componentDifferenceDeg = componentDifferenceDeg;
report.euclideanDifferenceDeg = euclideanDifferenceDeg;
report.rootToleranceDeg = rootToleranceDeg;
report.rootToleranceRationale = [ ...
    'Euclidean difference <= 1e-4 deg is the same-root criterion retained ' ...
    'from the 7.5 m/s diagnosis.'];
report.conclusion = conclusion;
report.elapsedSeconds = elapsedSeconds;
report.highLevelTrimSolveCount = highLevelTrimSolveCount;
report.objectiveFunctionEvaluationCount = ...
    sum([solves.objectiveFunctionEvaluations]);
report.postTrimEomCallCount = postTrimEomCallCount;
report.residualJacobianCallCount = 0;
report.fullLinearizationCallCount = 0;
report.executionCompleted = highLevelTrimSolveCount == 2 && ...
    postTrimEomCallCount == 2 && all([solves.candidateCount] == 1) && ...
    ~any([solves.usedMultiStart]) && ~any([solves.usedRescue]);
print_report(report);
end

function summary = summarize_wing(wing, nearBlendFraction)
summary.SslipHalf = wing.SslipHalf;
summary.SfreeHalf = wing.SfreeHalf;
summary.F = wing.F(:);
summary.M = wing.M(:);
summary.nearBlendFraction = nearBlendFraction;
summary.regions = repmat(struct( ...
    'side', NaN, 'inSlipstream', false, 'area', NaN, ...
    'F', [], 'M', [], 'Vlocal', [], 'alphaRad', NaN, 'betaRad', NaN, ...
    'wakeVelocity', NaN, 'normalFlowRatio', NaN, ...
    'blendCenter', NaN, 'blendHalfWidth', NaN, 'blendWeight', NaN, ...
    'nearNormal', false, 'inBlendRegion', false, ...
    'distanceToBlendBand', NaN, 'nearBlendRegion', false, ...
    'inOrNearBlendRegion', false), numel(wing.regions), 1);
for k = 1:numel(wing.regions)
    source = wing.regions{k};
    item = summary.regions(k);
    item.side = source.side;
    item.inSlipstream = source.inSlipstream;
    item.area = source.area;
    item.F = source.F(:);
    item.M = source.M(:);
    item.Vlocal = source.Vlocal(:);
    item.alphaRad = source.alpha;
    item.betaRad = source.beta;
    item.wakeVelocity = source.wakeVelocity;
    item.normalFlowRatio = source.normalFlowRatioActual;
    item.blendCenter = source.normalFlowTransitionCenter;
    item.blendHalfWidth = source.normalFlowBlendHalfWidth;
    item.blendWeight = source.normalFlowBranchWeight;
    item.nearNormal = source.nearNormal;
    item.inBlendRegion = source.inNormalFlowTransition;
    lower = item.blendCenter - item.blendHalfWidth;
    upper = item.blendCenter + item.blendHalfWidth;
    item.distanceToBlendBand = max([lower-item.normalFlowRatio, ...
        item.normalFlowRatio-upper, 0]);
    item.nearBlendRegion = ~item.inBlendRegion && ...
        item.distanceToBlendBand <= nearBlendFraction*item.blendHalfWidth;
    item.inOrNearBlendRegion = item.inBlendRegion || item.nearBlendRegion;
    summary.regions(k) = item;
end
summary.anyInBlendRegion = any([summary.regions.inBlendRegion]);
summary.anyNearBlendRegion = any([summary.regions.nearBlendRegion]);
summary.anyInOrNearBlendRegion = any([summary.regions.inOrNearBlendRegion]);
end

function summary = summarize_rotor(rotor)
summary.inducedVelocity = rotor.inducedVelocity;
summary.inducedVelocityError = rotor.inducedVelocityError;
summary.iterations = rotor.iterations;
summary.coupledConverged = rotor.coupledConverged;
summary.Vhub = rotor.Vhub(:);
summary.Vaxial = rotor.Vaxial;
summary.Vlong = rotor.Vlong;
summary.Vlat = rotor.Vlat;
summary.muLong = rotor.muLong;
summary.muLat = rotor.muLat;
summary.eT = rotor.eT(:);
summary.nDisk = rotor.nDisk(:);
summary.thrust = rotor.thrust;
summary.torque = rotor.torque;
summary.F = rotor.F(:);
summary.M = rotor.M(:);
end

function limits = applied_control_limits(u, P)
names = {'collective'; 'rightCollective'; 'leftCollective'; ...
    'cyclicLong'; 'rightCyclicLong'; 'leftCyclicLong'; ...
    'aileron'; 'elevator'; 'rudder'};
values = [u(1); u(1)+u(2); u(1)-u(2); ...
    u(3); u(3)+u(4); u(3)-u(4); u(5:7)];
lower = [repmat(P.control.collectiveLim(1), 3, 1); ...
    repmat(P.control.cyclicLim(1), 3, 1); ...
    P.control.aileronLim(1); P.control.elevatorLim(1); P.control.rudderLim(1)];
upper = [repmat(P.control.collectiveLim(2), 3, 1); ...
    repmat(P.control.cyclicLim(2), 3, 1); ...
    P.control.aileronLim(2); P.control.elevatorLim(2); P.control.rudderLim(2)];
limits = repmat(struct('name', '', 'value', NaN, 'lower', NaN, ...
    'upper', NaN, 'atOrBeyondLimit', true), numel(names), 1);
for k = 1:numel(names)
    limits(k).name = names{k};
    limits(k).value = values(k);
    limits(k).lower = lower(k);
    limits(k).upper = upper(k);
    limits(k).atOrBeyondLimit = values(k) <= lower(k) || values(k) >= upper(k);
end
end

function print_report(report)
fprintf('\n17.5 m/s midpoint trim diagnosis\n');
fprintf('=================================\n');
fprintf('%s\n', report.seedPrecisionNote);
for k = 1:numel(report.solves)
    s = report.solves(k);
    fprintf('\n%s\n', s.label);
    fprintf('  requested seed [deg] = [% .12f % .12f % .12f]\n', ...
        s.requestedInitialDeg);
    fprintf('  candidate seed [deg] = [% .12f % .12f % .12f]\n', ...
        s.actualCandidateInitialDeg);
    fprintf('  final [deg]          = [% .12f % .12f % .12f]\n', s.finalDeg);
    fprintf(['  exitflag=%d reducedNorm=%.12e fullNorm=%.12e ' ...
        'cost=%.12e funcCount=%d candidates=%d\n'], ...
        s.exitflag, s.reducedResidualNorm, s.fullResidualNorm, ...
        s.objectiveCost, s.objectiveFunctionEvaluations, s.candidateCount);
    fprintf(['  atLimit=%d withinLimits=%d appliedAtOrBeyond=%d ' ...
        'multistart=%d rescue=%d appliedControlsDeg='], ...
        s.atLimit, s.withinLimits, s.appliedControlAtOrBeyondLimit, ...
        s.usedMultiStart, s.usedRescue);
    fprintf(' % .12f', s.appliedControls*180/pi);
    fprintf('\n');
    fprintf('  wing in blend=%d near blend=%d in-or-near=%d\n', ...
        s.wing.anyInBlendRegion, s.wing.anyNearBlendRegion, ...
        s.wing.anyInOrNearBlendRegion);
    for j = 1:numel(s.wing.regions)
        w = s.wing.regions(j);
        fprintf(['    wing side=%+d slip=%d alpha=% .6f deg ratio=%.9f ' ...
            'weight=%.9f nearNormal=%d inBlend=%d wake=%.9f m/s ' ...
            'F=[% .6e % .6e % .6e] M=[% .6e % .6e % .6e]\n'], ...
            w.side, w.inSlipstream, w.alphaRad*180/pi, ...
            w.normalFlowRatio, w.blendWeight, w.nearNormal, ...
            w.inBlendRegion, w.wakeVelocity, w.F, w.M);
    end
    print_rotor('left', s.rotors.left);
    print_rotor('right', s.rotors.right);
end
fprintf('\nhigh-low final difference [deg] = [% .12f % .12f % .12f]\n', ...
    report.componentDifferenceDeg);
fprintf('Euclidean difference = %.12e deg; tolerance = %.12e deg\n', ...
    report.euclideanDifferenceDeg, report.rootToleranceDeg);
fprintf('Conclusion: %s\n', report.conclusion);
fprintf(['Calls: trims=%d objective=%d postEOM=%d Jacobian=%d ' ...
    'linearization=%d; elapsed=%.3f s; executionCompleted=%d\n'], ...
    report.highLevelTrimSolveCount, report.objectiveFunctionEvaluationCount, ...
    report.postTrimEomCallCount, report.residualJacobianCallCount, ...
    report.fullLinearizationCallCount, report.elapsedSeconds, ...
    report.executionCompleted);
end

function print_rotor(label, rotor)
fprintf(['    rotor %s: induced=%.12f m/s inducedError=%.3e ' ...
    'iterations=%d converged=%d thrust=%.9f N torque=%.9f N-m ' ...
    'Vaxial=%.9f Vlong=%.9f Vlat=%.9f ' ...
    'muLong=%.9f muLat=%.9f\n'], ...
    label, rotor.inducedVelocity, rotor.inducedVelocityError, ...
    rotor.iterations, rotor.coupledConverged, rotor.thrust, rotor.torque, ...
    rotor.Vaxial, rotor.Vlong, rotor.Vlat, rotor.muLong, rotor.muLat);
end

function tf = is_real_finite(value)
tf = isreal(value) && all(isfinite(value(:)));
end
