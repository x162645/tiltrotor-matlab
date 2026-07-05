function report = check_xv15_public_parameters()
%CHECK_XV15_PUBLIC_PARAMETERS Validate the opt-in XV-15 public profile.
% This check verifies unit conversions and profile isolation only. It does
% not validate a complete XV-15 aircraft model.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir,'model'));

d2r = pi / 180;
P = params_xv15_public();
Pdefault = params_nominal();

names = {};
passed = [];
messages = {};

add_case('profile function runs and metadata present', ...
    isfield(P,'meta') && isfield(P.meta,'parameterProfile') && ...
    strcmp(P.meta.parameterProfile,'XV15_PUBLIC_GEOMETRY_PROFILE'), ...
    'params_xv15_public() did not return the expected profile metadata.');

add_close('design gross mass kg', P.mass.m, 5896.7, 0.05);
add_close('wing area m2', P.wing.S, 15.7006, 5e-4);
add_close('wing span m', P.wing.b, 9.8044, 5e-4);
add_close('wing chord m', P.wing.c, 1.6002, 5e-4);
add_close('rotor radius m', P.rotor.R, 3.81, 5e-4);
add_close('rotor chord m', P.rotor.chord, 0.3556, 5e-5);
add_close('helicopter omega rad/s', P.rotor.OmegaHelicopter, 61.68, 0.02);
add_close('airplane omega rad/s', P.rotor.OmegaAirplane, 54.14, 0.02);
add_close('horizontal tail area m2', P.htail.S, 4.668, 5e-3);
add_close('vertical tail area each m2', P.vtail.SEach, 2.346, 5e-3);
add_close('flap max rad', P.control.flapMax, 75*d2r, 1e-14);
add_close('flaperon max rad', P.control.flaperonMax, 47*d2r, 1e-14);

add_case('default wing model remains legacy opt-in full-angle', ...
    strcmp(Pdefault.wing.modelType,'legacy') && ...
    isequal(Pdefault.wing.fullAngleModelEnabled,0), ...
    'params_nominal() default wing model or full-angle opt-in flag changed.');

add_case('default aileron limits not overwritten by flaperon reference', ...
    max(abs(Pdefault.control.aileronLim(:) - [-30; 30]*d2r)) < 1e-14 && ...
    max(abs(P.control.aileronLim(:) - Pdefault.control.aileronLim(:))) < 1e-14, ...
    'The XV-15 flaperon reference must not overwrite model aileronLim.');

add_case('retained non-XV15 fields are explicitly marked', ...
    isfield(P.mass,'retainedConceptStatus') && ...
    isfield(P.rotor,'retainedConceptStatus') && ...
    isfield(P.wing,'retainedConceptStatus') && ...
    isfield(P.htail,'rACStatus') && ...
    isfield(P.vtail,'positionStatus'), ...
    'Retained concept/assumed fields lack source/status markers.');

allValues = [P.mass.m; P.wing.S; P.wing.b; P.wing.c; P.rotor.R; ...
    P.rotor.chord; P.rotor.OmegaHelicopter; P.rotor.OmegaAirplane; ...
    P.htail.S; P.vtail.SEach; P.control.flapMax; P.control.flaperonMax];
add_case('checked public values finite and real', ...
    isreal(allValues) && all(isfinite(allValues)), ...
    'At least one checked public value is NaN, Inf, or complex.');

report.names = names;
report.passed = passed;
report.messages = messages;
report.allPassed = all(passed);
report.profile = P.meta.parameterProfile;
report.scope = ['Unit conversion and isolation check only; this is not ' ...
    'complete XV-15 model validation.'];

fprintf('\nXV-15 public parameter profile checks\n');
fprintf('=====================================\n');
for k = 1:numel(names)
    fprintf('%-52s : %s\n', names{k}, ternary(passed(k),'PASS','FAIL'));
    if ~passed(k)
        fprintf('  %s\n', messages{k});
    end
end
fprintf('All passed: %d\n', report.allPassed);

    function add_close(name, actual, expected, tolerance)
        add_case(name, abs(actual - expected) <= tolerance, ...
            sprintf('%s expected %.12g, got %.12g.', name, expected, actual));
    end

    function add_case(name, ok, message)
        names{end+1,1} = name;
        passed(end+1,1) = logical(ok);
        if ok
            messages{end+1,1} = '';
        else
            messages{end+1,1} = message;
        end
    end

    function value = ternary(condition,a,b)
        if condition
            value = a;
        else
            value = b;
        end
    end
end
