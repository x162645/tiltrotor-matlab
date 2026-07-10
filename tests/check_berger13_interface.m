function report = check_berger13_interface()
%CHECK_BERGER13_INTERFACE Interface checks for 13x10 research scaffold.

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

run_case('state and control names', @check_names);
run_case('params include base and nacelle placeholders', @check_params);
run_case('EOM returns finite 13-vector', @check_eom);
run_case('symmetric first nine states match legacy opt-in EOM', ...
    @check_symmetric_legacy_match);
run_case('independent rotor angle activation', ...
    @check_independent_rotor_activation);
run_case('asymmetric rotor loads differ from average-only loads', ...
    @check_asymmetric_load_difference);
run_case('nacelle torque signs', @check_torque_signs);
run_case('nacelle angle guards finite', @check_guards);
run_case('legacy default unchanged', @check_legacy_default);

report.names = cases;
report.passed = passed;
report.messages = messages;
report.allPassed = all(passed);

fprintf('\nBerger13 interface checks\n');
fprintf('=========================\n');
for k = 1:numel(cases)
    fprintf('%-44s : %s\n', cases{k}, ternary(passed(k), 'PASS', 'FAIL'));
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

    function check_names()
        assert(numel(get_state_names_13x10()) == 13);
        controls = get_control_input_names_13x10();
        assert(numel(controls) == 10);
        assert(strcmp(controls{5}, 'lateralCyclic'));
        assert(strcmp(controls{9}, 'nacelleTorqueLeft'));
        assert(strcmp(controls{10}, 'nacelleTorqueRight'));
    end

    function check_params()
        assert(isfield(P13, 'base'));
        assert(isfield(P13, 'nacelle'));
        assert(P13.nacelle.I > 0 && P13.nacelle.D > 0);
        assert(P13.base.control.enableLateralCyclic == true);
    end

    function check_eom()
        xdot = tiltrotor_eom_13x10(x13, u10, P13);
        assert(isequal(size(xdot), [13 1]));
        assert(isreal(xdot) && all(isfinite(xdot)));
    end

    function check_symmetric_legacy_match()
        Pbase = P13.base;
        legacy = tiltrotor_eom(x13(1:9), u10(1:8), x13(10), Pbase);
        research = tiltrotor_eom_13x10(x13, u10, P13);
        assert(norm(research(1:9)-legacy) < 1e-9);
    end

    function check_independent_rotor_activation()
        xAsym = x13;
        xAsym(10) = 80*d2r;
        xAsym(11) = 90*d2r;
        [~, ~, info] = total_forces_moments_13x10(xAsym, u10, P13);
        assert(info.usedIndependentRotorAngles == true);
        assert(info.usedAverageNonRotorAero == true);
        assert(abs(info.rotorLeft.betaMUsed - xAsym(10)) < 1e-12);
        assert(abs(info.rotorRight.betaMUsed - xAsym(11)) < 1e-12);
        assert(~isempty(info.warnings));
        assert(any(cellfun(@warning_mentions_average_nonrotor, info.warnings)));
    end

    function check_asymmetric_load_difference()
        xAsym = x13;
        xAsym(10) = 80*d2r;
        xAsym(11) = 90*d2r;
        [Fbody, Mbody, info] = total_forces_moments_13x10(xAsym, u10, P13);
        assert(norm(Fbody - info.averageOnlyF) > 1e-8);
        assert(norm(Mbody - info.averageOnlyM) > 1e-8);
        assert(norm(info.rotorLeft.deltaFromAverage.F) > 1e-8 || ...
            norm(info.rotorRight.deltaFromAverage.F) > 1e-8);
    end

    function check_torque_signs()
        up = u10;
        um = u10;
        up(9) = 100;
        um(9) = -100;
        fp = tiltrotor_eom_13x10(x13, up, P13);
        fm = tiltrotor_eom_13x10(x13, um, P13);
        assert(fp(12) > fm(12));

        up = u10;
        um = u10;
        up(10) = 100;
        um(10) = -100;
        fp = tiltrotor_eom_13x10(x13, up, P13);
        fm = tiltrotor_eom_13x10(x13, um, P13);
        assert(fp(13) > fm(13));
    end

    function check_guards()
        xBad = x13;
        xBad(10) = -10*d2r;
        xBad(11) = 100*d2r;
        xBad(12) = -100*d2r;
        xBad(13) = 100*d2r;
        xdot = tiltrotor_eom_13x10(xBad, u10, P13);
        assert(isreal(xdot) && all(isfinite(xdot)));
    end

    function check_legacy_default()
        P = params_nominal();
        assert(P.control.enableLateralCyclic == false);
        assert(numel(get_control_input_names(P)) == 7);
    end

    function value = ternary(condition, a, b)
        if condition
            value = a;
        else
            value = b;
        end
    end

    function tf = warning_mentions_average_nonrotor(text)
        tf = contains(text, 'independent left/right rotor loads') && ...
            contains(text, 'non-rotor aero still uses betaMAvg');
    end
end
