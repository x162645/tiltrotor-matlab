function report = run_nuaa_trim_trend_visual_overlay()
%RUN_NUAA_TRIM_TREND_VISUAL_OVERLAY Build NUAA screenshot/model trend boards.
% This validation artifact uses the NUAA paper figures as image references
% only. It does not digitize NUAA curves, tune parameters, or modify the
% production model/default dispatch.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);

report = struct();
report.generatedAt = datestr(now, 31);
report.rootDir = rootDir;
report.pdfPath = find_nuaa_pdf(rootDir);
report.pdfFound = exist(report.pdfPath, 'file') == 2;
report.defaultModel = check_default_model();

outRoot = fullfile(rootDir, 'validation', 'nuaa_trim_trend_overlay');
sourceDir = fullfile(outRoot, 'source_pages');
cropDir = fullfile(outRoot, 'crops');
plotDir = fullfile(outRoot, 'model_plots');
boardDir = fullfile(outRoot, 'comparison_boards');
ensure_dir(sourceDir);
ensure_dir(cropDir);
ensure_dir(plotDir);
ensure_dir(boardDir);

cases = define_cases();
if report.pdfFound
    pageImage = render_nuaa_page(report.pdfPath, sourceDir);
    report.sourcePage = pageImage;
    report.cropTable = write_source_pages_and_crops(pageImage, cases, ...
        sourceDir, cropDir);
else
    report.sourcePage = '';
    report.cropTable = table();
end

resultsPath = fullfile(rootDir, 'validation', 'wing_full_angle', ...
    'trim_envelope', 'full_angle_trim_envelope_results.csv');
summaryPath = fullfile(rootDir, 'validation', 'wing_full_angle', ...
    'trim_envelope', 'full_angle_trim_envelope_summary.csv');
T = readtable(resultsPath, 'FileType', 'text');
T.verticalPitchMapped_deg = -T.cyclicLong_deg;
S = readtable(summaryPath, 'FileType', 'text');
report.resultsPath = resultsPath;
report.summaryPath = summaryPath;
report.modelDataCoverage = check_model_data_coverage(T, cases);
report.modelDataComplete = all(report.modelDataCoverage.complete);

[diagnostics, checklist] = make_diagnostics_and_checklist(T, cases);
diagnosticsPath = fullfile(outRoot, 'model_trend_diagnostics.csv');
checklistPath = fullfile(outRoot, 'nuaa_visual_judgement_checklist.csv');
writetable(diagnostics, diagnosticsPath);
writetable(checklist, checklistPath);
report.diagnosticsPath = diagnosticsPath;
report.checklistPath = checklistPath;

modelPlotPaths = cell(numel(cases), 1);
comparisonPaths = cell(numel(cases), 1);
for i = 1:numel(cases)
    modelPlotPaths{i} = write_model_plot(T, cases(i), plotDir);
    if report.pdfFound
        comparisonPaths{i} = write_comparison_board(T, cases(i), ...
            boardDir);
    else
        comparisonPaths{i} = '';
    end
end
report.modelPlotPaths = modelPlotPaths;
report.comparisonPaths = comparisonPaths;
report.overviewPath = '';
if report.pdfFound
    report.overviewPath = write_overview_board(T, cases, boardDir);
end

report.cropsComplete = report.pdfFound && all(cellfun(@(p) exist(p, 'file') == 2, ...
    {cases.cropPath}.'));
report.comparisonBoardsComplete = report.pdfFound && ...
    all(cellfun(@(p) exist(p, 'file') == 2, comparisonPaths)) && ...
    exist(report.overviewPath, 'file') == 2;
report.modelPlotsComplete = all(cellfun(@(p) exist(p, 'file') == 2, modelPlotPaths));
report.finalConclusion = final_conclusion(report);

reportPath = fullfile(rootDir, 'docs', 'wing_full_angle', ...
    'NUAA_TRIM_TREND_VISUAL_OVERLAY_REPORT.md');
write_report(reportPath, report, cases, diagnostics, checklist, S);
report.reportPath = reportPath;

prUpdatePath = fullfile(rootDir, 'docs', 'wing_full_angle', ...
    'PR27_BODY_UPDATE.md');
update_pr_body(prUpdatePath, report);
report.prUpdatePath = prUpdatePath;

rawPath = fullfile(outRoot, 'nuaa_trim_trend_visual_overlay_raw.mat');
save(rawPath, 'report', '-v7.3');
report.rawPath = rawPath;

fprintf('\nNUAA trim trend visual overlay\n');
fprintf('==============================\n');
fprintf('PDF found: %d\n', report.pdfFound);
fprintf('Crops complete: %d\n', report.cropsComplete);
fprintf('Comparison boards complete: %d\n', report.comparisonBoardsComplete);
fprintf('Model data complete: %d\n', report.modelDataComplete);
fprintf('Conclusion: %s\n', report.finalConclusion);
fprintf('Report: %s\n', report.reportPath);
end

function pdfPath = find_nuaa_pdf(rootDir)
candidates = { ...
    fullfile(rootDir, 'references', 'NUAA_main_paper.pdf'), ...
    fullfile(rootDir, 'references', 'NUAA_main_paper.PDF')};
pdfPath = candidates{1};
for i = 1:numel(candidates)
    if exist(candidates{i}, 'file') == 2
        pdfPath = candidates{i};
        return;
    end
end
files = dir(fullfile(rootDir, '**', '*.pdf'));
for i = 1:numel(files)
    if contains(lower(files(i).name), 'nuaa')
        pdfPath = fullfile(files(i).folder, files(i).name);
        return;
    end
end
end

function model = check_default_model()
P = params_nominal();
model = struct('modelType', P.wing.modelType, ...
    'fullAngleModelEnabled', P.wing.fullAngleModelEnabled, ...
    'legacyStillDefault', strcmp(P.wing.modelType, 'legacy') && ...
        P.wing.fullAngleModelEnabled == 0);
end

function cases = define_cases()
outRoot = fullfile('validation', 'nuaa_trim_trend_overlay');
cropDir = fullfile(outRoot, 'crops');
cases = repmat(empty_case(), 4, 1);
cases(1) = make_case('fig5a', 'Fig.5(a)', 0, ...
    'helicopter_longitudinal', [0 5 10 12 15 20 25 30], ...
    {'collective_deg','verticalPitchMapped_deg','theta_deg'}, ...
    {'collective','vertical pitch candidate (-cyclicLong)','pitch angle'}, ...
    'model_fig5a_beta0_trim_trend.png', ...
    'compare_fig5a_beta0.png', ...
    fullfile(cropDir, 'nuaa_fig5a_crop.png'), ...
    [140 250 760 620]);
cases(2) = make_case('fig5b', 'Fig.5(b)', 90, ...
    'airplane_longitudinal', [70 85 100 115 130 145 150], ...
    {'collective_deg','elevator_deg','theta_deg'}, ...
    {'collective','elevator','pitch angle'}, ...
    'model_fig5b_beta90_trim_trend.png', ...
    'compare_fig5b_beta90.png', ...
    fullfile(cropDir, 'nuaa_fig5b_crop.png'), ...
    [890 250 740 620]);
cases(3) = make_case('fig6a', 'Fig.6(a)', 15, ...
    'conversion_longitudinal', [10 20 30 40 50 60], ...
    {'collective_deg','verticalPitchMapped_deg','theta_deg'}, ...
    {'collective','vertical pitch candidate (-cyclicLong)','pitch angle'}, ...
    'model_fig6a_beta15_trim_trend.png', ...
    'compare_fig6a_beta15.png', ...
    fullfile(cropDir, 'nuaa_fig6a_crop.png'), ...
    [140 950 760 570]);
cases(4) = make_case('fig6b', 'Fig.6(b)', 75, ...
    'conversion_longitudinal', [70 85 100 115 130 145], ...
    {'collective_deg','elevator_deg','theta_deg'}, ...
    {'collective','elevator','pitch angle'}, ...
    'model_fig6b_beta75_trim_trend.png', ...
    'compare_fig6b_beta75.png', ...
    fullfile(cropDir, 'nuaa_fig6b_crop.png'), ...
    [890 950 740 570]);
end

function c = empty_case()
c = struct('id', '', 'label', '', 'betaM_deg', NaN, 'mode', '', ...
    'requiredSpeeds', [], 'variables', {{}}, 'displayNames', {{}}, ...
    'modelPlotName', '', 'comparisonName', '', 'cropPath', '', ...
    'cropBox', []);
end

function c = make_case(id, label, beta, mode, speeds, vars, names, ...
        modelPlotName, comparisonName, cropPath, cropBox)
c = empty_case();
c.id = id;
c.label = label;
c.betaM_deg = beta;
c.mode = mode;
c.requiredSpeeds = speeds;
c.variables = vars;
c.displayNames = names;
c.modelPlotName = modelPlotName;
c.comparisonName = comparisonName;
c.cropPath = cropPath;
c.cropBox = cropBox;
end

function pageImage = render_nuaa_page(pdfPath, sourceDir)
prefix = fullfile(sourceDir, 'nuaa_page10');
existing = [prefix '-10.png'];
if exist(existing, 'file') ~= 2
    exe = poppler_exe('pdftoppm.exe');
    cmd = sprintf('"%s" -f 10 -l 10 -r 220 -png "%s" "%s"', ...
        exe, pdfPath, prefix);
    [status, output] = system(cmd);
    assert(status == 0, 'pdftoppm failed: %s', output);
end
pageImage = existing;
end

function exe = poppler_exe(name)
base = fullfile(getenv('USERPROFILE'), '.cache', 'codex-runtimes', ...
    'codex-primary-runtime', 'dependencies', 'native', 'poppler', ...
    'Library', 'bin', name);
if exist(base, 'file') == 2
    exe = base;
    return;
end
[status, pathText] = system(['where ' name]);
assert(status == 0, 'Cannot find %s.', name);
parts = regexp(strtrim(pathText), '\r\n|\n|\r', 'split');
exe = parts{1};
end

function cropTable = write_source_pages_and_crops(pageImage, cases, sourceDir, cropDir)
img = imread(pageImage);
rows = cell(numel(cases), 6);
for i = 1:numel(cases)
    sourceName = sprintf('nuaa_%s_source_page.png', cases(i).id);
    copyfile(pageImage, fullfile(sourceDir, sourceName));
    crop = crop_image(img, cases(i).cropBox);
    cropPath = fullfile(fileparts(fileparts(fileparts(fileparts(pageImage)))), ...
        cases(i).cropPath);
    imwrite(crop, cropPath);
    rows(i,:) = {cases(i).label, cases(i).betaM_deg, ...
        fullfile(sourceDir, sourceName), cropPath, ...
        mat2str(cases(i).cropBox), 'PDF page 10 / article page 10'};
end
cropTable = cell2table(rows, 'VariableNames', {'figure','betaM_deg', ...
    'sourcePagePath','cropPath','cropBoxPixels','pageNote'});
writetable(cropTable, fullfile(cropDir, 'nuaa_crop_manifest.csv'));
end

function crop = crop_image(img, box)
x = max(1, box(1));
y = max(1, box(2));
w = box(3);
h = box(4);
x2 = min(size(img, 2), x + w - 1);
y2 = min(size(img, 1), y + h - 1);
crop = img(y:y2, x:x2, :);
end

function coverage = check_model_data_coverage(T, cases)
rows = repmat(struct('figure','', 'betaM_deg',NaN, 'modelType','', ...
    'requiredSpeeds','', 'availableSpeeds','', 'complete',false, ...
    'modeMatches',false, 'notes',''), 0, 1);
models = {'legacy','full_angle'};
for i = 1:numel(cases)
    for j = 1:numel(models)
        mask = T.betaM_deg == cases(i).betaM_deg & ...
            strcmp(T.modelType, models{j});
        S = T(mask, :);
        row = struct();
        row.figure = cases(i).label;
        row.betaM_deg = cases(i).betaM_deg;
        row.modelType = models{j};
        row.requiredSpeeds = join_numbers(cases(i).requiredSpeeds);
        row.availableSpeeds = join_numbers(sort(S.V_mps(:).'));
        row.complete = all(ismember(cases(i).requiredSpeeds, S.V_mps(:).'));
        row.modeMatches = all(strcmp(S.mode, cases(i).mode));
        row.notes = '';
        if ~row.complete
            row.notes = 'missing required speeds';
        elseif ~row.modeMatches
            row.notes = 'mode mismatch';
        end
        rows(end+1,1) = row; %#ok<AGROW>
    end
end
coverage = struct2table(rows, 'AsArray', true);
end

function text = join_numbers(values)
if isempty(values)
    text = '';
    return;
end
parts = arrayfun(@(v) sprintf('%.12g', v), values, 'UniformOutput', false);
text = strjoin(parts, ', ');
end

function [diagnostics, checklist] = make_diagnostics_and_checklist(T, cases)
diagRows = repmat(empty_diag_row(), 0, 1);
checkRows = repmat(empty_check_row(), 0, 1);
models = {'legacy','full_angle'};
for i = 1:numel(cases)
    secondByModel = containers.Map();
    for j = 1:numel(models)
        mask = T.betaM_deg == cases(i).betaM_deg & strcmp(T.modelType, models{j});
        S = sortrows(T(mask, :), 'V_mps');
        for k = 1:numel(cases(i).variables)
            varName = cases(i).variables{k};
            y = S.(varName);
            x = S.V_mps;
            d1 = diff(y);
            d2 = diff(y, 2);
            row = empty_diag_row();
            row.figure = cases(i).label;
            row.mode = cases(i).mode;
            row.betaM_deg = cases(i).betaM_deg;
            row.modelType = models{j};
            row.variable = cases(i).displayNames{k};
            row.sourceColumn = varName;
            row.allConverged = all(S.converged);
            row.finite = all(isfinite(y)) && all(S.finiteReal);
            row.anyAtLimit = any(S.atLimit);
            row.maxAbsFirstDiff = finite_max_abs(d1);
            row.maxAbsSecondDiff = finite_max_abs(d2);
            row.hasJump = row.maxAbsFirstDiff > jump_threshold(varName, cases(i).betaM_deg);
            row.hasLocalBump = has_local_bump(y);
            row.visualTrend = trend_label(y);
            row.branchWeightZero = true;
            if strcmp(models{j}, 'full_angle') && cases(i).betaM_deg == 0
                row.branchWeightZero = all(S.branchWeight == 0);
            end
            row.fullAngleSmootherThanLegacy = false;
            diagRows(end+1,1) = row; %#ok<AGROW>
            secondByModel([models{j} '_' varName]) = row.maxAbsSecondDiff;

            chk = empty_check_row();
            chk.figure = cases(i).label;
            chk.mode = cases(i).mode;
            chk.betaM_deg = cases(i).betaM_deg;
            chk.variable = cases(i).displayNames{k};
            chk.nuaa_expected_visual_trend = 'OWNER_VISUAL_CHECK_REQUIRED';
            if strcmp(models{j}, 'legacy')
                chk.legacy_visual_trend = row.visualTrend;
                chk.legacy_obvious_issue = issue_text(row);
            else
                idx = find(strcmp({checkRows.figure}, cases(i).label) & ...
                    strcmp({checkRows.variable}, cases(i).displayNames{k}), 1);
                if isempty(idx)
                    chk.full_angle_visual_trend = row.visualTrend;
                    chk.full_angle_obvious_issue = issue_text(row);
                    chk.manual_owner_judgement = 'OWNER_TO_FILL';
                    chk.notes = 'NUAA curve is image reference only; no digitization.';
                    checkRows(end+1,1) = chk; %#ok<AGROW>
                else
                    checkRows(idx).full_angle_visual_trend = row.visualTrend;
                    checkRows(idx).full_angle_obvious_issue = issue_text(row);
                end
            end
            if strcmp(models{j}, 'legacy')
                chk.full_angle_visual_trend = '';
                chk.full_angle_obvious_issue = '';
                chk.manual_owner_judgement = 'OWNER_TO_FILL';
                chk.notes = 'NUAA curve is image reference only; no digitization.';
                checkRows(end+1,1) = chk; %#ok<AGROW>
            end
        end
    end
    for k = 1:numel(cases(i).variables)
        varName = cases(i).variables{k};
        legacyKey = ['legacy_' varName];
        fullKey = ['full_angle_' varName];
        if isKey(secondByModel, legacyKey) && isKey(secondByModel, fullKey)
            smoother = secondByModel(fullKey) <= secondByModel(legacyKey);
            for r = 1:numel(diagRows)
                if strcmp(diagRows(r).figure, cases(i).label) && ...
                        strcmp(diagRows(r).sourceColumn, varName) && ...
                        strcmp(diagRows(r).modelType, 'full_angle')
                    diagRows(r).fullAngleSmootherThanLegacy = smoother;
                end
            end
        end
    end
end
diagnostics = struct2table(diagRows, 'AsArray', true);
checklist = struct2table(checkRows, 'AsArray', true);
end

function row = empty_diag_row()
row = struct('figure','', 'mode','', 'betaM_deg',NaN, 'modelType','', ...
    'variable','', 'sourceColumn','', 'allConverged',false, ...
    'finite',false, 'anyAtLimit',false, 'maxAbsFirstDiff',NaN, ...
    'maxAbsSecondDiff',NaN, 'hasJump',false, 'hasLocalBump',false, ...
    'visualTrend','', 'fullAngleSmootherThanLegacy',false, ...
    'branchWeightZero',true);
end

function row = empty_check_row()
row = struct('figure','', 'mode','', 'betaM_deg',NaN, 'variable','', ...
    'nuaa_expected_visual_trend','OWNER_VISUAL_CHECK_REQUIRED', ...
    'legacy_visual_trend','', 'full_angle_visual_trend','', ...
    'legacy_obvious_issue','', 'full_angle_obvious_issue','', ...
    'manual_owner_judgement','OWNER_TO_FILL', 'notes','');
end

function value = finite_max_abs(x)
x = x(isfinite(x));
if isempty(x)
    value = 0;
else
    value = max(abs(x));
end
end

function threshold = jump_threshold(varName, beta)
if strcmp(varName, 'collective_deg')
    threshold = 12;
elseif beta == 0
    threshold = 8;
else
    threshold = 15;
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
if numel(y) < 2 || any(~isfinite(y))
    text = 'unclear';
    return;
end
d = diff(y);
scale = max(max(abs(y)), 1);
if max(abs(d)) < 0.02*scale
    text = 'nearly_flat';
elseif all(d >= -0.05*scale)
    text = 'increasing';
elseif all(d <= 0.05*scale)
    text = 'decreasing';
elseif max(abs(d)) > 0.35*scale
    text = 'discontinuous';
else
    text = 'nonmonotonic';
end
end

function text = issue_text(row)
issues = {};
if ~row.allConverged
    issues{end+1} = 'not_all_converged'; %#ok<AGROW>
end
if ~row.finite
    issues{end+1} = 'nonfinite'; %#ok<AGROW>
end
if row.anyAtLimit
    issues{end+1} = 'control_at_limit'; %#ok<AGROW>
end
if row.hasJump
    issues{end+1} = 'jump_candidate'; %#ok<AGROW>
end
if isempty(issues)
    text = 'none_auto_detected';
else
    text = strjoin(issues, ';');
end
end

function path = write_model_plot(T, c, plotDir)
path = fullfile(plotDir, c.modelPlotName);
figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 980 620]);
plot_model_curves(T, c, 11);
title(sprintf('%s model trim trends, betaM = %.0f deg, %s', ...
    c.label, c.betaM_deg, strrep(c.mode, '_', '\_')));
legend('Location', 'eastoutside', 'Interpreter', 'none');
print(gcf, path, '-dpng', '-r180');
close(gcf);
end

function path = write_comparison_board(T, c, boardDir)
path = fullfile(boardDir, c.comparisonName);
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

function path = write_overview_board(T, cases, boardDir)
path = fullfile(boardDir, 'nuaa_trim_trend_overlay_overview.png');
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
smoothCount = sum(S.fullAngleSmootherThanLegacy);
branchText = '';
if c.betaM_deg == 0
    branchText = sprintf(' branchWeight=0: %d.', all(S.branchWeightZero));
end
text = sprintf(['%s betaM %.0f deg. Model data converged/finite: %d. ' ...
    'Full-angle smoother variables vs legacy: %d/%d.%s Owner should judge ' ...
    'visual trend against the left screenshot; no NUAA digitization was used.'], ...
    c.label, c.betaM_deg, all(S.allConverged & S.finite), ...
    smoothCount, height(S), branchText);
end

function write_report(path, report, cases, diagnostics, checklist, summaryTable)
lines = {};
lines = add_line(lines, '# 南航配平点趋势截图对照验证报告');
lines = add_line(lines, '');
lines = add_line(lines, '## 一句话结论');
lines = add_line(lines, '');
lines = add_line(lines, '本任务未数字化南航曲线，只将南航原图截图与当前 legacy/full-angle 模型曲线同版式并排，用于人工趋势判断。');
lines = add_line(lines, '');
lines = add_line(lines, '## 本任务做了什么');
lines = add_line(lines, '');
lines = add_line(lines, '- 截取了 Fig.5(a)、Fig.5(b)、Fig.6(a)、Fig.6(b)。');
lines = add_line(lines, '- 复用当前真实完成的 legacy/full_angle 配平包线结果。');
lines = add_line(lines, '- 生成了四张对照图和一张总览图。');
lines = add_line(lines, '- 没有调参。');
lines = add_line(lines, '- 没有修改默认模型。');
lines = add_line(lines, '- 没有合并 PR。');
lines = add_line(lines, '');
lines = add_line(lines, '## 本任务没有做什么');
lines = add_line(lines, '');
lines = add_line(lines, '- 没有数字化南航曲线。');
lines = add_line(lines, '- 没有计算南航-模型逐点误差。');
lines = add_line(lines, '- 没有声称严格复现南航。');
lines = add_line(lines, '- 没有声称严格 XV-15 验证。');
lines = add_line(lines, '');
lines = add_line(lines, '## 工况表');
lines = add_line(lines, '');
lines = add_line(lines, '| 图 | betaM | V范围 | 南航变量 | 模型变量 |');
lines = add_line(lines, '|---|---:|---|---|---|');
for i = 1:numel(cases)
    lines = add_line(lines, sprintf('| %s | %.0f deg | %s m/s | %s | %s |', ...
        cases(i).label, cases(i).betaM_deg, ...
        range_list(cases(i).requiredSpeeds), ...
        strjoin(cases(i).displayNames, ', '), ...
        strjoin(cases(i).variables, ', ')));
end
lines = add_line(lines, '');
lines = add_line(lines, '## 输出图清单');
lines = add_line(lines, '');
for i = 1:numel(cases)
    lines = add_line(lines, sprintf('- `%s`', rel_path(cases(i).cropPath)));
    lines = add_line(lines, sprintf('- `%s`', rel_path(fullfile('validation', 'nuaa_trim_trend_overlay', 'model_plots', cases(i).modelPlotName))));
    lines = add_line(lines, sprintf('- `%s`', rel_path(fullfile('validation', 'nuaa_trim_trend_overlay', 'comparison_boards', cases(i).comparisonName))));
end
lines = add_line(lines, '- `validation/nuaa_trim_trend_overlay/comparison_boards/nuaa_trim_trend_overlay_overview.png`');
lines = add_line(lines, '');
lines = add_line(lines, '## 如何人工判断');
lines = add_line(lines, '');
lines = add_line(lines, '- 先看趋势方向是否同类，例如随速度增加是上升、下降还是基本平。');
lines = add_line(lines, '- 再看模型曲线是否有突跳或不合理局部凸起。');
lines = add_line(lines, '- 确认控制量是否同类变量：0/15 度主看纵向周期变距，75/90 度主看升降舵。');
lines = add_line(lines, '- 90 度飞机模式中 cyclicLong 应固定为 0，本任务使用的包线结果满足该约束。');
lines = add_line(lines, '- 可以比较 full_angle 是否比 legacy 更平滑，但不要要求数值一模一样。');
lines = add_line(lines, '');
lines = add_line(lines, '## 初步自动诊断');
lines = add_line(lines, '');
lines = add_line(lines, sprintf('- 模型数据完整：%d。', report.modelDataComplete));
lines = add_line(lines, sprintf('- 论文 PDF 找到：%d，四张论文图裁剪完成：%d。', report.pdfFound, report.cropsComplete));
lines = add_line(lines, sprintf('- 四张对照图和总览图生成完成：%d。', report.comparisonBoardsComplete));
lines = add_line(lines, sprintf('- legacy 默认保持：%d，`P.wing.modelType=%s`，`fullAngleModelEnabled=%g`。', ...
    report.defaultModel.legacyStillDefault, report.defaultModel.modelType, ...
    report.defaultModel.fullAngleModelEnabled));
lines = add_line(lines, '- 0 度 full_angle 的 branchWeight 为 0，说明本图没有重新启用旧的 branchWeight 触发路径。');
lines = add_line(lines, '- full_angle 对 legacy 是否更平滑由 `model_trend_diagnostics.csv` 中 `fullAngleSmootherThanLegacy` 给出；该诊断只针对模型曲线，不代表南航误差。');
lines = add_line(lines, '- 若对照图中趋势相似性存在争议，应由 owner 在 `nuaa_visual_judgement_checklist.csv` 中人工填写判断。');
lines = add_line(lines, '');
lines = add_line(lines, '## 配平包线摘要');
lines = add_line(lines, '');
lines = add_line(lines, '| betaM | model | attempted | completed | converged | timeout | failed | atLimit | clamped |');
lines = add_line(lines, '|---:|---|---:|---:|---:|---:|---:|---:|---:|');
for i = 1:height(summaryTable)
    lines = add_line(lines, sprintf('| %.0f | %s | %d | %d | %d | %d | %d | %d | %d |', ...
        summaryTable.betaM_deg(i), summaryTable.modelType{i}, ...
        summaryTable.attempted(i), summaryTable.completed(i), ...
        summaryTable.converged(i), summaryTable.timeout(i), ...
        summaryTable.failed(i), summaryTable.atLimit(i), ...
        summaryTable.clamped(i)));
end
lines = add_line(lines, '');
lines = add_line(lines, '## 结论');
lines = add_line(lines, '');
lines = add_line(lines, report.finalConclusion);
write_text(path, lines);
end

function update_pr_body(path, report)
lines = {};
if exist(path, 'file') == 2
    text = fileread(path);
    lines = regexp(text, '\r\n|\n|\r', 'split').';
else
    lines = {'# PR #27 Body Update'; ''; 'Status: keep this PR open, Draft, and unmerged.'};
end
marker = '## NUAA Trim Trend Visual Overlay';
idx = find(strcmp(lines, marker), 1);
if ~isempty(idx)
    lines = lines(1:idx-1);
end
lines = add_line(lines, '');
lines = add_line(lines, marker);
lines = add_line(lines, '');
lines = add_line(lines, sprintf('Conclusion: `%s`.', report.finalConclusion));
lines = add_line(lines, '');
lines = add_line(lines, '- NUAA Fig.5(a), Fig.5(b), Fig.6(a), and Fig.6(b) were used as screenshot references only.');
lines = add_line(lines, '- No NUAA curve digitization and no pointwise NUAA-model error calculation were performed.');
lines = add_line(lines, '- Existing legacy/full_angle trim envelope results were reused; no parameter tuning was performed.');
lines = add_line(lines, '- Legacy remains the default model; this PR remains Draft and unmerged.');
lines = add_line(lines, '');
lines = add_line(lines, 'Report: `docs/wing_full_angle/NUAA_TRIM_TREND_VISUAL_OVERLAY_REPORT.md`');
write_text(path, lines);
end

function conclusion = final_conclusion(report)
if ~report.pdfFound
    conclusion = 'VISUAL_OVERLAY_BLOCKED';
elseif report.cropsComplete && report.comparisonBoardsComplete && ...
        report.modelDataComplete && report.defaultModel.legacyStillDefault
    conclusion = 'VISUAL_OVERLAY_READY_FOR_OWNER_REVIEW';
else
    conclusion = 'VISUAL_OVERLAY_PARTIAL';
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

function text = range_list(values)
text = sprintf('%.12g-%.12g', min(values), max(values));
end

function text = rel_path(path)
text = strrep(path, '\', '/');
end
