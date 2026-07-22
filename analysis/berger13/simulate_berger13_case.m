function simulation = simulate_berger13_case(trimReport,P13,caseDef)
%SIMULATE_BERGER13_CASE Fixed-step nonlinear command/fault simulation.
% Explicit trapezoidal integration is used so prescribed delay contexts and
% limit flags remain observable at every output time.

required = {'name','duration','dt','inputType','amplitude','startTime'};
for k = 1:numel(required)
    if ~isfield(caseDef,required{k})
        error('simulate_berger13_case:InvalidCase', ...
            'caseDef.%s is required.',required{k});
    end
end
Psim = apply_parameter_overrides(P13,caseDef);
t = (0:caseDef.dt:caseDef.duration).';
n = numel(t);
x = NaN(n,13);
u = NaN(n,10);
loads = NaN(n,3);
limits = false(n,1);
leftRateClamped = false(n,1);
leftAccelerationClamped = false(n,1);
leftTorqueClamped = false(n,1);
rightRateClamped = false(n,1);
rightAccelerationClamped = false(n,1);
rightTorqueClamped = false(n,1);
guardValid = false(n,1);
guardReasons = cell(n,1);
guardDiagnostics = cell(n,1);
x(1,:) = trimReport.x13(:).';
diverged = false;
divergenceIndex = NaN;
for k = 1:n
    u(k,:) = command_at(t(k),trimReport.u10Command,caseDef).';
    context = delay_context(t(k),trimReport.u10Command,caseDef,Psim);
    [f1,out1] = tiltrotor_eom_13x10_command( ...
        x(k,:).',u(k,:).',Psim,context);
    loads(k,:) = [out1.Ftotal(2),out1.Mtotal(1),out1.Mtotal(3)];
    limits(k) = out1.nacelle.left.flags.anyLimit || ...
        out1.nacelle.right.flags.anyLimit;
    leftRateClamped(k) = out1.nacelle.left.flags.rateClamped;
    leftAccelerationClamped(k) = ...
        out1.nacelle.left.flags.accelerationClamped;
    leftTorqueClamped(k) = out1.nacelle.left.flags.torqueClamped;
    rightRateClamped(k) = out1.nacelle.right.flags.rateClamped;
    rightAccelerationClamped(k) = ...
        out1.nacelle.right.flags.accelerationClamped;
    rightTorqueClamped(k) = out1.nacelle.right.flags.torqueClamped;
    guardDiagnostics{k} = berger13_analysis_guard( ...
        x(k,:).',u(k,:).',out1,guard_config(caseDef));
    guardValid(k) = guardDiagnostics{k}.valid;
    guardReasons{k} = guardDiagnostics{k}.reasons;
    if k == n
        break;
    end
    xPredict = x(k,:).'+caseDef.dt*f1;
    uNext = command_at(t(k+1),trimReport.u10Command,caseDef);
    contextNext = delay_context(t(k+1),trimReport.u10Command, ...
        caseDef,Psim);
    f2 = tiltrotor_eom_13x10_command( ...
        xPredict,uNext,Psim,contextNext);
    x(k+1,:) = (x(k,:).'+0.5*caseDef.dt*(f1+f2)).';
    if any(~isfinite(x(k+1,:))) || ~isreal(x(k+1,:)) || ...
            max(abs(x(k+1,7:9))) > 4*pi
        diverged = true;
        divergenceIndex = k+1;
        x(k+1:end,:) = NaN;
        break;
    end
end

betaSym = 0.5*(x(:,10)+x(:,11));
betaDiff = 0.5*(x(:,11)-x(:,10));
deviation = x-trimReport.x13(:).';
simulation.caseDef = caseDef;
simulation.time = t;
simulation.x = x;
simulation.u = u;
simulation.lateralForceRollYawMoment = loads;
simulation.limitActive = limits;
simulation.limitDetails.leftRateClamped = leftRateClamped;
simulation.limitDetails.leftAccelerationClamped = leftAccelerationClamped;
simulation.limitDetails.leftTorqueClamped = leftTorqueClamped;
simulation.limitDetails.rightRateClamped = rightRateClamped;
simulation.limitDetails.rightAccelerationClamped = ...
    rightAccelerationClamped;
simulation.limitDetails.rightTorqueClamped = rightTorqueClamped;
simulation.betaSym = betaSym;
simulation.betaDiff = betaDiff;
simulation.diverged = diverged;
simulation.divergenceIndex = divergenceIndex;
firstViolationIndex = find(~guardValid,1);
if isempty(firstViolationIndex)
    firstViolationIndex = NaN;
    firstViolationTime = NaN;
    validPrefixEndIndex = find(all(isfinite(x),2),1,'last');
    violationReason = 'NONE';
else
    firstViolationTime = t(firstViolationIndex);
    validPrefixEndIndex = max(firstViolationIndex-1,1);
    violationReason = strjoin(guardReasons{firstViolationIndex},';');
end
if isempty(validPrefixEndIndex), validPrefixEndIndex = 1; end
simulation.guardValid = guardValid;
simulation.guardReasons = guardReasons;
simulation.guardDiagnostics = guardDiagnostics;
simulation.firstEnvelopeViolationIndex = firstViolationIndex;
simulation.firstEnvelopeViolationTime = firstViolationTime;
simulation.violationReason = violationReason;
simulation.validPrefixEndIndex = validPrefixEndIndex;
simulation.fullNumericalTrajectoryAvailable = true;
simulation.fullTrajectoryMetrics = trajectory_metrics( ...
    t,deviation,betaDiff,loads,limits,caseDef.startTime,1:n);
simulation.validPrefixMetrics = trajectory_metrics( ...
    t,deviation,betaDiff,loads,limits,caseDef.startTime, ...
    1:validPrefixEndIndex);
simulation.metrics = simulation.validPrefixMetrics;
simulation.quantitativeClaimAllowed = validPrefixEndIndex >= 2 && ...
    simulation.validPrefixMetrics.finiteReal;
simulation.finiteReal = all(isfinite(x(~isnan(x)))) && isreal(x);
end

function metrics = trajectory_metrics( ...
        t,deviation,betaDiff,loads,limits,startTime,indices)
metrics.maxAttitudeDeviationRad = ...
    max(abs(deviation(indices,7:9)),[],'all','omitnan');
metrics.maxAngularRateRadPerSecond = ...
    max(abs(deviation(indices,4:6)),[],'all','omitnan');
metrics.maxBetaDiffRad = max(abs(betaDiff(indices)),[],'all','omitnan');
metrics.maxAbsLateralForceN = ...
    max(abs(loads(indices,1)),[],'all','omitnan');
metrics.maxAbsRollMomentNm = ...
    max(abs(loads(indices,2)),[],'all','omitnan');
metrics.maxAbsYawMomentNm = ...
    max(abs(loads(indices,3)),[],'all','omitnan');
metrics.anyLimit = any(limits(indices));
metrics.recoveryTimeSeconds = recovery_time( ...
    t(indices),deviation(indices,:),startTime);
metrics.finiteReal = all(isfinite(deviation(indices,:)),'all') && ...
    all(isfinite(loads(indices,:)),'all');
end

function guard = guard_config(caseDef)
if isfield(caseDef,'analysisGuard')
    guard = caseDef.analysisGuard;
else
    guard = [];
end
end

function P = apply_parameter_overrides(P,caseDef)
if isfield(caseDef,'leftActuator')
    P.commandActuator.left = merge(P.commandActuator.left, ...
        caseDef.leftActuator);
end
if isfield(caseDef,'rightActuator')
    P.commandActuator.right = merge(P.commandActuator.right, ...
        caseDef.rightActuator);
end
end

function S = merge(S,overrides)
names = fieldnames(overrides);
for k = 1:numel(names)
    S.(names{k}) = overrides.(names{k});
end
end

function u = command_at(t,u0,caseDef)
u = u0(:);
amplitude = caseDef.amplitude;
if strcmp(caseDef.inputType,'ramp')
    rampDuration = caseDef.rampDuration;
    fraction = min(max((t-caseDef.startTime)/rampDuration,0),1);
    value = amplitude*fraction;
elseif t >= caseDef.startTime
    value = amplitude;
else
    value = 0;
end
if isfield(caseDef,'pulseEndTime') && t >= caseDef.pulseEndTime
    value = 0;
end
switch caseDef.inputType
    case {'betaSym','ramp'}
        u(9:10) = u(9:10)+value;
    case 'betaDiff'
        u(9) = u(9)-value;
        u(10) = u(10)+value;
    case 'lateralCyclic'
        u(5) = u(5)+value;
    case 'aileron'
        u(6) = u(6)+value;
    case 'rudder'
        u(8) = u(8)+value;
    otherwise
        error('simulate_berger13_case:UnsupportedInput', ...
            'Unsupported inputType %s.',caseDef.inputType);
end
end

function context = delay_context(t,u0,caseDef,P)
context = struct();
if P.commandActuator.left.commandDelay > 0
    delayed = command_at(max(0,t-P.commandActuator.left.commandDelay), ...
        u0,caseDef);
    context.left.delayedCommand = delayed(9);
end
if P.commandActuator.right.commandDelay > 0
    delayed = command_at(max(0,t-P.commandActuator.right.commandDelay), ...
        u0,caseDef);
    context.right.delayedCommand = delayed(10);
end
end

function value = recovery_time(t,deviation,startTime)
scale = max(abs(deviation),[],1,'omitnan');
tolerance = max(0.02*scale,1e-6);
settled = all(abs(deviation) <= tolerance,2);
value = NaN;
for k = find(t>=startTime,1):numel(t)
    if all(settled(k:end))
        value = t(k)-startTime;
        return;
    end
end
end
