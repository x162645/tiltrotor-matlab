function save_analysis_case(filePath, session)
%SAVE_ANALYSIS_CASE Save parameters and available analysis products to MAT.

if ~(ischar(filePath) || (isstring(filePath) && isscalar(filePath)))
    error('save_analysis_case:InvalidPath', ...
        'filePath must be a character vector or scalar string.');
end
filePath = char(filePath);
if isempty(filePath)
    error('save_analysis_case:InvalidPath', 'filePath must not be empty.');
end
if ~isstruct(session)
    error('save_analysis_case:InvalidSession', 'session must be a structure.');
end

[folder,~,extension] = fileparts(filePath);
if isempty(extension)
    filePath = [filePath '.mat'];
elseif ~strcmpi(extension,'.mat')
    error('save_analysis_case:InvalidExtension', ...
        'Analysis sessions must use the .mat extension.');
end
if ~isempty(folder) && ~exist(folder,'dir')
    error('save_analysis_case:MissingFolder', ...
        'Target folder does not exist: %s', folder);
end

session.exportedAt = datestr(now,30);
session.formatVersion = 1;
save(filePath, 'session', '-v7');
end
