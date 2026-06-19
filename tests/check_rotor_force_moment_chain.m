function report = check_rotor_force_moment_chain()
%CHECK_ROTOR_FORCE_MOMENT_CHAIN Rotor/load assembly internal audit checks.
% These checks verify code identities and symmetry relations only. They are
% not XV-15 validation and do not encode exact aircraft reference values.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir,'model'));
addpath(fullfile(rootDir,'analysis'));

P = params_nominal();
d2r = pi/180;

report.cases = struct('name',{},'passed',{},'message',{});
report.findings = struct('severity',{},'category',{},'message',{});
report.representativeConditions = struct('name',{},'betaM',{},'minUT',{},'maxUT',{});

cache = struct();
callCount.total_forces_moments = 0;
callCount.rotor_model_bemt = 0;

add_case('rotor basis unit length and orthogonality', @test_basis);
add_case('left/right hub mirror geometry', @test_hub_geometry);
add_case('hub local-velocity identity', @test_hub_velocity);
add_case('exact rotor moment decomposition', @test_rotor_moment_decomposition);
add_case('exact total component force/moment summation', @test_total_summation);
add_case('symmetric-hover force and reaction-torque cancellation', @test_symmetric_hover);
add_case('differential-collective mirror/sign relations', @test_diff_collective);
add_case('common collective monotonic thrust and finite torque', @test_collective_monotonic);
add_case('Jpolar=0 gives zero gyroscopic moment', @test_zero_jpolar);
add_case('synthetic nonzero Jpolar gyroscopic moment', @test_synthetic_jpolar);
add_case('finite real outputs and convergence flags', @test_finite_representatives);
add_case('minimum UT applicability record', @test_min_ut_record);

report.modelCallCount = callCount;
report.allPassed = all([report.cases.passed]);

fprintf('\nRotor force/moment chain checks\n');
fprintf('===============================\n');
fprintf('%-58s : %s\n', 'case', 'status');
for k = 1:numel(report.cases)
    status = ternary(report.cases(k).passed, 'PASS', 'FAIL');
    fprintf('%-58s : %s\n', report.cases(k).name, status);
    if ~report.cases(k).passed
        fprintf('  %s\n', report.cases(k).message);
    end
end
fprintf('Model calls: total_forces_moments=%d, rotor_model_bemt=%d\n', ...
    report.modelCallCount.total_forces_moments, ...
    report.modelCallCount.rotor_model_bemt);
for k = 1:numel(report.representativeConditions)
    c = report.representativeConditions(k);
    fprintf('Representative %-10s betaM=% .6f minUT=% .6e maxUT=% .6e\n', ...
        c.name, c.betaM, c.minUT, c.maxUT);
end
fprintf('All rotor force/moment chain checks passed: %d\n', report.allPassed);

    function result = test_basis()
        betaList = [0, pi/4, pi/2];
        expected = {[0;0;-1], [sqrt(0.5);0;-sqrt(0.5)], [1;0;0]};
        err = 0;
        for i = 1:numel(betaList)
            [eT,eD,eY] = rotor_basis(betaList(i));
            B = [eT,eD,eY];
            err = max(err, max(max(abs(B.'*B - eye(3)))));
            err = max(err, norm(eT - expected{i}));
            err = max(err, abs(norm(eD)-1));
            err = max(err, abs(norm(eY)-1));
        end
        result = make_result(err < 1e-14, ...
            sprintf('Rotor basis error %.3e exceeded tolerance.', err));
    end

    function result = test_hub_geometry()
        betaList = [0, pi/4, pi/2];
        err = 0;
        for i = 1:numel(betaList)
            mp = mass_properties(betaList(i), P);
            rL = hub_position(betaList(i), -1, mp.cgShift);
            rR = hub_position(betaList(i), +1, mp.cgShift);
            err = max(err, norm([rL(1)-rR(1); rL(2)+rR(2); rL(3)-rR(3)]));
        end
        result = make_result(err < 1e-12, ...
            sprintf('Left/right hub mirror error %.3e exceeded tolerance.', err));
    end

    function result = test_hub_velocity()
        c = representative('transition');
        x = c.x;
        L = c.info.rotorLeft;
        R = c.info.rotorRight;
        errL = norm(L.Vhub - (x(1:3) + cross(x(4:6), L.rHub)));
        errR = norm(R.Vhub - (x(1:3) + cross(x(4:6), R.rHub)));
        err = max(errL, errR);
        result = make_result(err < 1e-12, ...
            sprintf('Vhub identity error %.3e exceeded tolerance.', err));
    end

    function result = test_rotor_moment_decomposition()
        c = representative('transition');
        err = max(rotor_decomp_error(c.info.rotorLeft), ...
                  rotor_decomp_error(c.info.rotorRight));
        result = make_result(err < 1e-8, ...
            sprintf('Rotor force or moment decomposition error %.3e.', err));
    end

    function result = test_total_summation()
        c = representative('transition');
        Fsum = zeros(3,1);
        Msum = zeros(3,1);
        for i = 1:numel(c.info.components)
            Fsum = Fsum + c.info.components{i}.F;
            Msum = Msum + c.info.components{i}.M;
        end
        err = max(norm(Fsum - c.F), norm(Msum - c.M));
        result = make_result(err < 1e-10, ...
            sprintf('Component summation error %.3e exceeded tolerance.', err));
    end

    function result = test_symmetric_hover()
        c = representative('hover');
        L = c.info.rotorLeft;
        R = c.info.rotorRight;
        oddLoad = [c.F(2); c.M(1); c.M(3)];
        reactionSum = L.Mreaction + R.Mreaction;
        thrustErr = L.thrust - R.thrust;
        scale = max([norm(c.F), norm(c.M), abs(L.thrust), abs(R.thrust), 1]);
        err = max([norm(oddLoad), norm(reactionSum), abs(thrustErr)]) / scale;
        result = make_result(err < 1e-10, ...
            sprintf('Symmetric hover cancellation relative error %.3e.', err));
    end

    function result = test_diff_collective()
        amp = 2*d2r;
        cp = diff_collective_case(+amp);
        cm = diff_collective_case(-amp);
        Lp = cp.info.rotorLeft;
        Rp = cp.info.rotorRight;
        Lm = cm.info.rotorLeft;
        Rm = cm.info.rotorRight;
        evenErr = norm([cp.F([1 3]); cp.M(2)] - [cm.F([1 3]); cm.M(2)]);
        oddErr = norm([cp.F(2); cp.M([1 3])] + [cm.F(2); cm.M([1 3])]);
        swapErr = norm([Rp.thrust - Lm.thrust; Lp.thrust - Rm.thrust]);
        scale = max([norm([cp.F;cp.M]), norm([cm.F;cm.M]), 1]);
        signOk = cp.M(1) < 0 && cp.M(3) > 0;
        ok = evenErr/scale < 1e-10 && oddErr/scale < 1e-10 && ...
             swapErr/max(abs([Rp.thrust; Lp.thrust; Lm.thrust; Rm.thrust; 1])) < 1e-10 && ...
             signOk;
        result = make_result(ok, ...
            sprintf('diffCollective mirror errors even=%.3e odd=%.3e swap=%.3e signOk=%d.', ...
                evenErr/scale, oddErr/scale, swapErr, signOk));
    end

    function result = test_collective_monotonic()
        names = {'collective12','hover','collective24'};
        thrust = zeros(3,1);
        torqueFinite = true;
        for i = 1:3
            c = representative(names{i});
            thrust(i) = c.info.rotorLeft.thrust + c.info.rotorRight.thrust;
            torqueFinite = torqueFinite && is_real_finite([ ...
                c.info.rotorLeft.torque; c.info.rotorRight.torque]);
        end
        ok = all(diff(thrust) > 0) && torqueFinite;
        result = make_result(ok, ...
            sprintf('Total thrust sequence was [% .6e % .6e % .6e].', thrust));
    end

    function result = test_zero_jpolar()
        c = representative('transition');
        y = [c.info.rotorLeft.Hrot; c.info.rotorLeft.Mgyro; ...
             c.info.rotorRight.Hrot; c.info.rotorRight.Mgyro];
        ok = norm(y) == 0;
        result = make_result(ok, ...
            sprintf('Nominal Jpolar=0 gyro vector norm %.3e was not zero.', norm(y)));
    end

    function result = test_synthetic_jpolar()
        Pj = P;
        Pj.rotor.Jpolar = 25.0;
        x = [18; 1.5; -0.8; 0.11; -0.07; 0.05; 0.03; -0.02; 0];
        u = [16*d2r; 0; 1*d2r; 0; 0; -1*d2r; 0];
        [~,~,info] = call_tfm(x, u, pi/4, Pj);
        errL = norm(info.rotorLeft.Mgyro + cross(x(4:6), info.rotorLeft.Hrot));
        errR = norm(info.rotorRight.Mgyro + cross(x(4:6), info.rotorRight.Hrot));
        result = make_result(max(errL,errR) < 1e-10, ...
            sprintf('Synthetic Jpolar gyro identity error %.3e.', max(errL,errR)));
    end

    function result = test_finite_representatives()
        names = {'hover','transition','airplane'};
        ok = true;
        msg = '';
        for i = 1:numel(names)
            c = representative(names{i});
            y = [c.F; c.M; c.info.rotorLeft.zFlap; c.info.rotorRight.zFlap; ...
                c.info.rotorLeft.inducedVelocity; c.info.rotorRight.inducedVelocity; ...
                c.info.rotorLeft.minUT; c.info.rotorRight.minUT];
            localOk = is_real_finite(y) && ...
                c.info.rotorLeft.coupledConverged && ...
                c.info.rotorRight.coupledConverged && ...
                c.info.rotorLeft.flap.converged && ...
                c.info.rotorRight.flap.converged;
            if ~localOk
                ok = false;
                msg = [msg names{i} ' failed finite/convergence checks. ']; %#ok<AGROW>
            end
        end
        result = make_result(ok, msg);
    end

    function result = test_min_ut_record()
        names = {'hover','transition','airplane'};
        minUT = Inf;
        maxUT = -Inf;
        for i = 1:numel(names)
            c = representative(names{i});
            thisMin = min([c.info.rotorLeft.minUT, c.info.rotorRight.minUT]);
            thisMax = max([c.info.rotorLeft.maxUT, c.info.rotorRight.maxUT]);
            minUT = min(minUT, thisMin);
            maxUT = max(maxUT, thisMax);
            report.representativeConditions(end+1,1).name = names{i};
            report.representativeConditions(end).betaM = c.betaM;
            report.representativeConditions(end).minUT = thisMin;
            report.representativeConditions(end).maxUT = thisMax;
        end
        if minUT <= 0
            add_finding('INFO', 'temporarily allowed engineering simplification', ...
                sprintf('Representative cases reached reverse flow: minUT=%.6e m/s. Current atan2 denominator uses abs(UT), so reverse-flow loads remain outside validated applicability.', minUT));
        elseif minUT < 0.10*P.rotor.Omega*P.rotor.R
            add_finding('INFO', 'temporarily allowed engineering simplification', ...
                sprintf('Representative cases approached low tangential speed: minUT=%.6e m/s. Reverse-flow behavior remains outside this phase.', minUT));
        else
            add_finding('INFO', 'temporarily allowed engineering simplification', ...
                sprintf('Representative cases stayed in positive tangential flow: minUT=%.6e m/s, maxUT=%.6e m/s. Reverse-flow and windmill-brake regimes remain unsupported.', minUT, maxUT));
        end
        result = make_result(isfinite(minUT) && isfinite(maxUT), ...
            'Could not record finite UT bounds for representative cases.');
    end

    function c = representative(name)
        if isfield(cache, name)
            c = cache.(name);
            return;
        end

        switch name
            case 'hover'
                x = zeros(9,1);
                u = [18*d2r; 0; 0; 0; 0; 0; 0];
                betaM = 0;
            case 'transition'
                x = [22; 0.8; -0.5; 0.03; -0.02; 0.015; 0.02; -0.015; 0];
                u = [14*d2r; 0; 1*d2r; 0; 0; -2*d2r; 0];
                betaM = pi/4;
            case 'airplane'
                x = [45; 0.5; 1.0; 0.01; 0.015; -0.01; 0.01; 3*d2r; 0];
                u = [8*d2r; 0; 0; 0; 0; -2*d2r; 0];
                betaM = pi/2;
            case 'collective12'
                x = zeros(9,1);
                u = [12*d2r; 0; 0; 0; 0; 0; 0];
                betaM = 0;
            case 'collective24'
                x = zeros(9,1);
                u = [24*d2r; 0; 0; 0; 0; 0; 0];
                betaM = 0;
            otherwise
                error('Unknown representative case "%s".', name);
        end

        [F,M,info] = call_tfm(x, u, betaM, P);
        c = struct('name',name,'x',x,'u',u,'betaM',betaM, ...
            'F',F,'M',M,'info',info);
        cache.(name) = c;
    end

    function c = diff_collective_case(amp)
        x = zeros(9,1);
        u = [18*d2r; amp; 0; 0; 0; 0; 0];
        [F,M,info] = call_tfm(x, u, 0, P);
        c = struct('x',x,'u',u,'betaM',0,'F',F,'M',M,'info',info);
    end

    function [F,M,info] = call_tfm(x, u, betaM, thisP)
        callCount.total_forces_moments = callCount.total_forces_moments + 1;
        callCount.rotor_model_bemt = callCount.rotor_model_bemt + 2;
        [F,M,info] = total_forces_moments(x, u, betaM, thisP);
    end

    function err = rotor_decomp_error(rotor)
        Freconstructed = rotor.thrust*rotor.nDisk + ...
            rotor.Hlong*rotor.eD + rotor.Hlat*rotor.eY;
        Mreconstructed = rotor.Marm + rotor.Mreaction + rotor.Mgyro;
        err = max(norm(Freconstructed - rotor.F), ...
                  norm(Mreconstructed - rotor.M));
    end

    function rHub = hub_position(betaM, side, cgShift)
        rHub0 = [P.rotor.pivotX + P.mass.RH*sin(betaM);
                 side*P.rotor.pivotY;
                 P.rotor.pivotZ - P.mass.RH*cos(betaM)];
        rHub = rHub0 - cgShift;
    end

    function [eT,eD,eY] = rotor_basis(betaM)
        eT = [sin(betaM); 0; -cos(betaM)];
        eD = [cos(betaM); 0;  sin(betaM)];
        eY = [0; 1; 0];
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

    function add_case(name, fun)
        report.cases(end+1,1).name = name;
        try
            result = fun();
            report.cases(end).passed = result.passed;
            report.cases(end).message = result.message;
        catch ME
            report.cases(end).passed = false;
            report.cases(end).message = ME.message;
        end
    end

    function add_finding(severity, category, message)
        report.findings(end+1,1).severity = severity;
        report.findings(end).category = category;
        report.findings(end).message = message;
    end

    function value = ternary(condition, a, b)
        if condition
            value = a;
        else
            value = b;
        end
    end
end
