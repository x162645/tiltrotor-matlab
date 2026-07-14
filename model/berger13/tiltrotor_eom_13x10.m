function [xdot, out] = tiltrotor_eom_13x10(x13, u10, P13)
%TILTROTOR_EOM_13X10 Berger-inspired 13-state / 10-input research EOM.

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
mp = componentInfo.baseComponents.massProperties;
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

[betaDotLeft, betaDDotLeft] = nacelle_derivative( ...
    x13(10), x13(12), u10(9), P13.nacelle);
[betaDotRight, betaDDotRight] = nacelle_derivative( ...
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
out.nacelle.right.derivative = [betaDotRight; betaDDotRight];
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

function [betaDot, betaDDot] = nacelle_derivative(beta, betaRate, torque, cfg)
betaLimits = [cfg.betaMin; cfg.betaMax];
rateLimit = cfg.betaDotLim;
torqueSat = clamp(torque, [-cfg.torqueLim; cfg.torqueLim]);
betaDot = clamp(betaRate, [-rateLimit; rateLimit]);
betaDDot = (torqueSat - cfg.D*betaRate - cfg.K*0)/cfg.I;

if beta <= betaLimits(1) && betaDot < 0
    betaDot = 0;
end
if beta >= betaLimits(2) && betaDot > 0
    betaDot = 0;
end
if betaRate >= rateLimit && betaDDot > 0
    betaDDot = 0;
elseif betaRate <= -rateLimit && betaDDot < 0
    betaDDot = 0;
end
if beta <= betaLimits(1) && betaDDot < 0
    betaDDot = 0;
elseif beta >= betaLimits(2) && betaDDot > 0
    betaDDot = 0;
end
end

function y = clamp(value, limits)
y = min(max(value, limits(1)), limits(2));
end
