function validate_inputs(x, uCtrl, betaM, P)
%VALIDATE_INPUTS Check state, control, nacelle angle, and core parameters.

expectedNu = numel(get_control_input_names(P));

assert(isnumeric(x) && isreal(x) && numel(x) == 9, ...
    'x must be a 9-element real vector.');
assert(isnumeric(uCtrl) && isreal(uCtrl) && numel(uCtrl) == expectedNu, ...
    'uCtrl must match the active control input count.');
assert(all(isfinite(x(:))), 'x contains NaN or Inf.');
assert(all(isfinite(uCtrl(:))), 'uCtrl contains NaN or Inf.');
assert(isscalar(betaM) && isfinite(betaM), ...
    'betaM must be a finite scalar.');
assert(betaM >= -1e-9 && betaM <= pi/2 + 1e-9, ...
    'betaM must be between 0 and pi/2.');

assert(P.mass.m > 0, 'Total mass must be positive.');
assert(P.rotor.R > 0 && P.rotor.Omega > 0, ...
    'Rotor radius and speed must be positive.');
assert(P.rotor.nRadial >= 3 && P.rotor.nAzimuth >= 4, ...
    'Rotor discretization is too small.');

I0 = 0.5*(P.mass.I0 + P.mass.I0.');
assert(all(eig(I0) > 0), 'Nominal inertia matrix must be positive definite.');
end
