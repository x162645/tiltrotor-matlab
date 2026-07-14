function [A, B, report] = linearize_numeric(xe, ue, betaM, P)
%LINEARIZE_NUMERIC Center-difference linearization at one operating point.

xe = xe(:);
ue = ue(:);

nx = numel(xe);
nu = numel(ue);
expectedNx = get_state_dimension(P);
expectedNu = numel(get_control_input_names(P));

if nx ~= expectedNx || nu ~= expectedNu
    error('linearize_numeric:DimensionMismatch', ...
        'Expected %d states and %d controls.', expectedNx, expectedNu);
end

if ~isreal(xe) || ~isreal(ue) || ...
        any(~isfinite(xe)) || any(~isfinite(ue))
    error('linearize_numeric:InvalidOperatingPoint', ...
        'Linearization point must contain finite real values.');
end

if ~(isscalar(betaM) && isreal(betaM) && isfinite(betaM))
    error('linearize_numeric:InvalidNacelleAngle', ...
        'betaM must be a finite real scalar.');
end

dx = state_difference_steps(P, nx);
du = control_difference_steps(P, nu);

if numel(dx) ~= nx || numel(du) ~= nu
    error('linearize_numeric:StepDimensionMismatch', ...
        'Difference-step dimensions do not match state/control dimensions.');
end

if ~isreal(dx) || ~isreal(du) || ...
        any(~isfinite(dx)) || any(~isfinite(du)) || ...
        any(dx <= 0) || any(du <= 0)
    error('linearize_numeric:InvalidDifferenceSteps', ...
        'Difference steps must be finite positive real values.');
end

A = zeros(nx,nx);
B = zeros(nx,nu);

for j = 1:nx
    xp = xe;
    xm = xe;
    xp(j) = xp(j) + dx(j);
    xm(j) = xm(j) - dx(j);

    fp = tiltrotor_eom(xp, ue, betaM, P);
    fm = tiltrotor_eom(xm, ue, betaM, P);

    A(:,j) = (fp - fm)/(2*dx(j));
end

for j = 1:nu
    up = ue;
    um = ue;
    up(j) = up(j) + du(j);
    um(j) = um(j) - du(j);

    fp = tiltrotor_eom(xe, up, betaM, P);
    fm = tiltrotor_eom(xe, um, betaM, P);

    B(:,j) = (fp - fm)/(2*du(j));
end

f0 = tiltrotor_eom(xe, ue, betaM, P);

report.f0 = f0;
report.dx = dx;
report.du = du;
report.finite = isreal(A) && isreal(B) && isreal(f0) && ...
    all(isfinite(A(:))) && all(isfinite(B(:))) && all(isfinite(f0(:)));
end

function du = control_difference_steps(P, nu)
duBase = P.linear.du(:);
if numel(duBase) == nu
    du = duBase;
elseif nu == 8 && numel(duBase) == 7
    du = [duBase(1:4); duBase(4); duBase(5:7)];
else
    error('linearize_numeric:ControlStepDimensionMismatch', ...
        'P.linear.du size does not match the active control dimension.');
end
end

function dx = state_difference_steps(P, nx)
dxBase = P.linear.dx(:);
if numel(dxBase) == nx
    dx = dxBase;
elseif nx == 11 && numel(dxBase) == 9 && ...
        isfield(P, 'nacelleDynamics') && ...
        isfield(P.nacelleDynamics, 'linearDx')
    dx = [dxBase; P.nacelleDynamics.linearDx(:)];
else
    error('linearize_numeric:StateStepDimensionMismatch', ...
        'P.linear.dx size does not match the active state dimension.');
end
end
