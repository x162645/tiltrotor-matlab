function result = diagnose_xv15_twist_equivalent_collective_offset()
%DIAGNOSE_XV15_TWIST_EQUIVALENT_COLLECTIVE_OFFSET Read-only diagnostic.
%
% Reproduces the source profile and rootCut-to-tip linear shape fit used by
% build_xv15_v1_hover_validation_instance.m. Computes signed residual means
% over rootCut <= r/R <= 1 with uniform, (r/R)^2, and (r/R)^3 integration
% weights. Does not call a rotor model, alter parameters, or write files.
%
% Source profile: NASA/CR-2017-219486 Appendix A Figure A-2, transcribed as
% nasa_metal_twist_deg in the repository's frozen validation runners.

rootCut = 0.0875;
x = linspace(rootCut, 1, 4001).';
thetaDeg = nasa_metal_twist_deg(x);
thetaRad = thetaDeg*pi/180;

% Exact fit weights passed by the frozen validation runner.
fitWeights = ones(size(x));
fitWeights([1 end]) = 0.5;

xNorm = (x-rootCut)/(1-rootCut);
x75 = (0.75-rootCut)/(1-rootCut);
theta75Rad = interp1(x, thetaRad, 0.75, 'linear');
dx = xNorm-x75;
dthetaRad = thetaRad-theta75Rad;
denominator = sum(fitWeights.*dx.^2);
twistTipEqRad = sum(fitWeights.*dx.*dthetaRad)/denominator;
thetaFitRad = theta75Rad+twistTipEqRad*dx;
residualRad = thetaRad-thetaFitRad;
theta75Deg = theta75Rad*180/pi;
twistTipEqDeg = twistTipEqRad*180/pi;
thetaFitDeg = thetaFitRad*180/pi;
residualDeg = residualRad*180/pi;

% Signed, normalized residual integrals in the r/R coordinate.
powers = [0; 2; 3];
meanResidualDeg = zeros(3,1);
for k = 1:numel(powers)
    w = x.^powers(k);
    meanResidualDeg(k) = trapz(x, w.*residualDeg)/trapz(x, w);
end

% Self-test: this known linear profile is represented exactly.
xTest = [rootCut; 0.25; 0.50; 0.75; 1.00];
fitWeightsTest = [0.5; 1; 1; 1; 0.5];
dxTest = (xTest-rootCut)/(1-rootCut)-x75;
thetaLinearDeg = 4*ones(size(xTest));
thetaLinear75Deg = interp1(xTest, thetaLinearDeg, 0.75, 'linear');
kTest = sum(fitWeightsTest.*dxTest.* ...
    (thetaLinearDeg-thetaLinear75Deg)) / ...
    sum(fitWeightsTest.*dxTest.^2);
linearResidualDeg = thetaLinearDeg-(thetaLinear75Deg+kTest*dxTest);
selfTestMeanResidualDeg = zeros(3,1);
for k = 1:numel(powers)
    wTest = xTest.^powers(k);
    selfTestMeanResidualDeg(k) = ...
        trapz(xTest, wTest.*linearResidualDeg)/trapz(xTest, wTest);
end
assert(all(selfTestMeanResidualDeg == 0), ...
    'Known linear-twist self-test did not return zero residual.');

result = struct();
result.rootCut = rootCut;
result.rR = x;
result.thetaSource_deg = thetaDeg;
result.thetaFit_deg = thetaFitDeg;
result.residual_deg = residualDeg;
result.fitWeights = fitWeights;
result.theta75Source_deg = theta75Deg;
result.twistTipEq_deg = twistTipEqDeg;
result.slope_deg_per_rR = twistTipEqRad/(1-rootCut)*180/pi;
result.intercept_deg = theta75Deg-result.slope_deg_per_rR*0.75;
result.meanResidualUnweighted_deg = meanResidualDeg(1);
result.meanResidualThrustR2_deg = meanResidualDeg(2);
result.meanResidualTorqueR3_deg = meanResidualDeg(3);
result.selfTestMeanResidual_deg = selfTestMeanResidualDeg;

fprintf('rootCut = %.17g\n', rootCut);
fprintf('twistTipEq_deg = %.17g\n', twistTipEqDeg);
fprintf('slope_deg_per_rR = %.17g\n', result.slope_deg_per_rR);
fprintf('intercept_deg = %.17g\n', result.intercept_deg);
fprintf('meanResidual_unweighted_deg = %.17g\n', meanResidualDeg(1));
fprintf('meanResidual_thrust_r2_deg = %.17g\n', meanResidualDeg(2));
fprintf('meanResidual_torque_r3_deg = %.17g\n', meanResidualDeg(3));
fprintf('selfTestMeanResidual_unweighted_deg = %.17g\n', ...
    selfTestMeanResidualDeg(1));
fprintf('selfTestMeanResidual_thrust_r2_deg = %.17g\n', ...
    selfTestMeanResidualDeg(2));
fprintf('selfTestMeanResidual_torque_r3_deg = %.17g\n', ...
    selfTestMeanResidualDeg(3));
fprintf('radial_residuals (rR, true_deg, fit_deg, true_minus_fit_deg)\n');
for k = 1:numel(x)
    fprintf('%.17g %.17g %.17g %.17g\n', x(k), thetaDeg(k), ...
        thetaFitDeg(k), residualDeg(k));
end
end
