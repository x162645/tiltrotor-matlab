function report = check_gui_control_architecture_selector()
%CHECK_GUI_CONTROL_ARCHITECTURE_SELECTOR Verify GUI 7/8 input service wiring.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir,'model'));
addpath(fullfile(rootDir,'services'));

P = params_nominal();
names = {};
passed = [];
messages = {};

run_case('default architecture is seven inputs', @check_default_seven);
run_case('write switch enables eight inputs', @check_enable_eight);
run_case('switching back removes lateralCyclic', @check_disable_eight);
run_case('parameter catalog follows control count', @check_catalog_du_rows);

report.names = names;
report.passed = passed;
report.messages = messages;
report.allPassed = all(passed);

fprintf('\nGUI control architecture selector checks\n');
fprintf('========================================\n');
for k = 1:numel(names)
    fprintf('%-40s : %s\n', names{k}, ternary(passed(k),'PASS','FAIL'));
    if ~passed(k)
        fprintf('  %s\n', messages{k});
    end
end
fprintf('All passed: %d\n', report.allPassed);

    function run_case(name, fun)
        names{end+1,1} = name;
        try
            fun();
            passed(end+1,1) = true;
            messages{end+1,1} = '';
        catch ME
            passed(end+1,1) = false;
            messages{end+1,1} = sprintf('%s: %s', ME.identifier, ME.message);
        end
    end

    function check_default_seven()
        controls = get_control_input_names(P);
        assert(numel(controls) == 7);
        assert(~any(strcmp(controls, 'lateralCyclic')));
    end

    function check_enable_eight()
        P8 = write_parameter_value(P, 'control.enableLateralCyclic', 1);
        controls = get_control_input_names(P8);
        assert(numel(controls) == 8);
        assert(strcmp(controls{5}, 'lateralCyclic'));
        assert(numel(P8.linear.du) == 8);
    end

    function check_disable_eight()
        P8 = write_parameter_value(P, 'control.enableLateralCyclic', 1);
        P7 = write_parameter_value(P8, 'control.enableLateralCyclic', 0);
        controls = get_control_input_names(P7);
        assert(numel(controls) == 7);
        assert(~any(strcmp(controls, 'lateralCyclic')));
        assert(numel(P7.linear.du) == 7);
    end

    function check_catalog_du_rows()
        rows7 = build_parameter_catalog(P);
        P8 = write_parameter_value(P, 'control.enableLateralCyclic', 1);
        rows8 = build_parameter_catalog(P8);
        keys7 = {rows7.key};
        keys8 = {rows8.key};
        assert(any(strcmp(keys7, 'linear.du(7)')));
        assert(~any(strcmp(keys7, 'linear.du(8)')));
        assert(any(strcmp(keys8, 'linear.du(8)')));
    end
end

function value = ternary(condition,a,b)
if condition
    value = a;
else
    value = b;
end
end
