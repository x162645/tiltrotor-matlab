function results = stage2_branch_aware_trim_continuation(condition,mode,seedReport,P,outputRoot)
%STAGE2_BRANCH_AWARE_TRIM_CONTINUATION Generic Stage-2 numerical trim closure.
%
% This routine generalizes the B45-proven adaptive-path method to any of the
% existing three-variable explicit Stage-2 trim definitions. It changes only
% the numerical path used to reach trial trim coordinates. Model equations,
% physical/model parameters, production trim tolerance, production/flap
% iteration limits, trim/control bounds, and trim/control DOFs are unchanged.
%
% A seed is admissible only when its returned M1 point is finite/real,
% physically converged, and on a supported physical branch. Subsequent trial
% points are reached by adaptive path continuation while carrying ONLY the
% converged left/right flap states from the last accepted point.

if nargin<5 || isempty(outputRoot)
    outputRoot=fullfile(pwd,'results','stage2_branch_aware_trim_continuation');
end
if ~exist(outputRoot,'dir'), mkdir(outputRoot); end
if nargin<4 || isempty(P), P=stage2_matched_rotor_parameters(); end
assert(isstruct(seedReport) && isfield(seedReport,'point') && isfield(seedReport,'trimVariableVector'), ...
    'stage2_branch_aware_trim_continuation:BadSeedReport');

modelIdentity='M1_EVIDENCE_V1_PROPAGATION';
d=seedReport.definition;
if ~strcmp(char(seedReport.mode),char(mode))
    error('stage2_branch_aware_trim_continuation:SeedModeMismatch','Seed mode does not match requested mode.');
end
z=seedReport.trimVariableVector(:); p=seedReport.point;
assert(numel(z)==3 && numel(p.residual)==3, ...
    'stage2_branch_aware_trim_continuation:UnexpectedTrimDimension', ...
    'Current Stage-2 explicit-mode contract requires three trim variables/residuals.');
assert(p.finiteReal && p.physicalConverged && p.physicalBranchSupported, ...
    'stage2_branch_aware_trim_continuation:UnsupportedSeed', ...
    'Seed must already be finite, physically converged, and branch supported.');

sc=d.variableScale(:);
rscl=ones(numel(d.residualNames),1);
for i=1:numel(d.residualNames)
    if any(strcmp(d.residualNames{i},{'udot','vdot','wdot'})), rscl(i)=P.env.g; end
end

% Numerical-path controls are frozen for all Stage-2 cases and match the
% successful B45 branch-tracking scale. They do not alter P.trim or rotor
% solver tolerances/iteration limits.
fdFractions=[7.5e-5 5e-5 2.5e-5 1e-5 5e-6 2.5e-6 1e-6];
fdIdx=1;
trust=2e-2; trustMin=1.25e-4; trustMax=1.6e-1;
maxOuterIterations=40; minPathDt=2^-14; maxPathAttempts=80;
alphaSet=[1 .5 .25 .125 .0625];

rows=repmat(emptyrow(),maxOuterIterations,1); nrow=0; stopReason='MAX_OUTER_ITERATIONS';
totalModelEvaluations=0; startResidualNorm=norm(p.residual);

for it=1:maxOuterIterations
    nrow=it; raw0=norm(p.residual); phi0=objective(p); rr=p.residual(:)./rscl;
    row=emptyrow(); row.iteration=it; row.z1=z(1); row.z2=z(2); row.z3=z(3);
    row.residualNormRaw=raw0; row.objectiveScaled=phi0; row.trustRadius=trust;

    if raw0<P.trim.residualTolerance
        row.stopTag='RESIDUAL_TOLERANCE_REACHED'; rows(it)=row; stopReason=row.stopTag; break;
    end

    selected=false; Jscaled=NaN(3); fsel=NaN; condJ=Inf; sv=[NaN;NaN;NaN];
    for fi=fdIdx:numel(fdFractions)
        [J,supported,ev]=micro_jacobian(p,z,fdFractions(fi)); totalModelEvaluations=totalModelEvaluations+ev;
        Js=diag(1./rscl)*J*diag(sc);
        if all(supported(:)) && all(isfinite(Js(:))) && isreal(Js)
            [~,S,~]=svd(Js); st=diag(S); tol=max(size(Js))*eps(max(st)); rk=sum(st>tol);
            if rk==3
                selected=true; Jscaled=Js; fsel=fdFractions(fi); sv=st; condJ=st(1)/st(3); fdIdx=fi; break;
            end
        end
    end
    row.fdFraction=fsel; row.conditionScaled=condJ; row.s1=sv(1); row.s2=sv(2); row.s3=sv(3);
    if ~selected
        row.stopTag='NO_SUPPORTED_FULL_RANK_MICRO_JACOBIAN'; rows(it)=row; stopReason=row.stopTag; break;
    end

    eta=-pinv(Jscaled)*rr; row.gnStepInf=max(abs(eta));
    if max(abs(eta))>trust, eta=eta*(trust/max(abs(eta))); end
    row.appliedStepInf=max(abs(eta)); dz=sc.*eta;

    accepted=false; bestPoint=p; bestZ=z; bestPhi=phi0; bestRaw=raw0;
    bestAlpha=0; bestRatio=NaN; bestAttempts=NaN; bestEvalCount=0;
    for ai=1:numel(alphaSet)
        a=alphaSet(ai); zTrial=z+a*dz;
        if any(zTrial<d.bounds(:,1) | zTrial>d.bounds(:,2)), continue; end
        [ok,trialPoint,pathAttempts,ev]=advance_path(p,z,zTrial); totalModelEvaluations=totalModelEvaluations+ev;
        if ~ok, continue; end
        phiTrial=objective(trialPoint);
        pred=rr+Jscaled*(a*eta); predPhi=sum(pred.^2)+trialPoint.penalty;
        denom=phi0-predPhi;
        if denom>eps, ratio=(phi0-phiTrial)/denom; else, ratio=NaN; end
        if phiTrial<bestPhi
            accepted=true; bestPoint=trialPoint; bestZ=zTrial; bestPhi=phiTrial; bestRaw=norm(trialPoint.residual);
            bestAlpha=a; bestRatio=ratio; bestAttempts=pathAttempts; bestEvalCount=ev;
            if ai==1 && isfinite(ratio) && ratio>.75, break; end
        end
    end

    row.bestAlpha=bestAlpha; row.bestTrialRaw=bestRaw; row.bestTrialObjective=bestPhi;
    row.reductionRatio=bestRatio; row.pathAttempts=bestAttempts; row.acceptedEvalCount=bestEvalCount;
    if ~accepted
        trust=.5*trust; row.trustRadiusNext=trust;
        if trust<trustMin
            row.stopTag='NO_DECREASING_STEP_AT_MIN_TRUST'; rows(it)=row; stopReason=row.stopTag; break;
        end
        row.stopTag='REJECT_SHRINK'; rows(it)=row;
        fprintf('STAGE2_BRANCH_TRIM|%s|it=%d|raw=%.12e|fd=%.7g|trust=%.7g|stop=%s\n',condition.name,it,raw0,fsel,trust,row.stopTag);
        continue;
    end

    if isfinite(bestRatio) && bestRatio<.25
        trust=max(trustMin,.5*trust);
    elseif isfinite(bestRatio) && bestRatio>.75 && bestAlpha==1 && row.appliedStepInf>=.9*row.trustRadius
        trust=min(trustMax,1.5*trust);
    end
    row.trustRadiusNext=trust; row.stopTag='ACCEPT'; rows(it)=row;
    fprintf('STAGE2_BRANCH_TRIM|%s|it=%d|raw=%.12e->%.12e|fd=%.7g|cond=%.6e|trust=%.7g->%.7g|a=%.4g|ratio=%.6g|pathAttempts=%g|evals=%d\n', ...
        condition.name,it,raw0,bestRaw,fsel,condJ,row.trustRadius,trust,bestAlpha,bestRatio,bestAttempts,totalModelEvaluations);
    z=bestZ; p=bestPoint;
end

iterations=struct2table(rows(1:nrow));
span=d.bounds(:,2)-d.bounds(:,1); margin=min(z-d.bounds(:,1),d.bounds(:,2)-z)./span;
atLimit=any(margin<=1e-8);
credible=p.finiteReal && p.physicalConverged && p.physicalBranchSupported && ...
    norm(p.residual)<P.trim.residualTolerance && ~atLimit;
summary=struct2table(struct( ...
    'caseName',condition.name,'mode',mode,'startResidualNorm',startResidualNorm, ...
    'finalResidualNorm',norm(p.residual),'trimResidualTolerance',P.trim.residualTolerance, ...
    'physicalConverged',logical(p.physicalConverged), ...
    'physicalBranchSupported',logical(p.physicalBranchSupported),'atLimit',logical(atLimit), ...
    'minimumBoundMargin',min(margin),'credible',logical(credible),'iterations',nrow, ...
    'stopReason',stopReason,'finalTrustRadius',trust,'totalModelEvaluations',totalModelEvaluations, ...
    'minimumSelectedFdFraction',minimum_fd(iterations), ...
    'theta_deg',p.x9(8)*180/pi,'collective_deg',p.u7(1)*180/pi, ...
    'cyclicLong_deg',p.u7(3)*180/pi,'elevator_deg',p.u7(6)*180/pi));

writetable(summary,fullfile(outputRoot,[condition.name '_BRANCH_AWARE_TRIM_SUMMARY.csv']));
writetable(iterations,fullfile(outputRoot,[condition.name '_BRANCH_AWARE_TRIM_ITERATIONS.csv']));
results=struct('condition',condition,'mode',mode,'summary',summary,'iterations',iterations, ...
    'finalPoint',p,'finalZ',z,'seedReport',seedReport, ...
    'claimBoundary','GENERIC_STAGE2_BRANCH_TRACKING_ONLY_NO_PHYSICS_PARAMETER_TOLERANCE_BOUND_DOF_OR_PRODUCTION_ITERATION_CHANGE');
save(fullfile(outputRoot,[condition.name '_BRANCH_AWARE_TRIM.mat']),'results');

disp(summary);

    function value=objective(pt)
        q=pt.residual(:)./rscl; value=sum(q.^2)+pt.penalty;
    end

    function [J,supported,ev]=micro_jacobian(basePoint,baseZ,fraction)
        J=NaN(3); supported=false(3,2); ev=0; h=fraction*sc;
        for jj=1:3
            vals=NaN(3,2);
            for si=1:2
                signValue=2*si-3; target=baseZ; target(jj)=target(jj)+signValue*h(jj);
                [ok,pt,~,ee]=advance_path(basePoint,baseZ,target); ev=ev+ee;
                if ok, supported(jj,si)=true; vals(:,si)=pt.residual(:); end
            end
            if all(supported(jj,:)), J(:,jj)=(vals(:,2)-vals(:,1))/(2*h(jj)); end
        end
    end

    function [ok,pt,attempts,ev]=advance_path(basePoint,zFrom,zTo)
        t=0; dt=1; pt=basePoint; attempts=0; ev=0; ok=false;
        while t<1-1e-14 && attempts<maxPathAttempts
            tTry=min(1,t+dt); zTry=zFrom+tTry*(zTo-zFrom); attempts=attempts+1; ev=ev+1;
            Pk=P;
            Pk.stage2Numerics.flapInitialLeft=pt.eomOut.components.rotorLeft.zFlap(:);
            Pk.stage2Numerics.flapInitialRight=pt.eomOut.components.rotorRight.zFlap(:);
            good=false;
            try
                candidate=stage2_evaluate_trim_point(modelIdentity,condition,d,zTry,Pk);
                good=candidate.finiteReal && candidate.physicalConverged && candidate.physicalBranchSupported;
            catch
                good=false;
            end
            if good
                pt=candidate; t=tTry;
                if t>=1-1e-14, ok=true; return; end
                dt=min(2*dt,1-t);
            else
                dt=.5*dt;
                if dt<minPathDt, ok=false; return; end
            end
        end
    end
end

function value=minimum_fd(T)
if isempty(T), value=NaN; return; end
v=T.fdFraction(isfinite(T.fdFraction));
if isempty(v), value=NaN; else, value=min(v); end
end

function row=emptyrow()
row=struct('iteration',NaN,'z1',NaN,'z2',NaN,'z3',NaN, ...
    'residualNormRaw',NaN,'objectiveScaled',NaN,'fdFraction',NaN, ...
    'conditionScaled',NaN,'s1',NaN,'s2',NaN,'s3',NaN,'trustRadius',NaN, ...
    'gnStepInf',NaN,'appliedStepInf',NaN,'bestAlpha',NaN,'bestTrialRaw',NaN, ...
    'bestTrialObjective',NaN,'reductionRatio',NaN,'pathAttempts',NaN, ...
    'acceptedEvalCount',NaN,'trustRadiusNext',NaN,'stopTag','');
end
