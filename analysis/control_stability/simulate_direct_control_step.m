function result = simulate_direct_control_step( ...
        pointId,trimReport,P13,A9,B9,controlName,amplitude,dt,duration)
%SIMULATE_DIRECT_CONTROL_STEP Nine-state physical-control step comparison.
% Nonlinear and linear models use the same explicit trapezoidal time grid.
% The envelope is an assumed analysis guard, not a flight-safety boundary.

contract = control_stability_interface_contract();
controlIndex = find(strcmp(contract.nineInputNames,controlName),1);
if isempty(controlIndex)
    error('control_stability:UnknownControl', ...
        'Unknown nine-state control "%s".',controlName);
end
if ~(isscalar(amplitude) && isfinite(amplitude) && isreal(amplitude))
    error('control_stability:InvalidStepAmplitude', ...
        'Step amplitude must be a finite real scalar.');
end
if ~(isscalar(dt) && dt > 0 && isfinite(dt) && ...
        isscalar(duration) && duration > dt && isfinite(duration))
    error('control_stability:InvalidTimeGrid', ...
        'dt and duration must be positive finite scalars.');
end

x0 = trimReport.x13(1:9);
u0 = trimReport.u10Torque([1:4,6:8]);
betaM = trimReport.condition.betaM;
P = P13.base;
startTime = min(0.10,0.20*duration);
t = (0:dt:duration).';
n = numel(t);
xNonlinear = NaN(n,9);
xLinearDelta = NaN(n,9);
uHistory = repmat(u0(:).',n,1);
valid = false(n,1);
physicalConverged = false(n,1);
guardReason = repmat({''},n,1);
xNonlinear(1,:) = x0(:).';
xLinearDelta(1,:) = zeros(1,9);

for k = 1:n
    if t(k) >= startTime
        uHistory(k,controlIndex) = ...
            uHistory(k,controlIndex)+amplitude;
    end
    [fCurrent,outCurrent] = tiltrotor_eom( ...
        xNonlinear(k,:).',uHistory(k,:).',betaM,P);
    physicalConverged(k) = outCurrent.physicalConverged && ...
        outCurrent.physicalBranchSupported;
    [valid(k),guardReason{k}] = analysis_guard( ...
        xNonlinear(k,:).',outCurrent);
    if k == n
        break;
    end

    uNext = u0;
    if t(k+1) >= startTime
        uNext(controlIndex) = uNext(controlIndex)+amplitude;
    end
    xPredict = xNonlinear(k,:).'+dt*fCurrent;
    fPredict = tiltrotor_eom(xPredict,uNext,betaM,P);
    xNonlinear(k+1,:) = (xNonlinear(k,:).'+ ...
        0.5*dt*(fCurrent+fPredict)).';

    duCurrent = uHistory(k,:).'-u0;
    duNext = uNext-u0;
    linearCurrent = A9*xLinearDelta(k,:).'+B9*duCurrent;
    linearPredictState = xLinearDelta(k,:).'+dt*linearCurrent;
    linearPredict = A9*linearPredictState+B9*duNext;
    xLinearDelta(k+1,:) = (xLinearDelta(k,:).'+ ...
        0.5*dt*(linearCurrent+linearPredict)).';
end

xLinear = xLinearDelta+x0(:).';
nonlinearDelta = xNonlinear-x0(:).';
linearDelta = xLinear-x0(:).';
errorValue = nonlinearDelta-linearDelta;
finiteRows = all(isfinite(xNonlinear),2) & all(isfinite(xLinear),2);
if ~all(finiteRows)
    error('control_stability:NonFiniteStepResponse', ...
        'The covered direct-control step produced a non-finite state.');
end

stepControl = u0;
stepControl(controlIndex) = stepControl(controlIndex)+amplitude;
[fStep,outStep] = tiltrotor_eom(x0,stepControl,betaM,P);
[fBase,outBase] = tiltrotor_eom(x0,u0,betaM,P);
if ~outStep.physicalConverged || ~outBase.physicalConverged
    error('control_stability:StepLeavesPhysicalBranch', ...
        'Initial physical-control step is not physically converged.');
end
initialAngularAcceleration = fStep(4:6)-fBase(4:6);

[pPeak,pPeakTime] = peak_metric(t,nonlinearDelta(:,4));
[qPeak,qPeakTime] = peak_metric(t,nonlinearDelta(:,5));
[rPeak,rPeakTime] = peak_metric(t,nonlinearDelta(:,6));
[phiPeak,phiPeakTime] = peak_metric(t,nonlinearDelta(:,7));
[thetaPeak,thetaPeakTime] = peak_metric(t,nonlinearDelta(:,8));
[psiPeak,psiPeakTime] = peak_metric(t,nonlinearDelta(:,9));
primaryStateIndex = primary_state_index(controlName);
primarySignal = nonlinearDelta(:,primaryStateIndex);
[primaryPeak,primaryPeakTime] = peak_metric(t,primarySignal);
riseTime = peak_rise_time(t,primarySignal,startTime);
overshoot = endpoint_overshoot(primarySignal,t,startTime);

firstInvalid = find(~valid,1);
if isempty(firstInvalid)
    firstInvalid = NaN;
    validDuration = duration-startTime;
    firstInvalidReason = 'NONE';
else
    validDuration = max(0,t(firstInvalid)-startTime);
    firstInvalidReason = guardReason{firstInvalid};
end

metrics = struct();
metrics.pointId = pointId;
metrics.controlName = controlName;
metrics.stepAmplitudeRad = amplitude;
metrics.stepAmplitudeDeg = amplitude*180/pi;
if abs(amplitude-0.5*pi/180) <= 1e-12
    metrics.stepSelectionBasis = ...
        '0.5 deg and below five percent of the channel half-range';
else
    metrics.stepSelectionBasis = [ ...
        'reduced local step after the 0.5 deg trial left the supported ' ...
        'rotor physical branch'];
end
metrics.dtSeconds = dt;
metrics.durationSeconds = duration;
metrics.stepStartSeconds = startTime;
metrics.initialPdotRadPerSecond2 = initialAngularAcceleration(1);
metrics.initialQdotRadPerSecond2 = initialAngularAcceleration(2);
metrics.initialRdotRadPerSecond2 = initialAngularAcceleration(3);
metrics.pPeakRadPerSecond = pPeak;
metrics.pPeakTimeSeconds = pPeakTime;
metrics.qPeakRadPerSecond = qPeak;
metrics.qPeakTimeSeconds = qPeakTime;
metrics.rPeakRadPerSecond = rPeak;
metrics.rPeakTimeSeconds = rPeakTime;
metrics.phiPeakRad = phiPeak;
metrics.phiPeakTimeSeconds = phiPeakTime;
metrics.thetaPeakRad = thetaPeak;
metrics.thetaPeakTimeSeconds = thetaPeakTime;
metrics.psiPeakRad = psiPeak;
metrics.psiPeakTimeSeconds = psiPeakTime;
metrics.primaryStateName = contract.nineStateNames{primaryStateIndex};
metrics.primaryPeak = primaryPeak;
metrics.primaryPeakTimeSeconds = primaryPeakTime;
metrics.peakBasedRiseTimeSeconds = riseTime;
metrics.endpointOvershootPercent = overshoot;
metrics.validDomainDurationSeconds = validDuration;
metrics.firstInvalidIndex = firstInvalid;
metrics.firstInvalidReason = firstInvalidReason;
metrics.maximumLinearNonlinearStateError = max(abs(errorValue(:)));
metrics.rmsLinearNonlinearStateError = sqrt(mean(errorValue(:).^2));
metrics.physicalConvergedAtEveryStep = all(physicalConverged);
metrics.validAtEveryStep = all(valid);
metrics.finiteReal = isreal(xNonlinear) && isreal(xLinear) && ...
    all(isfinite(xNonlinear(:))) && all(isfinite(xLinear(:)));

trajectory = table(t,xNonlinear(:,1),xNonlinear(:,2),xNonlinear(:,3), ...
    xNonlinear(:,4),xNonlinear(:,5),xNonlinear(:,6), ...
    xNonlinear(:,7),xNonlinear(:,8),xNonlinear(:,9), ...
    xLinear(:,1),xLinear(:,2),xLinear(:,3), ...
    xLinear(:,4),xLinear(:,5),xLinear(:,6), ...
    xLinear(:,7),xLinear(:,8),xLinear(:,9), ...
    valid,physicalConverged,guardReason, ...
    'VariableNames',{'timeSeconds','uNonlinear','vNonlinear', ...
    'wNonlinear','pNonlinear','qNonlinear','rNonlinear', ...
    'phiNonlinear','thetaNonlinear','psiNonlinear', ...
    'uLinear','vLinear','wLinear','pLinear','qLinear','rLinear', ...
    'phiLinear','thetaLinear','psiLinear','validDomain', ...
    'physicalConverged','guardReason'});

result.metrics = metrics;
result.trajectory = trajectory;
result.xNonlinear = xNonlinear;
result.xLinear = xLinear;
result.error = errorValue;
result.time = t;
result.controlHistory = uHistory;
result.analysisGuardSource = 'ASSUMED_ANALYSIS_GUARD';
result.claimBoundary = ['open-loop local response for the generic low-order ' ...
    'model; not a handling-quality rating'];
end

function [valid,reason] = analysis_guard(x,out)
d2r = pi/180;
speed = norm(x(1:3));
alpha = atan2(x(3),x(1));
if speed > 0
    beta = asin(max(-1,min(1,x(2)/speed)));
else
    beta = NaN;
end
reasons = {};
if speed < 5 || speed > 120
    reasons{end+1} = 'BODY_SPEED_GUARD';
end
if abs(alpha) > 35*d2r
    reasons{end+1} = 'ANGLE_OF_ATTACK_GUARD';
end
if ~isfinite(beta) || abs(beta) > 20*d2r
    reasons{end+1} = 'SIDESLIP_GUARD';
end
if abs(x(7)) > 45*d2r
    reasons{end+1} = 'ROLL_ATTITUDE_GUARD';
end
if abs(x(8)) > 45*d2r
    reasons{end+1} = 'PITCH_ATTITUDE_GUARD';
end
if any(abs(x(4:6)) > 1.5)
    reasons{end+1} = 'BODY_RATE_GUARD';
end
if ~out.physicalConverged || ~out.physicalBranchSupported
    reasons{end+1} = out.physicalStatus;
end
if isempty(reasons)
    valid = true;
    reason = 'NONE';
else
    valid = false;
    reason = strjoin(reasons,';');
end
end

function index = primary_state_index(controlName)
switch controlName
    case {'elevator','cyclicLong'}
        index = 5;
    case {'aileron','diffCollective'}
        index = 4;
    case {'rudder','diffCyclic'}
        index = 6;
    otherwise
        index = 5;
end
end

function [peak,time] = peak_metric(t,value)
[peak,index] = max(abs(value));
time = t(index);
end

function value = peak_rise_time(t,signal,startTime)
selection = find(t >= startTime);
segment = abs(signal(selection));
peak = max(segment);
if peak <= 1e-12
    value = NaN;
    return;
end
i10 = find(segment >= 0.10*peak,1);
i90 = find(segment >= 0.90*peak,1);
if isempty(i10) || isempty(i90) || i90 < i10
    value = NaN;
else
    value = t(selection(i90))-t(selection(i10));
end
end

function value = endpoint_overshoot(signal,t,startTime)
segment = signal(t >= startTime);
nTail = max(1,ceil(0.10*numel(segment)));
endpoint = mean(segment(end-nTail+1:end));
peak = max(abs(segment));
if abs(endpoint) <= 1e-10
    value = NaN;
else
    value = max(0,(peak-abs(endpoint))/abs(endpoint)*100);
end
end
