function [Fbody, Mbody, out] = wing_model(x, uCtrl, betaM, cgShift, rotorLeft, rotorRight, P)
%WING_MODEL Wing free-stream and rotor-slipstream aerodynamic model.
% The near-normal and lift-line conceptual branches are both evaluated at
% the same local flow state, then blended over a finite normal-flow band.

Vbody = x(1:3);
omegaBody = x(4:6);
aileron = uCtrl(5);

S_half = P.wing.S/2;

muMean = 0.5*(hypot(rotorLeft.muLong, rotorLeft.muLat) + ...
              hypot(rotorRight.muLong, rotorRight.muLat));

if ~(isfinite(P.wing.muMax) && P.wing.muMax > 0)
    error('P.wing.muMax must be positive and finite.');
end

% NUAA Eq. (16) uses betaM=0 in helicopter mode and betaM=pi/2 in
% airplane mode, matching the current code variable. Figure-level nacelle
% angle annotations may use a different visual reference and are not used
% as the formula argument here.
slipstreamAngleArgument = pi/2 - betaM;
angleRaw = sin(1.386*slipstreamAngleArgument) + ...
           cos(3.114*slipstreamAngleArgument);
muRaw = (P.wing.muMax - muMean)/P.wing.muMax;
SslipRawHalf = P.wing.SslipMaxHalf*angleRaw*muRaw;

% Code-only physical-area guard: this bound is not part of NUAA Eq. (16).
SslipUpperHalf = min(P.wing.SslipMaxHalf, S_half);
S_slip = min(max(SslipRawHalf, 0), SslipUpperHalf);
S_free = S_half - S_slip;

Fbody = zeros(3,1);
Mbody = zeros(3,1);
regionOut = cell(4,1);
idx = 0;

for side = [-1, 1]
    if side < 0
        rotor = rotorLeft;
    else
        rotor = rotorRight;
    end

    rFree0 = [P.wing.xAC;
              side*P.wing.yFreeAC;
              P.wing.zAC];
    rFree = rFree0 - cgShift;

    idx = idx + 1;
    [F, M, data] = one_region(rFree, S_free, side, false, rotor);
    Fbody = Fbody + F;
    Mbody = Mbody + M;
    regionOut{idx} = data;

    rSlip0 = [P.wing.xAC;
              side*P.wing.ySlipAC;
              P.wing.zAC];
    rSlip = rSlip0 - cgShift;

    idx = idx + 1;
    [F, M, data] = one_region(rSlip, S_slip, side, true, rotor);
    Fbody = Fbody + F;
    Mbody = Mbody + M;
    regionOut{idx} = data;
end

out.SslipHalf = S_slip;
out.SfreeHalf = S_free;
out.slipstreamAreaModel = 'NUAA_EQ16_WITH_PHYSICAL_AREA_GUARD';
out.betaMCode = betaM;
out.slipstreamAngleArgument = slipstreamAngleArgument;
out.angleRaw = angleRaw;
out.muMean = muMean;
out.muRaw = muRaw;
out.SslipRawHalf = SslipRawHalf;
out.SslipUpperHalf = SslipUpperHalf;
out.SslipClampedLow = SslipRawHalf < 0;
out.SslipClampedHigh = SslipRawHalf > SslipUpperHalf;
out.regions = regionOut;
out.maxEq17BasisError = max_region_field(regionOut, 'eq17BasisError');
out.maxEq17ReconstructionError = max_region_field( ...
    regionOut, 'eq17ReconstructionError');
out.wakeFactorUsed = false;
out.F = Fbody;
out.M = Mbody;

    function [Freg, Mreg, data] = one_region(rAC, Sreg, side, inSlipstream, rotor)
        VrigidLocal = Vbody + cross(omegaBody, rAC);

        if inSlipstream
            v1d = rotor.inducedVelocity;
            if ~(isfinite(v1d) && v1d >= 0)
                error('wing_model:InvalidEq17InducedVelocity', ...
                    'NUAA Eq.17 requires finite nonnegative v1d.');
            end
            % NUAA Eq. (17), in current body axes x forward, y right, z down.
            % This is exactly v1d*rotor.eT because eT=[sin(betaM);0;-cos(betaM)].
            VwakeEq17 = [v1d*sin(betaM); 0; -v1d*cos(betaM)];
            VwakeBasis = v1d*rotor.eT;
            eq17BasisError = norm(VwakeEq17 - VwakeBasis);
            localVelocityModel = 'NUAA_EQ17';
            Vlocal = VrigidLocal + VwakeEq17;
        else
            v1d = 0;
            VwakeEq17 = zeros(3,1);
            VwakeBasis = zeros(3,1);
            eq17BasisError = 0;
            localVelocityModel = 'FREE_STREAM_RIGID_BODY';
            Vlocal = VrigidLocal;
        end

        eq17ReconstructionError = norm(Vlocal - ...
            (Vbody + cross(omegaBody, rAC) + VwakeEq17));

        if Sreg <= 0
            Freg = zeros(3,1);
            Mreg = zeros(3,1);
            data = base_region_data(Sreg, side, inSlipstream, rAC, ...
                VrigidLocal, v1d, VwakeEq17, VwakeBasis, ...
                eq17BasisError, eq17ReconstructionError, ...
                localVelocityModel, Vlocal);
            data.wakeVelocity = v1d;
            data.V = norm(Vlocal);
            data.F = Freg;
            data.M = Mreg;
            return;
        end

        V = norm(Vlocal);
        if V < 1e-8
            Freg = zeros(3,1);
            Mreg = zeros(3,1);
            data = base_region_data(Sreg, side, inSlipstream, rAC, ...
                VrigidLocal, v1d, VwakeEq17, VwakeBasis, ...
                eq17BasisError, eq17ReconstructionError, ...
                localVelocityModel, Vlocal);
            data.wakeVelocity = v1d;
            data.V = V;
            data.F = Freg;
            data.M = Mreg;
            return;
        end

        velocityFloor = 1e-8;
        alpha = atan2(Vlocal(3), Vlocal(1));
        beta = asin(min(max(Vlocal(2)/V, -1), 1));
        qbar = 0.5*P.env.rho*V^2;

        dCLail = -side*P.wing.CLaileron*aileron;

        center = P.wing.normalFlowRatio;
        if ~isfield(P.wing, 'normalFlowBlendHalfWidth')
            error('P.wing.normalFlowBlendHalfWidth is required.');
        end
        halfWidth = P.wing.normalFlowBlendHalfWidth;
        if ~(isfinite(halfWidth) && halfWidth > 0)
            error('P.wing.normalFlowBlendHalfWidth must be positive and finite.');
        end

        ratio = abs(Vlocal(1))/max(V, velocityFloor);
        lower = center - halfWidth;
        upper = center + halfWidth;
        xi = (ratio - lower)/(2*halfWidth);
        xi = min(max(xi, 0), 1);
        branchWeight = smootherstep(xi);
        nearNormal = ratio < center;
        inTransition = ratio > lower && ratio < upper;

        CDn = P.wing.CDnormal;
        FNear = -qbar*Sreg*CDn*(Vlocal/max(V, velocityFloor));
        MaeroNear = zeros(3,1);

        CLrawLift = P.wing.CL0 + P.wing.CLalpha*alpha + dCLail;
        CLLift = P.wing.CLmax*tanh(CLrawLift/P.wing.CLmax);
        CDLift = P.wing.CD0 + P.wing.kInduced*CLLift^2;
        CYLift = P.wing.CYbeta*beta;
        CmLift = P.wing.Cm0 + P.wing.Cmalpha*alpha ...
               + P.wing.Cmaileron*(-side*aileron);

        LLift = qbar*Sreg*CLLift;
        DLift = qbar*Sreg*CDLift;
        YLift = qbar*Sreg*CYLift;

        FLiftLine = aero_force_body(DLift, YLift, LLift, alpha, beta);
        MaeroLiftLine = [0; qbar*Sreg*P.wing.c*CmLift; 0];

        Freg = (1 - branchWeight)*FNear + branchWeight*FLiftLine;
        Maero = (1 - branchWeight)*MaeroNear + ...
            branchWeight*MaeroLiftLine;

        CL = branchWeight*CLLift;
        CD = (1 - branchWeight)*CDn + branchWeight*CDLift;
        Cm = branchWeight*CmLift;

        Marm = cross(rAC, Freg);
        Mreg = Marm + Maero;
        MNear = cross(rAC, FNear) + MaeroNear;
        MLiftLine = cross(rAC, FLiftLine) + MaeroLiftLine;

        data.area = Sreg;
        data.side = side;
        data.inSlipstream = inSlipstream;
        data.wakeVelocity = v1d;
        data.rAC = rAC;
        data.VrigidLocal = VrigidLocal;
        data.v1dEq17 = v1d;
        data.VwakeEq17 = VwakeEq17;
        data.VwakeBasis = VwakeBasis;
        data.eq17BasisError = eq17BasisError;
        data.eq17ReconstructionError = eq17ReconstructionError;
        data.localVelocityModel = localVelocityModel;
        data.Vlocal = Vlocal;
        data.V = V;
        data.alpha = alpha;
        data.beta = beta;
        data.qbar = qbar;
        data.CL = CL;
        data.CD = CD;
        data.Cm = Cm;
        data.normalFlowRatioActual = ratio;
        data.normalFlowTransitionCenter = center;
        data.normalFlowBlendHalfWidth = halfWidth;
        data.normalFlowMargin = ratio - center;
        data.normalFlowBranchWeight = branchWeight;
        data.inNormalFlowTransition = inTransition;
        data.nearNormal = nearNormal;
        data.FNear = FNear;
        data.FLiftLine = FLiftLine;
        data.MaeroNear = MaeroNear;
        data.MaeroLiftLine = MaeroLiftLine;
        data.Maero = Maero;
        data.Marm = Marm;
        data.MNear = MNear;
        data.MLiftLine = MLiftLine;
        data.CLLiftLine = CLLift;
        data.CDLiftLine = CDLift;
        data.CmLiftLine = CmLift;
        data.F = Freg;
        data.M = Mreg;
    end

    function data = base_region_data(area, side, inSlipstream, rAC, ...
            VrigidLocal, v1d, VwakeEq17, VwakeBasis, eq17BasisError, ...
            eq17ReconstructionError, localVelocityModel, Vlocal)
        data = struct();
        data.area = area;
        data.side = side;
        data.inSlipstream = inSlipstream;
        data.rAC = rAC;
        data.VrigidLocal = VrigidLocal;
        data.v1dEq17 = v1d;
        data.VwakeEq17 = VwakeEq17;
        data.VwakeBasis = VwakeBasis;
        data.eq17BasisError = eq17BasisError;
        data.eq17ReconstructionError = eq17ReconstructionError;
        data.localVelocityModel = localVelocityModel;
        data.Vlocal = Vlocal;
    end

    function value = max_region_field(regions, fieldName)
        values = zeros(numel(regions), 1);
        for iRegion = 1:numel(regions)
            if isfield(regions{iRegion}, fieldName)
                values(iRegion) = regions{iRegion}.(fieldName);
            end
        end
        value = max(values);
    end

    function w = smootherstep(t)
        w = 6*t^5 - 15*t^4 + 10*t^3;
    end
end
