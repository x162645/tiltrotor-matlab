function rotorLoads = compute_berger13_rotor_loads( ...
        xRigid, u8, betaMAvg, betaML, betaMR, Pbase, baseInfo)
%COMPUTE_BERGER13_ROTOR_LOADS Independent rotor loads for berger13.
% This helper is adapted from the legacy rotor assembly in
% total_forces_moments. It keeps the 13x10 force/moment reference at the
% average-angle mass properties while evaluating the left and right rotor
% loads at their independent nacelle angles.

xRigid = xRigid(:);
u8 = u8(:);
if nargin < 7 || isempty(baseInfo)
    [~, ~, baseInfo] = total_forces_moments(xRigid, u8, betaMAvg, Pbase);
end

if ~isfield(baseInfo, 'appliedRotorControls') || ...
        ~isfield(baseInfo, 'massProperties')
    error('compute_berger13_rotor_loads:InvalidBaseInfo', ...
        'baseInfo must come from total_forces_moments at betaMAvg.');
end

cgShiftAvg = baseInfo.massProperties.cgShift;
leftAvg = component_by_name(baseInfo, 'rotorLeft');
rightAvg = component_by_name(baseInfo, 'rotorRight');

[FleftInd, MleftInd, leftDataInd] = rotor_model_bemt( ...
    xRigid, baseInfo.appliedRotorControls.left, betaML, -1, ...
    cgShiftAvg, Pbase);
[FrightInd, MrightInd, rightDataInd] = rotor_model_bemt( ...
    xRigid, baseInfo.appliedRotorControls.right, betaMR, +1, ...
    cgShiftAvg, Pbase);

rotorLoads.rotorLeft = pack_side(betaMAvg, betaML, leftAvg, ...
    FleftInd, MleftInd, leftDataInd);
rotorLoads.rotorRight = pack_side(betaMAvg, betaMR, rightAvg, ...
    FrightInd, MrightInd, rightDataInd);
rotorLoads.deltaF = rotorLoads.rotorLeft.deltaFromAverage.F + ...
    rotorLoads.rotorRight.deltaFromAverage.F;
rotorLoads.deltaM = rotorLoads.rotorLeft.deltaFromAverage.M + ...
    rotorLoads.rotorRight.deltaFromAverage.M;
end

function sideOut = pack_side(betaMAvg, betaMUsed, avgComp, ...
        Find, Mind, dataInd)
sideOut.betaMAvg = betaMAvg;
sideOut.betaMUsed = betaMUsed;
sideOut.average.F = avgComp.F;
sideOut.average.M = avgComp.M;
sideOut.average.data = avgComp.data;
sideOut.independent.F = Find;
sideOut.independent.M = Mind;
sideOut.independent.data = dataInd;
sideOut.deltaFromAverage.F = Find - avgComp.F;
sideOut.deltaFromAverage.M = Mind - avgComp.M;
end

function comp = component_by_name(baseInfo, targetName)
if ~isfield(baseInfo, 'components') || ~iscell(baseInfo.components)
    error('compute_berger13_rotor_loads:MissingComponents', ...
        'baseInfo.components is required.');
end
for k = 1:numel(baseInfo.components)
    candidate = baseInfo.components{k};
    if isfield(candidate, 'name') && strcmp(candidate.name, targetName)
        comp = candidate;
        return;
    end
end
error('compute_berger13_rotor_loads:MissingRotorComponent', ...
    'Could not find %s in baseInfo.components.', targetName);
end
