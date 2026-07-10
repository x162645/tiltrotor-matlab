function report = check_berger13_linear_derivative_report()
%CHECK_BERGER13_LINEAR_DERIVATIVE_REPORT Report workflow checks.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir, 'model'));
addpath(fullfile(rootDir, 'model', 'berger13'));
addpath(fullfile(rootDir, 'analysis', 'berger13'));

outputRoot = fullfile(tempdir, ['berger13_linear_derivative_report_' ...
    datestr(now, 'yyyymmddTHHMMSSFFF')]);

cases = {};
passed = [];
messages = {};
reportData = [];

run_case('report workflow runs', @check_workflow_runs);
run_case('report files exist', @check_files_exist);
run_case('four representative cases are present', @check_case_count);
run_case('all cases have finite 13x13 and 13x10 derivatives', ...
    @check_dimensions_and_finite);
run_case('symmetric cases match legacy opt-in first nine states', ...
    @check_symmetric_legacy_match);
run_case('asymmetric case records independent rotor-load deltas', ...
    @check_asymmetric_delta);
run_case('lateral cyclic and nacelle torque columns are active', ...
    @check_control_columns);
run_case('betaML and betaMR state columns are active', ...
    @check_beta_columns);
run_case('conditioning diagnostics are reported', ...
    @check_conditioning_fields);
run_case('nullspace diagnostics are reported', ...
    @check_nullspace_fields);
run_case('conditioning report text is explanatory', ...
    @check_conditioning_text);
run_case('report avoids external validation claims', ...
    @check_no_external_validation_claim);

report.names = cases;
report.passed = passed;
report.messages = messages;
report.allPassed = all(passed);
report.reportData = reportData;

fprintf('\nBerger13 linear derivative report checks\n');
fprintf('========================================\n');
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

    function data = get_report_data()
        if isempty(reportData)
            reportData = report_berger13_linear_derivatives(outputRoot);
        end
        data = reportData;
    end

    function check_workflow_runs()
        data = get_report_data();
        assert(isstruct(data));
        assert(isfield(data, 'cases'));
        assert(isfolder(data.outputDir));
    end

    function check_files_exist()
        data = get_report_data();
        assert(isfile(fullfile(data.outputDir, ...
            'berger13_linear_derivatives_report.md')));
        assert(isfile(fullfile(data.outputDir, ...
            'berger13_linear_derivatives.csv')));
    end

    function check_case_count()
        data = get_report_data();
        assert(numel(data.cases) >= 4);
        names = {data.cases.caseName};
        assert(any(strcmp(names, 'helicopter_like')));
        assert(any(strcmp(names, 'conversion_mid')));
        assert(any(strcmp(names, 'airplane_like')));
        assert(any(strcmp(names, 'asymmetric_nacelle_probe')));
    end

    function check_dimensions_and_finite()
        data = get_report_data();
        for finiteIdx = 1:numel(data.cases)
            item = data.cases(finiteIdx);
            assert(item.finite);
            assert(isequal(item.ASize, [13 13]));
            assert(isequal(item.BSize, [13 10]));
            assert(isfinite(item.ANorm) && isfinite(item.BNorm));
        end
    end

    function check_symmetric_legacy_match()
        data = get_report_data();
        for symIdx = 1:numel(data.cases)
            item = data.cases(symIdx);
            if abs(item.betaML-item.betaMR) < 1e-12
                assert(item.first9DifferenceNorm < 1e-8);
            end
        end
    end

    function check_asymmetric_delta()
        data = get_report_data();
        idx = find(strcmp({data.cases.caseName}, ...
            'asymmetric_nacelle_probe'), 1);
        assert(~isempty(idx));
        item = data.cases(idx);
        assert(item.forceDeltaNorm > 1e-8);
        assert(item.momentDeltaNorm > 1e-8);
        assert(item.usedIndependentRotorAngles);
        assert(item.usedAverageNonRotorAero);
    end

    function check_control_columns()
        data = get_report_data();
        for controlIdx = 1:numel(data.cases)
            item = data.cases(controlIdx);
            assert(item.controlColumnNorms(5) > 1e-8);
            assert(abs(item.B12_9) > 1e-8);
            assert(abs(item.B13_10) > 1e-8);
        end
    end

    function check_beta_columns()
        data = get_report_data();
        for betaIdx = 1:numel(data.cases)
            item = data.cases(betaIdx);
            assert(item.normAFirstNineBetaML > 1e-8);
            assert(item.normAFirstNineBetaMR > 1e-8);
        end
    end

    function check_conditioning_fields()
        data = get_report_data();
        for conditioningIdx = 1:numel(data.cases)
            item = data.cases(conditioningIdx);
            assert(isfield(item, 'rawCondA'));
            assert(isfield(item, 'scaledCondA'));
            assert(isfield(item, 'dynamicCondA'));
            assert(isfield(item, 'scaledDynamicCondA'));
            assert(isfield(item, 'rawRankA'));
            assert(isfield(item, 'scaledRankA'));
            assert(isfield(item, 'dynamicRankA'));
            assert(isfield(item, 'rankB'));
            assert(isfinite(item.rawRankA));
            assert(isfinite(item.scaledRankA));
            assert(isfinite(item.dynamicRankA));
            assert(isfinite(item.rankB));
            assert(isfinite(item.rawCondA) || isinf(item.rawCondA));
            assert(isfinite(item.scaledCondA) || isinf(item.scaledCondA));
            assert(isfinite(item.dynamicCondA) || isinf(item.dynamicCondA));
            assert(isfinite(item.scaledDynamicCondA) || ...
                isinf(item.scaledDynamicCondA));
            assert(any(strcmp(item.zeroColumnNamesA, 'psi')));
            assert(~isempty(item.conditioningInterpretation));
        end
    end

    function check_nullspace_fields()
        data = get_report_data();
        for nullIdx = 1:numel(data.cases)
            item = data.cases(nullIdx);
            assert(isfield(item, 'A_nullity'));
            assert(isfield(item, 'A_effectiveCond'));
            assert(isfield(item, 'scaledA_effectiveCond'));
            assert(isfield(item, 'reducedA_nullity'));
            assert(isfield(item, 'reducedA_effectiveCond'));
            assert(isfield(item, 'B_rank'));
            assert(isfield(item, 'B_nullity'));
            assert(isfield(item, 'B_effectiveCond'));
            assert(isfield(item, 'B_dominantNullControls'));
            assert(isfinite(item.A_nullity));
            assert(isfinite(item.reducedA_nullity));
            assert(isfinite(item.B_nullity));
            assert(item.A_nullity >= 1);
            assert(item.B_nullity == 10-item.B_rank);
            assert(isfinite(item.A_effectiveCond) || ...
                isinf(item.A_effectiveCond));
            assert(isfinite(item.scaledA_effectiveCond) || ...
                isinf(item.scaledA_effectiveCond));
            assert(isfinite(item.reducedA_effectiveCond) || ...
                isinf(item.reducedA_effectiveCond));
            assert(isfinite(item.B_effectiveCond) || ...
                isinf(item.B_effectiveCond));
            assert(~isempty(item.B_dominantNullControls));
            assert(~isempty(item.nullspaceInterpretation));
        end
    end

    function check_conditioning_text()
        data = get_report_data();
        text = lower(fileread(fullfile(data.outputDir, ...
            'berger13_linear_derivatives_report.md')));
        assert(contains(text, 'conditioning diagnostics'));
        assert(contains(text, 'nullspace'));
        assert(contains(text, 'effective condition'));
        assert(contains(text, 'scaled'));
        assert(contains(text, 'svd'));
        assert(contains(text, 'rank'));
        assert(contains(text, 'not validation'));
        assert(contains(text, 'zero a columns: psi'));
        assert(contains(text, 'dominant b null controls'));
    end

    function check_no_external_validation_claim()
        data = get_report_data();
        text = lower(fileread(fullfile(data.outputDir, ...
            'berger13_linear_derivatives_report.md')));
        forbidden = { ...
            'berger/xv-15 validation completed', ...
            'xv-15 validation completed', ...
            'handling-quality validation completed', ...
            'flight-test validation completed'};
        for forbiddenIdx = 1:numel(forbidden)
            assert(~contains(text, forbidden{forbiddenIdx}));
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
