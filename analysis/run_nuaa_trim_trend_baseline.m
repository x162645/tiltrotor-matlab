function report = run_nuaa_trim_trend_baseline(varargin)
%RUN_NUAA_TRIM_TREND_BASELINE Baseline trim sweeps matching NUAA Fig. 5/6.
% The sweep uses the current params_nominal() values and existing trim
% definitions only. It does not tune model parameters, limits, tolerances, or
% solver settings.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir, 'model'));
addpath(fullfile(rootDir, 'analysis'));

if nargin > 0
    report = replot_existing_results(varargin{:});
    return;
end

P = params_nominal();
d2r = pi/180;
resultDir = fullfile(rootDir, 'validation', 'nuaa_trim_trends');
if ~exist(resultDir, 'dir')
    mkdir(resultDir);
end
stamp = datestr(now, 'yyyymmdd_HHMMSS');

cases = define_cases();
totalPointCount = sum(arrayfun(@(c) numel(c.speeds), cases));
fprintf('\nNUAA Figure 5/6 trim baseline sweep\n');
fprintf('===================================\n');
fprintf('Output directory: %s\n', resultDir);
fprintf('High-level trim points: %d\n', totalPointCount);
fprintf('Credibility diagnostics: default per completed trim point.\n');
fprintf('run_all_checks is not called by this script.\n\n');

rows = repmat(empty_row(), totalPointCount, 1);
points = repmat(struct('caseName', '', 'V', NaN, 'xTrim', [], ...
    'uTrim', [], 'trimReport', struct(), 'credibility', struct(), ...
    'success', false), totalPointCount, 1);

rowIndex = 0;
runTimer = tic;
for iCase = 1:numel(cases)
    c = cases(iCase);
    fprintf('Case %s: NUAA beta %.1f deg, current betaM %.1f deg, mode %s\n', ...
        c.name, c.nuaaNacelleDeg, c.betaMDeg, c.trimMode);
    seed = [];
    for iSpeed = 1:numel(c.speeds)
        V = c.speeds(iSpeed);
        rowIndex = rowIndex + 1;
        pointTimer = tic;
        condition = struct('V', V, 'betaM', c.betaMDeg*d2r, 'gamma', 0);
        definition0 = make_trim_definition(c.trimMode, condition, P);
        if isempty(seed)
            names = {'default'};
            initials = {definition0.initialValues};
        else
            names = {'continuation', 'default_rescue'};
            initials = {seed, definition0.initialValues};
        end
        [names, initials] = add_zero_pitch_rescue(definition0, ...
            names, initials);
        attempts = make_attempts(definition0, names, initials);

        [row, point, acceptedSeed] = solve_point(c, condition, attempts, P);
        row.runtime_s = toc(pointTimer);
        rows(rowIndex) = row;
        points(rowIndex) = point;
        if row.trimConverged && row.finiteReal
            seed = acceptedSeed;
        end
        fprintf(['  V=%7.3f m/s source=%s exitflag=%g trim=%d cred=%s ' ...
            'res=%.3e theta=% .3f coll=% .3f cyc=% .3f elev=% .3f ' ...
            'runtime=%.1fs\n'], V, row.initialSource, row.exitflag, ...
            row.trimConverged, row.credibilityStatus, row.residualNorm, ...
            row.theta_deg, row.collective_deg, row.cyclicLong_deg, ...
            row.elevator_deg, row.runtime_s);
        if ~isempty(row.failureReason)
            fprintf('    failure: %s\n', row.failureReason);
        end
    end
    fprintf('\n');
end

elapsed = toc(runTimer);
rawTable = struct2table(rows);
summaryTable = make_summary_table(rawTable, cases, elapsed);
failureTable = rawTable(~rawTable.trimConverged | ...
    strcmp(rawTable.credibilityStatus, 'FAIL') | ...
    ~cellfun(@isempty, rawTable.errorIdentifier), :);

paths = make_paths(resultDir, stamp);
writetable(rawTable, paths.rawCsv);
writetable(summaryTable, paths.summaryCsv);
writetable(failureTable, paths.failureCsv);
figurePaths = write_figures(rawTable, cases, paths.figureDir);
write_readme(paths.readme, paths, cases, totalPointCount, elapsed);

report = struct();
report.generatedAt = datestr(now, 31);
report.scope = ['Current conceptual model zero-tuning trim results; ' ...
    'not a digitization or reproduction of NUAA curves.'];
report.reference = struct('file', 'references/NUAA_main_paper.pdf', ...
    'pdfPage', 10, 'originalPage', '10 of 18', ...
    'figures', 'Figure 5 and Figure 6');
report.angleConversion = ['NUAA 90 deg = current betaM 0 deg; ' ...
    'NUAA 0 deg = current betaM 90 deg; ' ...
    'NUAA 15 deg = current betaM 75 deg; ' ...
    'NUAA 75 deg = current betaM 15 deg.'];
report.paths = paths;
report.figurePaths = figurePaths;
report.cases = cases;
report.rawTable = rawTable;
report.summaryTable = summaryTable;
report.failureTable = failureTable;
report.points = points;
report.totalPointCount = totalPointCount;
report.elapsed_s = elapsed;

save(paths.mat, 'report', 'rawTable', 'summaryTable', 'failureTable', ...
    'points', 'cases', '-v7');

fprintf('Saved raw CSV: %s\n', paths.rawCsv);
fprintf('Saved summary CSV: %s\n', paths.summaryCsv);
fprintf('Saved failure CSV: %s\n', paths.failureCsv);
fprintf('Saved MAT: %s\n', paths.mat);
fprintf('Saved figures in: %s\n', paths.figureDir);
fprintf('Elapsed seconds: %.3f\n', elapsed);
end

function report = replot_existing_results(action, matPath)
if ~(ischar(action) || (isstring(action) && isscalar(action))) || ...
        ~strcmp(char(action), 'replot')
    error('run_nuaa_trim_trend_baseline:InvalidMode', ...
        'Optional mode must be ''replot''.');
end
if nargin < 2 || ~(ischar(matPath) || (isstring(matPath) && isscalar(matPath)))
    error('run_nuaa_trim_trend_baseline:InvalidMode', ...
        'Replot mode requires a MAT result path.');
end
data = load(char(matPath), 'report', 'rawTable', 'cases');
report = data.report;
figurePaths = write_figures(data.rawTable, data.cases, ...
    report.paths.figureDir);
report.figurePaths = figurePaths;
save(char(matPath), 'report', '-append');
fprintf('Replotted figures in: %s\n', report.paths.figureDir);
end

function cases = define_cases()
cases = repmat(struct('name', '', 'figure', '', 'subfigure', '', ...
    'description', '', 'trimMode', '', 'nuaaNacelleDeg', NaN, ...
    'betaMDeg', NaN, 'speeds', [], 'plotVariables', {{}}, ...
    'plotLabels', {{}}), 4, 1);

cases(1).name = 'fig5a_helicopter';
cases(1).figure = 'Figure 5';
cases(1).subfigure = 'a';
cases(1).description = 'helicopter mode';
cases(1).trimMode = 'helicopter_longitudinal';
cases(1).nuaaNacelleDeg = 90;
cases(1).betaMDeg = 0;
cases(1).speeds = 0:5:30;
cases(1).plotVariables = {'collective_deg', 'cyclicLong_deg', 'theta_deg'};
cases(1).plotLabels = {'Collective pitch', ...
    'Vertical pitch / cyclicLong', 'Pitch attitude'};

cases(2).name = 'fig5b_flight';
cases(2).figure = 'Figure 5';
cases(2).subfigure = 'b';
cases(2).description = 'flight mode';
cases(2).trimMode = 'airplane_longitudinal';
cases(2).nuaaNacelleDeg = 0;
cases(2).betaMDeg = 90;
cases(2).speeds = [70, 85, 100, 115, 130, 145, 150];
cases(2).plotVariables = {'collective_deg', 'elevator_deg', 'theta_deg'};
cases(2).plotLabels = {'Collective pitch', 'Elevator', 'Pitch attitude'};

cases(3).name = 'fig6a_transition_nuaa15';
cases(3).figure = 'Figure 6';
cases(3).subfigure = 'a';
cases(3).description = 'transition mode, NUAA nacelle tilt angle 15 deg';
cases(3).trimMode = 'conversion_longitudinal';
cases(3).nuaaNacelleDeg = 15;
cases(3).betaMDeg = 75;
cases(3).speeds = 10:10:60;
cases(3).plotVariables = {'collective_deg', 'cyclicLong_deg', 'theta_deg'};
cases(3).plotLabels = {'Collective pitch', ...
    'Vertical pitch / cyclicLong', 'Pitch attitude'};

cases(4).name = 'fig6b_transition_nuaa75';
cases(4).figure = 'Figure 6';
cases(4).subfigure = 'b';
cases(4).description = 'transition mode, NUAA nacelle tilt angle 75 deg';
cases(4).trimMode = 'conversion_longitudinal';
cases(4).nuaaNacelleDeg = 75;
cases(4).betaMDeg = 15;
cases(4).speeds = [70, 85, 100, 115, 130, 145];
cases(4).plotVariables = {'collective_deg', 'elevator_deg', 'theta_deg'};
cases(4).plotLabels = {'Collective pitch', 'Elevator', 'Pitch attitude'};
end

function [names, initials] = add_zero_pitch_rescue(definition, names, initials)
pitchIndex = find(strcmp(definition.unknownNames, 'pitchCommand'), 1);
if isempty(pitchIndex)
    return;
end
z = definition.initialValues(:);
z(pitchIndex) = 0;
names{end+1} = 'zero_pitch_rescue';
initials{end+1} = z;
end

function attempts = make_attempts(definition, names, initialValues)
attempts = repmat(struct('name', '', 'definition', definition), ...
    numel(names), 1);
seen = cell(numel(names), 1);
for k = 1:numel(names)
    attempts(k).name = names{k};
    attempts(k).definition = definition;
    attempts(k).definition.initialValues = initialValues{k}(:);
    key = sprintf('%.16g,', attempts(k).definition.initialValues);
    if any(strcmp(seen, key))
        attempts(k).name = [names{k} '_duplicate'];
    end
    seen{k} = key;
end
end

function [row, point, acceptedSeed] = solve_point(c, condition, attempts, P)
row = empty_row();
row.caseName = c.name;
row.figure = c.figure;
row.subfigure = c.subfigure;
row.description = c.description;
row.trimMode = c.trimMode;
row.velocity_mps = condition.V;
row.nuaaNacelle_deg = c.nuaaNacelleDeg;
row.betaM_deg = c.betaMDeg;
row.gamma_deg = condition.gamma*180/pi;
row.initialSource = attempts(1).name;
row.solutionSource = 'not_run';

point = struct('caseName', c.name, 'V', condition.V, 'xTrim', [], ...
    'uTrim', [], 'trimReport', struct(), 'credibility', struct(), ...
    'success', false);

best = struct('score', Inf, 'row', row, 'point', point, 'seed', []);
for k = 1:numel(attempts)
    if contains(attempts(k).name, '_duplicate')
        continue;
    end
    thisRow = row;
    thisRow.initialSource = attempts(k).name;
    try
        [xTrim, uTrim, trimReport] = trim_general( ...
            condition, attempts(k).definition, P);
        credibility = diagnose_trim_credibility( ...
            condition, attempts(k).definition, xTrim, uTrim, ...
            trimReport, P);
        thisRow = fill_success_row(thisRow, xTrim, uTrim, ...
            trimReport, credibility, attempts(k).definition, P);
        thisPoint = point;
        thisPoint.xTrim = xTrim(:);
        thisPoint.uTrim = uTrim(:);
        thisPoint.trimReport = trimReport;
        thisPoint.credibility = credibility;
        thisPoint.success = thisRow.trimConverged && thisRow.finiteReal;
        z = trim_variables_vector(trimReport, attempts(k).definition);
        score = trim_score(thisRow);
        if score < best.score
            best.score = score;
            best.row = thisRow;
            best.point = thisPoint;
            best.seed = z;
        end
        if thisRow.trimConverged && thisRow.finiteReal
            break;
        end
    catch ME
        thisRow.errorIdentifier = ME.identifier;
        thisRow.errorMessage = ME.message;
        thisRow.failureReason = sprintf('%s: %s', ME.identifier, ME.message);
        score = Inf;
        if isfinite(score) && score < best.score
            best.score = score;
            best.row = thisRow;
        elseif isinf(best.score)
            best.row = thisRow;
        end
    end
end

row = best.row;
point = best.point;
acceptedSeed = best.seed;
if contains(row.initialSource, 'rescue')
    row.solutionSource = 'rescue';
    row.usedRescue = true;
elseif strcmp(row.initialSource, 'continuation')
    row.solutionSource = 'normal_continuation';
else
    row.solutionSource = 'normal_default';
end
end

function row = fill_success_row(row, xTrim, uTrim, trimReport, ...
        credibility, definition, P)
d2r = pi/180;
row.exitflag = trimReport.exitflag;
row.solverConverged = trimReport.solverConverged;
row.trimConverged = trimReport.converged;
row.residualNorm = trimReport.residualNorm;
row.fullResidualNorm = trimReport.fullResidualNorm;
row.credibilityStatus = credibility.status;
row.credibilityReasons = strjoin(credibility.reasons(:).', ';');
row.conditionNumber = credibility.conditionNumber;
row.minimumMarginFraction = credibility.minimumMarginFraction;
row.theta_deg = xTrim(8)/d2r;
row.collective_deg = uTrim(1)/d2r;
row.diffCollective_deg = uTrim(2)/d2r;
row.cyclicLong_deg = uTrim(3)/d2r;
row.diffCyclic_deg = uTrim(4)/d2r;
row.aileron_deg = uTrim(5)/d2r;
row.elevator_deg = uTrim(6)/d2r;
row.rudder_deg = uTrim(7)/d2r;
row.pitchCommand = NaN;
if isfield(trimReport.trimVariables, 'pitchCommand')
    row.pitchCommand = trimReport.trimVariables.pitchCommand;
end
row.virtualPitchCommand = row.pitchCommand;
row.atLimit = trimReport.atLimit;
row.withinLimits = trimReport.withinLimits;
row.finiteReal = is_real_finite(xTrim) && is_real_finite(uTrim) && ...
    is_real_finite(trimReport.residual) && ...
    is_real_finite(trimReport.fullStateDerivative);
[row.controlLimitUsageMax, row.remainingControlMarginMin] = ...
    control_usage(uTrim, P);
if ~row.trimConverged
    row.failureReason = trim_failure_reason(trimReport, credibility);
end
row.unknownNames = strjoin(definition.unknownNames(:).', ';');
end

function reason = trim_failure_reason(trimReport, credibility)
items = {};
if trimReport.exitflag <= 0
    items{end+1} = sprintf('exitflag=%d', trimReport.exitflag);
end
if ~trimReport.converged
    items{end+1} = 'trimReport.converged=false';
end
if trimReport.atLimit
    items{end+1} = 'trim variable at limit';
end
if ~trimReport.withinLimits
    items{end+1} = 'trim variable outside limit';
end
if strcmp(credibility.status, 'FAIL')
    items{end+1} = ['credibility FAIL: ' ...
        strjoin(credibility.reasons(:).', ';')];
end
if isempty(items)
    reason = '';
else
    reason = strjoin(items, '; ');
end
end

function score = trim_score(row)
if row.trimConverged && row.finiteReal
    score = row.residualNorm;
else
    score = 1e6 + row.residualNorm + row.fullResidualNorm;
    if strcmp(row.credibilityStatus, 'FAIL')
        score = score + 1e5;
    end
end
end

function z = trim_variables_vector(trimReport, definition)
z = NaN(numel(definition.unknownNames), 1);
for i = 1:numel(definition.unknownNames)
    z(i) = trimReport.trimVariables.(definition.unknownNames{i});
end
end

function [usageMax, marginMin] = control_usage(uCtrl, P)
values = [uCtrl(1); uCtrl(1)+uCtrl(2); uCtrl(1)-uCtrl(2); ...
    uCtrl(3); uCtrl(3)+uCtrl(4); uCtrl(3)-uCtrl(4); uCtrl(5:7)];
lower = [repmat(P.control.collectiveLim(1), 3, 1); ...
    repmat(P.control.cyclicLim(1), 3, 1); ...
    P.control.aileronLim(1); P.control.elevatorLim(1); ...
    P.control.rudderLim(1)];
upper = [repmat(P.control.collectiveLim(2), 3, 1); ...
    repmat(P.control.cyclicLim(2), 3, 1); ...
    P.control.aileronLim(2); P.control.elevatorLim(2); ...
    P.control.rudderLim(2)];
reference = max(abs([lower, upper]), [], 2);
usageMax = max(abs(values)./reference);
margin = min(values-lower, upper-values);
marginMin = min(2*margin./(upper-lower));
end

function summaryTable = make_summary_table(rawTable, cases, elapsed)
n = numel(cases);
caseName = cell(n, 1);
description = cell(n, 1);
nuaaNacelle_deg = NaN(n, 1);
betaM_deg = NaN(n, 1);
pointCount = NaN(n, 1);
trimConvergedCount = NaN(n, 1);
credibilityPassCount = NaN(n, 1);
credibilityCautionCount = NaN(n, 1);
credibilityFailCount = NaN(n, 1);
errorCount = NaN(n, 1);
elapsed_s = repmat(elapsed, n, 1);
for i = 1:n
    mask = strcmp(rawTable.caseName, cases(i).name);
    caseName{i} = cases(i).name;
    description{i} = cases(i).description;
    nuaaNacelle_deg(i) = cases(i).nuaaNacelleDeg;
    betaM_deg(i) = cases(i).betaMDeg;
    pointCount(i) = sum(mask);
    trimConvergedCount(i) = sum(rawTable.trimConverged(mask));
    credibilityPassCount(i) = sum(strcmp(rawTable.credibilityStatus(mask), 'PASS'));
    credibilityCautionCount(i) = sum(strcmp(rawTable.credibilityStatus(mask), 'CAUTION'));
    credibilityFailCount(i) = sum(strcmp(rawTable.credibilityStatus(mask), 'FAIL'));
    errorCount(i) = sum(~cellfun(@isempty, rawTable.errorIdentifier(mask)));
end
summaryTable = table(caseName, description, nuaaNacelle_deg, betaM_deg, ...
    pointCount, trimConvergedCount, credibilityPassCount, ...
    credibilityCautionCount, credibilityFailCount, errorCount, elapsed_s);
end

function paths = make_paths(resultDir, stamp)
paths.resultDir = resultDir;
paths.figureDir = fullfile(resultDir, ['figures_' stamp]);
if ~exist(paths.figureDir, 'dir')
    mkdir(paths.figureDir);
end
paths.rawCsv = fullfile(resultDir, ['nuaa_trim_baseline_points_' stamp '.csv']);
paths.summaryCsv = fullfile(resultDir, ['nuaa_trim_baseline_summary_' stamp '.csv']);
paths.failureCsv = fullfile(resultDir, ['nuaa_trim_baseline_failures_' stamp '.csv']);
paths.mat = fullfile(resultDir, ['nuaa_trim_baseline_' stamp '.mat']);
paths.readme = fullfile(resultDir, ['nuaa_trim_baseline_notes_' stamp '.txt']);
end

function figurePaths = write_figures(rawTable, cases, figureDir)
figurePaths = cell(numel(cases), 1);
for i = 1:numel(cases)
    c = cases(i);
    mask = strcmp(rawTable.caseName, c.name);
    T = rawTable(mask, :);
    fig = figure('Visible', 'off', 'Color', 'w');
    hold on;
    styles = {'-s', '-o', '-^'};
    for j = 1:numel(c.plotVariables)
        y = T.(c.plotVariables{j});
        y(~T.trimConverged) = NaN;
        plot(T.velocity_mps, y, styles{j}, 'LineWidth', 1.5, ...
            'MarkerSize', 6, 'DisplayName', c.plotLabels{j});
    end
    failMask = ~T.trimConverged | strcmp(T.credibilityStatus, 'FAIL');
    if any(failMask)
        yl = ylim;
        yFail = yl(1)*ones(sum(failMask), 1);
        plot(T.velocity_mps(failMask), yFail, 'rx', 'LineWidth', 1.5, ...
            'MarkerSize', 8, 'DisplayName', 'failed/FAIL point');
    end
    grid on;
    xlabel('Velocity (m/s)');
    ylabel('Collective, Elevator, Pitch (deg)');
    title({required_chinese_title(), ...
        sprintf('%s(%s): %s', c.figure, c.subfigure, ...
        compact_description(c)), ...
        sprintf('NUAA nacelle %.0f deg, current betaM %.0f deg', ...
        c.nuaaNacelleDeg, c.betaMDeg)}, 'FontSize', 10);
    legend('Location', 'best');
    figurePath = fullfile(figureDir, [c.name '.png']);
    saveas(fig, figurePath);
    close(fig);
    figurePaths{i} = figurePath;
end
end

function text = compact_description(c)
if contains(c.name, 'helicopter')
    text = 'helicopter mode';
elseif contains(c.name, 'flight')
    text = 'flight mode';
else
    text = 'transition mode';
end
end

function text = required_chinese_title()
text = char(hex2dec({'5F53','524D','6982','5FF5','6A21','578B', ...
    '96F6','8C03','53C2','914D','5E73','7ED3','679C'})).';
end

function write_readme(filePath, paths, cases, totalPointCount, elapsed)
fid = fopen(filePath, 'w');
if fid < 0
    warning('Could not write notes file: %s', filePath);
    return;
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, 'NUAA Figure 5/6 current-model zero-tuning trim baseline\n');
fprintf(fid, 'Reference: references/NUAA_main_paper.pdf, PDF page 10, original page 10 of 18.\n');
fprintf(fid, 'This run uses params_nominal() and existing trim definitions only.\n');
fprintf(fid, 'It does not digitize or reproduce NUAA data points.\n\n');
fprintf(fid, 'Angle conversion: NUAA 90 deg = betaM 0 deg; NUAA 0 deg = betaM 90 deg; NUAA 15 deg = betaM 75 deg; NUAA 75 deg = betaM 15 deg.\n\n');
for i = 1:numel(cases)
    fprintf(fid, '%s %s: %s, speeds m/s =', cases(i).figure, ...
        cases(i).subfigure, cases(i).description);
    fprintf(fid, ' %.6g', cases(i).speeds);
    fprintf(fid, '\n');
end
fprintf(fid, '\nPoint count: %d\n', totalPointCount);
fprintf(fid, 'Elapsed seconds: %.3f\n', elapsed);
fprintf(fid, 'Raw CSV: %s\n', paths.rawCsv);
fprintf(fid, 'Summary CSV: %s\n', paths.summaryCsv);
fprintf(fid, 'Failure CSV: %s\n', paths.failureCsv);
fprintf(fid, 'MAT: %s\n', paths.mat);
fprintf(fid, 'Figure directory: %s\n', paths.figureDir);
end

function row = empty_row()
row = struct( ...
    'caseName', '', ...
    'figure', '', ...
    'subfigure', '', ...
    'description', '', ...
    'trimMode', '', ...
    'velocity_mps', NaN, ...
    'nuaaNacelle_deg', NaN, ...
    'betaM_deg', NaN, ...
    'gamma_deg', NaN, ...
    'theta_deg', NaN, ...
    'collective_deg', NaN, ...
    'diffCollective_deg', NaN, ...
    'cyclicLong_deg', NaN, ...
    'diffCyclic_deg', NaN, ...
    'aileron_deg', NaN, ...
    'elevator_deg', NaN, ...
    'rudder_deg', NaN, ...
    'pitchCommand', NaN, ...
    'virtualPitchCommand', NaN, ...
    'residualNorm', NaN, ...
    'fullResidualNorm', NaN, ...
    'exitflag', NaN, ...
    'solverConverged', false, ...
    'trimConverged', false, ...
    'credibilityStatus', 'NOT_RUN', ...
    'credibilityReasons', '', ...
    'conditionNumber', NaN, ...
    'minimumMarginFraction', NaN, ...
    'controlLimitUsageMax', NaN, ...
    'remainingControlMarginMin', NaN, ...
    'initialSource', '', ...
    'solutionSource', '', ...
    'usedRescue', false, ...
    'atLimit', false, ...
    'withinLimits', false, ...
    'finiteReal', false, ...
    'runtime_s', NaN, ...
    'failureReason', '', ...
    'errorIdentifier', '', ...
    'errorMessage', '', ...
    'unknownNames', '');
end

function tf = is_real_finite(value)
tf = isreal(value) && all(isfinite(value(:)));
end
