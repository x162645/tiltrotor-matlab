function report = check_nacelle_dynamics_gui_service()
%CHECK_NACELLE_DYNAMICS_GUI_SERVICE Experimental GUI service checks.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir, 'model'));
addpath(fullfile(rootDir, 'services'));

P = params_nominal();
cases = {};
passed = [];
messages = {};

run_case('default service remains legacy 9-state', @check_default_disabled);
run_case('enabled service returns bounded 11-state response', @check_enabled);
run_case('GUI file contains experimental opt-in text', @check_gui_text);

report.names = cases;
report.passed = passed;
report.messages = messages;
report.allPassed = all(passed);

fprintf('\nNacelle dynamics GUI service checks\n');
fprintf('===================================\n');
for k = 1:numel(cases)
    fprintf('%-50s : %s\n', cases{k}, ternary(passed(k), 'PASS', 'FAIL'));
    if ~passed(k)
        fprintf('  %s\n', messages{k});
    end
end
fprintf('All nacelle dynamics GUI service checks passed: %d\n', report.allPassed);

    function run_case(name, fun)
        cases{end+1,1} = name;
        try
            fun();
            passed(end+1,1) = true;
            messages{end+1,1} = '';
        catch ME
            passed(end+1,1) = false;
            messages{end+1,1} = sprintf('%s: %s', ME.identifier, ME.message);
        end
    end

    function check_default_disabled()
        result = run_nacelle_dynamics_response_case(struct(), P);
        assert(~result.enabled);
        assert(result.stateDimension == 9);
        assert(numel(result.stateNames) == 9);
        assert(isreal(result.state) && all(isfinite(result.state(:))));
        assert(max(abs(result.betaMDeg-result.betaMDeg(1))) < 1e-12);
        assert(max(abs(result.betaMDotDegPerSec)) < 1e-12);
    end

    function check_enabled()
        config = struct('enableNacelleDynamics', true, ...
            'initialBetaDeg', 15, 'commandBetaDeg', 75, ...
            'duration', 2, 'timeStep', 0.05);
        result = run_nacelle_dynamics_response_case(config, P);
        assert(result.enabled);
        assert(result.stateDimension == 11);
        assert(numel(result.stateNames) == 11);
        assert(isreal(result.state) && all(isfinite(result.state(:))));
        assert(result.betaMDeg(end) > result.betaMDeg(1));
        assert(max(abs(result.betaMDotDegPerSec)) <= 8 + 1e-8);
        assert(result.rateLimited);
    end

    function check_gui_text()
        appPath = fullfile(rootDir, 'app', 'launch_tiltrotor_app.m');
        text = fileread(appPath);
        requiredText = ['该功能为实验扩展，默认关闭。启用后模型状态由 9 个增加到 11 个，' ...
            '用于研究短舱角滞后和速率限制。'];
        assert(~isempty(strfind(text, '短舱动态（实验）')));
        assert(~isempty(strfind(text, requiredText)));
        forbidden = {'复现 Berger 51 状态', '真实转换飞行', ...
            '已验证真实 XV-15', '替代 legacy 模型'};
        for i = 1:numel(forbidden)
            assert(isempty(strfind(text, forbidden{i})), ...
                'Forbidden GUI claim found: %s', forbidden{i});
        end
    end

    function value = ternary(condition, a, b)
        if condition
            value = a;
        else
            value = b;
        end
    end
end
