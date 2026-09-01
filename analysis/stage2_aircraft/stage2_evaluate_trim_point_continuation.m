function [point,trace] = stage2_evaluate_trim_point_continuation(modelIdentity,condition,definition,zTarget,P,opts)
%STAGE2_EVALUATE_TRIM_POINT_CONTINUATION Deterministic branch-followed evaluator.
% Starting from a supported anchor point, move to zTarget along a fixed
% straight path in scaled trim-variable space. At each substep, reuse the
% converged left/right flap states only as nonlinear-solver initial guesses.
% Rotor equations, model parameters, tolerances, iteration limits and trim
% degrees of freedom are unchanged.

if nargin < 6, opts=struct(); end
if ~isfield(opts,'anchorZ') || isempty(opts.anchorZ)
    error('stage2_evaluate_trim_point_continuation:AnchorRequired','opts.anchorZ is required.');
end
if ~isfield(opts,'maxStepFraction') || isempty(opts.maxStepFraction)
    opts.maxStepFraction=2.5e-4;
end
if ~(isfinite(opts.maxStepFraction) && opts.maxStepFraction>0)
    error('stage2_evaluate_trim_point_continuation:BadStep','maxStepFraction must be positive and finite.');
end

zTarget=zTarget(:); anchorZ=opts.anchorZ(:); scale=definition.variableScale(:);
if numel(zTarget)~=numel(anchorZ) || numel(zTarget)~=numel(scale)
    error('stage2_evaluate_trim_point_continuation:DimensionMismatch','Target, anchor and variableScale sizes must match.');
end
if any(zTarget < definition.bounds(:,1) | zTarget > definition.bounds(:,2))
    error('stage2_evaluate_trim_point_continuation:TargetOutsideBounds','Target lies outside the frozen trim bounds.');
end

anchor=stage2_evaluate_trim_point(modelIdentity,condition,definition,anchorZ,P);
if ~(anchor.finiteReal && anchor.physicalConverged && anchor.physicalBranchSupported)
    error('stage2_evaluate_trim_point_continuation:UnsupportedAnchor','Continuation anchor is not physically supported.');
end
leftSeed=anchor.eomOut.components.rotorLeft.zFlap(:);
rightSeed=anchor.eomOut.components.rotorRight.zFlap(:);

scaledDistance=max(abs((zTarget-anchorZ)./scale));
if scaledDistance <= 10*eps
    point=anchor;
    trace=struct('nSteps',0,'maxStepFraction',opts.maxStepFraction,'scaledDistance',scaledDistance, ...
        'anchorZ',anchorZ,'targetZ',zTarget,'leftFinalZFlap',leftSeed,'rightFinalZFlap',rightSeed);
    return;
end
nSteps=max(1,ceil(scaledDistance/opts.maxStepFraction));
point=anchor;
for k=1:nSteps
    frac=k/nSteps;
    zk=anchorZ+frac*(zTarget-anchorZ);
    Pk=P;
    Pk.stage2Numerics.flapInitialLeft=leftSeed;
    Pk.stage2Numerics.flapInitialRight=rightSeed;
    try
        point=stage2_evaluate_trim_point(modelIdentity,condition,definition,zk,Pk);
    catch ME
        error('stage2_evaluate_trim_point_continuation:SubstepFailed', ...
            'Continuation failed at substep %d/%d (fraction %.9g): %s | %s', ...
            k,nSteps,frac,ME.identifier,ME.message);
    end
    if ~(point.finiteReal && point.physicalConverged && point.physicalBranchSupported)
        error('stage2_evaluate_trim_point_continuation:UnsupportedSubstep', ...
            'Continuation substep %d/%d returned unsupported status %s.',k,nSteps,point.physicalStatus);
    end
    leftSeed=point.eomOut.components.rotorLeft.zFlap(:);
    rightSeed=point.eomOut.components.rotorRight.zFlap(:);
end
trace=struct('nSteps',nSteps,'maxStepFraction',opts.maxStepFraction,'scaledDistance',scaledDistance, ...
    'anchorZ',anchorZ,'targetZ',zTarget,'leftFinalZFlap',leftSeed,'rightFinalZFlap',rightSeed);
end
