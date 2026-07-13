function diagnostic = diagnose_trim_solver_evidence_failures(evidenceDir, opts)
%DIAGNOSE_TRIM_SOLVER_EVIDENCE_FAILURES Classify PR #44 trim evidence failures.
% This diagnostic reads committed evidence files only. It does not rerun trim
% solvers, change model equations, tune parameters, or relabel failures.

if nargin < 1 || isempty(evidenceDir)
    evidenceDir = latest_evidence_dir();
elseif isstruct(evidenceDir)
    opts = evidenceDir;
    evidenceDir = latest_evidence_dir();
end
if nargin < 2 || isempty(opts)
    opts = struct();
end

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir, 'analysis'));

csvFile = fullfile(evidenceDir, 'trim_solver_evidence.csv');
jsonFile = fullfile(evidenceDir, 'trim_solver_evidence.json');
if exist(csvFile, 'file') ~= 2 || exist(jsonFile, 'file') ~= 2
    error('diagnose_trim_solver_evidence_failures:MissingEvidence', ...
        'Evidence directory must contain trim_solver_evidence.csv/json.');
end

tableIn = readtable(csvFile);
jsonText = fileread(jsonFile);

records = table_to_records(tableIn);
failureRows = build_failure_rows(records);
matrix = build_failure_matrix(records);
categoryCounts = build_category_counts(failureRows);
dominantSummary = build_dominant_summary(failureRows);
comparison = build_architecture_comparison(records);

diagnostic.evidenceDir = evidenceDir;
diagnostic.csvFile = csvFile;
diagnostic.jsonFile = jsonFile;
diagnostic.jsonRecordCount = count_json_records(jsonText);
diagnostic.totalRecords = numel(records);
diagnostic.successCount = sum([records.success]);
diagnostic.failureCount = sum(~[records.success]);
diagnostic.runErrorCount = sum([records.run_error]);
diagnostic.caseNames = unique_cell({records.case_name});
diagnostic.trimModes = unique_cell({records.trim_mode});
diagnostic.architectures = unique_cell({records.architecture});
diagnostic.failureRows = failureRows;
diagnostic.failureTable = struct2table(failureRows);
diagnostic.failureMatrix = matrix;
diagnostic.failureMatrixTable = struct2table(matrix);
diagnostic.categoryCounts = categoryCounts;
diagnostic.categoryCountTable = struct2table(categoryCounts);
diagnostic.dominantResidualSummary = dominantSummary;
diagnostic.dominantResidualTable = struct2table(dominantSummary);
diagnostic.architectureComparison = comparison;
diagnostic.architectureComparisonTable = struct2table(comparison);

if isfield(opts, 'outputDir') && ~isempty(opts.outputDir)
    diagnostic = write_outputs(diagnostic, opts.outputDir);
end

fprintf('\nTrim solver failure diagnostic\n');
fprintf('==============================\n');
fprintf('Evidence directory: %s\n', evidenceDir);
fprintf('Records: %d, success: %d, failures: %d, run errors: %d\n', ...
    diagnostic.totalRecords, diagnostic.successCount, ...
    diagnostic.failureCount, diagnostic.runErrorCount);
end

function evidenceDir = latest_evidence_dir()
rootDir = fileparts(fileparts(mfilename('fullpath')));
baseDir = fullfile(rootDir, 'validation', 'trim_solver_evidence');
listing = dir(baseDir);
matches = {};
for i = 1:numel(listing)
    if listing(i).isdir && listing(i).name(1) ~= '.'
        candidate = fullfile(baseDir, listing(i).name);
        if exist(fullfile(candidate, 'trim_solver_evidence.csv'), 'file') == 2 && ...
                exist(fullfile(candidate, 'trim_solver_evidence.json'), 'file') == 2
            matches{end+1,1} = candidate; %#ok<AGROW>
        end
    end
end
if isempty(matches)
    error('diagnose_trim_solver_evidence_failures:NoEvidence', ...
        'No trim solver evidence directory was found.');
end
[~, order] = sort(matches);
matches = matches(order);
evidenceDir = matches{end};
end

function records = table_to_records(t)
records = repmat(empty_record(), height(t), 1);
for i = 1:height(t)
    r = empty_record();
    names = t.Properties.VariableNames;
    for j = 1:numel(names)
        r.(names{j}) = field_value(t, names{j}, i);
    end
    r.success = as_bool(r.success);
    r.finite = as_bool(r.finite);
    r.solver_converged = as_bool(r.solver_converged);
    r.within_limits = as_bool(r.within_limits);
    r.at_limit = as_bool(r.at_limit);
    r.any_limit_violation = as_bool(r.any_limit_violation);
    r.lateralCyclic_available = as_bool(r.lateralCyclic_available);
    r.lateralCyclic_selected = as_bool(r.lateralCyclic_selected);
    r.run_error = as_bool(r.run_error);
    records(i) = r;
end
end

function r = empty_record()
r = struct('case_name', '', 'trim_mode', '', 'architecture', '', ...
    'V_mps', NaN, 'betaM_deg', NaN, 'gamma_deg', NaN, ...
    'success', false, 'message', '', 'finite', false, ...
    'guarded', false, 'solver_converged', false, 'residual_norm', NaN, ...
    'primary_residual_norm', NaN, 'full_residual_norm', NaN, ...
    'residual_labels', '', 'residual_values', '', ...
    'scaled_residual_values', '', 'success_tolerance', NaN, ...
    'theta_deg', NaN, 'phi_deg', NaN, 'u_mps', NaN, ...
    'v_mps', NaN, 'w_mps', NaN, 'p_degps', NaN, ...
    'q_degps', NaN, 'r_degps', NaN, 'collective_deg', NaN, ...
    'diffCollective_deg', NaN, 'cyclicLong_deg', NaN, ...
    'diffCyclic_deg', NaN, 'lateralCyclic_deg', NaN, ...
    'aileron_deg', NaN, 'elevator_deg', NaN, 'rudder_deg', NaN, ...
    'within_limits', false, 'at_limit', false, ...
    'any_limit_violation', false, 'limit_summary', '', ...
    'selected_controls', '', 'control_norm', NaN, ...
    'regularization_weight', NaN, ...
    'effective_degrees_of_freedom', NaN, ...
    'lateralCyclic_available', false, ...
    'lateralCyclic_selected', false, 'Ftotal_x', NaN, ...
    'Ftotal_y', NaN, 'Ftotal_z', NaN, 'Mtotal_x', NaN, ...
    'Mtotal_y', NaN, 'Mtotal_z', NaN, 'run_error', false);
end

function rows = build_failure_rows(records)
failures = records(~[records.success]);
rows = repmat(empty_failure_row(), numel(failures), 1);
for i = 1:numel(failures)
    r = failures(i);
    [label, value] = dominant_residual(r.residual_labels, ...
        r.residual_values);
    [scaledLabel, scaledValue] = dominant_residual(r.residual_labels, ...
        r.scaled_residual_values);
    category = classify_failure(r);
    rows(i).case_name = r.case_name;
    rows(i).architecture = r.architecture;
    rows(i).trim_mode = r.trim_mode;
    rows(i).failure_category = category;
    rows(i).message = r.message;
    rows(i).residual_norm = r.residual_norm;
    rows(i).primary_residual_norm = r.primary_residual_norm;
    rows(i).full_residual_norm = r.full_residual_norm;
    rows(i).success_tolerance = r.success_tolerance;
    rows(i).residual_to_tolerance = residual_ratio(r);
    rows(i).dominant_residual_label = label;
    rows(i).dominant_residual_value = value;
    rows(i).dominant_scaled_residual_label = scaledLabel;
    rows(i).dominant_scaled_residual_value = scaledValue;
    rows(i).within_limits = r.within_limits;
    rows(i).at_limit = r.at_limit;
    rows(i).any_limit_violation = r.any_limit_violation;
    rows(i).limit_summary = r.limit_summary;
    rows(i).selected_controls = r.selected_controls;
    rows(i).lateralCyclic_available = r.lateralCyclic_available;
    rows(i).lateralCyclic_selected = r.lateralCyclic_selected;
    rows(i).suspected_root_cause = suspected_root_cause(r, category, ...
        label);
end
end

function row = empty_failure_row()
row = struct('case_name', '', 'architecture', '', 'trim_mode', '', ...
    'failure_category', '', 'message', '', 'residual_norm', NaN, ...
    'primary_residual_norm', NaN, 'full_residual_norm', NaN, ...
    'success_tolerance', NaN, 'residual_to_tolerance', NaN, ...
    'dominant_residual_label', '', 'dominant_residual_value', NaN, ...
    'dominant_scaled_residual_label', '', ...
    'dominant_scaled_residual_value', NaN, ...
    'within_limits', false, 'at_limit', false, ...
    'any_limit_violation', false, 'limit_summary', '', ...
    'selected_controls', '', 'lateralCyclic_available', false, ...
    'lateralCyclic_selected', false, 'suspected_root_cause', '');
end

function category = classify_failure(r)
message = lower(r.message);
if strcmp(r.trim_mode, 'lateral_directional_balance') && ...
        (contains(message, 'base trim') || contains(message, 'dependency'))
    category = 'BASE_TRIM_DEPENDENCY_FAILURE';
elseif ~r.finite && ~contains(message, 'base trim')
    category = 'NONFINITE_OR_INVALID_EVAL';
elseif strcmp(r.trim_mode, 'full_6dof_straight_trim')
    category = 'FULL6DOF_FORMULATION_LIMITATION';
elseif r.at_limit || r.any_limit_violation
    category = 'CONTROL_OR_STATE_LIMIT_CONTACT';
elseif r.within_limits && ~r.at_limit && r.residual_norm > 0.005
    category = 'PRIMARY_RESIDUAL_NOT_REDUCED';
elseif isfinite(r.residual_norm) && isfinite(r.success_tolerance) && ...
        r.residual_norm < 10*r.success_tolerance
    category = 'STRICT_SUCCESS_CRITERION_FAILURE';
else
    category = 'UNKNOWN_FAILURE';
end
end

function cause = suspected_root_cause(r, category, dominantLabel)
switch category
    case 'BASE_TRIM_DEPENDENCY_FAILURE'
        cause = ['Longitudinal base trim did not converge, so the ' ...
            'lateral objective was not evaluated.'];
    case 'FULL6DOF_FORMULATION_LIMITATION'
        cause = sprintf(['Full 6-DOF objective ran, but %s dominates ' ...
            'and the residual remains far above tolerance.'], ...
            dominantLabel);
    case 'CONTROL_OR_STATE_LIMIT_CONTACT'
        cause = sprintf(['A trim variable or control reached an active ' ...
            'limit: %s.'], r.limit_summary);
    case 'PRIMARY_RESIDUAL_NOT_REDUCED'
        cause = sprintf(['Residual remains high without active limits; ' ...
            '%s is the dominant residual.'], dominantLabel);
    case 'NONFINITE_OR_INVALID_EVAL'
        cause = 'The row contains a nonfinite or invalid evaluation.';
    case 'STRICT_SUCCESS_CRITERION_FAILURE'
        cause = ['Residual is near tolerance but strict success checks ' ...
            'were not all satisfied.'];
    otherwise
        cause = 'Failure did not match a known diagnostic category.';
end
end

function ratio = residual_ratio(r)
if isfinite(r.residual_norm) && isfinite(r.success_tolerance) && ...
        r.success_tolerance > 0
    ratio = r.residual_norm/r.success_tolerance;
else
    ratio = NaN;
end
end

function rows = build_failure_matrix(records)
caseNames = {'helicopter_low_speed','conversion_mid', ...
    'airplane_like','conversion_high'};
architectures = {'7-input','8-input'};
rows = repmat(empty_matrix_row(), numel(caseNames)*numel(architectures), 1);
k = 0;
for iCase = 1:numel(caseNames)
    for iArch = 1:numel(architectures)
        k = k + 1;
        rows(k).case_name = caseNames{iCase};
        rows(k).architecture = architectures{iArch};
        rows(k).longitudinal = mode_status(records, caseNames{iCase}, ...
            architectures{iArch}, 'longitudinal_symmetric');
        rows(k).lateral = mode_status(records, caseNames{iCase}, ...
            architectures{iArch}, 'lateral_directional_balance');
        rows(k).full6dof = mode_status(records, caseNames{iCase}, ...
            architectures{iArch}, 'full_6dof_straight_trim');
        rows(k).notes = matrix_notes(records, caseNames{iCase}, ...
            architectures{iArch});
    end
end
end

function row = empty_matrix_row()
row = struct('case_name', '', 'architecture', '', 'longitudinal', '', ...
    'lateral', '', 'full6dof', '', 'notes', '');
end

function status = mode_status(records, caseName, architecture, mode)
idx = strcmp({records.case_name}, caseName) & ...
    strcmp({records.architecture}, architecture) & ...
    strcmp({records.trim_mode}, mode);
if ~any(idx)
    status = 'MISSING';
elseif records(idx).success
    status = 'PASS';
else
    status = 'FAIL';
end
end

function notes = matrix_notes(records, caseName, architecture)
sub = records(strcmp({records.case_name}, caseName) & ...
    strcmp({records.architecture}, architecture));
if all([sub.success])
    notes = 'all modes converge';
elseif strcmp(caseName, 'conversion_mid')
    notes = ['longitudinal cyclicLong=-35 deg limit; lateral blocked ' ...
        'by base failure; full6dof residual about 2.20'];
elseif strcmp(caseName, 'airplane_like')
    notes = ['longitudinal cyclicLong=+35 deg limit; lateral blocked ' ...
        'by base failure; full6dof residual about 3.16'];
elseif strcmp(caseName, 'conversion_high')
    notes = ['no active longitudinal limit, but residual remains about ' ...
        '6.20; lateral blocked by base failure'];
else
    notes = 'representative condition summary unavailable';
end
end

function counts = build_category_counts(failureRows)
categories = {'BASE_TRIM_DEPENDENCY_FAILURE', ...
    'FULL6DOF_FORMULATION_LIMITATION', 'CONTROL_OR_STATE_LIMIT_CONTACT', ...
    'PRIMARY_RESIDUAL_NOT_REDUCED', 'NONFINITE_OR_INVALID_EVAL', ...
    'STRICT_SUCCESS_CRITERION_FAILURE', 'UNKNOWN_FAILURE'};
counts = repmat(struct('category', '', 'count', 0, ...
    'affected_modes', '', 'primary_interpretation', ''), ...
    numel(categories), 1);
for i = 1:numel(categories)
    idx = strcmp({failureRows.failure_category}, categories{i});
    counts(i).category = categories{i};
    counts(i).count = sum(idx);
    counts(i).affected_modes = strjoin(unique_cell( ...
        {failureRows(idx).trim_mode}), ';');
    counts(i).primary_interpretation = category_interpretation( ...
        categories{i});
end
end

function text = category_interpretation(category)
switch category
    case 'BASE_TRIM_DEPENDENCY_FAILURE'
        text = 'lateral mode did not run because base trim failed';
    case 'FULL6DOF_FORMULATION_LIMITATION'
        text = 'full 6-DOF residual remains far above tolerance';
    case 'CONTROL_OR_STATE_LIMIT_CONTACT'
        text = 'active trim/control limit prevents success';
    case 'PRIMARY_RESIDUAL_NOT_REDUCED'
        text = 'residual remains high without active limit contact';
    case 'NONFINITE_OR_INVALID_EVAL'
        text = 'nonfinite or invalid evaluation';
    case 'STRICT_SUCCESS_CRITERION_FAILURE'
        text = 'near tolerance but strict success checks failed';
    otherwise
        text = 'unclassified failure';
end
end

function rows = build_dominant_summary(failureRows)
caseNames = {'conversion_mid','airplane_like','conversion_high'};
rows = repmat(struct('case_name', '', 'dominant_residual_label', '', ...
    'affected_modes', '', 'interpretation', ''), numel(caseNames), 1);
for i = 1:numel(caseNames)
    idx = strcmp({failureRows.case_name}, caseNames{i}) & ...
        ~strcmp({failureRows.dominant_residual_label}, 'NA');
    labels = {failureRows(idx).dominant_residual_label};
    rows(i).case_name = caseNames{i};
    rows(i).dominant_residual_label = most_common(labels);
    rows(i).affected_modes = strjoin(unique_cell( ...
        {failureRows(idx).trim_mode}), ';');
    rows(i).interpretation = dominant_interpretation( ...
        rows(i).dominant_residual_label);
end
end

function text = dominant_interpretation(label)
if strcmp(label, 'udot')
    text = 'body-x acceleration / longitudinal force balance dominates';
elseif strcmp(label, 'wdot')
    text = 'body-z acceleration / lift-thrust balance dominates';
elseif strcmp(label, 'qdot')
    text = 'pitch moment residual is present but not largest raw residual';
else
    text = 'dominant residual is not available';
end
end

function rows = build_architecture_comparison(records)
caseNames = {'helicopter_low_speed','conversion_mid', ...
    'airplane_like','conversion_high'};
modes = {'longitudinal_symmetric','lateral_directional_balance', ...
    'full_6dof_straight_trim'};
rows = repmat(empty_comparison_row(), numel(caseNames)*numel(modes), 1);
k = 0;
for iCase = 1:numel(caseNames)
    for iMode = 1:numel(modes)
        k = k + 1;
        r7 = find_record(records, caseNames{iCase}, '7-input', modes{iMode});
        r8 = find_record(records, caseNames{iCase}, '8-input', modes{iMode});
        rows(k).case_name = caseNames{iCase};
        rows(k).trim_mode = modes{iMode};
        rows(k).residual_7 = r7.residual_norm;
        rows(k).residual_8 = r8.residual_norm;
        rows(k).improvement_ratio = improvement_ratio(r7, r8);
        rows(k).lateralCyclic_selected = r8.lateralCyclic_selected;
        rows(k).lateralCyclic_deg = r8.lateralCyclic_deg;
        rows(k).interpretation = comparison_interpretation(r7, r8);
    end
end
end

function row = empty_comparison_row()
row = struct('case_name', '', 'trim_mode', '', 'residual_7', NaN, ...
    'residual_8', NaN, 'improvement_ratio', NaN, ...
    'lateralCyclic_selected', false, 'lateralCyclic_deg', NaN, ...
    'interpretation', '');
end

function r = find_record(records, caseName, architecture, mode)
idx = strcmp({records.case_name}, caseName) & ...
    strcmp({records.architecture}, architecture) & ...
    strcmp({records.trim_mode}, mode);
if ~any(idx)
    error('diagnose_trim_solver_evidence_failures:MissingRecord', ...
        'Missing record for %s %s %s.', caseName, architecture, mode);
end
r = records(find(idx, 1));
end

function ratio = improvement_ratio(r7, r8)
if isfinite(r7.residual_norm) && isfinite(r8.residual_norm) && ...
        r7.residual_norm ~= 0
    ratio = (r7.residual_norm - r8.residual_norm)/r7.residual_norm;
else
    ratio = NaN;
end
end

function text = comparison_interpretation(r7, r8)
if r7.success && r8.success
    text = 'both architectures already converge';
elseif isinf(r7.residual_norm) && isinf(r8.residual_norm)
    text = 'both architectures blocked by dependency failure';
elseif strcmp(r8.trim_mode, 'full_6dof_straight_trim') && ...
        r8.lateralCyclic_selected
    ratio = improvement_ratio(r7, r8);
    if isfinite(ratio) && ratio > 0.02
        text = ['8-input modestly improves residual, but the case still ' ...
            'fails tolerance'];
    elseif isfinite(ratio) && ratio < -0.01
        text = ['8-input does not improve the total residual in this ' ...
            'case; no effectiveness conclusion is implied'];
    else
        text = ['8-input has no meaningful total residual change; ' ...
            'dominant residual remains longitudinal'];
    end
else
    text = 'lateralCyclic is not selected by this mode';
end
end

function [label, value] = dominant_residual(labelText, valueText)
labels = split_tokens(labelText);
values = parse_number_list(valueText);
if isempty(labels) || isempty(values) || numel(labels) ~= numel(values) || ...
        all(isnan(values))
    label = 'NA';
    value = NaN;
    return;
end
[~, idx] = max(abs(values));
label = labels{idx};
value = values(idx);
end

function labels = split_tokens(text)
text = char(text);
if isempty(text)
    labels = {};
else
    labels = strsplit(text, ';');
end
end

function values = parse_number_list(text)
tokens = split_tokens(text);
values = NaN(size(tokens));
for i = 1:numel(tokens)
    values(i) = str2double(tokens{i});
end
end

function value = field_value(t, name, idx)
raw = t.(name);
if iscell(raw)
    value = raw{idx};
elseif isstring(raw)
    value = char(raw(idx));
else
    value = raw(idx);
end
end

function value = as_bool(value)
if islogical(value)
    return;
elseif isnumeric(value)
    value = value ~= 0;
elseif ischar(value)
    value = strcmpi(value, 'true') || strcmp(value, '1');
else
    value = logical(value);
end
end

function items = unique_cell(items)
if isempty(items)
    items = {};
    return;
end
items = items(~cellfun(@isempty, items));
[~, idx] = unique(items, 'stable');
items = items(sort(idx));
end

function value = most_common(items)
items = unique_cell(items);
if isempty(items)
    value = 'NA';
    return;
end
counts = zeros(numel(items),1);
for i = 1:numel(items)
    counts(i) = sum(strcmp(items{i}, items));
end
[~, idx] = max(counts);
value = items{idx};
end

function n = count_json_records(text)
matches = regexp(text, '"case_name"\s*:', 'match');
n = numel(matches);
end

function diagnostic = write_outputs(diagnostic, outputDir)
if exist(outputDir, 'dir') ~= 7
    mkdir(outputDir);
end
diagnostic.outputDir = outputDir;
diagnostic.reportFile = fullfile(outputDir, ...
    'TRIM_SOLVER_FAILURE_DIAGNOSTIC.md');
diagnostic.csvFile = fullfile(outputDir, ...
    'trim_solver_failure_diagnostic.csv');
diagnostic.jsonFile = fullfile(outputDir, ...
    'trim_solver_failure_diagnostic.json');
writetable(diagnostic.failureTable, diagnostic.csvFile);
write_json(diagnostic.jsonFile, diagnostic);
write_markdown(diagnostic.reportFile, diagnostic);
end

function write_json(jsonFile, diagnostic)
payload.scope = ['Internal trim solver failure diagnostic; not external ' ...
    'validation and not a trend-comparison result.'];
payload.evidenceDir = diagnostic.evidenceDir;
payload.totalRecords = diagnostic.totalRecords;
payload.successCount = diagnostic.successCount;
payload.failureCount = diagnostic.failureCount;
payload.runErrorCount = diagnostic.runErrorCount;
payload.categoryCounts = diagnostic.categoryCounts;
payload.dominantResidualSummary = diagnostic.dominantResidualSummary;
payload.architectureComparison = diagnostic.architectureComparison;
payload.failureRows = diagnostic.failureRows;
text = jsonencode(payload, 'PrettyPrint', true);
fid = fopen(jsonFile, 'w');
if fid < 0
    error('diagnose_trim_solver_evidence_failures:CannotOpenJson', ...
        'Cannot open JSON output file.');
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '%s\n', text);
end

function write_markdown(reportFile, diagnostic)
fid = fopen(reportFile, 'w');
if fid < 0
    error('diagnose_trim_solver_evidence_failures:CannotOpenMarkdown', ...
        'Cannot open Markdown output file.');
end
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, '# Trim Solver Failure Diagnostic\n\n');
fprintf(fid, 'This diagnostic classifies the committed PR #44 trim solver ');
fprintf(fid, 'evidence. It does not rerun trim solvers, tune parameters, ');
fprintf(fid, 'change equations, or relabel non-converged rows as success.\n\n');
fprintf(fid, '## 1. Executive Summary\n\n');
fprintf(fid, '- Records: %d\n', diagnostic.totalRecords);
fprintf(fid, '- Success: %d\n', diagnostic.successCount);
fprintf(fid, '- Failures/non-converged: %d\n', diagnostic.failureCount);
fprintf(fid, '- Run errors: %d\n', diagnostic.runErrorCount);
fprintf(fid, ['- Low-speed helicopter case succeeds for all modes and ' ...
    'both architectures.\n']);
fprintf(fid, ['- All non-helicopter representative cases fail in all ' ...
    'three modes.\n\n']);

write_table(fid, '## 2. Failure Matrix', ...
    {'case','architecture','longitudinal','lateral','full6dof','notes'}, ...
    diagnostic.failureMatrix, {'case_name','architecture','longitudinal', ...
    'lateral','full6dof','notes'});
write_table(fid, '## 3. Failure Category Counts', ...
    {'category','count','affected modes','interpretation'}, ...
    diagnostic.categoryCounts, {'category','count','affected_modes', ...
    'primary_interpretation'});
write_table(fid, '## 4. Dominant Residual Analysis', ...
    {'case','dominant residual','affected modes','interpretation'}, ...
    diagnostic.dominantResidualSummary, {'case_name', ...
    'dominant_residual_label','affected_modes','interpretation'});
write_table(fid, '## 5. Limit and Control Analysis', ...
    {'case','mode','arch','at limit','within limits','selected controls', ...
    'suspected limitation'}, diagnostic.failureRows, {'case_name', ...
    'trim_mode','architecture','at_limit','within_limits', ...
    'selected_controls','suspected_root_cause'});
write_table(fid, '## 6. 7-input vs 8-input Comparison', ...
    {'case','mode','residual 7','residual 8','improvement', ...
    'lateralCyclic selected','interpretation'}, ...
    diagnostic.architectureComparison, {'case_name','trim_mode', ...
    'residual_7','residual_8','improvement_ratio', ...
    'lateralCyclic_selected','interpretation'});

fprintf(fid, '\n## 7. Most Likely Root Causes\n\n');
fprintf(fid, ['- Solver/formulation level: lateral failures mostly ' ...
    'reflect base-trim dependency failures; full 6-DOF runs remain far ' ...
    'above tolerance in conversion/high-speed cases.\n']);
fprintf(fid, ['- Control allocation level: conversion_mid and ' ...
    'airplane_like reach cyclicLong limits; lateralCyclic participates ' ...
    'in 8-input full6dof rows but does not remove longitudinal residuals.\n']);
fprintf(fid, ['- Model/physics level: representative conversion and ' ...
    'airplane-like cases expose stronger thrust/lift/pitch coupling than ' ...
    'the current trim variable set resolves.\n']);
fprintf(fid, ['- Numerical optimization level: conversion_high remains high ' ...
    'without active limits, so scaling, multistart, or residual weighting ' ...
    'sensitivity is a follow-up diagnostic.\n\n']);

fprintf(fid, '## 8. Recommended Next Actions\n\n');
fprintf(fid, '- A. Run a longitudinal trim robustness audit first.\n');
fprintf(fid, ['- B. Audit whether elevator should enter the full6dof ' ...
    'unknown set in conversion/fixed-wing-like conditions.\n']);
fprintf(fid, ['  Elevator entry into the full6dof unknown set is a ' ...
    'diagnostic hypothesis for follow-up audit only; it is not a ' ...
    'proven fix and is not implemented by this diagnostic.\n']);
fprintf(fid, ['- C. Audit lateral objectives only on cases with converged ' ...
    'base trim.\n']);
fprintf(fid, '- D. Run cyclicLong limit sensitivity.\n');
fprintf(fid, ['- E. Run lateralCyclic allocation / regularization ' ...
    'sensitivity.\n']);
fprintf(fid, ['- F. Run multistart / variable scaling / residual weighting ' ...
    'sensitivity.\n\n']);

fprintf(fid, '## 9. What Not To Claim\n\n');
fprintf(fid, '- No external validation passed.\n');
fprintf(fid, '- No all-envelope trim reliability is proven.\n');
fprintf(fid, '- No NUAA/Berger/XV-15 trend consistency is claimed.\n');
fprintf(fid, '- Solver failure does not prove model equations are wrong.\n');
fprintf(fid, '- Do not claim lateralCyclic is ineffective.\n');
fprintf(fid, '- Non-convergence is not a run error.\n');
end

function write_table(fid, title, headers, rows, fields)
fprintf(fid, '\n%s\n\n', title);
fprintf(fid, '|%s|\n', strjoin(headers, '|'));
fprintf(fid, '|%s|\n', strjoin(repmat({'-'}, size(headers)), '|'));
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
    text = char(string(value));
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
