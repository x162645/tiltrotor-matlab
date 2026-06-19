function report = check_wing_normal_flow_blend()
%CHECK_WING_NORMAL_FLOW_BLEND Component-level continuity check for wing blend.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir,'model'));

P0 = params_nominal();
widths = unique([0.03, 0.05, 0.08, P0.wing.normalFlowBlendHalfWidth]);
reports = [];

for iWidth = 1:numel(widths)
    P = P0;
    P.wing.normalFlowBlendHalfWidth = widths(iWidth);
    thisReport = evaluate_width(P);
    if isempty(reports)
        reports = repmat(thisReport, numel(widths), 1);
    else
        reports(iWidth) = thisReport;
    end
end

report.widths = widths;
report.cases = reports;
report.allPassed = all([reports.passed]);

fprintf('\nWing normal-flow blend continuity\n');
fprintf('=================================\n');
for iWidth = 1:numel(reports)
    r = reports(iWidth);
    fprintf(['halfWidth=%.3f maxStep=%.6e maxDerivJump=%.6e ' ...
        'leftC1=%.6e rightC1=%.6e weightRange=[%.6f %.6f] passed=%d\n'], ...
        r.halfWidth, r.maxAdjacentLoadStep, r.maxDerivativeJump, ...
        r.leftEndpointC1RelativeError, r.rightEndpointC1RelativeError, ...
        r.minWeight, r.maxWeight, r.passed);
end

assert(report.allPassed, ...
    'Wing normal-flow blend continuity check failed.');
end

function widthReport = evaluate_width(P)
center = P.wing.normalFlowRatio;
halfWidth = P.wing.normalFlowBlendHalfWidth;
lower = center - halfWidth;
upper = center + halfWidth;

scanMin = min(0.25, max(0.01, lower - 0.05));
scanMax = max(0.45, min(0.95, upper + 0.05));
ratios = unique([scanMin:0.001:scanMax, 0.25:0.001:0.45, ...
    lower + (-4:4)*1.0e-4, upper + (-4:4)*1.0e-4]);
ratios = ratios(ratios >= scanMin & ratios <= scanMax);
n = numel(ratios);
loads = zeros(n, 6);
weights = zeros(n, 1);
finiteFlags = false(n, 1);
outsideBranchConsistent = true;
deterministic = true;

for k = 1:n
    [load1, out1] = wing_load_at_ratio(P, ratios(k));
    [load2, out2] = wing_load_at_ratio(P, ratios(k));
    loads(k,:) = load1(:).';
    weights(k) = representative_weight(out1);
    finiteFlags(k) = is_real_finite(load1) && is_real_finite(weights(k));
    deterministic = deterministic && norm(load1 - load2) <= ...
        1.0e-11*max(norm(load1), 1);
    deterministic = deterministic && abs(weights(k) - ...
        representative_weight(out2)) <= 1.0e-14;
    outsideBranchConsistent = outsideBranchConsistent && ...
        branch_limit_consistent(out1, ratios(k), lower, upper);
end

dr = diff(ratios(:));
dLoads = diff(loads, 1, 1)./dr;
ddLoads = diff(dLoads, 1, 1)./max(diff(ratios(1:end-1)).', eps);

scaleLoad = max(max(vecnorm(loads, 2, 2)), 1);
maxStep = max(vecnorm(diff(loads, 1, 1), 2, 2));
maxDerivativeJump = max(vecnorm(diff(dLoads, 1, 1), 2, 2));

weightMonotonic = all(diff(weights) >= -1.0e-12);
weightLowerOk = all(weights(ratios <= lower + 1.0e-12) <= 1.0e-12);
weightUpperOk = all(weights(ratios >= upper - 1.0e-12) >= 1 - 1.0e-12);

h = 1.0e-4;
leftC1 = endpoint_c1_error(P, lower, h);
rightC1 = endpoint_c1_error(P, upper, h);

passed = all(finiteFlags) && deterministic && outsideBranchConsistent && ...
    weightMonotonic && weightLowerOk && weightUpperOk && ...
    maxStep/scaleLoad < 0.08 && ...
    maxDerivativeJump < 5.0e7 && ...
    leftC1 < 0.08 && rightC1 < 0.08 && ...
    all(isfinite(ddLoads(:)));

widthReport.halfWidth = halfWidth;
widthReport.lower = lower;
widthReport.upper = upper;
widthReport.minWeight = min(weights);
widthReport.maxWeight = max(weights);
widthReport.maxAdjacentLoadStep = maxStep;
widthReport.maxDerivativeJump = maxDerivativeJump;
widthReport.leftEndpointC1RelativeError = leftC1;
widthReport.rightEndpointC1RelativeError = rightC1;
widthReport.outsideBranchConsistent = outsideBranchConsistent;
widthReport.weightMonotonic = weightMonotonic;
widthReport.weightLowerOk = weightLowerOk;
widthReport.weightUpperOk = weightUpperOk;
widthReport.deterministic = deterministic;
widthReport.allFiniteReal = all(finiteFlags);
widthReport.passed = passed;
end

function tf = branch_limit_consistent(out, ratio, lower, upper)
tf = true;
for iRegion = 1:numel(out.regions)
    r = out.regions{iRegion};
    if ~isfield(r, 'FNear')
        continue;
    end
    load = [r.F(:); r.M(:)];
    if ratio <= lower
        branchLoad = [r.FNear(:); r.MNear(:)];
    elseif ratio >= upper
        branchLoad = [r.FLiftLine(:); r.MLiftLine(:)];
    else
        continue;
    end
    tf = tf && norm(load - branchLoad) <= ...
        1.0e-11*max(norm(branchLoad), 1);
end
end

function w = representative_weight(out)
weights = zeros(numel(out.regions), 1);
for iRegion = 1:numel(out.regions)
    r = out.regions{iRegion};
    if isfield(r, 'normalFlowBranchWeight')
        weights(iRegion) = r.normalFlowBranchWeight;
    end
end
w = mean(weights);
end

function err = endpoint_c1_error(P, ratio0, h)
[lm1, ~] = wing_load_at_ratio(P, ratio0 - h);
[l0, ~] = wing_load_at_ratio(P, ratio0);
[lp1, ~] = wing_load_at_ratio(P, ratio0 + h);
dLeft = (l0 - lm1)/h;
dRight = (lp1 - l0)/h;
err = norm(dRight - dLeft)/max([norm(dLeft), norm(dRight), 1]);
end

function [load, out] = wing_load_at_ratio(P, ratio)
Vmag = 24;
vzSign = -1;
vx = ratio*Vmag;
vz = vzSign*sqrt(max(1 - ratio^2, 0))*Vmag;
x = [vx; 0; vz; zeros(6,1)];
uCtrl = zeros(7,1);
zeroRotor = struct('muLong',0,'muLat',0,'inducedVelocity',0, ...
    'eT',[0;0;-1]);
[F, M, out] = wing_model(x, uCtrl, 0, zeros(3,1), ...
    zeroRotor, zeroRotor, P);
load = [F(:); M(:)];
end

function tf = is_real_finite(value)
tf = isreal(value) && all(isfinite(value(:)));
end
