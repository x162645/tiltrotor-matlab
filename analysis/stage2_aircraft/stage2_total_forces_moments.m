function [Ftotal,Mtotal,info] = stage2_total_forces_moments(modelIdentity,x,uCtrl,betaM,P)
%STAGE2_TOTAL_FORCES_MOMENTS Production-equivalent component stack with
% an explicit M0/M1 rotor backend. Gravity remains in stage2_tiltrotor_eom.
%
% Optional P.stage2Numerics.flapInitialLeft / flapInitialRight are analysis-
% only numerical initial-state overrides. They do not change rotor equations,
% physical parameters, tolerances, iteration limits, or default behavior.

x=x(:); uCtrl=uCtrl(:);
if numel(x)~=9 || numel(uCtrl)~=7
    error('stage2_total_forces_moments:InvalidInput','Expected 9-state and 7-control vectors.');
end
mp=mass_properties(betaM,P);
collective=uCtrl(1); diffCollective=uCtrl(2); cyclic=uCtrl(3); diffCyclic=uCtrl(4);
ctrlRight=struct('collective',collective+diffCollective,'cyclicLong',cyclic+diffCyclic);
ctrlLeft =struct('collective',collective-diffCollective,'cyclicLong',cyclic-diffCyclic);
ctrlRight.collective=clamp(ctrlRight.collective,P.control.collectiveLim);
ctrlLeft.collective=clamp(ctrlLeft.collective,P.control.collectiveLim);
ctrlRight.cyclicLong=clamp(ctrlRight.cyclicLong,P.control.cyclicLim);
ctrlLeft.cyclicLong=clamp(ctrlLeft.cyclicLong,P.control.cyclicLim);
uApplied=uCtrl;
uApplied(1)=0.5*(ctrlRight.collective+ctrlLeft.collective);
uApplied(2)=0.5*(ctrlRight.collective-ctrlLeft.collective);
uApplied(3)=0.5*(ctrlRight.cyclicLong+ctrlLeft.cyclicLong);
uApplied(4)=0.5*(ctrlRight.cyclicLong-ctrlLeft.cyclicLong);
uApplied(5)=clamp(uApplied(5),P.control.aileronLim);
uApplied(6)=clamp(uApplied(6),P.control.elevatorLim);
uApplied(7)=clamp(uApplied(7),P.control.rudderLim);

PL=P; PR=P; leftSeedOverride=false; rightSeedOverride=false;
if strcmpi(char(modelIdentity),'M1_EVIDENCE_V1_PROPAGATION') && isfield(P,'stage2Numerics')
    if isfield(P.stage2Numerics,'flapInitialLeft') && ~isempty(P.stage2Numerics.flapInitialLeft)
        seed=P.stage2Numerics.flapInitialLeft(:);
        if numel(seed)~=3 || any(~isfinite(seed)) || ~isreal(seed)
            error('stage2_total_forces_moments:InvalidLeftFlapInitial', ...
                'stage2Numerics.flapInitialLeft must be a finite real 3-vector.');
        end
        PL.rotor.flapInitial=seed; leftSeedOverride=true;
    end
    if isfield(P.stage2Numerics,'flapInitialRight') && ~isempty(P.stage2Numerics.flapInitialRight)
        seed=P.stage2Numerics.flapInitialRight(:);
        if numel(seed)~=3 || any(~isfinite(seed)) || ~isreal(seed)
            error('stage2_total_forces_moments:InvalidRightFlapInitial', ...
                'stage2Numerics.flapInitialRight must be a finite real 3-vector.');
        end
        PR.rotor.flapInitial=seed; rightSeedOverride=true;
    end
end

[FrotL,MrotL,rotL]=stage2_rotor_backend(modelIdentity,x,ctrlLeft,betaM,-1,mp.cgShift,PL);
[FrotR,MrotR,rotR]=stage2_rotor_backend(modelIdentity,x,ctrlRight,betaM,+1,mp.cgShift,PR);
[Fwing,Mwing,wing]=wing_model(x,uApplied,betaM,mp.cgShift,rotL,rotR,P);
[Ffus,Mfus,fus]=fuselage_model(x,mp.cgShift,P);
[Fht,Mht,htail]=horizontal_tail_model(x,uApplied(6),mp.cgShift,P);
[Fvt,Mvt,vtail]=vertical_tail_model(x,uApplied(7),mp.cgShift,P);
Ftotal=FrotL+FrotR+Fwing+Ffus+Fht+Fvt;
Mtotal=MrotL+MrotR+Mwing+Mfus+Mht+Mvt;
info.components={struct('name','rotorLeft','F',FrotL,'M',MrotL,'data',rotL); ...
    struct('name','rotorRight','F',FrotR,'M',MrotR,'data',rotR); ...
    struct('name','wing','F',Fwing,'M',Mwing,'data',wing); ...
    struct('name','fuselage','F',Ffus,'M',Mfus,'data',fus); ...
    struct('name','horizontalTail','F',Fht,'M',Mht,'data',htail); ...
    struct('name','verticalTail','F',Fvt,'M',Mvt,'data',vtail)};
info.massProperties=mp; info.commandedControls=uCtrl; info.appliedControls=uApplied;
info.appliedRotorControls.left=ctrlLeft; info.appliedRotorControls.right=ctrlRight;
info.rotorLeft=rotL; info.rotorRight=rotR; info.wing=wing; info.fuselage=fus;
info.horizontalTail=htail; info.verticalTail=vtail;
info.stage2Numerics=struct('leftFlapInitialOverride',leftSeedOverride, ...
    'rightFlapInitialOverride',rightSeedOverride);
info.physicalConverged=rotL.physicalConverged && rotR.physicalConverged;
info.physicalBranchSupported=rotL.physicalBranchSupported && rotR.physicalBranchSupported;
if info.physicalConverged, info.physicalStatus='PHYSICAL_CONVERGED';
elseif strcmp(rotL.physicalStatus,rotR.physicalStatus), info.physicalStatus=rotL.physicalStatus;
else, info.physicalStatus=sprintf('LEFT_%s__RIGHT_%s',rotL.physicalStatus,rotR.physicalStatus); end
info.F=Ftotal; info.M=Mtotal; info.stage2ModelIdentity=char(modelIdentity);
end
function y=clamp(v,lim), y=min(max(v,lim(1)),lim(2)); end
