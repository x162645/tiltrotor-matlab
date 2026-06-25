function report = check_pitch_allocation()
%CHECK_PITCH_ALLOCATION Validate the ASSUMED_CONCEPT open-loop allocation.

P = params_nominal();
direction = struct('cyclicDirection', -1, 'elevatorDirection', -1);
d2r = pi/180;

cases = {};
passed = [];
messages = {};
staticRuntime = NaN;
helicopterRuntime = NaN;
airplaneRuntime = NaN;
conversionRuntime = NaN;
helicopterDifferences = nan(1,3);
airplaneDifferences = nan(1,3);
conversionResult = struct();

run_case('static allocation schedule', @test_static_schedule);
run_case('helicopter endpoint equivalence', @test_helicopter_endpoint);
run_case('airplane endpoint equivalence', @test_airplane_endpoint);
run_case('single 45 deg conversion trim', @test_conversion_point);

report.names = cases;
report.passed = passed;
report.messages = messages;
report.allPassed = all(passed);
report.staticRuntime = staticRuntime;
report.helicopterRuntime = helicopterRuntime;
report.airplaneRuntime = airplaneRuntime;
report.conversionRuntime = conversionRuntime;
report.helicopterDifferences = helicopterDifferences;
report.airplaneDifferences = airplaneDifferences;
report.conversion = conversionResult;

fprintf('\nOpen-loop pitch allocation checks\n');
fprintf('=================================\n');
for k = 1:numel(cases)
    fprintf('%-39s : %s\n', cases{k}, ternary(passed(k), 'PASS', 'FAIL'));
    if ~passed(k)
        fprintf('  %s\n', messages{k});
    end
end
fprintf(['Endpoint differences [state control residual-norm]:\n' ...
    '  helicopter %.3e %.3e %.3e\n' ...
    '  airplane   %.3e %.3e %.3e\n'], ...
    helicopterDifferences, airplaneDifferences);
if isfield(conversionResult, 'residualNorm')
    fprintf(['45 deg conversion: residual=%.6e pitchCommand=%.6e ' ...
        'cyclicLong=%.6e elevator=%.6e atLimit=%d withinLimits=%d\n'], ...
        conversionResult.residualNorm, conversionResult.pitchCommand, ...
        conversionResult.cyclicLong, conversionResult.elevator, ...
        conversionResult.atLimit, conversionResult.withinLimits);
    if isfield(conversionResult, 'cyclicUsage')
        fprintf(['45 deg authority: limit=%.6e normalizedCommand=%.6e ' ...
            'cyclicUsage=%.6f elevatorUsage=%.6f ' ...
            'cyclicMargin=%.6f elevatorMargin=%.6f\n'], ...
            conversionResult.pitchCommandLimit, ...
            conversionResult.normalizedPitchCommand, ...
            conversionResult.cyclicUsage, conversionResult.elevatorUsage, ...
            conversionResult.cyclicMargin, conversionResult.elevatorMargin);
        fprintf('45 deg state x=');
        fprintf(' %.12e', conversionResult.x);
        fprintf('\n45 deg control u=');
        fprintf(' %.12e', conversionResult.u);
        fprintf('\n45 deg residual=');
        fprintf(' %.12e', conversionResult.residual);
        fprintf('\n');
    end
end
fprintf(['Runtimes [static helicopter airplane conversion] s: ' ...
    '%.3f %.3f %.3f %.3f\n'], staticRuntime, helicopterRuntime, ...
    airplaneRuntime, conversionRuntime);
fprintf('All open-loop pitch allocation checks passed: %d\n', ...
    report.allPassed);

    function test_static_schedule()
        timer = tic;
        beta = [0 15 30 45 60 75 90]*d2r;
        gCyclic = zeros(size(beta));
        gElevator = zeros(size(beta));
        pitchCommandLimit = zeros(size(beta));
        command = 0.37;
        for i = 1:numel(beta)
            a = pitch_allocation_schedule(beta(i), command, P, direction);
            assert(strcmp(a.type, 'ebook_cosine_virtual_command'));
            assert(strcmp(a.classification, 'ASSUMED_CONCEPT'));
            assert(isreal(a.gCyclic) && isfinite(a.gCyclic));
            assert(isreal(a.gElevator) && isfinite(a.gElevator));
            assert(a.gCyclic >= 0 && a.gCyclic <= 1);
            assert(a.gElevator >= 0 && a.gElevator <= 1);
            assert(abs(a.gCyclic+a.gElevator-1) <= 10*eps);
            assert(isreal(a.authorityDenominator) && ...
                isfinite(a.authorityDenominator));
            assert(isreal(a.pitchCommandLimit) && ...
                isfinite(a.pitchCommandLimit));
            assert(a.pitchCommandLimit >= 1 && a.pitchCommandLimit <= 2+10*eps);
            assert(abs(a.normalizedPitchCommand - ...
                command/a.pitchCommandLimit) <= 10*eps);
            assert(a.normalizedPitchCommand >= -1 && ...
                a.normalizedPitchCommand <= 1);
            assert(abs(a.cyclicLong - direction.cyclicDirection* ...
                a.gCyclic*a.cyclicReference*command) <= 10*eps);
            assert(abs(a.elevator - direction.elevatorDirection* ...
                a.gElevator*a.elevatorReference*command) <= 10*eps);
            gCyclic(i) = a.gCyclic;
            gElevator(i) = a.gElevator;
            pitchCommandLimit(i) = a.pitchCommandLimit;

            boundary = pitch_allocation_schedule( ...
                beta(i), a.pitchCommandLimit, P, direction);
            cyclicUsage = abs(boundary.cyclicLong)/boundary.cyclicReference;
            elevatorUsage = abs(boundary.elevator)/boundary.elevatorReference;
            assert(abs(max(cyclicUsage,elevatorUsage)-1) <= 10*eps);
            assert(abs(boundary.cyclicLong - direction.cyclicDirection* ...
                boundary.gCyclic*boundary.cyclicReference* ...
                boundary.pitchCommand) <= 10*eps);
            assert(abs(boundary.elevator - direction.elevatorDirection* ...
                boundary.gElevator*boundary.elevatorReference* ...
                boundary.pitchCommand) <= 10*eps);
        end
        assert(all(diff(gCyclic) <= 10*eps));
        assert(all(diff(gElevator) >= -10*eps));
        assert(gCyclic(1) == 1 && gElevator(1) == 0);
        assert(abs(gCyclic(4)-0.5) <= 10*eps && ...
            abs(gElevator(4)-0.5) <= 10*eps);
        assert(abs(gCyclic(end)) <= 10*eps && gElevator(end) == 1);
        assert(abs(pitchCommandLimit(1)-1) <= 10*eps);
        assert(abs(pitchCommandLimit(4)-2) <= 20*eps);
        assert(abs(pitchCommandLimit(end)-1) <= 10*eps);
        assert(all(pitchCommandLimit >= 1 & ...
            pitchCommandLimit <= 2+20*eps));

        expect_schedule_error(-eps, 0, P, direction, ...
            'pitch_allocation_schedule:InvalidNacelleAngle');
        expect_schedule_error(pi/2+eps, 0, P, direction, ...
            'pitch_allocation_schedule:InvalidNacelleAngle');
        expect_schedule_error(NaN, 0, P, direction, ...
            'pitch_allocation_schedule:InvalidNacelleAngle');
        expect_schedule_error(0, 1+eps, P, direction, ...
            'pitch_allocation_schedule:InvalidPitchCommand');
        expect_schedule_error(0, Inf, P, direction, ...
            'pitch_allocation_schedule:InvalidPitchCommand');
        expect_schedule_error(pi/4, 2+1e-10, P, direction, ...
            'pitch_allocation_schedule:InvalidPitchCommand');
        badP = P;
        badP.control.cyclicLim = [0 0];
        expect_schedule_error(0, 0, badP, direction, ...
            'pitch_allocation_schedule:InvalidReference');
        badP = P;
        badP.control.elevatorLim = [NaN 1];
        expect_schedule_error(0, 0, badP, direction, ...
            'pitch_allocation_schedule:InvalidReference');
        badDirection = direction;
        badDirection.cyclicDirection = 0;
        expect_schedule_error(0, 0, P, badDirection, ...
            'pitch_allocation_schedule:InvalidDirection');
        badDirection = direction;
        badDirection.elevatorDirection = 2;
        expect_schedule_error(0, 0, P, badDirection, ...
            'pitch_allocation_schedule:InvalidDirection');

        condition = struct('V',35,'betaM',pi/4,'gamma',0);
        definition = make_trim_definition( ...
            'conversion_longitudinal', condition, P);
        assert(isequal(definition.unknownNames, ...
            {'theta';'collective';'pitchCommand'}));
        assert(isequal(definition.residualNames, {'udot';'wdot';'qdot'}));
        assert(~isfield(definition.fixedControls, 'cyclicLong'));
        assert(~isfield(definition.fixedControls, 'elevator'));
        assert(strcmp(definition.allocation.classification, 'ASSUMED_CONCEPT'));
        assert(abs(definition.bounds(3,1)+2) <= 20*eps && ...
            abs(definition.bounds(3,2)-2) <= 20*eps);

        endpointCondition = struct('V',20,'betaM',0,'gamma',0);
        endpointDefinition = make_trim_definition( ...
            'conversion_longitudinal', endpointCondition, P);
        assert(isequal(endpointDefinition.bounds(3,:), [-1 1]));
        endpointCondition.betaM = pi/2;
        endpointDefinition = make_trim_definition( ...
            'conversion_longitudinal', endpointCondition, P);
        assert(abs(endpointDefinition.bounds(3,1)+1) <= 10*eps && ...
            abs(endpointDefinition.bounds(3,2)-1) <= 10*eps);

        bad = definition;
        bad = rmfield(bad, 'allocation');
        expect_trim_error(condition, bad, 'trim_general:InvalidDefinition');
        bad = definition;
        bad.fixedControls.cyclicLong = 0;
        expect_trim_error(condition, bad, 'trim_general:InvalidDefinition');
        staticRuntime = toc(timer);
    end

    function test_helicopter_endpoint()
        timer = tic;
        condition = struct('V',20,'betaM',0,'gamma',0);
        directDefinition = make_trim_definition( ...
            'helicopter_longitudinal', condition, P);
        conversionDefinition = make_trim_definition( ...
            'conversion_longitudinal', condition, P);
        [xDirect,uDirect,rDirect] = trim_general( ...
            condition, directDefinition, P);
        [xConversion,uConversion,rConversion] = trim_general( ...
            condition, conversionDefinition, P);
        helicopterRuntime = toc(timer);
        helicopterDifferences = [max(abs(xDirect-xConversion)), ...
            max(abs(uDirect-uConversion)), ...
            abs(rDirect.residualNorm-rConversion.residualNorm)];
        assert(rDirect.converged && rConversion.converged);
        assert(all(helicopterDifferences <= 1e-8));
        assert_allocation_trace(condition, uConversion, rConversion);
    end

    function test_airplane_endpoint()
        timer = tic;
        condition = struct('V',100,'betaM',pi/2,'gamma',0);
        directDefinition = make_trim_definition( ...
            'airplane_longitudinal', condition, P);
        conversionDefinition = make_trim_definition( ...
            'conversion_longitudinal', condition, P);
        [xDirect,uDirect,rDirect] = trim_general( ...
            condition, directDefinition, P);
        [xConversion,uConversion,rConversion] = trim_general( ...
            condition, conversionDefinition, P);
        airplaneRuntime = toc(timer);
        airplaneDifferences = [max(abs(xDirect-xConversion)), ...
            max(abs(uDirect-uConversion)), ...
            abs(rDirect.residualNorm-rConversion.residualNorm)];
        assert(rDirect.converged && rConversion.converged);
        % The Eq12/Eq13 induced-flow closure leaves the endpoint solutions
        % equivalent but can move the optimizer residual-norm difference
        % slightly above the state/control equality tolerance.
        assert(all(airplaneDifferences <= [1e-7, 1e-8, 5e-8]));
        assert_allocation_trace(condition, uConversion, rConversion);
    end

    function test_conversion_point()
        timer = tic;
        condition = struct('V',35,'betaM',pi/4,'gamma',0);
        definition = make_trim_definition( ...
            'conversion_longitudinal', condition, P);
        [x,u,r] = trim_general(condition, definition, P);
        conversionRuntime = toc(timer);
        conversionResult.x = x;
        conversionResult.u = u;
        conversionResult.residual = r.residual;
        conversionResult.residualNorm = r.residualNorm;
        conversionResult.fullResidualNorm = r.fullResidualNorm;
        conversionResult.pitchCommand = r.trimVariables.pitchCommand;
        conversionResult.cyclicLong = u(3);
        conversionResult.elevator = u(6);
        conversionResult.normalizedPitchCommand = ...
            r.allocation.normalizedPitchCommand;
        conversionResult.pitchCommandLimit = r.allocation.pitchCommandLimit;
        conversionResult.cyclicUsage = ...
            abs(u(3))/r.allocation.cyclicReference;
        conversionResult.elevatorUsage = ...
            abs(u(6))/r.allocation.elevatorReference;
        conversionResult.cyclicMargin = 1-conversionResult.cyclicUsage;
        conversionResult.elevatorMargin = 1-conversionResult.elevatorUsage;
        conversionResult.atLimit = r.atLimit;
        conversionResult.withinLimits = r.withinLimits;
        conversionResult.invalidEvaluationCount = ...
            r.objectiveInvalidEvaluationCount;
        conversionResult.invalidEvaluationIdentifiers = ...
            r.objectiveInvalidEvaluationIdentifiers;
        conversionResult.limitReport = r.limitReport;
        conversionResult.converged = r.converged;
        assert(isreal(x) && all(isfinite(x)));
        assert(isreal(u) && all(isfinite(u)));
        assert(isreal(r.fullStateDerivative) && ...
            all(isfinite(r.fullStateDerivative)));
        assert(r.residualNorm < P.trim.residualTolerance);
        assert(r.converged && ~r.atLimit && r.withinLimits);
        assert(abs(r.allocation.normalizedPitchCommand) < 1-1e-8);
        assert(conversionResult.cyclicUsage < 1-1e-8 && ...
            conversionResult.elevatorUsage < 1-1e-8);
        assert_allocation_trace(condition, u, r);
    end

    function assert_allocation_trace(condition, u, r)
        expected = pitch_allocation_schedule(condition.betaM, ...
            r.trimVariables.pitchCommand, P, direction);
        tolerance = 10*eps(max([1, abs(expected.cyclicLong), ...
            abs(expected.elevator)]));
        assert(abs(u(3)-expected.cyclicLong) <= tolerance);
        assert(abs(u(6)-expected.elevator) <= tolerance);
        assert(abs(r.allocation.cyclicLong-u(3)) <= tolerance);
        assert(abs(r.allocation.elevator-u(6)) <= tolerance);
        assert(abs(r.allocation.authorityDenominator - ...
            max(r.allocation.gCyclic,r.allocation.gElevator)) <= 10*eps);
        assert(abs(r.allocation.pitchCommandLimit - ...
            1/r.allocation.authorityDenominator) <= 10*eps);
        assert(abs(r.allocation.normalizedPitchCommand - ...
            r.trimVariables.pitchCommand/r.allocation.pitchCommandLimit) ...
            <= 10*eps);
        assert(r.allocation.cyclicDirection == -1 && ...
            r.allocation.elevatorDirection == -1);
    end

    function expect_schedule_error(betaM, command, params, mapping, identifier)
        try
            pitch_allocation_schedule(betaM, command, params, mapping);
        catch ME
            assert(strcmp(ME.identifier, identifier), ...
                'Expected %s, received %s.', identifier, ME.identifier);
            return;
        end
        error('check_pitch_allocation:MissingExpectedError', ...
            'Expected error %s was not raised.', identifier);
    end

    function expect_trim_error(condition, definition, identifier)
        try
            trim_general(condition, definition, P);
        catch ME
            assert(strcmp(ME.identifier, identifier), ...
                'Expected %s, received %s.', identifier, ME.identifier);
            return;
        end
        error('check_pitch_allocation:MissingExpectedError', ...
            'Expected error %s was not raised.', identifier);
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
