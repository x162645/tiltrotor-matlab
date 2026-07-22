function unit = berger13_derivative_unit(outputName,inputName,inputUnit)
%BERGER13_DERIVATIVE_UNIT Return an explicit Jacobian-entry unit string.

contract = berger13_derivative_contract();
outputIndex = find(strcmp(contract.stateNames,outputName),1);
if isempty(outputIndex)
    error('berger13_derivative_unit:UnknownOutput', ...
        'Unknown state derivative output %s.',outputName);
end
if nargin < 3 || isempty(inputUnit)
    inputIndex = find(strcmp(contract.stateNames,inputName),1);
    if isempty(inputIndex)
        inputIndex = find(strcmp(contract.commandInputNames,inputName),1);
        if isempty(inputIndex)
            error('berger13_derivative_unit:UnknownInput', ...
                'Unknown derivative input %s.',inputName);
        end
        inputUnit = contract.commandInputUnits{inputIndex};
    else
        inputUnit = contract.stateUnits{inputIndex};
    end
end
unit = sprintf('(%s)/(%s)', ...
    contract.stateDerivativeUnits{outputIndex},inputUnit);
end
