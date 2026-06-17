clear; clc; close all;

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir,'model'));
addpath(fullfile(rootDir,'analysis'));

P = params_nominal();

opts.gamma = 0;
opts.initialDeg = [0, 18, 0];
[xTrim,uTrim,report] = trim_symmetric(0,0,P,opts);

if ~report.converged
    warning('悬停配平残差较大，仍继续演示。');
end

betaM = 0;
stepCollective = 0.5*pi/180;

odeOptions = odeset('RelTol',1e-6,'AbsTol',1e-8);
[t,x] = ode45(@plant,[0 8],xTrim,odeOptions);

figure('Name','Hover collective-step response');
plot(t,-x(:,3),'LineWidth',1.3);
grid on;
xlabel('Time (s)');
ylabel('Upward body velocity -w (m/s)');
title('Response to a 0.5 deg collective pulse');

figure('Name','Pitch response');
plot(t,x(:,8)*180/pi,'LineWidth',1.3);
grid on;
xlabel('Time (s)');
ylabel('Pitch attitude (deg)');
title('Pitch attitude during collective pulse');

    function xdot = plant(time,state)
        u = uTrim;
        if time >= 1 && time <= 2
            u(1) = u(1) + stepCollective;
        end
        xdot = tiltrotor_eom(state,u,betaM,P);
    end
