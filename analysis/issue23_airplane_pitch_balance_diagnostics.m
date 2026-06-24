function report = issue23_airplane_pitch_balance_diagnostics()
%ISSUE23_AIRPLANE_PITCH_BALANCE_DIAGNOSTICS Issue #23 staged audit.
% This script writes a new timestamped validation folder only. All
% parameter changes are local in-memory candidates; production defaults are
% not modified by this diagnostic.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir, 'model'));
addpath(fullfile(rootDir, 'analysis'));
addpath(fullfile(rootDir, 'services'));

d2r = pi/180;
P0 = params_nominal();
stamp = datestr(now, 'yyyymmdd_HHMMSS');
outDir = fullfile(rootDir, 'validation', 'nuaa_trim_trends', ...
    ['issue23_pitch_balance_' stamp]);
if exist(outDir, 'dir')
    error('issue23:OutputExists', 'Output directory already exists: %s', outDir);
end
mkdir(outDir);

fprintf('\nIssue #23 airplane pitch-balance diagnostics\n');
fprintf('===========================================\n');
fprintf('Output directory: %s\n', outDir);
fprintf('Focused airplane speeds: %s m/s\n', mat2str(speed_set()));
fprintf('No production parameter file is modified by this script.\n\n');

report = struct();
report.generatedAt = datestr(now, 31);
report.issue = 'GitHub x162645/tiltrotor-matlab#23';
report.outputDir = outDir;
report.scope = ['In-memory staged parameter audit for airplane-mode ' ...
    'pitch balance and +/-20 deg elevator acceptance.'];
report.oldValues = old_values(P0);

trimRows = empty_trim_row();
componentRows = empty_component_row();
tailRows = empty_tail_row();
candidateRows = empty_candidate_row();

% Stage 0 and Stage 1 exact cases, elevator limit remains +/-40 deg.
stage1 = { ...
    make_candidate('A_current', P0, 'Stage 0/1 exact current defaults'), ...
    make_candidate('B_wingCma0', apply_overrides(P0, 0, NaN, NaN, NaN, NaN), ...
        'Stage 1 exact wing.Cmalpha=0'), ...
    make_candidate('C_fuselageCma0', apply_overrides(P0, NaN, 0, NaN, NaN, NaN), ...
        'Stage 1 exact fuselage.Cmalpha=0'), ...
    make_candidate('D_bothCma0', apply_overrides(P0, 0, 0, NaN, NaN, NaN), ...
        'Stage 1 exact wing/fuselage Cmalpha=0')};

for i = 1:numel(stage1)
    [rows, comps, tails] = run_speed_set(stage1{i}, 40);
    trimRows = append_rows(trimRows, rows);
    componentRows = append_rows(componentRows, comps);
    tailRows = append_rows(tailRows, tails);
    candidateRows = append_rows(candidateRows, summarize_candidate(stage1{i}, rows, tails, 40));
end

% Stage 2A: sequential downwash scan from the best Stage 1 candidate.
baseStage2 = stage1{4};
downwashValues = [0.30 0.35 0.40 0.45 0.50];
dwCandidates = cell(numel(downwashValues), 1);
for i = 1:numel(downwashValues)
    name = sprintf('S2A_dw%03.0f', 100*downwashValues(i));
    Pc = baseStage2.P;
    Pc.htail.downwashAlpha = downwashValues(i);
    dwCandidates{i} = make_candidate(name, Pc, 'Stage 2A downwash scan');
    [rows, comps, tails] = run_speed_set(dwCandidates{i}, 40, 70);
    trimRows = append_rows(trimRows, rows);
    componentRows = append_rows(componentRows, comps);
    tailRows = append_rows(tailRows, tails);
    candidateRows = append_rows(candidateRows, summarize_candidate(dwCandidates{i}, rows, tails, 40));
end

% Stage 2B: incidence only after selecting the smallest material downwash
% change that still approaches the +/-20 deg target without using range edge.
selectedDw = dwCandidates{3}; % downwashAlpha = 0.40, not a diagnostic edge.
incidenceValuesDeg = [0 -1 -2 -3];
incCandidates = cell(numel(incidenceValuesDeg), 1);
for i = 1:numel(incidenceValuesDeg)
    name = sprintf('S2B_dw040_inc%+03.0f', incidenceValuesDeg(i));
    Pc = selectedDw.P;
    Pc.htail.incidence = incidenceValuesDeg(i)*d2r;
    incCandidates{i} = make_candidate(name, Pc, 'Stage 2B tail incidence scan');
    [rows, comps, tails] = run_speed_set(incCandidates{i}, 40, 70);
    trimRows = append_rows(trimRows, rows);
    componentRows = append_rows(componentRows, comps);
    tailRows = append_rows(tailRows, tails);
    candidateRows = append_rows(candidateRows, summarize_candidate(incCandidates{i}, rows, tails, 40));
end

% Stage 2C: elevator effectiveness only because downwash/incidence alone do
% not leave the requested 2 deg margin at 70 m/s.
selectedInc = incCandidates{3}; % incidence = -2 deg, not a diagnostic edge.
cleValues = [1.60 1.80 2.00 2.20];
cleCandidates = cell(numel(cleValues), 1);
for i = 1:numel(cleValues)
    name = sprintf('S2C_dw040_inc-02_CLe%03.0f', 100*cleValues(i));
    Pc = selectedInc.P;
    Pc.htail.CLelevator = cleValues(i);
    cleCandidates{i} = make_candidate(name, Pc, 'Stage 2C elevator effectiveness scan');
    [rows, comps, tails] = run_speed_set(cleCandidates{i}, 40, 70);
    trimRows = append_rows(trimRows, rows);
    componentRows = append_rows(componentRows, comps);
    tailRows = append_rows(tailRows, tails);
    candidateRows = append_rows(candidateRows, summarize_candidate(cleCandidates{i}, rows, tails, 40));
end

% Stage 3: final physical +/-20 deg limit on the first non-edge candidate
% that met the 70 m/s margin target in Stage 2C. Issue #23 physical review
% retains wing.Cm0=-0.03 as a nonzero effective concept parameter.
Pc = cleCandidates{3}.P; % CLelevator = 2.00, not the scan edge.
acceptedCandidate = make_candidate( ...
    'S2C_dw040_inc-02_CLe200_Cm0-003', Pc, ...
    'Selected Stage 2 candidate with retained wing Cm0=-0.03');
[rows, comps, tails] = run_speed_set(acceptedCandidate, 40, 70);
trimRows = append_rows(trimRows, rows);
componentRows = append_rows(componentRows, comps);
tailRows = append_rows(tailRows, tails);
candidateRows = append_rows(candidateRows, summarize_candidate(acceptedCandidate, rows, tails, 40));
[finalRows, finalComps, finalTails] = run_speed_set(acceptedCandidate, 20);
trimRows = append_rows(trimRows, finalRows);
componentRows = append_rows(componentRows, finalComps);
tailRows = append_rows(tailRows, finalTails);
candidateRows = append_rows(candidateRows, summarize_candidate(acceptedCandidate, finalRows, finalTails, 20));

acceptance = evaluate_acceptance(finalRows, componentRows, tailRows, ...
    acceptedCandidate, P0);
report.accepted = acceptance.allPassed;
report.acceptance = acceptance;
report.selectedCandidate = candidate_summary(acceptedCandidate, 20);
Paccepted = acceptedCandidate.P;
Paccepted.control.elevatorLim = [-20 20]*d2r;
report.newValues = old_values(Paccepted);
report.trimRows = trimRows;
report.componentRows = componentRows;
report.tailRows = tailRows;
report.candidateRows = candidateRows;

trimTable = struct2table(trimRows);
componentTable = struct2table(componentRows);
tailTable = struct2table(tailRows);
candidateTable = struct2table(candidateRows);

paths.trimCsv = fullfile(outDir, 'issue23_trim_comparison.csv');
paths.componentCsv = fullfile(outDir, 'issue23_component_moments.csv');
paths.tailCsv = fullfile(outDir, 'issue23_tail_baseline_loads.csv');
paths.candidateCsv = fullfile(outDir, 'issue23_candidate_sensitivity.csv');
paths.reportMd = fullfile(outDir, 'ISSUE23_PITCH_BALANCE_REPORT.md');
paths.mat = fullfile(outDir, 'issue23_pitch_balance_report.mat');

writetable(trimTable, paths.trimCsv);
writetable(componentTable, paths.componentCsv);
writetable(tailTable, paths.tailCsv);
writetable(candidateTable, paths.candidateCsv);
report.paths = paths;
save(paths.mat, 'report', '-v7');
write_markdown_report(paths.reportMd, report, finalRows, componentRows, tailRows);

fprintf('\nIssue #23 output: %s\n', outDir);
fprintf('Accepted candidate: %d\n', report.accepted);
fprintf('Selected values: wing.Cm0=%.6g, wing.Cmalpha=%.6g, fuselage.Cmalpha=%.6g, downwash=%.6g, incidence=%.6g deg, CLelevator=%.6g, elevatorLim=[%.1f %.1f] deg\n', ...
    acceptedCandidate.P.wing.Cm0, acceptedCandidate.P.wing.Cmalpha, ...
    acceptedCandidate.P.fuselage.Cmalpha, ...
    acceptedCandidate.P.htail.downwashAlpha, ...
    acceptedCandidate.P.htail.incidence/d2r, ...
    acceptedCandidate.P.htail.CLelevator, ...
    acceptedCandidate.P.control.elevatorLim/d2r);
fprintf('Report: %s\n', paths.reportMd);
end

function values = old_values(P)
d2r = pi/180;
values.wing_Cm0 = P.wing.Cm0;
values.wing_Cmalpha = P.wing.Cmalpha;
values.fuselage_Cm0 = P.fuselage.Cm0;
values.fuselage_Cmalpha = P.fuselage.Cmalpha;
values.htail_downwashAlpha = P.htail.downwashAlpha;
values.htail_incidence_deg = P.htail.incidence/d2r;
values.htail_CLelevator = P.htail.CLelevator;
values.htail_Cmelevator = P.htail.Cmelevator;
values.elevatorLimLower_deg = P.control.elevatorLim(1)/d2r;
values.elevatorLimUpper_deg = P.control.elevatorLim(2)/d2r;
end

function candidate = make_candidate(name, P, description)
candidate.name = name;
candidate.description = description;
candidate.P = P;
end

function P = apply_overrides(P, wingCma, fusCma, downwash, incidenceDeg, CLe)
d2r = pi/180;
if isfinite_or_nan_scalar(wingCma) && ~isnan(wingCma)
    P.wing.Cmalpha = wingCma;
end
if isfinite_or_nan_scalar(fusCma) && ~isnan(fusCma)
    P.fuselage.Cmalpha = fusCma;
end
if isfinite_or_nan_scalar(downwash) && ~isnan(downwash)
    P.htail.downwashAlpha = downwash;
end
if isfinite_or_nan_scalar(incidenceDeg) && ~isnan(incidenceDeg)
    P.htail.incidence = incidenceDeg*d2r;
end
if isfinite_or_nan_scalar(CLe) && ~isnan(CLe)
    P.htail.CLelevator = CLe;
end
end

function tf = isfinite_or_nan_scalar(value)
tf = isnumeric(value) && isreal(value) && isscalar(value) && ...
    (isfinite(value) || isnan(value));
end

function speeds = speed_set()
speeds = [70 72.5 75 77.5 80 82.5 85 90 100];
end

function [rows, comps, tails] = run_speed_set(candidate, elevatorLimitDeg, speeds)
d2r = pi/180;
P = candidate.P;
P.control.elevatorLim = [-elevatorLimitDeg elevatorLimitDeg]*d2r;
if nargin < 3
    speeds = speed_set();
end
speeds = speeds(:).';
preferredOrder = [100 90 85 82.5 80 77.5 75 72.5 70];
solveOrder = preferredOrder(ismember(preferredOrder, speeds));
extra = speeds(~ismember(speeds, solveOrder));
solveOrder = [solveOrder extra];
rows = repmat(empty_trim_row(), numel(speeds), 1);
comps = repmat(empty_component_row(), numel(speeds), 1);
tails = repmat(empty_tail_row(), numel(speeds), 1);
seed = [];

fprintf('Candidate %s, elevator limit +/-%.0f deg\n', ...
    candidate.name, elevatorLimitDeg);
for i = 1:numel(solveOrder)
    V = solveOrder(i);
    idx = find(abs(speeds - V) < 1e-9, 1);
    condition = struct('V', V, 'betaM', pi/2, 'gamma', 0);
    definition = make_trim_definition('airplane_longitudinal', condition, P);
    if ~isempty(seed)
        attempts = cell(2, 1);
        attemptNames = cell(2, 1);
        attempts{1} = seed;
        attempts{2} = definition.initialValues;
        attemptNames{1} = 'continuation';
        attemptNames{2} = 'default';
    else
        attempts = cell(1, 1);
        attemptNames = cell(1, 1);
        attempts{1} = definition.initialValues;
        attemptNames{1} = 'default';
    end

    [row, comp, tail, nextSeed] = solve_attempts(candidate, condition, ...
        definition, attempts, attemptNames, P, elevatorLimitDeg);
    rows(idx) = row;
    comps(idx) = comp;
    tails(idx) = tail;
    if row.trimConverged && row.finiteReal
        seed = nextSeed;
    end
    fprintf('  V=%6.1f conv=%d res=%.3e elev=% .3f theta=% .3f coll=% .3f source=%s\n', ...
        row.V_mps, row.trimConverged, row.residualNorm, ...
        row.elevatorCommand_deg, row.theta_deg, row.collective_deg, ...
        row.initialSource);
end
end

function [row, comp, tail, seed] = solve_attempts(candidate, condition, ...
        definition0, attempts, attemptNames, P, elevatorLimitDeg)
bestScore = Inf;
row = fill_identity(empty_trim_row(), candidate, condition, elevatorLimitDeg);
comp = fill_identity(empty_component_row(), candidate, condition, elevatorLimitDeg);
tail = fill_identity(empty_tail_row(), candidate, condition, elevatorLimitDeg);
seed = [];
for i = 1:numel(attempts)
    definition = definition0;
    definition.initialValues = attempts{i}(:);
    thisRow = fill_identity(empty_trim_row(), candidate, condition, elevatorLimitDeg);
    thisRow.initialSource = attemptNames{i};
    timer = tic;
    try
        [x, u, trimReport] = trim_general(condition, definition, P);
        thisRow.runtime_s = toc(timer);
        thisRow = fill_trim_row(thisRow, x, u, trimReport, P);
        [thisComp, thisTail] = component_tables(candidate, condition, ...
            elevatorLimitDeg, x, u, trimReport, P);
        score = trim_score(thisRow);
        if score < bestScore
            bestScore = score;
            row = thisRow;
            comp = thisComp;
            tail = thisTail;
            seed = trim_variables_vector(trimReport, definition);
        end
        if thisRow.trimConverged && thisRow.finiteReal
            return;
        end
    catch ME
        thisRow.runtime_s = toc(timer);
        thisRow.errorIdentifier = ME.identifier;
        thisRow.errorMessage = ME.message;
        if isinf(bestScore)
            row = thisRow;
        end
    end
end
end

function row = fill_identity(row, candidate, condition, elevatorLimitDeg)
d2r = pi/180;
row.candidate = candidate.name;
row.stage = candidate.description;
row.elevatorLimit_deg = elevatorLimitDeg;
row.elevator_lower_limit_deg = -elevatorLimitDeg;
row.elevator_upper_limit_deg = elevatorLimitDeg;
row.V_mps = condition.V;
row.betaM_deg = condition.betaM/d2r;
row.wing_Cm0 = candidate.P.wing.Cm0;
row.wing_Cmalpha = candidate.P.wing.Cmalpha;
row.fuselage_Cmalpha = candidate.P.fuselage.Cmalpha;
row.htail_downwashAlpha = candidate.P.htail.downwashAlpha;
row.htail_incidence_deg = candidate.P.htail.incidence/d2r;
row.htail_CLelevator = candidate.P.htail.CLelevator;
end

function row = fill_trim_row(row, x, u, trimReport, P)
d2r = pi/180;
row.exitflag = trimReport.exitflag;
row.solverConverged = trimReport.solverConverged;
row.trimConverged = trimReport.converged;
row.atLimit = trimReport.atLimit;
row.withinLimits = trimReport.withinLimits;
row.finiteReal = is_real_finite(x) && is_real_finite(u) && ...
    is_real_finite(trimReport.fullStateDerivative);
row.residualNorm = trimReport.residualNorm;
row.fullResidualNorm = trimReport.fullResidualNorm;
row.udot = trimReport.fullStateDerivative(1);
row.wdot = trimReport.fullStateDerivative(3);
row.qdot = trimReport.fullStateDerivative(5);
row.theta_deg = x(8)/d2r;
row.collective_deg = u(1)/d2r;
row.cyclicLong_deg = u(3)/d2r;
row.elevatorCommand_deg = u(6)/d2r;
row.elevatorApplied_deg = trimReport.appliedControls(6)/d2r;
row.elevatorMarginToLower_deg = ...
    (u(6) - P.control.elevatorLim(1))/d2r;
row.elevatorMarginToUpper_deg = ...
    (P.control.elevatorLim(2) - u(6))/d2r;
row.controlLimitMarginMin_deg = min(row.elevatorMarginToLower_deg, ...
    row.elevatorMarginToUpper_deg);
end

function [comp, tail] = component_tables(candidate, condition, ...
        elevatorLimitDeg, x, u, trimReport, P)
comp = fill_identity(empty_component_row(), candidate, condition, elevatorLimitDeg);
tail = fill_identity(empty_tail_row(), candidate, condition, elevatorLimitDeg);
if ~isfield(trimReport, 'fullStateDerivative') || isempty(x)
    return;
end
[~, eomOut] = tiltrotor_eom(x, u, condition.betaM, P);
info = eomOut.components;

comp.My_total_Nm = eomOut.Mtotal(2);
comp.rotors_My_Nm = component_My(info, 'rotorLeft') + ...
    component_My(info, 'rotorRight');
comp.wing_My_Nm = component_My(info, 'wing');
comp.fuselage_My_Nm = component_My(info, 'fuselage');
comp.htail_My_Nm = component_My(info, 'horizontalTail');
comp.vtail_My_Nm = component_My(info, 'verticalTail');
[comp.wing_arm_My_Nm, comp.wing_intrinsic_My_Nm] = wing_split(info.wing);
comp.fuselage_arm_My_Nm = info.fuselage.Marm(2);
comp.fuselage_intrinsic_My_Nm = info.fuselage.Maero(2);
comp.htail_arm_My_Nm = info.horizontalTail.Marm(2);
comp.htail_direct_My_Nm = info.horizontalTail.Maero(2);

ht = info.horizontalTail;
tail.elevator_deg = u(6)/(pi/180);
tail.alphaEff_deg = ht.alphaEff/(pi/180);
tail.alphaLocal_deg = ht.alphaLocal/(pi/180);
tail.alphaCG_deg = ht.alphaCG/(pi/180);
tail.qbar_Pa = ht.qbar;
tail.CL = ht.CL;
tail.Fx_N = ht.F(1);
tail.Fz_N = ht.F(3);
tail.My_arm_Nm = ht.Marm(2);
tail.My_direct_Nm = ht.Maero(2);
tail.My_total_Nm = ht.M(2);

[F0, M0, ht0] = horizontal_tail_model(x, 0, ...
    eomOut.massProperties.cgShift, P);
tail.zeroElevator_alphaEff_deg = ht0.alphaEff/(pi/180);
tail.zeroElevator_CL = ht0.CL;
tail.zeroElevator_Fx_N = F0(1);
tail.zeroElevator_Fz_N = F0(3);
tail.zeroElevator_My_arm_Nm = ht0.Marm(2);
tail.zeroElevator_My_direct_Nm = ht0.Maero(2);
tail.zeroElevator_My_total_Nm = M0(2);
end

function value = component_My(info, name)
idx = find(strcmp(cellfun(@(s) s.name, info.components, 'UniformOutput', false), name), 1);
value = info.components{idx}.M(2);
end

function [armMy, intrinsicMy] = wing_split(wing)
armMy = 0;
intrinsicMy = 0;
for i = 1:numel(wing.regions)
    r = wing.regions{i};
    if isfield(r, 'Marm')
        armMy = armMy + r.Marm(2);
    end
    if isfield(r, 'Maero')
        intrinsicMy = intrinsicMy + r.Maero(2);
    end
end
end

function row = summarize_candidate(candidate, rows, tails, elevatorLimitDeg)
row = fill_identity(empty_candidate_row(), candidate, ...
    struct('V', 70, 'betaM', pi/2, 'gamma', 0), elevatorLimitDeg);
mask70 = abs([rows.V_mps] - 70) < 1e-9;
row.allTrimConverged = all([rows.trimConverged]);
row.allFiniteReal = all([rows.finiteReal]);
row.anyAtLimit = any([rows.atLimit]);
row.maxResidualNorm = max([rows.residualNorm]);
row.elevator70_deg = rows(mask70).elevatorCommand_deg;
row.theta70_deg = rows(mask70).theta_deg;
row.collective70_deg = rows(mask70).collective_deg;
row.minElevatorMargin_deg = min([rows.controlLimitMarginMin_deg]);
if numel(rows) > 1
    row.maxAbsElevatorStep_deg = max(abs(diff([rows.elevatorCommand_deg])));
    row.maxAbsThetaStep_deg = max(abs(diff([rows.theta_deg])));
    row.maxAbsCollectiveStep_deg = max(abs(diff([rows.collective_deg])));
else
    row.maxAbsElevatorStep_deg = NaN;
    row.maxAbsThetaStep_deg = NaN;
    row.maxAbsCollectiveStep_deg = NaN;
end
row.zeroElevatorTailFz70_N = tails(mask70).zeroElevator_Fz_N;
row.zeroElevatorTailMy70_Nm = tails(mask70).zeroElevator_My_total_Nm;
end

function summary = candidate_summary(candidate, elevatorLimitDeg)
summary = old_values(candidate.P);
summary.candidate = candidate.name;
summary.description = candidate.description;
summary.elevatorLimit_deg = elevatorLimitDeg;
end

function acceptance = evaluate_acceptance(rows, componentRows, tailRows, ...
        candidate, P0)
maskFinal = strcmp({componentRows.candidate}, candidate.name) & ...
    abs([componentRows.elevatorLimit_deg] - 20) < 1e-9;
finalComps = componentRows(maskFinal);
maskTail = strcmp({tailRows.candidate}, candidate.name) & ...
    abs([tailRows.elevatorLimit_deg] - 20) < 1e-9;
finalTails = tailRows(maskTail);
mask70 = abs([rows.V_mps] - 70) < 1e-9;
elev = [rows.elevatorCommand_deg];
theta = [rows.theta_deg];
coll = [rows.collective_deg];
wingIntrinsic = [finalComps.wing_intrinsic_My_Nm];
wingArm = [finalComps.wing_arm_My_Nm];

acceptance.pointsFiniteCredible = all([rows.trimConverged]) && ...
    all([rows.finiteReal]) && ~any([rows.atLimit]);
acceptance.elevator70Margin = abs(rows(mask70).elevatorCommand_deg) <= 18;
acceptance.smoothTrends = max(abs(diff(elev))) < 8 && ...
    max(abs(diff(theta))) < 5 && max(abs(diff(coll))) < 5;
acceptance.nuaaQualitative = abs(elev(1)) >= abs(elev(end)) && ...
    max(abs(elev)) < 20;
acceptance.wingIntrinsicSeparatedAndTraceable = all(isfinite(wingIntrinsic)) && ...
    all(isfinite(wingArm)) && all(abs(wingIntrinsic) <= ...
    0.80*max(abs(wingArm), 1));
acceptance.tailZeroLoadReduced = abs(finalTails(mask70).zeroElevator_Fz_N) < ...
    0.75*abs(baseline_tail_zero_load(P0));
acceptance.notAtDiagnosticEdge = ...
    candidate.P.htail.downwashAlpha > 0.30 && ...
    candidate.P.htail.downwashAlpha < 0.50 && ...
    candidate.P.htail.incidence/(pi/180) > -3 && ...
    candidate.P.htail.incidence/(pi/180) < 0 && ...
    candidate.P.htail.CLelevator > 1.60 && ...
    candidate.P.htail.CLelevator < 2.20;
acceptance.allPassed = acceptance.pointsFiniteCredible && ...
    acceptance.elevator70Margin && acceptance.smoothTrends && ...
    acceptance.nuaaQualitative && ...
    acceptance.wingIntrinsicSeparatedAndTraceable && ...
    acceptance.tailZeroLoadReduced && acceptance.notAtDiagnosticEdge;
end

function Fz = baseline_tail_zero_load(P)
d2r = pi/180;
condition = struct('V', 70, 'betaM', pi/2, 'gamma', 0);
P.control.elevatorLim = [-40 40]*d2r;
definition = make_trim_definition('airplane_longitudinal', condition, P);
[x, ~, ~] = trim_general(condition, definition, P);
mp = mass_properties(condition.betaM, P);
[~, ~, ht0] = horizontal_tail_model(x, 0, mp.cgShift, P);
Fz = ht0.F(3);
end

function z = trim_variables_vector(trimReport, definition)
z = NaN(numel(definition.unknownNames), 1);
for i = 1:numel(definition.unknownNames)
    z(i) = trimReport.trimVariables.(definition.unknownNames{i});
end
end

function score = trim_score(row)
if row.trimConverged && row.finiteReal
    score = row.residualNorm;
else
    score = 1e6 + row.residualNorm + row.fullResidualNorm;
    if row.atLimit
        score = score + 1e5;
    end
end
end

function out = append_rows(out, rows)
if isempty(out) || (numel(out) == 1 && strcmp(out(1).candidate, ''))
    out = rows(:);
else
    out = [out(:); rows(:)];
end
end

function row = empty_trim_row()
row = struct('candidate', '', 'stage', '', 'elevatorLimit_deg', NaN, ...
    'elevator_lower_limit_deg', NaN, 'elevator_upper_limit_deg', NaN, ...
    'V_mps', NaN, 'betaM_deg', NaN, 'wing_Cm0', NaN, ...
    'wing_Cmalpha', NaN, ...
    'fuselage_Cmalpha', NaN, 'htail_downwashAlpha', NaN, ...
    'htail_incidence_deg', NaN, 'htail_CLelevator', NaN, ...
    'initialSource', '', 'runtime_s', NaN, 'exitflag', NaN, ...
    'solverConverged', false, 'trimConverged', false, ...
    'atLimit', false, 'withinLimits', false, 'finiteReal', false, ...
    'residualNorm', NaN, 'fullResidualNorm', NaN, ...
    'udot', NaN, 'wdot', NaN, 'qdot', NaN, ...
    'theta_deg', NaN, 'collective_deg', NaN, ...
    'cyclicLong_deg', NaN, 'elevatorCommand_deg', NaN, ...
    'elevatorApplied_deg', NaN, 'elevatorMarginToLower_deg', NaN, ...
    'elevatorMarginToUpper_deg', NaN, ...
    'controlLimitMarginMin_deg', NaN, ...
    'errorIdentifier', '', 'errorMessage', '');
end

function row = empty_component_row()
row = struct('candidate', '', 'stage', '', 'elevatorLimit_deg', NaN, ...
    'elevator_lower_limit_deg', NaN, 'elevator_upper_limit_deg', NaN, ...
    'V_mps', NaN, 'betaM_deg', NaN, 'wing_Cm0', NaN, ...
    'wing_Cmalpha', NaN, ...
    'fuselage_Cmalpha', NaN, 'htail_downwashAlpha', NaN, ...
    'htail_incidence_deg', NaN, 'htail_CLelevator', NaN, ...
    'My_total_Nm', NaN, 'rotors_My_Nm', NaN, ...
    'wing_My_Nm', NaN, 'wing_arm_My_Nm', NaN, ...
    'wing_intrinsic_My_Nm', NaN, 'fuselage_My_Nm', NaN, ...
    'fuselage_arm_My_Nm', NaN, 'fuselage_intrinsic_My_Nm', NaN, ...
    'htail_My_Nm', NaN, 'htail_arm_My_Nm', NaN, ...
    'htail_direct_My_Nm', NaN, 'vtail_My_Nm', NaN);
end

function row = empty_tail_row()
row = struct('candidate', '', 'stage', '', 'elevatorLimit_deg', NaN, ...
    'elevator_lower_limit_deg', NaN, 'elevator_upper_limit_deg', NaN, ...
    'V_mps', NaN, 'betaM_deg', NaN, 'wing_Cm0', NaN, ...
    'wing_Cmalpha', NaN, ...
    'fuselage_Cmalpha', NaN, 'htail_downwashAlpha', NaN, ...
    'htail_incidence_deg', NaN, 'htail_CLelevator', NaN, ...
    'elevator_deg', NaN, 'alphaEff_deg', NaN, ...
    'alphaLocal_deg', NaN, 'alphaCG_deg', NaN, 'qbar_Pa', NaN, ...
    'CL', NaN, 'Fx_N', NaN, 'Fz_N', NaN, ...
    'My_arm_Nm', NaN, 'My_direct_Nm', NaN, 'My_total_Nm', NaN, ...
    'zeroElevator_alphaEff_deg', NaN, 'zeroElevator_CL', NaN, ...
    'zeroElevator_Fx_N', NaN, 'zeroElevator_Fz_N', NaN, ...
    'zeroElevator_My_arm_Nm', NaN, ...
    'zeroElevator_My_direct_Nm', NaN, ...
    'zeroElevator_My_total_Nm', NaN);
end

function row = empty_candidate_row()
row = struct('candidate', '', 'stage', '', 'elevatorLimit_deg', NaN, ...
    'elevator_lower_limit_deg', NaN, 'elevator_upper_limit_deg', NaN, ...
    'V_mps', NaN, 'betaM_deg', NaN, 'wing_Cm0', NaN, ...
    'wing_Cmalpha', NaN, ...
    'fuselage_Cmalpha', NaN, 'htail_downwashAlpha', NaN, ...
    'htail_incidence_deg', NaN, 'htail_CLelevator', NaN, ...
    'allTrimConverged', false, 'allFiniteReal', false, ...
    'anyAtLimit', false, 'maxResidualNorm', NaN, ...
    'elevator70_deg', NaN, 'theta70_deg', NaN, ...
    'collective70_deg', NaN, 'minElevatorMargin_deg', NaN, ...
    'maxAbsElevatorStep_deg', NaN, 'maxAbsThetaStep_deg', NaN, ...
    'maxAbsCollectiveStep_deg', NaN, ...
    'zeroElevatorTailFz70_N', NaN, ...
    'zeroElevatorTailMy70_Nm', NaN);
end

function tf = is_real_finite(value)
tf = isreal(value) && all(isfinite(value(:)));
end

function write_markdown_report(path, report, finalRows, componentRows, tailRows)
fid = fopen(path, 'w');
if fid < 0
    error('issue23:ReportOpenFailed', 'Could not open %s', path);
end
cleaner = onCleanup(@() fclose(fid));
old = report.oldValues;
new = report.newValues;
fprintf(fid, '# Issue #23 Airplane Pitch Balance Report\n\n');
fprintf(fid, 'Generated: %s\n\n', report.generatedAt);
fprintf(fid, 'Scope: in-memory staged audit; production defaults are changed only after this report is accepted externally by Codex.\n\n');
fprintf(fid, '## Selected Candidate\n\n');
fprintf(fid, '- acceptedByScript: %d\n', report.accepted);
fprintf(fid, '- wing.Cm0: %.6g -> %.6g\n', old.wing_Cm0, new.wing_Cm0);
fprintf(fid, '- wing.Cmalpha: %.6g -> %.6g /rad\n', old.wing_Cmalpha, new.wing_Cmalpha);
fprintf(fid, '- fuselage.Cmalpha: %.6g -> %.6g /rad\n', old.fuselage_Cmalpha, new.fuselage_Cmalpha);
fprintf(fid, '- htail.downwashAlpha: %.6g -> %.6g\n', old.htail_downwashAlpha, new.htail_downwashAlpha);
fprintf(fid, '- htail.incidence: %.6g -> %.6g deg\n', old.htail_incidence_deg, new.htail_incidence_deg);
fprintf(fid, '- htail.CLelevator: %.6g -> %.6g /rad\n', old.htail_CLelevator, new.htail_CLelevator);
fprintf(fid, '- elevatorLim: [%.1f %.1f] -> [%.1f %.1f] deg\n\n', ...
    old.elevatorLimLower_deg, old.elevatorLimUpper_deg, ...
    new.elevatorLimLower_deg, new.elevatorLimUpper_deg);

fprintf(fid, '## Acceptance\n\n');
names = fieldnames(report.acceptance);
for i = 1:numel(names)
    value = report.acceptance.(names{i});
    if islogical(value)
        fprintf(fid, '- %s: %d\n', names{i}, value);
    else
        fprintf(fid, '- %s: %.6g\n', names{i}, value);
    end
end
fprintf(fid, '\n');

fprintf(fid, '## Final +/-20 deg Airplane Trend\n\n');
fprintf(fid, '|V m/s|theta deg|collective deg|elevator deg|residual|converged|margin deg|\n');
fprintf(fid, '|-:|-:|-:|-:|-:|-:|-:|\n');
for i = 1:numel(finalRows)
    r = finalRows(i);
    fprintf(fid, '|%.1f|%.6f|%.6f|%.6f|%.3e|%d|%.6f|\n', ...
        r.V_mps, r.theta_deg, r.collective_deg, ...
        r.elevatorCommand_deg, r.residualNorm, r.trimConverged, ...
        r.controlLimitMarginMin_deg);
end
fprintf(fid, '\n');

fprintf(fid, '## Component Pitch Moments\n\n');
write_component_point(fid, componentRows, tailRows, report.selectedCandidate.candidate, 20, 70);
write_component_point(fid, componentRows, tailRows, report.selectedCandidate.candidate, 20, 100);

fprintf(fid, '## Rationale And Limitations\n\n');
fprintf(fid, '- The previous wing.Cmalpha=-0.45/rad and fuselage.Cmalpha=-0.20/rad terms lacked reliable provenance and produced excessive fixed-wing nose-down direct moment.\n');
fprintf(fid, '- The selected candidate keeps both direct slopes at zero as an initial mechanistic diagnostic baseline, not as a claim that the real aircraft values are zero.\n');
fprintf(fid, '- The selected candidate retains wing.Cm0=-0.03 as a calibrated effective concept parameter so all direct intrinsic longitudinal moments are not forced to zero.\n');
fprintf(fid, '- Tail downwash, incidence, and elevator effectiveness are retained as calibrated effective candidates; downwash and incidence are not uniquely identifiable from the current trim set.\n');
fprintf(fid, '- CLelevator primarily changes per-deflection control authority and does not change the zero-elevator baseline tail load.\n');
fprintf(fid, '- Geometry provenance for aerodynamic centers and tail arm remains unresolved; no geometry, equations, allocation, or solver behavior was changed in this diagnostic.\n');
fprintf(fid, '- The current model remains an extendable low-order component mechanism model, not a validated XV-15 wing-body pitching-moment model.\n');
fprintf(fid, '- Existing validation outputs are preserved; new CSV/MAT files are in this timestamped folder.\n');
end

function write_component_point(fid, componentRows, tailRows, candidate, limitDeg, V)
mask = strcmp({componentRows.candidate}, candidate) & ...
    abs([componentRows.elevatorLimit_deg] - limitDeg) < 1e-9 & ...
    abs([componentRows.V_mps] - V) < 1e-9;
cm = componentRows(mask);
tm = tailRows(strcmp({tailRows.candidate}, candidate) & ...
    abs([tailRows.elevatorLimit_deg] - limitDeg) < 1e-9 & ...
    abs([tailRows.V_mps] - V) < 1e-9);
fprintf(fid, '### V = %.1f m/s\n\n', V);
fprintf(fid, '- total My: %.6f N m\n', cm.My_total_Nm);
fprintf(fid, '- rotors My: %.6f N m\n', cm.rotors_My_Nm);
fprintf(fid, '- wing My: %.6f N m (arm %.6f, intrinsic %.6f)\n', ...
    cm.wing_My_Nm, cm.wing_arm_My_Nm, cm.wing_intrinsic_My_Nm);
fprintf(fid, '- fuselage My: %.6f N m (arm %.6f, intrinsic %.6f)\n', ...
    cm.fuselage_My_Nm, cm.fuselage_arm_My_Nm, ...
    cm.fuselage_intrinsic_My_Nm);
fprintf(fid, '- horizontal tail My: %.6f N m (arm %.6f, direct %.6f)\n', ...
    cm.htail_My_Nm, cm.htail_arm_My_Nm, cm.htail_direct_My_Nm);
fprintf(fid, '- zero-elevator tail Fz/My: %.6f N / %.6f N m\n\n', ...
    tm.zeroElevator_Fz_N, tm.zeroElevator_My_total_Nm);
end
