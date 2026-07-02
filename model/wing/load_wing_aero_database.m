function db = load_wing_aero_database(P)
%LOAD_WING_AERO_DATABASE Load the selected full-angle wing coefficient table.
% The production interface accepts alpha/Re/Mach/flap dimensions. Current
% provisional tables may still be alpha-only, but that reduction is carried
% explicitly in db.dimensionPolicy and lookup diagnostics.

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
db.Re = optional_numeric_column(T, 'Re', order, NaN);
db.Mach = optional_numeric_column(T, 'Mach', order, NaN);
db.flapDeg = optional_numeric_column(T, 'flap_deg', order, 0);
if ismember('source', T.Properties.VariableNames)
    db.source = T.source(order);
else
    db.source = repmat({''}, numel(alpha), 1);
end
if ismember('source_class', T.Properties.VariableNames)
    db.sourceClass = T.source_class(order);
else
    db.sourceClass = db.source;
end
if ismember('validity', T.Properties.VariableNames)
    db.validity = T.validity(order);
else
    db.validity = repmat({'PROVISIONAL'}, numel(alpha), 1);
end
db.path = filePath;
db.id = 'wing_full_angle_v0_partial_20260702';
if isfield(P.wing, 'fullAngleDatabaseDimensionPolicy')
    db.dimensionPolicy = P.wing.fullAngleDatabaseDimensionPolicy;
else
    db.dimensionPolicy = 'unspecified';
end
db.hasReDimension = any(isfinite(db.Re)) && numel(unique(db.Re(isfinite(db.Re)))) > 1;
db.hasMachDimension = any(isfinite(db.Mach)) && numel(unique(db.Mach(isfinite(db.Mach)))) > 1;
db.hasFlapDimension = any(isfinite(db.flapDeg)) && numel(unique(db.flapDeg(isfinite(db.flapDeg)))) > 1;
db.isReducedAlphaOnly = ~(db.hasReDimension || db.hasMachDimension || db.hasFlapDimension);
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

function values = optional_numeric_column(T, name, order, defaultValue)
if ismember(name, T.Properties.VariableNames)
    raw = T.(name);
    values = raw(order);
else
    values = defaultValue*ones(numel(order), 1);
end
end
