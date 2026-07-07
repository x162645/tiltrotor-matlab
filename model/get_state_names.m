function names = get_state_names(P)
%GET_STATE_NAMES Return state names for the active nonlinear state vector.

names = {'u'; 'v'; 'w'; 'p'; 'q'; 'r'; 'phi'; 'theta'; 'psi'};
if has_nacelle_dynamic_states(P)
    names = [names; {'betaM'; 'betaM_dot'}];
end
end
