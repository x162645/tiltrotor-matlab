function rotorLoads = compute_berger13_rotor_loads( ...
        xRigid, betaMAvg, betaML, betaMR, lateralCyclic, P13, ...
        baseInfo, massProperties13)
%COMPUTE_BERGER13_ROTOR_LOADS Replace baseline rotors with PR1 rotors.
% The baseline component stack and mass reference are evaluated at the
% average nacelle angle.  Only left/right rotor loads are reevaluated at
% betaML/betaMR.  Non-rotor loads remain an explicit average-angle limit.

if ~isfield(baseInfo, 'appliedRotorControls') || ...
        ~isfield(baseInfo, 'massProperties')
    error('compute_berger13_rotor_loads:InvalidBaseInfo', ...
        'baseInfo must come from the NUAA baseline component stack.');
end

Pbase = P13.base;
if nargin < 9 || isempty(massProperties13)
    massProperties13 = baseInfo.massProperties;
end
cgShift = massProperties13.cgShift;
leftAvg = component_by_name(baseInfo, 'rotorLeft');
rightAvg = component_by_name(baseInfo, 'rotorRight');

leftControl = baseInfo.appliedRotorControls.left;
rightControl = baseInfo.appliedRotorControls.right;
leftControl.lateralCyclic = P13.interface.lateralCyclicScale*lateralCyclic;
rightControl.lateralCyclic = P13.interface.lateralCyclicScale*lateralCyclic;
mapping = P13.interface.lateralCyclicTheta1cMapping;

[Fleft, Mleft, leftData] = rotor_model_bemt_berger13( ...
    xRigid, leftControl, betaML, -1, cgShift, Pbase, mapping);
[Fright, Mright, rightData] = rotor_model_bemt_berger13( ...
    xRigid, rightControl, betaMR, +1, cgShift, Pbase, mapping);

rotorLoads.rotorLeft = pack_side(betaMAvg, betaML, leftAvg, ...
    Fleft, Mleft, leftData);
rotorLoads.rotorRight = pack_side(betaMAvg, betaMR, rightAvg, ...
    Fright, Mright, rightData);
rotorLoads.deltaF = rotorLoads.rotorLeft.deltaFromAverage.F + ...
    rotorLoads.rotorRight.deltaFromAverage.F;
rotorLoads.deltaM = rotorLoads.rotorLeft.deltaFromAverage.M + ...
    rotorLoads.rotorRight.deltaFromAverage.M;
end

function sideOut = pack_side(betaMAvg, betaMUsed, avgComp, F, M, data)
sideOut.betaMAvg = betaMAvg;
sideOut.betaMUsed = betaMUsed;
sideOut.average.F = avgComp.F;
sideOut.average.M = avgComp.M;
sideOut.average.data = avgComp.data;
sideOut.independent.F = F;
sideOut.independent.M = M;
sideOut.independent.data = data;
sideOut.deltaFromAverage.F = F - avgComp.F;
sideOut.deltaFromAverage.M = M - avgComp.M;
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
