function value = read_parameter_value(P, key)
%READ_PARAMETER_VALUE Read a scalar catalog value from a parameter struct.

[pathParts, index] = parse_parameter_key(key);
value = P;
for k = 1:numel(pathParts)
    if ~isstruct(value) || ~isfield(value, pathParts{k})
        error('read_parameter_value:UnknownKey', ...
            'Unknown parameter key %s.', key);
    end
    value = value.(pathParts{k});
end
if ~isempty(index)
    if strcmp(strjoin(pathParts,'.'), 'linear.du') && index{1} > numel(value)
        value = expanded_control_steps(P);
    end
    value = value(index{:});
end
if ~(isnumeric(value) || islogical(value)) || ~isscalar(value)
    error('read_parameter_value:NonScalarValue', ...
        'Parameter key %s does not refer to a scalar numeric value.', key);
end

function du = expanded_control_steps(P)
duBase = P.linear.du(:);
if numel(get_control_input_names(P)) == 8 && numel(duBase) == 7
    du = [duBase(1:4); duBase(4); duBase(5:7)];
else
    du = duBase;
end
end
end

function [pathParts, index] = parse_parameter_key(key)
key = char(key);
token = regexp(key, '^([A-Za-z]\w*(?:\.[A-Za-z]\w*)*)(?:\((\d+)(?:,(\d+))?\))?$', ...
    'tokens', 'once');
if isempty(token)
    error('read_parameter_value:InvalidKey', ...
        'Invalid parameter key %s.', key);
end
pathParts = strsplit(token{1}, '.');
index = {};
if numel(token) >= 2 && ~isempty(token{2})
    if numel(token) >= 3 && ~isempty(token{3})
        index = {str2double(token{2}), str2double(token{3})};
    else
        index = {str2double(token{2})};
    end
end
end
