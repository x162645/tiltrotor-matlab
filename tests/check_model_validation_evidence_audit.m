function report = check_model_validation_evidence_audit()
%CHECK_MODEL_VALIDATION_EVIDENCE_AUDIT Verify one-stop evidence artifacts.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir, 'analysis'));

outRoot = fullfile(rootDir, 'validation', 'model_validation_evidence');
docRoot = fullfile(rootDir, 'docs', 'validation');

entryPath = fullfile(rootDir, 'analysis', ...
    'run_model_validation_evidence_audit.m');
assert(exist(entryPath, 'file') == 2, ...
    'Missing run_model_validation_evidence_audit.m.');

requiredBeforeRead = {
    fullfile(outRoot, 'evidence_matrix.csv')
    fullfile(outRoot, 'gate_summary.csv')
    fullfile(docRoot, 'MODEL_VALIDATION_ONE_STOP_REPORT.md')
    fullfile(outRoot, 'owner_review_package')};
if ~all_exist(requiredBeforeRead)
    run_model_validation_evidence_audit();
end

requiredFiles = {
    fullfile(outRoot, 'evidence_matrix.csv')
    fullfile(outRoot, 'gate_summary.csv')
    fullfile(outRoot, 'final_status.csv')
    fullfile(outRoot, 'owner_review_package', 'evidence_matrix.csv')
    fullfile(outRoot, 'owner_review_package', 'gate_summary.csv')
    fullfile(outRoot, 'owner_review_package', 'hard_gate_failures.csv')
    fullfile(outRoot, 'owner_review_package', 'non_comparable_items.csv')
    fullfile(outRoot, 'owner_review_package', 'recommended_next_actions.md')
    fullfile(outRoot, 'owner_review_package', 'final_owner_review_checklist.md')
    fullfile(docRoot, 'MODEL_VALIDATION_ONE_STOP_REPORT.md')
    fullfile(docRoot, 'MODEL_VALIDATION_EVIDENCE_MATRIX.md')};
assert(all_exist(requiredFiles), 'One-stop validation evidence artifacts are missing.');

E = readtable(fullfile(outRoot, 'evidence_matrix.csv'), 'TextType', 'string');
G = readtable(fullfile(outRoot, 'gate_summary.csv'), 'TextType', 'string');
F = readtable(fullfile(outRoot, 'final_status.csv'), 'TextType', 'string');

requiredColumns = ["validation_item","model_output","source_document", ...
    "source_location","source_value_or_trend","model_case", ...
    "comparison_type","evidence_strength","hard_gate", ...
    "automated_metric","pass_fail_rule","current_status","notes"];
assert(all(ismember(requiredColumns, string(E.Properties.VariableNames))), ...
    'Evidence matrix is missing required columns.');

enums = validation_model_evidence_enums();
assert(all(ismember(cellstr(E.comparison_type), enums.comparisonType)), ...
    'Invalid comparison_type enum in evidence matrix.');
assert(all(ismember(cellstr(E.evidence_strength), enums.evidenceStrength)), ...
    'Invalid evidence_strength enum in evidence matrix.');

assert(height(G) >= 9, 'Gate summary must include Gate 0 through Gate 8.');
assert(all(ismember((0:8).', G.gate_no)), ...
    'Gate summary does not include every gate number from 0 to 8.');

assert(any(strcmp(E.validation_item, "NUAA_fig5a_beta0") & ...
    strcmp(E.current_status, "PARTIAL_COMPARABLE")), ...
    '0 deg NUAA trend must be classified as PARTIAL_COMPARABLE.');
assert(any(strcmp(E.validation_item, "NUAA_fig6a_beta15") & ...
    (strcmp(E.current_status, "NON_COMPARABLE") | ...
     strcmp(E.current_status, "NON_COMPARABLE_OR_UNRESOLVED"))), ...
    '15 deg NUAA trend must be non-comparable or unresolved.');
assert(any(strcmp(E.validation_item, "NUAA_fig6b_beta75") & ...
    strcmp(E.current_status, "SOFT_COMPARABLE")), ...
    '75 deg NUAA trend must be SOFT_COMPARABLE.');
assert(any(strcmp(E.validation_item, "NUAA_fig5b_beta90") & ...
    strcmp(E.current_status, "SOFT_COMPARABLE")), ...
    '90 deg NUAA trend must be SOFT_COMPARABLE.');

hard0 = E(strcmp(E.validation_item, "NUAA_fig5a_beta0") | ...
    strcmp(E.validation_item, "NUAA_fig6a_beta15"), :);
assert(~any(hard0.hard_gate), ...
    'NUAA 0/15 deg vertical pitch/cyclic trends must not be hard gates.');

assert(any(strcmp(cellstr(F.finalConclusion), enums.finalConclusion)), ...
    'finalConclusion is outside the allowed enum list.');

[statusProtected, protectedText] = system(sprintf( ...
    'git -C "%s" status --short -- params_nominal.m model app', rootDir));
assert(statusProtected == 0, 'Protected-path git status failed.');
protectedClean = isempty(strtrim(protectedText));
assert(protectedClean, 'Protected paths params_nominal.m/model/app were modified.');

report = struct();
report.allPassed = true;
report.evidenceRows = height(E);
report.gateRows = height(G);
report.finalConclusion = char(F.finalConclusion(1));
report.protectedPathsClean = protectedClean;

fprintf('\nModel validation evidence audit check\n');
fprintf('Evidence rows: %d\n', report.evidenceRows);
fprintf('Gate rows: %d\n', report.gateRows);
fprintf('Final conclusion: %s\n', report.finalConclusion);
fprintf('Protected params/model/app clean: %d\n', report.protectedPathsClean);
end

function tf = all_exist(paths)
tf = true;
for i = 1:numel(paths)
    path = paths{i};
    tf = tf && (exist(path, 'file') == 2 || exist(path, 'dir') == 7);
end
end
