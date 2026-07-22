function result = nacelle_command_actuator( ...
        beta,betaRate,betaCommand,cfg,nacelleCfg,context)
%NACELLE_COMMAND_ACTUATOR Closed-loop second-order angle-command channel.
% A nonzero delay requires an externally supplied delayedCommand because a
% true time delay cannot be represented by the frozen 13 Markov states.

if nargin < 6
    context = struct();
end
validate_cfg(cfg,nacelleCfg);
commandRequested = betaCommand;
flags.delayActive = cfg.commandDelay > 0;
flags.stuck = logical(cfg.stuck);
flags.commandFrozen = logical(cfg.commandFreeze);

if flags.delayActive
    if ~isfield(context,'delayedCommand') || ...
            ~isscalar(context.delayedCommand) || ...
            ~isfinite(context.delayedCommand)
        error('nacelle_command_actuator:DelayContextRequired', ...
            ['A positive commandDelay requires context.delayedCommand ' ...
             'from an external command-history simulator.']);
    end
    betaCommand = context.delayedCommand;
end
if flags.commandFrozen
    if isfield(context,'frozenCommand')
        betaCommand = context.frozenCommand;
    else
        betaCommand = cfg.frozenCommand;
    end
end

commandApplied = min(max(betaCommand,nacelleCfg.betaMin), ...
    nacelleCfg.betaMax);
rateLimit = nacelleCfg.betaDotLim*cfg.rateScale;
betaDot = min(max(betaRate,-rateLimit),rateLimit);
rawAcceleration = cfg.omegaN^2*(commandApplied-beta) - ...
    2*cfg.zeta*cfg.omegaN*betaRate;
rawTorque = nacelleCfg.I*rawAcceleration;
torqueApplied = min(max(rawTorque,-nacelleCfg.torqueLim), ...
    nacelleCfg.torqueLim);
betaDDot = torqueApplied/nacelleCfg.I;
betaDDot = min(max(betaDDot,-cfg.accelLim),cfg.accelLim);
torqueApplied = nacelleCfg.I*betaDDot;

if flags.stuck
    betaDot = 0;
    betaDDot = 0;
    torqueApplied = 0;
end
if beta <= nacelleCfg.betaMin && betaDot < 0
    betaDot = 0;
end
if beta >= nacelleCfg.betaMax && betaDot > 0
    betaDot = 0;
end
if betaRate >= rateLimit && betaDDot > 0
    betaDDot = 0;
    torqueApplied = 0;
elseif betaRate <= -rateLimit && betaDDot < 0
    betaDDot = 0;
    torqueApplied = 0;
end
if beta <= nacelleCfg.betaMin && betaDDot < 0
    betaDDot = 0;
    torqueApplied = 0;
elseif beta >= nacelleCfg.betaMax && betaDDot > 0
    betaDDot = 0;
    torqueApplied = 0;
end

flags.commandClamped = abs(commandApplied-betaCommand) > 0;
flags.rateClamped = abs(betaDot-betaRate) > 0;
flags.accelerationClamped = abs(betaDDot-rawAcceleration) > 0;
flags.torqueClamped = abs(rawTorque) > nacelleCfg.torqueLim;
flags.atLowerAngle = beta <= nacelleCfg.betaMin;
flags.atUpperAngle = beta >= nacelleCfg.betaMax;
flags.anyLimit = flags.commandClamped || flags.rateClamped || ...
    flags.accelerationClamped || flags.torqueClamped || ...
    flags.atLowerAngle || flags.atUpperAngle;

result.betaDot = betaDot;
result.betaDDot = betaDDot;
result.commandRequested = commandRequested;
result.commandApplied = commandApplied;
result.rawAcceleration = rawAcceleration;
result.internalTorque = torqueApplied;
result.rateLimitApplied = rateLimit;
result.flags = flags;
end

function validate_cfg(cfg,nacelleCfg)
values = [cfg.omegaN,cfg.zeta,cfg.accelLim,cfg.rateScale, ...
    cfg.commandDelay,nacelleCfg.I,nacelleCfg.betaDotLim, ...
    nacelleCfg.torqueLim];
if any(~isfinite(values)) || any(values < 0) || cfg.omegaN <= 0 || ...
        cfg.accelLim <= 0 || cfg.rateScale <= 0 || nacelleCfg.I <= 0
    error('nacelle_command_actuator:InvalidConfiguration', ...
        'Actuator parameters must be finite and physically admissible.');
end
end
