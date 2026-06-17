function validate_inputs(x, uCtrl, betaM, P)
%VALIDATE_INPUTS 检查状态、控制、短舱角和主要参数。

assert(isnumeric(x) && isreal(x) && numel(x) == 9, ...
    'x 必须是 9 元实数向量。');
assert(isnumeric(uCtrl) && isreal(uCtrl) && numel(uCtrl) == 7, ...
    'uCtrl 必须是 7 元实数向量。');
assert(all(isfinite(x(:))), 'x 中存在 NaN 或 Inf。');
assert(all(isfinite(uCtrl(:))), 'uCtrl 中存在 NaN 或 Inf。');
assert(isscalar(betaM) && isfinite(betaM), 'betaM 必须是有限标量。');
assert(betaM >= -1e-9 && betaM <= pi/2 + 1e-9, ...
    'betaM 应位于 0 到 pi/2。');

assert(P.mass.m > 0, '整机质量必须为正。');
assert(P.rotor.R > 0 && P.rotor.Omega > 0, ...
    '旋翼半径和转速必须为正。');
assert(P.rotor.nRadial >= 3 && P.rotor.nAzimuth >= 4, ...
    '旋翼离散网格过小。');

I0 = 0.5*(P.mass.I0 + P.mass.I0.');
assert(all(eig(I0) > 0), '名义惯量矩阵必须正定。');
end
