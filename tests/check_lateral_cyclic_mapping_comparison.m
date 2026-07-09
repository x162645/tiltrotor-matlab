function report = check_lateral_cyclic_mapping_comparison()
%CHECK_LATERAL_CYCLIC_MAPPING_COMPARISON Focused mapping-comparison test.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir, 'model'));
addpath(fullfile(rootDir, 'analysis'));
addpath(fullfile(rootDir, 'tests'));

cases = {};
passed = [];
messages = {};
tmpRoot = fullfile(tempdir, 'tiltrotor_lateral_cyclic_mapping_test');
opts = struct('outputRoot', tmpRoot, 'timestamp', 'latest');

run_case('comparison workflow runs', @check_workflow_runs);
run_case('all three mappings evaluated', @check_all_mappings);
run_case('hover and low-speed cases succeed', @check_required_cases);
run_case('current cancellation is identified', @check_current_cancellation);
run_case('candidate improvement is reported', @check_candidate_improvement);
run_case('report and CSV files exist', @check_outputs_exist);
run_case('finite successful rows', @check_finite_rows);

report.names = cases;
report.passed = passed;
report.messages = messages;
report.allPassed = all(passed);

fprintf('\nLateral cyclic mapping comparison checks\n');
fprintf('========================================\n');
for k = 1:numel(cases)
    fprintf('%-42s : %s\n', cases{k}, ternary(passed(k),'PASS','FAIL'));
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
            cachedSummary = compare_lateral_cyclic_mappings(opts);
        end
        summary = cachedSummary;
    end

    function check_workflow_runs()
        summary = get_summary();
        assert(isstruct(summary));
        assert(isfield(summary, 'recommendation'));
    end

    function check_all_mappings()
        summary = get_summary();
        mappings = unique(summary.table.mapping);
        assert(all(ismember({'current'; 'rotDir'; 'minusRotDir'}, mappings)));
    end

    function check_required_cases()
        summary = get_summary();
        T = summary.table;
        required = {'hover_like_beta0'; 'low_speed_helicopter'};
        for i = 1:numel(required)
            rows = strcmp(T.condition, required{i});
            assert(any(rows), 'Required condition was not evaluated.');
            assert(all(strcmp(T.status(rows), 'OK')), ...
                'Required condition has a failed mapping row.');
        end
    end

    function check_current_cancellation()
        summary = get_summary();
        T = summary.table;
        rows = strcmp(T.mapping, 'current');
        assert(any(strcmp(T.classification(rows), ...
            'CURRENT_CANCELLATION_CONFIRMED')) || ...
            any(strcmp(T.classification(rows), ...
            'LONGITUDINAL_LEAK_DOMINANT')), ...
            'Current mapping was not identified as cancellation/leakage.');
        assert(any(~T.nDiskY_same_sign(rows)), ...
            'Current mapping did not show left/right nDiskY cancellation.');
    end

    function check_candidate_improvement()
        summary = get_summary();
        T = summary.table;
        currentRows = strcmp(T.mapping, 'current');
        candidateRows = strcmp(T.mapping, 'rotDir') | ...
            strcmp(T.mapping, 'minusRotDir');
        bestCandidate = max(T.lateral_target_norm(candidateRows));
        bestCurrent = max(T.lateral_target_norm(currentRows));
        noBetter = strcmp(summary.recommendation.name, ...
            'no-better-candidate');
        assert(bestCandidate > bestCurrent || noBetter, ...
            'No candidate improvement or explicit no-better conclusion.');
    end

    function check_outputs_exist()
        summary = get_summary();
        assert(exist(summary.reportFile, 'file') == 2, ...
            'Markdown comparison report was not written.');
        assert(exist(summary.csvFile, 'file') == 2, ...
            'CSV comparison report was not written.');
    end

    function check_finite_rows()
        summary = get_summary();
        T = summary.table;
        rows = strcmp(T.status, 'OK');
        values = [T.B_vdot(rows), T.B_pdot(rows), T.B_rdot(rows), ...
            T.raw_dFy(rows), T.raw_dMx(rows), T.raw_dMz(rows), ...
            T.lateral_target_norm(rows), T.longitudinal_leak_norm(rows)];
        assert(all(isfinite(values(:))), ...
            'Successful comparison rows contain non-finite values.');
    end

    function value = ternary(condition, a, b)
        if condition
            value = a;
        else
            value = b;
        end
    end
end
