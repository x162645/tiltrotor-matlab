function ctrl = map_control_inputs(uCtrl, P)
%MAP_CONTROL_INPUTS Map active input vector to named control fields.
% Legacy mode:
%   [collective diffCollective cyclicLong diffCyclic aileron elevator rudder]
% Opt-in lateral cyclic mode:
%   [collective diffCollective cyclicLong diffCyclic lateralCyclic
%    aileron elevator rudder]

uCtrl = uCtrl(:);
names = get_control_input_names(P);
nInput = numel(names);

if ~(isnumeric(uCtrl) && isreal(uCtrl) && numel(uCtrl) == nInput && ...
        all(isfinite(uCtrl)))
    error('map_control_inputs:DimensionMismatch', ...
        'uCtrl must be a finite real %d-element vector.', nInput);
end

ctrl.collective = uCtrl(1);
ctrl.diffCollective = uCtrl(2);
ctrl.cyclicLong = uCtrl(3);
ctrl.diffCyclic = uCtrl(4);
if nInput == 8
    ctrl.lateralCyclic = uCtrl(5);
    ctrl.aileron = uCtrl(6);
    ctrl.elevator = uCtrl(7);
    ctrl.rudder = uCtrl(8);
else
    ctrl.lateralCyclic = 0;
    ctrl.aileron = uCtrl(5);
    ctrl.elevator = uCtrl(6);
    ctrl.rudder = uCtrl(7);
end

ctrl.numInputs = nInput;
ctrl.inputNames = names;
ctrl.inputUnits = get_control_input_units(P);
end
