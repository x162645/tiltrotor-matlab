function P = write_parameter_value(P, key, value)
%WRITE_PARAMETER_VALUE Write one scalar catalog value and refresh derivatives.

if ~(isnumeric(value) && isreal(value) && isscalar(value) && isfinite(value))
    error('write_parameter_value:InvalidValue', ...
        'Parameter value must be a finite real scalar.');
end

[pathParts, index] = parse_parameter_key(key);
P = assign_value(P, pathParts, index, value);

if strcmp(key, 'rotor.R') || strcmp(key, 'rotor.bladeMass')
    P.rotor.Ib = P.rotor.bladeMass*P.rotor.R^2/3;
    P.rotor.Sblade = P.rotor.bladeMass*P.rotor.R/2;
end
if strcmp(key, 'control.enableLateralCyclic')
    P.control.enableLateralCyclic = logical(value);
end
P = normalize_linear_control_steps(P);
end

function P = assign_value(P, pathParts, index, value)
switch numel(pathParts)
    case 2
        if strcmp(pathParts{1}, 'linear') && strcmp(pathParts{2}, 'du') && ...
                ~isempty(index) && index{1} > numel(P.linear.du)
            P = normalize_linear_control_steps(P);
        end
        if isempty(index)
            P.(pathParts{1}).(pathParts{2}) = value;
        else
            current = P.(pathParts{1}).(pathParts{2});
            current(index{:}) = value;
            if strcmp(pathParts{2}, 'I0') && numel(index) == 2 && index{1} ~= index{2}
                current(index{2}, index{1}) = value;
            end
            P.(pathParts{1}).(pathParts{2}) = current;
        end
    otherwise
        error('write_parameter_value:UnsupportedKey', ...
            'Unsupported parameter key depth.');
end
end

function P = normalize_linear_control_steps(P)
if ~isfield(P, 'linear') || ~isfield(P.linear, 'du')
    return;
end
du = P.linear.du(:);
enabled = isfield(P, 'control') && isfield(P.control, 'enableLateralCyclic') && ...
    logical(P.control.enableLateralCyclic);
if enabled && numel(du) == 7
    P.linear.du = [du(1:4); du(4); du(5:7)];
elseif ~enabled && numel(du) == 8
    P.linear.du = [du(1:4); du(6:8)];
else
    P.linear.du = du;
end
end

function [pathParts, index] = parse_parameter_key(key)
key = char(key);
token = regexp(key, '^([A-Za-z]\w*(?:\.[A-Za-z]\w*)*)(?:\((\d+)(?:,(\d+))?\))?$', ...
    'tokens', 'once');
if isempty(token)
    error('write_parameter_value:InvalidKey', ...
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
