function report = check_low_collective_quick_audit()
%CHECK_LOW_COLLECTIVE_QUICK_AUDIT Focused regression for audit artifacts.

rootDir = fileparts(fileparts(mfilename('fullpath')));
outputDir = fullfile(rootDir, 'docs', 'low_collective_quick_audit');
result = low_collective_quick_audit(outputDir);
collectivePointsDeg = [4, 8, 10, 12];

cases = struct('name',{},'passed',{},'message',{});
add_case('isolated baseline identity', ...
    strcmp(strtrim(git_value(rootDir, ...
    'merge-base HEAD 65e459504dd473f6dcf18326028f3a8a7991c55a')), ...
    '65e459504dd473f6dcf18326028f3a8a7991c55a'), ...
    'Audit branch is not based on the recorded PR #59 remote HEAD.');

for k = 4
    diag = result.pointResults(k);
    prod = result.productionResults(k);
    scaleT = max(1, abs(prod.thrust));
    scaleQ = max(1, abs(prod.torque));
    ok = prod.success && diag.converged && ...
        abs(diag.loads.T-prod.thrust)/scaleT < 1e-10 && ...
        abs(diag.loads.Q-prod.torque)/scaleQ < 1e-10 && ...
        abs(diag.finalVi-prod.inducedVelocity) < 1e-10;
    add_case(sprintf('%g deg diagnostic matches production', ...
        collectivePointsDeg(k)), ok, ...
        sprintf('T/Q/vi mismatch at point index %d.', k));
end

diag = result.pointResults(1);
prod = result.productionResults(1);
scaleT = max(1,abs(prod.thrust));
scaleQ = max(1,abs(prod.torque));
add_case('4 deg numerical return is physically rejected', ...
    prod.returned && prod.numericalConverged && ...
    ~prod.physicalConverged && ~prod.success && ...
    strcmp(prod.physicalStatus, ...
    'UNSUPPORTED_NEGATIVE_THRUST_BRANCH') && ...
    ~prod.physicalBranchSupported && ...
    ~prod.closureResidualSatisfied && ...
    isfinite(prod.closureResidual) && ...
    abs(prod.closureResidual) > 100 && ...
    abs(diag.loads.T-prod.thrust)/scaleT < 1e-10 && ...
    abs(diag.loads.Q-prod.torque)/scaleQ < 1e-10 && ...
    abs(diag.finalVi-prod.inducedVelocity) < 1e-10, ...
    '4 deg negative-thrust branch was accepted or its raw residual was hidden.');

for k = [2,3]
    prod = result.productionResults(k);
    ok = ~prod.returned && ~prod.success && strcmp(prod.errorIdentifier, ...
        'rotor_model_bemt:CoupledSolveNotConverged');
    add_case(sprintf('%g deg production failure retained', ...
        collectivePointsDeg(k)), ok, ...
        sprintf('Expected committed coupled-solve failure at point index %d.', k));
end

required = {
    'LOW_COLLECTIVE_DEFINITION_MAPPING.csv'
    'LOW_COLLECTIVE_POINT_DIAGNOSTICS.csv'
    'LOW_COLLECTIVE_RESIDUAL_AT_8DEG.csv'
    'LOW_COLLECTIVE_RESIDUAL_AT_8DEG.png'
    'LOW_COLLECTIVE_SEED_TESTS.csv'
    'LOW_COLLECTIVE_AUDIT_SUMMARY.csv'
    'LOW_COLLECTIVE_MATLAB_RUN.log'
    'LOW_COLLECTIVE_RUN_ENVIRONMENT.txt'};
allExist = true;
for k = 1:numel(required)
    allExist = allExist && exist(fullfile(outputDir, required{k}), 'file') == 2;
end
add_case('all required generated artifacts exist', allExist, ...
    'One or more required quick-audit artifacts are missing.');

finiteResidual = result.residualTable.valid;
add_case('residual probe has eleven valid finite points', ...
    height(result.residualTable) == 11 && all(finiteResidual) && ...
    all(isfinite(result.residualTable.residual_N)), ...
    'Residual probe does not contain eleven valid finite points.');

add_case('seed matrix has four mandated trials', ...
    height(result.seedTable) == 4 && ...
    isequal(sort(unique(result.seedTable.collective_deg)), [8;10]), ...
    'Seed table does not contain both seeds at 8 and 10 deg.');

summaryVariables = {'question','answer','classification','evidence_file', ...
    'evidence_field_or_line','confidence','remaining_uncertainty', ...
    'recommended_action'};
add_case('summary schema is complete', ...
    all(ismember(summaryVariables, result.summaryTable.Properties.VariableNames)), ...
    'Audit summary is missing one or more required columns.');

report.cases = cases;
report.allPassed = all([cases.passed]);
report.residualClassification = result.residualClassification;
report.seedClassifications = unique(result.seedTable.pair_classification);

fprintf('\nLow-collective quick-audit focused checks\n');
fprintf('=========================================\n');
for k = 1:numel(cases)
    fprintf('%-55s : %s\n', cases(k).name, ...
        ternary(cases(k).passed, 'PASS', 'FAIL'));
    if ~cases(k).passed
        fprintf('  %s\n', cases(k).message);
    end
end
fprintf('Residual classification: %s\n', report.residualClassification);
fprintf('All focused checks passed: %d\n', report.allPassed);

    function add_case(name, passed, message)
        cases(end+1,1).name = name;
        cases(end).passed = logical(passed);
        cases(end).message = ternary(passed, '', message);
    end
end

function value = git_value(rootDir, arguments)
[status, value] = system(sprintf('git -C "%s" %s', rootDir, arguments));
if status ~= 0
    value = '';
end
end

function value = ternary(condition, a, b)
if condition
    value = a;
else
    value = b;
end
end
