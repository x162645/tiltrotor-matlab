function names = get_control_input_names(P)
%GET_CONTROL_INPUT_NAMES Active flight-control input order.
% Default legacy order is 7 inputs. Enabling P.control.enableLateralCyclic
% inserts symmetric lateral cyclic as input 5 before the fixed surfaces.

legacyNames = {'collective'; 'diffCollective'; 'cyclicLong'; ...
    'diffCyclic'; 'aileron'; 'elevator'; 'rudder'};

if lateral_cyclic_enabled(P)
    names = {'collective'; 'diffCollective'; 'cyclicLong'; ...
        'diffCyclic'; 'lateralCyclic'; 'aileron'; 'elevator'; ...
        'rudder'};
else
    names = legacyNames;
end
end

function enabled = lateral_cyclic_enabled(P)
enabled = isfield(P, 'control') && ...
    isfield(P.control, 'enableLateralCyclic') && ...
    logical(P.control.enableLateralCyclic);
end
