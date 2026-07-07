function [xdot, out] = tiltrotor_eom(x, uCtrl, betaM, P)
%TILTROTOR_EOM 六自由度非线性运动方程，可选短舱动态状态。
%
% x = [u v w p q r phi theta psi]'.
% 若 P.nacelleDynamics.enabled=true:
% x = [u v w p q r phi theta psi betaM betaM_dot]'.
% 机体系：x前、y右、z下。
% 对应论文式(31)~(36)。

x = x(:);
uCtrl = uCtrl(:);

if has_nacelle_dynamic_states(P)
    if numel(x) ~= 11
        error('tiltrotor_eom:InvalidStateDimension', ...
            'Enabled nacelle dynamics require an 11-state vector.');
    end
    xRigid = x(1:9);
    [betaMEffective, nacelleStateDot, nacelleInfo] = ...
        nacelle_dynamics_derivative(x(10), x(11), betaM, P);
else
    if numel(x) ~= 9
        error('tiltrotor_eom:InvalidStateDimension', ...
            'Legacy nacelle-static mode requires a 9-state vector.');
    end
    xRigid = x;
    betaMEffective = betaM;
    nacelleStateDot = [];
    nacelleInfo = struct([]);
end

[Fap, Map, componentInfo] = total_forces_moments( ...
    xRigid, uCtrl, betaMEffective, P);
mp = componentInfo.massProperties;
mass = mp.mass;

Vbody = xRigid(1:3);
omega = xRigid(4:6);
phi = xRigid(7);
theta = xRigid(8);

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

xdot = [Vdot; omegaDot; eulerDot; nacelleStateDot];

out.FaeroProp = Fap;
out.Fgravity = Fg;
out.Ftotal = Ftotal;
out.Mtotal = Mtotal;
out.massProperties = mp;
out.components = componentInfo;
out.betaMEffective = betaMEffective;
out.nacelleDynamics = nacelleInfo;
out.xdot = xdot;
end

function [betaMEffective, stateDot, info] = ...
        nacelle_dynamics_derivative(betaMState, betaMRate, betaMCommandArg, P)
%NACELLE_DYNAMICS_DERIVATIVE Phase 1 quasi-static nacelle state model.

d2r = pi/180;
cfg = P.nacelleDynamics;
if ~(isnumeric(betaMState) && isreal(betaMState) && isscalar(betaMState) && ...
        isfinite(betaMState) && isnumeric(betaMRate) && ...
        isreal(betaMRate) && isscalar(betaMRate) && isfinite(betaMRate))
    error('tiltrotor_eom:InvalidNacelleState', ...
        'Nacelle dynamic states must be finite real scalars.');
end
if ~(isnumeric(betaMCommandArg) && isreal(betaMCommandArg) && ...
        isscalar(betaMCommandArg) && isfinite(betaMCommandArg))
    error('tiltrotor_eom:InvalidNacelleCommand', ...
        'External betaM command must be a finite real scalar.');
end
betaLimits = [cfg.betaMinDeg; cfg.betaMaxDeg]*d2r;
rateLimit = cfg.rateLimitDegPerSec*d2r;
if isempty(cfg.commandDeg)
    betaCommand = betaMCommandArg;
else
    betaCommand = cfg.commandDeg*d2r;
end

betaCommand = clamp(betaCommand, betaLimits);
betaMEffective = clamp(betaMState, betaLimits);
betaDot = clamp(betaMRate, [-rateLimit; rateLimit]);

atLower = betaMState <= betaLimits(1) && betaDot < 0;
atUpper = betaMState >= betaLimits(2) && betaDot > 0;
if atLower || atUpper
    betaDot = 0;
end

betaDDot = cfg.omega^2*(betaCommand - betaMEffective) - ...
    2*cfg.zeta*cfg.omega*betaMRate;

if betaMRate >= rateLimit && betaDDot > 0
    betaDDot = 0;
elseif betaMRate <= -rateLimit && betaDDot < 0
    betaDDot = 0;
end
if betaMState <= betaLimits(1) && betaDDot < 0
    betaDDot = 0;
elseif betaMState >= betaLimits(2) && betaDDot > 0
    betaDDot = 0;
end

stateDot = [betaDot; betaDDot];
info.enabled = true;
info.model = cfg.model;
info.betaMState = betaMState;
info.betaMRate = betaMRate;
info.betaMEffective = betaMEffective;
info.betaMCommand = betaCommand;
info.betaLimits = betaLimits;
info.rateLimit = rateLimit;
info.derivative = stateDot;
info.omittedCouplings = { ...
    'rCG_dot'; 'rCG_ddot'; 'I_dot_times_omega'; ...
    'nacelle_gyro_moment'; 'left_right_desync'; 'torque_pid'};
end

function y = clamp(value, limits)
y = min(max(value, limits(1)), limits(2));
end
