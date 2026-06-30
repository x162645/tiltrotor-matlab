function build_transition_program_originals()
% Export standalone MATLAB-generated program trend figures for 15 and 75 deg.

rootDir = fileparts(fileparts(mfilename('fullpath')));
csvPath = fullfile(fileparts(rootDir), ...
    '20260625_eq12_13_16_angle_fix', ...
    'summary_figure', 'NUAA_TRIM_POINT_CLEAN.csv');
T = readtable(csvPath, 'TextType', 'string');

plotProgramTrend(rootDir, T, "conversion_longitudinal", 15, [10 60], [-20 25], ...
    'Program trim trend - transition mode 15 deg', ...
    'vertical pitch / longitudinal cyclic (deg)', 'paperCyclic_deg', ...
    'PROGRAM_TRANSITION_15DEG_TREND');

plotProgramTrend(rootDir, T, "conversion_longitudinal", 75, [70 150], [-25 55], ...
    'Program trim trend - transition mode 75 deg', ...
    'elevator (deg)', 'elevator_deg', ...
    'PROGRAM_TRANSITION_75DEG_TREND');
end

function plotProgramTrend(rootDir, T, modeName, betaDeg, xLimits, yLimits, ...
    titleText, primaryLabel, primaryColumn, stem)
idx = T.mode == modeName & abs(T.betaM_deg - betaDeg) < 1e-9;
S = sortrows(T(idx, :), 'V_mps');

fig = figure('Visible', 'off', 'Color', 'w', ...
    'Units', 'pixels', 'Position', [100 100 1050 720]);
ax = axes(fig);
hold(ax, 'on');
plot(ax, S.V_mps, S.collective_deg, '-ks', ...
    'LineWidth', 1.8, 'MarkerSize', 6, 'MarkerFaceColor', 'k', ...
    'DisplayName', 'collective (deg)');
plot(ax, S.V_mps, S.(primaryColumn), '-ro', ...
    'LineWidth', 1.8, 'MarkerSize', 6, 'MarkerFaceColor', 'r', ...
    'DisplayName', primaryLabel);
plot(ax, S.V_mps, S.theta_deg, '-g^', ...
    'LineWidth', 1.8, 'MarkerSize', 6, 'MarkerFaceColor', 'g', ...
    'DisplayName', 'pitch angle (deg)');
grid(ax, 'on');
xlim(ax, xLimits);
ylim(ax, yLimits);
xlabel(ax, 'Velocity (m/s)');
ylabel(ax, 'Angle (deg)');
title(ax, titleText, 'FontWeight', 'bold');
legend(ax, 'Location', 'best');
set(fig, 'PaperPositionMode', 'auto');

pngPath = fullfile(rootDir, stem + ".png");
pdfPath = fullfile(rootDir, stem + ".pdf");
figPath = fullfile(rootDir, stem + ".fig");
print(fig, pngPath, '-dpng', '-r200');
print(fig, pdfPath, '-dpdf', '-bestfit');
savefig(fig, figPath);
close(fig);
fprintf('Wrote %s\n', pngPath);
fprintf('Wrote %s\n', pdfPath);
fprintf('Wrote %s\n', figPath);
end
