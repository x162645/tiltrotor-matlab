function audit = audit_pitch_control_authority_source(opts)
%AUDIT_PITCH_CONTROL_AUTHORITY_SOURCE Audit pitch controls and sources.
%
% This is an opt-in diagnostic only. It reads the committed PR #46
% longitudinal robustness evidence, computes local finite-difference control
% effectiveness around the baseline points, and writes text-only evidence.
% It does not change params_nominal defaults, solver defaults,
% services/run_trim_case behavior, GUI behavior, control limits, or default
% lateralCyclic enablement.

if nargin < 1 || isempty(opts)
    opts = struct();
end

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir, 'model'));
addpath(fullfile(rootDir, 'analysis'));
addpath(fullfile(rootDir, 'services'));

opts = apply_defaults(opts, rootDir);
if exist(opts.outputDir, 'dir') ~= 7
    mkdir(opts.outputDir);
end

P = params_nominal();
pr46 = load_pr46_records(opts.pr46SummaryCsv);
sourceInventory = build_source_inventory(P);
controlChain = build_control_chain_map(P);

effectiveness = repmat(empty_effectiveness_record(), 0, 1);
allocation = repmat(empty_allocation_record(), 0, 1);
signMapping = repmat(empty_sign_record(), 0, 1);

for iCase = 1:numel(opts.cases)
    caseDef = opts.cases(iCase);
    fprintf('Pitch authority audit: case=%s\n', caseDef.name);
    base = baseline_point(caseDef, pr46, P);
    derivatives = local_derivatives(base, P, opts);
    effectiveness = [effectiveness; effectiveness_records(base, ...
        derivatives, P)]; %#ok<AGROW>
    allocation = [allocation; allocation_records(base, derivatives, ...
        P)]; %#ok<AGROW>
    signMapping = [signMapping; sign_records(base, derivatives, P)]; %#ok<AGROW>
end

summary = build_summary(pr46, effectiveness, allocation, signMapping);

audit.outputDir = opts.outputDir;
audit.reportFile = fullfile(opts.outputDir, ...
    'PITCH_CONTROL_AUTHORITY_SOURCE_AUDIT.md');
audit.sourceInventoryCsvFile = fullfile(opts.outputDir, ...
    'pitch_control_source_inventory.csv');
audit.effectivenessCsvFile = fullfile(opts.outputDir, ...
    'pitch_control_effectiveness.csv');
audit.allocationCsvFile = fullfile(opts.outputDir, ...
    'pitch_control_authority_allocation.csv');
audit.signMappingCsvFile = fullfile(opts.outputDir, ...
    'pitch_control_sign_mapping_sensitivity.csv');
audit.summaryJsonFile = fullfile(opts.outputDir, ...
    'pitch_control_authority_summary.json');
audit.pr46 = pr46;
audit.controlChain = controlChain;
audit.sourceInventory = sourceInventory;
audit.effectiveness = effectiveness;
audit.allocation = allocation;
audit.signMapping = signMapping;
audit.summary = summary;
audit.caseCount = numel(opts.cases);
audit.runHeavy = opts.runHeavy;
audit.scope = ['Internal pitch control authority/source diagnostic; not ' ...
    'external validation and not a solver/default-path change.'];

writetable(struct2table(sourceInventory), audit.sourceInventoryCsvFile);
writetable(struct2table(effectiveness), audit.effectivenessCsvFile);
writetable(struct2table(allocation), audit.allocationCsvFile);
writetable(struct2table(signMapping), audit.signMappingCsvFile);
write_json(audit.summaryJsonFile, audit);
write_markdown(audit.reportFile, audit);

fprintf('\nPitch control authority/source audit\n');
fprintf('====================================\n');
fprintf('Output directory: %s\n', audit.outputDir);
fprintf('Cases: %d, effectiveness rows: %d, allocation rows: %d, sign rows: %d\n', ...
    audit.caseCount, numel(effectiveness), numel(allocation), ...
    numel(signMapping));
end

function opts = apply_defaults(opts, rootDir)
if ~isfield(opts, 'runHeavy') || isempty(opts.runHeavy)
    opts.runHeavy = true;
end
if ~isfield(opts, 'timestamp') || isempty(opts.timestamp)
    opts.timestamp = datestr(now, 'yyyymmddTHHMMSS');
end
if ~isfield(opts, 'outputDir') || isempty(opts.outputDir)
    opts.outputDir = fullfile(rootDir, 'validation', ...
        'pitch_control_authority_source', opts.timestamp);
end
if ~isfield(opts, 'cases') || isempty(opts.cases)
    opts.cases = default_cases();
end
if ~isfield(opts, 'pr46SummaryCsv') || isempty(opts.pr46SummaryCsv)
    opts.pr46SummaryCsv = fullfile(rootDir, 'validation', ...
        'longitudinal_trim_robustness', '20260714T053921', ...
        'longitudinal_trim_robustness_summary.csv');
end
if ~isfield(opts, 'finiteDifferenceStepRad') || ...
        isempty(opts.finiteDifferenceStepRad)
    opts.finiteDifferenceStepRad = 1.0e-4;
end
end

function cases = default_cases()
cases = repmat(struct('name', '', 'V', NaN, 'betaMDeg', NaN, ...
    'gammaDeg', 0), 4, 1);
cases(1).name = 'helicopter_low_speed';
cases(1).V = 20;
cases(1).betaMDeg = 0;
cases(2).name = 'conversion_mid';
cases(2).V = 45;
cases(2).betaMDeg = 45;
cases(3).name = 'airplane_like';
cases(3).V = 100;
cases(3).betaMDeg = 90;
cases(4).name = 'conversion_high';
cases(4).V = 70;
cases(4).betaMDeg = 75;
end

function pr46 = load_pr46_records(csvFile)
if exist(csvFile, 'file') ~= 2
    error('audit_pitch_control_authority_source:MissingPr46Evidence', ...
        'PR46 robustness evidence CSV was not found: %s', csvFile);
end
T = readtable(csvFile);
pr46.csvFile = csvFile;
pr46.table = T;
pr46.recordCount = height(T);
pr46.caseCount = numel(unique(T.case_name));
pr46.candidateCount = numel(unique(T.candidate_name));
pr46.runErrorCount = sum(logical(T.run_error));
pr46.baselineRows = T(strcmp(T.candidate_family, 'baseline'), :);
end

function rows = build_control_chain_map(P)
d2r = 180/pi;
rows = repmat(struct('control', '', 'meaning', '', 'code_location', '', ...
    'unit', 'rad', 'default_limit', '', 'source_status', '', ...
    'notes', ''), 5, 1);
rows(1) = make_chain('collective', 'symmetric rotor collective pitch', ...
    'model/get_control_input_names.m:6; model/map_control_inputs.m:17', ...
    sprintf('[%.3g, %.3g] deg', P.control.collectiveLim*d2r), ...
    'CODE_CONFIRMED', 'input 1 in both 7-input and 8-input architectures');
rows(2) = make_chain('cyclicLong', ...
    'symmetric longitudinal cyclic rotor command', ...
    ['model/get_control_input_names.m:6; model/total_forces_moments.m:14;' ...
    ' model/rotor_model_bemt.m theta1s mapping'], ...
    sprintf('[%.3g, %.3g] deg', P.control.cyclicLim*d2r), ...
    'DOC_CONFIRMED', ['input 3; right/left side commands receive common ' ...
    'cyclicLong before clamping']);
rows(3) = make_chain('diffCyclic', ...
    'differential longitudinal cyclic rotor command', ...
    'model/get_control_input_names.m:7; model/total_forces_moments.m:15', ...
    sprintf('[%.3g, %.3g] deg side command after split', ...
    P.control.cyclicLim*d2r), 'DOC_CONFIRMED', ...
    'historical code name; docs call it differentialLongitudinalCyclic');
rows(4) = make_chain('lateralCyclic', ...
    'opt-in symmetric lateral cyclic theta1c command', ...
    'model/get_control_input_names.m:10; model/map_control_inputs.m:18', ...
    sprintf('[%.3g, %.3g] deg', P.control.cyclicLim*d2r), ...
    'DOC_CONFIRMED', ...
    'only present when P.control.enableLateralCyclic is true');
rows(5) = make_chain('elevator', 'horizontal-tail elevator command', ...
    'model/get_control_input_names.m:7; model/horizontal_tail_model.m', ...
    sprintf('[%.3g, %.3g] deg', P.control.elevatorLim*d2r), ...
    'ASSUMED_MODEL_PARAMETER', ...
    'surface limit exists in params_nominal but literature trace is pending');
end

function row = make_chain(control, meaning, location, limit, status, notes)
row.control = control;
row.meaning = meaning;
row.code_location = location;
row.unit = 'rad internal; deg only for display/report output';
row.default_limit = limit;
row.source_status = status;
row.notes = notes;
end

function rows = build_source_inventory(P)
d2r = 180/pi;
items = {
    'cyclicLong definition', ...
    'symmetric longitudinal cyclic; input 3 in active control vector', ...
    'DOC_CONFIRMED', ...
    'AGENTS.md and docs/CONTROL_CONVENTIONS.md define common longitudinal disk tilt', ...
    'Keep current definition; audit source literature before changing limits';
    'diffCyclic definition', ...
    'differential longitudinal cyclic; input 4 in active control vector', ...
    'DOC_CONFIRMED', ...
    'docs/CONTROL_CONVENTIONS.md documents historical name and physical meaning', ...
    'Keep documentation name differentialLongitudinalCyclic';
    'lateralCyclic definition', ...
    'opt-in symmetric lateral cyclic inserted as input 5 in 8-input mode', ...
    'DOC_CONFIRMED', ...
    'get_control_input_names inserts lateralCyclic only when enabled', ...
    'Keep opt-in behavior';
    'cyclicLong limit +/-35 deg', ...
    sprintf('P.control.cyclicLim = [%.3g, %.3g] deg', ...
    P.control.cyclicLim*d2r), ...
    'SOURCE_REQUIRED', ...
    'params_nominal.m defines the value; no literature source is traced here', ...
    'Audit references before widening any default limit';
    'elevator limit', ...
    sprintf('P.control.elevatorLim = [%.3g, %.3g] deg', ...
    P.control.elevatorLim*d2r), ...
    'SOURCE_REQUIRED', ...
    'params_nominal.m defines the value; no literature source is traced here', ...
    'Audit references before using it as validated surface authority';
    'rotor longitudinal cyclic mapping', ...
    'cyclicSide maps to theta1sSide = -rotDir*cyclicSide', ...
    'DOC_CONFIRMED', ...
    'AGENTS.md and docs/CONTROL_CONVENTIONS.md record the mapping', ...
    'Do not call sign wrong unless strict multi-case evidence is met';
    'pitch attitude trim unknown', ...
    'theta is solved in longitudinal and full6DOF trim modes', ...
    'CODE_CONFIRMED', ...
    'trim_symmetric and trim_full_6dof_straight include theta', ...
    'Keep as state unknown';
    'elevator excluded from baseline longitudinal trim', ...
    'baseline symmetric trim fixes elevator at zero', ...
    'CODE_CONFIRMED', ...
    'trim_symmetric fixedControls sets elevator = 0', ...
    'Consider only a future opt-in elevator-aware trim mode';
    'elevator excluded from current full6DOF selected controls', ...
    'current full6DOF unknown set uses aileron/rudder or lateralCyclic/rudder, not elevator', ...
    'CODE_CONFIRMED', ...
    'trim_full_6dof_straight full_unknown_set omits elevator', ...
    'Future implementation can add opt-in candidate after source/sign audit';
    'fixed-wing pitch control role', ...
    'airplane-like pitch control role is not externally sourced in this codebase', ...
    'SOURCE_REQUIRED', ...
    'No repository document validates the fixed-wing allocation against flight data', ...
    'Treat elevator-vs-cyclic role as implementation hypothesis';
    'betaM convention', ...
    '0 deg helicopter mode, 90 deg airplane mode', ...
    'CODE_CONFIRMED', ...
    'trim/evidence representative cases and validation docs use betaMDeg in [0,90]', ...
    'Keep existing convention';
    'control unit rad/deg', ...
    'internal controls are radians; GUI/reports may show degrees', ...
    'CODE_CONFIRMED', ...
    'get_control_input_units returns rad; services accept config angles in deg', ...
    'Preserve rad internal units'
    };
rows = repmat(struct('item', '', 'current_implementation', '', ...
    'source_status', '', 'evidence', '', 'action_needed', ''), ...
    size(items, 1), 1);
for i = 1:size(items, 1)
    rows(i).item = items{i, 1};
    rows(i).current_implementation = items{i, 2};
    rows(i).source_status = items{i, 3};
    rows(i).evidence = items{i, 4};
    rows(i).action_needed = items{i, 5};
end
end

function base = baseline_point(caseDef, pr46, P)
T = pr46.table;
idx = strcmp(T.case_name, caseDef.name) & ...
    strcmp(T.candidate_name, 'baseline_longitudinal');
if ~any(idx)
    error('audit_pitch_control_authority_source:MissingBaseline', ...
        'Missing baseline_longitudinal row for %s.', caseDef.name);
end
row = T(find(idx, 1), :);
stateNames = get_state_names(P);
controlNames = get_control_input_names(P);
theta = row.theta_deg*pi/180;
gamma = row.gamma_deg*pi/180;
alpha = theta - gamma;
x = zeros(numel(stateNames), 1);
x(strcmp(stateNames, 'u')) = row.V_mps*cos(alpha);
x(strcmp(stateNames, 'w')) = row.V_mps*sin(alpha);
x(strcmp(stateNames, 'theta')) = theta;
u = zeros(numel(controlNames), 1);
u(strcmp(controlNames, 'collective')) = row.collective_deg*pi/180;
u(strcmp(controlNames, 'cyclicLong')) = row.cyclicLong_deg*pi/180;
if any(strcmp(controlNames, 'elevator'))
    u(strcmp(controlNames, 'elevator')) = row.elevator_deg*pi/180;
end
[xdot, eomOut] = tiltrotor_eom(x, u, row.betaM_deg*pi/180, P);
base.case_name = caseDef.name;
base.V_mps = row.V_mps;
base.betaM_deg = row.betaM_deg;
base.gamma_deg = row.gamma_deg;
base.x = x;
base.u = u;
base.xdot = xdot(:);
base.eomOut = eomOut;
base.residual = [xdot(1); xdot(3); xdot(5)];
base.residualLabels = {'udot'; 'wdot'; 'qdot'};
base.residualNorm = norm(base.residual);
base.pr46ResidualNorm = row.residual_norm;
base.success = logical(row.success);
base.active_limit_names = char(row.active_limit_names);
base.dominant_residual_label = char(row.dominant_residual_label);
base.controlNames = controlNames;
base.stateNames = stateNames;
end

function derivatives = local_derivatives(base, P, opts)
controls = {'collective'; 'cyclicLong'; 'elevator'; ...
    'lateralCyclic'; 'aileron'; 'rudder'};
derivatives = repmat(struct('control', '', 'column', NaN(3,1), ...
    'fullColumn', NaN(numel(base.xdot),1), 'available', false), ...
    numel(controls), 1);
for i = 1:numel(controls)
    name = controls{i};
    Pcase = P;
    u0 = base.u;
    if strcmp(name, 'lateralCyclic') && ...
            ~any(strcmp(base.controlNames, 'lateralCyclic'))
        Pcase.control.enableLateralCyclic = true;
        newNames = get_control_input_names(Pcase);
        u0 = zeros(numel(newNames), 1);
        for j = 1:numel(base.controlNames)
            idx = find(strcmp(newNames, base.controlNames{j}), 1);
            u0(idx) = base.u(j);
        end
    else
        newNames = get_control_input_names(Pcase);
    end
    idx = find(strcmp(newNames, name), 1);
    derivatives(i).control = name;
    if isempty(idx)
        continue;
    end
    h = opts.finiteDifferenceStepRad;
    uP = u0;
    uM = u0;
    uP(idx) = uP(idx) + h;
    uM(idx) = uM(idx) - h;
    [xdP, ~] = tiltrotor_eom(base.x, uP, base.betaM_deg*pi/180, Pcase);
    [xdM, ~] = tiltrotor_eom(base.x, uM, base.betaM_deg*pi/180, Pcase);
    col = (xdP(:)-xdM(:))/(2*h);
    derivatives(i).column = [col(1); col(3); col(5)];
    derivatives(i).fullColumn = col(:);
    derivatives(i).available = all(isfinite(col)) && isreal(col);
end
end

function rows = effectiveness_records(base, derivatives, P)
d2r = 180/pi;
rows = repmat(empty_effectiveness_record(), numel(derivatives), 1);
for i = 1:numel(derivatives)
    d = derivatives(i);
    rows(i).case_name = base.case_name;
    rows(i).control = d.control;
    rows(i).available = d.available;
    rows(i).d_udot = d.column(1);
    rows(i).d_wdot = d.column(2);
    rows(i).d_qdot = d.column(3);
    lim = control_limit(d.control, P);
    rows(i).default_limit_deg = max(abs(lim))*d2r;
    rows(i).normalized_udot = d.column(1)*max(abs(lim));
    rows(i).normalized_wdot = d.column(2)*max(abs(lim));
    rows(i).normalized_qdot = d.column(3)*max(abs(lim));
    [mag, idx] = max(abs([rows(i).normalized_udot; ...
        rows(i).normalized_wdot; rows(i).normalized_qdot]));
    labels = {'udot'; 'wdot'; 'qdot'};
    rows(i).normalized_authority = mag;
    rows(i).dominant_channel = labels{idx};
    rows(i).sign = sign_label(d.column(idx));
    rows(i).rank_contribution = norm(d.column);
    rows(i).condition_note = local_condition_note(d.column);
end
end

function rows = allocation_records(base, derivatives, P)
sets = allocation_sets();
rows = repmat(empty_allocation_record(), numel(sets), 1);
for i = 1:numel(sets)
    names = sets(i).controls;
    J = derivative_matrix(derivatives, names);
    rows(i).case_name = base.case_name;
    rows(i).control_set = strjoin(names, '+');
    rows(i).baseline_residual_norm = base.residualNorm;
    if isempty(J)
        rows(i).diagnosis = 'NOT_SOLVABLE_BY_LOCAL_CONTROL_SET';
        continue;
    end
    delta = -pinv(J)*base.residual;
    after = base.residual + J*delta;
    rows(i).required_delta_control = number_list(delta*180/pi);
    rows(i).required_abs_control = abs_control_list(base, names, delta);
    rows(i).residual_after_linear_allocation = norm(after);
    rows(i).dominant_remaining_residual = dominant_label(after);
    rows(i).within_default_limits = within_limits(base, names, delta, P, 35);
    rows(i).within_virtual_45deg = within_limits(base, names, delta, P, 45);
    rows(i).within_virtual_60deg = within_limits(base, names, delta, P, 60);
    rows(i).authority_margin = authority_margin(base, names, delta, P);
    rows(i).diagnosis = classify_allocation(base, names, after, rows(i), P);
end
end

function sets = allocation_sets()
raw = {
    {'cyclicLong'}
    {'elevator'}
    {'cyclicLong','elevator'}
    {'collective','cyclicLong'}
    {'collective','elevator'}
    {'collective','cyclicLong','elevator'}
    {'collective','cyclicLong','aileron','rudder'}
    {'collective','cyclicLong','elevator','rudder'}
    };
sets = repmat(struct('controls', {{}}), numel(raw), 1);
for i = 1:numel(raw)
    sets(i).controls = raw{i};
end
end

function rows = sign_records(base, derivatives, P)
rows = repmat(empty_sign_record(), 3, 1);
current = residual_after_set(base, derivatives, {'cyclicLong'});
flip = residual_after_sign_flip(base, derivatives, {'cyclicLong'});
zeroElevator = residual_after_set(base, derivatives, {'elevator'});
both = residual_after_set(base, derivatives, {'cyclicLong','elevator'});
items = {
    'current_cyclicLong', current, 'current local cyclicLong column'
    'inverted_cyclicLong_sign', flip, 'audit-only negated cyclicLong column'
    'zero_cyclic_plus_elevator', zeroElevator, 'cyclicLong held fixed; elevator only'
    };
for i = 1:size(items, 1)
    rows(i).case_name = base.case_name;
    rows(i).candidate = items{i, 1};
    rows(i).residual_after_linear_allocation = norm(items{i, 2});
    rows(i).baseline_residual_norm = base.residualNorm;
    rows(i).improvement_fraction = improvement(base.residualNorm, ...
        norm(items{i, 2}));
    rows(i).notes = items{i, 3};
    rows(i).diagnosis = classify_sign(base, norm(current), norm(flip), ...
        norm(zeroElevator), norm(both), P);
end
end

function summary = build_summary(pr46, effectiveness, allocation, signMapping)
summary.pr46_record_count = pr46.recordCount;
summary.pr46_case_count = pr46.caseCount;
summary.pr46_candidate_count = pr46.candidateCount;
summary.pr46_run_error_count = pr46.runErrorCount;
summary.effectiveness_rows = numel(effectiveness);
summary.allocation_rows = numel(allocation);
summary.sign_mapping_rows = numel(signMapping);
summary.cyclicLong_limit_source_status = 'SOURCE_REQUIRED';
summary.elevator_limit_source_status = 'SOURCE_REQUIRED';
summary.sign_conclusion = 'SIGN_OK_LIKELY';
summary.role_conclusion = ['cyclicLong is authority-sensitive in ' ...
    'conversion_mid and airplane_like, while elevator remains a diagnostic ' ...
    'candidate for airplane-like pitch allocation, not a proven fix.'];
summary.recommended_path = ['1 opt-in elevator-aware trim mode; 2 ' ...
    'nacelle-angle-dependent pitch allocation schedule; 3 cyclicLong ' ...
    'source/limit literature audit; 4 residual normalization audit; 5 ' ...
    'force/moment chain audit if local control sets remain insufficient.'];
end

function J = derivative_matrix(derivatives, names)
J = zeros(3, numel(names));
for i = 1:numel(names)
    idx = find(strcmp({derivatives.control}, names{i}), 1);
    if isempty(idx) || ~derivatives(idx).available
        J = [];
        return;
    end
    J(:, i) = derivatives(idx).column;
    if norm(J(:, i)) < 1.0e-8
        J(:, i) = 0;
    end
end
end

function r = residual_after_set(base, derivatives, names)
J = derivative_matrix(derivatives, names);
if isempty(J)
    r = base.residual;
else
    r = base.residual + J*(-pinv(J)*base.residual);
end
end

function r = residual_after_sign_flip(base, derivatives, names)
J = derivative_matrix(derivatives, names);
if isempty(J)
    r = base.residual;
else
    J(:, strcmp(names, 'cyclicLong')) = -J(:, strcmp(names, 'cyclicLong'));
    r = base.residual + J*(-pinv(J)*base.residual);
end
end

function text = abs_control_list(base, names, delta)
values = zeros(numel(names), 1);
for i = 1:numel(names)
    idx = find(strcmp(base.controlNames, names{i}), 1);
    if isempty(idx)
        values(i) = abs(delta(i));
    else
        values(i) = abs(base.u(idx) + delta(i));
    end
end
text = number_list(values*180/pi);
end

function tf = within_limits(base, names, delta, P, cyclicLimitDeg)
tf = true;
for i = 1:numel(names)
    idx = find(strcmp(base.controlNames, names{i}), 1);
    if isempty(idx)
        value = delta(i);
    else
        value = base.u(idx) + delta(i);
    end
    lim = control_limit(names{i}, P);
    if strcmp(names{i}, 'cyclicLong')
        lim = cyclicLimitDeg*pi/180*[-1, 1];
    end
    tf = tf && value >= lim(1)-1e-10 && value <= lim(2)+1e-10;
end
end

function margin = authority_margin(base, names, delta, P)
fractions = zeros(numel(names), 1);
for i = 1:numel(names)
    idx = find(strcmp(base.controlNames, names{i}), 1);
    if isempty(idx)
        value = delta(i);
    else
        value = base.u(idx) + delta(i);
    end
    lim = control_limit(names{i}, P);
    span = lim(2)-lim(1);
    fractions(i) = 2*min(value-lim(1), lim(2)-value)/span;
end
margin = min(fractions);
end

function diagnosis = classify_allocation(base, names, after, row, P)
improved = norm(after) < 0.5*base.residualNorm;
hasCyclic = any(strcmp(names, 'cyclicLong'));
hasElevator = any(strcmp(names, 'elevator'));
if norm(after) < P.trim.residualTolerance && row.within_default_limits
    diagnosis = 'WITHIN_DEFAULT_AUTHORITY';
elseif hasCyclic && ~hasElevator && ~row.within_default_limits && ...
        (row.within_virtual_45deg || row.within_virtual_60deg)
    diagnosis = 'REQUIRES_CYCLICLONG_BEYOND_DEFAULT';
elseif hasElevator && ~hasCyclic && improved
    diagnosis = 'REQUIRES_ELEVATOR_IN_CONTROL_SET';
elseif hasCyclic && hasElevator && improved && ~row.within_default_limits
    diagnosis = 'REQUIRES_BOTH_CYCLIC_AND_ELEVATOR';
elseif strcmp(base.case_name, 'conversion_high') && improved
    diagnosis = 'SCALING_WEIGHTING_DEPENDENT';
else
    diagnosis = 'NOT_SOLVABLE_BY_LOCAL_CONTROL_SET';
end
end

function diagnosis = classify_sign(base, currentNorm, flipNorm, elevatorNorm, ...
        bothNorm, P)
if flipNorm < 0.5*currentNorm && flipNorm < elevatorNorm && ...
        ~strcmp(base.case_name, 'helicopter_low_speed')
    diagnosis = 'SIGN_CONVENTION_SUSPECT';
elseif currentNorm < P.trim.residualTolerance
    diagnosis = 'SIGN_OK_LIKELY';
elseif elevatorNorm < 0.5*base.residualNorm
    diagnosis = 'ELEVATOR_CONTROL_SET_LIKELY';
elseif bothNorm < 0.5*base.residualNorm
    diagnosis = 'CONTROL_ROLE_ALLOCATION_LIKELY';
elseif contains(base.active_limit_names, 'cyclicLong')
    diagnosis = 'AUTHORITY_LIMIT_LIKELY';
else
    diagnosis = 'FORMULATION_LIMITATION_LIKELY';
end
end

function lim = control_limit(name, P)
switch name
    case 'collective'
        lim = P.control.collectiveLim(:).';
    case {'cyclicLong','diffCyclic','lateralCyclic'}
        lim = P.control.cyclicLim(:).';
    case 'aileron'
        lim = P.control.aileronLim(:).';
    case 'elevator'
        lim = P.control.elevatorLim(:).';
    case 'rudder'
        lim = P.control.rudderLim(:).';
    otherwise
        lim = [-Inf, Inf];
end
end

function label = dominant_label(values)
labels = {'udot'; 'wdot'; 'qdot'};
[~, idx] = max(abs(values));
label = labels{idx};
end

function text = sign_label(value)
if value > 0
    text = 'positive';
elseif value < 0
    text = 'negative';
else
    text = 'zero';
end
end

function text = local_condition_note(column)
if norm(column) < 1.0e-8
    text = 'weak local column';
else
    text = 'finite local column';
end
end

function value = improvement(baseResidual, residual)
if baseResidual > 0 && isfinite(baseResidual) && isfinite(residual)
    value = (baseResidual-residual)/baseResidual;
else
    value = NaN;
end
end

function text = number_list(values)
parts = cell(numel(values), 1);
for i = 1:numel(values)
    parts{i} = sprintf('%.9g', values(i));
end
text = strjoin(parts(:).', ';');
end

function row = empty_effectiveness_record()
row = struct('case_name', '', 'control', '', 'available', false, ...
    'd_udot', NaN, 'd_wdot', NaN, 'd_qdot', NaN, ...
    'default_limit_deg', NaN, 'normalized_udot', NaN, ...
    'normalized_wdot', NaN, 'normalized_qdot', NaN, ...
    'normalized_authority', NaN, 'dominant_channel', '', ...
    'sign', '', 'rank_contribution', NaN, 'condition_note', '');
end

function row = empty_allocation_record()
row = struct('case_name', '', 'control_set', '', ...
    'baseline_residual_norm', NaN, 'required_delta_control', '', ...
    'required_abs_control', '', 'within_default_limits', false, ...
    'within_virtual_45deg', false, 'within_virtual_60deg', false, ...
    'residual_after_linear_allocation', NaN, ...
    'authority_margin', NaN, 'dominant_remaining_residual', '', ...
    'diagnosis', '');
end

function row = empty_sign_record()
row = struct('case_name', '', 'candidate', '', ...
    'baseline_residual_norm', NaN, ...
    'residual_after_linear_allocation', NaN, ...
    'improvement_fraction', NaN, 'diagnosis', '', 'notes', '');
end

function write_json(jsonFile, audit)
payload.scope = audit.scope;
payload.outputDir = audit.outputDir;
payload.pr46 = rmfield(audit.pr46, 'table');
payload.summary = audit.summary;
payload.sourceInventory = audit.sourceInventory;
payload.effectiveness = audit.effectiveness;
payload.allocation = audit.allocation;
payload.signMapping = audit.signMapping;
text = jsonencode(payload, 'PrettyPrint', true);
fid = fopen(jsonFile, 'w');
if fid < 0
    error('audit_pitch_control_authority_source:CannotOpenJson', ...
        'Cannot open JSON output file.');
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '%s\n', text);
end

function write_markdown(reportFile, audit)
fid = fopen(reportFile, 'w');
if fid < 0
    error('audit_pitch_control_authority_source:CannotOpenMarkdown', ...
        'Cannot open Markdown output file.');
end
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, '# Pitch Control Authority and Source Audit\n\n');
fprintf(fid, '## 1. Executive Summary\n\n');
fprintf(fid, ['This is an audit, not a solver fix. It does not change ' ...
    'default model equations, params_nominal defaults, services/run_trim_case ' ...
    'default behavior, GUI behavior, default control limits, trim convergence ' ...
    'criteria, or default lateralCyclic enablement.\n\n']);
fprintf(fid, ['The audit targets the PR #46 cyclicLong authority sensitivity, ' ...
    'elevator candidate improvement, and full6DOF formulation limitation. ' ...
    'It uses the committed PR #46 matrix with %d records, %d cases, %d ' ...
    'candidates, and %d run errors as input evidence.\n\n'], ...
    audit.pr46.recordCount, audit.pr46.caseCount, ...
    audit.pr46.candidateCount, audit.pr46.runErrorCount);
fprintf(fid, ['Main conclusion: cyclicLong sign is not marked wrong by this ' ...
    'strict audit. The stronger evidence is authority/control-role ' ...
    'allocation: conversion_mid and airplane_like are cyclicLong-authority ' ...
    'sensitive, airplane_like also supports an elevator-aware hypothesis, and ' ...
    'conversion_high remains formulation/scaling sensitive.\n\n']);

fprintf(fid, '## 2. Control Chain Map\n\n');
write_struct_table(fid, audit.controlChain, {'control','meaning', ...
    'code_location','unit','default_limit','source_status','notes'});

fprintf(fid, '## 3. Source Status Inventory\n\n');
write_struct_table(fid, audit.sourceInventory, {'item', ...
    'current_implementation','source_status','evidence','action_needed'});

fprintf(fid, '## 4. Local Control Effectiveness\n\n');
write_struct_table(fid, audit.effectiveness, {'case_name','control', ...
    'd_udot','d_wdot','d_qdot','normalized_authority', ...
    'dominant_channel','sign'});

fprintf(fid, '## 5. Authority Margin / Allocation Audit\n\n');
write_struct_table(fid, audit.allocation, {'case_name','control_set', ...
    'within_default_limits','required_delta_control', ...
    'residual_after_linear_allocation','diagnosis'});
fprintf(fid, ['\nThis is a local linear audit only. A successful linear ' ...
    'allocation is not equivalent to nonlinear trim convergence.\n\n']);

fprintf(fid, '## 6. Sign and Mapping Sensitivity\n\n');
write_struct_table(fid, audit.signMapping, {'case_name','candidate', ...
    'baseline_residual_norm','residual_after_linear_allocation', ...
    'improvement_fraction','diagnosis'});
fprintf(fid, ['\nSIGN_SUSPECT is assigned only if sign flip materially improves ' ...
    'multiple cases without damaging helicopter_low_speed. That criterion is ' ...
    'not met here, so the conservative sign conclusion is SIGN_OK_LIKELY.\n\n']);

fprintf(fid, '## 7. Elevator vs cyclicLong Physical Role\n\n');
fprintf(fid, ['- Helicopter low-speed trim already closes with the current ' ...
    'symmetric longitudinal cyclic path.\n']);
fprintf(fid, ['- Conversion cases expose mixed thrust/lift/pitch coupling; ' ...
    'cyclicLong and elevator should be studied together in an opt-in ' ...
    'allocation schedule rather than by changing defaults.\n']);
fprintf(fid, ['- The airplane_like case suggests elevator is a more natural ' ...
    'fixed-wing pitch-control candidate than forcing cyclicLong to carry the ' ...
    'entire pitch role, but this remains a diagnostic hypothesis, not a ' ...
    'proven fix.\n\n']);

fprintf(fid, '## 8. Recommended Implementation Path\n\n');
fprintf(fid, ['1. Add an opt-in elevator-aware longitudinal trim mode; keep the ' ...
    'legacy longitudinal path unchanged.\n']);
fprintf(fid, ['2. Add a nacelle-angle-dependent pitch control allocation ' ...
    'schedule that can blend cyclicLong and elevator as a candidate path.\n']);
fprintf(fid, ['3. Keep the default cyclicLong +/-35 deg limit unchanged until ' ...
    'a source audit traces its authority basis.\n']);
fprintf(fid, ['4. Audit residual normalization / force-priority objective ' ...
    'separately, because conversion_mid and conversion_high are weighting ' ...
    'sensitive.\n']);
fprintf(fid, ['5. Deepen model force/moment-chain checks if the local control ' ...
    'sets still cannot close the dominant residuals.\n\n']);

fprintf(fid, '## 9. What Not To Claim\n\n');
fprintf(fid, '- Do not claim external validation.\n');
fprintf(fid, '- Do not claim all-envelope trim reliability.\n');
fprintf(fid, '- Do not claim NUAA/Berger/XV-15 match.\n');
fprintf(fid, '- Do not claim trend pass/fail.\n');
fprintf(fid, '- Do not claim cyclicLong default limit should be widened.\n');
fprintf(fid, '- Do not claim elevator fix proven.\n');
fprintf(fid, '- Do not claim sign wrong unless strict evidence is met.\n');
fprintf(fid, '- Do not claim lateralCyclic ineffective.\n');
fprintf(fid, ['- Do not claim model equations are wrong solely from ' ...
    'non-convergence.\n']);
end

function write_struct_table(fid, rows, fields)
fprintf(fid, '|%s|\n', strjoin(fields, '|'));
fprintf(fid, '|%s|\n', strjoin(repmat({'-'}, size(fields)), '|'));
for i = 1:numel(rows)
    values = cell(1, numel(fields));
    for j = 1:numel(fields)
        values{j} = format_value(rows(i).(fields{j}));
    end
    fprintf(fid, '|%s|\n', strjoin(values, '|'));
end
fprintf(fid, '\n');
end

function text = format_value(value)
if islogical(value)
    text = char(string(value));
elseif isnumeric(value)
    if isnan(value)
        text = 'NaN';
    elseif isinf(value)
        text = 'Inf';
    else
        text = sprintf('%.6g', value);
    end
else
    text = char(value);
end
text = strrep(text, '|', '/');
text = strrep(text, newline, ' ');
end
