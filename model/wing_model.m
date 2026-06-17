function [Fbody, Mbody, out] = wing_model(x, uCtrl, betaM, cgShift, rotorLeft, rotorRight, P)
%WING_MODEL 机翼自由流区与旋翼滑流区模型。
% 对应论文式(16)~(22)的部件化实现。

Vbody = x(1:3);
omegaBody = x(4:6);
aileron = uCtrl(5);

S_half = P.wing.S/2;

% 滑流面积在两个端点较大，过渡中部略有收缩；同时考虑前进比。
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

    % 自由流区域
    rFree0 = [P.wing.xAC;
              side*P.wing.yFreeAC;
              P.wing.zAC];
    rFree = rFree0 - cgShift;

    idx = idx + 1;
    [F, M, data] = one_region(rFree, S_free, side, false, rotor);
    Fbody = Fbody + F;
    Mbody = Mbody + M;
    regionOut{idx} = data;

    % 滑流区域
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
            data = struct('area',Sreg,'V',V,'F',Freg,'M',Mreg);
            return;
        end

        alpha = atan2(Vlocal(3), Vlocal(1));
        beta = asin(min(max(Vlocal(2)/V, -1), 1));
        qbar = 0.5*P.env.rho*V^2;

        % 正副翼使左翼升力增加、右翼升力减小，形成正滚转力矩。
        dCLail = -side*P.wing.CLaileron*aileron;

        nearNormal = abs(Vlocal(1))/V < P.wing.normalFlowRatio;

        if nearNormal
            % 近法向流动不再使用小迎角升力线和 Cm-alpha。
            CDn = P.wing.CDnormal;
            Freg = -qbar*Sreg*CDn*(Vlocal/V);
            Maero = zeros(3,1);
            CL = 0;
            CD = CDn;
            Cm = 0;
        else
            CLraw = P.wing.CL0 + P.wing.CLalpha*alpha + dCLail;
            CL = P.wing.CLmax*tanh(CLraw/P.wing.CLmax);
            CD = P.wing.CD0 + P.wing.kInduced*CL^2;
            CY = P.wing.CYbeta*beta;
            Cm = P.wing.Cm0 + P.wing.Cmalpha*alpha ...
               + P.wing.Cmaileron*(-side*aileron);

            L = qbar*Sreg*CL;
            D = qbar*Sreg*CD;
            Y = qbar*Sreg*CY;

            Freg = aero_force_body(D, Y, L, alpha, beta);
            Maero = [0; qbar*Sreg*P.wing.c*Cm; 0];
        end

        Mreg = cross(rAC, Freg) + Maero;

        data.area = Sreg;
        data.side = side;
        data.inSlipstream = inSlipstream;
        data.wakeVelocity = wakeVelocity;
        data.rAC = rAC;
        data.Vlocal = Vlocal;
        data.V = V;
        data.alpha = alpha;
        data.beta = beta;
        data.CL = CL;
        data.CD = CD;
        data.Cm = Cm;
        data.F = Freg;
        data.M = Mreg;
    end
end
