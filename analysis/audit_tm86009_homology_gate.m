function [homologyTable,highRows] = audit_tm86009_homology_gate(matrixPath)
%AUDIT_TM86009_HOMOLOGY_GATE Fail closed before quantitative V4 validation.
%
% This gate intentionally contains no aircraft physics. It prevents a
% TM-86009 comparison from being promoted to quantitative validation until
% at least one candidate case has a report-level HIGH homology assessment.
%
% MATLAB R2021a note:
%   The validation ledger is a comma-delimited UTF-8 CSV. Delimiter and
%   header normalization are made explicit here so a locale/import heuristic
%   cannot turn an evidence-gate failure into a false schema failure.

rootDir = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1 || isempty(matrixPath)
    matrixPath = fullfile(rootDir, 'results', ...
        'xv15_validation_baseline', 'TM86009_HOMOLOGY_MATRIX.csv');
end
if ~exist(matrixPath, 'file')
    error('audit_tm86009_homology_gate:MissingMatrix', ...
        'Missing TM-86009 homology matrix: %s', matrixPath);
end

homologyTable = readtable(matrixPath, 'Delimiter', ',', 'TextType', 'string');
actualNames = strtrim(string(homologyTable.Properties.VariableNames));
if ~isempty(actualNames)
    % Strip a possible UTF-8 BOM from the first header after import.
    actualNames(1) = erase(actualNames(1), char(65279));
end
homologyTable.Properties.VariableNames = cellstr(actualNames);

required = ["caseId","source","evidenceType","homologyStatus", ...
    "blocker","allowedClaim"];
missing = required(~ismember(required, actualNames));
if ~isempty(missing)
    error('audit_tm86009_homology_gate:InvalidSchema', ...
        ['Homology matrix is missing required columns: %s. ' ...
         'Imported columns: %s'], ...
        strjoin(cellstr(missing), ', '), strjoin(cellstr(actualNames), ', '));
end

highRows = strcmpi(strtrim(string(homologyTable.homologyStatus)), 'HIGH');
if ~any(highRows)
    pendingCases = strjoin(cellstr(string(homologyTable.caseId)), ', ');
    error('audit_tm86009_homology_gate:NoHighHomologyCase', ...
        ['No TM-86009 case has HIGH homology. Quantitative dynamic ' ...
         'validation is intentionally blocked. Current cases: %s'], ...
        pendingCases);
end

highIdx = find(highRows);
allowedHigh = strcmpi(strtrim(string(homologyTable.allowedClaim(highRows))), ...
    'QUANTITATIVE_DYNAMIC_VALIDATION');
if any(~allowedHigh)
    badIdx = highIdx(~allowedHigh);
    badCases = strjoin(cellstr(string(homologyTable.caseId(badIdx))), ', ');
    error('audit_tm86009_homology_gate:HighCaseClaimMismatch', ...
        ['HIGH cases must explicitly allow ' ...
         'QUANTITATIVE_DYNAMIC_VALIDATION: %s'], badCases);
end
end
