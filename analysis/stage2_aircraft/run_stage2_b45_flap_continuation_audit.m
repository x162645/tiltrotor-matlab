function results = run_stage2_b45_flap_continuation_audit(outputRoot)
%RUN_STAGE2_B45_FLAP_CONTINUATION_AUDIT Diagnose B45 M1 flap convergence basin.
% Diagnostic only: production equations, tolerances, Jacobian settings,
% line search and model parameters remain unchanged. Only the initial flap
% state is replaced by a converged neighboring solution for warm-start tests.
if nargin < 1 || isempty(outputRoot)
    outputRoot=fullfile(pwd,'results','stage2_b45_flap_continuation_audit');
end
if ~exist(outputRoot,'dir'), mkdir(outputRoot); end

P=stage2_matched_rotor_parameters(); d2r=pi/180;
condition=struct('name','B45_V035','V',35,'betaM',45*d2r,'gamma',0, ...
    'mode','conversion_longitudinal');
definition=make_trim_definition(condition.mode,condition,P);
z0=[0.36961115687162627;0.6097990356720934;1.647599943976152];
base=stage2_evaluate_trim_point('M1_EVIDENCE_V1_PROPAGATION',condition,definition,z0,P);
assert(base.physicalConverged && base.physicalBranchSupported, ...
    'run_stage2_b45_flap_continuation_audit:BaseUnsupported','Frozen B45 center must be supported.');
centerSeed=base.eomOut.components.rotorLeft.zFlap(:);
cgShift=base.eomOut.components.massProperties.cgShift;

stepFractions=[-2.5e-4 -5e-4 -7.5e-4 -1e-3];
rows=repmat(empty_row(),3,1);
for j=1:3
    row=empty_row(); row.variableIndex=j; row.variableName=definition.unknownNames{j};
    target=z0; target(j)=target(j)-1e-3*definition.variableScale(j);

    % First reproduce the target failure with the unmodified default seed.
    try
        [~,~,outDefault]=eval_left_rotor(target,P,condition,definition,cgShift);
        row.defaultReturned=true; row.defaultStatus=outDefault.physicalStatus;
        row.defaultResidual=outDefault.flapResidualNorm;
    catch ME
        row.defaultErrorIdentifier=ME.identifier; row.defaultErrorMessage=ME.message;
    end

    % Direct warm start from the converged frozen B45 center solution.
    Pw=P; Pw.rotor.flapInitial=centerSeed;
    try
        [~,~,outWarm]=eval_left_rotor(target,Pw,condition,definition,cgShift);
        row.centerWarmReturned=true; row.centerWarmStatus=outWarm.physicalStatus;
        row.centerWarmResidual=outWarm.flapResidualNorm;
        row.centerWarmZ1=outWarm.zFlap(1); row.centerWarmZ2=outWarm.zFlap(2); row.centerWarmZ3=outWarm.zFlap(3);
    catch ME
        row.centerWarmErrorIdentifier=ME.identifier; row.centerWarmErrorMessage=ME.message;
    end

    % Fine solution-branch continuation using only the previous converged zFlap.
    seed=centerSeed; continuationOk=true; reached=0; lastOut=[];
    for f=stepFractions
        zk=z0; zk(j)=zk(j)+f*definition.variableScale(j);
        Pc=P; Pc.rotor.flapInitial=seed;
        try
            [~,~,outC]=eval_left_rotor(zk,Pc,condition,definition,cgShift);
            seed=outC.zFlap(:); lastOut=outC; reached=f;
        catch ME
            continuationOk=false;
            row.continuationErrorIdentifier=ME.identifier;
            row.continuationErrorMessage=ME.message;
            break;
        end
    end
    row.continuationReturned=continuationOk;
    row.continuationReachedFraction=reached;
    if continuationOk
        row.continuationStatus=lastOut.physicalStatus;
        row.continuationResidual=lastOut.flapResidualNorm;
        row.continuationZ1=lastOut.zFlap(1); row.continuationZ2=lastOut.zFlap(2); row.continuationZ3=lastOut.zFlap(3);
    end
    rows(j)=row;
end

points=struct2table(rows);
writetable(points,fullfile(outputRoot,'STAGE2_B45_FLAP_CONTINUATION_POINTS.csv'));
results=struct('points',points,'baseZ',z0,'centerLeftZFlap',centerSeed, ...
    'targetFraction',-1e-3,'continuationFractions',stepFractions, ...
    'modelIdentity','M1_EVIDENCE_V1_PROPAGATION', ...
    'claimBoundary','DIAGNOSTIC_INITIAL_STATE_ONLY_NO_PHYSICS_OR_THRESHOLD_CHANGE');
save(fullfile(outputRoot,'STAGE2_B45_FLAP_CONTINUATION_AUDIT.mat'),'results');
disp(points);
for k=1:height(points)
    fprintf(['B45_CONTINUATION|var=%s|default=%d|center_warm=%d|continuation=%d|' ...
        'reached=%.7g|warm_res=%.9e|cont_res=%.9e|default_err=%s|warm_err=%s|cont_err=%s\n'], ...
        points.variableName{k},points.defaultReturned(k),points.centerWarmReturned(k), ...
        points.continuationReturned(k),points.continuationReachedFraction(k), ...
        points.centerWarmResidual(k),points.continuationResidual(k), ...
        points.defaultErrorIdentifier{k},points.centerWarmErrorIdentifier{k}, ...
        points.continuationErrorIdentifier{k});
end
end

function [F,M,out]=eval_left_rotor(z,P,condition,definition,cgShift)
[x,u]=build_point_inputs(z,P,condition,definition);
ctrlLeft=struct('collective',u(1)-u(2),'cyclicLong',u(3)-u(4));
ctrlLeft.collective=clamp(ctrlLeft.collective,P.control.collectiveLim);
ctrlLeft.cyclicLong=clamp(ctrlLeft.cyclicLong,P.control.cyclicLim);
[F,M,out]=stage2_rotor_backend('M1_EVIDENCE_V1_PROPAGATION',x,ctrlLeft, ...
    condition.betaM,-1,cgShift,P);
end

function [x,u]=build_point_inputs(z,P,condition,definition)
stateNames={'u';'v';'w';'p';'q';'r';'phi';'theta';'psi'};
controlNames={'collective';'diffCollective';'cyclicLong';'diffCyclic';'aileron';'elevator';'rudder'};
x=zeros(9,1); u=zeros(7,1);
x=apply_values(x,stateNames,definition.fixedStates); u=apply_values(u,controlNames,definition.fixedControls);
for i=1:numel(definition.unknownNames)
    nm=definition.unknownNames{i}; si=find(strcmp(stateNames,nm),1); ci=find(strcmp(controlNames,nm),1);
    if ~isempty(si), x(si)=z(i); elseif ~isempty(ci), u(ci)=z(i); end
end
if isfield(definition,'allocation')
    pi=find(strcmp(definition.unknownNames,'pitchCommand'),1);
    allocation=pitch_allocation_schedule(condition.betaM,z(pi),P,definition.allocation.direction);
    u(strcmp(controlNames,'cyclicLong'))=allocation.cyclicLong;
    u(strcmp(controlNames,'elevator'))=allocation.elevator;
end
theta=x(8); alpha=theta-condition.gamma;
if condition.V<1e-10, x(1)=0; x(3)=0; else, x(1)=condition.V*cos(alpha); x(3)=condition.V*sin(alpha); end
end

function vector=apply_values(vector,names,S)
f=fieldnames(S); for i=1:numel(f), vector(strcmp(names,f{i}))=S.(f{i}); end
end
function y=clamp(v,lim), y=min(max(v,lim(1)),lim(2)); end
function r=empty_row()
r=struct('variableIndex',NaN,'variableName','', ...
    'defaultReturned',false,'defaultStatus','','defaultResidual',NaN, ...
    'defaultErrorIdentifier','','defaultErrorMessage','', ...
    'centerWarmReturned',false,'centerWarmStatus','','centerWarmResidual',NaN, ...
    'centerWarmZ1',NaN,'centerWarmZ2',NaN,'centerWarmZ3',NaN, ...
    'centerWarmErrorIdentifier','','centerWarmErrorMessage','', ...
    'continuationReturned',false,'continuationReachedFraction',0,'continuationStatus','', ...
    'continuationResidual',NaN,'continuationZ1',NaN,'continuationZ2',NaN,'continuationZ3',NaN, ...
    'continuationErrorIdentifier','','continuationErrorMessage','');
end
