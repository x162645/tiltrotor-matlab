function result = simulate_linear_response(linearResult, config, P)
%SIMULATE_LINEAR_RESPONSE Simulate a small-disturbance control response.
% The state-space equation is integrated with ODE45, so this service does
% not require Control System Toolbox. Input amplitudes are specified in deg.

if nargin < 3 || isempty(P)
    P = params_nominal();
end
if nargin < 2 || isempty(config)
    config = struct();
end
if nargin < 1 || ~isstruct(linearResult) || ...
        ~isfield(linearResult,'A') || ~isfield(linearResult,'B') || ...
        ~isfield(linearResult,'trim')
    error('simulate_linear_response:InvalidLinearResult', ...
        'linearResult must be returned by run_linearization_case.');
end

parameterReport = validate_parameter_set(P);
if ~parameterReport.valid
    error('simulate_linear_response:InvalidParameters', '%s\n%s', ...
        parameterReport.summary, strjoin(parameterReport.errors, newline));
end

config = apply_defaults(config);
validate_config(config);

A = linearResult.A;
B = linearResult.B;
xTrim = linearResult.trim.xTrim(:);
uTrim = linearResult.trim.uTrim(:);
if ~isequal(size(A),[9,9]) || ~isequal(size(B),[9,7]) || ...
        numel(xTrim) ~= 9 || numel(uTrim) ~= 7
    error('simulate_linear_response:DimensionMismatch', ...
        'Expected A 9-by-9, B 9-by-7, 9 states, and 7 controls.');
end

nStep = floor(config.totalTime/config.timeStep);
t = (0:nStep)'*config.timeStep;
if t(end) < config.totalTime
    t(end+1,1) = config.totalTime;
end

du = zeros(numel(t), 7);
amplitude = config.amplitudeDeg*pi/180;
tau = t-config.startTime;
active = tau >= 0;

switch lower(config.waveform)
    case 'step'
        signal = amplitude*double(active);
    case 'pulse'
        signal = amplitude*double(active & tau <= config.duration);
    case 'sine'
        activeSine = active;
        if config.duration > 0
            activeSine = activeSine & tau <= config.duration;
        end
        signal = amplitude*sin(2*pi*config.frequencyHz*tau).*double(activeSine);
    case 'doublet'
        halfDuration = config.duration/2;
        signal = zeros(size(t));
        signal(active & tau < halfDuration) = amplitude;
        signal(tau >= halfDuration & tau <= config.duration) = -amplitude;
    otherwise
        error('simulate_linear_response:UnknownWaveform', ...
            'Unsupported waveform %s.', config.waveform);
end

du(:,config.controlChannel) = signal;

odeOptions = odeset('RelTol',1e-7,'AbsTol',1e-9);
[timeOut, dx] = ode45(@state_derivative, t, zeros(9,1), odeOptions);
if ~isequal(timeOut, t)
    duOut = interp1(t, du, timeOut, 'linear');
else
    duOut = du;
end

xActual = dx + repmat(xTrim.', size(dx,1), 1);
uActual = duOut + repmat(uTrim.', size(duOut,1), 1);
if ~isreal(dx) || any(~isfinite(dx(:))) || any(~isfinite(xActual(:)))
    error('simulate_linear_response:NonFiniteResponse', ...
        'Linear response contains complex, NaN, or Inf values.');
end

stateNames = {'u';'v';'w';'p';'q';'r';'phi';'theta';'psi'};
stateUnits = {'m/s';'m/s';'m/s';'rad/s';'rad/s';'rad/s'; ...
    'rad';'rad';'rad'};
controlNames = {'collective';'diffCollective';'cyclicLong'; ...
    'diffCyclic';'aileron';'elevator';'rudder'};
selected = dx(:,config.outputState);
[peakMagnitude, peakIndex] = max(abs(selected));

result.kind = 'linear-small-disturbance-response';
result.timestamp = datestr(now, 30);
result.success = true;
result.config = config;
result.time = timeOut;
result.deltaState = dx;
result.actualState = xActual;
result.deltaControl = duOut;
result.actualControl = uActual;
result.stateNames = stateNames;
result.stateUnits = stateUnits;
result.controlNames = controlNames;
result.selectedOutput = selected;
result.selectedOutputName = stateNames{config.outputState};
result.selectedOutputUnit = stateUnits{config.outputState};
result.peakAbs = peakMagnitude;
result.peakTime = timeOut(peakIndex);
result.finalValue = selected(end);
result.limitWarning = detect_limit_violation(uActual, P);
result.parameterValidation = parameterReport;

    function derivative = state_derivative(currentTime, deltaState)
        currentInput = interp1(t, du, currentTime, 'linear').';
        derivative = A*deltaState + B*currentInput;
    end
end

function config = apply_defaults(config)
defaults = struct( ...
    'controlChannel', 3, ...
    'waveform', 'step', ...
    'amplitudeDeg', 0.5, ...
    'startTime', 1.0, ...
    'duration', 1.0, ...
    'frequencyHz', 0.5, ...
    'totalTime', 10.0, ...
    'timeStep', 0.02, ...
    'outputState', 8);
names = fieldnames(defaults);
for k = 1:numel(names)
    if ~isfield(config,names{k}) || isempty(config.(names{k}))
        config.(names{k}) = defaults.(names{k});
    end
end
end

function validate_config(config)
if ~(isnumeric(config.controlChannel) && isscalar(config.controlChannel) && ...
        isfinite(config.controlChannel) && config.controlChannel == round(config.controlChannel) && ...
        config.controlChannel >= 1 && config.controlChannel <= 7)
    error('simulate_linear_response:InvalidControlChannel', ...
        'controlChannel must be an integer from 1 to 7.');
end
if ~(ischar(config.waveform) || (isstring(config.waveform) && isscalar(config.waveform)))
    error('simulate_linear_response:InvalidWaveform', ...
        'waveform must be step, pulse, sine, or doublet.');
end
config.waveform = char(config.waveform); %#ok<NASGU>
check_scalar(config.amplitudeDeg, 'amplitudeDeg', @(v) true);
check_scalar(config.startTime, 'startTime', @(v) v >= 0);
check_scalar(config.duration, 'duration', @(v) v > 0);
check_scalar(config.frequencyHz, 'frequencyHz', @(v) v > 0);
check_scalar(config.totalTime, 'totalTime', @(v) v > 0);
check_scalar(config.timeStep, 'timeStep', @(v) v > 0);
if config.startTime > config.totalTime
    error('simulate_linear_response:InvalidStartTime', ...
        'startTime must not exceed totalTime.');
end
if ~(isnumeric(config.outputState) && isscalar(config.outputState) && ...
        isfinite(config.outputState) && config.outputState == round(config.outputState) && ...
        config.outputState >= 1 && config.outputState <= 9)
    error('simulate_linear_response:InvalidOutputState', ...
        'outputState must be an integer from 1 to 9.');
end
end

function check_scalar(value, name, predicate)
if ~(isnumeric(value) && isreal(value) && isscalar(value) && isfinite(value) && ...
        predicate(value))
    error('simulate_linear_response:InvalidConfig', ...
        '%s is outside its valid finite scalar range.', name);
end
end

function violated = detect_limit_violation(uActual, P)
collectiveLeft = uActual(:,1)-uActual(:,2);
collectiveRight = uActual(:,1)+uActual(:,2);
cyclicLeft = uActual(:,3)-uActual(:,4);
cyclicRight = uActual(:,3)+uActual(:,4);
violated = outside(collectiveLeft,P.control.collectiveLim) || ...
    outside(collectiveRight,P.control.collectiveLim) || ...
    outside(cyclicLeft,P.control.cyclicLim) || ...
    outside(cyclicRight,P.control.cyclicLim) || ...
    outside(uActual(:,5),P.control.aileronLim) || ...
    outside(uActual(:,6),P.control.elevatorLim) || ...
    outside(uActual(:,7),P.control.rudderLim);
end

function tf = outside(values, limits)
tf = any(values < limits(1) | values > limits(2));
end
