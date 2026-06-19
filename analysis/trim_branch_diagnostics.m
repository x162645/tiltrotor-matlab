function report = trim_branch_diagnostics()
%TRIM_BRANCH_DIAGNOSTICS Diagnose low-speed helicopter trim branches.
%
% This diagnostic does not modify the physical model or control interface.
% Continuation scans disable trim_symmetric internal multistart so each
% speed point is solved strictly from the previous successful point. Rescue
% initials are tried only after the continuation attempt fails and are
% recorded in the returned report.
rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir, 'model'));
addpath(fullfile(rootDir, 'analysis'));

P = params_nominal();
d2r = pi/180;

baseOpts = struct();
baseOpts.betaM = 0;
baseOpts.gamma = 0;
baseOpts.initialDeg = [0, 18, 0];
baseOpts.useContinuation = true;
baseOpts.useTrimMultiStart = false;
baseOpts.allowRescueInitials = true;
baseOpts.fullResidualTolerance = max(P.trim.residualTolerance, 1.0e-6);
baseOpts.maxDeltaThetaDeg = 2.5;
baseOpts.maxDeltaControlDeg = 1.25;
baseOpts.signFlipThresholdDeg = 0.25;
baseOpts.jacobianStepRad = 1.0e-4;
baseOpts.rescueInitialDegs = [
     0, 18,  0;
    -4, 18, -1;
     4, 16,  2;
     8, 15,  4;
    -8, 20, -4;
    12, 14,  6];

ascOpts = baseOpts;
ascOpts.speeds = 0:1:20;
report.ascending = trim_sweep_helicopter(P, ascOpts);

descOpts = baseOpts;
descOpts.speeds = 20:-1:0;
descOpts.initialDeg = report.ascending.points(end).solutionDeg;
report.descending = trim_sweep_helicopter(P, descOpts);

denseOpts = baseOpts;
denseOpts.speeds = 4:0.5:12;
seedIndex = find([report.ascending.points.V] == 4, 1);
if ~isempty(seedIndex)
    denseOpts.initialDeg = report.ascending.points(seedIndex).solutionDeg;
end
report.dense = trim_sweep_helicopter(P, denseOpts);

multiSpeeds = [5, 7.5, 10];
initialSetsDeg = [
     0, 18,  0;
    -8, 20, -4;
    -4, 18, -1;
     4, 16,  2;
     8, 15,  4;
    12, 14,  6;
    18, 12, 10;
   -15, 24, -8;
    25, 10, 15;
   -25, 30,-15];
report.multistart = solve_multistart_grid(P, baseOpts, ...
    multiSpeeds, initialSetsDeg);
report.comparison = compare_bidirectional(report.ascending, ...
    report.descending);

print_branch_summary(report, d2r);
end

function multi = solve_multistart_grid(P, baseOpts, speeds, initialSetsDeg)
tolResidual = P.trim.residualTolerance;
solutionTolDeg = [0.05, 0.05, 0.05];
multi = repmat(struct( ...
    'V', NaN, ...
    'attempts', struct([]), ...
    'lowResidualSolutions', struct([])), numel(speeds), 1);

for iV = 1:numel(speeds)
    V = speeds(iV);
    attempts = repmat(make_attempt(), size(initialSetsDeg, 1), 1);
    for iStart = 1:size(initialSetsDeg, 1)
        trimOpts = struct();
        trimOpts.gamma = baseOpts.gamma;
        trimOpts.initialDeg = initialSetsDeg(iStart, :);
        trimOpts.useMultiStart = false;
        trimOpts.alwaysMultiStart = false;
        [xTrim, uTrim, info] = trim_symmetric( ...
            V, baseOpts.betaM, P, trimOpts);
        attempts(iStart).initialDeg = initialSetsDeg(iStart, :);
        attempts(iStart).solutionDeg = [xTrim(8), uTrim(1), ...
            uTrim(3)]*180/pi;
        attempts(iStart).exitflag = info.exitflag;
        attempts(iStart).residualNorm = info.residualNorm;
        attempts(iStart).lowResidual = info.exitflag > 0 && ...
            info.residualNorm <= tolResidual && ...
            info.finiteFullStateDerivative && ...
            ~info.atLimit && info.withinLimits;
        attempts(iStart).jacobian = local_jacobian_report( ...
            V, baseOpts.betaM, baseOpts.gamma, ...
            [xTrim(8); uTrim(1); uTrim(3)], P, ...
            baseOpts.jacobianStepRad);
    end

    lowAttempts = attempts([attempts.lowResidual]);
    multi(iV).V = V;
    multi(iV).attempts = attempts;
    multi(iV).lowResidualSolutions = unique_solutions( ...
        lowAttempts, solutionTolDeg);
end
end

function attempt = make_attempt()
attempt = struct( ...
    'initialDeg', [NaN, NaN, NaN], ...
    'solutionDeg', [NaN, NaN, NaN], ...
    'exitflag', NaN, ...
    'residualNorm', NaN, ...
    'lowResidual', false, ...
    'jacobian', struct());
end

function solutions = unique_solutions(attempts, tolDeg)
solutions = repmat(make_solution(), 0, 1);
for i = 1:numel(attempts)
    z = attempts(i).solutionDeg;
    matched = false;
    for j = 1:numel(solutions)
        if all(abs(z - solutions(j).solutionDeg) <= tolDeg)
            solutions(j).count = solutions(j).count + 1;
            solutions(j).seedIndices(end+1) = i;
            if attempts(i).residualNorm < solutions(j).residualNorm
                solutions(j).solutionDeg = z;
                solutions(j).residualNorm = attempts(i).residualNorm;
                solutions(j).jacobian = attempts(i).jacobian;
            end
            matched = true;
            break;
        end
    end
    if ~matched
        item = make_solution();
        item.solutionDeg = z;
        item.residualNorm = attempts(i).residualNorm;
        item.count = 1;
        item.seedIndices = i;
        item.jacobian = attempts(i).jacobian;
        solutions(end+1, 1) = item; %#ok<AGROW>
    end
end
end

function solution = make_solution()
solution = struct( ...
    'solutionDeg', [NaN, NaN, NaN], ...
    'residualNorm', NaN, ...
    'count', 0, ...
    'seedIndices', [], ...
    'jacobian', struct());
end

function comparison = compare_bidirectional(ascending, descending)
ascV = [ascending.points.V];
descV = [descending.points.V];
comparison = repmat(struct( ...
    'V', NaN, ...
    'thetaAscDeg', NaN, ...
    'thetaDescDeg', NaN, ...
    'collectiveAscDeg', NaN, ...
    'collectiveDescDeg', NaN, ...
    'cyclicLongAscDeg', NaN, ...
    'cyclicLongDescDeg', NaN, ...
    'deltaThetaDeg', NaN, ...
    'deltaCollectiveDeg', NaN, ...
    'deltaCyclicLongDeg', NaN), numel(ascV), 1);

for i = 1:numel(ascV)
    j = find(abs(descV - ascV(i)) < 1.0e-12, 1);
    if isempty(j)
        continue;
    end
    a = ascending.points(i);
    d = descending.points(j);
    comparison(i).V = ascV(i);
    comparison(i).thetaAscDeg = a.solutionDeg(1);
    comparison(i).thetaDescDeg = d.solutionDeg(1);
    comparison(i).collectiveAscDeg = a.solutionDeg(2);
    comparison(i).collectiveDescDeg = d.solutionDeg(2);
    comparison(i).cyclicLongAscDeg = a.solutionDeg(3);
    comparison(i).cyclicLongDescDeg = d.solutionDeg(3);
    comparison(i).deltaThetaDeg = ...
        comparison(i).thetaDescDeg - comparison(i).thetaAscDeg;
    comparison(i).deltaCollectiveDeg = ...
        comparison(i).collectiveDescDeg - comparison(i).collectiveAscDeg;
    comparison(i).deltaCyclicLongDeg = ...
        comparison(i).cyclicLongDescDeg - comparison(i).cyclicLongAscDeg;
end
end

function print_branch_summary(report, d2r)
fprintf('\nBidirectional branch comparison\n');
fprintf('===============================\n');
fprintf(['V[m/s] theta_up theta_down dTheta collective_up ' ...
    'collective_down dCollective cyclic_up cyclic_down dCyclic\n']);
for i = 1:numel(report.comparison)
    c = report.comparison(i);
    fprintf(['%5.1f % .6f % .6f % .6f % .6f % .6f % .6f ' ...
        '% .6f % .6f % .6f\n'], c.V, c.thetaAscDeg, ...
        c.thetaDescDeg, c.deltaThetaDeg, c.collectiveAscDeg, ...
        c.collectiveDescDeg, c.deltaCollectiveDeg, ...
        c.cyclicLongAscDeg, c.cyclicLongDescDeg, ...
        c.deltaCyclicLongDeg);
end

print_compact_scan('Ascending 0:1:20', report.ascending.points, d2r);
print_compact_scan('Descending 20:-1:0', report.descending.points, d2r);
print_compact_scan('Dense 4:0.5:12', report.dense.points, d2r);
print_multistart_summary(report.multistart);
end

function print_compact_scan(titleText, points, d2r)
fprintf('\n%s\n', titleText);
fprintf('%s\n', repmat('-', 1, numel(titleText)));
fprintf(['V theta collective cyclicLong trimNorm rescue jacRank ' ...
    'jacCond s1 s2 s3\n']);
for i = 1:numel(points)
    p = points(i);
    s = p.residualJacobian.singularValues;
    if numel(s) < 3
        s = [NaN, NaN, NaN];
    end
    fprintf(['%5.1f % .6f % .6f % .6f % .3e %d %d % .3e ' ...
        '% .3e % .3e % .3e\n'], ...
        p.V, p.xTrim(8)/d2r, p.uTrim(1)/d2r, p.uTrim(3)/d2r, ...
        p.trimResidualNorm, p.usedRescueInitial, ...
        p.residualJacobian.rank, p.residualJacobian.conditionNumber, ...
        s(1), s(2), s(3));
end
end

function print_multistart_summary(multistart)
fprintf('\nMulti-initial low-residual solutions\n');
fprintf('====================================\n');
for i = 1:numel(multistart)
    item = multistart(i);
    fprintf('V=%.1f m/s: %d distinct low-residual solution(s)\n', ...
        item.V, numel(item.lowResidualSolutions));
    for j = 1:numel(item.lowResidualSolutions)
        sol = item.lowResidualSolutions(j);
        s = sol.jacobian.singularValues;
        fprintf(['  #%d theta=% .6f collective=% .6f cyclicLong=% .6f ' ...
            'trimNorm=% .3e count=%d rank=%d cond=% .3e ' ...
            's=[% .3e % .3e % .3e]\n'], j, ...
            sol.solutionDeg(1), sol.solutionDeg(2), ...
            sol.solutionDeg(3), sol.residualNorm, sol.count, ...
            sol.jacobian.rank, sol.jacobian.conditionNumber, ...
            s(1), s(2), s(3));
    end
end
end

function jac = local_jacobian_report(V, betaM, gamma, z, P, h)
J = zeros(3, 3);
for i = 1:3
    dz = zeros(3, 1);
    dz(i) = h;
    J(:, i) = (local_residual(V, betaM, gamma, z + dz, P) - ...
        local_residual(V, betaM, gamma, z - dz, P))/(2*h);
end
s = svd(J);
if isempty(s) || max(s) == 0
    rankTol = 0;
else
    rankTol = max(size(J))*eps(max(s));
end
if isempty(s) || s(end) <= rankTol
    condJ = Inf;
else
    condJ = s(1)/s(end);
end
jac.matrix = J;
jac.singularValues = s(:).';
jac.rankTolerance = rankTol;
jac.rank = sum(s > rankTol);
jac.conditionNumber = condJ;
jac.finite = isreal(J) && all(isfinite(J(:)));
end

function R = local_residual(V, betaM, gamma, z, P)
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
