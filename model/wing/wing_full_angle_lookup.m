function coeff = wing_full_angle_lookup(alpha, P)
%WING_FULL_ANGLE_LOOKUP Interpolate full-angle wing CL, CD, and Cm.
% Alpha is radians.  The table is periodic over [-pi, pi].

db = load_wing_aero_database(P);
alphaWrapped = mod(alpha + pi, 2*pi) - pi;
if alphaWrapped == -pi && alpha > 0
    alphaWrapped = pi;
end
method = 'pchip';
if isfield(P.wing, 'fullAngleInterpolationMethod')
    method = P.wing.fullAngleInterpolationMethod;
end
coeff.CL = interp1(db.alpha, db.CL, alphaWrapped, method, 'extrap');
coeff.CD = interp1(db.alpha, db.CD, alphaWrapped, method, 'extrap');
coeff.Cm = interp1(db.alpha, db.Cm, alphaWrapped, method, 'extrap');
coeff.alpha = alphaWrapped;
coeff.databaseId = db.id;
coeff.databasePath = db.path;
if ~isreal(coeff.CL) || ~isreal(coeff.CD) || ~isreal(coeff.Cm) || ...
        ~all(isfinite([coeff.CL; coeff.CD; coeff.Cm])) || coeff.CD < 0
    error('wing_full_angle_lookup:InvalidCoefficient', ...
        'Full-angle interpolation produced invalid coefficients.');
end
end
