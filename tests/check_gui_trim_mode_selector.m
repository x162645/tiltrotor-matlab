function report = check_gui_trim_mode_selector()
%CHECK_GUI_TRIM_MODE_SELECTOR Verify trim-mode selector service behavior.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir,'model'));
addpath(fullfile(rootDir,'analysis'));
addpath(fullfile(rootDir,'services'));

P = params_nominal();
names = {};
passed = [];
messages = {};

run_case('default mode definition is enabled', @check_default_definition);
run_case('lateral-directional mode is guarded', @check_lateral_guarded);
run_case('full 6-DOF mode is guarded', @check_full_guarded);
run_case('run_trim_case does not fake guarded success', @check_run_trim_guard);

report.names = names;
report.passed = passed;
report.messages = messages;
report.allPassed = all(passed);

fprintf('\nGUI trim mode selector checks\n');
fprintf('=============================\n');
for k = 1:numel(names)
    fprintf('%-42s : %s\n', names{k}, ternary(passed(k),'PASS','FAIL'));
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

    function check_default_definition()
        def = build_trim_mode_definition('longitudinal_symmetric', P);
        assert(def.enabled);
        assert(~def.guarded);
        assert(strcmp(def.solver, 'trim_symmetric'));
    end

    function check_lateral_guarded()
        def = build_trim_mode_definition('lateral_directional_balance', P);
        assert(~def.enabled);
        assert(def.guarded);
        assert(any(strcmp(def.residualNames, 'vdot')));
        assert(any(strcmp(def.unknownNames, 'lateralCyclic')));
    end

    function check_full_guarded()
        def = build_trim_mode_definition('full_6dof', P);
        assert(~def.enabled);
        assert(def.guarded);
        assert(numel(def.residualNames) == 6);
    end

    function check_run_trim_guard()
        config = struct('V',0,'betaMDeg',0,'gammaDeg',0, ...
            'trimMode','full_6dof','useMultiStart',false, ...
            'alwaysMultiStart',false);
        result = run_trim_case(config, P);
        assert(~result.success);
        assert(result.guarded);
        assert(~isfield(result, 'xTrim'), ...
            'Guarded mode must not return a fake trim point.');
    end
end

function value = ternary(condition,a,b)
if condition
    value = a;
else
    value = b;
end
end
