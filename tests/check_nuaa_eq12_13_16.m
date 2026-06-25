function report = check_nuaa_eq12_13_16()
%CHECK_NUAA_EQ12_13_16 Focused checks for NUAA Eq. (12), (13), and (16).
%
% These are implementation-structure checks only. They do not establish
% XV-15 quantitative validation.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir,'model'));
addpath(fullfile(rootDir,'analysis'));

P = params_nominal();
d2r = pi/180;

report.cases = struct('name',{},'passed',{},'message',{});

add_case('Eq12 literal radial/azimuth values and azimuth mean', ...
    test_eq12_formula_values());
add_case('Eq12 left/right spatial field consistency', ...
    test_eq12_left_right_field());
add_case('Eq13 algebra and 0.5 induced update', ...
    test_eq13_algebra_and_update());
add_case('Eq13 representative rotor calls finite and converged', ...
    test_eq13_representative_calls());
add_case('Eq16 raw/applied area and clamp flags', ...
    test_eq16_area_grid());
add_case('old wing slipstream schedules absent from production', ...
    test_old_wing_schedules_absent());

report.allPassed = all([report.cases.passed]);

fprintf('\nNUAA Eq. (12)/(13)/(16) focused checks\n');
fprintf('======================================\n');
fprintf('%-56s : %s\n','case','status');
for k = 1:numel(report.cases)
    status = ternary(report.cases(k).passed, 'PASS', 'FAIL');
    fprintf('%-56s : %s\n', report.cases(k).name, status);
    if ~report.cases(k).passed
        fprintf('  %s\n', report.cases(k).message);
    end
end
fprintf('All NUAA equation focused checks passed: %d\n', report.allPassed);

assert(report.allPassed, 'NUAA Eq12/Eq13/Eq16 focused checks failed.');

    function result = test_eq12_formula_values()
        viMean = 7.25;
        r = [0, P.rotor.R, P.rotor.R];
        psi = [0, 0, pi];
        value = viMean .* (1 + cos(psi).*(r/P.rotor.R));
        meanPsi = linspace(0, 2*pi, 4096+1);
        meanPsi(end) = [];
        rSamples = [0, 0.25, 0.5, 1.0]*P.rotor.R;
        field = viMean .* (1 + cos(meanPsi(:)).*(rSamples/P.rotor.R));
        meanErr = max(abs(mean(field,1) - viMean));
        ok = abs(value(1) - viMean) < 1e-14 && ...
             abs(value(2) - 2*viMean) < 1e-14 && ...
             abs(value(3)) < 1e-14 && ...
             meanErr < 1e-13;
        result = make_result(ok, sprintf('values=%s meanErr=%.3e', ...
            mat2str(value, 12), meanErr));
    end

    function result = test_eq12_left_right_field()
        [~,~,info] = total_forces_moments(zeros(9,1), ...
            [18*d2r;0;0;0;0;0;0], 0, P);
        L = info.rotorLeft;
        R = info.rotorRight;
        psi = L.inducedVelocityFieldPsi;
        rMid = L.inducedVelocityFieldRadius;
        expected = 1 + cos(psi).*(rMid/P.rotor.R);
        leftNorm = L.inducedVelocityField / L.inducedVelocity;
        rightNorm = R.inducedVelocityField / R.inducedVelocity;
        ok = strcmp(L.inflowModel, 'NUAA_EQ12_FIRST_HARMONIC') && ...
             strcmp(R.inflowModel, 'NUAA_EQ12_FIRST_HARMONIC') && ...
             max(abs(leftNorm(:) - expected(:))) < 1e-13 && ...
             max(abs(rightNorm(:) - expected(:))) < 1e-13 && ...
             max(abs(leftNorm(:) - rightNorm(:))) < 1e-13 && ...
             L.inducedVelocityFieldAzimuthMeanError < 1e-12 && ...
             R.inducedVelocityFieldAzimuthMeanError < 1e-12;
        result = make_result(ok, sprintf('leftMeanErr=%.3e rightMeanErr=%.3e', ...
            L.inducedVelocityFieldAzimuthMeanError, ...
            R.inducedVelocityFieldAzimuthMeanError));
    end

    function result = test_eq13_algebra_and_update()
        [~,~,info] = total_forces_moments(zeros(9,1), ...
            [18*d2r;0;0;0;0;0;0], 0, P);
        rotor = info.rotorRight;
        tipSpeed = P.rotor.Omega*P.rotor.R;
        A = pi*P.rotor.R^2;
        Vplane = hypot(rotor.Vlong, rotor.Vlat);
        guardedT = rotor.CT*(0.5*P.env.rho*A*tipSpeed^2);
        targetMomentum = guardedT / ...
            (2*P.env.rho*A*sqrt(Vplane^2 + ...
            (rotor.Vaxial + rotor.inducedVelocityUpdateOld)^2));
        targetEq13 = tipSpeed*rotor.CT / ...
            (4*sqrt(rotor.lambda1^2 + rotor.mu^2));
        updateExpected = 0.5*(rotor.inducedVelocityUpdateOld + ...
            rotor.inducedVelocityTargetEq13);
        ok = strcmp(rotor.inducedClosureModel, 'NUAA_EQ13') && ...
             abs(rotor.inducedVelocityTargetEq13 - targetEq13) < 1e-10 && ...
             abs(rotor.inducedVelocityTargetEq13 - targetMomentum) < 1e-10 && ...
             rotor.inducedVelocityUpdateWeight == 0.5 && ...
             abs(rotor.inducedVelocityUpdateNew - updateExpected) < 1e-14 && ...
             abs(rotor.inducedVelocity - rotor.inducedVelocityUpdateNew) < 1e-14;
        result = make_result(ok, sprintf(['target=%.12g momentum=%.12g ' ...
            'updateErr=%.3e'], rotor.inducedVelocityTargetEq13, ...
            targetMomentum, rotor.inducedVelocityUpdateNew-updateExpected));
    end

    function result = test_eq13_representative_calls()
        cases = [0, 18; 20, 14; 60, 8];
        ok = true;
        messages = cell(size(cases,1),1);
        for i = 1:size(cases,1)
            x = [cases(i,1);0;0;0;0;0;0;0;0];
            u = [cases(i,2)*d2r;0;0;0;0;0;0];
            [F,M,o] = total_forces_moments(x, u, 0, P);
            y = [F; M; o.rotorLeft.inducedVelocity; ...
                o.rotorRight.inducedVelocity; o.rotorLeft.CT; ...
                o.rotorRight.CT; o.rotorLeft.lambda0; ...
                o.rotorRight.lambda1];
            caseOk = isreal(y) && all(isfinite(y(:))) && ...
                o.rotorLeft.coupledConverged && ...
                o.rotorRight.coupledConverged;
            ok = ok && caseOk;
            messages{i} = sprintf('V=%.1f ok=%d', cases(i,1), caseOk);
        end
        result = make_result(ok, strjoin(messages, '; '));
    end

    function result = test_eq16_area_grid()
        betasDeg = [0, 15, 30, 45, 60, 75, 90];
        mus = [0, 0.5*P.wing.muMax, P.wing.muMax, 1.2*P.wing.muMax];
        ok = true;
        maxRawErr = 0;
        maxAppliedErr = 0;
        maxComplementErr = 0;
        for iBeta = 1:numel(betasDeg)
            betaM = betasDeg(iBeta)*d2r;
            for iMu = 1:numel(mus)
                mu = mus(iMu);
                rotor = make_rotor(betaM, mu);
                [~,~,out] = wing_model(zeros(9,1), zeros(7,1), betaM, ...
                    zeros(3,1), rotor, rotor, P);
                betaPaper = pi/2 - betaM;
                angleRaw = sin(1.386*(pi/2 - betaPaper)) + ...
                           cos(3.114*(pi/2 - betaPaper));
                muRaw = (P.wing.muMax - mu)/P.wing.muMax;
                raw = P.wing.SslipMaxHalf*angleRaw*muRaw;
                upper = min(P.wing.SslipMaxHalf, P.wing.S/2);
                applied = min(max(raw, 0), upper);
                rawErr = abs(out.SslipRawHalf - raw);
                appliedErr = abs(out.SslipHalf - applied);
                complementErr = abs(out.SfreeHalf + out.SslipHalf - P.wing.S/2);
                flagsOk = out.SslipClampedLow == (raw < 0) && ...
                    out.SslipClampedHigh == (raw > upper);
                caseOk = strcmp(out.slipstreamAreaModel, ...
                    'NUAA_EQ16_WITH_PHYSICAL_AREA_GUARD') && ...
                    rawErr < 1e-13 && appliedErr < 1e-13 && ...
                    complementErr < 1e-13 && flagsOk;
                ok = ok && caseOk;
                maxRawErr = max(maxRawErr, rawErr);
                maxAppliedErr = max(maxAppliedErr, appliedErr);
                maxComplementErr = max(maxComplementErr, complementErr);
            end
        end
        result = make_result(ok, sprintf(['maxRawErr=%.3e ' ...
            'maxAppliedErr=%.3e maxComplementErr=%.3e'], ...
            maxRawErr, maxAppliedErr, maxComplementErr));
    end

    function result = test_old_wing_schedules_absent()
        text = fileread(fullfile(rootDir, 'model', 'wing_model.m'));
        oldVelocity = '1 - 0.25*min';
        oldOrientation = '0.60 + 0.40*abs(cos(2*betaM))';
        ok = isempty(strfind(text, oldVelocity)) && ...
            isempty(strfind(text, oldOrientation));
        result = make_result(ok, ...
            'Old 25% velocity reduction or 60% orientation floor is still present.');
    end

    function rotor = make_rotor(betaM, mu)
        rotor.inducedVelocity = 0;
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
