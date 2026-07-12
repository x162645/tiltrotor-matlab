function report = check_full_6dof_trim_solver()
%CHECK_FULL_6DOF_TRIM_SOLVER Verify straight six-DOF trim solver behavior.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir,'model'));
addpath(fullfile(rootDir,'analysis'));
addpath(fullfile(rootDir,'services'));

P = params_nominal();
names = {};
passed = [];
messages = {};

run_case('7-input full 6-DOF smoke', @check_seven_input);
run_case('8-input full 6-DOF smoke', @check_eight_input);
run_case('full solver is not longitudinal wrapper', @check_not_wrapper);
run_case('limit at active variable fails success', @check_limit_failure);

report.names = names;
report.passed = passed;
report.messages = messages;
report.allPassed = all(passed);

fprintf('\nFull 6-DOF trim solver checks\n');
fprintf('=============================\n');
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

    function check_seven_input()
        result = run_trim_case(base_config(), P);
        assert(strcmp(result.kind, 'full-6dof-straight-trim'));
        assert(~isfield(result, 'guarded') || ~result.guarded);
        assert(result.report.finite);
        assert(result.success);
        assert(numel(result.xTrim) == 9);
        assert(numel(result.uTrim) == 7);
        assert(isequal(result.report.residualLabels, ...
            {'udot';'vdot';'wdot';'pdot';'qdot';'rdot'}));
        assert(result.report.primaryResidualNorm < result.report.successTolerance);
    end

    function check_eight_input()
        P8 = write_parameter_value(P, 'control.enableLateralCyclic', 1);
        result = run_trim_case(base_config(), P8);
        assert(strcmp(result.kind, 'full-6dof-straight-trim'));
        assert(result.report.finite);
        assert(numel(result.uTrim) == 8);
        assert(any(strcmp(result.report.selectedControls, 'lateralCyclic')));
        assert(strcmp(result.controlNames{5}, 'lateralCyclic'));
    end

    function check_not_wrapper()
        result = run_trim_case(base_config(), P);
        assert(~strcmp(result.kind, 'symmetric-trim'));
        assert(strcmp(result.report.definitionName, 'full_6dof_straight_trim'));
        assert(numel(result.report.unknownNames) == 6);
        assert(any(strcmp(result.report.unknownNames, 'phi')));
        assert(any(strcmp(result.report.residualLabels, 'vdot')));
    end

    function check_limit_failure()
        Plim = P;
        Plim.control.rudderLim = [0, 1.0e-12];
        result = run_trim_case(base_config(), Plim);
        assert(~result.success);
        assert(result.report.finite);
        assert(result.report.atLimit);
    end
end

function config = base_config()
config = struct('V',0,'betaMDeg',0,'gammaDeg',0, ...
    'initialThetaDeg',0,'initialCollectiveDeg',18, ...
    'initialCyclicLongDeg',0,'thetaLimitDeg',35, ...
    'useMultiStart',false,'alwaysMultiStart',false, ...
    'trimMode','full_6dof_straight_trim');
end

function value = ternary(condition,a,b)
if condition
    value = a;
else
    value = b;
end
end
