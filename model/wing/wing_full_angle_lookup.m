function coeff = wing_full_angle_lookup(alpha, Re, Mach, flapDeg, P)
%WING_FULL_ANGLE_LOOKUP Interpolate full-angle wing CL, CD, and Cm.
% Alpha is radians. The production interface is alpha/Re/Mach/flapDeg; old
% alpha-only calls remain accepted and are reported as reduced-dimensional.
% The production path uses PCHIP in alpha inside each database slice, then
% linear interpolation across Re, Mach and the symmetric plain-flap family.

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
policy = 'clamp';
if isfield(P.wing, 'fullAngleOutOfRangePolicy')
    policy = P.wing.fullAngleOutOfRangePolicy;
end

reDim = dimension_request(db, 'Re', Re, policy, P);
machDim = dimension_request(db, 'Mach', Mach, policy, P);
flapDim = dimension_request(db, 'flapDeg', flapDeg, policy, P);

[CL, CD, Cm] = interpolate_corners(db, alphaWrapped, method, reDim, machDim, flapDim);
coeff.CL = CL;
coeff.CD = CD;
coeff.Cm = Cm;
coeff.alpha = alphaWrapped;
coeff.Re = Re;
coeff.Mach = Mach;
coeff.flapDeg = flapDeg;
coeff.databaseId = db.id;
coeff.databasePath = db.path;
coeff.dimensionPolicy = db.dimensionPolicy;
coeff.gridOutOfRangePolicy = policy;
coeff.outOfRangeClamped = reDim.clamped || machDim.clamped || flapDim.clamped;
coeff.interpolatedDimensions = struct('Re', reDim, 'Mach', machDim, ...
    'flapDeg', flapDim);
coeff.dimensionReductionActive = db.isReducedAlphaOnly || ...
    reDim.reduced || machDim.reduced || flapDim.reduced;
coeff.hasReDimension = db.hasReDimension;
coeff.hasMachDimension = db.hasMachDimension;
coeff.hasFlapDimension = db.hasFlapDimension;
if ~isreal(coeff.CL) || ~isreal(coeff.CD) || ~isreal(coeff.Cm) || ...
        ~all(isfinite([coeff.CL; coeff.CD; coeff.Cm])) || coeff.CD < 0
    error('wing_full_angle_lookup:InvalidCoefficient', ...
        'Full-angle interpolation produced invalid coefficients.');
end
end

function [CL, CD, Cm] = interpolate_corners(db, alpha, method, reDim, machDim, flapDim)
CL = 0;
CD = 0;
Cm = 0;
for iRe = 1:numel(reDim.values)
    for iMach = 1:numel(machDim.values)
        for iFlap = 1:numel(flapDim.values)
            w = reDim.weights(iRe) * machDim.weights(iMach) * flapDim.weights(iFlap);
            if w == 0
                continue;
            end
            slice = alpha_slice(db, reDim.values(iRe), machDim.values(iMach), ...
                flapDim.values(iFlap));
            CL = CL + w * interp1(slice.alpha, slice.CL, alpha, method, 'extrap');
            CD = CD + w * interp1(slice.alpha, slice.CD, alpha, method, 'extrap');
            Cm = Cm + w * interp1(slice.alpha, slice.Cm, alpha, method, 'extrap');
        end
    end
end
end

function slice = alpha_slice(db, Re, Mach, flapDeg)
mask = true(size(db.alpha));
if db.hasReDimension
    mask = mask & abs(db.Re - Re) <= max(1e-6, 1e-12*max(abs(Re), 1));
end
if db.hasMachDimension
    mask = mask & abs(db.Mach - Mach) <= 1e-12;
end
if db.hasFlapDimension
    mask = mask & abs(db.flapDeg - flapDeg) <= 1e-9;
end
alphaGrid = db.alpha(mask);
CLGrid = db.CL(mask);
CDGrid = db.CD(mask);
CmGrid = db.Cm(mask);
[alphaGrid, order] = sort(alphaGrid);
CLGrid = CLGrid(order);
CDGrid = CDGrid(order);
CmGrid = CmGrid(order);
[alphaGrid, uniqueIdx] = unique(alphaGrid, 'stable');
slice.alpha = alphaGrid;
slice.CL = CLGrid(uniqueIdx);
slice.CD = CDGrid(uniqueIdx);
slice.Cm = CmGrid(uniqueIdx);
if numel(slice.alpha) < 2
    error('wing_full_angle_lookup:InsufficientSlice', ...
        'Selected full-angle database slice has fewer than two alpha rows.');
end
end

function dim = dimension_request(db, name, requested, policy, P)
[hasDimension, rawValues, defaultValue] = dimension_values(db, name, P);
dim.name = name;
dim.requested = requested;
dim.reduced = false;
dim.clamped = false;
dim.policy = policy;
if ~hasDimension
    dim.values = defaultValue;
    dim.weights = 1;
    dim.query = defaultValue;
    dim.reduced = isfinite(requested) && abs(requested - defaultValue) > 1e-12;
    return;
end
values = unique(rawValues(isfinite(rawValues)));
values = sort(values(:).');
if ~isfinite(requested)
    query = defaultValue;
    dim.reduced = true;
else
    query = requested;
end
[v0, v1, w, clamped] = bracket_dimension(values, query, policy, name);
dim.values = unique([v0, v1], 'stable');
if numel(dim.values) == 1
    dim.weights = 1;
else
    dim.weights = [1-w, w];
end
dim.query = query;
dim.clamped = clamped;
end

function [hasDimension, values, defaultValue] = dimension_values(db, name, P)
switch name
    case 'Re'
        hasDimension = db.hasReDimension;
        values = db.Re;
        defaultValue = default_from_param(P, 'fullAngleDefaultRe', median(values(isfinite(values))));
    case 'Mach'
        hasDimension = db.hasMachDimension;
        values = db.Mach;
        finiteValues = values(isfinite(values));
        defaultValue = default_from_param(P, 'fullAngleDefaultMach', min(finiteValues));
    case 'flapDeg'
        hasDimension = db.hasFlapDimension;
        values = db.flapDeg;
        defaultValue = 0;
    otherwise
        error('wing_full_angle_lookup:UnknownDimension', 'Unknown dimension %s.', name);
end
end

function value = default_from_param(P, fieldName, fallback)
if isfield(P.wing, fieldName) && isfinite(P.wing.(fieldName))
    value = P.wing.(fieldName);
else
    value = fallback;
end
end

function [v0, v1, w, clamped] = bracket_dimension(values, query, policy, name)
clamped = false;
if query < values(1)
    if strcmpi(policy, 'error')
        error('wing_full_angle_lookup:OutOfRange', ...
            '%s %.12g is below database range %.12g.', name, query, values(1));
    end
    query = values(1);
    clamped = true;
elseif query > values(end)
    if strcmpi(policy, 'error')
        error('wing_full_angle_lookup:OutOfRange', ...
            '%s %.12g is above database range %.12g.', name, query, values(end));
    end
    query = values(end);
    clamped = true;
end
idxUpper = find(values >= query, 1, 'first');
if isempty(idxUpper)
    idxUpper = numel(values);
end
if idxUpper == 1
    v0 = values(1);
    v1 = values(1);
    w = 0;
elseif abs(values(idxUpper) - query) < 1e-12*max(abs(query), 1)
    v0 = values(idxUpper);
    v1 = values(idxUpper);
    w = 0;
else
    v0 = values(idxUpper-1);
    v1 = values(idxUpper);
    w = (query - v0) / (v1 - v0);
end
end
