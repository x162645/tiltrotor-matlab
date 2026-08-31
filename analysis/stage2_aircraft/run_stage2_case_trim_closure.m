function results = run_stage2_case_trim_closure(caseName,outputRoot)
%RUN_STAGE2_CASE_TRIM_CLOSURE Per-case execution of the frozen Stage-2 seed contract.
%
% Computational decomposition only: this uses the exact same nine predeclared
% seeds as run_stage2_m1_trim_multistart_diagnostic and the same generic
% branch-aware continuation engine. Splitting B15/B75 into separate CI jobs
% changes wall-clock organization only, not physics, solver settings, bounds,
% DOFs, seeds, continuation controls, or credibility gates.

if nargin<1 || isempty(caseName), error('run_stage2_case_trim_closure:CaseRequired','caseName required'); end
if nargin<2 || isempty(outputRoot), outputRoot=fullfile(pwd,'results',['stage2_' lower(caseName) '_trim_closure']); end
if ~exist(outputRoot,'dir'), mkdir(outputRoot); end
P=stage2_matched_rotor_parameters(); d2r=pi/180;
switch char(caseName)
    case 'B15_V020'
        condition=struct('name','B15_V020','V',20,'betaM',15*d2r,'gamma',0,'mode','helicopter_longitudinal');
    case 'B75_V080'
        condition=struct('name','B75_V080','V',80,'betaM',75*d2r,'gamma',0,'mode','airplane_longitudinal');
    otherwise
        error('run_stage2_case_trim_closure:UnsupportedCase','Only B15_V020 and B75_V080 are active in this phase.');
end

[~,~,r0]=stage2_trim_longitudinal('M0_MATCHED_PRODUCTION',condition,P,struct('mode',condition.mode));
assert(r0.credible,'run_stage2_case_trim_closure:M0NotCredible');
definition=r0.definition; canonical=definition.initialValues(:); m0seed=r0.trimVariableVector(:); scale=definition.variableScale(:);
assert(numel(canonical)==3,'run_stage2_case_trim_closure:UnexpectedTrimDimension');
seeds=NaN(3,9); labels=cell(1,9);
seeds(:,1)=canonical; labels{1}='CANONICAL';
seeds(:,2)=m0seed; labels{2}='M0_TRIM';
seeds(:,3)=.5*(canonical+m0seed); labels{3}='CANONICAL_M0_MIDPOINT';
col=3;
for k=1:3
    col=col+1; seeds(:,col)=m0seed; seeds(k,col)=seeds(k,col)+.5*scale(k); labels{col}=sprintf('M0_PLUS_HALF_SCALE_%s',upper(definition.unknownNames{k}));
    col=col+1; seeds(:,col)=m0seed; seeds(k,col)=seeds(k,col)-.5*scale(k); labels{col}=sprintf('M0_MINUS_HALF_SCALE_%s',upper(definition.unknownNames{k}));
end
for j=1:9, seeds(:,j)=min(max(seeds(:,j),definition.bounds(:,1)),definition.bounds(:,2)); end

seedRows=repmat(empty_seed_row(),9,1); reports=cell(1,9); bestReport=[]; bestResidual=Inf; bestSeed=''; credibleReport=[]; credibleSeed='';
for j=1:9
    row=empty_seed_row(); row.caseName=condition.name; row.seedLabel=labels{j}; row.seed1=seeds(1,j); row.seed2=seeds(2,j); row.seed3=seeds(3,j);
    try
        [x,u,r]=stage2_trim_longitudinal('M1_EVIDENCE_V1_PROPAGATION',condition,P,struct('mode',condition.mode,'initialValues',seeds(:,j)));
        reports{j}=r; row.solveReturned=true; row.solverConverged=logical(r.solverConverged); row.physicalConverged=logical(r.physicalConverged);
        row.physicalBranchSupported=logical(r.physicalBranchSupported); row.credible=logical(r.credible); row.residualNorm=r.residualNorm;
        row.physicalStatus=r.physicalStatus; row.atLimit=logical(r.atLimit); row.theta_deg=x(8)/d2r; row.collective_deg=u(1)/d2r; row.cyclicLong_deg=u(3)/d2r; row.elevator_deg=u(6)/d2r;
        if r.credible && isempty(credibleReport), credibleReport=r; credibleSeed=labels{j}; end
        if r.point.finiteReal && r.physicalConverged && r.physicalBranchSupported && isfinite(r.residualNorm) && r.residualNorm<bestResidual
            bestReport=r; bestResidual=r.residualNorm; bestSeed=labels{j};
        end
    catch ME
        if startsWith(ME.identifier,'m1_evidence_v1_forward_rotor:') || startsWith(ME.identifier,'rotor_model_bemt:') || strcmp(ME.identifier,'pitch_allocation_schedule:InvalidPitchCommand')
            row.physicalStatus=['MODEL_DOMAIN_ERROR:' ME.identifier]; reports{j}=ME;
        else
            rethrow(ME);
        end
    end
    seedRows(j)=row;
end
seedTable=struct2table(seedRows); writetable(seedTable,fullfile(outputRoot,[condition.name '_SEED_AUDIT.csv']));

summary=empty_summary(); summary.caseName=condition.name; summary.mode=condition.mode; summary.supportedSeedCount=sum(seedTable.physicalConverged & seedTable.physicalBranchSupported);
summary.credibleSeedCount=sum(seedTable.credible); summary.bestSupportedSeed=bestSeed; if isfinite(bestResidual), summary.bestSupportedResidualNorm=bestResidual; end

if ~isempty(credibleReport)
    finalPoint=credibleReport.point; summary.selectedSeed=credibleSeed; summary.seedResidualNorm=credibleReport.residualNorm; summary.continuationAttempted=false;
    summary.finalResidualNorm=credibleReport.residualNorm; summary.physicalConverged=credibleReport.physicalConverged; summary.physicalBranchSupported=credibleReport.physicalBranchSupported;
    summary.atLimit=credibleReport.atLimit; summary.minimumBoundMargin=min_bound_margin(credibleReport.trimVariableVector,credibleReport.definition.bounds);
    summary.credible=true; summary.classification='CREDIBLE_IN_PREDECLARED_MULTISTART'; closure=struct('finalPoint',finalPoint,'finalZ',credibleReport.trimVariableVector,'sourceReport',credibleReport);
elseif isempty(bestReport)
    summary.continuationAttempted=false; summary.credible=false; summary.classification='NO_SUPPORTED_MULTISTART_SEED_CONTINUATION_NOT_STARTED'; closure=struct();
else
    summary.selectedSeed=bestSeed; summary.seedResidualNorm=bestResidual; summary.continuationAttempted=true;
    c=stage2_branch_aware_trim_continuation(condition,condition.mode,bestReport,P,fullfile(outputRoot,'continuation')); closure=c; s=c.summary;
    summary.finalResidualNorm=s.finalResidualNorm(1); summary.physicalConverged=s.physicalConverged(1); summary.physicalBranchSupported=s.physicalBranchSupported(1);
    summary.atLimit=s.atLimit(1); summary.minimumBoundMargin=s.minimumBoundMargin(1); summary.credible=s.credible(1); summary.outerIterations=s.iterations(1); summary.stopReason=s.stopReason{1};
    if summary.credible, summary.classification='CREDIBLE_AFTER_GENERIC_BRANCH_AWARE_CONTINUATION'; else, summary.classification='GENERIC_BRANCH_AWARE_CONTINUATION_NOT_CREDIBLE'; end
end
if summary.credible
    if isfield(closure,'finalPoint'), fp=closure.finalPoint; else, fp=finalPoint; end
    summary.theta_deg=fp.x9(8)/d2r; summary.collective_deg=fp.u7(1)/d2r; summary.cyclicLong_deg=fp.u7(3)/d2r; summary.elevator_deg=fp.u7(6)/d2r;
end
summaryTable=struct2table(summary); writetable(summaryTable,fullfile(outputRoot,[condition.name '_TRIM_CLOSURE_SUMMARY.csv']));
results=struct('condition',condition,'seedTable',seedTable,'reports',{reports},'summary',summaryTable,'closure',closure, ...
    'seedContract','CANONICAL__M0__MIDPOINT__M0_PLUS_MINUS_HALF_EXISTING_SCALE_PER_VARIABLE', ...
    'claimBoundary','COMPUTATIONAL_DECOMPOSITION_ONLY_SHARED_STAGE2_METHOD_NO_PHYSICS_PARAMETER_TOLERANCE_BOUND_DOF_OR_PRODUCTION_ITERATION_CHANGE');
save(fullfile(outputRoot,[condition.name '_TRIM_CLOSURE.mat']),'results'); disp(summaryTable);
end

function m=min_bound_margin(z,bounds)
span=bounds(:,2)-bounds(:,1); m=min(min(z(:)-bounds(:,1),bounds(:,2)-z(:))./span);
end
function r=empty_seed_row()
r=struct('caseName','','seedLabel','','seed1',NaN,'seed2',NaN,'seed3',NaN,'solveReturned',false,'solverConverged',false,'physicalConverged',false,'physicalBranchSupported',false,'credible',false,'residualNorm',NaN,'physicalStatus','NOT_RUN','atLimit',false,'theta_deg',NaN,'collective_deg',NaN,'cyclicLong_deg',NaN,'elevator_deg',NaN);
end
function r=empty_summary()
r=struct('caseName','','mode','','supportedSeedCount',0,'credibleSeedCount',0,'bestSupportedSeed','','bestSupportedResidualNorm',NaN,'selectedSeed','','seedResidualNorm',NaN,'continuationAttempted',false,'finalResidualNorm',NaN,'physicalConverged',false,'physicalBranchSupported',false,'atLimit',false,'minimumBoundMargin',NaN,'credible',false,'outerIterations',0,'stopReason','','theta_deg',NaN,'collective_deg',NaN,'cyclicLong_deg',NaN,'elevator_deg',NaN,'classification','NOT_RUN');
end
