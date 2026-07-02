function coverage = wing_wake_coverage(strips, rotorLeft, rotorRight, P)
%WING_WAKE_COVERAGE Estimate left/right rotor wake coverage per strip.
% Coverage is geometric; aerodynamic-law selection never depends on speed.

Rwake = P.rotor.R;
if isfield(P.wing, 'fullAngleWakeContraction')
    Rwake = Rwake * P.wing.fullAngleWakeContraction;
end
if ~(isfinite(Rwake) && Rwake > 0)
    error('wing_wake_coverage:InvalidWakeRadius', 'Wake radius must be positive.');
end
coverage.left = zeros(strips.count, 1);
coverage.right = zeros(strips.count, 1);
coverage.total = zeros(strips.count, 1);
coverage.leftVelocity = rotorLeft.inducedVelocity * rotorLeft.eT(:);
coverage.rightVelocity = rotorRight.inducedVelocity * rotorRight.eT(:);
for i = 1:strips.count
    y0 = strips.edges(i);
    y1 = strips.edges(i+1);
    coverage.left(i) = interval_overlap_fraction(y0, y1, -P.rotor.pivotY - Rwake, -P.rotor.pivotY + Rwake);
    coverage.right(i) = interval_overlap_fraction(y0, y1, P.rotor.pivotY - Rwake, P.rotor.pivotY + Rwake);
    coverage.total(i) = min(1, coverage.left(i) + coverage.right(i));
end
end

function f = interval_overlap_fraction(a0, a1, b0, b1)
width = a1 - a0;
overlap = max(0, min(a1, b1) - max(a0, b0));
f = min(max(overlap / max(width, eps), 0), 1);
end
