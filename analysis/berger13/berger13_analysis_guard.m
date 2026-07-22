function assessment = berger13_analysis_guard(x,u,out,guard)
%BERGER13_ANALYSIS_GUARD Evaluate an explicit assumed research envelope.
% These thresholds are analysis guards, not aircraft or flight-safety limits.

if nargin < 4 || isempty(guard)
    guard = default_guard();
end
x = x(:);
u = u(:);
if numel(u) ~= 10 || any(~isfinite(u))
    error('berger13_analysis_guard:InvalidControl', ...
        'The command vector must contain ten finite values.');
end
speed = norm(x(1:3));
alpha = atan2(x(3),x(1));
if speed > 0
    sideslip = asin(max(-1,min(1,x(2)/speed)));
else
    sideslip = NaN;
end
reasons = {};
if speed < guard.minBodySpeedMps
    reasons{end+1,1} = 'BODY_SPEED_BELOW_GUARD';
elseif speed > guard.maxBodySpeedMps
    reasons{end+1,1} = 'BODY_SPEED_ABOVE_GUARD';
end
if abs(alpha) > guard.maxAbsAlphaRad
    reasons{end+1,1} = 'ANGLE_OF_ATTACK_GUARD';
end
if ~isfinite(sideslip) || abs(sideslip) > guard.maxAbsSideslipRad
    reasons{end+1,1} = 'SIDESLIP_GUARD';
end
if abs(x(7)) > guard.maxAbsPhiRad
    reasons{end+1,1} = 'ROLL_ATTITUDE_GUARD';
end
if abs(x(8)) > guard.maxAbsThetaRad
    reasons{end+1,1} = 'PITCH_ATTITUDE_GUARD';
end
if any(abs(x(4:6)) > guard.maxAbsBodyRateRadPerSecond)
    reasons{end+1,1} = 'BODY_RATE_GUARD';
end

left = out.nacelle.left;
right = out.nacelle.right;
nacelleLimit = left.flags.atLowerAngle || left.flags.atUpperAngle || ...
    right.flags.atLowerAngle || right.flags.atUpperAngle;
actuatorLimit = left.flags.anyLimit || right.flags.anyLimit;
if nacelleLimit
    reasons{end+1,1} = 'NACELLE_ANGLE_LIMIT';
end

[wingValid,wingStatus] = wing_guard(out.components13.wingIndependent,guard);
if ~wingValid
    reasons{end+1,1} = 'LOCAL_WING_FLOW_GUARD';
end
assessment.valid = isempty(reasons);
assessment.reasons = reasons;
assessment.bodySpeedMps = speed;
assessment.alphaRad = alpha;
assessment.sideslipRad = sideslip;
assessment.phiRad = x(7);
assessment.thetaRad = x(8);
assessment.bodyRatesRadPerSecond = x(4:6);
assessment.controlSaturation = actuatorLimit;
assessment.nacelleAngleLimit = nacelleLimit;
assessment.localWingFlowValid = wingValid;
assessment.normalFlowBranchStatus = wingStatus;
assessment.guard = guard;
end

function [valid,status] = wing_guard(wing,guard)
regions = [wing.left.regions(:);wing.right.regions(:)];
valid = true;
transitionCount = 0;
nearNormalCount = 0;
for k = 1:numel(regions)
    region = regions{k};
    valid = valid && isfinite(region.V) && ...
        region.V >= guard.minLocalWingSpeedMps && ...
        abs(region.alpha) <= guard.maxAbsLocalWingAlphaRad && ...
        abs(region.beta) <= guard.maxAbsLocalWingBetaRad && ...
        isfinite(region.normalFlowBranchWeight) && ...
        region.normalFlowBranchWeight >= 0 && ...
        region.normalFlowBranchWeight <= 1;
    transitionCount = transitionCount+double(region.inNormalFlowTransition);
    nearNormalCount = nearNormalCount+double(region.nearNormal);
end
status = sprintf('nearNormal=%d,transition=%d,total=%d', ...
    nearNormalCount,transitionCount,numel(regions));
end

function guard = default_guard()
d2r = pi/180;
guard.minBodySpeedMps = 5;
guard.maxBodySpeedMps = 120;
guard.maxAbsAlphaRad = 35*d2r;
guard.maxAbsSideslipRad = 20*d2r;
guard.maxAbsPhiRad = 45*d2r;
guard.maxAbsThetaRad = 45*d2r;
guard.maxAbsBodyRateRadPerSecond = 1.5;
guard.minLocalWingSpeedMps = 0.5;
guard.maxAbsLocalWingAlphaRad = 85*d2r;
guard.maxAbsLocalWingBetaRad = 85*d2r;
guard.actuatorLimitIsDiagnosticOnly = true;
guard.parameterSource = 'ASSUMED_ANALYSIS_GUARD';
guard.claimBoundary = 'analysis guard, not aircraft or safety envelope';
end
