function modifiedIds = get_modified_parameter_ids(P, baselineP, catalog)
%GET_MODIFIED_PARAMETER_IDS Compare editable catalog items with a baseline.
% The comparison is performed in internal units only. The tolerances are
% intentionally small and only absorb floating point round-off such as
% deg/rad display round trips.

if nargin < 3 || isempty(catalog)
    catalog = build_parameter_catalog();
end

modifiedIds = cell(0,1);
for k = 1:numel(catalog)
    item = catalog(k);
    currentValue = read_internal_value(P, item);
    baselineValue = read_internal_value(baselineP, item);
    if ~values_equal(currentValue, baselineValue)
        modifiedIds{end+1,1} = item.id; %#ok<AGROW>
    end
end
end

function value = read_internal_value(S, item)
value = S;
for k = 1:numel(item.path)
    name = item.path{k};
    if ~isstruct(value) || ~isfield(value, name)
        error('get_modified_parameter_ids:MissingValue', ...
            '参数“%s”缺少对应的数据。', item.name);
    end
    value = value.(name);
end
if ~isempty(item.subscript)
    if numel(item.subscript) == 1
        value = value(item.subscript(1));
    else
        value = value(item.subscript(1), item.subscript(2));
    end
end
if ~(isnumeric(value) && isreal(value) && isscalar(value) && ...
        isfinite(value))
    error('get_modified_parameter_ids:InvalidValue', ...
        '参数“%s”的当前值不是有限实数。', item.name);
end
end

function tf = values_equal(a, b)
absTol = 1.0e-12;
relTol = 1.0e-12;
scale = max([1, abs(a), abs(b)]);
tf = abs(a-b) <= absTol + relTol*scale;
end
