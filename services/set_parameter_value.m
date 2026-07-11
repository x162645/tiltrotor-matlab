function P = set_parameter_value(P, key, value)
%SET_PARAMETER_VALUE Compatibility wrapper for catalog writes.
P = write_parameter_value(P, key, value);
end
