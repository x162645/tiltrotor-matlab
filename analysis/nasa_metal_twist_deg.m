function theta_deg = nasa_metal_twist_deg(x)
%NASA_METAL_TWIST_DEG Shared audited XV-15 original-metal-blade twist fit.
%
% This is the same public nonlinear twist polynomial already used locally in
% the XV-15 actual-geometry validation diagnostics.  It is exposed as a
% shared analysis helper so later M1 research runners can use exactly the
% same source mapping without duplicating or changing coefficients.
%
% x is nondimensional radius r/R.  Output is geometric blade twist in deg.

theta_deg = 289.98*x.^5-892.87*x.^4+987.06*x.^3 ...
    -438.31*x.^2+15.695*x+32.057;
end
