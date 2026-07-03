function report = check_full_angle_trim_envelope_mode_definitions()
%CHECK_FULL_ANGLE_TRIM_ENVELOPE_MODE_DEFINITIONS Verify mode routing.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir, 'analysis'));

P = params_nominal();
d2r = pi/180;
heli = make_trim_definition('helicopter_longitudinal', ...
    struct('V', 12, 'betaM', 0, 'gamma', 0), P);
assert(isequal(heli.unknownNames, {'theta';'collective';'cyclicLong'}));
assert(isfield(heli.fixedControls, 'elevator') && heli.fixedControls.elevator == 0);
for beta = [15 45 75]
    c = struct('V', 60, 'betaM', beta*d2r, 'gamma', 0);
    conv = make_trim_definition('conversion_longitudinal', c, P);
    assert(any(strcmp(conv.unknownNames, 'pitchCommand')));
    assert(isfield(conv, 'allocation'));
    assert(~isfield(conv.fixedControls, 'cyclicLong'));
    assert(~isfield(conv.fixedControls, 'elevator'));
end
air = make_trim_definition('airplane_longitudinal', ...
    struct('V', 100, 'betaM', pi/2, 'gamma', 0), P);
assert(isequal(air.unknownNames, {'theta';'collective';'elevator'}));
assert(isfield(air.fixedControls, 'cyclicLong') && air.fixedControls.cyclicLong == 0);
report.allPassed = true;
fprintf('Full-angle trim envelope mode definitions check passed.\n');
end
