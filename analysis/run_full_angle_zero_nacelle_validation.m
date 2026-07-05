function report = run_full_angle_zero_nacelle_validation()
%RUN_FULL_ANGLE_ZERO_NACELLE_VALIDATION Compare legacy and full-angle 0-deg nacelle trim sweeps.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir,'model'));
addpath(fullfile(rootDir,'model','wing'));
addpath(fullfile(rootDir,'analysis'));
Plegacy = params_nominal();
Pnew = Plegacy;
Pnew.wing.fullAngleModelEnabled = 1;
opts = struct();
opts.betaM = 0;
opts.gamma = 0;
opts.speeds = 7:0.25:12;
opts.initialDeg = [0, 18, 0];
opts.useContinuation = true;
opts.useTrimMultiStart = false;
opts.allowRescueInitials = true;
opts.failOnRescueInitial = false;
opts.computeResidualJacobian = false;
opts.computeLinearization = false;
opts.maxDeltaThetaDeg = 2.5;
opts.maxDeltaControlDeg = 1.25;
opts.signFlipThresholdDeg = 0.25;
legacy = trim_sweep_helicopter(Plegacy, opts);
fullAngle = trim_sweep_helicopter(Pnew, opts);
legacyTable = points_to_table(legacy, true);
fullTable = points_to_table(fullAngle, false);
outDir = fullfile(rootDir, 'validation','wing_full_angle','zero_nacelle_bump');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end
writetable(legacyTable, fullfile(outDir, 'legacy_zero_nacelle_7_12_step025.csv'));
writetable(fullTable, fullfile(outDir, 'full_angle_zero_nacelle_7_12_step025.csv'));
report.legacy = legacy;
report.fullAngle = fullAngle;
report.legacyTable = legacyTable;
report.fullAngleTable = fullTable;
report.legacyAllConverged = all([legacy.points.converged]);
report.fullAngleAllConverged = all([fullAngle.points.converged]);
report.legacyMaxAbsSecondDiffTheta = max_abs_second_diff(legacyTable.thetaDeg);
report.fullAngleMaxAbsSecondDiffTheta = max_abs_second_diff(fullTable.thetaDeg);
report.fullAngleHasBranchWeight = any(fullTable.branchWeight ~= 0);
save(fullfile(outDir, 'zero_nacelle_bump_comparison.mat'), 'report', '-v7.3');
fprintf('\nZero-nacelle full-angle comparison\n');
fprintf('==================================\n');
fprintf('legacyAllConverged=%d fullAngleAllConverged=%d\n', report.legacyAllConverged, report.fullAngleAllConverged);
fprintf('legacyThetaSecondDiff=%.12e fullAngleThetaSecondDiff=%.12e branchWeightInNew=%d\n', ...
    report.legacyMaxAbsSecondDiffTheta, report.fullAngleMaxAbsSecondDiffTheta, report.fullAngleHasBranchWeight);
end

function T = points_to_table(sweep, expectBranchWeight)
n = numel(sweep.points);
V = zeros(n,1); thetaDeg = zeros(n,1); collectiveDeg = zeros(n,1); cyclicLongDeg = zeros(n,1);
residualNorm = zeros(n,1); converged = false(n,1); wingFx = zeros(n,1); wingFz = zeros(n,1); wingMy = zeros(n,1); branchWeight = zeros(n,1);
for i = 1:n
    p = sweep.points(i);
    V(i) = p.V;
    thetaDeg(i) = p.solutionDeg(1);
    collectiveDeg(i) = p.solutionDeg(2);
    cyclicLongDeg(i) = p.solutionDeg(3);
    residualNorm(i) = p.trimResidualNorm;
    converged(i) = p.converged;
    wing = find_wing(p.forcesMoments.components);
    wingFx(i) = wing.F(1);
    wingFz(i) = wing.F(3);
    wingMy(i) = wing.M(2);
    if expectBranchWeight
        branchWeight(i) = mean_branch_weight(wing.data.regions);
    end
end
T = table(V, thetaDeg, collectiveDeg, cyclicLongDeg, residualNorm, converged, wingFx, wingFz, wingMy, branchWeight);
end

function wing = find_wing(components)
for k = 1:numel(components)
    c = components(k);
    if strcmp(c.name, 'wing')
        wing = c;
        return;
    end
end
error('Wing component not found.');
end

function w = mean_branch_weight(regions)
values = [];
for i = 1:numel(regions)
    r = regions{i};
    if isfield(r, 'normalFlowBranchWeight')
        values(end+1) = r.normalFlowBranchWeight; %#ok<AGROW>
    end
end
if isempty(values)
    w = 0;
else
    w = mean(values);
end
end

function value = max_abs_second_diff(v)
if numel(v) < 3
    value = NaN;
else
    value = max(abs(diff(v, 2)));
end
end
