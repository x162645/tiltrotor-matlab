function point = evaluate_berger13_trim_point( ...
        condition, definition, z, P13)
%EVALUATE_BERGER13_TRIM_POINT Build one symmetric torque-interface point.
% State and input contracts are frozen by the Berger13 PR1 namespace.
% Static nacelle holding torque is zero because the PR1 torque equation has
% no active stiffness term: I*betaDDot = Q - D*betaDot.

if nargin < 4 || isempty(P13)
    P13 = params_berger13();
end
[x9, u7, baseResidual, penalty, baseXdot, baseOut, allocation] = ...
    evaluate_trim_definition_point(condition, definition, z, P13.base);

betaM = condition.betaM;
x13 = [x9(:); betaM; betaM; 0; 0];
u10 = [u7(1:4); 0; u7(5:7); 0; 0];
[xdot13, eomOut] = tiltrotor_eom_13x10(x13, u10, P13);

derivativeNames = {'udot'; 'vdot'; 'wdot'; 'pdot'; 'qdot'; 'rdot'; ...
    'phidot'; 'thetadot'; 'psidot'; 'betaMLdot'; 'betaMRdot'; ...
    'betaMLddot'; 'betaMRddot'};
residual = zeros(numel(definition.residualNames),1);
for k = 1:numel(residual)
    residual(k) = xdot13(strcmp(derivativeNames, ...
        definition.residualNames{k}));
end

point.x13 = x13;
point.u10Torque = u10;
point.xdot13 = xdot13;
point.residual = residual;
point.residualLabels = definition.residualNames(:);
point.penalty = penalty;
point.forceBalanceBody = eomOut.Ftotal;
point.momentBalanceBody = eomOut.Mtotal;
point.eomOut = eomOut;
point.allocation = allocation;
point.base.x9 = x9;
point.base.u7 = u7;
point.base.residual = baseResidual;
point.base.xdot9 = baseXdot;
point.base.eomOut = baseOut;
point.finiteReal = isreal(xdot13) && all(isfinite(xdot13)) && ...
    isreal(eomOut.Ftotal) && all(isfinite(eomOut.Ftotal)) && ...
    isreal(eomOut.Mtotal) && all(isfinite(eomOut.Mtotal));
end
