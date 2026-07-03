function report = check_control_surface_aileron_audit()
%CHECK_CONTROL_SURFACE_AILERON_AUDIT Verify aileron source audit artifacts.

rootDir = fileparts(fileparts(fileparts(mfilename('fullpath'))));
auditPath = fullfile(rootDir, 'validation', 'wing_full_angle', ...
    'full_angle', 'control_surface_aileron_source_audit.csv');
docPath = fullfile(rootDir, 'docs', 'wing_full_angle', ...
    'CONTROL_SURFACE_AILERON_AUDIT.md');
assert(exist(auditPath, 'file') == 2, 'Missing aileron source audit CSV.');
assert(exist(docPath, 'file') == 2, 'Missing aileron audit report.');
txt = fileread(auditPath);
lineCount = numel(regexp(strtrim(txt), '\r\n|\n|\r', 'split')) - 1;
assert(lineCount >= 3, 'Aileron source audit has too few rows.');
assert(contains(txt, 'TM-88373 Figure 6a') && ...
    contains(txt, 'NASA CR-176970 text') && contains(txt, 'legacy model'), ...
    'Aileron source audit is missing required source rows.');
assert(~contains(txt, ',YES,'), ...
    'No audited source may be marked usable for differential aileron.');

report.rows = lineCount;
report.allPassed = true;
fprintf('Aileron source audit rows=%d gate=PARTIAL\n', report.rows);
end
