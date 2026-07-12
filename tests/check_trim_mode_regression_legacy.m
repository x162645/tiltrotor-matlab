function report = check_trim_mode_regression_legacy()
%CHECK_TRIM_MODE_REGRESSION_LEGACY Preserve legacy longitudinal behavior.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir,'model'));
addpath(fullfile(rootDir,'analysis'));
addpath(fullfile(rootDir,'services'));

P = params_nominal();
names = {};
passed = [];
messages = {};

run_case('default longitudinal trim still runs', @check_default_trim);
run_case('explicit longitudinal trim matches default', @check_explicit_match);
run_case('legacy linearization remains 9x7', @check_legacy_linearization);
run_case('lateral cyclic remains opt-in', @check_lateral_cyclic_default);

report.names = names;
report.passed = passed;
report.messages = messages;
report.allPassed = all(passed);

fprintf('\nLegacy trim mode regression checks\n');
fprintf('==================================\n');
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

    function check_default_trim()
        result = run_trim_case(base_config(false), P);
        assert(strcmp(result.kind, 'symmetric-trim'));
        assert(result.success);
        assert(numel(result.xTrim) == 9);
        assert(numel(result.uTrim) == 7);
    end

    function check_explicit_match()
        implicit = run_trim_case(base_config(false), P);
        explicit = run_trim_case(base_config(true), P);
        assert(max(abs(implicit.xTrim-explicit.xTrim)) < 1e-12);
        assert(max(abs(implicit.uTrim-explicit.uTrim)) < 1e-12);
        assert(abs(implicit.report.residualNorm- ...
            explicit.report.residualNorm) < 1e-12);
    end

    function check_legacy_linearization()
        result = run_trim_case(base_config(true), P);
        linearResult = run_linearization_case(result, P);
        assert(linearResult.success);
        assert(isequal(size(linearResult.A), [9,9]));
        assert(isequal(size(linearResult.B), [9,7]));
    end

    function check_lateral_cyclic_default()
        controls = get_control_input_names(P);
        assert(numel(controls) == 7);
        assert(~any(strcmp(controls, 'lateralCyclic')));
    end
end

function config = base_config(includeMode)
config = struct('V',0,'betaMDeg',0,'gammaDeg',0, ...
    'initialThetaDeg',0,'initialCollectiveDeg',18, ...
    'initialCyclicLongDeg',0,'thetaLimitDeg',35, ...
    'useMultiStart',false,'alwaysMultiStart',false);
if includeMode
    config.trimMode = 'longitudinal_symmetric';
end
end

function value = ternary(condition,a,b)
if condition
    value = a;
else
    value = b;
end
end
