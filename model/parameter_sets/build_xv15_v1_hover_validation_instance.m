function [P, mapping] = build_xv15_v1_hover_validation_instance(Pbase, testPoint, sourceData)
%BUILD_XV15_V1_HOVER_VALIDATION_INSTANCE Build a low-order XV-15 V1 instance.
%
% This function does not turn the generic model into an XV-15 model. It
% maps the XV-15 original-metal-blade hover validation configuration into
% the parameter fields that the current low-order production code actually
% reads. Distributed quantities are reduced only through explicit,
% auditable rules. Missing reconstruction inputs remain blockers rather
% than being silently replaced with plausible values.
%
% Inputs
%   Pbase     - base low-order parameter struct. Defaults to params_nominal.
%   testPoint - optional struct. Supported fields:
%                 rpm
%                 rho
%                 theta75_rad or theta75_deg
%   sourceData - optional struct. Supported fields:
%                 chord.rR
%                 chord.chord_m or chord.chord_in
%                 chord.reductionPolicy (optional for diagnostics, required
%                     before hold-out freeze): AREA_PRESERVING,
%                     HOVER_THRUST_R2, or HOVER_TORQUE_R3
%                 twist.rR
%                 twist.theta_rad or twist.theta_deg
%                 twist.weights (optional)
%                 sectionAero.liftSlope
%                 sectionAero.CLmax
%                 sectionAero.CD0
%                 sectionAero.kCD
%                 bladeFirstMassMoment_kgm or Sblade_kgm
%                 Ib_kgm2 (optional; otherwise public 105 slug ft^2 value)
%
% Outputs
%   P        - validation-instance parameter struct. Generic-only fields are
%              preserved unless this mapping explicitly changes them.
%   mapping  - provenance, reduction diagnostics, readiness flags and the
%              converted model collective command when theta_0.75 is given.
%
% V1 hold-out readiness is intentionally strict. A complete validation pack
% requires explicit test-point rho/rpm/theta75, a frozen chord-reduction
% policy, a twist reduction, section-aero reconstruction, and a closed
% Ib/Sblade treatment.

if nargin < 1 || isempty(Pbase)
    Pbase = params_nominal();
end
if nargin < 2 || isempty(testPoint)
    testPoint = struct();
end
if nargin < 3 || isempty(sourceData)
    sourceData = struct();
end

validateattributes(Pbase, {'struct'}, {'scalar'});
validateattributes(testPoint, {'struct'}, {'scalar'});
validateattributes(sourceData, {'struct'}, {'scalar'});

P = Pbase;
d2r = pi/180;
in2m = 0.0254;
slugft2_to_kgm2 = 1.3558179483314004;

% Public XV-15 original-metal-blade reference facts used by the V1 mapping.
% Detailed source/locator/unit records are retained in
% docs/XV15_V1_VALIDATION_INSTANCE.md and the PR #64 evidence registry.
public.R_m = 3.81;
public.Nb = 3;
public.rootCut = 0.0875;
public.referenceHoverRpm = 565;
public.Ib_kgm2 = 105*slugft2_to_kgm2;
public.chord_rR = [0.0875; 0.25; 1.0];
public.chord_in = [17; 14; 14];

mapping = struct();
mapping.stage = 'V1_XV15_ORIGINAL_METAL_BLADE_STEADY_HOVER';
mapping.modelClass = 'GENERIC_LOW_ORDER_MODEL_WITH_STAGE_SPECIFIC_VALIDATION_INSTANCE';
mapping.appliedPaths = {};
mapping.blockingIssues = {};
mapping.evidence = public;
mapping.claimBoundary = [ ...
    'This is a low-order validation mapping, not an XV-15 digital twin. ' ...
    'Distributed geometry and aerodynamics are only applied after an ' ...
    'explicit reduction or reconstruction rule.'];

%% Direct configuration fields: semantics already match production code.
P.rotor.R = public.R_m;
P.rotor.Nb = public.Nb;
P.rotor.rootCut = public.rootCut;
mapping.appliedPaths = append_path(mapping.appliedPaths, 'rotor.R');
mapping.appliedPaths = append_path(mapping.appliedPaths, 'rotor.Nb');
mapping.appliedPaths = append_path(mapping.appliedPaths, 'rotor.rootCut');

%% Test-point rotor speed.
if isfield(testPoint, 'rpm') && is_valid_positive_scalar(testPoint.rpm)
    rpm = testPoint.rpm;
    rpmExplicit = true;
    rpmDisposition = 'TEST_CONDITION_DIRECT_EXPLICIT';
else
    rpm = public.referenceHoverRpm;
    rpmExplicit = false;
    rpmDisposition = 'REFERENCE_HOVER_DEFAULT_NOT_TEST_POINT_CONFIRMED';
end
P.rotor.Omega = rpm*2*pi/60;
mapping.appliedPaths = append_path(mapping.appliedPaths, 'rotor.Omega');
mapping.testCondition.rpm = rpm;
mapping.testCondition.rpmExplicit = rpmExplicit;
mapping.testCondition.rpmDisposition = rpmDisposition;

%% Test-point density. Do not invent a density when the experiment does not
% supply one; retain the base value but mark the hold-out contract incomplete.
if isfield(testPoint, 'rho') && is_valid_positive_scalar(testPoint.rho)
    P.env.rho = testPoint.rho;
    rhoExplicit = true;
    mapping.appliedPaths = append_path(mapping.appliedPaths, 'env.rho');
else
    rhoExplicit = false;
end
mapping.testCondition.rho = P.env.rho;
mapping.testCondition.rhoExplicit = rhoExplicit;

%% Radial chord -> current constant-chord field.
% The production BEMT multiplies chord by local W^2 in both dL and dD and
% multiplies in-plane force by r again for torque. Therefore one constant
% chord cannot simultaneously preserve planform area, hover-force weighting
% and hover-torque weighting. Compute all three geometry-only reductions,
% then require an explicit policy before the final hold-out parameter freeze.
[chordRR, chordM, chordSource] = chord_source(sourceData, public, in2m);
validate_radial_profile(chordRR, chordM, 'chord');
if abs(chordRR(1)-public.rootCut) > 1e-10 || abs(chordRR(end)-1) > 1e-10
    error('build_xv15_v1_hover_validation_instance:ChordCoverage', ...
        'Chord profile must span exactly from rootCut=%.6g to r/R=1.', ...
        public.rootCut);
end

[chordArea, areaNumerator, areaDenominator] = ...
    piecewise_linear_weighted_equivalent(chordRR, chordM, 0);
[chordR2, r2Numerator, r2Denominator] = ...
    piecewise_linear_weighted_equivalent(chordRR, chordM, 2);
[chordR3, r3Numerator, r3Denominator] = ...
    piecewise_linear_weighted_equivalent(chordRR, chordM, 3);
[reductionPolicy, policyExplicit] = chord_reduction_policy(sourceData);

switch reductionPolicy
    case 'AREA_PRESERVING'
        chordEq = chordArea;
    case 'HOVER_THRUST_R2'
        chordEq = chordR2;
    case 'HOVER_TORQUE_R3'
        chordEq = chordR3;
    otherwise
        error('build_xv15_v1_hover_validation_instance:ChordPolicyInternal', ...
            'Unhandled chord-reduction policy: %s', reductionPolicy);
end

P.rotor.chord = chordEq;
mapping.appliedPaths = append_path(mapping.appliedPaths, 'rotor.chord');
mapping.chord.source = chordSource;
mapping.chord.rR = chordRR;
mapping.chord.chord_m = chordM;
mapping.chord.areaPreservingEq_m = chordArea;
mapping.chord.hoverThrustR2Eq_m = chordR2;
mapping.chord.hoverTorqueR3Eq_m = chordR3;
mapping.chord.chordEq_m = chordEq; % backward-compatible selected-value name
mapping.chord.selectedEq_m = chordEq;
mapping.chord.selectedPolicy = reductionPolicy;
mapping.chord.policyExplicit = policyExplicit;
mapping.chord.areaIntegralDistributed_m = areaNumerator;
mapping.chord.areaIntegralEquivalentSelected_m = ...
    chordEq*areaDenominator;
mapping.chord.areaResidualSelected_m = ...
    mapping.chord.areaIntegralEquivalentSelected_m-areaNumerator;
mapping.chord.r2WeightedNumerator = r2Numerator;
mapping.chord.r2WeightDenominator = r2Denominator;
mapping.chord.r3WeightedNumerator = r3Numerator;
mapping.chord.r3WeightDenominator = r3Denominator;
candidates = [chordArea, chordR2, chordR3];
mapping.chord.candidateSpread_m = max(candidates)-min(candidates);
mapping.chord.relativeCandidateSpread = mapping.chord.candidateSpread_m/ ...
    max(abs(chordArea), eps);
mapping.chord.disposition = ['EQUIVALENT_REDUCTION_' reductionPolicy];
if ~policyExplicit
    mapping.blockingIssues{end+1,1} = 'CHORD_REDUCTION_POLICY_NOT_FROZEN';
end

%% Radial twist -> current rootCut-to-tip linear-twist representation.
% Production collective is an absolute pitch offset and the validation
% collective is referenced at 0.75R. Therefore fit the twist SHAPE relative
% to 0.75R directly; this makes the reduction invariant to arbitrary absolute
% pitch offsets in the source profile and makes the reported residual equal
% to the profile error actually used by the collective adapter.
[twistAvailable, twistData] = twist_source(sourceData);
if twistAvailable
    validate_radial_profile(twistData.rR, twistData.thetaRad, 'twist');
    if any(twistData.rR < public.rootCut-1e-12) || ...
            any(twistData.rR > 1+1e-12)
        error('build_xv15_v1_hover_validation_instance:TwistRange', ...
            'Twist stations must lie within rootCut <= r/R <= 1.');
    end

    spanCoversRootToTip = ...
        min(twistData.rR) <= public.rootCut+1e-10 && ...
        max(twistData.rR) >= 1-1e-10;
    if min(twistData.rR) > 0.75 || max(twistData.rR) < 0.75
        error('build_xv15_v1_hover_validation_instance:TwistReferenceCoverage', ...
            'Twist profile must cover r/R=0.75 for the collective-reference mapping.');
    end

    x = (twistData.rR-public.rootCut)/(1-public.rootCut);
    x75 = (0.75-public.rootCut)/(1-public.rootCut);
    theta75Source = interp1(twistData.rR, twistData.thetaRad, 0.75, 'linear');
    dx = x-x75;
    dtheta = twistData.thetaRad-theta75Source;
    denominator = sum(twistData.weights.*dx.^2);
    if ~(isfinite(denominator) && denominator > 0)
        error('build_xv15_v1_hover_validation_instance:TwistFitDegenerate', ...
            'Twist stations do not provide a valid slope about r/R=0.75.');
    end
    twistTipEq = sum(twistData.weights.*dx.*dtheta)/denominator;
    thetaFit = theta75Source+twistTipEq*dx;
    residual = twistData.thetaRad-thetaFit;
    weightedRms = sqrt(sum(twistData.weights.*residual.^2)/ ...
        sum(twistData.weights));

    P.rotor.twistTip = twistTipEq;
    mapping.appliedPaths = append_path(mapping.appliedPaths, 'rotor.twistTip');
    mapping.twist.available = true;
    mapping.twist.rR = twistData.rR;
    mapping.twist.thetaSource_rad = twistData.thetaRad;
    mapping.twist.thetaFit_rad = thetaFit;
    mapping.twist.residual_rad = residual;
    mapping.twist.weights = twistData.weights;
    mapping.twist.theta75Source_rad = theta75Source;
    mapping.twist.rootReferenceFromSourceFit_rad = ...
        theta75Source-twistTipEq*x75;
    mapping.twist.twistTipEq_rad = twistTipEq;
    mapping.twist.rmsResidual_rad = sqrt(mean(residual.^2));
    mapping.twist.weightedRmsResidual_rad = weightedRms;
    mapping.twist.maxAbsResidual_rad = max(abs(residual));
    mapping.twist.spanCoversRootToTip = spanCoversRootToTip;
    mapping.twist.disposition = ...
        'EQUIVALENT_REDUCTION_LINEAR_SHAPE_FIT_ANCHORED_AT_075R';
else
    mapping.twist.available = false;
    mapping.twist.twistTipEq_rad = NaN;
    mapping.twist.rmsResidual_rad = NaN;
    mapping.twist.weightedRmsResidual_rad = NaN;
    mapping.twist.maxAbsResidual_rad = NaN;
    mapping.twist.spanCoversRootToTip = false;
    mapping.twist.disposition = 'BLOCKED_SOURCE_RADIAL_TWIST_REQUIRED';
    mapping.blockingIssues{end+1,1} = 'RADIAL_TWIST_RECONSTRUCTION_REQUIRED';
end

%% theta_0.75 test definition -> production-model collective definition.
[theta75Available, theta75Rad, theta75Disposition] = theta75_source(testPoint, d2r);
mapping.collective.theta75Available = theta75Available;
mapping.collective.theta75_rad = theta75Rad;
mapping.collective.theta75Disposition = theta75Disposition;
if theta75Available && mapping.twist.available
    x75 = (0.75-public.rootCut)/(1-public.rootCut);
    collectiveModel = theta75Rad-P.rotor.twistTip*x75;
    theta75Reconstructed = collectiveModel+P.rotor.twistTip*x75;
    mapping.collective.x75 = x75;
    mapping.collective.modelCollective_rad = collectiveModel;
    mapping.collective.theta75Reconstructed_rad = theta75Reconstructed;
    mapping.collective.reconstructionError_rad = ...
        theta75Reconstructed-theta75Rad;
    mapping.collective.disposition = ...
        'VALIDATION_INPUT_ADAPTER_THETA75_TO_MODEL_ROOTCUT_REFERENCE';
else
    mapping.collective.modelCollective_rad = NaN;
    mapping.collective.theta75Reconstructed_rad = NaN;
    mapping.collective.reconstructionError_rad = NaN;
    mapping.collective.disposition = 'BLOCKED_UNTIL_THETA75_AND_TWIST_ARE_AVAILABLE';
    if ~theta75Available
        mapping.blockingIssues{end+1,1} = 'TEST_POINT_THETA75_REQUIRED';
    end
end

%% Section-aero reconstruction. These four fields are exactly what the
% current BEMT consumes, so only a complete reconstructed set is applied.
[aeroAvailable, aero] = section_aero_source(sourceData);
if aeroAvailable
    P.rotor.liftSlope = aero.liftSlope;
    P.rotor.CLmax = aero.CLmax;
    P.rotor.CD0 = aero.CD0;
    P.rotor.kCD = aero.kCD;
    mapping.appliedPaths = append_path(mapping.appliedPaths, 'rotor.liftSlope');
    mapping.appliedPaths = append_path(mapping.appliedPaths, 'rotor.CLmax');
    mapping.appliedPaths = append_path(mapping.appliedPaths, 'rotor.CD0');
    mapping.appliedPaths = append_path(mapping.appliedPaths, 'rotor.kCD');
    mapping.sectionAero = aero;
    mapping.sectionAero.available = true;
    mapping.sectionAero.disposition = 'AERO_RECONSTRUCTION_APPLIED';
else
    mapping.sectionAero.available = false;
    mapping.sectionAero.disposition = 'BLOCKED_SECTION_AERO_RECONSTRUCTION_REQUIRED';
    mapping.blockingIssues{end+1,1} = 'SECTION_AERO_RECONSTRUCTION_REQUIRED';
end

%% Coupled flapping mass-property closure.
% Do not apply the public Ib by itself. It is only activated together with
% a supplied first blade-mass moment Sblade used by the same flap residual.
SbladeAvailable = false;
Sblade = NaN;
if isfield(sourceData, 'bladeFirstMassMoment_kgm') && ...
        is_valid_positive_scalar(sourceData.bladeFirstMassMoment_kgm)
    Sblade = sourceData.bladeFirstMassMoment_kgm;
    SbladeAvailable = true;
elseif isfield(sourceData, 'Sblade_kgm') && ...
        is_valid_positive_scalar(sourceData.Sblade_kgm)
    Sblade = sourceData.Sblade_kgm;
    SbladeAvailable = true;
end

IbToApply = public.Ib_kgm2;
IbSource = 'PUBLIC_XV15_105_SLUG_FT2';
if isfield(sourceData, 'Ib_kgm2') && is_valid_positive_scalar(sourceData.Ib_kgm2)
    IbToApply = sourceData.Ib_kgm2;
    IbSource = 'EXPLICIT_SOURCE_DATA';
end

mapping.flapMass.publicIbEvidence_kgm2 = public.Ib_kgm2;
mapping.flapMass.IbCandidate_kgm2 = IbToApply;
mapping.flapMass.IbSource = IbSource;
mapping.flapMass.Sblade_kgm = Sblade;
if SbladeAvailable
    P.rotor.Ib = IbToApply;
    P.rotor.Sblade = Sblade;
    mapping.appliedPaths = append_path(mapping.appliedPaths, 'rotor.Ib');
    mapping.appliedPaths = append_path(mapping.appliedPaths, 'rotor.Sblade');
    mapping.flapMass.closed = true;
    mapping.flapMass.disposition = 'COUPLED_RECONSTRUCTION_APPLIED';
else
    mapping.flapMass.closed = false;
    mapping.flapMass.disposition = 'BLOCKED_DO_NOT_APPLY_IB_IN_ISOLATION';
    mapping.blockingIssues{end+1,1} = 'IB_SBLADE_COUPLED_RECONSTRUCTION_REQUIRED';
end

%% Readiness contract.
mapping.readiness.directGeometry = true;
mapping.readiness.chordReduction = all(isfinite(candidates)) && all(candidates > 0);
mapping.readiness.chordPolicyFrozen = policyExplicit;
mapping.readiness.twistReduction = mapping.twist.available && ...
    mapping.twist.spanCoversRootToTip;
mapping.readiness.testPointRpm = rpmExplicit;
mapping.readiness.testPointRho = rhoExplicit;
mapping.readiness.collectiveAdapter = theta75Available && mapping.twist.available;
mapping.readiness.sectionAero = aeroAvailable;
mapping.readiness.flapMassClosure = mapping.flapMass.closed;
mapping.readiness.readyForMappingDiagnostics = ...
    mapping.readiness.directGeometry && mapping.readiness.chordReduction;
mapping.readiness.readyForHoldout = ...
    mapping.readiness.directGeometry && ...
    mapping.readiness.chordReduction && ...
    mapping.readiness.chordPolicyFrozen && ...
    mapping.readiness.twistReduction && ...
    mapping.readiness.testPointRpm && ...
    mapping.readiness.testPointRho && ...
    mapping.readiness.collectiveAdapter && ...
    mapping.readiness.sectionAero && ...
    mapping.readiness.flapMassClosure;

if mapping.readiness.readyForHoldout
    mapping.variantName = 'XV15_V1_HOVER_VALIDATION_INSTANCE_READY';
else
    mapping.variantName = 'XV15_V1_HOVER_VALIDATION_INSTANCE_INCOMPLETE';
end

mapping.appliedPaths = unique(mapping.appliedPaths, 'stable');
mapping.blockingIssues = unique(mapping.blockingIssues, 'stable');
end

function [rR, chordM, source] = chord_source(sourceData, public, in2m)
if isfield(sourceData, 'chord') && isstruct(sourceData.chord) && ...
        isfield(sourceData.chord, 'rR')
    rR = sourceData.chord.rR(:);
    if isfield(sourceData.chord, 'chord_m')
        chordM = sourceData.chord.chord_m(:);
        source = 'EXPLICIT_SOURCE_DATA_CHORD_M';
    elseif isfield(sourceData.chord, 'chord_in')
        chordM = sourceData.chord.chord_in(:)*in2m;
        source = 'EXPLICIT_SOURCE_DATA_CHORD_IN';
    else
        error('build_xv15_v1_hover_validation_instance:ChordValuesMissing', ...
            'sourceData.chord requires chord_m or chord_in.');
    end
else
    rR = public.chord_rR;
    chordM = public.chord_in*in2m;
    source = 'PUBLIC_XV15_ROOT_TAPER_PIECEWISE_RECONSTRUCTION';
end
end

function [policy, explicit] = chord_reduction_policy(sourceData)
policy = 'AREA_PRESERVING';
explicit = false;
if isfield(sourceData, 'chord') && isstruct(sourceData.chord) && ...
        isfield(sourceData.chord, 'reductionPolicy')
    raw = sourceData.chord.reductionPolicy;
    if isstring(raw) && isscalar(raw)
        raw = char(raw);
    end
    if ~ischar(raw)
        error('build_xv15_v1_hover_validation_instance:ChordPolicyType', ...
            'chord.reductionPolicy must be a character vector or scalar string.');
    end
    policy = upper(strtrim(raw));
    explicit = true;
end
allowed = {'AREA_PRESERVING','HOVER_THRUST_R2','HOVER_TORQUE_R3'};
if ~any(strcmp(policy, allowed))
    error('build_xv15_v1_hover_validation_instance:ChordPolicy', ...
        'Unsupported chord-reduction policy: %s', policy);
end
end

function [ceq, numerator, denominator] = ...
        piecewise_linear_weighted_equivalent(rR, chordM, power)
% Exact integral for a piecewise-linear chord profile times (r/R)^power.
numerator = 0;
denominator = 0;
for k = 1:numel(rR)-1
    r1 = rR(k);
    r2 = rR(k+1);
    c1 = chordM(k);
    c2 = chordM(k+1);
    slope = (c2-c1)/(r2-r1);
    intercept = c1-slope*r1;
    numerator = numerator + ...
        intercept*(r2^(power+1)-r1^(power+1))/(power+1) + ...
        slope*(r2^(power+2)-r1^(power+2))/(power+2);
    denominator = denominator + ...
        (r2^(power+1)-r1^(power+1))/(power+1);
end
if ~(isfinite(denominator) && denominator > 0)
    error('build_xv15_v1_hover_validation_instance:ChordWeightDegenerate', ...
        'Chord weighting integral is not positive and finite.');
end
ceq = numerator/denominator;
end

function [available, data] = twist_source(sourceData)
available = false;
data = struct('rR',[],'thetaRad',[],'weights',[]);
if ~isfield(sourceData, 'twist') || ~isstruct(sourceData.twist) || ...
        ~isfield(sourceData.twist, 'rR')
    return;
end

data.rR = sourceData.twist.rR(:);
if isfield(sourceData.twist, 'theta_rad')
    data.thetaRad = sourceData.twist.theta_rad(:);
elseif isfield(sourceData.twist, 'theta_deg')
    data.thetaRad = sourceData.twist.theta_deg(:)*pi/180;
else
    return;
end
if isfield(sourceData.twist, 'weights')
    data.weights = sourceData.twist.weights(:);
else
    data.weights = ones(size(data.rR));
end
if numel(data.weights) ~= numel(data.rR) || ...
        any(~isfinite(data.weights)) || any(data.weights <= 0)
    error('build_xv15_v1_hover_validation_instance:InvalidTwistWeights', ...
        'Twist weights must be finite, positive and match the station count.');
end
available = true;
end

function [available, theta75Rad, disposition] = theta75_source(testPoint, d2r)
available = false;
theta75Rad = NaN;
disposition = 'NOT_SUPPLIED';
if isfield(testPoint, 'theta75_rad') && is_valid_finite_scalar(testPoint.theta75_rad)
    available = true;
    theta75Rad = testPoint.theta75_rad;
    disposition = 'TEST_INPUT_DIRECT_RAD';
elseif isfield(testPoint, 'theta75_deg') && is_valid_finite_scalar(testPoint.theta75_deg)
    available = true;
    theta75Rad = testPoint.theta75_deg*d2r;
    disposition = 'TEST_INPUT_DIRECT_DEG_CONVERTED_TO_RAD';
end
end

function [available, aero] = section_aero_source(sourceData)
aero = struct();
available = false;
if ~isfield(sourceData, 'sectionAero') || ~isstruct(sourceData.sectionAero)
    return;
end
required = {'liftSlope','CLmax','CD0','kCD'};
for k = 1:numel(required)
    name = required{k};
    if ~isfield(sourceData.sectionAero, name) || ...
            ~is_valid_finite_scalar(sourceData.sectionAero.(name))
        return;
    end
    aero.(name) = sourceData.sectionAero.(name);
end
if aero.liftSlope <= 0 || aero.CLmax <= 0 || aero.CD0 < 0 || aero.kCD < 0
    error('build_xv15_v1_hover_validation_instance:InvalidSectionAero', ...
        'Section-aero equivalent parameters must satisfy physical sign constraints.');
end
available = true;
end

function validate_radial_profile(rR, values, label)
if numel(rR) ~= numel(values) || numel(rR) < 2
    error('build_xv15_v1_hover_validation_instance:ProfileSize', ...
        '%s profile must contain at least two matched stations.', label);
end
if any(~isfinite(rR)) || any(~isfinite(values)) || any(diff(rR) <= 0)
    error('build_xv15_v1_hover_validation_instance:ProfileInvalid', ...
        '%s radial stations/values must be finite and strictly increasing.', label);
end
end

function tf = is_valid_positive_scalar(value)
tf = isnumeric(value) && isscalar(value) && isreal(value) && ...
    isfinite(value) && value > 0;
end

function tf = is_valid_finite_scalar(value)
tf = isnumeric(value) && isscalar(value) && isreal(value) && isfinite(value);
end

function paths = append_path(paths, path)
paths{end+1,1} = path;
end
