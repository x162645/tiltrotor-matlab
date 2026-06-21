function definition = make_trim_definition(mode, condition, P)
%MAKE_TRIM_DEFINITION Build an explicit longitudinal trim definition.

if nargin < 3
    error('make_trim_definition:InvalidInput', ...
        'mode, condition, and P are required.');
end
if ~(ischar(mode) || (isstring(mode) && isscalar(mode)))
    error('make_trim_definition:InvalidMode', ...
        'mode must be a character vector or scalar string.');
end
mode = char(mode);

d2r = pi/180;
fixedStates = struct('v', 0, 'p', 0, 'q', 0, 'r', 0, ...
    'phi', 0, 'psi', 0);
fixedControls = struct('diffCollective', 0, 'diffCyclic', 0, ...
    'aileron', 0, 'rudder', 0);

definition.name = mode;
definition.mode = mode;
definition.residualNames = {'udot'; 'wdot'; 'qdot'};
definition.fixedStates = fixedStates;
definition.fixedControls = fixedControls;
definition.compatibilityMode = false;

switch mode
    case {'legacy_symmetric', 'helicopter_longitudinal'}
        definition.unknownNames = {'theta'; 'collective'; 'cyclicLong'};
        definition.fixedControls.elevator = 0;
        if condition.V < 1
            initialDeg = [0; 18; 0];
        elseif condition.betaM < pi/4
            initialDeg = [4; 16; 2];
        else
            initialDeg = [4; 8; -4];
        end
        definition.initialValues = initialDeg*d2r;
        definition.variableScale = P.trim.variableScale(:);
        definition.bounds = [ ...
            -35*d2r, 35*d2r; ...
            P.control.collectiveLim(:).'; ...
            P.control.cyclicLim(:).'];
        definition.compatibilityMode = strcmp(mode, 'legacy_symmetric');

    case 'airplane_longitudinal'
        definition.unknownNames = {'theta'; 'collective'; 'elevator'};
        definition.fixedControls.cyclicLong = 0;
        definition.initialValues = [4; 8; 0]*d2r;
        % These are numerical search scales, not aircraft parameters.
        definition.variableScale = [2; 18; 2]*d2r;
        definition.bounds = [ ...
            -35*d2r, 35*d2r; ...
            P.control.collectiveLim(:).'; ...
            P.control.elevatorLim(:).'];

    case 'conversion_longitudinal'
        % ASSUMED_CONCEPT: one normalized virtual pitch command is mapped
        % to cyclicLong and elevator by the explicit cosine schedule.
        direction = struct('cyclicDirection', -1, ...
            'elevatorDirection', -1);
        zeroAllocation = pitch_allocation_schedule( ...
            condition.betaM, 0, P, direction);
        definition.unknownNames = {'theta'; 'collective'; 'pitchCommand'};
        definition.allocation.type = 'ebook_cosine_virtual_command';
        definition.allocation.classification = 'ASSUMED_CONCEPT';
        definition.allocation.direction = direction;

        if condition.betaM < pi/4
            initialThetaDeg = 4;
            initialCollectiveDeg = 16;
            initialCyclicDeg = 2;
            initialPitchCommand = (initialCyclicDeg*d2r)/( ...
                direction.cyclicDirection*zeroAllocation.gCyclic* ...
                zeroAllocation.cyclicReference);
        elseif condition.betaM < pi/2
            initialThetaDeg = 4;
            initialCollectiveDeg = 8;
            initialCyclicDeg = -4;
            initialPitchCommand = (initialCyclicDeg*d2r)/( ...
                direction.cyclicDirection*zeroAllocation.gCyclic* ...
                zeroAllocation.cyclicReference);
        else
            initialThetaDeg = 4;
            initialCollectiveDeg = 8;
            initialElevatorDeg = 0;
            initialPitchCommand = (initialElevatorDeg*d2r)/( ...
                direction.elevatorDirection*zeroAllocation.gElevator* ...
                zeroAllocation.elevatorReference);
        end
        definition.initialValues = [initialThetaDeg*d2r; ...
            initialCollectiveDeg*d2r; initialPitchCommand];
        % NUMERICAL search scale derived from a 2 deg direct-actuator scale.
        pitchCommandScale = (2*d2r)/( ...
            zeroAllocation.gCyclic*zeroAllocation.cyclicReference + ...
            zeroAllocation.gElevator*zeroAllocation.elevatorReference);
        definition.variableScale = [2*d2r; 18*d2r; pitchCommandScale];
        definition.bounds = [ ...
            -35*d2r, 35*d2r; ...
            P.control.collectiveLim(:).'; ...
            -1, 1];

    otherwise
        error('make_trim_definition:UnsupportedMode', ...
            'Unsupported trim mode "%s".', mode);
end
end
