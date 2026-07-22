function [xTrim,uCommand,report] = trim_berger13_command_symmetric( ...
        condition,P13,opts)
%TRIM_BERGER13_COMMAND_SYMMETRIC Static trim for the angle-command interface.
% At equilibrium each commanded angle equals its corresponding state angle.

if nargin < 2 || isempty(P13)
    P13 = params_berger13();
end
if nargin < 3
    opts = struct();
end
[xTrim,uTorque,torqueReport] = ...
    trim_berger13_symmetric(condition,P13,opts);
uCommand = [uTorque(1:8);xTrim(10);xTrim(11)];
[xdot,out] = tiltrotor_eom_13x10_command(xTrim,uCommand,P13);
dynamicIndices = [1:6,10:13];
dynamicResidual = xdot(dynamicIndices);
finiteReal = isreal(xdot) && all(isfinite(xdot));
credible = torqueReport.credible && finiteReal && ...
    norm(dynamicResidual) < 10*P13.base.trim.residualTolerance && ...
    norm(xTrim(12:13),inf) == 0 && ...
    norm(xTrim(10:11)-uCommand(9:10),inf) == 0;

report = torqueReport;
report.torqueInterfaceTrim = torqueReport;
report.u10Command = uCommand;
report.fullStateDerivativeCommand = xdot;
report.dynamicResidualCommand = dynamicResidual;
report.dynamicResidualNormCommand = norm(dynamicResidual);
report.commandEomOut = out;
report.commandAppliedDifference = max(abs([ ...
    out.nacelle.left.commandApplied;out.nacelle.right.commandApplied] - ...
    uCommand(9:10)));
report.credible = credible;
if credible
    report.status = 'CREDIBLE';
else
    report.status = 'FAILED';
    report.reasons{end+1,1} = ...
        'angle-command equilibrium failed the full 13-state substitution';
end
report.inputContract = 'ANGLE_COMMAND';
report.inputNames = get_command_input_names_13x10();
end
