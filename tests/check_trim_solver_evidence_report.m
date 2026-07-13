function report = check_trim_solver_evidence_report()
%CHECK_TRIM_SOLVER_EVIDENCE_REPORT Verify evidence report generation.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir, 'model'));
addpath(fullfile(rootDir, 'analysis'));
addpath(fullfile(rootDir, 'services'));

outputDir = fullfile(tempdir, ['trim_solver_evidence_test_' ...
    datestr(now, 'yyyymmddTHHMMSSFFF')]);
opts = struct('outputDir', outputDir, 'smoke', true);
summary = report_trim_solver_evidence(opts);

cases = {};
passed = [];
messages = {};

add_case('report function completes', summary.recordCount > 0, '');
add_case('csv json and markdown exist', ...
    exist(summary.csvFile, 'file') == 2 && ...
    exist(summary.jsonFile, 'file') == 2 && ...
    exist(summary.reportFile, 'file') == 2, '');
add_case('all trim modes are present', has_values(summary.table.trim_mode, ...
    {'longitudinal_symmetric','lateral_directional_balance', ...
    'full_6dof_straight_trim'}), '');
add_case('both control architectures are present', ...
    has_values(summary.table.architecture, {'7-input','8-input'}), '');
add_case('required fields exist', required_fields_exist(summary.table), '');
add_case('failed records have diagnostic fields', ...
    failed_records_have_diagnostics(summary.table), '');
add_case('lateral cyclic field exists in 8-input records', ...
    any(strcmp(summary.table.architecture, '8-input') & ...
    ~isnan(summary.table.lateralCyclic_deg)), '');
add_case('no solver run errors in smoke evidence', ...
    summary.runErrorCount == 0, '');
add_case('report avoids forbidden validation claims', ...
    avoids_forbidden_claims(summary.reportFile), '');

report.names = cases;
report.passed = passed;
report.messages = messages;
report.summary = summary;
report.allPassed = all(passed);

fprintf('\nTrim solver evidence report checks\n');
fprintf('==================================\n');
for k = 1:numel(cases)
    fprintf('%-46s : %s\n', cases{k}, ternary(passed(k), 'PASS', 'FAIL'));
    if ~passed(k)
        fprintf('  %s\n', messages{k});
    end
end
fprintf('All passed: %d\n', report.allPassed);

    function add_case(name, condition, message)
        cases{end+1,1} = name;
        passed(end+1,1) = logical(condition);
        messages{end+1,1} = message;
    end
end

function ok = has_values(column, values)
ok = true;
for i = 1:numel(values)
    ok = ok && any(strcmp(column, values{i}));
end
end

function ok = required_fields_exist(t)
required = {'success','message','residual_norm','within_limits', ...
    'at_limit','any_limit_violation','collective_deg', ...
    'cyclicLong_deg','lateralCyclic_deg','rudder_deg'};
ok = all(ismember(required, t.Properties.VariableNames));
end

function ok = failed_records_have_diagnostics(t)
failed = ~t.success;
if ~any(failed)
    ok = true;
    return;
end
ok = all(~cellfun(@isempty, t.message(failed))) && ...
    all(~cellfun(@isempty, t.residual_labels(failed))) && ...
    all(~cellfun(@isempty, t.limit_summary(failed)));
end

function ok = avoids_forbidden_claims(reportFile)
text = fileread(reportFile);
forbidden = {'NUAA validated','Berger validated','XV-15 validated', ...
    'trend pass','handling qualities validated'};
ok = true;
for i = 1:numel(forbidden)
    ok = ok && ~contains(text, forbidden{i});
end
end

function value = ternary(condition, a, b)
if condition
    value = a;
else
    value = b;
end
end
