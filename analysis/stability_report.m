function report = stability_report(A, tolerance)
%STABILITY_REPORT 整理全系统和纵/横向子系统特征值。

if nargin < 2
    tolerance = 1e-7;
end

if ~ismatrix(A) || size(A,1) ~= size(A,2)
    error('A 必须是方阵。');
end

report.full = eig(A);
report.maxRealPart = max(real(report.full));
report.openLoopStable = all(real(report.full) < tolerance);

% 状态顺序：[u v w p q r phi theta psi]
idxLong = [1, 3, 5, 8];
idxLat  = [2, 4, 6, 7, 9];

if size(A,1) >= 9
    report.longitudinal = eig(A(idxLong,idxLong));
    report.lateral = eig(A(idxLat,idxLat));
else
    report.longitudinal = [];
    report.lateral = [];
end
end
