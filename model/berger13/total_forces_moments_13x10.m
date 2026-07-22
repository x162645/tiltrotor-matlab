function [Fbody, Mbody, info] = total_forces_moments_13x10(x13, u10, P13)
%TOTAL_FORCES_MOMENTS_13X10 Isolated force/moment wrapper for PR1.
% The unchanged NUAA component stack is the symmetric reference. Namespace-
% local corrections replace both rotors and both half-wing region sums with
% left/right angle and wake evaluations while preserving the legacy default.

validate_13x10_inputs(x13, u10);
x13 = x13(:);
u10 = u10(:);
Pbase = P13.base;

xRigid = x13(1:9);
uLegacy = [u10(1:4); u10(6:8)];
betaMLRaw = x13(10);
betaMRRaw = x13(11);
betaLimits = [P13.nacelle.betaMin; P13.nacelle.betaMax];
betaML = clamp(betaMLRaw, betaLimits);
betaMR = clamp(betaMRRaw, betaLimits);
betaMAvg = 0.5*(betaML + betaMR);
lateralRaw = u10(5);
lateralApplied = clamp(lateralRaw, Pbase.control.cyclicLim);

[Favg, Mavg, baseInfo] = total_forces_moments( ...
    xRigid, uLegacy, betaMAvg, Pbase);
massProperties13 = mass_properties_berger13(betaML,betaMR,P13);
rotorLoads = compute_berger13_rotor_loads( ...
    xRigid, betaMAvg, betaML, betaMR, lateralApplied, P13,baseInfo, ...
    massProperties13);
[FwingIndependent,MwingIndependent,wingIndependent] = ...
    wing_model_berger13_independent(xRigid,uLegacy,betaML,betaMR, ...
    massProperties13.cgShift,rotorLoads.rotorLeft.independent.data, ...
    rotorLoads.rotorRight.independent.data,Pbase);
wingAverage = component_by_name(baseInfo,'wing');
wingDeltaF = FwingIndependent-wingAverage.F;
wingDeltaM = MwingIndependent-wingAverage.M;

Fbody = Favg + rotorLoads.deltaF + wingDeltaF;
Mbody = Mavg + rotorLoads.deltaM + wingDeltaM;

info.betaML = betaML;
info.betaMR = betaMR;
info.betaMAvg = betaMAvg;
info.betaMLRaw = betaMLRaw;
info.betaMRRaw = betaMRRaw;
info.lateralCyclicRaw = lateralRaw;
info.lateralCyclicApplied = lateralApplied;
info.nacelleTorqueLeft = u10(9);
info.nacelleTorqueRight = u10(10);
info.usedIndependentRotorAngles = true;
info.usedAverageNonRotorAero = true;
info.usedAverageWingLoads = false;
info.usedIndependentWingLoads = true;
info.usedNamespaceLocalLateralCyclic = true;
info.forceMomentApproximation = ['left/right rotors and half-wing regions ' ...
    'use betaML/betaMR and side-specific wakes; fuselage and tails retain ' ...
    'the symmetric reference evaluation at betaMAvg'];
info.baseComponents = baseInfo;
info.massProperties = massProperties13;
info.rotorLeft = rotorLoads.rotorLeft;
info.rotorRight = rotorLoads.rotorRight;
info.wingIndependent = wingIndependent;
info.wingIndependent.average = wingAverage;
info.wingIndependent.deltaF = wingDeltaF;
info.wingIndependent.deltaM = wingDeltaM;
info.averageOnlyF = Favg;
info.averageOnlyM = Mavg;
info.F = Fbody;
info.M = Mbody;
info.limitFlags.betaML = abs(betaML-betaMLRaw) > 0;
info.limitFlags.betaMR = abs(betaMR-betaMRRaw) > 0;
info.limitFlags.lateralCyclic = abs(lateralApplied-lateralRaw) > 0;
info.limitFlags.baseControls = ...
    norm(baseInfo.appliedControls-uLegacy, inf) > ...
    10*eps*max(1,norm(uLegacy,inf));
info.warnings = {};
if abs(betaML-betaMR) > 1e-10
    info.warnings{end+1,1} = ['independent rotor and wing angles are active; ' ...
        'fuselage and tail loads remain at betaMAvg'];
end
if abs(lateralApplied) > 1e-12
    info.warnings{end+1,1} = ['lateral cyclic changes namespace-local rotor ' ...
        'loads; baseline wing slipstream inputs remain lateral-free'];
end

function comp = component_by_name(baseInfo,targetName)
for k = 1:numel(baseInfo.components)
    candidate = baseInfo.components{k};
    if strcmp(candidate.name,targetName)
        comp = candidate;
        return;
    end
end
error('total_forces_moments_13x10:MissingComponent', ...
    'Could not find component %s.',targetName);
end
end

function validate_13x10_inputs(x13, u10)
if ~(isnumeric(x13) && isreal(x13) && numel(x13) == 13 && ...
        all(isfinite(x13(:))))
    error('total_forces_moments_13x10:InvalidState', ...
        'x13 must be a finite real 13-element vector.');
end
if ~(isnumeric(u10) && isreal(u10) && numel(u10) == 10 && ...
        all(isfinite(u10(:))))
    error('total_forces_moments_13x10:InvalidControl', ...
        'u10 must be a finite real 10-element vector.');
end
end

function y = clamp(value, limits)
y = min(max(value, limits(1)), limits(2));
end
