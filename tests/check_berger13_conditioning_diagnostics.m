function report = check_berger13_conditioning_diagnostics()
%CHECK_BERGER13_CONDITIONING_DIAGNOSTICS Conditioning helper checks.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir, 'model'));
addpath(fullfile(rootDir, 'model', 'berger13'));
addpath(fullfile(rootDir, 'analysis', 'berger13'));

cases = {};
passed = [];
messages = {};
diagData = [];
AOriginal = [];
BOriginal = [];

run_case('conditioning helper runs on representative A/B', ...
    @check_helper_runs);
run_case('raw scaled and dynamic rank diagnostics exist', ...
    @check_rank_fields);
run_case('psi zero column is detected', @check_psi_zero_column);
run_case('scaled diagnostics are finite or structural Inf', ...
    @check_scaled_diagnostics);
run_case('B rank and control column norms are finite', ...
    @check_b_diagnostics);
run_case('helper does not modify A/B inputs', @check_inputs_unchanged);
run_case('diagnostic text avoids validation claims', ...
    @check_no_validation_claim);

report.names = cases;
report.passed = passed;
report.messages = messages;
report.allPassed = all(passed);
report.diagnostics = diagData;

fprintf('\nBerger13 conditioning diagnostic checks\n');
fprintf('=======================================\n');
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

    function diag = get_diag()
        if isempty(diagData)
            P13 = params_berger13();
            d2r = pi/180;
            x13 = [45; 0; 0; 0; 0; 0; 0; 0; 0; ...
                45*d2r; 45*d2r; 0; 0];
            u10 = [8*d2r; 0; 0; 0; 1*d2r; 0; -2*d2r; 0; 0; 0];
            [AOriginal, BOriginal] = linearize_13x10_numeric(x13, u10, P13);
            ABefore = AOriginal;
            BBefore = BOriginal;
            diagData = diagnose_berger13_conditioning(AOriginal, BOriginal, ...
                get_state_names_13x10(), get_control_input_names_13x10());
            assert(isequaln(AOriginal, ABefore));
            assert(isequaln(BOriginal, BBefore));
        end
        diag = diagData;
    end

    function check_helper_runs()
        diag = get_diag();
        assert(isstruct(diag));
        assert(isfield(diag, 'raw'));
        assert(isfield(diag, 'scaled'));
        assert(isfield(diag, 'dynamic'));
        assert(isfield(diag, 'B'));
    end

    function check_rank_fields()
        diag = get_diag();
        assert(isfinite(diag.raw.rankA));
        assert(isfinite(diag.scaled.rankScaledA));
        assert(isfinite(diag.dynamic.rankADynamic));
        assert(isfinite(diag.dynamic.rankScaledADynamic));
        assert(diag.raw.rankA <= 13);
        assert(diag.scaled.rankScaledA <= 13);
    end

    function check_psi_zero_column()
        diag = get_diag();
        assert(any(strcmp(diag.raw.zeroColumnNamesA, 'psi')));
        assert(any(diag.raw.zeroColumnIndicesA == 9));
    end

    function check_scaled_diagnostics()
        diag = get_diag();
        assert(all(isfinite(diag.scaled.stateScale)));
        assert(all(diag.scaled.stateScale > 0));
        assert(all(isfinite(diag.raw.singularValuesA)));
        assert(all(isfinite(diag.scaled.singularValuesScaledA)));
        assert(isfinite(diag.scaled.maxSingularScaledA));
        assert(isfinite(diag.dynamic.condADynamic) || ...
            isinf(diag.dynamic.condADynamic));
        assert(isfinite(diag.dynamic.condScaledADynamic) || ...
            isinf(diag.dynamic.condScaledADynamic));
    end

    function check_b_diagnostics()
        diag = get_diag();
        assert(isfinite(diag.B.rankB));
        assert(numel(diag.B.controlColumnNorms) == 10);
        assert(all(isfinite(diag.B.controlColumnNorms)));
        assert(numel(diag.B.activeControlColumns) >= 8);
    end

    function check_inputs_unchanged()
        get_diag();
        assert(isequaln(AOriginal, AOriginal));
        assert(isequaln(BOriginal, BOriginal));
    end

    function check_no_validation_claim()
        diag = get_diag();
        text = lower([diag.interpretation, ' ', strjoin(diag.notes(:).', ' ')]);
        forbidden = { ...
            'validation completed', ...
            'xv-15 validation completed', ...
            'handling-quality validation completed', ...
            'flight-test validation completed'};
        for forbiddenIdx = 1:numel(forbidden)
            assert(~contains(text, forbidden{forbiddenIdx}));
        end
        assert(contains(text, 'not validation'));
    end

    function value = ternary(condition, a, b)
        if condition
            value = a;
        else
            value = b;
        end
    end
end
