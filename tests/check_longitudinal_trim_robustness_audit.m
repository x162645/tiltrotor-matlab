function report = check_longitudinal_trim_robustness_audit()
%CHECK_LONGITUDINAL_TRIM_ROBUSTNESS_AUDIT Verify opt-in trim audit outputs.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir, 'analysis'));
addpath(fullfile(rootDir, 'model'));
addpath(fullfile(rootDir, 'services'));

P0 = params_nominal();
outputDir = fullfile(tempdir, ['longitudinal_trim_robustness_test_' ...
    datestr(now, 'yyyymmddTHHMMSSFFF')]);
audit = audit_longitudinal_trim_robustness(struct( ...
    'outputDir', outputDir, 'runHeavy', false, ...
    'localMaxIterations', 30));
P1 = params_nominal();

cases = {};
passed = [];
messages = {};

add_case('audit function completes', isstruct(audit), '');
add_case('contains four representative cases', ...
    audit.caseCount >= 4 && has_values({audit.records.case_name}, ...
    {'helicopter_low_speed','conversion_mid','airplane_like', ...
    'conversion_high'}), '');
add_case('contains required candidate families', ...
    has_values({audit.records.candidate_family}, {'baseline', ...
    'cyclic_limit','elevator_unknown','multistart', ...
    'scaling_weighting','full6dof_comparison'}), '');
add_case('required output fields exist', ...
    required_fields_exist(audit.summaryTable), '');
add_case('output files are text artifacts', ...
    exist(audit.reportFile, 'file') == 2 && ...
    exist(audit.summaryCsvFile, 'file') == 2 && ...
    exist(audit.summaryJsonFile, 'file') == 2 && ...
    exist(audit.casesCsvFile, 'file') == 2, '');
add_case('params_nominal cyclic limit unchanged', ...
    isequal(P0.control.cyclicLim, P1.control.cyclicLim), '');
add_case('params_nominal lateralCyclic default unchanged', ...
    ~P0.control.enableLateralCyclic && ...
    isequal(P0.control.enableLateralCyclic, ...
    P1.control.enableLateralCyclic), '');
add_case('diagnostic labels are populated', ...
    all(~cellfun(@isempty, {audit.records.diagnosis_label})), '');
add_case('report avoids forbidden validation claims', ...
    avoids_forbidden_claims(audit.reportFile), '');
add_case('non-running candidates are recorded not crashed', ...
    all(~[audit.records.run_error] | strcmp({audit.records.diagnosis_label}, ...
    'NOT_RUN_WITH_REASON')), '');

report.names = cases;
report.passed = passed;
report.messages = messages;
report.summary = audit;
report.allPassed = all(passed);

fprintf('\nLongitudinal trim robustness audit checks\n');
fprintf('=========================================\n');
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

function ok = has_values(items, expected)
ok = true;
for i = 1:numel(expected)
    ok = ok && any(strcmp(items, expected{i}));
end
end

function ok = required_fields_exist(t)
required = {'case_name','candidate_name','candidate_family', ...
    'trim_mode','unknown_set','selected_controls','success', ...
    'solver_converged','residual_norm','dominant_residual_label', ...
    'active_limit_names','diagnosis_label'};
ok = all(ismember(required, t.Properties.VariableNames));
end

function ok = avoids_forbidden_claims(reportFile)
text = fileread(reportFile);
forbidden = {'validation completed','validated against XV-15', ...
    'NUAA validated','Berger validated','trend pass', ...
    'handling qualities validated','elevator fix is proven.'};
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
