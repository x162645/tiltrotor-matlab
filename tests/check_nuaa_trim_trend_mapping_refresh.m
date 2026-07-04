function report = check_nuaa_trim_trend_mapping_refresh()
%CHECK_NUAA_TRIM_TREND_MAPPING_REFRESH Verify mapping refresh artifacts.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir, 'analysis'));

refreshDir = fullfile(rootDir, 'validation', 'nuaa_trim_trend_overlay', ...
    'mapping_refresh');

requiredFiles = {
    fullfile(refreshDir, 'nuaa_variable_mapping_decision.csv')
    fullfile(refreshDir, 'model_fig5a_beta0_trim_trend_refreshed.png')
    fullfile(refreshDir, 'model_fig6a_beta15_trim_trend_refreshed.png')
    fullfile(refreshDir, 'compare_fig5a_beta0_refreshed.png')
    fullfile(refreshDir, 'compare_fig6a_beta15_refreshed.png')
    fullfile(refreshDir, 'model_fig5b_beta90_trim_trend_refreshed.png')
    fullfile(refreshDir, 'model_fig6b_beta75_trim_trend_refreshed.png')
    fullfile(refreshDir, 'compare_fig5b_beta90_refreshed.png')
    fullfile(refreshDir, 'compare_fig6b_beta75_refreshed.png')
    fullfile(refreshDir, 'nuaa_trim_trend_overlay_overview_refreshed.png')
    fullfile(rootDir, 'docs', 'wing_full_angle', ...
        'NUAA_TRIM_TREND_MAPPING_REFRESH_REPORT.md')
    fullfile(rootDir, 'docs', 'wing_full_angle', ...
        'NUAA_TRIM_TREND_VISUAL_OVERLAY_REPORT.md')
    fullfile(rootDir, 'validation', 'nuaa_trim_trend_overlay', ...
        'model_trend_diagnostics.csv')
    fullfile(rootDir, 'validation', 'nuaa_trim_trend_overlay', ...
        'nuaa_visual_judgement_checklist.csv')
    };

missing = {};
for i = 1:numel(requiredFiles)
    if exist(requiredFiles{i}, 'file') ~= 2
        missing{end+1,1} = requiredFiles{i}; %#ok<AGROW>
    end
end
if ~isempty(missing)
    error('check_nuaa_trim_trend_mapping_refresh:MissingArtifact', ...
        'Missing mapping refresh artifact: %s', missing{1});
end

decision = readtable(fullfile(refreshDir, ...
    'nuaa_variable_mapping_decision.csv'), 'TextType', 'string');
assert(any(strcmp(decision.figure, 'Fig.5(a)') & ...
    strcmp(decision.code_candidate_name, 'cyclicLong_neg_deg') & ...
    decision.selectedForRefresh), ...
    'Fig.5(a) must select -cyclicLong_deg.');
assert(any(strcmp(decision.figure, 'Fig.6(a)') & ...
    strcmp(decision.code_candidate_name, 'cyclicLong_neg_deg') & ...
    decision.selectedForRefresh), ...
    'Fig.6(a) must select -cyclicLong_deg.');
assert(any(strcmp(decision.figure, 'Fig.5(b)') & ...
    strcmp(decision.code_candidate_name, 'elevator_deg') & ...
    decision.selectedForRefresh), ...
    'Fig.5(b) must retain elevator_deg.');
assert(any(strcmp(decision.figure, 'Fig.6(b)') & ...
    strcmp(decision.code_candidate_name, 'elevator_deg') & ...
    decision.selectedForRefresh), ...
    'Fig.6(b) must retain elevator_deg.');

reportText = fileread(fullfile(rootDir, 'docs', 'wing_full_angle', ...
    'NUAA_TRIM_TREND_MAPPING_REFRESH_REPORT.md'));
assert(contains(reportText, 'Fig.5(b) 90°：已核查，仍使用 `elevator_deg`'), ...
    'Report must state Fig.5(b) elevator mapping was rechecked.');
assert(contains(reportText, 'Fig.6(b) 75°：已核查，仍使用 `elevator_deg`'), ...
    'Report must state Fig.6(b) elevator mapping was rechecked.');

[statusModel, outModel] = system(sprintf( ...
    'git -C "%s" status --short -- params_nominal.m model', rootDir));
assert(statusModel == 0, 'git status for protected paths failed.');
protectedDirty = strtrim(outModel);

report = struct();
report.requiredCount = numel(requiredFiles);
report.decisionRows = height(decision);
report.fig5aRefreshed = true;
report.fig6aRefreshed = true;
report.fig5bVariableDefinitionChanged = false;
report.fig6bVariableDefinitionChanged = false;
report.refreshedOverviewExists = true;
report.protectedPathsClean = isempty(protectedDirty);
report.protectedPathStatus = protectedDirty;
report.allPassed = isempty(missing) && report.protectedPathsClean;

fprintf('\nNUAA trim trend mapping refresh check\n');
fprintf('Required artifacts: %d\n', report.requiredCount);
fprintf('Decision rows: %d\n', report.decisionRows);
fprintf('Protected params/model clean: %d\n', report.protectedPathsClean);

assert(report.allPassed, ...
    'NUAA trim trend mapping refresh artifact check failed.');
end
