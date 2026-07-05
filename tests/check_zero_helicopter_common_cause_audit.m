function report = check_zero_helicopter_common_cause_audit()
%CHECK_ZERO_HELICOPTER_COMMON_CAUSE_AUDIT Verify audit artifacts exist.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir, 'analysis'));

outDir = fullfile(rootDir, 'validation', 'helicopter_zero_common_cause_audit');
plotDir = fullfile(outDir, 'plots');

requiredFiles = {
    fullfile(outDir, 'zero_helicopter_common_cause_audit_raw.mat')
    fullfile(outDir, 'zero_cyclic_mapping_audit.csv')
    fullfile(outDir, 'zero_collective_trend_audit.csv')
    fullfile(outDir, 'zero_component_slope_audit.csv')
    fullfile(outDir, 'cross_mode_trend_context.csv')
    fullfile(outDir, 'zero_common_cause_gate_status.csv')
    fullfile(plotDir, 'zero_collective_legacy_vs_full_angle.png')
    fullfile(plotDir, 'zero_cyclic_mapping_candidates.png')
    fullfile(plotDir, 'zero_theta_legacy_vs_full_angle.png')
    fullfile(plotDir, 'zero_component_Fz_vs_V.png')
    fullfile(plotDir, 'zero_component_My_vs_V.png')
    fullfile(plotDir, 'zero_switch_cases_collective.png')
    fullfile(plotDir, 'zero_common_cause_summary_board.png')
    fullfile(rootDir, 'docs', 'wing_full_angle', ...
        'ZERO_HELICOPTER_COMMON_CAUSE_AUDIT_REPORT.md')
    };

missing = {};
for i = 1:numel(requiredFiles)
    if exist(requiredFiles{i}, 'file') ~= 2
        missing{end+1,1} = requiredFiles{i}; %#ok<AGROW>
    end
end

if ~isempty(missing)
    error('check_zero_helicopter_common_cause_audit:MissingArtifact', ...
        'Missing audit artifact: %s', missing{1});
end

mapping = readtable(fullfile(outDir, 'zero_cyclic_mapping_audit.csv'), ...
    'TextType', 'string');
collective = readtable(fullfile(outDir, 'zero_collective_trend_audit.csv'), ...
    'TextType', 'string');
gates = readtable(fullfile(outDir, 'zero_common_cause_gate_status.csv'), ...
    'TextType', 'string');

assert(all(ismember(["legacy";"full_angle"], unique(mapping.modelType))), ...
    'Mapping audit must contain legacy and full_angle.');
assert(all(ismember(["legacy";"full_angle"], unique(collective.modelType))), ...
    'Collective audit must contain legacy and full_angle.');
assert(height(mapping) == 16, 'Expected 16 mapping rows: 8 speeds x 2 model types.');
base = collective(strcmp(collective.caseName, 'baseline_normal'), :);
assert(height(base) == 16, 'Expected 16 baseline collective rows.');
assert(all(ismember(["CYCLIC_MAPPING_GATE";"COLLECTIVE_REVERSAL_GATE"; ...
    "COMMON_CAUSE_CLASSIFICATION";"FINAL_RECOMMENDATION"], gates.gate)), ...
    'Gate table is missing required gates.');

[statusModel, outModel] = system(sprintf( ...
    'git -C "%s" status --short -- params_nominal.m model', rootDir));
assert(statusModel == 0, 'git status for protected paths failed.');
protectedDirty = strtrim(outModel);

report = struct();
report.requiredCount = numel(requiredFiles);
report.mappingRows = height(mapping);
report.collectiveRows = height(collective);
report.gateRows = height(gates);
report.protectedPathsClean = isempty(protectedDirty);
report.protectedPathStatus = protectedDirty;
report.allPassed = isempty(missing) && report.mappingRows == 16 && ...
    report.protectedPathsClean;

fprintf('\nZero helicopter common-cause audit check\n');
fprintf('Required artifacts: %d\n', report.requiredCount);
fprintf('Mapping rows: %d\n', report.mappingRows);
fprintf('Collective rows: %d\n', report.collectiveRows);
fprintf('Protected params/model clean: %d\n', report.protectedPathsClean);

assert(report.allPassed, ...
    'Zero helicopter common-cause audit artifact check failed.');
end
