function P = stage2_matched_rotor_parameters()
%STAGE2_MATCHED_ROTOR_PARAMETERS Common rotor/aircraft parameter base.
%
% The whole-aircraft M0/M1 propagation comparison must not change radius,
% root cut, RPM, mass, atmosphere, hub geometry, or numerical tolerances
% between variants.  This helper maps the frozen XV-15 M0 validation-instance
% rotor geometry reduction into the otherwise unchanged generic conceptual
% aircraft parameter set.  M1 replaces only the frozen evidence-package
% rotor representation inside its analysis-only rotor backend.

P = params_nominal();
R = 3.81;
rootCut = 0.0875;

P.rotor.R = R;
P.rotor.Nb = 3;
P.rotor.rootCut = rootCut;

% Exact equivalent constant-chord / linear-twist reduction used by the
% frozen M0 XV-15 hover validation mapping.
xGeom = linspace(rootCut,1,4001).';
chordIn = 14*ones(size(xGeom));
inboard = xGeom <= 0.25;
chordIn(inboard) = -18.4615*xGeom(inboard) + 18.6154;
P.rotor.chord = trapz(xGeom,chordIn)/(1-rootCut)*0.0254;

thetaSourceDeg = nasa_metal_twist_deg(xGeom);
theta75SourceDeg = nasa_metal_twist_deg(0.75);
xNorm = (xGeom-rootCut)/(1-rootCut);
x75 = (0.75-rootCut)/(1-rootCut);
shapeCoordinate = xNorm-x75;
shapeTarget = thetaSourceDeg-theta75SourceDeg;
twistTipEqDeg = trapz(xGeom,shapeCoordinate.*shapeTarget) / ...
    trapz(xGeom,shapeCoordinate.^2);
P.rotor.twistTip = twistTipEqDeg*pi/180;

P.rotor.Ib = P.rotor.bladeMass*R^2/3;
P.rotor.Sblade = P.rotor.bladeMass*R/2;
if ~isfield(P.env,'aSound') || isempty(P.env.aSound)
    P.env.aSound = 340.0;
end

P.stage2RotorMapping = struct();
P.stage2RotorMapping.role = 'MATCHED_M0_M1_PROPAGATION_PARAMETER_BASE';
P.stage2RotorMapping.R_m = R;
P.stage2RotorMapping.rootCut = rootCut;
P.stage2RotorMapping.chordEquivalent_m = P.rotor.chord;
P.stage2RotorMapping.twistTipEquivalent_deg = twistTipEqDeg;
P.stage2RotorMapping.theta75LinearFraction = x75;
P.stage2RotorMapping.rpmRole = ...
    'COMMON_GENERIC_AIRCRAFT_OMEGA_UNCHANGED_BETWEEN_M0_AND_M1';
P.stage2RotorMapping.claimBoundary = [ ...
    'VALIDATION_INSTANCE_ROTOR_MAPPING_ON_GENERIC_CONCEPT_AIRFRAME_' ...
    'NOT_XV15_FULL_AIRCRAFT_MODEL'];
end
