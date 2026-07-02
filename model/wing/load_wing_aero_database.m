function db = load_wing_aero_database(P)
%LOAD_WING_AERO_DATABASE Load the selected full-angle wing coefficient table.
% The database is project-relative and stores alpha in rad plus CL/CD/Cm.

persistent cachedPath cachedDb

if isfield(P.wing, 'fullAngleDatabaseFile')
    relPath = P.wing.fullAngleDatabaseFile;
else
    relPath = fullfile('data','wing_full_angle','full_angle_selected', ...
        'wing_full_angle_database.csv');
end

rootDir = fileparts(fileparts(fileparts(mfilename('fullpath'))));
filePath = fullfile(rootDir, relPath);
if ~exist(filePath, 'file')
    error('load_wing_aero_database:MissingDatabase', ...
        'Full-angle wing database not found: %s', filePath);
end

if ~isempty(cachedDb) && strcmp(cachedPath, filePath)
    db = cachedDb;
    return;
end

T = readtable(filePath, 'FileType', 'text');
required = {'alpha_rad','CL','CD','Cm'};
for k = 1:numel(required)
    if ~ismember(required{k}, T.Properties.VariableNames)
        error('load_wing_aero_database:InvalidDatabase', ...
            'Database is missing column %s.', required{k});
    end
end
alpha = T.alpha_rad(:);
[alpha, order] = sort(alpha);
db.alpha = alpha;
db.CL = T.CL(order);
db.CD = T.CD(order);
db.Cm = T.Cm(order);
if ismember('source', T.Properties.VariableNames)
    db.source = T.source(order);
else
    db.source = repmat({''}, numel(alpha), 1);
end
db.path = filePath;
db.id = 'wing_full_angle_v0_partial_20260702';
if any(~isfinite([db.alpha; db.CL; db.CD; db.Cm])) || any(db.CD < 0)
    error('load_wing_aero_database:InvalidValues', ...
        'Full-angle wing database contains invalid coefficient values.');
end
if min(db.alpha) > -pi || max(db.alpha) < pi
    error('load_wing_aero_database:InsufficientRange', ...
        'Full-angle wing database must cover at least [-pi, pi].');
end

cachedPath = filePath;
cachedDb = db;
db = cachedDb;
end
