function [x, uCtrl, residual, penalty, xdot, eomOut, allocation] = ...
        evaluate_trim_definition_point(condition, definition, z, P)
%EVALUATE_TRIM_DEFINITION_POINT Construct and evaluate one trim point.
% This is the shared physical point path for trim_general and trim
% credibility diagnostics. Base state order is [u v w p q r phi theta psi],
% optionally followed by [betaM betaM_dot] when nacelle dynamics are enabled.
% control order is [collective diffCollective cyclicLong diffCyclic
% aileron elevator rudder], and angular quantities are in rad.

stateNames = get_state_names(P);
controlNames = {'collective'; 'diffCollective'; 'cyclicLong'; ...
    'diffCyclic'; 'aileron'; 'elevator'; 'rudder'};
derivativeNames = derivative_names(P);

z = z(:);
if numel(z) ~= numel(definition.unknownNames)
    error('evaluate_trim_definition_point:InvalidUnknownVector', ...
        'z must match definition.unknownNames.');
end

x = zeros(get_state_dimension(P),1);
uCtrl = zeros(7,1);
allocation = struct([]);
x = apply_named_values(x, stateNames, definition.fixedStates);
uCtrl = apply_named_values(uCtrl, controlNames, definition.fixedControls);
if has_nacelle_dynamic_states(P)
    x(strcmp(stateNames, 'betaM')) = condition.betaM;
    x(strcmp(stateNames, 'betaM_dot')) = 0;
end

for i = 1:numel(definition.unknownNames)
    name = definition.unknownNames{i};
    stateIndex = find(strcmp(stateNames, name), 1);
    controlIndex = find(strcmp(controlNames, name), 1);
    if ~isempty(stateIndex)
        x(stateIndex) = z(i);
    elseif ~isempty(controlIndex)
        uCtrl(controlIndex) = z(i);
    end
end

if isfield(definition, 'allocation')
    pitchIndex = strcmp(definition.unknownNames, 'pitchCommand');
    allocation = pitch_allocation_schedule(condition.betaM, ...
        z(pitchIndex), P, definition.allocation.direction);
    uCtrl(strcmp(controlNames, 'cyclicLong')) = allocation.cyclicLong;
    uCtrl(strcmp(controlNames, 'elevator')) = allocation.elevator;
end

theta = x(strcmp(stateNames, 'theta'));
alpha = theta-condition.gamma;
if condition.V < 1e-10
    x(strcmp(stateNames, 'u')) = 0;
    x(strcmp(stateNames, 'w')) = 0;
else
    x(strcmp(stateNames, 'u')) = condition.V*cos(alpha);
    x(strcmp(stateNames, 'w')) = condition.V*sin(alpha);
end

[xdot, eomOut] = tiltrotor_eom(x, uCtrl, condition.betaM, P);
xdot = xdot(:);
residual = zeros(numel(definition.residualNames),1);
for j = 1:numel(residual)
    residual(j) = xdot(strcmp(derivativeNames, ...
        definition.residualNames{j}));
end

bounds = definition.bounds;
below = max(bounds(:,1)-z, 0);
above = max(z-bounds(:,2), 0);
penalty = 100*sum(below.^2 + above.^2);
if ~isempty(allocation)
    generatedValues = [allocation.cyclicLong; allocation.elevator];
    generatedBounds = [P.control.cyclicLim(:).'; ...
        P.control.elevatorLim(:).'];
    generatedBelow = max(generatedBounds(:,1)-generatedValues, 0);
    generatedAbove = max(generatedValues-generatedBounds(:,2), 0);
    penalty = penalty + ...
        100*sum(generatedBelow.^2 + generatedAbove.^2);
end
end

function vector = apply_named_values(vector, names, values)
fields = fieldnames(values);
for i = 1:numel(fields)
    vector(strcmp(names, fields{i})) = values.(fields{i});
end
end

function names = derivative_names(P)
names = {'udot'; 'vdot'; 'wdot'; 'pdot'; 'qdot'; ...
    'rdot'; 'phidot'; 'thetadot'; 'psidot'};
if has_nacelle_dynamic_states(P)
    names = [names; {'betaM_dot'; 'betaM_ddot'}];
end
end
