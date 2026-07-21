function [A, B, report] = linearize_13x10_numeric( ...
        x13, u10, P13, stepScale)
%LINEARIZE_13X10_NUMERIC Boundary-aware finite differences for PR1.
% This is an internal numerical-consistency tool, not a trim, modal, or
% external-validation workflow.

if nargin < 3 || isempty(P13)
    P13 = params_berger13();
end
if nargin < 4 || isempty(stepScale)
    stepScale = 1;
end
x13 = x13(:);
u10 = u10(:);
if numel(x13) ~= 13 || numel(u10) ~= 10
    error('linearize_13x10_numeric:DimensionMismatch', ...
        'Expected 13 states and 10 controls.');
end
if any(~isfinite(x13)) || any(~isfinite(u10)) || ...
        ~isreal(x13) || ~isreal(u10)
    error('linearize_13x10_numeric:InvalidOperatingPoint', ...
        'Operating point must be finite and real.');
end
if ~(isscalar(stepScale) && isreal(stepScale) && ...
        isfinite(stepScale) && stepScale > 0)
    error('linearize_13x10_numeric:InvalidScale', ...
        'stepScale must be a finite positive scalar.');
end

dx = difference_steps(P13, 'dx', 13)*stepScale;
du = difference_steps(P13, 'du', 10)*stepScale;
[xLower, xUpper, uLower, uUpper] = bounds_13x10(P13);
f0 = tiltrotor_eom_13x10(x13, u10, P13);
A = zeros(13, 13);
B = zeros(13, 10);
stateSchemes = cell(13,1);
controlSchemes = cell(10,1);

for j = 1:13
    [A(:,j), stateSchemes{j}] = state_column( ...
        x13, u10, j, dx(j), xLower(j), xUpper(j), f0, P13);
end
for j = 1:10
    [B(:,j), controlSchemes{j}] = control_column( ...
        x13, u10, j, du(j), uLower(j), uUpper(j), f0, P13);
end

report.f0 = f0;
report.dx = dx;
report.du = du;
report.stepScale = stepScale;
report.stateSchemes = stateSchemes;
report.controlSchemes = controlSchemes;
report.stateNames = get_state_names_13x10();
report.stateUnits = get_state_units_13x10();
report.controlNames = get_control_input_names_13x10();
report.controlUnits = get_control_input_units_13x10();
report.ASize = size(A);
report.BSize = size(B);
report.finite = isreal(A) && isreal(B) && isreal(f0) && ...
    all(isfinite(A(:))) && all(isfinite(B(:))) && all(isfinite(f0(:)));
report.warnings = {'finite A/B is internal numerical evidence only'};
end

function [column, scheme] = state_column( ...
        x, u, j, h, lower, upper, f0, P13)
if x(j)-h < lower
    xp = x;
    xp(j) = xp(j)+h;
    column = (tiltrotor_eom_13x10(xp,u,P13)-f0)/h;
    scheme = 'forward';
elseif x(j)+h > upper
    xm = x;
    xm(j) = xm(j)-h;
    column = (f0-tiltrotor_eom_13x10(xm,u,P13))/h;
    scheme = 'backward';
else
    xp = x;
    xm = x;
    xp(j) = xp(j)+h;
    xm(j) = xm(j)-h;
    fp = tiltrotor_eom_13x10(xp,u,P13);
    fm = tiltrotor_eom_13x10(xm,u,P13);
    column = (fp-fm)/(2*h);
    scheme = 'central';
end
end

function [column, scheme] = control_column( ...
        x, u, j, h, lower, upper, f0, P13)
if u(j)-h < lower
    up = u;
    up(j) = up(j)+h;
    column = (tiltrotor_eom_13x10(x,up,P13)-f0)/h;
    scheme = 'forward';
elseif u(j)+h > upper
    um = u;
    um(j) = um(j)-h;
    column = (f0-tiltrotor_eom_13x10(x,um,P13))/h;
    scheme = 'backward';
else
    up = u;
    um = u;
    up(j) = up(j)+h;
    um(j) = um(j)-h;
    fp = tiltrotor_eom_13x10(x,up,P13);
    fm = tiltrotor_eom_13x10(x,um,P13);
    column = (fp-fm)/(2*h);
    scheme = 'central';
end
end

function [xLower, xUpper, uLower, uUpper] = bounds_13x10(P13)
xLower = -inf(13,1);
xUpper = inf(13,1);
xLower(10:11) = P13.nacelle.betaMin;
xUpper(10:11) = P13.nacelle.betaMax;
xLower(12:13) = -P13.nacelle.betaDotLim;
xUpper(12:13) = P13.nacelle.betaDotLim;

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
uLower(9:10) = -P13.nacelle.torqueLim;
uUpper(9:10) = P13.nacelle.torqueLim;
end

function steps = difference_steps(P13, fieldName, n)
if isfield(P13, 'linear') && isfield(P13.linear, fieldName)
    steps = P13.linear.(fieldName)(:);
else
    steps = 1e-4*ones(n,1);
end
if numel(steps) ~= n || any(~isfinite(steps)) || any(steps <= 0)
    error('linearize_13x10_numeric:InvalidStep', ...
        'P13.linear.%s must be a positive %d-vector.', fieldName, n);
end
end
