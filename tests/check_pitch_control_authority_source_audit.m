function report = check_pitch_control_authority_source_audit()
%CHECK_PITCH_CONTROL_AUTHORITY_SOURCE_AUDIT Verify pitch authority audit.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir, 'analysis'));
addpath(fullfile(rootDir, 'model'));
addpath(fullfile(rootDir, 'services'));

P0 = params_nominal();
config = struct('V', 20, 'betaMDeg', 0, 'gammaDeg', 0, ...
    'trimMode', 'longitudinal_symmetric');
before = run_trim_case(config, P0);

outputDir = fullfile(tempdir, ['pitch_control_authority_source_test_' ...
    datestr(now, 'yyyymmddTHHMMSSFFF')]);
audit = audit_pitch_control_authority_source(struct( ...
    'outputDir', outputDir, 'runHeavy', false));

P1 = params_nominal();
after = run_trim_case(config, P1);

cases = {};
passed = [];
messages = {};

add_case('audit function completes', isstruct(audit), '');
add_case('contains four representative cases', ...
    audit.caseCount >= 4 && has_values({audit.effectiveness.case_name}, ...
    {'helicopter_low_speed','conversion_mid','airplane_like', ...
    'conversion_high'}), '');
add_case('contains source inventory', ...
    numel(audit.sourceInventory) >= 10 && ...
    any(strcmp({audit.sourceInventory.source_status}, 'SOURCE_REQUIRED')), '');
add_case('contains control effectiveness', ...
    numel(audit.effectiveness) >= 20 && ...
    has_values({audit.effectiveness.control}, ...
    {'collective','cyclicLong','elevator'}), '');
add_case('contains authority allocation', ...
    numel(audit.allocation) >= 20 && ...
    has_values({audit.allocation.diagnosis}, ...
    {'NOT_SOLVABLE_BY_LOCAL_CONTROL_SET'}), '');
add_case('contains sign mapping sensitivity', ...
    numel(audit.signMapping) >= 12 && ...
    has_values({audit.signMapping.candidate}, ...
    {'current_cyclicLong','inverted_cyclicLong_sign', ...
    'zero_cyclic_plus_elevator'}), '');
add_case('params_nominal cyclic limit unchanged', ...
    isequal(P0.control.cyclicLim, P1.control.cyclicLim), '');
add_case('params_nominal lateralCyclic default unchanged', ...
    ~P0.control.enableLateralCyclic && ...
    isequal(P0.control.enableLateralCyclic, ...
    P1.control.enableLateralCyclic), '');
add_case('run_trim_case behavior unchanged', ...
    before.success == after.success && ...
    norm(before.xTrim-after.xTrim) < 1.0e-10 && ...
    norm(before.uTrim-after.uTrim) < 1.0e-10, '');
add_case('cyclicLong source is not invented', ...
    source_status_for(audit.sourceInventory, ...
    'cyclicLong limit +/-35 deg', 'SOURCE_REQUIRED'), '');
add_case('report avoids forbidden validation claims', ...
    avoids_forbidden_claims(audit.reportFile) && ...
    avoids_forbidden_claims(fullfile(rootDir, 'docs', ...
    'PITCH_CONTROL_AUTHORITY_SOURCE_AUDIT.md')), '');
add_case('output files are text artifacts', ...
    output_files_are_text(audit), '');
add_case('lightweight mode completes with no run errors', ...
    audit.pr46.runErrorCount == 0 && audit.summary.pr46_record_count == 76, '');

report.names = cases;
report.passed = passed;
report.messages = messages;
report.summary = audit;
report.allPassed = all(passed);

fprintf('\nPitch control authority/source audit checks\n');
fprintf('===========================================\n');
for k = 1:numel(cases)
    fprintf('%-48s : %s\n', cases{k}, ternary(passed(k), 'PASS', 'FAIL'));
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

function ok = source_status_for(rows, item, status)
idx = strcmp({rows.item}, item);
ok = any(idx) && any(strcmp({rows(idx).source_status}, status));
end

function ok = output_files_are_text(audit)
files = {audit.reportFile, audit.sourceInventoryCsvFile, ...
    audit.effectivenessCsvFile, audit.allocationCsvFile, ...
    audit.signMappingCsvFile, audit.summaryJsonFile};
ok = true;
for i = 1:numel(files)
    [~, ~, ext] = fileparts(files{i});
    ok = ok && exist(files{i}, 'file') == 2 && ...
        any(strcmpi(ext, {'.md','.csv','.json'}));
end
end

function ok = avoids_forbidden_claims(reportFile)
text = fileread(reportFile);
forbidden = {'validation completed','validated against XV-15', ...
    'NUAA validated','Berger validated','XV-15 validated', ...
    'trend comparison passed','handling qualities validated', ...
    'elevator fix is proven','cyclicLong sign is wrong'};
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
