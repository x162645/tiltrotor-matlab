clear; clc; close all;

rootDir = fileparts(mfilename('fullpath'));
addpath(rootDir);
addpath(fullfile(rootDir,'model'));
addpath(fullfile(rootDir,'analysis'));
addpath(fullfile(rootDir,'tests'));

resultDir = fullfile(rootDir,'results');
if ~exist(resultDir,'dir')
    mkdir(resultDir);
end

P = params_nominal();
d2r = pi/180;

cases = {
    'Hover',              0,   0, [0, 18,  0];
    'Helicopter 20 m/s', 20,   0, [4, 12,  3];
    'Transition 15 deg', 25,  15, [5, 12,  3];
    'Transition 30 deg', 30,  30, [6, 12,  2];
    'Transition 45 deg', 35,  45, [7, 11,  0];
    'Airplane 100 m/s', 100, 90, [4,  8, -4]
};

nCase = size(cases,1);
results = repmat(struct(),nCase,1);

fprintf('\nTiltrotor forward mechanistic model v2\n');
fprintf('=====================================\n');

for k = 1:nCase
    name = cases{k,1};
    V = cases{k,2};
    betaDeg = cases{k,3};

    opts.gamma = 0;
    opts.initialDeg = cases{k,4};

    [xTrim,uTrim,report] = trim_symmetric(V,betaDeg*d2r,P,opts);

    results(k).name = name;
    results(k).V = V;
    results(k).betaDeg = betaDeg;
    results(k).xTrim = xTrim;
    results(k).uTrim = uTrim;
    results(k).report = report;

    fprintf('%-22s residual=%10.3e converged=%d\n', ...
        name, report.residualNorm, report.converged);
    fprintf(' theta=%8.3f deg, collective=%8.3f deg, cyclic=%8.3f deg, elevator=%8.3f deg\n', ...
        xTrim(8)/d2r, uTrim(1)/d2r, uTrim(3)/d2r, uTrim(6)/d2r);
end

% 对最后一个工况线性化。
xe = results(end).xTrim;
ue = results(end).uTrim;
betaM = results(end).betaDeg*d2r;

[A,B,linearReport] = linearize_numeric(xe,ue,betaM,P);
stab = stability_report(A,P.linear.stabilityTolerance);

fprintf('\nAirplane-mode full-system eigenvalues:\n');
disp(stab.full);
fprintf('Maximum real part: %.6f\n',stab.maxRealPart);
fprintf('Open-loop stable flag: %d\n',stab.openLoopStable);

save(fullfile(resultDir,'demo_results.mat'), ...
    'P','results','A','B','linearReport','stab');

collective = zeros(nCase,1);
cyclic = zeros(nCase,1);
elevator = zeros(nCase,1);
theta = zeros(nCase,1);

for k = 1:nCase
    collective(k) = results(k).uTrim(1)/d2r;
    cyclic(k) = results(k).uTrim(3)/d2r;
    elevator(k) = results(k).uTrim(6)/d2r;
    theta(k) = results(k).xTrim(8)/d2r;
end

figure('Name','Tiltrotor trim controls');
plot(1:nCase,collective,'o-','LineWidth',1.2); hold on;
plot(1:nCase,cyclic,'s-','LineWidth',1.2);
plot(1:nCase,elevator,'^-','LineWidth',1.2);
plot(1:nCase,theta,'d-','LineWidth',1.2);
grid on;
xlabel('Flight case');
ylabel('Angle (deg)');
legend('Collective','Longitudinal cyclic','Elevator','Pitch attitude', ...
    'Location','best');
title('Symmetric trim results');
xticks(1:nCase);
xticklabels(cases(:,1));
xtickangle(25);
