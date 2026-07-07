function [A, B, report] = linearize_numeric(xe, ue, betaM, P)
%LINEARIZE_NUMERIC 在给定配平点进行中心差分线性化。
% 对应论文式(38)~(42)。

xe = xe(:);
ue = ue(:);

nx = numel(xe);
nu = numel(ue);
expectedNx = get_state_dimension(P);

if nx ~= expectedNx || nu ~= 7
    error('linearize_numeric:DimensionMismatch', ...
        '当前模型要求 %d 状态、7 控制。', expectedNx);
end

if ~isreal(xe) || ~isreal(ue) || ...
        any(~isfinite(xe)) || any(~isfinite(ue))
    error('线性化基点必须是有限实数。');
end

if ~(isscalar(betaM) && isreal(betaM) && isfinite(betaM))
    error('betaM 必须是有限实数标量。');
end

dx = state_difference_steps(P, nx);
du = P.linear.du(:);

if numel(dx) ~= nx || numel(du) ~= nu
    error('差分步长尺寸与状态/控制维数不一致。');
end

if ~isreal(dx) || ~isreal(du) || ...
        any(~isfinite(dx)) || any(~isfinite(du)) || ...
        any(dx <= 0) || any(du <= 0)
    error('线性化差分步长必须为有限正实数。');
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
