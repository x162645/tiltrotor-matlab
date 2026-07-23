function [xdot,out] = tiltrotor_eom_13x10_reference(x13,u10,P13,options)
%TILTROTOR_EOM_13X10_REFERENCE Opt-in torque-interface reference-rotor EOM.

if nargin < 3 || isempty(P13)
    P13 = params_berger13();
end
if nargin < 4
    options = struct();
end
x13 = x13(:);
u10 = u10(:);
[Fap,Map,componentInfo] = ...
    total_forces_moments_13x10_reference(x13,u10,P13,options);
mp = componentInfo.massProperties;
Vbody = x13(1:3);
omega = x13(4:6);
phi = x13(7);
theta = x13(8);
Fg = mp.mass*P13.base.env.g*[-sin(theta); ...
    sin(phi)*cos(theta);cos(phi)*cos(theta)];
Vdot = (Fap+Fg)/mp.mass-cross(omega,Vbody);
omegaDot = mp.I\(Map-cross(omega,mp.I*omega));
eulerDot = euler_321_dot(phi,theta,omega);
[betaDotLeft,betaDDotLeft,leftFlags] = nacelle_derivative( ...
    x13(10),x13(12),u10(9),P13.nacelle);
[betaDotRight,betaDDotRight,rightFlags] = nacelle_derivative( ...
    x13(11),x13(13),u10(10),P13.nacelle);
xdot = [Vdot;omegaDot;eulerDot;betaDotLeft;betaDotRight; ...
    betaDDotLeft;betaDDotRight];

out.modelId = 'NUAA_PUBLIC_FORMULA_REFERENCE';
out.FaeroProp = Fap;
out.Fgravity = Fg;
out.Ftotal = Fap+Fg;
out.Mtotal = Map;
out.massProperties = mp;
out.components13 = componentInfo;
out.nacelle.left.derivative = [betaDotLeft;betaDDotLeft];
out.nacelle.left.limitFlags = leftFlags;
out.nacelle.right.derivative = [betaDotRight;betaDDotRight];
out.nacelle.right.limitFlags = rightFlags;
out.xdot = xdot;
end

function eulerDot = euler_321_dot(phi,theta,omega)
c = cos(theta);
if abs(c) < 1e-6
    c = sign(c+eps)*1e-6;
end
T = [1,sin(phi)*sin(theta)/c,cos(phi)*sin(theta)/c; ...
     0,cos(phi),-sin(phi);0,sin(phi)/c,cos(phi)/c];
eulerDot = T*omega;
end

function [betaDot,betaDDot,flags] = nacelle_derivative( ...
        beta,betaRate,torque,cfg)
torqueApplied = min(max(torque,-cfg.torqueLim),cfg.torqueLim);
betaDot = min(max(betaRate,-cfg.betaDotLim),cfg.betaDotLim);
betaDDot = (torqueApplied-cfg.D*betaRate)/cfg.I;
if beta <= cfg.betaMin && betaDot < 0
    betaDot = 0;
end
if beta >= cfg.betaMax && betaDot > 0
    betaDot = 0;
end
if betaRate >= cfg.betaDotLim && betaDDot > 0
    betaDDot = 0;
elseif betaRate <= -cfg.betaDotLim && betaDDot < 0
    betaDDot = 0;
end
if beta <= cfg.betaMin && betaDDot < 0
    betaDDot = 0;
elseif beta >= cfg.betaMax && betaDDot > 0
    betaDDot = 0;
end
flags.torqueClamped = abs(torqueApplied-torque) > 0;
flags.rateClamped = abs(betaDot-betaRate) > 0;
flags.atLowerAngle = beta <= cfg.betaMin;
flags.atUpperAngle = beta >= cfg.betaMax;
end
