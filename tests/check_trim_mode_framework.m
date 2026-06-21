function report = check_trim_mode_framework()
%CHECK_TRIM_MODE_FRAMEWORK Validate definitions, legacy identity, and endpoints.

P = params_nominal();
condition20 = struct('V', 20, 'betaM', 0, 'gamma', 0);
base = make_trim_definition('helicopter_longitudinal', condition20, P);
legacyStateDifferences = [];
legacyControlDifferences = [];
legacyResidualDifferences = [];
helicopterResidualNorm = NaN;
airplaneResidualNorm = NaN;

cases = {};
passed = [];
messages = {};
run_case('definition factory schemas', @test_factory_schemas);
run_case('overdetermined definition rejected', @test_overdetermined);
run_case('underdetermined definition rejected', @test_underdetermined);
run_case('duplicate unknown rejected', @test_duplicate);
run_case('unsupported names rejected', @test_unsupported);
run_case('unknown/fixed overlap rejected', @test_overlap);
run_case('malformed values and sizes rejected', @test_malformed);
run_case('conversion allocation constraint required', @test_conversion);
run_case('modified legacy compatibility rejected', @test_modified_legacy);
run_case('legacy hover identity', @test_legacy_hover);
run_case('legacy 20 m/s identity', @test_legacy_v20);
run_case('helicopter endpoint', @test_helicopter_endpoint);
run_case('airplane endpoint', @test_airplane_endpoint);

report.names = cases;
report.passed = passed;
report.messages = messages;
report.allPassed = all(passed);
report.legacyWorstStateDifference = max(legacyStateDifferences);
report.legacyWorstControlDifference = max(legacyControlDifferences);
report.legacyWorstResidualNormDifference = max(legacyResidualDifferences);
report.helicopterResidualNorm = helicopterResidualNorm;
report.airplaneResidualNorm = airplaneResidualNorm;

fprintf('\nGeneral trim mode framework checks\n');
fprintf('==================================\n');
for k = 1:numel(cases)
    fprintf('%-43s : %s\n', cases{k}, ternary(passed(k), 'PASS', 'FAIL'));
    if ~passed(k)
        fprintf('  %s\n', messages{k});
    end
end
fprintf('Legacy worst differences: state=%.3e control=%.3e residual-norm=%.3e\n', ...
    report.legacyWorstStateDifference, report.legacyWorstControlDifference, ...
    report.legacyWorstResidualNormDifference);
fprintf('Endpoint residual norms: helicopter=%.3e airplane=%.3e\n', ...
    report.helicopterResidualNorm, report.airplaneResidualNorm);
fprintf('All general trim mode framework checks passed: %d\n', report.allPassed);

    function test_factory_schemas()
        legacy = make_trim_definition('legacy_symmetric', condition20, P);
        heli = make_trim_definition('helicopter_longitudinal', condition20, P);
        airplaneCondition = struct('V',100,'betaM',pi/2,'gamma',0);
        airplane = make_trim_definition('airplane_longitudinal', airplaneCondition, P);
        assert(legacy.compatibilityMode && ~heli.compatibilityMode && ...
            ~airplane.compatibilityMode);
        assert(isequal(legacy.unknownNames, ...
            {'theta';'collective';'cyclicLong'}));
        assert(isequal(airplane.unknownNames, ...
            {'theta';'collective';'elevator'}));
        assert(airplane.fixedControls.cyclicLong == 0);
        assert(heli.fixedControls.elevator == 0);
    end

    function test_overdetermined()
        bad = base;
        bad.unknownNames = {'theta';'collective'};
        bad.initialValues = bad.initialValues(1:2);
        bad.variableScale = bad.variableScale(1:2);
        bad.bounds = bad.bounds(1:2,:);
        expect_error(bad, 'trim_general:OverdeterminedDefinition');
    end

    function test_underdetermined()
        bad = base;
        bad.residualNames = {'udot';'wdot'};
        expect_error(bad, 'trim_general:UnderdeterminedDefinition');
    end

    function test_duplicate()
        bad = base;
        bad.unknownNames = {'theta';'theta';'collective'};
        expect_error(bad, 'trim_general:InvalidDefinition');
    end

    function test_unsupported()
        bad = base;
        bad.unknownNames{3} = 'bogusControl';
        expect_error(bad, 'trim_general:InvalidDefinition');
        bad = base;
        bad.residualNames{3} = 'bogusDot';
        expect_error(bad, 'trim_general:InvalidDefinition');
        bad = base;
        bad.fixedStates.u = 0;
        expect_error(bad, 'trim_general:InvalidDefinition');
    end

    function test_overlap()
        bad = base;
        bad.fixedControls.collective = 0;
        expect_error(bad, 'trim_general:InvalidDefinition');
    end

    function test_malformed()
        bad = base;
        bad.initialValues = [0; NaN; 0];
        expect_error(bad, 'trim_general:InvalidDefinition');
        bad = base;
        bad.variableScale = [1; 2];
        expect_error(bad, 'trim_general:InvalidDefinition');
        bad = base;
        bad.bounds = [-1 1; -1 1];
        expect_error(bad, 'trim_general:InvalidDefinition');
        bad = base;
        bad.fixedControls.elevator = [0 0];
        expect_error(bad, 'trim_general:InvalidDefinition');
    end

    function test_conversion()
        bad = base;
        bad.unknownNames = {'theta';'collective';'cyclicLong';'elevator'};
        bad.initialValues = zeros(4,1);
        bad.variableScale = ones(4,1);
        bad.bounds = repmat([-1 1],4,1);
        bad.fixedControls = rmfield(bad.fixedControls, 'elevator');
        expect_error(bad, 'trim_general:AllocationConstraintRequired');
    end

    function test_modified_legacy()
        legacy = make_trim_definition('legacy_symmetric', condition20, P);
        legacy.fixedControls.elevator = 1e-3;
        expect_error(legacy, 'trim_general:InvalidDefinition');
    end

    function test_legacy_hover()
        condition = struct('V',0,'betaM',0,'gamma',0);
        definition = make_trim_definition('legacy_symmetric', condition, P);
        [xOld,uOld,rOld] = trim_symmetric(0,0,P);
        [xNew,uNew,rNew] = trim_general(condition,definition,P);
        record_legacy_differences(xOld,uOld,rOld,xNew,uNew,rNew);
        assert(rNew.compatibilityMode);
    end

    function test_legacy_v20()
        definition = make_trim_definition('legacy_symmetric', condition20, P);
        [xOld,uOld,rOld] = trim_symmetric(20,0,P);
        [xNew,uNew,rNew] = trim_general(condition20,definition,P);
        record_legacy_differences(xOld,uOld,rOld,xNew,uNew,rNew);
    end

    function test_helicopter_endpoint()
        definition = make_trim_definition('helicopter_longitudinal', condition20, P);
        [x,u,r] = trim_general(condition20,definition,P);
        helicopterResidualNorm = r.residualNorm;
        assert_real_finite(x,u,r);
        assert(r.converged && r.residualNorm < P.trim.residualTolerance);
        assert(u(6) == 0 && ~r.atLimit && r.withinLimits);
        assert(strcmp(r.definitionName, 'helicopter_longitudinal'));
    end

    function test_airplane_endpoint()
        condition = struct('V',100,'betaM',pi/2,'gamma',0);
        definition = make_trim_definition('airplane_longitudinal', condition, P);
        [x,u,r] = trim_general(condition,definition,P);
        airplaneResidualNorm = r.residualNorm;
        assert_real_finite(x,u,r);
        assert(r.converged && r.residualNorm < P.trim.residualTolerance);
        assert(u(3) == 0 && ~r.atLimit && r.withinLimits);
        assert(strcmp(r.definitionName, 'airplane_longitudinal'));
    end

    function expect_error(definition, identifier)
        try
            trim_general(condition20, definition, P);
        catch ME
            assert(strcmp(ME.identifier, identifier), ...
                'Expected %s, received %s.', identifier, ME.identifier);
            return;
        end
        error('check_trim_mode_framework:MissingExpectedError', ...
            'Expected error %s was not raised.', identifier);
    end

    function record_legacy_differences(xOld,uOld,rOld,xNew,uNew,rNew)
        dx = max(abs(xOld-xNew));
        du = max(abs(uOld-uNew));
        dr = abs(rOld.residualNorm-rNew.residualNorm);
        legacyStateDifferences(end+1) = dx;
        legacyControlDifferences(end+1) = du;
        legacyResidualDifferences(end+1) = dr;
        assert(dx <= 1e-10 && du <= 1e-10 && dr <= 1e-10);
    end

    function assert_real_finite(x,u,r)
        assert(isreal(x) && all(isfinite(x)));
        assert(isreal(u) && all(isfinite(u)));
        assert(isreal(r.fullStateDerivative) && ...
            all(isfinite(r.fullStateDerivative)));
    end

    function run_case(name,fun)
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

    function value = ternary(condition,a,b)
        if condition
            value = a;
        else
            value = b;
        end
    end
end
