function session = load_analysis_case(filePath)
%LOAD_ANALYSIS_CASE Load a saved GUI analysis session with version checks.

if ~(ischar(filePath) || (isstring(filePath) && isscalar(filePath)))
    error('load_analysis_case:InvalidPath', ...
        'filePath must be a character vector or scalar string.');
end
filePath = char(filePath);
if ~exist(filePath, 'file')
    error('load_analysis_case:MissingFile', ...
        'Project file does not exist: %s', filePath);
end

loaded = load(filePath, 'session');
if ~isfield(loaded, 'session') || ~isstruct(loaded.session)
    error('load_analysis_case:MissingSession', ...
        'Project file does not contain a valid session structure.');
end
session = loaded.session;
if ~isfield(session, 'formatVersion') || session.formatVersion ~= 1
    error('load_analysis_case:UnsupportedVersion', ...
        'Unsupported project file version.');
end

required = {'parameters','trim','linearization','response'};
for k = 1:numel(required)
    if ~isfield(session, required{k})
        error('load_analysis_case:MissingField', ...
            'Project file is missing field %s.', required{k});
    end
end
end
