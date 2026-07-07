function result = run_nacelle_dynamics_response_case(config, P)
%RUN_NACELLE_DYNAMICS_RESPONSE_CASE Open-loop nacelle response service.
% This service supports the experimental GUI entry. The default leaves the
% nacelle dynamic states disabled and therefore uses the legacy 9-state path.

if nargin < 2 || isempty(P)
    P = params_nominal();
end
if nargin < 1 || isempty(config)
    config = struct();
end

config = apply_defaults(config);
validate_config(config);

parameterReport = validate_parameter_set(P);
if ~parameterReport.valid
    error('run_nacelle_dynamics_response_case:InvalidParameters', '%s\n%s', ...
        parameterReport.summary, strjoin(parameterReport.errors, newline));
end

d2r = pi/180;
r2d = 180/pi;
Pcase = P;
Pcase.nacelleDynamics.enabled = logical(config.enableNacelleDynamics);
Pcase.nacelleDynamics.commandDeg = config.commandBetaDeg;
Pcase.nacelleDynamics.rateLimitDegPerSec = config.rateLimitDegPerSec;
Pcase.nacelleDynamics.omega = config.omega;
Pcase.nacelleDynamics.zeta = config.zeta;

beta0 = config.initialBetaDeg*d2r;
theta0 = config.thetaDeg*d2r;
xRigid0 = [config.V; 0; 0; 0; 0; 0; 0; theta0; 0];
uCtrl = [config.collectiveDeg; config.diffCollectiveDeg; ...
    config.cyclicLongDeg; config.diffCyclicDeg; config.aileronDeg; ...
    config.elevatorDeg; config.rudderDeg]*d2r;

if Pcase.nacelleDynamics.enabled
    x0 = [xRigid0; beta0; 0];
else
    x0 = xRigid0;
end

t = (0:config.timeStep:config.duration).';
if t(end) < config.duration
    t(end+1,1) = config.duration;
end

odeOptions = odeset('RelTol', 1e-7, 'AbsTol', 1e-9);
[timeOut, x] = ode45(@(time, state) tiltrotor_eom( ...
    state, uCtrl, beta0, Pcase), t, x0, odeOptions);

if ~isreal(x) || any(~isfinite(x(:)))
    error('run_nacelle_dynamics_response_case:NonFiniteResponse', ...
        'Nacelle response contains complex, NaN, or Inf values.');
end

if Pcase.nacelleDynamics.enabled
    betaM = x(:,10);
    betaRateState = x(:,11);
    betaDot = sample_beta_dot(timeOut, x, uCtrl, beta0, Pcase);
else
    betaM = beta0*ones(size(timeOut));
    betaRateState = zeros(size(timeOut));
    betaDot = zeros(size(timeOut));
end

rateLimit = Pcase.nacelleDynamics.rateLimitDegPerSec*d2r;
rateLimited = max(abs(betaDot)) <= rateLimit + 1e-10;

result.kind = 'experimental-nacelle-dynamics-response';
result.timestamp = datestr(now, 30);
result.success = true;
result.enabled = Pcase.nacelleDynamics.enabled;
result.stateDimension = numel(x0);
result.config = config;
result.time = timeOut;
result.state = x;
result.stateNames = get_state_names(Pcase);
result.stateUnits = get_state_units(Pcase);
result.fixedControls = uCtrl;
result.betaM = betaM;
result.betaMDeg = betaM*r2d;
result.betaMCommandDeg = clamp(config.commandBetaDeg, ...
    [Pcase.nacelleDynamics.betaMinDeg; Pcase.nacelleDynamics.betaMaxDeg]) ...
    *ones(size(timeOut));
result.betaMDot = betaDot;
result.betaMDotDegPerSec = betaDot*r2d;
result.betaRateState = betaRateState;
result.betaRateStateDegPerSec = betaRateState*r2d;
result.thetaDeg = x(:,8)*r2d;
result.qDegPerSec = x(:,5)*r2d;
result.u = x(:,1);
result.w = x(:,3);
result.rateLimited = rateLimited;
result.parameterValidation = parameterReport;
result.note = ['Experimental open-loop response. This is not complete real ' ...
    'conversion flight and does not replace the legacy model.'];
end

function config = apply_defaults(config)
defaults = struct( ...
    'enableNacelleDynamics', false, ...
    'V', 70, ...
    'thetaDeg', 0, ...
    'initialBetaDeg', 15, ...
    'commandBetaDeg', 75, ...
    'rateLimitDegPerSec', 8, ...
    'omega', 2.0, ...
    'zeta', 0.8, ...
    'duration', 6.0, ...
    'timeStep', 0.05, ...
    'collectiveDeg', 12, ...
    'diffCollectiveDeg', 0, ...
    'cyclicLongDeg', 1, ...
    'diffCyclicDeg', 0, ...
    'aileronDeg', 0, ...
    'elevatorDeg', -1, ...
    'rudderDeg', 0);

names = fieldnames(defaults);
for k = 1:numel(names)
    if ~isfield(config, names{k}) || isempty(config.(names{k}))
        config.(names{k}) = defaults.(names{k});
    end
end
end

function validate_config(config)
if ~((islogical(config.enableNacelleDynamics) && ...
        isscalar(config.enableNacelleDynamics)) || ...
        (isnumeric(config.enableNacelleDynamics) && ...
        isscalar(config.enableNacelleDynamics) && ...
        (config.enableNacelleDynamics == 0 || config.enableNacelleDynamics == 1)))
    error('run_nacelle_dynamics_response_case:InvalidConfig', ...
        'enableNacelleDynamics must be a logical scalar.');
end
check_scalar(config.V, 'V', @(v) v >= 0);
check_scalar(config.thetaDeg, 'thetaDeg', @(v) abs(v) <= 90);
check_scalar(config.initialBetaDeg, 'initialBetaDeg', @(v) v >= 0 && v <= 90);
check_scalar(config.commandBetaDeg, 'commandBetaDeg', @(v) true);
check_scalar(config.rateLimitDegPerSec, 'rateLimitDegPerSec', @(v) v > 0);
check_scalar(config.omega, 'omega', @(v) v > 0);
check_scalar(config.zeta, 'zeta', @(v) v > 0);
check_scalar(config.duration, 'duration', @(v) v > 0 && v <= 60);
check_scalar(config.timeStep, 'timeStep', @(v) v > 0 && v <= config.duration);
check_scalar(config.collectiveDeg, 'collectiveDeg', @(v) true);
check_scalar(config.diffCollectiveDeg, 'diffCollectiveDeg', @(v) true);
check_scalar(config.cyclicLongDeg, 'cyclicLongDeg', @(v) true);
check_scalar(config.diffCyclicDeg, 'diffCyclicDeg', @(v) true);
check_scalar(config.aileronDeg, 'aileronDeg', @(v) true);
check_scalar(config.elevatorDeg, 'elevatorDeg', @(v) true);
check_scalar(config.rudderDeg, 'rudderDeg', @(v) true);
end

function check_scalar(value, name, predicate)
if ~(isnumeric(value) && isreal(value) && isscalar(value) && ...
        isfinite(value) && predicate(value))
    error('run_nacelle_dynamics_response_case:InvalidConfig', ...
        '%s is outside its valid finite scalar range.', name);
end
end

function betaDot = sample_beta_dot(timeOut, x, uCtrl, betaArg, Pcase)
betaDot = zeros(numel(timeOut), 1);
for k = 1:numel(timeOut)
    f = tiltrotor_eom(x(k,:).', uCtrl, betaArg, Pcase);
    betaDot(k) = f(10);
end
end

function y = clamp(value, limits)
y = min(max(value, limits(1)), limits(2));
end
