function mp = mass_properties(betaM, P)
%MASS_PROPERTIES 计算短舱倾转引起的重心移动与惯量变化。
% 对应论文式(1)~(3)的低阶实现。

dx = P.mass.mNac * P.mass.RH * sin(betaM) / P.mass.m;
dz = P.mass.mNac * P.mass.RH * (1 - cos(betaM)) / P.mass.m;

mp.cgShift = [dx; 0; dz];

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
