function data = wing_local_flow(Vlocal, area, chord, side, aileron, flapDeg, P)
%WING_LOCAL_FLOW Compute one strip-region force from common full-angle data.

V = norm(Vlocal);
if area <= 0 || V < 1e-8
    data.F = zeros(3,1);
    data.Maero = zeros(3,1);
    data.V = V;
    data.alpha = 0;
    data.beta = 0;
    data.qbar = 0;
    data.Re = 0;
    data.Mach = 0;
    data.flapDeg = flapDeg;
    data.CL = 0;
    data.CD = 0;
    data.Cm = 0;
    data.controlSurfaceModel = 'no_load_zero_area_or_velocity';
    data.aileronAerodynamicsMode = 'UNMODELED_NO_CREDIBLE_FULL_ANGLE_AILERON_DATA';
    return;
end
alpha = atan2(Vlocal(3), Vlocal(1));
beta = asin(min(max(Vlocal(2)/V, -1), 1));
qbar = 0.5 * P.env.rho * V^2;
Re = local_reynolds(V, chord, P);
Mach = local_mach(V, P);
coeff = wing_full_angle_lookup(alpha, Re, Mach, flapDeg, P);
CL = coeff.CL;
CD = coeff.CD;
Cm = coeff.Cm;
CY = P.wing.CYbeta * beta;
L = qbar * area * CL;
D = qbar * area * CD;
Y = qbar * area * CY;
data.F = aero_force_body(D, Y, L, alpha, beta);
data.Maero = [0; qbar * area * chord * Cm; 0];
data.V = V;
data.alpha = alpha;
data.beta = beta;
data.qbar = qbar;
data.Re = Re;
data.Mach = Mach;
data.flapDeg = flapDeg;
data.aileronCommand = aileron;
data.controlSurfaceModel = P.wing.fullAngleControlSurfacePolicy;
data.aileronAerodynamicsMode = 'UNMODELED_NO_CREDIBLE_FULL_ANGLE_AILERON_DATA';
data.CL = CL;
data.CD = CD;
data.Cm = Cm;
data.databaseId = coeff.databaseId;
data.dimensionPolicy = coeff.dimensionPolicy;
data.dimensionReductionActive = coeff.dimensionReductionActive;
end

function Re = local_reynolds(V, chord, P)
if isfield(P.env, 'mu') && isfinite(P.env.mu) && P.env.mu > 0
    mu = P.env.mu;
else
    mu = 1.7894e-5;
end
Re = P.env.rho * V * chord / mu;
end

function Mach = local_mach(V, P)
if isfield(P.env, 'a') && isfinite(P.env.a) && P.env.a > 0
    a = P.env.a;
else
    a = 340.3;
end
Mach = V / a;
end
