function [P13, manifest] = params_generic_geometry_optimized()
%PARAMS_GENERIC_GEOMETRY_OPTIMIZED Frozen geometry-only trim design (C1).
% The values are bounded design variables for the generic conceptual model.
% They are not XV-15 measurements and do not modify params_nominal defaults.

P13 = params_berger13();
baseline = P13.base;

P13.base.wing.xAC = 0.10;
P13.base.rotor.pivotZ = 0.10;
P13.base.htail.incidence = -5*pi/180;

records = [ ...
    design_record('wing.xAC',baseline.wing.xAC,P13.base.wing.xAC, ...
        -0.4,0.4,'m','GEOMETRY'); ...
    design_record('rotor.pivotZ',baseline.rotor.pivotZ, ...
        P13.base.rotor.pivotZ,-0.6,0.6,'m','GEOMETRY'); ...
    design_record('htail.incidence',baseline.htail.incidence, ...
        P13.base.htail.incidence,-5*pi/180,2*pi/180,'rad','GEOMETRY')];

manifest = base_manifest('GENERIC_GEOMETRY_OPTIMIZED_C1',records);
manifest.parentVariant = 'PARAMS_NOMINAL_GENERIC_BASELINE';
manifest.optimizationClass = 'BOUNDED_GEOMETRY_ONLY';
manifest.calibrationSetID = 'DESIGN_FEASIBILITY_SET_9_POINT';
manifest.validationSetID = 'QUALITATIVE_EXTERNAL_HOLDOUT_AND_NUMERICAL_ROBUSTNESS';
manifest.claimBoundary = ['Generic low-order-model geometry design only; ' ...
    'not an XV-15 geometry reconstruction or flight-test validation.'];
end

function r = design_record(path,baselineValue,frozenValue,lower,upper,unit,role)
r = struct('path',path,'baselineValue',baselineValue, ...
    'frozenValue',frozenValue,'lowerBound',lower,'upperBound',upper, ...
    'unit',unit,'sourceClass','ASSUMED_MODEL_PARAMETER', ...
    'claimClass','OPTIMIZED_GENERIC','roleClass',role, ...
    'selectionSet','DESIGN_FEASIBILITY_SET_9_POINT', ...
    'validationUse','FROZEN_BEFORE_VALIDATION', ...
    'note','Bounded conceptual-design variable; no public-aircraft claim.');
end

function m = base_manifest(name,records)
m = struct();
m.variantName = name;
m.records = records;
m.optimizedFields = {records.path}.';
m.fixedFields = {'mass and inertia';'control limits'; ...
    'trim credibility gates';'numerical tolerances and iteration limits'; ...
    'all unlisted aerodynamic and geometric parameters'};
m.objectiveDefinition = 'GENERIC_TRIM_OBJECTIVE_V1';
m.parameterBoundsID = 'GENERIC_TRIM_BOUNDS_V1';
m.randomSeed = 20260723;
m.codeSHA = 'SET_AT_RESULT_GENERATION';
m.resultSHA = 'SET_AT_RESULT_GENERATION';
end
