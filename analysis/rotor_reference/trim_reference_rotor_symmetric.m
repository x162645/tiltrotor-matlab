function [xTrim,uTrim,report] = trim_reference_rotor_symmetric( ...
        condition,P13,opts)
%TRIM_REFERENCE_ROTOR_SYMMETRIC Opt-in symmetric reference-rotor trim.
% Solves udot=wdot=qdot=0 through the 13-state torque-interface reference
% stack. This is an internal comparison calculation, not validation.

if nargin < 2 || isempty(P13)
    P13 = params_berger13();
end
if nargin < 3
    opts = struct();
end
validate_condition(condition);
if ~isfield(opts,'mode') || isempty(opts.mode)
    error('trim_reference_rotor_symmetric:ExplicitModeRequired', ...
        ['opts.mode is required. No betaM-based trim-definition handoff ' ...
         'is accepted without explicit continuity evidence.']);
end
mode = opts.mode;
definition = make_trim_definition(mode,condition,P13.base);
z0 = option_value(opts,'initialValues',definition.initialValues);
z0 = z0(:);
if numel(z0) ~= numel(definition.initialValues) || ...
        ~isreal(z0) || any(~isfinite(z0))
    error('trim_reference_rotor_symmetric:InvalidInitialValues', ...
        'Initial values must match the finite real unknown vector.');
end
z0 = clamp(z0,definition.bounds);
scale = definition.variableScale(:);
y0 = (z0-definition.initialValues(:))./scale;
solverOptions = optimset('Display',option_value(opts,'display','off'), ...
    'MaxIter',option_value(opts,'maxIter',250), ...
    'MaxFunEvals',option_value(opts,'maxFunctionEvaluations',500), ...
    'TolX',option_value(opts,'toleranceX',1e-8), ...
    'TolFun',option_value(opts,'toleranceFunction',1e-10));

evaluationCount = 0;
failedEvaluationCount = 0;
failureIdentifiers = {};
[yBest,objectiveValue,exitflag,solverOutput] = ...
    fminsearch(@objective,y0,solverOptions);
zBest = clamp(definition.initialValues(:)+scale.*yBest, ...
    definition.bounds);
point = evaluate_point(zBest);
[J,stepReport] = residual_jacobian(zBest,point.residual);
scaledJ = diag([1/P13.base.env.g,1/P13.base.env.g,1])* ...
    J*diag(scale);
singularValues = svd(scaledJ);
rankTolerance = 1e-8*max(max(singularValues),eps);
effectiveRank = sum(singularValues > rankTolerance);
conditionNumber = max(singularValues)/max(min(singularValues),realmin);
[minimumMargin,activeLimits] = bound_margins(zBest,definition.bounds);

tol = P13.base.trim.residualTolerance;
dynamicIndices = [1:6,10:13];
finiteReal = point.finiteReal && isreal(J) && all(isfinite(J(:)));
if ~finiteReal
    status = 'NONPHYSICAL';
    reason = 'Reference trim point or Jacobian is non-finite or complex.';
elseif exitflag <= 0 || norm(point.residual) >= tol || ...
        max(abs(point.xdot13(dynamicIndices))) >= 10*tol
    status = 'FAILED';
    reason = 'Solver exit state or full dynamic-equilibrium residual failed.';
elseif minimumMargin <= 0.02
    status = 'CONVERGED_BUT_BOUNDARY_LIMITED';
    reason = 'At least one trim unknown is within 2% of a bound.';
elseif effectiveRank < numel(zBest)
    status = 'RANK_DEFICIENT';
    reason = 'Scaled trim Jacobian is rank deficient.';
elseif conditionNumber > 1e8 || stepReport.maximumRelativeVariation > 1e-2
    status = 'ILL_CONDITIONED';
    reason = 'Jacobian conditioning or step sensitivity is excessive.';
else
    status = 'CREDIBLE';
    reason = ['Finite interior numerical equilibrium with a stable ' ...
        'full-rank Jacobian; this is internal evidence only.'];
end

xTrim = point.x13;
uTrim = point.u10Torque;
report.modelId = 'NUAA_PUBLIC_FORMULA_REFERENCE';
report.claimBoundary = ['INTERNAL_NUMERICAL_TRIM_COMPARISON_' ...
    'NOT_EXTERNAL_VALIDATION'];
report.status = status;
report.credible = strcmp(status,'CREDIBLE');
report.reason = reason;
report.condition = condition;
report.mode = mode;
report.definition = definition;
report.trimVariableVector = zBest;
report.trimVariables = named_struct(definition.unknownNames,zBest);
report.x13 = xTrim;
report.u10Torque = uTrim;
report.fullStateDerivative = point.xdot13;
report.dynamicResidualIndices = dynamicIndices;
report.dynamicResidual = point.xdot13(dynamicIndices);
report.dynamicResidualNorm = norm(report.dynamicResidual);
report.forceBalanceBody = point.forceBalanceBody;
report.momentBalanceBody = point.momentBalanceBody;
report.objectiveValue = objectiveValue;
report.exitflag = exitflag;
report.solverOutput = solverOutput;
report.evaluationCount = evaluationCount;
report.failedEvaluationCount = failedEvaluationCount;
report.failureIdentifiers = unique(failureIdentifiers);
report.jacobian = J;
report.jacobianStepReport = stepReport;
report.singularValues = singularValues;
report.rank = effectiveRank;
report.rankTolerance = rankTolerance;
report.conditionNumber = conditionNumber;
report.minimumUnknownMarginFraction = minimumMargin;
report.activeLimits = activeLimits;
report.finiteReal = finiteReal;
report.point = point;

    function value = objective(y)
        evaluationCount = evaluationCount+1;
        zRaw = definition.initialValues(:)+scale.*y(:);
        z = clamp(zRaw,definition.bounds);
        violation = (zRaw-z)./scale;
        try
            candidate = evaluate_point(z);
            scaledResidual = candidate.residual./ ...
                [P13.base.env.g;P13.base.env.g;1];
            value = sum(scaledResidual.^2)+1e3*sum(violation.^2);
            if ~candidate.finiteReal || ~isfinite(value) || ~isreal(value)
                error('trim_reference_rotor_symmetric:NonfinitePoint', ...
                    'Reference objective produced a non-finite point.');
            end
        catch ME
            % Trial failures remain visible in the final report.
            failedEvaluationCount = failedEvaluationCount+1;
            failureIdentifiers{end+1,1} = ME.identifier; %#ok<AGROW>
            value = 1e12+1e3*sum(violation.^2)+sum(y(:).^2);
        end
    end

    function pointOut = evaluate_point(z)
        [x9,u7,allocation] = build_base_point(z);
        x13 = [x9;condition.betaM;condition.betaM;0;0];
        u10 = [u7(1:4);0;u7(5:7);0;0];
        [xdot13,eomOut] = tiltrotor_eom_13x10_reference( ...
            x13,u10,P13,option_value(opts,'rotorOptions',struct()));
        pointOut.x13 = x13;
        pointOut.u10Torque = u10;
        pointOut.xdot13 = xdot13;
        pointOut.residual = xdot13([1,3,5]);
        pointOut.forceBalanceBody = eomOut.Ftotal;
        pointOut.momentBalanceBody = eomOut.Mtotal;
        pointOut.eomOut = eomOut;
        pointOut.allocation = allocation;
        pointOut.finiteReal = isreal(xdot13) && all(isfinite(xdot13)) && ...
            isreal(eomOut.Ftotal) && all(isfinite(eomOut.Ftotal)) && ...
            isreal(eomOut.Mtotal) && all(isfinite(eomOut.Mtotal));
    end

    function [x9,u7,allocation] = build_base_point(z)
        stateNames = {'u','v','w','p','q','r','phi','theta','psi'};
        controlNames = {'collective','diffCollective','cyclicLong', ...
            'diffCyclic','aileron','elevator','rudder'};
        x9 = apply_fixed(zeros(9,1),stateNames,definition.fixedStates);
        u7 = apply_fixed(zeros(7,1),controlNames,definition.fixedControls);
        allocation = struct([]);
        for iName = 1:numel(definition.unknownNames)
            name = definition.unknownNames{iName};
            stateIndex = find(strcmp(stateNames,name),1);
            controlIndex = find(strcmp(controlNames,name),1);
            if ~isempty(stateIndex)
                x9(stateIndex) = z(iName);
            elseif ~isempty(controlIndex)
                u7(controlIndex) = z(iName);
            end
        end
        if isfield(definition,'allocation')
            index = strcmp(definition.unknownNames,'pitchCommand');
            allocation = pitch_allocation_schedule(condition.betaM,z(index), ...
                P13.base,definition.allocation.direction);
            u7(3) = allocation.cyclicLong;
            u7(6) = allocation.elevator;
        end
        alpha = x9(8)-condition.gamma;
        x9(1) = condition.V*cos(alpha);
        x9(3) = condition.V*sin(alpha);
    end

    function [J,steps] = residual_jacobian(z,f0) %#ok<INUSD>
        hScaled = [1e-3,1e-4,1e-5];
        matrices = cell(numel(hScaled),1);
        for iStep = 1:numel(hScaled)
            matrices{iStep} = zeros(3,numel(z));
            for j = 1:numel(z)
                h = hScaled(iStep)*scale(j);
                zp = z; zm = z;
                zp(j) = min(z(j)+h,definition.bounds(j,2));
                zm(j) = max(z(j)-h,definition.bounds(j,1));
                if zp(j) == zm(j)
                    matrices{iStep}(:,j) = 0;
                else
                    fp = evaluate_point(zp);
                    fm = evaluate_point(zm);
                    matrices{iStep}(:,j) = ...
                        (fp.residual-fm.residual)/(zp(j)-zm(j));
                end
            end
        end
        J = matrices{2};
        referenceNorm = max(norm(J,'fro'),eps);
        variations = [norm(matrices{1}-J,'fro'); ...
            norm(matrices{3}-J,'fro')]/referenceNorm;
        steps.scaledSteps = hScaled(:);
        steps.matrices = matrices;
        steps.relativeVariations = variations;
        steps.maximumRelativeVariation = max(variations);
    end
end

function vector = apply_fixed(vector,names,values)
fields = fieldnames(values);
for k = 1:numel(fields)
    vector(strcmp(names,fields{k})) = values.(fields{k});
end
end

function S = named_struct(names,values)
S = struct();
for k = 1:numel(names)
    S.(names{k}) = values(k);
end
end

function [minimumMargin,active] = bound_margins(z,bounds)
span = bounds(:,2)-bounds(:,1);
margin = min(z-bounds(:,1),bounds(:,2)-z)./span;
minimumMargin = min(margin);
active = margin <= 0.02;
end

function validate_condition(condition)
required = {'V','betaM','gamma'};
for k = 1:numel(required)
    if ~isfield(condition,required{k}) || ...
            ~isscalar(condition.(required{k})) || ...
            ~isreal(condition.(required{k})) || ...
            ~isfinite(condition.(required{k}))
        error('trim_reference_rotor_symmetric:InvalidCondition', ...
            'condition.%s must be a finite real scalar.',required{k});
    end
end
if condition.V < 0 || condition.betaM < 0 || condition.betaM > pi/2
    error('trim_reference_rotor_symmetric:InvalidCondition', ...
        'V must be nonnegative and betaM must be in [0,pi/2].');
end
end

function value = option_value(options,name,defaultValue)
if isfield(options,name)
    value = options.(name);
else
    value = defaultValue;
end
end

function value = clamp(value,bounds)
value = min(max(value,bounds(:,1)),bounds(:,2));
end
