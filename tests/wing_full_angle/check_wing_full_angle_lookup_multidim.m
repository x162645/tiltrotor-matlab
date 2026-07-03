function report = check_wing_full_angle_lookup_multidim()
%CHECK_WING_FULL_ANGLE_LOOKUP_MULTIDIM Verify continuous 4-D coefficient lookup.

rootDir = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(rootDir);
addpath(fullfile(rootDir,'model'));
addpath(fullfile(rootDir,'model','wing'));

P = params_nominal();
alpha = 4.3*pi/180;
Re = 0.8e6;
Mach = 0.05;
flapDeg = 15;
mid = wing_full_angle_lookup(alpha, Re, Mach, flapDeg, P);
expected = corner_weighted_lookup(alpha, Re, Mach, flapDeg, P);
err = norm([mid.CL-expected.CL; mid.CD-expected.CD; mid.Cm-expected.Cm]);
assert(err < 1e-10, 'Multidimensional lookup did not match linear corner interpolation.');
assert(~mid.dimensionReductionActive, ...
    'Fully specified alpha/Re/Mach/flap lookup must not report dimension reduction.');
assert(~mid.outOfRangeClamped, 'Interior query should not be clamped.');
assert(is_real_finite([mid.CL; mid.CD; mid.Cm]) && mid.CD >= 0);

oldCall = wing_full_angle_lookup(alpha, P);
assert(oldCall.dimensionReductionActive, ...
    'Legacy alpha-only lookup must explicitly report reduced-dimensional use.');

low = wing_full_angle_lookup(alpha, 1.0e5, Mach, flapDeg, P);
edge = wing_full_angle_lookup(alpha, 0.6e6, Mach, flapDeg, P);
assert(low.outOfRangeClamped, 'Out-of-range Re query must report clamping.');
assert(norm([low.CL-edge.CL; low.CD-edge.CD; low.Cm-edge.Cm]) < 1e-10, ...
    'Clamped Re query must equal the boundary value.');

Perr = P;
Perr.wing.fullAngleOutOfRangePolicy = 'error';
didError = false;
try
    wing_full_angle_lookup(alpha, 1.0e5, Mach, flapDeg, Perr);
catch ME
    didError = strcmp(ME.identifier, 'wing_full_angle_lookup:OutOfRange');
end
assert(didError, 'Error policy must reject out-of-range dimensions.');

minusPi = wing_full_angle_lookup(-pi, 1.0e6, 0.1, 0, P);
plusPi = wing_full_angle_lookup(pi, 1.0e6, 0.1, 0, P);
closure = norm([minusPi.CL-plusPi.CL; minusPi.CD-plusPi.CD; minusPi.Cm-plusPi.Cm]);
assert(closure < 1e-10, 'Periodic alpha closure failed.');

derivs = numerical_derivatives(alpha, Re, Mach, flapDeg, P);
assert(is_real_finite(derivs), 'Numerical lookup derivatives must be finite real values.');

report.midpointError = err;
report.periodicClosure = closure;
report.derivatives = derivs;
report.allPassed = true;
fprintf('\nWing full-angle multidimensional lookup\n');
fprintf('=======================================\n');
fprintf('midpointError=%.12e periodicClosure=%.12e\n', err, closure);
end

function coeff = corner_weighted_lookup(alpha, Re, Mach, flapDeg, P)
reVals = [0.6e6, 1.0e6];
machVals = [0.0, 0.1];
flapVals = [0, 30];
reW = (Re - reVals(1))/(reVals(2) - reVals(1));
machW = (Mach - machVals(1))/(machVals(2) - machVals(1));
flapW = (flapDeg - flapVals(1))/(flapVals(2) - flapVals(1));
coeff.CL = 0;
coeff.CD = 0;
coeff.Cm = 0;
for i = 1:2
    for j = 1:2
        for k = 1:2
            w = weight(i, reW)*weight(j, machW)*weight(k, flapW);
            c = wing_full_angle_lookup(alpha, reVals(i), machVals(j), flapVals(k), P);
            coeff.CL = coeff.CL + w*c.CL;
            coeff.CD = coeff.CD + w*c.CD;
            coeff.Cm = coeff.Cm + w*c.Cm;
        end
    end
end
end

function w = weight(index, upperWeight)
if index == 1
    w = 1 - upperWeight;
else
    w = upperWeight;
end
end

function derivs = numerical_derivatives(alpha, Re, Mach, flapDeg, P)
steps = [1e-4, 1e3, 1e-4, 1e-3];
base = [alpha, Re, Mach, flapDeg];
derivs = zeros(3,4);
for k = 1:4
    plus = base; minus = base;
    plus(k) = plus(k) + steps(k);
    minus(k) = minus(k) - steps(k);
    cp = wing_full_angle_lookup(plus(1), plus(2), plus(3), plus(4), P);
    cm = wing_full_angle_lookup(minus(1), minus(2), minus(3), minus(4), P);
    derivs(:,k) = ([cp.CL; cp.CD; cp.Cm] - [cm.CL; cm.CD; cm.Cm])/(2*steps(k));
end
end

function tf = is_real_finite(value)
tf = isreal(value) && all(isfinite(value(:)));
end
