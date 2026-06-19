function report = check_aerodynamic_components()
%CHECK_AERODYNAMIC_COMPONENTS Lightweight audit of non-rotor aerodynamics.
% This is an internal consistency check for the current conceptual model.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir,'model'));
addpath(fullfile(rootDir,'tests'));

P = params_nominal();
d2r = pi/180;

tol = 2.0e-9;
callCount = struct('aero_force_body',0,'wing_model',0, ...
    'fuselage_model',0,'horizontal_tail_model',0, ...
    'vertical_tail_model',0,'total_forces_moments',0);

report.cases = struct('name',{},'passed',{},'message',{});
report.details = struct();

zeroRotorHeli = make_rotor(0, [0;0;-1], 0);
zeroRotorAirplane = make_rotor(0, [1;0;0], 0);
wakeRotorHeli = make_rotor(10.0, [0;0;-1], 0);
u0 = zeros(7,1);
cg0 = zeros(3,1);

xTransition = [35;0;3;0;0;0;0;0;0];
xAirplane = [45;0;0;0;0;0;0;0;0];
xHoverLike = zeros(9,1);

transition = evaluate_component_set(xTransition, u0, pi/2, cg0, ...
    zeroRotorAirplane);
airplane = evaluate_component_set(xAirplane, u0, pi/2, cg0, ...
    zeroRotorAirplane);

add_case('aero force basis and canonical directions', ...
    check_aero_force_transform());
add_case('positive drag opposes local velocity', ...
    check_drag_opposes_velocity(transition, airplane));
add_case('wing area partition and left/right symmetry', ...
    check_wing_partition_symmetry(transition.wing));

uAilP = u0;
uAilM = u0;
uAilP(5) = 1.0e-4;
uAilM(5) = -1.0e-4;
wingAilP = call_wing(xTransition, uAilP, pi/2, cg0, ...
    zeroRotorAirplane, zeroRotorAirplane);
wingAilM = call_wing(xTransition, uAilM, pi/2, cg0, ...
    zeroRotorAirplane, zeroRotorAirplane);
add_case('aileron sign-reversal mirror and roll sign', ...
    check_aileron_response(transition.wing, wingAilP, wingAilM));

blend = evaluate_wing_blend_local();
add_case('near-normal blend continuity and diagnostics', ...
    check_blend_response(blend));

wingWake = call_wing(xHoverLike, u0, 0, cg0, wakeRotorHeli, wakeRotorHeli);
wingNoWake = call_wing(xHoverLike, u0, 0, cg0, zeroRotorHeli, zeroRotorHeli);
add_case('slipstream scope and hover force direction', ...
    check_slipstream_response(wingWake, wingNoWake));

xP = xTransition; xP(4) = 0.10;
xQ = xTransition; xQ(5) = 0.10;
xR = xTransition; xR(6) = 0.10;
fusP = call_fuselage(xP, cg0);
fusQ = call_fuselage(xQ, cg0);
fusR = call_fuselage(xR, cg0);
add_case('fuselage decomposition, drag, and p/q/r damping', ...
    check_fuselage_response(transition.fuselage, fusP, fusQ, fusR));

htElevP = call_htail(xTransition, 3*d2r, cg0);
htElevM = call_htail(xTransition, -3*d2r, cg0);
add_case('horizontal-tail downwash and elevator response', ...
    check_htail_response(transition.htail, htElevP, htElevM));

xBeta = xTransition; xBeta(2) = 3.0;
vtBeta = call_vtail(xBeta, 0, cg0);
vtRudP = call_vtail(xTransition, 3*d2r, cg0);
vtRudM = call_vtail(xTransition, -3*d2r, cg0);
add_case('twin vertical-tail sideslip and rudder response', ...
    check_vtail_response(transition.vtail, vtBeta, vtRudP, vtRudM));

add_case('finite real deterministic representative conditions', ...
    check_finite_representative(transition, airplane, wingWake));

report.callCount = callCount;
report.totalTopLevelCalls = sum(struct2array(callCount));
report.allPassed = all([report.cases.passed]);

fprintf('\nAerodynamic component checks\n');
fprintf('============================\n');
fprintf('%-50s : %s\n','case','status');
for k = 1:numel(report.cases)
    status = ternary(report.cases(k).passed, 'PASS', 'FAIL');
    fprintf('%-50s : %s\n', report.cases(k).name, status);
    if ~report.cases(k).passed
        fprintf('  %s\n', report.cases(k).message);
    end
end
fprintf('Top-level component/model calls: %d\n', report.totalTopLevelCalls);
fprintf(['Calls: aero=%d wing=%d fuselage=%d htail=%d vtail=%d ' ...
    'totalModel=%d\n'], callCount.aero_force_body, callCount.wing_model, ...
    callCount.fuselage_model, callCount.horizontal_tail_model, ...
    callCount.vertical_tail_model, callCount.total_forces_moments);
fprintf('All aerodynamic component checks passed: %d\n', report.allPassed);

assert(report.allPassed, ...
    'Aerodynamic component audit has failed items.');

    function result = check_aero_force_transform()
        alpha = 0.23;
        beta = -0.18;
        [xW,yW,zW] = wind_basis(alpha, beta);
        B = [xW,yW,zW];
        orthErr = max(max(abs(B.'*B - eye(3))));
        handedErr = norm(cross(xW,yW) - zW);

        Fdrag0 = call_aero(10,0,0,0,0);
        Fside0 = call_aero(0,5,0,0,0);
        Flift0 = call_aero(0,0,7,0,0);
        Fdrag = call_aero(10,0,0,alpha,beta);
        Fsmall1 = call_aero(1,2,3,1e-7,-2e-7);
        Fsmall2 = call_aero(1,2,3,1e-7,-2e-7);

        ok = orthErr < 5e-15 && handedErr < 5e-15 && ...
            norm(Fdrag0 - [-10;0;0]) < tol && ...
            norm(Fside0 - [0;5;0]) < tol && ...
            norm(Flift0 - [0;0;-7]) < tol && ...
            dot(Fdrag, xW) < 0 && abs(dot(Fdrag, yW)) < tol && ...
            abs(dot(Fdrag, zW)) < tol && ...
            is_real_finite(Fsmall1) && norm(Fsmall1 - Fsmall2) == 0;
        msg = sprintf('orthErr=%.3e handedErr=%.3e', orthErr, handedErr);

        report.details.aeroBasis.orthogonalityError = orthErr;
        report.details.aeroBasis.handednessError = handedErr;
        result = make_result(ok, msg);
    end

    function result = check_drag_opposes_velocity(varargin)
        ok = true;
        samples = {};
        for iArg = 1:nargin
            samples{end+1} = varargin{iArg}.wing;
            samples{end+1} = varargin{iArg}.fuselage;
            samples{end+1} = varargin{iArg}.htail;
            samples{end+1} = varargin{iArg}.vtail;
        end
        for iSample = 1:numel(samples)
            ok = ok && component_drag_ok(samples{iSample});
        end
        result = make_result(ok, ...
            'Expected every nonzero component force to oppose its local velocity in power dot-product.');
    end

    function result = check_wing_partition_symmetry(wing)
        halfIdentity = abs(wing.out.SfreeHalf + wing.out.SslipHalf - ...
            P.wing.S/2);
        areaOk = wing.out.SfreeHalf >= -tol && wing.out.SslipHalf >= -tol && ...
            wing.out.SfreeHalf <= P.wing.S/2 + tol && ...
            wing.out.SslipHalf <= P.wing.S/2 + tol && halfIdentity < tol;
        symmetryOk = near_zero(wing.F(2), wing.F) && ...
            near_zero(wing.M([1 3]), wing.M);
        result = make_result(areaOk && symmetryOk, ...
            sprintf('areaIdentity=%.3e Fy=%.3e Mx=%.3e Mz=%.3e', ...
            halfIdentity, wing.F(2), wing.M(1), wing.M(3)));
    end

    function result = check_aileron_response(base, plus, minus)
        baseLoad = [base.F; base.M];
        plusLoad = [plus.F; plus.M];
        minusLoad = [minus.F; minus.M];
        mirrorErr = norm((plusLoad - baseLoad) + (minusLoad - baseLoad));
        scale = max([norm(baseLoad), norm(plusLoad), norm(minusLoad), 1]);
        ok = mirrorErr <= 1e-6*scale && ...
            plus.M(1) > base.M(1) && minus.M(1) < base.M(1);
        result = make_result(ok, ...
            sprintf('mirrorErr=%.3e dMxPlus=%.3e dMxMinus=%.3e', ...
            mirrorErr, plus.M(1)-base.M(1), minus.M(1)-base.M(1)));
    end

    function result = check_blend_response(blend)
        weights = [blend.left.weight, blend.center.weight, blend.right.weight];
        loadLeft = [blend.left.F; blend.left.M];
        loadCenter = [blend.center.F; blend.center.M];
        loadRight = [blend.right.F; blend.right.M];
        stepScale = max([norm(loadLeft), norm(loadCenter), norm(loadRight), 1]);
        maxRelStep = max(norm(loadCenter-loadLeft), ...
            norm(loadRight-loadCenter))/stepScale;
        diagOk = blend.left.diagOk && blend.center.diagOk && ...
            blend.right.diagOk;
        ok = all(isfinite(weights)) && all(diff(weights) > 0) && ...
            maxRelStep < 0.10 && diagOk;
        report.details.wingBlend.weights = weights;
        report.details.wingBlend.maxRelativeStep = maxRelStep;
        result = make_result(ok, ...
            sprintf('weights=[%.6f %.6f %.6f] maxRelStep=%.3e diagOk=%d', ...
            weights(1), weights(2), weights(3), maxRelStep, diagOk));
    end

    function result = check_slipstream_response(wake, noWake)
        freeWakeOk = true;
        slipWakeOk = true;
        slipForceOk = true;
        for iRegion = 1:numel(wake.out.regions)
            r = wake.out.regions{iRegion};
            if ~isfield(r, 'inSlipstream')
                continue;
            end
            if r.inSlipstream
                slipWakeOk = slipWakeOk && r.wakeVelocity > 0 && ...
                    abs(norm(r.Vlocal) - r.wakeVelocity) < 1e-10 && ...
                    r.Vlocal(3) < 0;
                slipForceOk = slipForceOk && dot(r.F, r.Vlocal) < 0 && r.F(3) > 0;
            else
                freeWakeOk = freeWakeOk && r.wakeVelocity == 0 && ...
                    norm(r.F) == 0 && norm(r.M) == 0;
            end
        end
        ok = freeWakeOk && slipWakeOk && slipForceOk && ...
            norm(noWake.F) == 0 && norm(noWake.M) == 0;
        report.details.slipstream.hoverForce = wake.F;
        result = make_result(ok, ...
            sprintf('Fwake=[%.3e %.3e %.3e], noWakeNorm=%.3e', ...
            wake.F(1), wake.F(2), wake.F(3), norm([noWake.F; noWake.M])));
    end

    function result = check_fuselage_response(base, pPlus, qPlus, rPlus)
        decompErr = norm(base.M - (base.out.Marm + base.out.Maero));
        dragOk = base.out.CD >= 0;
        dampingOk = (pPlus.out.Maero(1) - base.out.Maero(1)) < 0 && ...
            (qPlus.out.Maero(2) - base.out.Maero(2)) < 0 && ...
            (rPlus.out.Maero(3) - base.out.Maero(3)) < 0;
        ok = decompErr < 1e-10 && dragOk && dampingOk;
        result = make_result(ok, ...
            sprintf('decompErr=%.3e CD=%.3e dM=[%.3e %.3e %.3e]', ...
            decompErr, base.out.CD, ...
            pPlus.out.Maero(1)-base.out.Maero(1), ...
            qPlus.out.Maero(2)-base.out.Maero(2), ...
            rPlus.out.Maero(3)-base.out.Maero(3)));
    end

    function result = check_htail_response(base, elevP, elevM)
        decompErr = norm(base.M - (base.out.Marm + base.out.Maero));
        downwashOk = base.out.alphaCG > 0 && ...
            abs(base.out.alphaEff - ...
            (base.out.alphaLocal - P.htail.downwashAlpha*base.out.alphaCG + ...
             P.htail.incidence)) < 1e-14 && ...
            base.out.alphaEff < base.out.alphaLocal;
        elevatorOk = elevP.out.CL > elevM.out.CL && ...
            elevP.F(3) < elevM.F(3) && elevP.M(2) < elevM.M(2);
        ok = decompErr < 1e-10 && downwashOk && elevatorOk;
        result = make_result(ok, ...
            sprintf('decompErr=%.3e alphaLocal=%.3e alphaEff=%.3e dCL=%.3e dMy=%.3e', ...
            decompErr, base.out.alphaLocal, base.out.alphaEff, ...
            elevP.out.CL-elevM.out.CL, elevP.M(2)-elevM.M(2)));
    end

    function result = check_vtail_response(base, betaPos, rudP, rudM)
        baseLoad = [base.F; base.M];
        rudPlusLoad = [rudP.F; rudP.M];
        rudMinusLoad = [rudM.F; rudM.M];
        oddIdx = [2 4 6];
        mirrorErr = norm((rudPlusLoad(oddIdx) - baseLoad(oddIdx)) + ...
            (rudMinusLoad(oddIdx) - baseLoad(oddIdx)));
        scale = max([norm(baseLoad(oddIdx)), norm(rudPlusLoad(oddIdx)), ...
            norm(rudMinusLoad(oddIdx)), 1]);
        betaOk = betaPos.F(2) < base.F(2) && betaPos.M(3) > base.M(3);
        rudderOk = mirrorErr <= 1e-8*scale && ...
            rudP.F(2) > base.F(2) && rudP.M(3) < base.M(3);
        symmetryOk = near_zero(base.F(2), base.F) && ...
            near_zero(base.M([1 3]), base.M);
        ok = betaOk && rudderOk && symmetryOk;
        result = make_result(ok, ...
            sprintf('betaFy=%.3e betaMz=%.3e rudMirrorErr=%.3e', ...
            betaPos.F(2)-base.F(2), betaPos.M(3)-base.M(3), mirrorErr));
    end

    function result = check_finite_representative(transitionData, airplaneData, hoverWing)
        values = [pack_set(transitionData); pack_set(airplaneData); ...
            hoverWing.F; hoverWing.M];
        ok = is_real_finite(values);
        result = make_result(ok, ...
            'Expected hover-like, transition, and airplane-mode representative outputs to be finite real values.');
    end

    function tf = component_drag_ok(sample)
        tf = true;
        if isfield(sample.out, 'regions')
            for i = 1:numel(sample.out.regions)
                r = sample.out.regions{i};
                if isfield(r, 'Vlocal') && norm(r.Vlocal) > 0 && norm(r.F) > 0
                    tf = tf && dot(r.F, r.Vlocal) <= 1e-10;
                end
            end
        elseif isfield(sample.out, 'fins')
            for i = 1:numel(sample.out.fins)
                r = sample.out.fins{i};
                if isfield(r, 'Vlocal') && norm(r.Vlocal) > 0 && norm(r.F) > 0
                    tf = tf && dot(r.F, r.Vlocal) <= 1e-10;
                end
            end
        elseif isfield(sample.out, 'Vlocal') && norm(sample.out.Vlocal) > 0
            tf = tf && dot(sample.F, sample.out.Vlocal) <= 1e-10;
        end
    end

    function blend = evaluate_wing_blend_local()
        center = P.wing.normalFlowRatio;
        h = 1.0e-3;
        blend.left = wing_at_ratio(center - h);
        blend.center = wing_at_ratio(center);
        blend.right = wing_at_ratio(center + h);
    end

    function item = wing_at_ratio(ratio)
        Vmag = 24;
        vx = ratio*Vmag;
        vz = -sqrt(max(1 - ratio^2, 0))*Vmag;
        x = [vx;0;vz;zeros(6,1)];
        data = call_wing(x, u0, 0, cg0, zeroRotorHeli, zeroRotorHeli);
        weights = zeros(numel(data.out.regions),1);
        diagOk = true;
        for i = 1:numel(data.out.regions)
            r = data.out.regions{i};
            weights(i) = r.normalFlowBranchWeight;
            diagOk = diagOk && norm(r.M - (r.Marm + r.Maero)) < 1e-10;
        end
        item.F = data.F;
        item.M = data.M;
        item.weight = mean(weights);
        item.diagOk = diagOk;
    end

    function set = evaluate_component_set(x, uCtrl, betaM, cgShift, rotor)
        set.wing = call_wing(x, uCtrl, betaM, cgShift, rotor, rotor);
        set.fuselage = call_fuselage(x, cgShift);
        set.htail = call_htail(x, uCtrl(6), cgShift);
        set.vtail = call_vtail(x, uCtrl(7), cgShift);
    end

    function data = call_wing(x, uCtrl, betaM, cgShift, rotorLeft, rotorRight)
        callCount.wing_model = callCount.wing_model + 1;
        [F,M,out] = wing_model(x, uCtrl, betaM, cgShift, ...
            rotorLeft, rotorRight, P);
        data.F = F;
        data.M = M;
        data.out = out;
    end

    function data = call_fuselage(x, cgShift)
        callCount.fuselage_model = callCount.fuselage_model + 1;
        [F,M,out] = fuselage_model(x, cgShift, P);
        data.F = F;
        data.M = M;
        data.out = out;
    end

    function data = call_htail(x, elevator, cgShift)
        callCount.horizontal_tail_model = ...
            callCount.horizontal_tail_model + 1;
        [F,M,out] = horizontal_tail_model(x, elevator, cgShift, P);
        data.F = F;
        data.M = M;
        data.out = out;
    end

    function data = call_vtail(x, rudder, cgShift)
        callCount.vertical_tail_model = callCount.vertical_tail_model + 1;
        [F,M,out] = vertical_tail_model(x, rudder, cgShift, P);
        data.F = F;
        data.M = M;
        data.out = out;
    end

    function F = call_aero(D, Y, L, alpha, beta)
        callCount.aero_force_body = callCount.aero_force_body + 1;
        F = aero_force_body(D, Y, L, alpha, beta);
    end

    function rotor = make_rotor(inducedVelocity, eT, mu)
        rotor.inducedVelocity = inducedVelocity;
        rotor.eT = eT(:)/norm(eT);
        rotor.muLong = mu;
        rotor.muLat = 0;
    end

    function [xW,yW,zW] = wind_basis(alpha, beta)
        xW = [cos(alpha)*cos(beta);
              sin(beta);
              sin(alpha)*cos(beta)];
        yW = [-cos(alpha)*sin(beta);
               cos(beta);
              -sin(alpha)*sin(beta)];
        zW = [-sin(alpha);
               0;
               cos(alpha)];
    end

    function y = pack_set(set)
        y = [set.wing.F; set.wing.M; set.fuselage.F; set.fuselage.M; ...
            set.htail.F; set.htail.M; set.vtail.F; set.vtail.M];
    end

    function tf = near_zero(value, scaleValue)
        scale = max(norm(scaleValue),1);
        tf = all(abs(value(:)) <= 1e-9*scale + 1e-6);
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
