function report = check_gui_trim_modes_real_solver_wiring()
%CHECK_GUI_TRIM_MODES_REAL_SOLVER_WIRING Verify trim mode service dispatch.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir,'model'));
addpath(fullfile(rootDir,'analysis'));
addpath(fullfile(rootDir,'services'));

P = params_nominal();
names = {};
passed = [];
messages = {};

run_case('definitions are enabled real solvers', @check_definitions);
run_case('lateral mode dispatches real solver', @check_lateral_dispatch);
run_case('full mode dispatches real solver', @check_full_dispatch);
run_case('static GUI text no longer says guarded scaffold', @check_gui_text);

report.names = names;
report.passed = passed;
report.messages = messages;
report.allPassed = all(passed);

fprintf('\nGUI trim mode real solver wiring checks\n');
fprintf('=======================================\n');
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

    function check_definitions()
        lateral = build_trim_mode_definition('lateral_directional_balance', P);
        full = build_trim_mode_definition('full_6dof_straight_trim', P);
        assert(lateral.enabled && ~lateral.guarded);
        assert(full.enabled && ~full.guarded);
        assert(strcmp(lateral.solver, 'trim_lateral_directional_balance'));
        assert(strcmp(full.solver, 'trim_full_6dof_straight'));
    end

    function check_lateral_dispatch()
        result = run_trim_case(config_for('lateral_directional_balance'), P);
        assert(strcmp(result.kind, 'lateral-directional-trim'));
        assert(~isfield(result, 'guarded') || ~result.guarded);
        assert(result.report.finite);
        assert(isfield(result, 'baseTrim') && result.baseTrim.success);
    end

    function check_full_dispatch()
        result = run_trim_case(config_for('full_6dof_straight_trim'), P);
        assert(strcmp(result.kind, 'full-6dof-straight-trim'));
        assert(~isfield(result, 'guarded') || ~result.guarded);
        assert(result.report.finite);
        assert(isfield(result, 'baseTrimForInitialGuess'));
    end

    function check_gui_text()
        appText = fileread(fullfile(rootDir, 'app', 'launch_tiltrotor_app.m'));
        assert(~contains(appText, 'guarded scaffold'));
        assert(contains(appText, 'full_6dof_straight_trim'));
        assert(contains(appText, '真实求解服务') || ...
            contains(appText, '鐪熷疄姹傝В鏈嶅姟'));
    end
end

function config = config_for(mode)
config = struct('V',0,'betaMDeg',0,'gammaDeg',0, ...
    'initialThetaDeg',0,'initialCollectiveDeg',18, ...
    'initialCyclicLongDeg',0,'thetaLimitDeg',35, ...
    'useMultiStart',false,'alwaysMultiStart',false, ...
    'trimMode',mode);
end

function value = ternary(condition,a,b)
if condition
    value = a;
else
    value = b;
end
end
