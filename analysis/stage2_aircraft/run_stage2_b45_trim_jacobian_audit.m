function results = run_stage2_b45_trim_jacobian_audit(outputRoot)
%RUN_STAGE2_B45_TRIM_JACOBIAN_AUDIT Diagnose the isolated B45 M1 trim failure.
% The audit reuses the exact deterministic multistart contract, selects the
% lowest-residual physically supported returned point for each representative
% condition, and differentiates the exact current trim definition. B15/B75
% are retained only as local numerical references. No new control DOF or
% physical-model change is introduced.

if nargin < 1 || isempty(outputRoot)
    outputRoot = fullfile(pwd,'results','stage2_b45_trim_jacobian_audit');
end
if ~exist(outputRoot,'dir'), mkdir(outputRoot); end

multistartRoot = fullfile(outputRoot,'multistart_reexecution');
ms = run_stage2_m1_trim_multistart_diagnostic(multistartRoot);
P = stage2_matched_rotor_parameters();
d2r = pi/180;
conditions = repmat(struct('name','','V',NaN,'betaM',NaN,'gamma',0,'mode',''),3,1);
conditions(1) = struct('name','B15_V020','V',20,'betaM',15*d2r,'gamma',0, ...
    'mode','helicopter_longitudinal');
conditions(2) = struct('name','B45_V035','V',35,'betaM',45*d2r,'gamma',0, ...
    'mode','conversion_longitudinal');
conditions(3) = struct('name','B75_V080','V',80,'betaM',75*d2r,'gamma',0, ...
    'mode','airplane_longitudinal');

audits = cell(3,1);
summaryRows = repmat(empty_summary(),3,1);
robustnessRows = repmat(empty_robustness_row(),9,1);
robustIdx = 0;

for i = 1:3
    [bestReport,bestSeedIndex] = select_best_supported(ms.reports(i,:));
    assert(~isempty(bestReport), ...
        'run_stage2_b45_trim_jacobian_audit:NoSupportedPoint', ...
        'No physically supported M1 point exists for %s.',conditions(i).name);
    expectedBest = ms.summary.bestSupportedResidualNorm(i);
    assert(abs(bestReport.residualNorm-expectedBest) <= 1e-10*max(1,abs(expectedBest)), ...
        'run_stage2_b45_trim_jacobian_audit:MultistartSelectionDrift', ...
        'Selected point does not reproduce multistart summary for %s.',conditions(i).name);

    opts = struct('stepFraction',1e-2,'robustnessFractions',[5e-3 1e-2 2e-2], ...
        'lineSearchAlphas',[1 0.5 0.25 0.125 0.0625]);
    a = stage2_trim_definition_jacobian('M1_EVIDENCE_V1_PROPAGATION', ...
        conditions(i),bestReport.definition,bestReport.trimVariableVector,P,opts);
    audits{i} = a;

    s = empty_summary();
    s.caseName = conditions(i).name;
    s.mode = conditions(i).mode;
    s.bestMultistartSeedIndex = bestSeedIndex;
    s.baseResidualNormRaw = a.baseResidualNormRaw;
    s.baseResidualNormScaled = a.baseResidualNormScaled;
    s.baseResidual1 = a.baseResidual(1);
    s.baseResidual2 = a.baseResidual(2);
    s.baseResidual3 = a.baseResidual(3);
    s.z1 = a.baseZ(1); s.z2 = a.baseZ(2); s.z3 = a.baseZ(3);
    s.variable1 = a.unknownNames{1}; s.variable2 = a.unknownNames{2}; s.variable3 = a.unknownNames{3};
    s.rankScaled = a.jacobian.rankScaled;
    s.conditionScaled = a.jacobian.conditionScaled;
    s.s1Scaled = a.jacobian.singularValuesScaled(1);
    s.s2Scaled = a.jacobian.singularValuesScaled(2);
    s.s3Scaled = a.jacobian.singularValuesScaled(3);
    s.colNorm1Scaled = a.jacobian.columnNormsScaled(1);
    s.colNorm2Scaled = a.jacobian.columnNormsScaled(2);
    s.colNorm3Scaled = a.jacobian.columnNormsScaled(3);
    s.allNeighborsSupported = a.jacobian.allNeighborsSupported;
    s.dz1GaussNewton = a.gaussNewtonDeltaZ(1);
    s.dz2GaussNewton = a.gaussNewtonDeltaZ(2);
    s.dz3GaussNewton = a.gaussNewtonDeltaZ(3);
    s.linearPredictedResidualNormScaled = a.linearPredictedResidualNormScaled;
    s.alphaToFirstBound = a.alphaToFirstBound;
    s.fullGaussNewtonStepWithinBounds = a.fullGaussNewtonStepWithinBounds;
    s.bestSupportedLineSearchRawResidual = a.bestSupportedLineSearchRawResidual;
    s.bestSupportedLineSearchAlpha = a.lineSearch(a.bestSupportedLineSearchIndex).alpha;
    s.classification = a.classification;
    summaryRows(i) = s;

    for k = 1:numel(a.robustness)
        robustIdx = robustIdx+1;
        rr = empty_robustness_row();
        rr.caseName = conditions(i).name;
        rr.stepFraction = a.robustness(k).stepFraction;
        rr.allNeighborsSupported = a.robustness(k).allNeighborsSupported;
        rr.rankScaled = a.robustness(k).rankScaled;
        rr.conditionScaled = a.robustness(k).conditionScaled;
        rr.s1Scaled = a.robustness(k).s1Scaled;
        rr.s2Scaled = a.robustness(k).s2Scaled;
        rr.s3Scaled = a.robustness(k).s3Scaled;
        rr.relativeDifferenceFromBase = a.robustness(k).relativeDifferenceFromBase;
        robustnessRows(robustIdx) = rr;
    end
end

summary = struct2table(summaryRows);
robustness = struct2table(robustnessRows);
b45LineSearch = struct2table(audits{2}.lineSearch);
JrawB45 = array2table(audits{2}.jacobian.Jraw, ...
    'VariableNames',{'theta','collective','pitchCommand'}, ...
    'RowNames',{'udot','wdot','qdot'});
JscaledB45 = array2table(audits{2}.jacobian.Jscaled, ...
    'VariableNames',{'thetaScale','collectiveScale','pitchCommandScale'}, ...
    'RowNames',{'udotOverG','wdotOverG','qdot'});

writetable(summary,fullfile(outputRoot,'STAGE2_B45_JACOBIAN_SUMMARY.csv'));
writetable(robustness,fullfile(outputRoot,'STAGE2_B45_JACOBIAN_STEP_ROBUSTNESS.csv'));
writetable(b45LineSearch,fullfile(outputRoot,'STAGE2_B45_GAUSS_NEWTON_LINE_SEARCH.csv'));
writetable(JrawB45,fullfile(outputRoot,'STAGE2_B45_JACOBIAN_RAW.csv'),'WriteRowNames',true);
writetable(JscaledB45,fullfile(outputRoot,'STAGE2_B45_JACOBIAN_SCALED.csv'),'WriteRowNames',true);

results = struct();
results.summary = summary;
results.robustness = robustness;
results.b45LineSearch = b45LineSearch;
results.audits = audits;
results.multistart = ms;
results.modelIdentity = 'M1_EVIDENCE_V1_PROPAGATION';
results.claimBoundary = ...
    'LOCAL_TRIM_FEASIBILITY_DIAGNOSTIC_ONLY_NO_NEW_CONTROL_DOF_NO_MODEL_PARAMETER_CHANGE';
save(fullfile(outputRoot,'STAGE2_B45_TRIM_JACOBIAN_AUDIT.mat'),'results');

disp(summary);
disp(b45LineSearch);
end

function [bestReport,bestIdx] = select_best_supported(reportRow)
bestReport = []; bestIdx = NaN; bestResidual = Inf;
for j = 1:numel(reportRow)
    r = reportRow{j};
    if isstruct(r) && isfield(r,'physicalConverged') && ...
            r.physicalConverged && r.physicalBranchSupported && ...
            isfinite(r.residualNorm) && r.residualNorm < bestResidual
        bestResidual = r.residualNorm; bestReport = r; bestIdx = j;
    end
end
end

function s = empty_summary()
s = struct('caseName','','mode','','bestMultistartSeedIndex',NaN, ...
    'baseResidualNormRaw',NaN,'baseResidualNormScaled',NaN, ...
    'baseResidual1',NaN,'baseResidual2',NaN,'baseResidual3',NaN, ...
    'variable1','','variable2','','variable3','','z1',NaN,'z2',NaN,'z3',NaN, ...
    'rankScaled',NaN,'conditionScaled',NaN,'s1Scaled',NaN,'s2Scaled',NaN,'s3Scaled',NaN, ...
    'colNorm1Scaled',NaN,'colNorm2Scaled',NaN,'colNorm3Scaled',NaN, ...
    'allNeighborsSupported',false,'dz1GaussNewton',NaN,'dz2GaussNewton',NaN, ...
    'dz3GaussNewton',NaN,'linearPredictedResidualNormScaled',NaN, ...
    'alphaToFirstBound',NaN,'fullGaussNewtonStepWithinBounds',false, ...
    'bestSupportedLineSearchRawResidual',NaN,'bestSupportedLineSearchAlpha',NaN, ...
    'classification','NOT_RUN');
end

function r = empty_robustness_row()
r = struct('caseName','','stepFraction',NaN,'allNeighborsSupported',false, ...
    'rankScaled',NaN,'conditionScaled',NaN,'s1Scaled',NaN,'s2Scaled',NaN, ...
    's3Scaled',NaN,'relativeDifferenceFromBase',NaN);
end
