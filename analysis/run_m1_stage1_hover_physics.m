function results = run_m1_stage1_hover_physics(outputDir)
%RUN_M1_STAGE1_HOVER_PHYSICS Execute the first M1 physics ladder.
%
% Purpose
% -------
% Run a single-evidence-level MATLAB comparison that starts from frozen pure
% M0 and adds independently sourced XV-15 physics in a traceable ladder.
% OARF Run 15 is development external-correlation data only. No CT/CP/FM
% target is used to fit any parameter in this runner.
%
% Ladder
% ------
% M0              : frozen production low-order model.
% DIAG_SECTION     : scalar C81 section-aero bridge with reduced geometry.
% M1_A_GEOMETRY   : actual radial chord/nonlinear twist + scalar C81.
% M1_B_SPAN_C81   : actual geometry + four-region C81 + local Mach.
% M1_C_ANNULAR    : M1_B + independent annular momentum closure.
%
% DIAG_SECTION is an attribution bridge rather than the final M1 identity.

rootDir = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1 || isempty(outputDir)
    outputDir = fullfile(rootDir, 'results', 'm1_stage1_hover_physics');
end
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

m0Dir = fullfile(outputDir, 'm0_pure');
sectionDir = fullfile(outputDir, 'diag_section_only');
geometryDir = fullfile(outputDir, 'm1_geometry_c81');

m0 = run_xv15_v1_baseline_correlation(m0Dir);
section = run_xv15_frozen_low_order_validation(sectionDir);
geometry = run_xv15_actual_geometry_c81_crosscheck(geometryDir);

% Pure-M0 fixed 6--11 deg metrics.
fixedMask = strcmp(m0.metricTable.window, 'FIXED_REPORT_WINDOW_6_TO_11_DEG');
CT_m0 = metric_value(m0.metricTable, fixedMask, 'CT');
CP_m0 = metric_value(m0.metricTable, fixedMask, 'CP');
FM_m0 = metric_value(m0.metricTable, fixedMask, 'FM');

% Section-only bridge uses the same 6--11 deg window.
CT_section = section.metricTable.CT_MAPE_pct(1);
CP_section = section.metricTable.CP_MAPE_pct(1);
FM_section = section.metricTable.FM_MAPE_pct(1);

% Actual-geometry cross-check: first row is 6--11 deg.
g = geometry.metrics;
row611 = strcmp(cellstr(string(g.window)), '6-11');
if sum(row611) ~= 1
    error('run_m1_stage1_hover_physics:GeometryWindow', ...
        'Expected exactly one 6-11 metric row from geometry cross-check.');
end

CT_geom = g.CT_MAPE_scalarC81_global_pct(row611);
CP_geom = g.CP_MAPE_scalarC81_global_pct(row611);
FM_geom = g.FM_MAPE_scalarC81_global_pct(row611);

CT_span = g.CT_MAPE_fullC81_global_pct(row611);
CP_span = g.CP_MAPE_fullC81_global_pct(row611);
FM_span = g.FM_MAPE_fullC81_global_pct(row611);

CT_ann = g.CT_MAPE_fullC81_annular_pct(row611);
CP_ann = g.CP_MAPE_fullC81_annular_pct(row611);
FM_ann = g.FM_MAPE_fullC81_annular_pct(row611);

modelIdentity = { ...
    'M0_PRODUCTION_LOW_ORDER'; ...
    'DIAG_SECTION_C81_REDUCED_GEOMETRY'; ...
    'M1_A_ACTUAL_GEOMETRY_SCALAR_C81'; ...
    'M1_B_ACTUAL_GEOMETRY_SPANWISE_C81'; ...
    'M1_C_ACTUAL_GEOMETRY_SPANWISE_C81_ANNULAR'};

changeFromPrevious = { ...
    'FROZEN_BASELINE'; ...
    'ADD_INDEPENDENT_SCALAR_C81_SECTION_AERO'; ...
    'REPLACE_CONSTANT_CHORD_LINEAR_TWIST_WITH_PUBLIC_RADIAL_GEOMETRY'; ...
    'REPLACE_SCALAR_C81_WITH_FOUR_REGION_C81_LOCAL_MACH'; ...
    'REPLACE_GLOBAL_MOMENTUM_WITH_INDEPENDENT_ANNULAR_MOMENTUM'};

role = { ...
    'FROZEN_REFERENCE'; ...
    'ATTRIBUTION_BRIDGE'; ...
    'M1_CANDIDATE'; ...
    'M1_CANDIDATE'; ...
    'M1_CANDIDATE'};

CT_MAPE_pct = [CT_m0; CT_section; CT_geom; CT_span; CT_ann];
CP_MAPE_pct = [CP_m0; CP_section; CP_geom; CP_span; CP_ann];
FM_MAPE_pct = [FM_m0; FM_section; FM_geom; FM_span; FM_ann];

CT_deltaFromM0_pp = CT_MAPE_pct - CT_m0;
CP_deltaFromM0_pp = CP_MAPE_pct - CP_m0;
FM_deltaFromM0_pp = FM_MAPE_pct - FM_m0;

CT_deltaFromPrevious_pp = [0; diff(CT_MAPE_pct)];
CP_deltaFromPrevious_pp = [0; diff(CP_MAPE_pct)];
FM_deltaFromPrevious_pp = [0; diff(FM_MAPE_pct)];

reportWindow = repmat({'6_TO_11_DEG'}, numel(modelIdentity), 1);
datasetRole = repmat({'DEVELOPMENT_EXTERNAL_CORRELATION'}, ...
    numel(modelIdentity), 1);
parameterFitToOarfTargets = repmat({'NO'}, numel(modelIdentity), 1);

summaryTable = table(modelIdentity, role, changeFromPrevious, reportWindow, ...
    datasetRole, parameterFitToOarfTargets, CT_MAPE_pct, CP_MAPE_pct, ...
    FM_MAPE_pct, CT_deltaFromM0_pp, CP_deltaFromM0_pp, ...
    FM_deltaFromM0_pp, CT_deltaFromPrevious_pp, ...
    CP_deltaFromPrevious_pp, FM_deltaFromPrevious_pp);

writetable(summaryTable, fullfile(outputDir, ...
    'M1_STAGE1_MODEL_LADDER_METRICS.csv'));

metadataName = { ...
    'm0_frozen_sha'; ...
    'm0_frozen_branch'; ...
    'm1_research_branch'; ...
    'dataset_role'; ...
    'report_window'; ...
    'oarf_parameter_fit'; ...
    'stage1_scope'; ...
    'annular_model_boundary'};
metadataValue = { ...
    '27f40883633ca14acc0e928649b62d7abb855491'; ...
    'frozen/m0-xv15-hover-v1-20260828'; ...
    'research/m1-xv15-physics-enhanced-20260828'; ...
    'DEVELOPMENT_EXTERNAL_CORRELATION'; ...
    '6_TO_11_DEG'; ...
    'NO'; ...
    'SECTION_AERO_RADIAL_GEOMETRY_SPANWISE_C81_ANNULAR_MOMENTUM'; ...
    'ANNULAR_MOMENTUM_IS_NOT_NONLOCAL_WAKE'};
metadataTable = table(metadataName, metadataValue);
writetable(metadataTable, fullfile(outputDir, ...
    'M1_STAGE1_METADATA.csv'));

results = struct();
results.summaryTable = summaryTable;
results.metadataTable = metadataTable;
results.m0 = m0;
results.section = section;
results.geometry = geometry;
results.claimBoundary = ['M1_STAGE1_PHYSICS_ATTRIBUTION_NO_OARF_TARGET_FIT_' ...
    'NOT_FINAL_INDEPENDENT_VALIDATION'];
save(fullfile(outputDir, 'M1_STAGE1_RESULTS.mat'), 'results');
end

function value = metric_value(T, windowMask, quantityName)
mask = windowMask & strcmp(T.quantity, quantityName);
if sum(mask) ~= 1
    error('run_m1_stage1_hover_physics:MetricLookup', ...
        'Expected one metric row for %s.', quantityName);
end
value = T.MAPE_pct(mask);
end
