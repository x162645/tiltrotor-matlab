function [Pnew, result] = set_parameter_catalog_value(P, item, displayValue)
%SET_PARAMETER_CATALOG_VALUE Write one catalog item after validation.

result = struct('success', false, 'message', '', 'changedIds', {{}}, ...
    'derivedUpdates', {{}});
Pnew = P;

if ~(isnumeric(displayValue) && isreal(displayValue) && ...
        isscalar(displayValue) && isfinite(displayValue))
    result.message = sprintf('“%s”必须填写有限实数。', item.name);
    return;
end

if ~within_bound(displayValue, item.minimum, item.minimumInclusive, true)
    result.message = sprintf('“%s”低于允许下限。', item.name);
    return;
end
if ~within_bound(displayValue, item.maximum, item.maximumInclusive, false)
    result.message = sprintf('“%s”高于允许上限。', item.name);
    return;
end
if item.integerRequired && displayValue ~= round(displayValue)
    result.message = sprintf('“%s”必须是整数。', item.name);
    return;
end

internalValue = (displayValue - item.displayOffset)/item.displayScale;
candidate = P;
candidate = write_internal_value(candidate, item, internalValue);
[candidate, derivedUpdates] = apply_write_policy(candidate, item);

validation = validate_parameter_set(candidate);
if ~validation.valid
    result.message = strjoin(validation.errors, newline);
    return;
end

Pnew = candidate;
result.success = true;
result.message = sprintf('“%s”已更新。', item.name);
result.changedIds = {item.id};
result.derivedUpdates = derivedUpdates;
end

function tf = within_bound(value, bound, inclusive, isLower)
if isinf(bound)
    tf = true;
elseif isLower && inclusive
    tf = value >= bound;
elseif isLower
    tf = value > bound;
elseif inclusive
    tf = value <= bound;
else
    tf = value < bound;
end
end

function S = write_internal_value(S, item, value)
if isempty(item.path)
    error('set_parameter_catalog_value:InvalidPath', ...
        '参数“%s”缺少写入位置。', item.name);
end
S = write_at_path(S, item.path, item.subscript, value);
end

function S = write_at_path(S, pathParts, subscript, value)
fieldName = pathParts{1};
if numel(pathParts) == 1
    target = S.(fieldName);
    if isempty(subscript)
        target = value;
    elseif numel(subscript) == 1
        target(subscript(1)) = value;
    else
        target(subscript(1), subscript(2)) = value;
    end
    S.(fieldName) = target;
else
    S.(fieldName) = write_at_path(S.(fieldName), pathParts(2:end), ...
        subscript, value);
end
end

function [P, derivedUpdates] = apply_write_policy(P, item)
derivedUpdates = {};
switch item.writePolicy
    case 'rotorDerived'
        P.rotor.Ib = P.rotor.bladeMass*P.rotor.R^2/3;
        P.rotor.Sblade = P.rotor.bladeMass*P.rotor.R/2;
        derivedUpdates = {'桨叶挥舞惯量'; '桨叶一阶质量矩'};
    case 'symmetricI0'
        if numel(item.subscript) == 2 && item.subscript(1) ~= item.subscript(2)
            i = item.subscript(1);
            j = item.subscript(2);
            P.mass.I0(j,i) = P.mass.I0(i,j);
        end
    case 'diagKI'
        if numel(item.subscript) == 2
            i = item.subscript(1);
            j = item.subscript(2);
            if i ~= j
                error('set_parameter_catalog_value:InvalidInertiaRate', ...
                    '倾转惯量变化率只允许编辑对角分量。');
            end
        end
    case 'direct'
    otherwise
        error('set_parameter_catalog_value:UnsupportedPolicy', ...
            '参数“%s”的写入方式不受支持。', item.name);
end
end
