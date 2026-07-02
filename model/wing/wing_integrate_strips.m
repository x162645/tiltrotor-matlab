function [Fbody, Mbody, out] = wing_integrate_strips(x, uCtrl, betaM, cgShift, rotorLeft, rotorRight, P)
%WING_INTEGRATE_STRIPS Integrate full-angle strip forces and moments.

Vbody = x(1:3);
omegaBody = x(4:6);
aileron = uCtrl(5);
flapDeg = 0;
strips = wing_strip_geometry(P);
coverage = wing_wake_coverage(strips, rotorLeft, rotorRight, betaM, cgShift, P);
Fbody = zeros(3,1);
Mbody = zeros(3,1);
stripOut = cell(strips.count, 1);
for i = 1:strips.count
    r0 = strips.rAC(i,:).';
    r = r0 - cgShift;
    Vrigid = Vbody + cross(omegaBody, r);
    side = sign(strips.y(i));
    if side == 0
        side = 1;
    end
    fLeft = coverage.left(i);
    fRight = coverage.right(i);
    fWake = min(1, fLeft + fRight);
    fFree = max(0, 1 - fWake);
    area = strips.area(i);
    chord = strips.chord(i);

    free = wing_local_flow(Vrigid, area*fFree, chord, side, aileron, flapDeg, P);
    left = wing_local_flow(Vrigid + coverage.leftVelocity, area*fLeft, chord, side, aileron, flapDeg, P);
    right = wing_local_flow(Vrigid + coverage.rightVelocity, area*fRight, chord, side, aileron, flapDeg, P);
    F = free.F + left.F + right.F;
    Maero = free.Maero + left.Maero + right.Maero;
    M = cross(r, F) + Maero;
    Fbody = Fbody + F;
    Mbody = Mbody + M;

    stripOut{i} = struct('rAC', r, 'y', strips.y(i), 'area', area, ...
        'freeFraction', fFree, 'leftWakeFraction', fLeft, ...
        'rightWakeFraction', fRight, 'wakeFraction', fWake, ...
        'VrigidLocal', Vrigid, 'F', F, 'M', M, 'Maero', Maero, ...
        'flapDeg', flapDeg, 'aileronCommand', aileron, ...
        'free', free, 'leftWake', left, 'rightWake', right);
end
db = load_wing_aero_database(P);
out = struct();
out.model = 'FULL_ANGLE_STRIP';
out.strips = stripOut;
out.stripCount = strips.count;
out.wakeCoverage = coverage;
out.F = Fbody;
out.M = Mbody;
out.usesCompleteResultBranchBlend = false;
out.usesCommonCoefficientLaw = true;
out.databaseDimensionPolicy = db.dimensionPolicy;
out.controlSurfaceModel = 'database_only_no_legacy_linear_aileron';
out.databaseId = db.id;
end
