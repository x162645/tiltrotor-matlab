function report = check_trim_credibility()
%CHECK_TRIM_CREDIBILITY Focused Stage 2/3 trim-diagnostic checks.

P = params_nominal();
cases = {};
passed = [];
messages = {};
results = struct();

run_case('shared point evaluation identity', @test_shared_point_identity);
run_case('three representative diagnostics', @test_representative_cases);
run_case('one-sided finite differences', @test_one_sided_differences);
run_case('deterministic seed sensitivity', @test_seed_sensitivity);
run_case('seed nonconvergence classification', ...
    @test_seed_nonconvergence_classification);
run_case('four-point condition sensitivity', @test_condition_sensitivity);
run_case('invalid options rejected', @test_invalid_options);

report.names = cases;
report.passed = passed;
report.messages = messages;
report.allPassed = all(passed);
report.results = results;

fprintf('\nTrim credibility Stage 2/3 checks\n');
fprintf('==================================\n');
for caseIndex = 1:numel(cases)
    fprintf('%-40s : %s\n', cases{caseIndex}, ...
        ternary(passed(caseIndex), 'PASS', 'FAIL'));
    if ~passed(caseIndex)
        fprintf('  %s\n', messages{caseIndex});
    end
end
if isfield(results, 'conversion')
    fprintf(['Representative statuses: helicopter=%s conversion=%s ' ...
        'airplane=%s\n'], results.helicopter.status, ...
        results.conversion.status, results.airplane.status);
    fprintf(['45 deg minimum margin=%.8f condition=%.6f ' ...
        'max-step-variation=%.3e\n'], ...
        results.conversion.minimumMarginFraction, ...
        results.conversion.conditionNumber, ...
        results.conversion.maximumJacobianStepVariation);
end
fprintf('All trim credibility Stage 2/3 checks passed: %d\n', ...
    report.allPassed);

    function test_shared_point_identity()
        specifications = { ...
            'helicopter_longitudinal', 20, 0; ...
            'conversion_longitudinal', 35, pi/4; ...
            'airplane_longitudinal', 100, pi/2};
        for k = 1:size(specifications,1)
            condition = struct('V', specifications{k,2}, ...
                'betaM', specifications{k,3}, 'gamma', 0);
            definition = make_trim_definition( ...
                specifications{k,1}, condition, P);
            [x, u, trimReport] = trim_general(condition, definition, P);
            z = trim_vector(definition, trimReport);
            [xe, ue, residual, penalty, xdot, eomOut, allocation] = ...
                evaluate_trim_definition_point( ...
                condition, definition, z, P);
            assert(isequaln(xe, x));
            assert(isequaln(ue, u));
            assert(isequaln(residual, trimReport.residual));
            assert(isequaln(penalty, trimReport.penalty));
            assert(isequaln(xdot, trimReport.fullStateDerivative));
            assert(isequaln(eomOut.components.appliedControls, ...
                trimReport.appliedControls));
            assert(isequaln(allocation, trimReport.allocation));
        end
    end

    function test_representative_cases()
        specifications = { ...
            'helicopter_longitudinal', 20, 0, 'PASS'; ...
            'conversion_longitudinal', 35, pi/4, 'PASS'; ...
            'airplane_longitudinal', 100, pi/2, 'PASS'};
        expectedScaled = { ...
            [-3.480288065562e-02, 1.599845432536e-01, 1.881111040848e-02; ...
             -2.871211196488e-02,-1.513686461257e+00, 7.421058217654e-04; ...
             -1.767997774074e-02,-8.221124974694e-02,-2.774191597106e-02], ...
            [-1.580753356285e-03, 1.050458910745e+00,-7.180303306872e-03; ...
             -5.574005409674e-02,-1.380907110975e+00,-1.008426859015e-02; ...
             -4.269540010143e-02, 7.659797053671e-02, 3.100019737827e-02], ...
            [ 1.530502840385e-02, 2.611232006492e+00, 2.913812139694e-03; ...
             -3.557879825097e-01,-3.909213376691e-03,-3.240615306077e-02; ...
             -5.274697257877e-01,-6.997938865623e-01,-3.360965161326e-01]};
        resultNames = {'helicopter','conversion','airplane'};
        for k = 1:size(specifications,1)
            condition = struct('V', specifications{k,2}, ...
                'betaM', specifications{k,3}, 'gamma', 0);
            definition = make_trim_definition( ...
                specifications{k,1}, condition, P);
            [x, u, trimReport] = trim_general(condition, definition, P);
            credibility = diagnose_trim_credibility( ...
                condition, definition, x, u, trimReport, P);
            assert_required_structure(credibility, definition);
            assert(strcmp(credibility.status, specifications{k,4}));
            assert(max(abs(credibility.scaledJacobian(:)- ...
                expectedScaled{k}(:))) < 2e-11);
            assert(credibility.defaultRank == 3);
            assert(credibility.effectiveRank == 3);
            assert(strcmp(credibility.conditionLevel, 'LOW'));
            assert(strcmp(credibility.jacobianStepVariationLevel, 'STABLE'));
            assert(credibility.maxScaledFullDerivative < ...
                P.trim.residualTolerance);
            assert(credibility.commandAppliedDifference == 0);
            assert(all(strcmp(credibility.columnDifferenceMethods(:), ...
                'central')));
            assert(all([credibility.stepResults.finiteReal]));
            assert(strcmp(credibility.seedSensitivity.status, 'NOT_RUN'));
            assert(strcmp(credibility.seedSensitivity.reason, ...
                'STAGE_3_NOT_REQUESTED'));
            assert(strcmp(credibility.conditionSensitivity.status, 'NOT_RUN'));
            assert(strcmp(credibility.conditionSensitivity.reason, ...
                'STAGE_3_NOT_REQUESTED'));
            assert(strcmp(credibility.classification, ...
                'NUMERICAL_DIAGNOSTIC'));
            results.(resultNames{k}) = credibility;
        end
        conversion = results.conversion;
        assert(~any(strcmp(conversion.reasons, 'LOW_MARGIN')));
        expectedMargin = 1.802226554901e-1;
        assert(abs(conversion.minimumMarginFraction-expectedMargin) < 1e-10);
    end

    function test_one_sided_differences()
        condition = struct('V',20,'betaM',0,'gamma',0);
        definition = make_trim_definition( ...
            'helicopter_longitudinal', condition, P);
        [x, u, trimReport] = trim_general(condition, definition, P);
        theta = trimReport.trimVariables.theta;

        backwardDefinition = definition;
        backwardDefinition.bounds(1,2) = theta;
        backward = diagnose_trim_credibility(condition, ...
            backwardDefinition, x, u, trimReport, P);
        assert(all(strcmp(backward.columnDifferenceMethods(:,1), ...
            'backward-second-order')));
        assert(strcmp(backward.status, 'CAUTION'));
        assert(any(strcmp(backward.reasons, 'ONE_SIDED_DIFFERENCE')));

        forwardDefinition = definition;
        forwardDefinition.bounds(1,1) = theta;
        forward = diagnose_trim_credibility(condition, ...
            forwardDefinition, x, u, trimReport, P);
        assert(all(strcmp(forward.columnDifferenceMethods(:,1), ...
            'forward-second-order')));
        assert(strcmp(forward.status, 'CAUTION'));
        assert(any(strcmp(forward.reasons, 'ONE_SIDED_DIFFERENCE')));
    end

    function test_seed_sensitivity()
        [condition, definition, x, u, trimReport] = conversion_baseline();
        baselineX = x;
        baselineU = u;
        baselineReport = trimReport;
        defaultCredibility = diagnose_trim_credibility( ...
            condition, definition, x, u, trimReport, P);
        opts = struct('runSeedSensitivity', true, ...
            'runConditionSensitivity', false);
        credibility = diagnose_trim_credibility( ...
            condition, definition, x, u, trimReport, P, opts);
        seed = credibility.seedSensitivity;
        assert(strcmp(seed.status, 'COMPLETE'));
        assert(~strcmp(seed.classification, 'NOT_RUN'));
        assert(seed.runCount == 2 && numel(seed.results) == 2);
        assert(isequal({seed.results.name}.', {'seedPlus';'seedMinus'}));
        assert(all([seed.results.finiteReal]));
        assert(all([seed.results.converged]));
        assert(~any([seed.results.atLimit]));
        assert(all([seed.results.withinLimits]));
        assert(all(isfinite([seed.results.residualNorm])));
        assert(all(isfinite([seed.results.residualNormDifference])));
        assert(all(isfinite([seed.results.runtime])) && ...
            all([seed.results.runtime] > 0));
        z = trim_vector(definition, trimReport);
        patterns = [1,-1,1; -1,1,-1].';
        for seedIndex = 1:2
            expectedSeed = z+0.25*definition.variableScale(:).* ...
                patterns(:,seedIndex);
            assert(seed.results(seedIndex).seedScaleFactor == 1);
            assert(isequal(seed.results(seedIndex).requestedInitialValues, ...
                expectedSeed));
            assert(isequal(seed.results(seedIndex).initialValues, ...
                expectedSeed));
            assert(isreal(seed.results(seedIndex).xTrim) && ...
                all(isfinite(seed.results(seedIndex).xTrim)));
            assert(isreal(seed.results(seedIndex).uTrim) && ...
                all(isfinite(seed.results(seedIndex).uTrim)));
        end
        if seed.maximumStateControlDifference <= seed.consistencyThreshold
            assert(strcmp(seed.classification, 'CONSISTENT'));
        else
            assert(strcmp(seed.classification, 'CAUTION'));
            assert(any(strcmp(seed.reasons, ...
                'POSSIBLE_BRANCH_SENSITIVITY')));
        end
        assert(strcmp(credibility.conditionSensitivity.status, 'NOT_RUN'));
        assert(strcmp(credibility.conditionSensitivity.reason, ...
            'STAGE_3_NOT_REQUESTED'));
        assert(isequaln(x, baselineX) && isequaln(u, baselineU));
        assert(isequaln(trimReport, baselineReport));
        assert_base_credibility_unchanged(defaultCredibility, credibility);
        results.seedSensitivity = seed;
    end

    function test_seed_nonconvergence_classification()
        [condition, definition, x, u, trimReport] = conversion_baseline();
        lowIterationP = P;
        lowIterationP.trim.maxIterations = 0;
        opts = struct('runSeedSensitivity', true, ...
            'runConditionSensitivity', false);
        credibility = diagnose_trim_credibility( ...
            condition, definition, x, u, trimReport, lowIterationP, opts);
        seed = credibility.seedSensitivity;
        assert(strcmp(seed.status, 'COMPLETE'));
        assert(strcmp(seed.classification, 'FAIL'));
        assert(any(strcmp(seed.reasons, 'SEED_NOT_CONVERGED')));
        assert(any(~[seed.results.converged]));
        results.seedNonconvergence = seed;
    end

    function test_condition_sensitivity()
        [condition, definition, x, u, trimReport] = conversion_baseline();
        baselineX = x;
        baselineU = u;
        baselineReport = trimReport;
        defaultCredibility = diagnose_trim_credibility( ...
            condition, definition, x, u, trimReport, P);
        opts = struct('runSeedSensitivity', false, ...
            'runConditionSensitivity', true);
        credibility = diagnose_trim_credibility( ...
            condition, definition, x, u, trimReport, P, opts);
        sensitivity = credibility.conditionSensitivity;
        assert(strcmp(sensitivity.status, 'COMPLETE'));
        assert(~strcmp(sensitivity.classification, 'NOT_RUN'));
        assert(sensitivity.runCount == 4 && numel(sensitivity.results) == 4);
        expectedNames = {'V34p5_beta45';'V35p5_beta45'; ...
            'V35_beta44p5';'V35_beta45p5'};
        assert(isequal({sensitivity.results.name}.', expectedNames));
        expectedV = [34.5,35.5,35,35];
        expectedBeta = [45,45,44.5,45.5]*pi/180;
        z = trim_vector(definition, trimReport);
        for conditionIndex = 1:4
            item = sensitivity.results(conditionIndex);
            assert(item.condition.V == expectedV(conditionIndex));
            assert(abs(item.condition.betaM-expectedBeta(conditionIndex)) < ...
                10*eps);
            assert(item.condition.gamma == 0);
            assert(isequal(item.initialValues, z));
            assert(item.converged);
            assert(item.finiteReal);
            assert(isreal(item.xTrim) && all(isfinite(item.xTrim)));
            assert(isreal(item.uTrim) && all(isfinite(item.uTrim)));
            assert(isfinite(item.residualNorm));
            assert(isfinite(item.maxStateDifferenceFromBaseline));
            assert(isfinite(item.maxControlDifferenceFromBaseline));
            assert(isfinite(item.conditionNumber));
            assert(isfinite(item.minimumMarginFraction));
            assert(isfinite(item.commandAppliedDifference));
            assert(isfinite(item.runtime) && item.runtime > 0);
            assert(~item.atLimit && item.withinLimits);
            assert(~isempty(item.marginItems));
            assert(~strcmp(item.credibilityStatus, 'FAIL'));
        end
        assert(sensitivity.results(3).condition.betaM ~= ...
            sensitivity.results(4).condition.betaM);
        assert(strcmp(credibility.seedSensitivity.status, 'NOT_RUN'));
        assert(strcmp(credibility.seedSensitivity.reason, ...
            'STAGE_3_NOT_REQUESTED'));
        assert(isequaln(x, baselineX) && isequaln(u, baselineU));
        assert(isequaln(trimReport, baselineReport));
        assert_base_credibility_unchanged(defaultCredibility, credibility);
        results.conditionSensitivity = sensitivity;
    end

    function test_invalid_options()
        condition = struct('V',20,'betaM',0,'gamma',0);
        definition = make_trim_definition( ...
            'helicopter_longitudinal', condition, P);
        [x, u, trimReport] = trim_general(condition, definition, P);
        try
            diagnose_trim_credibility(condition, definition, x, u, ...
                trimReport, P, struct('maxStepReductions', -1));
        catch ME
            assert(strcmp(ME.identifier, ...
                'diagnose_trim_credibility:InvalidOptions'));
            return;
        end
        error('check_trim_credibility:MissingExpectedError', ...
            'Invalid diagnostic options were not rejected.');
    end

    function [condition, definition, x, u, trimReport] = ...
            conversion_baseline()
        condition = struct('V',35,'betaM',pi/4,'gamma',0);
        definition = make_trim_definition( ...
            'conversion_longitudinal', condition, P);
        [x, u, trimReport] = trim_general(condition, definition, P);
    end

    function assert_base_credibility_unchanged(before, after)
        fields = {'rawJacobian','scaledJacobian','rawJacobians', ...
            'scaledJacobians','stepResults','hScaled','singularValues', ...
            'sigmaMax','sigmaMin','defaultRank','effectiveRank', ...
            'rankTolerance','conditionNumber','conditionLevel', ...
            'jacobianStepVariation','maximumJacobianStepVariation', ...
            'fullDerivative','scaledFullDerivative', ...
            'maxScaledFullDerivative','marginItems', ...
            'minimumMarginFraction','commandAppliedDifference', ...
            'trimVariables','trimResidual','pointReproduction'};
        for fieldIndex = 1:numel(fields)
            assert(isequaln(before.(fields{fieldIndex}), ...
                after.(fields{fieldIndex})), ...
                'Base credibility field changed: %s', fields{fieldIndex});
        end
    end

    function assert_required_structure(credibility, definition)
        required = {'status','reasons','rawJacobian','scaledJacobian', ...
            'stepResults','columnDifferenceMethods','singularValues', ...
            'sigmaMax','sigmaMin','defaultRank','effectiveRank', ...
            'rankTolerance','conditionNumber','conditionLevel', ...
            'jacobianStepVariation','fullDerivative', ...
            'scaledFullDerivative','marginItems', ...
            'minimumMarginFraction','commandAppliedDifference', ...
            'seedSensitivity','conditionSensitivity','classification'};
        assert(all(isfield(credibility, required)));
        assert(isequal(size(credibility.rawJacobian), [3,3]));
        assert(isequal(size(credibility.scaledJacobian), [3,3]));
        assert(numel(credibility.stepResults) == 3);
        assert(isequal(credibility.hScaled, [1e-2;1e-3;1e-4]));
        assert(isequal(credibility.rowLabels, ...
            definition.residualNames(:)));
        assert(isequal(credibility.columnLabels, ...
            definition.unknownNames(:)));
        assert(isreal(credibility.rawJacobian) && ...
            all(isfinite(credibility.rawJacobian(:))));
        assert(isreal(credibility.scaledJacobian) && ...
            all(isfinite(credibility.scaledJacobian(:))));
        assert(numel(credibility.fullDerivative) == 9);
        assert(numel(credibility.scaledFullDerivative) == 9);
        assert(numel(credibility.selectedResidualMask) == 9);
        assert(all(structfun(@(x) x == 0, ...
            credibility.pointReproduction)));
    end

    function z = trim_vector(definition, trimReport)
        z = zeros(numel(definition.unknownNames),1);
        for j = 1:numel(z)
            z(j) = trimReport.trimVariables.(definition.unknownNames{j});
        end
    end

    function run_case(name, fun)
        cases{end+1,1} = name;
        try
            fun();
            passed(end+1,1) = true;
            messages{end+1,1} = '';
        catch ME
            passed(end+1,1) = false;
            messages{end+1,1} = sprintf('%s: %s', ...
                ME.identifier, ME.message);
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
