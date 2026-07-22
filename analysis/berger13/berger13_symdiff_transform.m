function transform = berger13_symdiff_transform(A, B, inputContract)
%BERGER13_SYMDIFF_TRANSFORM Left/right to symmetric/differential axes.
% betaDiff and the differential input are defined as (right-left)/2.

if nargin < 3 || isempty(inputContract)
    inputContract = 'TORQUE';
end
if ~ismember(inputContract,{'TORQUE','ANGLE_COMMAND'})
    error('berger13_symdiff_transform:InvalidInputContract', ...
        'inputContract must be TORQUE or ANGLE_COMMAND.');
end

Tstate = eye(13);
Tstate(10:11,10:11) = [0.5, 0.5; -0.5, 0.5];
Tstate(12:13,12:13) = [0.5, 0.5; -0.5, 0.5];
Tinput = eye(10);
Tinput(9:10,9:10) = [0.5, 0.5; -0.5, 0.5];

transform.Tstate = Tstate;
transform.TstateInverse = inv(Tstate);
transform.Tinput = Tinput;
transform.TinputInverse = inv(Tinput);
transform.stateNames = get_state_names_13x10();
transform.stateNames(10:13) = {'betaSym'; 'betaDiff'; ...
    'betaSymDot'; 'betaDiffDot'};
if strcmp(inputContract,'ANGLE_COMMAND')
    transform.inputNames = get_command_input_names_13x10();
    transform.inputNames(9:10) = {'betaSymCommand'; ...
        'betaDiffCommand'};
    transform.inputUnits = get_command_input_units_13x10();
else
    transform.inputNames = get_control_input_names_13x10();
    transform.inputNames(9:10) = {'nacelleTorqueSym'; ...
        'nacelleTorqueDiff'};
    transform.inputUnits = get_control_input_units_13x10();
end
transform.stateUnits = get_state_units_13x10();
transform.inputContract = inputContract;
transform.invertibilityError = max( ...
    norm(Tstate*transform.TstateInverse-eye(13),'fro'), ...
    norm(Tinput*transform.TinputInverse-eye(10),'fro'));

if nargin >= 1 && ~isempty(A)
    if ~isequal(size(A),[13,13])
        error('berger13_symdiff_transform:InvalidA', ...
            'A must be 13-by-13.');
    end
    transform.A = Tstate*A*transform.TstateInverse;
end
if nargin >= 2 && ~isempty(B)
    if ~isequal(size(B),[13,10])
        error('berger13_symdiff_transform:InvalidB', ...
            'B must be 13-by-10.');
    end
    transform.B = Tstate*B*transform.TinputInverse;
end
end
