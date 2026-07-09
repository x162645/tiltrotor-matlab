function [A, B, report] = linearize_13x10_numeric(x13, u10, P13)
%LINEARIZE_13X10_NUMERIC Center-difference linearization for 13x10 model.

if nargin < 3 || isempty(P13)
    P13 = params_berger13();
end
x13 = x13(:);
u10 = u10(:);
if numel(x13) ~= 13 || numel(u10) ~= 10
    error('linearize_13x10_numeric:DimensionMismatch', ...
        'Expected 13 states and 10 controls.');
end
if any(~isfinite(x13)) || any(~isfinite(u10)) || ~isreal(x13) || ~isreal(u10)
    error('linearize_13x10_numeric:InvalidOperatingPoint', ...
        'Operating point must be finite and real.');
end

dx = difference_steps(P13, 'dx', 13);
du = difference_steps(P13, 'du', 10);
A = zeros(13, 13);
B = zeros(13, 10);

for j = 1:13
    xp = x13;
    xm = x13;
    xp(j) = xp(j) + dx(j);
    xm(j) = xm(j) - dx(j);
    fp = tiltrotor_eom_13x10(xp, u10, P13);
    fm = tiltrotor_eom_13x10(xm, u10, P13);
    A(:,j) = (fp-fm)/(2*dx(j));
end

for j = 1:10
    up = u10;
    um = u10;
    up(j) = up(j) + du(j);
    um(j) = um(j) - du(j);
    fp = tiltrotor_eom_13x10(x13, up, P13);
    fm = tiltrotor_eom_13x10(x13, um, P13);
    B(:,j) = (fp-fm)/(2*du(j));
end

f0 = tiltrotor_eom_13x10(x13, u10, P13);
report.f0 = f0;
report.finite = isreal(A) && isreal(B) && isreal(f0) && ...
    all(isfinite(A(:))) && all(isfinite(B(:))) && all(isfinite(f0(:)));
report.stateNames = get_state_names_13x10();
report.controlNames = get_control_input_names_13x10();
report.ASize = size(A);
report.BSize = size(B);
report.ANorm = norm(A, 'fro');
report.BNorm = norm(B, 'fro');
report.conditionNumber = cond(A + 1e-9*eye(size(A)));
report.warnings = {};
end

function steps = difference_steps(P13, fieldName, n)
if isfield(P13, 'linear') && isfield(P13.linear, fieldName)
    steps = P13.linear.(fieldName)(:);
else
    steps = 1e-4*ones(n, 1);
end
if numel(steps) ~= n || any(~isfinite(steps)) || any(steps <= 0)
    error('linearize_13x10_numeric:InvalidStep', ...
        'P13.linear.%s must be a positive %d-vector.', fieldName, n);
end
end
