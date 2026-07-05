function result = check_nuaa_trim_trend_layout_fix()
%CHECK_NUAA_TRIM_TREND_LAYOUT_FIX Verify standard NUAA layout outputs.

rootDir = fileparts(fileparts(mfilename('fullpath')));
boardDir = fullfile(rootDir, 'validation', 'nuaa_trim_trend_overlay', ...
    'comparison_boards');
reportPath = fullfile(rootDir, 'docs', 'wing_full_angle', ...
    'NUAA_TRIM_TREND_LAYOUT_FIX_REPORT.md');

overviewPath = fullfile(boardDir, 'nuaa_trim_trend_overlay_overview.png');
singlePaths = {
    fullfile(boardDir, 'compare_fig5a_beta0.png')
    fullfile(boardDir, 'compare_fig5b_beta90.png')
    fullfile(boardDir, 'compare_fig6a_beta15.png')
    fullfile(boardDir, 'compare_fig6b_beta75.png')};

allPaths = [{overviewPath}; singlePaths(:)];
exists = cellfun(@(p) exist(p, 'file') == 2, allPaths);
sizes = cellfun(@(p) dir_size(p), allPaths);
largeEnough = sizes > 50 * 1024;

overviewInfo = imfinfo(overviewPath);
singleInfo = cellfun(@imfinfo, singlePaths);
overviewIsFourByTwo = overviewInfo.Height > overviewInfo.Width && ...
    overviewInfo.Height >= max([singleInfo.Height]) * 2.4;
singlesAreOneByTwo = all([singleInfo.Width] > [singleInfo.Height]);

reportExists = exist(reportPath, 'file') == 2;
reportText = fileread(reportPath);
reportHasConclusion = contains(reportText, 'NUAA_LAYOUT_FIX_READY');
reportHas15Note = contains(reportText, ...
    '15 deg vertical pitch') && contains(reportText, 'not uniquely confirmed');

[status, protectedText] = system(sprintf(['git -C "%s" status --short -- ', ...
    'params_nominal.m model'], rootDir));
protectedClean = status == 0 && isempty(strtrim(protectedText));

result = struct();
result.overviewPath = overviewPath;
result.singlePaths = singlePaths;
result.standardPathsExist = all(exists);
result.pngFilesLargeEnough = all(largeEnough);
result.overviewIsFourByTwo = overviewIsFourByTwo;
result.singlesAreOneByTwo = singlesAreOneByTwo;
result.reportExists = reportExists;
result.reportHasConclusion = reportHasConclusion;
result.reportHas15Note = reportHas15Note;
result.protectedParamsModelClean = protectedClean;
result.passed = result.standardPathsExist && result.pngFilesLargeEnough && ...
    result.overviewIsFourByTwo && result.singlesAreOneByTwo && ...
    result.reportExists && result.reportHasConclusion && ...
    result.reportHas15Note && result.protectedParamsModelClean;

fprintf('\nNUAA trim trend layout fix check\n');
fprintf('================================\n');
fprintf('standard paths exist: %d\n', result.standardPathsExist);
fprintf('PNG files > 50 KB: %d\n', result.pngFilesLargeEnough);
fprintf('overview 4x2 layout signature: %d\n', result.overviewIsFourByTwo);
fprintf('single boards 1x2 layout signature: %d\n', result.singlesAreOneByTwo);
fprintf('layout report exists: %d\n', result.reportExists);
fprintf('protected params/model clean: %d\n', result.protectedParamsModelClean);
fprintf('All layout checks passed: %d\n', result.passed);

assert(result.passed, 'NUAA trim trend layout fix check failed.');
end

function value = dir_size(path)
info = dir(path);
if isempty(info)
    value = 0;
else
    value = info.bytes;
end
end
