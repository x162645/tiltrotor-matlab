function coeff = wing_full_angle_lookup(alpha, Re, Mach, flapDeg, P)
%WING_FULL_ANGLE_LOOKUP Interpolate full-angle wing CL, CD, and Cm.
% Alpha is radians. The production interface is alpha/Re/Mach/flapDeg; old
% alpha-only calls remain accepted and are reported as reduced-dimensional.

if nargin == 2
    P = Re;
    Re = NaN;
    Mach = NaN;
    flapDeg = 0;
elseif nargin ~= 5
    error('wing_full_angle_lookup:InvalidInputCount', ...
        'Expected (alpha,P) or (alpha,Re,Mach,flapDeg,P).');
end

db = load_wing_aero_database(P);
alphaWrapped = mod(alpha + pi, 2*pi) - pi;
if alphaWrapped == -pi && alpha > 0
    alphaWrapped = pi;
end
method = 'pchip';
if isfield(P.wing, 'fullAngleInterpolationMethod')
    method = P.wing.fullAngleInterpolationMethod;
end

rowMask = select_dimension_rows(db, Re, Mach, flapDeg);
alphaGrid = db.alpha(rowMask);
CLGrid = db.CL(rowMask);
CDGrid = db.CD(rowMask);
CmGrid = db.Cm(rowMask);
[alphaGrid, uniqueIdx] = unique(alphaGrid, 'stable');
CLGrid = CLGrid(uniqueIdx);
CDGrid = CDGrid(uniqueIdx);
CmGrid = CmGrid(uniqueIdx);
if numel(alphaGrid) < 2
    error('wing_full_angle_lookup:InsufficientSlice', ...
        'Selected full-angle database slice has fewer than two alpha rows.');
end

coeff.CL = interp1(alphaGrid, CLGrid, alphaWrapped, method, 'extrap');
coeff.CD = interp1(alphaGrid, CDGrid, alphaWrapped, method, 'extrap');
coeff.Cm = interp1(alphaGrid, CmGrid, alphaWrapped, method, 'extrap');
coeff.alpha = alphaWrapped;
coeff.Re = Re;
coeff.Mach = Mach;
coeff.flapDeg = flapDeg;
coeff.databaseId = db.id;
coeff.databasePath = db.path;
coeff.dimensionPolicy = db.dimensionPolicy;
coeff.dimensionReductionActive = db.isReducedAlphaOnly || ...
    (db.hasReDimension && ~isfinite(Re)) || ...
    (db.hasMachDimension && ~isfinite(Mach)) || ...
    (db.hasFlapDimension && ~isfinite(flapDeg)) || ...
    (~db.hasReDimension && isfinite(Re)) || ...
    (~db.hasMachDimension && isfinite(Mach)) || ...
    (~db.hasFlapDimension && isfinite(flapDeg) && abs(flapDeg) > 1e-12);
coeff.hasReDimension = db.hasReDimension;
coeff.hasMachDimension = db.hasMachDimension;
coeff.hasFlapDimension = db.hasFlapDimension;
if ~isreal(coeff.CL) || ~isreal(coeff.CD) || ~isreal(coeff.Cm) || ...
        ~all(isfinite([coeff.CL; coeff.CD; coeff.Cm])) || coeff.CD < 0
    error('wing_full_angle_lookup:InvalidCoefficient', ...
        'Full-angle interpolation produced invalid coefficients.');
end
end

function rowMask = select_dimension_rows(db, Re, Mach, flapDeg)
rowMask = true(size(db.alpha));
if db.hasReDimension
    values = unique(db.Re(isfinite(db.Re)));
    if isfinite(Re)
        target = Re;
    else
        target = values(ceil(numel(values)/2));
    end
    [~, idx] = min(abs(values - target));
    rowMask = rowMask & abs(db.Re - values(idx)) < 1e-9;
end
if db.hasMachDimension
    values = unique(db.Mach(isfinite(db.Mach)));
    if isfinite(Mach)
        target = Mach;
    else
        target = values(1);
    end
    [~, idx] = min(abs(values - target));
    rowMask = rowMask & abs(db.Mach - values(idx)) < 1e-12;
end
if db.hasFlapDimension
    values = unique(db.flapDeg(isfinite(db.flapDeg)));
    if isfinite(flapDeg)
        target = flapDeg;
    else
        target = 0;
    end
    [~, idx] = min(abs(values - target));
    rowMask = rowMask & abs(db.flapDeg - values(idx)) < 1e-9;
end
end
