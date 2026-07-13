function summary = report_trim_solver_evidence(opts)
%REPORT_TRIM_SOLVER_EVIDENCE Export internal trim-solver evidence.
% This diagnostic records current solver behavior. It is not external
% validation and does not tune parameters or alter solver definitions.

if nargin < 1 || isempty(opts)
    opts = struct();
end

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir, 'model'));
addpath(fullfile(rootDir, 'analysis'));
addpath(fullfile(rootDir, 'services'));

if ~isfield(opts, 'timestamp') || isempty(opts.timestamp)
    opts.timestamp = datestr(now, 'yyyymmddTHHMMSS');
end
if isfield(opts, 'outputDir') && ~isempty(opts.outputDir)
    outputDir = opts.outputDir;
else
    if ~isfield(opts, 'outputRoot') || isempty(opts.outputRoot)
        opts.outputRoot = fullfile(rootDir, 'validation', ...
            'trim_solver_evidence');
    end
    outputDir = fullfile(opts.outputRoot, opts.timestamp);
end
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

if isfield(opts, 'cases') && ~isempty(opts.cases)
    cases = opts.cases;
elseif isfield(opts, 'smoke') && opts.smoke
    cases = default_cases(true);
else
    cases = default_cases(false);
end

trimModes = {'longitudinal_symmetric'; ...
    'lateral_directional_balance'; 'full_6dof_straight_trim'};
architectures = {'7-input'; '8-input'};
records = repmat(empty_record(), 0, 1);

for iCase = 1:numel(cases)
    for iArch = 1:numel(architectures)
        P = params_nominal();
        P.control.enableLateralCyclic = strcmp(architectures{iArch}, ...
            '8-input');
        controlNames = get_control_input_names(P);
        stateNames = get_state_names(P);
        for iMode = 1:numel(trimModes)
            config = make_config(cases(iCase), trimModes{iMode});
            fprintf('Evidence run: case=%s architecture=%s mode=%s\n', ...
                cases(iCase).name, architectures{iArch}, trimModes{iMode});
            record = run_one_case(config, P, cases(iCase).name, ...
                architectures{iArch}, stateNames, controlNames);
            records(end+1,1) = record; %#ok<AGROW>
        end
    end
end

csvTable = records_to_table(records);
csvFile = fullfile(outputDir, 'trim_solver_evidence.csv');
jsonFile = fullfile(outputDir, 'trim_solver_evidence.json');
reportFile = fullfile(outputDir, 'TRIM_SOLVER_EVIDENCE_REPORT.md');
writetable(csvTable, csvFile);
write_json(jsonFile, records, cases, architectures, trimModes);
write_markdown(reportFile, records);

summary.outputDir = outputDir;
summary.csvFile = csvFile;
summary.jsonFile = jsonFile;
summary.reportFile = reportFile;
summary.records = records;
summary.table = csvTable;
summary.caseCount = numel(cases);
summary.recordCount = numel(records);
summary.successCount = sum([records.success]);
summary.failureCount = sum(~[records.success]);
summary.runErrorCount = sum([records.run_error]);
summary.trimModes = trimModes;
summary.architectures = architectures;

fprintf('\nTrim solver evidence report\n');
fprintf('===========================\n');
fprintf('Output directory: %s\n', outputDir);
fprintf('Records: %d, success: %d, failure: %d, run errors: %d\n', ...
    summary.recordCount, summary.successCount, summary.failureCount, ...
    summary.runErrorCount);
end

function cases = default_cases(smoke)
if smoke
    cases = struct('name', 'helicopter_low_speed', 'V', 20, ...
        'betaMDeg', 0, 'gammaDeg', 0);
    return;
end
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

function config = make_config(caseDef, trimMode)
config = struct('V', caseDef.V, 'betaMDeg', caseDef.betaMDeg, ...
    'gammaDeg', caseDef.gammaDeg, 'initialThetaDeg', 0, ...
    'initialCollectiveDeg', 18, 'initialCyclicLongDeg', 0, ...
    'thetaLimitDeg', 35, 'useMultiStart', false, ...
    'alwaysMultiStart', false, 'trimMode', trimMode);
end

function record = run_one_case(config, P, caseName, architecture, ...
        stateNames, controlNames)
record = empty_record();
record.case_name = caseName;
record.trim_mode = config.trimMode;
record.architecture = architecture;
record.V_mps = config.V;
record.betaM_deg = config.betaMDeg;
record.gamma_deg = config.gammaDeg;
record.lateralCyclic_available = any(strcmp(controlNames, 'lateralCyclic'));
try
    result = run_trim_case(config, P);
    record = fill_from_result(record, result, stateNames, controlNames);
catch ME
    record.run_error = true;
    record.success = false;
    record.message = sprintf('%s: %s', ME.identifier, ME.message);
end
end

function record = fill_from_result(record, result, stateNames, controlNames)
record.success = logical(get_field(result, 'success', false));
record.message = result_message(result);
record.finite = logical(get_report_field(result, 'finite', ...
    all(isfinite_or_nan(get_field(result, 'xdot', NaN)))));
record.guarded = logical(get_field(result, 'guarded', false));
record.solver_converged = logical(get_report_field(result, ...
    'solverConverged', get_report_field(result, 'converged', false)));
record.residual_norm = get_report_field(result, 'residualNorm', NaN);
record.primary_residual_norm = get_report_field(result, ...
    'primaryResidualNorm', get_report_field(result, ...
    'lateralResidualNorm', record.residual_norm));
record.full_residual_norm = get_report_field(result, ...
    'fullResidualNorm', vector_norm(get_field(result, 'xdot', NaN)));
record.success_tolerance = get_report_field(result, 'successTolerance', NaN);
record.within_limits = logical(get_report_field(result, ...
    'withinLimits', false));
record.at_limit = logical(get_report_field(result, 'atLimit', false));
limitReport = get_report_field(result, 'limitReport', struct());
record.any_limit_violation = logical(get_field(limitReport, ...
    'anyViolation', false));
record.limit_summary = limit_summary(limitReport);
definition = get_field(result, 'definition', struct());
record.selected_controls = string_list(get_report_field(result, ...
    'selectedControls', get_report_field(result, 'unknownNames', ...
    get_field(definition, 'unknownNames', {}))));
record.control_norm = get_report_field(result, 'controlNorm', NaN);
record.regularization_weight = get_report_field(result, ...
    'regularizationWeight', NaN);
record.effective_degrees_of_freedom = get_report_field(result, ...
    'effectiveDegreesOfFreedom', NaN);

residualLabels = cellstr_list(get_report_field(result, ...
    'residualLabels', {}));
residualValues = get_report_field(result, 'residual', NaN);
scaledResidual = get_report_field(result, 'scaledResidual', NaN);
record.residual_labels = string_list(residualLabels);
record.residual_values = number_list(residualValues);
record.scaled_residual_values = number_list(scaledResidual);

x = get_field(result, 'xTrim', NaN(numel(stateNames),1));
u = get_field(result, 'uTrim', NaN(numel(controlNames),1));
record.theta_deg = state_value(x, stateNames, 'theta')*180/pi;
record.phi_deg = state_value(x, stateNames, 'phi')*180/pi;
record.u_mps = state_value(x, stateNames, 'u');
record.v_mps = state_value(x, stateNames, 'v');
record.w_mps = state_value(x, stateNames, 'w');
record.p_degps = state_value(x, stateNames, 'p')*180/pi;
record.q_degps = state_value(x, stateNames, 'q')*180/pi;
record.r_degps = state_value(x, stateNames, 'r')*180/pi;

record.collective_deg = control_value(u, controlNames, 'collective')*180/pi;
record.diffCollective_deg = control_value(u, controlNames, ...
    'diffCollective')*180/pi;
record.cyclicLong_deg = control_value(u, controlNames, 'cyclicLong')*180/pi;
record.diffCyclic_deg = control_value(u, controlNames, 'diffCyclic')*180/pi;
record.lateralCyclic_deg = control_value(u, controlNames, ...
    'lateralCyclic')*180/pi;
record.aileron_deg = control_value(u, controlNames, 'aileron')*180/pi;
record.elevator_deg = control_value(u, controlNames, 'elevator')*180/pi;
record.rudder_deg = control_value(u, controlNames, 'rudder')*180/pi;
record.lateralCyclic_selected = contains_token(record.selected_controls, ...
    'lateralCyclic');

loads = get_field(result, 'loads', struct());
F = get_field(loads, 'Ftotal', NaN(3,1));
M = get_field(loads, 'Mtotal', NaN(3,1));
record.Ftotal_x = vector_value(F, 1);
record.Ftotal_y = vector_value(F, 2);
record.Ftotal_z = vector_value(F, 3);
record.Mtotal_x = vector_value(M, 1);
record.Mtotal_y = vector_value(M, 2);
record.Mtotal_z = vector_value(M, 3);
end

function record = empty_record()
record = struct( ...
    'case_name', '', 'trim_mode', '', 'architecture', '', ...
    'V_mps', NaN, 'betaM_deg', NaN, 'gamma_deg', NaN, ...
    'success', false, 'message', '', 'finite', false, ...
    'guarded', false, 'solver_converged', false, ...
    'residual_norm', NaN, 'primary_residual_norm', NaN, ...
    'full_residual_norm', NaN, 'residual_labels', '', ...
    'residual_values', '', 'scaled_residual_values', '', ...
    'success_tolerance', NaN, 'theta_deg', NaN, 'phi_deg', NaN, ...
    'u_mps', NaN, 'v_mps', NaN, 'w_mps', NaN, ...
    'p_degps', NaN, 'q_degps', NaN, 'r_degps', NaN, ...
    'collective_deg', NaN, 'diffCollective_deg', NaN, ...
    'cyclicLong_deg', NaN, 'diffCyclic_deg', NaN, ...
    'lateralCyclic_deg', NaN, 'aileron_deg', NaN, ...
    'elevator_deg', NaN, 'rudder_deg', NaN, ...
    'within_limits', false, 'at_limit', false, ...
    'any_limit_violation', false, 'limit_summary', '', ...
    'selected_controls', '', 'control_norm', NaN, ...
    'regularization_weight', NaN, ...
    'effective_degrees_of_freedom', NaN, ...
    'lateralCyclic_available', false, ...
    'lateralCyclic_selected', false, ...
    'Ftotal_x', NaN, 'Ftotal_y', NaN, 'Ftotal_z', NaN, ...
    'Mtotal_x', NaN, 'Mtotal_y', NaN, 'Mtotal_z', NaN, ...
    'run_error', false);
end

function tableOut = records_to_table(records)
tableOut = struct2table(records);
end

function write_json(jsonFile, records, cases, architectures, trimModes)
payload.generated = datestr(now, 30);
payload.scope = ['Internal numerical trim solver evidence; not external ' ...
    'validation and not a trend comparison.'];
payload.cases = cases;
payload.architectures = architectures;
payload.trimModes = trimModes;
payload.records = records;
text = jsonencode(payload, 'PrettyPrint', true);
fid = fopen(jsonFile, 'w');
if fid < 0
    error('report_trim_solver_evidence:CannotOpenJson', ...
        'Cannot open JSON output file.');
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '%s\n', text);
end

function write_markdown(reportFile, records)
fid = fopen(reportFile, 'w');
if fid < 0
    error('report_trim_solver_evidence:CannotOpenMarkdown', ...
        'Cannot open Markdown output file.');
end
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, '# Trim Solver Evidence Report\n\n');
fprintf(fid, 'This is internal numerical evidence for the current trim ');
fprintf(fid, 'solver interfaces. It is not external validation, not an ');
fprintf(fid, 'NUAA/Berger/XV-15 trend comparison, and not a handling qualities ');
fprintf(fid, 'assessment.\n\n');
fprintf(fid, 'Default 7-input architecture keeps ');
fprintf(fid, '`P.control.enableLateralCyclic = false`. The 8-input ');
fprintf(fid, 'architecture explicitly enables `lateralCyclic`.\n\n');

fprintf(fid, '## Case Status\n\n');
fprintf(fid, '|case|mode|architecture|success|residual norm|within limits|message|\n');
fprintf(fid, '|-|-|-|-:|-:|-:|-|\n');
for i = 1:numel(records)
    r = records(i);
    fprintf(fid, '|%s|%s|%s|%d|%.6e|%d|%s|\n', ...
        r.case_name, r.trim_mode, r.architecture, r.success, ...
        r.residual_norm, r.within_limits, escape_pipe(r.message));
end

fprintf(fid, '\n## Controls Summary\n\n');
fprintf(fid, ['|case|mode|architecture|collective deg|cyclicLong deg|' ...
    'lateralCyclic deg|aileron deg|elevator deg|rudder deg|selected controls|\n']);
fprintf(fid, '|-|-|-|-:|-:|-:|-:|-:|-:|-|\n');
for i = 1:numel(records)
    r = records(i);
    fprintf(fid, '|%s|%s|%s|%.6g|%.6g|%.6g|%.6g|%.6g|%.6g|%s|\n', ...
        r.case_name, r.trim_mode, r.architecture, ...
        r.collective_deg, r.cyclicLong_deg, r.lateralCyclic_deg, ...
        r.aileron_deg, r.elevator_deg, r.rudder_deg, ...
        escape_pipe(r.selected_controls));
end

fprintf(fid, '\n## Residual Summary\n\n');
fprintf(fid, '|case|mode|architecture|labels|values|full residual norm|limit summary|\n');
fprintf(fid, '|-|-|-|-|-|-:|-|\n');
for i = 1:numel(records)
    r = records(i);
    fprintf(fid, '|%s|%s|%s|%s|%s|%.6e|%s|\n', ...
        r.case_name, r.trim_mode, r.architecture, ...
        escape_pipe(r.residual_labels), escape_pipe(r.residual_values), ...
        r.full_residual_norm, escape_pipe(r.limit_summary));
end

fprintf(fid, '\n## Limitations\n\n');
fprintf(fid, '- These runs are representative internal smoke diagnostics only.\n');
fprintf(fid, '- A failed trim run is recorded as evidence and is not hidden.\n');
fprintf(fid, '- No model equations, default parameters, or control limits are tuned.\n');
fprintf(fid, '- No external validation or trend comparison is claimed.\n');
end

function value = get_field(s, name, defaultValue)
if isstruct(s) && isfield(s, name)
    value = s.(name);
else
    value = defaultValue;
end
end

function value = get_report_field(result, name, defaultValue)
if isfield(result, 'report') && isstruct(result.report) && ...
        isfield(result.report, name)
    value = result.report.(name);
else
    value = defaultValue;
end
end

function text = result_message(result)
if isfield(result, 'message') && ~isempty(result.message)
    text = char(result.message);
elseif isfield(result, 'report') && isfield(result.report, 'message') && ...
        ~isempty(result.report.message)
    text = char(result.report.message);
elseif isfield(result, 'success') && result.success
    text = 'success';
elseif isfield(result, 'report') && isfield(result.report, 'atLimit') && ...
        result.report.atLimit
    text = 'Trim did not meet convergence criteria; an active limit was reached.';
elseif isfield(result, 'report') && isfield(result.report, 'residualNorm')
    text = sprintf(['Trim did not meet convergence criteria; ' ...
        'residual norm %.3e.'], result.report.residualNorm);
else
    text = 'failed without message';
end
end

function value = state_value(x, names, name)
idx = find(strcmp(names, name), 1);
value = vector_value(x, idx);
end

function value = control_value(u, names, name)
idx = find(strcmp(names, name), 1);
value = vector_value(u, idx);
end

function value = vector_value(v, idx)
if isempty(idx) || ~isnumeric(v) || numel(v) < idx
    value = NaN;
else
    value = v(idx);
end
end

function value = vector_norm(v)
if isnumeric(v) && ~isempty(v)
    value = norm(v(:));
else
    value = NaN;
end
end

function ok = isfinite_or_nan(v)
ok = isnumeric(v) && isreal(v) && all(isfinite(v(:)) | isnan(v(:)));
end

function text = string_list(value)
items = cellstr_list(value);
text = strjoin(items(:).', ';');
end

function items = cellstr_list(value)
if isempty(value)
    items = {};
elseif ischar(value)
    items = cellstr(value);
elseif isstring(value)
    items = cellstr(value(:));
elseif iscell(value)
    items = value(:);
else
    items = cellstr(string(value(:)));
end
end

function text = number_list(value)
if ~(isnumeric(value) || islogical(value)) || isempty(value)
    text = '';
    return;
end
items = cell(numel(value),1);
for i = 1:numel(value)
    items{i} = sprintf('%.12g', value(i));
end
text = strjoin(items(:).', ';');
end

function tf = contains_token(text, token)
if isempty(text)
    tf = false;
else
    tf = any(strcmp(strsplit(text, ';'), token));
end
end

function text = limit_summary(limitReport)
if ~isstruct(limitReport)
    text = '';
    return;
end
items = [];
if isfield(limitReport, 'items')
    items = limitReport.items;
elseif isfield(limitReport, 'entries')
    items = limitReport.entries;
end
if isempty(items)
    text = sprintf('atLimit=%d violation=%d', ...
        get_field(limitReport, 'anyAtLimit', false), ...
        get_field(limitReport, 'anyViolation', false));
    return;
end
parts = {};
for i = 1:numel(items)
    if get_field(items(i), 'atLimit', false) || ...
            get_field(items(i), 'violated', false)
        parts{end+1} = sprintf('%s atLimit=%d violated=%d', ...
            get_field(items(i), 'name', ''), ...
            get_field(items(i), 'atLimit', false), ...
            get_field(items(i), 'violated', false)); %#ok<AGROW>
    end
end
if isempty(parts)
    text = 'no active limits or violations';
else
    text = strjoin(parts, ';');
end
end

function text = escape_pipe(text)
text = strrep(char(text), '|', '/');
text = strrep(text, newline, ' ');
end
