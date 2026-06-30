function build_trend_comparison_figure()
% Build NUAA paper-vs-program trend comparison from existing artifacts only.

rootDir = fileparts(fileparts(mfilename('fullpath')));
csvDir = fullfile(fileparts(rootDir), '20260625_eq12_13_16_angle_fix');
cleanCsv = fullfile(csvDir, 'summary_figure', 'NUAA_TRIM_POINT_CLEAN.csv');

T = readtable(cleanCsv, 'TextType', 'string');

fig = figure('Visible', 'off', 'Color', 'w', ...
    'Units', 'pixels', 'Position', [100 100 2100 3000]);
tl = tiledlayout(fig, 4, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

plotMode(tl, 1, fullfile(rootDir, '_work', 'paper_0deg_helicopter.png'), ...
    T, "helicopter_longitudinal", 0, [0 30], [-5 20], ...
    '1. 0 deg helicopter mode', 'cyclic');
plotMode(tl, 2, fullfile(rootDir, '_work', 'paper_15deg_transition.png'), ...
    T, "conversion_longitudinal", 15, [10 60], [-20 25], ...
    '2. 15 deg transition mode', 'cyclic');
plotMode(tl, 5, fullfile(rootDir, '_work', 'paper_75deg_transition.png'), ...
    T, "conversion_longitudinal", 75, [70 150], [-25 55], ...
    '3. 75 deg transition mode', 'elevator');
plotMode(tl, 6, fullfile(rootDir, '_work', 'paper_90deg_flight.png'), ...
    T, "airplane_longitudinal", 90, [70 150], [-25 55], ...
    '4. 90 deg flight mode', 'elevator');

title(tl, ['NUAA paper trend figures vs current program trend plots ', ...
    '(CSV baseline before Eq.17 replacement)'], ...
    'FontWeight', 'bold', 'FontSize', 16);

pngPath = fullfile(rootDir, 'NUAA_vs_PROGRAM_TREND_COMPARISON.png');
pdfPath = fullfile(rootDir, 'NUAA_vs_PROGRAM_TREND_COMPARISON.pdf');
set(fig, 'PaperPositionMode', 'auto');
print(fig, pngPath, '-dpng', '-r200');
print(fig, pdfPath, '-dpdf', '-bestfit');
close(fig);
fprintf('Wrote %s\n', pngPath);
fprintf('Wrote %s\n', pdfPath);
end

function plotMode(tl, tileIdx, paperImagePath, T, modeName, betaDeg, xLimits, yLimits, modeTitle, primary)
axPaper = nexttile(tl, tileIdx);
img = imread(paperImagePath);
image(axPaper, img);
axis(axPaper, 'image');
axis(axPaper, 'off');
title(axPaper, sprintf('%s - NUAA paper figure', modeTitle), 'FontSize', 11);

axProg = nexttile(tl, tileIdx + 2);
idx = T.mode == modeName & abs(T.betaM_deg - betaDeg) < 1e-9;
S = sortrows(T(idx, :), 'V_mps');

hold(axProg, 'on');
plot(axProg, S.V_mps, S.collective_deg, '-ks', ...
    'LineWidth', 1.6, 'MarkerFaceColor', 'k', 'DisplayName', 'collective (deg)');
if primary == "cyclic"
    plot(axProg, S.V_mps, S.paperCyclic_deg, '-ro', ...
        'LineWidth', 1.6, 'MarkerFaceColor', 'r', ...
        'DisplayName', 'vertical pitch / longitudinal cyclic (deg)');
else
    plot(axProg, S.V_mps, S.elevator_deg, '-ro', ...
        'LineWidth', 1.6, 'MarkerFaceColor', 'r', 'DisplayName', 'elevator (deg)');
end
plot(axProg, S.V_mps, S.theta_deg, '-g^', ...
    'LineWidth', 1.6, 'MarkerFaceColor', 'g', 'DisplayName', 'pitch angle (deg)');
grid(axProg, 'on');
xlim(axProg, xLimits);
ylim(axProg, yLimits);
xlabel(axProg, 'Velocity (m/s)');
ylabel(axProg, 'Angle (deg)');
title(axProg, sprintf('%s - current program plot', modeTitle), 'FontSize', 11);
legend(axProg, 'Location', 'best', 'FontSize', 8);
hold(axProg, 'off');
end
