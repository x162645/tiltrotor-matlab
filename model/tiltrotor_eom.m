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
mass = mp.mass;

Vbody = x(1:3);
omega = x(4:6);
phi = x(7);
theta = x(8);

% 重力在机体系中的分量。
Fg = mass*P.env.g * ...
    [-sin(theta);
      sin(phi)*cos(theta);
      cos(phi)*cos(theta)];

Ftotal = Fap + Fg;
Mtotal = Map;

Vdot = Ftotal/mass - cross(omega, Vbody);

omegaDot = mp.I \ ...
    (Mtotal - cross(omega, mp.I*omega));

% 3-2-1 欧拉角在 theta=+-90 deg 处存在固有奇异性。这里仅为数值
% 保护统一限制分母，避免 tan(theta) 绕过 cos(theta) 的保护逻辑。
cosThetaSafe = cos(theta);
if abs(cosThetaSafe) < 1e-6
    cosThetaSafe = sign(cosThetaSafe + eps)*1e-6;
end
tanThetaSafe = sin(theta)/cosThetaSafe;

T321 = [1, sin(phi)*tanThetaSafe,  cos(phi)*tanThetaSafe;
        0, cos(phi),              -sin(phi);
        0, sin(phi)/cosThetaSafe,  cos(phi)/cosThetaSafe];

eulerDot = T321*omega;

xdot = [Vdot; omegaDot; eulerDot];

out.FaeroProp = Fap;
out.Fgravity = Fg;
out.Ftotal = Ftotal;
out.Mtotal = Mtotal;
out.massProperties = mp;
out.components = componentInfo;
out.physicalConverged = componentInfo.physicalConverged;
out.physicalBranchSupported = componentInfo.physicalBranchSupported;
out.physicalStatus = componentInfo.physicalStatus;
out.xdot = xdot;
end
