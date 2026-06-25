function report = plot_nuaa_trim_point_summary()
%PLOT_NUAA_TRIM_POINT_SUMMARY Consolidated NUAA trim-point overview figure.
% This script reads existing trim and stability CSV files only. It does not
% run trim, linearization, model equations, allocation, limit, or parameter
% updates.

rootDir = fileparts(fileparts(mfilename('fullpath')));
localDir = fullfile(rootDir, 'validation', 'nuaa_trim_trends', ...
    '20260625_091852');
docsBaseDir = fullfile(rootDir, 'docs', 'validation', ...
    'nuaa_trim_trends', '20260625');

localPoints = fullfile(localDir, 'nuaa_trim_points.csv');
localStability = fullfile(localDir, 'nuaa_stability_map.csv');
docsPoints = fullfile(docsBaseDir, 'nuaa_trim_points.csv');
docsStability = fullfile(docsBaseDir, 'nuaa_stability_map.csv');

if exist(localPoints, 'file') == 2 && exist(localStability, 'file') == 2
    pointsPath = localPoints;
    stabilityPath = localStability;
    sourceDir = localDir;
else
    pointsPath = docsPoints;
    stabilityPath = docsStability;
    sourceDir = docsBaseDir;
end

assert_file(pointsPath);
assert_file(stabilityPath);

points = readtable(pointsPath);
stability = readtable(stabilityPath);
primary = filter_primary_points(points);
[primary, stability] = normalize_keys(primary, stability);
joined = innerjoin(primary, stability, ...
    'Keys', {'mode','betaM_deg','V_mps'}, ...
    'RightVariables', {'max_real_full','max_real_longitudinal', ...
    'max_real_lateral','openLoopCandidate','tau_growth_s'});

if height(joined) ~= height(primary)
    error('plot_nuaa_trim_point_summary:StabilityJoinFailed', ...
        'Expected %d joined rows, got %d.', height(primary), height(joined));
end

joined = sortrows(joined, {'betaM_deg','V_mps'});
joined.mode_cn = mode_cn(joined.mode, joined.betaM_deg);
validate_mode_counts(joined);

clean = make_clean_table(joined);
summary = make_summary_table(joined);

outDir = fullfile(sourceDir, 'summary_figure');
docsOutDir = fullfile(docsBaseDir, 'summary_figure');
ensure_dir(outDir);
ensure_dir(docsOutDir);

paths = struct();
paths.cleanCsv = fullfile(outDir, 'NUAA_TRIM_POINT_CLEAN.csv');
paths.summaryCsv = fullfile(outDir, 'NUAA_TRIM_POINT_SUMMARY.csv');
paths.png = fullfile(outDir, 'NUAA_TRIM_POINT_OVERVIEW.png');
paths.pdf = fullfile(outDir, 'NUAA_TRIM_POINT_OVERVIEW.pdf');
paths.docsCleanCsv = fullfile(docsOutDir, 'NUAA_TRIM_POINT_CLEAN.csv');
paths.docsSummaryCsv = fullfile(docsOutDir, 'NUAA_TRIM_POINT_SUMMARY.csv');
paths.docsPng = fullfile(docsOutDir, 'NUAA_TRIM_POINT_OVERVIEW.png');
paths.docsPdf = fullfile(docsOutDir, 'NUAA_TRIM_POINT_OVERVIEW.pdf');

writetable(clean, paths.cleanCsv);
writetable(summary, paths.summaryCsv);
make_overview_figure(joined, summary, paths.png, paths.pdf);

copyfile(paths.cleanCsv, paths.docsCleanCsv);
copyfile(paths.summaryCsv, paths.docsSummaryCsv);
copyfile(paths.png, paths.docsPng);
copyfile(paths.pdf, paths.docsPdf);

verify_outputs(clean, summary, joined, paths);

report = struct();
report.sourcePoints = pointsPath;
report.sourceStability = stabilityPath;
report.outputDir = outDir;
report.docsOutputDir = docsOutDir;
report.cleanCsv = paths.cleanCsv;
report.summaryCsv = paths.summaryCsv;
report.png = paths.png;
report.pdf = paths.pdf;
report.docsCleanCsv = paths.docsCleanCsv;
report.docsSummaryCsv = paths.docsSummaryCsv;
report.docsPng = paths.docsPng;
report.docsPdf = paths.docsPdf;
report.pointCount = height(clean);
report.summaryCount = height(summary);
report.modeCounts = mode_count_struct(joined);
report.unstablePointCount = sum(logical(joined.openLoopCandidate));

fprintf('NUAA_TRIM_POINT_SUMMARY_DONE\n');
fprintf('SOURCE_POINTS=%s\n', pointsPath);
fprintf('SOURCE_STABILITY=%s\n', stabilityPath);
fprintf('CLEAN_ROWS=%d SUMMARY_ROWS=%d UNSTABLE_POINTS=%d\n', ...
    report.pointCount, report.summaryCount, report.unstablePointCount);
fprintf('COUNTS helicopter=%d conversion15=%d conversion75=%d airplane=%d total=%d\n', ...
    report.modeCounts.helicopter, report.modeCounts.conversion15, ...
    report.modeCounts.conversion75, report.modeCounts.airplane, ...
    report.pointCount);
fprintf('PNG=%s\n', paths.png);
fprintf('PDF=%s\n', paths.pdf);
fprintf('DOCS_PNG=%s\n', paths.docsPng);
fprintf('DOCS_PDF=%s\n', paths.docsPdf);
end

function primary = filter_primary_points(points)
mask = points.isPrimary == 1 & points.converged == 1 & ...
    points.finite == 1 & points.atLimit == 0 & ...
    strcmp(points.credibilityClass, 'PASS');
primary = points(mask, :);
if height(primary) ~= 100
    error('plot_nuaa_trim_point_summary:PrimaryPointCountMismatch', ...
        'Expected 100 primary credible points, got %d.', height(primary));
end
end

function [points, stability] = normalize_keys(points, stability)
points.betaM_deg = round(points.betaM_deg, 10);
points.V_mps = round(points.V_mps, 10);
stability.betaM_deg = round(stability.betaM_deg, 10);
stability.V_mps = round(stability.V_mps, 10);
end

function validate_mode_counts(T)
counts = mode_count_struct(T);
expected = struct('helicopter', 13, 'conversion15', 21, ...
    'conversion75', 33, 'airplane', 33);
names = fieldnames(expected);
for i = 1:numel(names)
    name = names{i};
    if counts.(name) ~= expected.(name)
        error('plot_nuaa_trim_point_summary:ModeCountMismatch', ...
            'Mode count mismatch for %s: expected %d, got %d.', ...
            name, expected.(name), counts.(name));
    end
end
if height(T) ~= 100
    error('plot_nuaa_trim_point_summary:TotalCountMismatch', ...
        'Expected 100 joined points, got %d.', height(T));
end
end

function counts = mode_count_struct(T)
counts = struct();
counts.helicopter = count_mode(T, 'helicopter_longitudinal', 0);
counts.conversion15 = count_mode(T, 'conversion_longitudinal', 15);
counts.conversion75 = count_mode(T, 'conversion_longitudinal', 75);
counts.airplane = count_mode(T, 'airplane_longitudinal', 90);
end

function n = count_mode(T, mode, betaM)
n = sum(strcmp(T.mode, mode) & abs(T.betaM_deg - betaM) < 1e-9);
end

function clean = make_clean_table(T)
clean = table();
clean.mode_cn = T.mode_cn;
clean.mode = T.mode;
clean.betaM_deg = T.betaM_deg;
clean.V_mps = T.V_mps;
clean.theta_deg = finite_numeric(T.theta_deg, 'theta_deg');
clean.collective_deg = finite_numeric(T.collective_deg, 'collective_deg');
clean.cyclicLong_deg = finite_numeric(T.cyclicLong_deg, 'cyclicLong_deg');
clean.paperCyclic_deg = finite_numeric(T.paperCyclic_deg, 'paperCyclic_deg');
clean.elevator_deg = finite_numeric(T.elevator_deg, 'elevator_deg');
clean.pitchCommand = optional_numeric_text(T.pitchCommand);
clean.residualNorm = finite_numeric(T.residualNorm, 'residualNorm');
clean.jacobianRank = finite_numeric(T.jacobianRank, 'jacobianRank');
clean.jacobianConditionNumber = finite_numeric(T.jacobianConditionNumber, ...
    'jacobianConditionNumber');
clean.collectiveMargin_deg = finite_numeric(T.collectiveMargin_deg, ...
    'collectiveMargin_deg');
clean.cyclicLongMargin_deg = finite_numeric(T.cyclicLongMargin_deg, ...
    'cyclicLongMargin_deg');
clean.elevatorMargin_deg = finite_numeric(T.elevatorMargin_deg, ...
    'elevatorMargin_deg');
clean.max_real_full = finite_numeric(T.max_real_full, 'max_real_full');
clean.max_real_longitudinal = finite_numeric(T.max_real_longitudinal, ...
    'max_real_longitudinal');
clean.max_real_lateral = finite_numeric(T.max_real_lateral, ...
    'max_real_lateral');
clean.openLoopCandidate = T.openLoopCandidate;
clean.tau_growth_s = optional_numeric_text(T.tau_growth_s);
clean.git_sha = T.git_sha;
clean = sortrows(clean, {'betaM_deg','V_mps'});
end

function summary = make_summary_table(T)
groups = mode_specs();
mode_cn_col = {};
betaM_deg = [];
V_min = [];
V_max = [];
point_count = [];
collective_start_deg = [];
collective_end_deg = [];
collective_change_deg = [];
primary_control_name = {};
primary_control_start_deg = [];
primary_control_end_deg = [];
primary_control_change_deg = [];
theta_start_deg = [];
theta_end_deg = [];
theta_change_deg = [];
max_residual_norm = [];
minimum_control_margin_deg = [];
unstable_point_count = [];
unstable_fraction = [];
max_positive_real = {};
minimum_growth_time_s = {};

for i = 1:numel(groups)
    spec = groups(i);
    S = sortrows(T(strcmp(T.mode, spec.mode) & ...
        abs(T.betaM_deg - spec.betaM_deg) < 1e-9, :), 'V_mps');
    mode_cn_col{end+1,1} = spec.mode_cn; %#ok<AGROW>
    betaM_deg(end+1,1) = spec.betaM_deg; %#ok<AGROW>
    V_min(end+1,1) = min(S.V_mps); %#ok<AGROW>
    V_max(end+1,1) = max(S.V_mps); %#ok<AGROW>
    point_count(end+1,1) = height(S); %#ok<AGROW>
    collective_start_deg(end+1,1) = S.collective_deg(1); %#ok<AGROW>
    collective_end_deg(end+1,1) = S.collective_deg(end); %#ok<AGROW>
    collective_change_deg(end+1,1) = S.collective_deg(end) - ...
        S.collective_deg(1); %#ok<AGROW>
    primary_control_name{end+1,1} = spec.primary_control_name; %#ok<AGROW>
    control = S.(spec.primary_control_var);
    primary_control_start_deg(end+1,1) = control(1); %#ok<AGROW>
    primary_control_end_deg(end+1,1) = control(end); %#ok<AGROW>
    primary_control_change_deg(end+1,1) = control(end) - control(1); %#ok<AGROW>
    theta_start_deg(end+1,1) = S.theta_deg(1); %#ok<AGROW>
    theta_end_deg(end+1,1) = S.theta_deg(end); %#ok<AGROW>
    theta_change_deg(end+1,1) = S.theta_deg(end) - S.theta_deg(1); %#ok<AGROW>
    max_residual_norm(end+1,1) = max(S.residualNorm); %#ok<AGROW>
    margins = [S.collectiveMargin_deg, S.cyclicLongMargin_deg, ...
        S.elevatorMargin_deg];
    minimum_control_margin_deg(end+1,1) = min(margins(:)); %#ok<AGROW>
    unstable = logical(S.openLoopCandidate);
    unstable_point_count(end+1,1) = sum(unstable); %#ok<AGROW>
    unstable_fraction(end+1,1) = sum(unstable)/height(S); %#ok<AGROW>
    if any(unstable)
        positiveReal = S.max_real_full(unstable);
        growth = S.tau_growth_s(unstable);
        growth = growth(isfinite(growth) & growth > 0);
        max_positive_real{end+1,1} = format_number(max(positiveReal)); %#ok<AGROW>
        minimum_growth_time_s{end+1,1} = format_number(min(growth)); %#ok<AGROW>
    else
        max_positive_real{end+1,1} = ''; %#ok<AGROW>
        minimum_growth_time_s{end+1,1} = ''; %#ok<AGROW>
    end
end

summary = table(mode_cn_col, betaM_deg, V_min, V_max, point_count, ...
    collective_start_deg, collective_end_deg, collective_change_deg, ...
    primary_control_name, primary_control_start_deg, ...
    primary_control_end_deg, primary_control_change_deg, ...
    theta_start_deg, theta_end_deg, theta_change_deg, max_residual_norm, ...
    minimum_control_margin_deg, unstable_point_count, unstable_fraction, ...
    max_positive_real, minimum_growth_time_s);
summary.Properties.VariableNames = {'mode_cn','betaM_deg','V_min','V_max', ...
    'point_count','collective_start_deg','collective_end_deg', ...
    'collective_change_deg','primary_control_name', ...
    'primary_control_start_deg','primary_control_end_deg', ...
    'primary_control_change_deg','theta_start_deg','theta_end_deg', ...
    'theta_change_deg','max_residual_norm','minimum_control_margin_deg', ...
    'unstable_point_count','unstable_fraction','max_positive_real', ...
    'minimum_growth_time_s'};
end

function make_overview_figure(T, summary, pngPath, pdfPath)
fontName = choose_font();
groups = mode_specs();
fig = figure('Visible','off', 'Color','w', 'Units','centimeters', ...
    'Position',[2, 2, 42, 26]);
layout = tiledlayout(fig, 4, 4, 'TileSpacing','compact', ...
    'Padding','compact');
title(layout, {'倾转旋翼机配平点趋势总览', ...
    sprintf('Git %s；数据日期 2026-06-25', T.git_sha{1})}, ...
    'FontName', fontName, 'FontWeight','bold', 'FontSize', 16);

for col = 1:numel(groups)
    spec = groups(col);
    S = sortrows(T(strcmp(T.mode, spec.mode) & ...
        abs(T.betaM_deg - spec.betaM_deg) < 1e-9, :), 'V_mps');
    plot_metric(nexttile(layout, col), S, {'collective_deg'}, {'总距'}, ...
        spec.title, '总距 (deg)', fontName, true);
    plot_metric(nexttile(layout, 4 + col), S, spec.control_vars, ...
        spec.control_labels, '', '纵向操纵 (deg)', fontName, false);
    plot_metric(nexttile(layout, 8 + col), S, {'theta_deg'}, ...
        {'俯仰姿态'}, '', '俯仰姿态角 (deg)', fontName, false);
    plot_summary_text(nexttile(layout, 12 + col), summary(col, :), ...
        fontName);
end

annotation(fig, 'textbox', [0.08 0.005 0.84 0.035], ...
    'String', '当前结果为低阶部件机理模型的配平趋势与开环稳定性基线，非 XV-15/GTRS 定量验模。', ...
    'EdgeColor', 'none', 'HorizontalAlignment', 'center', ...
    'FontName', fontName, 'FontSize', 10);

exportgraphics(fig, pngPath, 'Resolution', 300);
try
    exportgraphics(fig, pdfPath, 'ContentType', 'vector');
catch
    exportgraphics(fig, pdfPath, 'ContentType', 'image', 'Resolution', 300);
end
close(fig);
end

function plot_metric(ax, S, vars, labels, chartTitle, yLabel, fontName, ...
        showLegend)
hold(ax, 'on');
colors = lines(numel(vars));
stable = ~logical(S.openLoopCandidate);
unstable = logical(S.openLoopCandidate);
for i = 1:numel(vars)
    y = S.(vars{i});
    plot(ax, S.V_mps, y, '-', 'Color', colors(i,:), 'LineWidth', 1.3, ...
        'HandleVisibility','off');
    plot(ax, S.V_mps(stable), y(stable), 'o', 'Color', colors(i,:), ...
        'MarkerFaceColor', colors(i,:), 'MarkerSize', 4.2, ...
        'HandleVisibility','off');
    plot(ax, S.V_mps(unstable), y(unstable), 'd', 'Color', colors(i,:), ...
        'MarkerFaceColor', 'none', 'MarkerSize', 6.0, ...
        'LineWidth', 1.2, 'HandleVisibility','off');
end
for i = 1:numel(vars)
    plot(ax, NaN, NaN, '-', 'Color', colors(i,:), 'LineWidth', 1.5, ...
        'DisplayName', labels{i});
end
plot(ax, NaN, NaN, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 4.2, ...
    'DisplayName', '无候选正根点');
plot(ax, NaN, NaN, 'kd', 'MarkerFaceColor', 'none', 'MarkerSize', 6.0, ...
    'LineWidth', 1.2, 'DisplayName', '开环候选不稳定点');
grid(ax, 'on');
ax.GridAlpha = 0.18;
ax.FontName = fontName;
ax.FontSize = 9;
xlabel(ax, 'V (m/s)', 'FontName', fontName);
ylabel(ax, yLabel, 'FontName', fontName);
if ~isempty(chartTitle)
    title(ax, chartTitle, 'FontName', fontName, 'FontSize', 11);
end
if showLegend
    legend(ax, 'Location','best', 'FontName', fontName, 'FontSize', 8);
end
end

function plot_summary_text(ax, row, fontName)
axis(ax, 'off');
maxPositive = table_cell_text(row, 'max_positive_real');
minGrowth = table_cell_text(row, 'minimum_growth_time_s');
if isempty(maxPositive)
    maxPositive = '无';
end
if isempty(minGrowth)
    minGrowth = '无';
end
textLines = {
    char(row.mode_cn)
    sprintf('速度范围：%.1f-%.1f m/s', row.V_min, row.V_max)
    sprintf('点数：%d', row.point_count)
    sprintf('总距端点变化：%+.2f deg', row.collective_change_deg)
    sprintf('%s端点变化：%+.2f deg', char(row.primary_control_name), ...
        row.primary_control_change_deg)
    sprintf('俯仰姿态端点变化：%+.2f deg', row.theta_change_deg)
    sprintf('最大残差：%.3g', row.max_residual_norm)
    sprintf('最小控制余量：%.2f deg', row.minimum_control_margin_deg)
    sprintf('候选不稳定点：%d/%d', row.unstable_point_count, ...
        row.point_count)
    sprintf('最大正根：%s', maxPositive)
    sprintf('最短增长时间：%s s', minGrowth)
    };
text(ax, 0, 0.95, textLines, 'Units','normalized', ...
    'VerticalAlignment','top', 'FontName', fontName, 'FontSize', 9);
end

function specs = mode_specs()
specs = struct([]);
specs(1).mode = 'helicopter_longitudinal';
specs(1).betaM_deg = 0;
specs(1).mode_cn = '直升机模式';
specs(1).title = '直升机模式 betaM=0°';
specs(1).primary_control_var = 'paperCyclic_deg';
specs(1).primary_control_name = '纵向周期变距';
specs(1).control_vars = {'paperCyclic_deg'};
specs(1).control_labels = {'纵向周期变距'};

specs(2).mode = 'conversion_longitudinal';
specs(2).betaM_deg = 15;
specs(2).mode_cn = '转换模式 15°';
specs(2).title = '转换模式 betaM=15°';
specs(2).primary_control_var = 'paperCyclic_deg';
specs(2).primary_control_name = '纵向周期变距';
specs(2).control_vars = {'paperCyclic_deg','elevator_deg'};
specs(2).control_labels = {'纵向周期变距','升降舵'};

specs(3).mode = 'conversion_longitudinal';
specs(3).betaM_deg = 75;
specs(3).mode_cn = '转换模式 75°';
specs(3).title = '转换模式 betaM=75°';
specs(3).primary_control_var = 'elevator_deg';
specs(3).primary_control_name = '升降舵';
specs(3).control_vars = {'elevator_deg','cyclicLong_deg'};
specs(3).control_labels = {'升降舵','直接周期变距'};

specs(4).mode = 'airplane_longitudinal';
specs(4).betaM_deg = 90;
specs(4).mode_cn = '固定翼模式';
specs(4).title = '固定翼模式 betaM=90°';
specs(4).primary_control_var = 'elevator_deg';
specs(4).primary_control_name = '升降舵';
specs(4).control_vars = {'elevator_deg'};
specs(4).control_labels = {'升降舵'};
end

function labels = mode_cn(mode, betaM)
labels = cell(height(table(mode, betaM)), 1);
for i = 1:numel(labels)
    if strcmp(mode{i}, 'helicopter_longitudinal') && abs(betaM(i)) < 1e-9
        labels{i} = '直升机模式';
    elseif strcmp(mode{i}, 'conversion_longitudinal') && ...
            abs(betaM(i) - 15) < 1e-9
        labels{i} = '转换模式 15°';
    elseif strcmp(mode{i}, 'conversion_longitudinal') && ...
            abs(betaM(i) - 75) < 1e-9
        labels{i} = '转换模式 75°';
    elseif strcmp(mode{i}, 'airplane_longitudinal') && ...
            abs(betaM(i) - 90) < 1e-9
        labels{i} = '固定翼模式';
    else
        error('plot_nuaa_trim_point_summary:UnknownMode', ...
            'Unknown mode/betaM pair: %s %.10g.', mode{i}, betaM(i));
    end
end
end

function values = finite_numeric(values, name)
if any(~isfinite(values(:)))
    error('plot_nuaa_trim_point_summary:NonFiniteNumeric', ...
        'Column %s contains NaN or Inf.', name);
end
end

function text = optional_numeric_text(values)
text = cell(numel(values), 1);
for i = 1:numel(values)
    if isfinite(values(i))
        text{i} = format_number(values(i));
    else
        text{i} = '';
    end
end
end

function text = format_number(value)
if isempty(value) || ~isfinite(value)
    text = '';
else
    text = sprintf('%.12g', value);
end
end

function text = table_cell_text(row, name)
value = row.(name);
if iscell(value)
    text = value{1};
else
    text = char(value);
end
end

function fontName = choose_font()
fontName = 'Helvetica';
try
    fonts = listfonts;
    if any(strcmp(fonts, 'Microsoft YaHei'))
        fontName = 'Microsoft YaHei';
    end
catch
end
end

function verify_outputs(clean, summary, joined, paths)
if height(clean) ~= 100
    error('plot_nuaa_trim_point_summary:CleanRowCountMismatch', ...
        'Clean CSV row count is %d, expected 100.', height(clean));
end
if height(summary) ~= 4
    error('plot_nuaa_trim_point_summary:SummaryRowCountMismatch', ...
        'Summary CSV row count is %d, expected 4.', height(summary));
end
validate_mode_counts(joined);
assert_nonempty(paths.cleanCsv);
assert_nonempty(paths.summaryCsv);
assert_nonempty(paths.png, 1024);
assert_nonempty(paths.pdf, 1024);
assert_nonempty(paths.docsCleanCsv);
assert_nonempty(paths.docsSummaryCsv);
assert_nonempty(paths.docsPng, 1024);
assert_nonempty(paths.docsPdf, 1024);
end

function assert_file(path)
if exist(path, 'file') ~= 2
    error('plot_nuaa_trim_point_summary:MissingInput', ...
        'Required input file is missing: %s', path);
end
end

function assert_nonempty(path, minBytes)
if nargin < 2
    minBytes = 0;
end
info = dir(path);
if isempty(info) || info.bytes <= minBytes
    error('plot_nuaa_trim_point_summary:EmptyOutput', ...
        'Output file is missing or empty: %s', path);
end
end

function ensure_dir(path)
if exist(path, 'dir') ~= 7
    mkdir(path);
end
end
