function [Fbody, Mbody, out] = wing_model_full_angle(x, uCtrl, betaM, cgShift, rotorLeft, rotorRight, P)
%WING_MODEL_FULL_ANGLE Full-angle wing strip model.
% Free-stream and rotor-wake strip portions use the same CL/CD/Cm lookup.
% Differences come only from local velocity, alpha, qbar, area and moment arm.

x = x(:);
uCtrl = uCtrl(:);
[Fbody, Mbody, out] = wing_integrate_strips( ...
    x, uCtrl, betaM, cgShift, rotorLeft, rotorRight, P);
out.betaMCode = betaM;
[wakeArea, freeArea] = strip_area_totals(out.strips);
out.SslipHalf = 0.5*wakeArea;
out.SfreeHalf = 0.5*freeArea;
out.normalFlowBranchWeight = 0;
out.slipstreamAreaModel = 'STRIP_WAKE_COVERAGE_GEOMETRY';
out.localVelocityModel = 'RIGID_BODY_PLUS_EXISTING_ROTOR_INDUCED_VELOCITY';
out.controlSurfaceModel = 'database_only_no_legacy_linear_aileron';
end

function [wakeArea, freeArea] = strip_area_totals(strips)
wakeArea = 0;
freeArea = 0;
for i = 1:numel(strips)
    strip = strips{i};
    wakeArea = wakeArea + strip.area*strip.wakeFraction;
    freeArea = freeArea + strip.area*strip.freeFraction;
end
end
