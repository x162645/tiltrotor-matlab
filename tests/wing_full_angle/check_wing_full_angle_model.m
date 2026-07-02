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
closureError = norm([coeffA.CL - coeffB.CL; coeffA.CD - coeffB.CD; coeffA.Cm - coeffB.Cm]);
assert(closureError < 1e-10);
assert(norm(Fwake - Ffree) > 0, 'Wake induced velocity should change full-angle wing load.');
report.freeForce = Ffree;
report.wakeForce = Fwake;
report.closureError = closureError;
report.allPassed = true;
fprintf('\nWing full-angle model\n');
fprintf('=====================\n');
fprintf('closureError=%.12e dWakeForce=%.12e\n', closureError, norm(Fwake-Ffree));
end

function tf = is_real_finite(value)
tf = isreal(value) && all(isfinite(value(:)));
end

