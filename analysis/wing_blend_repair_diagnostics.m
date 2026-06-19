function report = wing_blend_repair_diagnostics()
%WING_BLEND_REPAIR_DIAGNOSTICS Validation package for wing blend repair.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir,'model'));
addpath(fullfile(rootDir,'analysis'));
addpath(fullfile(rootDir,'tests'));

P = params_nominal();

fprintf('\nWing blend repair diagnostics\n');
fprintf('=============================\n');
fprintf('normalFlowRatio center = %.6f\n', P.wing.normalFlowRatio);
fprintf('normalFlowBlendHalfWidth = %.6f\n', ...
    P.wing.normalFlowBlendHalfWidth);

report.component = check_wing_normal_flow_blend();

baseOpts = make_sweep_opts();
baseOpts.speeds = 0:1:20;
fprintf('\nBasic 0-20 m/s sweep\n');
report.basicForward = trim_sweep_helicopter(P, baseOpts);
print_sweep_table(report.basicForward, 'basic-forward');

fineOpts = make_sweep_opts();
fineOpts.speeds = 7:0.05:12;
fprintf('\nFine 7-12 m/s forward sweep\n');
report.fineForward = trim_sweep_helicopter(P, fineOpts);
print_sweep_table(report.fineForward, 'fine-forward');

reverseOpts = fineOpts;
reverseOpts.speeds = 12:-0.05:7;
fprintf('\nFine 12-7 m/s reverse sweep\n');
report.fineReverse = trim_sweep_helicopter(P, reverseOpts);
print_sweep_table(report.fineReverse, 'fine-reverse');

report.focus = print_focus_pair(report.fineForward, 9.25, 9.30);
report.reverseCompare = compare_forward_reverse(report.fineForward, ...
    report.fineReverse, [8, 9, 9.25, 9.30, 9.5, 10, 11]);
report.multistart = run_multistart_cases(P, report.fineForward, ...
    report.fineReverse);
report.linearizationSensitivity = run_linearization_sensitivity(P, ...
    report.fineForward, [9.25, 9.30, 10]);
report.deterministic = deterministic_check(P, report.fineForward, 9.30);
report.rescueAt1 = rescue_status(report.basicForward, 1);

fprintf('\n1 m/s rescue status\n');
fprintf('===================\n');
fprintf('usedRescue=%d source=%s residual=%.12e exitflag=%d\n', ...
    report.rescueAt1.usedRescueInitial, report.rescueAt1.initialSource, ...
    report.rescueAt1.trimResidualNorm, report.rescueAt1.exitflag);
end

function opts = make_sweep_opts()
opts = struct();
opts.betaM = 0;
opts.gamma = 0;
opts.initialDeg = [0, 18, 0];
opts.useContinuation = true;
opts.useTrimMultiStart = false;
opts.allowRescueInitials = true;
opts.failOnRescueInitial = false;
opts.maxDeltaThetaDeg = 2.5;
opts.maxDeltaControlDeg = 1.25;
opts.signFlipThresholdDeg = 0.25;
opts.jacobianStepRad = 1.0e-4;
opts.rescueInitialDegs = [
     0, 18,  0;
    -4, 18, -1;
     4, 16,  2;
     8, 15,  4;
    -8, 20, -4;
    12, 14,  6];
end

function print_sweep_table(sweep, label)
fprintf('\nSweep table: %s\n', label);
fprintf(['label V theta collective cyclicLong residual exitflag init rescue ' ...
    'iter branchWeight ratio wingFx wingFy wingFz wingMx wingMy wingMz ' ...
    'beta0L beta1cL beta1sL beta0R beta1cR beta1sR viL viR jacCond jacSmin linFinite\n']);
for k = 1:numel(sweep.points)
    p = sweep.points(k);
    w = wing_summary(p);
    r = rotor_summary(p);
    iter = NaN;
    if isfield(p.trimInfo, 'output') && isfield(p.trimInfo.output, 'iterations')
        iter = p.trimInfo.output.iterations;
    end
    jacCond = p.residualJacobian.conditionNumber;
    jacSmin = NaN;
    if isfield(p.residualJacobian, 'singularValues') && ...
            ~isempty(p.residualJacobian.singularValues)
        jacSmin = min(p.residualJacobian.singularValues);
    end
    fprintf(['%s %.6f %.9f %.9f %.9f %.12e %d %s %d %.0f ' ...
        '%.9f %.9f %.9f %.9f %.9f %.9f %.9f ' ...
        '%.9f %.9f %.9f %.9f %.9f %.9f %.9f %.9f %.12e %.12e %d\n'], ...
        label, p.V, p.solutionDeg(1), p.solutionDeg(2), ...
        p.solutionDeg(3), p.trimResidualNorm, p.exitflag, ...
        p.initialSource, p.usedRescueInitial, iter, w.weight, w.ratio, ...
        w.F(1), w.F(2), w.F(3), w.M(1), w.M(2), w.M(3), ...
        r.beta0L, r.beta1cL, r.beta1sL, r.beta0R, r.beta1cR, ...
        r.beta1sR, r.viL, r.viR, jacCond, jacSmin, ...
        p.linearization.finite);
end
end

function focus = print_focus_pair(sweep, v0, v1)
p0 = nearest_point(sweep, v0);
p1 = nearest_point(sweep, v1);
w0 = wing_summary(p0);
w1 = wing_summary(p1);
focus.dThetaDeg = p1.solutionDeg(1) - p0.solutionDeg(1);
focus.dCollectiveDeg = p1.solutionDeg(2) - p0.solutionDeg(2);
focus.dCyclicLongDeg = p1.solutionDeg(3) - p0.solutionDeg(3);
focus.dWingF = w1.F - w0.F;
focus.dWingM = w1.M - w0.M;
focus.branchWeight0 = w0.weight;
focus.branchWeight1 = w1.weight;
fprintf('\nFocus pair %.2f -> %.2f m/s\n', p0.V, p1.V);
fprintf('dTheta=%.9f deg dCollective=%.9f deg dCyclicLong=%.9f deg\n', ...
    focus.dThetaDeg, focus.dCollectiveDeg, focus.dCyclicLongDeg);
fprintf('branchWeight %.9f -> %.9f ratio %.9f -> %.9f\n', ...
    w0.weight, w1.weight, w0.ratio, w1.ratio);
fprintf('dWingF=[%.9f %.9f %.9f] dWingM=[%.9f %.9f %.9f]\n', ...
    focus.dWingF(1), focus.dWingF(2), focus.dWingF(3), ...
    focus.dWingM(1), focus.dWingM(2), focus.dWingM(3));
end

function comparison = compare_forward_reverse(forward, reverse, speeds)
fprintf('\nForward/reverse comparison\n');
fprintf('==========================\n');
comparison = repmat(struct('V',NaN,'dThetaDeg',NaN,'dCollectiveDeg',NaN, ...
    'dCyclicLongDeg',NaN,'sameBranchWeight',false), numel(speeds), 1);
for i = 1:numel(speeds)
    pf = nearest_point(forward, speeds(i));
    pr = nearest_point(reverse, speeds(i));
    wf = wing_summary(pf);
    wr = wing_summary(pr);
    comparison(i).V = speeds(i);
    comparison(i).dThetaDeg = pr.solutionDeg(1) - pf.solutionDeg(1);
    comparison(i).dCollectiveDeg = pr.solutionDeg(2) - pf.solutionDeg(2);
    comparison(i).dCyclicLongDeg = pr.solutionDeg(3) - pf.solutionDeg(3);
    comparison(i).sameBranchWeight = abs(wr.weight - wf.weight) < 1e-6;
    fprintf(['V=%.2f dTheta=%.9f dCollective=%.9f dCyclicLong=%.9f ' ...
        'wF=%.9f wR=%.9f\n'], speeds(i), comparison(i).dThetaDeg, ...
        comparison(i).dCollectiveDeg, comparison(i).dCyclicLongDeg, ...
        wf.weight, wr.weight);
end
end

function multistart = run_multistart_cases(P, forward, reverse)
d2r = pi/180;
speeds = [8, 9, 9.25, 9.30, 9.5, 10, 11];
fprintf('\nMultistart trim cases\n');
fprintf('=====================\n');
multistart = repmat(struct('V',NaN,'solutions',[]), numel(speeds), 1);
baseSeeds = [
     0, 18,  0;
    -2, 17, -1;
     2, 16,  2;
     6, 16,  4;
    -6, 18, -3];
for i = 1:numel(speeds)
    V = speeds(i);
    pf = nearest_point(forward, V);
    pr = nearest_point(reverse, V);
    p8 = nearest_point(forward, 8);
    p11 = nearest_point(forward, 11);
    interpSeed = 0.5*(p8.solutionDeg + p11.solutionDeg);
    seeds = unique([baseSeeds; pf.solutionDeg; pr.solutionDeg; ...
        p8.solutionDeg; p11.solutionDeg; interpSeed; ...
        pf.solutionDeg + [0.2, 0, 0]; pf.solutionDeg + [0, 0.2, 0]; ...
        pf.solutionDeg + [0, 0, 0.2]], 'rows');
    cases = [];
    fprintf('V=%.2f\n', V);
    for j = 1:size(seeds, 1)
        opts = struct('gamma',0,'initialDeg',seeds(j,:), ...
            'useMultiStart',false);
        [xTrim, uTrim, info] = trim_symmetric(V, 0, P, opts);
        zDeg = [xTrim(8), uTrim(1), uTrim(3)]/d2r;
        [~, eomOut] = tiltrotor_eom(xTrim, uTrim, 0, P);
        w = wing_summary_from_eom(eomOut);
        jac = local_residual_jacobian(V, 0, zDeg*d2r, P);
        this = struct('seedDeg',seeds(j,:), 'solutionDeg',zDeg, ...
            'residualNorm',info.residualNorm, 'exitflag',info.exitflag, ...
            'success',info.converged, 'branchWeight',w.weight, ...
            'jacConditionNumber',jac.conditionNumber, ...
            'jacMinSingularValue',jac.minSingularValue);
        if isempty(cases)
            cases = this;
        else
            cases(end+1) = this; %#ok<AGROW>
        end
        fprintf(['  seed%02d=[%.6f %.6f %.6f] sol=[%.9f %.9f %.9f] ' ...
            'res=%.12e exit=%d success=%d weight=%.9f cond=%.12e smin=%.12e\n'], ...
            j, seeds(j,1), seeds(j,2), seeds(j,3), ...
            zDeg(1), zDeg(2), zDeg(3), info.residualNorm, ...
            info.exitflag, info.converged, w.weight, ...
            jac.conditionNumber, jac.minSingularValue);
    end
    multistart(i).V = V;
    multistart(i).solutions = cases;
end
end

function sens = run_linearization_sensitivity(P, sweep, speeds)
fprintf('\nLinearization step sensitivity\n');
fprintf('=============================\n');
scales = [0.5, 1, 2];
sens = repmat(struct('V',NaN,'finite',[],'relDiffA',[],'relDiffB',[]), ...
    numel(speeds), 1);
for i = 1:numel(speeds)
    p = nearest_point(sweep, speeds(i));
    Aref = [];
    Bref = [];
    finite = false(size(scales));
    relA = NaN(size(scales));
    relB = NaN(size(scales));
    fprintf('V=%.2f\n', p.V);
    for j = 1:numel(scales)
        Pj = P;
        Pj.linear.dx = P.linear.dx*scales(j);
        Pj.linear.du = P.linear.du*scales(j);
        [A, B, lin] = linearize_numeric(p.xTrim, p.uTrim, p.betaM, Pj);
        finite(j) = lin.finite && is_real_finite(A) && is_real_finite(B);
        if j == 2
            Aref = A;
            Bref = B;
        end
        if ~isempty(Aref)
            relA(j) = norm(A - Aref, 'fro')/max(norm(Aref, 'fro'), 1);
            relB(j) = norm(B - Bref, 'fro')/max(norm(Bref, 'fro'), 1);
        end
        fprintf('  scale=%.3f finite=%d relA=%.12e relB=%.12e\n', ...
            scales(j), finite(j), relA(j), relB(j));
    end
    sens(i).V = p.V;
    sens(i).finite = finite;
    sens(i).relDiffA = relA;
    sens(i).relDiffB = relB;
end
end

function det = deterministic_check(P, sweep, speed)
p = nearest_point(sweep, speed);
f1 = tiltrotor_eom(p.xTrim, p.uTrim, p.betaM, P);
f2 = tiltrotor_eom(p.xTrim, p.uTrim, p.betaM, P);
[~, e1] = tiltrotor_eom(p.xTrim, p.uTrim, p.betaM, P);
[~, e2] = tiltrotor_eom(p.xTrim, p.uTrim, p.betaM, P);
w1 = wing_summary_from_eom(e1);
w2 = wing_summary_from_eom(e2);
det.stateDerivativeDifference = norm(f2 - f1);
det.wingForceDifference = norm(w2.F - w1.F);
det.wingMomentDifference = norm(w2.M - w1.M);
fprintf('\nRepeat-call determinism at %.2f m/s\n', p.V);
fprintf('df=%.12e dWingF=%.12e dWingM=%.12e\n', ...
    det.stateDerivativeDifference, det.wingForceDifference, ...
    det.wingMomentDifference);
end

function p = rescue_status(sweep, speed)
p = nearest_point(sweep, speed);
end

function point = nearest_point(sweep, speed)
[~, idx] = min(abs([sweep.points.V] - speed));
point = sweep.points(idx);
end

function w = wing_summary(point)
components = point.forcesMoments.components;
for i = 1:numel(components)
    if strcmp(components(i).name, 'wing')
        w = wing_summary_from_component(components(i));
        return;
    end
end
error('Wing component not found.');
end

function w = wing_summary_from_eom(eomOut)
components = eomOut.components.components;
for i = 1:numel(components)
    c = components{i};
    if strcmp(c.name, 'wing')
        w = wing_summary_from_component(c);
        return;
    end
end
error('Wing component not found.');
end

function w = wing_summary_from_component(component)
w.F = component.F(:);
w.M = component.M(:);
weights = [];
ratios = [];
regions = component.data.regions;
for i = 1:numel(regions)
    r = regions{i};
    if isfield(r, 'normalFlowBranchWeight')
        weights(end+1) = r.normalFlowBranchWeight; %#ok<AGROW>
        ratios(end+1) = r.normalFlowRatioActual; %#ok<AGROW>
    end
end
w.weight = mean(weights);
w.ratio = mean(ratios);
end

function r = rotor_summary(point)
r.beta0L = NaN; r.beta1cL = NaN; r.beta1sL = NaN; r.viL = NaN;
r.beta0R = NaN; r.beta1cR = NaN; r.beta1sR = NaN; r.viR = NaN;
components = point.forcesMoments.components;
for i = 1:numel(components)
    c = components(i);
    if strcmp(c.name, 'rotorLeft')
        r.beta0L = c.data.beta0;
        r.beta1cL = c.data.beta1c;
        r.beta1sL = c.data.beta1s;
        r.viL = c.data.inducedVelocity;
    elseif strcmp(c.name, 'rotorRight')
        r.beta0R = c.data.beta0;
        r.beta1cR = c.data.beta1c;
        r.beta1sR = c.data.beta1s;
        r.viR = c.data.inducedVelocity;
    end
end
end

function jac = local_residual_jacobian(V, gamma, z, P)
h = 1e-4;
J = zeros(3,3);
for i = 1:3
    dz = zeros(3,1);
    dz(i) = h;
    rp = residual_at_z(V, gamma, z + dz, P);
    rm = residual_at_z(V, gamma, z - dz, P);
    J(:,i) = (rp - rm)/(2*h);
end
s = svd(J);
jac.conditionNumber = s(1)/max(s(end), eps(s(1)));
jac.minSingularValue = s(end);
end

function R = residual_at_z(V, gamma, z, P)
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
xdot = tiltrotor_eom(x, uCtrl, 0, P);
R = [xdot(1); xdot(3); xdot(5)];
end

function tf = is_real_finite(value)
tf = isreal(value) && all(isfinite(value(:)));
end
