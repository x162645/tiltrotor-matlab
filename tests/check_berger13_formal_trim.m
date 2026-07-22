function report = check_berger13_formal_trim()
%CHECK_BERGER13_FORMAL_TRIM Focused PR2 trim and coordinate checks.

P13 = params_berger13();
d2r = pi/180;
condition = struct('V',35,'betaM',45*d2r,'gamma',0);
opts = struct('mode','conversion_longitudinal', ...
    'runMultipleSeeds',true);
[x13,u10,trimReport] = trim_berger13_symmetric(condition,P13,opts);

names = {};
passed = [];
messages = {};
run_case('formal 13-state dimensions and finite values', @case_dimensions);
run_case('full dynamic-equilibrium substitution', @case_substitution);
run_case('multiple-seed convergence and sensitivity', @case_multiseed);
run_case('static torque and symmetric nacelle constraints', @case_static);
run_case('continuation to neighboring speed', @case_continuation);
run_case('symmetric/differential transform invertibility', @case_transform);
run_case('credible-point three-step linearization', @case_linearization);
run_case('noncredible point rejected', @case_rejection);
run_case('legacy nine-state point remains identical', @case_legacy);

report.names = names;
report.passed = passed;
report.messages = messages;
report.allPassed = all(passed);
report.trimStatus = trimReport.status;
report.residualNorm = trimReport.dynamicResidualNorm;
report.conditionNumber = trimReport.conditionNumber;
report.minimumMargin = trimReport.minimumUnknownMarginFraction;
fprintf('\nBerger13 PR2 formal trim checks\n');
fprintf('================================\n');
for k = 1:numel(names)
    fprintf('%-52s : %s\n',names{k},ternary(passed(k),'PASS','FAIL'));
    if ~passed(k)
        fprintf('  %s\n',messages{k});
    end
end
fprintf('Status=%s residual=%.3e cond=%.3e margin=%.3f\n', ...
    trimReport.status, trimReport.dynamicResidualNorm, ...
    trimReport.conditionNumber, trimReport.minimumUnknownMarginFraction);
fprintf('All passed: %d\n',report.allPassed);

    function case_dimensions()
        assert(isequal(size(x13),[13,1]) && isequal(size(u10),[10,1]));
        assert(isreal(x13) && all(isfinite(x13)));
        assert(isreal(u10) && all(isfinite(u10)));
        assert(strcmp(trimReport.status,'CREDIBLE'));
    end

    function case_substitution()
        [xdot,out] = tiltrotor_eom_13x10(x13,u10,P13);
        assert(max(abs(xdot([1:6,10:13]))) < ...
            10*P13.base.trim.residualTolerance);
        assert(norm(out.Ftotal-trimReport.forceBalanceBody) < 1e-9);
        assert(norm(out.Mtotal-trimReport.momentBalanceBody) < 1e-9);
    end

    function case_multiseed()
        assert(numel(trimReport.seedResults) == 3);
        assert(trimReport.initialConditionSensitivity.numberOfFiniteSeeds >= 2);
        assert(trimReport.initialConditionSensitivity. ...
            maximumNormalizedDifference < 0.25);
    end

    function case_static()
        assert(norm(u10(9:10),inf) == 0);
        assert(norm(x13(10)-x13(11),inf) == 0);
        assert(norm(x13(12:13),inf) == 0);
        assert(norm(trimReport.fullStateDerivative(10:13),inf) == 0);
    end

    function case_continuation()
        nextCondition = condition;
        nextCondition.V = 36;
        nextOpts = struct('mode','conversion_longitudinal', ...
            'initialValues',trimReport.trimVariableVector);
        [~,~,nextReport] = trim_berger13_symmetric( ...
            nextCondition,P13,nextOpts);
        assert(strcmp(nextReport.status,'CREDIBLE'));
        assert(nextReport.continuation.usedInitialValues);
    end

    function case_transform()
        T = berger13_symdiff_transform([],[]);
        assert(T.invertibilityError < 1e-12);
        xsd = T.Tstate*x13;
        assert(abs(xsd(10)-condition.betaM) < 1e-12);
        assert(abs(xsd(11)) < 1e-12);
    end

    function case_linearization()
        linearModel = linearize_berger13_trim_point(trimReport,P13);
        assert(isequal(size(linearModel.A13),[13,13]));
        assert(isequal(size(linearModel.B13Torque),[13,10]));
        assert(linearModel.finiteReal);
        assert(linearModel.maximumRelativeStepVariation < 1e-2);
        assert(norm(linearModel.symdiff.Tstate*linearModel.A13* ...
            linearModel.symdiff.TstateInverse- ...
            linearModel.symdiff.A,'fro') < 1e-10);
    end

    function case_rejection()
        rejected = trimReport;
        rejected.status = 'ILL_CONDITIONED';
        gotExpected = false;
        try
            linearize_berger13_trim_point(rejected,P13);
        catch ME
            gotExpected = strcmp(ME.identifier, ...
                'linearize_berger13_trim_point:NonCrediblePoint');
        end
        assert(gotExpected);
    end

    function case_legacy()
        definition = make_trim_definition( ...
            'conversion_longitudinal',condition,P13.base);
        [x9,u7] = trim_general(condition,definition,P13.base);
        assert(norm(x13(1:9)-x9,inf) < 1e-8);
        assert(norm([u10(1:4);u10(6:8)]-u7,inf) < 1e-8);
    end

    function run_case(name,fun)
        names{end+1,1} = name;
        try
            fun();
            passed(end+1,1) = true;
            messages{end+1,1} = '';
        catch ME
            passed(end+1,1) = false;
            messages{end+1,1} = ME.message;
        end
    end
end

function value = ternary(condition, yesValue, noValue)
if condition
    value = yesValue;
else
    value = noValue;
end
end
