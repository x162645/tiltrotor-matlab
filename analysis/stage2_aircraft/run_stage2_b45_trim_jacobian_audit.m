function results = run_stage2_b45_trim_jacobian_audit(outputRoot)
%RUN_STAGE2_B45_TRIM_JACOBIAN_AUDIT Diagnose the isolated B45 M1 trim failure.
% The base point is the lowest-raw-residual physically supported B45 result
% from deterministic multistart workflow run 33300606420, artifact
% stage2-m1-trim-multistart-diagnostic. The current model must reproduce that
% checkpoint fail-closed before derivatives are accepted. No multistart is
% rerun here; no new control DOF or physical-model change is introduced.

if nargin < 1 || isempty(outputRoot)
    outputRoot = fullfile(pwd,'results','stage2_b45_trim_jacobian_audit');
end
if ~exist(outputRoot,'dir'), mkdir(outputRoot); end

P = stage2_matched_rotor_parameters();
d2r = pi/180;
condition = struct('name','B45_V035','V',35,'betaM',45*d2r,'gamma',0, ...
    'mode','conversion_longitudinal');
definition = make_trim_definition(condition.mode,condition,P);

% Frozen evidence checkpoint from run 33300606420 / seed
% M0_MINUS_HALF_SCALE_THETA. These are solver outputs, not tuned parameters.
zCheckpoint = [0.36961115687162627; 0.6097990356720934; 1.647599943976152];
expectedResidual = [-0.11445984591707202; -0.416173243818573; 0.07587035495863398];
expectedResidualNorm = 0.43824369471720004;
checkpoint = stage2_evaluate_trim_point('M1_EVIDENCE_V1_PROPAGATION', ...
    condition,definition,zCheckpoint,P);
assert(checkpoint.physicalConverged && checkpoint.physicalBranchSupported, ...
    'run_stage2_b45_trim_jacobian_audit:CheckpointPhysicalDrift', ...
    'Frozen B45 checkpoint no longer lies on the supported M1 physical branch.');
assert(norm(checkpoint.residual-expectedResidual) <= 1e-9 && ...
    abs(norm(checkpoint.residual)-expectedResidualNorm) <= 1e-9, ...
    'run_stage2_b45_trim_jacobian_audit:CheckpointResidualDrift', ...
    'Frozen B45 multistart checkpoint no longer reproduces run 33300606420.');

opts = struct('stepFraction',1e-2,'robustnessFractions',[5e-3 1e-2 2e-2], ...
    'lineSearchAlphas',[1 0.5 0.25 0.125 0.0625]);
a = stage2_trim_definition_jacobian('M1_EVIDENCE_V1_PROPAGATION', ...
    condition,definition,zCheckpoint,P,opts);

s = empty_summary();
s.caseName = condition.name;
s.mode = condition.mode;
s.sourceWorkflowRun = 33300606420;
s.sourceSeed = 'M0_MINUS_HALF_SCALE_THETA';
s.baseResidualNormRaw = a.baseResidualNormRaw;
s.baseResidualNormScaled = a.baseResidualNormScaled;
s.baseResidual1 = a.baseResidual(1); s.baseResidual2 = a.baseResidual(2); s.baseResidual3 = a.baseResidual(3);
s.variable1 = a.unknownNames{1}; s.variable2 = a.unknownNames{2}; s.variable3 = a.unknownNames{3};
s.z1 = a.baseZ(1); s.z2 = a.baseZ(2); s.z3 = a.baseZ(3);
s.rankScaled = a.jacobian.rankScaled; s.conditionScaled = a.jacobian.conditionScaled;
s.s1Scaled = a.jacobian.singularValuesScaled(1); s.s2Scaled = a.jacobian.singularValuesScaled(2); s.s3Scaled = a.jacobian.singularValuesScaled(3);
s.colNorm1Scaled = a.jacobian.columnNormsScaled(1); s.colNorm2Scaled = a.jacobian.columnNormsScaled(2); s.colNorm3Scaled = a.jacobian.columnNormsScaled(3);
s.allNeighborsSupported = a.jacobian.allNeighborsSupported;
s.dz1GaussNewton = a.gaussNewtonDeltaZ(1); s.dz2GaussNewton = a.gaussNewtonDeltaZ(2); s.dz3GaussNewton = a.gaussNewtonDeltaZ(3);
s.linearPredictedResidualNormScaled = a.linearPredictedResidualNormScaled;
s.alphaToFirstBound = a.alphaToFirstBound;
s.fullGaussNewtonStepWithinBounds = a.fullGaussNewtonStepWithinBounds;
s.bestSupportedLineSearchRawResidual = a.bestSupportedLineSearchRawResidual;
s.bestSupportedLineSearchAlpha = a.lineSearch(a.bestSupportedLineSearchIndex).alpha;
s.classification = a.classification;
summary = struct2table(s);

robustnessRows = repmat(empty_robustness_row(),numel(a.robustness),1);
for k = 1:numel(a.robustness)
    rr = empty_robustness_row(); rr.caseName = condition.name;
    rr.stepFraction = a.robustness(k).stepFraction;
    rr.allNeighborsSupported = a.robustness(k).allNeighborsSupported;
    rr.rankScaled = a.robustness(k).rankScaled;
    rr.conditionScaled = a.robustness(k).conditionScaled;
    rr.s1Scaled = a.robustness(k).s1Scaled; rr.s2Scaled = a.robustness(k).s2Scaled; rr.s3Scaled = a.robustness(k).s3Scaled;
    rr.relativeDifferenceFromBase = a.robustness(k).relativeDifferenceFromBase;
    robustnessRows(k) = rr;
end
robustness = struct2table(robustnessRows);
b45LineSearch = struct2table(a.lineSearch);
JrawB45 = array2table(a.jacobian.Jraw, ...
    'VariableNames',{'theta','collective','pitchCommand'}, ...
    'RowNames',{'udot','wdot','qdot'});
JscaledB45 = array2table(a.jacobian.Jscaled, ...
    'VariableNames',{'thetaScale','collectiveScale','pitchCommandScale'}, ...
    'RowNames',{'udotOverG','wdotOverG','qdot'});

writetable(summary,fullfile(outputRoot,'STAGE2_B45_JACOBIAN_SUMMARY.csv'));
writetable(robustness,fullfile(outputRoot,'STAGE2_B45_JACOBIAN_STEP_ROBUSTNESS.csv'));
writetable(b45LineSearch,fullfile(outputRoot,'STAGE2_B45_GAUSS_NEWTON_LINE_SEARCH.csv'));
writetable(JrawB45,fullfile(outputRoot,'STAGE2_B45_JACOBIAN_RAW.csv'),'WriteRowNames',true);
writetable(JscaledB45,fullfile(outputRoot,'STAGE2_B45_JACOBIAN_SCALED.csv'),'WriteRowNames',true);

results = struct(); results.summary = summary; results.robustness = robustness;
results.b45LineSearch = b45LineSearch; results.audit = a;
results.sourceWorkflowRun = 33300606420;
results.sourceArtifact = 'stage2-m1-trim-multistart-diagnostic';
results.modelIdentity = 'M1_EVIDENCE_V1_PROPAGATION';
results.claimBoundary = ...
    'LOCAL_TRIM_FEASIBILITY_DIAGNOSTIC_ONLY_NO_NEW_CONTROL_DOF_NO_MODEL_PARAMETER_CHANGE';
save(fullfile(outputRoot,'STAGE2_B45_TRIM_JACOBIAN_AUDIT.mat'),'results');

disp(summary); disp(b45LineSearch);
end

function s = empty_summary()
s = struct('caseName','','mode','','sourceWorkflowRun',NaN,'sourceSeed','', ...
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
