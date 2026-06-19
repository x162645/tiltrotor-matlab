function report = check_control_limits()
%CHECK_CONTROL_LIMITS Verify that commanded controls are consistently clamped.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir,'model'));

P = params_nominal();
d2r = pi/180;

x = [40;0;0;0;0;0;0;0;0];
betaM = pi/2;
base = [8*d2r;0;0;0;0;0;0];

uHigh = base;
uHigh(5) = P.control.aileronLim(2) + 5*d2r;
uHigh(6) = P.control.elevatorLim(2) + 5*d2r;
uHigh(7) = P.control.rudderLim(2) + 5*d2r;
[~,~,infoHigh] = total_forces_moments(x,uHigh,betaM,P);

uLow = base;
uLow(5) = P.control.aileronLim(1) - 5*d2r;
uLow(6) = P.control.elevatorLim(1) - 5*d2r;
uLow(7) = P.control.rudderLim(1) - 5*d2r;
[~,~,infoLow] = total_forces_moments(x,uLow,betaM,P);

names = {
    'commanded controls preserved';
    'upper conventional-surface limits applied';
    'lower conventional-surface limits applied';
    'applied controls finite and real'
    };

passed = false(4,1);
messages = cell(4,1);

passed(1) = norm(infoHigh.commandedControls-uHigh) < 1e-14 && ...
    norm(infoLow.commandedControls-uLow) < 1e-14;
messages{1} = 'Diagnostic commandedControls must preserve the original input vector.';

passed(2) = norm(infoHigh.appliedControls(5:7) - ...
    [P.control.aileronLim(2); P.control.elevatorLim(2); ...
     P.control.rudderLim(2)]) < 1e-14;
messages{2} = 'Aileron, elevator, and rudder upper limits were not applied consistently.';

passed(3) = norm(infoLow.appliedControls(5:7) - ...
    [P.control.aileronLim(1); P.control.elevatorLim(1); ...
     P.control.rudderLim(1)]) < 1e-14;
messages{3} = 'Aileron, elevator, and rudder lower limits were not applied consistently.';

applied = [infoHigh.appliedControls(:); infoLow.appliedControls(:)];
passed(4) = isreal(applied) && all(isfinite(applied));
messages{4} = 'Applied control vectors contain NaN, Inf, or complex values.';

for k = 1:numel(passed)
    if passed(k)
        messages{k} = '';
    end
end

report.names = names;
report.passed = passed;
report.messages = messages;
report.allPassed = all(passed);
report.commandedHigh = uHigh;
report.commandedLow = uLow;
report.appliedHigh = infoHigh.appliedControls;
report.appliedLow = infoLow.appliedControls;
report.limitSemantics = ['Current limits are model input-envelope limits. ' ...
    'They are not claimed to be exact aircraft mechanical limits.'];

fprintf('\nControl-limit application checks\n');
fprintf('================================\n');
for k = 1:numel(names)
    fprintf('%-42s : %s\n', names{k}, ternary(passed(k),'PASS','FAIL'));
    if ~passed(k)
        fprintf('  %s\n', messages{k});
    end
end
fprintf('All passed: %d\n', report.allPassed);

    function value = ternary(condition,a,b)
        if condition
            value = a;
        else
            value = b;
        end
    end
end
