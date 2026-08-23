function [Fbody, Mbody, out] = rotor_model_bemt_section_aero(x, rotorCtrl, betaM, side, cgShift, P)
%ROTOR_MODEL_BEMT_SECTION_AERO Opt-in low-order section-aero extension.
%
% This wrapper preserves rotor_model_bemt as the production baseline while
% adding two scalar low-order section-aerodynamic effects needed for external
% validation studies:
%
%   alpha0L                       scalar zero-lift angle, rad
%   enableCompressibilityCorrection  bounded equivalent PG slope correction
%
% The extension is deliberately low order. A scalar alpha0L is algebraically
% equivalent to replacing alpha by alpha-alpha0L in the current section lift
% law, so it is implemented by an equal collective-reference shift before the
% unchanged production rotor model is called. Compressibility is represented
% by one reference-radius Mach number, not by a radial airfoil database.
%
% Backward compatibility:
% - missing alpha0L -> 0 rad
% - missing/false compressibility flag -> disabled
% Hence a legacy P struct produces the same call into rotor_model_bemt.
%
% Optional fields:
%   P.rotor.alpha0L                         [rad], default 0
%   P.rotor.enableCompressibilityCorrection logical, default false
%   P.rotor.compressibilityReferenceRadius  r/R, default 0.75
%   P.rotor.compressibilityMachCap          -, default 0.75
%   P.env.aSound                            m/s, default 340
%
% This wrapper does not claim that any validation-specific alpha0L is an
% aircraft-type constant. Its provenance belongs to the validation builder.

alpha0L = scalar_field_or_default(P.rotor, 'alpha0L', 0.0);
enableCompressibility = logical_field_or_default( ...
    P.rotor, 'enableCompressibilityCorrection', false);
referenceRadius = scalar_field_or_default( ...
    P.rotor, 'compressibilityReferenceRadius', 0.75);
machCap = scalar_field_or_default(P.rotor, 'compressibilityMachCap', 0.75);
aSound = scalar_field_or_default(P.env, 'aSound', 340.0);

if ~(isfinite(alpha0L) && isreal(alpha0L))
    error('rotor_model_bemt_section_aero:InvalidAlpha0L', ...
        'P.rotor.alpha0L must be a finite real scalar.');
end
if ~(isfinite(referenceRadius) && referenceRadius > 0 && referenceRadius <= 1)
    error('rotor_model_bemt_section_aero:InvalidReferenceRadius', ...
        'compressibilityReferenceRadius must lie in (0,1].');
end
if ~(isfinite(machCap) && machCap > 0 && machCap < 1)
    error('rotor_model_bemt_section_aero:InvalidMachCap', ...
        'compressibilityMachCap must lie in (0,1).');
end
if ~(isfinite(aSound) && aSound > 0)
    error('rotor_model_bemt_section_aero:InvalidSoundSpeed', ...
        'P.env.aSound must be positive and finite.');
end

Pwork = P;
rotorCtrlWork = rotorCtrl;
rotorCtrlWork.collective = rotorCtrl.collective - alpha0L;

referenceMachRaw = abs(P.rotor.Omega*P.rotor.R)*referenceRadius/aSound;
referenceMachUsed = min(referenceMachRaw, machCap);

if enableCompressibility
    liftSlopeFactor = 1/sqrt(max(1-referenceMachUsed^2, 1.0e-8));
else
    liftSlopeFactor = 1.0;
end
Pwork.rotor.liftSlope = P.rotor.liftSlope*liftSlopeFactor;

[Fbody, Mbody, out] = rotor_model_bemt( ...
    x, rotorCtrlWork, betaM, side, cgShift, Pwork);

out.sectionAeroExtension = 'SCALAR_ALPHA0L_EQUIVALENT';
out.sectionAlpha0L = alpha0L;
out.sectionAlpha0LDeg = alpha0L*180/pi;
out.sectionGeometricCollective = rotorCtrl.collective;
out.sectionEffectiveCollective = rotorCtrlWork.collective;
out.compressibilityCorrectionEnabled = enableCompressibility;
out.compressibilityReferenceRadius = referenceRadius;
out.compressibilityReferenceMachRaw = referenceMachRaw;
out.compressibilityReferenceMachUsed = referenceMachUsed;
out.compressibilityMachCap = machCap;
out.sectionLiftSlopeBaseline = P.rotor.liftSlope;
out.sectionLiftSlopeFactor = liftSlopeFactor;
out.sectionLiftSlopeEffective = Pwork.rotor.liftSlope;
end

function value = scalar_field_or_default(S, name, defaultValue)
if isfield(S, name) && ~isempty(S.(name))
    value = S.(name);
else
    value = defaultValue;
end
if ~(isscalar(value) && isnumeric(value))
    error('rotor_model_bemt_section_aero:InvalidScalarField', ...
        '%s must be a numeric scalar.', name);
end
end

function value = logical_field_or_default(S, name, defaultValue)
if isfield(S, name) && ~isempty(S.(name))
    value = S.(name);
else
    value = defaultValue;
end
if ~(isscalar(value) && (islogical(value) || isnumeric(value)))
    error('rotor_model_bemt_section_aero:InvalidLogicalField', ...
        '%s must be a scalar logical/numeric flag.', name);
end
value = logical(value);
end
