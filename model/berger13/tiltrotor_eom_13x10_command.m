function [xdot,out] = tiltrotor_eom_13x10_command( ...
        x13,u10Command,P13,context)
%TILTROTOR_EOM_13X10_COMMAND Distinct angle-command 13-state research EOM.
% Inputs 9/10 are always left/right angles. They are never nacelle torques.

if nargin < 3 || isempty(P13)
    P13 = params_berger13();
end
if nargin < 4
    context = struct();
end
x13 = x13(:);
u10Command = u10Command(:);
if numel(x13) ~= 13 || numel(u10Command) ~= 10 || ...
        any(~isfinite(x13)) || any(~isfinite(u10Command)) || ...
        ~isreal(x13) || ~isreal(u10Command)
    error('tiltrotor_eom_13x10_command:InvalidInput', ...
        'Expected finite real 13-state and 10-command vectors.');
end

leftContext = side_context(context,'left');
rightContext = side_context(context,'right');
left = nacelle_command_actuator(x13(10),x13(12),u10Command(9), ...
    P13.commandActuator.left,P13.nacelle,leftContext);
right = nacelle_command_actuator(x13(11),x13(13),u10Command(10), ...
    P13.commandActuator.right,P13.nacelle,rightContext);

u10TorqueEquivalent = [u10Command(1:8);0;0];
[Fap,Map,components] = total_forces_moments_13x10( ...
    x13,u10TorqueEquivalent,P13);
mp = components.massProperties;
Vbody = x13(1:3);
omega = x13(4:6);
phi = x13(7);
theta = x13(8);

Fg = mp.mass*P13.base.env.g*[-sin(theta); ...
    sin(phi)*cos(theta);cos(phi)*cos(theta)];
eBeta = [0;-1;0];
Mreaction = -left.internalTorque*eBeta-right.internalTorque*eBeta;
MtiltRateGyro = tilt_rate_gyro(x13,P13);
Mtotal = Map+Mreaction+MtiltRateGyro;
Vdot = (Fap+Fg)/mp.mass-cross(omega,Vbody);
omegaDot = mp.I\(Mtotal-cross(omega,mp.I*omega));
eulerDot = euler_321_dot(phi,theta,omega);
xdot = [Vdot;omegaDot;eulerDot;left.betaDot;right.betaDot; ...
    left.betaDDot;right.betaDDot];

out.FaeroProp = Fap;
out.Fgravity = Fg;
out.Ftotal = Fap+Fg;
out.MaeroProp = Map;
out.MactuatorReaction = Mreaction;
out.MnacelleRateGyro = MtiltRateGyro;
out.MexternalHinge = zeros(3,1);
out.Mtotal = Mtotal;
out.massProperties = mp;
out.components13 = components;
out.physicalConverged = components.physicalConverged;
out.physicalBranchSupported = components.physicalBranchSupported;
out.physicalStatus = components.physicalStatus;
out.nacelle.left = left;
out.nacelle.right = right;
out.inputContract = 'ANGLE_COMMAND';
out.inputNames = get_command_input_names_13x10();
out.mechanics = P13.mechanics;
out.couplingBoundary = P13.mechanics.couplingBoundary;
out.xdot = xdot;
end

function M = tilt_rate_gyro(x13,P13)
Jomega = P13.base.rotor.Jpolar*P13.base.rotor.Omega;
eDLeft = [cos(x13(10));0;sin(x13(10))];
eDRight = [cos(x13(11));0;sin(x13(11))];
% H=rotDir*J*Omega*eT and d(eT)/dt=betaDot*eD. The body receives
% the opposite moment. rotDir is -1 left and +1 right.
M = -((-1)*Jomega*x13(12)*eDLeft + ...
      (+1)*Jomega*x13(13)*eDRight);
end

function contextSide = side_context(context,name)
if isfield(context,name)
    contextSide = context.(name);
else
    contextSide = struct();
end
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
