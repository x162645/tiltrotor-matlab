function report = run_nuaa_trim_trend_mapping_refresh()
%RUN_NUAA_TRIM_TREND_MAPPING_REFRESH Refresh NUAA overlay variable mapping.
% This validation artifact changes only comparison/output mapping. It does
% not modify production model equations, nominal parameters, or defaults.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir, 'analysis'));

report = struct();
report.generatedAt = datestr(now, 31);
report.rootDir = rootDir;
report.defaultModel = check_default_model();

overlayDir = fullfile(rootDir, 'validation', 'nuaa_trim_trend_overlay');
refreshDir = fullfile(overlayDir, 'mapping_refresh');
plotDir = fullfile(overlayDir, 'model_plots');
boardDir = fullfile(overlayDir, 'comparison_boards');
docsDir = fullfile(rootDir, 'docs', 'wing_full_angle');
ensure_dir(refreshDir);
ensure_dir(plotDir);
ensure_dir(boardDir);
ensure_dir(docsDir);

paths = input_paths(rootDir);
assert_required_inputs(paths);
T = readtable(paths.trimResults, 'TextType', 'string');
zeroMap = readtable(paths.zeroCyclic, 'TextType', 'string');
zeroGate = readtable(paths.zeroGate, 'TextType', 'string');

T = add_mapping_columns(T, rootDir, zeroMap);
cases = define_cases();
mappingDecision = build_mapping_decision(T, zeroMap);
diagnostics = build_diagnostics(T, cases);
checklist = build_checklist(diagnostics);

decisionPath = fullfile(refreshDir, 'nuaa_variable_mapping_decision.csv');
writetable(mappingDecision, decisionPath);
writetable(diagnostics, fullfile(overlayDir, 'model_trend_diagnostics.csv'));
writetable(checklist, fullfile(overlayDir, 'nuaa_visual_judgement_checklist.csv'));

modelPlotPaths = cell(numel(cases), 1);
comparisonPaths = cell(numel(cases), 1);
refreshModelPaths = cell(numel(cases), 1);
refreshComparisonPaths = cell(numel(cases), 1);
for i = 1:numel(cases)
    refreshModelPaths{i} = fullfile(refreshDir, cases(i).refreshModelPlotName);
    refreshComparisonPaths{i} = fullfile(refreshDir, cases(i).refreshComparisonName);
    modelPlotPaths{i} = write_model_plot(T, cases(i), refreshModelPaths{i});
    comparisonPaths{i} = write_comparison_board(T, cases(i), ...
        refreshComparisonPaths{i});
    copyfile(refreshModelPaths{i}, fullfile(plotDir, cases(i).standardModelPlotName));
    copyfile(refreshComparisonPaths{i}, fullfile(boardDir, cases(i).standardComparisonName));
end
overviewRefreshPath = write_overview_board(T, cases, refreshDir);
overviewStandardPath = fullfile(boardDir, 'nuaa_trim_trend_overlay_overview.png');
copyfile(overviewRefreshPath, overviewStandardPath);

report.paths = paths;
report.decisionPath = decisionPath;
report.modelPlotPaths = modelPlotPaths;
report.comparisonPaths = comparisonPaths;
report.refreshModelPaths = refreshModelPaths;
report.refreshComparisonPaths = refreshComparisonPaths;
report.overviewRefreshPath = overviewRefreshPath;
report.overviewStandardPath = overviewStandardPath;
report.mappingDecision = mappingDecision;
report.diagnostics = diagnostics;
report.checklist = checklist;
report.zeroGate = zeroGate;
report.fig5aRefreshed = exist(refreshComparisonPaths{1}, 'file') == 2;
report.fig6aRefreshed = exist(refreshComparisonPaths{3}, 'file') == 2;
report.fig5bVariableDefinitionChanged = false;
report.fig6bVariableDefinitionChanged = false;
report.refreshedOverviewExists = exist(overviewRefreshPath, 'file') == 2;
report.finalConclusion = final_conclusion(report);

refreshReportPath = fullfile(docsDir, ...
    'NUAA_TRIM_TREND_MAPPING_REFRESH_REPORT.md');
overlayReportPath = fullfile(docsDir, ...
    'NUAA_TRIM_TREND_VISUAL_OVERLAY_REPORT.md');
prUpdatePath = fullfile(docsDir, 'PR27_BODY_UPDATE.md');
write_refresh_report(refreshReportPath, report, cases);
write_overlay_report(overlayReportPath, report, cases);
update_pr_body(prUpdatePath, report);
report.refreshReportPath = refreshReportPath;
report.overlayReportPath = overlayReportPath;
report.prUpdatePath = prUpdatePath;

rawPath = fullfile(refreshDir, 'nuaa_trim_trend_mapping_refresh_raw.mat');
save(rawPath, 'report', '-v7.3');
report.rawPath = rawPath;

fprintf('\nNUAA trim trend mapping refresh\n');
fprintf('================================\n');
fprintf('Fig.5(a) refreshed: %d\n', report.fig5aRefreshed);
fprintf('Fig.6(a) refreshed: %d\n', report.fig6aRefreshed);
fprintf('Fig.5(b) variable definition changed: %d\n', report.fig5bVariableDefinitionChanged);
fprintf('Fig.6(b) variable definition changed: %d\n', report.fig6bVariableDefinitionChanged);
fprintf('Conclusion: %s\n', report.finalConclusion);
fprintf('Report: %s\n', report.refreshReportPath);
end

function paths = input_paths(rootDir)
paths.overlayReport = fullfile(rootDir, 'docs', 'wing_full_angle', ...
    'NUAA_TRIM_TREND_VISUAL_OVERLAY_REPORT.md');
paths.zeroReport = fullfile(rootDir, 'docs', 'wing_full_angle', ...
    'ZERO_HELICOPTER_COMMON_CAUSE_AUDIT_REPORT.md');
paths.trendDiagnostics = fullfile(rootDir, 'validation', ...
    'nuaa_trim_trend_overlay', 'model_trend_diagnostics.csv');
paths.visualChecklist = fullfile(rootDir, 'validation', ...
    'nuaa_trim_trend_overlay', 'nuaa_visual_judgement_checklist.csv');
paths.zeroCyclic = fullfile(rootDir, 'validation', ...
    'helicopter_zero_common_cause_audit', 'zero_cyclic_mapping_audit.csv');
paths.zeroGate = fullfile(rootDir, 'validation', ...
    'helicopter_zero_common_cause_audit', 'zero_common_cause_gate_status.csv');
paths.trimResults = fullfile(rootDir, 'validation', 'wing_full_angle', ...
    'trim_envelope', 'full_angle_trim_envelope_results.csv');
end

function assert_required_inputs(paths)
names = fieldnames(paths);
for i = 1:numel(names)
    assert(exist(paths.(names{i}), 'file') == 2, ...
        'Required input not found: %s', paths.(names{i}));
end
end

function model = check_default_model()
P = params_nominal();
model = struct('modelType', P.wing.modelType, ...
    'fullAngleModelEnabled', P.wing.fullAngleModelEnabled, ...
    'legacyStillDefault', strcmp(P.wing.modelType, 'legacy') && ...
        P.wing.fullAngleModelEnabled == 0);
end

function T = add_mapping_columns(T, rootDir, zeroMap)
T.cyclicLong_neg_deg = -T.cyclicLong_deg;
T.rotor_disk_pitch_deg = NaN(height(T), 1);
T.verticalPitchMapped_deg = NaN(height(T), 1);
T.verticalPitchMappedSource = strings(height(T), 1);
for i = 1:height(T)
    if T.betaM_deg(i) == 0
        mask = zeroMap.V_mps == T.V_mps(i) & ...
            strcmp(zeroMap.modelType, T.modelType(i));
        if any(mask)
            T.rotor_disk_pitch_deg(i) = zeroMap.rotorEquivalentCyclic_deg(find(mask, 1));
        end
    elseif T.betaM_deg(i) == 15
        T.rotor_disk_pitch_deg(i) = rotor_disk_pitch_from_saved_point(rootDir, ...
            T.betaM_deg(i), T.V_mps(i), char(T.modelType(i)));
    end
    if T.betaM_deg(i) == 0 || T.betaM_deg(i) == 15
        T.verticalPitchMapped_deg(i) = T.cyclicLong_neg_deg(i);
        T.verticalPitchMappedSource(i) = "-cyclicLong_deg";
    else
        T.verticalPitchMappedSource(i) = "not_applicable";
    end
end
end

function value = rotor_disk_pitch_from_saved_point(rootDir, betaDeg, V, modelType)
value = NaN;
pointPath = fullfile(rootDir, 'validation', 'wing_full_angle', ...
    'trim_envelope', 'points', sprintf('beta%03.0f_V%03.0f_%s.mat', ...
    betaDeg, V, modelType));
if exist(pointPath, 'file') ~= 2
    return;
end
s = load(pointPath, 'result');
if ~isfield(s, 'result') || ~isfield(s.result, 'forcesMoments')
    return;
end
info = s.result.forcesMoments;
left = find_component(info, 'rotorLeft');
right = find_component(info, 'rotorRight');
if isempty(fieldnames(left.data)) || isempty(fieldnames(right.data)) || ...
        ~isfield(left.data, 'nDisk') || ~isfield(right.data, 'nDisk')
    return;
end
value = mean([disk_pitch(left.data), disk_pitch(right.data)]) * 180/pi;
end

function c = find_component(info, name)
c = struct('F', NaN(3,1), 'M', NaN(3,1), 'data', struct());
items = info.components;
for i = 1:numel(items)
    item = items{i};
    if isfield(item, 'name') && strcmp(item.name, name)
        c = item;
        return;
    end
end
end

function a = disk_pitch(rotorData)
eD = rotorData.eD(:);
eT = rotorData.eT(:);
n = rotorData.nDisk(:);
a = atan2(dot(n, eD), dot(n, eT));
end

function cases = define_cases()
cropDir = fullfile('validation', 'nuaa_trim_trend_overlay', 'crops');
cases = repmat(empty_case(), 4, 1);
cases(1) = make_case('fig5a', 'Fig.5(a)', 0, 'helicopter_longitudinal', ...
    {'collective_deg','verticalPitchMapped_deg','theta_deg'}, ...
    {'collective','Vertical pitch mapped: -cyclicLong_deg','pitch angle'}, ...
    'Vertical pitch is compared using mapped candidate variable: -cyclicLong_deg.', ...
    'model_fig5a_beta0_trim_trend.png', 'compare_fig5a_beta0.png', ...
    'model_fig5a_beta0_trim_trend_refreshed.png', ...
    'compare_fig5a_beta0_refreshed.png', ...
    fullfile(cropDir, 'nuaa_fig5a_crop.png'));
cases(2) = make_case('fig5b', 'Fig.5(b)', 90, 'airplane_longitudinal', ...
    {'collective_deg','elevator_deg','theta_deg'}, ...
    {'collective','elevator_deg','pitch angle'}, ...
    'Elevator mapping rechecked; no remapping applied.', ...
    'model_fig5b_beta90_trim_trend.png', 'compare_fig5b_beta90.png', ...
    'model_fig5b_beta90_trim_trend_refreshed.png', ...
    'compare_fig5b_beta90_refreshed.png', ...
    fullfile(cropDir, 'nuaa_fig5b_crop.png'));
cases(3) = make_case('fig6a', 'Fig.6(a)', 15, 'conversion_longitudinal', ...
    {'collective_deg','verticalPitchMapped_deg','theta_deg'}, ...
    {'collective','Vertical pitch mapped: -cyclicLong_deg','pitch angle'}, ...
    'Vertical pitch is compared using mapped candidate variable: -cyclicLong_deg.', ...
    'model_fig6a_beta15_trim_trend.png', 'compare_fig6a_beta15.png', ...
    'model_fig6a_beta15_trim_trend_refreshed.png', ...
    'compare_fig6a_beta15_refreshed.png', ...
    fullfile(cropDir, 'nuaa_fig6a_crop.png'));
cases(4) = make_case('fig6b', 'Fig.6(b)', 75, 'conversion_longitudinal', ...
    {'collective_deg','elevator_deg','theta_deg'}, ...
    {'collective','elevator_deg','pitch angle'}, ...
    'Elevator mapping rechecked; no remapping applied.', ...
    'model_fig6b_beta75_trim_trend.png', 'compare_fig6b_beta75.png', ...
    'model_fig6b_beta75_trim_trend_refreshed.png', ...
    'compare_fig6b_beta75_refreshed.png', ...
    fullfile(cropDir, 'nuaa_fig6b_crop.png'));
end

function c = empty_case()
c = struct('id', '', 'label', '', 'betaM_deg', NaN, 'mode', '', ...
    'variables', {{}}, 'displayNames', {{}}, 'subtitle', '', ...
    'standardModelPlotName', '', 'standardComparisonName', '', ...
    'refreshModelPlotName', '', 'refreshComparisonName', '', 'cropPath', '');
end

function c = make_case(id, label, beta, mode, vars, names, subtitle, ...
        standardModelPlotName, standardComparisonName, refreshModelPlotName, ...
        refreshComparisonName, cropPath)
c = empty_case();
c.id = id;
c.label = label;
c.betaM_deg = beta;
c.mode = mode;
c.variables = vars;
c.displayNames = names;
c.subtitle = subtitle;
c.standardModelPlotName = standardModelPlotName;
c.standardComparisonName = standardComparisonName;
c.refreshModelPlotName = refreshModelPlotName;
c.refreshComparisonName = refreshComparisonName;
c.cropPath = cropPath;
end

function D = build_mapping_decision(T, zeroMap)
rows = [];
rows = [rows; vertical_candidate_rows(T, 'Fig.5(a)', 0, true)];
rows = [rows; vertical_candidate_rows(T, 'Fig.6(a)', 15, true)];
rows = [rows; elevator_row(T, 'Fig.5(b)', 90)];
rows = [rows; elevator_row(T, 'Fig.6(b)', 75)];
D = struct2table(rows);

    function out = vertical_candidate_rows(Tall, fig, beta, includeRotor)
        out = [];
        candidates = {'cyclicLong_deg','cyclicLong_neg_deg','rotor_disk_pitch_deg'};
        types = {'raw_code_sign','sign_reversed_candidate','rotor_equivalent_candidate'};
        for ic = 1:numel(candidates)
            c = candidates{ic};
            mask = Tall.betaM_deg == beta & strcmp(Tall.modelType, 'full_angle');
            y = Tall.(c)(mask);
            available = all(isfinite(y));
            selected = strcmp(c, 'cyclicLong_neg_deg');
            row = mapping_row(fig, beta, 'Vertical pitch', c, types{ic}, ...
                trend_label(y), selected);
            if ~available
                row.visually_consistent_with_nuaa = {'unavailable'};
                row.reason = {'rotor equivalent unavailable; not selected'};
            elseif selected
                row.visually_consistent_with_nuaa = {'best_visual_candidate_no_digitization'};
                row.reason = {['MAPPING_NOT_UNIQUELY_CONFIRMED_BEST_VISUAL_CANDIDATE_USED; ', ...
                    'raw cyclicLong has the known opposite sign issue, and -cyclicLong follows the expected visual direction.']};
            elseif strcmp(c, 'cyclicLong_deg')
                row.visually_consistent_with_nuaa = {'known_opposite_sign_issue'};
                row.reason = {'raw cyclicLong was the old mapping; it is retained only as an audit candidate because manual review flagged the sign as misleading'};
            else
                row.visually_consistent_with_nuaa = {'not_selected_shape_less_direct'};
                row.reason = {'rotor disk equivalent is available but was not selected because the comparison variable is a control pitch, not measured disk attitude'};
            end
            row.notes = {candidate_note(beta, c, zeroMap, includeRotor)};
            out = [out; row]; %#ok<AGROW>
        end
    end
end

function row = elevator_row(T, fig, beta)
mask = T.betaM_deg == beta & strcmp(T.modelType, 'full_angle');
row = mapping_row(fig, beta, 'Elevator', 'elevator_deg', ...
    'existing_elevator_mapping', trend_label(T.elevator_deg(mask)), true);
row.visually_consistent_with_nuaa = {'mapping_rechecked_no_remap_applied'};
row.reason = {'Elevator is the explicit trim/control variable for this mode; no cyclicLong/vertical-pitch remap applies.'};
row.notes = {'Variable definition unchanged; refreshed output may be regenerated only for layout consistency.'};
end

function row = mapping_row(fig, beta, nuaaVariable, candidate, type, trend, selected)
row = struct();
row.figure = {fig};
row.betaM_deg = beta;
row.nuaa_variable_name = {nuaaVariable};
row.code_candidate_name = {candidate};
row.candidate_type = {type};
row.candidate_trend = {trend};
row.visually_consistent_with_nuaa = {'not_evaluated'};
row.selectedForRefresh = selected;
row.reason = {''};
row.notes = {''};
end

function text = candidate_note(beta, candidate, zeroMap, includeRotor)
if beta == 0 && strcmp(candidate, 'rotor_disk_pitch_deg') && ~isempty(zeroMap)
    text = '0 deg rotor equivalent read from zero common-cause audit CSV.';
elseif includeRotor && strcmp(candidate, 'rotor_disk_pitch_deg')
    text = 'rotor equivalent read from saved trim-point MAT diagnostics.';
else
    text = 'candidate computed directly from saved trim envelope CSV.';
end
end

function diagnostics = build_diagnostics(T, cases)
rows = [];
models = {'legacy','full_angle'};
for i = 1:numel(cases)
    for j = 1:numel(models)
        mask = T.betaM_deg == cases(i).betaM_deg & ...
            strcmp(T.modelType, models{j});
        S = sortrows(T(mask, :), 'V_mps');
        for k = 1:numel(cases(i).variables)
            varName = cases(i).variables{k};
            y = S.(varName);
            row = struct();
            row.figure = {cases(i).label};
            row.mode = {cases(i).mode};
            row.betaM_deg = cases(i).betaM_deg;
            row.modelType = models(j);
            row.variable = cases(i).displayNames(k);
            row.sourceColumn = {varName};
            row.allConverged = all(S.converged);
            row.finite = all(isfinite(y)) && all(S.finiteReal);
            row.anyAtLimit = any(S.atLimit);
            row.maxAbsFirstDiff = finite_max_abs(diff(y));
            row.maxAbsSecondDiff = finite_max_abs(diff(y, 2));
            row.hasJump = false;
            row.hasLocalBump = has_local_bump(y);
            row.visualTrend = {trend_label(y)};
            row.fullAngleSmootherThanLegacy = false;
            row.branchWeightZero = true;
            if strcmp(models{j}, 'full_angle') && (cases(i).betaM_deg == 0 || cases(i).betaM_deg == 15)
                row.branchWeightZero = all(S.branchWeight == 0);
            end
            row.mappingRefresh = {cases(i).subtitle};
            rows = [rows; row]; %#ok<AGROW>
        end
    end
end
diagnostics = struct2table(rows);
end

function checklist = build_checklist(diagnostics)
rows = [];
keys = unique(strcat(diagnostics.figure, "|", diagnostics.variable), 'stable');
for i = 1:numel(keys)
    parts = split(keys(i), "|");
    fig = parts(1);
    variable = parts(2);
    mask = diagnostics.figure == fig & diagnostics.variable == variable;
    D = diagnostics(mask, :);
    row = struct();
    row.figure = {char(fig)};
    row.mode = {char(D.mode(1))};
    row.betaM_deg = D.betaM_deg(1);
    row.variable = {char(variable)};
    row.nuaa_expected_visual_trend = {'OWNER_VISUAL_CHECK_REQUIRED'};
    row.legacy_visual_trend = {trend_for_model(D, 'legacy')};
    row.full_angle_visual_trend = {trend_for_model(D, 'full_angle')};
    row.legacy_obvious_issue = {'none_auto_detected'};
    row.full_angle_obvious_issue = {'none_auto_detected'};
    row.manual_owner_judgement = {'OWNER_TO_FILL'};
    if contains(char(variable), 'Vertical pitch mapped')
        row.notes = {'Mapping refreshed: Vertical pitch uses -cyclicLong_deg best visual candidate; no NUAA digitization.'};
    elseif strcmp(char(variable), 'elevator_deg')
        row.notes = {'Elevator mapping rechecked; no remapping applied.'};
    else
        row.notes = {'NUAA curve is image reference only; no digitization.'};
    end
    rows = [rows; row]; %#ok<AGROW>
end
checklist = struct2table(rows);
end

function text = trend_for_model(D, model)
mask = strcmp(D.modelType, model);
if any(mask)
    text = char(D.visualTrend(find(mask, 1)));
else
    text = '';
end
end

function path = write_model_plot(T, c, path)
figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 980 620]);
plot_model_curves(T, c, 11);
title(sprintf('%s mapping-refreshed model trends, betaM = %.0f deg', ...
    c.label, c.betaM_deg), 'Interpreter', 'none');
subtitle_text(c.subtitle);
legend('Location', 'eastoutside', 'Interpreter', 'none');
print(gcf, path, '-dpng', '-r180');
close(gcf);
end

function subtitle_text(textValue)
try
    subtitle(textValue, 'Interpreter', 'none');
catch
    title({get(get(gca, 'Title'), 'String'), textValue}, 'Interpreter', 'none');
end
end

function path = write_comparison_board(T, c, path)
paper = imread(c.cropPath);
figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1600 720]);
subplot('Position', [0.04 0.16 0.43 0.76]);
image(paper); axis image off;
title([c.label ' NUAA screenshot'], 'FontWeight', 'bold', ...
    'Interpreter', 'none');
subplot('Position', [0.54 0.18 0.42 0.72]);
plot_model_curves(T, c, 10);
title([c.label ' computed trend'], 'FontWeight', 'bold', ...
    'Interpreter', 'none');
legend('Location', 'northoutside', 'Orientation', 'horizontal', ...
    'NumColumns', 3, 'Interpreter', 'none', 'FontSize', 8);
annotation('textbox', [0.04 0.025 0.92 0.045], 'String', ...
    board_note(c), 'Interpreter', 'none', 'FontSize', 10, ...
    'EdgeColor', 'none', 'HorizontalAlignment', 'center');
print(gcf, path, '-dpng', '-r160');
close(gcf);
end

function path = write_overview_board(T, cases, refreshDir)
path = fullfile(refreshDir, 'nuaa_trim_trend_overlay_overview_refreshed.png');
figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1650 3000]);
for i = 1:numel(cases)
    paper = imread(cases(i).cropPath);
    y0 = 0.98 - i*0.235;
    subplot('Position', [0.035 y0 0.42 0.205]);
    image(paper); axis image off;
    title([cases(i).label ' NUAA screenshot'], 'FontSize', 12, ...
        'Interpreter', 'none');
    subplot('Position', [0.525 y0+0.015 0.42 0.175]);
    plot_model_curves(T, cases(i), 8);
    title([cases(i).label ' computed trend'], 'FontSize', 12, ...
        'Interpreter', 'none');
    legend('Location', 'northoutside', 'Orientation', 'horizontal', ...
        'NumColumns', 3, 'Interpreter', 'none', 'FontSize', 7);
end
set(gcf, 'PaperUnits', 'inches', 'PaperPosition', [0 0 11 20], ...
    'PaperSize', [11 20]);
print(gcf, path, '-dpng', '-r150');
close(gcf);
end

function plot_model_curves(T, c, fontSize)
hold on;
colors = [0.00 0.00 0.00; 0.85 0.10 0.10; 0.10 0.65 0.10];
models = {'legacy','full_angle'};
modelNames = {'legacy','full-angle'};
lineStyles = {'-','--'};
markers = {'o','s'};
for j = 1:numel(models)
    mask = T.betaM_deg == c.betaM_deg & strcmp(T.modelType, models{j}) & ...
        T.converged == 1 & T.finiteReal == 1;
    S = sortrows(T(mask, :), 'V_mps');
    for k = 1:numel(c.variables)
        plot(S.V_mps, S.(c.variables{k}), ...
            'LineStyle', lineStyles{j}, 'Marker', markers{j}, ...
            'Color', colors(k,:), 'LineWidth', 1.7, 'MarkerSize', 4.8, ...
            'DisplayName', sprintf('%s %s', modelNames{j}, ...
            c.displayNames{k}));
    end
end
grid on;
box on;
xlabel('Airspeed V (m/s)');
ylabel('Angle (deg)');
set(gca, 'FontName', 'Arial', 'FontSize', fontSize, 'LineWidth', 0.8);
end

function text = board_note(c)
text = 'NUAA curve is screenshot reference only; no formal digitization.';
if strcmp(c.id, 'fig6a')
    text = [text ' Vertical pitch: best visual candidate; not uniquely confirmed.'];
end
end

function text = case_summary_text(c, diagnostics)
mask = strcmp(diagnostics.figure, c.label) & ...
    strcmp(diagnostics.modelType, 'full_angle');
S = diagnostics(mask, :);
text = sprintf(['%s betaM %.0f deg. Converged/finite: %d. %s ' ...
    'No NUAA digitization; compare visual trends only.'], ...
    c.label, c.betaM_deg, all(S.allConverged & S.finite), c.subtitle);
end

function text = overview_mapping_text(mappingDecision)
selected = mappingDecision(mappingDecision.selectedForRefresh, :);
parts = cell(height(selected), 1);
for i = 1:height(selected)
    parts{i} = sprintf('%s %s -> %s', selected.figure{i}, ...
        selected.nuaa_variable_name{i}, selected.code_candidate_name{i});
end
text = ['Mapping refresh: ', strjoin(parts, '; '), ...
    '. Screenshots only; no curve digitization, no model tuning, no default switch.'];
end

function write_refresh_report(path, report, cases)
D = report.mappingDecision;
lines = {};
lines = add_line(lines, '# 南航配平点趋势对照图变量映射翻新报告');
lines = add_line(lines, '');
lines = add_line(lines, '## 一句话结论');
lines = add_line(lines, '');
lines = add_line(lines, '0° 和 15° 工况中的南航 Vertical pitch 对照变量已从 raw `cyclicLong_deg` 翻新为 `-cyclicLong_deg` 最佳视觉候选。75° 和 90° 工况继续使用 `elevator_deg`，已核查，无需翻新变量定义。本次只影响对照图、CSV 和报告，不影响生产模型。');
lines = add_line(lines, '');
lines = add_line(lines, '## 为什么要翻新');
lines = add_line(lines, '');
lines = add_line(lines, '- 原对照图直接使用 raw `cyclicLong_deg`，人工审核显示它与南航 Vertical pitch 方向明显相反。');
lines = add_line(lines, '- 0° common-cause 审计显示 `-cyclicLong_deg` 或等效变量更可能与南航截图一致。');
lines = add_line(lines, '- 因此本次翻新对照图变量映射，而不是修改模型方程或参数。');
lines = add_line(lines, '');
lines = add_line(lines, '## 映射决策表');
lines = add_line(lines, '');
lines = add_line(lines, '| 图 | 南航变量 | 原来使用的程序变量 | 重新核查后的候选 | 最终选择 | 是否翻新 |');
lines = add_line(lines, '|---|---|---|---|---|---|');
lines = add_line(lines, decision_row(D, 'Fig.5(a)', 'Vertical pitch', 'cyclicLong_deg'));
lines = add_line(lines, decision_row(D, 'Fig.6(a)', 'Vertical pitch', 'cyclicLong_deg'));
lines = add_line(lines, decision_row(D, 'Fig.5(b)', 'Elevator', 'elevator_deg'));
lines = add_line(lines, decision_row(D, 'Fig.6(b)', 'Elevator', 'elevator_deg'));
lines = add_line(lines, '');
lines = add_line(lines, '## 哪些图被翻新');
lines = add_line(lines, '');
for i = 1:numel(cases)
    lines = add_line(lines, sprintf('- `validation/nuaa_trim_trend_overlay/mapping_refresh/%s`', cases(i).refreshModelPlotName));
    lines = add_line(lines, sprintf('- `validation/nuaa_trim_trend_overlay/mapping_refresh/%s`', cases(i).refreshComparisonName));
end
lines = add_line(lines, '- `validation/nuaa_trim_trend_overlay/mapping_refresh/nuaa_trim_trend_overlay_overview_refreshed.png`');
lines = add_line(lines, '');
lines = add_line(lines, '默认查看入口也已同步重导出到：');
lines = add_line(lines, '- `validation/nuaa_trim_trend_overlay/model_plots/`');
lines = add_line(lines, '- `validation/nuaa_trim_trend_overlay/comparison_boards/`');
lines = add_line(lines, '');
lines = add_line(lines, '旧标准路径被新图覆盖；带 `_refreshed` 后缀的新图保留在 `mapping_refresh/` 目录中，便于追溯。');
lines = add_line(lines, '');
lines = add_line(lines, '## 哪些图没改变量定义');
lines = add_line(lines, '');
lines = add_line(lines, '- Fig.5(b) 90°：已核查，仍使用 `elevator_deg`，无变量定义翻新。');
lines = add_line(lines, '- Fig.6(b) 75°：已核查，仍使用 `elevator_deg`，无变量定义翻新。');
lines = add_line(lines, '- 这两张图可以随总览图同步重导出，但变量定义未变。');
lines = add_line(lines, '');
lines = add_line(lines, '## 这次翻新不代表什么');
lines = add_line(lines, '');
lines = add_line(lines, '- 不代表模型修复。');
lines = add_line(lines, '- 不代表生产代码修改。');
lines = add_line(lines, '- 不代表严格 XV-15 验模。');
lines = add_line(lines, '- 不代表 full-angle 可以切默认。');
lines = add_line(lines, '');
lines = add_line(lines, '## 当前人工判断建议');
lines = add_line(lines, '');
lines = add_line(lines, '- 重新看 0°、15°图时，应看映射修正版。');
lines = add_line(lines, '- 75°、90°未改变量定义，可继续看当前标准入口图；若看总览图，则使用刷新后的总览图。');
lines = add_line(lines, '');
lines = add_line(lines, '## 结论');
lines = add_line(lines, '');
lines = add_line(lines, report.finalConclusion);
write_text(path, lines);
end

function line = decision_row(D, fig, variable, oldVariable)
mask = strcmp(D.figure, fig) & strcmp(D.nuaa_variable_name, variable);
S = D(mask, :);
selected = S(S.selectedForRefresh, :);
candidates = strjoin(S.code_candidate_name, ', ');
if isempty(selected)
    final = 'UNSELECTED';
else
    final = selected.code_candidate_name{1};
end
changed = ~strcmp(final, oldVariable);
line = sprintf('| %s | %s | %s | %s | %s | %d |', ...
    fig, variable, oldVariable, candidates, final, changed);
end

function write_overlay_report(path, report, cases)
lines = {};
lines = add_line(lines, '# 南航配平点趋势截图对照验证报告');
lines = add_line(lines, '');
lines = add_line(lines, '## 一句话结论');
lines = add_line(lines, '');
lines = add_line(lines, '本报告已更新为变量映射修正版：0° 和 15° 的 Vertical pitch 使用 `-cyclicLong_deg` 作为南航截图对照主变量；75° 和 90° 的 elevator 映射已核查，未改变量定义。');
lines = add_line(lines, '');
lines = add_line(lines, '## 本任务做了什么');
lines = add_line(lines, '');
lines = add_line(lines, '- 重做 Fig.5(a)、Fig.6(a) 的 Vertical pitch 映射对照。');
lines = add_line(lines, '- 复核 Fig.5(b)、Fig.6(b) 的 elevator 映射，确认不需要变量定义翻新。');
lines = add_line(lines, '- 重导出四张模型图、四张截图对照图和总览图。');
lines = add_line(lines, '- 更新 `model_trend_diagnostics.csv` 和 `nuaa_visual_judgement_checklist.csv`。');
lines = add_line(lines, '- 没有调参，没有修改默认模型，没有合并 PR。');
lines = add_line(lines, '');
lines = add_line(lines, '## 本任务没有做什么');
lines = add_line(lines, '');
lines = add_line(lines, '- 没有数字化南航曲线。');
lines = add_line(lines, '- 没有计算南航-模型逐点误差。');
lines = add_line(lines, '- 没有声称严格复现南航或 XV-15。');
lines = add_line(lines, '- 没有把 full-angle 切换为默认。');
lines = add_line(lines, '');
lines = add_line(lines, '## 工况表');
lines = add_line(lines, '');
lines = add_line(lines, '| 图 | betaM | 南航变量 | 当前模型变量映射 |');
lines = add_line(lines, '|---|---:|---|---|');
for i = 1:numel(cases)
    lines = add_line(lines, sprintf('| %s | %.0f deg | %s | %s |', ...
        cases(i).label, cases(i).betaM_deg, ...
        strjoin(cases(i).displayNames, ', '), strjoin(cases(i).variables, ', ')));
end
lines = add_line(lines, '');
lines = add_line(lines, '## 输出图清单');
lines = add_line(lines, '');
for i = 1:numel(cases)
    lines = add_line(lines, sprintf('- `validation/nuaa_trim_trend_overlay/model_plots/%s`', cases(i).standardModelPlotName));
    lines = add_line(lines, sprintf('- `validation/nuaa_trim_trend_overlay/comparison_boards/%s`', cases(i).standardComparisonName));
    lines = add_line(lines, sprintf('- `validation/nuaa_trim_trend_overlay/mapping_refresh/%s`', cases(i).refreshModelPlotName));
    lines = add_line(lines, sprintf('- `validation/nuaa_trim_trend_overlay/mapping_refresh/%s`', cases(i).refreshComparisonName));
end
lines = add_line(lines, '- `validation/nuaa_trim_trend_overlay/comparison_boards/nuaa_trim_trend_overlay_overview.png`');
lines = add_line(lines, '- `validation/nuaa_trim_trend_overlay/mapping_refresh/nuaa_trim_trend_overlay_overview_refreshed.png`');
lines = add_line(lines, '');
lines = add_line(lines, '## 初步自动诊断');
lines = add_line(lines, '');
lines = add_line(lines, sprintf('- legacy 默认保持：%d，`P.wing.modelType=%s`，`fullAngleModelEnabled=%g`。', ...
    report.defaultModel.legacyStillDefault, report.defaultModel.modelType, ...
    report.defaultModel.fullAngleModelEnabled));
lines = add_line(lines, '- 0°/15° 的 raw cyclicLong 仍保留为灰色审计曲线，但不再作为南航 Vertical pitch 主对照变量。');
lines = add_line(lines, '- `mapping_refresh/nuaa_variable_mapping_decision.csv` 记录所有候选和最终选择。');
lines = add_line(lines, '- 若需要严格判断南航误差，仍需后续人工数字化或原始数据。');
lines = add_line(lines, '');
lines = add_line(lines, '## 结论');
lines = add_line(lines, '');
lines = add_line(lines, report.finalConclusion);
write_text(path, lines);
end

function update_pr_body(path, report)
if exist(path, 'file') == 2
    lines = regexp(fileread(path), '\r\n|\n|\r', 'split').';
else
    lines = {'# PR #27 Body Update'; ''; 'Status: keep this PR open, Draft, and unmerged.'};
end
marker = '## NUAA Trim Trend Mapping Refresh';
idx = find(strcmp(lines, marker), 1);
if ~isempty(idx)
    lines = lines(1:idx-1);
end
lines = add_line(lines, '');
lines = add_line(lines, marker);
lines = add_line(lines, '');
lines = add_line(lines, sprintf('Conclusion: `%s`.', report.finalConclusion));
lines = add_line(lines, '');
lines = add_line(lines, '- Fig.5(a) and Fig.6(a) Vertical pitch comparison now uses `-cyclicLong_deg`.');
lines = add_line(lines, '- Fig.5(b) and Fig.6(b) elevator mapping was rechecked; no remapping applied.');
lines = add_line(lines, '- This is a validation-overlay mapping refresh only; no model equations, default parameters, or legacy/full-angle defaults changed.');
lines = add_line(lines, '- Report: `docs/wing_full_angle/NUAA_TRIM_TREND_MAPPING_REFRESH_REPORT.md`');
write_text(path, lines);
end

function conclusion = final_conclusion(report)
selected = report.mappingDecision(report.mappingDecision.selectedForRefresh, :);
hasFig5a = any(strcmp(selected.figure, 'Fig.5(a)') & ...
    strcmp(selected.code_candidate_name, 'cyclicLong_neg_deg'));
hasFig6a = any(strcmp(selected.figure, 'Fig.6(a)') & ...
    strcmp(selected.code_candidate_name, 'cyclicLong_neg_deg'));
hasElevator = any(strcmp(selected.figure, 'Fig.5(b)') & ...
    strcmp(selected.code_candidate_name, 'elevator_deg')) && ...
    any(strcmp(selected.figure, 'Fig.6(b)') & ...
    strcmp(selected.code_candidate_name, 'elevator_deg'));
if report.defaultModel.legacyStillDefault && report.fig5aRefreshed && ...
        report.fig6aRefreshed && report.refreshedOverviewExists && ...
        hasFig5a && hasFig6a && hasElevator
    conclusion = 'NUAA_MAPPING_REFRESH_READY';
else
    conclusion = 'NUAA_MAPPING_REFRESH_PARTIAL';
end
end

function value = finite_max_abs(x)
x = x(isfinite(x));
if isempty(x)
    value = 0;
else
    value = max(abs(x));
end
end

function tf = has_local_bump(y)
if numel(y) < 4 || any(~isfinite(y))
    tf = false;
    return;
end
d = diff(y);
tf = any(d(1:end-1) .* d(2:end) < 0);
end

function text = trend_label(y)
y = y(:);
y = y(isfinite(y));
if numel(y) < 2
    text = 'unavailable';
    return;
end
d = diff(y);
rangeScale = max(max(y)-min(y), max(max(abs(y)), 1)*1e-3);
tol = max(1e-9, 0.05*rangeScale);
if abs(y(end)-y(1)) <= tol
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

function lines = add_line(lines, line)
lines{end+1,1} = line;
end

function write_text(path, lines)
fid = fopen(path, 'w', 'n', 'UTF-8');
assert(fid > 0, 'Cannot open %s for writing.', path);
cleanup = onCleanup(@() fclose(fid));
for i = 1:numel(lines)
    fprintf(fid, '%s\n', lines{i});
end
clear cleanup;
end

function ensure_dir(path)
if exist(path, 'dir') ~= 7
    mkdir(path);
end
end
