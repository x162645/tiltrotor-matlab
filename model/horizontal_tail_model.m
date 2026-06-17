function [Fbody, Mbody, out] = horizontal_tail_model(x, elevator, cgShift, P)
%HORIZONTAL_TAIL_MODEL 平尾与升降舵模型。
% 对应论文式(25)~(26)。

Vbody = x(1:3);
omega = x(4:6);

rAC = P.htail.rAC - cgShift;
Vlocal = Vbody + cross(omega, rAC);
V = norm(Vlocal);

if V < 1e-8
    Fbody = zeros(3,1);
    Mbody = zeros(3,1);
    out = struct('V',V,'F',Fbody,'M',Mbody,'rAC',rAC);
    return;
end

alphaLocal = atan2(Vlocal(3), Vlocal(1));
alphaCG = atan2(Vbody(3), max(abs(Vbody(1)),1e-8));

alphaEff = alphaLocal ...
         - P.htail.downwashAlpha*alphaCG ...
         + P.htail.incidence;

beta = asin(min(max(Vlocal(2)/V, -1), 1));
qbar = 0.5*P.env.rho*V^2;

CLraw = P.htail.CL0 ...
      + P.htail.CLalpha*alphaEff ...
      + P.htail.CLelevator*elevator;

CL = P.htail.CLmax*tanh(CLraw/P.htail.CLmax);
CD = P.htail.CD0 + P.htail.kInduced*CL^2;
Cm = P.htail.Cm0 + P.htail.Cmelevator*elevator;

L = qbar*P.htail.S*CL;
D = qbar*P.htail.S*CD;

Fbody = aero_force_body(D, 0, L, alphaLocal, beta);
Maero = [0; qbar*P.htail.S*P.htail.c*Cm; 0];
Mbody = cross(rAC, Fbody) + Maero;

out.rAC = rAC;
out.Vlocal = Vlocal;
out.V = V;
out.alphaLocal = alphaLocal;
out.alphaEff = alphaEff;
out.CL = CL;
out.CD = CD;
out.Cm = Cm;
out.F = Fbody;
out.M = Mbody;
end
