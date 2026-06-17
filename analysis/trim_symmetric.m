function [xTrim, uTrim, report] = trim_symmetric(V, betaM, P, opts)
%TRIM_SYMMETRIC 对称定常飞行配平。
%
% 待求变量：
% z(1) = theta
% z(2) = collective
% z(3) = 统一纵向俯仰操纵指令
%
% 过渡混控：
% eta = sin(betaM)^2
% cyclic  = (1-eta)*pitchCommand
% elevator = eta*pitchCommand
%
% 配平残差：
% [udot, wdot, qdot]。

if nargin < 4
    opts = struct();
end

if ~isfield(opts, 'gamma')
    opts.gamma = 0;
end

if ~isfield(opts, 'initialDeg')
    if V < 1
        opts.initialDeg = [0, 18, 0];
    elseif betaM < pi/4
        opts.initialDeg = [4, 12, 4];
    else
        opts.initialDeg = [4, 8, -4];
    end
end

if numel(opts.initialDeg) < 3
    error('opts.initialDeg 至少应包含 [theta, collective, pitchCommand]。');
end

d2r = pi/180;
z0 = opts.initialDeg(1:3).'*d2r;

options = optimset( ...
    'Display', P.trim.display, ...
    'MaxIter', P.trim.maxIterations, ...
    'MaxFunEvals', 10*P.trim.maxIterations, ...
    'TolX', 1e-8, ...
    'TolFun', 1e-10);

objective = @(z) trim_cost(z);
[zOpt, fval, exitflag, output] = fminsearch(objective, z0, options);

[xTrim, uTrim, residual] = build_point(zOpt);

report.residual = residual;
report.residualNorm = norm(residual);
report.cost = fval;
report.exitflag = exitflag;
report.output = output;
report.converged = report.residualNorm < P.trim.residualTolerance;
report.betaM = betaM;
report.V = V;
report.gamma = opts.gamma;

    function J = trim_cost(z)
        [~, ~, R, penalty] = build_point(z);
        scale = [P.env.g; P.env.g; 1.0];
        Rs = R./scale;
        J = Rs.'*Rs + penalty;
    end

    function [xCandidate, uCandidate, R, penalty] = build_point(z)
        theta = z(1);
        collective = z(2);
        pitchCommand = z(3);

        alpha = theta - opts.gamma;

        if V < 1e-10
            u = 0;
            w = 0;
        else
            u = V*cos(alpha);
            w = V*sin(alpha);
        end

        xCandidate = [u; 0; w; 0; 0; 0; 0; theta; 0];

        eta = sin(betaM)^2;
        cyclic = (1-eta)*pitchCommand;
        elevator = eta*pitchCommand;

        uCandidate = [collective; 0; cyclic; 0; 0; elevator; 0];

        [xd, ~] = tiltrotor_eom(xCandidate, uCandidate, betaM, P);
        R = [xd(1); xd(3); xd(5)];

        penalty = 0;
        penalty = penalty + bound_penalty(collective, P.control.collectiveLim);
        penalty = penalty + bound_penalty(cyclic, P.control.cyclicLim);
        penalty = penalty + bound_penalty(elevator, P.control.elevatorLim);
        penalty = penalty + 10*max(abs(theta)-35*d2r,0)^2;
    end

    function value = bound_penalty(xValue, limits)
        below = max(limits(1)-xValue, 0);
        above = max(xValue-limits(2), 0);
        value = 100*(below^2 + above^2);
    end
end
