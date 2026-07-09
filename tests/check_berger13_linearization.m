function report = check_berger13_linearization()
%CHECK_BERGER13_LINEARIZATION Linearization checks for 13x10 scaffold.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir, 'model'));
addpath(fullfile(rootDir, 'model', 'berger13'));
addpath(fullfile(rootDir, 'analysis', 'berger13'));

d2r = pi/180;
P13 = params_berger13();
x13 = [40; 0; 0; 0; 0; 0; 0; 0; 0; 90*d2r; 90*d2r; 0; 0];
u10 = [8*d2r; 0; 0; 0; 1*d2r; 0; -2*d2r; 0; 0; 0];

cases = {};
passed = [];
messages = {};

run_case('linearization dimensions and finite values', @check_dimensions);
run_case('nacelle torque columns affect nacelle accelerations', @check_torque_columns);
run_case('lateralCyclic column is nonzero', @check_lateral_column);
run_case('symmetric first nine states match legacy opt-in EOM', @check_legacy_match);

report.names = cases;
report.passed = passed;
report.messages = messages;
report.allPassed = all(passed);

fprintf('\nBerger13 linearization checks\n');
fprintf('=============================\n');
for k = 1:numel(cases)
    fprintf('%-52s : %s\n', cases{k}, ternary(passed(k), 'PASS', 'FAIL'));
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

    function [A, B, lin] = get_linearization()
        persistent Ac Bc linc
        if isempty(Ac)
            [Ac, Bc, linc] = linearize_13x10_numeric(x13, u10, P13);
        end
        A = Ac;
        B = Bc;
        lin = linc;
    end

    function check_dimensions()
        [A, B, lin] = get_linearization();
        assert(isequal(size(A), [13 13]));
        assert(isequal(size(B), [13 10]));
        assert(lin.finite);
        assert(all(isfinite(A(:))) && all(isfinite(B(:))));
    end

    function check_torque_columns()
        [~, B, ~] = get_linearization();
        assert(abs(B(12,9)) > 1e-8);
        assert(abs(B(13,10)) > 1e-8);
    end

    function check_lateral_column()
        [~, B, ~] = get_linearization();
        assert(norm(B(:,5)) > 1e-8);
    end

    function check_legacy_match()
        Pbase = P13.base;
        betaM = x13(10);
        legacy = tiltrotor_eom(x13(1:9), u10(1:8), betaM, Pbase);
        research = tiltrotor_eom_13x10(x13, u10, P13);
        assert(norm(research(1:9)-legacy) < 1e-9);
    end

    function value = ternary(condition, a, b)
        if condition
            value = a;
        else
            value = b;
        end
    end
end
