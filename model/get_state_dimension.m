function nx = get_state_dimension(P)
%GET_STATE_DIMENSION Return the active nonlinear state dimension.

if has_nacelle_dynamic_states(P)
    nx = 11;
else
    nx = 9;
end
end
