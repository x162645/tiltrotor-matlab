function report = check_lateral_cyclic_input()
%CHECK_LATERAL_CYCLIC_INPUT Verify opt-in 8th flight-control input mapping.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir,'model'));
addpath(fullfile(rootDir,'analysis'));

d2r = pi/180;
P = params_nominal();
betaM = pi/2;
x = [40;0;0;0;0;0;0;0;0];

cases = {};
passed = [];
messages = {};

run_case('legacy 7-input dimensions and labels', @check_legacy_dimensions);
run_case('enabled 8-input dimensions and labels', @check_enabled_dimensions);
run_case('lateralCyclic produces lateral response', @check_lateral_response);
run_case('rotDir aligns disk lateral response', @check_rotDir_disk_response);
run_case('current mapping remains cancellation diagnostic', @check_current_cancellation);
run_case('minusRotDir reverses lateral sign', @check_minusRotDir_sign);
run_case('surface index alignment is protected', @check_surface_alignment);

report.names = cases;
report.passed = passed;
report.messages = messages;
report.allPassed = all(passed);

fprintf('\nLateral cyclic input checks\n');
fprintf('===========================\n');
for k = 1:numel(cases)
    fprintf('%-42s : %s\n', cases{k}, ternary(passed(k),'PASS','FAIL'));
    if ~passed(k)
        fprintf('  %s\n', messages{k});
    end
end
fprintf('All passed: %d\n', report.allPassed);

    function run_case(name, fun)
        cases{end+1,1} = name;
        try
            fun();
            passed(end+1,1) = true;
            messages{end+1,1} = '';
        catch ME
            passed(end+1,1) = false;
            messages{end+1,1} = ME.message;
        end
    end

    function check_legacy_dimensions()
        P0 = P;
        P0.control.enableLateralCyclic = false;
        u = [8*d2r;0;0;0;1*d2r;-2*d2r;3*d2r];
        names = get_control_input_names(P0);
        ctrl = map_control_inputs(u, P0);
        [xdot, out] = tiltrotor_eom(x, u, betaM, P0);
        [~, B, lin] = linearize_numeric(x, u, betaM, P0);

        assert(numel(names) == 7);
        assert(strcmp(names{5}, 'aileron'));
        assert(ctrl.lateralCyclic == 0);
        assert(abs(ctrl.aileron - u(5)) < eps);
        assert(numel(xdot) == get_state_dimension(P0));
        assert(isequal(size(B), [get_state_dimension(P0), 7]));
        assert(lin.finite);
        assert(abs(out.components.appliedControls(5) - u(5)) < eps);
        assert(abs(out.components.appliedControls(6) - u(6)) < eps);
        assert(abs(out.components.appliedControls(7) - u(7)) < eps);
        assert(out.components.rotorLeft.theta1c == 0);
        assert(out.components.rotorRight.theta1c == 0);
    end

    function check_enabled_dimensions()
        P8 = P;
        P8.control.enableLateralCyclic = true;
        u = [8*d2r;0;0;0;1*d2r;2*d2r;-2*d2r;3*d2r];
        names = get_control_input_names(P8);
        ctrl = map_control_inputs(u, P8);
        [xdot, out] = tiltrotor_eom(x, u, betaM, P8);
        [~, B, lin] = linearize_numeric(x, u, betaM, P8);

        assert(numel(names) == 8);
        assert(strcmp(names{5}, 'lateralCyclic'));
        assert(strcmp(names{6}, 'aileron'));
        assert(strcmp(names{7}, 'elevator'));
        assert(strcmp(names{8}, 'rudder'));
        assert(abs(ctrl.lateralCyclic - u(5)) < eps);
        assert(abs(ctrl.aileron - u(6)) < eps);
        assert(numel(xdot) == get_state_dimension(P8));
        assert(isequal(size(B), [get_state_dimension(P8), 8]));
        assert(lin.finite);
        assert(abs(out.components.appliedControls(5) - u(5)) < eps);
        assert(abs(out.components.appliedControls(6) - u(6)) < eps);
        assert(abs(out.components.appliedControls(7) - u(7)) < eps);
        assert(abs(out.components.appliedControls(8) - u(8)) < eps);
        assert(abs(out.components.rotorLeft.theta1c + u(5)) < eps);
        assert(abs(out.components.rotorRight.theta1c - u(5)) < eps);
    end

    function check_lateral_response()
        P8 = P;
        P8.control.enableLateralCyclic = true;
        u = [8*d2r;0;0;0;0;0;-2*d2r;0];
        [~, B, lin] = linearize_numeric(x, u, betaM, P8);
        lateralColumn = B(:,5);
        stateNames = get_state_names(P8);
        vdotRow = find(strcmp(stateNames, 'v'), 1);
        longitudinalRows = find(ismember(stateNames, {'u'; 'w'; 'q'}));
        [~, maxRow] = max(abs(lateralColumn));
        raw = raw_load_derivative(x, u, betaM, P8, 5);
        assert(lin.finite);
        assert(norm(lateralColumn) > 1e-8, ...
            'lateralCyclic B-column is unexpectedly zero.');
        assert(abs(lateralColumn(vdotRow)) > 1e-4 || abs(raw(2)) > 1e-2, ...
            'lateralCyclic did not produce a significant lateral response.');
        assert(~ismember(maxRow, longitudinalRows), ...
            'lateralCyclic B-column is still dominated by u/w/q leakage.');
    end

    function check_rotDir_disk_response()
        diag = mapping_diagnostics('rotDir');
        assert(same_sign(diag.dBeta1sLeft, diag.dBeta1sRight), ...
            'rotDir mapping did not align left/right beta1s response.');
        assert(same_sign(diag.dNDiskYLeft, diag.dNDiskYRight), ...
            'rotDir mapping did not align left/right nDisk_y response.');
        assert(diag.dNDiskYLeft > 1e-8 && diag.dNDiskYRight > 1e-8, ...
            'positive lateralCyclic does not produce common +eY disk-normal response.');
    end

    function check_current_cancellation()
        rotDirDiag = mapping_diagnostics('rotDir');
        currentDiag = mapping_diagnostics('current');
        assert(opposite_sign(currentDiag.dBeta1sLeft, ...
            currentDiag.dBeta1sRight), ...
            'current mapping no longer shows opposite beta1s response.');
        assert(opposite_sign(currentDiag.dNDiskYLeft, ...
            currentDiag.dNDiskYRight), ...
            'current mapping no longer shows opposite nDisk_y response.');
        assert(rotDirDiag.targetNorm > 1e3*max(currentDiag.targetNorm, eps), ...
            'current mapping target response is not clearly smaller than rotDir.');
    end

    function check_minusRotDir_sign()
        rotDirDiag = mapping_diagnostics('rotDir');
        minusDiag = mapping_diagnostics('minusRotDir');
        assert(same_sign(minusDiag.dNDiskYLeft, minusDiag.dNDiskYRight), ...
            'minusRotDir mapping did not align left/right nDisk_y response.');
        assert(opposite_sign(rotDirDiag.raw_dFy, minusDiag.raw_dFy) || ...
            opposite_sign(rotDirDiag.B_vdot, minusDiag.B_vdot), ...
            'minusRotDir does not reverse the lateral sign versus rotDir.');
    end

    function check_surface_alignment()
        P0 = P;
        P0.control.enableLateralCyclic = false;
        u7 = [8*d2r;0;0;0;3*d2r;-2*d2r;1*d2r];
        c7 = map_control_inputs(u7, P0);
        assert(abs(c7.aileron - u7(5)) < eps);
        assert(abs(c7.elevator - u7(6)) < eps);
        assert(abs(c7.rudder - u7(7)) < eps);

        P8 = P;
        P8.control.enableLateralCyclic = true;
        u8 = [8*d2r;0;0;0;4*d2r;3*d2r;-2*d2r;1*d2r];
        c8 = map_control_inputs(u8, P8);
        assert(abs(c8.lateralCyclic - u8(5)) < eps);
        assert(abs(c8.aileron - u8(6)) < eps);
        assert(abs(c8.elevator - u8(7)) < eps);
        assert(abs(c8.rudder - u8(8)) < eps);
    end

    function value = ternary(condition, a, b)
        if condition
            value = a;
        else
            value = b;
        end
    end

    function raw = raw_load_derivative(xCase, uCase, betaMCase, Pcase, idx)
        h = 1.0e-4;
        up = uCase;
        um = uCase;
        up(idx) = up(idx) + h;
        um(idx) = um(idx) - h;
        [Fp, Mp] = total_forces_moments(xCase, up, betaMCase, Pcase);
        [Fm, Mm] = total_forces_moments(xCase, um, betaMCase, Pcase);
        raw = [(Fp-Fm); (Mp-Mm)]/(2*h);
    end

    function diag = mapping_diagnostics(mappingName)
        Pcase = P;
        Pcase.control.enableLateralCyclic = true;
        Pcase.control.lateralCyclicTheta1cMapping = mappingName;
        uCase = [8*d2r;0;0;0;0;0;-2*d2r;0];
        idx = 5;
        h = 1.0e-4;
        up = uCase;
        um = uCase;
        up(idx) = up(idx) + h;
        um(idx) = um(idx) - h;
        [~, ~, outP] = total_forces_moments(x, up, betaM, Pcase);
        [~, ~, outM] = total_forces_moments(x, um, betaM, Pcase);
        raw = raw_load_derivative(x, uCase, betaM, Pcase, idx);
        [~, B, lin] = linearize_numeric(x, uCase, betaM, Pcase);
        stateNames = get_state_names(Pcase);
        vdotRow = find(strcmp(stateNames, 'v'), 1);
        pdotRow = find(strcmp(stateNames, 'p'), 1);
        rdotRow = find(strcmp(stateNames, 'r'), 1);

        diag.dBeta1sLeft = (outP.rotorLeft.beta1s - ...
            outM.rotorLeft.beta1s)/(2*h);
        diag.dBeta1sRight = (outP.rotorRight.beta1s - ...
            outM.rotorRight.beta1s)/(2*h);
        diag.dNDiskYLeft = (outP.rotorLeft.nDisk(2) - ...
            outM.rotorLeft.nDisk(2))/(2*h);
        diag.dNDiskYRight = (outP.rotorRight.nDisk(2) - ...
            outM.rotorRight.nDisk(2))/(2*h);
        diag.B_vdot = B(vdotRow, idx);
        diag.targetNorm = norm([B([vdotRow pdotRow rdotRow], idx); ...
            raw([2 4 6])]);
        diag.raw_dFy = raw(2);
        assert(lin.finite);
    end

    function tf = same_sign(a, b)
        tol = 1.0e-8;
        tf = abs(a) > tol && abs(b) > tol && sign(a) == sign(b);
    end

    function tf = opposite_sign(a, b)
        tol = 1.0e-8;
        tf = abs(a) > tol && abs(b) > tol && sign(a) == -sign(b);
    end
end
