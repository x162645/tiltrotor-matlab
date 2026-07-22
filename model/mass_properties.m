function mp = mass_properties(betaM, P)
%MASS_PROPERTIES 计算短舱倾转引起的重心移动与惯量变化。
% 对应论文式(1)~(3)的低阶实现。

dx = P.mass.mNac * P.mass.RH_mass * sin(betaM) / P.mass.m;
dz = P.mass.mNac * P.mass.RH_mass * (1 - cos(betaM)) / P.mass.m;

% Optional opt-in longitudinal-layout interface.  The legacy/default
% parameter structure does not contain baselineCG, which is exactly
% equivalent to a zero vector.  Positive components are expressed in the
% body frame (x forward, y right, z down) from the unchanged model origin.
% This field is for explicitly named design variants; it is never inferred.
baselineCG = zeros(3,1);
if isfield(P.mass, 'baselineCG')
    baselineCG = P.mass.baselineCG(:);
    if numel(baselineCG) ~= 3 || ~isreal(baselineCG) || ...
            any(~isfinite(baselineCG))
        error('mass_properties:InvalidBaselineCG', ...
            'P.mass.baselineCG must be a finite real 3-element vector.');
    end
end

mp.cgShift = baselineCG + [dx; 0; dz];
mp.baselineCG = baselineCG;

I = P.mass.I0 - betaM * P.mass.KI;
I = 0.5*(I + I.');

principalMoments = eig(I);
if any(principalMoments <= 0)
    error('当前短舱角下的惯量矩阵非正定，请检查 I0 和 KI。');
end

mp.I = I;
mp.mass = P.mass.m;
mp.betaM = betaM;
mp.principalMoments = principalMoments;
mp.radiusOfGyration = sqrt(principalMoments / P.mass.m);
mp.inertiaSymmetryError = norm(I - I.', 'fro');
mp.minInertiaEigenvalue = min(principalMoments);
end
