function comparison = compare_berger13_linear_nonlinear( ...
        trimReport,linearModel,P13,caseDef)
%COMPARE_BERGER13_LINEAR_NONLINEAR State-wise small-disturbance comparison.

nonlinear = simulate_berger13_case(trimReport,P13,caseDef);
t = nonlinear.time;
dt = caseDef.dt;
n = numel(t);
dx = zeros(n,13);
u0 = trimReport.u10Command(:);
A = linearModel.A13Command;
B = linearModel.B13Command;
for k = 1:n-1
    du1 = nonlinear.u(k,:).'-u0;
    du2 = nonlinear.u(k+1,:).'-u0;
    f1 = A*dx(k,:).'+B*du1;
    prediction = dx(k,:).'+dt*f1;
    f2 = A*prediction+B*du2;
    dx(k+1,:) = (dx(k,:).'+0.5*dt*(f1+f2)).';
end
xLinear = dx+trimReport.x13(:).';
stateNames = {'u';'v';'p';'q';'r';'phi';'theta';'psi'; ...
    'betaSym';'betaDiff'};
nonlinearSelected = [nonlinear.x(:,1),nonlinear.x(:,2), ...
    nonlinear.x(:,4:9),nonlinear.betaSym,nonlinear.betaDiff];
linearSelected = [xLinear(:,1),xLinear(:,2),xLinear(:,4:9), ...
    0.5*(xLinear(:,10)+xLinear(:,11)), ...
    0.5*(xLinear(:,11)-xLinear(:,10))];
errorValue = nonlinearSelected-linearSelected;
peakError = max(abs(errorValue),[],1).';
rmsError = sqrt(mean(errorValue.^2,1)).';
phaseError = NaN(numel(stateNames),1);
for j = 1:numel(stateNames)
    [~,iNonlinear] = max(abs(nonlinearSelected(:,j)- ...
        nonlinearSelected(1,j)));
    [~,iLinear] = max(abs(linearSelected(:,j)-linearSelected(1,j)));
    phaseError(j) = t(iNonlinear)-t(iLinear);
end
comparison.caseName = caseDef.name;
comparison.time = t;
comparison.nonlinear = nonlinearSelected;
comparison.linear = linearSelected;
comparison.error = errorValue;
comparison.stateNames = stateNames;
comparison.metrics = table(stateNames,peakError,rmsError,phaseError, ...
    'VariableNames',{'stateName','peakAbsoluteError','rmsError', ...
    'peakTimeDifferenceSeconds'});
comparison.nonlinearSimulation = nonlinear;
comparison.validSmallDisturbanceAmplitude = caseDef.amplitude;
comparison.claimBoundary = ['agreement is numerical/local for this amplitude ' ...
    'and is not external validation'];
end
