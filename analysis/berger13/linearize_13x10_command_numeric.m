function [A,B,report] = linearize_13x10_command_numeric( ...
        x13,u10Command,P13,stepScale)
%LINEARIZE_13X10_COMMAND_NUMERIC Boundary-aware command-interface Jacobian.

if nargin < 3 || isempty(P13)
    P13 = params_berger13();
end
if nargin < 4 || isempty(stepScale)
    stepScale = 1;
end
x13 = x13(:);
u10Command = u10Command(:);
if numel(x13) ~= 13 || numel(u10Command) ~= 10 || ...
        any(~isfinite(x13)) || any(~isfinite(u10Command)) || ...
        ~isreal(x13) || ~isreal(u10Command) || ...
        ~isscalar(stepScale) || stepScale <= 0 || ~isfinite(stepScale)
    error('linearize_13x10_command_numeric:InvalidInput', ...
        'State, command, and positive stepScale must be finite and real.');
end
dx = P13.linearCommand.dx(:)*stepScale;
du = P13.linearCommand.du(:)*stepScale;
[xLower,xUpper,uLower,uUpper] = bounds(P13);
f0 = tiltrotor_eom_13x10_command(x13,u10Command,P13);
A = zeros(13,13);
B = zeros(13,10);
stateSchemes = cell(13,1);
inputSchemes = cell(10,1);
for j = 1:13
    [A(:,j),stateSchemes{j}] = difference_column( ...
        x13,u10Command,j,dx(j),xLower(j),xUpper(j),true,f0,P13);
end
for j = 1:10
    [B(:,j),inputSchemes{j}] = difference_column( ...
        x13,u10Command,j,du(j),uLower(j),uUpper(j),false,f0,P13);
end
report.f0 = f0;
report.dx = dx;
report.du = du;
report.stepScale = stepScale;
report.stateSchemes = stateSchemes;
report.inputSchemes = inputSchemes;
report.stateNames = get_state_names_13x10();
report.stateUnits = get_state_units_13x10();
report.inputNames = get_command_input_names_13x10();
report.inputUnits = get_command_input_units_13x10();
report.finiteReal = isreal(A) && isreal(B) && ...
    all(isfinite(A(:))) && all(isfinite(B(:))) && ...
    isreal(f0) && all(isfinite(f0));
end

function [column,scheme] = difference_column( ...
        x,u,j,h,lower,upper,isState,f0,P13)
if isState
    value = x(j);
else
    value = u(j);
end
if value-h < lower
    [xp,up] = perturb(x,u,j,h,isState);
    fp = tiltrotor_eom_13x10_command(xp,up,P13);
    column = (fp-f0)/h;
    scheme = 'forward';
elseif value+h > upper
    [xm,um] = perturb(x,u,j,-h,isState);
    fm = tiltrotor_eom_13x10_command(xm,um,P13);
    column = (f0-fm)/h;
    scheme = 'backward';
else
    [xp,up] = perturb(x,u,j,h,isState);
    [xm,um] = perturb(x,u,j,-h,isState);
    fp = tiltrotor_eom_13x10_command(xp,up,P13);
    fm = tiltrotor_eom_13x10_command(xm,um,P13);
    column = (fp-fm)/(2*h);
    scheme = 'central';
end
end

function [x,u] = perturb(x,u,j,delta,isState)
if isState
    x(j) = x(j)+delta;
else
    u(j) = u(j)+delta;
end
end

function [xLower,xUpper,uLower,uUpper] = bounds(P13)
xLower = -inf(13,1);
xUpper = inf(13,1);
xLower(10:11) = P13.nacelle.betaMin;
xUpper(10:11) = P13.nacelle.betaMax;
xLower(12) = -P13.nacelle.betaDotLim* ...
    P13.commandActuator.left.rateScale;
xUpper(12) = -xLower(12);
xLower(13) = -P13.nacelle.betaDotLim* ...
    P13.commandActuator.right.rateScale;
xUpper(13) = -xLower(13);
P = P13.base;
uLower = -inf(10,1);
uUpper = inf(10,1);
uLower(1) = P.control.collectiveLim(1);
uUpper(1) = P.control.collectiveLim(2);
uLower(3:5) = P.control.cyclicLim(1);
uUpper(3:5) = P.control.cyclicLim(2);
uLower(6) = P.control.aileronLim(1);
uUpper(6) = P.control.aileronLim(2);
uLower(7) = P.control.elevatorLim(1);
uUpper(7) = P.control.elevatorLim(2);
uLower(8) = P.control.rudderLim(1);
uUpper(8) = P.control.rudderLim(2);
uLower(9:10) = P13.nacelle.betaMin;
uUpper(9:10) = P13.nacelle.betaMax;
end
