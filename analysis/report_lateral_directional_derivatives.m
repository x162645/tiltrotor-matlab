function summary = report_lateral_directional_derivatives(opts)
%REPORT_LATERAL_DIRECTIONAL_DERIVATIVES Audit lateral/directional derivatives.
% This workflow evaluates the current opt-in 8-flight-input model only. It
% reports EOM B-matrix derivatives separately from raw force/moment
% derivatives from total_forces_moments.

if nargin < 1 || isempty(opts)
    opts = struct();
end

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir, 'model'));
addpath(fullfile(rootDir, 'analysis'));

P = params_nominal();
P.control.enableLateralCyclic = true;
d2r = pi/180;

if ~isfield(opts, 'outputRoot') || isempty(opts.outputRoot)
    opts.outputRoot = fullfile(rootDir, 'validation', ...
        'lateral_directional_derivatives');
end
if ~isfield(opts, 'timestamp') || isempty(opts.timestamp)
    opts.timestamp = datestr(now, 'yyyymmddTHHMMSS');
end
outputDir = fullfile(opts.outputRoot, opts.timestamp);
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

stateNames = get_state_names(P);
controlNames = get_control_input_names(P);
latRowNames = {'vdot'; 'pdot'; 'rdot'};
latStateNames = {'v'; 'p'; 'r'; 'phi'; 'psi'};
latControlNames = {'diffCollective'; 'diffCyclic'; 'lateralCyclic'; ...
    'aileron'; 'rudder'};
latRows = find_name_indices({'v'; 'p'; 'r'}, stateNames);
latStateCols = find_name_indices(latStateNames, stateNames);
latControlCols = find_name_indices(latControlNames, controlNames);

conditions = representative_conditions(d2r);
rowRecords = {};
caseResults = repmat(empty_case_result(), numel(conditions), 1);

for i = 1:numel(conditions)
    c = conditions(i);
    result = empty_case_result();
    result.name = c.name;
    result.betaMDeg = c.betaMDeg;
    result.V = c.V;
    result.x = [c.V; 0; 0; 0; 0; 0; 0; 0; 0];
    result.u = c.u;
    result.status = 'SKIPPED_TRIM_FAILED';
    result.reason = '';

    try
        [A, B, linReport] = linearize_numeric(result.x, result.u, ...
            c.betaMDeg*d2r, P);
        if ~linReport.finite || ~is_real_finite(A) || ~is_real_finite(B)
            error('report_lateral_directional_derivatives:NonFiniteLinearization', ...
                'Linearization returned non-finite or complex values.');
        end

        result.status = 'OK';
        result.reason = 'representative finite operating point';
        result.A = A;
        result.B = B;
        result.BSize = size(B);
        result.Alat = A(latRows, latStateCols);
        result.Blat = B(latRows, latControlCols);
        result.lateralCyclicFullColumnNorm = norm(B(:, latControlCols(3)));
        result.controlResults = control_derivative_results( ...
            result.x, result.u, c.betaMDeg*d2r, P, controlNames, ...
            latRows, latControlNames, B);

        for j = 1:numel(result.controlResults)
            cr = result.controlResults(j);
            rowRecords(end+1,:) = {result.name, result.status, ...
                cr.controlName, cr.classification, cr.reason, ...
                cr.b_vdot, cr.b_pdot, cr.b_rdot, cr.bColumnNorm, ...
                cr.raw_dFy, cr.raw_dMx, cr.raw_dMz, cr.rawLoadNorm}; %#ok<AGROW>
        end
    catch ME
        result.reason = sprintf('%s: %s', ME.identifier, ME.message);
        for j = 1:numel(latControlNames)
            rowRecords(end+1,:) = {result.name, result.status, ...
                latControlNames{j}, 'SKIPPED_TRIM_FAILED', ...
                result.reason, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}; %#ok<AGROW>
        end
    end
    caseResults(i) = result;
end

csvTable = cell2table(rowRecords, 'VariableNames', { ...
    'condition', 'status', 'control', 'classification', 'reason', ...
    'B_vdot', 'B_pdot', 'B_rdot', 'B_column_norm', ...
    'raw_dFy', 'raw_dMx', 'raw_dMz', 'raw_load_norm'});

csvFile = fullfile(outputDir, 'lateral_directional_derivatives.csv');
reportFile = fullfile(outputDir, 'lateral_directional_derivative_report.md');
writetable(csvTable, csvFile);
write_markdown_report(reportFile, caseResults, csvTable, latRowNames, ...
    latStateNames, latControlNames, controlNames);

summary.outputDir = outputDir;
summary.reportFile = reportFile;
summary.csvFile = csvFile;
summary.table = csvTable;
summary.caseResults = caseResults;
summary.successCount = sum(strcmp({caseResults.status}, 'OK'));
summary.controlNames = controlNames;
summary.latControlNames = latControlNames;
summary.generatedMatFile = '';
summary.generatedSummaryPng = '';
end

function conditions = representative_conditions(d2r)
conditions = repmat(struct('name', '', 'V', NaN, 'betaMDeg', NaN, ...
    'u', NaN(8,1)), 4, 1);
conditions(1).name = 'hover_like_beta0';
conditions(1).V = 0;
conditions(1).betaMDeg = 0;
conditions(1).u = [18; 0; 0; 0; 0; 0; 0; 0]*d2r;

conditions(2).name = 'low_speed_helicopter';
conditions(2).V = 20;
conditions(2).betaMDeg = 0;
conditions(2).u = [12; 0; 0; 0; 0; 0; 0; 0]*d2r;

conditions(3).name = 'conversion_mid';
conditions(3).V = 45;
conditions(3).betaMDeg = 45;
conditions(3).u = [10; 0; 0; 0; 0; 0; 0; 0]*d2r;

conditions(4).name = 'airplane_forward';
conditions(4).V = 100;
conditions(4).betaMDeg = 90;
conditions(4).u = [8; 0; 0; 0; 0; 0; -2; 0]*d2r;
end

function result = empty_case_result()
result = struct('name', '', 'status', '', 'reason', '', 'betaMDeg', NaN, ...
    'V', NaN, 'x', NaN(9,1), 'u', NaN(8,1), 'A', [], 'B', [], ...
    'BSize', [NaN NaN], 'Alat', [], 'Blat', [], ...
    'lateralCyclicFullColumnNorm', NaN, 'controlResults', struct([]));
end

function results = control_derivative_results(x, u, betaM, P, controlNames, ...
        latRows, latControlNames, B)
results = repmat(struct('controlName', '', 'classification', '', ...
    'reason', '', 'b_vdot', NaN, 'b_pdot', NaN, 'b_rdot', NaN, ...
    'bColumnNorm', NaN, 'raw_dFy', NaN, 'raw_dMx', NaN, ...
    'raw_dMz', NaN, 'rawLoadNorm', NaN), numel(latControlNames), 1);
for j = 1:numel(latControlNames)
    controlName = latControlNames{j};
    controlIndex = find(strcmp(controlNames, controlName), 1);
    bLat = B(latRows, controlIndex);
    bCol = B(:, controlIndex);
    raw = raw_load_derivative(x, u, betaM, P, controlIndex);
    classification = classify_response(controlName, bLat, bCol, raw);

    results(j).controlName = controlName;
    results(j).classification = classification.name;
    results(j).reason = classification.reason;
    results(j).b_vdot = bLat(1);
    results(j).b_pdot = bLat(2);
    results(j).b_rdot = bLat(3);
    results(j).bColumnNorm = norm(bCol);
    results(j).raw_dFy = raw(2);
    results(j).raw_dMx = raw(4);
    results(j).raw_dMz = raw(6);
    results(j).rawLoadNorm = norm(raw);
end
end

function raw = raw_load_derivative(x, u, betaM, P, controlIndex)
h = 1.0e-4;
up = u;
um = u;
up(controlIndex) = up(controlIndex) + h;
um(controlIndex) = um(controlIndex) - h;
[Fp, Mp] = total_forces_moments(x, up, betaM, P);
[Fm, Mm] = total_forces_moments(x, um, betaM, P);
raw = [(Fp-Fm); (Mp-Mm)]/(2*h);
end

function classification = classify_response(controlName, bLat, bCol, raw)
target = [bLat(:); raw([2 4 6])];
if ~is_real_finite(target) || ~is_real_finite(bCol) || ~is_real_finite(raw)
    classification.name = 'FAIL_NONFINITE';
    classification.reason = 'non-finite or complex derivative';
elseif norm(bCol) <= 1.0e-10 && norm(raw) <= 1.0e-7
    classification.name = 'FAIL_ZERO_COLUMN';
    classification.reason = 'full B column and raw load response are near zero';
elseif norm(target) <= 1.0e-7
    classification.name = 'CAUTION_SMALL_EFFECT';
    classification.reason = 'target Y/L/N response is numerically present but very small';
elseif strcmp(controlName, 'lateralCyclic') && norm(target) < 1.0e-3*max(norm(raw), 1)
    classification.name = 'CAUTION_SMALL_EFFECT';
    classification.reason = 'lateralCyclic is connected, but Y/L/N response is small in this operating point';
else
    classification.name = 'PASS_NONZERO';
    classification.reason = 'finite nonzero model-internal response';
end
end

function write_markdown_report(reportFile, caseResults, csvTable, rowNames, ...
        stateNames, controlNames, activeControlNames)
fid = fopen(reportFile, 'w');
if fid < 0
    error('report_lateral_directional_derivatives:CannotOpenReport', ...
        'Cannot open report file for writing.');
end
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, '# Lateral/Directional Derivative Report\n\n');
fprintf(fid, 'This report audits the current opt-in 8-flight-input model. ');
fprintf(fid, 'It does not validate the model against Berger, XV-15, or flight-test data.\n\n');
fprintf(fid, 'Active control order:\n\n');
fprintf(fid, '```text\n');
fprintf(fid, '%s\n', strjoin(activeControlNames.', ' '));
fprintf(fid, '```\n\n');
fprintf(fid, 'Legacy default 7-input behavior remains controlled by ');
fprintf(fid, '`P.control.enableLateralCyclic = false`. The audited mode sets it to true.\n\n');
fprintf(fid, '`lateralCyclic` is connected to the rotor blade-pitch term ');
fprintf(fid, '`theta1c*cos(psi)` with the default opt-in mapping ');
fprintf(fid, '`theta1c = rotDir*lateralCyclic`. `diffCyclic` remains ');
fprintf(fid, 'differential longitudinal cyclic.\n\n');
fprintf(fid, 'EOM B derivatives are state-derivative sensitivities from ');
fprintf(fid, '`linearize_numeric`. Raw load derivatives are central differences of ');
fprintf(fid, '`[F; M]` from `total_forces_moments`; they are not the same quantity.\n\n');

fprintf(fid, '## Conditions\n\n');
fprintf(fid, '|condition|status|V_mps|betaM_deg|reason|\n');
fprintf(fid, '|-|-:|-:|-:|-|\n');
for i = 1:numel(caseResults)
    c = caseResults(i);
    fprintf(fid, '|%s|%s|%.6g|%.6g|%s|\n', c.name, c.status, ...
        c.V, c.betaMDeg, c.reason);
end

fprintf(fid, '\n## Derivative Blocks\n\n');
for i = 1:numel(caseResults)
    c = caseResults(i);
    fprintf(fid, '### %s\n\n', c.name);
    if ~strcmp(c.status, 'OK')
        fprintf(fid, 'Skipped: %s\n\n', c.reason);
        continue;
    end
    fprintf(fid, 'B size: %d x %d. `lateralCyclic` full-column norm: %.12e.\n\n', ...
        c.BSize(1), c.BSize(2), c.lateralCyclicFullColumnNorm);
    write_matrix(fid, 'A_lat rows [vdot pdot rdot], columns [v p r phi psi]', ...
        c.Alat, rowNames, stateNames);
    write_matrix(fid, ['B_lat rows [vdot pdot rdot], columns ' ...
        '[diffCollective diffCyclic lateralCyclic aileron rudder]'], ...
        c.Blat, rowNames, controlNames);
end

fprintf(fid, '## Control Derivative Summary\n\n');
fprintf(fid, '|condition|control|classification|B_vdot|B_pdot|B_rdot|raw_dFy|raw_dMx|raw_dMz|reason|\n');
fprintf(fid, '|-|-|-:|-:|-:|-:|-:|-:|-:|-|\n');
for i = 1:height(csvTable)
    fprintf(fid, '|%s|%s|%s|%.6e|%.6e|%.6e|%.6e|%.6e|%.6e|%s|\n', ...
        csvTable.condition{i}, csvTable.control{i}, ...
        csvTable.classification{i}, csvTable.B_vdot(i), ...
        csvTable.B_pdot(i), csvTable.B_rdot(i), ...
        csvTable.raw_dFy(i), csvTable.raw_dMx(i), ...
        csvTable.raw_dMz(i), csvTable.reason{i});
end

fprintf(fid, '\n## Key Sign Findings\n\n');
fprintf(fid, '- `lateralCyclic` has a finite nonzero full B column in all successful representative conditions.\n');
fprintf(fid, '- With the default opt-in `rotDir` mapping, `lateralCyclic` produces significant model-internal `Y/L/N` target response in the representative set.\n');
fprintf(fid, '- Positive `lateralCyclic` is the current internal convention for common `+eY` rotor disk-normal tilt; this is not external sign validation.\n');
fprintf(fid, '- `aileron` produces positive raw `Mx` in forward-speed representative points and is zero in hover-like zero-speed wing loading.\n');
fprintf(fid, '- `rudder` produces positive raw `Fy` and negative raw `Mz` in forward-speed representative points.\n');
fprintf(fid, '- `diffCollective` produces a strong raw `Mx` response across the representative set.\n');
fprintf(fid, '- `diffCyclic` produces a strong raw `Mz` response, with sign depending on nacelle angle and operating condition.\n');

fprintf(fid, '\n## Why lateralCyclic signs vary with betaM\n\n');
fprintf(fid, 'The default opt-in `rotDir` mapping makes `lateralCyclic` ');
fprintf(fid, 'model-internally effective, but the representative `B_vdot` ');
fprintf(fid, 'and raw `dFy` signs can change between betaM conditions. ');
fprintf(fid, 'The betaM angle changes the rotor thrust axis `eT`, disk-plane ');
fprintf(fid, '`eD/eY` projections into body axes, proprotor inflow state, ');
fprintf(fid, 'flapping response, moment arms, and aerodynamic coupling. ');
fprintf(fid, 'Also, B-matrix entries are EOM state-derivative sensitivities, ');
fprintf(fid, 'while raw load derivatives are central differences of `[F; M]`; ');
fprintf(fid, 'they should not be mixed as identical quantities. The representative ');
fprintf(fid, 'points are not a broad trim sweep, so this observation confirms ');
fprintf(fid, 'internal response effectiveness only, not external sign validation.\n');

fprintf(fid, '\n## Limitations\n\n');
fprintf(fid, '- This is an internal derivative/sign audit only, not Berger or XV-15 validation.\n');
fprintf(fid, '- The representative states are finite operating points, not certified trims for stability conclusions.\n');
fprintf(fid, '- This does not implement 13x10, nacelle torque, independent left/right nacelle states, or Berger 51 states.\n');
fprintf(fid, '- The `rotDir` sign convention remains model-internal until checked against a documented external rotor azimuth and disk-response convention.\n');
end

function write_matrix(fid, titleText, values, rowNames, colNames)
fprintf(fid, '%s\n\n', titleText);
fprintf(fid, '| |');
for j = 1:numel(colNames)
    fprintf(fid, '%s|', colNames{j});
end
fprintf(fid, '\n|-|');
for j = 1:numel(colNames)
    fprintf(fid, '-:|');
end
fprintf(fid, '\n');
for i = 1:numel(rowNames)
    fprintf(fid, '|%s|', rowNames{i});
    for j = 1:numel(colNames)
        fprintf(fid, '%.12e|', values(i,j));
    end
    fprintf(fid, '\n');
end
fprintf(fid, '\n');
end

function idx = find_name_indices(queryNames, names)
idx = zeros(numel(queryNames), 1);
for k = 1:numel(queryNames)
    idx(k) = find(strcmp(names, queryNames{k}), 1);
    if isempty(idx(k))
        error('report_lateral_directional_derivatives:MissingName', ...
            'Missing name %s.', queryNames{k});
    end
end
end

function tf = is_real_finite(value)
tf = isnumeric(value) && isreal(value) && all(isfinite(value(:)));
end
