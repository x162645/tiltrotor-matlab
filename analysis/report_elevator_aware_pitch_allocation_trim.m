function summary = report_elevator_aware_pitch_allocation_trim(opts)
%REPORT_ELEVATOR_AWARE_PITCH_ALLOCATION_TRIM Export opt-in evidence.
% The report records candidate behavior only. It is not external validation,
% not a default solver replacement, and not a parameter or limit change.

if nargin < 1 || isempty(opts)
    opts = struct();
end

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir, 'model'));
addpath(fullfile(rootDir, 'analysis'));
addpath(fullfile(rootDir, 'services'));

opts = apply_defaults(opts, rootDir);
if exist(opts.outputDir, 'dir') ~= 7
    mkdir(opts.outputDir);
end

records = repmat(empty_record(), 0, 1);
cases = opts.cases;
candidates = candidate_plan(opts.runHeavy);

for iCase = 1:numel(cases)
    baseline = run_existing_baseline(cases(iCase));
    for iCandidate = 1:numel(candidates)
        fprintf('Elevator-aware evidence: case=%s candidate=%s\n', ...
            cases(iCase).name, candidates(iCandidate).candidateName);
        record = run_candidate(cases(iCase), candidates(iCandidate), ...
            baseline, opts);
        records(end+1, 1) = record; %#ok<AGROW>
    end
end

caseSummary = build_case_summary(records);
tableAll = struct2table(records);
tableSummary = struct2table(caseSummary);

summary.outputDir = opts.outputDir;
summary.reportFile = fullfile(opts.outputDir, ...
    'ELEVATOR_AWARE_PITCH_ALLOCATION_TRIM_REPORT.md');
summary.casesCsvFile = fullfile(opts.outputDir, ...
    'elevator_aware_pitch_allocation_trim_cases.csv');
summary.summaryCsvFile = fullfile(opts.outputDir, ...
    'elevator_aware_pitch_allocation_trim_summary.csv');
summary.summaryJsonFile = fullfile(opts.outputDir, ...
    'elevator_aware_pitch_allocation_trim_summary.json');
summary.records = records;
summary.caseSummary = caseSummary;
summary.recordCount = numel(records);
summary.caseCount = numel(cases);
summary.candidateCount = numel(candidates);
summary.successCount = sum([records.success]);
summary.runErrorCount = sum([records.run_error]);
summary.runHeavy = opts.runHeavy;
summary.solverRunHeavy = opts.solverRunHeavy;

writetable(tableAll, summary.casesCsvFile);
writetable(tableSummary, summary.summaryCsvFile);
write_json(summary.summaryJsonFile, summary);
write_markdown(summary.reportFile, summary);

fprintf('\nElevator-aware pitch allocation trim report\n');
fprintf('===========================================\n');
fprintf('Output directory: %s\n', summary.outputDir);
fprintf('Records: %d, success: %d, run errors: %d\n', ...
    summary.recordCount, summary.successCount, summary.runErrorCount);
end

function opts = apply_defaults(opts, rootDir)
if ~isfield(opts, 'runHeavy') || isempty(opts.runHeavy)
    opts.runHeavy = true;
end
if ~isfield(opts, 'timestamp') || isempty(opts.timestamp)
    opts.timestamp = datestr(now, 'yyyymmddTHHMMSS');
end
if ~isfield(opts, 'outputDir') || isempty(opts.outputDir)
    opts.outputDir = fullfile(rootDir, 'validation', ...
        'elevator_aware_pitch_allocation_trim', opts.timestamp);
end
if ~isfield(opts, 'cases') || isempty(opts.cases)
    opts.cases = default_cases();
end
if ~isfield(opts, 'maxIterations') || isempty(opts.maxIterations)
    opts.maxIterations = 120;
end
if ~isfield(opts, 'solverRunHeavy') || isempty(opts.solverRunHeavy)
    opts.solverRunHeavy = false;
end
end

function cases = default_cases()
cases = repmat(struct('name', '', 'V', NaN, 'betaMDeg', NaN, ...
    'gammaDeg', 0), 4, 1);
cases(1).name = 'helicopter_low_speed';
cases(1).V = 20;
cases(1).betaMDeg = 0;
cases(2).name = 'conversion_mid';
cases(2).V = 45;
cases(2).betaMDeg = 45;
cases(3).name = 'airplane_like';
cases(3).V = 100;
cases(3).betaMDeg = 90;
cases(4).name = 'conversion_high';
cases(4).V = 70;
cases(4).betaMDeg = 75;
end

function candidates = candidate_plan(runHeavy)
raw = {
    'baseline_existing_summary', 'baseline_existing_summary', [1 1 1]
    'theta_collective_cyclicLong', 'theta_collective_cyclicLong', [1 1 1]
    'theta_collective_elevator', 'theta_collective_elevator', [1 1 1]
    'theta_collective_cyclicLong_elevator_regularized', ...
    'theta_collective_cyclicLong_elevator_regularized', [1 1 1]
    'theta_collective_scheduled_pitch', ...
    'theta_collective_scheduled_pitch', [1 1 1]
    };
if runHeavy
    raw = [raw; {
        'scheduled_pitch_force_priority', ...
        'theta_collective_scheduled_pitch', [2 2 0.5]
        'scheduled_pitch_moment_priority', ...
        'theta_collective_scheduled_pitch', [0.75 0.75 2]
        }];
end
candidates = repmat(struct('candidateName', '', 'controlSet', '', ...
    'residualWeights', [1;1;1]), size(raw, 1), 1);
for i = 1:size(raw, 1)
    candidates(i).candidateName = raw{i, 1};
    candidates(i).controlSet = raw{i, 2};
    candidates(i).residualWeights = raw{i, 3}(:);
end
end

function baseline = run_existing_baseline(caseDef)
P = params_nominal();
config = struct('V', caseDef.V, 'betaMDeg', caseDef.betaMDeg, ...
    'gammaDeg', caseDef.gammaDeg, 'trimMode', 'longitudinal_symmetric', ...
    'useMultiStart', false, 'alwaysMultiStart', false);
baseline = run_trim_case(config, P);
end

function record = run_candidate(caseDef, candidate, baseline, opts)
record = empty_record();
record.case_name = caseDef.name;
record.V = caseDef.V;
record.betaM_deg = caseDef.betaMDeg;
record.gamma_deg = caseDef.gammaDeg;
record.candidate_name = candidate.candidateName;
record.control_set = candidate.controlSet;
record.use_schedule = strcmp(candidate.controlSet, ...
    'theta_collective_scheduled_pitch');
record.baseline_residual_norm = baseline.report.residualNorm;
Pbaseline = params_nominal();
record.tolerance = get_report_field(baseline.report, 'successTolerance', ...
    Pbaseline.trim.residualTolerance);
record.residual_norm_over_tolerance = Inf;

if strcmp(candidate.candidateName, 'baseline_existing_summary')
    record = fill_from_baseline(record, baseline);
    return;
end

try
    P = params_nominal();
    localOpts.candidateName = candidate.candidateName;
    localOpts.controlSet = candidate.controlSet;
    localOpts.residualWeights = candidate.residualWeights;
    localOpts.runHeavy = opts.solverRunHeavy;
    if ~isempty(opts.maxIterations)
        localOpts.maxIterations = opts.maxIterations;
    end
    result = trim_longitudinal_elevator_aware(P, caseDef, localOpts);
    record = fill_from_candidate(record, result, baseline);
catch ME
    record.run_error = true;
    record.success = false;
    record.solver_converged = false;
    record.message = sprintf('%s: %s', ME.identifier, ME.message);
    record.diagnosis_label = 'NOT_RUN_WITH_REASON';
end
end

function record = fill_from_baseline(record, result)
stateNames = result.stateNames;
controlNames = result.controlNames;
x = result.xTrim;
u = result.uTrim;
report = result.report;
record.success = logical(result.success);
record.solver_converged = logical(report.solverConverged);
record.residual_norm = report.residualNorm;
record.weighted_residual_norm = norm(report.scaledResidual);
record.raw_udot = report.residual(1);
record.raw_wdot = report.residual(2);
record.raw_qdot = report.residual(3);
record.dominant_residual = dominant_label(report.residualLabels, ...
    report.residual);
record.theta_deg = state_value(x, stateNames, 'theta')*180/pi;
record.collective_deg = control_value(u, controlNames, 'collective')*180/pi;
record.cyclicLong_deg = control_value(u, controlNames, 'cyclicLong')*180/pi;
record.elevator_deg = control_value(u, controlNames, 'elevator')*180/pi;
record.cyclic_weight = cos(result.betaM)^2;
record.elevator_weight = sin(result.betaM)^2;
record.active_limit_names = active_limits(report.limitReport);
record.within_default_limits = logical(report.withinLimits);
record.message = result_message(result);
record.residual_norm_over_tolerance = record.residual_norm/record.tolerance;
record.diagnosis_label = 'BASELINE_REPRODUCED';
end

function record = fill_from_candidate(record, result, baseline)
stateNames = result.stateNames;
controlNames = result.controlNames;
record.success = logical(result.success);
record.solver_converged = logical(result.solverConverged);
record.residual_norm = result.residualNorm;
record.weighted_residual_norm = result.weightedResidualNorm;
record.residual_norm_over_tolerance = result.residualNorm/result.successTolerance;
record.raw_udot = residual_value(result, 'udot');
record.raw_wdot = residual_value(result, 'wdot');
record.raw_qdot = residual_value(result, 'qdot');
record.dominant_residual = result.dominantResidual;
record.theta_deg = state_value(result.xTrim, stateNames, 'theta')*180/pi;
record.collective_deg = control_value(result.uTrim, controlNames, ...
    'collective')*180/pi;
record.cyclicLong_deg = control_value(result.uTrim, controlNames, ...
    'cyclicLong')*180/pi;
record.elevator_deg = control_value(result.uTrim, controlNames, ...
    'elevator')*180/pi;
record.cyclic_weight = result.cyclicWeight;
record.elevator_weight = result.elevatorWeight;
record.active_limit_names = result.limitReport.activeLimitNames;
record.within_default_limits = logical(result.withinDefaultLimits);
record.message = result.message;
record.diagnosis_label = classify_candidate(record, baseline);
end

function label = classify_candidate(record, baseline)
base = baseline.report.residualNorm;
if record.run_error
    label = 'NOT_RUN_WITH_REASON';
elseif record.success && record.residual_norm < base
    if record.use_schedule
        label = 'SCHEDULED_ALLOCATION_IMPROVES';
    else
        label = 'ELEVATOR_AWARE_IMPROVES';
    end
elseif ~record.within_default_limits || ~isempty(record.active_limit_names)
    label = 'CONTROL_LIMIT_CONTACT';
else
    improvement = improvement_fraction(base, record.residual_norm);
    if improvement >= 0.5 && record.use_schedule
        label = 'SCHEDULED_ALLOCATION_IMPROVES';
    elseif improvement >= 0.5
        label = 'ELEVATOR_AWARE_IMPROVES';
    elseif contains(record.candidate_name, 'force_priority') && improvement > 0
        label = 'FORCE_PRIORITY_SENSITIVE';
    elseif contains(record.candidate_name, 'moment_priority') && improvement > 0
        label = 'MOMENT_PRIORITY_SENSITIVE';
    elseif record.use_schedule
        label = 'SCHEDULED_ALLOCATION_NOT_ENOUGH';
    elseif contains(record.control_set, 'elevator')
        label = 'ELEVATOR_AWARE_NOT_ENOUGH';
    elseif record.residual_norm_over_tolerance >= 100
        label = 'FORMULATION_LIMITATION_LIKELY';
    else
        label = 'NONLINEAR_SOLVER_LIMITATION';
    end
end
end

function rows = build_case_summary(records)
caseNames = unique({records.case_name}, 'stable');
rows = repmat(struct('case_name', '', 'baseline_residual_norm', NaN, ...
    'best_candidate', '', 'best_residual_norm', NaN, ...
    'best_improvement_fraction', NaN, 'best_diagnosis_label', ''), ...
    numel(caseNames), 1);
for i = 1:numel(caseNames)
    idx = strcmp({records.case_name}, caseNames{i});
    subset = records(idx);
    baseIdx = strcmp({subset.candidate_name}, 'baseline_existing_summary');
    baseResidual = subset(find(baseIdx, 1)).residual_norm;
    residuals = [subset.residual_norm];
    [bestResidual, bestIdx] = min(residuals);
    rows(i).case_name = caseNames{i};
    rows(i).baseline_residual_norm = baseResidual;
    rows(i).best_candidate = subset(bestIdx).candidate_name;
    rows(i).best_residual_norm = bestResidual;
    rows(i).best_improvement_fraction = improvement_fraction( ...
        baseResidual, bestResidual);
    rows(i).best_diagnosis_label = subset(bestIdx).diagnosis_label;
end
end

function record = empty_record()
record = struct('case_name', '', 'V', NaN, 'betaM_deg', NaN, ...
    'gamma_deg', NaN, 'candidate_name', '', 'control_set', '', ...
    'use_schedule', false, 'success', false, 'solver_converged', false, ...
    'run_error', false, 'baseline_residual_norm', NaN, ...
    'residual_norm', NaN, 'residual_norm_over_tolerance', NaN, ...
    'raw_udot', NaN, 'raw_wdot', NaN, 'raw_qdot', NaN, ...
    'weighted_residual_norm', NaN, 'dominant_residual', '', ...
    'theta_deg', NaN, 'collective_deg', NaN, 'cyclicLong_deg', NaN, ...
    'elevator_deg', NaN, 'cyclic_weight', NaN, 'elevator_weight', NaN, ...
    'active_limit_names', '', 'within_default_limits', false, ...
    'message', '', 'diagnosis_label', '', 'tolerance', NaN);
end

function value = residual_value(result, name)
idx = strcmp(result.residualLabels, name);
if any(idx)
    value = result.residual(idx);
else
    value = NaN;
end
end

function value = state_value(x, names, name)
idx = find(strcmp(names, name), 1);
if isempty(idx) || numel(x) < idx
    value = NaN;
else
    value = x(idx);
end
end

function value = control_value(u, names, name)
idx = find(strcmp(names, name), 1);
if isempty(idx) || numel(u) < idx
    value = NaN;
else
    value = u(idx);
end
end

function text = active_limits(limitReport)
if isfield(limitReport, 'activeLimitNames')
    text = limitReport.activeLimitNames;
    return;
end
text = '';
if isfield(limitReport, 'items')
    items = limitReport.items;
    text = strjoin({items([items.atLimit]).name}, ';');
end
end

function text = result_message(result)
if isfield(result, 'message')
    text = result.message;
elseif isfield(result, 'report') && isfield(result.report, 'message')
    text = result.report.message;
else
    text = '';
end
end

function value = get_report_field(report, name, defaultValue)
if isstruct(report) && isfield(report, name)
    value = report.(name);
else
    value = defaultValue;
end
end

function label = dominant_label(labels, values)
[~, idx] = max(abs(values));
label = labels{idx};
end

function value = improvement_fraction(baseResidual, residual)
if isfinite(baseResidual) && baseResidual > 0 && isfinite(residual)
    value = (baseResidual-residual)/baseResidual;
else
    value = NaN;
end
end

function write_json(jsonFile, summary)
payload = rmfield(summary, {'records','caseSummary'});
payload.records = summary.records;
payload.caseSummary = summary.caseSummary;
text = jsonencode(payload, 'PrettyPrint', true);
fid = fopen(jsonFile, 'w');
if fid < 0
    error('report_elevator_aware_pitch_allocation_trim:CannotOpenJson', ...
        'Cannot open JSON output file.');
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '%s\n', text);
end

function write_markdown(reportFile, summary)
fid = fopen(reportFile, 'w');
if fid < 0
    error('report_elevator_aware_pitch_allocation_trim:CannotOpenMarkdown', ...
        'Cannot open Markdown output file.');
end
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, '# Elevator-Aware Pitch Allocation Trim Candidate\n\n');
fprintf(fid, '## 1. Executive Summary\n\n');
fprintf(fid, ['This report covers an opt-in implementation candidate. It ' ...
    'does not replace the default longitudinal trim path, change model ' ...
    'equations, alter params_nominal defaults, change default control ' ...
    'limits, change GUI defaults, or enable lateralCyclic by default.\n\n']);
fprintf(fid, ['The goal is to test whether elevator-aware and scheduled pitch ' ...
    'allocation candidates improve the PR #46/#47 non-helicopter ' ...
    'longitudinal residuals. The evidence is internal numerical diagnostic ' ...
    'evidence only.\n\n']);

fprintf(fid, '## 2. Motivation from PR #46 / PR #47\n\n');
fprintf(fid, ['PR #46 found conversion_mid cyclicLong authority sensitivity, ' ...
    'airplane_like elevator qdot/wdot authority, conversion_high ' ...
    'formulation/scaling sensitivity, no strict sign-error evidence, and ' ...
    'SOURCE_REQUIRED status for cyclicLong and elevator limits. PR #47 ' ...
    'recommended an opt-in elevator-aware follow-up without changing ' ...
    'defaults.\n\n']);

fprintf(fid, '## 3. Candidate Formulations\n\n');
fprintf(fid, ['- baseline_existing_summary\n- theta_collective_cyclicLong\n' ...
    '- theta_collective_elevator\n' ...
    '- theta_collective_cyclicLong_elevator_regularized\n' ...
    '- theta_collective_scheduled_pitch\n' ...
    '- scheduled_pitch_force_priority\n' ...
    '- scheduled_pitch_moment_priority\n\n']);
fprintf(fid, ['The default report run keeps the full candidate matrix but ' ...
    'uses single-start finite-budget solves for reproducibility. Solver ' ...
    'multistart remains explicitly opt-in through solverRunHeavy.\n\n']);

fprintf(fid, '## 4. Schedule Definition\n\n');
fprintf(fid, ['The scheduled candidates use cyclicWeight = cos(betaM)^2 and ' ...
    'elevatorWeight = sin(betaM)^2. This is a candidate schedule only, ' ...
    'not an externally validated control law and not a default control ' ...
    'allocation change.\n\n']);

fprintf(fid, '## 5. Evidence Matrix\n\n');
write_struct_table(fid, summary.records, {'case_name','candidate_name', ...
    'success','residual_norm','active_limit_names','diagnosis_label'});

fprintf(fid, '## 6. Interpretation\n\n');
write_struct_table(fid, summary.caseSummary, {'case_name', ...
    'baseline_residual_norm','best_candidate','best_residual_norm', ...
    'best_improvement_fraction','best_diagnosis_label'});
fprintf(fid, ['\nHelicopter low-speed should remain non-degraded. ' ...
    'conversion_mid and airplane_like indicate whether elevator-aware or ' ...
    'scheduled candidates improve the residuals. conversion_high should be ' ...
    'interpreted conservatively because PR #46/#47 already identified ' ...
    'formulation/scaling sensitivity.\n\n']);

fprintf(fid, '## 7. Recommended Next Step\n\n');
fprintf(fid, ['Use these results to decide whether an opt-in GUI/service hook ' ...
    'is worth reviewing. Continue residual-normalization, force/moment ' ...
    'chain, and source-limit audits before any default-path change.\n\n']);

fprintf(fid, '## 8. What Not To Claim\n\n');
fprintf(fid, '- Do not claim external validation.\n');
fprintf(fid, '- Do not claim all-envelope trim reliability.\n');
fprintf(fid, '- Do not claim NUAA/Berger/XV-15 match.\n');
fprintf(fid, '- Do not claim trend pass/fail.\n');
fprintf(fid, '- Do not claim elevator fix proven.\n');
fprintf(fid, '- Do not claim scheduled allocation is physically validated.\n');
fprintf(fid, '- Do not claim cyclicLong default limit should be widened.\n');
fprintf(fid, '- Do not claim sign wrong.\n');
fprintf(fid, ['- Do not claim model equations are wrong solely from ' ...
    'non-convergence.\n']);
end

function write_struct_table(fid, rows, fields)
fprintf(fid, '|%s|\n', strjoin(fields, '|'));
fprintf(fid, '|%s|\n', strjoin(repmat({'-'}, size(fields)), '|'));
for i = 1:numel(rows)
    values = cell(1, numel(fields));
    for j = 1:numel(fields)
        values{j} = format_value(rows(i).(fields{j}));
    end
    fprintf(fid, '|%s|\n', strjoin(values, '|'));
end
fprintf(fid, '\n');
end

function text = format_value(value)
if islogical(value)
    if value
        text = 'true';
    else
        text = 'false';
    end
elseif isnumeric(value)
    if isnan(value)
        text = 'NaN';
    elseif isinf(value)
        text = 'Inf';
    else
        text = sprintf('%.6g', value);
    end
else
    text = char(value);
end
text = strrep(text, '|', '/');
text = strrep(text, newline, ' ');
end
