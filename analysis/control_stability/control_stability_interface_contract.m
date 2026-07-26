function contract = control_stability_interface_contract()
%CONTROL_STABILITY_INTERFACE_CONTRACT Frozen post-processing input contract.
% This function documents existing interfaces; it does not alter allocation.

contract.nineStateNames = ...
    {'u';'v';'w';'p';'q';'r';'phi';'theta';'psi'};
contract.nineStateUnits = ...
    {'m/s';'m/s';'m/s';'rad/s';'rad/s';'rad/s'; ...
     'rad';'rad';'rad'};
contract.nineInputNames = ...
    {'collective';'diffCollective';'cyclicLong';'diffCyclic'; ...
     'aileron';'elevator';'rudder'};
contract.nineInputUnits = repmat({'rad'},7,1);
contract.betaMRole = 'EXTERNAL_CONFIGURATION_PARAMETER';
contract.betaMUnit = 'rad';
contract.betaMIsNineStateBColumn = false;

contract.thirteenStateNames = get_state_names_13x10();
contract.thirteenStateUnits = get_state_units_13x10();
contract.thirteenTorqueInputNames = get_control_input_names_13x10();
contract.thirteenTorqueInputUnits = get_control_input_units_13x10();
contract.thirteenCommandInputNames = get_command_input_names_13x10();
contract.thirteenCommandInputUnits = get_command_input_units_13x10();
contract.nineToThirteenInputColumns = [1;2;3;4;6;7;8];

contract.rotorAllocation = {
    'rightCollective = collective + diffCollective'
    'leftCollective = collective - diffCollective'
    'rightCyclicLong = cyclicLong + diffCyclic'
    'leftCyclicLong = cyclicLong - diffCyclic'
    'theta1sSide = -rotDir*cyclicSide'
    };
contract.diffCyclicAcademicName = ...
    'differentialLongitudinalCyclic';
contract.lateralChannels = ...
    {'aileron';'diffCollective';'diffCyclic'};
contract.lateralChannelsAreInterchangeable = false;
contract.sourceFiles = {
    'model/total_forces_moments.m'
    'model/berger13/get_control_input_names_13x10.m'
    'model/berger13/get_command_input_names_13x10.m'
    'model/berger13/tiltrotor_eom_13x10.m'
    'model/berger13/tiltrotor_eom_13x10_command.m'
    };
end
