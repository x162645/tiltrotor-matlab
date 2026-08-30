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
tol = 1e-14;

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

uCollectiveHigh = base;
uCollectiveHigh(1) = P.control.collectiveLim(2) + 5*d2r;
[~,~,infoCollectiveHigh] = total_forces_moments(x,uCollectiveHigh,betaM,P);

uCollectiveLow = base;
uCollectiveLow(1) = P.control.collectiveLim(1) - 5*d2r;
[~,~,infoCollectiveLow] = total_forces_moments(x,uCollectiveLow,betaM,P);

uCyclicHigh = base;
uCyclicHigh(3) = P.control.cyclicLim(2) + 5*d2r;
[~,~,infoCyclicHigh] = total_forces_moments(x,uCyclicHigh,betaM,P);

uCyclicLow = base;
uCyclicLow(3) = P.control.cyclicLim(1) - 5*d2r;
[~,~,infoCyclicLow] = total_forces_moments(x,uCyclicLow,betaM,P);

uDiffCollective = base;
uDiffCollective(1) = 30*d2r;
uDiffCollective(2) = 35*d2r;
[~,~,infoDiffCollective] = total_forces_moments(x,uDiffCollective,betaM,P);

uDiffCyclic = base;
uDiffCyclic(3) = 20*d2r;
uDiffCyclic(4) = 20*d2r;
[~,~,infoDiffCyclic] = total_forces_moments(x,uDiffCyclic,betaM,P);

commands = {uHigh,uLow,uCollectiveHigh,uCollectiveLow, ...
    uCyclicHigh,uCyclicLow,uDiffCollective,uDiffCyclic};
infos = {infoHigh,infoLow,infoCollectiveHigh,infoCollectiveLow, ...
    infoCyclicHigh,infoCyclicLow,infoDiffCollective,infoDiffCyclic};

names = {
    'default elevator limit is +/-20 deg';
    'commanded controls preserved';
    'upper conventional-surface limits applied';
    'lower conventional-surface limits applied';
    'total collective rotor limits applied';
    'longitudinal cyclic rotor limits applied';
    'differential collective reconstruction';
    'differential cyclic reconstruction';
    'applied rotor controls within limits';
    'rotor equivalent controls match diagnostics';
    'applied controls finite and real'
    };

passed = false(numel(names),1);
messages = cell(numel(names),1);

passed(1) = max(abs(P.control.elevatorLim(:)/d2r - [-20; 20])) < tol;
messages{1} = 'Default elevator limits must remain +/-20 deg after Issue #23 calibration.';

passed(2) = all_commanded_preserved(infos, commands, tol);
messages{2} = 'Diagnostic commandedControls must preserve the original input vector.';

passed(3) = norm(infoHigh.appliedControls(5:7) - ...
    [P.control.aileronLim(2); P.control.elevatorLim(2); ...
     P.control.rudderLim(2)]) < tol;
messages{3} = 'Aileron, elevator, and rudder upper limits were not applied consistently.';

passed(4) = norm(infoLow.appliedControls(5:7) - ...
    [P.control.aileronLim(1); P.control.elevatorLim(1); ...
     P.control.rudderLim(1)]) < tol;
messages{4} = 'Aileron, elevator, and rudder lower limits were not applied consistently.';

passed(5) = norm(infoCollectiveHigh.appliedControls(1:4) - ...
    [P.control.collectiveLim(2); 0; 0; 0]) < tol && ...
    norm(infoCollectiveLow.appliedControls(1:4) - ...
    [P.control.collectiveLim(1); 0; 0; 0]) < tol;
messages{5} = 'Collective upper/lower limits were not reflected in appliedControls.';

passed(6) = norm(infoCyclicHigh.appliedControls(1:4) - ...
    [base(1); 0; P.control.cyclicLim(2); 0]) < tol && ...
    norm(infoCyclicLow.appliedControls(1:4) - ...
    [base(1); 0; P.control.cyclicLim(1); 0]) < tol;
messages{6} = 'Cyclic upper/lower limits were not reflected in appliedControls.';

passed(7) = norm(infoDiffCollective.appliedControls(1:4) - ...
    rotor_equivalent(infoDiffCollective)) < tol && ...
    infoDiffCollective.appliedRotorControls.left.collective == P.control.collectiveLim(1) && ...
    infoDiffCollective.appliedRotorControls.right.collective < P.control.collectiveLim(2);
messages{7} = 'Differential collective saturation was not reconstructed from side controls.';

passed(8) = norm(infoDiffCyclic.appliedControls(1:4) - ...
    rotor_equivalent(infoDiffCyclic)) < tol && ...
    infoDiffCyclic.appliedRotorControls.right.cyclicLong == P.control.cyclicLim(2) && ...
    abs(infoDiffCyclic.appliedRotorControls.left.cyclicLong) < tol;
messages{8} = 'Differential cyclic saturation was not reconstructed from side controls.';

passed(9) = all_rotor_controls_within_limits(infos, P, tol);
messages{9} = 'At least one applied left/right rotor control is outside model limits.';

passed(10) = all_rotor_equivalents_match(infos, tol);
messages{10} = 'appliedControls(1:4) must match values reconstructed from left/right rotor controls.';

applied = [];
for k = 1:numel(infos)
    applied = [applied; infos{k}.appliedControls(:); rotor_equivalent(infos{k})]; %#ok<AGROW>
end
passed(11) = isreal(applied) && all(isfinite(applied));
messages{11} = 'Applied control vectors contain NaN, Inf, or complex values.';

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
report.appliedRotorDiffCollective = infoDiffCollective.appliedRotorControls;
report.appliedRotorDiffCyclic = infoDiffCyclic.appliedRotorControls;
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

    function eq = rotor_equivalent(info)
        right = info.appliedRotorControls.right;
        left = info.appliedRotorControls.left;
        eq = [
            0.5*(right.collective + left.collective);
            0.5*(right.collective - left.collective);
            0.5*(right.cyclicLong + left.cyclicLong);
            0.5*(right.cyclicLong - left.cyclicLong)
            ];
    end

    function ok = all_commanded_preserved(infoList, commandList, tolerance)
        ok = true;
        for i = 1:numel(infoList)
            ok = ok && norm(infoList{i}.commandedControls - commandList{i}) < tolerance;
        end
    end

    function ok = all_rotor_equivalents_match(infoList, tolerance)
        ok = true;
        for i = 1:numel(infoList)
            ok = ok && norm(infoList{i}.appliedControls(1:4) - ...
                rotor_equivalent(infoList{i})) < tolerance;
        end
    end

    function ok = all_rotor_controls_within_limits(infoList, params, tolerance)
        ok = true;
        for i = 1:numel(infoList)
            left = infoList{i}.appliedRotorControls.left;
            right = infoList{i}.appliedRotorControls.right;
            values = [
                left.collective, right.collective;
                left.cyclicLong, right.cyclicLong
                ];
            lower = [params.control.collectiveLim(1); params.control.cyclicLim(1)];
            upper = [params.control.collectiveLim(2); params.control.cyclicLim(2)];
            ok = ok && all(values(:,1) >= lower - tolerance) && ...
                all(values(:,1) <= upper + tolerance) && ...
                all(values(:,2) >= lower - tolerance) && ...
                all(values(:,2) <= upper + tolerance);
        end
    end
end
