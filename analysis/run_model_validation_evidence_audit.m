function report = run_model_validation_evidence_audit(varargin)
%RUN_MODEL_VALIDATION_EVIDENCE_AUDIT One-stop model validation evidence audit.
% The audit generates an evidence chain for the current concept model. It
% does not tune parameters, switch defaults, or modify production model code.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir, 'model'));
addpath(fullfile(rootDir, 'model', 'wing'));
addpath(fullfile(rootDir, 'analysis'));
addpath(fullfile(rootDir, 'tests'));
addpath(fullfile(rootDir, 'tests', 'wing_full_angle'));

opts = parse_options(varargin{:});
enums = validation_model_evidence_enums();

outRoot = fullfile(rootDir, 'validation', 'model_validation_evidence');
docRoot = fullfile(rootDir, 'docs', 'validation');
ensure_dir(outRoot);
ensure_dir(docRoot);

report = struct();
report.generatedAt = datestr(now, 31);
report.rootDir = rootDir;
report.outputRoot = outRoot;
report.docRoot = docRoot;
report.git = collect_git(rootDir);
report.errors = empty_error_table();

sourceInventory = build_source_inventory(rootDir);
writetable(sourceInventory, fullfile(outRoot, 'source_inventory.csv'));

evidenceMatrix = build_evidence_matrix();
validate_evidence_matrix(evidenceMatrix, enums);
writetable(evidenceMatrix, fullfile(outRoot, 'evidence_matrix.csv'));
write_evidence_matrix_doc(fullfile(docRoot, ...
    'MODEL_VALIDATION_EVIDENCE_MATRIX.md'), evidenceMatrix);

gateRows = empty_gate_rows();
[gateRows, report.errors] = run_gate(gateRows, report.errors, 0, ...
    'GATE0_RUNTIME_DEFAULT', true, opts, rootDir, outRoot, docRoot, ...
    @() gate0_runtime_default(rootDir, outRoot, docRoot));
[gateRows, report.errors] = run_gate(gateRows, report.errors, 1, ...
    'GATE1_TRIM_CLOSURE', true, opts, rootDir, outRoot, docRoot, ...
    @() gate1_trim_closure(rootDir, outRoot, docRoot));
[gateRows, report.errors] = run_gate(gateRows, report.errors, 2, ...
    'GATE2_COMPONENT_BALANCE', true, opts, rootDir, outRoot, docRoot, ...
    @() gate2_component_balance(rootDir, outRoot, docRoot));
[gateRows, report.errors] = run_gate(gateRows, report.errors, 3, ...
    'GATE3_ROTOR_CONTROL', false, opts, rootDir, outRoot, docRoot, ...
    @() gate3_rotor_control(rootDir, outRoot, docRoot));
[gateRows, report.errors] = run_gate(gateRows, report.errors, 4, ...
    'GATE4_WING_WAKE', false, opts, rootDir, outRoot, docRoot, ...
    @() gate4_wing_wake(rootDir, outRoot, docRoot));
[gateRows, report.errors] = run_gate(gateRows, report.errors, 5, ...
    'GATE5_TRIM_TREND_COMPARABILITY', false, opts, rootDir, outRoot, docRoot, ...
    @() gate5_trim_trend_comparability(rootDir, outRoot, docRoot));
[gateRows, report.errors] = run_gate(gateRows, report.errors, 6, ...
    'GATE6_LINEARIZATION_STABILITY', true, opts, rootDir, outRoot, docRoot, ...
    @() gate6_linearization(rootDir, outRoot, docRoot));
[gateRows, report.errors] = run_gate(gateRows, report.errors, 7, ...
    'GATE7_NUMERICAL_ROBUSTNESS', false, opts, rootDir, outRoot, docRoot, ...
    @() gate7_numerical_robustness(rootDir, outRoot, docRoot));

gateSummary = struct2table(gateRows, 'AsArray', true);
gate8 = gate8_owner_package(rootDir, outRoot, docRoot, evidenceMatrix, ...
    gateSummary, sourceInventory, report.errors);
gateRows(end+1) = make_gate_row(8, 'GATE8_OWNER_PACKAGE', ...
    gate8.status, false, gate8.runtime_s, gate8.notes, 'RUN');
gateSummary = struct2table(gateRows, 'AsArray', true);

hardFailures = hard_gate_failures(gateSummary);
nonComparable = non_comparable_items(evidenceMatrix);
softRefs = soft_reference_items(evidenceMatrix);
unresolved = unresolved_items(evidenceMatrix, gateSummary, sourceInventory);

finalConclusion = choose_final_conclusion(gateSummary, sourceInventory, ...
    hardFailures, report.errors, enums);

writetable(gateSummary, fullfile(outRoot, 'gate_summary.csv'));
writetable(report.errors, fullfile(outRoot, 'error_log.csv'));
writetable(hardFailures, fullfile(outRoot, 'hard_gate_failures.csv'));
writetable(nonComparable, fullfile(outRoot, 'non_comparable_items.csv'));
writetable(softRefs, fullfile(outRoot, 'soft_reference_comparisons.csv'));
writetable(unresolved, fullfile(outRoot, 'unresolved_items.csv'));
write_one_stop_report(fullfile(docRoot, 'MODEL_VALIDATION_ONE_STOP_REPORT.md'), ...
    finalConclusion, sourceInventory, evidenceMatrix, gateSummary, ...
    hardFailures, nonComparable, softRefs, unresolved);

ownerDir = fullfile(outRoot, 'owner_review_package');
ensure_dir(ownerDir);
copyfile(fullfile(outRoot, 'evidence_matrix.csv'), ...
    fullfile(ownerDir, 'evidence_matrix.csv'));
copyfile(fullfile(outRoot, 'gate_summary.csv'), ...
    fullfile(ownerDir, 'gate_summary.csv'));
copyfile(fullfile(outRoot, 'unresolved_items.csv'), ...
    fullfile(ownerDir, 'unresolved_items.csv'));
copyfile(fullfile(outRoot, 'non_comparable_items.csv'), ...
    fullfile(ownerDir, 'non_comparable_items.csv'));
copyfile(fullfile(outRoot, 'hard_gate_failures.csv'), ...
    fullfile(ownerDir, 'hard_gate_failures.csv'));
copyfile(fullfile(outRoot, 'soft_reference_comparisons.csv'), ...
    fullfile(ownerDir, 'soft_reference_comparisons.csv'));
write_owner_texts(ownerDir, finalConclusion, gateSummary, hardFailures, ...
    nonComparable, unresolved);

statusPath = fullfile(outRoot, 'final_status.csv');
status = table({finalConclusion}, {classification_for_0deg()}, ...
    {classification_for_15deg()}, {classification_for_75_90deg()}, ...
    height(hardFailures), height(nonComparable), ...
    'VariableNames', {'finalConclusion','classification0deg', ...
    'classification15deg','classification75_90deg', ...
    'hardGateFailureCount','nonComparableItemCount'});
writetable(status, statusPath);

report.sourceInventory = sourceInventory;
report.evidenceMatrix = evidenceMatrix;
report.gateSummary = gateSummary;
report.hardGateFailures = hardFailures;
report.nonComparableItems = nonComparable;
report.softReferenceComparisons = softRefs;
report.unresolvedItems = unresolved;
report.finalConclusion = finalConclusion;
report.outputs.finalStatus = statusPath;

fprintf('\nModel validation evidence audit complete\n');
fprintf('Final conclusion: %s\n', finalConclusion);
fprintf('Evidence root: %s\n', outRoot);
end

function opts = parse_options(varargin)
opts = struct('forceRerun', false);
if mod(numel(varargin), 2) ~= 0
    error('run_model_validation_evidence_audit:InvalidOptions', ...
        'Options must be name/value pairs.');
end
for i = 1:2:numel(varargin)
    name = char(varargin{i});
    value = varargin{i+1};
    switch lower(name)
        case 'forcererun'
            opts.forceRerun = logical(value);
        otherwise
            error('run_model_validation_evidence_audit:InvalidOptions', ...
                'Unknown option: %s', name);
    end
end
end

function git = collect_git(rootDir)
git = struct();
git.branch = strtrim(run_cmd(rootDir, 'branch --show-current'));
git.head = strtrim(run_cmd(rootDir, 'rev-parse HEAD'));
git.statusShort = strtrim(run_cmd(rootDir, ...
    'status --short --untracked-files=all'));
git.remoteCount = strtrim(run_cmd(rootDir, ['rev-list --left-right ' ...
    '--count origin/task/full-wing-model-autonomous-20260702...HEAD']));
git.worktreeCleanAtStart = isempty(git.statusShort);
git.remoteZeroZeroAtStart = ~isempty(regexp(git.remoteCount, ...
    '^\s*0\s+0\s*$', 'once'));
end

function text = run_cmd(rootDir, cmd)
[~, text] = system(sprintf('git -C "%s" %s', rootDir, cmd));
end

function T = build_source_inventory(rootDir)
rows = {
    'NASA_CR_114614', fullfile('references','wing_full_angle','NASA_CR_114614_source_verified_technical_extract_NOT_FACSIMILE.pdf'), 'Bell Model 301 real-time simulation mathematical model candidate', 'EXISTS_NOT_FACSIMILE_EXTRACT'
    'NASA_TM_88373', fullfile('references','wing_full_angle','NASA_TM_88373.pdf'), 'Wing full-angle and near-normal flow reference candidate', 'EXISTS'
    'NASA_TM_X_62407', fullfile('references','NASA_TM_X_62407.pdf'), 'XV-15 public data candidate', 'EXISTS'
    'NASA_TM_81244', fullfile('references','NASA_TM_81244.pdf'), 'XV-15 public data candidate', 'EXISTS'
    'NUAA_main_paper', fullfile('references','NUAA_main_paper.pdf'), 'Method and trend reference, not hard trim-angle truth', 'EXISTS'
    'Berger_HeliUM_or_handling_qualities', fullfile('references','Berger_or_HeliUM_placeholder.pdf'), 'Optional higher-order handling-quality reference', 'MISSING_OPTIONAL'};
T = cell2table(rows, 'VariableNames', {'source_id','relative_path', ...
    'role','expected_status'});
present = false(height(T), 1);
sha = cell(height(T), 1);
bytes = zeros(height(T), 1);
for i = 1:height(T)
    path = fullfile(rootDir, T.relative_path{i});
    present(i) = exist(path, 'file') == 2;
    if present(i)
        info = dir(path);
        bytes(i) = info.bytes;
        sha{i} = sha256_file(path);
    else
        bytes(i) = 0;
        sha{i} = 'MISSING';
    end
end
T.present = present;
T.bytes = bytes;
T.sha256 = sha;
T.extraction_method = repmat({'file_inventory_only_no_new_download'}, height(T), 1);
T.current_status = repmat({'AVAILABLE_OR_OPTIONAL_MISSING'}, height(T), 1);
for i = 1:height(T)
    if ~T.present(i) && ~contains(T.expected_status{i}, 'OPTIONAL')
        T.current_status{i} = 'MISSING_REQUIRED_CANDIDATE';
    elseif ~T.present(i)
        T.current_status{i} = 'MISSING_OPTIONAL';
    end
end
end

function hash = sha256_file(path)
md = java.security.MessageDigest.getInstance('SHA-256');
fid = fopen(path, 'r');
cleanup = onCleanup(@() fclose(fid));
while true
    chunk = fread(fid, 1024*1024, '*uint8');
    if isempty(chunk)
        break;
    end
    md.update(chunk);
end
bytes = typecast(md.digest(), 'uint8');
hex = dec2hex(bytes).';
hash = lower(hex(:).');
end

function T = build_evidence_matrix()
cols = {'validation_item','model_output','source_document','source_location', ...
    'source_value_or_trend','model_case','comparison_type', ...
    'evidence_strength','hard_gate','automated_metric','pass_fail_rule', ...
    'current_status','notes'};
rows = {
    'runtime_default_protection','P.wing.modelType, fullAngleModelEnabled','internal code','params_nominal.m','legacy default remains opt-in','default startup','INTERNAL_BALANCE','HARD',true,'default fields and git protected paths','legacy and params/model/app untouched','PENDING_GATE0','Hard gate protects production model.'
    'trim_closure','residualNorm, fullResidualNorm, convergence','saved trim envelope','validation/wing_full_angle/trim_envelope','finite real converged point evidence','0/15/45/75/90 deg saved points','INTERNAL_BALANCE','HARD',true,'trim closure summary','finite real and converged representative rows','PENDING_GATE1','Uses existing actual point files, not placeholder rows.'
    'component_balance','component Fx/Fy/Fz/Mx/My/Mz','internal model','total_forces_moments','summed component balance','representative saved trim points','INTERNAL_BALANCE','HARD',true,'component summary closure error','component sum equals total force/moment','PENDING_GATE2','No external flight-test claim.'
    'rotor_control_power','thrust, torque, power, control derivatives','NASA/Bell candidate and internal model','CR-114614 candidate plus code','sign and magnitude sanity only','hover representative point','DERIVATIVE_SIGN','SOFT',false,'finite derivative signs','finite derivative table and documented sign','PENDING_GATE3','External same-variable values are not hard coded.'
    'wing_wake_full_angle','CL/CD/Cm range, wake coverage, branch weight','NASA TM-88373 and internal database','references/wing_full_angle','full-angle wing aero only','wing full-angle opt-in samples','CONTINUITY_CHECK','SEMI_HARD',false,'database range and branchWeightInNew','finite database and branchWeightInNew=0','PENDING_GATE4','TM-88373 not used as whole-aircraft trim hard gate.'
    'NUAA_fig5a_beta0','collective/pitch trend, vertical pitch not hard','NUAA_main_paper','Fig.5(a)','partial trend reference','0 deg trim trend','TREND_CHECK','SOFT',false,'classification row','PARTIAL_COMPARABLE, not PASS/FAIL','PARTIAL_COMPARABLE','Control definitions not fully identical.'
    'NUAA_fig6a_beta15','15 deg trim control trend','NUAA_main_paper','Fig.6(a)','not directly comparable','15 deg conversion_longitudinal','NON_COMPARABLE','NON_COMPARABLE',false,'classification row','NON_COMPARABLE_OR_UNRESOLVED','NON_COMPARABLE','pitchCommand allocation differs from cited manipulation method.'
    'NUAA_fig6b_beta75','elevator trend only','NUAA_main_paper','Fig.6(b)','screenshot-level trend reference','75 deg trim trend','OWNER_VISUAL_REVIEW_ONLY','SOFT',false,'classification row','SOFT_COMPARABLE only','SOFT_COMPARABLE','Owner visual review required.'
    'NUAA_fig5b_beta90','elevator trend only','NUAA_main_paper','Fig.5(b)','screenshot-level trend reference','90 deg trim trend','OWNER_VISUAL_REVIEW_ONLY','SOFT',false,'classification row','SOFT_COMPARABLE only','SOFT_COMPARABLE','Owner visual review required.'
    'linearization_stability','A, B, eigenvalues','internal model','linearize_numeric.m','finite real matrices and smooth trends','representative trim points','INTERNAL_BALANCE','HARD',true,'finite A/B and eigenvalue table','no NaN/Inf/complex A/B','PENDING_GATE6','No stability correctness claim from sign alone.'
    'numerical_robustness','step sensitivity, seed/path sensitivity classification','internal model','analysis scripts and saved points','bounded numerical sensitivity evidence','representative cases','CONTINUITY_CHECK','INTERNAL_ONLY',false,'sensitivity summary','finite sensitivity metrics or documented limitation','PENDING_GATE7','Long Monte Carlo is not run by this one-stop smoke audit.'
    'owner_review_package','hard failures and limitations','generated evidence package','validation/model_validation_evidence/owner_review_package','manual final judgement set','owner package','OWNER_VISUAL_REVIEW_ONLY','INTERNAL_ONLY',false,'owner package files','files generated','PENDING_GATE8','Owner still judges soft comparisons.'};
T = cell2table(rows, 'VariableNames', cols);
end

function validate_evidence_matrix(T, enums)
assert(all(ismember(T.comparison_type, enums.comparisonType)), ...
    'Evidence matrix contains invalid comparison_type.');
assert(all(ismember(T.evidence_strength, enums.evidenceStrength)), ...
    'Evidence matrix contains invalid evidence_strength.');
end

function [rows, errors] = run_gate(rows, errors, gateNo, gateName, hardGate, ...
    opts, rootDir, outRoot, docRoot, fun)
inputHash = gate_input_hash(rootDir, gateName);
cachePath = fullfile(outRoot, 'gate_runtime_manifest.csv');
required = expected_gate_outputs(gateNo, outRoot, docRoot);
cacheAction = 'RUN';
if ~opts.forceRerun && can_skip_gate(cachePath, gateName, inputHash, required)
    previous = readtable(cachePath, 'TextType', 'string');
    mask = strcmp(cellstr(previous.gate), gateName) & ...
        strcmp(cellstr(previous.inputHash), inputHash);
    idx = find(mask, 1, 'last');
    status = char(previous.status(idx));
    notes = char(previous.notes(idx));
    rows(end+1) = make_gate_row(gateNo, gateName, status, hardGate, 0, ...
        notes, 'SKIPPED_UNCHANGED');
    return;
end
timer = tic;
try
    result = fun();
    runtime = toc(timer);
    rows(end+1) = make_gate_row(gateNo, gateName, result.status, ...
        hardGate, runtime, result.notes, cacheAction);
catch ME
    runtime = toc(timer);
    rows(end+1) = make_gate_row(gateNo, gateName, 'RUNTIME_ERROR', ...
        hardGate, runtime, ME.message, cacheAction);
    errors = append_error(errors, gateName, ME.identifier, ME.message);
end
append_cache(cachePath, gateName, inputHash, rows(end).status, ...
    rows(end).runtime_s, rows(end).notes);
end

function row = make_gate_row(gateNo, gateName, status, hardGate, runtime, notes, cacheAction)
row = struct('gate_no', gateNo, 'gate', gateName, 'status', status, ...
    'hard_gate', logical(hardGate), 'runtime_s', runtime, ...
    'cache_action', cacheAction, 'notes', notes);
end

function rows = empty_gate_rows()
rows = repmat(make_gate_row(NaN, '', '', false, NaN, '', ''), 0, 1);
end

function errors = empty_error_table()
errors = table(cell(0,1), cell(0,1), cell(0,1), cell(0,1), ...
    'VariableNames', {'gate','identifier','message','logged_at'});
end

function errors = append_error(errors, gate, identifier, message)
errors(end+1, :) = {gate, identifier, message, datestr(now, 31)};
end

function h = gate_input_hash(rootDir, gateName)
head = strtrim(run_cmd(rootDir, 'rev-parse HEAD'));
h = stable_hash([gateName '|' head]);
end

function h = stable_hash(text)
md = java.security.MessageDigest.getInstance('MD5');
md.update(uint8(text));
bytes = typecast(md.digest(), 'uint8');
hex = dec2hex(bytes).';
h = lower(hex(:).');
end

function tf = can_skip_gate(cachePath, gateName, inputHash, required)
tf = false;
if exist(cachePath, 'file') ~= 2 || ~all_files_exist(required)
    return;
end
try
    T = readtable(cachePath, 'TextType', 'string');
catch
    return;
end
if ~all(ismember({'gate','inputHash','status'}, T.Properties.VariableNames))
    return;
end
mask = strcmp(cellstr(T.gate), gateName) & strcmp(cellstr(T.inputHash), inputHash);
tf = any(mask) && ~any(strcmp(cellstr(T.status(mask)), 'RUNTIME_ERROR'));
end

function append_cache(path, gateName, inputHash, status, runtime, notes)
row = table({gateName}, {inputHash}, {status}, runtime, {notes}, ...
    {datestr(now, 31)}, 'VariableNames', {'gate','inputHash','status', ...
    'runtime_s','notes','completed_at'});
if exist(path, 'file') == 2
    old = readtable(path, 'TextType', 'string');
    row = [old; row]; %#ok<AGROW>
end
writetable(row, path);
end

function files = expected_gate_outputs(gateNo, outRoot, docRoot)
switch gateNo
    case 0
        files = {fullfile(outRoot,'gate0_runtime_default','runtime_default_summary.csv'), fullfile(docRoot,'GATE0_RUNTIME_DEFAULT_REPORT.md')};
    case 1
        files = {fullfile(outRoot,'gate1_trim_closure','trim_closure_summary.csv'), fullfile(docRoot,'GATE1_TRIM_CLOSURE_REPORT.md')};
    case 2
        files = {fullfile(outRoot,'gate2_component_balance','component_balance_summary.csv'), fullfile(docRoot,'GATE2_COMPONENT_BALANCE_REPORT.md')};
    case 3
        files = {fullfile(outRoot,'gate3_rotor_control','rotor_control_derivatives.csv'), fullfile(docRoot,'GATE3_ROTOR_CONTROL_REPORT.md')};
    case 4
        files = {fullfile(outRoot,'gate4_wing_wake','wing_wake_summary.csv'), fullfile(docRoot,'GATE4_WING_WAKE_REPORT.md')};
    case 5
        files = {fullfile(outRoot,'gate5_trim_trend_comparability','trim_trend_comparability.csv'), fullfile(docRoot,'GATE5_TRIM_TREND_COMPARABILITY_REPORT.md')};
    case 6
        files = {fullfile(outRoot,'gate6_linearization','linearization_summary.csv'), fullfile(docRoot,'GATE6_LINEARIZATION_STABILITY_REPORT.md')};
    case 7
        files = {fullfile(outRoot,'gate7_numerical_robustness','numerical_robustness_summary.csv'), fullfile(docRoot,'GATE7_NUMERICAL_ROBUSTNESS_REPORT.md')};
    otherwise
        files = {};
end
end

function tf = all_files_exist(files)
tf = true;
for i = 1:numel(files)
    tf = tf && exist(files{i}, 'file') == 2;
end
end

function result = gate0_runtime_default(rootDir, outRoot, docRoot)
outDir = fullfile(outRoot, 'gate0_runtime_default');
ensure_dir(outDir);
P = params_nominal();
statusText = strtrim(run_cmd(rootDir, 'status --short -- params_nominal.m model app'));
items = {
    'startup_path','PASS','audit added required paths'
    'params_nominal_load','PASS','params_nominal returned without error'
    'legacy_default',passfail(strcmp(P.wing.modelType, 'legacy')),'P.wing.modelType'
    'full_angle_opt_in',passfail(P.wing.fullAngleModelEnabled == 0),'P.wing.fullAngleModelEnabled'
    'run_all_checks_entry_exists',passfail(exist(fullfile(rootDir,'tests','run_all_checks.m'), 'file') == 2),'entry exists'
    'protected_production_paths_clean',passfail(isempty(statusText)),'git status params/model/app'};
T = cell2table(items, 'VariableNames', {'check','status','notes'});
figPath = fullfile(outDir, 'gate0_runtime_default.png');
write_status_plot(figPath, T.check, strcmp(T.status, 'PASS'));
csvPath = fullfile(outDir, 'runtime_default_summary.csv');
writetable(T, csvPath);
write_gate_report(fullfile(docRoot, 'GATE0_RUNTIME_DEFAULT_REPORT.md'), ...
    'Gate 0 Runtime And Default Report', T, ...
    'Gate 0 checks startup reachability, default model protection, and protected-path cleanliness.');
result.status = ternary(all(strcmp(T.status, 'PASS')), 'PASS', 'FAIL');
result.notes = sprintf('Gate0 checks passed %d/%d.', sum(strcmp(T.status,'PASS')), height(T));
end

function result = gate1_trim_closure(rootDir, outRoot, docRoot)
outDir = fullfile(outRoot, 'gate1_trim_closure');
ensure_dir(outDir);
src = fullfile(rootDir, 'validation', 'wing_full_angle', 'trim_envelope', ...
    'full_angle_trim_envelope_results.csv');
if exist(src, 'file') ~= 2
    error('gate1:MissingTrimEnvelope', 'Missing trim envelope CSV.');
end
T = readtable(src, 'TextType', 'string');
rows = {};
betas = unique(T.betaM_deg).';
for b = betas
    mask = T.betaM_deg == b;
    rows(end+1, :) = {b, sum(mask), sum(T.actuallyExecuted(mask)), ...
        sum(T.converged(mask)), sum(T.finiteReal(mask)), ...
        max(T.residualNorm(mask)), max(T.fullResidualNorm(mask)), ...
        sum(T.atLimit(mask)), gate_status_from_trim(T(mask, :))}; %#ok<AGROW>
end
S = cell2table(rows, 'VariableNames', {'betaM_deg','rows','actuallyExecuted', ...
    'converged','finiteReal','maxResidualNorm','maxFullResidualNorm', ...
    'atLimitCount','status'});
writetable(S, fullfile(outDir, 'trim_closure_summary.csv'));
write_numeric_plot(fullfile(outDir, 'gate1_trim_residuals.png'), ...
    S.betaM_deg, S.maxFullResidualNorm, 'betaM_deg', 'maxFullResidualNorm');
write_gate_report(fullfile(docRoot, 'GATE1_TRIM_CLOSURE_REPORT.md'), ...
    'Gate 1 Trim Closure Report', S, ...
    'Gate 1 reads existing actual trim point evidence and does not create placeholder trim rows.');
allOk = all(strcmp(S.status, 'PASS'));
result.status = ternary(allOk, 'PASS', 'PARTIAL');
result.notes = sprintf('Trim rows read from existing envelope: %d.', height(T));
end

function status = gate_status_from_trim(T)
if all(T.actuallyExecuted) && all(T.finiteReal) && all(T.converged)
    status = 'PASS';
elseif all(T.actuallyExecuted) && all(T.finiteReal) && any(T.converged)
    status = 'PARTIAL';
else
    status = 'FAIL';
end
end

function result = gate2_component_balance(rootDir, outRoot, docRoot)
outDir = fullfile(outRoot, 'gate2_component_balance');
ensure_dir(outDir);
points = selected_point_files(rootDir);
rows = {};
summary = {};
for i = 1:numel(points)
    loaded = load(points{i}, 'result');
    r = loaded.result;
    comps = r.forcesMoments.components;
    Fsum = zeros(3,1);
    Msum = zeros(3,1);
    for j = 1:numel(comps)
        c = comps{j};
        Fsum = Fsum + c.F(:);
        Msum = Msum + c.M(:);
        rows(end+1, :) = {r.betaM_deg, r.V_mps, r.modelType, c.name, ...
            c.F(1), c.F(2), c.F(3), c.M(1), c.M(2), c.M(3)}; %#ok<AGROW>
    end
    rows(end+1, :) = {r.betaM_deg, r.V_mps, r.modelType, 'total', ...
        r.forcesMoments.F(1), r.forcesMoments.F(2), r.forcesMoments.F(3), ...
        r.forcesMoments.M(1), r.forcesMoments.M(2), r.forcesMoments.M(3)}; %#ok<AGROW>
    closure = norm([Fsum-r.forcesMoments.F(:); Msum-r.forcesMoments.M(:)]);
    summary(end+1, :) = {r.betaM_deg, r.V_mps, r.modelType, ...
        r.residualNorm, r.fullResidualNorm, closure, r.converged, ...
        r.finiteReal, ternary(closure < 1e-8 && r.finiteReal, 'PASS', 'FAIL')}; %#ok<AGROW>
end
T = cell2table(rows, 'VariableNames', {'betaM_deg','V_mps','modelType', ...
    'component','Fx_N','Fy_N','Fz_N','Mx_Nm','My_Nm','Mz_Nm'});
S = cell2table(summary, 'VariableNames', {'betaM_deg','V_mps','modelType', ...
    'residualNorm','fullResidualNorm','componentClosureError', ...
    'converged','finiteReal','status'});
writetable(T, fullfile(outDir, 'component_force_moment_timeseries.csv'));
writetable(S, fullfile(outDir, 'component_balance_summary.csv'));
write_numeric_plot(fullfile(outDir, 'gate2_component_closure.png'), ...
    (1:height(S)).', S.componentClosureError, 'case', 'closureError');
write_gate_report(fullfile(docRoot, 'GATE2_COMPONENT_BALANCE_REPORT.md'), ...
    'Gate 2 Component Balance Report', S, ...
    'Gate 2 loads saved trim point MAT files and verifies component sums against total force/moment.');
result.status = ternary(all(strcmp(S.status, 'PASS')), 'PASS', 'FAIL');
result.notes = sprintf('Component balance checked on %d saved trim points.', numel(points));
end

function files = selected_point_files(rootDir)
pointDir = fullfile(rootDir, 'validation', 'wing_full_angle', 'trim_envelope', 'points');
names = {'beta000_V000_legacy.mat','beta000_V030_legacy.mat', ...
    'beta015_V030_legacy.mat','beta075_V115_legacy.mat', ...
    'beta090_V100_legacy.mat'};
files = {};
for i = 1:numel(names)
    path = fullfile(pointDir, names{i});
    if exist(path, 'file') == 2
        files{end+1,1} = path; %#ok<AGROW>
    end
end
if isempty(files)
    allFiles = dir(fullfile(pointDir, '*.mat'));
    for i = 1:min(5, numel(allFiles))
        files{end+1,1} = fullfile(pointDir, allFiles(i).name); %#ok<AGROW>
    end
end
if isempty(files)
    error('selected_point_files:MissingPoints', 'No saved trim point MAT files found.');
end
end

function result = gate3_rotor_control(~, outRoot, docRoot)
outDir = fullfile(outRoot, 'gate3_rotor_control');
ensure_dir(outDir);
P = params_nominal();
d2r = pi/180;
x = zeros(9,1);
u = [18;0;0;0;0;0;0]*d2r;
betaM = 0;
h = 1e-3;
[~,~,base] = total_forces_moments(x,u,betaM,P);
rows = {};
controls = {'collective',1,'Fz_N'; 'cyclicLong',3,'My_Nm'; ...
    'elevator',6,'My_Nm'};
for i = 1:size(controls,1)
    up = u; um = u;
    idx = controls{i,2};
    up(idx) = up(idx) + h;
    um(idx) = um(idx) - h;
    [Fp,Mp] = total_forces_moments(x,up,betaM,P);
    [Fm,Mm] = total_forces_moments(x,um,betaM,P);
    dF = (Fp-Fm)/(2*h);
    dM = (Mp-Mm)/(2*h);
    metric = controls{i,3};
    value = ternary(strcmp(metric, 'Fz_N'), dF(3), dM(2));
    rows(end+1, :) = {controls{i,1}, metric, value, isfinite(value), ...
        sign(value), 'SIGN_CHECK_ONLY'}; %#ok<AGROW>
end
T = cell2table(rows, 'VariableNames', {'control','metric', ...
    'derivative_per_rad','finiteReal','sign','comparisonMode'});
rotorRows = {
    'left', base.rotorLeft.thrust, base.rotorLeft.torque, ...
        base.rotorLeft.torque * P.rotor.Omega, base.rotorLeft.inducedVelocity
    'right', base.rotorRight.thrust, base.rotorRight.torque, ...
        base.rotorRight.torque * P.rotor.Omega, base.rotorRight.inducedVelocity};
R = cell2table(rotorRows, 'VariableNames', {'rotor','thrust_N', ...
    'torque_Nm','derivedPower_W','inducedVelocity_mps'});
writetable(T, fullfile(outDir, 'rotor_control_derivatives.csv'));
writetable(R, fullfile(outDir, 'rotor_performance_summary.csv'));
write_numeric_plot(fullfile(outDir, 'gate3_control_derivatives.png'), ...
    (1:height(T)).', T.derivative_per_rad, 'controlIndex', 'derivative');
write_gate_report(fullfile(docRoot, 'GATE3_ROTOR_CONTROL_REPORT.md'), ...
    'Gate 3 Rotor Control Report', T, ...
    'Gate 3 computes finite sign-level control derivatives. It does not hard-fit NASA/Bell values.');
result.status = ternary(all(T.finiteReal), 'PASS', 'FAIL');
result.notes = 'Rotor/control derivatives computed at one representative hover state.';
end

function result = gate4_wing_wake(rootDir, outRoot, docRoot)
outDir = fullfile(outRoot, 'gate4_wing_wake');
ensure_dir(outDir);
P = params_nominal();
P.wing.fullAngleModelEnabled = 1;
P.wing.modelType = 'fullAngle';
zeroRotor = struct('muLong',0,'muLat',0,'inducedVelocity',0,'eT',[0;0;-1]);
wakeRotor = struct('muLong',0,'muLat',0,'inducedVelocity',10,'eT',[0;0;-1]);
rows = {};
for betaDeg = [0 45 90]
    betaM = betaDeg*pi/180;
    x = [max(20, betaDeg+10);0;-5;0;0;0;0;0;0];
    u = zeros(7,1);
    [F0,M0,out0] = wing_model(x,u,betaM,zeros(3,1),zeroRotor,zeroRotor,P);
    [Fw,Mw,outw] = wing_model(x,u,betaM,zeros(3,1),wakeRotor,wakeRotor,P);
    rows(end+1, :) = {betaDeg, norm(F0), norm(M0), norm(Fw), norm(Mw), ...
        norm(Fw-F0), outw.normalFlowBranchWeight, ...
        max(outw.wakeCoverage.total), is_real_finite([F0;M0;Fw;Mw]), ...
        outw.usesCommonCoefficientLaw, outw.usesCompleteResultBranchBlend}; %#ok<AGROW>
end
S = cell2table(rows, 'VariableNames', {'betaM_deg','freeForceNorm_N', ...
    'freeMomentNorm_Nm','wakeForceNorm_N','wakeMomentNorm_Nm', ...
    'wakeDeltaForceNorm_N','branchWeightInNew','maxWakeCoverage', ...
    'finiteReal','usesCommonCoefficientLaw','usesCompleteResultBranchBlend'});
dbPath = fullfile(rootDir, 'data', 'wing_full_angle', 'full_angle_selected', ...
    'wing_full_angle_database.csv');
DB = readtable(dbPath, 'TextType', 'string');
rangeRows = {};
vars = {'alpha_deg','Re','Mach','CL','CD','Cm'};
for i = 1:numel(vars)
    if ismember(vars{i}, DB.Properties.VariableNames)
        v = DB.(vars{i});
        rangeRows(end+1, :) = {vars{i}, min(v), max(v), all(isfinite(v))}; %#ok<AGROW>
    end
end
R = cell2table(rangeRows, 'VariableNames', {'variable','minValue','maxValue','finiteReal'});
writetable(S, fullfile(outDir, 'wing_wake_summary.csv'));
writetable(R, fullfile(outDir, 'wing_database_range_check.csv'));
write_numeric_plot(fullfile(outDir, 'gate4_wing_wake_delta.png'), ...
    S.betaM_deg, S.wakeDeltaForceNorm_N, 'betaM_deg', 'wakeDeltaForceNorm_N');
write_gate_report(fullfile(docRoot, 'GATE4_WING_WAKE_REPORT.md'), ...
    'Gate 4 Wing Wake Report', S, ...
    'Gate 4 verifies full-angle opt-in diagnostics, wake response, and database finite ranges.');
ok = all(S.finiteReal) && all(S.usesCommonCoefficientLaw) && ...
    ~any(S.usesCompleteResultBranchBlend) && all(S.branchWeightInNew == 0);
result.status = ternary(ok, 'PASS', 'FAIL');
result.notes = 'Full-angle wing path checked without changing defaults.';
end

function result = gate5_trim_trend_comparability(~, outRoot, docRoot)
outDir = fullfile(outRoot, 'gate5_trim_trend_comparability');
ensure_dir(outDir);
rows = {
    'Fig.5(a)','0 deg','PARTIAL_COMPARABLE','TREND_CHECK','SOFT','collective and pitch angle may be trend context; vertical pitch/cyclic are not hard gates.'
    'Fig.6(a)','15 deg','NON_COMPARABLE_OR_UNRESOLVED','NON_COMPARABLE','NON_COMPARABLE','conversion_longitudinal pitchCommand allocation differs from the paper manipulation method.'
    'Fig.6(b)','75 deg','SOFT_COMPARABLE','OWNER_VISUAL_REVIEW_ONLY','SOFT','elevator chain is screenshot-level trend context only.'
    'Fig.5(b)','90 deg','SOFT_COMPARABLE','OWNER_VISUAL_REVIEW_ONLY','SOFT','elevator chain is screenshot-level trend context only.'};
T = cell2table(rows, 'VariableNames', {'source_figure','model_case', ...
    'comparability','comparison_type','evidence_strength','reason'});
writetable(T, fullfile(outDir, 'trim_trend_comparability.csv'));
write_status_plot(fullfile(outDir, 'gate5_comparability.png'), ...
    T.model_case, ~strcmp(T.comparability, 'NON_COMPARABLE_OR_UNRESOLVED'));
write_gate_report(fullfile(docRoot, ...
    'GATE5_TRIM_TREND_COMPARABILITY_REPORT.md'), ...
    'Gate 5 Trim Trend Comparability Report', T, ...
    'Gate 5 classifies external trim trends. Non-comparable items are limitations, not failures.');
result.status = 'PASS_WITH_LIMITATIONS';
result.notes = '0 deg partial, 15 deg non-comparable, 75/90 deg soft comparable.';
end

function result = gate6_linearization(rootDir, outRoot, docRoot)
outDir = fullfile(outRoot, 'gate6_linearization');
ensure_dir(outDir);
P = params_nominal();
files = selected_point_files(rootDir);
rows = {};
eigRows = {};
for i = 1:min(3, numel(files))
    loaded = load(files{i}, 'result');
    r = loaded.result;
    [A,B,rep] = linearize_numeric(r.xTrim, r.uTrim, r.betaM_deg*pi/180, P);
    ev = eig(A);
    rows(end+1, :) = {r.betaM_deg, r.V_mps, r.modelType, ...
        all(size(A)==[9 9]), all(size(B)==[9 7]), rep.finite, ...
        max(real(ev)), max(abs(imag(ev))), norm(rep.f0), ...
        ternary(rep.finite, 'PASS', 'FAIL')}; %#ok<AGROW>
    for j = 1:numel(ev)
        eigRows(end+1, :) = {r.betaM_deg, r.V_mps, r.modelType, ...
            j, real(ev(j)), imag(ev(j))}; %#ok<AGROW>
    end
end
S = cell2table(rows, 'VariableNames', {'betaM_deg','V_mps','modelType', ...
    'A_size_ok','B_size_ok','finiteReal','maxRealEigenvalue', ...
    'maxAbsImagEigenvalue','baseDerivativeNorm','status'});
E = cell2table(eigRows, 'VariableNames', {'betaM_deg','V_mps', ...
    'modelType','eigenIndex','realPart','imagPart'});
writetable(S, fullfile(outDir, 'linearization_summary.csv'));
writetable(E, fullfile(outDir, 'eigenvalue_trends.csv'));
write_numeric_plot(fullfile(outDir, 'gate6_eigen_real.png'), ...
    (1:height(S)).', S.maxRealEigenvalue, 'case', 'maxRealEigenvalue');
write_gate_report(fullfile(docRoot, ...
    'GATE6_LINEARIZATION_STABILITY_REPORT.md'), ...
    'Gate 6 Linearization Stability Report', S, ...
    'Gate 6 checks finite A/B matrices and records eigenvalue trends without claiming validation from stability alone.');
result.status = ternary(all(S.finiteReal), 'PASS', 'FAIL');
result.notes = sprintf('Linearization checked on %d saved trim points.', height(S));
end

function result = gate7_numerical_robustness(rootDir, outRoot, docRoot)
outDir = fullfile(outRoot, 'gate7_numerical_robustness');
ensure_dir(outDir);
P = params_nominal();
files = selected_point_files(rootDir);
loaded = load(files{1}, 'result');
r = loaded.result;
baseP = P;
scales = [0.5 1 2];
rows = {};
refA = [];
refB = [];
for i = 1:numel(scales)
    Pc = baseP;
    Pc.linear.dx = baseP.linear.dx * scales(i);
    Pc.linear.du = baseP.linear.du * scales(i);
    [A,B,rep] = linearize_numeric(r.xTrim, r.uTrim, r.betaM_deg*pi/180, Pc);
    if i == 2
        refA = A;
        refB = B;
    end
    rows(end+1, :) = {scales(i), rep.finite, norm(A, 'fro'), ...
        norm(B, 'fro'), NaN, NaN}; %#ok<AGROW>
end
for i = 1:numel(scales)
    Pc = baseP;
    Pc.linear.dx = baseP.linear.dx * scales(i);
    Pc.linear.du = baseP.linear.du * scales(i);
    [A,B] = linearize_numeric(r.xTrim, r.uTrim, r.betaM_deg*pi/180, Pc);
    rows{i,5} = norm(A-refA, 'fro')/max(norm(refA, 'fro'), 1);
    rows{i,6} = norm(B-refB, 'fro')/max(norm(refB, 'fro'), 1);
end
T = cell2table(rows, 'VariableNames', {'stepScale','finiteReal', ...
    'normA','normB','relA_vs_scale1','relB_vs_scale1'});
writetable(T, fullfile(outDir, 'numerical_robustness_summary.csv'));
write_numeric_plot(fullfile(outDir, 'gate7_step_sensitivity.png'), ...
    T.stepScale, T.relA_vs_scale1, 'stepScale', 'relA_vs_scale1');
write_gate_report(fullfile(docRoot, 'GATE7_NUMERICAL_ROBUSTNESS_REPORT.md'), ...
    'Gate 7 Numerical Robustness Report', T, ...
    'Gate 7 performs a local linearization step-size sensitivity check. Large multi-start and Monte Carlo sweeps remain owner-visible limitations.');
result.status = ternary(all(T.finiteReal), 'PASS_WITH_LIMITATIONS', 'FAIL');
result.notes = 'Local step-size sensitivity completed; broad sweeps are not rerun here.';
end

function result = gate8_owner_package(~, outRoot, docRoot, evidenceMatrix, gateSummary, sourceInventory, errors)
timer = tic;
gate8Dir = fullfile(outRoot, 'gate8_owner_package');
ensure_dir(gate8Dir);
overview = table({'evidence_matrix'; 'gate_summary'; 'hard_gate_failures'; ...
    'non_comparable_items'; 'soft_reference_comparisons'; 'unresolved_items'}, ...
    {'owner evidence index'; 'gate status'; 'hard failure filter'; ...
    'non comparable filter'; 'soft reference filter'; 'manual follow-up filter'}, ...
    'VariableNames', {'artifact','purpose'});
writetable(overview, fullfile(gate8Dir, 'owner_package_manifest.csv'));
write_gate_report(fullfile(docRoot, 'GATE8_OWNER_PACKAGE_REPORT.md'), ...
    'Gate 8 Owner Package Report', overview, ...
    sprintf(['Gate 8 assembles owner review files from %d evidence rows, ' ...
    '%d gates, %d sources, and %d errors.'], height(evidenceMatrix), ...
    height(gateSummary), height(sourceInventory), height(errors)));
result.status = 'PASS';
result.runtime_s = toc(timer);
result.notes = 'Owner package manifest generated.';
end

function failures = hard_gate_failures(gateSummary)
mask = gateSummary.hard_gate & ~(strcmp(gateSummary.status, 'PASS') | ...
    strcmp(gateSummary.status, 'PASS_WITH_LIMITATIONS'));
failures = gateSummary(mask, :);
end

function T = non_comparable_items(evidence)
mask = strcmp(evidence.comparison_type, 'NON_COMPARABLE') | ...
    strcmp(evidence.evidence_strength, 'NON_COMPARABLE') | ...
    contains(evidence.current_status, 'NON_COMPARABLE');
T = evidence(mask, :);
end

function T = soft_reference_items(evidence)
mask = strcmp(evidence.evidence_strength, 'SOFT') | ...
    strcmp(evidence.comparison_type, 'OWNER_VISUAL_REVIEW_ONLY') | ...
    contains(evidence.current_status, 'SOFT');
T = evidence(mask, :);
end

function T = unresolved_items(evidence, gateSummary, sourceInventory)
rows = {};
for i = 1:height(evidence)
    if contains(evidence.current_status{i}, 'PENDING') || ...
            contains(evidence.current_status{i}, 'NON_COMPARABLE') || ...
            contains(evidence.current_status{i}, 'PARTIAL') || ...
            contains(evidence.current_status{i}, 'SOFT')
        rows(end+1, :) = {evidence.validation_item{i}, 'EVIDENCE_LIMITATION', ...
            evidence.current_status{i}, evidence.notes{i}}; %#ok<AGROW>
    end
end
for i = 1:height(gateSummary)
    if ~(strcmp(gateSummary.status{i}, 'PASS') || ...
            strcmp(gateSummary.status{i}, 'PASS_WITH_LIMITATIONS'))
        rows(end+1, :) = {gateSummary.gate{i}, 'GATE_LIMITATION', ...
            gateSummary.status{i}, gateSummary.notes{i}}; %#ok<AGROW>
    end
end
for i = 1:height(sourceInventory)
    if ~sourceInventory.present(i)
        rows(end+1, :) = {sourceInventory.source_id{i}, 'SOURCE_LIMITATION', ...
            sourceInventory.current_status{i}, sourceInventory.role{i}}; %#ok<AGROW>
    end
end
if isempty(rows)
    T = cell2table(cell(0, 4), 'VariableNames', ...
        {'item','type','status','notes'});
else
    T = cell2table(rows, 'VariableNames', {'item','type','status','notes'});
end
end

function conclusion = choose_final_conclusion(gateSummary, sourceInventory, hardFailures, errors, enums)
if height(errors) > 0
    conclusion = 'MODEL_VALIDATION_BLOCKED_BY_RUNTIME_ERROR';
elseif height(hardFailures) > 0
    conclusion = 'MODEL_VALIDATION_BLOCKED_BY_HARD_GATE_FAILURE';
elseif any(~sourceInventory.present & ~contains(sourceInventory.expected_status, 'OPTIONAL'))
    conclusion = 'MODEL_VALIDATION_BLOCKED_BY_MISSING_EVIDENCE';
elseif any(contains(gateSummary.status, 'LIMITATIONS')) || ...
        any(strcmp(gateSummary.status, 'PARTIAL')) || ...
        any(strcmp(gateSummary.status, 'PASS_WITH_LIMITATIONS'))
    conclusion = 'MODEL_VALIDATION_PARTIAL_WITH_LIMITATIONS';
else
    conclusion = 'MODEL_VALIDATION_READY_FOR_OWNER_REVIEW';
end
assert(any(strcmp(conclusion, enums.finalConclusion)));
end

function write_evidence_matrix_doc(path, T)
lines = {'# Model Validation Evidence Matrix', '', ...
    'This matrix classifies which model outputs are externally comparable, internally checkable, or non-comparable under current control definitions.', '', ...
    '|Item|Output|Comparison|Strength|Hard Gate|Status|Notes|', ...
    '|-|-|-|-|-|-|-|'};
for i = 1:height(T)
    lines{end+1,1} = sprintf('|%s|%s|%s|%s|%d|%s|%s|', ...
        T.validation_item{i}, T.model_output{i}, T.comparison_type{i}, ...
        T.evidence_strength{i}, T.hard_gate(i), T.current_status{i}, ...
        T.notes{i}); %#ok<AGROW>
end
write_lines(path, lines);
end

function write_one_stop_report(path, finalConclusion, sources, evidence, gates, hardFailures, nonComparable, softRefs, unresolved)
lines = {};
lines = add_line(lines, '# Model Validation One-Stop Report');
lines = add_line(lines, '');
lines = add_line(lines, ['Final conclusion: `' finalConclusion '`.']);
lines = add_line(lines, '');
lines = add_line(lines, '## 1. One-Sentence Conclusion');
lines = add_line(lines, '');
lines = add_line(lines, 'The current concept model has an automated internal evidence chain, but external trim-trend comparisons remain partial, soft, or non-comparable where control definitions differ.');
lines = add_line(lines, '');
lines = add_line(lines, '## 2. What The Current Model Can Validate');
lines = add_line(lines, '');
lines = add_line(lines, '- Runtime/default protection, trim closure, component force/moment balance, finite linearization, and selected control derivative signs.');
lines = add_line(lines, '- Full-angle wing opt-in behavior and wake sensitivity as internal/semi-hard evidence.');
lines = add_line(lines, '');
lines = add_line(lines, '## 3. What The Current Model Cannot Directly Validate');
lines = add_line(lines, '');
lines = add_line(lines, '- Strict XV-15 reproduction, direct NUAA 0/15 deg vertical pitch hard comparisons, or screenshot-only trend matches as PASS/FAIL decisions.');
lines = add_line(lines, '');
lines = add_line(lines, '## 4. External Source Inventory');
lines = add_table(lines, sources(:, {'source_id','relative_path','present','current_status'}));
lines = add_line(lines, '## 5. Evidence Matrix Summary');
lines = add_line(lines, sprintf('- Evidence rows: %d.', height(evidence)));
lines = add_line(lines, sprintf('- Hard evidence rows: %d.', sum(strcmp(evidence.evidence_strength, 'HARD'))));
lines = add_line(lines, sprintf('- Non-comparable rows: %d.', height(nonComparable)));
lines = add_line(lines, '');
lines = add_line(lines, '## 6. Gate 0-8 Status');
lines = add_table(lines, gates(:, {'gate_no','gate','status','hard_gate','runtime_s','notes'}));
lines = add_line(lines, '## 7. Hard Gate Failures');
lines = add_table(lines, hardFailures);
lines = add_line(lines, '## 8. Non-Comparable Items');
lines = add_table(lines, nonComparable(:, {'validation_item','model_case','current_status','notes'}));
lines = add_line(lines, '## 9. Soft Reference Items');
lines = add_table(lines, softRefs(:, {'validation_item','model_case','current_status','notes'}));
lines = add_line(lines, '## 10. 0 deg Curvature Handling');
lines = add_line(lines, '');
lines = add_line(lines, ['Current classification: `' classification_for_0deg() '`. It is a partial trend context, not a hard gate.']);
lines = add_line(lines, '');
lines = add_line(lines, '## 11. 15 deg NUAA Trim-Angle Non-Comparability');
lines = add_line(lines, '');
lines = add_line(lines, ['Current classification: `' classification_for_15deg() '`. The current conversion_longitudinal pitchCommand allocation is not treated as the same control definition.']);
lines = add_line(lines, '');
lines = add_line(lines, '## 12. 75/90 deg Screenshot-Level Trend Handling');
lines = add_line(lines, '');
lines = add_line(lines, ['Current classification: `' classification_for_75_90deg() '`. These items require owner visual review and cannot be promoted to automatic PASS.']);
lines = add_line(lines, '');
lines = add_line(lines, '## 13. Can It Enter Follow-On Handling-Qualities Work');
lines = add_line(lines, '');
lines = add_line(lines, 'Yes, with limitations: use it as a concept-level component model with internal consistency evidence, not as a validated XV-15 reproduction.');
lines = add_line(lines, '');
lines = add_line(lines, '## 14. Owner Must Review');
lines = add_line(lines, '');
lines = add_line(lines, '- `hard_gate_failures.csv`');
lines = add_line(lines, '- `non_comparable_items.csv`');
lines = add_line(lines, '- `gate_summary.csv`');
lines = add_line(lines, '- This one-stop report');
lines = add_line(lines, '');
lines = add_line(lines, '## 15. Recommended Next Actions');
lines = add_table(lines, unresolved);
write_lines(path, lines);
end

function lines = add_table(lines, T)
lines = add_line(lines, '');
if height(T) == 0 || width(T) == 0
    lines = add_line(lines, '_None._');
    lines = add_line(lines, '');
    return;
end
names = T.Properties.VariableNames;
lines = add_line(lines, ['|' strjoin(names, '|') '|']);
lines = add_line(lines, ['|' strjoin(repmat({'-'}, 1, numel(names)), '|') '|']);
for i = 1:height(T)
    vals = cell(1, numel(names));
    for j = 1:numel(names)
        vals{j} = markdown_value(T.(names{j})(i));
    end
    lines = add_line(lines, ['|' strjoin(vals, '|') '|']);
end
lines = add_line(lines, '');
end

function text = markdown_value(value)
if iscell(value)
    value = value{1};
end
if isstring(value)
    value = char(value);
elseif islogical(value)
    value = num2str(value);
elseif isnumeric(value)
    value = sprintf('%.6g', value);
end
text = strrep(char(value), '|', '/');
end

function write_owner_texts(ownerDir, finalConclusion, gateSummary, hardFailures, nonComparable, unresolved)
lines = {'# Recommended Next Actions', '', ...
    ['Final conclusion: `' finalConclusion '`'], '', ...
    '1. Review hard gate failures first.', ...
    '2. Review non-comparable items before judging NUAA trim trends.', ...
    '3. Treat soft references as owner visual context only.', ...
    '4. Do not switch the default model from legacy based on this package alone.'};
write_lines(fullfile(ownerDir, 'recommended_next_actions.md'), lines);
checklist = {'# Final Owner Review Checklist', '', ...
    '- [ ] hard_gate_failures.csv reviewed', ...
    '- [ ] non_comparable_items.csv reviewed', ...
    '- [ ] gate_summary.csv reviewed', ...
    '- [ ] MODEL_VALIDATION_ONE_STOP_REPORT.md reviewed', ...
    '- [ ] no strict XV-15 validation claim added', ...
    '- [ ] no default model switch approved'};
write_lines(fullfile(ownerDir, 'final_owner_review_checklist.md'), checklist);
write_gate_report(fullfile(ownerDir, 'owner_gate_summary.md'), ...
    'Owner Gate Summary', gateSummary, 'Owner package gate status table.');
write_gate_report(fullfile(ownerDir, 'owner_non_comparable.md'), ...
    'Owner Non-Comparable Items', nonComparable, 'Items that must not be treated as automatic failures.');
write_gate_report(fullfile(ownerDir, 'owner_unresolved_items.md'), ...
    'Owner Unresolved Items', unresolved, 'Remaining limitations and manual review items.');
end

function write_gate_report(path, title, T, intro)
lines = {['# ' title], '', intro, ''};
lines = add_table(lines, T);
write_lines(path, lines);
end

function write_status_plot(path, labels, ok)
fig = figure('Visible','off');
bar(double(ok));
ylim([0 1.2]);
set(gca, 'XTick', 1:numel(labels), 'XTickLabel', labels);
xtickangle(30);
ylabel('pass flag');
saveas(fig, path);
close(fig);
end

function write_numeric_plot(path, x, y, xlab, ylab)
fig = figure('Visible','off');
plot(x, y, 'o-', 'LineWidth', 1.2);
grid on;
xlabel(xlab);
ylabel(ylab);
saveas(fig, path);
close(fig);
end

function lines = add_line(lines, line)
lines{end+1,1} = line;
end

function write_lines(path, lines)
while ~isempty(lines) && isempty(lines{end})
    lines(end) = [];
end
fid = fopen(path, 'w', 'n', 'UTF-8');
assert(fid > 0, 'Cannot write %s.', path);
cleanup = onCleanup(@() fclose(fid));
for i = 1:numel(lines)
    fprintf(fid, '%s\n', lines{i});
end
clear cleanup;
end

function ensure_dir(path)
if exist(path, 'dir') ~= 7
    mkdir(path);
end
end

function text = passfail(tf)
text = ternary(tf, 'PASS', 'FAIL');
end

function value = ternary(condition, a, b)
if condition
    value = a;
else
    value = b;
end
end

function tf = is_real_finite(value)
tf = isreal(value) && all(isfinite(value(:)));
end

function value = classification_for_0deg()
value = 'PARTIAL_COMPARABLE';
end

function value = classification_for_15deg()
value = 'NON_COMPARABLE_OR_UNRESOLVED';
end

function value = classification_for_75_90deg()
value = 'SOFT_COMPARABLE';
end
