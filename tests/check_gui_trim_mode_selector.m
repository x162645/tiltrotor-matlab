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
run_case('lateral-directional mode is enabled', @check_lateral_enabled);
run_case('full 6-DOF mode is enabled', @check_full_enabled);
run_case('run_trim_case returns real solver reports', @check_run_trim_solver);

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

    function check_lateral_enabled()
        def = build_trim_mode_definition('lateral_directional_balance', P);
        assert(def.enabled);
        assert(~def.guarded);
        assert(strcmp(def.solver, 'trim_lateral_directional_balance'));
        assert(any(strcmp(def.residualNames, 'vdot')));
        assert(any(strcmp(def.unknownNames, 'diffCyclic')));
    end

    function check_full_enabled()
        def = build_trim_mode_definition('full_6dof_straight_trim', P);
        assert(def.enabled);
        assert(~def.guarded);
        assert(strcmp(def.solver, 'trim_full_6dof_straight'));
        assert(numel(def.residualNames) == 6);
    end

    function check_run_trim_solver()
        config = struct('V',0,'betaMDeg',0,'gammaDeg',0, ...
            'initialThetaDeg',0,'initialCollectiveDeg',18, ...
            'initialCyclicLongDeg',0,'thetaLimitDeg',35, ...
            'trimMode','full_6dof_straight_trim', ...
            'useMultiStart',false,'alwaysMultiStart',false);
        result = run_trim_case(config, P);
        assert(~isfield(result, 'guarded') || ~result.guarded);
        assert(strcmp(result.kind, 'full-6dof-straight-trim'));
        assert(isfield(result, 'xTrim') && numel(result.xTrim) == 9);
        assert(numel(result.report.residualLabels) == 6);
        assert(result.report.finite);
    end
end

function value = ternary(condition,a,b)
if condition
    value = a;
else
    value = b;
end
end
