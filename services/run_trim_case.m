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

if ~strcmp(config.trimMode, 'longitudinal_symmetric')
    result = guarded_trim_mode_result(config, P, parameterReport);
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
validModes = {'longitudinal_symmetric', ...
    'lateral_directional_balance', 'full_6dof'};
if ~(ischar(config.trimMode) && any(strcmp(config.trimMode, validModes)))
    error('run_trim_case:InvalidTrimMode', ...
        'trimMode must be longitudinal_symmetric, lateral_directional_balance, or full_6dof.');
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

function result = guarded_trim_mode_result(config, P, parameterReport)
definition = build_trim_mode_definition(config.trimMode, P);
controlNames = get_control_input_names(P);
switch config.trimMode
    case 'lateral_directional_balance'
        message = ['该模式当前提供受控入口和定义检查；完整横侧向求解尚未启用，' ...
            '不会调用纵向对称配平冒充成功。'];
        if ~any(strcmp(controlNames, 'lateralCyclic'))
            message = [message newline ...
                '当前为默认 7 输入；如需检查 lateralCyclic，请先启用 8 输入控制架构。'];
        end
    case 'full_6dof'
        message = ['该模式需要完整未知量、残差和约束定义；当前为 guarded scaffold，' ...
            '完整求解未启用，不输出假配平结果。'];
    otherwise
        error('run_trim_case:UnsupportedGuardedMode', ...
            'Unsupported guarded trim mode %s.', config.trimMode);
end

result.kind = 'guarded-trim-mode';
result.timestamp = datestr(now, 30);
result.success = false;
result.guarded = true;
result.enabled = false;
result.mode = config.trimMode;
result.modeLabel = definition.label;
result.message = message;
result.reason = '完整配平定义尚未启用';
result.config = config;
result.parameterValidation = parameterReport;
result.stateNames = get_state_names(P);
result.controlNames = controlNames;
result.residualTargets = definition.residualNames;
result.recommendedControls = definition.unknownNames;
result.definition = definition;
end
