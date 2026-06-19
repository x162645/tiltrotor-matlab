function [xTrim, uTrim, report] = trim_symmetric(V, betaM, P, opts)
%TRIM_SYMMETRIC Symmetric steady trim for the current 9-state model.
%
% Low-speed helicopter-mode trim variables:
%   z(1) = theta, rad
%   z(2) = collective, rad
%   z(3) = cyclicLong, rad
%
% Fixed quantities:
%   V, betaM, gamma are prescribed. Non-symmetric states and controls are
%   zero. Elevator, aileron and rudder are held at zero in this symmetric
%   helicopter trim closure.
%
% Trim equations:
%   [udot, wdot, qdot] = 0.

if nargin < 4
    opts = struct();
end

if ~isfield(opts, 'gamma')
    opts.gamma = 0;
end

if ~isfield(opts, 'initialDeg')
    if V < 1
        opts.initialDeg = [0, 18, 0];
    elseif betaM < pi/4
        opts.initialDeg = [4, 16, 2];
    else
        opts.initialDeg = [4, 8, -4];
    end
end

if numel(opts.initialDeg) < 3
    error('opts.initialDeg must contain [theta, collective, cyclicLong].');
end
if ~isfield(opts, 'thetaLimitDeg')
    opts.thetaLimitDeg = 35;
end
if ~isfield(opts, 'useMultiStart')
    opts.useMultiStart = true;
end
if ~isfield(opts, 'alwaysMultiStart')
    opts.alwaysMultiStart = false;
end

d2r = pi/180;
z0 = opts.initialDeg(1:3).'*d2r;
zScale = get_trim_variable_scale(P);
ySeed = ones(size(z0));
useHoverCollectiveOnly = V < 1e-9;
useDimensionlessSearch = ~useHoverCollectiveOnly;
thetaLim = opts.thetaLimitDeg*d2r*[-1, 1];

options = optimset( ...
    'Display', P.trim.display, ...
    'MaxIter', P.trim.maxIterations, ...
    'MaxFunEvals', 10*P.trim.maxIterations, ...
    'TolX', 1e-8, ...
    'TolFun', 1e-10);

invalidEvalCount = 0;
invalidEvalIdentifiers = {};
[zOpt, fval, exitflag, output, candidates] = solve_multistart(z0);

[xTrim, uTrim, residual, penalty, xdotFull, eomOut, penaltyBreakdown] = ...
    build_point(zOpt);
limitReport = make_limit_report(zOpt, uTrim);
residualScale = [P.env.g; P.env.g; 1.0];
scaledResidual = residual./residualScale;

report.residual = residual;
report.residualNorm = norm(residual);
report.residualLabels = {'udot'; 'wdot'; 'qdot'};
report.residualScale = residualScale;
report.residualScaleUnits = {'m/s^2'; 'm/s^2'; 'rad/s^2'};
report.scaledResidual = scaledResidual;
report.objectiveResidualCost = scaledResidual.'*scaledResidual;
report.fullStateDerivative = xdotFull;
report.fullResidualNorm = norm(xdotFull);
report.fullResidualLabels = {'udot'; 'vdot'; 'wdot'; 'pdot'; 'qdot'; ...
    'rdot'; 'phidot'; 'thetadot'; 'psidot'};
report.cost = fval;
report.penalty = penalty;
report.penaltyBreakdown = penaltyBreakdown;
report.objectiveCostReconstructed = report.objectiveResidualCost + penalty;
report.exitflag = exitflag;
report.output = output;
report.candidates = candidates;
report.candidateAcceptance = [candidates.acceptable].';
report.solverConverged = exitflag > 0;
report.finiteFullStateDerivative = is_real_finite(xdotFull);
report.limitReport = limitReport;
report.atLimit = limitReport.anyAtLimit;
report.withinLimits = ~limitReport.anyViolation;
report.converged = report.solverConverged && ...
    report.residualNorm < P.trim.residualTolerance && ...
    report.finiteFullStateDerivative && ...
    ~report.atLimit && report.withinLimits;
report.betaM = betaM;
report.V = V;
report.gamma = opts.gamma;
report.requestedInitialDeg = opts.initialDeg(1:3);
report.commandedControls = uTrim;
report.appliedControls = eomOut.components.appliedControls;
report.trimVariables = struct( ...
    'theta', zOpt(1), ...
    'collective', zOpt(2), ...
    'cyclicLong', zOpt(3));
report.trimVariableLabels = {'theta'; 'collective'; 'cyclicLong'};
if useHoverCollectiveOnly
    report.searchVariable = 'physical-rad-hover-collective';
    report.searchMapping = 'xTrim = [0; collective; 0] at exact V=0 symmetric hover';
elseif useDimensionlessSearch
    report.searchVariable = 'dimensionless';
    report.searchMapping = 'xTrim = xSeed + variableScale.*(y - ones(3,1))';
else
    report.searchVariable = 'physical-rad';
    report.searchMapping = 'xTrim = z';
end
report.dimensionlessInitial = ySeed;
report.trimVariableScale = zScale;
report.trimVariableScaleUnits = 'rad';
report.trimVariableScaleClassification = 'NUMERICAL';
report.initialSimplexPhysicalStep = 0.05*zScale;
report.initialSimplexPhysicalStepUnits = 'rad';
report.objectiveInvalidEvaluationCount = invalidEvalCount;
report.objectiveInvalidEvaluationIdentifiers = unique(invalidEvalIdentifiers);

    function z = trim_from_y(y, seedZ)
        z = seedZ(:) + zScale.*(y(:)-ySeed);
    end

    function J = trim_cost_from_y(y, seedZ)
        J = trim_cost(trim_from_y(y, seedZ));
    end

    function J = trim_cost(z)
        try
            [~, ~, R, thisPenalty] = build_point(z);
        catch ME
            if is_objective_domain_error(ME)
                note_invalid_eval(ME);
                J = 1.0e30;
                return;
            end
            rethrow(ME);
        end
        if ~is_real_finite(R) || ~isfinite(thisPenalty)
            invalidEvalCount = invalidEvalCount + 1;
            invalidEvalIdentifiers{end+1} = 'trim_symmetric:NonFiniteObjective';
            J = 1.0e30;
            return;
        end
        scale = [P.env.g; P.env.g; 1.0];
        Rs = R./scale;
        J = Rs.'*Rs + thisPenalty;
    end

    function [xCandidate, uCandidate, R, thisPenalty, xdot, thisEomOut, ...
            thisPenaltyBreakdown] = build_point(z)
        theta = z(1);
        collective = z(2);
        cyclicLong = z(3);

        alpha = theta - opts.gamma;

        if V < 1e-10
            u = 0;
            w = 0;
        else
            u = V*cos(alpha);
            w = V*sin(alpha);
        end

        xCandidate = [u; 0; w; 0; 0; 0; 0; theta; 0];
        uCandidate = [collective; 0; cyclicLong; 0; 0; 0; 0];

        [xd, thisEomOut] = tiltrotor_eom(xCandidate, uCandidate, betaM, P);
        xdot = xd(:);
        R = [xdot(1); xdot(3); xdot(5)];

        thisPenaltyBreakdown.collective = bound_penalty(collective, ...
            P.control.collectiveLim);
        thisPenaltyBreakdown.cyclicLong = bound_penalty(cyclicLong, ...
            P.control.cyclicLim);
        thisPenaltyBreakdown.theta = 10*bound_penalty(theta, thetaLim);
        thisPenalty = thisPenaltyBreakdown.collective + ...
            thisPenaltyBreakdown.cyclicLong + thisPenaltyBreakdown.theta;
    end

    function value = bound_penalty(xValue, limits)
        below = max(limits(1)-xValue, 0);
        above = max(xValue-limits(2), 0);
        value = 100*(below^2 + above^2);
    end

    function [bestZ, bestCost, bestExitflag, bestOutput, records] = ...
            solve_multistart(primaryZ0)
        starts = make_initial_candidates(primaryZ0);
        nStart = size(starts, 2);
        records = repmat(struct( ...
            'initialDeg', zeros(1,3), ...
            'solutionDeg', zeros(1,3), ...
            'cost', NaN, ...
            'residualNorm', NaN, ...
            'exitflag', NaN, ...
            'acceptable', false, ...
            'atLimit', false, ...
            'withinLimits', false), nStart, 1);

        bestCost = Inf;
        bestResidualNorm = Inf;
        bestZ = primaryZ0;
        bestExitflag = -Inf;
        bestOutput = struct();

        for iStart = 1:nStart
            zi = starts(:, iStart);
            if useHoverCollectiveOnly
                zi = [0; zi(2); 0];
                [collectiveCandidate, costCandidate, exitCandidate, outputCandidate] = ...
                    fminbnd(@(c) trim_cost([0; c; 0]), ...
                    P.control.collectiveLim(1), P.control.collectiveLim(2), options);
                zCandidate = [0; collectiveCandidate(1); 0];
                yCandidate = NaN(size(ySeed));
            elseif useDimensionlessSearch
                [yCandidate, costCandidate, exitCandidate, outputCandidate] = ...
                    fminsearch(@(y) trim_cost_from_y(y, zi), ySeed, options);
                zCandidate = trim_from_y(yCandidate, zi);
            else
                [zCandidate, costCandidate, exitCandidate, outputCandidate] = ...
                    fminsearch(@(z) trim_cost(z), zi, options);
                yCandidate = NaN(size(ySeed));
            end
            [~, uc, rc, ~, xd] = build_point(zCandidate);
            rn = norm(rc);
            candidateLimits = make_limit_report(zCandidate, uc);

            records(iStart).initialDeg = zi(:).'/d2r;
            records(iStart).solutionDeg = zCandidate(:).'/d2r;
            records(iStart).initialY = ySeed(:).';
            records(iStart).solutionY = yCandidate(:).';
            records(iStart).cost = costCandidate;
            records(iStart).residualNorm = rn;
            records(iStart).exitflag = exitCandidate;

            better = costCandidate < bestCost || ...
                (abs(costCandidate-bestCost) < 1e-14 && rn < bestResidualNorm);
            if better
                bestCost = costCandidate;
                bestResidualNorm = rn;
                bestZ = zCandidate;
                bestExitflag = exitCandidate;
                bestOutput = outputCandidate;
            end

            acceptable = exitCandidate > 0 && ...
                rn < P.trim.residualTolerance && ...
                is_real_finite(xd) && ...
                ~candidateLimits.anyAtLimit && ...
                ~candidateLimits.anyViolation;
            records(iStart).acceptable = acceptable;
            records(iStart).atLimit = candidateLimits.anyAtLimit;
            records(iStart).withinLimits = ~candidateLimits.anyViolation;
            if acceptable && ~opts.alwaysMultiStart
                break;
            end
        end
    end

    function starts = make_initial_candidates(primaryZ0)
        starts = primaryZ0(:);
        if ~opts.useMultiStart || V < 1e-9
            return;
        end

        baseDeg = primaryZ0(:).'/d2r;
        collectiveDeg = baseDeg(2);
        forwardSeedsDeg = [
             baseDeg(1), collectiveDeg, baseDeg(3);
             baseDeg(1)+4, collectiveDeg, baseDeg(3)+2;
             baseDeg(1)-4, collectiveDeg, baseDeg(3)-2;
             4, 16, 2;
             6, 16, 3];
        starts = unique(round(forwardSeedsDeg, 10), 'rows', 'stable').'*d2r;
    end

    function limitReport = make_limit_report(z, uCtrl)
        tol = 1.0e-8;
        names = {'theta'; 'collective'; 'cyclicLong'};
        values = [z(1); uCtrl(1); uCtrl(3)];
        lower = [thetaLim(1); P.control.collectiveLim(1); ...
            P.control.cyclicLim(1)];
        upper = [thetaLim(2); P.control.collectiveLim(2); ...
            P.control.cyclicLim(2)];
        entries = repmat(struct('name', '', 'value', NaN, ...
            'lower', NaN, 'upper', NaN, 'atLower', false, ...
            'atUpper', false, 'atLimit', false, 'violated', false), ...
            numel(names), 1);

        for i = 1:numel(names)
            entries(i).name = names{i};
            entries(i).value = values(i);
            entries(i).lower = lower(i);
            entries(i).upper = upper(i);
            entries(i).atLower = abs(values(i)-lower(i)) <= tol;
            entries(i).atUpper = abs(values(i)-upper(i)) <= tol;
            entries(i).atLimit = entries(i).atLower || entries(i).atUpper;
            entries(i).violated = values(i) < lower(i)-tol || ...
                values(i) > upper(i)+tol;
        end

        limitReport.items = entries;
        limitReport.anyAtLimit = any([entries.atLimit]);
        limitReport.anyViolation = any([entries.violated]);
    end

    function tf = is_real_finite(value)
        tf = isreal(value) && all(isfinite(value(:)));
    end

    function note_invalid_eval(ME)
        invalidEvalCount = invalidEvalCount + 1;
        invalidEvalIdentifiers{end+1} = ME.identifier;
    end

    function tf = is_objective_domain_error(ME)
        tf = strcmp(ME.identifier, 'rotor_model_bemt:FlapNotConverged') || ...
            strcmp(ME.identifier, 'rotor_model_bemt:CoupledSolveNotConverged');
    end

    function scale = get_trim_variable_scale(params)
        if ~isfield(params, 'trim') || ~isfield(params.trim, 'variableScale')
            error('P.trim.variableScale must define [theta; collective; cyclicLong] search scales in rad.');
        end
        scale = params.trim.variableScale(:);
        if numel(scale) ~= 3 || ~is_real_finite(scale) || any(scale <= 0)
            error('P.trim.variableScale must be a finite positive 3-vector in rad.');
        end
    end
end
