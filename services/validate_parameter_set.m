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
check_lateral_cyclic_flag();
check_linear_state_steps();
check_linear_control_steps();
check_nacelle_dynamics();

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

    function check_lateral_cyclic_flag()
        [ok, value] = lookup_value(P, {'control','enableLateralCyclic'});
        if ~ok
            errors{end+1,1} = 'Missing parameter P.control.enableLateralCyclic.';
            return;
        end
        valid = (islogical(value) && isscalar(value)) || ...
            (isnumeric(value) && isreal(value) && isscalar(value) && ...
            isfinite(value) && (value == 0 || value == 1));
        if ~valid
            errors{end+1,1} = ...
                'P.control.enableLateralCyclic must be logical or numeric 0/1.';
        end
    end

    function check_linear_control_steps()
        [ok, value] = lookup_value(P, {'linear','du'});
        expectedLength = numel(get_control_input_names(P));
        validLength = expectedLength;
        if expectedLength == 8
            validLength = [7, 8];
        end
        if ~ok
            errors{end+1,1} = 'Missing parameter linear.du.';
            return;
        end
        if ~(isnumeric(value) && isreal(value) && ...
                any(numel(value) == validLength) && ...
                all(isfinite(value(:))) && all(value(:) > 0))
            errors{end+1,1} = ...
                'P.linear.du must contain finite positive control steps.';
        end
    end

    function check_linear_state_steps()
        [ok, value] = lookup_value(P, {'linear','dx'});
        if ~ok
            errors{end+1,1} = 'Missing parameter linear.dx.';
            return;
        end
        validBase = isnumeric(value) && isreal(value) && ...
            (numel(value) == 9 || numel(value) == get_state_dimension(P)) && ...
            all(isfinite(value(:))) && all(value(:) > 0);
        if ~validBase
            errors{end+1,1} = ...
                'P.linear.dx must contain finite positive state steps.';
            return;
        end
        if has_nacelle_dynamic_states(P) && numel(value) == 9
            [okExtra, extra] = lookup_value(P, {'nacelleDynamics','linearDx'});
            if ~okExtra || ~(isnumeric(extra) && isreal(extra) && ...
                    numel(extra) == 2 && all(isfinite(extra(:))) && ...
                    all(extra(:) > 0))
                errors{end+1,1} = ['Enabled nacelle dynamics with 9 base ' ...
                    'linear steps requires positive P.nacelleDynamics.linearDx.'];
            end
        end
    end

    function check_nacelle_dynamics()
        if ~isfield(P, 'nacelleDynamics')
            return;
        end
        nd = P.nacelleDynamics;
        if ~isstruct(nd) || ~isscalar(nd)
            errors{end+1,1} = 'P.nacelleDynamics must be a scalar struct.';
            return;
        end
        if ~isfield(nd, 'enabled') || ~((islogical(nd.enabled) && ...
                isscalar(nd.enabled)) || (isnumeric(nd.enabled) && ...
                isreal(nd.enabled) && isscalar(nd.enabled) && ...
                isfinite(nd.enabled) && (nd.enabled == 0 || nd.enabled == 1)))
            errors{end+1,1} = ...
                'P.nacelleDynamics.enabled must be logical or numeric 0/1.';
        end
        if ~isfield(nd, 'model') || ...
                ~(ischar(nd.model) && strcmp(nd.model, 'symmetric_second_order'))
            errors{end+1,1} = ['P.nacelleDynamics.model must be ' ...
                '''symmetric_second_order''.'];
        end
        check_nd_scalar('betaMinDeg', @(v) v >= 0 && v <= 90);
        check_nd_scalar('betaMaxDeg', @(v) v >= 0 && v <= 90);
        if isfield(nd, 'betaMinDeg') && isfield(nd, 'betaMaxDeg') && ...
                isnumeric(nd.betaMinDeg) && isnumeric(nd.betaMaxDeg) && ...
                isscalar(nd.betaMinDeg) && isscalar(nd.betaMaxDeg) && ...
                isfinite(nd.betaMinDeg) && isfinite(nd.betaMaxDeg) && ...
                nd.betaMinDeg >= nd.betaMaxDeg
            errors{end+1,1} = ...
                'P.nacelleDynamics beta limits must satisfy min < max.';
        end
        check_nd_scalar('rateLimitDegPerSec', @(v) v > 0);
        check_nd_scalar('omega', @(v) v > 0);
        check_nd_scalar('zeta', @(v) v > 0);
        check_nd_scalar('tau', @(v) v > 0);
        if ~isfield(nd, 'commandDeg') || ...
                ~(isempty(nd.commandDeg) || (isnumeric(nd.commandDeg) && ...
                isreal(nd.commandDeg) && isscalar(nd.commandDeg) && ...
                isfinite(nd.commandDeg)))
            errors{end+1,1} = ...
                'P.nacelleDynamics.commandDeg must be [] or a finite scalar.';
        end
        if isfield(nd, 'linearDx') && ~(isnumeric(nd.linearDx) && ...
                isreal(nd.linearDx) && numel(nd.linearDx) == 2 && ...
                all(isfinite(nd.linearDx(:))) && all(nd.linearDx(:) > 0))
            errors{end+1,1} = ...
                'P.nacelleDynamics.linearDx must be a positive 2-vector.';
        end
    end

    function check_nd_scalar(fieldName, predicate)
        if ~isfield(P.nacelleDynamics, fieldName)
            errors{end+1,1} = sprintf( ...
                'Missing parameter P.nacelleDynamics.%s.', fieldName);
            return;
        end
        value = P.nacelleDynamics.(fieldName);
        if ~(isnumeric(value) && isreal(value) && isscalar(value) && ...
                isfinite(value) && predicate(value))
            errors{end+1,1} = sprintf( ...
                'P.nacelleDynamics.%s is outside its valid range.', fieldName);
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
