function report = check_wing_full_angle_control_surface()
%CHECK_WING_FULL_ANGLE_CONTROL_SURFACE Audit full-angle control-surface status.

rootDir = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(rootDir);
addpath(fullfile(rootDir,'model'));
addpath(fullfile(rootDir,'model','wing'));

P = params_nominal();
P.wing.fullAngleModelEnabled = 1;
P.wing.fullAngleStripCount = 24;
zeroRotor = struct('muLong',0,'muLat',0,'inducedVelocity',0,'eT',[0;0;-1]);
x = [35;0;-3;0;0;0;0;0;0];
u0 = zeros(7,1);
h = 1.0*pi/180;
uPlus = u0; uPlus(5) = h;
uMinus = u0; uMinus(5) = -h;
[F0,M0,out0] = wing_model(x, u0, pi/4, zeros(3,1), zeroRotor, zeroRotor, P);
[Fp,Mp,outP] = wing_model(x, uPlus, pi/4, zeros(3,1), zeroRotor, zeroRotor, P);
[Fm,Mm,outM] = wing_model(x, uMinus, pi/4, zeros(3,1), zeroRotor, zeroRotor, P);
aileronColumn = ([Fp;Mp] - [Fm;Mm])/(2*h);
baselineError = max(norm([Fp-F0; Mp-M0]), norm([Fm-F0; Mm-M0]));
assert(is_real_finite([F0;M0;Fp;Mp;Fm;Mm;aileronColumn]));
assert(baselineError < 1e-12, ...
    'Current full-angle baseline must not hide unsupported aileron increments.');
assert(norm(aileronColumn) < 1e-10, ...
    'Aileron derivative must remain zero unless a sourced aileron model is added.');
assert(strcmp(out0.controlSurfaceModel, ...
    'longitudinal_full_angle_baseline_no_lateral_aileron_aero'));
assert(strcmp(outP.aileronAerodynamicsMode, ...
    'UNMODELED_NO_CREDIBLE_FULL_ANGLE_AILERON_DATA'));
assert(strcmp(outM.aileronAerodynamicsMode, ...
    'UNMODELED_NO_CREDIBLE_FULL_ANGLE_AILERON_DATA'));

report.aileronColumn = aileronColumn;
report.baselineError = baselineError;
report.controlSurfaceGate = 'PARTIAL';
report.allPassed = true;
fprintf('\nWing full-angle control surface audit\n');
fprintf('=====================================\n');
fprintf('aileronColumnNorm=%.12e baselineError=%.12e gate=%s\n', ...
    norm(aileronColumn), baselineError, report.controlSurfaceGate);
end

function tf = is_real_finite(value)
tf = isreal(value) && all(isfinite(value(:)));
end
