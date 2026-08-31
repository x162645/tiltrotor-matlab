function results = run_stage2_b45_branch_tracked_trim_audit(outputRoot)
%RUN_STAGE2_B45_BRANCH_TRACKED_TRIM_AUDIT Re-evaluate B45 local feasibility.
% The frozen B45 checkpoint is used as a deterministic continuation anchor.
% Only converged left/right flap states are reused as nonlinear-solver initial
% guesses. Equations, physical parameters, tolerances, bounds and trim DOFs
% remain unchanged.

if nargin < 1 || isempty(outputRoot)
    outputRoot=fullfile(pwd,'results','stage2_b45_branch_tracked_trim_audit');
end
if ~exist(outputRoot,'dir'), mkdir(outputRoot); end

P=stage2_matched_rotor_parameters(); d2r=pi/180;
condition=struct('name','B45_V035','V',35,'betaM',45*d2r,'gamma',0, ...
    'mode','conversion_longitudinal');
definition=make_trim_definition(condition.mode,condition,P);
zAnchor=[0.36961115687162627;0.6097990356720934;1.647599943976152];
expectedResidual=[-0.11445984591707202;-0.416173243818573;0.07587035495863398];
anchor=stage2_evaluate_trim_point('M1_EVIDENCE_V1_PROPAGATION',condition,definition,zAnchor,P);
assert(anchor.physicalConverged && anchor.physicalBranchSupported && ...
    norm(anchor.residual-expectedResidual)<=1e-9, ...
    'run_stage2_b45_branch_tracked_trim_audit:AnchorDrift', ...
    'Frozen B45 checkpoint no longer reproduces prior evidence.');

contOpts=struct('anchorZ',zAnchor,'maxStepFraction',2.5e-4);
pointEvaluator=@(mi,c,d,z,p) stage2_evaluate_trim_point_continuation(mi,c,d,z,p,contOpts);
jacOpts=struct('stepFraction',1e-3,'robustnessFractions',[5e-4 1e-3 2.5e-3], ...
    'lineSearchAlphas',[1 0.5 0.25 0.125 0.0625 0.03125],'pointEvaluator',pointEvaluator);

initialAudit=stage2_trim_definition_jacobian('M1_EVIDENCE_V1_PROPAGATION', ...
    condition,definition,zAnchor,P,jacOpts);

maxNewtonIter=12;
rows=repmat(empty_iter(),maxNewtonIter,1);
z=zAnchor; nDone=0; stopReason='MAX_ITER';
for iter=1:maxNewtonIter
    a=stage2_trim_definition_jacobian('M1_EVIDENCE_V1_PROPAGATION', ...
        condition,definition,z,P,jacOpts);
    nDone=iter; r=empty_iter();
    r.iteration=iter; r.z1=z(1); r.z2=z(2); r.z3=z(3);
    r.residualNormRaw=a.baseResidualNormRaw; r.residualNormScaled=a.baseResidualNormScaled;
    r.rankScaled=a.jacobian.rankScaled; r.conditionScaled=a.jacobian.conditionScaled;
    r.s1=a.jacobian.singularValuesScaled(1); r.s2=a.jacobian.singularValuesScaled(2); r.s3=a.jacobian.singularValuesScaled(3);
    r.allNeighborsSupported=a.jacobian.allNeighborsSupported;
    r.bestLineResidual=a.bestSupportedLineSearchRawResidual;
    r.bestLineAlpha=a.lineSearch(a.bestSupportedLineSearchIndex).alpha;
    r.classification=a.classification;
    rows(iter)=r;

    if a.baseResidualNormRaw < P.trim.residualTolerance
        stopReason='RESIDUAL_TOLERANCE_REACHED'; break;
    end
    if ~(a.jacobian.finite && a.jacobian.allNeighborsSupported && a.jacobian.rankScaled==3)
        stopReason='JACOBIAN_NOT_FULLY_SUPPORTED_FULL_RANK'; break;
    end
    idx=a.bestSupportedLineSearchIndex;
    if ~isfinite(a.bestSupportedLineSearchRawResidual) || ...
            a.bestSupportedLineSearchRawResidual >= a.baseResidualNormRaw*(1-1e-8) || ...
            a.lineSearch(idx).alpha<=0
        stopReason='NO_RESIDUAL_DECREASING_GAUSS_NEWTON_STEP'; break;
    end
    z=[a.lineSearch(idx).z1;a.lineSearch(idx).z2;a.lineSearch(idx).z3];
end
iterations=struct2table(rows(1:nDone));
finalPoint=pointEvaluator('M1_EVIDENCE_V1_PROPAGATION',condition,definition,z,P);
span=definition.bounds(:,2)-definition.bounds(:,1);
margin=min(z-definition.bounds(:,1),definition.bounds(:,2)-z)./span;
atLimit=any(margin<=1e-8);
credible=finalPoint.finiteReal && finalPoint.physicalConverged && finalPoint.physicalBranchSupported && ...
    norm(finalPoint.residual)<P.trim.residualTolerance && ~atLimit;

s=struct();
s.caseName=condition.name; s.anchorResidualNorm=norm(anchor.residual);
s.initialAllNeighborsSupported=initialAudit.jacobian.allNeighborsSupported;
s.initialRankScaled=initialAudit.jacobian.rankScaled;
s.initialConditionScaled=initialAudit.jacobian.conditionScaled;
s.initialS1=initialAudit.jacobian.singularValuesScaled(1);
s.initialS2=initialAudit.jacobian.singularValuesScaled(2);
s.initialS3=initialAudit.jacobian.singularValuesScaled(3);
s.initialBestLineResidual=initialAudit.bestSupportedLineSearchRawResidual;
s.initialBestLineAlpha=initialAudit.lineSearch(initialAudit.bestSupportedLineSearchIndex).alpha;
s.finalZ1=z(1); s.finalZ2=z(2); s.finalZ3=z(3);
s.finalResidual1=finalPoint.residual(1); s.finalResidual2=finalPoint.residual(2); s.finalResidual3=finalPoint.residual(3);
s.finalResidualNorm=norm(finalPoint.residual); s.trimResidualTolerance=P.trim.residualTolerance;
s.finalPhysicalConverged=finalPoint.physicalConverged;
s.finalPhysicalBranchSupported=finalPoint.physicalBranchSupported;
s.atLimit=atLimit; s.credible=credible; s.iterations=nDone; s.stopReason=stopReason;
summary=struct2table(s);

robRows=repmat(struct('stepFraction',NaN,'allNeighborsSupported',false,'rankScaled',NaN, ...
    'conditionScaled',NaN,'s1',NaN,'s2',NaN,'s3',NaN,'relativeDifferenceFromBase',NaN), ...
    numel(initialAudit.robustness),1);
for k=1:numel(initialAudit.robustness)
    robRows(k).stepFraction=initialAudit.robustness(k).stepFraction;
    robRows(k).allNeighborsSupported=initialAudit.robustness(k).allNeighborsSupported;
    robRows(k).rankScaled=initialAudit.robustness(k).rankScaled;
    robRows(k).conditionScaled=initialAudit.robustness(k).conditionScaled;
    robRows(k).s1=initialAudit.robustness(k).s1Scaled;
    robRows(k).s2=initialAudit.robustness(k).s2Scaled;
    robRows(k).s3=initialAudit.robustness(k).s3Scaled;
    robRows(k).relativeDifferenceFromBase=initialAudit.robustness(k).relativeDifferenceFromBase;
end
robustness=struct2table(robRows);
Jscaled=array2table(initialAudit.jacobian.Jscaled, ...
    'VariableNames',{'thetaScale','collectiveScale','pitchCommandScale'}, ...
    'RowNames',{'udotOverG','wdotOverG','qdot'});
initialLineSearch=struct2table(initialAudit.lineSearch);

writetable(summary,fullfile(outputRoot,'STAGE2_B45_BRANCH_TRACKED_TRIM_SUMMARY.csv'));
writetable(iterations,fullfile(outputRoot,'STAGE2_B45_BRANCH_TRACKED_TRIM_ITERATIONS.csv'));
writetable(robustness,fullfile(outputRoot,'STAGE2_B45_BRANCH_TRACKED_JACOBIAN_ROBUSTNESS.csv'));
writetable(Jscaled,fullfile(outputRoot,'STAGE2_B45_BRANCH_TRACKED_JACOBIAN_SCALED.csv'),'WriteRowNames',true);
writetable(initialLineSearch,fullfile(outputRoot,'STAGE2_B45_BRANCH_TRACKED_INITIAL_LINE_SEARCH.csv'));
results=struct('summary',summary,'iterations',iterations,'robustness',robustness, ...
    'initialAudit',initialAudit,'finalPoint',finalPoint,'anchorZ',zAnchor, ...
    'claimBoundary','DETERMINISTIC_FLAP_INITIAL_STATE_CONTINUATION_ONLY_NO_PHYSICS_PARAMETER_TOLERANCE_OR_TRIM_DOF_CHANGE');
save(fullfile(outputRoot,'STAGE2_B45_BRANCH_TRACKED_TRIM_AUDIT.mat'),'results');

disp(summary); disp(robustness); disp(iterations);
fprintf(['B45_BRANCH_TRACKED|neighbors=%d|rank=%d|cond=%.9e|s=[%.9e %.9e %.9e]|' ...
    'initial_res=%.9e|initial_best=%.9e|final_res=%.9e|tol=%.9e|credible=%d|stop=%s\n'], ...
    initialAudit.jacobian.allNeighborsSupported,initialAudit.jacobian.rankScaled, ...
    initialAudit.jacobian.conditionScaled,initialAudit.jacobian.singularValuesScaled(1), ...
    initialAudit.jacobian.singularValuesScaled(2),initialAudit.jacobian.singularValuesScaled(3), ...
    norm(anchor.residual),initialAudit.bestSupportedLineSearchRawResidual,norm(finalPoint.residual), ...
    P.trim.residualTolerance,credible,stopReason);
end

function r=empty_iter()
r=struct('iteration',NaN,'z1',NaN,'z2',NaN,'z3',NaN,'residualNormRaw',NaN, ...
    'residualNormScaled',NaN,'rankScaled',NaN,'conditionScaled',NaN,'s1',NaN,'s2',NaN,'s3',NaN, ...
    'allNeighborsSupported',false,'bestLineResidual',NaN,'bestLineAlpha',NaN,'classification','');
end
