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

if strcmp(config.trimMode, 'lateral_directional_balance')
    result = run_lateral_directional_case(config, P, parameterReport);
    return;
elseif strcmp(config.trimMode, 'full_6dof_straight_trim')
    result = run_full_6dof_case(config, P, parameterReport);
    return;
end

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
result.parameterValidation = parameterReport;
result.stateNames = get_state_names(P);
result.stateUnits = get_state_units(P);
result.controlNames = get_control_input_names(P);
result.controlUnits = get_control_input_units(P);
result.loads.FaeroProp = eomOut.FaeroProp;
result.loads.Fgravity = eomOut.Fgravity;
result.loads.Ftotal = eomOut.Ftotal;
result.loads.Mtotal = eomOut.Mtotal;
result.loads.components = eomOut.components;
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
    'alwaysMultiStart', false, ...
    'trimMode', 'longitudinal_symmetric');

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
if isstring(config.trimMode) && isscalar(config.trimMode)
    config.trimMode = char(config.trimMode);
end
config.trimMode = normalize_trim_mode(config.trimMode);
validModes = {'longitudinal_symmetric', ...
    'lateral_directional_balance', 'full_6dof_straight_trim'};
if ~(ischar(config.trimMode) && any(strcmp(config.trimMode, validModes)))
    error('run_trim_case:InvalidTrimMode', ...
        ['trimMode must be longitudinal_symmetric, ' ...
        'lateral_directional_balance, or full_6dof_straight_trim.']);
end
end

function mode = normalize_trim_mode(mode)
if strcmp(mode, 'full_6dof')
    mode = 'full_6dof_straight_trim';
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

function result = run_lateral_directional_case(config, P, parameterReport)
baseConfig = config;
baseConfig.trimMode = 'longitudinal_symmetric';
baseTrim = run_trim_case(baseConfig, P);
if ~baseTrim.success
    result = failed_dependency_result('lateral-directional-trim', config, ...
        P, parameterReport, baseTrim, ...
        'Longitudinal base trim did not converge; lateral balance was not run.');
    return;
end

betaM = config.betaMDeg*pi/180;
opts = struct();
[xTrim, uTrim, trimReport] = trim_lateral_directional_balance( ...
    baseTrim, betaM, P, opts);
[xdot, eomOut] = tiltrotor_eom(xTrim, uTrim, betaM, P);
result = solver_result('lateral-directional-trim', config, P, ...
    parameterReport, betaM, xTrim, uTrim, xdot, eomOut, trimReport);
result.baseTrim = baseTrim;
end

function result = run_full_6dof_case(config, P, parameterReport)
condition = struct('V', config.V, 'betaM', config.betaMDeg*pi/180, ...
    'gamma', config.gammaDeg*pi/180);
opts = struct('thetaLimitDeg', config.thetaLimitDeg);
baseConfig = config;
baseConfig.trimMode = 'longitudinal_symmetric';
try
    baseTrim = run_trim_case(baseConfig, P);
    if baseTrim.success
        opts.baseTrim = baseTrim;
    end
catch ME
    baseTrim = struct('success', false, 'message', ME.message, ...
        'identifier', ME.identifier);
end

[xTrim, uTrim, trimReport] = trim_full_6dof_straight(condition, P, opts);
[xdot, eomOut] = tiltrotor_eom(xTrim, uTrim, condition.betaM, P);
result = solver_result('full-6dof-straight-trim', config, P, ...
    parameterReport, condition.betaM, xTrim, uTrim, xdot, eomOut, ...
    trimReport);
result.baseTrimForInitialGuess = baseTrim;
end

function result = solver_result(kind, config, P, parameterReport, betaM, ...
        xTrim, uTrim, xdot, eomOut, trimReport)
result.kind = kind;
result.timestamp = datestr(now, 30);
result.success = trimReport.converged;
result.guarded = false;
result.enabled = true;
result.config = config;
result.betaM = betaM;
result.xTrim = xTrim(:);
result.uTrim = uTrim(:);
result.xdot = xdot(:);
result.report = trimReport;
result.message = trimReport.message;
result.parameterValidation = parameterReport;
result.stateNames = get_state_names(P);
result.stateUnits = get_state_units(P);
result.controlNames = get_control_input_names(P);
result.controlUnits = get_control_input_units(P);
result.loads.FaeroProp = eomOut.FaeroProp;
result.loads.Fgravity = eomOut.Fgravity;
result.loads.Ftotal = eomOut.Ftotal;
result.loads.Mtotal = eomOut.Mtotal;
result.loads.components = eomOut.components;
result.definition = build_trim_mode_definition(config.trimMode, P);
end

function result = failed_dependency_result(kind, config, P, parameterReport, ...
        dependency, message)
definition = build_trim_mode_definition(config.trimMode, P);
stateDim = get_state_dimension(P);
controlNames = get_control_input_names(P);
residualLabels = definition.residualNames(:);
result.kind = kind;
result.timestamp = datestr(now, 30);
result.success = false;
result.guarded = false;
result.enabled = true;
result.config = config;
result.betaM = config.betaMDeg*pi/180;
result.xTrim = NaN(stateDim,1);
result.uTrim = NaN(numel(controlNames),1);
result.xdot = NaN(stateDim,1);
result.message = message;
result.parameterValidation = parameterReport;
result.stateNames = get_state_names(P);
result.stateUnits = get_state_units(P);
result.controlNames = controlNames;
result.controlUnits = get_control_input_units(P);
result.loads.FaeroProp = NaN(3,1);
result.loads.Fgravity = NaN(3,1);
result.loads.Ftotal = NaN(3,1);
result.loads.Mtotal = NaN(3,1);
result.loads.components = struct();
result.definition = definition;
result.dependency = dependency;
result.report.residual = NaN(numel(residualLabels),1);
result.report.residualNorm = Inf;
result.report.residualLabels = residualLabels;
result.report.residualScale = NaN(numel(residualLabels),1);
result.report.residualScaleUnits = residual_units(residualLabels);
result.report.fullStateDerivative = NaN(stateDim,1);
result.report.fullResidualNorm = Inf;
result.report.finite = false;
result.report.converged = false;
result.report.withinLimits = false;
result.report.atLimit = false;
result.report.limitReport = struct('anyViolation', false, ...
    'anyAtLimit', false, 'entries', []);
result.report.message = message;
end

function units = residual_units(labels)
units = cell(numel(labels),1);
for i = 1:numel(labels)
    switch labels{i}
        case {'udot','vdot','wdot'}
            units{i} = 'm/s^2';
        otherwise
            units{i} = 'rad/s^2';
    end
end
end
