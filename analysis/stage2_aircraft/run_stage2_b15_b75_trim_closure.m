function results = run_stage2_b15_b75_trim_closure(outputRoot)
%RUN_STAGE2_B15_B75_TRIM_CLOSURE Resume Stage-2 mainline after B45 phase exit.
%
% The same predeclared nine-seed multistart diagnostic is first used only to
% locate an already physically supported M1 point. If a credible trim already
% exists, it is accepted. Otherwise the supported point with the smallest trim
% residual is used as the numerical starting point for the SAME generic
% branch-aware continuation engine for both B15 and B75.
%
% No case-specific physical model change, parameter change, tolerance change,
% production/flap iteration-limit change, trim/control-bound change, or DOF
% change is permitted.

if nargin<1 || isempty(outputRoot)
    outputRoot=fullfile(pwd,'results','stage2_b15_b75_trim_closure');
end
if ~exist(outputRoot,'dir'), mkdir(outputRoot); end
P=stage2_matched_rotor_parameters(); d2r=pi/180;

multistartDir=fullfile(outputRoot,'multistart');
ms=run_stage2_m1_trim_multistart_diagnostic(multistartDir);

conditions(1)=struct('name','B15_V020','V',20,'betaM',15*d2r,'gamma',0,'mode','helicopter_longitudinal');
conditions(2)=struct('name','B75_V080','V',80,'betaM',75*d2r,'gamma',0,'mode','airplane_longitudinal');
msCaseIndex=[1 3];
closureResults=cell(2,1); summaryRows=repmat(empty_summary(),2,1);

% B75 first is intentional only as execution order: its stale primary result
% was already physically converged/branch supported and residual-limited. The
% algorithm and gates are identical for B15.
executionOrder=[2 1];
for orderIndex=1:numel(executionOrder)
    k=executionOrder(orderIndex); condition=conditions(k); i=msCaseIndex(k);
    row=empty_summary(); row.caseName=condition.name; row.mode=condition.mode;
    row.multistartSupportedCount=ms.summary.supportedPhysicalCount(i);
    row.multistartCredibleCount=ms.summary.credibleCount(i);
    row.multistartBestSupportedResidual=ms.summary.bestSupportedResidualNorm(i);
    row.multistartClassification=ms.summary.classification{i};

    bestReport=[]; bestResidual=Inf; bestSeed=''; credibleReport=[]; credibleSeed='';
    for j=1:9
        r=ms.reports{i,j};
        if ~isstruct(r) || ~isfield(r,'point'), continue; end
        if r.credible && isempty(credibleReport)
            credibleReport=r; credibleSeed=ms.points.seedLabel{(i-1)*9+j};
        end
        if r.point.finiteReal && r.physicalConverged && r.physicalBranchSupported && ...
                isfinite(r.residualNorm) && r.residualNorm<bestResidual
            bestReport=r; bestResidual=r.residualNorm; bestSeed=ms.points.seedLabel{(i-1)*9+j};
        end
    end

    if ~isempty(credibleReport)
        finalReport=credibleReport; finalPoint=credibleReport.point;
        row.seedLabel=credibleSeed; row.seedResidualNorm=credibleReport.residualNorm;
        row.continuationAttempted=false; row.finalResidualNorm=credibleReport.residualNorm;
        row.physicalConverged=credibleReport.physicalConverged;
        row.physicalBranchSupported=credibleReport.physicalBranchSupported;
        row.atLimit=credibleReport.atLimit; row.credible=true;
        row.theta_deg=finalPoint.x9(8)/d2r; row.collective_deg=finalPoint.u7(1)/d2r;
        row.cyclicLong_deg=finalPoint.u7(3)/d2r; row.elevator_deg=finalPoint.u7(6)/d2r;
        row.classification='CREDIBLE_IN_PREDECLARED_MULTISTART';
        closureResults{k}=struct('finalPoint',finalPoint,'finalZ',credibleReport.trimVariableVector, ...
            'sourceReport',finalReport,'classification',row.classification);
    elseif isempty(bestReport)
        row.continuationAttempted=false; row.credible=false;
        row.classification='NO_SUPPORTED_MULTISTART_SEED_CONTINUATION_NOT_STARTED';
        closureResults{k}=struct('classification',row.classification);
    else
        row.seedLabel=bestSeed; row.seedResidualNorm=bestResidual; row.continuationAttempted=true;
        caseDir=fullfile(outputRoot,condition.name);
        c=stage2_branch_aware_trim_continuation(condition,condition.mode,bestReport,P,caseDir);
        closureResults{k}=c; s=c.summary;
        row.finalResidualNorm=s.finalResidualNorm(1); row.physicalConverged=s.physicalConverged(1);
        row.physicalBranchSupported=s.physicalBranchSupported(1); row.atLimit=s.atLimit(1);
        row.minimumBoundMargin=s.minimumBoundMargin(1); row.credible=s.credible(1);
        row.outerIterations=s.iterations(1); row.stopReason=s.stopReason{1};
        row.theta_deg=s.theta_deg(1); row.collective_deg=s.collective_deg(1);
        row.cyclicLong_deg=s.cyclicLong_deg(1); row.elevator_deg=s.elevator_deg(1);
        if row.credible
            row.classification='CREDIBLE_AFTER_GENERIC_BRANCH_AWARE_CONTINUATION';
        else
            row.classification='GENERIC_BRANCH_AWARE_CONTINUATION_NOT_CREDIBLE';
        end
    end
    summaryRows(k)=row;
end

summary=struct2table(summaryRows);
writetable(summary,fullfile(outputRoot,'STAGE2_B15_B75_TRIM_CLOSURE_SUMMARY.csv'));
results=struct('summary',summary,'multistart',ms,'closures',{closureResults}, ...
    'executionOrder','B75_THEN_B15_SAME_ALGORITHM', ...
    'claimBoundary','STAGE2_NUMERICAL_TRIM_CLOSURE_ONLY_NO_MODEL_PARAMETER_TOLERANCE_BOUND_DOF_OR_PRODUCTION_ITERATION_CHANGE');
save(fullfile(outputRoot,'STAGE2_B15_B75_TRIM_CLOSURE.mat'),'results');
disp(summary);
end

function r=empty_summary()
r=struct('caseName','','mode','','multistartSupportedCount',0,'multistartCredibleCount',0, ...
    'multistartBestSupportedResidual',NaN,'multistartClassification','', ...
    'seedLabel','','seedResidualNorm',NaN,'continuationAttempted',false, ...
    'finalResidualNorm',NaN,'physicalConverged',false,'physicalBranchSupported',false, ...
    'atLimit',false,'minimumBoundMargin',NaN,'credible',false,'outerIterations',0, ...
    'stopReason','','theta_deg',NaN,'collective_deg',NaN,'cyclicLong_deg',NaN, ...
    'elevator_deg',NaN,'classification','NOT_RUN');
end
