function report = trim_branch_local_diagnostics()
%TRIM_BRANCH_LOCAL_DIAGNOSTICS Local branch diagnostics near V=9 m/s.
%
% This script does not change model physics, trim residual thresholds, state
% definitions, or control interfaces. It calls trim_symmetric with internal
% multistart disabled so the first attempt at each continuation point uses
% exactly the previous successful solution as the next initial value.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir, 'model'));
addpath(fullfile(rootDir, 'analysis'));

P = params_nominal();
d2r = pi/180;
stamp = datestr(now, 'yyyymmdd_HHMMSS');
resultDir = fullfile(rootDir, 'results');
if ~exist(resultDir, 'dir')
    mkdir(resultDir);
end

cfg = make_config(P);
speeds05Asc = 9.00:0.05:9.60;
speeds05Desc = 9.60:-0.05:9.00;

fprintf('\nLocal helicopter trim branch diagnostics\n');
fprintf('========================================\n');
fprintf('Residual tolerance from params: %.12e\n', P.trim.residualTolerance);
fprintf('0.05 m/s ascending speeds:');
fprintf(' %.2f', speeds05Asc);
fprintf('\n');
fprintf('0.05 m/s descending speeds:');
fprintf(' %.2f', speeds05Desc);
fprintf('\n');

report = struct();
report.generatedAt = datestr(now, 31);
report.config = cfg;
report.ascending05 = run_continuation( ...
    'ascending_0p05', speeds05Asc, cfg.ascInitialDeg, P, cfg);
report.descending05 = run_continuation( ...
    'descending_0p05', speeds05Desc, cfg.descInitialDeg, P, cfg);

intervals = collect_dense_intervals(report.ascending05, report.descending05, cfg);
report.denseIntervals = intervals;
report.dense = repmat(make_empty_dense_scan(), numel(intervals), 1);
for i = 1:numel(intervals)
    thisInterval = intervals(i);
    denseSpeeds = make_dense_speeds(thisInterval);
    if strcmp(thisInterval.direction, 'ascending')
        initialDeg = thisInterval.startSolutionDeg;
    else
        initialDeg = thisInterval.startSolutionDeg;
    end
    report.dense(i).direction = thisInterval.direction;
    report.dense(i).reason = thisInterval.reason;
    report.dense(i).startV = thisInterval.startV;
    report.dense(i).endV = thisInterval.endV;
    report.dense(i).scan = run_continuation( ...
        ['dense_' thisInterval.direction '_' num2str(i)], ...
        denseSpeeds, initialDeg, P, cfg);
end

report.multiseed05 = run_multiseed_search( ...
    speeds05Asc, report.ascending05, report.descending05, P, cfg);
report.dualSeedDense = run_dual_seed_dense_search( ...
    cfg.dualSeedDenseSpeeds, report.ascending05, report.descending05, ...
    P, cfg);
report.jacobianStepStudyV906 = run_jacobian_step_study( ...
    9.06, cfg.highBranchV906SeedDeg, P, cfg);

report.evidence = assess_evidence(report, cfg);
report.paths.mat = fullfile(resultDir, ...
    ['trim_branch_local_diagnostics_' stamp '.mat']);
report.paths.summary = fullfile(resultDir, ...
    ['trim_branch_local_diagnostics_' stamp '.txt']);
save(report.paths.mat, 'report');
write_summary(report, report.paths.summary, d2r);

fprintf('\nSaved local diagnostic MAT: %s\n', report.paths.mat);
fprintf('Saved local diagnostic summary: %s\n', report.paths.summary);
fprintf('Pseudo-arclength conclusion status: %s\n', ...
    report.evidence.pseudoArclengthConclusionStatus);
end

function cfg = make_config(P)
cfg.betaM = 0;
cfg.gamma = 0;
cfg.ascInitialDeg = [0, 18, 0];
cfg.descInitialDeg = [8, 15, 4];
cfg.rescueSeeds = struct( ...
    'source', {'rescue_default_hover', 'rescue_low_reference', ...
        'rescue_high_reference', 'rescue_legacy_high', ...
        'rescue_legacy_low'}, ...
    'initialDeg', {[0, 18, 0], [-1.260257, 16.935369, 0.193075], ...
        [6.580908, 16.228358, 2.308986], [8, 15, 4], ...
        [-4, 18, -1]});
cfg.residualTolerance = P.trim.residualTolerance;
cfg.maxDeltaThetaDeg = 2.5;
cfg.maxDeltaControlDeg = 1.25;
cfg.jacobianStepRad = 1.0e-4;
cfg.jacobianStepStudyRad = [1.0e-3, 3.0e-4, 1.0e-4, 3.0e-5, 1.0e-5];
cfg.solutionTolDeg = [0.02, 0.02, 0.02];
cfg.lowThetaMaxDeg = 1.0;
cfg.highThetaMinDeg = 2.0;
cfg.singularFoldTol = 1.0e-3;
cfg.dualSeedDenseSpeeds = 9.05:0.01:9.30;
cfg.highBranchV906SeedDeg = [6.734621267, 16.268379643, 2.392635643];
end

function scan = run_continuation(label, speeds, initialDeg, P, cfg)
scan.label = label;
scan.speeds = speeds(:).';
scan.points = repmat(make_empty_point(), numel(speeds), 1);
scan.firstStrictFailure = make_empty_attempt();
scan.hasStrictFailure = false;

currentInitialDeg = initialDeg(:).';
lastSuccessful = [];
fprintf('\nStrict continuation: %s\n', label);
fprintf('%s\n', repmat('-', 1, 21 + numel(label)));
fprintf(['V strict ok rescue theta collective cyclicLong residual ' ...
    'exit iter func branch limit\n']);

for k = 1:numel(speeds)
    V = speeds(k);
    point = make_empty_point();
    point.V = V;
    point.requestedInitialDeg = currentInitialDeg;

    strictAttempt = solve_once(V, currentInitialDeg, 'strict_previous', ...
        false, 0, P, cfg);
    point.strictAttempt = strictAttempt;
    point.attempts = strictAttempt;

    if strictAttempt.success
        selected = strictAttempt;
    else
        if ~scan.hasStrictFailure
            scan.firstStrictFailure = strictAttempt;
            scan.hasStrictFailure = true;
        end
        selected = strictAttempt;
        for iRescue = 1:numel(cfg.rescueSeeds)
            seed = cfg.rescueSeeds(iRescue);
            rescueAttempt = solve_once(V, seed.initialDeg, seed.source, ...
                true, iRescue, P, cfg);
            point.attempts(end+1, 1) = rescueAttempt; %#ok<AGROW>
            if rescueAttempt.success
                selected = rescueAttempt;
                break;
            end
            if attempt_score(rescueAttempt) < attempt_score(selected)
                selected = rescueAttempt;
            end
        end
    end

    point.selectedAttempt = selected;
    point.success = selected.success;
    point.usedRescue = selected.usedRescue;
    point.solutionDeg = selected.solutionDeg;
    point.branchLabel = classify_branch(selected.solutionDeg, cfg);
    point.jacobian = selected.jacobian;
    point.limit = selected.limit;
    if ~isempty(lastSuccessful) && point.success
        dz = point.solutionDeg - lastSuccessful.solutionDeg;
        point.deltaFromPreviousDeg = dz;
        point.jumpFromPrevious = abs(dz(1)) > cfg.maxDeltaThetaDeg || ...
            any(abs(dz(2:3)) > cfg.maxDeltaControlDeg);
    end

    scan.points(k) = point;
    if point.success
        currentInitialDeg = point.solutionDeg;
        lastSuccessful = point;
    end

    out = selected.output;
    fprintf(['%5.2f %d %d % .6f % .6f % .6f % .3e %d %d %d ' ...
        '%s %d\n'], V, strictAttempt.success, point.usedRescue, ...
        selected.solutionDeg(1), selected.solutionDeg(2), ...
        selected.solutionDeg(3), selected.residualNorm, ...
        selected.exitflag, get_output_number(out, 'iterations'), ...
        get_output_number(out, 'funcCount'), point.branchLabel, ...
        selected.limit.any);
end
end

function attempt = solve_once(V, initialDeg, source, usedRescue, rescueIndex, P, cfg)
trimOpts = struct();
trimOpts.gamma = cfg.gamma;
trimOpts.initialDeg = initialDeg(:).';
trimOpts.useMultiStart = false;
trimOpts.alwaysMultiStart = false;
[xTrim, uTrim, info] = trim_symmetric(V, cfg.betaM, P, trimOpts);

z = [xTrim(8); uTrim(1); uTrim(3)];
attempt = make_empty_attempt();
attempt.V = V;
attempt.source = source;
attempt.usedRescue = usedRescue;
attempt.rescueIndex = rescueIndex;
attempt.initialDeg = initialDeg(:).';
attempt.solutionDeg = z(:).'*180/pi;
attempt.xTrim = xTrim(:);
attempt.uTrim = uTrim(:);
attempt.residual = info.residual(:);
attempt.residualNorm = info.residualNorm;
attempt.exitflag = info.exitflag;
attempt.output = info.output;
attempt.limit = limit_report(info);
attempt.success = info.exitflag > 0 && ...
    info.residualNorm <= cfg.residualTolerance && ...
    info.finiteFullStateDerivative && ...
    ~info.atLimit && info.withinLimits;
attempt.jacobian = jacobian_report(V, z, P, cfg);
attempt.hasNaNInf = has_nan_inf(attempt);
attempt.hasComplex = ~isreal(xTrim) || ~isreal(uTrim) || ...
    ~isreal(info.residual) || attempt.jacobian.hasComplex;
end

function score = attempt_score(attempt)
score = attempt.residualNorm + 1.0e3*double(attempt.limit.any) + ...
    1.0e6*double(attempt.hasNaNInf || attempt.hasComplex);
end

function jac = jacobian_report(V, z, P, cfg)
h = cfg.jacobianStepRad;
jac = jacobian_from_matrix(jacobian_matrix(V, z, P, cfg, h), h);
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

function jac = jacobian_from_matrix(J, h)
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
jac.variables = {'theta', 'collective', 'cyclicLong'};
jac.residuals = {'udot', 'wdot', 'qdot'};
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
if V < 1.0e-10
    u = 0;
    w = 0;
else
    u = V*cos(alpha);
    w = V*sin(alpha);
end
x = [u; 0; w; 0; 0; 0; 0; theta; 0];
uCtrl = [collective; 0; cyclicLong; 0; 0; 0; 0];
xdot = tiltrotor_eom(x, uCtrl, cfg.betaM, P);
R = [xdot(1); xdot(3); xdot(5)];
end

function multi = run_multiseed_search(speeds, ascScan, descScan, P, cfg)
multi = repmat(make_empty_multiseed_point(), numel(speeds), 1);
fprintf('\nMulti-seed low-residual search at 0.05 m/s points\n');
fprintf('=================================================\n');
for k = 1:numel(speeds)
    V = speeds(k);
    lowSeed = nearest_branch_seed(ascScan, V, 'low', cfg);
    highSeed = nearest_branch_seed(descScan, V, 'high', cfg);
    if any(isnan(lowSeed))
        lowSeed = [-1.260257, 16.935369, 0.193075];
    end
    if any(isnan(highSeed))
        highSeed = [6.580908, 16.228358, 2.308986];
    end
    midSeed = 0.5*(lowSeed + highSeed);
    seedSet = make_multiseed_set(lowSeed, highSeed, midSeed);

    item = make_empty_multiseed_point();
    item.V = V;
    item.seedSet = seedSet;
    item.attempts = repmat(make_empty_attempt(), numel(seedSet), 1);
    for iSeed = 1:numel(seedSet)
        seed = seedSet(iSeed);
        item.attempts(iSeed) = solve_once(V, seed.initialDeg, ...
            seed.source, false, 0, P, cfg);
    end
    item.lowResidualSolutions = unique_successful_solutions( ...
        item.attempts, cfg.solutionTolDeg);
    multi(k) = item;

    fprintf('V=%.2f: %d distinct low-residual solution(s)\n', ...
        V, numel(item.lowResidualSolutions));
    for iSol = 1:numel(item.lowResidualSolutions)
        sol = item.lowResidualSolutions(iSol);
        fprintf(['  #%d theta=% .6f collective=% .6f cyclicLong=% .6f ' ...
            'norm=% .3e rank=%d smin=% .3e cond=% .3e seeds=%s\n'], ...
            iSol, sol.solutionDeg(1), sol.solutionDeg(2), ...
            sol.solutionDeg(3), sol.residualNorm, sol.jacobian.rank, ...
            sol.jacobian.minSingularValue, ...
            sol.jacobian.conditionNumber, sol.seedSources);
    end
end
end

function dense = run_dual_seed_dense_search(speeds, ascScan, descScan, P, cfg)
dense = repmat(make_empty_multiseed_point(), numel(speeds), 1);
fprintf('\nDual-seed low-residual search at 0.01 m/s points\n');
fprintf('================================================\n');
for k = 1:numel(speeds)
    V = speeds(k);
    lowSeed = nearest_branch_seed(ascScan, V, 'low', cfg);
    highSeed = nearest_branch_seed(descScan, V, 'high', cfg);
    if any(isnan(lowSeed))
        lowSeed = [-1.289547621, 16.909248366, 0.201410530];
    end
    if any(isnan(highSeed))
        highSeed = [6.734621267, 16.268379643, 2.392635643];
    end

    item = make_empty_multiseed_point();
    item.V = V;
    item.seedSet = [
        struct('source', 'low_branch_seed', 'initialDeg', lowSeed);
        struct('source', 'high_branch_seed', 'initialDeg', highSeed)];
    item.attempts = repmat(make_empty_attempt(), numel(item.seedSet), 1);
    for iSeed = 1:numel(item.seedSet)
        seed = item.seedSet(iSeed);
        item.attempts(iSeed) = solve_once(V, seed.initialDeg, ...
            seed.source, false, 0, P, cfg);
    end
    item.lowResidualSolutions = unique_successful_solutions( ...
        item.attempts, cfg.solutionTolDeg);
    dense(k) = item;

    fprintf('V=%.2f: %d distinct low-residual solution(s)\n', ...
        V, numel(item.lowResidualSolutions));
    for iSol = 1:numel(item.lowResidualSolutions)
        sol = item.lowResidualSolutions(iSol);
        fprintf(['  #%d theta=% .6f collective=% .6f cyclicLong=% .6f ' ...
            'norm=% .3e rank=%d smin=% .3e cond=% .3e seeds=%s\n'], ...
            iSol, sol.solutionDeg(1), sol.solutionDeg(2), ...
            sol.solutionDeg(3), sol.residualNorm, sol.jacobian.rank, ...
            sol.jacobian.minSingularValue, ...
            sol.jacobian.conditionNumber, sol.seedSources);
    end
end
end

function study = run_jacobian_step_study(V, highSeedDeg, P, cfg)
attempt = solve_once(V, highSeedDeg, 'v9p06_high_seed', false, 0, P, cfg);
z = [attempt.xTrim(8); attempt.uTrim(1); attempt.uTrim(3)];
scale = [P.env.g; P.env.g; 1.0];
study.V = V;
study.seedDeg = highSeedDeg;
study.solutionDeg = attempt.solutionDeg;
study.residual = attempt.residual;
study.residualNorm = attempt.residualNorm;
study.scaledResidualNorm = norm(attempt.residual./scale);
study.exitflag = attempt.exitflag;
study.success = attempt.success;
study.steps = repmat(make_empty_step_jacobian(), ...
    numel(cfg.jacobianStepStudyRad), 1);

fprintf('\nV=9.06 high-branch Jacobian step sensitivity\n');
fprintf('============================================\n');
fprintf(['h rawRank rawS1 rawS2 rawS3 rawCond scaledRank scaledS1 ' ...
    'scaledS2 scaledS3 scaledCond residualNorm scaledResidualNorm\n']);
for i = 1:numel(cfg.jacobianStepStudyRad)
    h = cfg.jacobianStepStudyRad(i);
    Jraw = jacobian_matrix(V, z, P, cfg, h);
    Jscaled = diag(1./scale)*Jraw;
    raw = jacobian_from_matrix(Jraw, h);
    scaled = jacobian_from_matrix(Jscaled, h);
    step = make_empty_step_jacobian();
    step.h = h;
    step.raw = raw;
    step.scaled = scaled;
    study.steps(i) = step;

    sr = raw.singularValues;
    ss = scaled.singularValues;
    fprintf(['%.1e %d %.6e %.6e %.6e %.6e %d %.6e %.6e %.6e ' ...
        '%.6e %.6e %.6e\n'], h, raw.rank, sr(1), sr(2), sr(3), ...
        raw.conditionNumber, scaled.rank, ss(1), ss(2), ss(3), ...
        scaled.conditionNumber, study.residualNorm, ...
        study.scaledResidualNorm);
end
end

function seedSet = make_multiseed_set(lowSeed, highSeed, midSeed)
perturb = [
     0.10,  0.00,  0.00;
    -0.10,  0.00,  0.00;
     0.00,  0.05,  0.00;
     0.00, -0.05,  0.00;
     0.00,  0.00,  0.05;
     0.00,  0.00, -0.05];
sources = {};
seeds = [];
sources{end+1, 1} = 'low_branch_seed'; %#ok<AGROW>
seeds(end+1, :) = lowSeed; %#ok<AGROW>
sources{end+1, 1} = 'high_branch_seed'; %#ok<AGROW>
seeds(end+1, :) = highSeed; %#ok<AGROW>
sources{end+1, 1} = 'midpoint_seed'; %#ok<AGROW>
seeds(end+1, :) = midSeed; %#ok<AGROW>
for i = 1:size(perturb, 1)
    sources{end+1, 1} = ['low_perturb_' num2str(i)]; %#ok<AGROW>
    seeds(end+1, :) = lowSeed + perturb(i, :); %#ok<AGROW>
end
for i = 1:size(perturb, 1)
    sources{end+1, 1} = ['high_perturb_' num2str(i)]; %#ok<AGROW>
    seeds(end+1, :) = highSeed + perturb(i, :); %#ok<AGROW>
end
seedSet = repmat(struct('source', '', 'initialDeg', [NaN, NaN, NaN]), ...
    numel(sources), 1);
for i = 1:numel(sources)
    seedSet(i).source = sources{i};
    seedSet(i).initialDeg = seeds(i, :);
end
end

function seed = nearest_branch_seed(scan, V, branchName, cfg)
seed = [NaN, NaN, NaN];
bestDistance = Inf;
for i = 1:numel(scan.points)
    p = scan.points(i);
    if ~p.success
        continue;
    end
    isLow = p.solutionDeg(1) <= cfg.lowThetaMaxDeg;
    isHigh = p.solutionDeg(1) >= cfg.highThetaMinDeg;
    if (strcmp(branchName, 'low') && ~isLow) || ...
            (strcmp(branchName, 'high') && ~isHigh)
        continue;
    end
    distance = abs(p.V - V);
    if distance < bestDistance
        seed = p.solutionDeg;
        bestDistance = distance;
    end
end
end

function solutions = unique_successful_solutions(attempts, tolDeg)
solutions = repmat(make_empty_solution(), 0, 1);
for i = 1:numel(attempts)
    a = attempts(i);
    if ~a.success
        continue;
    end
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

function intervals = collect_dense_intervals(ascScan, descScan, cfg)
intervals = repmat(make_empty_interval(), 0, 1);
intervals = [intervals; scan_dense_intervals(ascScan, 'ascending', cfg)];
intervals = [intervals; scan_dense_intervals(descScan, 'descending', cfg)];
end

function intervals = scan_dense_intervals(scan, direction, cfg)
intervals = repmat(make_empty_interval(), 0, 1);
for i = 2:numel(scan.points)
    p0 = scan.points(i-1);
    p1 = scan.points(i);
    reason = '';
    if ~p1.strictAttempt.success
        reason = 'strict_failure';
    elseif p0.success && p1.success && p1.jumpFromPrevious
        reason = 'continuity_jump';
    end
    if isempty(reason) || ~p0.success
        continue;
    end
    item = make_empty_interval();
    item.direction = direction;
    item.reason = reason;
    item.startV = p0.V;
    item.endV = p1.V;
    item.startSolutionDeg = p0.solutionDeg;
    item.endSolutionDeg = p1.solutionDeg;
    intervals(end+1, 1) = item; %#ok<AGROW>
end
if isempty(intervals) && scan.hasStrictFailure
    f = scan.firstStrictFailure;
    idx = find(abs([scan.points.V] - f.V) < 1.0e-12, 1);
    if ~isempty(idx) && idx > 1 && scan.points(idx-1).success
        item = make_empty_interval();
        item.direction = direction;
        item.reason = 'strict_failure';
        item.startV = scan.points(idx-1).V;
        item.endV = scan.points(idx).V;
        item.startSolutionDeg = scan.points(idx-1).solutionDeg;
        item.endSolutionDeg = scan.points(idx).solutionDeg;
        intervals(end+1, 1) = item;
    end
end
end

function speeds = make_dense_speeds(interval)
if strcmp(interval.direction, 'ascending')
    speeds = interval.startV:0.01:interval.endV;
else
    speeds = interval.startV:-0.01:interval.endV;
end
if isempty(speeds) || abs(speeds(end) - interval.endV) > 1.0e-9
    speeds(end+1) = interval.endV;
end
end

function evidence = assess_evidence(report, cfg)
allSolutions = collect_all_unique_solutions(report.multiseed05);
solutionCounts = arrayfun(@(m) numel(m.lowResidualSolutions), ...
    report.multiseed05);
hasMultipleSameSpeed = any(solutionCounts > 1);
minS = Inf;
for i = 1:numel(allSolutions)
    minS = min(minS, allSolutions(i).jacobian.minSingularValue);
end
if isempty(allSolutions)
    minS = NaN;
end
ascFail = report.ascending05.hasStrictFailure;
descFail = report.descending05.hasStrictFailure;
evidence.hasMultipleSameSpeed = hasMultipleSameSpeed;
evidence.minSingularValueObserved = minS;
evidence.singularValueNearZero = isfinite(minS) && ...
    minS < cfg.singularFoldTol;
evidence.bidirectionalStrictFailure = ascFail && descFail;
evidence.tryPseudoArclength = hasMultipleSameSpeed || ...
    evidence.singularValueNearZero || evidence.bidirectionalStrictFailure;
evidence.pseudoArclengthConclusionStatus = ...
    ['paused: existing pseudo-arclength conclusion is not used by this ' ...
    'diagnostic revision'];
if evidence.tryPseudoArclength
    evidence.message = ['triggered by multi-solution, near-singular ' ...
        'Jacobian, or bidirectional strict failure evidence'];
else
    evidence.message = ['not attempted: no same-speed multi-solution, ' ...
        'no near-zero minimum singular value, and no bidirectional ' ...
        'strict termination evidence'];
end
end

function allSolutions = collect_all_unique_solutions(multiseed)
allSolutions = repmat(make_empty_solution(), 0, 1);
for i = 1:numel(multiseed)
    sols = multiseed(i).lowResidualSolutions;
    for j = 1:numel(sols)
        allSolutions(end+1, 1) = sols(j); %#ok<AGROW>
    end
end
end

function write_summary(report, filePath, d2r)
fid = fopen(filePath, 'w');
if fid < 0
    warning('Could not open summary file: %s', filePath);
    return;
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, 'Local helicopter trim branch diagnostics\n');
fprintf(fid, 'Generated: %s\n\n', report.generatedAt);
write_scan(fid, 'Ascending 9.00:0.05:9.60', report.ascending05, d2r);
write_scan(fid, 'Descending 9.60:-0.05:9.00', report.descending05, d2r);
for i = 1:numel(report.dense)
    titleText = sprintf('Dense %s %.2f to %.2f (%s)', ...
        report.dense(i).direction, report.dense(i).startV, ...
        report.dense(i).endV, report.dense(i).reason);
    write_scan(fid, titleText, report.dense(i).scan, d2r);
end
write_multiseed(fid, report.multiseed05);
write_dual_seed_dense(fid, report.dualSeedDense);
write_jacobian_step_study(fid, report.jacobianStepStudyV906);
fprintf(fid, '\nEvidence summary\n');
fprintf(fid, 'hasMultipleSameSpeed: %d\n', report.evidence.hasMultipleSameSpeed);
fprintf(fid, 'minSingularValueObserved: %.12e\n', ...
    report.evidence.minSingularValueObserved);
fprintf(fid, 'singularValueNearZero: %d\n', ...
    report.evidence.singularValueNearZero);
fprintf(fid, 'bidirectionalStrictFailure: %d\n', ...
    report.evidence.bidirectionalStrictFailure);
fprintf(fid, 'tryPseudoArclength: %d\n', ...
    report.evidence.tryPseudoArclength);
fprintf(fid, 'message: %s\n', report.evidence.message);
fprintf(fid, 'pseudoArclengthConclusionStatus: %s\n', ...
    report.evidence.pseudoArclengthConclusionStatus);
end

function write_scan(fid, titleText, scan, d2r)
fprintf(fid, '\n%s\n', titleText);
fprintf(fid, '%s\n', repmat('-', 1, numel(titleText)));
fprintf(fid, ['V strictSuccess usedRescue theta collective cyclicLong ' ...
    'residual exitflag iterations funcCount branch jump limit ' ...
    'jacRank s1 s2 s3 smin cond\n']);
for i = 1:numel(scan.points)
    p = scan.points(i);
    a = p.selectedAttempt;
    s = a.jacobian.singularValues;
    if numel(s) < 3
        s = [NaN, NaN, NaN];
    end
    fprintf(fid, ['%.2f %d %d %.9f %.9f %.9f %.12e %d %d %d %s ' ...
        '%d %d %d %.12e %.12e %.12e %.12e %.12e\n'], ...
        p.V, p.strictAttempt.success, p.usedRescue, ...
        a.solutionDeg(1), a.solutionDeg(2), a.solutionDeg(3), ...
        a.residualNorm, a.exitflag, ...
        get_output_number(a.output, 'iterations'), ...
        get_output_number(a.output, 'funcCount'), p.branchLabel, ...
        p.jumpFromPrevious, a.limit.any, a.jacobian.rank, ...
        s(1), s(2), s(3), a.jacobian.minSingularValue, ...
        a.jacobian.conditionNumber);
end
if scan.hasStrictFailure
    f = scan.firstStrictFailure;
    fprintf(fid, ['First strict failure at V=%.2f, initial=[%.9f %.9f %.9f], ' ...
        'final=[%.9f %.9f %.9f], residualNorm=%.12e, exitflag=%d, ' ...
        'iterations=%d, funcCount=%d, limit=%d, message=%s\n'], ...
        f.V, f.initialDeg(1), f.initialDeg(2), f.initialDeg(3), ...
        f.solutionDeg(1), f.solutionDeg(2), f.solutionDeg(3), ...
        f.residualNorm, f.exitflag, ...
        get_output_number(f.output, 'iterations'), ...
        get_output_number(f.output, 'funcCount'), f.limit.any, ...
        flatten_message(f.output));
else
    fprintf(fid, 'First strict failure: none\n');
end
fprintf(fid, 'Rescue attempts\n');
for i = 1:numel(scan.points)
    attempts = scan.points(i).attempts;
    for j = 1:numel(attempts)
        if attempts(j).usedRescue
            a = attempts(j);
            fprintf(fid, ['V=%.2f source=%s success=%d initial=[%.9f %.9f %.9f] ' ...
                'final=[%.9f %.9f %.9f] residualNorm=%.12e exitflag=%d\n'], ...
                a.V, a.source, a.success, a.initialDeg(1), ...
                a.initialDeg(2), a.initialDeg(3), a.solutionDeg(1), ...
                a.solutionDeg(2), a.solutionDeg(3), a.residualNorm, ...
                a.exitflag);
        end
    end
end
end

function write_multiseed(fid, multiseed)
fprintf(fid, '\nMulti-seed unique low-residual solutions\n');
fprintf(fid, '----------------------------------------\n');
for i = 1:numel(multiseed)
    item = multiseed(i);
    fprintf(fid, 'V=%.2f count=%d\n', item.V, ...
        numel(item.lowResidualSolutions));
    for j = 1:numel(item.lowResidualSolutions)
        sol = item.lowResidualSolutions(j);
        s = sol.jacobian.singularValues;
        if numel(s) < 3
            s = [NaN, NaN, NaN];
        end
        fprintf(fid, ['  #%d theta=%.9f collective=%.9f cyclicLong=%.9f ' ...
            'residualNorm=%.12e rank=%d s=[%.12e %.12e %.12e] ' ...
            'smin=%.12e cond=%.12e sources=%s\n'], ...
            j, sol.solutionDeg(1), sol.solutionDeg(2), ...
            sol.solutionDeg(3), sol.residualNorm, sol.jacobian.rank, ...
            s(1), s(2), s(3), sol.jacobian.minSingularValue, ...
            sol.jacobian.conditionNumber, sol.seedSources);
    end
end
end

function write_dual_seed_dense(fid, dense)
fprintf(fid, '\nDual-seed unique low-residual solutions, V=9.05:0.01:9.30\n');
fprintf(fid, '-----------------------------------------------------------\n');
write_multiseed(fid, dense);
end

function write_jacobian_step_study(fid, study)
fprintf(fid, '\nV=9.06 high-branch Jacobian step sensitivity\n');
fprintf(fid, '--------------------------------------------\n');
fprintf(fid, ['solutionDeg=[%.9f %.9f %.9f], residualNorm=%.12e, ' ...
    'scaledResidualNorm=%.12e, exitflag=%d, success=%d\n'], ...
    study.solutionDeg(1), study.solutionDeg(2), study.solutionDeg(3), ...
    study.residualNorm, study.scaledResidualNorm, study.exitflag, ...
    study.success);
fprintf(fid, ['h rawRank rawS1 rawS2 rawS3 rawSmin rawCond scaledRank ' ...
    'scaledS1 scaledS2 scaledS3 scaledSmin scaledCond\n']);
for i = 1:numel(study.steps)
    step = study.steps(i);
    sr = step.raw.singularValues;
    ss = step.scaled.singularValues;
    fprintf(fid, ['%.12e %d %.12e %.12e %.12e %.12e %.12e %d ' ...
        '%.12e %.12e %.12e %.12e %.12e\n'], step.h, ...
        step.raw.rank, sr(1), sr(2), sr(3), ...
        step.raw.minSingularValue, step.raw.conditionNumber, ...
        step.scaled.rank, ss(1), ss(2), ss(3), ...
        step.scaled.minSingularValue, step.scaled.conditionNumber);
end
end

function point = make_empty_point()
point = struct( ...
    'V', NaN, ...
    'requestedInitialDeg', [NaN, NaN, NaN], ...
    'strictAttempt', make_empty_attempt(), ...
    'attempts', make_empty_attempt(), ...
    'selectedAttempt', make_empty_attempt(), ...
    'success', false, ...
    'usedRescue', false, ...
    'solutionDeg', [NaN, NaN, NaN], ...
    'branchLabel', 'unknown', ...
    'jacobian', struct(), ...
    'limit', struct(), ...
    'deltaFromPreviousDeg', [NaN, NaN, NaN], ...
    'jumpFromPrevious', false);
end

function attempt = make_empty_attempt()
attempt = struct( ...
    'V', NaN, ...
    'source', '', ...
    'usedRescue', false, ...
    'rescueIndex', 0, ...
    'initialDeg', [NaN, NaN, NaN], ...
    'solutionDeg', [NaN, NaN, NaN], ...
    'xTrim', [], ...
    'uTrim', [], ...
    'residual', [], ...
    'residualNorm', NaN, ...
    'exitflag', NaN, ...
    'output', struct(), ...
    'limit', struct('any', false, 'atLimit', false, ...
        'violation', false, 'items', struct([])), ...
    'success', false, ...
    'jacobian', struct(), ...
    'hasNaNInf', false, ...
    'hasComplex', false);
end

function item = make_empty_multiseed_point()
item = struct( ...
    'V', NaN, ...
    'seedSet', struct([]), ...
    'attempts', make_empty_attempt(), ...
    'lowResidualSolutions', make_empty_solution());
item.lowResidualSolutions = repmat(make_empty_solution(), 0, 1);
end

function sol = make_empty_solution()
sol = struct( ...
    'solutionDeg', [NaN, NaN, NaN], ...
    'residualNorm', NaN, ...
    'count', 0, ...
    'seedSources', '', ...
    'jacobian', struct());
end

function item = make_empty_interval()
item = struct( ...
    'direction', '', ...
    'reason', '', ...
    'startV', NaN, ...
    'endV', NaN, ...
    'startSolutionDeg', [NaN, NaN, NaN], ...
    'endSolutionDeg', [NaN, NaN, NaN]);
end

function item = make_empty_dense_scan()
item = struct( ...
    'direction', '', ...
    'reason', '', ...
    'startV', NaN, ...
    'endV', NaN, ...
    'scan', struct());
end

function step = make_empty_step_jacobian()
step = struct( ...
    'h', NaN, ...
    'raw', struct(), ...
    'scaled', struct());
end

function limit = limit_report(info)
limit.any = false;
limit.atLimit = false;
limit.violation = false;
limit.items = struct([]);
if isfield(info, 'atLimit')
    limit.atLimit = info.atLimit;
end
if isfield(info, 'withinLimits')
    limit.violation = ~info.withinLimits;
end
if isfield(info, 'limitReport') && isfield(info.limitReport, 'items')
    limit.items = info.limitReport.items;
end
limit.any = limit.atLimit || limit.violation;
end

function label = classify_branch(solutionDeg, cfg)
thetaDeg = solutionDeg(1);
if thetaDeg <= cfg.lowThetaMaxDeg
    label = 'low';
elseif thetaDeg >= cfg.highThetaMinDeg
    label = 'high';
else
    label = 'middle';
end
end

function tf = has_nan_inf(attempt)
tf = any(~isfinite(attempt.solutionDeg(:))) || ...
    any(~isfinite(attempt.residual(:))) || ...
    attempt.jacobian.hasNaNInf;
end

function value = get_output_number(output, fieldName)
if isstruct(output) && isfield(output, fieldName) && ...
        isnumeric(output.(fieldName)) && ~isempty(output.(fieldName))
    value = output.(fieldName);
else
    value = NaN;
end
end

function msg = flatten_message(output)
msg = '';
if isstruct(output) && isfield(output, 'message') && ...
        ischar(output.message)
    msg = output.message;
end
msg = strrep(msg, sprintf('\n'), ' ');
msg = strrep(msg, sprintf('\r'), ' ');
end
