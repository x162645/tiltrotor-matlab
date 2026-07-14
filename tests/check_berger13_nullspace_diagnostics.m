function report = check_berger13_nullspace_diagnostics()
%CHECK_BERGER13_NULLSPACE_DIAGNOSTICS Nullspace helper checks.

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

run_case('nullspace helper runs on representative A/B', ...
    @check_helper_runs);
run_case('A nullity and effective condition are reported', ...
    @check_a_nullspace);
run_case('reduced-state nullspace diagnostics are reported', ...
    @check_reduced_nullspace);
run_case('B control nullspace diagnostics are reported', ...
    @check_b_nullspace);
run_case('dominant null coordinates are nonempty', ...
    @check_dominant_entries);
run_case('helper does not modify A/B inputs', @check_inputs_unchanged);
run_case('diagnostic text avoids validation claims', ...
    @check_no_validation_claim);

report.names = cases;
report.passed = passed;
report.messages = messages;
report.allPassed = all(passed);
report.diagnostics = diagData;

fprintf('\nBerger13 nullspace diagnostic checks\n');
fprintf('====================================\n');
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
            [AOriginal, BOriginal] = linearize_13x10_numeric( ...
                x13, u10, P13);
            ABefore = AOriginal;
            BBefore = BOriginal;
            conditioning = diagnose_berger13_conditioning( ...
                AOriginal, BOriginal, get_state_names_13x10(), ...
                get_control_input_names_13x10());
            diagData = diagnose_berger13_nullspace( ...
                AOriginal, BOriginal, get_state_names_13x10(), ...
                get_control_input_names_13x10(), conditioning);
            assert(isequaln(AOriginal, ABefore));
            assert(isequaln(BOriginal, BBefore));
        end
        diag = diagData;
    end

    function check_helper_runs()
        diag = get_diag();
        assert(isstruct(diag));
        assert(isfield(diag, 'nullityA'));
        assert(isfield(diag, 'effectiveCondA'));
        assert(isfield(diag, 'nullityB'));
        assert(isfield(diag, 'effectiveCondB'));
    end

    function check_a_nullspace()
        diag = get_diag();
        assert(diag.nullityA >= 1);
        assert(diag.nullityA == size(AOriginal, 2)-diag.rankA);
        assert(isfinite(diag.effectiveCondA) || isinf(diag.effectiveCondA));
        assert(all(isfinite(diag.singularValuesA)));
        assert(isfinite(diag.toleranceA));
        assert(~isempty(diag.nullVectorInterpretation));
    end

    function check_reduced_nullspace()
        diag = get_diag();
        assert(~isempty(diag.reducedStateNames));
        assert(~isempty(diag.reducedStateIndices));
        assert(diag.reducedNullityA >= 0);
        assert(isfinite(diag.reducedEffectiveCondA) || ...
            isinf(diag.reducedEffectiveCondA));
        assert(~isempty(diag.reducedInterpretation));
    end

    function check_b_nullspace()
        diag = get_diag();
        assert(diag.nullityB >= 1);
        assert(diag.nullityB == size(BOriginal, 2)-diag.rankB);
        assert(isfinite(diag.effectiveCondB) || isinf(diag.effectiveCondB));
        assert(all(isfinite(diag.singularValuesB)));
        assert(isfinite(diag.toleranceB));
        assert(~isempty(diag.controlNullVectorInterpretation));
    end

    function check_dominant_entries()
        diag = get_diag();
        assert(~isempty(diag.dominantStatesPerNullVector));
        assert(~isempty(diag.dominantControlsPerNullVector));
        assert(~isempty(diag.dominantStatesPerNullVector{1}));
        assert(~isempty(diag.dominantControlsPerNullVector{1}));
    end

    function check_inputs_unchanged()
        get_diag();
        ACopy = AOriginal;
        BCopy = BOriginal;
        diagnose_berger13_nullspace(AOriginal, BOriginal, ...
            get_state_names_13x10(), get_control_input_names_13x10());
        assert(isequaln(AOriginal, ACopy));
        assert(isequaln(BOriginal, BCopy));
    end

    function check_no_validation_claim()
        diag = get_diag();
        text = lower([diag.interpretation, ' ', strjoin(diag.notes(:).', ' ')]);
        forbidden = { ...
            'validation completed', ...
            'xv-15 validation completed', ...
            'handling-quality validation completed', ...
            'flight-test validation completed', ...
            'physical mode'};
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
