function data = wing_local_flow(Vlocal, area, chord, side, aileron, P)
%WING_LOCAL_FLOW Compute one strip-region force from common full-angle data.

V = norm(Vlocal);
if area <= 0 || V < 1e-8
    data.F = zeros(3,1);
    data.Maero = zeros(3,1);
    data.V = V;
    data.alpha = 0;
    data.beta = 0;
    data.qbar = 0;
    data.CL = 0;
    data.CD = 0;
    data.Cm = 0;
    return;
end
alpha = atan2(Vlocal(3), Vlocal(1));
beta = asin(min(max(Vlocal(2)/V, -1), 1));
coeff = wing_full_angle_lookup(alpha, P);
CL = coeff.CL - side * P.wing.CLaileron * aileron;
CD = coeff.CD;
Cm = coeff.Cm + P.wing.Cmaileron * (-side * aileron);
CY = P.wing.CYbeta * beta;
qbar = 0.5 * P.env.rho * V^2;
L = qbar * area * CL;
D = qbar * area * CD;
Y = qbar * area * CY;
data.F = aero_force_body(D, Y, L, alpha, beta);
data.Maero = [0; qbar * area * chord * Cm; 0];
data.V = V;
data.alpha = alpha;
data.beta = beta;
data.qbar = qbar;
data.CL = CL;
data.CD = CD;
data.Cm = Cm;
data.databaseId = coeff.databaseId;
end
