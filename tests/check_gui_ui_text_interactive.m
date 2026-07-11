function report = check_gui_ui_text_interactive()
%CHECK_GUI_UI_TEXT_INTERACTIVE Static GUI wording checks.
% This avoids opening a uifigure in headless validation environments.

rootDir = fileparts(fileparts(mfilename('fullpath')));
appPath = fullfile(rootDir, 'app', 'launch_tiltrotor_app.m');
text = fileread(appPath);

names = {};
passed = [];
messages = {};

run_case('parameter tab is no longer key-only', @check_parameter_title);
run_case('nacelle tab wording is professional', @check_nacelle_wording);
run_case('control architecture selector text exists', @check_control_selector);
run_case('trim mode selector text exists', @check_trim_modes);
run_case('response wording uses actual-plus-trim wording', @check_response_wording);

report.names = names;
report.passed = passed;
report.messages = messages;
report.allPassed = all(passed);

fprintf('\nGUI UI wording checks\n');
fprintf('=====================\n');
for k = 1:numel(names)
    fprintf('%-44s : %s\n', names{k}, ternary(passed(k),'PASS','FAIL'));
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

    function check_parameter_title()
        assert(contains(text, 'Title'',''参数设置'));
        assert(~contains(text, 'Title'',''关键参数'));
    end

    function check_nacelle_wording()
        assert(contains(text, 'Title'',''短舱动态'));
        forbidden = {'短舱动态（实验）','实验设置','短舱动态实验'};
        for i = 1:numel(forbidden)
            assert(~contains(text, forbidden{i}), ...
                'Forbidden wording remains: %s', forbidden{i});
        end
        assert(contains(text, '默认关闭以保持 legacy 9 状态路径'));
    end

    function check_control_selector()
        assert(contains(text, '默认 7 输入'));
        assert(contains(text, '启用 lateralCyclic 8 输入'));
    end

    function check_trim_modes()
        assert(contains(text, '纵向对称配平'));
        assert(contains(text, '横侧向平衡/导数检查'));
        assert(contains(text, '六自由度联合配平'));
    end

    function check_response_wording()
        assert(contains(text, '叠加配平值显示'));
        assert(~contains(text, '显示实际总量'));
    end
end

function value = ternary(condition,a,b)
if condition
    value = a;
else
    value = b;
end
end
