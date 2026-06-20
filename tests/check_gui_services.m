function report = check_gui_services()
%CHECK_GUI_SERVICES Focused non-graphical checks for the analysis workbench.
% This test exercises service APIs without opening a uifigure.

P = params_nominal();
trimResult = [];
linearResult = [];
responseResult = [];
names = {};
passed = [];
messages = {};

run_check('default parameter validation', @check_default_parameters);
run_check('invalid parameter rejection', @check_invalid_parameter_rejection);
run_check('invalid inertia rejection', @check_invalid_inertia_rejection);
run_check('invalid step and limit rejection', @check_invalid_step_limit_rejection);
run_check('hover trim service', @check_hover_trim);
run_check('trim-point linearization service', @check_linearization);
run_check('linear response service', @check_response);
run_check('response waveform timing', @check_response_waveforms);
run_check('response limit warning', @check_response_limit_warning);
run_check('analysis session export', @check_export);
run_check('application entry points', @check_entry_points);

report.names = names;
report.passed = passed;
report.messages = messages;
report.allPassed = all(passed);
report.trim = trimResult;
report.linearization = linearResult;
report.response = responseResult;

fprintf('\nGUI/service checks\n');
fprintf('==================\n');
for k = 1:numel(names)
    fprintf('%-38s : %s\n',names{k},ternary(passed(k),'PASS','FAIL'));
    if ~passed(k)
        fprintf('  %s\n',messages{k});
    end
end
fprintf('All passed: %d\n',report.allPassed);

    function run_check(name,fun)
        names{end+1,1} = name;
        try
            fun();
            passed(end+1,1) = true;
            messages{end+1,1} = '';
        catch ME
            passed(end+1,1) = false;
            messages{end+1,1} = sprintf('%s: %s',ME.identifier,ME.message);
        end
    end

    function check_default_parameters()
        validation = validate_parameter_set(P);
        assert(validation.valid, strjoin(validation.errors,newline));
    end

    function check_invalid_parameter_rejection()
        badP = P;
        badP.mass.m = -1;
        validation = validate_parameter_set(badP);
        assert(~validation.valid, ...
            'Negative total mass should fail parameter validation.');
    end

    function check_invalid_inertia_rejection()
        badP = P;
        badP.mass.I0(1,2) = 10;
        validation = validate_parameter_set(badP);
        assert(~validation.valid, ...
            'Non-symmetric inertia should fail parameter validation.');

        badP = P;
        badP.mass.I0(1,1) = -1;
        validation = validate_parameter_set(badP);
        assert(~validation.valid, ...
            'Non-positive-definite inertia should fail parameter validation.');
    end

    function check_invalid_step_limit_rejection()
        badP = P;
        badP.linear.du(3) = 0;
        validation = validate_parameter_set(badP);
        assert(~validation.valid, ...
            'Zero linearization control step should fail parameter validation.');

        badP = P;
        badP.control.cyclicLim = [1 1];
        validation = validate_parameter_set(badP);
        assert(~validation.valid, ...
            'Non-increasing cyclic limits should fail parameter validation.');
    end

    function check_hover_trim()
        config = struct( ...
            'V',0, ...
            'betaMDeg',0, ...
            'gammaDeg',0, ...
            'initialThetaDeg',0, ...
            'initialCollectiveDeg',18, ...
            'initialCyclicLongDeg',0, ...
            'thetaLimitDeg',35, ...
            'useMultiStart',false, ...
            'alwaysMultiStart',false);
        trimResult = run_trim_case(config,P);
        assert(trimResult.success, ...
            'Default hover trim did not satisfy the service acceptance criteria.');
        assert(numel(trimResult.xTrim) == 9);
        assert(numel(trimResult.uTrim) == 7);
        assert(isreal(trimResult.xTrim) && all(isfinite(trimResult.xTrim)));
        assert(isreal(trimResult.uTrim) && all(isfinite(trimResult.uTrim)));
    end

    function check_linearization()
        assert(~isempty(trimResult), 'Hover trim check must run first.');
        linearResult = run_linearization_case(trimResult,P);
        assert(linearResult.success);
        assert(isequal(size(linearResult.A),[9,9]));
        assert(isequal(size(linearResult.B),[9,7]));
        assert(all(isfinite(linearResult.A(:))));
        assert(all(isfinite(linearResult.B(:))));
        assert(numel(linearResult.eigenvalues) == 9);
    end

    function check_response()
        assert(~isempty(linearResult), 'Linearization check must run first.');
        config = struct( ...
            'controlChannel',3, ...
            'waveform','step', ...
            'amplitudeDeg',0.1, ...
            'startTime',0.1, ...
            'duration',0.2, ...
            'frequencyHz',0.5, ...
            'totalTime',0.5, ...
            'timeStep',0.05, ...
            'outputState',8);
        responseResult = simulate_linear_response(linearResult,config,P);
        assert(responseResult.success);
        assert(size(responseResult.deltaState,2) == 9);
        assert(size(responseResult.deltaControl,2) == 7);
        assert(size(responseResult.deltaState,1) == numel(responseResult.time));
        assert(all(isfinite(responseResult.deltaState(:))));
        assert(norm(responseResult.deltaState(1,:)) < 1e-12);
        assert(abs(max(responseResult.deltaControl(:,3))-0.1*pi/180) < 1e-12);
        expectedState = responseResult.deltaState + ...
            repmat(linearResult.trim.xTrim(:).', size(responseResult.deltaState,1), 1);
        expectedControl = responseResult.deltaControl + ...
            repmat(linearResult.trim.uTrim(:).', size(responseResult.deltaControl,1), 1);
        assert(max(abs(responseResult.actualState(:)-expectedState(:))) < 1e-12);
        assert(max(abs(responseResult.actualControl(:)-expectedControl(:))) < 1e-12);
    end

    function check_response_waveforms()
        assert(~isempty(linearResult), 'Linearization check must run first.');
        waveforms = {'step','pulse','sine','doublet'};
        for iWave = 1:numel(waveforms)
            config = struct( ...
                'controlChannel',3, ...
                'waveform',waveforms{iWave}, ...
                'amplitudeDeg',0.1, ...
                'startTime',0.1, ...
                'duration',0.2, ...
                'frequencyHz',2.0, ...
                'totalTime',0.4, ...
                'timeStep',0.05, ...
                'outputState',8);
            response = simulate_linear_response(linearResult,config,P);
            assert(response.success);
            assert(all(isfinite(response.deltaState(:))));
            signal = response.deltaControl(:,3);
            t = response.time;
            amp = 0.1*pi/180;
            switch waveforms{iWave}
                case 'step'
                    assert(all(abs(signal(t < 0.1)) < 1e-12));
                    assert(all(abs(signal(t >= 0.1)-amp) < 1e-12));
                case 'pulse'
                    assert(all(abs(signal(t < 0.1)) < 1e-12));
                    assert(all(abs(signal(t >= 0.1 & t <= 0.3)-amp) < 1e-12));
                    assert(all(abs(signal(t > 0.3)) < 1e-12));
                case 'sine'
                    expected = amp*sin(2*pi*2.0*(t-0.1)).*double(t >= 0.1 & t <= 0.3);
                    assert(max(abs(signal-expected)) < 1e-12);
                case 'doublet'
                    assert(all(abs(signal(t < 0.1)) < 1e-12));
                    assert(all(abs(signal(t >= 0.1 & t < 0.2)-amp) < 1e-12));
                    assert(all(abs(signal(t >= 0.2 & t <= 0.3)+amp) < 1e-12));
                    assert(all(abs(signal(t > 0.3)) < 1e-12));
            end
        end
    end

    function check_response_limit_warning()
        assert(~isempty(linearResult), 'Linearization check must run first.');
        config = struct( ...
            'controlChannel',3, ...
            'waveform','step', ...
            'amplitudeDeg',40, ...
            'startTime',0.0, ...
            'duration',0.1, ...
            'frequencyHz',0.5, ...
            'totalTime',0.1, ...
            'timeStep',0.05, ...
            'outputState',8);
        response = simulate_linear_response(linearResult,config,P);
        assert(response.limitWarning, ...
            'Large cyclic command should trigger a control-limit warning.');
    end

    function check_export()
        assert(~isempty(trimResult), 'Trim check must run first.');
        assert(~isempty(linearResult), 'Linearization check must run first.');
        assert(~isempty(responseResult), 'Response check must run first.');
        filePath = fullfile(pwd, 'results', 'gui_service_export_check.mat');
        session = struct('parameters',P, ...
            'trim',trimResult, ...
            'linearization',linearResult, ...
            'response',responseResult);
        save_analysis_case(filePath, session);
        loaded = load(filePath, 'session');
        delete(filePath);
        assert(isfield(loaded, 'session'));
        assert(isfield(loaded.session, 'parameters'));
        assert(isfield(loaded.session, 'trim'));
        assert(isfield(loaded.session, 'linearization'));
        assert(isfield(loaded.session, 'response'));
    end

    function check_entry_points()
        assert(exist('launch_tiltrotor_app','file') == 2, ...
            'launch_tiltrotor_app.m is not on the MATLAB path.');
        assert(exist('run_app','file') == 2, ...
            'run_app.m is not on the MATLAB path.');
    end
end

function value = ternary(condition,a,b)
if condition
    value = a;
else
    value = b;
end
end
