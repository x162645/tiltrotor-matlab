function [xdot, out] = tiltrotor_eom_13x10(x13, u10, P13)
%TILTROTOR_EOM_13X10 Isolated 13-state / 10-input PR1 research EOM.
% The first nine equations retain the NUAA physical-baseline rigid-body
% form.  The two nacelles use placeholder uncoupled torque/rate dynamics.
% Actuator reaction torque, I_dot*omega, moving-mass acceleration,
% gyroscopic/transmission coupling, and position control are not included.

if nargin < 3 || isempty(P13)
    P13 = params_berger13();
end
x13 = x13(:);
u10 = u10(:);
if ~(isnumeric(x13) && isreal(x13) && numel(x13) == 13 && ...
        all(isfinite(x13)))
    error('tiltrotor_eom_13x10:InvalidState', ...
        'x13 must be a finite real 13-element vector.');
end
if ~(isnumeric(u10) && isreal(u10) && numel(u10) == 10 && ...
        all(isfinite(u10)))
    error('tiltrotor_eom_13x10:InvalidControl', ...
        'u10 must be a finite real 10-element vector.');
end

[Fap, Map, componentInfo] = total_forces_moments_13x10(x13, u10, P13);
Pbase = P13.base;
mp = componentInfo.massProperties;
mass = mp.mass;

xRigid = x13(1:9);
Vbody = xRigid(1:3);
omega = xRigid(4:6);
phi = xRigid(7);
theta = xRigid(8);

Fg = mass*Pbase.env.g * ...
    [-sin(theta);
      sin(phi)*cos(theta);
      cos(phi)*cos(theta)];

Ftotal = Fap + Fg;
Mtotal = Map;
Vdot = Ftotal/mass - cross(omega, Vbody);
omegaDot = mp.I \ (Mtotal - cross(omega, mp.I*omega));
eulerDot = euler_321_dot(phi, theta, omega);

[betaDotLeft, betaDDotLeft, leftFlags] = nacelle_derivative( ...
    x13(10), x13(12), u10(9), P13.nacelle);
[betaDotRight, betaDDotRight, rightFlags] = nacelle_derivative( ...
    x13(11), x13(13), u10(10), P13.nacelle);

xdot = [Vdot; omegaDot; eulerDot; betaDotLeft; betaDotRight; ...
    betaDDotLeft; betaDDotRight];

out.FaeroProp = Fap;
out.Fgravity = Fg;
out.Ftotal = Ftotal;
out.Mtotal = Mtotal;
out.massProperties = mp;
out.components13 = componentInfo;
out.nacelle.left.derivative = [betaDotLeft; betaDDotLeft];
out.nacelle.left.limitFlags = leftFlags;
out.nacelle.right.derivative = [betaDotRight; betaDDotRight];
out.nacelle.right.limitFlags = rightFlags;
out.nacelle.stiffnessImplemented = false;
out.xdot = xdot;
end

function eulerDot = euler_321_dot(phi, theta, omega)
cosThetaSafe = cos(theta);
if abs(cosThetaSafe) < 1e-6
    cosThetaSafe = sign(cosThetaSafe + eps)*1e-6;
end
tanThetaSafe = sin(theta)/cosThetaSafe;
T321 = [1, sin(phi)*tanThetaSafe,  cos(phi)*tanThetaSafe;
        0, cos(phi),              -sin(phi);
        0, sin(phi)/cosThetaSafe,  cos(phi)/cosThetaSafe];
eulerDot = T321*omega;
end

function [betaDot, betaDDot, flags] = nacelle_derivative( ...
        beta, betaRate, torque, cfg)
betaLimits = [cfg.betaMin; cfg.betaMax];
rateLimits = [-cfg.betaDotLim; cfg.betaDotLim];
torqueLimits = [-cfg.torqueLim; cfg.torqueLim];
torqueApplied = clamp(torque, torqueLimits);
betaDot = clamp(betaRate, rateLimits);

% Reviewed PR1 placeholder equation: I*betaDDot=Qsat-D*betaRate.
% cfg.K is retained only for provenance compatibility and is not active.
betaDDot = (torqueApplied - cfg.D*betaRate)/cfg.I;

if beta <= betaLimits(1) && betaDot < 0
    betaDot = 0;
end
if beta >= betaLimits(2) && betaDot > 0
    betaDot = 0;
end
if betaRate >= rateLimits(2) && betaDDot > 0
    betaDDot = 0;
elseif betaRate <= rateLimits(1) && betaDDot < 0
    betaDDot = 0;
end
if beta <= betaLimits(1) && betaDDot < 0
    betaDDot = 0;
elseif beta >= betaLimits(2) && betaDDot > 0
    betaDDot = 0;
end

flags.torqueClamped = abs(torqueApplied-torque) > 0;
flags.rateClamped = abs(clamp(betaRate, rateLimits)-betaRate) > 0;
flags.atLowerAngle = beta <= betaLimits(1);
flags.atUpperAngle = beta >= betaLimits(2);
end

function y = clamp(value, limits)
y = min(max(value, limits(1)), limits(2));
end
