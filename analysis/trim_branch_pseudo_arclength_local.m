function report = trim_branch_pseudo_arclength_local()
%TRIM_BRANCH_PSEUDO_ARCLENGTH_LOCAL Independent pseudo-arclength diagnostic.
%
% This is only a diagnostic continuation attempt. It solves the same
% trim residual [udot, wdot, qdot] = 0 plus one arclength constraint in
% variables [thetaDeg, collectiveDeg, cyclicLongDeg, V].

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir, 'model'));
addpath(fullfile(rootDir, 'analysis'));

P = params_nominal();
cfg.betaM = 0;
cfg.gamma = 0;
cfg.residualTolerance = P.trim.residualTolerance;
cfg.scale = [P.env.g; P.env.g; 1.0];
cfg.maxSteps = 50;
cfg.minV = 8.8;
cfg.maxV = 9.7;
cfg.ds = 0.025;
cfg.options = optimset('Display', 'off', 'MaxIter', 500, ...
    'MaxFunEvals', 4000, 'TolX', 1e-9, 'TolFun', 1e-12);

fprintf('\nPseudo-arclength local branch diagnostic\n');
fprintf('========================================\n');

lowA = solve_trim_deg(9.28, [-1.293036, 16.906082, 0.202426], P, cfg);
lowB = solve_trim_deg(9.29, [-1.294197, 16.905025, 0.202765], P, cfg);
highA = solve_trim_deg(9.08, [6.742289, 16.270345, 2.396819], P, cfg);
highB = solve_trim_deg(9.07, [6.746123, 16.271326, 2.398911], P, cfg);

report.lowStart = [lowA; lowB];
report.highStart = [highA; highB];
report.lowForward = continue_pseudo('low_forward', lowA.y, lowB.y, P, cfg);
report.highBackward = continue_pseudo('high_backward', highA.y, highB.y, P, cfg);
report.connection = assess_connection(report);

stamp = datestr(now, 'yyyymmdd_HHMMSS');
resultDir = fullfile(rootDir, 'results');
if ~exist(resultDir, 'dir')
    mkdir(resultDir);
end
report.paths.mat = fullfile(resultDir, ...
    ['trim_branch_pseudo_arclength_local_' stamp '.mat']);
report.paths.summary = fullfile(resultDir, ...
    ['trim_branch_pseudo_arclength_local_' stamp '.txt']);
save(report.paths.mat, 'report');
write_summary(report, report.paths.summary);

fprintf('Saved pseudo-arclength MAT: %s\n', report.paths.mat);
fprintf('Saved pseudo-arclength summary: %s\n', report.paths.summary);
fprintf('Connection verdict: %s\n', report.connection.verdict);
end

function scan = continue_pseudo(label, yPrev, yCurr, P, cfg)
scan.label = label;
scan.points = repmat(make_empty_point(), cfg.maxSteps, 1);
scan.points(1) = make_point(yPrev, residual_from_y(yPrev, P, cfg), ...
    true, 0, 0, struct(), 'seed_prev');
scan.points(2) = make_point(yCurr, residual_from_y(yCurr, P, cfg), ...
    true, 0, 0, struct(), 'seed_curr');
last = yPrev(:);
current = yCurr(:);

fprintf('\n%s\n', label);
fprintf('%s\n', repmat('-', 1, numel(label)));
fprintf('step V theta collective cyclicLong residual arc exit branch\n');
fprintf('%3d % .6f % .6f % .6f % .6f % .3e % .3e %d %s\n', ...
    1, yPrev(4), yPrev(1), yPrev(2), yPrev(3), ...
    norm(residual_from_y(yPrev, P, cfg)), 0, 1, branch_name(yPrev));
fprintf('%3d % .6f % .6f % .6f % .6f % .3e % .3e %d %s\n', ...
    2, yCurr(4), yCurr(1), yCurr(2), yCurr(3), ...
    norm(residual_from_y(yCurr, P, cfg)), 0, 1, branch_name(yCurr));

for k = 3:cfg.maxSteps
    tangent = current - last;
    tangent = tangent/max(norm(tangent), eps);
    predictor = current + cfg.ds*tangent;
    objective = @(y) pseudo_cost(y(:), predictor, tangent, cfg.ds, P, cfg);
    [yOpt, cost, exitflag, output] = fminsearch(objective, predictor, cfg.options);
    yOpt = yOpt(:);
    R = residual_from_y(yOpt, P, cfg);
    arcResidual = tangent.'*(yOpt - predictor)/max(cfg.ds, eps);
    localDistance = norm(yOpt - predictor);
    success = exitflag > 0 && norm(R) <= cfg.residualTolerance && ...
        all(isfinite(yOpt)) && isreal(yOpt) && ...
        localDistance <= 5*cfg.ds && ...
        yOpt(4) >= cfg.minV && yOpt(4) <= cfg.maxV;
    scan.points(k) = make_point(yOpt, R, success, cost, exitflag, ...
        output, 'pseudo');
    scan.points(k).arcResidual = arcResidual;
    scan.points(k).localDistance = localDistance;

    fprintf('%3d % .6f % .6f % .6f % .6f % .3e % .3e %d %s\n', ...
        k, yOpt(4), yOpt(1), yOpt(2), yOpt(3), norm(R), ...
        arcResidual, exitflag, branch_name(yOpt));

    if ~success
        scan.points = scan.points(1:k);
        return;
    end
    last = current;
    current = yOpt;
end
end

function cost = pseudo_cost(y, predictor, tangent, ds, P, cfg)
R = residual_from_y(y, P, cfg);
Rs = R./cfg.scale;
arc = tangent.'*(y - predictor)/max(ds, eps);
if any(~isfinite(R)) || any(~isfinite(y)) || ~isreal(R) || ~isreal(y)
    cost = 1.0e30;
else
    cost = Rs.'*Rs + arc^2;
end
end

function item = solve_trim_deg(V, initialDeg, P, cfg)
opts.gamma = cfg.gamma;
opts.initialDeg = initialDeg;
opts.useMultiStart = false;
opts.alwaysMultiStart = false;
[xTrim, uTrim, info] = trim_symmetric(V, cfg.betaM, P, opts);
y = [xTrim(8)*180/pi; uTrim(1)*180/pi; uTrim(3)*180/pi; V];
item = make_point(y, info.residual(:), ...
    info.exitflag > 0 && info.residualNorm <= cfg.residualTolerance && ...
    info.finiteFullStateDerivative && ~info.atLimit && info.withinLimits, ...
    info.cost, info.exitflag, info.output, 'trim_seed');
end

function R = residual_from_y(y, P, cfg)
z = y(1:3)*pi/180;
V = y(4);
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

function point = make_point(y, residual, success, cost, exitflag, output, source)
point = struct( ...
    'source', source, ...
    'y', y(:).', ...
    'thetaDeg', y(1), ...
    'collectiveDeg', y(2), ...
    'cyclicLongDeg', y(3), ...
    'V', y(4), ...
    'residual', residual(:), ...
    'residualNorm', norm(residual), ...
    'success', success, ...
    'cost', cost, ...
    'exitflag', exitflag, ...
    'output', output, ...
    'arcResidual', NaN, ...
    'localDistance', NaN, ...
    'branch', branch_name(y));
end

function point = make_empty_point()
point = make_point([NaN; NaN; NaN; NaN], [NaN; NaN; NaN], ...
    false, NaN, NaN, struct(), '');
end

function name = branch_name(y)
if y(1) <= 1.0
    name = 'low';
elseif y(1) >= 2.0
    name = 'high';
else
    name = 'middle';
end
end

function connection = assess_connection(report)
lowPoints = report.lowForward.points([report.lowForward.points.success]);
highPoints = report.highBackward.points([report.highBackward.points.success]);
connection.minDistance = Inf;
connection.lowIndex = NaN;
connection.highIndex = NaN;
for i = 1:numel(lowPoints)
    for j = 1:numel(highPoints)
        dz = lowPoints(i).y(1:3) - highPoints(j).y(1:3);
        dV = lowPoints(i).V - highPoints(j).V;
        distance = norm([dz(:); 10*dV]);
        if distance < connection.minDistance
            connection.minDistance = distance;
            connection.lowIndex = i;
            connection.highIndex = j;
        end
    end
end
if isfinite(connection.minDistance) && connection.minDistance < 0.1
    connection.verdict = 'connected_within_numeric_tolerance';
else
    connection.verdict = 'not_connected_by_this_attempt';
end
end

function write_summary(report, filePath)
fid = fopen(filePath, 'w');
if fid < 0
    warning('Could not open pseudo summary: %s', filePath);
    return;
end
cleanup = onCleanup(@() fclose(fid));
write_scan(fid, report.lowForward);
write_scan(fid, report.highBackward);
fprintf(fid, '\nConnection\n');
fprintf(fid, 'verdict: %s\n', report.connection.verdict);
fprintf(fid, 'minDistance: %.12e\n', report.connection.minDistance);
fprintf(fid, 'lowIndex: %g\n', report.connection.lowIndex);
fprintf(fid, 'highIndex: %g\n', report.connection.highIndex);
end

function write_scan(fid, scan)
fprintf(fid, '\n%s\n', scan.label);
fprintf(fid, ['step V theta collective cyclicLong residualNorm ' ...
    'arcResidual localDistance exitflag success branch\n']);
for i = 1:numel(scan.points)
    p = scan.points(i);
    fprintf(fid, ['%d %.12f %.12f %.12f %.12f %.12e %.12e %.12e ' ...
        '%d %d %s\n'], ...
        i, p.V, p.thetaDeg, p.collectiveDeg, p.cyclicLongDeg, ...
        p.residualNorm, p.arcResidual, p.localDistance, p.exitflag, ...
        p.success, p.branch);
end
end
