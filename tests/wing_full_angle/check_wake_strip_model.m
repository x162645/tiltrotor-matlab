function report = check_wake_strip_model()
%CHECK_WAKE_STRIP_MODEL Offline checks for full-angle wake/strip mechanics.

rootDir = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(rootDir);
addpath(fullfile(rootDir,'model'));
addpath(fullfile(rootDir,'model','wing'));

P = params_nominal();
P.wing.fullAngleModelEnabled = 1;
u = zeros(7,1);
x = [18;0;-12;0;0;0;0;0;0];
zeroRotor = struct('muLong',0,'muLat',0,'inducedVelocity',0,'eT',[0;0;-1]);
wakeRotor = struct('muLong',0,'muLat',0,'inducedVelocity',10,'eT',[0;0;-1]);
P12 = P; P12.wing.fullAngleStripCount = 12;
P24 = P; P24.wing.fullAngleStripCount = 24;
P48 = P; P48.wing.fullAngleStripCount = 48;
P96 = P; P96.wing.fullAngleStripCount = 96;
[F12,~,o12] = wing_model(x,u,0,zeros(3,1),wakeRotor,wakeRotor,P12);
[F24,~,o24] = wing_model(x,u,0,zeros(3,1),wakeRotor,wakeRotor,P24);
[F48,~,o48] = wing_model(x,u,0,zeros(3,1),wakeRotor,wakeRotor,P48);
[F96,~,o96] = wing_model(x,u,0,zeros(3,1),wakeRotor,wakeRotor,P96);
rel24 = norm(F24-F48)/max(norm(F48),1);
rel12 = norm(F12-F48)/max(norm(F48),1);
rel48 = norm(F48-F96)/max(norm(F96),1);
[Fzero,~,ozero] = wing_model(x,u,0,zeros(3,1),zeroRotor,zeroRotor,P24);
PnoWake = P24; PnoWake.wing.fullAngleWakeContraction = 0.2;
[Fnarrow,~,onarrow] = wing_model(x,u,0,zeros(3,1),wakeRotor,wakeRotor,PnoWake);
[~,~,oNacelle] = wing_model(x,u,pi/3,zeros(3,1),wakeRotor,wakeRotor,P24);
Psep = P24; Psep.rotor.pivotZ = Psep.rotor.pivotZ - 1.0;
[~,~,oSep] = wing_model(x,u,0,zeros(3,1),wakeRotor,wakeRotor,Psep);
leftWake = wakeRotor; rightWeak = wakeRotor; rightWeak.inducedVelocity = 2;
[~,Masym,oAsym] = wing_model(x,u,0,zeros(3,1),leftWake,rightWeak,P24);
xSideslip = x; xSideslip(2) = 5;
[Fside,~,oSide] = wing_model(xSideslip,u,0,zeros(3,1),wakeRotor,wakeRotor,P24);
assert(is_real_finite([F12;F24;F48;F96;Fzero;Fnarrow;Masym;Fside]));
assert(rel24 < 0.08, '24-strip force should be within 8%% of 48-strip reference.');
assert(rel48 < 0.04, '48-strip force should be within 4%% of 96-strip reference.');
assert(norm(Fzero-F24) > 1, 'Wake and zero-wake loads should differ.');
assert(all(o24.wakeCoverage.total >= -1e-12 & o24.wakeCoverage.total <= 1+1e-12));
assert(sum(o24.wakeCoverage.total) >= sum(onarrow.wakeCoverage.total));
assert(sum(ozero.wakeCoverage.total) == sum(o24.wakeCoverage.total));
assert(norm(oNacelle.wakeCoverage.leftGeometry.centerAtWing - ...
    o24.wakeCoverage.leftGeometry.centerAtWing) > 1e-9, ...
    'Wake centerline must move when nacelle angle changes.');
assert(abs(oSep.wakeCoverage.leftGeometry.diskWingDistance - ...
    o24.wakeCoverage.leftGeometry.diskWingDistance) > 1e-9, ...
    'Disk-wing distance diagnostic must respond to rotor/wing separation.');
assert(norm(Masym) > 0 && norm(oAsym.wakeCoverage.leftVelocity - ...
    oAsym.wakeCoverage.rightVelocity) > 0, ...
    'Left/right wake induced-velocity asymmetry must affect diagnostics and loads.');
assert(isfinite(oSide.strips{1}.free.beta), ...
    'Sideslip local-flow diagnostics must remain finite.');
assert(isfield(o24.wakeCoverage, 'leftGeometry') && ...
    isfield(o24.wakeCoverage.leftGeometry, 'hub') && ...
    isfield(o24.wakeCoverage.leftGeometry, 'centerAtWing') && ...
    isfield(o24.wakeCoverage.leftGeometry, 'diskWingDistance'), ...
    'Wake coverage must report rotor-centerline geometry diagnostics.');
assert(strcmp(o24.wakeCoverage.model, 'ROTOR_AXIS_PROJECTED_STRIP_AREA_SOURCE_TRACED_V1'), ...
    'Wake coverage must use the projected strip-area geometry model.');
assert(strcmp(o24.wakeCoverage.sourceStatus, 'CR_114614_LOCAL_EXTRACT_CR_176970_SOURCE_TRACED'), ...
    'Wake coverage must report CR-114614/CR-176970 source traceability.');
report.rel12To48 = rel12;
report.rel24To48 = rel24;
report.rel48To96 = rel48;
report.zeroWakeForce = Fzero;
report.wakeForce = F24;
report.allPassed = true;
fprintf('\nWake strip model\n');
fprintf('================\n');
fprintf('rel12To48=%.12e rel24To48=%.12e rel48To96=%.12e dWakeForce=%.12e\n', ...
    rel12, rel24, rel48, norm(F24-Fzero));
end

function tf = is_real_finite(value)
tf = isreal(value) && all(isfinite(value(:)));
end
