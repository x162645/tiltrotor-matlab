function [xTrim,uTrim,report] = stage2_trim_longitudinal(modelIdentity,condition,P,opts)
%STAGE2_TRIM_LONGITUDINAL Reuse exact production explicit trim definition;
% only the EOM evaluator is replaced by the analysis-only stage-2 backend.
if nargin<4, opts=struct(); end
if ~isfield(opts,'mode') || isempty(opts.mode), error('stage2_trim_longitudinal:ExplicitModeRequired','opts.mode is required.'); end
definition=make_trim_definition(opts.mode,condition,P);
if isfield(opts,'initialValues') && ~isempty(opts.initialValues)
    z0=opts.initialValues(:); if numel(z0)~=numel(definition.initialValues), error('stage2_trim_longitudinal:BadInitial','initialValues size mismatch.'); end
    definition.initialValues=min(max(z0,definition.bounds(:,1)),definition.bounds(:,2));
end
n=numel(definition.initialValues); y0=ones(n,1); z0=definition.initialValues(:); scale=definition.variableScale(:);
options=optimset('Display',P.trim.display,'MaxIter',P.trim.maxIterations,'MaxFunEvals',10*P.trim.maxIterations,'TolX',1e-8,'TolFun',1e-10);
invalidCount=0; invalidIds={};
[yOpt,fval,exitflag,output]=fminsearch(@objective,y0,options); zOpt=from_scaled(yOpt);
point=stage2_evaluate_trim_point(modelIdentity,condition,definition,zOpt,P);
below=max(definition.bounds(:,1)-zOpt,0); above=max(zOpt-definition.bounds(:,2),0);
span=definition.bounds(:,2)-definition.bounds(:,1); margin=min(zOpt-definition.bounds(:,1),definition.bounds(:,2)-zOpt)./span;
atLimit=any(margin<=1e-8) || any(below>0) || any(above>0);
withinLimits=~any(below>1e-8 | above>1e-8);
resNorm=norm(point.residual); solverConverged=exitflag>0;
credible=solverConverged && resNorm<P.trim.residualTolerance && point.finiteReal && ...
    point.physicalConverged && point.physicalBranchSupported && ~atLimit && withinLimits;
xTrim=point.x9; uTrim=point.u7;
report=struct(); report.modelIdentity=char(modelIdentity); report.mode=opts.mode; report.definition=definition;
report.trimVariableVector=zOpt; report.trimVariables=named_struct(definition.unknownNames,zOpt);
report.x9=xTrim; report.u7=uTrim; report.point=point; report.residual=point.residual; report.residualNorm=resNorm;
report.solverConverged=solverConverged; report.physicalConverged=point.physicalConverged;
report.physicalBranchSupported=point.physicalBranchSupported; report.physicalStatus=point.physicalStatus;
report.atLimit=atLimit; report.withinLimits=withinLimits; report.credible=credible;
report.exitflag=exitflag; report.output=output; report.cost=fval; report.invalidEvaluationCount=invalidCount;
report.invalidEvaluationIdentifiers=unique(invalidIds); report.allocation=point.allocation;
report.claimBoundary='WHOLE_AIRCRAFT_PROPAGATION_SENSITIVITY_NOT_XV15_AIRCRAFT_VALIDATION';
    function z=from_scaled(y), z=z0+scale.*(y(:)-y0); end
    function J=objective(y)
        try
            p=stage2_evaluate_trim_point(modelIdentity,condition,definition,from_scaled(y),P);
        catch ME
            if startsWith(ME.identifier,'m1_evidence_v1_forward_rotor:') || startsWith(ME.identifier,'rotor_model_bemt:') || strcmp(ME.identifier,'pitch_allocation_schedule:InvalidPitchCommand')
                invalidCount=invalidCount+1; invalidIds{end+1}=ME.identifier; J=1e30; return;
            end
            rethrow(ME);
        end
        rs=p.residual; rs(ismember(definition.residualNames,{'udot','vdot','wdot'}))=rs(ismember(definition.residualNames,{'udot','vdot','wdot'}))/P.env.g;
        J=rs.'*rs+p.penalty;
        if ~p.physicalConverged || ~p.physicalBranchSupported
            invalidCount=invalidCount+1; invalidIds{end+1}=p.physicalStatus;
        end
        if ~isfinite(J) || ~isreal(J), J=1e30; end
    end
end
function S=named_struct(names,z), S=struct(); for k=1:numel(names), S.(names{k})=z(k); end, end
