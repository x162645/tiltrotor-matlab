function sweepReport = trim_sweep_helicopter(P, opts)
%TRIM_SWEEP_HELICOPTER Low-speed helicopter-mode trim continuity sweep.
%
% Uses the current code definition betaM = 0 rad for helicopter mode. The
% trim closure is theta/collective/cyclicLong with udot/wdot/qdot residuals.
if nargin < 1 || isempty(P)
    P = params_nominal();
end
if nargin < 2
    opts = struct();
end

if ~isfield(opts, 'speeds')
    opts.speeds = [0, 5, 10, 15, 20];
end
if ~isfield(opts, 'betaM')
    opts.betaM = 0;
end
if ~isfield(opts, 'gamma')
    opts.gamma = 0;
end

% Reject invalid physical sweep inputs before constructing any trim attempt.
if ~(isnumeric(opts.speeds) && isreal(opts.speeds) && ...
        isvector(opts.speeds) && ~isempty(opts.speeds) && ...
        all(isfinite(opts.speeds(:))) && all(opts.speeds(:) >= 0))
    error('trim_sweep_helicopter:InvalidSpeeds', ...
        'opts.speeds must be a nonempty finite real vector with values >= 0 m/s.');
end
if ~(isnumeric(opts.betaM) && isreal(opts.betaM) && ...
        isscalar(opts.betaM) && isfinite(opts.betaM) && ...
        opts.betaM >= 0 && opts.betaM <= pi/2)
    error('trim_sweep_helicopter:InvalidNacelleAngle', ...
        'opts.betaM must be a finite real scalar in [0, pi/2] rad.');
end
if ~(isnumeric(opts.gamma) && isreal(opts.gamma) && ...
        isscalar(opts.gamma) && isfinite(opts.gamma))
    error('trim_sweep_helicopter:InvalidGamma', ...
        'opts.gamma must be a finite real scalar in rad.');
end
if ~isfield(opts, 'initialDeg')
    opts.initialDeg = [0, 18, 0];
end
if ~isfield(opts, 'useContinuation')
    opts.useContinuation = true;
end
if ~isfield(opts, 'useTrimMultiStart')
    opts.useTrimMultiStart = true;
end
if ~isfield(opts, 'allowRescueInitials')
    opts.allowRescueInitials = false;
end
if ~isfield(opts, 'failOnRescueInitial')
    opts.failOnRescueInitial = false;
end
if ~isfield(opts, 'computeResidualJacobian')
    opts.computeResidualJacobian = true;
end
if ~isfield(opts, 'computeLinearization')
    opts.computeLinearization = true;
end
if ~isfield(opts, 'rescueInitialDegs')
    opts.rescueInitialDegs = [
         0, 18,  0;
         4, 16,  2;
        -4, 18, -2;
         8, 15,  4;
        -8, 20, -4];
end
if ~isfield(opts, 'fullResidualTolerance')
    opts.fullResidualTolerance = max(P.trim.residualTolerance, 1.0e-6);
end
if ~isfield(opts, 'jacobianStepRad')
    opts.jacobianStepRad = 1.0e-4;
end
if ~isfield(opts, 'maxDeltaThetaDeg')
    opts.maxDeltaThetaDeg = 10;
end
if ~isfield(opts, 'maxDeltaControlDeg')
    opts.maxDeltaControlDeg = 10;
end
if ~isfield(opts, 'signFlipThresholdDeg')
    opts.signFlipThresholdDeg = 0.25;
end
opts.computeResidualJacobian = validate_logical_option( ...
    opts.computeResidualJacobian, ...
    'trim_sweep_helicopter:InvalidComputeResidualJacobian', ...
    'opts.computeResidualJacobian');
opts.computeLinearization = validate_logical_option( ...
    opts.computeLinearization, ...
    'trim_sweep_helicopter:InvalidComputeLinearization', ...
    'opts.computeLinearization');

d2r = pi/180;
speeds = opts.speeds(:).';
nSpeed = numel(speeds);
points = repmat(make_empty_point(), nSpeed, 1);
trimOpts.gamma = opts.gamma;
trimOpts.initialDeg = opts.initialDeg;
trimOpts.useMultiStart = opts.useTrimMultiStart;
trimOpts.alwaysMultiStart = false;
residualJacobianCallCount = 0;
linearizationCallCount = 0;

fprintf('\nHelicopter-mode trim continuity sweep\n');
fprintf('=====================================\n');
fprintf('betaM = %.12g rad, speeds [m/s] =', opts.betaM);
fprintf(' %.6g', speeds);
fprintf('\n');

for k = 1:nSpeed
    V = speeds(k);
    requestedInitialDeg = trimOpts.initialDeg(1:3);
    [xTrim, uTrim, trimInfo, attempts] = solve_with_optional_rescue( ...
        V, opts.betaM, P, trimOpts, opts);
    [f0, eomOut] = tiltrotor_eom(xTrim, uTrim, opts.betaM, P);

    point = make_empty_point();
    point.V = V;
    point.betaM = opts.betaM;
    point.initialDeg = requestedInitialDeg(:).';
    point.solutionDeg = [xTrim(8), uTrim(1), uTrim(3)]/d2r;
    point.initialSource = attempts(end).source;
    point.usedRescueInitial = attempts(end).usedRescue;
    point.rescueIndex = attempts(end).rescueIndex;
    point.attempts = attempts;
    point.exitflag = trimInfo.exitflag;
    point.converged = trimInfo.converged;
    point.trimResidual = trimInfo.residual(:);
    point.trimResidualNorm = trimInfo.residualNorm;
    point.fullResidual = f0(:);
    point.fullResidualNorm = norm(f0);
    point.xTrim = xTrim(:);
    point.uTrim = uTrim(:);
    point.controlLimits = control_limit_report(uTrim, P);
    point.anyControlAtLimit = any([point.controlLimits.atLimit]);
    point.trimVariableLimits = trimInfo.limitReport;
    point.anyTrimVariableAtLimit = trimInfo.atLimit;
    point.anyLimit = point.anyControlAtLimit || point.anyTrimVariableAtLimit;
    point.forcesMoments = force_moment_report(eomOut);
    point.finiteTrim = is_real_finite(xTrim) && is_real_finite(uTrim) && ...
        is_real_finite(trimInfo.residual) && is_real_finite(f0);
    point.trimInfo = trimInfo;
    point.status = classify_trim_point(point, P, opts);

    point.residualJacobian = empty_jacobian_report( ...
        opts, opts.computeResidualJacobian, point.status.success);
    point.linearization = empty_linearization_report( ...
        opts.computeLinearization, point.status.success);

    if point.status.success && opts.computeResidualJacobian
        residualJacobianCallCount = residualJacobianCallCount + 1;
        point.residualJacobian = residual_jacobian_report( ...
            point.V, point.betaM, opts.gamma, ...
            [point.xTrim(8); point.uTrim(1); point.uTrim(3)], P, opts);
        point.residualJacobian.requested = true;
        point.residualJacobian.computed = true;
        if point.residualJacobian.finite
            point.residualJacobian.status = 'COMPUTED';
            point.residualJacobian.message = '';
        else
            point.residualJacobian.status = 'FAILED';
            point.residualJacobian.message = ...
                'requested residual Jacobian is non-real or non-finite';
        end
    end

    if point.status.success && opts.computeLinearization
        linearizationCallCount = linearizationCallCount + 1;
        [A, B, linInfo] = linearize_numeric(xTrim, uTrim, opts.betaM, P);
        point.linearization.A = A;
        point.linearization.B = B;
        point.linearization.report = linInfo;
        point.linearization.finite = linInfo.finite && ...
            is_real_finite(A) && is_real_finite(B);
        point.linearization.hasComplex = ~isreal(A) || ~isreal(B);
        point.linearization.hasNaNInf = any(~isfinite(A(:))) || ...
            any(~isfinite(B(:)));
        point.linearization.computed = true;
        if point.linearization.finite
            point.linearization.status = 'COMPUTED';
            point.linearization.message = '';
        else
            point.linearization.status = 'FAILED';
            point.linearization.message = ...
                'requested linearization is non-real or non-finite';
        end
    end

    points(k) = point;

    fprintf(['V=%5.1f m/s exitflag=%3d trimNorm=% .3e ' ...
        'fullNorm=% .3e theta=% .3f deg collective=% .3f deg ' ...
        'cyclicLong=% .3f deg init=%s rescue=%d limit=%d ' ...
        'jac=%s lin=%s status=%s\n'], ...
        point.V, point.exitflag, point.trimResidualNorm, ...
        point.fullResidualNorm, point.xTrim(8)/d2r, point.uTrim(1)/d2r, ...
        point.uTrim(3)/d2r, point.initialSource, point.usedRescueInitial, ...
        point.anyLimit, point.residualJacobian.status, ...
        point.linearization.status, point.status.label);

    if opts.useContinuation && point.status.success
        trimOpts.initialDeg = [point.xTrim(8), point.uTrim(1), ...
            point.uTrim(3)]/d2r;
    end
end

adjacent = continuity_report(points, opts);
summary = make_summary(points, adjacent);

sweepReport.speeds = speeds;
sweepReport.betaM = opts.betaM;
sweepReport.options = opts;
sweepReport.points = points;
sweepReport.adjacent = adjacent;
sweepReport.summary = summary;
sweepReport.diagnosticCalls = struct( ...
    'residualJacobian', residualJacobianCallCount, ...
    'linearization', linearizationCallCount);
sweepReport.allPassed = summary.allTrimSuccessful && ...
    summary.allRequestedResidualJacobiansPassed && ...
    summary.allRequestedLinearizationsPassed && ...
    summary.noLimitSaturation && ...
    summary.continuityPassed && ...
    (~opts.failOnRescueInitial || summary.noRescueInitials);

fprintf('\nTrim continuity adjacent diagnostics\n');
fprintf('------------------------------------\n');
for k = 1:numel(adjacent)
    fprintf(['%5.1f -> %5.1f m/s: dTheta=% .3f deg ' ...
        'dCollective=% .3f deg dCyclic=% .3f deg jump=%d signFlip=%d passed=%d\n'], ...
        adjacent(k).V0, adjacent(k).V1, adjacent(k).deltaThetaDeg, ...
        adjacent(k).deltaControlDeg(1), adjacent(k).deltaControlDeg(3), ...
        adjacent(k).jumpDetected, adjacent(k).signFlipDetected, ...
        adjacent(k).passed);
    if ~adjacent(k).passed
        fprintf('  %s\n', adjacent(k).message);
    end
end
fprintf('All helicopter trim continuity checks passed: %d\n', ...
    sweepReport.allPassed);
end

function point = make_empty_point()
point = struct( ...
    'V', NaN, ...
    'betaM', NaN, ...
    'exitflag', NaN, ...
    'converged', false, ...
    'trimResidual', [], ...
    'trimResidualNorm', NaN, ...
    'fullResidual', [], ...
    'fullResidualNorm', NaN, ...
    'xTrim', [], ...
    'uTrim', [], ...
    'controlLimits', struct([]), ...
    'anyControlAtLimit', false, ...
    'trimVariableLimits', struct(), ...
    'anyTrimVariableAtLimit', false, ...
    'anyLimit', false, ...
    'forcesMoments', struct(), ...
    'finiteTrim', false, ...
    'trimInfo', struct(), ...
    'status', struct('success', false, 'label', 'NOT_RUN', 'message', ''), ...
    'linearization', struct('requested', false, 'computed', false, ...
        'status', 'NOT_REQUESTED', 'message', '', 'A', [], 'B', [], ...
        'report', struct(), 'finite', false, 'hasComplex', false, ...
        'hasNaNInf', false), ...
    'initialDeg', [NaN, NaN, NaN], ...
    'solutionDeg', [NaN, NaN, NaN], ...
    'initialSource', '', ...
    'usedRescueInitial', false, ...
    'rescueIndex', 0, ...
    'attempts', struct([]), ...
    'residualJacobian', struct());
end

function [xTrim, uTrim, trimInfo, attempts] = solve_with_optional_rescue( ...
        V, betaM, P, trimOpts, sweepOpts)
d2r = pi/180;
attemptOpts = trimOpts;
attemptOpts.useMultiStart = sweepOpts.useTrimMultiStart;

[xBest, uBest, infoBest] = trim_symmetric(V, betaM, P, attemptOpts);
attempts = make_attempt_record( ...
    'continuation', false, 0, attemptOpts.initialDeg, ...
    xBest, uBest, infoBest);

bestScore = attempt_score(infoBest, xBest, uBest, P, sweepOpts);
bestIndex = 1;

if attempts(1).success || ~sweepOpts.allowRescueInitials
    xTrim = xBest;
    uTrim = uBest;
    trimInfo = infoBest;
    return;
end

rescueDegs = sweepOpts.rescueInitialDegs;
for iRescue = 1:size(rescueDegs, 1)
    attemptOpts.initialDeg = rescueDegs(iRescue, :);
    [xr, ur, ir] = trim_symmetric(V, betaM, P, attemptOpts);
    attempts(end+1, 1) = make_attempt_record( ...
        'rescue', true, iRescue, attemptOpts.initialDeg, xr, ur, ir); %#ok<AGROW>
    thisScore = attempt_score(ir, xr, ur, P, sweepOpts);
    if thisScore < bestScore
        xBest = xr;
        uBest = ur;
        infoBest = ir;
        bestScore = thisScore;
        bestIndex = numel(attempts);
    end
    if attempts(end).success
        xBest = xr;
        uBest = ur;
        infoBest = ir;
        bestIndex = numel(attempts);
        break;
    end
end

if bestIndex ~= numel(attempts)
    attempts(end+1, 1) = attempts(bestIndex); %#ok<AGROW>
    attempts(end).source = 'best_failed_attempt';
end
xTrim = xBest;
uTrim = uBest;
trimInfo = infoBest;

    function record = make_attempt_record(source, usedRescue, rescueIndex, ...
            initialDeg, xCandidate, uCandidate, infoCandidate)
        record.source = source;
        record.usedRescue = usedRescue;
        record.rescueIndex = rescueIndex;
        record.initialDeg = initialDeg(:).';
        record.solutionDeg = [xCandidate(8), uCandidate(1), ...
            uCandidate(3)]/d2r;
        record.exitflag = infoCandidate.exitflag;
        record.residualNorm = infoCandidate.residualNorm;
        record.success = infoCandidate.exitflag > 0 && ...
            infoCandidate.residualNorm <= P.trim.residualTolerance && ...
            infoCandidate.finiteFullStateDerivative && ...
            ~infoCandidate.atLimit && infoCandidate.withinLimits;
    end
end

function score = attempt_score(infoCandidate, xCandidate, uCandidate, P, opts)
[f0, ~] = tiltrotor_eom(xCandidate, uCandidate, opts.betaM, P);
limitPenalty = double(infoCandidate.atLimit || ~infoCandidate.withinLimits);
finitePenalty = double(~is_real_finite(f0) || ...
    ~infoCandidate.finiteFullStateDerivative);
score = infoCandidate.residualNorm + norm(f0) + ...
    1.0e3*limitPenalty + 1.0e6*finitePenalty;
end

function jac = residual_jacobian_report(V, betaM, gamma, z, P, opts)
jac = trim_residual_jacobian(V, betaM, gamma, z, P, opts);
end

function jac = empty_jacobian_report(opts, requested, trimSuccessful)
if requested
    status = 'FAILED';
    message = 'requested residual Jacobian was not computed because trim failed';
else
    status = 'NOT_REQUESTED';
    message = 'residual Jacobian was not requested';
end
if trimSuccessful && requested
    message = 'requested residual Jacobian has not been computed';
end
jac = struct( ...
    'requested', requested, ...
    'computed', false, ...
    'status', status, ...
    'message', message, ...
    'variables', {{'theta', 'collective', 'cyclicLong'}}, ...
    'residuals', {{'udot', 'wdot', 'qdot'}}, ...
    'stepRad', opts.jacobianStepRad, ...
    'matrix', [], ...
    'singularValues', [], ...
    'rankTolerance', NaN, ...
    'rank', 0, ...
        'conditionNumber', NaN, ...
        'finite', false, ...
        'hasComplex', false, ...
        'hasNaNInf', false, ...
        'definition', 'raw d[udot;wdot;qdot]/d[theta;collective;cyclicLong]', ...
        'variableUnits', {{'rad', 'rad', 'rad'}}, ...
        'residualUnits', {{'m/s^2', 'm/s^2', 'rad/s^2'}}, ...
        'isScaled', false, ...
        'scaled', struct());
end

function lin = empty_linearization_report(requested, trimSuccessful)
if requested
    status = 'FAILED';
    message = 'requested linearization was not computed because trim failed';
else
    status = 'NOT_REQUESTED';
    message = 'linearization was not requested';
end
if trimSuccessful && requested
    message = 'requested linearization has not been computed';
end
lin = struct('requested', requested, 'computed', false, ...
    'status', status, 'message', message, 'A', [], 'B', [], ...
    'report', struct(), 'finite', false, 'hasComplex', false, ...
    'hasNaNInf', false);
end

function status = classify_trim_point(point, P, opts)
messages = {};
if point.exitflag <= 0
    messages{end+1} = sprintf('exitflag=%d', point.exitflag);
end
if point.trimResidualNorm > P.trim.residualTolerance
    messages{end+1} = sprintf('trim residual %.3e > %.3e', ...
        point.trimResidualNorm, P.trim.residualTolerance);
end
if point.fullResidualNorm > opts.fullResidualTolerance
    messages{end+1} = sprintf('full residual %.3e > %.3e', ...
        point.fullResidualNorm, opts.fullResidualTolerance);
end
if point.anyControlAtLimit
    messages{end+1} = 'control at limit';
end
if point.anyTrimVariableAtLimit
    messages{end+1} = 'trim variable at limit';
end
if isfield(point.trimInfo, 'withinLimits') && ~point.trimInfo.withinLimits
    messages{end+1} = 'trim variable outside limit';
end
if ~point.finiteTrim
    messages{end+1} = 'non-real or non-finite trim output';
end

status.success = isempty(messages);
if status.success
    status.label = 'SUCCESS';
    status.message = '';
else
    status.label = 'FAILED';
    status.message = strjoin(messages, '; ');
end
end

function adjacent = continuity_report(points, opts)
d2r = pi/180;
n = max(numel(points)-1, 0);
adjacent = repmat(struct( ...
    'V0', NaN, 'V1', NaN, 'deltaX', [], 'deltaU', [], ...
    'deltaThetaDeg', NaN, 'deltaControlDeg', [], ...
    'jumpDetected', false, 'signFlipDetected', false, ...
    'failedPointInPair', false, 'passed', false, 'message', ''), n, 1);

for k = 1:n
    p0 = points(k);
    p1 = points(k+1);
    item = adjacent(k);
    item.V0 = p0.V;
    item.V1 = p1.V;
    item.deltaX = p1.xTrim - p0.xTrim;
    item.deltaU = p1.uTrim - p0.uTrim;
    item.deltaThetaDeg = item.deltaX(8)/d2r;
    item.deltaControlDeg = item.deltaU/d2r;
    item.failedPointInPair = ~(p0.status.success && p1.status.success);

    controlJump = any(abs(item.deltaControlDeg(:)) > opts.maxDeltaControlDeg);
    thetaJump = abs(item.deltaThetaDeg) > opts.maxDeltaThetaDeg;
    item.jumpDetected = controlJump || thetaJump;
    item.signFlipDetected = significant_sign_flip( ...
        p0.uTrim(:)/d2r, ...
        p1.uTrim(:)/d2r, ...
        opts.signFlipThresholdDeg);

    messages = {};
    if item.failedPointInPair
        messages{end+1} = 'one or both trim points failed';
    end
    if item.jumpDetected
        messages{end+1} = 'adjacent trim/control jump exceeds threshold';
    end
    if item.signFlipDetected
        messages{end+1} = 'significant control sign flip detected';
    end

    item.passed = isempty(messages);
    item.message = strjoin(messages, '; ');
    adjacent(k) = item;
end
end

function tf = significant_sign_flip(aDeg, bDeg, thresholdDeg)
active = abs(aDeg) > thresholdDeg & abs(bDeg) > thresholdDeg;
tf = any(sign(aDeg(active)) ~= sign(bDeg(active)));
end

function summary = make_summary(points, adjacent)
summary = struct();
pointSuccess = arrayfun(@(p) p.status.success, points);
summary.successSpeeds = [points(pointSuccess).V];
summary.failedSpeeds = [points(~pointSuccess).V];
summary.allTrimSuccessful = all(pointSuccess);
summary.noControlSaturation = ~any([points.anyControlAtLimit]);
summary.noTrimVariableSaturation = ~any([points.anyTrimVariableAtLimit]);
summary.noLimitSaturation = ~any([points.anyLimit]);
summary.noRescueInitials = ~any([points.usedRescueInitial]);
summary.allRequestedResidualJacobiansPassed = all(arrayfun( ...
    @(p) ~p.residualJacobian.requested || ...
    (p.residualJacobian.computed && p.residualJacobian.finite), points));
summary.allRequestedLinearizationsPassed = all(arrayfun( ...
    @(p) ~p.linearization.requested || ...
    (p.linearization.computed && p.linearization.finite), points));
% Backward-compatible summary name for callers that inspect this field.
summary.allLinearizationsFinite = summary.allRequestedLinearizationsPassed;
summary.continuityPassed = isempty(adjacent) || all([adjacent.passed]);
summary.failedMessages = arrayfun(@(p) p.status.message, ...
    points(~pointSuccess), 'UniformOutput', false);
summary.jumpPairs = adjacent([adjacent.jumpDetected]);
summary.signFlipPairs = adjacent([adjacent.signFlipDetected]);
end

function report = force_moment_report(eomOut)
report.FaeroProp = eomOut.FaeroProp(:);
report.Fgravity = eomOut.Fgravity(:);
report.Ftotal = eomOut.Ftotal(:);
report.Mtotal = eomOut.Mtotal(:);
components = eomOut.components.components;
report.components = repmat(struct('name', '', 'F', zeros(3,1), ...
    'M', zeros(3,1), 'data', struct()), numel(components), 1);
for k = 1:numel(components)
    c = components{k};
    report.components(k).name = c.name;
    report.components(k).F = c.F(:);
    report.components(k).M = c.M(:);
    report.components(k).data = c.data;
end
end

function limits = control_limit_report(uCtrl, P)
tol = 1.0e-10;
names = {'collective'; 'rightCollective'; 'leftCollective'; ...
    'cyclic'; 'rightCyclicLong'; 'leftCyclicLong'; ...
    'aileron'; 'elevator'; 'rudder'};
values = [uCtrl(1); uCtrl(1)+uCtrl(2); uCtrl(1)-uCtrl(2); ...
    uCtrl(3); uCtrl(3)+uCtrl(4); uCtrl(3)-uCtrl(4); ...
    uCtrl(5); uCtrl(6); uCtrl(7)];
lower = [P.control.collectiveLim(1); P.control.collectiveLim(1); ...
    P.control.collectiveLim(1); P.control.cyclicLim(1); ...
    P.control.cyclicLim(1); P.control.cyclicLim(1); ...
    P.control.aileronLim(1); P.control.elevatorLim(1); ...
    P.control.rudderLim(1)];
upper = [P.control.collectiveLim(2); P.control.collectiveLim(2); ...
    P.control.collectiveLim(2); P.control.cyclicLim(2); ...
    P.control.cyclicLim(2); P.control.cyclicLim(2); ...
    P.control.aileronLim(2); P.control.elevatorLim(2); ...
    P.control.rudderLim(2)];

limits = struct([]);
for k = 1:numel(names)
    limits(k).name = names{k};
    limits(k).value = values(k);
    limits(k).lower = lower(k);
    limits(k).upper = upper(k);
    limits(k).atLower = abs(values(k)-lower(k)) <= tol;
    limits(k).atUpper = abs(values(k)-upper(k)) <= tol;
    limits(k).atLimit = limits(k).atLower || limits(k).atUpper;
end
end

function tf = is_real_finite(value)
tf = isreal(value) && all(isfinite(value(:)));
end

function value = validate_logical_option(value, errorId, optionName)
if islogical(value) && isscalar(value)
    return;
end
if isnumeric(value) && isreal(value) && isscalar(value) && ...
        isfinite(value) && (value == 0 || value == 1)
    value = logical(value);
    return;
end
error(errorId, ...
    '%s must be a logical scalar or numeric scalar 0/1.', optionName);
end
