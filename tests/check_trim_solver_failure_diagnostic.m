function report = check_trim_solver_failure_diagnostic()
%CHECK_TRIM_SOLVER_FAILURE_DIAGNOSTIC Verify trim evidence failure diagnosis.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir, 'analysis'));

evidenceDir = fullfile(rootDir, 'validation', 'trim_solver_evidence', ...
    '20260713T164911');
outputDir = fullfile(tempdir, ['trim_solver_failure_diagnostic_test_' ...
    datestr(now, 'yyyymmddTHHMMSSFFF')]);
diagnostic = diagnose_trim_solver_evidence_failures(evidenceDir, ...
    struct('outputDir', outputDir));

cases = {};
passed = [];
messages = {};

add_case('diagnostic function completes', isstruct(diagnostic), '');
add_case('reads PR44 evidence record count', ...
    diagnostic.totalRecords == 24, '');
add_case('failure count is preserved', diagnostic.failureCount == 18, '');
add_case('run errors remain zero', diagnostic.runErrorCount == 0, '');
add_case('required categories exist', ...
    has_categories(diagnostic.categoryCounts, ...
    {'BASE_TRIM_DEPENDENCY_FAILURE', ...
    'FULL6DOF_FORMULATION_LIMITATION', ...
    'CONTROL_OR_STATE_LIMIT_CONTACT', ...
    'PRIMARY_RESIDUAL_NOT_REDUCED'}), '');
add_case('category counts match evidence', ...
    category_count(diagnostic, 'BASE_TRIM_DEPENDENCY_FAILURE') == 6 && ...
    category_count(diagnostic, 'FULL6DOF_FORMULATION_LIMITATION') == 6 && ...
    category_count(diagnostic, 'CONTROL_OR_STATE_LIMIT_CONTACT') == 4 && ...
    category_count(diagnostic, 'PRIMARY_RESIDUAL_NOT_REDUCED') == 2, '');
add_case('dominant residual summary matches evidence', ...
    dominant_for_case(diagnostic, 'conversion_mid', 'udot') && ...
    dominant_for_case(diagnostic, 'airplane_like', 'wdot') && ...
    dominant_for_case(diagnostic, 'conversion_high', 'wdot'), '');
add_case('output files are written', ...
    exist(diagnostic.reportFile, 'file') == 2 && ...
    exist(diagnostic.csvFile, 'file') == 2 && ...
    exist(diagnostic.jsonFile, 'file') == 2, '');
add_case('diagnostic avoids forbidden validation claims', ...
    avoids_forbidden_claims(diagnostic.reportFile) && ...
    avoids_forbidden_claims(fullfile(rootDir, 'docs', ...
    'TRIM_SOLVER_FAILURE_DIAGNOSTIC.md')), '');
add_case('failure rows are not required to succeed', ...
    all(~[diagnostic.failureRows.lateralCyclic_available] | ...
    ismember({diagnostic.failureRows.failure_category}, ...
    {'BASE_TRIM_DEPENDENCY_FAILURE', ...
    'FULL6DOF_FORMULATION_LIMITATION', ...
    'CONTROL_OR_STATE_LIMIT_CONTACT', ...
    'PRIMARY_RESIDUAL_NOT_REDUCED'})), '');

report.names = cases;
report.passed = passed;
report.messages = messages;
report.summary = diagnostic;
report.allPassed = all(passed);

fprintf('\nTrim solver failure diagnostic checks\n');
fprintf('=====================================\n');
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

function ok = has_categories(categoryCounts, expected)
names = {categoryCounts.category};
ok = true;
for i = 1:numel(expected)
    ok = ok && any(strcmp(names, expected{i}));
end
end

function count = category_count(diagnostic, category)
idx = strcmp({diagnostic.categoryCounts.category}, category);
if any(idx)
    count = diagnostic.categoryCounts(idx).count;
else
    count = NaN;
end
end

function ok = dominant_for_case(diagnostic, caseName, expectedLabel)
idx = strcmp({diagnostic.dominantResidualSummary.case_name}, caseName);
ok = any(idx) && strcmp( ...
    diagnostic.dominantResidualSummary(idx).dominant_residual_label, ...
    expectedLabel);
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
