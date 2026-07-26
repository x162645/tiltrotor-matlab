function xPerturbed = perturb_body_flow_angles(x9,alpha,betaSlip)
%PERTURB_BODY_FLOW_ANGLES Reconstruct velocity at fixed speed magnitude.
% alpha=atan2(w,u), betaSlip=asin(v/V), body z is positive downward.

xPerturbed = x9(:);
V = norm(xPerturbed(1:3));
if ~(isfinite(V) && V > 0)
    error('control_stability:InvalidPerturbationSpeed', ...
        'Flow-angle perturbations require positive finite speed.');
end
xPerturbed(1) = V*cos(alpha)*cos(betaSlip);
xPerturbed(2) = V*sin(betaSlip);
xPerturbed(3) = V*sin(alpha)*cos(betaSlip);
end
