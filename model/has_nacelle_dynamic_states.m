function tf = has_nacelle_dynamic_states(P)
%HAS_NACELLE_DYNAMIC_STATES True for the opt-in symmetric nacelle states.

tf = false;
if ~isstruct(P) || ~isfield(P, 'nacelleDynamics') || ...
        ~isstruct(P.nacelleDynamics) || ...
        ~isfield(P.nacelleDynamics, 'enabled')
    return;
end

enabled = P.nacelleDynamics.enabled;
if islogical(enabled) && isscalar(enabled)
    tf = enabled;
elseif isnumeric(enabled) && isreal(enabled) && isscalar(enabled) && ...
        isfinite(enabled)
    tf = enabled ~= 0;
end
end
