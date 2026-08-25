function result = run_xv15_mass_property_single_factor(outputDir)
%RUN_XV15_MASS_PROPERTY_SINGLE_FACTOR One-point mass-property check.
%
% This diagnostic changes only the coupled blade mass-property pack used by
% the existing steady first-harmonic flap solve. It does not change any
% production equation, add a model variant, scan a parameter, or use an
% OARF performance target. The 10-deg point is a single representative
% point inside the supported 6-to-11-deg window. A paired call is required
% because the current first-harmonic hover inflow can couple periodic flap
% motion back into the blade-element angle of attack.

rootDir = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1 || isempty(outputDir)
    outputDir = fullfile(rootDir, 'results', ...
        'xv15_source_contract_closure');
end
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

checkId = 'XV15_MASS_PROPERTY_SINGLE_FACTOR_20260825';
d2r = pi/180;
R_m = 3.81;
R_ft = 12.5;
theta75_deg = 10;
Vtip_fps = 768.0;
Vtip_mps = Vtip_fps*0.3048;

%% Source mass distribution: NASA TP-2004-212262, Appendix A, pp. 22-25.
% The integrated total is an equivalent model-deck mass, not a direct
% weighing result, because the root node contains a concentrated model term.
rR = (0:0.02:1).';
massDensity_slugPerFt = [ ...
    4.513; 0.638; 0.807; 1.032; 1.192; 1.156; 1.120; 0.853; ...
    0.508; 0.246; 0.231; 0.216; 0.208; 0.202; 0.195; 0.184; ...
    0.174; 0.164; 0.153; 0.146; 0.152; 0.157; 0.171; 0.189; ...
    0.201; 0.197; 0.193; 0.189; 0.186; 0.182; 0.179; 0.175; ...
    0.171; 0.168; 0.164; 0.161; 0.157; 0.154; 0.150; 0.147; ...
    0.143; 0.140; 0.136; 0.132; 0.129; 0.125; 0.122; 0.133; ...
    0.149; 0.161; 0.161];
r_ft = rR*R_ft;
bladeMass_slug = trapz(r_ft, massDensity_slugPerFt);
Sblade_slugFt = trapz(r_ft, massDensity_slugPerFt.*r_ft);
IbIntegrated_slugFt2 = trapz( ...
    r_ft, massDensity_slugPerFt.*r_ft.^2);

slug_to_kg = 14.5939029372064;
ft_to_m = 0.3048;
slugFt2_to_kgm2 = slug_to_kg*ft_to_m^2;
bladeMass_kg = bladeMass_slug*slug_to_kg;
Sblade_kgm = Sblade_slugFt*slug_to_kg*ft_to_m;
IbIntegrated_kgm2 = IbIntegrated_slugFt2*slugFt2_to_kgm2;

% Use the directly tabulated per-blade flapping inertia from NASA
% CR-114626 Table III-1 and CR-2017-219486 Table A-1 as Ib. The independently
% integrated distribution is retained as a consistency check.
IbDirect_slugFt2 = 105;
IbDirect_kgm2 = IbDirect_slugFt2*slugFt2_to_kgm2;
IbIntegrationDifference_pct = 100*( ...
    IbIntegrated_kgm2-IbDirect_kgm2)/IbDirect_kgm2;

%% Reproduce the frozen low-order input mapping at one supported point.
Pbase = params_nominal();
rootCut = 0.0875;
xGeom = linspace(rootCut, 1, 4001).';
twistWeights = ones(size(xGeom));
twistWeights([1 end]) = 0.5;

c81 = build_xv15_c81_low_order_section_aero();
sourceData = struct();
sourceData.chord.reductionPolicy = 'AREA_PRESERVING';
sourceData.twist.rR = xGeom;
sourceData.twist.theta_deg = nasa_metal_twist_deg(xGeom);
sourceData.twist.weights = twistWeights;
sourceData.bladeFirstMassMoment_kgm = Sblade_kgm;
sourceData.Ib_kgm2 = IbDirect_kgm2;

testPoint = struct();
testPoint.rpm = Vtip_mps/R_m*60/(2*pi);
testPoint.rho = 1.225;
testPoint.theta75_deg = theta75_deg;
[Psource, mapping] = build_xv15_v1_hover_validation_instance( ...
    Pbase, testPoint, sourceData);
if ~mapping.readiness.flapMassClosure
    error('run_xv15_mass_property_single_factor:MassPackNotClosed', ...
        'The source-based Ib/Sblade pack was not applied as a coupled set.');
end

Psource.rotor.bladeMass = bladeMass_kg;
Psource = apply_section_aero(Psource, c81);
Pgeneric = Psource;
Pgeneric.rotor.bladeMass = 45;
Pgeneric.rotor.Ib = 45*R_m^2/3;
Pgeneric.rotor.Sblade = 45*R_m/2;

ctrl = struct('collective', mapping.collective.modelCollective_rad, ...
    'cyclicLong', 0);
[~, ~, outGeneric] = rotor_model_bemt_section_aero( ...
    zeros(9,1), ctrl, 0, -1, zeros(3,1), Pgeneric);
[~, ~, outSource] = rotor_model_bemt_section_aero( ...
    zeros(9,1), ctrl, 0, -1, zeros(3,1), Psource);
if ~(outGeneric.physicalConverged && outSource.physicalConverged)
    error('run_xv15_mass_property_single_factor:NotPhysical', ...
        'Both paired calls must physically converge.');
end

generic = hover_metrics(outGeneric, Pgeneric, Vtip_mps);
source = hover_metrics(outSource, Psource, Vtip_mps);
CTRelativeChange_pct = relative_change_pct(source.CT, generic.CT);
CPRelativeChange_pct = relative_change_pct(source.CP, generic.CP);
FMRelativeChange_pct = relative_change_pct(source.FM, generic.FM);
thrustRelativeChange_pct = relative_change_pct( ...
    outSource.thrust, outGeneric.thrust);
torqueRelativeChange_pct = relative_change_pct( ...
    outSource.torque, outGeneric.torque);
maxAbsCoefficientChange_pct = max(abs([CTRelativeChange_pct, ...
    CPRelativeChange_pct, FMRelativeChange_pct]));

resultTable = table({checkId}, theta75_deg, Vtip_fps, ...
    bladeMass_kg, Pgeneric.rotor.bladeMass, ...
    IbDirect_kgm2, Pgeneric.rotor.Ib, IbIntegrated_kgm2, ...
    IbIntegrationDifference_pct, Sblade_kgm, Pgeneric.rotor.Sblade, ...
    outGeneric.beta0/d2r, outSource.beta0/d2r, ...
    generic.CT, source.CT, CTRelativeChange_pct, ...
    generic.CP, source.CP, CPRelativeChange_pct, ...
    generic.FM, source.FM, FMRelativeChange_pct, ...
    thrustRelativeChange_pct, torqueRelativeChange_pct, ...
    maxAbsCoefficientChange_pct, ...
    'VariableNames', {'checkId','theta75_deg','Vtip_fps', ...
    'sourceBladeMass_kg','genericBladeMass_kg', ...
    'sourceIbDirect_kgm2','genericIb_kgm2', ...
    'sourceIbIntegrated_kgm2','IbIntegrationDifference_pct', ...
    'sourceSblade_kgm','genericSblade_kgm', ...
    'genericBeta0_deg','sourceBeta0_deg', ...
    'genericCT','sourceCT','CTRelativeChange_pct', ...
    'genericCP','sourceCP','CPRelativeChange_pct', ...
    'genericFM','sourceFM','FMRelativeChange_pct', ...
    'thrustRelativeChange_pct','torqueRelativeChange_pct', ...
    'maxAbsCoefficientChange_pct'});
writetable(resultTable, fullfile(outputDir, ...
    'XV15_MASS_PROPERTY_SINGLE_FACTOR.csv'));

result = struct();
result.table = resultTable;
result.mapping = mapping;
result.sourceMassDensity_slugPerFt = massDensity_slugPerFt;
end

function P = apply_section_aero(P, c81)
P.rotor.alpha0L = c81.alpha0L_rad;
P.rotor.liftSlope = c81.liftSlope;
P.rotor.CLmax = c81.CLmax;
P.rotor.CD0 = c81.CD0;
P.rotor.kCD = c81.kCD;
P.rotor.enableCompressibilityCorrection = false;
end

function metrics = hover_metrics(out, P, Vtip_mps)
A = pi*P.rotor.R^2;
metrics.CT = out.thrust/(P.env.rho*A*Vtip_mps^2);
metrics.CP = out.torque*P.rotor.Omega/( ...
    P.env.rho*A*Vtip_mps^3);
metrics.FM = metrics.CT^(3/2)/(sqrt(2)*metrics.CP);
end

function value = relative_change_pct(newValue, baseValue)
value = 100*(newValue-baseValue)/baseValue;
end

function theta_deg = nasa_metal_twist_deg(x)
theta_deg = 289.98*x.^5 - 892.87*x.^4 + 987.06*x.^3 ...
    - 438.31*x.^2 + 15.695*x + 32.057;
end
