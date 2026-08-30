function value = get_parameter_catalog_value(P, item)
%GET_PARAMETER_CATALOG_VALUE Read one catalog item in display units.

internalValue = read_internal_value(P, item);
if ~(isnumeric(internalValue) && isreal(internalValue) && ...
        isscalar(internalValue) && isfinite(internalValue))
    error('get_parameter_catalog_value:InvalidValue', ...
        '参数“%s”的当前值不是有限实数。', item.name);
end
value = internalValue*item.displayScale + item.displayOffset;
end

function value = read_internal_value(S, item)
value = S;
for k = 1:numel(item.path)
    name = item.path{k};
    if ~isstruct(value) || ~isfield(value, name)
        error('get_parameter_catalog_value:MissingValue', ...
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
end
