function results = run_stage2_b45_local_continuation_trim_audit(outputRoot)
%RUN_STAGE2_B45_LOCAL_CONTINUATION_TRIM_AUDIT Local branch-followed B45 trim.
% Numerical diagnostic only. Each iteration starts from the current supported
% point and reuses its converged left/right flap states as initial guesses for
% short continuation moves. Rotor equations, physical parameters, tolerances,
% trim bounds and trim degrees of freedom are unchanged.

if nargin < 1 || isempty(outputRoot)
    outputRoot=fullfile(pwd,'results','stage2_b45_local_continuation_trim_audit');
end
if ~exist(outputRoot,'dir'), mkdir(outputRoot); end

P=stage2_matched_rotor_parameters(); d2r=pi/180;
condition=struct('name','B45_V035','V',35,'betaM',45*d2r,'gamma',0,'mode','conversion_longitudinal');
definition=make_trim_definition(condition.mode,condition,P);
z=[0.36961115687162627;0.6097990356720934;1.647599943976152];
expectedResidual=[-0.11445984591707202;-0.416173243818573;0.07587035495863398];
point=stage2_evaluate_trim_point('M1_EVIDENCE_V1_PROPAGATION',condition,definition,z,P);
assert(point.physicalConverged && point.physicalBranchSupported && norm(point.residual-expectedResidual)<=1e-9, ...
    'run_stage2_b45_local_continuation_trim_audit:AnchorDrift','Frozen B45 checkpoint drifted.');

scale=definition.variableScale(:);
resScale=ones(3,1);
for i=1:3
    if any(strcmp(definition.residualNames{i},{'udot','vdot','wdot'})), resScale(i)=P.env.g; end
end
jacFraction=1e-3; maxContinuationFraction=5e-4;
trustRadius=5e-3; trustMin=2.5e-4; trustMax=2e-2;
lineAlphas=[1 0.5 0.25 0.125 0.0625]; maxIter=15;
rows=repmat(empty_iter(),maxIter,1); nDone=0; stopReason='MAX_ITER';
initialJ=[]; initialSingular=[NaN NaN NaN]; initialCondition=NaN; initialRank=NaN;

for iter=1:maxIter
    nDone=iter; baseNorm=norm(point.residual); rs=point.residual(:)./resScale;
    J=NaN(3,3); supported=true(3,2);
    h=jacFraction*scale;
    for j=1:3
        for sidx=1:2
            sg=2*sidx-3; zt=z; zt(j)=zt(j)+sg*h(j);
            if any(zt<definition.bounds(:,1) | zt>definition.bounds(:,2))
                supported(j,sidx)=false; continue;
            end
            try
                pt=advance_from(point,z,zt);
                if ~(pt.finiteReal && pt.physicalConverged && pt.physicalBranchSupported)
                    supported(j,sidx)=false;
                end
                if sidx==1, rm=pt.residual; else, rp=pt.residual; end
            catch
                supported(j,sidx)=false;
            end
        end
        if all(supported(j,:)), J(:,j)=(rp-rm)/(2*h(j)); end
    end
    Jscaled=diag(1./resScale)*J*diag(scale);
    finiteJ=isreal(Jscaled)&&all(isfinite(Jscaled(:)))&&all(supported(:));
    if finiteJ
        [~,S,~]=svd(Jscaled); sv=diag(S); tol=max(size(Jscaled))*eps(max(sv)); rankJ=sum(sv>tol);
        if sv(end)<=tol, condJ=Inf; else, condJ=sv(1)/sv(end); end
    else
        sv=[NaN;NaN;NaN]; rankJ=0; condJ=Inf;
    end
    if iter==1
        initialJ=Jscaled; initialSingular=sv(:).'; initialCondition=condJ; initialRank=rankJ;
    end

    row=empty_iter(); row.iteration=iter; row.z1=z(1); row.z2=z(2); row.z3=z(3);
    row.residualNorm=baseNorm; row.rankScaled=rankJ; row.conditionScaled=condJ;
    row.s1=sv(1); row.s2=sv(2); row.s3=sv(3); row.allNeighborsSupported=all(supported(:));
    row.trustRadius=trustRadius;

    if baseNorm<P.trim.residualTolerance
        stopReason='RESIDUAL_TOLERANCE_REACHED'; rows(iter)=row; break;
    end
    if ~(finiteJ && rankJ==3)
        stopReason='LOCAL_JACOBIAN_NOT_SUPPORTED_FULL_RANK'; rows(iter)=row; break;
    end

    eta=-pinv(Jscaled)*rs;
    etaNormInf=max(abs(eta));
    if etaNormInf>trustRadius, eta=eta*(trustRadius/etaNormInf); end
    dz=scale.*eta;
    bestNorm=baseNorm; bestPoint=point; bestZ=z; bestAlpha=0;
    for aa=lineAlphas
        zt=z+aa*dz;
        if any(zt<definition.bounds(:,1) | zt>definition.bounds(:,2)), continue; end
        try
            pt=advance_from(point,z,zt);
            rn=norm(pt.residual);
            if pt.finiteReal && pt.physicalConverged && pt.physicalBranchSupported && rn<bestNorm
                bestNorm=rn; bestPoint=pt; bestZ=zt; bestAlpha=aa;
            end
        catch
        end
    end
    row.bestTrialResidual=bestNorm; row.bestAlpha=bestAlpha;
    row.predictedStepInf=max(abs(eta)); rows(iter)=row;

    if bestAlpha<=0
        trustRadius=0.5*trustRadius;
        if trustRadius<trustMin
            stopReason='NO_DECREASING_STEP_AT_MIN_TRUST_RADIUS'; break;
        end
        continue;
    end
    reduction=(baseNorm-bestNorm)/max(baseNorm,eps);
    z=bestZ; point=bestPoint;
    if bestAlpha==1 && reduction>0.1, trustRadius=min(trustMax,1.5*trustRadius); end
end

iterations=struct2table(rows(1:nDone));
span=definition.bounds(:,2)-definition.bounds(:,1);
margin=min(z-definition.bounds(:,1),definition.bounds(:,2)-z)./span;
atLimit=any(margin<=1e-8);
credible=point.finiteReal && point.physicalConverged && point.physicalBranchSupported && ...
    norm(point.residual)<P.trim.residualTolerance && ~atLimit;
summary=struct2table(struct('caseName',condition.name,'initialResidualNorm',norm(expectedResidual), ...
    'initialRankScaled',initialRank,'initialConditionScaled',initialCondition, ...
    'initialS1',initialSingular(1),'initialS2',initialSingular(2),'initialS3',initialSingular(3), ...
    'finalZ1',z(1),'finalZ2',z(2),'finalZ3',z(3), ...
    'finalResidual1',point.residual(1),'finalResidual2',point.residual(2),'finalResidual3',point.residual(3), ...
    'finalResidualNorm',norm(point.residual),'trimResidualTolerance',P.trim.residualTolerance, ...
    'finalPhysicalConverged',point.physicalConverged,'finalPhysicalBranchSupported',point.physicalBranchSupported, ...
    'atLimit',atLimit,'credible',credible,'iterations',nDone,'stopReason',stopReason));
Jtable=array2table(initialJ,'VariableNames',{'thetaScale','collectiveScale','pitchCommandScale'}, ...
    'RowNames',{'udotOverG','wdotOverG','qdot'});
writetable(summary,fullfile(outputRoot,'STAGE2_B45_LOCAL_CONTINUATION_TRIM_SUMMARY.csv'));
writetable(iterations,fullfile(outputRoot,'STAGE2_B45_LOCAL_CONTINUATION_TRIM_ITERATIONS.csv'));
writetable(Jtable,fullfile(outputRoot,'STAGE2_B45_LOCAL_CONTINUATION_INITIAL_JACOBIAN.csv'),'WriteRowNames',true);
results=struct('summary',summary,'iterations',iterations,'initialJscaled',initialJ,'finalPoint',point, ...
    'claimBoundary','LOCAL_CONTINUATION_TRUST_REGION_NUMERICS_ONLY_NO_PHYSICS_PARAMETER_TOLERANCE_BOUND_OR_DOF_CHANGE');
save(fullfile(outputRoot,'STAGE2_B45_LOCAL_CONTINUATION_TRIM_AUDIT.mat'),'results');
disp(summary); disp(iterations);
fprintf(['B45_LOCAL_CONT|rank=%d|cond=%.9e|s=[%.9e %.9e %.9e]|initial=%.9e|' ...
    'final=%.9e|tol=%.9e|credible=%d|iters=%d|stop=%s\n'],initialRank,initialCondition, ...
    initialSingular(1),initialSingular(2),initialSingular(3),norm(expectedResidual),norm(point.residual), ...
    P.trim.residualTolerance,credible,nDone,stopReason);

    function pt=advance_from(startPoint,zStart,zTarget)
        dist=max(abs((zTarget-zStart)./scale));
        nSteps=max(1,ceil(dist/maxContinuationFraction));
        leftSeed=startPoint.eomOut.components.rotorLeft.zFlap(:);
        rightSeed=startPoint.eomOut.components.rotorRight.zFlap(:);
        pt=startPoint;
        for kk=1:nSteps
            zk=zStart+(kk/nSteps)*(zTarget-zStart);
            Pk=P; Pk.stage2Numerics.flapInitialLeft=leftSeed; Pk.stage2Numerics.flapInitialRight=rightSeed;
            pt=stage2_evaluate_trim_point('M1_EVIDENCE_V1_PROPAGATION',condition,definition,zk,Pk);
            if ~(pt.finiteReal && pt.physicalConverged && pt.physicalBranchSupported)
                error('run_stage2_b45_local_continuation_trim_audit:UnsupportedSubstep','Unsupported local continuation substep.');
            end
            leftSeed=pt.eomOut.components.rotorLeft.zFlap(:);
            rightSeed=pt.eomOut.components.rotorRight.zFlap(:);
        end
    end
end

function r=empty_iter()
r=struct('iteration',NaN,'z1',NaN,'z2',NaN,'z3',NaN,'residualNorm',NaN, ...
    'rankScaled',NaN,'conditionScaled',NaN,'s1',NaN,'s2',NaN,'s3',NaN, ...
    'allNeighborsSupported',false,'trustRadius',NaN,'predictedStepInf',NaN, ...
    'bestTrialResidual',NaN,'bestAlpha',NaN);
end
