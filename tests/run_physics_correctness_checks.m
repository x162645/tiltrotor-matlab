function report = run_physics_correctness_checks()
%RUN_PHYSICS_CORRECTNESS_CHECKS Run the existing suite plus focused audits.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir,'model'));
addpath(fullfile(rootDir,'analysis'));
addpath(fullfile(rootDir,'tests'));

report.existing = run_all_checks();
report.physicalSanity = check_physical_sanity();
report.controlLimits = check_control_limits();
report.allPassed = report.existing.allPassed && ...
    report.physicalSanity.allPassed && report.controlLimits.allPassed;

fprintf('\nPhysics and correctness audit summary\n');
fprintf('=====================================\n');
fprintf('Existing internal suite : %s\n', ...
    ternary(report.existing.allPassed,'PASS','FAIL'));
fprintf('Physical sanity        : %s\n', ...
    ternary(report.physicalSanity.allPassed,'PASS','FAIL'));
fprintf('Control-limit behavior : %s\n', ...
    ternary(report.controlLimits.allPassed,'PASS','FAIL'));
fprintf('Overall                 : %s\n', ...
    ternary(report.allPassed,'PASS','FAIL'));

    function value = ternary(condition,a,b)
        if condition
            value = a;
        else
            value = b;
        end
    end
end
