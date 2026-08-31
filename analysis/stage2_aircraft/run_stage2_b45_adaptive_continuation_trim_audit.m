function results = run_stage2_b45_adaptive_continuation_trim_audit(outputRoot)
%RUN_STAGE2_B45_ADAPTIVE_CONTINUATION_TRIM_AUDIT Adaptive B45 trim audit.
% Numerical-diagnostics only. The physical model, rotor equations, physical
% parameters, tolerances, trim bounds and trim/control DOFs are unchanged.
%
% At each iteration this audit:
%   1) follows the already-supported M1 flap branch from the current point;
%   2) tries centered FD fractions from largest to smallest and selects the
%      largest fraction whose six signed neighbors are physically supported
%      and whose scaled trim Jacobian is finite/full-rank;
%   3) computes a trust-region Gauss-Newton step using the exact production
%      residual scaling used by stage2_trim_longitudinal;
%   4) accepts only physically supported trial points that decrease the same
%      scaled trim objective (sum of squared scaled residuals + penalty).
%
% Reusing zFlap changes only the nonlinear solver initial state. It does not
% alter M1 equations or any convergence threshold.

if nargin < 1 || isempty(outputRoot)
    outputRoot = fullfile(pwd,'results','stage2_b45_adaptive_continuation_trim_audit');
end
if ~exist(outputRoot,'dir'), mkdir(outputRoot); end

P = stage2_matched_rotor_parameters();
d2r = pi/180;
condition = struct('name','B45_V035','V',35,'betaM',45*d2r,'gamma',0, ...
    'mode','conversion_longitudinal');
definition = make_trim_definition(condition.mode,condition,P);
z = [0.36961115687162627;0.6097990356720934;1.647599943976152];
expectedResidual = [-0.11445984591707202;-0.416173243818573;0.07587035495863398];
point = stage2_evaluate_trim_point('M1_EVIDENCE_V1_PROPAGATION',condition,definition,z,P);
assert(point.finiteReal && point.physicalConverged && point.physicalBranchSupported && ...
    norm(point.residual-expectedResidual)<=1e-9, ...
    'run_stage2_b45_adaptive_continuation_trim_audit:AnchorDrift', ...
    'Frozen B45 checkpoint no longer reproduces prior evidence.');

scale = definition.variableScale(:);
residualScale = ones(numel(definition.residualNames),1);
for i=1:numel(definition.residualNames)
    if any(strcmp(definition.residualNames{i},{'udot','vdot','wdot'}))
        residualScale(i)=P.env.g;
    end
end

fdFractions = [1e-3 5e-4 2.5e-4 1e-4];
% Iteration-8 localization showed 2.5e-4 total FD displacement becomes
% supported when traversed in two substeps. Use that resolved local branch
% tracking scale consistently for both FD neighbors and trial steps.
maxContinuationFraction = 1.25e-4;
lineAlphas = [1 0.5 0.25 0.125 0.0625];
maxIter = 30;
trustRadius = 5e-3;
trustMin = 1.25e-4;
trustMax = 2e-2;

iterRows = repmat(empty_iter(),maxIter,1);
attemptRows = repmat(empty_attempt(),maxIter*numel(fdFractions),1);
attemptCount = 0;
nDone = 0;
stopReason = 'MAX_ITER';

for iter=1:maxIter
    nDone=iter;
    phi0 = trim_objective(point);
    raw0 = norm(point.residual);
    rs = point.residual(:)./residualScale;

    selected=false;
    selectedFraction=NaN; Jscaled=NaN(3,3); sv=[NaN;NaN;NaN]; rankJ=0; condJ=Inf;
    supportMask=false(3,2);

    for fi=1:numel(fdFractions)
        f=fdFractions(fi);
        attemptCount=attemptCount+1;
        [Jtry,supportTry,statusTry] = centered_jacobian(point,z,f);
        JscaledTry = diag(1./residualScale)*Jtry*diag(scale);
        finiteJ = isreal(JscaledTry) && all(isfinite(JscaledTry(:))) && all(supportTry(:));
        if finiteJ
            [~,S,~]=svd(JscaledTry); sTry=diag(S);
            tol=max(size(JscaledTry))*eps(max(sTry));
            rankTry=sum(sTry>tol);
            if sTry(end)<=tol, condTry=Inf; else, condTry=sTry(1)/sTry(end); end
        else
            sTry=[NaN;NaN;NaN]; rankTry=0; condTry=Inf;
        end
        ar=empty_attempt();
        ar.iteration=iter; ar.stepFraction=f; ar.supportedNeighborCount=sum(supportTry(:));
        ar.allSixSupported=all(supportTry(:)); ar.finiteJacobian=finiteJ;
        ar.rankScaled=rankTry; ar.conditionScaled=condTry;
        ar.s1=sTry(1); ar.s2=sTry(2); ar.s3=sTry(3);
        ar.thetaMinusStatus=statusTry{1,1}; ar.thetaPlusStatus=statusTry{1,2};
        ar.collectiveMinusStatus=statusTry{2,1}; ar.collectivePlusStatus=statusTry{2,2};
        ar.pitchMinusStatus=statusTry{3,1}; ar.pitchPlusStatus=statusTry{3,2};
        attemptRows(attemptCount)=ar;
        if finiteJ && rankTry==3
            selected=true; selectedFraction=f; Jscaled=JscaledTry;
            sv=sTry; rankJ=rankTry; condJ=condTry; supportMask=supportTry;
            break;
        end
    end

    row=empty_iter();
    row.iteration=iter; row.z1=z(1); row.z2=z(2); row.z3=z(3);
    row.residual1=point.residual(1); row.residual2=point.residual(2); row.residual3=point.residual(3);
    row.residualNormRaw=raw0; row.objectiveScaled=phi0;
    row.selectedFdFraction=selectedFraction; row.rankScaled=rankJ; row.conditionScaled=condJ;
    row.s1=sv(1); row.s2=sv(2); row.s3=sv(3);
    row.allNeighborsSupported=selected && all(supportMask(:)); row.trustRadius=trustRadius;

    if raw0 < P.trim.residualTolerance
        row.stopTag='RESIDUAL_TOLERANCE_REACHED'; iterRows(iter)=row;
        stopReason=row.stopTag; break;
    end
    if ~selected
        row.stopTag='NO_SUPPORTED_FULL_RANK_CENTERED_JACOBIAN'; iterRows(iter)=row;
        stopReason=row.stopTag; break;
    end

    etaGN = -pinv(Jscaled)*rs;
    eta = etaGN;
    etaInf=max(abs(eta));
    if etaInf>trustRadius, eta=eta*(trustRadius/etaInf); end
    row.gnStepInf=max(abs(etaGN)); row.appliedStepInf=max(abs(eta));
    dz=scale.*eta;

    bestPhi=phi0; bestRaw=raw0; bestPoint=point; bestZ=z; bestAlpha=0;
    bestPredPhi=phi0; bestRatio=NaN;
    for ai=1:numel(lineAlphas)
        aa=lineAlphas(ai);
        zt=z+aa*dz;
        if any(zt<definition.bounds(:,1) | zt>definition.bounds(:,2)), continue; end
        try
            pt=advance_from(point,z,zt);
            if ~(pt.finiteReal && pt.physicalConverged && pt.physicalBranchSupported), continue; end
            phi=trim_objective(pt);
            if phi<bestPhi
                predRs=rs+Jscaled*(aa*eta);
                predPhi=sum(predRs.^2)+pt.penalty;
                denom=phi0-predPhi;
                if denom>eps, ratio=(phi0-phi)/denom; else, ratio=NaN; end
                bestPhi=phi; bestRaw=norm(pt.residual); bestPoint=pt; bestZ=zt;
                bestAlpha=aa; bestPredPhi=predPhi; bestRatio=ratio;
            end
        catch
            % Unsupported continuation trial: keep searching smaller alpha.
        end
    end

    row.bestAlpha=bestAlpha; row.bestTrialObjectiveScaled=bestPhi;
    row.bestTrialResidualNormRaw=bestRaw; row.predictedObjectiveScaled=bestPredPhi;
    row.actualToPredictedReductionRatio=bestRatio;

    if bestAlpha<=0
        trustRadius=0.5*trustRadius;
        row.trustRadiusNext=trustRadius;
        if trustRadius<trustMin
            row.stopTag='NO_OBJECTIVE_DECREASING_STEP_AT_MIN_TRUST_RADIUS';
            iterRows(iter)=row; stopReason=row.stopTag; break;
        end
        row.stopTag='REJECT_AND_SHRINK_TRUST_REGION';
        iterRows(iter)=row;
        continue;
    end

    % Standard trust-region interpretation of actual/predicted reduction.
    if isfinite(bestRatio) && bestRatio<0.25
        trustRadius=max(trustMin,0.5*trustRadius);
    elseif isfinite(bestRatio) && bestRatio>0.75 && bestAlpha==1 && ...
            row.appliedStepInf>=0.9*row.trustRadius
        trustRadius=min(trustMax,1.5*trustRadius);
    end
    row.trustRadiusNext=trustRadius;
    row.stopTag='ACCEPT';
    iterRows(iter)=row;
    z=bestZ; point=bestPoint;
end

iterations=struct2table(iterRows(1:nDone));
attempts=struct2table(attemptRows(1:attemptCount));
span=definition.bounds(:,2)-definition.bounds(:,1);
margin=min(z-definition.bounds(:,1),definition.bounds(:,2)-z)./span;
atLimit=any(margin<=1e-8);
credible=point.finiteReal && point.physicalConverged && point.physicalBranchSupported && ...
    norm(point.residual)<P.trim.residualTolerance && ~atLimit;

s=struct();
s.caseName=condition.name;
s.initialResidualNorm=norm(expectedResidual);
s.initialObjectiveScaled=sum((expectedResidual./residualScale).^2);
s.finalZ1=z(1); s.finalZ2=z(2); s.finalZ3=z(3);
s.finalResidual1=point.residual(1); s.finalResidual2=point.residual(2); s.finalResidual3=point.residual(3);
s.finalResidualNorm=norm(point.residual); s.finalObjectiveScaled=trim_objective(point);
s.trimResidualTolerance=P.trim.residualTolerance;
s.finalPhysicalConverged=point.physicalConverged;
s.finalPhysicalBranchSupported=point.physicalBranchSupported;
s.atLimit=atLimit; s.credible=credible; s.iterations=nDone; s.stopReason=stopReason;
s.minimumSelectedFdFraction=min_selected_fraction(iterations);
s.maximumSelectedFdFraction=max_selected_fraction(iterations);
s.maxContinuationFraction=maxContinuationFraction;
summary=struct2table(s);

writetable(summary,fullfile(outputRoot,'STAGE2_B45_ADAPTIVE_CONTINUATION_TRIM_SUMMARY.csv'));
writetable(iterations,fullfile(outputRoot,'STAGE2_B45_ADAPTIVE_CONTINUATION_TRIM_ITERATIONS.csv'));
writetable(attempts,fullfile(outputRoot,'STAGE2_B45_ADAPTIVE_CONTINUATION_JACOBIAN_ATTEMPTS.csv'));
results=struct('summary',summary,'iterations',iterations,'jacobianAttempts',attempts, ...
    'finalPoint',point,'finalZ',z,'fdFractions',fdFractions, ...
    'claimBoundary',['ADAPTIVE_CENTERED_FD_AND_FLAP_INITIAL_STATE_CONTINUATION_ONLY_' ...
    'NO_PHYSICS_PARAMETER_TOLERANCE_BOUND_OR_TRIM_DOF_CHANGE']);
save(fullfile(outputRoot,'STAGE2_B45_ADAPTIVE_CONTINUATION_TRIM_AUDIT.mat'),'results');

disp(summary); disp(iterations);
fprintf(['B45_ADAPTIVE|initial_raw=%.12e|final_raw=%.12e|initial_phi=%.12e|' ...
    'final_phi=%.12e|tol=%.12e|credible=%d|iters=%d|fd_min=%.7g|fd_max=%.7g|stop=%s\n'], ...
    s.initialResidualNorm,s.finalResidualNorm,s.initialObjectiveScaled,s.finalObjectiveScaled, ...
    s.trimResidualTolerance,s.credible,s.iterations,s.minimumSelectedFdFraction, ...
    s.maximumSelectedFdFraction,s.stopReason);

    function phi=trim_objective(pt)
        rr=pt.residual(:)./residualScale;
        phi=sum(rr.^2)+pt.penalty;
    end

    function [J,support,status]=centered_jacobian(basePoint,zBase,f)
        J=NaN(3,3); support=false(3,2); status=repmat({'NOT_RUN'},3,2);
        h=f*scale;
        for jj=1:3
            rp=NaN(3,1); rm=NaN(3,1);
            for si=1:2
                sg=2*si-3;
                zt=zBase; zt(jj)=zt(jj)+sg*h(jj);
                if any(zt<definition.bounds(:,1) | zt>definition.bounds(:,2))
                    status{jj,si}='OUTSIDE_TRIM_BOUNDS'; continue;
                end
                try
                    pt=advance_from(basePoint,zBase,zt);
                    support(jj,si)=pt.finiteReal && pt.physicalConverged && pt.physicalBranchSupported;
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

    function pt=advance_from(startPoint,zStart,zTarget)
        dist=max(abs((zTarget-zStart)./scale));
        nSteps=max(1,ceil(dist/maxContinuationFraction));
        leftSeed=startPoint.eomOut.components.rotorLeft.zFlap(:);
        rightSeed=startPoint.eomOut.components.rotorRight.zFlap(:);
        pt=startPoint;
        for kk=1:nSteps
            zk=zStart+(kk/nSteps)*(zTarget-zStart);
            Pk=P;
            Pk.stage2Numerics.flapInitialLeft=leftSeed;
            Pk.stage2Numerics.flapInitialRight=rightSeed;
            pt=stage2_evaluate_trim_point('M1_EVIDENCE_V1_PROPAGATION',condition,definition,zk,Pk);
            if ~(pt.finiteReal && pt.physicalConverged && pt.physicalBranchSupported)
                error('run_stage2_b45_adaptive_continuation_trim_audit:UnsupportedSubstep', ...
                    'Unsupported continuation substep %d/%d: %s',kk,nSteps,pt.physicalStatus);
            end
            leftSeed=pt.eomOut.components.rotorLeft.zFlap(:);
            rightSeed=pt.eomOut.components.rotorRight.zFlap(:);
        end
    end
end

function f=min_selected_fraction(T)
v=T.selectedFdFraction(isfinite(T.selectedFdFraction));
if isempty(v), f=NaN; else, f=min(v); end
end
function f=max_selected_fraction(T)
v=T.selectedFdFraction(isfinite(T.selectedFdFraction));
if isempty(v), f=NaN; else, f=max(v); end
end
function r=empty_iter()
r=struct('iteration',NaN,'z1',NaN,'z2',NaN,'z3',NaN, ...
    'residual1',NaN,'residual2',NaN,'residual3',NaN,'residualNormRaw',NaN, ...
    'objectiveScaled',NaN,'selectedFdFraction',NaN,'rankScaled',NaN, ...
    'conditionScaled',NaN,'s1',NaN,'s2',NaN,'s3',NaN,'allNeighborsSupported',false, ...
    'trustRadius',NaN,'gnStepInf',NaN,'appliedStepInf',NaN,'bestAlpha',NaN, ...
    'bestTrialObjectiveScaled',NaN,'bestTrialResidualNormRaw',NaN, ...
    'predictedObjectiveScaled',NaN,'actualToPredictedReductionRatio',NaN, ...
    'trustRadiusNext',NaN,'stopTag','');
end
function r=empty_attempt()
r=struct('iteration',NaN,'stepFraction',NaN,'supportedNeighborCount',0, ...
    'allSixSupported',false,'finiteJacobian',false,'rankScaled',NaN, ...
    'conditionScaled',NaN,'s1',NaN,'s2',NaN,'s3',NaN, ...
    'thetaMinusStatus','','thetaPlusStatus','','collectiveMinusStatus','', ...
    'collectivePlusStatus','','pitchMinusStatus','','pitchPlusStatus','');
end
