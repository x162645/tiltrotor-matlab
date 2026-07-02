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
[F12,~,o12] = wing_model(x,u,0,zeros(3,1),wakeRotor,wakeRotor,P12);
[F24,~,o24] = wing_model(x,u,0,zeros(3,1),wakeRotor,wakeRotor,P24);
[F48,~,o48] = wing_model(x,u,0,zeros(3,1),wakeRotor,wakeRotor,P48);
rel24 = norm(F24-F48)/max(norm(F48),1);
rel12 = norm(F12-F48)/max(norm(F48),1);
[Fzero,~,ozero] = wing_model(x,u,0,zeros(3,1),zeroRotor,zeroRotor,P24);
PnoWake = P24; PnoWake.wing.fullAngleWakeContraction = 0.2;
[Fnarrow,~,onarrow] = wing_model(x,u,0,zeros(3,1),wakeRotor,wakeRotor,PnoWake);
assert(is_real_finite([F12;F24;F48;Fzero;Fnarrow]));
assert(rel24 < 0.08, '24-strip force should be within 8%% of 48-strip reference.');
assert(norm(Fzero-F24) > 1, 'Wake and zero-wake loads should differ.');
assert(all(o24.wakeCoverage.total >= -1e-12 & o24.wakeCoverage.total <= 1+1e-12));
assert(sum(o24.wakeCoverage.total) >= sum(onarrow.wakeCoverage.total));
assert(sum(ozero.wakeCoverage.total) == sum(o24.wakeCoverage.total));
report.rel12To48 = rel12;
report.rel24To48 = rel24;
report.zeroWakeForce = Fzero;
report.wakeForce = F24;
report.allPassed = true;
fprintf('\nWake strip model\n');
fprintf('================\n');
fprintf('rel12To48=%.12e rel24To48=%.12e dWakeForce=%.12e\n', ...
    rel12, rel24, norm(F24-Fzero));
end

function tf = is_real_finite(value)
tf = isreal(value) && all(isfinite(value(:)));
end
