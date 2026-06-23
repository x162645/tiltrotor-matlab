function filtered = filter_parameter_catalog(catalog, options)
%FILTER_PARAMETER_CATALOG Filter parameter catalog entries.

if nargin < 2 || isempty(options)
    options = struct();
end

mask = true(numel(catalog), 1);

if isfield(options, 'category') && ~isempty(options.category)
    category = char(options.category);
    mask = mask & strcmp({catalog.category}.', category);
end

if isfield(options, 'query') && ~isempty(options.query)
    query = lower(char(options.query));
    queryMask = false(numel(catalog), 1);
    for k = 1:numel(catalog)
        haystack = lower([catalog(k).id ' ' catalog(k).name ' ' catalog(k).category ' ' ...
            catalog(k).description ' ' catalog(k).basis]);
        queryMask(k) = contains(haystack, query);
    end
    mask = mask & queryMask;
end

if isfield(options, 'modifiedOnly') && logical(options.modifiedOnly)
    if isfield(options, 'modifiedIds') && ~isempty(options.modifiedIds)
        modifiedIds = normalize_ids(options.modifiedIds);
        mask = mask & ismember({catalog.id}.', modifiedIds);
    else
        mask = false(numel(catalog), 1);
    end
end

filtered = catalog(mask);
end

function ids = normalize_ids(value)
if ischar(value)
    ids = {value};
elseif isstring(value)
    ids = cellstr(value(:));
elseif iscell(value)
    ids = value(:);
else
    ids = {};
end
end
