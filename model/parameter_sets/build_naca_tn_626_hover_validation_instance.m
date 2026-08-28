function [P, mapping] = build_naca_tn_626_hover_validation_instance(Pbase, thetaDeg)
%BUILD_NACA_TN_626_HOVER_VALIDATION_INSTANCE Frozen simple-rotor mapping.
%
% Maps the four-blade, untwisted NACA 0015 rotor in NACA TN 626 into
% fields already consumed by the current low-order rotor model. No
% production equation is changed and no parameter is fitted to Table III.

if nargin < 1 || isempty(Pbase)
    Pbase = params_nominal();
end
if nargin < 2
    error('build_naca_tn_626_hover_validation_instance:ThetaRequired', ...
        'A blade-incidence angle in degrees is required.');
end

validateattributes(Pbase, {'struct'}, {'scalar'});
validateattributes(thetaDeg, {'numeric'}, ...
    {'real','finite','scalar','>=',0,'<=',12});

P = Pbase;
in2m = 0.0254;
ft2m = 0.3048;
rpm2rads = 2*pi/60;

% Direct experimental configuration and documented low-order reductions.
P.rotor.R = 2.5*ft2m;
P.rotor.Nb = 4;
P.rotor.Omega = 960*rpm2rads;
P.rotor.chord = 2*in2m;
P.rotor.rootCut = 5/30;
P.rotor.twistTip = 0;

% Same-report NACA 0015 reduction, independent of rotor Table III targets.
liftSlope = 5.75;
dragAlphaCoefficient = 0.75;
clPeakMagnitudes = [0.906, 0.948, 0.955, 0.910];
P.rotor.alpha0L = 0;
P.rotor.liftSlope = liftSlope;
P.rotor.CLmax = mean(clPeakMagnitudes);
P.rotor.CD0 = 0.0113;
P.rotor.kCD = dragAlphaCoefficient/liftSlope^2;
P.rotor.enableCompressibilityCorrection = false;

% TN 626 does not report blade mass properties. Preserve the generic
% single-blade mass only as a declared numerical placeholder and restore
% the existing uniform-mass derivation after changing radius.
P.rotor.Ib = P.rotor.bladeMass*P.rotor.R^2/3;
P.rotor.Sblade = P.rotor.bladeMass*P.rotor.R/2;

% Density is unavailable in the report. It cancels from the present
% incompressible hover coefficients, so retain and label the base value.
P.env.rho = Pbase.env.rho;

mapping = struct();
mapping.freezeId = 'NACA_TN626_FOUR_BLADE_SIMPLE_HOVER_V1_20260828';
mapping.sourceReport = 'NACA_TN_626';
mapping.sourceRecord = 'NASA_NTRS_19930081433';
mapping.claimBoundary = ...
    'SIMPLE_ISOLATED_ROTOR_CORE_COMPARISON_NOT_TEST_RIG_REPRODUCTION';
mapping.collective.modelCollective_rad = thetaDeg*pi/180;
mapping.collective.reportIncidence_deg = thetaDeg;
mapping.collective.referenceDisposition = ...
    'ASSUMED_ZERO_THRUST_TO_SYMMETRIC_ZERO_LIFT_ALIGNMENT';
mapping.geometry.R_m = P.rotor.R;
mapping.geometry.Nb = P.rotor.Nb;
mapping.geometry.chord_m = P.rotor.chord;
mapping.geometry.rootCut = P.rotor.rootCut;
mapping.geometry.twistTip_rad = P.rotor.twistTip;
mapping.geometry.rootDisposition = ...
    'OMIT_INBOARD_FAIRING_INSIDE_FIVE_INCH_RADIUS';
mapping.testCondition.rpm = 960;
mapping.testCondition.rpmDisposition = ...
    'REPORTED_APPROXIMATE_AVERAGE';
mapping.testCondition.rho_kgm3 = P.env.rho;
mapping.testCondition.rhoDisposition = ...
    'ASSUMED_DIMENSIONLESS_INVARIANT_IN_CURRENT_MODEL';
mapping.sectionAero.alpha0L_rad = P.rotor.alpha0L;
mapping.sectionAero.liftSlope_perRad = P.rotor.liftSlope;
mapping.sectionAero.CLmax = P.rotor.CLmax;
mapping.sectionAero.CD0 = P.rotor.CD0;
mapping.sectionAero.dragAlphaCoefficient = dragAlphaCoefficient;
mapping.sectionAero.kCD = P.rotor.kCD;
mapping.flapMass.bladeMass_kg = P.rotor.bladeMass;
mapping.flapMass.Ib_kgm2 = P.rotor.Ib;
mapping.flapMass.Sblade_kgm = P.rotor.Sblade;
mapping.flapMass.disposition = ...
    'GENERIC_PLACEHOLDER_REDERIVED_FOR_RADIUS_NOT_TN626_DATA';
mapping.initialization.aircraftMass_kg = P.mass.m;
mapping.initialization.disposition = ...
    'INHERITED_GENERIC_MASS_USED_ONLY_FOR_INDUCED_VELOCITY_INITIAL_GUESS';
mapping.numerics.nRadial = P.rotor.nRadial;
mapping.numerics.nAzimuth = P.rotor.nAzimuth;
mapping.numerics.inducedMaxIter = P.rotor.inducedMaxIter;
mapping.numerics.inducedTol = P.rotor.inducedTol;
mapping.coefficientConversion.reportToStandardFactor = 0.5;
mapping.readiness.directOuterGeometry = true;
mapping.readiness.untwistedBlade = true;
mapping.readiness.independentSectionAero = true;
mapping.readiness.fixedCollectiveAdapter = true;
mapping.readiness.targetsUsedInMapping = false;
mapping.readiness.readyForSimpleComparison = true;
end
