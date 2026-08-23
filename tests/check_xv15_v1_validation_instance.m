function summary = check_xv15_v1_validation_instance()
%CHECK_XV15_V1_VALIDATION_INSTANCE Software-contract checks for V1 mapping.
%
% These checks verify parameter transformation semantics only.  Synthetic
% twist/aero/mass inputs below are deliberately not XV-15 validation data
% and must never be reported as physical validation evidence.

P0 = params_nominal();
publicIb = 105*1.3558179483314004;
expectedChordEq = 0.3623849315068493;
d2r = pi/180;

%% Partial/default instance: only mappings supported by public facts apply.
[Ppartial, partial] = build_xv15_v1_hover_validation_instance(P0);
assert(abs(Ppartial.rotor.R-3.81) < 1e-12, ...
    'V1 direct rotor radius mapping failed.');
assert(Ppartial.rotor.Nb == 3, ...
    'V1 blade-count mapping failed.');
assert(abs(Ppartial.rotor.rootCut-0.0875) < 1e-12, ...
    'V1 root-cut mapping failed.');
assert(abs(Ppartial.rotor.Omega-565*2*pi/60) < 1e-12, ...
    'Reference hover RPM default was not mapped correctly.');
assert(~partial.testCondition.rpmExplicit, ...
    'Default 565 rpm must not be labelled a confirmed test-point input.');
assert(~partial.testCondition.rhoExplicit, ...
    'Base density must not be labelled a confirmed test-point input.');
assert(abs(Ppartial.rotor.chord-expectedChordEq) < 1e-12, ...
    'Area-preserving equivalent chord is incorrect.');
assert(partial.chord.relativeAreaResidual < 1e-12, ...
    'Equivalent chord must preserve the source planform integral.');

% Missing radial twist must not overwrite the generic linear-twist field.
assert(~partial.twist.available, ...
    'Default V1 builder should remain blocked without radial twist source data.');
assert(isequal(Ppartial.rotor.twistTip, P0.rotor.twistTip), ...
    'Generic twist field must remain untouched when twist reconstruction is absent.');

% Public Ib evidence must not be activated in isolation from Sblade closure.
assert(~partial.flapMass.closed, ...
    'Default V1 builder must report unresolved Ib/Sblade closure.');
assert(isequal(Ppartial.rotor.Ib, P0.rotor.Ib), ...
    'Public Ib must not be applied without a coupled Sblade reconstruction.');
assert(abs(partial.flapMass.publicIbEvidence_kgm2-publicIb) < 1e-10, ...
    'Public Ib evidence was not retained in mapping diagnostics.');
assert(~partial.readiness.readyForHoldout, ...
    'Incomplete mapping must never be declared hold-out ready.');

expectedBlockers = { ...
    'RADIAL_TWIST_RECONSTRUCTION_REQUIRED'; ...
    'TEST_POINT_THETA75_REQUIRED'; ...
    'SECTION_AERO_RECONSTRUCTION_REQUIRED'; ...
    'IB_SBLADE_COUPLED_RECONSTRUCTION_REQUIRED'};
for k = 1:numel(expectedBlockers)
    assert(any(strcmp(partial.blockingIssues, expectedBlockers{k})), ...
        'Missing expected V1 blocker: %s', expectedBlockers{k});
end

%% Complete synthetic contract: verify transformations algebraically.
rootCut = 0.0875;
rR = [rootCut; 0.25; 0.50; 0.75; 1.0];
x = (rR-rootCut)/(1-rootCut);
syntheticRootPitch = 22*d2r;
syntheticTwistTip = -40*d2r;
thetaRad = syntheticRootPitch + syntheticTwistTip*x;
x75 = (0.75-rootCut)/(1-rootCut);
theta75 = syntheticRootPitch + syntheticTwistTip*x75;

testPoint.rpm = 565;
testPoint.rho = 1.18;
testPoint.theta75_rad = theta75;

sourceData.twist.rR = rR;
sourceData.twist.theta_rad = thetaRad;
sourceData.sectionAero.liftSlope = 5.9;
sourceData.sectionAero.CLmax = 1.40;
sourceData.sectionAero.CD0 = 0.010;
sourceData.sectionAero.kCD = 0.015;
sourceData.Sblade_kgm = 80.0;

[Pcomplete, complete] = build_xv15_v1_hover_validation_instance( ...
    P0, testPoint, sourceData);

assert(abs(Pcomplete.rotor.twistTip-syntheticTwistTip) < 1e-12, ...
    'Linear synthetic twist should be recovered exactly.');
assert(complete.twist.rmsResidual_rad < 1e-12, ...
    'Exact linear synthetic twist should have negligible fit residual.');
assert(complete.twist.maxAbsResidual_rad < 1e-12, ...
    'Exact linear synthetic twist should have negligible max residual.');
assert(abs(complete.collective.modelCollective_rad-syntheticRootPitch) < 1e-12, ...
    'theta75 adapter did not recover the production root-reference collective.');
assert(abs(complete.collective.reconstructionError_rad) < 1e-12, ...
    'theta75 adapter must reconstruct its input exactly for the fitted law.');

assert(abs(Pcomplete.env.rho-testPoint.rho) < 1e-12, ...
    'Explicit test density was not applied.');
assert(abs(Pcomplete.rotor.Omega-testPoint.rpm*2*pi/60) < 1e-12, ...
    'Explicit test RPM was not applied.');
assert(complete.testCondition.rpmExplicit && complete.testCondition.rhoExplicit, ...
    'Explicit test conditions were not marked correctly.');

assert(abs(Pcomplete.rotor.liftSlope-sourceData.sectionAero.liftSlope) < 1e-12, ...
    'Section-aero liftSlope mapping failed.');
assert(abs(Pcomplete.rotor.CLmax-sourceData.sectionAero.CLmax) < 1e-12, ...
    'Section-aero CLmax mapping failed.');
assert(abs(Pcomplete.rotor.CD0-sourceData.sectionAero.CD0) < 1e-12, ...
    'Section-aero CD0 mapping failed.');
assert(abs(Pcomplete.rotor.kCD-sourceData.sectionAero.kCD) < 1e-12, ...
    'Section-aero kCD mapping failed.');

assert(abs(Pcomplete.rotor.Ib-publicIb) < 1e-10, ...
    'Public Ib should apply once the Sblade closure input is supplied.');
assert(abs(Pcomplete.rotor.Sblade-sourceData.Sblade_kgm) < 1e-12, ...
    'Sblade coupled mapping failed.');
assert(complete.flapMass.closed, ...
    'Complete synthetic contract should close Ib/Sblade.');
assert(complete.readiness.readyForHoldout, ...
    'Complete synthetic software contract should satisfy readiness gates.');
assert(isempty(complete.blockingIssues), ...
    'Complete synthetic software contract should have no mapping blockers.');

% Builder must preserve the current low-order model form: no radial geometry
% or aero-table fields are added to the production parameter struct.
assert(~isfield(Pcomplete.rotor, 'radial'), ...
    'V1 mapping must not silently upgrade the rotor model form.');
assert(~isfield(Pcomplete.rotor, 'aeroTables'), ...
    'V1 mapping must not silently add high-order rotor aero tables.');

summary = struct();
summary.allPassed = true;
summary.expectedChordEq_m = expectedChordEq;
summary.publicIb_kgm2 = publicIb;
summary.partialReadyForHoldout = partial.readiness.readyForHoldout;
summary.completeSyntheticReadyForHoldout = complete.readiness.readyForHoldout;
summary.claimBoundary = 'SOFTWARE_CONTRACT_TEST_ONLY_NOT_PHYSICAL_VALIDATION';
end
