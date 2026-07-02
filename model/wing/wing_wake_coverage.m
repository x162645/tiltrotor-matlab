function coverage = wing_wake_coverage(strips, rotorLeft, rotorRight, betaM, cgShift, P)
%WING_WAKE_COVERAGE Estimate left/right rotor wake coverage per strip.
% The geometry uses each rotor hub, rotor-axis direction, disk-wing
% distance, wake radius and true strip span overlap. It is still a
% provisional source-traced strip model, not a validated free-wake method.

coverage.left = zeros(strips.count, 1);
coverage.right = zeros(strips.count, 1);
coverage.total = zeros(strips.count, 1);
coverage.leftVelocity = rotorLeft.inducedVelocity * rotorLeft.eT(:);
coverage.rightVelocity = rotorRight.inducedVelocity * rotorRight.eT(:);
coverage.model = 'ROTOR_AXIS_PROJECTED_STRIP_AREA_PROVISIONAL';
coverage.sourceStatus = 'CR_114614_CR_176970_FORMULA_EXTRACTION_PARTIAL';

leftGeom = rotor_wake_geometry(rotorLeft, -1, betaM, cgShift, P);
rightGeom = rotor_wake_geometry(rotorRight, +1, betaM, cgShift, P);
coverage.leftGeometry = leftGeom;
coverage.rightGeometry = rightGeom;

for i = 1:strips.count
    y0 = strips.edges(i);
    y1 = strips.edges(i+1);
    rStrip = strips.rAC(i,:).';
    coverage.left(i) = strip_fraction_for_wake(y0, y1, rStrip, leftGeom);
    coverage.right(i) = strip_fraction_for_wake(y0, y1, rStrip, rightGeom);
    coverage.total(i) = min(1, coverage.left(i) + coverage.right(i));
end
end

function geom = rotor_wake_geometry(rotor, side, betaM, cgShift, P)
if isfield(rotor, 'rHub') && numel(rotor.rHub) == 3
    hub = rotor.rHub(:) + cgShift(:);
else
    hub = [P.rotor.pivotX + P.rotor.RH_hub*sin(betaM);
           side*P.rotor.pivotY;
           P.rotor.pivotZ - P.rotor.RH_hub*cos(betaM)];
end
if isfield(rotor, 'eT') && numel(rotor.eT) == 3
    axis = rotor.eT(:);
else
    axis = [sin(betaM); 0; -cos(betaM)];
end
axisNorm = norm(axis);
if ~(isfinite(axisNorm) && axisNorm > 0)
    error('wing_wake_coverage:InvalidRotorAxis', 'Rotor axis must be finite.');
end
axis = axis / axisNorm;

radius = P.rotor.R;
if isfield(P.wing, 'fullAngleWakeContraction')
    radius = radius * P.wing.fullAngleWakeContraction;
end
if ~(isfinite(radius) && radius > 0)
    error('wing_wake_coverage:InvalidWakeRadius', 'Wake radius must be positive.');
end

% Use the downstream line from disk to wing. In the current body convention,
% induced velocity is added along eT, while the disk-to-wing geometric
% centerline is the opposite direction for helicopter-mode download.
wakeDir = -axis;
if abs(wakeDir(3)) >= abs(wakeDir(1))
    planeCoordinate = 'z';
    planeValue = P.wing.zAC;
    denom = wakeDir(3);
    offsetAxis = [1; 0; 0];
    t = (planeValue - hub(3)) / guarded_denom(denom);
else
    planeCoordinate = 'x';
    planeValue = P.wing.xAC;
    denom = wakeDir(1);
    offsetAxis = [0; 0; 1];
    t = (planeValue - hub(1)) / guarded_denom(denom);
end
if ~isfinite(t) || t < 0
    t = 0;
end
center = hub + t*wakeDir;

geom = struct();
geom.side = side;
geom.hub = hub;
geom.axis = axis;
geom.wakeDir = wakeDir;
geom.centerAtWing = center;
geom.radiusAtWing = radius;
geom.diskWingDistance = abs(t);
geom.planeCoordinate = planeCoordinate;
geom.planeValue = planeValue;
geom.offsetAxis = offsetAxis;
geom.assumptions = ['straight rotor-axis wake centerline; radius equals ' ...
    'P.rotor.R times fullAngleWakeContraction; strip area fraction from ' ...
    'spanwise overlap of circular wake footprint'];
end

function f = strip_fraction_for_wake(y0, y1, rStrip, geom)
radius = geom.radiusAtWing;
normalOffset = dot(rStrip - geom.centerAtWing, geom.offsetAxis);
if abs(normalOffset) >= radius
    f = 0;
    return;
end
halfSpan = sqrt(max(radius^2 - normalOffset^2, 0));
b0 = geom.centerAtWing(2) - halfSpan;
b1 = geom.centerAtWing(2) + halfSpan;
f = interval_overlap_fraction(y0, y1, b0, b1);
end

function value = guarded_denom(denom)
if abs(denom) < 1e-9
    value = sign(denom + (denom == 0))*1e-9;
else
    value = denom;
end
end

function f = interval_overlap_fraction(a0, a1, b0, b1)
width = a1 - a0;
overlap = max(0, min(a1, b1) - max(a0, b0));
f = min(max(overlap / max(width, eps), 0), 1);
end
