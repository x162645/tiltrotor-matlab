function audit = stage2_trim_definition_jacobian(modelIdentity,condition,definition,z,P,opts)
%STAGE2_TRIM_DEFINITION_JACOBIAN Local feasibility audit on exact trim DOFs.
% Finite differences follow stage2_evaluate_trim_point, including any
% conversion-mode virtual-command allocation. No additional control DOF is
% introduced and no model parameter is changed. Unsupported finite-difference
% neighbors are retained as diagnostic evidence; they are never imputed.

if nargin < 6, opts = struct(); end
if ~isfield(opts,'stepFraction') || isempty(opts.stepFraction), opts.stepFraction = 1.0e-2; end
if ~isfield(opts,'robustnessFractions') || isempty(opts.robustnessFractions)
    opts.robustnessFractions = [5.0e-3 1.0e-2 2.0e-2];
end
if ~isfield(opts,'lineSearchAlphas') || isempty(opts.lineSearchAlphas)
    opts.lineSearchAlphas = [1 0.5 0.25 0.125 0.0625];
end

z = z(:); scale = definition.variableScale(:);
if numel(z) ~= numel(scale) || numel(z) ~= 3
    error('stage2_trim_definition_jacobian:UnexpectedDimension', ...
        'This audit expects the current three-variable longitudinal trim definition.');
end
if any(~isfinite(scale)) || any(scale <= 0)
    error('stage2_trim_definition_jacobian:InvalidScale', ...
        'definition.variableScale must be finite and positive.');
end

base = stage2_evaluate_trim_point(modelIdentity,condition,definition,z,P);
residualScale = ones(numel(definition.residualNames),1);
for i = 1:numel(definition.residualNames)
    if any(strcmp(definition.residualNames{i},{'udot','vdot','wdot'})), residualScale(i) = P.env.g; end
end
rs = base.residual(:)./residualScale;

baseResult = local_jacobian(opts.stepFraction);
robustness = repmat(empty_robustness(),numel(opts.robustnessFractions),1);
for k = 1:numel(opts.robustnessFractions)
    tmp = local_jacobian(opts.robustnessFractions(k));
    robustness(k).stepFraction = opts.robustnessFractions(k);
    robustness(k).finite = tmp.finite;
    robustness(k).allNeighborsSupported = tmp.allNeighborsSupported;
    robustness(k).supportedNeighborCount = sum(tmp.plusSupported)+sum(tmp.minusSupported);
    robustness(k).rankScaled = tmp.rankScaled;
    robustness(k).conditionScaled = tmp.conditionScaled;
    robustness(k).s1Scaled = tmp.singularValuesScaled(1);
    robustness(k).s2Scaled = tmp.singularValuesScaled(2);
    robustness(k).s3Scaled = tmp.singularValuesScaled(3);
    if tmp.finite && baseResult.finite
        robustness(k).relativeDifferenceFromBase = ...
            norm(tmp.Jscaled-baseResult.Jscaled,'fro')/max(norm(baseResult.Jscaled,'fro'),eps);
    end
end

if baseResult.finite && baseResult.allNeighborsSupported
    eta = -pinv(baseResult.Jscaled)*rs;
    dz = scale.*eta;
    linearResidualScaled = rs + baseResult.Jscaled*eta;
    alphaBound = max_feasible_alpha(z,dz,definition.bounds);
    alpha0 = min(1,0.99*alphaBound);
    if ~isfinite(alpha0), alpha0 = 1; end
    if alpha0 < 0, alpha0 = 0; end
    alphas = unique([alpha0*opts.lineSearchAlphas(:); 0],'stable');
else
    eta = NaN(3,1); dz = NaN(3,1); linearResidualScaled = NaN(3,1);
    alphaBound = NaN; alphas = 0;
end

line = repmat(empty_line(),numel(alphas),1);
for k = 1:numel(alphas)
    aa = alphas(k); line(k).alpha = aa;
    if any(~isfinite(dz))
        zTrial = z;
    else
        zTrial = z + aa*dz;
    end
    line(k).withinBounds = all(zTrial >= definition.bounds(:,1)-1e-12 & ...
        zTrial <= definition.bounds(:,2)+1e-12);
    try
        pt = stage2_evaluate_trim_point(modelIdentity,condition,definition,zTrial,P);
        line(k).evaluationReturned = true;
        line(k).physicalConverged = pt.physicalConverged;
        line(k).physicalBranchSupported = pt.physicalBranchSupported;
        line(k).physicalStatus = pt.physicalStatus;
        line(k).residualNormRaw = norm(pt.residual);
        line(k).residualNormScaled = norm(pt.residual(:)./residualScale);
        line(k).residual1 = pt.residual(1); line(k).residual2 = pt.residual(2); line(k).residual3 = pt.residual(3);
        line(k).z1 = zTrial(1); line(k).z2 = zTrial(2); line(k).z3 = zTrial(3);
        if ~isempty(pt.allocation)
            line(k).cyclicLong = pt.allocation.cyclicLong; line(k).elevator = pt.allocation.elevator;
        else
            line(k).cyclicLong = pt.u7(3); line(k).elevator = pt.u7(6);
        end
    catch ME
        line(k).physicalStatus = ['ERROR:' ME.identifier];
    end
end

supported = [line.evaluationReturned] & [line.physicalConverged] & ...
    [line.physicalBranchSupported] & [line.withinBounds];
if any(supported)
    rawNorms = [line.residualNormRaw]; rawNorms(~supported) = Inf;
    [bestRaw,bestIdx] = min(rawNorms);
else
    bestRaw = Inf; bestIdx = 1;
end

classification = 'LOCAL_FEASIBILITY_UNRESOLVED';
if ~baseResult.allNeighborsSupported || ~baseResult.finite
    classification = 'LOCAL_NEIGHBORHOOD_NONSMOOTH_OR_MODEL_DOMAIN_LIMITED';
elseif baseResult.rankScaled < 3
    classification = 'LOCAL_TRIM_DIRECTION_RANK_DEFICIENT';
elseif baseResult.conditionScaled > 1e6
    classification = 'LOCAL_TRIM_DIRECTION_SEVERELY_ILL_CONDITIONED';
elseif norm(base.residual) < P.trim.residualTolerance
    classification = 'BASE_POINT_ALREADY_RESIDUAL_CREDIBLE';
elseif alphaBound < 1
    classification = 'LOCAL_NEWTON_CORRECTION_EXCEEDS_EXISTING_TRIM_BOUNDS';
elseif bestRaw < 0.1*norm(base.residual)
    classification = 'LOCAL_NEWTON_DIRECTION_STRONGLY_REDUCES_RESIDUAL_SOLVER_PROTOCOL_SUSPECT';
elseif bestRaw < norm(base.residual)
    classification = 'LOCAL_NEWTON_DIRECTION_PARTIALLY_REDUCES_RESIDUAL_NONLINEAR_CLOSURE_REMAINS';
else
    classification = 'LOCAL_NEWTON_DIRECTION_DOES_NOT_REDUCE_NONLINEAR_RESIDUAL';
end

audit = struct();
audit.modelIdentity = char(modelIdentity); audit.caseName = condition.name; audit.mode = condition.mode;
audit.unknownNames = definition.unknownNames; audit.baseZ = z; audit.bounds = definition.bounds;
audit.variableScale = scale; audit.residualNames = definition.residualNames; audit.residualScale = residualScale;
audit.baseResidual = base.residual; audit.baseResidualNormRaw = norm(base.residual); audit.baseResidualNormScaled = norm(rs);
audit.basePhysicalConverged = base.physicalConverged; audit.basePhysicalBranchSupported = base.physicalBranchSupported;
audit.basePhysicalStatus = base.physicalStatus; audit.jacobian = baseResult; audit.robustness = robustness;
audit.gaussNewtonEtaScaled = eta; audit.gaussNewtonDeltaZ = dz;
audit.linearPredictedResidualScaled = linearResidualScaled;
audit.linearPredictedResidualNormScaled = norm(linearResidualScaled);
audit.alphaToFirstBound = alphaBound;
audit.fullGaussNewtonStepWithinBounds = isfinite(alphaBound) && alphaBound >= 1;
audit.lineSearch = line; audit.bestSupportedLineSearchRawResidual = bestRaw;
audit.bestSupportedLineSearchIndex = bestIdx; audit.classification = classification;
audit.claimBoundary = 'LOCAL_TRIM_FEASIBILITY_DIAGNOSTIC_ONLY_NO_NEW_CONTROL_DOF_NO_MODEL_PARAMETER_CHANGE';

    function out = local_jacobian(stepFraction)
        h = stepFraction*scale; J = NaN(3,3);
        plusSupported = false(3,1); minusSupported = false(3,1);
        plusStatus = cell(3,1); minusStatus = cell(3,1);
        for j = 1:3
            zp = z; zm = z; zp(j) = zp(j)+h(j); zm(j) = zm(j)-h(j);
            [rp,plusSupported(j),plusStatus{j}] = eval_neighbor(zp);
            [rm,minusSupported(j),minusStatus{j}] = eval_neighbor(zm);
            if plusSupported(j) && minusSupported(j), J(:,j) = (rp-rm)/(2*h(j)); end
        end
        Jscaled = diag(1./residualScale)*J*diag(scale);
        out = matrix_report(J,Jscaled,h,plusSupported,minusSupported,plusStatus,minusStatus);
    end

    function [r,supported,status] = eval_neighbor(zn)
        r = NaN(3,1); supported = false; status = 'NOT_EVALUATED';
        if any(zn < definition.bounds(:,1) | zn > definition.bounds(:,2)), status = 'OUTSIDE_TRIM_BOUNDS'; return; end
        try
            pt = stage2_evaluate_trim_point(modelIdentity,condition,definition,zn,P);
            r = pt.residual; supported = pt.finiteReal && pt.physicalConverged && pt.physicalBranchSupported;
            status = pt.physicalStatus;
        catch ME
            status = ['ERROR:' ME.identifier];
        end
    end
end

function out = matrix_report(J,Jscaled,h,plusSupported,minusSupported,plusStatus,minusStatus)
out = struct(); out.step = h; out.Jraw = J; out.Jscaled = Jscaled;
out.plusSupported = plusSupported; out.minusSupported = minusSupported;
out.plusStatus = plusStatus; out.minusStatus = minusStatus;
out.allNeighborsSupported = all(plusSupported) && all(minusSupported);
out.finite = isreal(Jscaled) && all(isfinite(Jscaled(:)));
out.columnNormsRaw = sqrt(sum(J.^2,1)); out.columnNormsScaled = sqrt(sum(Jscaled.^2,1));
if out.finite
    [~,S,V] = svd(Jscaled); s = diag(S); tol = max(size(Jscaled))*eps(max(s));
    out.singularValuesScaled = s(:).'; out.rankToleranceScaled = tol; out.rankScaled = sum(s>tol);
    out.minRightSingularVectorScaled = V(:,end);
    if s(end) <= tol, out.conditionScaled = Inf; else, out.conditionScaled = s(1)/s(end); end
else
    out.singularValuesScaled = [NaN NaN NaN]; out.rankToleranceScaled = NaN; out.rankScaled = 0;
    out.minRightSingularVectorScaled = NaN(3,1); out.conditionScaled = Inf;
end
end

function alpha = max_feasible_alpha(z,dz,bounds)
alpha = Inf;
for i = 1:numel(z)
    if dz(i) > 0, alpha = min(alpha,(bounds(i,2)-z(i))/dz(i));
    elseif dz(i) < 0, alpha = min(alpha,(bounds(i,1)-z(i))/dz(i)); end
end
if alpha < 0, alpha = 0; end
end

function r = empty_robustness()
r = struct('stepFraction',NaN,'finite',false,'allNeighborsSupported',false, ...
    'supportedNeighborCount',0,'rankScaled',NaN,'conditionScaled',NaN, ...
    's1Scaled',NaN,'s2Scaled',NaN,'s3Scaled',NaN,'relativeDifferenceFromBase',NaN);
end

function r = empty_line()
r = struct('alpha',NaN,'withinBounds',false,'evaluationReturned',false, ...
    'physicalConverged',false,'physicalBranchSupported',false,'physicalStatus','NOT_RUN', ...
    'residualNormRaw',NaN,'residualNormScaled',NaN,'residual1',NaN,'residual2',NaN, ...
    'residual3',NaN,'z1',NaN,'z2',NaN,'z3',NaN,'cyclicLong',NaN,'elevator',NaN);
end
