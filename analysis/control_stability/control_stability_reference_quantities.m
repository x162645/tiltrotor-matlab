function ref = control_stability_reference_quantities(x9,betaM,P)
%CONTROL_STABILITY_REFERENCE_QUANTITIES Aerodynamic normalization contract.

x9 = x9(:);
V = norm(x9(1:3));
if ~(isfinite(V) && V > 0)
    error('control_stability:InvalidReferenceSpeed', ...
        'A positive finite body-speed magnitude is required.');
end
ref.V = V;
ref.alpha = atan2(x9(3),x9(1));
ref.betaSlip = asin(max(-1,min(1,x9(2)/V)));
ref.rho = P.env.rho;
ref.qbar = 0.5*P.env.rho*V^2;
ref.S = P.wing.S;
ref.c = P.wing.c;
ref.b = P.wing.b;
ref.momentReference = 'CURRENT_CENTER_OF_GRAVITY';
ref.bodyAxes = 'x forward, y right, z down';
ref.betaM = betaM;
ref.angleUnits = 'rad';
end
