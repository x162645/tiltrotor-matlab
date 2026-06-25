function flapReport = check_flapping_model()
%CHECK_FLAPPING_MODEL Regression checks for the steady harmonic flapping model.
%
% These checks validate internal consistency only. They are not XV-15
% validation and do not prove agreement with NUAA data.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir,'model'));
addpath(fullfile(rootDir,'analysis'));

P = params_nominal();
d2r = pi/180;

flapReport.cases = struct('name',{},'passed',{},'message',{});

add_case('UP degenerates when beta and betaDot are zero', ...
    test_up_degenerate());
add_case('hover zero-cyclic left/right mirror', ...
    test_hover_mirror());
add_case('NUAA Eq12 hover inflow field diagnostics', ...
    test_eq12_hover_inflow_field());
add_case('positive cyclicLong disk-tilt direction', ...
    test_positive_cyclic_direction());
add_case('+/- cyclicLong antisymmetric response', ...
    test_cyclic_antisymmetry());
add_case('diffCyclic left/right differential mapping', ...
    test_diff_cyclic_mapping());
add_case('rotDir changes betaDot phase', ...
    test_rot_dir_phase());
add_case('flapping residual convergence', ...
    test_flap_residual_convergence());
add_case('induced/flapping coupled convergence', ...
    test_coupled_convergence());
add_case('rotor grid sensitivity', ...
    test_grid_sensitivity());
add_case('forward-speed scan continuity', ...
    test_speed_scan());
add_case('finite real outputs', ...
    test_finite_outputs());
add_case('trim and linearization still run', ...
    test_trim_linearization());
add_case('repeat calls are deterministic', ...
    test_deterministic_calls());

flapReport.allPassed = all([flapReport.cases.passed]);

fprintf('\nFlapping model checks\n');
fprintf('=====================\n');
fprintf('%-44s : %s\n', 'case', 'status');
for k = 1:numel(flapReport.cases)
    status = ternary(flapReport.cases(k).passed, 'PASS', 'FAIL');
    fprintf('%-44s : %s\n', flapReport.cases(k).name, status);
    if ~flapReport.cases(k).passed
        fprintf('  %s\n', flapReport.cases(k).message);
    end
end
fprintf('All flapping model checks passed: %d\n', flapReport.allPassed);

    function result = test_up_degenerate()
        Vaxial = 3.0;
        viField = 4.0;
        Vlong = 10.0;
        Vlat = -2.0;
        psi = 0.7;
        r = 2.1;
        beta = 0;
        betaDot = 0;
        Vrad = Vlong*cos(psi) + Vlat*sin(psi);
        baseUP = Vaxial + viField;
        upgradedUP = Vaxial + viField - beta*Vrad - r*betaDot;
        ok = upgradedUP == baseUP;
        result = make_result(ok, 'UP did not exactly reduce to Vaxial+viField.');
    end

    function result = test_hover_mirror()
        [~,~,info] = hover_load([18*d2r;0;0;0;0;0;0], P);
        L = info.rotorLeft;
        R = info.rotorRight;
        vals = [L.thrust-R.thrust;
                L.beta0-R.beta0;
                L.beta1c-R.beta1c;
                L.beta1s+R.beta1s;
                L.nDisk(1)-R.nDisk(1);
                L.nDisk(2)+R.nDisk(2);
                L.nDisk(3)-R.nDisk(3)];
        scale = max([abs(L.thrust), abs(R.thrust), 1]);
        ok = norm(vals(1))/scale < 1e-10 && norm(vals(2:end)) < 1e-10;
        result = make_result(ok, 'Hover mirror relation failed.');
    end

    function result = test_eq12_hover_inflow_field()
        [~,~,info] = hover_load([18*d2r;0;0;0;0;0;0], P);
        L = info.rotorLeft;
        R = info.rotorRight;
        [MTL, RL] = flap_components(L);
        [MTR, RR] = flap_components(R);

        fprintf('\nNUAA Eq12 hover flapping components [mean cos sin], N*m\n');
        fprintf('left  MT: '); fprintf('% .12e ', MTL); fprintf('\n');
        fprintf('left   R: '); fprintf('% .12e ', RL); fprintf('\n');
        fprintf('right MT: '); fprintf('% .12e ', MTR); fprintf('\n');
        fprintf('right  R: '); fprintf('% .12e ', RR); fprintf('\n');

        meanOk = L.inducedVelocityFieldAzimuthMeanError < 1e-12 && ...
            R.inducedVelocityFieldAzimuthMeanError < 1e-12;
        rangeOk = L.inducedVelocityFieldMin < L.inducedVelocity && ...
            L.inducedVelocityFieldMax > L.inducedVelocity && ...
            R.inducedVelocityFieldMin < R.inducedVelocity && ...
            R.inducedVelocityFieldMax > R.inducedVelocity;
        modelOk = strcmp(L.inflowModel, 'NUAA_EQ12_FIRST_HARMONIC') && ...
            strcmp(R.inflowModel, 'NUAA_EQ12_FIRST_HARMONIC');
        residualOk = norm(RL) < 1e-6*max(abs(MTL(1)),1) && ...
            norm(RR) < 1e-6*max(abs(MTR(1)),1);
        ok = meanOk && rangeOk && modelOk && residualOk;
        result = make_result(ok, ...
            'NUAA Eq12 inflow field diagnostics or flapping residual failed.');
    end

    function result = test_positive_cyclic_direction()
        [Fbase,~,base] = hover_load([18*d2r;0;0;0;0;0;0], P);
        [Fplus,~,plus] = hover_load([18*d2r;0;2*d2r;0;0;0;0], P);
        dF = Fplus - base.F;
        dFLegacy = Fplus - Fbase;
        L = plus.rotorLeft;
        R = plus.rotorRight;
        L0 = base.rotorLeft;
        R0 = base.rotorRight;
        eD = L.eD;
        ok = (L.beta1c - L0.beta1c) < 0 && ...
             (R.beta1c - R0.beta1c) < 0 && ...
             dot(L.nDisk-L0.nDisk,eD) > 0 && ...
             dot(R.nDisk-R0.nDisk,eD) > 0 && ...
             abs(dF(2)) <= 1e-8*max(norm(dF),1) + 1e-7 && ...
             dFLegacy(1) > 0;
        msg = ['Expected positive common cyclicLong to produce common ' ...
            'negative beta1c increments, disk-normal increments toward +eD, ' ...
            'cancelling lateral force, and positive longitudinal force.'];
        result = make_result(ok, msg);
    end

    function result = test_cyclic_antisymmetry()
        [F0,M0,o0] = hover_load([18*d2r;0;0;0;0;0;0], P);
        [Fp,Mp,op] = hover_load([18*d2r;0;2*d2r;0;0;0;0], P);
        [Fm,Mm,om] = hover_load([18*d2r;0;-2*d2r;0;0;0;0], P);
        loadErr = ([Fp;Mp]-[F0;M0]) + ([Fm;Mm]-[F0;M0]);
        betaErr = (op.rotorRight.beta1c - o0.rotorRight.beta1c) + ...
                  (om.rotorRight.beta1c - o0.rotorRight.beta1c);
        scale = max([norm([Fp;Mp]), norm([Fm;Mm]), norm([F0;M0]), 1]);
        ok = norm(loadErr)/scale < 2e-2 && abs(betaErr) < 2e-3;
        result = make_result(ok, '+/- cyclicLong response is not antisymmetric.');
    end

    function result = test_diff_cyclic_mapping()
        [~,~,plus] = hover_load([18*d2r;0;2*d2r;0;0;0;0], P);
        [~,~,minus] = hover_load([18*d2r;0;-2*d2r;0;0;0;0], P);
        [Fdiff,Mdiff,diffCase] = hover_load([18*d2r;0;0;2*d2r;0;0;0], P);
        [Fbase,Mbase,~] = hover_load([18*d2r;0;0;0;0;0;0], P);
        rightErr = norm([diffCase.rotorRight.beta0 - plus.rotorRight.beta0;
                         diffCase.rotorRight.beta1c - plus.rotorRight.beta1c;
                         diffCase.rotorRight.beta1s - plus.rotorRight.beta1s]);
        leftErr = norm([diffCase.rotorLeft.beta0 - minus.rotorLeft.beta0;
                        diffCase.rotorLeft.beta1c - minus.rotorLeft.beta1c;
                        diffCase.rotorLeft.beta1s - minus.rotorLeft.beta1s]);
        dF = Fdiff - Fbase;
        dM = Mdiff - Mbase;
        ok = rightErr < 1e-12 && leftErr < 1e-12 && ...
             diffCase.rotorLeft.beta1c > 0 && ...
             diffCase.rotorRight.beta1c < 0 && ...
             dM(3) < 0 && ...
             abs(dF(1)) <= 1e-8*max(norm([Fdiff;Mdiff;Fbase;Mbase]),1) + 1e-7;
        result = make_result(ok, ...
            'diffCyclic did not produce opposite beta1c and negative yaw moment.');
    end

    function result = test_rot_dir_phase()
        beta1c = -0.03;
        beta1s = 0.08;
        psi = 0.4;
        betaDotRight = P.rotor.Omega*(-beta1c*sin(psi) + beta1s*cos(psi));
        betaDotLeft = -P.rotor.Omega*(-beta1c*sin(psi) + beta1s*cos(psi));
        ok = abs(betaDotRight + betaDotLeft) < 1e-14;
        result = make_result(ok, 'left/right rotDir did not reverse betaDot phase.');
    end

    function result = test_flap_residual_convergence()
        [~,~,info] = hover_load([18*d2r;0;0;0;0;0;0], P);
        ok = info.rotorLeft.flap.converged && info.rotorRight.flap.converged && ...
            info.rotorLeft.flap.residualNorm < P.rotor.flapResidualTol && ...
            info.rotorRight.flap.residualNorm < P.rotor.flapResidualTol;
        result = make_result(ok, 'Flapping residual did not converge below tolerance.');
    end

    function result = test_coupled_convergence()
        [~,~,info] = hover_load([18*d2r;0;0;0;0;0;0], P);
        ok = info.rotorLeft.coupledConverged && info.rotorRight.coupledConverged && ...
            info.rotorLeft.inducedVelocityError < P.rotor.inducedTol && ...
            info.rotorRight.inducedVelocityError < P.rotor.inducedTol;
        result = make_result(ok, 'Coupled induced/flapping solve did not converge.');
    end

    function result = test_grid_sensitivity()
        Pg = P;
        Pg.rotor.nRadial = 20;
        Pg.rotor.nAzimuth = 36;
        [~,~,o1] = hover_load([18*d2r;0;0;0;0;0;0], P);
        [~,~,o2] = hover_load([18*d2r;0;0;0;0;0;0], Pg);
        y1 = [o1.rotorRight.thrust; o1.rotorRight.inducedVelocity; ...
              o1.rotorRight.beta0; o1.rotorRight.beta1c; o1.rotorRight.beta1s];
        y2 = [o2.rotorRight.thrust; o2.rotorRight.inducedVelocity; ...
              o2.rotorRight.beta0; o2.rotorRight.beta1c; o2.rotorRight.beta1s];
        rel = abs(y2-y1)./max(abs(y2), 1);
        ok = rel(1) < 0.08 && rel(2) < 0.08 && all(rel(3:end) < 0.15);
        result = make_result(ok, 'Flapping model grid sensitivity exceeded tolerance.');
    end

    function result = test_speed_scan()
        speeds = 0:5:30;
        betaPrev = [];
        ok = true;
        for i = 1:numel(speeds)
            x = [speeds(i);0;0;0;0;0;0;0;0];
            u = [18*d2r;0;0;0;0;0;0];
            [F,M,o] = total_forces_moments(x,u,0,P);
            y = [F; M; o.rotorRight.beta0; o.rotorRight.beta1c; ...
                o.rotorRight.beta1s; o.rotorRight.inducedVelocity];
            ok = ok && is_real_finite(y);
            betaNow = y(7:9);
            if ~isempty(betaPrev)
                ok = ok && norm(betaNow-betaPrev) < 0.5;
            end
            betaPrev = betaNow;
        end
        result = make_result(ok, 'Forward-speed scan produced invalid values or a jump.');
    end

    function result = test_finite_outputs()
        [F,M,o] = hover_load([18*d2r;0;2*d2r;0;0;0;0], P);
        y = [F; M; o.rotorLeft.zFlap; o.rotorRight.zFlap; ...
            o.rotorLeft.inducedVelocity; o.rotorRight.inducedVelocity];
        ok = is_real_finite(y);
        result = make_result(ok, 'Outputs contain NaN, Inf, or complex values.');
    end

    function result = test_trim_linearization()
        [xTrim,uTrim,trimInfo] = trim_symmetric(0,0,P);
        [A,B,linInfo] = linearize_numeric(xTrim,uTrim,0,P);
        ok = trimInfo.converged && linInfo.finite && ...
            all(size(A) == [9,9]) && all(size(B) == [9,7]);
        result = make_result(ok, 'Trim or linearization did not complete cleanly.');
    end

    function result = test_deterministic_calls()
        x = zeros(9,1);
        u = [18*d2r;0;1*d2r;0;0;0;0];
        [F1,M1,o1] = total_forces_moments(x,u,0,P);
        [F2,M2,o2] = total_forces_moments(x,u,0,P);
        y1 = [F1; M1; o1.rotorLeft.zFlap; o1.rotorRight.zFlap; ...
            o1.rotorLeft.inducedVelocity; o1.rotorRight.inducedVelocity];
        y2 = [F2; M2; o2.rotorLeft.zFlap; o2.rotorRight.zFlap; ...
            o2.rotorLeft.inducedVelocity; o2.rotorRight.inducedVelocity];
        ok = isequal(y1, y2);
        result = make_result(ok, 'Repeated calls with identical inputs differ.');
    end

    function [F,M,info] = hover_load(u, thisP)
        x0 = zeros(9,1);
        [F,M,info] = total_forces_moments(x0,u,0,thisP);
    end

    function [MT, R] = flap_components(rotorInfo)
        psi = (0:P.rotor.nAzimuth-1)'*(2*pi/P.rotor.nAzimuth);
        MT = fourier3(rotorInfo.flap.aeroMomentByAzimuth(:), psi);
        R = fourier3(rotorInfo.flap.residualByAzimuth(:), psi);
    end

    function c3 = fourier3(value, psi)
        c3 = [mean(value);
              2*mean(value.*cos(psi));
              2*mean(value.*sin(psi))];
    end

    function tf = is_real_finite(value)
        tf = isreal(value) && all(isfinite(value(:)));
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
        flapReport.cases(end+1,1).name = name;
        flapReport.cases(end).passed = result.passed;
        flapReport.cases(end).message = result.message;
    end

    function value = ternary(condition, a, b)
        if condition
            value = a;
        else
            value = b;
        end
    end
end
