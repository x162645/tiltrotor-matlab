function [Fbody,Mbody,info] = total_forces_moments_13x10_reference( ...
        x13,u10,P13,options)
%TOTAL_FORCES_MOMENTS_13X10_REFERENCE Explicit opt-in reference-rotor stack.
% The production/default stack is evaluated only to reuse its reviewed
% control allocation and non-rotor components. Both rotor loads and the
% independently resolved half-wing slipstream loads are then replaced by
% NUAA_PUBLIC_FORMULA_REFERENCE results about the same actual total CG.

if nargin < 4
    options = struct();
end
x13 = x13(:);
u10 = u10(:);
if numel(x13) ~= 13 || numel(u10) ~= 10 || ...
        any(~isfinite([x13;u10])) || ~isreal([x13;u10])
    error('total_forces_moments_13x10_reference:InvalidInput', ...
        'Expected finite real 13-state and 10-input vectors.');
end
if abs(u10(5)) > 1e-12
    error('total_forces_moments_13x10_reference:LateralCyclicUnsupported', ...
        ['The public equations do not close the separate lateral-cyclic ' ...
         'channel. Use zero lateral cyclic for reference comparisons.']);
end

% Read-only evaluation of the reviewed stack supplies exact applied control
% values and actual-CG non-rotor components. Its rotor/wing loads are not
% retained in the returned force or moment.
[Fcurrent,Mcurrent,currentInfo] = ...
    total_forces_moments_13x10(x13,u10,P13);
P = P13.base;
betaML = currentInfo.betaML;
betaMR = currentInfo.betaMR;
xRigid = x13(1:9);
cgActual = currentInfo.massProperties.cgShift;
leftControl = currentInfo.baseComponents.appliedRotorControls.left;
rightControl = currentInfo.baseComponents.appliedRotorControls.right;

[Fleft,Mleft,leftData] = nuaa_public_formula_rotor( ...
    xRigid,leftControl,betaML,-1,cgActual,P,options);
[Fright,Mright,rightData] = nuaa_public_formula_rotor( ...
    xRigid,rightControl,betaMR,+1,cgActual,P,options);
[Fwing,Mwing,wingData] = wing_model_berger13_independent( ...
    xRigid,[u10(1:4);u10(6:8)],betaML,betaMR,cgActual, ...
    leftData,rightData,P);

fuselage = component_by_name(currentInfo,'fuselage');
horizontalTail = component_by_name(currentInfo,'horizontalTail');
verticalTail = component_by_name(currentInfo,'verticalTail');
components = {
    pack('rotorLeft',Fleft,Mleft,leftData);
    pack('rotorRight',Fright,Mright,rightData);
    pack('wing',Fwing,Mwing,wingData);
    fuselage;
    horizontalTail;
    verticalTail
    };
[Fbody,Mbody] = sum_components(components);

info = currentInfo;
info.modelId = 'NUAA_PUBLIC_FORMULA_REFERENCE';
info.modelNameZh = '南航公开公式旋翼参考模型';
info.defaultRotorPathModified = false;
info.currentReferenceOnly.F = Fcurrent;
info.currentReferenceOnly.M = Mcurrent;
info.currentReferenceOnly.info = currentInfo;
info.components = components;
info.rotorLeft.independent.F = Fleft;
info.rotorLeft.independent.M = Mleft;
info.rotorLeft.independent.data = leftData;
info.rotorRight.independent.F = Fright;
info.rotorRight.independent.M = Mright;
info.rotorRight.independent.data = rightData;
info.wingIndependent = wingData;
info.F = Fbody;
info.M = Mbody;
info.referenceMinusCurrent.F = Fbody-Fcurrent;
info.referenceMinusCurrent.M = Mbody-Mcurrent;
end

function comp = component_by_name(info,target)
for k = 1:numel(info.components)
    if strcmp(info.components{k}.name,target)
        comp = info.components{k};
        return;
    end
end
error('total_forces_moments_13x10_reference:MissingComponent', ...
    'Could not find %s in the reviewed component stack.',target);
end

function comp = pack(name,F,M,data)
comp = struct('name',name,'F',F,'M',M,'data',data);
end

function [F,M] = sum_components(components)
F = zeros(3,1);
M = zeros(3,1);
for k = 1:numel(components)
    F = F+components{k}.F;
    M = M+components{k}.M;
end
end
