function report = check_nacelle_dynamics_state_extension()
%CHECK_NACELLE_DYNAMICS_STATE_EXTENSION Phase 1 opt-in nacelle-state checks.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir, 'model'));
addpath(fullfile(rootDir, 'analysis'));
addpath(fullfile(rootDir, 'services'));

P = params_nominal();
d2r = pi/180;
cases = {};
passed = [];
messages = {};

add_case('default state dimension is legacy 9', @test_default_dimension);
add_case('disabled EOM equals legacy 9-state path', @test_disabled_invariance);
add_case('enabled EOM returns 11 finite states', @test_enabled_eom);
add_case('rate state is limited to 8 deg/s', @test_rate_limit);
add_case('command is clamped to [0,90] deg', @test_command_clamp);
add_case('angle limit prevents outward motion', @test_angle_guard);
add_case('enabled linearization accepts 11 states', @test_enabled_linearization);
add_case('enabled trim appends betaM and betaM_dot', @test_enabled_trim);

report.names = cases;
report.passed = passed;
report.messages = messages;
report.allPassed = all(passed);

fprintf('\nNacelle dynamic state extension checks\n');
fprintf('======================================\n');
for k = 1:numel(cases)
    fprintf('%-42s : %s\n', cases{k}, ternary(passed(k), 'PASS', 'FAIL'));
    if ~passed(k)
        fprintf('  %s\n', messages{k});
    end
end
fprintf('All nacelle dynamic state checks passed: %d\n', report.allPassed);

    function add_case(name, fun)
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

    function test_default_dimension()
        assert(~has_nacelle_dynamic_states(P));
        assert(get_state_dimension(P) == 9);
        assert(numel(get_state_names(P)) == 9);
    end

    function test_disabled_invariance()
        x9 = representative_state();
        u = representative_control();
        betaM = 35*d2r;
        fLegacy = tiltrotor_eom(x9, u, betaM, P);

        Pdisabled = P;
        Pdisabled.nacelleDynamics.enabled = false;
        fDisabled = tiltrotor_eom(x9, u, betaM, Pdisabled);

        assert(numel(fLegacy) == 9);
        assert(isequaln(fLegacy, fDisabled));
    end

    function test_enabled_eom()
        Pdyn = enabled_params();
        betaM = 35*d2r;
        x11 = [representative_state(); betaM; 0];
        u = representative_control();
        [f11, out] = tiltrotor_eom(x11, u, betaM, Pdyn);
        f9 = tiltrotor_eom(x11(1:9), u, betaM, P);

        assert(get_state_dimension(Pdyn) == 11);
        assert(numel(f11) == 11);
        assert(isreal(f11) && all(isfinite(f11)));
        assert(max(abs(f11(1:9)-f9)) < 1e-12);
        assert(abs(f11(10)) < 1e-12);
        assert(abs(f11(11)) < 1e-12);
        assert(abs(out.betaMEffective-betaM) < 1e-12);
    end

    function test_rate_limit()
        Pdyn = enabled_params();
        Pdyn.nacelleDynamics.commandDeg = 90;
        betaM = 20*d2r;
        x11 = [representative_state(); betaM; 20*d2r];
        f11 = tiltrotor_eom(x11, representative_control(), betaM, Pdyn);
        assert(abs(f11(10) - 8*d2r) < 1e-12);
        assert(f11(11) <= 1e-12);
    end

    function test_command_clamp()
        PdynHigh = enabled_params();
        PdynHigh.nacelleDynamics.commandDeg = 120;
        PdynAtLimit = enabled_params();
        PdynAtLimit.nacelleDynamics.commandDeg = 90;
        betaM = 80*d2r;
        x11 = [representative_state(); betaM; 0];
        fHigh = tiltrotor_eom(x11, representative_control(), betaM, PdynHigh);
        fAtLimit = tiltrotor_eom(x11, representative_control(), betaM, PdynAtLimit);

        PdynLow = enabled_params();
        PdynLow.nacelleDynamics.commandDeg = -20;
        PdynZero = enabled_params();
        PdynZero.nacelleDynamics.commandDeg = 0;
        fLow = tiltrotor_eom(x11, representative_control(), betaM, PdynLow);
        fZero = tiltrotor_eom(x11, representative_control(), betaM, PdynZero);

        assert(max(abs(fHigh-fAtLimit)) < 1e-12);
        assert(max(abs(fLow-fZero)) < 1e-12);
    end

    function test_angle_guard()
        Pdyn = enabled_params();
        Pdyn.nacelleDynamics.commandDeg = 90;
        x11 = [representative_state(); pi/2; 4*d2r];
        f11 = tiltrotor_eom(x11, representative_control(), pi/2, Pdyn);
        assert(abs(f11(10)) < 1e-12);
        assert(f11(11) <= 1e-12);
    end

    function test_enabled_linearization()
        Pdyn = enabled_params();
        betaM = pi/2;
        x11 = [40; 0; 0; 0; 0; 0; 0; 0; 0; betaM; 0];
        u = [8*d2r; 0; 0; 0; 0; -2*d2r; 0];
        [A, B, linReport] = linearize_numeric(x11, u, betaM, Pdyn);
        assert(isequal(size(A), [11,11]));
        assert(isequal(size(B), [11,7]));
        assert(linReport.finite);
    end

    function test_enabled_trim()
        Pdyn = enabled_params();
        opts = struct('useMultiStart', false, 'alwaysMultiStart', false, ...
            'initialDeg', [0, 18, 0]);
        [xTrim, ~, trimReport] = trim_symmetric(0, 0, Pdyn, opts);
        assert(numel(xTrim) == 11);
        assert(abs(xTrim(10)) < 1e-12);
        assert(abs(xTrim(11)) < 1e-12);
        assert(numel(trimReport.fullStateDerivative) == 11);
        assert(isreal(trimReport.fullStateDerivative) && ...
            all(isfinite(trimReport.fullStateDerivative)));
    end

    function Pdyn = enabled_params()
        Pdyn = P;
        Pdyn.nacelleDynamics.enabled = true;
    end

    function x = representative_state()
        x = [25; 0.5; -1.0; 0.02; -0.01; 0.03; 0.01; 0.04; -0.02];
    end

    function u = representative_control()
        u = [12*d2r; 0.5*d2r; 1.0*d2r; -0.25*d2r; ...
            0.5*d2r; -1.0*d2r; 0.25*d2r];
    end

    function value = ternary(condition, a, b)
        if condition
            value = a;
        else
            value = b;
        end
    end
end
