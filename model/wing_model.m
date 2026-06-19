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

muFactor = 1 - 0.25*min(muMean/max(P.wing.muMax, eps), 1);
orientationFactor = 0.60 + 0.40*abs(cos(2*betaM));

S_slip = min(P.wing.SslipMaxHalf, S_half) ...
       * muFactor * orientationFactor;
S_slip = min(max(S_slip, 0), S_half);
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
out.regions = regionOut;
out.F = Fbody;
out.M = Mbody;

    function [Freg, Mreg, data] = one_region(rAC, Sreg, side, inSlipstream, rotor)
        if Sreg <= 0
            Freg = zeros(3,1);
            Mreg = zeros(3,1);
            data = struct('area',0,'F',Freg,'M',Mreg);
            return;
        end

        Vlocal = Vbody + cross(omegaBody, rAC);

        if inSlipstream
            wakeVelocity = P.rotor.wakeFactor*max(rotor.inducedVelocity,0);
            Vlocal = Vlocal + wakeVelocity*rotor.eT;
        else
            wakeVelocity = 0;
        end

        V = norm(Vlocal);
        if V < 1e-8
            Freg = zeros(3,1);
            Mreg = zeros(3,1);
            data = struct('area',Sreg,'side',side, ...
                'inSlipstream',inSlipstream,'wakeVelocity',wakeVelocity, ...
                'rAC',rAC,'Vlocal',Vlocal,'V',V,'F',Freg,'M',Mreg);
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
        data.wakeVelocity = wakeVelocity;
        data.rAC = rAC;
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

    function w = smootherstep(t)
        w = 6*t^5 - 15*t^4 + 10*t^3;
    end
end
