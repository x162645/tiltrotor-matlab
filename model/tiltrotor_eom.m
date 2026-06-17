function [xdot, out] = tiltrotor_eom(x, uCtrl, betaM, P)
%TILTROTOR_EOM 九状态六自由度非线性运动方程。
%
% x = [u v w p q r phi theta psi]'.
% 机体系：x前、y右、z下。
% 对应论文式(31)~(36)。

x = x(:);
uCtrl = uCtrl(:);

[Fap, Map, componentInfo] = total_forces_moments(x, uCtrl, betaM, P);
mp = componentInfo.massProperties;

Vbody = x(1:3);
omega = x(4:6);
phi = x(7);
theta = x(8);

% 重力在机体系中的分量。
Fg = P.mass.m*P.env.g * ...
    [-sin(theta);
      sin(phi)*cos(theta);
      cos(phi)*cos(theta)];

Ftotal = Fap + Fg;
Mtotal = Map;

Vdot = Ftotal/P.mass.m - cross(omega, Vbody);

omegaDot = mp.I \ ...
    (Mtotal - cross(omega, mp.I*omega));

cosTheta = cos(theta);
if abs(cosTheta) < 1e-6
    cosTheta = sign(cosTheta + eps)*1e-6;
end

T321 = [1, sin(phi)*tan(theta),  cos(phi)*tan(theta);
        0, cos(phi),            -sin(phi);
        0, sin(phi)/cosTheta,    cos(phi)/cosTheta];

eulerDot = T321*omega;

xdot = [Vdot; omegaDot; eulerDot];

out.FaeroProp = Fap;
out.Fgravity = Fg;
out.Ftotal = Ftotal;
out.Mtotal = Mtotal;
out.massProperties = mp;
out.components = componentInfo;
out.xdot = xdot;
end
