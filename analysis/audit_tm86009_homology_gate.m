function [homologyTable,highRows] = audit_tm86009_homology_gate(matrixPath)
%AUDIT_TM86009_HOMOLOGY_GATE Fail closed before quantitative V4 validation.
%
% This gate intentionally contains no aircraft physics.  It prevents a
% TM-86009 comparison from being promoted to quantitative validation until
% at least one candidate case has a report-level HIGH homology assessment.

rootDir = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1 || isempty(matrixPath)
    matrixPath = fullfile(rootDir, 'results', ...
        'xv15_validation_baseline', 'TM86009_HOMOLOGY_MATRIX.csv');
end
if ~exist(matrixPath, 'file')
    error('audit_tm86009_homology_gate:MissingMatrix', ...
        'Missing TM-86009 homology matrix: %s', matrixPath);
end

homologyTable = readtable(matrixPath, 'TextType', 'string');
required = ["caseId","source","evidenceType","homologyStatus", ...
    "blocker","allowedClaim"];
missing = required(~ismember(required, string(homologyTable.Properties.VariableNames)));
if ~isempty(missing)
    error('audit_tm86009_homology_gate:InvalidSchema', ...
        'Homology matrix is missing required columns: %s', ...
        strjoin(cellstr(missing), ', '));
end

highRows = strcmpi(strtrim(homologyTable.homologyStatus), 'HIGH');
if ~any(highRows)
    pendingCases = strjoin(cellstr(homologyTable.caseId), ', ');
    error('audit_tm86009_homology_gate:NoHighHomologyCase', ...
        ['No TM-86009 case has HIGH homology. Quantitative dynamic ' ...
         'validation is intentionally blocked. Current cases: %s'], ...
        pendingCases);
end

invalidClaim = ~strcmpi(strtrim(homologyTable.allowedClaim(highRows)), ...
    'QUANTITATIVE_DYNAMIC_VALIDATION');
if any(invalidClaim)
    badCases = strjoin(cellstr(homologyTable.caseId(highRows & ...
        ismember((1:height(homologyTable))', find(highRows(invalidClaim))))), ', ');
    error('audit_tm86009_homology_gate:HighCaseClaimMismatch', ...
        'HIGH cases must explicitly allow QUANTITATIVE_DYNAMIC_VALIDATION: %s', ...
        badCases);
end
end
