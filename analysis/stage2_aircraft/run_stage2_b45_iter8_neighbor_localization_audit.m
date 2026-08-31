function results = run_stage2_b45_iter8_neighbor_localization_audit(outputRoot)
%RUN_STAGE2_B45_ITER8_NEIGHBOR_LOCALIZATION_AUDIT Localize support loss.
% Reconstruct the exact supported iteration-8 point from the frozen B45
% checkpoint by deterministic flap-state continuation. Then sample symmetric
% trim-variable neighbors at progressively smaller fractions, carrying only
% converged left/right flap states as nonlinear-solver initial guesses.
% No model equation, parameter, tolerance, bound, or trim DOF is changed.

if nargin<1 || isempty(outputRoot)
    outputRoot=fullfile(pwd,'results','stage2_b45_iter8_neighbor_localization');
end
if ~exist(outputRoot,'dir'), mkdir(outputRoot); end

P=stage2_matched_rotor_parameters(); d2r=pi/180;
condition=struct('name','B45_V035','V',35,'betaM',45*d2r,'gamma',0,'mode','conversion_longitudinal');
definition=make_trim_definition(condition.mode,condition,P);
z0=[0.36961115687162627;0.6097990356720934;1.647599943976152];
z8=[0.369564894531578;0.609781364944676;1.6450544894307];
expectedResidual8=[-0.112765630002703;-0.410013682980943;0.0747474035633331];

cont=struct('anchorZ',z0,'maxStepFraction',5e-4);
[base,baseTrace]=stage2_evaluate_trim_point_continuation('M1_EVIDENCE_V1_PROPAGATION', ...
    condition,definition,z8,P,cont);
assert(base.physicalConverged && base.physicalBranchSupported && ...
    norm(base.residual-expectedResidual8)<=5e-9, ...
    'run_stage2_b45_iter8_neighbor_localization_audit:ReconstructionDrift', ...
    'Iteration-8 point did not reconstruct on the same physical branch.');

fractions=[1e-3 5e-4 2.5e-4 1e-4];
sgns=[-1 1];
rows=repmat(empty_row(),numel(fractions)*3*2,1); idx=0;
for f=fractions
    for j=1:3
        for sg=sgns
            idx=idx+1; row=empty_row();
            row.stepFraction=f; row.variableIndex=j; row.variableName=definition.unknownNames{j}; row.sign=sg;
            row.delta=sg*f*definition.variableScale(j);
            zt=z8; zt(j)=zt(j)+row.delta;
            row.targetZ1=zt(1); row.targetZ2=zt(2); row.targetZ3=zt(3);
            row.withinBounds=all(zt>=definition.bounds(:,1) & zt<=definition.bounds(:,2));
            if ~row.withinBounds, row.status='OUTSIDE_TRIM_BOUNDS'; rows(idx)=row; continue; end
            try
                [pt,tr]=advance_from_base(base,z8,zt,f);
                row.evaluationReturned=true; row.physicalConverged=pt.physicalConverged;
                row.physicalBranchSupported=pt.physicalBranchSupported; row.status=pt.physicalStatus;
                row.residualNorm=norm(pt.residual); row.residual1=pt.residual(1); row.residual2=pt.residual(2); row.residual3=pt.residual(3);
                row.continuationSteps=tr.nSteps;
                row.leftBeta0=pt.eomOut.components.rotorLeft.zFlap(1);
                row.leftBeta1c=pt.eomOut.components.rotorLeft.zFlap(2);
                row.leftBeta1s=pt.eomOut.components.rotorLeft.zFlap(3);
                row.rightBeta0=pt.eomOut.components.rotorRight.zFlap(1);
                row.rightBeta1c=pt.eomOut.components.rotorRight.zFlap(2);
                row.rightBeta1s=pt.eomOut.components.rotorRight.zFlap(3);
            catch ME
                row.status=['ERROR:' ME.identifier]; row.errorIdentifier=ME.identifier; row.errorMessage=ME.message;
            end
            rows(idx)=row;
        end
    end
end
points=struct2table(rows);
summaryRows=repmat(empty_summary(),numel(fractions),1);
for k=1:numel(fractions)
    mask=abs(points.stepFraction-fractions(k))<eps;
    T=points(mask,:); s=empty_summary(); s.stepFraction=fractions(k);
    s.returnedCount=sum(T.evaluationReturned); s.supportedCount=sum(T.physicalConverged & T.physicalBranchSupported);
    s.allSixSupported=s.supportedCount==6;
    s.thetaMinusSupported=one_supported(T,1,-1); s.thetaPlusSupported=one_supported(T,1,1);
    s.collectiveMinusSupported=one_supported(T,2,-1); s.collectivePlusSupported=one_supported(T,2,1);
    s.pitchMinusSupported=one_supported(T,3,-1); s.pitchPlusSupported=one_supported(T,3,1);
    summaryRows(k)=s;
end
summary=struct2table(summaryRows);
writetable(points,fullfile(outputRoot,'STAGE2_B45_ITER8_NEIGHBOR_POINTS.csv'));
writetable(summary,fullfile(outputRoot,'STAGE2_B45_ITER8_NEIGHBOR_SUMMARY.csv'));
results=struct('baseZ',z8,'baseResidual',base.residual,'baseTrace',baseTrace, ...
    'points',points,'summary',summary,'fractions',fractions, ...
    'claimBoundary','ITER8_LOCAL_SUPPORT_DIAGNOSTIC_FLAP_INITIAL_STATE_CONTINUATION_ONLY');
save(fullfile(outputRoot,'STAGE2_B45_ITER8_NEIGHBOR_LOCALIZATION_AUDIT.mat'),'results');
disp(summary); disp(points(:,{'stepFraction','variableName','sign','evaluationReturned','physicalConverged','status','errorIdentifier'}));
for k=1:height(points)
    fprintf('B45_I8_NEIGHBOR|f=%.7g|var=%s|sign=%+d|returned=%d|physical=%d|status=%s|err=%s\n', ...
        points.stepFraction(k),points.variableName{k},points.sign(k),points.evaluationReturned(k), ...
        points.physicalConverged(k)&&points.physicalBranchSupported(k),points.status{k},points.errorIdentifier{k});
end
end

function [pt,tr]=advance_from_base(base,zStart,zTarget,f)
scaleDist=max(abs((zTarget-zStart)./([1;1;1]))); %#ok<NASGU>
% Use two or more continuation substeps across every requested FD displacement.
nSteps=max(2,ceil(2));
leftSeed=base.eomOut.components.rotorLeft.zFlap(:);
rightSeed=base.eomOut.components.rotorRight.zFlap(:);
pt=base;
for kk=1:nSteps
    zk=zStart+(kk/nSteps)*(zTarget-zStart);
    Pk=evalin('caller','P'); condition=evalin('caller','condition'); definition=evalin('caller','definition');
    Pk.stage2Numerics.flapInitialLeft=leftSeed; Pk.stage2Numerics.flapInitialRight=rightSeed;
    pt=stage2_evaluate_trim_point('M1_EVIDENCE_V1_PROPAGATION',condition,definition,zk,Pk);
    if ~(pt.finiteReal && pt.physicalConverged && pt.physicalBranchSupported)
        error('run_stage2_b45_iter8_neighbor_localization_audit:UnsupportedSubstep', ...
            'Unsupported substep %d/%d at fraction %.7g: %s',kk,nSteps,f,pt.physicalStatus);
    end
    leftSeed=pt.eomOut.components.rotorLeft.zFlap(:); rightSeed=pt.eomOut.components.rotorRight.zFlap(:);
end
tr=struct('nSteps',nSteps);
end

function tf=one_supported(T,j,sg)
mask=T.variableIndex==j & T.sign==sg; tf=any(T.evaluationReturned(mask) & T.physicalConverged(mask) & T.physicalBranchSupported(mask));
end
function r=empty_row()
r=struct('stepFraction',NaN,'variableIndex',NaN,'variableName','','sign',NaN,'delta',NaN, ...
    'targetZ1',NaN,'targetZ2',NaN,'targetZ3',NaN,'withinBounds',false,'evaluationReturned',false, ...
    'physicalConverged',false,'physicalBranchSupported',false,'status','NOT_RUN','errorIdentifier','', ...
    'errorMessage','','residualNorm',NaN,'residual1',NaN,'residual2',NaN,'residual3',NaN, ...
    'continuationSteps',0,'leftBeta0',NaN,'leftBeta1c',NaN,'leftBeta1s',NaN, ...
    'rightBeta0',NaN,'rightBeta1c',NaN,'rightBeta1s',NaN);
end
function s=empty_summary()
s=struct('stepFraction',NaN,'returnedCount',0,'supportedCount',0,'allSixSupported',false, ...
    'thetaMinusSupported',false,'thetaPlusSupported',false,'collectiveMinusSupported',false, ...
    'collectivePlusSupported',false,'pitchMinusSupported',false,'pitchPlusSupported',false);
end
