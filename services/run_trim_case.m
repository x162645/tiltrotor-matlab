function result = run_trim_case(config, P)
%RUN_TRIM_CASE Execute one symmetric trim case through a stable GUI service API.
% Angles supplied in CONFIG use degrees. Internal model angles remain radians.

if nargin < 2 || isempty(P)
    P = params_nominal();
end
if nargin < 1 || isempty(config)
    config = struct();
end

parameterReport = validate_parameter_set(P);
if ~parameterReport.valid
    error('run_trim_case:InvalidParameters', '%s\n%s', ...
        parameterReport.summary, strjoin(parameterReport.errors, newline));
end

config = apply_defaults(config);
validate_config(config);

opts.gamma = config.gammaDeg*pi/180;
opts.initialDeg = [config.initialThetaDeg, ...
    config.initialCollectiveDeg, config.initialCyclicLongDeg];
opts.thetaLimitDeg = config.thetaLimitDeg;
opts.useMultiStart = config.useMultiStart;
opts.alwaysMultiStart = config.alwaysMultiStart;

betaM = config.betaMDeg*pi/180;
[xTrim, uTrim, trimReport] = trim_symmetric(config.V, betaM, P, opts);
[xdot, eomOut] = tiltrotor_eom(xTrim, uTrim, betaM, P);

result.kind = 'symmetric-trim';
result.timestamp = datestr(now, 30);
result.success = trimReport.converged;
result.config = config;
result.betaM = betaM;
result.xTrim = xTrim(:);
result.uTrim = uTrim(:);
result.xdot = xdot(:);
result.report = trimReport;
result.trimResidualTolerance = P.trim.residualTolerance;
result.parameterValidation = parameterReport;
result.stateNames = {'u';'v';'w';'p';'q';'r';'phi';'theta';'psi'};
result.stateUnits = {'m/s';'m/s';'m/s';'rad/s';'rad/s';'rad/s'; ...
    'rad';'rad';'rad'};
result.controlNames = {'collective';'diffCollective';'cyclicLong'; ...
    'diffCyclic';'aileron';'elevator';'rudder'};
result.controlUnits = repmat({'rad'}, 7, 1);
result.loads.FaeroProp = eomOut.FaeroProp;
result.loads.Fgravity = eomOut.Fgravity;
result.loads.Ftotal = eomOut.Ftotal;
result.loads.Mtotal = eomOut.Mtotal;
result.loads.components = eomOut.components;
result.diagnostic = build_trim_diagnostic(result);
end

function config = apply_defaults(config)
defaults = struct( ...
    'V', 0, ...
    'betaMDeg', 0, ...
    'gammaDeg', 0, ...
    'initialThetaDeg', 0, ...
    'initialCollectiveDeg', 18, ...
    'initialCyclicLongDeg', 0, ...
    'thetaLimitDeg', 35, ...
    'useMultiStart', true, ...
    'alwaysMultiStart', false);

names = fieldnames(defaults);
for k = 1:numel(names)
    if ~isfield(config, names{k}) || isempty(config.(names{k}))
        config.(names{k}) = defaults.(names{k});
    end
end
end

function validate_config(config)
check_scalar(config.V, 'V', @(v) v >= 0, ...
    'Airspeed must be a finite scalar >= 0 m/s.');
check_scalar(config.betaMDeg, 'betaMDeg', @(v) v >= 0 && v <= 90, ...
    'Nacelle angle must be in [0, 90] deg.');
check_scalar(config.gammaDeg, 'gammaDeg', @(v) abs(v) <= 90, ...
    'Flight-path angle must be a finite scalar in [-90, 90] deg.');
check_scalar(config.initialThetaDeg, 'initialThetaDeg', @(v) abs(v) <= 90, ...
    'Initial pitch angle must be in [-90, 90] deg.');
check_scalar(config.initialCollectiveDeg, 'initialCollectiveDeg', @(v) true, ...
    'Initial collective must be finite.');
check_scalar(config.initialCyclicLongDeg, 'initialCyclicLongDeg', @(v) true, ...
    'Initial longitudinal cyclic must be finite.');
check_scalar(config.thetaLimitDeg, 'thetaLimitDeg', @(v) v > 0 && v < 90, ...
    'Pitch search limit must be in (0, 90) deg.');

if ~(islogical(config.useMultiStart) && isscalar(config.useMultiStart))
    error('run_trim_case:InvalidUseMultiStart', ...
        'useMultiStart must be a logical scalar.');
end
if ~(islogical(config.alwaysMultiStart) && isscalar(config.alwaysMultiStart))
    error('run_trim_case:InvalidAlwaysMultiStart', ...
        'alwaysMultiStart must be a logical scalar.');
end
end

function check_scalar(value, name, predicate, message)
if ~(isnumeric(value) && isreal(value) && isscalar(value) && isfinite(value))
    error('run_trim_case:InvalidConfig', '%s must be a finite real scalar.', name);
end
if ~predicate(value)
    error('run_trim_case:InvalidConfig', '%s', message);
end
end
