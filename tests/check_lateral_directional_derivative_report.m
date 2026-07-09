function report = check_lateral_directional_derivative_report()
%CHECK_LATERAL_DIRECTIONAL_DERIVATIVE_REPORT Focused derivative report test.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir, 'model'));
addpath(fullfile(rootDir, 'analysis'));
addpath(fullfile(rootDir, 'tests'));

cases = {};
passed = [];
messages = {};
tmpRoot = fullfile(tempdir, 'tiltrotor_lateral_directional_report_test');
opts = struct('outputRoot', tmpRoot, 'timestamp', 'latest');

run_case('report workflow runs', @check_report_runs);
run_case('at least one condition succeeds', @check_success_count);
run_case('enabled B matrix has 8 columns', @check_b_dimension);
run_case('lateralCyclic B column is nonzero', @check_lateral_column);
run_case('lateralCyclic raw target derivative exists', @check_lateral_raw);
run_case('report and CSV files exist', @check_outputs_exist);
run_case('no silent skipped conditions', @check_skipped_reasons);

report.names = cases;
report.passed = passed;
report.messages = messages;
report.allPassed = all(passed);

fprintf('\nLateral/directional derivative report checks\n');
fprintf('============================================\n');
for k = 1:numel(cases)
    fprintf('%-44s : %s\n', cases{k}, ternary(passed(k),'PASS','FAIL'));
    if ~passed(k)
        fprintf('  %s\n', messages{k});
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

    function summary = get_summary()
        persistent cachedSummary
        if isempty(cachedSummary)
            cachedSummary = report_lateral_directional_derivatives(opts);
        end
        summary = cachedSummary;
    end

    function check_report_runs()
        summary = get_summary();
        assert(isstruct(summary));
        assert(isfield(summary, 'caseResults'));
    end

    function check_success_count()
        summary = get_summary();
        assert(summary.successCount >= 1, ...
            'No representative condition succeeded.');
    end

    function check_b_dimension()
        summary = get_summary();
        ok = false;
        for i = 1:numel(summary.caseResults)
            c = summary.caseResults(i);
            if strcmp(c.status, 'OK')
                ok = ok || isequal(c.BSize, [9 8]);
            end
        end
        assert(ok, 'No successful condition produced a 9-by-8 B matrix.');
    end

    function check_lateral_column()
        summary = get_summary();
        norms = [summary.caseResults.lateralCyclicFullColumnNorm];
        assert(any(isfinite(norms) & norms > 1e-8), ...
            'lateralCyclic full B column is zero or non-finite.');
    end

    function check_lateral_raw()
        summary = get_summary();
        T = summary.table;
        rows = strcmp(T.control, 'lateralCyclic') & ...
            isfinite(T.raw_dMx) & isfinite(T.raw_dFy) & isfinite(T.B_pdot);
        target = max(abs([T.raw_dMx(rows), T.raw_dFy(rows), T.B_pdot(rows)]), [], 2);
        assert(any(target > 1e-12), ...
            'lateralCyclic has no detectable raw Mx/Fy or pdot effect.');
    end

    function check_outputs_exist()
        summary = get_summary();
        assert(exist(summary.reportFile, 'file') == 2, ...
            'Markdown report was not written.');
        assert(exist(summary.csvFile, 'file') == 2, ...
            'CSV report was not written.');
    end

    function check_skipped_reasons()
        summary = get_summary();
        for i = 1:numel(summary.caseResults)
            c = summary.caseResults(i);
            if ~strcmp(c.status, 'OK')
                assert(~isempty(c.reason), ...
                    'Skipped condition lacks a reason.');
            end
        end
        assert(all(isfinite(summary.table.B_column_norm) | ...
            strcmp(summary.table.status, 'SKIPPED_TRIM_FAILED')), ...
            'Successful rows contain non-finite B column norms.');
    end

    function value = ternary(condition, a, b)
        if condition
            value = a;
        else
            value = b;
        end
    end
end
