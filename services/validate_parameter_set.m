function report = validate_parameter_set(P)
%VALIDATE_PARAMETER_SET Validate the active concept-model parameter structure.
% This service checks only structural, dimensional, finite-value, and basic
% physical-consistency requirements. Passing does not imply XV-15 validation.

errors = {};
warnings = {};

check_scalar({'env','rho'}, 'Air density P.env.rho', @(v) v > 0);
check_scalar({'env','g'}, 'Gravity P.env.g', @(v) v > 0);
check_scalar({'mass','m'}, 'Total mass P.mass.m', @(v) v > 0);
check_scalar({'mass','mNac'}, 'Moving nacelle mass P.mass.mNac', @(v) v >= 0);
check_scalar({'rotor','R'}, 'Rotor radius P.rotor.R', @(v) v > 0);
check_scalar({'rotor','Omega'}, 'Rotor speed P.rotor.Omega', @(v) v > 0);
check_scalar({'rotor','chord'}, 'Rotor chord P.rotor.chord', @(v) v > 0);
check_integer({'rotor','Nb'}, 'Blade count P.rotor.Nb', 1);
check_integer({'rotor','nRadial'}, 'Radial stations P.rotor.nRadial', 2);
check_integer({'rotor','nAzimuth'}, 'Azimuth stations P.rotor.nAzimuth', 4);
check_scalar({'wing','S'}, 'Wing area P.wing.S', @(v) v > 0);
check_scalar({'wing','b'}, 'Wing span P.wing.b', @(v) v > 0);
check_scalar({'wing','c'}, 'Wing chord P.wing.c', @(v) v > 0);
check_scalar({'trim','residualTolerance'}, ...
    'Trim residual tolerance P.trim.residualTolerance', @(v) v > 0);
check_integer({'trim','maxIterations'}, ...
    'Trim maximum iterations P.trim.maxIterations', 1);
check_scalar({'linear','stabilityTolerance'}, ...
    'Stability tolerance P.linear.stabilityTolerance', @(v) v >= 0);

[okI, I0] = lookup_value(P, {'mass','I0'});
inertiaMatrixValid = false;
if ~okI
    errors{end+1,1} = 'Missing parameter P.mass.I0.';
elseif ~(isnumeric(I0) && isreal(I0) && isequal(size(I0), [3,3]) && ...
        all(isfinite(I0(:))))
    errors{end+1,1} = 'P.mass.I0 must be a finite real 3-by-3 matrix.';
else
    symmetryError = norm(I0-I0.', 'fro');
    if symmetryError > 1e-10*max(norm(I0,'fro'),1)
        errors{end+1,1} = 'P.mass.I0 must be symmetric.';
    elseif any(eig(0.5*(I0+I0.')) <= 0)
        errors{end+1,1} = 'P.mass.I0 must be positive definite.';
    else
        inertiaMatrixValid = true;
    end
end

check_limits({'control','collectiveLim'}, 'P.control.collectiveLim');
check_limits({'control','cyclicLim'}, 'P.control.cyclicLim');
check_limits({'control','aileronLim'}, 'P.control.aileronLim');
check_limits({'control','elevatorLim'}, 'P.control.elevatorLim');
check_limits({'control','rudderLim'}, 'P.control.rudderLim');
check_positive_vector({'linear','dx'}, 'P.linear.dx', 9);
check_positive_vector({'linear','du'}, 'P.linear.du', 7);

if inertiaMatrixValid
    try
        mp0 = mass_properties(0,P);
        mp90 = mass_properties(pi/2,P);
        if any(~isfinite(mp0.cgShift)) || any(~isfinite(mp90.cgShift)) || ...
                any(~isfinite(mp0.I(:))) || any(~isfinite(mp90.I(:)))
            errors{end+1,1} = ...
                'Mass properties must remain finite at betaM = 0 and 90 deg.';
        end
    catch ME
        errors{end+1,1} = sprintf( ...
            'Mass/inertia parameters are invalid over betaM = [0, 90] deg: %s', ...
            ME.message);
    end
end

[okMass, totalMass] = lookup_value(P, {'mass','m'});
[okNac, nacelleMass] = lookup_value(P, {'mass','mNac'});
if okMass && okNac && isnumeric(totalMass) && isnumeric(nacelleMass) && ...
        isscalar(totalMass) && isscalar(nacelleMass) && ...
        isfinite(totalMass) && isfinite(nacelleMass) && nacelleMass >= totalMass
    warnings{end+1,1} = ...
        'P.mass.mNac is greater than or equal to total mass; review its meaning.';
end

report.valid = isempty(errors);
report.errors = errors;
report.warnings = warnings;
report.errorCount = numel(errors);
report.warningCount = numel(warnings);
if report.valid
    if isempty(warnings)
        report.summary = 'Parameter validation passed.';
    else
        report.summary = sprintf('Parameter validation passed with %d warning(s).', ...
            numel(warnings));
    end
else
    report.summary = sprintf('Parameter validation failed with %d error(s).', ...
        numel(errors));
end

    function check_scalar(pathParts, label, predicate)
        [ok, value] = lookup_value(P, pathParts);
        if ~ok
            errors{end+1,1} = sprintf('Missing parameter %s.', strjoin(pathParts,'.'));
            return;
        end
        if ~(isnumeric(value) && isreal(value) && isscalar(value) && isfinite(value))
            errors{end+1,1} = sprintf('%s must be a finite real scalar.', label);
            return;
        end
        if ~predicate(value)
            errors{end+1,1} = sprintf('%s is outside its valid range.', label);
        end
    end

    function check_integer(pathParts, label, minimumValue)
        [ok, value] = lookup_value(P, pathParts);
        if ~ok
            errors{end+1,1} = sprintf('Missing parameter %s.', strjoin(pathParts,'.'));
            return;
        end
        if ~(isnumeric(value) && isreal(value) && isscalar(value) && ...
                isfinite(value) && value >= minimumValue && value == round(value))
            errors{end+1,1} = sprintf('%s must be an integer >= %d.', ...
                label, minimumValue);
        end
    end

    function check_limits(pathParts, label)
        [ok, value] = lookup_value(P, pathParts);
        if ~ok
            errors{end+1,1} = sprintf('Missing parameter %s.', strjoin(pathParts,'.'));
            return;
        end
        if ~(isnumeric(value) && isreal(value) && numel(value) == 2 && ...
                all(isfinite(value(:))) && value(1) < value(2))
            errors{end+1,1} = sprintf('%s must contain two increasing finite values.', label);
        end
    end

    function check_positive_vector(pathParts, label, expectedLength)
        [ok, value] = lookup_value(P, pathParts);
        if ~ok
            errors{end+1,1} = sprintf('Missing parameter %s.', strjoin(pathParts,'.'));
            return;
        end
        if ~(isnumeric(value) && isreal(value) && numel(value) == expectedLength && ...
                all(isfinite(value(:))) && all(value(:) > 0))
            errors{end+1,1} = sprintf('%s must contain %d finite positive values.', ...
                label, expectedLength);
        end
    end
end

function [ok, value] = lookup_value(S, pathParts)
value = S;
ok = true;
for k = 1:numel(pathParts)
    if ~isstruct(value) || ~isfield(value, pathParts{k})
        ok = false;
        value = [];
        return;
    end
    value = value.(pathParts{k});
end
end
