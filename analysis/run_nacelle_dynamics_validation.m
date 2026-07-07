function result = run_nacelle_dynamics_validation(config)
%RUN_NACELLE_DYNAMICS_VALIDATION Reproducible Phase 1 nacelle checks.
% This workflow validates the opt-in symmetric nacelle dynamic-state
% extension. It is not a Berger 51-state reproduction and it is not a
% complete conversion-flight simulation.

if nargin < 1 || isempty(config)
    config = struct();
end

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir, 'model'));
addpath(fullfile(rootDir, 'analysis'));
addpath(fullfile(rootDir, 'services'));

config = apply_defaults(config, rootDir);

if config.writeFiles && ~exist(config.outputDir, 'dir')
    mkdir(config.outputDir);
end

d2r = pi/180;
r2d = 180/pi;
P = params_nominal();
Pdyn = P;
Pdyn.nacelleDynamics.enabled = true;

checks = {};
passed = [];
messages = {};

legacyRows = run_legacy_checks();
actuator = run_actuator_checks();
equivalenceRows = run_quasi_static_equivalence();
linearRows = run_linearization_checks();
response = run_dynamic_response_demo();

add_check('legacy default remains 9-state', all([legacyRows.pass]));
add_check('actuator responses are finite and bounded', all([actuator.pass]));
add_check('11-state quasi-static EOM matches legacy first 9 states', ...
    all([equivalenceRows.pass]));
add_check('11-state linearization returns finite 11x11 and 11x7 matrices', ...
    all([linearRows.pass]));
add_check('open-loop response demo is finite real', response.pass);

result.timestamp = config.timestamp;
result.outputDir = config.outputDir;
result.legacy = legacyRows;
result.actuator = actuator;
result.quasiStaticEquivalence = equivalenceRows;
result.linearization = linearRows;
result.dynamicResponse = response;
result.names = checks;
result.passed = passed;
result.messages = messages;
result.allPassed = all(passed);

if config.writeFiles
    write_outputs(result);
end

fprintf('\nNacelle dynamics validation\n');
fprintf('===========================\n');
fprintf('Output directory: %s\n', config.outputDir);
for i = 1:numel(checks)
    fprintf('%-64s : %s\n', checks{i}, ternary(passed(i), 'PASS', 'FAIL'));
    if ~passed(i)
        fprintf('  %s\n', messages{i});
    end
end
fprintf('All nacelle dynamics validation checks passed: %d\n', result.allPassed);

    function legacyRows = run_legacy_checks()
        betaM = 45*d2r;
        x9 = representative_state(30, 0.02);
        uCtrl = representative_control();
        fLegacy = tiltrotor_eom(x9, uCtrl, betaM, P);
        Pdisabled = P;
        Pdisabled.nacelleDynamics.enabled = false;
        fDisabled = tiltrotor_eom(x9, uCtrl, betaM, Pdisabled);
        maxDiff = max(abs(fLegacy(:)-fDisabled(:)));

        legacyRows = struct_array_row('caseName', ...
            {'default parameter'; 'disabled EOM invariance'; ...
             'default trim dimension'; 'default linearization dimension'}, ...
            'stateDimension', {get_state_dimension(P); numel(x9); NaN; NaN}, ...
            'eomLength', {NaN; numel(fDisabled); NaN; NaN}, ...
            'maxAbsDiff', {NaN; maxDiff; NaN; NaN}, ...
            'pass', {get_state_dimension(P) == 9; ...
                numel(fDisabled) == 9 && maxDiff == 0; false; false}, ...
            'note', {'P.nacelleDynamics.enabled defaults false'; ...
                'Exact same legacy call when disabled'; ...
                'trim_symmetric default path'; ...
                'linearize_numeric default path'});

        trimOpts = struct('useMultiStart', false, ...
            'alwaysMultiStart', false, 'initialDeg', [0, 18, 0]);
        [xTrim, uTrim] = trim_symmetric(0, 0, P, trimOpts);
        legacyRows(3).stateDimension = numel(xTrim);
        legacyRows(3).eomLength = numel(tiltrotor_eom(xTrim, uTrim, 0, P));
        legacyRows(3).pass = numel(xTrim) == 9 && legacyRows(3).eomLength == 9;

        [A, B, linReport] = linearize_numeric(x9, uCtrl, betaM, P);
        legacyRows(4).stateDimension = size(A, 1);
        legacyRows(4).eomLength = numel(linReport.f0);
        legacyRows(4).maxAbsDiff = NaN;
        legacyRows(4).pass = isequal(size(A), [9, 9]) && ...
            isequal(size(B), [9, 7]) && linReport.finite;
    end

    function actuator = run_actuator_checks()
        if config.quick
            stepCases = [0, 90; 30, 120; 60, -20];
        else
            stepCases = [0, 90; 90, 0; 30, 45; 30, 120; 60, -20];
        end
        t = 0:config.actuatorTimeStep:config.actuatorDuration;
        rigid = representative_state(30, 0);
        uCtrl = representative_control();
        rateLimit = Pdyn.nacelleDynamics.rateLimitDegPerSec;
        betaMin = Pdyn.nacelleDynamics.betaMinDeg;
        betaMax = Pdyn.nacelleDynamics.betaMaxDeg;
        angleToleranceDeg = 0.1;
        rows = repmat(struct('caseName', '', 'initialDeg', NaN, ...
            'commandDeg', NaN, 'clampedCommandDeg', NaN, ...
            'minBetaDeg', NaN, 'maxBetaDeg', NaN, ...
            'maxBetaDotDegPerSec', NaN, 'maxRateStateDegPerSec', NaN, ...
            'equilibriumBetaDDot', NaN, ...
            'finiteReal', false, 'pass', false), size(stepCases, 1), 1);
        traces = [];

        for iCase = 1:size(stepCases, 1)
            initialDeg = stepCases(iCase, 1);
            commandDeg = stepCases(iCase, 2);
            clampedCommandDeg = min(max(commandDeg, betaMin), betaMax);
            Pcase = Pdyn;
            Pcase.nacelleDynamics.commandDeg = commandDeg;
            xN0 = [initialDeg*d2r; 0];
            betaArg = initialDeg*d2r;
            [~, xN] = ode45(@(time, xNac) nacelle_only_derivative( ...
                xNac, rigid, uCtrl, betaArg, Pcase), t, xN0);
            betaDeg = xN(:,1)*r2d;
            betaRateStateDeg = xN(:,2)*r2d;
            betaDotDeg = sample_beta_dot(t, xN, rigid, uCtrl, betaArg, Pcase);
            errorDeg = clampedCommandDeg - betaDeg;
            finiteReal = is_real_finite(xN);

            feq = tiltrotor_eom([rigid; clampedCommandDeg*d2r; 0], ...
                uCtrl, clampedCommandDeg*d2r, Pcase);
            betaDDotEq = feq(11);

            pass = finiteReal && min(betaDeg) >= betaMin-angleToleranceDeg && ...
                max(betaDeg) <= betaMax+angleToleranceDeg && ...
                max(abs(betaDotDeg)) <= rateLimit+1e-6 && ...
                abs(betaDDotEq) < 1e-10;

            rows(iCase).caseName = sprintf('%g_to_%g_deg', ...
                initialDeg, commandDeg);
            rows(iCase).initialDeg = initialDeg;
            rows(iCase).commandDeg = commandDeg;
            rows(iCase).clampedCommandDeg = clampedCommandDeg;
            rows(iCase).minBetaDeg = min(betaDeg);
            rows(iCase).maxBetaDeg = max(betaDeg);
            rows(iCase).maxBetaDotDegPerSec = max(abs(betaDotDeg));
            rows(iCase).maxRateStateDegPerSec = max(abs(betaRateStateDeg));
            rows(iCase).equilibriumBetaDDot = betaDDotEq;
            rows(iCase).finiteReal = finiteReal;
            rows(iCase).pass = pass;

            trace.caseIndex = iCase*ones(numel(t), 1);
            trace.time = t(:);
            trace.betaCommandDeg = clampedCommandDeg*ones(numel(t), 1);
            trace.betaDeg = betaDeg(:);
            trace.betaDotDegPerSec = betaDotDeg(:);
            trace.betaRateStateDegPerSec = betaRateStateDeg(:);
            trace.errorDeg = errorDeg(:);
            traces = append_trace(traces, trace);
        end

        actuator.rows = rows;
        actuator.traces = traces;
        actuator.pass = [rows.pass];
    end

    function rows = run_quasi_static_equivalence()
        if config.quick
            betaDegValues = [15, 45, 75];
            speeds = [30, 70];
        else
            betaDegValues = [0, 15, 45, 75, 90];
            speeds = [10, 30, 70, 100];
        end
        uCtrl = representative_control();
        rows = repmat(struct('caseName', '', 'V', NaN, 'betaMDeg', NaN, ...
            'maxAbsDiff', NaN, 'relativeDiff', NaN, 'endpointRisk', '', ...
            'pass', false), numel(betaDegValues)*numel(speeds), 1);
        k = 0;
        for iBeta = 1:numel(betaDegValues)
            for iV = 1:numel(speeds)
                k = k + 1;
                betaM = betaDegValues(iBeta)*d2r;
                x9 = representative_state(speeds(iV), 0);
                Pcase = Pdyn;
                Pcase.nacelleDynamics.commandDeg = [];
                f9 = tiltrotor_eom(x9, uCtrl, betaM, P);
                f11 = tiltrotor_eom([x9; betaM; 0], uCtrl, betaM, Pcase);
                diff9 = f11(1:9) - f9;
                maxAbs = max(abs(diff9));
                rel = maxAbs/max(norm(f9), 1);
                endpointRisk = '';
                if betaDegValues(iBeta) == 0 || betaDegValues(iBeta) == 90
                    endpointRisk = 'endpoint clamp: medium linearization risk';
                end
                rows(k).caseName = sprintf('V%g_beta%g', ...
                    speeds(iV), betaDegValues(iBeta));
                rows(k).V = speeds(iV);
                rows(k).betaMDeg = betaDegValues(iBeta);
                rows(k).maxAbsDiff = maxAbs;
                rows(k).relativeDiff = rel;
                rows(k).endpointRisk = endpointRisk;
                rows(k).pass = maxAbs < 1e-10 && is_real_finite(f11);
            end
        end
    end

    function rows = run_linearization_checks()
        if config.quick
            betaDegValues = 45;
            speeds = 70;
        else
            betaDegValues = [15, 45, 75];
            speeds = 70;
        end
        uCtrl = representative_control();
        rows = repmat(struct('caseName', '', 'V', NaN, 'betaMDeg', NaN, ...
            'sizeA', '', 'sizeB', '', 'finiteReal', false, ...
            'f0Norm', NaN, 'pass', false), ...
            numel(betaDegValues)*numel(speeds), 1);
        k = 0;
        for iBeta = 1:numel(betaDegValues)
            for iV = 1:numel(speeds)
                k = k + 1;
                betaM = betaDegValues(iBeta)*d2r;
                x11 = [representative_state(speeds(iV), 0); betaM; 0];
                Pcase = Pdyn;
                Pcase.nacelleDynamics.commandDeg = [];
                [A, B, linReport] = linearize_numeric(x11, uCtrl, betaM, Pcase);
                finiteReal = linReport.finite && is_real_finite(A) && ...
                    is_real_finite(B);
                rows(k).caseName = sprintf('V%g_beta%g', ...
                    speeds(iV), betaDegValues(iBeta));
                rows(k).V = speeds(iV);
                rows(k).betaMDeg = betaDegValues(iBeta);
                rows(k).sizeA = sprintf('%dx%d', size(A, 1), size(A, 2));
                rows(k).sizeB = sprintf('%dx%d', size(B, 1), size(B, 2));
                rows(k).finiteReal = finiteReal;
                rows(k).f0Norm = norm(linReport.f0);
                rows(k).pass = isequal(size(A), [11, 11]) && ...
                    isequal(size(B), [11, 7]) && finiteReal;
            end
        end
    end

    function response = run_dynamic_response_demo()
        Pcase = Pdyn;
        Pcase.nacelleDynamics.commandDeg = config.responseCommandDeg;
        beta0 = config.responseInitialDeg*d2r;
        x0 = [representative_state(config.responseAirspeed, 0); beta0; 0];
        uCtrl = representative_control();
        t = 0:config.responseTimeStep:config.responseDuration;
        [~, x] = ode45(@(time, state) tiltrotor_eom( ...
            state, uCtrl, beta0, Pcase), t, x0);
        finiteReal = is_real_finite(x);
        betaDeg = x(:,10)*r2d;
        betaRateStateDeg = x(:,11)*r2d;
        betaDotDeg = sample_beta_dot(t, x(:,10:11), x(:,1:9), uCtrl, ...
            beta0, Pcase);
        response.time = t(:);
        response.state = x;
        response.betaCommandDeg = config.responseCommandDeg*ones(numel(t), 1);
        response.betaDeg = betaDeg(:);
        response.betaDotDegPerSec = betaDotDeg(:);
        response.betaRateStateDegPerSec = betaRateStateDeg(:);
        response.thetaDeg = x(:,8)*r2d;
        response.qDegPerSec = x(:,5)*r2d;
        response.u = x(:,1);
        response.w = x(:,3);
        response.fixedControls = uCtrl;
        response.initialBetaDeg = config.responseInitialDeg;
        response.commandDeg = config.responseCommandDeg;
        response.duration = config.responseDuration;
        response.pass = finiteReal && max(abs(betaDotDeg)) <= ...
            Pcase.nacelleDynamics.rateLimitDegPerSec + 1e-6;
        response.note = ['Open-loop representative-state response; not a ' ...
            'complete conversion-flight simulation.'];
    end

    function write_outputs(resultData)
        actuatorCsv = fullfile(config.outputDir, 'actuator_response.csv');
        responseCsv = fullfile(config.outputDir, 'dynamic_response_demo.csv');
        writetable(struct_trace_to_table(resultData.actuator.traces), ...
            actuatorCsv);
        writetable(response_to_table(resultData.dynamicResponse), responseCsv);
        save(fullfile(config.outputDir, 'nacelle_dynamics_validation.mat'), ...
            'resultData');

        if config.makePlots
            write_actuator_plot(resultData.actuator.traces, ...
                fullfile(config.outputDir, 'actuator_response.png'));
            write_response_plot(resultData.dynamicResponse, ...
                fullfile(config.outputDir, 'dynamic_response_demo.png'));
        end
        write_markdown_report(resultData, fullfile(config.outputDir, ...
            'NACELLE_DYNAMIC_VALIDATION_REPORT.md'));
    end

    function write_actuator_plot(traces, filePath)
        t = traces.time;
        fig = figure('Visible', 'off', 'Color', 'w');
        subplot(3,1,1);
        hold on;
        plot(t, traces.betaDeg, 'LineWidth', 1.0);
        plot(t, traces.betaCommandDeg, '--', 'LineWidth', 1.0);
        ylabel('betaM deg');
        grid on;
        subplot(3,1,2);
        plot(t, traces.betaDotDegPerSec, 'LineWidth', 1.0);
        ylabel('betaM dot deg/s');
        grid on;
        subplot(3,1,3);
        plot(t, traces.errorDeg, 'LineWidth', 1.0);
        xlabel('time s');
        ylabel('error deg');
        grid on;
        saveas(fig, filePath);
        close(fig);
    end

    function write_response_plot(responseData, filePath)
        fig = figure('Visible', 'off', 'Color', 'w');
        subplot(3,1,1);
        plot(responseData.time, responseData.betaDeg, 'LineWidth', 1.0);
        hold on;
        plot(responseData.time, responseData.betaCommandDeg, '--', ...
            'LineWidth', 1.0);
        ylabel('betaM deg');
        grid on;
        subplot(3,1,2);
        plot(responseData.time, responseData.betaDotDegPerSec, ...
            'LineWidth', 1.0);
        ylabel('betaM dot deg/s');
        grid on;
        subplot(3,1,3);
        plot(responseData.time, responseData.thetaDeg, 'LineWidth', 1.0);
        hold on;
        plot(responseData.time, responseData.qDegPerSec, 'LineWidth', 1.0);
        xlabel('time s');
        ylabel('theta / q');
        legend({'theta deg', 'q deg/s'}, 'Location', 'best');
        grid on;
        saveas(fig, filePath);
        close(fig);
    end

    function write_markdown_report(resultData, filePath)
        fid = fopen(filePath, 'w');
        if fid < 0
            error('run_nacelle_dynamics_validation:ReportOpenFailed', ...
                'Could not open report for writing: %s', filePath);
        end
        cleaner = onCleanup(@() fclose(fid));
        fprintf(fid, '# Nacelle Dynamics Validation Report\n\n');
        fprintf(fid, 'Generated: %s\n\n', resultData.timestamp);
        fprintf(fid, 'This report validates the Phase 1 opt-in symmetric ');
        fprintf(fid, 'nacelle dynamic-state extension. It is not a Berger ');
        fprintf(fid, '51-state reproduction and not a complete real ');
        fprintf(fid, 'conversion-flight simulation.\n\n');
        fprintf(fid, '## Scope\n\n');
        fprintf(fid, '- Default remains disabled: ');
        fprintf(fid, '`P.nacelleDynamics.enabled = false`.\n');
        fprintf(fid, '- Legacy 9-state path remains the main path.\n');
        fprintf(fid, '- Enabled path uses 11 states: ');
        fprintf(fid, '`[u v w p q r phi theta psi betaM betaM_dot]`.\n');
        fprintf(fid, '- betaM convention: 0 deg helicopter, ');
        fprintf(fid, '90 deg airplane.\n');
        fprintf(fid, '- 8 deg/s is used as the default nacelle-rate ');
        fprintf(fid, 'scale reference.\n');
        fprintf(fid, '- Endpoint betaM=0/90 deg linearization has ');
        fprintf(fid, 'medium clamp risk.\n\n');

        fprintf(fid, '## Legacy Default Checks\n\n');
        fprintf(fid, '| case | state dimension | EOM length | max abs diff | status |\n');
        fprintf(fid, '|---|---:|---:|---:|---|\n');
        for i = 1:numel(resultData.legacy)
            fprintf(fid, '| %s | %.0f | %.0f | %.3g | %s |\n', ...
                resultData.legacy(i).caseName, ...
                resultData.legacy(i).stateDimension, ...
                resultData.legacy(i).eomLength, ...
                resultData.legacy(i).maxAbsDiff, ...
                ternary(resultData.legacy(i).pass, 'PASS', 'FAIL'));
        end
        fprintf(fid, '\n## Actuator Checks\n\n');
        fprintf(fid, '| case | command deg | clamped command deg | ');
        fprintf(fid, 'min beta deg | max beta deg | max actual beta dot deg/s | max rate-state deg/s | status |\n');
        fprintf(fid, '|---|---:|---:|---:|---:|---:|---:|---|\n');
        rows = resultData.actuator.rows;
        for i = 1:numel(rows)
            fprintf(fid, '| %s | %.3g | %.3g | %.3g | %.3g | %.3g | %.3g | %s |\n', ...
                rows(i).caseName, rows(i).commandDeg, ...
                rows(i).clampedCommandDeg, rows(i).minBetaDeg, ...
                rows(i).maxBetaDeg, rows(i).maxBetaDotDegPerSec, ...
                rows(i).maxRateStateDegPerSec, ...
                ternary(rows(i).pass, 'PASS', 'FAIL'));
        end
        fprintf(fid, '\n`max actual beta dot` is the EOM output ');
        fprintf(fid, '`d(betaM)/dt`; the raw internal rate state is ');
        fprintf(fid, 'reported separately for diagnostics.\n');
        fprintf(fid, '\n![Actuator response](actuator_response.png)\n\n');

        fprintf(fid, '## Quasi-Static Equivalence\n\n');
        fprintf(fid, '| case | V m/s | betaM deg | max abs diff | relative diff | status | note |\n');
        fprintf(fid, '|---|---:|---:|---:|---:|---|---|\n');
        rows = resultData.quasiStaticEquivalence;
        for i = 1:numel(rows)
            fprintf(fid, '| %s | %.3g | %.3g | %.3g | %.3g | %s | %s |\n', ...
                rows(i).caseName, rows(i).V, rows(i).betaMDeg, ...
                rows(i).maxAbsDiff, rows(i).relativeDiff, ...
                ternary(rows(i).pass, 'PASS', 'FAIL'), rows(i).endpointRisk);
        end

        fprintf(fid, '\n## 11-State Linearization\n\n');
        fprintf(fid, '| case | A size | B size | finite real | f0 norm | status |\n');
        fprintf(fid, '|---|---|---|---|---:|---|\n');
        rows = resultData.linearization;
        for i = 1:numel(rows)
            fprintf(fid, '| %s | %s | %s | %d | %.3g | %s |\n', ...
                rows(i).caseName, rows(i).sizeA, rows(i).sizeB, ...
                rows(i).finiteReal, rows(i).f0Norm, ...
                ternary(rows(i).pass, 'PASS', 'FAIL'));
        end

        fprintf(fid, '\n## Dynamic Response Demonstration\n\n');
        fprintf(fid, 'The response uses a representative open-loop state ');
        fprintf(fid, 'and fixed controls. It only validates nacelle-dynamics ');
        fprintf(fid, 'connection and quasi-static aero/load variation with ');
        fprintf(fid, 'betaM. It does not represent complete real conversion ');
        fprintf(fid, 'flight; real conversion requires flight-control, pilot, ');
        fprintf(fid, 'and control-scheduling logic.\n\n');
        fprintf(fid, '![Dynamic response](dynamic_response_demo.png)\n\n');
        fprintf(fid, '## Non-Goals\n\n');
        fprintf(fid, '- No rCG_dot or rCG_ddot terms.\n');
        fprintf(fid, '- No I_dot*omega term.\n');
        fprintf(fid, '- No nacelle gyroscopic or torque reaction moments.\n');
        fprintf(fid, '- No left/right independent nacelle states.\n');
        fprintf(fid, '- No PID or torque actuator model.\n');
        fprintf(fid, '- No blade modal states or dynamic inflow states.\n');
        fprintf(fid, '- No closed-loop flight controller.\n');
        clear cleaner;
    end

    function dxN = nacelle_only_derivative(xNac, rigid, uCtrl, betaArg, Pcase)
        f = tiltrotor_eom([rigid; xNac(:)], uCtrl, betaArg, Pcase);
        dxN = f(10:11);
    end

    function betaDotDeg = sample_beta_dot(time, xNac, rigid, uCtrl, betaArg, Pcase)
        betaDotDeg = zeros(numel(time), 1);
        for iSample = 1:numel(time)
            if size(rigid, 1) == numel(time)
                rigidSample = rigid(iSample, :).';
            else
                rigidSample = rigid(:);
            end
            f = tiltrotor_eom([rigidSample; xNac(iSample, :).'], ...
                uCtrl, betaArg, Pcase);
            betaDotDeg(iSample) = f(10)*r2d;
        end
    end

    function x = representative_state(V, theta)
        x = [V; 0; 0; 0; 0; 0; 0; theta; 0];
    end

    function u = representative_control()
        u = [12*d2r; 0.25*d2r; 1.0*d2r; -0.1*d2r; ...
            0.2*d2r; -1.0*d2r; 0.1*d2r];
    end

    function add_check(name, condition, message)
        if nargin < 3
            message = '';
        end
        checks{end+1,1} = name;
        passed(end+1,1) = logical(condition);
        messages{end+1,1} = message;
    end
end

function config = apply_defaults(config, rootDir)
if ~isfield(config, 'timestamp') || isempty(config.timestamp)
    config.timestamp = datestr(now, 'yyyymmddTHHMMSS');
end
if ~isfield(config, 'writeFiles') || isempty(config.writeFiles)
    config.writeFiles = true;
end
if ~isfield(config, 'makePlots') || isempty(config.makePlots)
    config.makePlots = config.writeFiles;
end
if ~isfield(config, 'quick') || isempty(config.quick)
    config.quick = false;
end
if ~isfield(config, 'outputRoot') || isempty(config.outputRoot)
    config.outputRoot = fullfile(rootDir, 'validation', 'nacelle_dynamics');
end
if ~isfield(config, 'outputDir') || isempty(config.outputDir)
    config.outputDir = fullfile(config.outputRoot, config.timestamp);
end
if ~isfield(config, 'actuatorDuration') || isempty(config.actuatorDuration)
    config.actuatorDuration = 14.0;
end
if ~isfield(config, 'actuatorTimeStep') || isempty(config.actuatorTimeStep)
    config.actuatorTimeStep = 0.05;
end
if ~isfield(config, 'responseDuration') || isempty(config.responseDuration)
    config.responseDuration = 6.0;
end
if ~isfield(config, 'responseTimeStep') || isempty(config.responseTimeStep)
    config.responseTimeStep = 0.05;
end
if ~isfield(config, 'responseAirspeed') || isempty(config.responseAirspeed)
    config.responseAirspeed = 70.0;
end
if ~isfield(config, 'responseInitialDeg') || isempty(config.responseInitialDeg)
    config.responseInitialDeg = 15.0;
end
if ~isfield(config, 'responseCommandDeg') || isempty(config.responseCommandDeg)
    config.responseCommandDeg = 75.0;
end
end

function tf = is_real_finite(value)
tf = isreal(value) && all(isfinite(value(:)));
end

function value = ternary(condition, a, b)
if condition
    value = a;
else
    value = b;
end
end

function rows = struct_array_row(varargin)
names = varargin(1:2:end);
values = varargin(2:2:end);
n = numel(values{1});
rows = repmat(struct(), n, 1);
for i = 1:n
    for j = 1:numel(names)
        rows(i).(names{j}) = values{j}{i};
    end
end
end

function traces = append_trace(traces, trace)
if isempty(traces)
    traces = trace;
    return;
end
names = fieldnames(trace);
for i = 1:numel(names)
    traces.(names{i}) = [traces.(names{i}); trace.(names{i})];
end
end

function tbl = struct_trace_to_table(trace)
tbl = table(trace.caseIndex, trace.time, trace.betaCommandDeg, ...
    trace.betaDeg, trace.betaDotDegPerSec, trace.betaRateStateDegPerSec, ...
    trace.errorDeg, ...
    'VariableNames', {'caseIndex', 'time_s', 'betaCommand_deg', ...
    'betaM_deg', 'betaM_dot_deg_s', 'betaM_rate_state_deg_s', ...
    'trackingError_deg'});
end

function tbl = response_to_table(response)
tbl = table(response.time, response.betaCommandDeg, response.betaDeg, ...
    response.betaDotDegPerSec, response.betaRateStateDegPerSec, ...
    response.thetaDeg, response.qDegPerSec, response.u, response.w, ...
    'VariableNames', {'time_s', 'betaCommand_deg', 'betaM_deg', ...
    'betaM_dot_deg_s', 'betaM_rate_state_deg_s', 'theta_deg', ...
    'q_deg_s', 'u_m_s', 'w_m_s'});
end
