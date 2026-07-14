function units = get_control_input_units(P)
%GET_CONTROL_INPUT_UNITS Units for the active flight-control inputs.

units = repmat({'rad'}, numel(get_control_input_names(P)), 1);
end
