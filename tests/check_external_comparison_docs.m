function report = check_external_comparison_docs()
%CHECK_EXTERNAL_COMPARISON_DOCS Lightweight checks for external audit docs.

rootDir = fileparts(fileparts(mfilename('fullpath')));
fieldMapPath = fullfile(rootDir, 'docs', ...
    'EXTERNAL_COMPARISON_FIELD_MAP.md');
auditPlanPath = fullfile(rootDir, 'docs', 'EXTERNAL_AUDIT_PLAN.md');

cases = {};
passed = [];
messages = {};

run_case('external comparison field map exists', ...
    @check_field_map_exists);
run_case('external audit plan exists', @check_audit_plan_exists);
run_case('required classification terms are present', ...
    @check_required_terms);
run_case('documents avoid validation-completed claims', ...
    @check_forbidden_claims);

report.names = cases;
report.passed = passed;
report.messages = messages;
report.allPassed = all(passed);

fprintf('\nExternal comparison document checks\n');
fprintf('===================================\n');
for displayIdx = 1:numel(cases)
    fprintf('%-58s : %s\n', cases{displayIdx}, ...
        ternary(passed(displayIdx), 'PASS', 'FAIL'));
    if ~passed(displayIdx)
        fprintf('  %s\n', messages{displayIdx});
    end
end
fprintf('All passed: %d\n', report.allPassed);

    function run_case(name, fun)
        cases{end+1,1} = name;
        try
            fun();
            passed(end+1,1) = true;
            messages{end+1,1} = '';
        catch ME
            passed(end+1,1) = false;
            messages{end+1,1} = ME.message;
        end
    end

    function check_field_map_exists()
        assert(isfile(fieldMapPath), ...
            'docs/EXTERNAL_COMPARISON_FIELD_MAP.md is missing.');
    end

    function check_audit_plan_exists()
        assert(isfile(auditPlanPath), ...
            'docs/EXTERNAL_AUDIT_PLAN.md is missing.');
    end

    function check_required_terms()
        text = lower([fileread(fieldMapPath), newline, ...
            fileread(auditPlanPath)]);
        required = { ...
            'direct_comparable', ...
            'trend_comparable', ...
            'partial_comparable', ...
            'not_comparable_current_model', ...
            'out_of_scope_current_phase', ...
            'source_required', ...
            'nuaa', ...
            'berger', ...
            'not validation', ...
            'not handling-quality validation'};
        for requiredIdx = 1:numel(required)
            assert(contains(text, required{requiredIdx}), ...
                'Missing required term: %s', required{requiredIdx});
        end
    end

    function check_forbidden_claims()
        text = lower([fileread(fieldMapPath), newline, ...
            fileread(auditPlanPath)]);
        forbidden = { ...
            'validation completed', ...
            'handling-quality validation completed', ...
            'berger 51-state reproduced', ...
            'xv-15 validation completed'};
        for forbiddenIdx = 1:numel(forbidden)
            assert(~contains(text, forbidden{forbiddenIdx}), ...
                'Forbidden claim found: %s', forbidden{forbiddenIdx});
        end
    end

    function value = ternary(condition, a, b)
        if condition
            value = a;
        else
            value = b;
        end
    end
end
