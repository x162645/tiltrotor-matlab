function results = run_stage2_b45_microfd_continuation_trim_audit(outputRoot)
%RUN_STAGE2_B45_MICROFD_CONTINUATION_TRIM_AUDIT
% Continue the B45 Stage-2 M1 trim audit from the archived terminal point of
% the post-iteration-8 audit using smaller adaptive centered-FD scales.
%
% Diagnostic numerical protocol only. This function does NOT change rotor or
% aircraft equations, physical parameters, solver tolerances, solver iteration
% limits, trim bounds, or trim/control degrees of freedom. Archived left/right
% zFlap states are used only as nonlinear-solver initial guesses.

if nargin<1 || isempty(outputRoot)
    outputRoot=fullfile(pwd,'results','stage2_b45_microfd_continuation_trim_audit');
end
if ~exist(outputRoot,'dir'), mkdir(outputRoot); end

P=stage2_matched_rotor_parameters(); d2r=pi/180;
condition=struct('name','B45_V035','V',35,'betaM',45*d2r,'gamma',0,'mode','conversion_longitudinal');
definition=make_trim_definition(condition.mode,condition,P);
scale=definition.variableScale(:);
residualScale=ones(numel(definition.residualNames),1);
for i=1:numel(definition.residualNames)
    if any(strcmp(definition.residualNames{i},{'udot','vdot','wdot'}))
        residualScale(i)=P.env.g;
    end
end

% Exact terminal state and rotor flap states archived by the successful
% post-iteration-8 adaptive audit.
z=[0.369511159961705;0.609760820093650;1.64209994397615];
expectedResidual=[-0.110799717573510;-0.402867889354836;0.0734445695198193];
P0=P;
P0.stage2Numerics.flapInitialLeft=[0.01779756670637974;0.5068067239388294;-0.01925343328660319];
P0.stage2Numerics.flapInitialRight=[0.01779756670637973;0.5068067239388293;0.01925343328660322];
point=stage2_evaluate_trim_point('M1_EVIDENCE_V1_PROPAGATION',condition,definition,z,P0);
assert(point.finiteReal && point.physicalConverged && point.physicalBranchSupported && ...
    norm(point.residual-expectedResidual)<=5e-9, ...
    'run_stage2_b45_microfd_continuation_trim_audit:SeedDrift', ...
    'Archived terminal point/zFlap seeds failed deterministic reproduction.');

% The direct signed-neighbor probe established that collective-minus fails at
% 1e-4 even with 16 continuation substeps but both signs are supported at
% 7.5e-5 and below. Keep 1e-4 as the largest candidate and adapt downward.
fdFractions=[1e-4 7.5e-5 5e-5 2.5e-5 1e-5 5e-6 2.5e-6 1e-6];
lineAlphas=[1 0.5 0.25 0.125 0.0625];
trialMaxSubstepFractions=[5e-4 2.5e-4 1.25e-4 7.5e-5];
maxIter=40;
% Resume the previous audit's established trust-region scale. No model or
% solver setting is altered by this analysis-level trust radius.
trustRadius=2e-2; trustMin=1.25e-4; trustMax=2e-2;

iterRows=repmat(empty_iter(),maxIter,1);
attemptRows=repmat(empty_attempt(),maxIter*numel(fdFractions),1);
attemptCount=0; nDone=0; stopReason='MAX_ITER';

for iter=1:maxIter
    nDone=iter;
    phi0=objective(point); raw0=norm(point.residual); rs=point.residual(:)./residualScale;
    selected=false; selectedFraction=NaN; Jscaled=NaN(3,3);
    sv=[NaN;NaN;NaN]; rankJ=0; condJ=Inf; supportMask=false(3,2);

    for fi=1:numel(fdFractions)
        f=fdFractions(fi); attemptCount=attemptCount+1;
        [J,support,status]=centered_jacobian_two_substeps(point,z,f);
        Js=diag(1./residualScale)*J*diag(scale);
        finiteJ=isreal(Js)&&all(isfinite(Js(:)))&&all(support(:));
        if finiteJ
            [~,S,~]=svd(Js); st=diag(S);
            tol=max(size(Js))*eps(max(st));
            rt=sum(st>tol);
            if st(end)<=tol, ct=Inf; else, ct=st(1)/st(end); end
        else
            st=[NaN;NaN;NaN]; rt=0; ct=Inf;
        end
        ar=empty_attempt(); ar.iteration=iter; ar.stepFraction=f;
        ar.supportedNeighborCount=sum(support(:)); ar.allSixSupported=all(support(:));
        ar.finiteJacobian=finiteJ; ar.rankScaled=rt; ar.conditionScaled=ct;
        ar.s1=st(1); ar.s2=st(2); ar.s3=st(3);
        ar.thetaMinusStatus=status{1,1}; ar.thetaPlusStatus=status{1,2};
        ar.collectiveMinusStatus=status{2,1}; ar.collectivePlusStatus=status{2,2};
        ar.pitchMinusStatus=status{3,1}; ar.pitchPlusStatus=status{3,2};
        attemptRows(attemptCount)=ar;
        if finiteJ && rt==3
            selected=true; selectedFraction=f; Jscaled=Js; sv=st;
            rankJ=rt; condJ=ct; supportMask=support; break;
        end
    end

    row=empty_iter(); row.iteration=iter; row.z1=z(1); row.z2=z(2); row.z3=z(3);
    row.residual1=point.residual(1); row.residual2=point.residual(2); row.residual3=point.residual(3);
    row.residualNormRaw=raw0; row.objectiveScaled=phi0;
    row.selectedFdFraction=selectedFraction; row.rankScaled=rankJ; row.conditionScaled=condJ;
    row.s1=sv(1); row.s2=sv(2); row.s3=sv(3);
    row.allNeighborsSupported=selected&&all(supportMask(:)); row.trustRadius=trustRadius;

    if raw0<P.trim.residualTolerance
        row.stopTag='RESIDUAL_TOLERANCE_REACHED'; iterRows(iter)=row; stopReason=row.stopTag;
        fprintf('B45_MICROFD|iter=%d|raw=%.12e|phi=%.12e|fd=%.7g|stop=%s\n', ...
            iter,raw0,phi0,selectedFraction,row.stopTag);
        break;
    end
    if ~selected
        row.stopTag='NO_SUPPORTED_FULL_RANK_CENTERED_JACOBIAN'; iterRows(iter)=row; stopReason=row.stopTag;
        fprintf('B45_MICROFD|iter=%d|raw=%.12e|phi=%.12e|fd=NaN|stop=%s\n', ...
            iter,raw0,phi0,row.stopTag);
        break;
    end

    etaGN=-pinv(Jscaled)*rs; eta=etaGN;
    if max(abs(eta))>trustRadius, eta=eta*(trustRadius/max(abs(eta))); end
    row.gnStepInf=max(abs(etaGN)); row.appliedStepInf=max(abs(eta));
    dz=scale.*eta;

    bestPhi=phi0; bestRaw=raw0; bestPoint=point; bestZ=z; bestAlpha=0;
    bestPredPhi=phi0; bestRatio=NaN; bestMaxSubstep=NaN;
    for ai=1:numel(lineAlphas)
        aa=lineAlphas(ai); zt=z+aa*dz;
        if any(zt<definition.bounds(:,1)|zt>definition.bounds(:,2)), continue; end
        [ok,pt,usedMaxSubstep]=try_advance_refined(point,z,zt);
        if ~ok, continue; end
        phi=objective(pt);
        if phi<bestPhi
            predRs=rs+Jscaled*(aa*eta);
            predPhi=sum(predRs.^2)+pt.penalty;
            denom=phi0-predPhi;
            if denom>eps, ratio=(phi0-phi)/denom; else, ratio=NaN; end
            bestPhi=phi; bestRaw=norm(pt.residual); bestPoint=pt; bestZ=zt;
            bestAlpha=aa; bestPredPhi=predPhi; bestRatio=ratio; bestMaxSubstep=usedMaxSubstep;
        end
    end

    row.bestAlpha=bestAlpha; row.bestTrialObjectiveScaled=bestPhi;
    row.bestTrialResidualNormRaw=bestRaw; row.predictedObjectiveScaled=bestPredPhi;
    row.actualToPredictedReductionRatio=bestRatio;
    row.acceptedContinuationMaxSubstep=bestMaxSubstep;

    if bestAlpha<=0
        trustRadius=0.5*trustRadius; row.trustRadiusNext=trustRadius;
        if trustRadius<trustMin
            row.stopTag='NO_OBJECTIVE_DECREASING_STEP_AT_MIN_TRUST_RADIUS';
            iterRows(iter)=row; stopReason=row.stopTag;
            fprintf('B45_MICROFD|iter=%d|raw=%.12e|phi=%.12e|fd=%.7g|trust=%.7g|stop=%s\n', ...
                iter,raw0,phi0,selectedFraction,trustRadius,row.stopTag);
            break;
        end
        row.stopTag='REJECT_AND_SHRINK_TRUST_REGION'; iterRows(iter)=row;
        fprintf('B45_MICROFD|iter=%d|raw=%.12e|phi=%.12e|fd=%.7g|trust=%.7g|stop=%s\n', ...
            iter,raw0,phi0,selectedFraction,trustRadius,row.stopTag);
        continue;
    end

    if isfinite(bestRatio) && bestRatio<0.25
        trustRadius=max(trustMin,0.5*trustRadius);
    elseif isfinite(bestRatio) && bestRatio>0.75 && bestAlpha==1 && ...
            row.appliedStepInf>=0.9*row.trustRadius
        trustRadius=min(trustMax,1.5*trustRadius);
    end
    row.trustRadiusNext=trustRadius; row.stopTag='ACCEPT'; iterRows(iter)=row;
    fprintf(['B45_MICROFD|iter=%d|raw=%.12e->%.12e|phi=%.12e->%.12e|fd=%.7g|' ...
        'rank=%d|cond=%.6e|s=[%.6e,%.6e,%.6e]|trust=%.7g->%.7g|' ...
        'alpha=%.7g|ratio=%.6g|maxsub=%.7g\n'], ...
        iter,raw0,bestRaw,phi0,bestPhi,selectedFraction,rankJ,condJ,sv(1),sv(2),sv(3), ...
        row.trustRadius,trustRadius,bestAlpha,bestRatio,bestMaxSubstep);
    z=bestZ; point=bestPoint;
end

iterations=struct2table(iterRows(1:nDone));
attempts=struct2table(attemptRows(1:attemptCount));
span=definition.bounds(:,2)-definition.bounds(:,1);
margin=min(z-definition.bounds(:,1),definition.bounds(:,2)-z)./span;
atLimit=any(margin<=1e-8);
credible=point.finiteReal&&point.physicalConverged&&point.physicalBranchSupported&& ...
    norm(point.residual)<P.trim.residualTolerance&&~atLimit;
s=struct(); s.caseName=condition.name; s.startResidualNorm=norm(expectedResidual);
s.startObjectiveScaled=sum((expectedResidual./residualScale).^2);
s.finalZ1=z(1); s.finalZ2=z(2); s.finalZ3=z(3);
s.finalResidual1=point.residual(1); s.finalResidual2=point.residual(2); s.finalResidual3=point.residual(3);
s.finalResidualNorm=norm(point.residual); s.finalObjectiveScaled=objective(point);
s.trimResidualTolerance=P.trim.residualTolerance; s.finalPhysicalConverged=point.physicalConverged;
s.finalPhysicalBranchSupported=point.physicalBranchSupported; s.atLimit=atLimit;
s.minimumBoundMargin=min(margin); s.credible=credible; s.iterations=nDone; s.stopReason=stopReason;
s.minimumSelectedFdFraction=min_selected(iterations); s.maximumSelectedFdFraction=max_selected(iterations);
summary=struct2table(s);

writetable(summary,fullfile(outputRoot,'STAGE2_B45_MICROFD_CONTINUATION_TRIM_SUMMARY.csv'));
writetable(iterations,fullfile(outputRoot,'STAGE2_B45_MICROFD_CONTINUATION_TRIM_ITERATIONS.csv'));
writetable(attempts,fullfile(outputRoot,'STAGE2_B45_MICROFD_CONTINUATION_JACOBIAN_ATTEMPTS.csv'));
results=struct('summary',summary,'iterations',iterations,'jacobianAttempts',attempts, ...
    'finalPoint',point,'finalZ',z,'fdFractions',fdFractions, ...
    'claimBoundary','MICRO_ADAPTIVE_CENTERED_FD_AND_ZFLAP_INITIAL_GUESS_CONTINUATION_ONLY_NO_PHYSICS_PARAMETER_TOLERANCE_BOUND_OR_DOF_CHANGE');
save(fullfile(outputRoot,'STAGE2_B45_MICROFD_CONTINUATION_TRIM_AUDIT.mat'),'results');
disp(summary); disp(iterations);
fprintf(['B45_MICROFD_FINAL|start=%.12e|final=%.12e|tol=%.12e|credible=%d|' ...
    'iters=%d|fdmin=%.7g|fdmax=%.7g|minmargin=%.7g|stop=%s\n'], ...
    s.startResidualNorm,s.finalResidualNorm,s.trimResidualTolerance,s.credible,s.iterations, ...
    s.minimumSelectedFdFraction,s.maximumSelectedFdFraction,s.minimumBoundMargin,s.stopReason);

    function phi=objective(pt)
        rr=pt.residual(:)./residualScale; phi=sum(rr.^2)+pt.penalty;
    end

    function [J,support,status]=centered_jacobian_two_substeps(basePoint,zBase,f)
        J=NaN(3,3); support=false(3,2); status=repmat({'NOT_RUN'},3,2); h=f*scale;
        for jj=1:3
            rp=NaN(3,1); rm=NaN(3,1);
            for si=1:2
                sg=2*si-3; zt=zBase; zt(jj)=zt(jj)+sg*h(jj);
                if any(zt<definition.bounds(:,1)|zt>definition.bounds(:,2))
                    status{jj,si}='OUTSIDE_TRIM_BOUNDS'; continue;
                end
                try
                    pt=advance_fixed(basePoint,zBase,zt,2);
                    support(jj,si)=pt.finiteReal&&pt.physicalConverged&&pt.physicalBranchSupported;
                    status{jj,si}=pt.physicalStatus;
                    if support(jj,si)
                        if si==1, rm=pt.residual(:); else, rp=pt.residual(:); end
                    end
                catch ME
                    status{jj,si}=['ERROR:' ME.identifier];
                end
            end
            if all(support(jj,:)), J(:,jj)=(rp-rm)/(2*h(jj)); end
        end
    end

    function [ok,pt,used]=try_advance_refined(startPoint,zStart,zTarget)
        ok=false; pt=startPoint; used=NaN;
        dist=max(abs((zTarget-zStart)./scale));
        for ci=1:numel(trialMaxSubstepFractions)
            maxf=trialMaxSubstepFractions(ci); nSteps=max(1,ceil(dist/maxf));
            try
                candidate=advance_fixed(startPoint,zStart,zTarget,nSteps);
                ok=true; pt=candidate; used=maxf; return;
            catch
            end
        end
    end

    function pt=advance_fixed(startPoint,zStart,zTarget,nSteps)
        leftSeed=startPoint.eomOut.components.rotorLeft.zFlap(:);
        rightSeed=startPoint.eomOut.components.rotorRight.zFlap(:); pt=startPoint;
        for kk=1:nSteps
            zk=zStart+(kk/nSteps)*(zTarget-zStart); Pk=P;
            Pk.stage2Numerics.flapInitialLeft=leftSeed;
            Pk.stage2Numerics.flapInitialRight=rightSeed;
            pt=stage2_evaluate_trim_point('M1_EVIDENCE_V1_PROPAGATION',condition,definition,zk,Pk);
            if ~(pt.finiteReal&&pt.physicalConverged&&pt.physicalBranchSupported)
                error('run_stage2_b45_microfd_continuation_trim_audit:UnsupportedSubstep', ...
                    'Unsupported substep %d/%d: %s',kk,nSteps,pt.physicalStatus);
            end
            leftSeed=pt.eomOut.components.rotorLeft.zFlap(:);
            rightSeed=pt.eomOut.components.rotorRight.zFlap(:);
        end
    end
end

function f=min_selected(T)
v=T.selectedFdFraction(isfinite(T.selectedFdFraction)); if isempty(v), f=NaN; else, f=min(v); end
end
function f=max_selected(T)
v=T.selectedFdFraction(isfinite(T.selectedFdFraction)); if isempty(v), f=NaN; else, f=max(v); end
end
function r=empty_iter()
r=struct('iteration',NaN,'z1',NaN,'z2',NaN,'z3',NaN, ...
    'residual1',NaN,'residual2',NaN,'residual3',NaN,'residualNormRaw',NaN, ...
    'objectiveScaled',NaN,'selectedFdFraction',NaN,'rankScaled',NaN,'conditionScaled',NaN, ...
    's1',NaN,'s2',NaN,'s3',NaN,'allNeighborsSupported',false,'trustRadius',NaN, ...
    'gnStepInf',NaN,'appliedStepInf',NaN,'bestAlpha',NaN,'bestTrialObjectiveScaled',NaN, ...
    'bestTrialResidualNormRaw',NaN,'predictedObjectiveScaled',NaN, ...
    'actualToPredictedReductionRatio',NaN,'acceptedContinuationMaxSubstep',NaN, ...
    'trustRadiusNext',NaN,'stopTag','');
end
function r=empty_attempt()
r=struct('iteration',NaN,'stepFraction',NaN,'supportedNeighborCount',0, ...
    'allSixSupported',false,'finiteJacobian',false,'rankScaled',NaN,'conditionScaled',NaN, ...
    's1',NaN,'s2',NaN,'s3',NaN,'thetaMinusStatus','','thetaPlusStatus','', ...
    'collectiveMinusStatus','','collectivePlusStatus','','pitchMinusStatus','','pitchPlusStatus','');
end
