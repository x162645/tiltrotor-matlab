function report = check_wing_full_angle_model()
%CHECK_WING_FULL_ANGLE_MODEL Full-angle wing-model smoke and physics checks.

rootDir = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(rootDir);
addpath(fullfile(rootDir,'model'));
addpath(fullfile(rootDir,'model','wing'));

P = params_nominal();
P.wing.fullAngleModelEnabled = 1;
P.wing.fullAngleStripCount = 24;
zeroRotor = struct('muLong',0,'muLat',0,'inducedVelocity',0,'eT',[0;0;-1]);
wakeRotor = struct('muLong',0,'muLat',0,'inducedVelocity',10,'eT',[0;0;-1]);
x = [24;0;-8;0;0;0;0;0;0];
u = zeros(7,1);
[Ffree,Mfree,outFree] = wing_model(x, u, 0, zeros(3,1), zeroRotor, zeroRotor, P);
[Fwake,Mwake,outWake] = wing_model(x, u, 0, zeros(3,1), wakeRotor, wakeRotor, P);
assert(is_real_finite([Ffree;Mfree;Fwake;Mwake]));
assert(outFree.usesCommonCoefficientLaw && ~outFree.usesCompleteResultBranchBlend);
assert(outWake.usesCommonCoefficientLaw && ~outWake.usesCompleteResultBranchBlend);
assert(outFree.stripCount == P.wing.fullAngleStripCount);
assert(abs(outFree.wakeCoverage.total(1)) <= 1);
coeffA = wing_full_angle_lookup(-pi, P);
coeffB = wing_full_angle_lookup(pi, P);
coeffLocal = wing_full_angle_lookup(0.05, 1.0e6, 0.10, 0, P);
closureError = norm([coeffA.CL - coeffB.CL; coeffA.CD - coeffB.CD; coeffA.Cm - coeffB.Cm]);
assert(closureError < 1e-10);
assert(isfield(coeffLocal, 'dimensionReductionActive'), ...
    'Lookup must expose database dimensionality diagnostics.');
assert(max_strip_re_mach(outWake) > 0, ...
    'Full-angle strip diagnostics must include local Re and Mach.');
assert(strcmp(outWake.controlSurfaceModel, ...
    'longitudinal_full_angle_baseline_no_lateral_aileron_aero'), ...
    'Full-angle path must not silently add legacy linear aileron increments.');
assert(strcmp(outWake.aileronAerodynamicsMode, ...
    'UNMODELED_NO_CREDIBLE_FULL_ANGLE_AILERON_DATA'), ...
    'Full-angle path must expose the unvalidated aileron-aero status.');
assert(norm(Fwake - Ffree) > 0, 'Wake induced velocity should change full-angle wing load.');
report.freeForce = Ffree;
report.wakeForce = Fwake;
report.closureError = closureError;
report.dimensionReductionActive = coeffLocal.dimensionReductionActive;
report.allPassed = true;
fprintf('\nWing full-angle model\n');
fprintf('=====================\n');
fprintf('closureError=%.12e dWakeForce=%.12e\n', closureError, norm(Fwake-Ffree));
end

function tf = is_real_finite(value)
tf = isreal(value) && all(isfinite(value(:)));
end

function value = max_strip_re_mach(out)
value = 0;
for i = 1:numel(out.strips)
    strip = out.strips{i};
    regions = {strip.free, strip.leftWake, strip.rightWake};
    for k = 1:numel(regions)
        item = regions{k};
        if isfield(item, 'Re') && isfield(item, 'Mach')
            value = max(value, min(item.Re, item.Mach));
        end
    end
end
end
