function report = check_berger13_pr4_research()
%CHECK_BERGER13_PR4_RESEARCH Focused modal/tracking/time-domain checks.

P13 = params_berger13();
d2r = pi/180;
condition = struct('V',35,'betaM',45*d2r,'gamma',0);
[~,~,torqueTrim] = trim_berger13_symmetric(condition,P13, ...
    struct('mode','conversion_longitudinal'));
[~,~,commandTrim] = trim_berger13_command_symmetric(condition,P13, ...
    struct('mode','conversion_longitudinal', ...
    'torqueTrimReport',torqueTrim));
linearModel = linearize_berger13_command_trim_point(commandTrim,P13);
A = linearModel.symdiff.A;
B = linearModel.symdiff.B;
stateNames = linearModel.symdiff.stateNames;
inputNames = get_command_input_names_13x10();
inputNames(9:10) = {'betaSymCommand';'betaDiffCommand'};
modal = analyze_berger13_modes(A,B,stateNames,inputNames);

names = {};
passed = [];
messages = {};
run_case('biorthogonal eigenvectors and finite modal metrics',@case_modal);
run_case('participation normalization and nacelle modes',@case_participation);
run_case('Hungarian global assignment optimum',@case_hungarian);
run_case('adjacent identical model tracking',@case_tracking);
run_case('short nonlinear command simulation finite',@case_simulation);
run_case('linear/nonlinear comparison has ten states',@case_comparison);

report.names = names;
report.passed = passed;
report.messages = messages;
report.allPassed = all(passed);
fprintf('\nBerger13 PR4 research workflow checks\n');
fprintf('=====================================\n');
for k = 1:numel(names)
    fprintf('%-55s : %s\n',names{k},ternary(passed(k),'PASS','FAIL'));
    if ~passed(k)
        fprintf('  %s\n',messages{k});
    end
end
fprintf('All passed: %d\n',report.allPassed);

    function case_modal()
        assert(modal.biorthogonalityError < 1e-8);
        assert(all(isfinite(real(modal.eigenvalues))));
        assert(height(modal.table) == 13);
    end

    function case_participation()
        assert(max(abs(sum(modal.participation,1)-1)) < 1e-12);
        assert(any(modal.table.betaSymParticipation > 0.4));
        assert(any(modal.table.betaDiffParticipation > 0.4));
    end

    function case_hungarian()
        cost = [4,1,3;2,0,5;3,2,2];
        assignment = hungarian_assignment(cost);
        rows = (1:3).';
        linearIndex = sub2ind([3,3],rows,assignment);
        assert(sum(cost(linearIndex)) == 5);
    end

    function case_tracking()
        tracking = track_berger13_modes({modal,modal},{'P1','P2'});
        second = tracking.table(strcmp(tracking.table.pointId,'P2'),:);
        assert(all(second.matchingConfidence > 0.99));
        assert(numel(unique(second.modeId)) == 13);
    end

    function case_simulation()
        caseDef = base_case('short-symmetric-step','betaSym',0.02*d2r);
        caseDef.duration = 0.20;
        caseDef.dt = 0.05;
        caseDef.startTime = 0.05;
        sim = simulate_berger13_case(commandTrim,P13,caseDef);
        assert(sim.finiteReal && ~sim.diverged);
        assert(size(sim.x,2) == 13);
        metricNames = fieldnames(sim.metrics);
        for metricIndex = 1:numel(metricNames)
            metric = sim.metrics.(metricNames{metricIndex});
            assert(isscalar(metric) && isreal(metric), ...
                'Every archived simulation metric must be a real scalar.');
        end
    end

    function case_comparison()
        caseDef = base_case('short-differential-step','betaDiff',0.01*d2r);
        caseDef.duration = 0.20;
        caseDef.dt = 0.05;
        caseDef.startTime = 0.05;
        comparison = compare_berger13_linear_nonlinear( ...
            commandTrim,linearModel,P13,caseDef);
        assert(width(comparison.metrics) == 4);
        assert(height(comparison.metrics) == 10);
        assert(all(isfinite(comparison.metrics.rmsError)));
    end

    function value = base_case(name,inputType,amplitude)
        value = struct('name',name,'duration',1,'dt',0.05, ...
            'inputType',inputType,'amplitude',amplitude,'startTime',0.1);
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

function value = ternary(condition,yesValue,noValue)
if condition
    value = yesValue;
else
    value = noValue;
end
end
