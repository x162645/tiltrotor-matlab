clear; clc;

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir,'model'));
addpath(fullfile(rootDir,'analysis'));

P = params_nominal();

opts.gamma = 0;
opts.initialDeg = [0, 18, 0];

[xTrim,uTrim,report] = trim_symmetric(0,0,P,opts);
[xdot,out] = tiltrotor_eom(xTrim,uTrim,0,P);

fprintf('Hover trim\n');
fprintf('----------\n');
fprintf('Residual norm: %.6e\n',report.residualNorm);
fprintf('Converged: %d\n',report.converged);
fprintf('Collective: %.6f deg\n',uTrim(1)*180/pi);
fprintf('Longitudinal cyclic: %.6f deg\n',uTrim(3)*180/pi);
fprintf('Pitch attitude: %.6f deg\n',xTrim(8)*180/pi);
fprintf('Total force including gravity [N]:\n');
disp(out.Ftotal);
fprintf('Total moment [N m]:\n');
disp(out.Mtotal);
fprintf('State derivative:\n');
disp(xdot);
