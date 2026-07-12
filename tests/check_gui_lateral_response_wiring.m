function report = check_gui_lateral_response_wiring()
%CHECK_GUI_LATERAL_RESPONSE_WIRING Verify opt-in lateralCyclic response path.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir,'model'));
addpath(fullfile(rootDir,'analysis'));
addpath(fullfile(rootDir,'services'));

d2r = pi/180;
P = params_nominal();
names = {};
passed = [];
messages = {};

run_case('legacy response controls exclude lateralCyclic', @check_legacy_controls);
run_case('eight-input linearization exposes lateralCyclic B column', @check_linearization);
run_case('linear response accepts lateralCyclic channel', @check_response);

report.names = names;
report.passed = passed;
report.messages = messages;
report.allPassed = all(passed);

fprintf('\nGUI lateralCyclic response wiring checks\n');
fprintf('========================================\n');
for k = 1:numel(names)
    fprintf('%-48s : %s\n', names{k}, ternary(passed(k),'PASS','FAIL'));
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

    function check_legacy_controls()
        controls = get_control_input_names(P);
        assert(numel(controls) == 7);
        assert(~any(strcmp(controls, 'lateralCyclic')));
    end

    function check_linearization()
        [linearResult, ~] = make_linear_result();
        assert(isequal(size(linearResult.B), [9, 8]));
        assert(strcmp(linearResult.controlNames{5}, 'lateralCyclic'));
        assert(norm(linearResult.B(:,5)) > 1e-8);
    end

    function check_response()
        [linearResult, P8] = make_linear_result();
        config = struct( ...
            'controlChannel',5, ...
            'waveform','step', ...
            'amplitudeDeg',0.25, ...
            'startTime',0.05, ...
            'duration',0.1, ...
            'frequencyHz',1.0, ...
            'totalTime',0.2, ...
            'timeStep',0.02, ...
            'outputState',2);
        response = simulate_linear_response(linearResult, config, P8);
        assert(response.success);
        assert(size(response.deltaControl,2) == 8);
        assert(strcmp(response.controlNames{5}, 'lateralCyclic'));
        assert(all(isfinite(response.deltaState(:))));
        assert(abs(max(response.deltaControl(:,5))-0.25*d2r) < 1e-12);
    end

    function [linearResult, P8] = make_linear_result()
        P8 = write_parameter_value(P, 'control.enableLateralCyclic', 1);
        betaM = pi/2;
        x = [40;0;0;0;0;0;0;0;0];
        u = [8*d2r;0;0;0;0;0;-2*d2r;0];
        [A,B,rep] = linearize_numeric(x, u, betaM, P8);
        assert(rep.finite);
        trimResult = struct('xTrim',x,'uTrim',u,'betaM',betaM,'success',true);
        linearResult = struct('A',A,'B',B,'trim',trimResult, ...
            'success',true,'stateNames',{get_state_names(P8)}, ...
            'controlNames',{get_control_input_names(P8)});
    end
end

function value = ternary(condition,a,b)
if condition
    value = a;
else
    value = b;
end
end
