function result = run_linearization_case(trimResult, P)
%RUN_LINEARIZATION_CASE Linearize at a converged trim point and classify modes.

if nargin < 2 || isempty(P)
    P = params_nominal();
end
if nargin < 1 || ~isstruct(trimResult)
    error('run_linearization_case:InvalidTrimResult', ...
        'trimResult must be a structure returned by run_trim_case.');
end
required = {'xTrim','uTrim','betaM','success'};
for k = 1:numel(required)
    if ~isfield(trimResult, required{k})
        error('run_linearization_case:InvalidTrimResult', ...
            'trimResult is missing field %s.', required{k});
    end
end
if ~trimResult.success
    error('run_linearization_case:UnconvergedTrim', ...
        'Linearization requires a converged trim result.');
end

parameterReport = validate_parameter_set(P);
if ~parameterReport.valid
    error('run_linearization_case:InvalidParameters', '%s\n%s', ...
        parameterReport.summary, strjoin(parameterReport.errors, newline));
end

[A, B, linearReport] = linearize_numeric( ...
    trimResult.xTrim, trimResult.uTrim, trimResult.betaM, P);
if ~linearReport.finite
    error('run_linearization_case:NonFiniteMatrices', ...
        'Linearization returned non-finite or complex values.');
end

lambda = eig(A);
wn = abs(lambda);
zeta = NaN(size(lambda));
nonzero = wn > eps;
zeta(nonzero) = -real(lambda(nonzero))./wn(nonzero);
timeScale = Inf(size(lambda));
nonzeroReal = abs(real(lambda)) > eps;
timeScale(nonzeroReal) = 1./abs(real(lambda(nonzeroReal)));

stabilityTolerance = P.linear.stabilityTolerance;
classification = cell(numel(lambda),1);
for k = 1:numel(lambda)
    if real(lambda(k)) > stabilityTolerance
        classification{k} = 'UNSTABLE';
    elseif real(lambda(k)) < -stabilityTolerance
        classification{k} = 'STABLE';
    else
        classification{k} = 'NEUTRAL';
    end
end

result.kind = 'numeric-linearization';
result.timestamp = datestr(now, 30);
result.success = true;
result.A = A;
result.B = B;
result.report = linearReport;
result.trim = trimResult;
result.parameterValidation = parameterReport;
result.stateNames = get_state_names(P);
result.controlNames = get_control_input_names(P);
result.eigenvalues = lambda;
result.naturalFrequency = wn;
result.dampingRatio = zeta;
result.timeScale = timeScale;
result.classification = classification;
result.isAsymptoticallyStable = all(real(lambda) < -stabilityTolerance);
result.hasUnstableMode = any(real(lambda) > stabilityTolerance);
result.stabilityTolerance = stabilityTolerance;
end
