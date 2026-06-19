function report = check_physical_sanity()
%CHECK_PHYSICAL_SANITY Broad physical-order checks for the concept model.
% These checks validate basic plausibility and internal scale only. They do
% not represent XV-15 identification or flight-test validation.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir,'model'));

P = params_nominal();

names = {};
passed = [];
messages = {};

A = pi*P.rotor.R^2;
tipSpeed = P.rotor.Omega*P.rotor.R;
solidity = P.rotor.Nb*P.rotor.chord/(pi*P.rotor.R);
diskLoading = P.mass.m*P.env.g/(2*A);
viHoverEstimate = sqrt((P.mass.m*P.env.g/2)/(2*P.env.rho*A));
principalRadiusEstimate = sqrt(diag(P.mass.I0)/P.mass.m);
mp0 = mass_properties(0,P);
mp90 = mass_properties(pi/2,P);

add_case('finite positive core parameters', ...
    P.mass.m > 0 && P.env.rho > 0 && P.env.g > 0 && ...
    P.rotor.R > 0 && P.rotor.Omega > 0 && P.rotor.chord > 0 && ...
    all(isfinite([P.mass.m; P.env.rho; P.env.g; P.rotor.R; ...
        P.rotor.Omega; P.rotor.chord])), ...
    'Mass, environment, and rotor core parameters must be finite and positive.');

add_case('inertia symmetric positive definite', ...
    norm(P.mass.I0-P.mass.I0.','fro') <= 1e-12*max(norm(P.mass.I0,'fro'),1) && ...
    all(eig(P.mass.I0) > 0) && all(eig(mp90.I) > 0), ...
    'Nominal and endpoint inertia matrices must be symmetric positive definite.');

add_case('rotor scale plausible', ...
    tipSpeed > 100 && tipSpeed < 350 && ...
    solidity > 0.03 && solidity < 0.20 && ...
    diskLoading > 100 && diskLoading < 2000 && ...
    viHoverEstimate > 3 && viHoverEstimate < 40, ...
    'Tip speed, solidity, disk loading, or hover induced-speed scale is outside the broad concept-model range.');

add_case('inertia radius scale plausible', ...
    all(principalRadiusEstimate > 0.2) && ...
    all(principalRadiusEstimate < max(P.wing.b,P.rotor.pivotY*2)), ...
    'Estimated radii of gyration are inconsistent with the current aircraft dimensions.');

add_case('cg shift finite and moderate', ...
    all(isfinite(mp0.cgShift)) && all(isfinite(mp90.cgShift)) && ...
    norm(mp0.cgShift) < 1e-12 && ...
    norm(mp90.cgShift) < 0.25*P.rotor.R, ...
    'Nacelle-induced CG shift is non-finite or too large for the current geometry.');

add_case('component geometry ordered', ...
    P.rotor.pivotY > P.rotor.R && ...
    P.wing.yFreeAC >= 0 && P.wing.ySlipAC >= 0 && ...
    P.wing.yFreeAC <= P.wing.b/2 && P.wing.ySlipAC <= P.wing.b/2 && ...
    P.htail.rAC(1) < 0 && P.vtail.xAC < 0, ...
    'Rotor spacing, wing stations, or tail longitudinal positions are inconsistent.');

allLimits = {P.control.collectiveLim, P.control.cyclicLim, ...
    P.control.aileronLim, P.control.elevatorLim, P.control.rudderLim};
limitsValid = true;
for k = 1:numel(allLimits)
    lim = allLimits{k};
    limitsValid = limitsValid && isnumeric(lim) && isreal(lim) && ...
        numel(lim) == 2 && all(isfinite(lim)) && lim(1) < lim(2);
end
limitsContainNeutral = P.control.cyclicLim(1) <= 0 && P.control.cyclicLim(2) >= 0 && ...
    P.control.aileronLim(1) <= 0 && P.control.aileronLim(2) >= 0 && ...
    P.control.elevatorLim(1) <= 0 && P.control.elevatorLim(2) >= 0 && ...
    P.control.rudderLim(1) <= 0 && P.control.rudderLim(2) >= 0;
add_case('control ranges internally valid', ...
    limitsValid && limitsContainNeutral && P.control.collectiveLim(1) >= 0, ...
    'Control ranges must be finite ordered pairs and include neutral where applicable.');

report.names = names;
report.passed = passed;
report.messages = messages;
report.allPassed = all(passed);
report.metrics.tipSpeed = tipSpeed;
report.metrics.solidity = solidity;
report.metrics.diskAreaEach = A;
report.metrics.diskLoadingTotal = diskLoading;
report.metrics.viHoverEstimate = viHoverEstimate;
report.metrics.principalRadiusEstimate = principalRadiusEstimate;
report.metrics.cgShift90 = mp90.cgShift;
report.scope = ['Broad concept-model plausibility only; no exact aircraft ' ...
    'identification or flight-test validation.'];

fprintf('\nPhysical sanity checks\n');
fprintf('======================\n');
for k = 1:numel(names)
    fprintf('%-36s : %s\n', names{k}, ternary(passed(k),'PASS','FAIL'));
    if ~passed(k)
        fprintf('  %s\n', messages{k});
    end
end
fprintf('tipSpeed=%.3f m/s, solidity=%.5f, diskLoading=%.3f N/m^2\n', ...
    tipSpeed, solidity, diskLoading);
fprintf('viHoverEstimate=%.3f m/s, |cgShift90|=%.5f m\n', ...
    viHoverEstimate, norm(mp90.cgShift));
fprintf('All passed: %d\n', report.allPassed);

    function add_case(name, ok, message)
        names{end+1,1} = name;
        passed(end+1,1) = logical(ok);
        if ok
            messages{end+1,1} = '';
        else
            messages{end+1,1} = message;
        end
    end

    function value = ternary(condition,a,b)
        if condition
            value = a;
        else
            value = b;
        end
    end
end
