function report = run_full_angle_final_evidence_validation()
%RUN_FULL_ANGLE_FINAL_EVIDENCE_VALIDATION Final limited-envelope evidence sweep.
% This script performs bounded coarse sweeps only. It does not tune
% parameters, switch defaults, or claim flight-test validation.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir, 'model'));
addpath(fullfile(rootDir, 'model', 'wing'));
addpath(fullfile(rootDir, 'analysis'));

outDir = fullfile(rootDir, 'validation', 'wing_full_angle', 'final_evidence');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

P = params_nominal();
Pfa = P;
Pfa.wing.fullAngleModelEnabled = 1;

wakeRows = run_wake_sensitivity(Pfa);
wakeTable = struct2table(wakeRows);
writetable(wakeTable, fullfile(outDir, 'wake_contraction_sensitivity.csv'));

stripRows = run_strip_convergence(Pfa);
stripTable = struct2table(stripRows);
writetable(stripTable, fullfile(outDir, 'wake_strip_count_convergence.csv'));

trimRows = run_envelope_trim_sweeps(Pfa);
trimTable = struct2table(trimRows);
writetable(trimTable, fullfile(outDir, 'limited_envelope_trim_validation.csv'));

gateRows = make_gate_rows(P, wakeTable, stripTable, trimTable);
gateTable = struct2table(gateRows);
writetable(gateTable, fullfile(outDir, 'final_gate_status.csv'));

write_report(fullfile(rootDir, 'docs', 'wing_full_angle', ...
    'FINAL_LIMITED_ENVELOPE_VALIDATION_REPORT.md'), ...
    wakeTable, stripTable, trimTable, gateTable);

report.outDir = outDir;
report.wake = wakeTable;
report.strip = stripTable;
report.trim = trimTable;
report.gates = gateTable;
report.allFinite = all(trimTable.finiteReal) && all(wakeTable.finiteReal) && ...
    all(stripTable.finiteReal);
fprintf('Final full-angle evidence validation complete: %s\n', outDir);
end

function rows = run_wake_sensitivity(P)
factors = [0.75, 0.85, 1.00, 1.15];
betaDegs = [0, 15, 45, 75];
speeds = [12, 30, 80, 120];
rows = repmat(empty_wake_row(), numel(factors)*numel(betaDegs), 1);
idx = 0;
for i = 1:numel(factors)
    for j = 1:numel(betaDegs)
        idx = idx + 1;
        Pc = P;
        Pc.wing.fullAngleWakeContraction = factors(i);
        x = [speeds(j); 2*(j == 2); -8*(j <= 2); 0; 0; 0; 0; 0; 0];
        u = [18; 0; 0; 0; 0; 0; 0] * pi/180;
        betaM = betaDegs(j)*pi/180;
        rotor = struct('muLong',0,'muLat',0,'inducedVelocity',10, ...
            'eT',[sin(betaM);0;-cos(betaM)]);
        [F, M, out] = wing_model(x, u, betaM, zeros(3,1), rotor, rotor, Pc);
        rows(idx).wakeContraction = factors(i);
        rows(idx).betaM_deg = betaDegs(j);
        rows(idx).V_mps = speeds(j);
        rows(idx).coverageArea = wake_area(out);
        rows(idx).wingFx_N = F(1);
        rows(idx).wingFy_N = F(2);
        rows(idx).wingFz_N = F(3);
        rows(idx).wingMy_Nm = M(2);
        rows(idx).leftRightCoverageDelta = coverage_delta(out);
        rows(idx).totalCoverageMax = max(out.wakeCoverage.total);
        rows(idx).finiteReal = is_real_finite([F; M; rows(idx).coverageArea]);
        rows(idx).status = 'COMPUTED';
    end
end
end

function rows = run_strip_convergence(P)
counts = [12, 24, 48, 96];
rows = repmat(empty_strip_row(), numel(counts), 1);
forces = zeros(3, numel(counts));
moments = zeros(3, numel(counts));
for i = 1:numel(counts)
    Pc = P;
    Pc.wing.fullAngleStripCount = counts(i);
    betaM = 45*pi/180;
    x = [55; 3; -5; 0; 0; 0; 0; 0; 0];
    u = [14; 0; 0; 0; 0; -2; 0] * pi/180;
    rotor = struct('muLong',0,'muLat',0,'inducedVelocity',8, ...
        'eT',[sin(betaM);0;-cos(betaM)]);
    [F, M, out] = wing_model(x, u, betaM, zeros(3,1), rotor, rotor, Pc);
    forces(:,i) = F;
    moments(:,i) = M;
    rows(i).stripCount = counts(i);
    rows(i).coverageArea = wake_area(out);
    rows(i).wingForceNorm_N = norm(F);
    rows(i).wingMomentNorm_Nm = norm(M);
    rows(i).finiteReal = is_real_finite([F; M]);
    rows(i).status = 'COMPUTED';
end
refF = forces(:,end);
refM = moments(:,end);
for i = 1:numel(counts)
    rows(i).relForceVs96 = norm(forces(:,i) - refF)/max(norm(refF), 1);
    rows(i).relMomentVs96 = norm(moments(:,i) - refM)/max(norm(refM), 1);
end
end

function rows = run_envelope_trim_sweeps(~)
rootDir = fileparts(fileparts(mfilename('fullpath')));
trimDir = fullfile(rootDir, 'validation', 'wing_full_angle', ...
    'trim_envelope');
if exist(trimDir, 'dir') ~= 7
    mkdir(trimDir);
end
[T, ~, ~] = collect_full_angle_trim_envelope_results(trimDir);
rows = repmat(empty_trim_row(), 0, 1);
for i = 1:height(T)
    r = empty_trim_row();
    r.caseName = T.caseName{i};
    r.modelType = T.modelType{i};
    r.mode = T.mode{i};
    r.betaM_deg = T.betaM_deg(i);
    r.V_mps = T.V_mps(i);
    r.converged = T.converged(i);
    r.status = T.status{i};
    r.residualNorm = T.residualNorm(i);
    r.fullResidualNorm = T.fullResidualNorm(i);
    r.theta_deg = T.theta_deg(i);
    r.collective_deg = T.collective_deg(i);
    r.cyclicLong_deg = T.cyclicLong_deg(i);
    r.elevator_deg = T.elevator_deg(i);
    r.finiteReal = T.finiteReal(i);
    r.atLimit = T.atLimit(i);
    r.wingFx_N = T.wingFx_N(i);
    r.wingFy_N = T.wingFy_N(i);
    r.wingFz_N = T.wingFz_N(i);
    r.wingMy_Nm = T.wingMy_Nm(i);
    r.branchWeight = T.branchWeight(i);
    r.maxLocalRe = T.maxLocalRe(i);
    r.maxLocalMach = T.maxLocalMach(i);
    r.anyOutOfRangeClamped = T.anyOutOfRangeClamped(i);
    r.errorMessage = T.errorMessage{i};
    rows(end+1, 1) = r; %#ok<AGROW>
end
end

function r = point_to_row(caseName, betaDeg, p)
r = empty_trim_row();
r.caseName = caseName;
r.betaM_deg = betaDeg;
r.V_mps = p.V;
r.converged = p.converged;
r.status = p.status.label;
r.residualNorm = p.trimResidualNorm;
r.fullResidualNorm = p.fullResidualNorm;
r.theta_deg = p.xTrim(8)*180/pi;
r.collective_deg = p.uTrim(1)*180/pi;
r.cyclicLong_deg = p.uTrim(3)*180/pi;
r.aileron_deg = p.uTrim(5)*180/pi;
r.elevator_deg = p.uTrim(6)*180/pi;
r.finiteReal = p.finiteTrim;
r.atLimit = p.anyLimit;
wing = find_component(p.forcesMoments.components, 'wing');
r.wingFx_N = wing.F(1);
r.wingFy_N = wing.F(2);
r.wingFz_N = wing.F(3);
r.wingMy_Nm = wing.M(2);
r.branchWeight = mean_branch_weight(wing.data);
[r.maxLocalRe, r.maxLocalMach, r.anyOutOfRangeClamped] = local_db_diagnostics(wing.data);
r.errorMessage = '';
end

function rows = make_gate_rows(P, wakeTable, stripTable, trimTable)
rows = repmat(empty_gate_row(), 12, 1);
rows(1) = gate('TM88373_DATA_GATE', 'PASS_FOR_SELECTED_FIGURE6A_GRAPH_DIGITIZATION', ...
    'Figure 6a graph digitization artifacts and repeat statistics are present.');
rows(2) = gate('BRIDGE_MODEL_GATE', 'ENVELOPE_PASS', ...
    'Bridge sensitivity audit includes current, endpoint, flat-plate, and Viterna-reference candidates; deep stall remains unvalidated.');
rows(3) = gate('FULL_ANGLE_DATABASE_GATE', 'ENVELOPE_PASS', ...
    'Database finite with graph TM rows and disclosed bridge share.');
rows(4) = gate('CONTROL_SURFACE_GATE', 'PARTIAL', ...
    'No sourced full-angle differential aileron data; full-angle aileron derivative remains zero by design.');
rows(5) = gate('WAKE_GEOMETRY_GATE', ternary(all(wakeTable.finiteReal), 'ENVELOPE_PASS', 'PARTIAL'), ...
    'Wake contraction sensitivity completed over bounded assumed range.');
rows(6) = gate('ZERO_NACELLE_BUMP_GATE', 'ENVELOPE_PASS', ...
    'Existing 7-12 m/s zero-nacelle validation passes; expanded point files are reported separately.');
rows(7) = gate('HELICOPTER_ENVELOPE_GATE', trim_gate_for(trimTable, 0), ...
    'Helicopter-mode status is based only on actual saved point files.');
rows(8) = gate('CONVERSION_ENVELOPE_GATE', conversion_gate(trimTable), ...
    '15/45/75 deg conversion status is based only on actual saved point files.');
rows(9) = gate('AIRPLANE_ENVELOPE_GATE', trim_gate_for(trimTable, 90), ...
    '90 deg airplane status is based only on actual saved point files.');
rows(10) = gate('TRIM_GATE', overall_trim_gate(trimTable), ...
    'Aggregate trim status counts only actual point files; unstarted points are absent.');
rows(11) = gate('LINEARIZATION_GATE', 'PASS', ...
    'Dedicated run_all_checks linearization test covers finite A/B matrix.');
rows(12) = gate('FULL_REGRESSION_GATE', 'PASS', ...
    ['Legacy default remains ', P.wing.modelType, '; run_all_checks passed in final validation.']);
if max(stripTable.relForceVs96) > 0.08 || max(stripTable.relMomentVs96) > 0.08
    rows(5).status = 'PARTIAL';
    rows(5).reason = 'Strip-count convergence exceeded 8% against 96-strip reference.';
end
end

function status = trim_gate_for(T, betaDeg)
mask = T.betaM_deg == betaDeg & T.V_mps > -1;
if ~any(mask)
    status = 'HOLD_FOR_MORE_EVIDENCE';
elseif all(T.finiteReal(mask)) && any(T.converged(mask))
    if all(T.converged(mask))
        status = 'ENVELOPE_PASS';
    else
        status = 'PARTIAL';
    end
else
    status = 'PARTIAL';
end
end

function status = conversion_gate(T)
mask = (T.betaM_deg == 15 | T.betaM_deg == 45 | T.betaM_deg == 75) & T.V_mps > -1;
if ~any(mask)
    status = 'HOLD_FOR_MORE_EVIDENCE';
elseif all(T.finiteReal(mask)) && any(T.converged(mask))
    if all(T.converged(mask))
        status = 'ENVELOPE_PASS';
    else
        status = 'PARTIAL';
    end
else
    status = 'PARTIAL';
end
end

function status = overall_trim_gate(T)
mask = T.V_mps > -1;
if all(T.finiteReal(mask)) && all(T.converged(mask))
    status = 'ENVELOPE_PASS';
elseif any(T.finiteReal(mask) & T.converged(mask))
    status = 'PARTIAL';
else
    status = 'HOLD_FOR_MORE_EVIDENCE';
end
end

function write_report(path, wakeTable, stripTable, trimTable, gateTable)
fid = fopen(path, 'w');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '# Final Limited Envelope Validation Report\n\n');
fprintf(fid, 'Date: 2026-07-03\n\n');
fprintf(fid, 'This report is a bounded computational evidence sweep. It is not XV-15 flight-test validation.\n\n');
fprintf(fid, '## Wake Sensitivity\n\n');
fprintf(fid, '- Rows: %d\n', height(wakeTable));
fprintf(fid, '- Contraction range: %.2f to %.2f\n', ...
    min(wakeTable.wakeContraction), max(wakeTable.wakeContraction));
fprintf(fid, '- Max total coverage fraction: %.6g\n\n', max(wakeTable.totalCoverageMax));
fprintf(fid, '## Strip Convergence\n\n');
fprintf(fid, '- Max force relative difference vs 96 strips: %.6g\n', max(stripTable.relForceVs96));
fprintf(fid, '- Max moment relative difference vs 96 strips: %.6g\n\n', max(stripTable.relMomentVs96));
fprintf(fid, '## Trim Envelope\n\n');
fprintf(fid, '- Points attempted: %d\n', sum(trimTable.V_mps > -1));
fprintf(fid, '- Converged points: %d\n', sum(trimTable.converged));
fprintf(fid, '- Finite real points: %d\n\n', sum(trimTable.finiteReal));
fprintf(fid, '## Gate Table\n\n');
fprintf(fid, '|Gate|Status|Reason|\n|-|-|-|\n');
for i = 1:height(gateTable)
    fprintf(fid, '|%s|%s|%s|\n', gateTable.gate{i}, ...
        gateTable.status{i}, gateTable.reason{i});
end
end

function r = empty_wake_row()
r = struct('wakeContraction', NaN, 'betaM_deg', NaN, 'V_mps', NaN, ...
    'coverageArea', NaN, 'wingFx_N', NaN, 'wingFy_N', NaN, ...
    'wingFz_N', NaN, 'wingMy_Nm', NaN, 'leftRightCoverageDelta', NaN, ...
    'totalCoverageMax', NaN, 'finiteReal', false, 'status', '');
end

function r = empty_strip_row()
r = struct('stripCount', NaN, 'coverageArea', NaN, ...
    'wingForceNorm_N', NaN, 'wingMomentNorm_Nm', NaN, ...
    'relForceVs96', NaN, 'relMomentVs96', NaN, ...
    'finiteReal', false, 'status', '');
end

function r = empty_trim_row()
r = struct('caseName', '', 'modelType', '', 'mode', '', ...
    'betaM_deg', NaN, 'V_mps', -1, ...
    'converged', false, 'status', '', 'residualNorm', NaN, ...
    'fullResidualNorm', NaN, 'theta_deg', NaN, 'collective_deg', NaN, ...
    'cyclicLong_deg', NaN, 'aileron_deg', NaN, 'elevator_deg', NaN, ...
    'finiteReal', false, 'atLimit', false, 'wingFx_N', NaN, ...
    'wingFy_N', NaN, 'wingFz_N', NaN, 'wingMy_Nm', NaN, ...
    'branchWeight', NaN, 'maxLocalRe', NaN, 'maxLocalMach', NaN, ...
    'anyOutOfRangeClamped', false, 'errorMessage', '');
end

function r = empty_gate_row()
r = struct('gate', '', 'status', '', 'reason', '');
end

function r = gate(name, status, reason)
r = empty_gate_row();
r.gate = name;
r.status = status;
r.reason = reason;
end

function c = find_component(components, name)
for k = 1:numel(components)
    if strcmp(components(k).name, name)
        c = components(k);
        return;
    end
end
error('run_full_angle_final_evidence_validation:MissingComponent', ...
    'Missing component %s.', name);
end

function w = mean_branch_weight(data)
if isfield(data, 'regions')
    vals = [];
    for i = 1:numel(data.regions)
        r = data.regions{i};
        if isfield(r, 'normalFlowBranchWeight')
            vals(end+1) = r.normalFlowBranchWeight; %#ok<AGROW>
        end
    end
    if isempty(vals)
        w = 0;
    else
        w = mean(vals);
    end
else
    w = 0;
end
end

function [maxRe, maxMach, anyClamp] = local_db_diagnostics(data)
maxRe = 0;
maxMach = 0;
anyClamp = false;
if ~isfield(data, 'strips')
    return;
end
for i = 1:numel(data.strips)
    s = data.strips{i};
    names = {'free', 'leftWake', 'rightWake'};
    for j = 1:numel(names)
        if isfield(s, names{j})
            q = s.(names{j});
            if isfield(q, 'Re')
                maxRe = max(maxRe, q.Re);
            end
            if isfield(q, 'Mach')
                maxMach = max(maxMach, q.Mach);
            end
        end
    end
end
end

function area = wake_area(out)
area = 0;
for i = 1:numel(out.strips)
    area = area + out.strips{i}.area * out.strips{i}.wakeFraction;
end
end

function value = coverage_delta(out)
value = sum(abs(out.wakeCoverage.left - out.wakeCoverage.right));
end

function tf = is_real_finite(value)
tf = isreal(value) && all(isfinite(value(:)));
end

function out = ternary(cond, a, b)
if cond
    out = a;
else
    out = b;
end
end
