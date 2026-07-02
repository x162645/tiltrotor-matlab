function [Fbody, Mbody, out] = wing_model(x, uCtrl, betaM, cgShift, rotorLeft, rotorRight, P)
%WING_MODEL Public wing aerodynamic-model entry point.
% Default behavior is the preserved legacy model.  The full-angle strip
% model is opt-in through P.wing.fullAngleModelEnabled or P.wing.modelType.

useFullAngle = false;
if isfield(P, 'wing')
    if isfield(P.wing, 'modelType') && ischar(P.wing.modelType)
        useFullAngle = strcmpi(P.wing.modelType, 'fullAngle') || ...
            strcmpi(P.wing.modelType, 'full-angle');
    end
    if isfield(P.wing, 'fullAngleModelEnabled')
        useFullAngle = useFullAngle || logical(P.wing.fullAngleModelEnabled);
    end
end

if useFullAngle
    [Fbody, Mbody, out] = wing_model_full_angle( ...
        x, uCtrl, betaM, cgShift, rotorLeft, rotorRight, P);
else
    [Fbody, Mbody, out] = wing_model_legacy( ...
        x, uCtrl, betaM, cgShift, rotorLeft, rotorRight, P);
end
end
