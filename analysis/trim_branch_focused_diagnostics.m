function report = trim_branch_focused_diagnostics()
%TRIM_BRANCH_FOCUSED_DIAGNOSTICS Focused local diagnostics for review.
%
% Scope:
%   1) Solve V=9.05:0.01:9.30 with low/high branch seeds.
%   2) Check V=9.06 high-branch Jacobian sensitivity for requested steps.
% This diagnostic does not modify model physics, trim thresholds, state
% definitions, or trim_symmetric.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir, 'model'));
addpath(fullfile(rootDir, 'analysis'));

P = params_nominal();
cfg.betaM = 0;
cfg.gamma = 0;
cfg.residualTolerance = P.trim.residualTolerance;
cfg.solutionTolDeg = [0.02, 0.02, 0.02];
cfg.jacobianSteps = [1.0e-3, 3.0e-4, 1.0e-4, 3.0e-5, 1.0e-5];
cfg.lowSeedDeg = [-1.266147, 16.930183, 0.194724];
cfg.highSeedDeg = [6.657840, 16.248539, 2.350802];
cfg.highV906SeedDeg = [6.734621267, 16.268379643, 2.392635643];
speeds = 9.05:0.01:9.30;

stamp = datestr(now, 'yyyymmdd_HHMMSS');
resultDir = fullfile(rootDir, 'results');
if ~exist(resultDir, 'dir')
    mkdir(resultDir);
end

fprintf('\nFocused trim branch diagnostics\n');
fprintf('===============================\n');
fprintf('Residual tolerance: %.12e\n', cfg.residualTolerance);

report.generatedAt = datestr(now, 31);
report.config = cfg;
report.dualSeedScan = run_dual_seed_scan(speeds, P, cfg);
report.jacobianStepStudyV906 = run_v906_step_study(P, cfg);
report.paths.summary = fullfile(resultDir, ...
    ['trim_branch_focused_diagnostics_' stamp '.txt']);
write_summary(report, report.paths.summary);
fprintf('\nSaved focused diagnostic summary: %s\n', report.paths.summary);
end

function scan = run_dual_seed_scan(speeds, P, cfg)
scan = repmat(make_empty_speed_item(), numel(speeds), 1);
fprintf('\nDual-seed scan, V=9.05:0.01:9.30\n');
fprintf('---------------------------------\n');
fprintf('V distinct lowTheta highTheta lowNorm highNorm\n');
for k = 1:numel(speeds)
    V = speeds(k);
    item = make_empty_speed_item();
    item.V = V;
    item.attempts(1) = solve_once(V, cfg.lowSeedDeg, 'low_seed', P, cfg);
    item.attempts(2) = solve_once(V, cfg.highSeedDeg, 'high_seed', P, cfg);
    item.lowResidualSolutions = unique_solutions( ...
        item.attempts([item.attempts.success]), cfg.solutionTolDeg);
    scan(k) = item;
    fprintf('%5.2f %d % .6f % .6f % .3e % .3e\n', V, ...
        numel(item.lowResidualSolutions), item.attempts(1).solutionDeg(1), ...
        item.attempts(2).solutionDeg(1), item.attempts(1).residualNorm, ...
        item.attempts(2).residualNorm);
end
end

function study = run_v906_step_study(P, cfg)
attempt = solve_once(9.06, cfg.highV906SeedDeg, 'v9p06_high_seed', P, cfg);
z = attempt.zRad;
scale = [P.env.g; P.env.g; 1.0];
study.V = 9.06;
study.seedDeg = cfg.highV906SeedDeg;
study.solutionDeg = attempt.solutionDeg;
study.residual = attempt.residual;
study.residualNorm = attempt.residualNorm;
study.scaledResidualNorm = norm(attempt.residual./scale);
study.exitflag = attempt.exitflag;
study.success = attempt.success;
study.steps = repmat(make_empty_step(), numel(cfg.jacobianSteps), 1);

fprintf('\nV=9.06 high-branch Jacobian step sensitivity\n');
fprintf('--------------------------------------------\n');
fprintf(['h rawRank rawS1 rawS2 rawS3 rawCond scaledRank scaledS1 ' ...
    'scaledS2 scaledS3 scaledCond residual scaledResidual\n']);
for i = 1:numel(cfg.jacobianSteps)
    h = cfg.jacobianSteps(i);
    J = jacobian_matrix(study.V, z, P, cfg, h);
    Js = diag(1./scale)*J;
    raw = jacobian_report(J, h);
    scaled = jacobian_report(Js, h);
    study.steps(i).h = h;
    study.steps(i).raw = raw;
    study.steps(i).scaled = scaled;
    sr = raw.singularValues;
    ss = scaled.singularValues;
    fprintf(['%.1e %d %.6e %.6e %.6e %.6e %d %.6e %.6e %.6e ' ...
        '%.6e %.6e %.6e\n'], h, raw.rank, sr(1), sr(2), sr(3), ...
        raw.conditionNumber, scaled.rank, ss(1), ss(2), ss(3), ...
        scaled.conditionNumber, study.residualNorm, ...
        study.scaledResidualNorm);
end
end

function attempt = solve_once(V, seedDeg, source, P, cfg)
opts.gamma = cfg.gamma;
opts.initialDeg = seedDeg;
opts.useMultiStart = false;
opts.alwaysMultiStart = false;
[xTrim, uTrim, info] = trim_symmetric(V, cfg.betaM, P, opts);
z = [xTrim(8); uTrim(1); uTrim(3)];
attempt.source = source;
attempt.initialDeg = seedDeg;
attempt.solutionDeg = z(:).'*180/pi;
attempt.zRad = z;
attempt.residual = info.residual(:);
attempt.residualNorm = info.residualNorm;
attempt.exitflag = info.exitflag;
attempt.output = info.output;
attempt.success = info.exitflag > 0 && ...
    info.residualNorm <= cfg.residualTolerance && ...
    info.finiteFullStateDerivative && ...
    ~info.atLimit && info.withinLimits;
attempt.jacobian = jacobian_report( ...
    jacobian_matrix(V, z, P, cfg, 1.0e-4), 1.0e-4);
end

function J = jacobian_matrix(V, z, P, cfg, h)
J = zeros(3, 3);
for i = 1:3
    dz = zeros(3, 1);
    dz(i) = h;
    J(:, i) = (residual_at_z(V, z + dz, P, cfg) - ...
        residual_at_z(V, z - dz, P, cfg))/(2*h);
end
end

function jac = jacobian_report(J, h)
s = svd(J);
if isempty(s) || max(s) == 0
    rankTol = 0;
else
    rankTol = max(size(J))*eps(max(s));
end
if isempty(s) || s(end) <= rankTol
    condJ = Inf;
    minSingular = NaN;
else
    condJ = s(1)/s(end);
    minSingular = s(end);
end
jac.stepRad = h;
jac.matrix = J;
jac.singularValues = s(:).';
jac.rankTolerance = rankTol;
jac.rank = sum(s > rankTol);
jac.minSingularValue = minSingular;
jac.conditionNumber = condJ;
jac.hasNaNInf = any(~isfinite(J(:)));
jac.hasComplex = ~isreal(J);
end

function R = residual_at_z(V, z, P, cfg)
theta = z(1);
collective = z(2);
cyclicLong = z(3);
alpha = theta - cfg.gamma;
u = V*cos(alpha);
w = V*sin(alpha);
x = [u; 0; w; 0; 0; 0; 0; theta; 0];
uCtrl = [collective; 0; cyclicLong; 0; 0; 0; 0];
xdot = tiltrotor_eom(x, uCtrl, cfg.betaM, P);
R = [xdot(1); xdot(3); xdot(5)];
end

function solutions = unique_solutions(attempts, tolDeg)
solutions = repmat(make_empty_solution(), 0, 1);
for i = 1:numel(attempts)
    a = attempts(i);
    matched = false;
    for j = 1:numel(solutions)
        if all(abs(a.solutionDeg - solutions(j).solutionDeg) <= tolDeg)
            solutions(j).count = solutions(j).count + 1;
            solutions(j).seedSources = [solutions(j).seedSources ',' a.source];
            if a.residualNorm < solutions(j).residualNorm
                solutions(j).solutionDeg = a.solutionDeg;
                solutions(j).residualNorm = a.residualNorm;
                solutions(j).jacobian = a.jacobian;
            end
            matched = true;
            break;
        end
    end
    if ~matched
        sol = make_empty_solution();
        sol.solutionDeg = a.solutionDeg;
        sol.residualNorm = a.residualNorm;
        sol.count = 1;
        sol.seedSources = a.source;
        sol.jacobian = a.jacobian;
        solutions(end+1, 1) = sol; %#ok<AGROW>
    end
end
end

function write_summary(report, filePath)
fid = fopen(filePath, 'w');
if fid < 0
    warning('Could not write focused diagnostic summary: %s', filePath);
    return;
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, 'Focused trim branch diagnostics\n');
fprintf(fid, 'Generated: %s\n\n', report.generatedAt);
fprintf(fid, 'Dual-seed unique low-residual solutions, V=9.05:0.01:9.30\n');
fprintf(fid, '-----------------------------------------------------------\n');
for i = 1:numel(report.dualSeedScan)
    item = report.dualSeedScan(i);
    fprintf(fid, 'V=%.2f count=%d\n', item.V, numel(item.lowResidualSolutions));
    for j = 1:numel(item.lowResidualSolutions)
        sol = item.lowResidualSolutions(j);
        s = sol.jacobian.singularValues;
        fprintf(fid, ['  #%d theta=%.9f collective=%.9f cyclicLong=%.9f ' ...
            'residualNorm=%.12e rank=%d rankTol=%.12e ' ...
            's=[%.12e %.12e %.12e] cond=%.12e sources=%s\n'], ...
            j, sol.solutionDeg(1), sol.solutionDeg(2), ...
            sol.solutionDeg(3), sol.residualNorm, sol.jacobian.rank, ...
            sol.jacobian.rankTolerance, s(1), s(2), s(3), ...
            sol.jacobian.conditionNumber, sol.seedSources);
    end
    for j = 1:numel(item.attempts)
        a = item.attempts(j);
        fprintf(fid, ['  attempt source=%s success=%d initial=[%.9f %.9f %.9f] ' ...
            'final=[%.9f %.9f %.9f] residualNorm=%.12e exitflag=%d\n'], ...
            a.source, a.success, a.initialDeg(1), a.initialDeg(2), ...
            a.initialDeg(3), a.solutionDeg(1), a.solutionDeg(2), ...
            a.solutionDeg(3), a.residualNorm, a.exitflag);
    end
end

study = report.jacobianStepStudyV906;
fprintf(fid, '\nV=9.06 high-branch Jacobian step sensitivity\n');
fprintf(fid, '--------------------------------------------\n');
fprintf(fid, ['solutionDeg=[%.9f %.9f %.9f], residualNorm=%.12e, ' ...
    'scaledResidualNorm=%.12e, exitflag=%d, success=%d\n'], ...
    study.solutionDeg(1), study.solutionDeg(2), study.solutionDeg(3), ...
    study.residualNorm, study.scaledResidualNorm, study.exitflag, ...
    study.success);
fprintf(fid, ['h rawRank rawRankTol rawS1 rawS2 rawS3 rawSmin rawCond ' ...
    'scaledRank scaledRankTol scaledS1 scaledS2 scaledS3 scaledSmin ' ...
    'scaledCond\n']);
for i = 1:numel(study.steps)
    step = study.steps(i);
    sr = step.raw.singularValues;
    ss = step.scaled.singularValues;
    fprintf(fid, ['%.12e %d %.12e %.12e %.12e %.12e %.12e %.12e ' ...
        '%d %.12e %.12e %.12e %.12e %.12e %.12e\n'], ...
        step.h, step.raw.rank, step.raw.rankTolerance, sr(1), sr(2), ...
        sr(3), step.raw.minSingularValue, step.raw.conditionNumber, ...
        step.scaled.rank, step.scaled.rankTolerance, ss(1), ss(2), ...
        ss(3), step.scaled.minSingularValue, ...
        step.scaled.conditionNumber);
end
end

function item = make_empty_speed_item()
item = struct( ...
    'V', NaN, ...
    'attempts', repmat(make_empty_attempt(), 2, 1), ...
    'lowResidualSolutions', repmat(make_empty_solution(), 0, 1));
end

function attempt = make_empty_attempt()
attempt = struct( ...
    'source', '', ...
    'initialDeg', [NaN, NaN, NaN], ...
    'solutionDeg', [NaN, NaN, NaN], ...
    'zRad', [NaN; NaN; NaN], ...
    'residual', [NaN; NaN; NaN], ...
    'residualNorm', NaN, ...
    'exitflag', NaN, ...
    'output', struct(), ...
    'success', false, ...
    'jacobian', struct());
end

function sol = make_empty_solution()
sol = struct( ...
    'solutionDeg', [NaN, NaN, NaN], ...
    'residualNorm', NaN, ...
    'count', 0, ...
    'seedSources', '', ...
    'jacobian', struct());
end

function step = make_empty_step()
step = struct('h', NaN, 'raw', struct(), 'scaled', struct());
end
