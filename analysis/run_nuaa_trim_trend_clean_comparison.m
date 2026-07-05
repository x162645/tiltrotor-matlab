function report = run_nuaa_trim_trend_clean_comparison()
%RUN_NUAA_TRIM_TREND_CLEAN_COMPARISON Build clean NUAA screenshot/model boards.
% The output is a visual validation artifact only. It uses the refreshed
% variable mapping and does not modify production model code or parameters.

rootDir = fileparts(fileparts(mfilename('fullpath')));
overlayDir = fullfile(rootDir, 'validation', 'nuaa_trim_trend_overlay');
outDir = fullfile(overlayDir, 'clean_comparison');
ensure_dir(outDir);

trimPath = fullfile(rootDir, 'validation', 'wing_full_angle', ...
    'trim_envelope', 'full_angle_trim_envelope_results.csv');
decisionPath = fullfile(overlayDir, 'mapping_refresh', ...
    'nuaa_variable_mapping_decision.csv');
assert(exist(trimPath, 'file') == 2, 'Missing trim result CSV: %s', trimPath);
assert(exist(decisionPath, 'file') == 2, ...
    'Missing refreshed mapping decision CSV: %s', decisionPath);

T = readtable(trimPath, 'TextType', 'string');
T.verticalPitchMapped_deg = -T.cyclicLong_deg;
D = readtable(decisionPath, 'TextType', 'string');
cases = define_cases(overlayDir);

modelPaths = cell(numel(cases), 1);
boardPaths = cell(numel(cases), 1);
for i = 1:numel(cases)
    modelPaths{i} = fullfile(outDir, ...
        sprintf('%s_clean_model_trend.png', cases(i).id));
    boardPaths{i} = fullfile(outDir, ...
        sprintf('%s_clean_paper_model_comparison.png', cases(i).id));
    write_clean_model_plot(T, cases(i), modelPaths{i});
    write_clean_pair_board(T, cases(i), boardPaths{i});
end

overviewPath = fullfile(outDir, ...
    'nuaa_trim_trend_clean_paper_model_comparison.png');
write_clean_overview(T, cases, overviewPath);

report = struct();
report.outputDir = outDir;
report.overviewPath = overviewPath;
report.modelPaths = modelPaths;
report.boardPaths = boardPaths;
report.mappingDecisionPath = decisionPath;
report.selectedMapping = D(D.selectedForRefresh == 1, :);

fprintf('\nClean NUAA trim trend comparison generated\n');
fprintf('==========================================\n');
fprintf('Overview: %s\n', overviewPath);
for i = 1:numel(boardPaths)
    fprintf('%s board: %s\n', cases(i).label, boardPaths{i});
end
end

function cases = define_cases(overlayDir)
cropDir = fullfile(overlayDir, 'crops');
cases = repmat(empty_case(), 4, 1);
cases(1) = make_case('fig5a_beta0', 'Fig.5(a) betaM=0 deg', 0, ...
    {'collective_deg','verticalPitchMapped_deg','theta_deg'}, ...
    {'collective','vertical pitch (-cyclicLong)','pitch angle'}, ...
    fullfile(cropDir, 'nuaa_fig5a_crop.png'));
cases(2) = make_case('fig5b_beta90', 'Fig.5(b) betaM=90 deg', 90, ...
    {'collective_deg','elevator_deg','theta_deg'}, ...
    {'collective','elevator','pitch angle'}, ...
    fullfile(cropDir, 'nuaa_fig5b_crop.png'));
cases(3) = make_case('fig6a_beta15', 'Fig.6(a) betaM=15 deg', 15, ...
    {'collective_deg','verticalPitchMapped_deg','theta_deg'}, ...
    {'collective','vertical pitch (-cyclicLong)','pitch angle'}, ...
    fullfile(cropDir, 'nuaa_fig6a_crop.png'));
cases(4) = make_case('fig6b_beta75', 'Fig.6(b) betaM=75 deg', 75, ...
    {'collective_deg','elevator_deg','theta_deg'}, ...
    {'collective','elevator','pitch angle'}, ...
    fullfile(cropDir, 'nuaa_fig6b_crop.png'));
end

function c = empty_case()
c = struct('id', '', 'label', '', 'betaM_deg', NaN, ...
    'variables', {{}}, 'displayNames', {{}}, 'cropPath', '');
end

function c = make_case(id, label, betaM, variables, displayNames, cropPath)
c = empty_case();
c.id = id;
c.label = label;
c.betaM_deg = betaM;
c.variables = variables;
c.displayNames = displayNames;
c.cropPath = cropPath;
assert(exist(cropPath, 'file') == 2, 'Missing NUAA crop: %s', cropPath);
end

function write_clean_model_plot(T, c, path)
figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 980 620]);
plot_case_curves(T, c);
title(c.label, 'Interpreter', 'none', 'FontWeight', 'bold');
legend('Location', 'eastoutside', 'Interpreter', 'none');
set(gca, 'FontName', 'Arial', 'FontSize', 11, 'LineWidth', 0.8);
print(gcf, path, '-dpng', '-r180');
close(gcf);
end

function write_clean_pair_board(T, c, outPath)
paper = imread(c.cropPath);

figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1500 700]);
subplot('Position', [0.035 0.08 0.43 0.84]);
image(paper);
axis image off;
title([c.label ' - NUAA paper'], 'Interpreter', 'none', ...
    'FontWeight', 'bold');

subplot('Position', [0.525 0.12 0.43 0.76]);
plot_case_curves(T, c);
title([c.label ' - computed trend'], 'Interpreter', 'none', ...
    'FontWeight', 'bold');
legend('Location', 'best', 'Interpreter', 'none');

print(gcf, outPath, '-dpng', '-r170');
close(gcf);
end

function write_clean_overview(T, cases, outPath)
figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1650 2150]);
for i = 1:numel(cases)
    y = 0.985 - i*0.235;
    paper = imread(cases(i).cropPath);

    subplot('Position', [0.035 y 0.42 0.205]);
    image(paper);
    axis image off;
    title([cases(i).label ' - NUAA paper'], 'Interpreter', 'none', ...
        'FontSize', 12, 'FontWeight', 'bold');

    subplot('Position', [0.525 y+0.018 0.42 0.175]);
    plot_case_curves(T, cases(i));
    title([cases(i).label ' - computed trend'], 'Interpreter', 'none', ...
        'FontSize', 12, 'FontWeight', 'bold');
    legend('Location', 'best', 'Interpreter', 'none', 'FontSize', 8);
end
print(gcf, outPath, '-dpng', '-r160');
close(gcf);
end

function plot_case_curves(T, c)
hold on;
colors = [0.0000 0.4470 0.7410;
          0.8500 0.3250 0.0980;
          0.4660 0.6740 0.1880];
models = {'legacy','full_angle'};
modelNames = {'legacy','full-angle'};
styles = {'-','--'};
markers = {'o','s'};

for j = 1:numel(models)
    mask = T.betaM_deg == c.betaM_deg & strcmp(T.modelType, models{j}) & ...
        T.converged == 1 & T.finiteReal == 1;
    S = sortrows(T(mask, :), 'V_mps');
    for k = 1:numel(c.variables)
        plot(S.V_mps, S.(c.variables{k}), ...
            'LineStyle', styles{j}, ...
            'Marker', markers{j}, ...
            'Color', colors(k,:), ...
            'LineWidth', 1.7, ...
            'MarkerSize', 5, ...
            'DisplayName', sprintf('%s %s', modelNames{j}, ...
            c.displayNames{k}));
    end
end
grid on;
box on;
xlabel('Airspeed V (m/s)');
ylabel('Angle (deg)');
set(gca, 'FontName', 'Arial', 'FontSize', 10.5, 'LineWidth', 0.8);
end

function ensure_dir(path)
if exist(path, 'dir') ~= 7
    mkdir(path);
end
end
