function [Fbody, Mbody, info] = total_forces_moments_13x10(x13, u10, P13)
%TOTAL_FORCES_MOMENTS_13X10 Isolated force/moment wrapper for PR1.
% The unchanged NUAA component stack receives the legacy seven controls at
% betaMAvg.  A namespace-local rotor replacement adds lateral cyclic and
% independent betaML/betaMR only to rotor loads.

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
rotorLoads = compute_berger13_rotor_loads( ...
    xRigid, betaMAvg, betaML, betaMR, lateralApplied, P13, baseInfo);

Fbody = Favg + rotorLoads.deltaF;
Mbody = Mavg + rotorLoads.deltaM;

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
info.usedNamespaceLocalLateralCyclic = true;
info.forceMomentApproximation = ['left/right rotor loads use betaML/betaMR ' ...
    'and research lateralCyclic; wing, fuselage, tail, mass properties, ' ...
    'and wing slipstream diagnostics use the unchanged baseline stack at ' ...
    'betaMAvg without lateralCyclic'];
info.baseComponents = baseInfo;
info.rotorLeft = rotorLoads.rotorLeft;
info.rotorRight = rotorLoads.rotorRight;
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
    info.warnings{end+1,1} = ['independent rotor nacelle angles are active; ' ...
        'non-rotor loads remain at betaMAvg'];
end
if abs(lateralApplied) > 1e-12
    info.warnings{end+1,1} = ['lateral cyclic changes namespace-local rotor ' ...
        'loads; baseline wing slipstream inputs remain lateral-free'];
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
