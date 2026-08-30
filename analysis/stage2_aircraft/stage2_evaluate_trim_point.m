function point = stage2_evaluate_trim_point(modelIdentity,condition,definition,z,P)
%STAGE2_EVALUATE_TRIM_POINT Exact named trim construction with stage-2 EOM.
stateNames={'u';'v';'w';'p';'q';'r';'phi';'theta';'psi'};
controlNames={'collective';'diffCollective';'cyclicLong';'diffCyclic';'aileron';'elevator';'rudder'};
derivativeNames={'udot';'vdot';'wdot';'pdot';'qdot';'rdot';'phidot';'thetadot';'psidot'};
z=z(:); x=zeros(9,1); u=zeros(7,1); allocation=struct([]);
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
[xdot,eomOut]=stage2_tiltrotor_eom(modelIdentity,x,u,condition.betaM,P);
residual=zeros(numel(definition.residualNames),1);
for j=1:numel(residual), residual(j)=xdot(strcmp(derivativeNames,definition.residualNames{j})); end
bounds=definition.bounds; below=max(bounds(:,1)-z,0); above=max(z-bounds(:,2),0);
penalty=100*sum(below.^2+above.^2);
if ~isempty(allocation)
    vals=[allocation.cyclicLong;allocation.elevator]; b=[P.control.cyclicLim(:).';P.control.elevatorLim(:).'];
    penalty=penalty+100*sum(max(b(:,1)-vals,0).^2+max(vals-b(:,2),0).^2);
end
point=struct('x9',x,'u7',u,'xdot9',xdot,'residual',residual,'penalty',penalty, ...
    'eomOut',eomOut,'allocation',allocation,'finiteReal',isreal(xdot)&&all(isfinite(xdot)), ...
    'physicalConverged',eomOut.physicalConverged,'physicalBranchSupported',eomOut.physicalBranchSupported, ...
    'physicalStatus',eomOut.physicalStatus,'modelIdentity',char(modelIdentity));
end
function vector=apply_values(vector,names,S)
f=fieldnames(S); for i=1:numel(f), vector(strcmp(names,f{i}))=S.(f{i}); end
end
