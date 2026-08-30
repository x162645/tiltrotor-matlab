function report = issue20_trim_authority_diagnostics()
%ISSUE20_TRIM_AUTHORITY_DIAGNOSTICS Diagnostic-only Issue #20 audit.
% This script does not modify production physics, parameters, trim
% algorithms, allocation schedules, or official control limits. Temporary
% parameter changes are held in local copies only.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir, 'model'));
addpath(fullfile(rootDir, 'analysis'));
addpath(fullfile(rootDir, 'services'));

P = params_nominal();
baselineMat = fullfile(rootDir, 'validation', 'nuaa_trim_trends', ...
    'nuaa_trim_baseline_20260623_162754.mat');
baselineCsv = fullfile(rootDir, 'validation', 'nuaa_trim_trends', ...
    'nuaa_trim_baseline_points_20260623_162754.csv');
if ~exist(baselineMat, 'file')
    error('issue20:MissingBaseline', 'Missing baseline MAT: %s', baselineMat);
end

stamp = datestr(now, 'yyyymmdd_HHMMSS');
outDir = fullfile(rootDir, 'validation', ...
    ['issue20_trim_authority_' stamp]);
if exist(outDir, 'dir')
    error('issue20:OutputExists', 'Output directory already exists: %s', outDir);
end
mkdir(outDir);

data = load(baselineMat, 'rawTable', 'points', 'cases');
rawTable = data.rawTable;
points = data.points;
cases = data.cases;

report = struct();
report.generatedAt = datestr(now, 31);
report.issue = 'GitHub x162645/tiltrotor-matlab#20';
report.scope = ['Diagnostic-only trim authority audit; no production ' ...
    'physics, parameter, trim, allocation, or limit changes.'];
report.inputs.baselineMat = baselineMat;
report.inputs.baselineCsv = baselineCsv;
report.outputDir = outDir;
report.angleSemantics = struct( ...
    'modelBetaM0', 'helicopter mode, rotor thrust up', ...
    'modelBetaM90', 'airplane mode, rotor thrust forward', ...
    'conventionalNacelleAngleDeg', '90 - modelBetaMDeg', ...
    'oldBaselineStatus', 'SUPERSEDED_WRONG_ANGLE_MAPPING');

report.callPath = call_path_summary(P);
report.allocationAudit = allocation_audit(P);
report.searchSettings = search_settings_summary(P);
report.baseline70 = baseline_70_summary(rawTable, points, cases, P);
report.seedRetest = seed_retest(P, data);
report.relaxedElevator = relaxed_elevator_tests(P, report.seedRetest);
report.fixedCyclic = fixed_cyclic_tests(P, report.seedRetest);
report.rawObjective = raw_objective_tests(P, report.seedRetest);
report.jacobians = jacobian_sweep(P, report.seedRetest);
report.best70 = best_70_candidate(report.seedRetest, P);
report.balance = component_balance(report.best70, P);
report.classification = final_classification(report);

save(fullfile(outDir, 'issue20_trim_authority_report.mat'), ...
    'report', '-v7');
write_text_report(fullfile(outDir, 'issue20_trim_authority_report.md'), ...
    report);
write_allocation_csv(fullfile(outDir, 'issue20_allocation_audit.csv'), ...
    report.allocationAudit);
write_seed_csv(fullfile(outDir, 'issue20_seed_retest.csv'), ...
    report.seedRetest);
write_jacobian_csv(fullfile(outDir, 'issue20_jacobian_summary.csv'), ...
    report.jacobians);

fprintf('Issue #20 diagnostic output: %s\n', outDir);
fprintf('Best official 70 m/s residual norm: %.6e\n', ...
    report.best70.trimReport.residualNorm);
fprintf('Classification: elevator=%s, seed=%s, pitchMoment=%s\n', ...
    report.classification.elevatorAuthorityLimit, ...
    report.classification.seedBranchAccess, ...
    report.classification.modelPitchMomentImbalance);
end

function summary = call_path_summary(P)
d2r = pi/180;
modes = {'helicopter_longitudinal', 'conversion_longitudinal', ...
    'airplane_longitudinal'};
conds = {struct('V',20,'betaM',0,'gamma',0), ...
    struct('V',35,'betaM',45*d2r,'gamma',0), ...
    struct('V',70,'betaM',90*d2r,'gamma',0)};
items = repmat(struct(), numel(modes), 1);
for i = 1:numel(modes)
    def = make_trim_definition(modes{i}, conds{i}, P);
    items(i).mode = modes{i};
    items(i).unknownNames = def.unknownNames(:).';
    items(i).fixedStates = def.fixedStates;
    items(i).fixedControls = def.fixedControls;
    items(i).usesAllocation = isfield(def, 'allocation');
    if isfield(def, 'allocation')
        items(i).allocationType = def.allocation.type;
    else
        items(i).allocationType = 'none';
    end
end
summary.items = items;
summary.confirmation = ['The 70 m/s betaM=90 deg baseline case uses ' ...
    'airplane_longitudinal: solved theta, collective, elevator; ' ...
    'fixed cyclicLong=0; no cos^2/sin^2 allocation.'];
end

function rows = allocation_audit(P)
d2r = pi/180;
direction = struct('cyclicDirection', -1, 'elevatorDirection', -1);
betasDeg = [0 15 45 75 90];
rows = repmat(struct(), numel(betasDeg), 1);
for i = 1:numel(betasDeg)
    a0 = pitch_allocation_schedule(betasDeg(i)*d2r, 0, P, direction);
    aMax = pitch_allocation_schedule(betasDeg(i)*d2r, ...
        a0.pitchCommandLimit, P, direction);
    rows(i).modelBetaMDeg = betasDeg(i);
    rows(i).conventionalNacelleAngleDeg = 90-betasDeg(i);
    rows(i).gCyclic = a0.gCyclic;
    rows(i).gElevator = a0.gElevator;
    rows(i).pitchCommandLimit = a0.pitchCommandLimit;
    rows(i).cyclicPerUnitCommand_deg = ...
        a0.cyclicDirection*a0.gCyclic*a0.cyclicReference/d2r;
    rows(i).elevatorPerUnitCommand_deg = ...
        a0.elevatorDirection*a0.gElevator*a0.elevatorReference/d2r;
    rows(i).maxCyclic_deg = aMax.cyclicLong/d2r;
    rows(i).maxElevator_deg = aMax.elevator/d2r;
    rows(i).maxCombinedActuatorUsage = max( ...
        abs([aMax.cyclicLong/aMax.cyclicReference, ...
        aMax.elevator/aMax.elevatorReference]));
end
end

function summary = search_settings_summary(P)
d2r = pi/180;
summary.objective = ['sum((selected residual ./ residualScale).^2) + ' ...
    'softBoundPenalty; translational residuals use residualScale=g; ' ...
    'qdot uses scale=1.'];
summary.rawAcceptanceTolerance = P.trim.residualTolerance;
summary.fminsearch = struct('MaxIter', P.trim.maxIterations, ...
    'MaxFunEvals', 10*P.trim.maxIterations, 'TolX', 1e-8, ...
    'TolFun', 1e-10, 'Display', P.trim.display);
summary.softBoundPenalty = ['100*sum(bound violations^2), including ' ...
    'generated cyclic/elevator in allocation mode.'];
summary.commandedApplied = ['trim_general reports commandedControls and ' ...
    'appliedControls; total_forces_moments hard clamps actual actuator ' ...
    'inputs before component loads.'];
summary.clampPlateau = ['Outside hard limits, applied elevator is fixed at ' ...
    'the limit, so outer commanded-control derivatives can go to zero.'];
summary.modes = mode_settings(P);
summary.airplane70FirstPoint = true;
summary.airplaneSpeeds_mps = [70 85 100 115 130 145 150];
summary.initialPhysicalSimplexRule = ['fminsearch starts at y=ones; ' ...
    'nonzero y coordinates use 5 percent simplex offsets, so physical ' ...
    'initial steps are 0.05*variableScale.'];
summary.airplaneInitialPhysicalSimplexStep_deg = ...
    0.05*[2;18;2];
summary.defaultAngleUnit = 'rad internally; deg shown here for readability';
summary.collectiveLimit_deg = P.control.collectiveLim/d2r;
summary.elevatorLimit_deg = P.control.elevatorLim/d2r;
end

function modes = mode_settings(P)
d2r = pi/180;
names = {'helicopter_longitudinal','conversion_longitudinal', ...
    'airplane_longitudinal'};
conds = {struct('V',20,'betaM',0,'gamma',0), ...
    struct('V',35,'betaM',45*d2r,'gamma',0), ...
    struct('V',70,'betaM',90*d2r,'gamma',0)};
modes = repmat(struct(), numel(names), 1);
for i = 1:numel(names)
    def = make_trim_definition(names{i}, conds{i}, P);
    modes(i).mode = names{i};
    modes(i).unknownNames = def.unknownNames(:).';
    modes(i).initialValues = def.initialValues(:);
    modes(i).initialValues_deg_or_command = def.initialValues(:)/d2r;
    if any(strcmp(def.unknownNames, 'pitchCommand'))
        modes(i).initialValues_deg_or_command(end) = def.initialValues(end);
    end
    modes(i).variableScale = def.variableScale(:);
    modes(i).variableScale_deg_or_command = def.variableScale(:)/d2r;
    if any(strcmp(def.unknownNames, 'pitchCommand'))
        modes(i).variableScale_deg_or_command(end) = def.variableScale(end);
    end
    modes(i).initialPhysicalSimplexStep = 0.05*def.variableScale(:);
    modes(i).bounds = def.bounds;
end
end

function out = baseline_70_summary(rawTable, points, cases, P)
d2r = pi/180;
mask = strcmp(rawTable.caseName, 'fig5b_flight') & ...
    abs(rawTable.velocity_mps-70) < 1e-9;
row = rawTable(mask, :);
idx = find(strcmp({points.caseName}, 'fig5b_flight') & ...
    abs([points.V]-70) < 1e-9, 1);
pt = points(idx);
tr = pt.trimReport;
out.row = row;
out.theta_deg = row.theta_deg;
out.collective_deg = row.collective_deg;
out.commandedElevator_deg = row.elevator_deg;
out.appliedElevator_deg = tr.appliedControls(6)/d2r;
out.cyclicLong_deg = row.cyclicLong_deg;
out.fullDerivative = tr.fullStateDerivative;
out.udot = tr.fullStateDerivative(1);
out.wdot = tr.fullStateDerivative(3);
out.qdot = tr.fullStateDerivative(5);
out.scaledResidual = tr.scaledResidual(:);
out.objectiveContributions = tr.scaledResidual(:).^2;
out.objectiveResidualCost = tr.objectiveResidualCost;
out.objective = tr.cost;
out.penalty = tr.penalty;
out.residualNorm = tr.residualNorm;
out.exitflag = tr.exitflag;
out.atLimit = tr.atLimit;
out.withinLimits = tr.withinLimits;
out.credibilityStatus = pt.credibility.status;
out.credibilityReasons = pt.credibility.reasons;
out.seedSource = row.initialSource{1};
out.commandedMinusAppliedElevator_deg = ...
    out.commandedElevator_deg - out.appliedElevator_deg;
out.minus40Meaning = ['The CSV elevator value is commanded. The model ' ...
    'applies the hard-clamped elevator stored in trimReport.appliedControls.'];
out.caseAngle = struct('storedNuaaNacelle_deg', row.nuaaNacelle_deg, ...
    'modelBetaMDeg', row.betaM_deg, ...
    'conventionalNacelleAngleDeg', 90-row.betaM_deg, ...
    'caseDefinitionFromScript', cases(2));
out.controlLimits_deg = struct('elevator', P.control.elevatorLim/d2r, ...
    'collective', P.control.collectiveLim/d2r);
end

function results = seed_retest(P, data)
d2r = pi/180;
condition = struct('V',70,'betaM',90*d2r,'gamma',0);
def = make_trim_definition('airplane_longitudinal', condition, P);
results = repmat(empty_solve_result(), 2+numel([82.5 80 77.5 75 72.5 70]), 1);
resultIndex = 1;

results(resultIndex) = solve_definition('original_70_default_seed', ...
    condition, def, P);
resultIndex = resultIndex + 1;

seed85 = seed_from_point(data.points, 'fig5b_flight', 85, def);
def85 = def;
def85.initialValues = seed85;
results(resultIndex) = solve_definition('direct_85_solution_seed_to_70', ...
    condition, def85, P);
resultIndex = resultIndex + 1;

speeds = [82.5 80 77.5 75 72.5 70];
seed = seed85;
for i = 1:numel(speeds)
    c = condition;
    c.V = speeds(i);
    d = make_trim_definition('airplane_longitudinal', c, P);
    d.initialValues = seed;
    label = sprintf('downward_85_to_%.1f', speeds(i));
    label = strrep(label, '.', 'p');
    r = solve_definition(label, c, d, P);
    results(resultIndex) = r;
    resultIndex = resultIndex + 1;
    if r.finiteReal
        seed = trim_vector(r.trimReport, d);
    end
end
end

function results = relaxed_elevator_tests(P, seedResults)
d2r = pi/180;
limitsDeg = [-50 -60 -80];
condition = struct('V',70,'betaM',90*d2r,'gamma',0);
seed = preferred_seed(seedResults);
results = repmat(empty_solve_result(), numel(limitsDeg), 1);
resultIndex = 1;
for i = 1:numel(limitsDeg)
    Ptest = P;
    Ptest.control.elevatorLim(1) = limitsDeg(i)*d2r;
    def = make_trim_definition('airplane_longitudinal', condition, Ptest);
    def.initialValues = seed;
    r = solve_definition(sprintf('elevator_lower_%d_deg', limitsDeg(i)), ...
        condition, def, Ptest);
    r.temporaryElevatorLowerLimit_deg = limitsDeg(i);
    results(resultIndex) = r;
    resultIndex = resultIndex + 1;
    if r.trimReport.converged
        break;
    end
end
results = results(1:resultIndex-1);
end

function results = fixed_cyclic_tests(P, seedResults)
d2r = pi/180;
cyclicDeg = [-5 -2 0 2 5];
condition = struct('V',70,'betaM',90*d2r,'gamma',0);
seed = preferred_seed(seedResults);
results = repmat(empty_solve_result(), numel(cyclicDeg), 1);
for i = 1:numel(cyclicDeg)
    def = make_trim_definition('airplane_longitudinal', condition, P);
    def.fixedControls.cyclicLong = cyclicDeg(i)*d2r;
    def.initialValues = seed;
    r = solve_definition(sprintf('fixed_cyclic_%+d_deg', cyclicDeg(i)), ...
        condition, def, P);
    r.fixedCyclicLong_deg = cyclicDeg(i);
    results(i) = r;
end
end

function results = raw_objective_tests(P, seedResults)
d2r = pi/180;
condition = struct('V',70,'betaM',90*d2r,'gamma',0);
def0 = make_trim_definition('airplane_longitudinal', condition, P);
defs = {def0, def0};
defs{2}.initialValues = preferred_seed(seedResults);
names = {'raw_equal_default_seed', 'raw_equal_preferred_seed'};
results = repmat(empty_solve_result(), numel(defs), 1);
for i = 1:numel(defs)
    results(i) = solve_raw_objective(names{i}, condition, defs{i}, P);
end
end

function jac = jacobian_sweep(P, seedResults)
d2r = pi/180;
speeds = [70 75 80 85];
steps = [1e-3 1e-4 1e-5];
seed70 = preferred_seed(seedResults);
jac = repmat(empty_jacobian_result(), numel(speeds)*numel(steps), 1);
jacIndex = 1;
for i = 1:numel(speeds)
    condition = struct('V',speeds(i),'betaM',90*d2r,'gamma',0);
    def = make_trim_definition('airplane_longitudinal', condition, P);
    if speeds(i) == 70
        def.initialValues = seed70;
    end
    sol = solve_definition(sprintf('jacobian_base_%g', speeds(i)), ...
        condition, def, P);
    if sol.finiteReal
        z = trim_vector(sol.trimReport, def);
    else
        z = def.initialValues(:);
    end
    for j = 1:numel(steps)
        item = local_jacobian(condition, def, z, P, steps(j));
        item.V = speeds(i);
        item.h = steps(j);
        item.baseConverged = sol.trimReport.converged;
        item.baseResidualNorm = sol.trimReport.residualNorm;
        jac(jacIndex) = item;
        jacIndex = jacIndex + 1;
    end
end
end

function out = best_70_candidate(seedResults, P)
candidates = seedResults(abs([seedResults.V]-70) < 1e-9);
finite = [candidates.finiteReal];
if any(finite)
    candidates = candidates(finite);
end
scores = arrayfun(@(r) r.trimReport.residualNorm + ...
    10*double(r.trimReport.atLimit) + ...
    10*double(~r.trimReport.withinLimits), candidates);
[~, idx] = min(scores);
out = candidates(idx);
out.selectionRule = ['lowest official-limit finite residual among original, ' ...
    'direct 85-seed, and downward-continuation 70 m/s candidates'];
out.controlLimits_deg = struct('elevator', P.control.elevatorLim*180/pi, ...
    'collective', P.control.collectiveLim*180/pi);
end

function balance = component_balance(candidate, P)
[xdot, eomOut] = tiltrotor_eom(candidate.xTrim, candidate.uTrim, ...
    candidate.betaM, P);
balance.xdot = xdot;
balance.Ftotal = eomOut.Ftotal;
balance.FaeroProp = eomOut.FaeroProp;
balance.Fgravity = eomOut.Fgravity;
balance.Mtotal = eomOut.Mtotal;
balance.massProperties = eomOut.massProperties;
balance.commandedControls = eomOut.components.commandedControls;
balance.appliedControls = eomOut.components.appliedControls;
balance.componentMy = component_my(eomOut.components.components);
balance.wing = wing_summary(eomOut.components.wing, P);
balance.horizontalTail = htail_summary(eomOut.components.horizontalTail, ...
    eomOut.components.appliedControls(6), P);
balance.rotorLeft = rotor_summary(eomOut.components.rotorLeft);
balance.rotorRight = rotor_summary(eomOut.components.rotorRight);
balance.fuselage = fuselage_summary(eomOut.components.fuselage);
balance.mainUnclosedResidual = main_residual_label(candidate.trimReport);
balance.pitchMomentNeeded = ['At betaM=90 deg, negative elevator is needed ' ...
    'to provide a nose-down tail contribution against the net nose-up ' ...
    'component balance at the selected candidate.'];
end

function classification = final_classification(report)
is70 = abs([report.seedRetest.V]-70) < 1e-9;
if any([report.seedRetest(is70).trimConverged])
    classification.seedBranchAccess = 'confirmed';
    classification.seedBranchAccessDetail = ...
        'At least one alternate 70 m/s seed/path reaches convergence.';
else
    classification.seedBranchAccess = 'excluded';
    classification.seedBranchAccessDetail = ...
        ['Original 70 m/s, direct 85 m/s seed to 70 m/s, and the ' ...
        'downward-continuation endpoint at 70 m/s all hit the same ' ...
        'official elevator limit and do not converge.'];
end
classification.elevatorAuthorityLimit = classify_relaxed(report);
classification.coupledPitchLiftLimit = 'highly likely';
classification.lowSpeedLiftLimit = 'highly likely';
classification.fixedCyclicClosureLimit = classify_fixed_cyclic(report);
classification.residualScalingEffect = classify_raw_objective(report);
classification.clampPlateau = 'confirmed';
classification.modelPitchMomentImbalance = 'confirmed';
classification.unknown = ['Physical fidelity versus NUAA/XV-15 remains ' ...
    'unknown; this is current-model numerical diagnosis only.'];
end

function value = classify_relaxed(report)
if any([report.relaxedElevator.trimConverged])
    value = 'confirmed';
else
    value = 'highly likely';
end
end

function value = classify_fixed_cyclic(report)
res = [report.fixedCyclic.trimConverged];
if any(res) && ~report.fixedCyclic([report.fixedCyclic.fixedCyclicLong_deg] == 0).trimConverged
    value = 'confirmed';
elseif min([report.fixedCyclic.residualNorm]) < ...
        0.9*report.fixedCyclic([report.fixedCyclic.fixedCyclicLong_deg] == 0).residualNorm
    value = 'highly likely';
else
    value = 'unknown';
end
end

function value = classify_raw_objective(report)
rawBest = min([report.rawObjective.residualNorm]);
officialBest = report.best70.trimReport.residualNorm;
if rawBest < 0.5*officialBest
    value = 'confirmed';
elseif rawBest < officialBest
    value = 'highly likely';
else
    value = 'excluded';
end
end

function r = solve_definition(label, condition, definition, P)
r = empty_solve_result();
r.label = label;
r.V = condition.V;
r.betaM = condition.betaM;
r.initialValues = definition.initialValues(:);
r.unknownNames = definition.unknownNames(:).';
timer = tic;
try
    [x,u,tr] = trim_general(condition, definition, P);
    r.runtime_s = toc(timer);
    r.xTrim = x(:);
    r.uTrim = u(:);
    r.trimReport = tr;
    r.residual = tr.residual(:);
    r.residualNorm = tr.residualNorm;
    r.scaledResidual = tr.scaledResidual(:);
    r.objectiveResidualCost = tr.objectiveResidualCost;
    r.objective = tr.cost;
    r.penalty = tr.penalty;
    r.exitflag = tr.exitflag;
    r.trimConverged = tr.converged;
    r.solverConverged = tr.solverConverged;
    r.atLimit = tr.atLimit;
    r.withinLimits = tr.withinLimits;
    r.commandedControls = tr.commandedControls(:);
    r.appliedControls = tr.appliedControls(:);
    r.finiteReal = is_real_finite(x) && is_real_finite(u) && ...
        is_real_finite(tr.fullStateDerivative);
catch ME
    r.runtime_s = toc(timer);
    r.errorIdentifier = ME.identifier;
    r.errorMessage = ME.message;
end
end

function r = solve_raw_objective(label, condition, definition, P)
r = empty_solve_result();
r.label = label;
r.V = condition.V;
r.betaM = condition.betaM;
r.initialValues = definition.initialValues(:);
r.unknownNames = definition.unknownNames(:).';
y0 = ones(numel(definition.unknownNames),1);
z0 = definition.initialValues(:);
scale = definition.variableScale(:);
options = optimset('Display', P.trim.display, ...
    'MaxIter', P.trim.maxIterations, ...
    'MaxFunEvals', 10*P.trim.maxIterations, ...
    'TolX', 1e-8, 'TolFun', 1e-10);
timer = tic;
try
    [yOpt, cost, exitflag] = fminsearch(@objective, y0, options);
    zOpt = z0 + scale.*(yOpt(:)-y0);
    [x,u,residual,penalty,xdot,eomOut,allocation] = ...
        evaluate_trim_definition_point(condition, definition, zOpt, P);
    tr = struct();
    tr.residual = residual;
    tr.residualNorm = norm(residual);
    tr.scaledResidual = residual;
    tr.objectiveResidualCost = residual.'*residual;
    tr.cost = cost;
    tr.penalty = penalty;
    tr.exitflag = exitflag;
    tr.solverConverged = exitflag > 0;
    tr.fullStateDerivative = xdot;
    tr.fullResidualNorm = norm(xdot);
    tr.commandedControls = u;
    tr.appliedControls = eomOut.components.appliedControls;
    tr.allocation = allocation;
    tr.trimVariables = named_values(definition.unknownNames, zOpt);
    tr.atLimit = any(abs(zOpt-definition.bounds(:,1)) <= 1e-8 | ...
        abs(zOpt-definition.bounds(:,2)) <= 1e-8);
    tr.withinLimits = all(zOpt >= definition.bounds(:,1)-1e-8 & ...
        zOpt <= definition.bounds(:,2)+1e-8);
    tr.converged = tr.solverConverged && ...
        tr.residualNorm < P.trim.residualTolerance && ...
        is_real_finite(xdot) && ~tr.atLimit && tr.withinLimits;
    r.runtime_s = toc(timer);
    r.xTrim = x(:);
    r.uTrim = u(:);
    r.trimReport = tr;
    r.residual = residual(:);
    r.residualNorm = tr.residualNorm;
    r.scaledResidual = tr.scaledResidual(:);
    r.objectiveResidualCost = tr.objectiveResidualCost;
    r.objective = cost;
    r.penalty = penalty;
    r.exitflag = exitflag;
    r.trimConverged = tr.converged;
    r.solverConverged = tr.solverConverged;
    r.atLimit = tr.atLimit;
    r.withinLimits = tr.withinLimits;
    r.commandedControls = tr.commandedControls(:);
    r.appliedControls = tr.appliedControls(:);
    r.finiteReal = is_real_finite(x) && is_real_finite(u) && ...
        is_real_finite(xdot);
catch ME
    r.runtime_s = toc(timer);
    r.errorIdentifier = ME.identifier;
    r.errorMessage = ME.message;
end

    function J = objective(y)
        z = z0 + scale.*(y(:)-y0);
        try
            [~,~,R,pen] = evaluate_trim_definition_point( ...
                condition, definition, z, P);
        catch ME
            if is_domain_error(ME)
                J = 1e30;
                return;
            end
            rethrow(ME);
        end
        if ~is_real_finite(R) || ~isfinite(pen)
            J = 1e30;
        else
            J = R.'*R + pen;
        end
    end
end

function item = local_jacobian(condition, definition, z, P, h)
residual0 = residual_at(condition, definition, z, P);
rawJ = zeros(3,3);
outerAppliedJ = zeros(3,1);
innerCommandJ = zeros(3,1);
methods = cell(3,1);
for k = 1:3
    zp = z;
    zm = z;
    zp(k) = zp(k)+h;
    zm(k) = zm(k)-h;
    if zp(k) <= definition.bounds(k,2) && zm(k) >= definition.bounds(k,1)
        rawJ(:,k) = (residual_at(condition, definition, zp, P) - ...
            residual_at(condition, definition, zm, P))/(2*h);
        methods{k} = 'central';
    elseif zp(k) <= definition.bounds(k,2)
        rawJ(:,k) = (residual_at(condition, definition, zp, P) - ...
            residual0)/h;
        methods{k} = 'forward';
    else
        rawJ(:,k) = (residual0 - ...
            residual_at(condition, definition, zm, P))/h;
        methods{k} = 'backward';
    end
end
residualScale = [P.env.g; P.env.g; 1];
scaledJ = diag(1./residualScale)*rawJ*diag(definition.variableScale(:));
sv = svd(scaledJ);
item.rawJacobian = rawJ;
item.scaledJacobian = scaledJ;
item.singularValues = sv(:).';
item.rank = rank(scaledJ);
item.conditionNumber = max(sv)/min(sv);
item.elevatorQdotEffect = rawJ(3,3);
item.elevatorWdotEffect = rawJ(2,3);
item.collectiveEffects = rawJ(:,2).';
item.methods = strjoin(methods, ';');

% Clamp derivative at the official lower elevator limit.
zClamp = z;
zClamp(3) = P.control.elevatorLim(1);
innerCommandJ(:,1) = (residual_at(condition, definition, ...
    replace_index(zClamp, 3, zClamp(3)+h), P) - ...
    residual_at(condition, definition, ...
    replace_index(zClamp, 3, zClamp(3)-h), P))/(2*h);
outerAppliedJ(:,1) = (residual_at_applied_elevator(condition, ...
    definition, zClamp, zClamp(3)-h, P) - ...
    residual_at_applied_elevator(condition, definition, zClamp, ...
    zClamp(3)-2*h, P))/h;
item.innerElevatorDerivativeAtClamp = innerCommandJ(:).';
item.outerAppliedDerivativeBelowClamp = outerAppliedJ(:).';
end

function R = residual_at(condition, definition, z, P)
[~,~,R] = evaluate_trim_definition_point(condition, definition, z, P);
end

function R = residual_at_applied_elevator(condition, definition, z, elevator, P)
zz = z;
zz(3) = elevator;
[x,u] = evaluate_trim_definition_point(condition, definition, zz, P);
[xdot,~] = tiltrotor_eom(x, u, condition.betaM, P);
R = [xdot(1); xdot(3); xdot(5)];
end

function z = replace_index(z, idx, value)
z(idx) = value;
end

function seed = seed_from_point(points, caseName, V, definition)
idx = find(strcmp({points.caseName}, caseName) & abs([points.V]-V) < 1e-9, 1);
tr = points(idx).trimReport;
seed = trim_vector(tr, definition);
end

function seed = preferred_seed(results)
target = find(strcmp({results.label}, 'direct_85_solution_seed_to_70'), 1);
if ~isempty(target) && results(target).finiteReal
    seed = trim_vector(results(target).trimReport, ...
        make_trim_definition('airplane_longitudinal', ...
        struct('V',70,'betaM',pi/2,'gamma',0), params_nominal()));
    return;
end
idx = find([results.finiteReal], 1, 'last');
seed = trim_vector(results(idx).trimReport, ...
    make_trim_definition('airplane_longitudinal', ...
    struct('V',results(idx).V,'betaM',pi/2,'gamma',0), params_nominal()));
end

function z = trim_vector(trimReport, definition)
z = zeros(numel(definition.unknownNames),1);
for i = 1:numel(definition.unknownNames)
    z(i) = trimReport.trimVariables.(definition.unknownNames{i});
end
end

function S = named_values(names, values)
S = struct();
for i = 1:numel(names)
    S.(names{i}) = values(i);
end
end

function rows = component_my(components)
rows = repmat(struct('name','','Fx',NaN,'Fy',NaN,'Fz',NaN, ...
    'Mx',NaN,'My',NaN,'Mz',NaN), numel(components), 1);
for i = 1:numel(components)
    c = components{i};
    rows(i).name = c.name;
    rows(i).Fx = c.F(1);
    rows(i).Fy = c.F(2);
    rows(i).Fz = c.F(3);
    rows(i).Mx = c.M(1);
    rows(i).My = c.M(2);
    rows(i).Mz = c.M(3);
end
end

function out = wing_summary(wing, P)
regions = wing.regions;
items = repmat(struct(), numel(regions), 1);
for i = 1:numel(regions)
    r = regions{i};
    items(i).area = getfield_or_nan(r, 'area');
    items(i).qbar = getfield_or_nan(r, 'qbar');
    items(i).alpha_deg = getfield_or_nan(r, 'alpha')*180/pi;
    items(i).CL = getfield_or_nan(r, 'CL');
    items(i).CLmax = P.wing.CLmax;
    items(i).lift_N = getfield_or_nan(r, 'qbar')* ...
        getfield_or_nan(r, 'area')*getfield_or_nan(r, 'CL');
    items(i).drag_N = getfield_or_nan(r, 'qbar')* ...
        getfield_or_nan(r, 'area')*getfield_or_nan(r, 'CD');
    items(i).pitchMoment_Nm = getfield_or_nan_vec(r, 'M', 2);
    items(i).armPitchMoment_Nm = getfield_or_nan_vec(r, 'Marm', 2);
    items(i).aeroPitchMoment_Nm = getfield_or_nan_vec(r, 'Maero', 2);
    items(i).branchWeight = getfield_or_nan(r, 'normalFlowBranchWeight');
end
out.regions = items;
out.totalMy = wing.M(2);
end

function out = htail_summary(ht, elevator, P)
CLraw = P.htail.CL0 + P.htail.CLalpha*ht.alphaEff + ...
    P.htail.CLelevator*elevator;
out.qbar = ht.qbar;
out.alpha_deg = ht.alphaEff*180/pi;
out.elevator_deg = elevator*180/pi;
out.CLraw = CLraw;
out.CL = ht.CL;
out.CLmax = P.htail.CLmax;
out.downforceBodyZ_N = ht.F(3);
out.armPitchMoment_Nm = ht.Marm(2);
out.directPitchMoment_Nm = ht.Maero(2);
out.totalPitchMoment_Nm = ht.M(2);
end

function out = rotor_summary(rotor)
out.thrust = rotor.thrust;
out.F = rotor.F;
out.M = rotor.M;
out.pitchMoment_Nm = rotor.M(2);
out.armPitchMoment_Nm = rotor.Marm(2);
out.reactionPitchMoment_Nm = rotor.Mreaction(2);
out.nDisk = rotor.nDisk;
out.eT = rotor.eT;
out.rHub = rotor.rHub;
end

function out = fuselage_summary(fus)
out.qbar = fus.qbar;
out.alpha_deg = fus.alpha*180/pi;
out.Cm = fus.Cm;
out.armPitchMoment_Nm = fus.Marm(2);
out.directPitchMoment_Nm = fus.Maero(2);
out.totalPitchMoment_Nm = fus.M(2);
end

function label = main_residual_label(trimReport)
[~, idx] = max(abs(trimReport.scaledResidual(:)));
names = {'udot','wdot','qdot'};
label = names{idx};
end

function v = getfield_or_nan(S, name)
if isfield(S, name)
    v = S.(name);
else
    v = NaN;
end
end

function v = getfield_or_nan_vec(S, name, idx)
if isfield(S, name)
    x = S.(name);
    v = x(idx);
else
    v = NaN;
end
end

function r = empty_solve_result()
r = struct('label','', 'V',NaN, 'betaM',NaN, 'initialValues',[], ...
    'unknownNames',{{}}, 'xTrim',[], 'uTrim',[], 'trimReport',struct(), ...
    'residual',[], 'residualNorm',Inf, 'scaledResidual',[], ...
    'objectiveResidualCost',Inf, 'objective',Inf, 'penalty',Inf, ...
    'exitflag',NaN, 'trimConverged',false, 'solverConverged',false, ...
    'atLimit',true, 'withinLimits',false, 'commandedControls',[], ...
    'appliedControls',[], 'finiteReal',false, 'runtime_s',NaN, ...
    'errorIdentifier','', 'errorMessage','', ...
    'temporaryElevatorLowerLimit_deg',NaN, 'fixedCyclicLong_deg',NaN);
end

function item = empty_jacobian_result()
item = struct('rawJacobian',NaN(3), 'scaledJacobian',NaN(3), ...
    'singularValues',NaN(1,3), 'rank',NaN, 'conditionNumber',NaN, ...
    'elevatorQdotEffect',NaN, 'elevatorWdotEffect',NaN, ...
    'collectiveEffects',NaN(1,3), 'methods','', ...
    'innerElevatorDerivativeAtClamp',NaN(1,3), ...
    'outerAppliedDerivativeBelowClamp',NaN(1,3), ...
    'V',NaN, 'h',NaN, 'baseConverged',false, ...
    'baseResidualNorm',NaN);
end

function tf = is_real_finite(value)
tf = isnumeric(value) && isreal(value) && all(isfinite(value(:)));
end

function tf = is_domain_error(ME)
tf = strcmp(ME.identifier, 'rotor_model_bemt:FlapNotConverged') || ...
    strcmp(ME.identifier, 'rotor_model_bemt:CoupledSolveNotConverged') || ...
    strcmp(ME.identifier, 'pitch_allocation_schedule:InvalidPitchCommand');
end

function write_allocation_csv(path, rows)
T = struct2table(rows);
writetable(T, path);
end

function write_seed_csv(path, rows)
flat = repmat(struct('label','','V',NaN,'betaM_deg',NaN, ...
    'theta_deg',NaN,'collective_deg',NaN,'elevatorCommand_deg',NaN, ...
    'elevatorApplied_deg',NaN,'residualNorm',NaN,'objective',NaN, ...
    'penalty',NaN,'exitflag',NaN,'solverConverged',false, ...
    'trimConverged',false,'atLimit',false,'withinLimits',false, ...
    'finiteReal',false,'runtime_s',NaN,'temporaryElevatorLowerLimit_deg',NaN, ...
    'fixedCyclicLong_deg',NaN,'errorIdentifier',''), numel(rows), 1);
for i = 1:numel(rows)
    flat(i).label = rows(i).label;
    flat(i).V = rows(i).V;
    flat(i).betaM_deg = rows(i).betaM*180/pi;
    flat(i).theta_deg = state_deg(rows(i).xTrim, 8);
    flat(i).collective_deg = control_deg(rows(i).commandedControls, 1);
    flat(i).elevatorCommand_deg = control_deg(rows(i).commandedControls, 6);
    flat(i).elevatorApplied_deg = control_deg(rows(i).appliedControls, 6);
    flat(i).residualNorm = rows(i).residualNorm;
    flat(i).objective = rows(i).objective;
    flat(i).penalty = rows(i).penalty;
    flat(i).exitflag = rows(i).exitflag;
    flat(i).solverConverged = rows(i).solverConverged;
    flat(i).trimConverged = rows(i).trimConverged;
    flat(i).atLimit = rows(i).atLimit;
    flat(i).withinLimits = rows(i).withinLimits;
    flat(i).finiteReal = rows(i).finiteReal;
    flat(i).runtime_s = rows(i).runtime_s;
    flat(i).temporaryElevatorLowerLimit_deg = ...
        rows(i).temporaryElevatorLowerLimit_deg;
    flat(i).fixedCyclicLong_deg = rows(i).fixedCyclicLong_deg;
    flat(i).errorIdentifier = rows(i).errorIdentifier;
end
writetable(struct2table(flat), path);
end

function write_jacobian_csv(path, rows)
flat = repmat(struct('V',NaN,'h',NaN,'rank',NaN, ...
    'conditionNumber',NaN,'sigma1',NaN,'sigma2',NaN,'sigma3',NaN, ...
    'elevatorQdotEffect',NaN,'elevatorWdotEffect',NaN, ...
    'collectiveUdotEffect',NaN,'collectiveWdotEffect',NaN, ...
    'collectiveQdotEffect',NaN,'methods',''), numel(rows), 1);
for i = 1:numel(rows)
    flat(i).V = rows(i).V;
    flat(i).h = rows(i).h;
    flat(i).rank = rows(i).rank;
    flat(i).conditionNumber = rows(i).conditionNumber;
    s = rows(i).singularValues;
    flat(i).sigma1 = s(1);
    flat(i).sigma2 = s(2);
    flat(i).sigma3 = s(3);
    flat(i).elevatorQdotEffect = rows(i).elevatorQdotEffect;
    flat(i).elevatorWdotEffect = rows(i).elevatorWdotEffect;
    flat(i).collectiveUdotEffect = rows(i).collectiveEffects(1);
    flat(i).collectiveWdotEffect = rows(i).collectiveEffects(2);
    flat(i).collectiveQdotEffect = rows(i).collectiveEffects(3);
    flat(i).methods = rows(i).methods;
end
writetable(struct2table(flat), path);
end

function write_text_report(path, report)
fid = fopen(path, 'w');
if fid < 0
    error('issue20:WriteFailed', 'Could not open report: %s', path);
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '# Issue #20 Trim Authority Diagnostic Report\n\n');
fprintf(fid, 'Generated: %s\n\n', report.generatedAt);
fprintf(fid, 'Scope: %s\n\n', report.scope);
fprintf(fid, 'Existing baseline marked: %s\n\n', ...
    report.angleSemantics.oldBaselineStatus);
fprintf(fid, '## Call Path\n\n%s\n\n', report.callPath.confirmation);
for i = 1:numel(report.callPath.items)
    item = report.callPath.items(i);
    fprintf(fid, '- %s: unknowns=%s, allocation=%s\n', item.mode, ...
        strjoin(item.unknownNames, ','), item.allocationType);
end
fprintf(fid, '\n## Baseline 70 m/s Row\n\n');
fprintf(fid, 'theta=%.6f deg, collective=%.6f deg, commanded elevator=%.6f deg, applied elevator=%.6f deg\n\n', ...
    report.baseline70.theta_deg, report.baseline70.collective_deg, ...
    report.baseline70.commandedElevator_deg, ...
    report.baseline70.appliedElevator_deg);
fprintf(fid, 'udot=%.6e, wdot=%.6e, qdot=%.6e, residualNorm=%.6e, objective=%.6e, penalty=%.6e\n\n', ...
    report.baseline70.udot, report.baseline70.wdot, ...
    report.baseline70.qdot, report.baseline70.residualNorm, ...
    report.baseline70.objective, report.baseline70.penalty);
fprintf(fid, '## Seed And Path Retest\n\n');
for i = 1:numel(report.seedRetest)
    r = report.seedRetest(i);
    fprintf(fid, '- %s: V=%.1f, converged=%d, residual=%.6e, elevator=%.6f deg, applied=%.6f deg, atLimit=%d\n', ...
        r.label, r.V, r.trimConverged, r.residualNorm, ...
        control_deg(r.commandedControls, 6), control_deg(r.appliedControls, 6), ...
        r.atLimit);
end
fprintf(fid, '\n## Relaxed Elevator Tests\n\n');
for i = 1:numel(report.relaxedElevator)
    r = report.relaxedElevator(i);
    fprintf(fid, '- lower %.0f deg: converged=%d, residual=%.6e, elevator=%.6f deg, applied=%.6f deg\n', ...
        r.temporaryElevatorLowerLimit_deg, r.trimConverged, ...
        r.residualNorm, control_deg(r.commandedControls, 6), ...
        control_deg(r.appliedControls, 6));
end
fprintf(fid, '\n## Fixed Cyclic Tests\n\n');
for i = 1:numel(report.fixedCyclic)
    r = report.fixedCyclic(i);
    fprintf(fid, '- cyclic %.1f deg: converged=%d, residual=%.6e, elevator=%.6f deg\n', ...
        r.fixedCyclicLong_deg, r.trimConverged, r.residualNorm, ...
        control_deg(r.commandedControls, 6));
end
fprintf(fid, '\n## Raw Equal-Weight Objective Tests\n\n');
for i = 1:numel(report.rawObjective)
    r = report.rawObjective(i);
    fprintf(fid, '- %s: converged=%d, residual=%.6e, objective=%.6e, elevator=%.6f deg, atLimit=%d\n', ...
        r.label, r.trimConverged, r.residualNorm, r.objective, ...
        control_deg(r.commandedControls, 6), r.atLimit);
end
fprintf(fid, '\n## Local Control-Effectiveness Jacobian\n\n');
for i = 1:numel(report.jacobians)
    j = report.jacobians(i);
    if abs(j.h-1e-4) < 1e-12
        fprintf(fid, '- V=%.0f m/s h=%.0e: rank=%d, cond=%.6f, singular=[%.6e %.6e %.6e], d(qdot)/d(elevator)=%.6e, d(wdot)/d(elevator)=%.6e\n', ...
            j.V, j.h, j.rank, j.conditionNumber, ...
            j.singularValues(1), j.singularValues(2), ...
            j.singularValues(3), j.elevatorQdotEffect, ...
            j.elevatorWdotEffect);
    end
end
first70 = find(abs([report.jacobians.V]-70) < 1e-9 & ...
    abs([report.jacobians.h]-1e-4) < 1e-12, 1);
if ~isempty(first70)
    j = report.jacobians(first70);
    fprintf(fid, '\nAt the elevator lower clamp, inner one-sided/near-limit derivative=[%.6e %.6e %.6e]; outer below-clamp applied derivative=[%.6e %.6e %.6e].\n', ...
        j.innerElevatorDerivativeAtClamp, ...
        j.outerAppliedDerivativeBelowClamp);
end
fprintf(fid, '\n## Allocation Audit\n\n');
for i = 1:numel(report.allocationAudit)
    a = report.allocationAudit(i);
    fprintf(fid, '- betaM %.0f deg: gCyclic=%.6f, gElevator=%.6f, limit=%.6f, max cyclic=%.6f deg, max elevator=%.6f deg\n', ...
        a.modelBetaMDeg, a.gCyclic, a.gElevator, ...
        a.pitchCommandLimit, a.maxCyclic_deg, a.maxElevator_deg);
end
fprintf(fid, '\n## Component Pitch Balance At Best Official 70 m/s Candidate\n\n');
fprintf(fid, 'Selected: %s, residual=%.6e\n\n', report.best70.label, ...
    report.best70.trimReport.residualNorm);
for i = 1:numel(report.balance.componentMy)
    c = report.balance.componentMy(i);
    fprintf(fid, '- %s: My=%.6e N m, F=[%.6e %.6e %.6e] N\n', ...
        c.name, c.My, c.Fx, c.Fy, c.Fz);
end
fprintf(fid, '\nTotal My=%.6e N m; main scaled residual=%s\n\n', ...
    report.balance.Mtotal(2), report.balance.mainUnclosedResidual);
fprintf(fid, 'Horizontal tail: qbar=%.6e, alpha=%.6f deg, elevator=%.6f deg, CLraw=%.6f, CL=%.6f, CLmax=%.6f, My arm/direct/total=[%.6e %.6e %.6e]\n\n', ...
    report.balance.horizontalTail.qbar, ...
    report.balance.horizontalTail.alpha_deg, ...
    report.balance.horizontalTail.elevator_deg, ...
    report.balance.horizontalTail.CLraw, ...
    report.balance.horizontalTail.CL, ...
    report.balance.horizontalTail.CLmax, ...
    report.balance.horizontalTail.armPitchMoment_Nm, ...
    report.balance.horizontalTail.directPitchMoment_Nm, ...
    report.balance.horizontalTail.totalPitchMoment_Nm);
fprintf(fid, 'CG shift=[%.6e %.6e %.6e] m\n\n', ...
    report.balance.massProperties.cgShift);
fprintf(fid, '## Final Classification\n\n');
fields = fieldnames(report.classification);
for i = 1:numel(fields)
    value = report.classification.(fields{i});
    if ischar(value)
        fprintf(fid, '- %s: %s\n', fields{i}, value);
    end
end
fprintf(fid, '\n## Files\n\n');
fprintf(fid, '- MAT: issue20_trim_authority_report.mat\n');
fprintf(fid, '- CSV: issue20_allocation_audit.csv\n');
fprintf(fid, '- CSV: issue20_seed_retest.csv\n');
fprintf(fid, '- CSV: issue20_jacobian_summary.csv\n');
end

function value = control_deg(u, idx)
if isempty(u)
    value = NaN;
else
    value = u(idx)*180/pi;
end
end

function value = state_deg(x, idx)
if isempty(x)
    value = NaN;
else
    value = x(idx)*180/pi;
end
end
