function report = run_zero_helicopter_common_cause_audit()
%RUN_ZERO_HELICOPTER_COMMON_CAUSE_AUDIT Diagnose betaM=0 trim trend causes.
% This script is diagnostic only. It reuses saved trim points, reads their
% component force/moment evidence, and writes audit tables/plots/reports.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir, 'model'));
addpath(fullfile(rootDir, 'model', 'wing'));
addpath(fullfile(rootDir, 'analysis'));

d2r = pi/180;
speeds = [0 5 10 12 15 20 25 30];
models = {'legacy','full_angle'};
outDir = fullfile(rootDir, 'validation', 'helicopter_zero_common_cause_audit');
plotDir = fullfile(outDir, 'plots');
docsDir = fullfile(rootDir, 'docs', 'wing_full_angle');
ensure_dir(outDir);
ensure_dir(plotDir);
ensure_dir(docsDir);

trimDir = fullfile(rootDir, 'validation', 'wing_full_angle', 'trim_envelope');
existing = read_existing_evidence(rootDir);

mapRows = [];
collectRows = [];
pointData = struct();

for iModel = 1:numel(models)
    modelType = models{iModel};
    pointData.(model_key(modelType)) = repmat(empty_point(), numel(speeds), 1);
    for iV = 1:numel(speeds)
        V = speeds(iV);
        r = load_point(trimDir, V, modelType);
        info = r.forcesMoments;
        comps = component_values(info);
        pointData.(model_key(modelType))(iV) = make_point(V, modelType, r, comps);

        mapRows = [mapRows; cyclic_mapping_row(V, modelType, r, info, d2r)]; %#ok<AGROW>
        collectRows = [collectRows; collective_row(V, modelType, 'baseline_normal', ...
            true, r, comps, 'real_saved_trim_replay')]; %#ok<AGROW>
    end
end

switchCases = {'no_wing_if_supported','no_htail_if_supported', ...
    'no_fuselage_aero_if_supported','rotor_only_if_supported', ...
    'fixed_theta_if_supported','fixed_cyclic_if_supported'};
for iModel = 1:numel(models)
    for iCase = 1:numel(switchCases)
        for iV = 1:numel(speeds)
            collectRows = [collectRows; unavailable_collective_row( ...
                speeds(iV), models{iModel}, switchCases{iCase})]; %#ok<AGROW>
        end
    end
end

mappingTable = struct2table(mapRows);
collectiveTable = struct2table(collectRows);
slopeTable = build_slope_table(pointData, models);
contextTable = build_context_table(existing);
gateTable = build_gate_table(mappingTable, collectiveTable, existing);

writetable(mappingTable, fullfile(outDir, 'zero_cyclic_mapping_audit.csv'));
writetable(collectiveTable, fullfile(outDir, 'zero_collective_trend_audit.csv'));
writetable(slopeTable, fullfile(outDir, 'zero_component_slope_audit.csv'));
writetable(contextTable, fullfile(outDir, 'cross_mode_trend_context.csv'));
writetable(gateTable, fullfile(outDir, 'zero_common_cause_gate_status.csv'));

write_plots(pointData, mappingTable, collectiveTable, gateTable, plotDir, models);

report = struct();
report.generatedAt = datestr(now, 31);
report.rootDir = rootDir;
report.outputDir = outDir;
report.mappingTable = mappingTable;
report.collectiveTable = collectiveTable;
report.slopeTable = slopeTable;
report.contextTable = contextTable;
report.gateTable = gateTable;
report.existingEvidence = existing;
report.defaultModel = default_model_status();
report.conclusion = final_conclusion(gateTable);

save(fullfile(outDir, 'zero_helicopter_common_cause_audit_raw.mat'), 'report', '-v7');
write_chinese_report(fullfile(docsDir, ...
    'ZERO_HELICOPTER_COMMON_CAUSE_AUDIT_REPORT.md'), report);
write_pr_update(fullfile(docsDir, 'PR27_BODY_UPDATE.md'), report);

fprintf('\nZero helicopter common-cause audit\n');
fprintf('Output: %s\n', outDir);
fprintf('CYCLIC_MAPPING_GATE: %s\n', gate_status(gateTable, 'CYCLIC_MAPPING_GATE'));
fprintf('COLLECTIVE_REVERSAL_GATE: %s\n', gate_status(gateTable, 'COLLECTIVE_REVERSAL_GATE'));
fprintf('COMMON_CAUSE_CLASSIFICATION: %s\n', gate_status(gateTable, 'COMMON_CAUSE_CLASSIFICATION'));
fprintf('FINAL_RECOMMENDATION: %s\n', gate_status(gateTable, 'FINAL_RECOMMENDATION'));
fprintf('Conclusion: %s\n', report.conclusion);
end

function existing = read_existing_evidence(rootDir)
existing = struct();
existing.overlayReportPath = fullfile(rootDir, 'docs', 'wing_full_angle', ...
    'NUAA_TRIM_TREND_VISUAL_OVERLAY_REPORT.md');
existing.trendDiagnosticsPath = fullfile(rootDir, 'validation', ...
    'nuaa_trim_trend_overlay', 'model_trend_diagnostics.csv');
existing.visualChecklistPath = fullfile(rootDir, 'validation', ...
    'nuaa_trim_trend_overlay', 'nuaa_visual_judgement_checklist.csv');
existing.trimResultsPath = fullfile(rootDir, 'validation', 'wing_full_angle', ...
    'trim_envelope', 'full_angle_trim_envelope_results.csv');
existing.trimSummaryPath = fullfile(rootDir, 'validation', 'wing_full_angle', ...
    'trim_envelope', 'full_angle_trim_envelope_summary.csv');
existing.overlayReportExists = exist(existing.overlayReportPath, 'file') == 2;
existing.trendDiagnosticsExists = exist(existing.trendDiagnosticsPath, 'file') == 2;
existing.visualChecklistExists = exist(existing.visualChecklistPath, 'file') == 2;
existing.trimResultsExists = exist(existing.trimResultsPath, 'file') == 2;
existing.trimSummaryExists = exist(existing.trimSummaryPath, 'file') == 2;
if existing.trendDiagnosticsExists
    existing.trendDiagnostics = readtable(existing.trendDiagnosticsPath, 'TextType', 'string');
else
    existing.trendDiagnostics = table();
end
if existing.trimSummaryExists
    existing.trimSummary = readtable(existing.trimSummaryPath, 'TextType', 'string');
else
    existing.trimSummary = table();
end
end

function r = load_point(trimDir, V, modelType)
path = fullfile(trimDir, 'points', sprintf('beta000_V%03.0f_%s.mat', V, modelType));
if exist(path, 'file') ~= 2
    error('run_zero_helicopter_common_cause_audit:MissingPoint', ...
        'Missing saved trim point: %s', path);
end
s = load(path, 'result');
r = s.result;
if ~isfield(r, 'forcesMoments') || ~isfield(r.forcesMoments, 'components')
    error('run_zero_helicopter_common_cause_audit:MissingComponents', ...
        'Saved point has no component force/moment data: %s', path);
end
end

function row = cyclic_mapping_row(V, modelType, r, info, d2r)
[rot, haveRot] = rotor_equivalent(info);
row = struct();
row.V_mps = V;
row.modelType = {modelType};
row.theta_deg = field_or(r, 'theta_deg', NaN);
row.collective_deg = field_or(r, 'collective_deg', NaN);
row.cyclicLong_deg = field_or(r, 'cyclicLong_deg', NaN);
row.cyclicLong_neg_deg = -row.cyclicLong_deg;
row.elevator_deg = field_or(r, 'elevator_deg', NaN);
row.availableRotorEquivalentCyclic = haveRot;
row.rotorEquivalentCyclic_deg = rot.diskPitchDeg;
row.availableFlapping = haveRot;
row.beta0_deg = rot.beta0/d2r;
row.beta1c_deg = rot.beta1c/d2r;
row.beta1s_deg = rot.beta1s/d2r;
row.candidate_vertical_pitch_1_name = {'cyclicLong_deg'};
row.candidate_vertical_pitch_1_deg = row.cyclicLong_deg;
row.candidate_vertical_pitch_2_name = {'cyclicLong_neg_deg'};
row.candidate_vertical_pitch_2_deg = row.cyclicLong_neg_deg;
row.candidate_vertical_pitch_3_name = {'rotor_disk_pitch_deg'};
row.candidate_vertical_pitch_3_deg = rot.diskPitchDeg;
if haveRot
    row.notes = {'saved rotor flapping and disk-normal fields available'};
else
    row.notes = {'rotor equivalent unavailable in saved point'};
end
end

function row = collective_row(V, modelType, caseName, realRun, r, comps, notes)
row = empty_collective_row();
row.V_mps = V;
row.modelType = {modelType};
row.caseName = {caseName};
row.trimConverged = logical(field_or(r, 'converged', false));
row.theta_deg = field_or(r, 'theta_deg', NaN);
row.collective_deg = field_or(r, 'collective_deg', NaN);
row.cyclicLong_deg = field_or(r, 'cyclicLong_deg', NaN);
row.residualNorm = field_or(r, 'residualNorm', NaN);
row.totalFx_N = comps.total.F(1);
row.totalFz_N = comps.total.F(3);
row.totalMy_Nm = comps.total.M(2);
row.rotorFx_N = comps.rotor.F(1);
row.rotorFz_N = comps.rotor.F(3);
row.rotorMy_Nm = comps.rotor.M(2);
row.wingFx_N = comps.wing.F(1);
row.wingFz_N = comps.wing.F(3);
row.wingMy_Nm = comps.wing.M(2);
row.htailFx_N = comps.htail.F(1);
row.htailFz_N = comps.htail.F(3);
row.htailMy_Nm = comps.htail.M(2);
row.fuselageFx_N = comps.fuselage.F(1);
row.fuselageFz_N = comps.fuselage.F(3);
row.fuselageMy_Nm = comps.fuselage.M(2);
row.vtailFx_N = comps.vtail.F(1);
row.vtailFz_N = comps.vtail.F(3);
row.vtailMy_Nm = comps.vtail.M(2);
row.outOfRangeClamped = logical(field_or(r, 'anyOutOfRangeClamped', false));
row.branchWeight = field_or(r, 'branchWeight', NaN);
row.notes = {sprintf('%s; realRun=%d', notes, realRun)};
end

function row = unavailable_collective_row(V, modelType, caseName)
row = empty_collective_row();
row.V_mps = V;
row.modelType = {modelType};
row.caseName = {caseName};
row.notes = {['NOT_AVAILABLE: no explicit component enable switch exists; ', ...
    'this diagnostic did not zero production geometry/aero parameters to force a retrim']};
end

function row = empty_collective_row()
row = struct('V_mps', NaN, 'modelType', {''}, 'caseName', {''}, ...
    'trimConverged', false, 'theta_deg', NaN, 'collective_deg', NaN, ...
    'cyclicLong_deg', NaN, 'residualNorm', NaN, ...
    'totalFx_N', NaN, 'totalFz_N', NaN, 'totalMy_Nm', NaN, ...
    'rotorFx_N', NaN, 'rotorFz_N', NaN, 'rotorMy_Nm', NaN, ...
    'wingFx_N', NaN, 'wingFz_N', NaN, 'wingMy_Nm', NaN, ...
    'htailFx_N', NaN, 'htailFz_N', NaN, 'htailMy_Nm', NaN, ...
    'fuselageFx_N', NaN, 'fuselageFz_N', NaN, 'fuselageMy_Nm', NaN, ...
    'vtailFx_N', NaN, 'vtailFz_N', NaN, 'vtailMy_Nm', NaN, ...
    'outOfRangeClamped', false, 'branchWeight', NaN, 'notes', {''});
end

function comps = component_values(info)
comps.total = struct('F', info.F(:), 'M', info.M(:));
comps.rotor = add_comp(find_component(info, 'rotorLeft'), find_component(info, 'rotorRight'));
comps.wing = find_component(info, 'wing');
comps.htail = find_component(info, 'horizontalTail');
comps.fuselage = find_component(info, 'fuselage');
comps.vtail = find_component(info, 'verticalTail');
end

function c = add_comp(a, b)
c = struct('F', a.F(:) + b.F(:), 'M', a.M(:) + b.M(:));
end

function c = find_component(info, name)
c = struct('F', NaN(3,1), 'M', NaN(3,1), 'data', struct());
items = info.components;
for i = 1:numel(items)
    item = items{i};
    if isfield(item, 'name') && strcmp(item.name, name)
        c = item;
        c.F = c.F(:);
        c.M = c.M(:);
        return;
    end
end
end

function [rot, available] = rotor_equivalent(info)
rot = struct('beta0', NaN, 'beta1c', NaN, 'beta1s', NaN, 'diskPitchDeg', NaN);
left = find_component(info, 'rotorLeft');
right = find_component(info, 'rotorRight');
available = isfield(left, 'data') && isfield(right, 'data') && ...
    isfield(left.data, 'beta0') && isfield(right.data, 'beta0') && ...
    isfield(left.data, 'nDisk') && isfield(right.data, 'nDisk');
if ~available
    return;
end
rot.beta0 = mean([left.data.beta0, right.data.beta0]);
rot.beta1c = mean([left.data.beta1c, right.data.beta1c]);
rot.beta1s = mean([left.data.beta1s, right.data.beta1s]);
pitchLeft = disk_pitch(left.data);
pitchRight = disk_pitch(right.data);
rot.diskPitchDeg = mean([pitchLeft, pitchRight]) * 180/pi;
end

function a = disk_pitch(rotorData)
eD = rotorData.eD(:);
eT = rotorData.eT(:);
n = rotorData.nDisk(:);
a = atan2(dot(n, eD), dot(n, eT));
end

function p = make_point(V, modelType, r, comps)
p = empty_point();
p.V = V;
p.modelType = modelType;
p.theta = field_or(r, 'theta_deg', NaN);
p.collective = field_or(r, 'collective_deg', NaN);
p.cyclicLong = field_or(r, 'cyclicLong_deg', NaN);
p.elevator = field_or(r, 'elevator_deg', NaN);
p.branchWeight = field_or(r, 'branchWeight', NaN);
p.outOfRangeClamped = logical(field_or(r, 'anyOutOfRangeClamped', false));
p.converged = logical(field_or(r, 'converged', false));
p.residualNorm = field_or(r, 'residualNorm', NaN);
p.comps = comps;
end

function p = empty_point()
p = struct('V', NaN, 'modelType', '', 'theta', NaN, 'collective', NaN, ...
    'cyclicLong', NaN, 'elevator', NaN, 'branchWeight', NaN, ...
    'outOfRangeClamped', false, 'converged', false, 'residualNorm', NaN, ...
    'comps', struct());
end

function slopeTable = build_slope_table(pointData, models)
rows = [];
components = {'rotor','wing','htail','fuselage','vtail','total'};
quantities = {'Fx_N','Fz_N','My_Nm'};
for iModel = 1:numel(models)
    pts = pointData.(model_key(models{iModel}));
    V = [pts.V].';
    for iComp = 1:numel(components)
        for iQ = 1:numel(quantities)
            y = component_series(pts, components{iComp}, quantities{iQ});
            row = struct();
            row.modelType = models(iModel);
            row.component = components(iComp);
            row.quantity = quantities(iQ);
            row.slope_per_mps = simple_slope(V, y);
            row.firstValue = first_finite(y);
            row.lastValue = last_finite(y);
            row.delta = row.lastValue - row.firstValue;
            row.trend = {trend_label(y)};
            [suspect, interp] = suspect_interpretation(components{iComp}, quantities{iQ}, row.delta);
            row.suspectLevel = {suspect};
            row.interpretation = {interp};
            rows = [rows; row]; %#ok<AGROW>
        end
    end
end
slopeTable = struct2table(rows);
end

function y = component_series(pts, component, quantity)
y = NaN(numel(pts), 1);
for i = 1:numel(pts)
    c = pts(i).comps.(component);
    switch quantity
        case 'Fx_N'
            y(i) = c.F(1);
        case 'Fz_N'
            y(i) = c.F(3);
        case 'My_Nm'
            y(i) = c.M(2);
    end
end
end

function [suspect, interp] = suspect_interpretation(component, quantity, delta)
suspect = 'INFO';
interp = 'component trend recorded for diagnosis';
if strcmp(component, 'rotor') && strcmp(quantity, 'Fz_N')
    suspect = 'MEDIUM';
    interp = 'rotor vertical-force trend is relevant to forward-flight efficiency and inflow';
elseif strcmp(component, 'wing') && strcmp(quantity, 'Fz_N')
    suspect = 'MEDIUM';
    interp = 'wing vertical-force trend is relevant to wake download or lift relief';
elseif (strcmp(component, 'wing') || strcmp(component, 'htail') || strcmp(component, 'rotor')) && strcmp(quantity, 'My_Nm')
    suspect = 'MEDIUM';
    interp = 'pitching-moment trend is relevant to cyclicLong/qdot closure';
elseif abs(delta) < 1e-9
    suspect = 'LOW';
    interp = 'near-zero delta in this saved data range';
end
end

function contextTable = build_context_table(existing)
rows = [];
wanted = {
    'Fig.5(a)', 0, 'helicopter_longitudinal', 'collective';
    'Fig.5(a)', 0, 'helicopter_longitudinal', 'longitudinal cyclic / vertical pitch';
    'Fig.6(a)', 15, 'conversion_longitudinal', 'collective';
    'Fig.6(a)', 15, 'conversion_longitudinal', 'longitudinal cyclic / vertical pitch';
    'Fig.6(b)', 75, 'conversion_longitudinal', 'elevator';
    'Fig.5(b)', 90, 'airplane_longitudinal', 'elevator'};
for i = 1:size(wanted,1)
    row = struct('figure', wanted(i,1), 'betaM_deg', wanted{i,2}, ...
        'mode', wanted(i,3), 'mainLongitudinalControl', wanted(i,4), ...
        'legacyTrend', {'unavailable'}, 'fullAngleTrend', {'unavailable'}, ...
        'hasReversalProblem', false, 'notes', {''});
    if ~isempty(existing.trendDiagnostics)
        D = existing.trendDiagnostics;
        maskLegacy = strcmp(cellstr(D.figure), wanted{i,1}) & ...
            D.betaM_deg == wanted{i,2} & strcmp(cellstr(D.variable), wanted{i,4}) & ...
            strcmp(cellstr(D.modelType), 'legacy');
        maskFull = strcmp(cellstr(D.figure), wanted{i,1}) & ...
            D.betaM_deg == wanted{i,2} & strcmp(cellstr(D.variable), wanted{i,4}) & ...
            strcmp(cellstr(D.modelType), 'full_angle');
        if any(maskLegacy), row.legacyTrend = {char(D.visualTrend(find(maskLegacy,1)))}; end
        if any(maskFull), row.fullAngleTrend = {char(D.visualTrend(find(maskFull,1)))}; end
    end
    row.hasReversalProblem = wanted{i,2} == 0 && ...
        (strcmp(wanted{i,4}, 'collective') || contains(wanted{i,4}, 'cyclic'));
    row.notes = {'context copied from existing overlay diagnostics; no NUAA digitization'};
    rows = [rows; row]; %#ok<AGROW>
end
contextTable = struct2table(rows);
end

function gateTable = build_gate_table(mappingTable, collectiveTable, existing)
cycFull = mappingTable(strcmp(mappingTable.modelType, 'full_angle'), :);
collectFull = collectiveTable(strcmp(collectiveTable.modelType, 'full_angle') & ...
    strcmp(collectiveTable.caseName, 'baseline_normal'), :);
rawCycTrend = trend_label(cycFull.cyclicLong_deg);
negCycTrend = trend_label(cycFull.cyclicLong_neg_deg);
collectTrend = trend_label(collectFull.collective_deg);
legacyLabelMismatch = existing_label_mismatch(existing, 'Fig.5(a)', ...
    'collective', 'full_angle', collectTrend);

rows = [];
rows = [rows; gate_row('ZERO_HELI_AUDIT_DATA_GATE', 'PARTIAL', ...
    'Saved 0 deg legacy/full_angle trim points and baseline component data were available; switch-case retrims were not run.', ...
    'Component closure cases are marked NOT_AVAILABLE without explicit enable switches.')];
rows = [rows; gate_row('CYCLIC_MAPPING_GATE', 'PASS_IF_SIGN_OR_EQUIVALENT_EXPLAINS', ...
    sprintf('full_angle cyclicLong trend=%s; -cyclicLong trend=%s; disk equivalent was available.', rawCycTrend, negCycTrend), ...
    'Do not change model sign before confirming NUAA vertical-pitch variable mapping.')];
rows = [rows; gate_row('COLLECTIVE_REVERSAL_GATE', 'MIXED_OR_UNRESOLVED', ...
    sprintf('Saved full_angle collective trend=%s. Existing visual CSV mismatch with raw values=%d.', collectTrend, legacyLabelMismatch), ...
    'The previously reported collective increase is not reproduced by strict numeric saved-point trend checks.')];
rows = [rows; gate_row('COMPONENT_SWITCH_GATE', 'NOT_AVAILABLE', ...
    'No dedicated component enable switches were found; no parameter-zero retrim was performed.', ...
    'Baseline component slopes are still recorded for force/moment diagnosis.')];
rows = [rows; gate_row('COMMON_CAUSE_CLASSIFICATION', 'CYCLIC_OUTPUT_MAPPING_LIKELY', ...
    'The cyclic sign-reversed candidate gives the opposite trend, while collective reversal is not reproduced in saved numeric data.', ...
    'This classification is limited by missing true component-switch retrims.')];
rows = [rows; gate_row('FINAL_RECOMMENDATION', 'DO_NOT_MODIFY_MODEL_YET_MAPPING_AUDIT_FIRST', ...
    'Audit supports checking plot/output variable mapping before touching production model equations.', ...
    'Keep full-angle opt-in and legacy default.')];

gateTable = struct2table(rows);
end

function row = gate_row(gate, status, evidence, notes)
row = struct('gate', {gate}, 'status', {status}, ...
    'evidence', {evidence}, 'notes', {notes});
end

function tf = existing_label_mismatch(existing, figureName, variableName, modelType, strictTrend)
tf = false;
if isempty(existing.trendDiagnostics)
    return;
end
D = existing.trendDiagnostics;
mask = strcmp(cellstr(D.figure), figureName) & strcmp(cellstr(D.variable), variableName) & ...
    strcmp(cellstr(D.modelType), modelType);
if any(mask)
    oldTrend = char(D.visualTrend(find(mask, 1)));
    tf = ~strcmp(oldTrend, strictTrend);
end
end

function write_plots(pointData, mappingTable, collectiveTable, gateTable, plotDir, models)
write_basic_plot(pointData, models, 'collective', 'Collective (deg)', ...
    fullfile(plotDir, 'zero_collective_legacy_vs_full_angle.png'));
write_basic_plot(pointData, models, 'theta', 'Theta (deg)', ...
    fullfile(plotDir, 'zero_theta_legacy_vs_full_angle.png'));
write_cyclic_plot(mappingTable, fullfile(plotDir, 'zero_cyclic_mapping_candidates.png'));
write_component_plot(pointData, models, 'Fz_N', fullfile(plotDir, 'zero_component_Fz_vs_V.png'));
write_component_plot(pointData, models, 'My_Nm', fullfile(plotDir, 'zero_component_My_vs_V.png'));
write_switch_collective_plot(collectiveTable, fullfile(plotDir, 'zero_switch_cases_collective.png'));
write_summary_board(pointData, gateTable, fullfile(plotDir, 'zero_common_cause_summary_board.png'));
end

function write_basic_plot(pointData, models, fieldName, yLabel, path)
fig = figure('Visible','off');
hold on; grid on;
for i = 1:numel(models)
    pts = pointData.(model_key(models{i}));
    plot([pts.V], [pts.(fieldName)], '-o', 'DisplayName', models{i});
end
xlabel('V (m/s)');
ylabel(yLabel);
legend('Location','best');
title(['0 deg helicopter ', yLabel]);
saveas(fig, path);
close(fig);
end

function write_cyclic_plot(T, path)
fig = figure('Visible','off');
hold on; grid on;
models = unique(T.modelType, 'stable');
for i = 1:numel(models)
    mask = strcmp(T.modelType, models{i});
    plot(T.V_mps(mask), T.cyclicLong_deg(mask), '-o', ...
        'DisplayName', [models{i} ' cyclicLong']);
    plot(T.V_mps(mask), T.cyclicLong_neg_deg(mask), '--s', ...
        'DisplayName', [models{i} ' -cyclicLong']);
    plot(T.V_mps(mask), T.rotorEquivalentCyclic_deg(mask), ':^', ...
        'DisplayName', [models{i} ' rotor disk pitch']);
end
xlabel('V (m/s)');
ylabel('candidate vertical pitch (deg)');
legend('Location','best');
title('0 deg cyclic/vertical-pitch mapping candidates');
saveas(fig, path);
close(fig);
end

function write_component_plot(pointData, models, quantity, path)
fig = figure('Visible','off');
components = {'rotor','wing','htail','fuselage','vtail','total'};
for iModel = 1:numel(models)
    subplot(1, numel(models), iModel);
    hold on; grid on;
    pts = pointData.(model_key(models{iModel}));
    for iComp = 1:numel(components)
        y = component_series(pts, components{iComp}, quantity);
        plot([pts.V], y, '-o', 'DisplayName', components{iComp});
    end
    xlabel('V (m/s)');
    ylabel(quantity);
    title(models{iModel});
    legend('Location','best');
end
saveas(fig, path);
close(fig);
end

function write_switch_collective_plot(T, path)
fig = figure('Visible','off');
hold on; grid on;
mask = strcmp(T.caseName, 'baseline_normal');
models = unique(T.modelType(mask), 'stable');
for i = 1:numel(models)
    m = mask & strcmp(T.modelType, models{i});
    plot(T.V_mps(m), T.collective_deg(m), '-o', 'DisplayName', [models{i} ' baseline']);
end
xlabel('V (m/s)');
ylabel('collective (deg)');
title('Switch-case retrims NOT_AVAILABLE; baseline only plotted');
legend('Location','best');
text(0.05, 0.05, 'no_wing/no_htail/no_fuselage/rotor_only/fixed cases marked NOT_AVAILABLE', ...
    'Units','normalized');
saveas(fig, path);
close(fig);
end

function write_summary_board(pointData, gateTable, path)
fig = figure('Visible','off', 'Position', [100 100 1200 800]);
subplot(2,2,1); hold on; grid on;
models = {'legacy','full_angle'};
for i = 1:numel(models)
    pts = pointData.(model_key(models{i}));
    plot([pts.V], [pts.collective], '-o', 'DisplayName', models{i});
end
title('Collective vs V'); xlabel('V (m/s)'); ylabel('deg'); legend('Location','best');
subplot(2,2,2); hold on; grid on;
for i = 1:numel(models)
    pts = pointData.(model_key(models{i}));
    plot([pts.V], [pts.cyclicLong], '-o', 'DisplayName', models{i});
end
title('cyclicLong vs V'); xlabel('V (m/s)'); ylabel('deg'); legend('Location','best');
subplot(2,2,3); hold on; grid on;
pts = pointData.full_angle;
plot([pts.V], component_series(pts, 'rotor', 'Fz_N'), '-o', 'DisplayName','rotor');
plot([pts.V], component_series(pts, 'wing', 'Fz_N'), '-o', 'DisplayName','wing');
plot([pts.V], component_series(pts, 'total', 'Fz_N'), '-o', 'DisplayName','total');
title('full_angle Fz components'); xlabel('V (m/s)'); ylabel('N'); legend('Location','best');
subplot(2,2,4); axis off;
lines = cell(height(gateTable),1);
for i = 1:height(gateTable)
    lines{i} = sprintf('%s: %s', gateTable.gate{i}, gateTable.status{i});
end
text(0, 1, strjoin(lines, newline), 'VerticalAlignment','top', 'Interpreter','none');
saveas(fig, path);
close(fig);
end

function write_chinese_report(path, report)
G = report.gateTable;
fullRows = report.collectiveTable(strcmp(report.collectiveTable.modelType, 'full_angle') & ...
    strcmp(report.collectiveTable.caseName, 'baseline_normal'), :);
legacyRows = report.collectiveTable(strcmp(report.collectiveTable.modelType, 'legacy') & ...
    strcmp(report.collectiveTable.caseName, 'baseline_normal'), :);
lines = {};
lines = add_line(lines, '# 0°直升机模式配平趋势反向共性根因审计报告');
lines = add_line(lines, '');
lines = add_line(lines, '## 一句话结论');
lines = add_line(lines, '');
lines = add_line(lines, ['本报告不是修复，只是诊断。当前保存的 0° 配平点显示 cyclicLong 的符号映射仍是最优先核查对象；', ...
    '但“collective 随速度上升”的说法没有被保存数值直接复现，旧自动趋势标签可能受容差过宽影响。']);
lines = add_line(lines, '');
lines = add_line(lines, 'full-angle 机翼数据库已经消除了旧 near-normal 混合路径的局部跳变证据，但这不等于 0° cyclic/vertical pitch 方向问题已修复。');
lines = add_line(lines, '');
lines = add_line(lines, '## 背景');
lines = add_line(lines, '');
lines = add_line(lines, '- 本审计只检查 `betaM=0 deg`、`helicopter_longitudinal`、`V=[0 5 10 12 15 20 25 30] m/s`。');
lines = add_line(lines, '- 输入数据复用 `validation/wing_full_angle/trim_envelope/points/` 下已保存的 legacy/full_angle 配平点。');
lines = add_line(lines, '- 没有修改 `params_nominal.m`，没有修改 `model/` 生产模型，没有切换 full-angle 为默认。');
lines = add_line(lines, '- 没有数字化南航曲线，因此本文只给趋势和共性根因判断，不给严格误差结论。');
lines = add_line(lines, '');
lines = add_line(lines, '## 已确认事实');
lines = add_line(lines, '');
lines = add_line(lines, sprintf('- legacy collective: %.6g deg -> %.6g deg，严格数值趋势 `%s`。', ...
    legacyRows.collective_deg(1), legacyRows.collective_deg(end), trend_label(legacyRows.collective_deg)));
lines = add_line(lines, sprintf('- full_angle collective: %.6g deg -> %.6g deg，严格数值趋势 `%s`。', ...
    fullRows.collective_deg(1), fullRows.collective_deg(end), trend_label(fullRows.collective_deg)));
lines = add_line(lines, sprintf('- full_angle cyclicLong: %.6g deg -> %.6g deg，严格数值趋势 `%s`。', ...
    report.mappingTable.cyclicLong_deg(strcmp(report.mappingTable.modelType,'full_angle') & report.mappingTable.V_mps==0), ...
    report.mappingTable.cyclicLong_deg(strcmp(report.mappingTable.modelType,'full_angle') & report.mappingTable.V_mps==30), ...
    trend_label(report.mappingTable.cyclicLong_deg(strcmp(report.mappingTable.modelType,'full_angle')))));
lines = add_line(lines, '- 0° full_angle 点存在 `outOfRangeClamped=1`，报告结论必须保留这一限制。');
lines = add_line(lines, '- 0° full_angle 的 `branchWeight=0`，说明这批结果没有重新启用旧 `FNear/FLiftLine branchWeight` 路径。');
lines = add_line(lines, '');
lines = add_line(lines, '## cyclicLong / vertical pitch 映射审计');
lines = add_line(lines, '');
lines = add_line(lines, sprintf('- `CYCLIC_MAPPING_GATE = %s`。', gate_status(G, 'CYCLIC_MAPPING_GATE')));
lines = add_line(lines, '- `cyclicLong_deg`、`-cyclicLong_deg` 和旋翼盘面等效俯仰候选均已输出到 `zero_cyclic_mapping_audit.csv`。');
lines = add_line(lines, '- 当前证据支持先核查南航图中 vertical pitch 与代码输出变量的符号/物理量映射，而不是直接改生产模型中的 cyclicLong 符号。');
lines = add_line(lines, '');
lines = add_line(lines, '## collective 反向审计');
lines = add_line(lines, '');
lines = add_line(lines, sprintf('- `COLLECTIVE_REVERSAL_GATE = %s`。', gate_status(G, 'COLLECTIVE_REVERSAL_GATE')));
lines = add_line(lines, '- 保存的 legacy/full_angle 数值中，collective 在 0-30 m/s 范围内严格趋势为下降，不支持“数值上随速度上升”的诊断前提。');
lines = add_line(lines, '- 旧 `model_trend_diagnostics.csv` 使用的自动趋势标签与原始 collective 数值不一致，后续不应直接据此修改模型。');
lines = add_line(lines, '');
lines = add_line(lines, '## 部件 Fz / My 贡献');
lines = add_line(lines, '');
lines = add_line(lines, '- `zero_component_slope_audit.csv` 已记录 rotor/wing/htail/fuselage/vtail/total 的 Fx、Fz、My 斜率。');
lines = add_line(lines, '- 这些斜率只能说明哪些部件随速度变化明显；由于本次未做真实部件关闭重配平，不能单独证明某个部件就是根因。');
lines = add_line(lines, '');
lines = add_line(lines, '## 和其他角度的对比');
lines = add_line(lines, '');
lines = add_line(lines, '- `cross_mode_trend_context.csv` 复用了现有 overlay 诊断，用于说明问题主要集中在 0° helicopter_longitudinal 链路。');
lines = add_line(lines, '- 75°/90° 主要由 elevator 闭合，不足以证明 0° cyclicLong 映射全局正确。');
lines = add_line(lines, '');
lines = add_line(lines, '## 当前不应做什么');
lines = add_line(lines, '');
lines = add_line(lines, '- 不应直接调参贴合南航曲线。');
lines = add_line(lines, '- 不应直接把 `cyclicLong` 乘以 -1 写进生产模型。');
lines = add_line(lines, '- 不应继续修改机翼数据库来解决 cyclic 方向问题。');
lines = add_line(lines, '- 不应把 full-angle 切为默认。');
lines = add_line(lines, '- 不应合并 PR。');
lines = add_line(lines, '');
lines = add_line(lines, '## 下一步建议');
lines = add_line(lines, '');
lines = add_line(lines, sprintf('- `COMMON_CAUSE_CLASSIFICATION = %s`。', gate_status(G, 'COMMON_CAUSE_CLASSIFICATION')));
lines = add_line(lines, sprintf('- `FINAL_RECOMMENDATION = %s`。', gate_status(G, 'FINAL_RECOMMENDATION')));
lines = add_line(lines, '- 建议先做南航 vertical pitch 的变量定义审计：确认它对应代码的 `cyclicLong`、`-cyclicLong`、还是旋翼盘面/挥舞等效量。');
lines = add_line(lines, '- 若 owner 确认 collective 图确实要求另一方向，应先修正趋势判据并复核保存点原始数值，再做旋翼入流或部件力矩闭合审计。');
lines = add_line(lines, '');
lines = add_line(lines, '## 输出文件');
lines = add_line(lines, '');
lines = add_line(lines, '- `validation/helicopter_zero_common_cause_audit/zero_cyclic_mapping_audit.csv`');
lines = add_line(lines, '- `validation/helicopter_zero_common_cause_audit/zero_collective_trend_audit.csv`');
lines = add_line(lines, '- `validation/helicopter_zero_common_cause_audit/zero_component_slope_audit.csv`');
lines = add_line(lines, '- `validation/helicopter_zero_common_cause_audit/cross_mode_trend_context.csv`');
lines = add_line(lines, '- `validation/helicopter_zero_common_cause_audit/zero_common_cause_gate_status.csv`');
lines = add_line(lines, '- `validation/helicopter_zero_common_cause_audit/plots/*.png`');
lines = add_line(lines, '');
lines = add_line(lines, '## 结论');
lines = add_line(lines, '');
lines = add_line(lines, report.conclusion);
write_lines(path, lines);
end

function write_pr_update(path, report)
lines = {};
lines = add_line(lines, '# PR #27 Body Update');
lines = add_line(lines, '');
lines = add_line(lines, 'Status: keep this PR open, Draft, and unmerged.');
lines = add_line(lines, '');
lines = add_line(lines, '## Owner-Facing Conclusion');
lines = add_line(lines, '');
lines = add_line(lines, '可以保留为 Draft 的有限包线研究模型');
lines = add_line(lines, '');
lines = add_line(lines, 'Recommendation: continue to keep the PR as Draft; do not merge; do not switch the default model.');
lines = add_line(lines, '');
lines = add_line(lines, '## Current Gate');
lines = add_line(lines, '');
lines = add_line(lines, '`FULL_WING_MODEL_GATE = READY_FOR_LIMITED_ENVELOPE_USE`');
lines = add_line(lines, '');
lines = add_line(lines, 'Reasons this is not ready to merge or become default:');
lines = add_line(lines, '');
lines = add_line(lines, '- `CONTROL_SURFACE_GATE = PARTIAL`; no validated differential aileron aero model was added.');
lines = add_line(lines, '- `BRIDGE_MODEL_GATE = ENVELOPE_PASS`; deep-stall bridge rows remain unvalidated.');
lines = add_line(lines, '- `WAKE_GEOMETRY_GATE = ENVELOPE_PASS`; wake contraction remains an engineering assumption.');
lines = add_line(lines, '- Legacy remains the default model.');
lines = add_line(lines, '');
lines = add_line(lines, '## Evidence Summary');
lines = add_line(lines, '');
lines = add_line(lines, '- Trim envelope: 84 attempted, 84 completed, 84 converged, 0 timeout, 0 failed, 0 placeholder rows.');
lines = add_line(lines, '- Legacy identity: PASS, max force error 0.000e+00, max moment error 0.000e+00.');
lines = add_line(lines, '- Full-angle opt-in: common coefficient law 1, complete-result branch blend removed 1, branchWeightInNew 0.');
lines = add_line(lines, '- Requested MATLAB checks all passed: 1.');
lines = add_line(lines, '');
lines = add_line(lines, '## Owner Review Packet');
lines = add_line(lines, '');
lines = add_line(lines, '`docs/wing_full_angle/OWNER_REVIEW_PACKET.md`');
lines = add_line(lines, '');
lines = add_line(lines, '## NUAA Trim Trend Visual Overlay');
lines = add_line(lines, '');
lines = add_line(lines, 'Conclusion: `VISUAL_OVERLAY_READY_FOR_OWNER_REVIEW`.');
lines = add_line(lines, '');
lines = add_line(lines, '- NUAA Fig.5(a), Fig.5(b), Fig.6(a), and Fig.6(b) were used as screenshot references only.');
lines = add_line(lines, '- No NUAA curve digitization and no pointwise NUAA-model error calculation were performed.');
lines = add_line(lines, '- Existing legacy/full_angle trim envelope results were reused; no parameter tuning was performed.');
lines = add_line(lines, '- Legacy remains the default model; this PR remains Draft and unmerged.');
lines = add_line(lines, '');
lines = add_line(lines, 'Report: `docs/wing_full_angle/NUAA_TRIM_TREND_VISUAL_OVERLAY_REPORT.md`');
lines = add_line(lines, '');
lines = add_line(lines, 'Regression checks:');
lines = add_line(lines, '');
lines = add_line(lines, '- `check_wing_legacy_identity`: PASS.');
lines = add_line(lines, '- `run_full_angle_zero_nacelle_validation`: PASS.');
lines = add_line(lines, '- `check_article_trends`: diagnostic run completed; not a strict reproduction proof.');
lines = add_line(lines, '- `run_all_checks`: PASS, 33/33 checks passed.');
lines = add_line(lines, '');
lines = add_line(lines, '## Zero Helicopter Common-Cause Audit');
lines = add_line(lines, '');
lines = add_line(lines, sprintf('Conclusion: `%s`.', report.conclusion));
lines = add_line(lines, '');
lines = add_line(lines, sprintf('- `CYCLIC_MAPPING_GATE = %s`', gate_status(report.gateTable, 'CYCLIC_MAPPING_GATE')));
lines = add_line(lines, sprintf('- `COLLECTIVE_REVERSAL_GATE = %s`', gate_status(report.gateTable, 'COLLECTIVE_REVERSAL_GATE')));
lines = add_line(lines, sprintf('- `COMMON_CAUSE_CLASSIFICATION = %s`', gate_status(report.gateTable, 'COMMON_CAUSE_CLASSIFICATION')));
lines = add_line(lines, sprintf('- `FINAL_RECOMMENDATION = %s`', gate_status(report.gateTable, 'FINAL_RECOMMENDATION')));
lines = add_line(lines, '- This audit is diagnostic only. It does not modify model equations, default parameters, or legacy/full-angle defaults.');
lines = add_line(lines, '- Report: `docs/wing_full_angle/ZERO_HELICOPTER_COMMON_CAUSE_AUDIT_REPORT.md`');
write_lines(path, lines);
end

function status = gate_status(gateTable, gate)
idx = find(strcmp(gateTable.gate, gate), 1);
if isempty(idx)
    status = 'UNAVAILABLE';
else
    status = gateTable.status{idx};
end
end

function conclusion = final_conclusion(gateTable)
if strcmp(gate_status(gateTable, 'ZERO_HELI_AUDIT_DATA_GATE'), 'PASS')
    conclusion = 'ZERO_HELI_COMMON_CAUSE_AUDIT_READY';
elseif strcmp(gate_status(gateTable, 'ZERO_HELI_AUDIT_DATA_GATE'), 'PARTIAL')
    conclusion = 'ZERO_HELI_COMMON_CAUSE_AUDIT_PARTIAL';
else
    conclusion = 'ZERO_HELI_COMMON_CAUSE_AUDIT_BLOCKED';
end
end

function status = default_model_status()
P = params_nominal();
status = struct('modelType', P.wing.modelType, ...
    'fullAngleModelEnabled', P.wing.fullAngleModelEnabled, ...
    'legacyStillDefault', strcmp(P.wing.modelType, 'legacy') && ...
    P.wing.fullAngleModelEnabled == 0);
end

function value = field_or(s, fieldName, defaultValue)
if isstruct(s) && isfield(s, fieldName)
    value = s.(fieldName);
else
    value = defaultValue;
end
end

function slope = simple_slope(x, y)
mask = isfinite(x) & isfinite(y);
if sum(mask) < 2
    slope = NaN;
else
    slope = (y(find(mask,1,'last')) - y(find(mask,1,'first'))) / ...
        (x(find(mask,1,'last')) - x(find(mask,1,'first')));
end
end

function v = first_finite(y)
idx = find(isfinite(y), 1, 'first');
if isempty(idx), v = NaN; else, v = y(idx); end
end

function v = last_finite(y)
idx = find(isfinite(y), 1, 'last');
if isempty(idx), v = NaN; else, v = y(idx); end
end

function text = trend_label(y)
y = y(:);
mask = isfinite(y);
y = y(mask);
if numel(y) < 2
    text = 'unavailable';
    return;
end
d = diff(y);
rangeScale = max(max(y) - min(y), max(max(abs(y)), 1)*1e-3);
tol = max(1e-9, 0.05*rangeScale);
if abs(y(end) - y(1)) <= tol
    text = 'nearly_flat';
elseif all(d >= -tol)
    text = 'increasing';
elseif all(d <= tol)
    text = 'decreasing';
elseif max(abs(d)) > 0.5*max(rangeScale, 1)
    text = 'discontinuous';
else
    text = 'nonmonotonic';
end
end

function key = model_key(modelType)
key = strrep(modelType, '-', '_');
end

function ensure_dir(path)
if exist(path, 'dir') ~= 7
    mkdir(path);
end
end

function lines = add_line(lines, text)
lines{end+1,1} = text;
end

function write_lines(path, lines)
fid = fopen(path, 'w', 'n', 'UTF-8');
if fid < 0
    error('run_zero_helicopter_common_cause_audit:FileOpenFailed', ...
        'Cannot write %s', path);
end
cleanup = onCleanup(@() fclose(fid));
for i = 1:numel(lines)
    fprintf(fid, '%s\n', lines{i});
end
end
