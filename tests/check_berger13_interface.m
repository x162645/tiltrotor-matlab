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
end
