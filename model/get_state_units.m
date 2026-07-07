function units = get_state_units(P)
%GET_STATE_UNITS Return display units for the active nonlinear state vector.

units = {'m/s'; 'm/s'; 'm/s'; 'rad/s'; 'rad/s'; 'rad/s'; ...
    'rad'; 'rad'; 'rad'};
if has_nacelle_dynamic_states(P)
    units = [units; {'rad'; 'rad/s'}];
end
end
