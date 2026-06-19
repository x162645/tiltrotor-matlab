function trendReport = check_article_trends()
%CHECK_ARTICLE_TRENDS NUAA Table 2 trend diagnostic at the model trim point.
%
% This function is a paper-trend diagnostic only. It is not a formal
% regression test and is not evidence that the current model reproduces
% NUAA Table 2. NUAA Table 2 uses Fx/Fy/Fz/Mx/My/Mz row labels, while the
% model B matrix rows are state derivatives
% [udot vdot wdot pdot qdot rdot phidot thetadot psidot]'.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir,'model'));
addpath(fullfile(rootDir,'analysis'));

P = params_nominal();

V = 0;
betaM = 0;
f0NormTolerance = P.trim.residualTolerance;
comparisonStep = 1.0e-4;
sensitivitySteps = [1.0e-3; 1.0e-4; 1.0e-5];

trendReport = struct();
trendReport.name = 'NUAA Table 2 trend diagnostic';
trendReport.scope = ['Diagnostic sign comparison only; not a formal ' ...
    'regression test or paper reproduction proof.'];
trendReport.formalComparable = false;
trendReport.formalComparableReason = ['NUAA Table 2 condition, control ' ...
    'units, body-axis directions, and row-label physical meanings are ' ...
    'UNVERIFIED.'];
trendReport.V = V;
trendReport.betaM = betaM;
trendReport.f0NormTolerance = f0NormTolerance;
trendReport.comparisonStep = comparisonStep;
trendReport.sensitivitySteps = sensitivitySteps;

[xTrim, uTrim, trimInfo] = trim_symmetric(V, betaM, P);
[f0, eomOut] = tiltrotor_eom(xTrim, uTrim, betaM, P);

trendReport.trim = trimInfo;
trendReport.trim.x = xTrim;
trendReport.trim.u = uTrim;
trendReport.trim.f0 = f0;
trendReport.trim.f0Norm = norm(f0);
trendReport.trim.f0NormTolerance = f0NormTolerance;
trendReport.trim.controlLimits = control_limit_report(uTrim, P);
trendReport.trim.anyControlAtLimit = any([trendReport.trim.controlLimits.atLimit]);
trendReport.trim.finite = is_real_finite(xTrim) && is_real_finite(uTrim) && ...
    is_real_finite(f0);
trendReport.trim.eomOut = eomOut;

trimComparable = trimInfo.exitflag > 0 && ...
    trimInfo.residualNorm <= P.trim.residualTolerance && ...
    trendReport.trim.f0Norm <= f0NormTolerance && ...
    trendReport.trim.finite;
trendReport.trim.comparable = trimComparable;

fprintf('\nNUAA Table 2 trend diagnostic\n');
fprintf('=============================\n');
fprintf('Diagnostic role: not a formal regression test or paper reproduction proof.\n');
fprintf('formalComparable: %d\n', trendReport.formalComparable);
fprintf('Trim point: V=%.6g m/s, betaM=%.6g rad\n', V, betaM);
fprintf('trim exitflag: %d\n', trimInfo.exitflag);
fprintf('trim residualNorm: %.12e\n', trimInfo.residualNorm);
fprintf('full f0 norm: %.12e (tolerance %.1e)\n', ...
    trendReport.trim.f0Norm, f0NormTolerance);
fprintf('full 9-state f0 [udot vdot wdot pdot qdot rdot phidot thetadot psidot]:\n');
fprintf('% .12e ', f0);
fprintf('\n');
fprintf('control at limit: %d\n', trendReport.trim.anyControlAtLimit);
print_control_limits(trendReport.trim.controlLimits);

if ~trimComparable
    trendReport.comparable = false;
    trendReport.comparisonStopReason = ['Trim failed, trim residual is too ' ...
        'large, f0 norm exceeds tolerance, or non-real/non-finite values exist.'];
    trendReport.names = {};
    trendReport.values = [];
    trendReport.expectedSigns = [];
    trendReport.actualSigns = [];
    trendReport.statuses = {};
    trendReport.matches = false(0,1);
    trendReport.diagnosticComparable = false(0,1);
    trendReport.diagnosticMatchFraction = NaN;
    trendReport.matchFraction = NaN;
    trendReport.finite = trendReport.trim.finite;
    fprintf('Comparison status: NOT_COMPARABLE\n');
    fprintf('%s\n', trendReport.comparisonStopReason);
    return;
end

[A, B, linInfo] = linearize_numeric(xTrim, uTrim, betaM, P);
trendReport.linearization.A = A;
trendReport.linearization.B = B;
trendReport.linearization.report = linInfo;
trendReport.linearization.finite = linInfo.finite && is_real_finite(A) && ...
    is_real_finite(B);

stateLabels = {'udot'; 'vdot'; 'wdot'; 'pdot'; 'qdot'; 'rdot'; ...
    'phidot'; 'thetadot'; 'psidot'};
bodyStateLabels = stateLabels(1:6);
trendReport.stateDerivativeMatrix.labels = stateLabels;
trendReport.stateDerivativeMatrix.bodyLabels = bodyStateLabels;
trendReport.stateDerivativeMatrix.B_col_diffCollective = B(:,2);
trendReport.stateDerivativeMatrix.B_col_diffCyclic = B(:,4);
trendReport.stateDerivativeMatrix.body_B_col_diffCollective = B(1:6,2);
trendReport.stateDerivativeMatrix.body_B_col_diffCyclic = B(1:6,4);

[loadDerivs, sensitivity] = load_derivative_diagnostics( ...
    xTrim, uTrim, betaM, P, comparisonStep, sensitivitySteps);
trendReport.generalizedLoadDerivatives = loadDerivs;
trendReport.stepSensitivity = sensitivity;

fprintf('\nState-derivative B matrix columns from linearize_numeric\n');
fprintf('Rows: udot vdot wdot pdot qdot rdot phidot thetadot psidot\n');
fprintf('B(:,2) diffCollective:\n');
fprintf('% .12e ', B(:,2));
fprintf('\n');
fprintf('B(:,4) diffCyclic:\n');
fprintf('% .12e ', B(:,4));
fprintf('\n');

fprintf('\nRaw generalized-load central differences from total_forces_moments\n');
fprintf('Rows: dFx dFy dFz dMx dMy dMz\n');
fprintf('d/d(diffCollective), h=%.1e:\n', comparisonStep);
fprintf('% .12e ', loadDerivs.diffCollective);
fprintf('\n');
fprintf('d/d(diffCyclic), h=%.1e:\n', comparisonStep);
fprintf('% .12e ', loadDerivs.diffCyclic);
fprintf('\n');

paperRefs = table2_references();
trendReport.paperReference = paperRefs;

stateComparisons = make_state_comparisons(B, paperRefs);
loadComparisons = make_load_comparisons(loadDerivs, paperRefs);
allComparisons = [stateComparisons(:); loadComparisons(:)];

trendReport.stateComparisons = stateComparisons;
trendReport.loadComparisons = loadComparisons;
trendReport.comparisons = allComparisons;

trendReport.names = {allComparisons.name}.';
trendReport.values = [allComparisons.value].';
trendReport.expectedSigns = [allComparisons.expectedSign].';
trendReport.actualSigns = [allComparisons.actualSign].';
trendReport.statuses = {allComparisons.status}.';
trendReport.matches = strcmp(trendReport.statuses, 'MATCH');
trendReport.diagnosticComparable = strcmp(trendReport.statuses, 'MATCH') | ...
    strcmp(trendReport.statuses, 'MISMATCH');

if any(trendReport.diagnosticComparable)
    trendReport.diagnosticMatchFraction = mean( ...
        trendReport.matches(trendReport.diagnosticComparable));
else
    trendReport.diagnosticMatchFraction = NaN;
end

% Backward-compatible alias. This is only a diagnostic sign fraction over
% comparable MATCH/MISMATCH items and does not represent model accuracy.
trendReport.matchFraction = trendReport.diagnosticMatchFraction;
trendReport.matchFractionMeaning = ['Alias of diagnosticMatchFraction; ' ...
    'not a model correctness rate.'];

trendReport.finite = trendReport.trim.finite && ...
    trendReport.linearization.finite && is_real_finite(loadDerivs.diffCollective) && ...
    is_real_finite(loadDerivs.diffCyclic);

fprintf('\nDiagnostic sign comparisons\n');
fprintf('Status values: MATCH, MISMATCH, NOT_COMPARABLE, MODEL_STRUCTURE_ZERO, UNVERIFIED\n');
for k = 1:numel(allComparisons)
    fprintf('%-34s value=% .6e expected=%+d status=%s\n', ...
        allComparisons(k).name, allComparisons(k).value, ...
        allComparisons(k).expectedSign, allComparisons(k).status);
end
fprintf('diagnosticMatchFraction: %.3f\n', trendReport.diagnosticMatchFraction);
fprintf('diagnosticMatchFraction is not a model accuracy or reproduction score.\n');
end

function refs = table2_references()
metadata = struct( ...
    'document', 'references/NUAA_main_paper.pdf', ...
    'pdfPage', 13, ...
    'originalPage', '13 of 18', ...
    'table', 'Table 2', ...
    'conditionCompleteness', 'UNVERIFIED', ...
    'controlUnit', 'UNVERIFIED', ...
    'bodyAxisDirection', 'UNVERIFIED', ...
    'rowLabelPhysicalMeaning', 'UNVERIFIED');

refs = ref_item('Fy', 'delta_cc',  3.3550, metadata);
refs(end+1) = ref_item('Mx', 'delta_cc', -17.0922, metadata);
refs(end+1) = ref_item('Mz', 'delta_cc',  0.9384, metadata);
refs(end+1) = ref_item('Fy', 'delta_ec',  0.1902, metadata);
refs(end+1) = ref_item('Mx', 'delta_ec', -0.0929, metadata);
refs(end+1) = ref_item('Mz', 'delta_ec', -3.6585, metadata);
end

function ref = ref_item(rowLabel, controlLabel, value, metadata)
ref = metadata;
ref.rowLabel = rowLabel;
ref.controlLabel = controlLabel;
ref.value = value;
ref.expectedSign = sign(value);
end

function comparisons = make_state_comparisons(B, refs)
comparisons = comparison_item( ...
    'vdot/ddiffCollective', B(2,2), find_ref(refs,'Fy','delta_cc'), ...
    'State derivative row; Table 2 row label is Fy, so this is diagnostic only.', '');
comparisons(end+1) = comparison_item( ...
    'pdot/ddiffCollective', B(4,2), find_ref(refs,'Mx','delta_cc'), ...
    'State derivative row; Table 2 row label is Mx, so this is diagnostic only.', '');
comparisons(end+1) = comparison_item( ...
    'rdot/ddiffCollective', B(6,2), find_ref(refs,'Mz','delta_cc'), ...
    'State derivative row; Table 2 row label is Mz, so this is diagnostic only.', '');
comparisons(end+1) = comparison_item( ...
    'vdot/ddiffCyclic', B(2,4), find_ref(refs,'Fy','delta_ec'), ...
    ['diffCyclic enters right+/left- cyclicSide and is mapped internally ' ...
    'to theta1s=-rotDir*cyclicSide; this remains a diagnostic sign comparison.'], '');
comparisons(end+1) = comparison_item( ...
    'pdot/ddiffCyclic', B(4,4), find_ref(refs,'Mx','delta_ec'), ...
    ['State pdot includes full inertia coupling; raw Mx derivative must be ' ...
    'checked separately.'], '');
comparisons(end+1) = comparison_item( ...
    'rdot/ddiffCyclic', B(6,4), find_ref(refs,'Mz','delta_ec'), ...
    'State derivative row; Table 2 row label is Mz, so this is diagnostic only.', '');
end

function comparisons = make_load_comparisons(loadDerivs, refs)
dc = loadDerivs.diffCollective;
de = loadDerivs.diffCyclic;
comparisons = comparison_item( ...
    'dFy/ddiffCollective', dc(2), find_ref(refs,'Fy','delta_cc'), ...
    'Raw generalized load derivative from total_forces_moments.', '');
comparisons(end+1) = comparison_item( ...
    'dMx/ddiffCollective', dc(4), find_ref(refs,'Mx','delta_cc'), ...
    'Raw generalized load derivative from total_forces_moments.', '');
comparisons(end+1) = comparison_item( ...
    'dMz/ddiffCollective', dc(6), find_ref(refs,'Mz','delta_cc'), ...
    'Raw generalized load derivative from total_forces_moments.', '');
comparisons(end+1) = comparison_item( ...
    'dFy/ddiffCyclic', de(2), find_ref(refs,'Fy','delta_ec'), ...
    ['Raw generalized load derivative from total_forces_moments after ' ...
    'theta1s=-rotDir*cyclicSide blade pitch mapping is applied.'], '');
comparisons(end+1) = comparison_item( ...
    'dMx/ddiffCyclic', de(4), find_ref(refs,'Mx','delta_ec'), ...
    'Raw generalized load derivative from total_forces_moments.', '');
comparisons(end+1) = comparison_item( ...
    'dMz/ddiffCyclic', de(6), find_ref(refs,'Mz','delta_ec'), ...
    'Raw generalized load derivative from total_forces_moments.', '');
end

function c = comparison_item(name, value, ref, note, forcedStatus)
actualSign = sign_with_zero(value);
if ~isempty(forcedStatus)
    status = forcedStatus;
elseif actualSign == ref.expectedSign
    status = 'MATCH';
else
    status = 'MISMATCH';
end

c.name = name;
c.value = value;
c.expectedValue = ref.value;
c.expectedSign = ref.expectedSign;
c.actualSign = actualSign;
c.status = status;
c.note = note;
c.reference = ref;
end

function ref = find_ref(refs, rowLabel, controlLabel)
for k = 1:numel(refs)
    if strcmp(refs(k).rowLabel, rowLabel) && ...
            strcmp(refs(k).controlLabel, controlLabel)
        ref = refs(k);
        return;
    end
end
error('Missing NUAA Table 2 reference for %s/%s.', rowLabel, controlLabel);
end

function [loadDerivs, sensitivity] = load_derivative_diagnostics( ...
    xTrim, uTrim, betaM, P, comparisonStep, sensitivitySteps)
labels = {'dFx'; 'dFy'; 'dFz'; 'dMx'; 'dMy'; 'dMz'};

loadDerivs.labels = labels;
loadDerivs.diffCollective = generalized_load_derivative( ...
    xTrim, uTrim, betaM, P, 2, comparisonStep);
loadDerivs.diffCyclic = generalized_load_derivative( ...
    xTrim, uTrim, betaM, P, 4, comparisonStep);

sensitivity.steps = sensitivitySteps;
sensitivity.labels = labels;
sensitivity.diffCollective = zeros(numel(labels), numel(sensitivitySteps));
sensitivity.diffCyclic = zeros(numel(labels), numel(sensitivitySteps));
sensitivity.diffCollectiveSigns = zeros(numel(labels), numel(sensitivitySteps));
sensitivity.diffCyclicSigns = zeros(numel(labels), numel(sensitivitySteps));

for k = 1:numel(sensitivitySteps)
    h = sensitivitySteps(k);
    sensitivity.diffCollective(:,k) = generalized_load_derivative( ...
        xTrim, uTrim, betaM, P, 2, h);
    sensitivity.diffCyclic(:,k) = generalized_load_derivative( ...
        xTrim, uTrim, betaM, P, 4, h);
    sensitivity.diffCollectiveSigns(:,k) = arrayfun( ...
        @sign_with_zero, sensitivity.diffCollective(:,k));
    sensitivity.diffCyclicSigns(:,k) = arrayfun( ...
        @sign_with_zero, sensitivity.diffCyclic(:,k));
end
end

function dLoad = generalized_load_derivative(xTrim, uTrim, betaM, P, idx, h)
up = uTrim;
um = uTrim;
up(idx) = up(idx) + h;
um(idx) = um(idx) - h;

[Fp, Mp] = total_forces_moments(xTrim, up, betaM, P);
[Fm, Mm] = total_forces_moments(xTrim, um, betaM, P);
dLoad = ([Fp; Mp] - [Fm; Mm])/(2*h);
end

function limits = control_limit_report(uCtrl, P)
tol = 1.0e-10;
names = {'collective'; 'rightCollective'; 'leftCollective'; ...
    'cyclic'; 'rightCyclicLong'; 'leftCyclicLong'; ...
    'aileron'; 'elevator'; 'rudder'};
values = [uCtrl(1); uCtrl(1)+uCtrl(2); uCtrl(1)-uCtrl(2); ...
    uCtrl(3); uCtrl(3)+uCtrl(4); uCtrl(3)-uCtrl(4); ...
    uCtrl(5); uCtrl(6); uCtrl(7)];
lower = [P.control.collectiveLim(1); P.control.collectiveLim(1); ...
    P.control.collectiveLim(1); P.control.cyclicLim(1); ...
    P.control.cyclicLim(1); P.control.cyclicLim(1); ...
    P.control.aileronLim(1); P.control.elevatorLim(1); ...
    P.control.rudderLim(1)];
upper = [P.control.collectiveLim(2); P.control.collectiveLim(2); ...
    P.control.collectiveLim(2); P.control.cyclicLim(2); ...
    P.control.cyclicLim(2); P.control.cyclicLim(2); ...
    P.control.aileronLim(2); P.control.elevatorLim(2); ...
    P.control.rudderLim(2)];

limits = struct([]);
for k = 1:numel(names)
    limits(k).name = names{k};
    limits(k).value = values(k);
    limits(k).lower = lower(k);
    limits(k).upper = upper(k);
    limits(k).atLower = abs(values(k)-lower(k)) <= tol;
    limits(k).atUpper = abs(values(k)-upper(k)) <= tol;
    limits(k).atLimit = limits(k).atLower || limits(k).atUpper;
end
end

function print_control_limits(limits)
fprintf('control limit check (rad):\n');
for k = 1:numel(limits)
    fprintf('  %-18s value=% .12e lower=% .12e upper=% .12e atLimit=%d\n', ...
        limits(k).name, limits(k).value, limits(k).lower, ...
        limits(k).upper, limits(k).atLimit);
end
end

function tf = is_real_finite(value)
tf = isreal(value) && all(isfinite(value(:)));
end

function s = sign_with_zero(value)
zeroTol = 1.0e-10;
if abs(value) <= zeroTol
    s = 0;
else
    s = sign(value);
end
end
