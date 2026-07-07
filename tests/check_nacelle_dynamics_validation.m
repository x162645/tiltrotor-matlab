function report = check_nacelle_dynamics_validation()
%CHECK_NACELLE_DYNAMICS_VALIDATION Lightweight validation workflow checks.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir, 'model'));
addpath(fullfile(rootDir, 'analysis'));
addpath(fullfile(rootDir, 'services'));

config = struct();
config.quick = true;
config.writeFiles = false;
config.makePlots = false;
config.actuatorDuration = 8.0;
config.responseDuration = 3.0;
result = run_nacelle_dynamics_validation(config);

cases = {};
passed = [];
messages = {};

add_case('validation workflow reports all passed', ...
    result.allPassed, '');
add_case('legacy default remains 9-state', ...
    all([result.legacy.pass]) && result.legacy(1).stateDimension == 9, '');
add_case('actuator cases remain bounded and finite', ...
    all([result.actuator.rows.pass]), '');
add_case('quasi-static equivalence is strict for first 9 states', ...
    all([result.quasiStaticEquivalence.pass]), '');
add_case('enabled linearization is 11x11 and 11x7', ...
    all([result.linearization.pass]), '');
add_case('dynamic response demo is finite real', ...
    result.dynamicResponse.pass, '');

report.names = cases;
report.passed = passed;
report.messages = messages;
report.validation = result;
report.allPassed = all(passed);

fprintf('\nNacelle dynamics validation checks\n');
fprintf('==================================\n');
for k = 1:numel(cases)
    fprintf('%-52s : %s\n', cases{k}, ternary(passed(k), 'PASS', 'FAIL'));
    if ~passed(k)
        fprintf('  %s\n', messages{k});
    end
end
fprintf('All nacelle dynamics validation checks passed: %d\n', report.allPassed);

    function add_case(name, condition, message)
        cases{end+1,1} = name;
        passed(end+1,1) = logical(condition);
        messages{end+1,1} = message;
    end

    function value = ternary(condition, a, b)
        if condition
            value = a;
        else
            value = b;
        end
    end
end
