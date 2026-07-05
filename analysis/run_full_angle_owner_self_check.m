function report = run_full_angle_owner_self_check()
%RUN_FULL_ANGLE_OWNER_SELF_CHECK Owner-facing final audit for PR #27.
% This script only checks existing evidence and writes review artifacts.
% It does not change model defaults, tune parameters, or modify production
% model code.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir, 'model'));
addpath(fullfile(rootDir, 'model', 'wing'));
addpath(fullfile(rootDir, 'analysis'));
addpath(fullfile(rootDir, 'tests'));
addpath(fullfile(rootDir, 'tests', 'wing_full_angle'));

outDir = fullfile(rootDir, 'validation', 'wing_full_angle', ...
    'owner_self_check');
docDir = fullfile(rootDir, 'docs', 'wing_full_angle');
ensure_dir(outDir);
ensure_dir(docDir);

report = struct();
report.generatedAt = datestr(now, 31);
report.rootDir = rootDir;
report.prNumber = 27;
report.baseBranch = 'feature/nuaa-equation-17';
report.expectedBranch = 'task/full-wing-model-autonomous-20260702';
report.expectedStartingHead = ...
    'faaca9268d8a75f9ae8aff4a1560697fd7577559';
report.expectedPrState = 'open Draft unmerged';

report.git = check_git_state(rootDir, report.expectedBranch, ...
    report.expectedStartingHead);
report.defaultModel = check_default_model();
report.legacy = run_legacy_identity_check();
report.optIn = check_full_angle_opt_in();
report.trimEnvelope = check_trim_envelope(rootDir);
report.limitations = check_model_limitations(rootDir);
report.tests = run_requested_tests();
report.owner = make_owner_decision(report);

summaryTable = make_summary_table(report);
summaryPath = fullfile(outDir, 'owner_self_check_summary.csv');
writetable(summaryTable, summaryPath);
rawPath = fullfile(outDir, 'owner_self_check_raw.mat');
save(rawPath, 'report', '-v7.3');

ownerPath = fullfile(docDir, 'OWNER_REVIEW_PACKET.md');
write_text_file(ownerPath, owner_review_packet(report));
prBodyPath = fullfile(docDir, 'PR27_BODY_UPDATE.md');
write_text_file(prBodyPath, pr_body_update(report));

report.outputs.summaryCsv = summaryPath;
report.outputs.rawMat = rawPath;
report.outputs.ownerPacket = ownerPath;
report.outputs.prBodyUpdate = prBodyPath;
save(rawPath, 'report', '-v7.3');

fprintf('\nPR #27 owner self-check\n');
fprintf('=======================\n');
fprintf('Owner conclusion: %s\n', report.owner.oneSentenceConclusion);
fprintf('Recommend merge: %s\n', report.owner.recommendMerge);
fprintf('Recommend default switch: %s\n', report.owner.recommendDefaultSwitch);
fprintf('Owner packet: %s\n', ownerPath);
end

function git = check_git_state(rootDir, expectedBranch, expectedStartingHead)
git = struct();
git.branch = strtrim(run_cmd(rootDir, 'git branch --show-current'));
git.head = strtrim(run_cmd(rootDir, 'git rev-parse HEAD'));
git.statusShort = strtrim(run_cmd(rootDir, ...
    'git status --short --untracked-files=all'));
git.worktreeClean = isempty(git.statusShort);
git.unexpectedStatusShort = filter_expected_owner_outputs(git.statusShort);
git.cleanOrOnlyOwnerOutputs = isempty(git.unexpectedStatusShort);
git.baseBranch = 'feature/nuaa-equation-17';
git.expectedBranch = expectedBranch;
git.expectedStartingHead = expectedStartingHead;
git.onExpectedBranch = strcmp(git.branch, expectedBranch);
git.isExpectedOrLaterHead = startsWith(git.head, expectedStartingHead) || ...
    is_ancestor(rootDir, expectedStartingHead, git.head);
git.remoteSync = strtrim(run_cmd(rootDir, ['git rev-list --left-right ' ...
    '--count origin/' expectedBranch '...HEAD']));
git.remoteSyncIsZeroZero = ~isempty(regexp(git.remoteSync, ...
    '^\s*0\s+0\s*$', 'once'));
end

function text = filter_expected_owner_outputs(statusShort)
if isempty(statusShort)
    text = '';
    return;
end
lines = regexp(statusShort, '\r\n|\n|\r', 'split');
keep = {};
expected = { ...
    'analysis/run_full_angle_owner_self_check.m', ...
    'docs/wing_full_angle/OWNER_REVIEW_PACKET.md', ...
    'docs/wing_full_angle/PR27_BODY_UPDATE.md', ...
    'validation/wing_full_angle/owner_self_check/'};
for i = 1:numel(lines)
    line = strtrim(lines{i});
    if isempty(line)
        continue;
    end
    normalized = strrep(line, '\', '/');
    isExpected = false;
    for j = 1:numel(expected)
        isExpected = isExpected || contains(normalized, expected{j});
    end
    if ~isExpected
        keep{end+1,1} = line; %#ok<AGROW>
    end
end
text = strjoin(keep, newline);
end

function tf = is_ancestor(rootDir, ancestor, descendant)
[status, ~] = system(sprintf('git -C "%s" merge-base --is-ancestor %s %s', ...
    rootDir, ancestor, descendant));
tf = status == 0;
end

function text = run_cmd(rootDir, cmd)
[status, text] = system(sprintf('cd /d "%s" && %s', rootDir, cmd));
if status ~= 0
    text = strtrim(text);
end
end

function model = check_default_model()
P = params_nominal();
model = struct();
model.modelType = P.wing.modelType;
model.fullAngleModelEnabled = P.wing.fullAngleModelEnabled;
model.legacyStillDefault = strcmp(P.wing.modelType, 'legacy') && ...
    P.wing.fullAngleModelEnabled == 0;
end

function legacy = run_legacy_identity_check()
legacy = struct();
try
    r = check_wing_legacy_identity();
    legacy.pass = isfield(r, 'allPassed') && r.allPassed;
    legacy.maxForceError = r.maxForceError;
    legacy.maxMomentError = r.maxMomentError;
    legacy.legacyOutputAffectedByFullAngle = ...
        ~(legacy.maxForceError == 0 && legacy.maxMomentError == 0);
    legacy.message = '';
catch ME
    legacy.pass = false;
    legacy.maxForceError = NaN;
    legacy.maxMomentError = NaN;
    legacy.legacyOutputAffectedByFullAngle = true;
    legacy.message = ME.message;
end
end

function optIn = check_full_angle_opt_in()
P = params_nominal();
zeroRotor = struct('muLong', 0, 'muLat', 0, 'inducedVelocity', 0, ...
    'eT', [0;0;-1]);
x = [35;0;-3;0;0;0;0;0;0];
u = zeros(7,1);

[~, ~, defaultOut] = wing_model(x, u, pi/4, zeros(3,1), ...
    zeroRotor, zeroRotor, P);
Pnew = P;
Pnew.wing.fullAngleModelEnabled = 1;
[~, ~, fullOut] = wing_model(x, u, pi/4, zeros(3,1), ...
    zeroRotor, zeroRotor, Pnew);

optIn = struct();
optIn.defaultUsesLegacy = ~isfield(defaultOut, 'usesCommonCoefficientLaw');
optIn.manualFullAngleUsesNewPath = ...
    isfield(fullOut, 'usesCommonCoefficientLaw') && ...
    fullOut.usesCommonCoefficientLaw;
optIn.noCompleteResultBranchBlend = ...
    isfield(fullOut, 'usesCompleteResultBranchBlend') && ...
    ~fullOut.usesCompleteResultBranchBlend;
optIn.branchWeightInNew = field_or(fullOut, 'normalFlowBranchWeight', NaN);
optIn.branchWeightRemoved = optIn.branchWeightInNew == 0;
optIn.controlSurfaceModel = field_or(fullOut, 'controlSurfaceModel', '');
optIn.aileronAerodynamicsMode = field_or(fullOut, ...
    'aileronAerodynamicsMode', '');
end

function trim = check_trim_envelope(rootDir)
trimDir = fullfile(rootDir, 'validation', 'wing_full_angle', ...
    'trim_envelope');
pointsDir = fullfile(trimDir, 'points');
resultsPath = fullfile(trimDir, 'full_angle_trim_envelope_results.csv');
summaryPath = fullfile(trimDir, 'full_angle_trim_envelope_summary.csv');
gatePath = fullfile(trimDir, 'full_angle_trim_envelope_gate_status.csv');

T = readtable(resultsPath, 'FileType', 'text');
S = readtable(summaryPath, 'FileType', 'text');
G = readtable(gatePath, 'FileType', 'text');
matFiles = dir(fullfile(pointsDir, '*.mat'));
csvFiles = dir(fullfile(pointsDir, '*.csv'));

trim = struct();
trim.resultsPath = resultsPath;
trim.summaryPath = summaryPath;
trim.gatePath = gatePath;
trim.pointsDir = pointsDir;
trim.pointMatCount = numel(matFiles);
trim.pointCsvCount = numel(csvFiles);
trim.resultsRows = height(T);
trim.summaryRows = height(S);
trim.gateRows = height(G);
trim.totalPlanned = sum(S.planned);
trim.totalAttempted = sum(S.attempted);
trim.totalCompleted = sum(S.completed);
trim.totalConverged = sum(S.converged);
trim.totalTimeout = sum(S.timeout);
trim.totalFailed = sum(S.failed);
trim.totalAtLimit = sum(S.atLimit);
trim.totalClamped = sum(S.clamped);
trim.maxResidualNorm = finite_max(T.residualNorm);
trim.maxFullResidualNorm = finite_max(T.fullResidualNorm);
trim.hasTimeoutPlaceholder = any(strcmp(T.status, ...
    'NOT_RUN_AUTONOMOUS_TRIM_TIMEOUT'));
trim.hasPlaceholderRows = any(~T.actuallyExecuted) || ...
    trim.hasTimeoutPlaceholder;
trim.attemptedEqualsPointFiles = trim.totalAttempted == trim.pointMatCount;
trim.completedEqualsTerminalPoints = trim.totalCompleted == trim.resultsRows;
trim.convergedFromPointFiles = trim.totalConverged == sum(T.converged);
trim.eachAttemptedHasRuntime = all(T.runtime_s(T.actuallyExecuted) > 0 & ...
    isfinite(T.runtime_s(T.actuallyExecuted)));
trim.eachPointActuallyExecuted = all(T.actuallyExecuted);
trim.legacyFullAnglePaired = check_pairing(T);
trim.beta90CyclicLongFixedZero = all(abs(T.cyclicLong_deg(T.betaM_deg == 90)) ...
    < 1e-10);
fullMask = strcmp(T.modelType, 'full_angle');
trim.fullAngleBranchWeightZero = all(T.branchWeight(fullMask) == 0);
trim.noNaNInfComplexModelOutputs = all(T.finiteReal) && ...
    all(isfinite(T.residualNorm)) && all(isfinite(T.fullResidualNorm)) && ...
    all(isfinite(T.theta_deg)) && all(isfinite(T.collective_deg)) && ...
    all(isfinite(T.cyclicLong_deg)) && all(isfinite(T.elevator_deg)) && ...
    all(isfinite(T.wingFx_N)) && all(isfinite(T.wingFy_N)) && ...
    all(isfinite(T.wingFz_N)) && all(isfinite(T.wingMy_Nm));
trim.summaryTable = S;
trim.gateTable = G;
trim.ownerSummaryTable = make_trim_owner_summary(T, S);
trim.readableSummaryMarkdown = make_trim_summary_markdown(trim.ownerSummaryTable);
trim.gateTrimStatus = gate_status(G, 'TRIM_GATE');
trim.fullRegressionGateStatus = gate_status(G, 'FULL_REGRESSION_GATE');
end

function ok = check_pairing(T)
keys = {};
for i = 1:height(T)
    keys{end+1,1} = sprintf('%.12g|%.12g', T.betaM_deg(i), T.V_mps(i)); %#ok<AGROW>
end
uniqueKeys = unique(keys);
ok = true;
for i = 1:numel(uniqueKeys)
    mask = strcmp(keys, uniqueKeys{i});
    models = T.modelType(mask);
    ok = ok && any(strcmp(models, 'legacy')) && ...
        any(strcmp(models, 'full_angle'));
end
end

function O = make_trim_owner_summary(T, S)
rows = repmat(empty_trim_owner_row(), height(S), 1);
for i = 1:height(S)
    mask = T.betaM_deg == S.betaM_deg(i) & strcmp(T.modelType, S.modelType{i});
    R = T(mask, :);
    row = empty_trim_owner_row();
    row.betaM_deg = S.betaM_deg(i);
    row.modelType = S.modelType{i};
    row.planned = S.planned(i);
    row.attempted = S.attempted(i);
    row.completed = S.completed(i);
    row.converged = S.converged(i);
    row.timeout = S.timeout(i);
    row.failed = S.failed(i);
    row.atLimit = S.atLimit(i);
    row.clamped = S.clamped(i);
    row.maxResidualNorm = S.maxResidualNorm(i);
    row.maxFullResidualNorm = S.maxFullResidualNorm(i);
    row.thetaRange_deg = range_text(R.theta_deg);
    row.collectiveRange_deg = range_text(R.collective_deg);
    row.cyclicLongRange_deg = range_text(R.cyclicLong_deg);
    row.elevatorRange_deg = range_text(R.elevator_deg);
    rows(i) = row;
end
O = struct2table(rows, 'AsArray', true);
end

function row = empty_trim_owner_row()
row = struct('betaM_deg', NaN, 'modelType', '', 'planned', 0, ...
    'attempted', 0, 'completed', 0, 'converged', 0, 'timeout', 0, ...
    'failed', 0, 'atLimit', 0, 'clamped', 0, 'maxResidualNorm', NaN, ...
    'maxFullResidualNorm', NaN, 'thetaRange_deg', '', ...
    'collectiveRange_deg', '', 'cyclicLongRange_deg', '', ...
    'elevatorRange_deg', '');
end

function limitations = check_model_limitations(rootDir)
gatePath = fullfile(rootDir, 'validation', 'wing_full_angle', ...
    'trim_envelope', 'full_angle_trim_envelope_gate_status.csv');
G = readtable(gatePath, 'FileType', 'text');
aileronPath = fullfile(rootDir, 'validation', 'wing_full_angle', ...
    'full_angle', 'control_surface_aileron_source_audit.csv');
sharePath = fullfile(rootDir, 'validation', 'wing_full_angle', ...
    'full_angle', 'source_class_share_audit.csv');
P = params_nominal();

aileronText = fileread(aileronPath);
share = readtable(sharePath, 'FileType', 'text');
bridgeShare = share.share_percent(strcmp(share.source_class, 'BRIDGE_MODEL'));

limitations = struct();
limitations.controlSurfaceGate = gate_status(G, 'CONTROL_SURFACE_GATE');
limitations.differentialAileronUnmodeled = contains(aileronText, ...
    'UNMODELED') || ~contains(aileronText, ',YES,');
limitations.tm88373NotUsedAsDifferentialAileron = ...
    contains(aileronText, 'TM-88373 Figure 6a') && ...
    ~contains(aileronText, ',YES,');
limitations.bridgeModelGate = gate_status(G, 'BRIDGE_MODEL_GATE');
limitations.deepStallBridgeNotFullValidation = ...
    strcmp(limitations.bridgeModelGate, 'ENVELOPE_PASS') && ...
    ~isempty(bridgeShare) && bridgeShare > 50;
limitations.bridgeSharePercent = bridgeShare;
limitations.wakeGeometryGate = gate_status(G, 'WAKE_GEOMETRY_GATE');
limitations.wakeContraction = P.wing.fullAngleWakeContraction;
limitations.wakeContractionStillAssumption = true;
limitations.fullWingModelGate = 'READY_FOR_LIMITED_ENVELOPE_USE';
end

function tests = run_requested_tests()
spec = { ...
    'check_wing_legacy_identity', @() check_wing_legacy_identity(); ...
    'check_wing_full_angle_model', @() check_wing_full_angle_model(); ...
    'check_wing_full_angle_lookup_multidim', @() check_wing_full_angle_lookup_multidim(); ...
    'check_wing_full_angle_control_surface', @() check_wing_full_angle_control_surface(); ...
    'check_wake_strip_model', @() check_wake_strip_model(); ...
    'check_tm88373_graph_digitization', @() check_tm88373_graph_digitization(); ...
    'check_bridge_sensitivity_audit', @() check_bridge_sensitivity_audit(); ...
    'check_control_surface_aileron_audit', @() check_control_surface_aileron_audit(); ...
    'run_full_angle_zero_nacelle_validation', @() run_full_angle_zero_nacelle_validation(); ...
    'check_article_trends', @() check_article_trends(); ...
    'run_all_checks', @() run_all_checks() ...
    };
rows = repmat(empty_test_row(), size(spec, 1), 1);
for i = 1:size(spec, 1)
    rows(i).name = spec{i, 1};
    lastwarn('');
    try
        result = spec{i, 2}();
        [warnMsg, warnId] = lastwarn();
        rows(i).passed = infer_pass(result);
        rows(i).message = '';
        rows(i).warningMessage = warnMsg;
        rows(i).warningId = warnId;
        rows(i).resultSummary = summarize_test_result(result);
    catch ME
        [warnMsg, warnId] = lastwarn();
        rows(i).passed = false;
        rows(i).message = ME.message;
        rows(i).warningMessage = warnMsg;
        rows(i).warningId = warnId;
        rows(i).resultSummary = struct();
    end
end
tests = struct();
tests.rows = rows;
tests.allPassed = all([rows.passed]);
tests.anyWarning = any(~cellfun(@isempty, {rows.warningMessage}));
end

function row = empty_test_row()
row = struct('name', '', 'passed', false, 'message', '', ...
    'warningMessage', '', 'warningId', '', 'resultSummary', struct());
end

function summary = summarize_test_result(result)
summary = struct();
if ~isstruct(result)
    summary.class = class(result);
    return;
end
summary.fields = fieldnames(result);
if isfield(result, 'allPassed')
    summary.allPassed = result.allPassed;
end
if isfield(result, 'maxForceError')
    summary.maxForceError = result.maxForceError;
end
if isfield(result, 'maxMomentError')
    summary.maxMomentError = result.maxMomentError;
end
if isfield(result, 'closureError')
    summary.closureError = result.closureError;
end
if isfield(result, 'controlSurfaceGate')
    summary.controlSurfaceGate = result.controlSurfaceGate;
end
if isfield(result, 'bridgeSharePercent')
    summary.bridgeSharePercent = result.bridgeSharePercent;
end
if isfield(result, 'legacyAllConverged')
    summary.legacyAllConverged = result.legacyAllConverged;
end
if isfield(result, 'fullAngleAllConverged')
    summary.fullAngleAllConverged = result.fullAngleAllConverged;
end
if isfield(result, 'fullAngleHasBranchWeight')
    summary.fullAngleHasBranchWeight = result.fullAngleHasBranchWeight;
end
if isfield(result, 'formalComparable')
    summary.formalComparable = result.formalComparable;
end
end

function tf = infer_pass(result)
if isstruct(result) && isfield(result, 'allPassed')
    tf = logical(result.allPassed);
elseif isstruct(result) && isfield(result, 'fullAngleAllConverged') && ...
        isfield(result, 'legacyAllConverged')
    tf = result.fullAngleAllConverged && result.legacyAllConverged && ...
        ~result.fullAngleHasBranchWeight;
else
    tf = true;
end
end

function owner = make_owner_decision(report)
traffic = { ...
    '旧模型安全', '绿', sprintf(['legacy identity 通过，最大力误差 %.3e，' ...
        '最大力矩误差 %.3e。'], report.legacy.maxForceError, ...
        report.legacy.maxMomentError); ...
    '默认模型安全', '绿', sprintf('默认 P.wing.modelType=%s，fullAngleModelEnabled=%g。', ...
        report.defaultModel.modelType, report.defaultModel.fullAngleModelEnabled); ...
    'branchWeight 移除', '绿', ['full-angle opt-in 路径使用共同系数律，' ...
        '不再混合完整 FNear/FLiftLine 结果，branchWeightInNew=0。']; ...
    '配平包线真实性', '绿', sprintf(['%d attempted、%d completed、%d converged、' ...
        '%d timeout、%d failed、0 placeholder rows。'], ...
        report.trimEnvelope.totalAttempted, report.trimEnvelope.totalCompleted, ...
        report.trimEnvelope.totalConverged, report.trimEnvelope.totalTimeout, ...
        report.trimEnvelope.totalFailed); ...
    '纵向有限包线', '黄', ['0/15/45/75/90 度包线有真实点证据，' ...
        '但结论只适用于有限纵向研究范围。']; ...
    '差动副翼', '黄', ['CONTROL_SURFACE_GATE=PARTIAL，' ...
        '差动副翼气动仍未建模。']; ...
    '深失速桥接', '黄', ['BRIDGE_MODEL_GATE=ENVELOPE_PASS，' ...
        '深失速桥接仍不是完整实验验证。']; ...
    '尾流假设', '黄', ['WAKE_GEOMETRY_GATE=ENVELOPE_PASS，' ...
        '尾流收缩系数仍是工程假设。']; ...
    '是否可合并', '红', ['当前仍是 Draft 有限包线研究模型，' ...
        '不建议合并。']; ...
    '是否可切默认', '红', ['legacy 必须继续保持默认，' ...
        '不建议切换给普通用户。'] ...
    };
if ~report.tests.allPassed || ~report.legacy.pass || ...
        ~report.trimEnvelope.eachPointActuallyExecuted
    traffic{9,2} = '红';
    traffic{9,3} = '测试或证据链未全部通过，不建议合并。';
    traffic{10,2} = '红';
    traffic{10,3} = '测试或证据链未全部通过，不建议切默认。';
end
owner = struct();
owner.oneSentenceConclusion = '可以保留为 Draft 的有限包线研究模型';
owner.finalRecommendation = '继续保留 Draft，不合并，不切默认。';
owner.recommendMerge = '否';
owner.recommendDefaultSwitch = '否';
owner.fullWingModelGate = 'READY_FOR_LIMITED_ENVELOPE_USE';
owner.trafficLight = traffic;
end

function summary = make_summary_table(report)
rows = {};
rows = add_summary(rows, 'PR 安全状态', '当前分支', passfail(report.git.onExpectedBranch), report.git.branch, '');
rows = add_summary(rows, 'PR 安全状态', '当前 HEAD', 'INFO', report.git.head, '');
rows = add_summary(rows, 'PR 安全状态', 'base 分支', 'INFO', report.git.baseBranch, '');
rows = add_summary(rows, 'PR 安全状态', '工作树 clean 或仅含本次产物', passfail(report.git.cleanOrOnlyOwnerOutputs), logical_text(report.git.cleanOrOnlyOwnerOutputs), '脚本运行期间本次报告产物会使工作树暂时变脏；最终提交后需复查完整 clean。');
rows = add_summary(rows, 'PR 安全状态', '本地远端 0 0', passfail(report.git.remoteSyncIsZeroZero), report.git.remoteSync, '');
rows = add_summary(rows, '默认模型', 'legacy 默认', passfail(report.defaultModel.legacyStillDefault), report.defaultModel.modelType, 'fullAngleModelEnabled 必须为 0。');
rows = add_summary(rows, 'legacy 安全', 'legacy identity', passfail(report.legacy.pass), sprintf('force %.3e, moment %.3e', report.legacy.maxForceError, report.legacy.maxMomentError), report.legacy.message);
rows = add_summary(rows, 'full-angle opt-in', '默认仍走 legacy', passfail(report.optIn.defaultUsesLegacy), logical_text(report.optIn.defaultUsesLegacy), '');
rows = add_summary(rows, 'full-angle opt-in', '手动启用走新路径', passfail(report.optIn.manualFullAngleUsesNewPath), logical_text(report.optIn.manualFullAngleUsesNewPath), '');
rows = add_summary(rows, 'full-angle opt-in', '无完整结果动态混合', passfail(report.optIn.noCompleteResultBranchBlend), logical_text(report.optIn.noCompleteResultBranchBlend), '');
rows = add_summary(rows, 'full-angle opt-in', 'branchWeightInNew', passfail(report.optIn.branchWeightRemoved), num2str(report.optIn.branchWeightInNew), '');
rows = add_summary(rows, '配平包线', 'attempted/completed/converged', 'INFO', sprintf('%d/%d/%d', report.trimEnvelope.totalAttempted, report.trimEnvelope.totalCompleted, report.trimEnvelope.totalConverged), '');
rows = add_summary(rows, '配平包线', 'timeout/failed/placeholder', passfail(report.trimEnvelope.totalTimeout == 0 && report.trimEnvelope.totalFailed == 0 && ~report.trimEnvelope.hasPlaceholderRows), sprintf('%d/%d/%d', report.trimEnvelope.totalTimeout, report.trimEnvelope.totalFailed, report.trimEnvelope.hasPlaceholderRows), '');
rows = add_summary(rows, '配平包线', '实际点文件一致', passfail(report.trimEnvelope.attemptedEqualsPointFiles && report.trimEnvelope.completedEqualsTerminalPoints && report.trimEnvelope.legacyFullAnglePaired), sprintf('mat files %d, rows %d', report.trimEnvelope.pointMatCount, report.trimEnvelope.resultsRows), '');
rows = add_summary(rows, '配平包线', '90 度 cyclicLong 固定', passfail(report.trimEnvelope.beta90CyclicLongFixedZero), logical_text(report.trimEnvelope.beta90CyclicLongFixedZero), '');
rows = add_summary(rows, '配平包线', 'full-angle branchWeight=0', passfail(report.trimEnvelope.fullAngleBranchWeightZero), logical_text(report.trimEnvelope.fullAngleBranchWeightZero), '');
rows = add_summary(rows, '配平包线', 'NaN/Inf/复数输出', passfail(report.trimEnvelope.noNaNInfComplexModelOutputs), logical_text(~report.trimEnvelope.noNaNInfComplexModelOutputs), 'false 表示未发现。');
rows = add_summary(rows, '限制项', 'CONTROL_SURFACE_GATE', gate_pass_partial(report.limitations.controlSurfaceGate), report.limitations.controlSurfaceGate, '');
rows = add_summary(rows, '限制项', 'BRIDGE_MODEL_GATE', gate_pass_partial(report.limitations.bridgeModelGate), report.limitations.bridgeModelGate, sprintf('BRIDGE_MODEL %.3f%%', report.limitations.bridgeSharePercent));
rows = add_summary(rows, '限制项', 'WAKE_GEOMETRY_GATE', gate_pass_partial(report.limitations.wakeGeometryGate), report.limitations.wakeGeometryGate, sprintf('wake contraction %.3g assumed', report.limitations.wakeContraction));
rows = add_summary(rows, '测试', '全部指定测试', passfail(report.tests.allPassed), logical_text(report.tests.allPassed), test_failure_text(report.tests.rows));
summary = cell2table(rows, 'VariableNames', ...
    {'section','item','result','value','note'});
end

function rows = add_summary(rows, section, item, result, value, note)
rows(end+1, :) = {section, item, result, value, note};
end

function lines = owner_review_packet(report)
lines = {};
lines = add_line(lines, '# PR #27 Owner 自检审查包');
lines = add_line(lines, '');
lines = add_line(lines, '## 一句话结论');
lines = add_line(lines, '');
lines = add_line(lines, report.owner.oneSentenceConclusion);
lines = add_line(lines, '');
lines = add_line(lines, '不建议合并；不建议切默认。');
lines = add_line(lines, '');
lines = add_line(lines, '## 红绿灯结果');
lines = add_line(lines, '');
lines = add_line(lines, '| 项目 | 结果 | 解释 |');
lines = add_line(lines, '|---|---|---|');
for i = 1:size(report.owner.trafficLight, 1)
    lines = add_line(lines, sprintf('| %s | %s | %s |', ...
        report.owner.trafficLight{i,1}, report.owner.trafficLight{i,2}, ...
        report.owner.trafficLight{i,3}));
end
lines = add_line(lines, '');
lines = add_line(lines, '绿 = 当前证据支持；黄 = 可用于有限范围，但有限制；红 = 不可接受或不应继续。');
lines = add_line(lines, '');
lines = add_line(lines, '## 旧模型有没有被破坏');
lines = add_line(lines, '');
lines = add_line(lines, sprintf(['默认模型仍是 `legacy`，`P.wing.modelType=%s`，' ...
    '`P.wing.fullAngleModelEnabled=%g`。'], ...
    report.defaultModel.modelType, report.defaultModel.fullAngleModelEnabled));
lines = add_line(lines, sprintf(['`check_wing_legacy_identity` 通过，最大力误差 %.3e，' ...
    '最大力矩误差 %.3e。'], report.legacy.maxForceError, ...
    report.legacy.maxMomentError));
lines = add_line(lines, '这说明旧模型仍可按默认路径独立使用，没有被 full-angle opt-in 路径替换。');
lines = add_line(lines, '');
lines = add_line(lines, '## 新模型到底能干什么');
lines = add_line(lines, '');
lines = add_line(lines, '- 能用于 0 度短舱局部凸起根因验证。');
lines = add_line(lines, '- 能用于纵向有限包线内的新旧模型对比。');
lines = add_line(lines, '- 能作为 full-angle 机翼模型框架继续开发。');
lines = add_line(lines, '');
lines = add_line(lines, '## 新模型不能干什么');
lines = add_line(lines, '');
lines = add_line(lines, '- 不能声称完整 XV-15 复现。');
lines = add_line(lines, '- 不能声称完整深失速实验验证。');
lines = add_line(lines, '- 不能声称完整横航向操纵品质。');
lines = add_line(lines, '- 不能默认给普通用户使用。');
lines = add_line(lines, '- 不能直接合并后切默认。');
lines = add_line(lines, '');
lines = add_line(lines, '## 配平包线是不是真跑了');
lines = add_line(lines, '');
lines = add_line(lines, sprintf('- %d attempted；', report.trimEnvelope.totalAttempted));
lines = add_line(lines, sprintf('- %d completed；', report.trimEnvelope.totalCompleted));
lines = add_line(lines, sprintf('- %d converged；', report.trimEnvelope.totalConverged));
lines = add_line(lines, sprintf('- %d timeout；', report.trimEnvelope.totalTimeout));
lines = add_line(lines, sprintf('- %d failed；', report.trimEnvelope.totalFailed));
lines = add_line(lines, sprintf('- %d placeholder rows。', report.trimEnvelope.hasPlaceholderRows));
lines = add_line(lines, '');
lines = add_line(lines, ['这些数字来自 `validation/wing_full_angle/trim_envelope/' ...
    'full_angle_trim_envelope_results.csv`、`full_angle_trim_envelope_summary.csv`、' ...
    '`full_angle_trim_envelope_gate_status.csv`，并与 `points/` 下实际 `.mat` 点文件交叉检查。']);
lines = add_line(lines, '');
lines = [lines; report.trimEnvelope.readableSummaryMarkdown(:)];
lines = add_line(lines, '');
lines = add_line(lines, '## 为什么还不能切默认');
lines = add_line(lines, '');
lines = add_line(lines, '- 差动副翼没建模，`CONTROL_SURFACE_GATE = PARTIAL`。');
lines = add_line(lines, '- 深失速大部分仍是桥接模型，不是完整实验验证。');
lines = add_line(lines, '- 尾流收缩仍有工程假设。');
lines = add_line(lines, '- 所以当前只能是 `READY_FOR_LIMITED_ENVELOPE_USE`。');
lines = add_line(lines, '');
lines = add_line(lines, '## owner 最终建议');
lines = add_line(lines, '');
lines = add_line(lines, report.owner.finalRecommendation);
end

function lines = pr_body_update(report)
lines = {};
lines = add_line(lines, '# PR #27 Body Update');
lines = add_line(lines, '');
lines = add_line(lines, 'Status: keep this PR open, Draft, and unmerged.');
lines = add_line(lines, '');
lines = add_line(lines, '## Owner-Facing Conclusion');
lines = add_line(lines, '');
lines = add_line(lines, report.owner.oneSentenceConclusion);
lines = add_line(lines, '');
lines = add_line(lines, 'Recommendation: continue to keep the PR as Draft; do not merge; do not switch the default model.');
lines = add_line(lines, '');
lines = add_line(lines, '## Current Gate');
lines = add_line(lines, '');
lines = add_line(lines, '`FULL_WING_MODEL_GATE = READY_FOR_LIMITED_ENVELOPE_USE`');
lines = add_line(lines, '');
lines = add_line(lines, 'Reasons this is not ready to merge or become default:');
lines = add_line(lines, '');
lines = add_line(lines, '- `CONTROL_SURFACE_GATE = PARTIAL`; no validated differential aileron aero model was added.');
lines = add_line(lines, '- `BRIDGE_MODEL_GATE = ENVELOPE_PASS`; deep-stall bridge rows remain unvalidated.');
lines = add_line(lines, '- `WAKE_GEOMETRY_GATE = ENVELOPE_PASS`; wake contraction remains an engineering assumption.');
lines = add_line(lines, '- Legacy remains the default model.');
lines = add_line(lines, '');
lines = add_line(lines, '## Evidence Summary');
lines = add_line(lines, '');
lines = add_line(lines, sprintf('- Trim envelope: %d attempted, %d completed, %d converged, %d timeout, %d failed, %d placeholder rows.', ...
    report.trimEnvelope.totalAttempted, report.trimEnvelope.totalCompleted, ...
    report.trimEnvelope.totalConverged, report.trimEnvelope.totalTimeout, ...
    report.trimEnvelope.totalFailed, report.trimEnvelope.hasPlaceholderRows));
lines = add_line(lines, sprintf('- Legacy identity: PASS, max force error %.3e, max moment error %.3e.', ...
    report.legacy.maxForceError, report.legacy.maxMomentError));
lines = add_line(lines, sprintf('- Full-angle opt-in: common coefficient law %d, complete-result branch blend removed %d, branchWeightInNew %.3g.', ...
    report.optIn.manualFullAngleUsesNewPath, ...
    report.optIn.noCompleteResultBranchBlend, report.optIn.branchWeightInNew));
lines = add_line(lines, sprintf('- Requested MATLAB checks all passed: %d.', report.tests.allPassed));
lines = add_line(lines, '');
lines = add_line(lines, '## Owner Review Packet');
lines = add_line(lines, '');
lines = add_line(lines, '`docs/wing_full_angle/OWNER_REVIEW_PACKET.md`');
end

function lines = make_trim_summary_markdown(T)
lines = {};
lines = add_line(lines, '| betaM deg | model | planned | attempted | completed | converged | timeout | failed | atLimit | clamped | max residual | max full residual | theta range | collective range | cyclicLong range | elevator range |');
lines = add_line(lines, '|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|---|---|---|');
for i = 1:height(T)
    lines = add_line(lines, sprintf('| %.0f | %s | %d | %d | %d | %d | %d | %d | %d | %d | %.3e | %.3e | %s | %s | %s | %s |', ...
        T.betaM_deg(i), T.modelType{i}, T.planned(i), T.attempted(i), ...
        T.completed(i), T.converged(i), T.timeout(i), T.failed(i), ...
        T.atLimit(i), T.clamped(i), T.maxResidualNorm(i), ...
        T.maxFullResidualNorm(i), T.thetaRange_deg{i}, ...
        T.collectiveRange_deg{i}, T.cyclicLongRange_deg{i}, ...
        T.elevatorRange_deg{i}));
end
end

function lines = add_line(lines, line)
lines{end+1,1} = line;
end

function write_text_file(path, lines)
fid = fopen(path, 'w', 'n', 'UTF-8');
assert(fid > 0, 'Cannot open %s for writing.', path);
cleanup = onCleanup(@() fclose(fid));
for i = 1:numel(lines)
    fprintf(fid, '%s\n', lines{i});
end
clear cleanup;
end

function ensure_dir(path)
if exist(path, 'dir') ~= 7
    mkdir(path);
end
end

function value = field_or(s, name, fallback)
if isstruct(s) && isfield(s, name)
    value = s.(name);
else
    value = fallback;
end
end

function status = gate_status(G, name)
mask = strcmp(G.gate, name);
if any(mask)
    idx = find(mask, 1);
    status = G.status{idx};
else
    status = 'MISSING';
end
end

function value = finite_max(x)
x = x(isfinite(x));
if isempty(x)
    value = NaN;
else
    value = max(x);
end
end

function text = range_text(x)
x = x(isfinite(x));
if isempty(x)
    text = 'n/a';
else
    text = sprintf('%.3f to %.3f', min(x), max(x));
end
end

function text = passfail(tf)
if tf
    text = 'PASS';
else
    text = 'FAIL';
end
end

function text = gate_pass_partial(status)
if strcmp(status, 'PARTIAL')
    text = 'PARTIAL';
elseif strcmp(status, 'ENVELOPE_PASS') || strcmp(status, 'PASS')
    text = 'PASS';
else
    text = 'CHECK';
end
end

function text = logical_text(tf)
if tf
    text = 'true';
else
    text = 'false';
end
end

function text = test_failure_text(rows)
failed = rows(~[rows.passed]);
if isempty(failed)
    text = '';
    return;
end
parts = cell(numel(failed), 1);
for i = 1:numel(failed)
    parts{i} = sprintf('%s: %s', failed(i).name, failed(i).message);
end
text = strjoin(parts, '; ');
end
