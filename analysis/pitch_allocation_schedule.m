function allocation = pitch_allocation_schedule(betaM, pitchCommand, P, direction)
%PITCH_ALLOCATION_SCHEDULE Map one virtual pitch command to direct actuators.
% ASSUMED_CONCEPT: cosine-squared open-loop allocation. This is not a
% validated real-aircraft mixer or mechanical transmission model.

validate_scalar(betaM, 'betaM', 0, pi/2, ...
    'pitch_allocation_schedule:InvalidNacelleAngle');
validate_scalar(pitchCommand, 'pitchCommand', -1, 1, ...
    'pitch_allocation_schedule:InvalidPitchCommand');

if ~isstruct(P) || ~isscalar(P) || ~isfield(P, 'control') || ...
        ~isstruct(P.control) || ~isscalar(P.control) || ...
        ~isfield(P.control, 'cyclicLim') || ...
        ~isfield(P.control, 'elevatorLim')
    error('pitch_allocation_schedule:InvalidReference', ...
        'P.control must define cyclicLim and elevatorLim.');
end
cyclicReference = validate_reference(P.control.cyclicLim, 'cyclicLim');
elevatorReference = validate_reference(P.control.elevatorLim, 'elevatorLim');

if ~isstruct(direction) || ~isscalar(direction) || ...
        ~isfield(direction, 'cyclicDirection') || ...
        ~isfield(direction, 'elevatorDirection')
    error('pitch_allocation_schedule:InvalidDirection', ...
        ['direction must contain cyclicDirection and elevatorDirection, ' ...
        'each equal to +1 or -1.']);
end
cyclicDirection = validate_direction(direction.cyclicDirection, ...
    'cyclicDirection');
elevatorDirection = validate_direction(direction.elevatorDirection, ...
    'elevatorDirection');

gCyclic = cos(betaM)^2;
gElevator = sin(betaM)^2;

allocation.type = 'ebook_cosine_virtual_command';
allocation.classification = 'ASSUMED_CONCEPT';
allocation.betaM = betaM;
allocation.gCyclic = gCyclic;
allocation.gElevator = gElevator;
allocation.cyclicReference = cyclicReference;
allocation.elevatorReference = elevatorReference;
allocation.cyclicDirection = cyclicDirection;
allocation.elevatorDirection = elevatorDirection;
allocation.pitchCommand = pitchCommand;
allocation.cyclicLong = cyclicDirection*gCyclic*cyclicReference*pitchCommand;
allocation.elevator = elevatorDirection*gElevator*elevatorReference*pitchCommand;
end

function validate_scalar(value, name, lower, upper, identifier)
if ~(isnumeric(value) && isreal(value) && isscalar(value) && ...
        isfinite(value) && value >= lower && value <= upper)
    error(identifier, '%s must be a finite real scalar in [%g, %g].', ...
        name, lower, upper);
end
end

function reference = validate_reference(limits, name)
if ~(isnumeric(limits) && isreal(limits) && isvector(limits) && ...
        numel(limits) == 2 && all(isfinite(limits(:))) && ...
        limits(1) < limits(2))
    error('pitch_allocation_schedule:InvalidReference', ...
        'P.control.%s must be a finite real two-element limit vector.', name);
end
reference = max(abs(limits(:)));
if ~(isfinite(reference) && reference > 0)
    error('pitch_allocation_schedule:InvalidReference', ...
        'P.control.%s must define a positive actuator reference.', name);
end
end

function value = validate_direction(value, name)
if ~(isnumeric(value) && isreal(value) && isscalar(value) && ...
        isfinite(value) && (value == -1 || value == 1))
    error('pitch_allocation_schedule:InvalidDirection', ...
        '%s must be +1 or -1.', name);
end
end
