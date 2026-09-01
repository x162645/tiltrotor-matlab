function results = run_stage2_b45_iter5_collective_micro_localization(outputRoot)
%RUN_STAGE2_B45_ITER5_COLLECTIVE_MICRO_LOCALIZATION
% Diagnostic-only localization of the collective-direction support boundary at
% the terminal point of the post-iteration-8 adaptive B45 trim audit.
% No equations, physical parameters, solver tolerances, iteration limits,
% trim bounds, or trim/control DOFs are changed.

if nargin<1 || isempty(outputRoot)
    outputRoot=fullfile(pwd,'results','stage2_b45_iter5_collective_micro_localization');
end
if ~exist(outputRoot,'dir'), mkdir(outputRoot); end

P=stage2_matched_rotor_parameters(); d2r=pi/180;
condition=struct('name','B45_V035','V',35,'betaM',45*d2r,'gamma',0,'mode','conversion_longitudinal');
definition=make_trim_definition(condition.mode,condition,P);
scale=definition.variableScale(:);

zAnchor=[0.36961115687162627;0.6097990356720934;1.647599943976152];
z0=[0.369564894531578;0.609781364944676;1.6450544894307];
waypoints=[ ...
  0.369558282444178,0.609778839330826,1.64469085306706; ...
  0.369548363579866,0.609775049337619,1.64414539852161; ...
  0.369533483628559,0.609769360816135,1.64332721670343; ...
  0.369511159961705,0.609760820093650,1.64209994397615]';
expectedFinalResidual=[-0.110799717573510;-0.402867889354836;0.0734445695198193];

opts=struct('anchorZ',zAnchor,'maxStepFraction',5e-4);
[point,trace0]=stage2_evaluate_trim_point_continuation('M1_EVIDENCE_V1_PROPAGATION', ...
    condition,definition,z0,P,opts);
z=z0;
for wi=1:size(waypoints,2)
    zt=waypoints(:,wi);
    point=advance_seeded(point,z,zt,5e-4);
    z=zt;
end
assert(point.finiteReal && point.physicalConverged && point.physicalBranchSupported && ...
    norm(point.residual-expectedFinalResidual)<=5e-9, ...
    'run_stage2_b45_iter5_collective_micro_localization:CheckpointDrift', ...
    'Archived iteration-5 endpoint failed deterministic reconstruction.');

fractions=[1e-4 7.5e-5 5e-5 2.5e-5 1e-5 5e-6 2.5e-6 1e-6];
substeps=[1 2 4 8 16];
rows=repmat(empty_row(),numel(fractions)*2*numel(substeps),1); n=0;

for fi=1:numel(fractions)
    f=fractions(fi);
    for si=1:2
        sgn=2*si-3;
        zt=z; zt(2)=zt(2)+sgn*f*scale(2);
        for ni=1:numel(substeps)
            ns=substeps(ni); n=n+1; r=empty_row();
            r.stepFraction=f; r.sign=sgn; r.substeps=ns; r.targetCollective=zt(2);
            try
                pt=advance_fixed(point,z,zt,ns);
                r.supported=pt.finiteReal && pt.physicalConverged && pt.physicalBranchSupported;
                r.status=pt.physicalStatus;
                if r.supported
                    r.residualNorm=norm(pt.residual);
                    r.residual1=pt.residual(1); r.residual2=pt.residual(2); r.residual3=pt.residual(3);
                end
            catch ME
                r.supported=false; r.status=['ERROR:' ME.identifier];
            end
            rows(n)=r;
            fprintf('B45_I5_MICRO|f=%.7g|sign=%+d|substeps=%d|supported=%d|status=%s|raw=%.12e\n', ...
                f,sgn,ns,r.supported,r.status,r.residualNorm);
        end
    end
end

T=struct2table(rows(1:n));
writetable(T,fullfile(outputRoot,'STAGE2_B45_ITER5_COLLECTIVE_MICRO_LOCALIZATION.csv'));
summary=struct(); summary.caseName=condition.name; summary.z1=z(1); summary.z2=z(2); summary.z3=z(3);
summary.residualNorm=norm(point.residual); summary.reconstructionStepsToIter8=trace0.nSteps;
summary.minimumTestedFraction=min(fractions); summary.maximumTestedFraction=max(fractions);
summary.anyMinusSupported=any(T.supported & T.sign<0); summary.anyPlusSupported=any(T.supported & T.sign>0);
summary.smallestMinusSupported=min_supported(T,-1); summary.smallestPlusSupported=min_supported(T,1);
S=struct2table(summary);
writetable(S,fullfile(outputRoot,'STAGE2_B45_ITER5_COLLECTIVE_MICRO_SUMMARY.csv'));
results=struct('summary',S,'sweep',T,'basePoint',point,'baseZ',z, ...
    'claimBoundary','COLLECTIVE_MICRO_SUPPORT_LOCALIZATION_ONLY_NO_PHYSICS_OR_SOLVER_SETTING_CHANGE');
save(fullfile(outputRoot,'STAGE2_B45_ITER5_COLLECTIVE_MICRO_LOCALIZATION.mat'),'results');
disp(S);

    function pt=advance_seeded(startPoint,zStart,zTarget,maxFraction)
        dist=max(abs((zTarget-zStart)./scale));
        ns=max(1,ceil(dist/maxFraction));
        pt=advance_fixed(startPoint,zStart,zTarget,ns);
    end

    function pt=advance_fixed(startPoint,zStart,zTarget,nSteps)
        leftSeed=startPoint.eomOut.components.rotorLeft.zFlap(:);
        rightSeed=startPoint.eomOut.components.rotorRight.zFlap(:);
        pt=startPoint;
        for kk=1:nSteps
            zk=zStart+(kk/nSteps)*(zTarget-zStart); Pk=P;
            Pk.stage2Numerics.flapInitialLeft=leftSeed;
            Pk.stage2Numerics.flapInitialRight=rightSeed;
            pt=stage2_evaluate_trim_point('M1_EVIDENCE_V1_PROPAGATION',condition,definition,zk,Pk);
            if ~(pt.finiteReal && pt.physicalConverged && pt.physicalBranchSupported)
                error('run_stage2_b45_iter5_collective_micro_localization:UnsupportedSubstep', ...
                    'Unsupported substep %d/%d: %s',kk,nSteps,pt.physicalStatus);
            end
            leftSeed=pt.eomOut.components.rotorLeft.zFlap(:);
            rightSeed=pt.eomOut.components.rotorRight.zFlap(:);
        end
    end
end

function v=min_supported(T,sgn)
x=T.stepFraction(T.supported & T.sign==sgn);
if isempty(x), v=NaN; else, v=min(x); end
end
function r=empty_row()
r=struct('stepFraction',NaN,'sign',NaN,'substeps',NaN,'targetCollective',NaN, ...
    'supported',false,'status','','residualNorm',NaN,'residual1',NaN,'residual2',NaN,'residual3',NaN);
end
