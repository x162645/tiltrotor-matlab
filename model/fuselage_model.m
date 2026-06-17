function [Fbody, Mbody, out] = fuselage_model(x, cgShift, P)
%FUSELAGE_MODEL 机身低阶气动力与气动力矩模型。
% 对应论文式(23)~(24)的坐标与力矩结构。

Vbody = x(1:3);
omega = x(4:6);

rAC = P.fuselage.rAC - cgShift;
Vlocal = Vbody + cross(omega, rAC);
V = norm(Vlocal);

if V < 1e-8
    Fbody = zeros(3,1);
    Mbody = zeros(3,1);
    out = struct('V',V,'F',Fbody,'M',Mbody,'rAC',rAC);
    return;
end

alpha = atan2(Vlocal(3), Vlocal(1));
beta = asin(min(max(Vlocal(2)/V, -1), 1));
qbar = 0.5*P.env.rho*V^2;

CD = P.fuselage.CD0 ...
   + P.fuselage.CDalpha2*alpha^2 ...
   + P.fuselage.CDbeta2*beta^2;

CL = P.fuselage.CL0 + P.fuselage.CLalpha*alpha;
CY = P.fuselage.CYbeta*beta;

D = qbar*P.fuselage.S*CD;
L = qbar*P.fuselage.S*CL;
Y = qbar*P.fuselage.S*CY;

Fbody = aero_force_body(D, Y, L, alpha, beta);

pHat = omega(1)*P.fuselage.b/(2*V);
qHat = omega(2)*P.fuselage.c/(2*V);
rHat = omega(3)*P.fuselage.b/(2*V);

Cl = P.fuselage.Clbeta*beta ...
   + P.fuselage.Clp*pHat ...
   + P.fuselage.Clr*rHat;

Cm = P.fuselage.Cm0 ...
   + P.fuselage.Cmalpha*alpha ...
   + P.fuselage.Cmq*qHat;

Cn = P.fuselage.Cnbeta*beta ...
   + P.fuselage.Cnp*pHat ...
   + P.fuselage.Cnr*rHat;

Maero = qbar*P.fuselage.S * ...
    [P.fuselage.b*Cl;
     P.fuselage.c*Cm;
     P.fuselage.b*Cn];

Mbody = cross(rAC, Fbody) + Maero;

out.rAC = rAC;
out.Vlocal = Vlocal;
out.V = V;
out.alpha = alpha;
out.beta = beta;
out.CD = CD;
out.CL = CL;
out.CY = CY;
out.Cl = Cl;
out.Cm = Cm;
out.Cn = Cn;
out.F = Fbody;
out.M = Mbody;
end
