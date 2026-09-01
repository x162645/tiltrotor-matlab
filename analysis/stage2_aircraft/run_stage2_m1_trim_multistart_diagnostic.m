function results = run_stage2_m1_trim_multistart_diagnostic(outputRoot)
%RUN_STAGE2_M1_TRIM_MULTISTART_DIAGNOSTIC Diagnose M1 trim seed sensitivity.
%
% This is a numerical/feasibility diagnostic only. It does not replace the
% canonical primary trim solves in run_stage2_trim_comparison and it does not
% select a model parameter or physical correction from validation error.
%
% For each frozen representative condition, use nine predeclared seeds:
%   1 canonical production trim seed;
%   2 credible M0 trim;
%   3 midpoint of canonical and M0 seeds;
%   4-9 M0 trim +/- 0.5 existing variableScale on each trim coordinate.
% All seeds are clipped to the existing production trim bounds. No result is
% fed back into M1_EVIDENCE_V1 or the primary propagation comparison.

if nargin < 1 || isempty(outputRoot)
    outputRoot = fullfile(pwd,'results','stage2_m1_trim_multistart');
end
if ~exist(outputRoot,'dir'), mkdir(outputRoot); end

P = stage2_matched_rotor_parameters();
d2r = pi/180;
conditions = repmat(struct('name','','V',NaN,'betaM',NaN,'gamma',0,'mode',''),3,1);
conditions(1) = struct('name','B15_V020','V',20,'betaM',15*d2r,'gamma',0, ...
    'mode','helicopter_longitudinal');
conditions(2) = struct('name','B45_V035','V',35,'betaM',45*d2r,'gamma',0, ...
    'mode','conversion_longitudinal');
conditions(3) = struct('name','B75_V080','V',80,'betaM',75*d2r,'gamma',0, ...
    'mode','airplane_longitudinal');

rows = repmat(empty_row(),27,1);
reports = cell(3,9);
summaryRows = repmat(empty_summary(),3,1);
rowIdx = 0;

for i = 1:numel(conditions)
    condition = conditions(i);
    [~,~,r0] = stage2_trim_longitudinal('M0_MATCHED_PRODUCTION',condition,P, ...
        struct('mode',condition.mode));
    assert(r0.credible, 'run_stage2_m1_trim_multistart_diagnostic:M0NotCredible', ...
        'M0 reference trim must remain credible for %s.', condition.name);

    definition = r0.definition;
    canonical = definition.initialValues(:);
    m0seed = r0.trimVariableVector(:);
    scale = definition.variableScale(:);
    n = numel(canonical);
    assert(n == 3, 'run_stage2_m1_trim_multistart_diagnostic:UnexpectedTrimDimension', ...
        'Expected three trim variables for %s.', condition.name);

    seeds = NaN(n,9);
    labels = cell(1,9);
    seeds(:,1) = canonical; labels{1} = 'CANONICAL';
    seeds(:,2) = m0seed; labels{2} = 'M0_TRIM';
    seeds(:,3) = 0.5*(canonical+m0seed); labels{3} = 'CANONICAL_M0_MIDPOINT';
    col = 3;
    for k = 1:n
        col = col+1;
        seeds(:,col) = m0seed; seeds(k,col) = seeds(k,col)+0.5*scale(k);
        labels{col} = sprintf('M0_PLUS_HALF_SCALE_%s',upper(definition.unknownNames{k}));
        col = col+1;
        seeds(:,col) = m0seed; seeds(k,col) = seeds(k,col)-0.5*scale(k);
        labels{col} = sprintf('M0_MINUS_HALF_SCALE_%s',upper(definition.unknownNames{k}));
    end
    for j = 1:size(seeds,2)
        seeds(:,j) = min(max(seeds(:,j),definition.bounds(:,1)),definition.bounds(:,2));
    end

    bestResidual = Inf;
    bestSeed = '';
    credibleCount = 0;
    supportedPhysicalCount = 0;
    returnedCount = 0;

    for j = 1:9
        rowIdx = rowIdx+1;
        row = empty_row();
        row.caseName = condition.name;
        row.mode = condition.mode;
        row.seedLabel = labels{j};
        row.seed1 = seeds(1,j); row.seed2 = seeds(2,j); row.seed3 = seeds(3,j);
        row.seedVariable1 = definition.unknownNames{1};
        row.seedVariable2 = definition.unknownNames{2};
        row.seedVariable3 = definition.unknownNames{3};
        opts = struct('mode',condition.mode,'initialValues',seeds(:,j));
        try
            [x,u,r] = stage2_trim_longitudinal('M1_EVIDENCE_V1_PROPAGATION',condition,P,opts);
            reports{i,j} = r;
            returnedCount = returnedCount+1;
            row.solveReturned = true;
            row.solverConverged = logical(r.solverConverged);
            row.physicalConverged = logical(r.physicalConverged);
            row.physicalBranchSupported = logical(r.physicalBranchSupported);
            row.credible = logical(r.credible);
            row.residualNorm = r.residualNorm;
            row.residual1 = r.residual(1);
            row.residual2 = r.residual(2);
            row.residual3 = r.residual(3);
            row.physicalStatus = r.physicalStatus;
            row.invalidEvaluationCount = r.invalidEvaluationCount;
            row.theta_deg = x(8)/d2r;
            row.collective_deg = u(1)/d2r;
            row.cyclicLong_deg = u(3)/d2r;
            row.elevator_deg = u(6)/d2r;
            row.status = classify_report(r,P);
            if r.physicalConverged && r.physicalBranchSupported
                supportedPhysicalCount = supportedPhysicalCount+1;
                if isfinite(r.residualNorm) && r.residualNorm < bestResidual
                    bestResidual = r.residualNorm;
                    bestSeed = labels{j};
                end
            end
            if r.credible, credibleCount = credibleCount+1; end
        catch ME
            if is_expected_model_domain_error(ME)
                row.status = ['MODEL_DOMAIN_ERROR:' ME.identifier];
                row.physicalStatus = ME.identifier;
                reports{i,j} = ME;
            else
                rethrow(ME);
            end
        end
        rows(rowIdx) = row;
    end

    s = empty_summary();
    s.caseName = condition.name;
    s.returnedCount = returnedCount;
    s.supportedPhysicalCount = supportedPhysicalCount;
    s.credibleCount = credibleCount;
    if isfinite(bestResidual)
        s.bestSupportedResidualNorm = bestResidual;
        s.bestSupportedSeed = bestSeed;
    end
    if credibleCount > 0
        s.classification = 'CREDIBLE_M1_TRIM_EXISTS_IN_PREDECLARED_LOCAL_MULTISTART';
    elseif supportedPhysicalCount > 0
        s.classification = 'NO_CREDIBLE_TRIM_FOUND_SUPPORTED_LOCAL_SOLVES_REMAIN_RESIDUAL_LIMITED';
    else
        s.classification = 'NO_SUPPORTED_LOCAL_M1_SOLVE_FOUND';
    end
    summaryRows(i) = s;
end

points = struct2table(rows);
summary = struct2table(summaryRows);
writetable(points,fullfile(outputRoot,'STAGE2_M1_MULTISTART_POINTS.csv'));
writetable(summary,fullfile(outputRoot,'STAGE2_M1_MULTISTART_SUMMARY.csv'));

results = struct();
results.points = points;
results.summary = summary;
results.reports = reports;
results.seedContract = 'CANONICAL__M0__MIDPOINT__M0_PLUS_MINUS_HALF_EXISTING_SCALE_PER_VARIABLE';
results.claimBoundary = 'NUMERICAL_FEASIBILITY_DIAGNOSTIC_ONLY_NOT_PRIMARY_TRIM_REPLACEMENT';
save(fullfile(outputRoot,'STAGE2_M1_MULTISTART_DIAGNOSTIC.mat'),'results');

disp(points);
disp(summary);
end

function status = classify_report(report,P)
if report.credible
    status = 'CREDIBLE';
elseif ~report.solverConverged
    status = 'SOLVER_NOT_CONVERGED';
elseif ~report.physicalConverged || ~report.physicalBranchSupported
    status = ['PHYSICAL:' report.physicalStatus];
elseif report.atLimit || ~report.withinLimits
    status = 'BOUNDARY_LIMITED';
elseif report.residualNorm >= P.trim.residualTolerance
    status = 'RESIDUAL_FAILED';
else
    status = 'NONCREDIBLE_UNCLASSIFIED';
end
end

function tf = is_expected_model_domain_error(ME)
tf = startsWith(ME.identifier,'m1_evidence_v1_forward_rotor:') || ...
    startsWith(ME.identifier,'rotor_model_bemt:') || ...
    strcmp(ME.identifier,'pitch_allocation_schedule:InvalidPitchCommand');
end

function row = empty_row()
row = struct('caseName','','mode','','seedLabel','','seedVariable1','', ...
    'seedVariable2','','seedVariable3','','seed1',NaN,'seed2',NaN,'seed3',NaN, ...
    'solveReturned',false,'solverConverged',false,'physicalConverged',false, ...
    'physicalBranchSupported',false,'credible',false,'residualNorm',NaN, ...
    'residual1',NaN,'residual2',NaN,'residual3',NaN,'physicalStatus','NOT_RUN', ...
    'invalidEvaluationCount',NaN,'theta_deg',NaN,'collective_deg',NaN, ...
    'cyclicLong_deg',NaN,'elevator_deg',NaN,'status','NOT_RUN');
end

function s = empty_summary()
s = struct('caseName','','returnedCount',0,'supportedPhysicalCount',0, ...
    'credibleCount',0,'bestSupportedResidualNorm',NaN,'bestSupportedSeed','', ...
    'classification','NOT_RUN');
end
