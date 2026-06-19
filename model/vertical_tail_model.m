function [Fbody, Mbody, out] = vertical_tail_model(x, rudder, cgShift, P)
%VERTICAL_TAIL_MODEL 双垂尾与方向舵模型。
% 对应论文式(27)~(30)。

Vbody = x(1:3);
omega = x(4:6);

Fbody = zeros(3,1);
Mbody = zeros(3,1);
finOut = cell(2,1);

sides = [-1, 1];

for k = 1:2
    side = sides(k);

    rAC0 = [P.vtail.xAC;
            side*P.vtail.yAC;
            P.vtail.zAC];

    rAC = rAC0 - cgShift;
    Vlocal = Vbody + cross(omega, rAC);
    V = norm(Vlocal);

    if V < 1e-8
        Ffin = zeros(3,1);
        Mfin = zeros(3,1);
        finOut{k} = struct('side',side,'V',V,'F',Ffin,'M',Mfin);
        continue;
    end

    alpha = atan2(Vlocal(3), Vlocal(1));
    beta = asin(min(max(Vlocal(2)/V, -1), 1));
    qbar = 0.5*P.env.rho*V^2;

    CY = P.vtail.CYbeta*beta + P.vtail.CYrudder*rudder;
    CD = P.vtail.CD0 + 0.02*CY^2;

    Y = qbar*P.vtail.SEach*CY;
    D = qbar*P.vtail.SEach*CD;

    Ffin = aero_force_body(D, Y, 0, alpha, beta);
    Marm = cross(rAC, Ffin);
    Mfin = Marm;

    Fbody = Fbody + Ffin;
    Mbody = Mbody + Mfin;

    finOut{k}.side = side;
    finOut{k}.rAC = rAC;
    finOut{k}.Vlocal = Vlocal;
    finOut{k}.V = V;
    finOut{k}.alpha = alpha;
    finOut{k}.beta = beta;
    finOut{k}.qbar = qbar;
    finOut{k}.CY = CY;
    finOut{k}.CD = CD;
    finOut{k}.Marm = Marm;
    finOut{k}.F = Ffin;
    finOut{k}.M = Mfin;
end

out.fins = finOut;
out.F = Fbody;
out.M = Mbody;
end
