function jac = trim_residual_jacobian(V, betaM, gamma, z, P, opts)
%TRIM_RESIDUAL_JACOBIAN Central-difference trim residual Jacobian.
%
% Raw definition:
%   variables = [theta; collective; cyclicLong], rad
%   residuals = [udot; wdot; qdot], [m/s^2; m/s^2; rad/s^2]
%   J_raw(i,j) = d residual_i / d variable_j
%
% Optional scaled matrix, when opts.variableScale and/or opts.residualScale
% are supplied, is reported separately and must not be compared directly
% with the raw condition number.

if nargin < 6
    opts = struct();
end
if ~isfield(opts, 'jacobianStepRad')
    opts.jacobianStepRad = 1.0e-4;
end

h = opts.jacobianStepRad;
if ~(isnumeric(V) && isreal(V) && isscalar(V) && isfinite(V) && V >= 0)
    error('trim_residual_jacobian:InvalidAirspeed', ...
        'V must be a finite real scalar with V >= 0 m/s.');
end
if ~(isnumeric(betaM) && isreal(betaM) && isscalar(betaM) && ...
        isfinite(betaM) && betaM >= 0 && betaM <= pi/2)
    error('trim_residual_jacobian:InvalidNacelleAngle', ...
        'betaM must be a finite real scalar in [0, pi/2] rad.');
end
if ~(isnumeric(gamma) && isreal(gamma) && isscalar(gamma) && isfinite(gamma))
    error('trim_residual_jacobian:InvalidGamma', ...
        'gamma must be a finite real scalar in rad.');
end
if ~(isnumeric(z) && isreal(z) && isvector(z) && numel(z) == 3 && ...
        all(isfinite(z(:))))
    error('trim_residual_jacobian:InvalidTrimVariables', ...
        'z must be a finite real three-vector in rad.');
end
z = z(:);
if ~(isnumeric(h) && isreal(h) && isscalar(h) && isfinite(h) && h > 0)
    error('opts.jacobianStepRad must be a finite positive real scalar in rad.');
end

J = zeros(3, 3);
for i = 1:3
    dz = zeros(3, 1);
    dz(i) = h;
    rp = local_trim_residual_at_z(V, betaM, gamma, z + dz, P);
    rm = local_trim_residual_at_z(V, betaM, gamma, z - dz, P);
    J(:, i) = (rp - rm)/(2*h);
end

jac = make_report(J, h);
jac.definition = 'raw d[udot;wdot;qdot]/d[theta;collective;cyclicLong]';
jac.variables = {'theta', 'collective', 'cyclicLong'};
jac.variableUnits = {'rad', 'rad', 'rad'};
jac.residuals = {'udot', 'wdot', 'qdot'};
jac.residualUnits = {'m/s^2', 'm/s^2', 'rad/s^2'};
jac.isScaled = false;
jac.scaled = struct();

if isfield(opts, 'variableScale') || isfield(opts, 'residualScale')
    if isfield(opts, 'variableScale')
        variableScale = opts.variableScale(:);
    else
        variableScale = ones(3, 1);
    end
    if isfield(opts, 'residualScale')
        residualScale = opts.residualScale(:);
    else
        residualScale = ones(3, 1);
    end
    if numel(variableScale) ~= 3 || numel(residualScale) ~= 3 || ...
            any(~isfinite(variableScale)) || any(~isfinite(residualScale)) || ...
            any(variableScale <= 0) || any(residualScale <= 0)
        error('variableScale and residualScale must be finite positive 3-vectors.');
    end
    Jscaled = diag(1./residualScale)*J*diag(variableScale);
    jac.scaled = make_report(Jscaled, h);
    jac.scaled.definition = ...
        'scaled diag(1/residualScale)*J_raw*diag(variableScale)';
    jac.scaled.variableScale = variableScale;
    jac.scaled.residualScale = residualScale;
    jac.scaled.isScaled = true;
end
end

function rep = make_report(J, h)
[~, S, Vright] = svd(J);
s = diag(S);
if isempty(s) || s(1) == 0
    rankTol = 0;
    condJ = Inf;
else
    rankTol = max(size(J))*eps(s(1));
    if s(end) <= rankTol
        condJ = Inf;
    else
        condJ = s(1)/s(end);
    end
end

rep = struct( ...
    'stepRad', h, ...
    'matrix', J, ...
    'singularValues', s(:).', ...
    'rightSingularVectors', Vright, ...
    'minRightSingularVector', Vright(:, end), ...
    'rankTolerance', rankTol, ...
    'rank', sum(s > rankTol), ...
    'conditionNumber', condJ, ...
    'finite', is_real_finite(J), ...
    'hasComplex', ~isreal(J), ...
    'hasNaNInf', any(~isfinite(J(:))));
end

function R = local_trim_residual_at_z(V, betaM, gamma, z, P)
theta = z(1);
collective = z(2);
cyclicLong = z(3);
alpha = theta - gamma;
if V < 1e-10
    u = 0;
    w = 0;
else
    u = V*cos(alpha);
    w = V*sin(alpha);
end
x = [u; 0; w; 0; 0; 0; 0; theta; 0];
uCtrl = [collective; 0; cyclicLong; 0; 0; 0; 0];
xdot = tiltrotor_eom(x, uCtrl, betaM, P);
R = [xdot(1); xdot(3); xdot(5)];
end

function tf = is_real_finite(value)
tf = isreal(value) && all(isfinite(value(:)));
end
