function report = check_nuaa_eq17_wing_velocity()
%CHECK_NUAA_EQ17_WING_VELOCITY Focused checks for NUAA Eq. (17)-(22).
%
% These checks verify implementation algebra and sign conventions in the
% current body-axis model. They do not constitute aircraft validation.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir,'model'));

P = params_nominal();
d2r = pi/180;
tol = 5.0e-12;

report.cases = struct('name',{},'passed',{},'message',{});
report.details = struct();

add_case('Eq17 beta endpoint and conversion-angle components', ...
    test_eq17_components());
add_case('Eq17 rigid-body velocity and reconstruction identity', ...
    test_rigid_body_reconstruction());
add_case('Eq17 left/right rotor basis equivalence', ...
    test_left_right_basis_equivalence());
add_case('free-stream regions do not add induced velocity', ...
    test_free_stream_is_rigid_body_only());
add_case('wakeFactor no longer affects wing production output', ...
    test_wake_factor_unused());
add_case('invalid Eq17 induced velocity errors explicitly', ...
    test_invalid_induced_velocity_errors());
add_case('Eq18 wing aerodynamic-center shift identity', ...
    test_eq18_rac_shift_identity());
add_case('Eq19 Eq21 zero-sideslip force transform identity', ...
    test_eq19_21_force_transform_identity());
add_case('Eq20 Eq22 wing moment identities and symmetry', ...
    test_eq20_22_moment_and_symmetry());

report.allPassed = all([report.cases.passed]);

fprintf('\nNUAA Eq. (17)-(22) wing velocity checks\n');
fprintf('=======================================\n');
fprintf('%-58s : %s\n','case','status');
for k = 1:numel(report.cases)
    status = ternary(report.cases(k).passed, 'PASS', 'FAIL');
    fprintf('%-58s : %s\n', report.cases(k).name, status);
    if ~report.cases(k).passed
        fprintf('  %s\n', report.cases(k).message);
    end
end
fprintf('All NUAA Eq17 wing checks passed: %d\n', report.allPassed);

assert(report.allPassed, 'NUAA Eq17 focused wing velocity checks failed.');

    function result = test_eq17_components()
        betasDeg = [0, 15, 75, 90];
        vLeft = [6.0, 6.5, 7.0, 7.5];
        vRight = [8.0, 8.5, 9.0, 9.5];
        x = representative_state();
        cgShift = [0.2; -0.1; 0.05];
        maxErr = 0;
        ok = true;
        for iBeta = 1:numel(betasDeg)
            betaM = betasDeg(iBeta)*d2r;
            left = make_rotor(betaM, vLeft(iBeta), 0.08);
            right = make_rotor(betaM, vRight(iBeta), 0.08);
            [~,~,out] = wing_model(x, zeros(7,1), betaM, cgShift, ...
                left, right, P);
            for iRegion = 1:numel(out.regions)
                r = out.regions{iRegion};
                if ~r.inSlipstream
                    continue;
                end
                expected = [r.v1dEq17*sin(betaM); 0; ...
                    -r.v1dEq17*cos(betaM)];
                err = norm(r.VwakeEq17 - expected);
                maxErr = max(maxErr, err);
                ok = ok && err < tol && strcmp(r.localVelocityModel, ...
                    'NUAA_EQ17');
            end
        end
        result = make_result(ok, sprintf('maxComponentErr=%.3e', maxErr));
    end

    function result = test_rigid_body_reconstruction()
        betaM = 15*d2r;
        x = representative_state();
        Vbody = x(1:3);
        omegaBody = x(4:6);
        cgShift = [0.2; -0.1; 0.05];
        rotor = make_rotor(betaM, 7.25, 0.04);
        [~,~,out] = wing_model(x, zeros(7,1), betaM, cgShift, ...
            rotor, rotor, P);
        maxCrossErr = 0;
        maxReconErr = 0;
        ok = out.maxEq17ReconstructionError < tol;
        for iRegion = 1:numel(out.regions)
            r = out.regions{iRegion};
            paperMatrixCross = [ ...
                 0,       r.rAC(3), -r.rAC(2);
                -r.rAC(3), 0,        r.rAC(1);
                 r.rAC(2),-r.rAC(1), 0] * omegaBody;
            crossErr = norm(cross(omegaBody, r.rAC) - paperMatrixCross);
            rigidErr = norm(r.VrigidLocal - (Vbody + paperMatrixCross));
            reconErr = norm(r.Vlocal - (r.VrigidLocal + r.VwakeEq17));
            maxCrossErr = max(maxCrossErr, max(crossErr, rigidErr));
            maxReconErr = max(maxReconErr, reconErr);
            ok = ok && crossErr < tol && rigidErr < tol && ...
                reconErr < tol && r.eq17ReconstructionError < tol;
        end
        result = make_result(ok, sprintf(['maxCrossErr=%.3e ' ...
            'maxReconErr=%.3e outRecon=%.3e'], maxCrossErr, maxReconErr, ...
            out.maxEq17ReconstructionError));
    end

    function result = test_left_right_basis_equivalence()
        betasDeg = [0, 15, 75, 90];
        ok = true;
        maxBasisErr = 0;
        sideValues = [];
        for iBeta = 1:numel(betasDeg)
            betaM = betasDeg(iBeta)*d2r;
            left = make_rotor(betaM, 5 + iBeta, 0.02);
            right = make_rotor(betaM, 9 + iBeta, 0.02);
            [~,~,out] = wing_model(representative_state(), zeros(7,1), ...
                betaM, zeros(3,1), left, right, P);
            maxBasisErr = max(maxBasisErr, out.maxEq17BasisError);
            expectedET = [sin(betaM); 0; -cos(betaM)];
            for iRegion = 1:numel(out.regions)
                r = out.regions{iRegion};
                if ~r.inSlipstream
                    continue;
                end
                if r.side < 0
                    vExpected = left.inducedVelocity;
                else
                    vExpected = right.inducedVelocity;
                end
                sideValues(end+1,1) = r.v1dEq17; %#ok<AGROW>
                ok = ok && abs(r.v1dEq17 - vExpected) < tol && ...
                    norm(r.VwakeEq17 - r.VwakeBasis) < tol && ...
                    norm(r.VwakeBasis - vExpected*expectedET) < tol;
            end
        end
        result = make_result(ok && maxBasisErr < tol, ...
            sprintf('maxBasisErr=%.3e v1dSamples=%s', maxBasisErr, ...
            mat2str(sideValues.', 5)));
    end

    function result = test_free_stream_is_rigid_body_only()
        betaM = 75*d2r;
        x = representative_state();
        rotor = make_rotor(betaM, 10.0, 0.03);
        [~,~,out] = wing_model(x, zeros(7,1), betaM, zeros(3,1), ...
            rotor, rotor, P);
        ok = true;
        maxErr = 0;
        for iRegion = 1:numel(out.regions)
            r = out.regions{iRegion};
            if r.inSlipstream
                continue;
            end
            err = norm(r.VwakeEq17) + norm(r.VwakeBasis) + ...
                abs(r.v1dEq17) + norm(r.Vlocal - r.VrigidLocal);
            maxErr = max(maxErr, err);
            ok = ok && err < tol && strcmp(r.localVelocityModel, ...
                'FREE_STREAM_RIGID_BODY');
        end
        result = make_result(ok, sprintf('maxFreeStreamErr=%.3e', maxErr));
    end

    function result = test_wake_factor_unused()
        betaM = 15*d2r;
        x = representative_state();
        uCtrl = zeros(7,1);
        uCtrl(5) = 0.01;
        cgShift = [0.1; 0.0; -0.04];
        left = make_rotor(betaM, 7.0, 0.05);
        right = make_rotor(betaM, 8.0, 0.05);

        P1 = P;
        P2 = P;
        P1.rotor.wakeFactor = 0.01;
        P2.rotor.wakeFactor = 999.0;
        [F1,M1,out1] = wing_model(x, uCtrl, betaM, cgShift, ...
            left, right, P1);
        [F2,M2,out2] = wing_model(x, uCtrl, betaM, cgShift, ...
            left, right, P2);
        err = norm([F1-F2; M1-M2]);
        for iRegion = 1:numel(out1.regions)
            r1 = out1.regions{iRegion};
            r2 = out2.regions{iRegion};
            err = max(err, norm(r1.Vlocal - r2.Vlocal));
            err = max(err, norm(r1.VwakeEq17 - r2.VwakeEq17));
            err = max(err, norm(r1.F - r2.F));
            err = max(err, norm(r1.M - r2.M));
        end
        ok = err < tol && ~out1.wakeFactorUsed && ~out2.wakeFactorUsed;
        result = make_result(ok, sprintf('wakeFactorPerturbErr=%.3e', err));
    end

    function result = test_invalid_induced_velocity_errors()
        betaM = 0;
        badValues = [-1, Inf, NaN];
        ok = true;
        messages = cell(numel(badValues),1);
        for iValue = 1:numel(badValues)
            rotor = make_rotor(betaM, badValues(iValue), 0);
            try
                wing_model(zeros(9,1), zeros(7,1), betaM, zeros(3,1), ...
                    rotor, rotor, P);
                ok = false;
                messages{iValue} = sprintf('value=%g no error', ...
                    badValues(iValue));
            catch ME
                caseOk = strcmp(ME.identifier, ...
                    'wing_model:InvalidEq17InducedVelocity');
                ok = ok && caseOk;
                messages{iValue} = sprintf('value=%g id=%s', ...
                    badValues(iValue), ME.identifier);
            end
        end
        result = make_result(ok, strjoin(messages, '; '));
    end

    function result = test_eq18_rac_shift_identity()
        betaM = 30*d2r;
        cgShift = [0.35; -0.22; 0.11];
        rotor = make_rotor(betaM, 4.5, 0.04);
        [~,~,out] = wing_model(representative_state(), zeros(7,1), ...
            betaM, cgShift, rotor, rotor, P);
        ok = true;
        maxErr = 0;
        for iRegion = 1:numel(out.regions)
            r = out.regions{iRegion};
            if r.inSlipstream
                y0 = P.wing.ySlipAC;
            else
                y0 = P.wing.yFreeAC;
            end
            r0 = [P.wing.xAC; r.side*y0; P.wing.zAC];
            err = norm(r.rAC - (r0 - cgShift));
            maxErr = max(maxErr, err);
            ok = ok && err < tol;
        end
        result = make_result(ok, sprintf('maxEq18Err=%.3e', maxErr));
    end

    function result = test_eq19_21_force_transform_identity()
        alphas = [-0.31, 0, 0.27];
        D = [12.4, 8.0, 16.2];
        L = [4.0, -3.0, 11.0];
        ok = true;
        maxErr = 0;
        for i = 1:numel(alphas)
            alpha = alphas(i);
            actual = aero_force_body(D(i), 0, L(i), alpha, 0);
            expected = [-D(i)*cos(alpha) + L(i)*sin(alpha);
                         0;
                        -D(i)*sin(alpha) - L(i)*cos(alpha)];
            err = norm(actual - expected);
            maxErr = max(maxErr, err);
            ok = ok && err < tol;
        end
        result = make_result(ok, sprintf('maxForceTransformErr=%.3e', ...
            maxErr));
    end

    function result = test_eq20_22_moment_and_symmetry()
        betaM = 90*d2r;
        rotor = make_rotor(betaM, 5.0, 0.05);
        uCtrl = zeros(7,1);
        [F,M,out] = wing_model([45;0;0;zeros(6,1)], uCtrl, betaM, ...
            zeros(3,1), rotor, rotor, P);
        ok = abs(F(2))/max(norm(F),1) < 1e-11 && ...
            max(abs(M([1 3])))/max(norm(M),1) < 1e-11;
        maxMomentErr = 0;
        for iRegion = 1:numel(out.regions)
            r = out.regions{iRegion};
            if ~isfield(r, 'Maero')
                continue;
            end
            err = norm(r.M - (cross(r.rAC, r.F) + r.Maero));
            err = max(err, norm(r.MNear - ...
                (cross(r.rAC, r.FNear) + r.MaeroNear)));
            err = max(err, norm(r.MLiftLine - ...
                (cross(r.rAC, r.FLiftLine) + r.MaeroLiftLine)));
            maxMomentErr = max(maxMomentErr, err);
            ok = ok && err < 1e-10;
        end
        result = make_result(ok, sprintf(['maxMomentErr=%.3e ' ...
            'Fy=%.3e Mx=%.3e Mz=%.3e'], maxMomentErr, F(2), M(1), M(3)));
    end

    function x = representative_state()
        x = [18; -1.5; 2.4; 0.13; -0.07; 0.05; 0; 0; 0];
    end

    function rotor = make_rotor(betaM, inducedVelocity, mu)
        rotor.inducedVelocity = inducedVelocity;
        rotor.eT = [sin(betaM); 0; -cos(betaM)];
        rotor.muLong = mu;
        rotor.muLat = 0;
    end

    function result = make_result(ok, msg)
        result.passed = logical(ok);
        if ok
            result.message = '';
        else
            result.message = msg;
        end
    end

    function add_case(name, result)
        report.cases(end+1,1).name = name;
        report.cases(end).passed = result.passed;
        report.cases(end).message = result.message;
    end

    function value = ternary(condition, a, b)
        if condition
            value = a;
        else
            value = b;
        end
    end
end
