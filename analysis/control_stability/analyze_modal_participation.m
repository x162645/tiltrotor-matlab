function result = analyze_modal_participation( ...
        pointId,modelKind,A,stateNames)
%ANALYZE_MODAL_PARTICIPATION Generic left/right eigenvector post-processing.
% W is constructed so W'*V=I. The unscaled participation definition is
% P(k,i)=V(k,i)*conj(W(k,i)); normalized magnitudes support classification.

if size(A,1) ~= size(A,2) || ~isreal(A) || any(~isfinite(A(:)))
    error('control_stability:InvalidModalMatrix', ...
        'A must be a finite real square matrix.');
end
n = size(A,1);
if numel(stateNames) ~= n
    error('control_stability:InvalidModalStateNames', ...
        'stateNames must match the A-matrix order.');
end
stateNames = stateNames(:);

[V,D] = eig(A);
lambda = diag(D);
conditionNumber = cond(V);
rcondV = rcond(V);
if ~isfinite(conditionNumber) || rcondV < 1e-12
    inverseV = pinv(V);
    leftEigenvectorMethod = ...
        'PSEUDOINVERSE_DIAGNOSTIC_FOR_PATHOLOGICAL_EIGENVECTORS';
else
    inverseV = V\eye(n);
    leftEigenvectorMethod = 'DIRECT_BIORTHOGONAL_SOLVE';
end
W = conj(inverseV).';
biorthogonalityError = norm(W'*V-eye(n),'fro');
participationRaw = V.*conj(W);
participationMagnitude = abs(participationRaw);
participationNormalized = participationMagnitude./ ...
    max(sum(participationMagnitude,1),eps);

matrixScale = max(1,norm(A,2));
separation = Inf(n,1);
for modeIndex = 1:n
    other = (1:n) ~= modeIndex;
    if any(other)
        separation(modeIndex) = min(abs(lambda(modeIndex)-lambda(other)));
    end
end
minimumSeparation = min(separation);
relativeMinimumSeparation = minimumSeparation/matrixScale;
nearRepeated = relativeMinimumSeparation < 1e-6;
pathological = ~isfinite(conditionNumber) || rcondV < 1e-12 || ...
    conditionNumber > 1e8 || ...
    biorthogonalityError > 1e-8 || nearRepeated;

parameterRows = repmat(empty_parameter_row(),n,1);
classificationRows = repmat(empty_classification_row(),n,1);
participationRows = repmat(empty_participation_row(),n*n,1);
zeroTolerance = max(1e-9,1e-8*matrixScale);
participationRowIndex = 0;
for modeIndex = 1:n
    realPart = real(lambda(modeIndex));
    imagPart = imag(lambda(modeIndex));
    naturalFrequency = abs(lambda(modeIndex));
    dampingRatio = NaN;
    period = NaN;
    halfTime = NaN;
    doublingTime = NaN;
    timeConstant = NaN;
    if naturalFrequency > zeroTolerance
        dampingRatio = -realPart/naturalFrequency;
    end
    if abs(imagPart) > zeroTolerance
        period = 2*pi/abs(imagPart);
    end
    if realPart < -zeroTolerance
        halfTime = log(2)/(-realPart);
        if abs(imagPart) <= zeroTolerance
            timeConstant = -1/realPart;
        end
        stability = 'STABLE';
    elseif realPart > zeroTolerance
        doublingTime = log(2)/realPart;
        stability = 'UNSTABLE';
    else
        stability = 'CRITICAL_OR_KINEMATIC';
    end

    scores = group_scores(participationNormalized(:,modeIndex),stateNames);
    [classification,confidence,dominantGroup,dominantScore,secondScore] = ...
        classify_mode(lambda(modeIndex),scores,stateNames, ...
        participationNormalized(:,modeIndex),pathological,zeroTolerance);

    parameterRows(modeIndex).pointId = pointId;
    parameterRows(modeIndex).modelKind = modelKind;
    parameterRows(modeIndex).modeIndex = modeIndex;
    parameterRows(modeIndex).realPartPerSecond = realPart;
    parameterRows(modeIndex).imagPartRadPerSecond = imagPart;
    parameterRows(modeIndex).naturalFrequencyRadPerSecond = naturalFrequency;
    parameterRows(modeIndex).dampingRatio = dampingRatio;
    parameterRows(modeIndex).oscillationPeriodSeconds = period;
    parameterRows(modeIndex).halfAmplitudeTimeSeconds = halfTime;
    parameterRows(modeIndex).doublingTimeSeconds = doublingTime;
    parameterRows(modeIndex).realRootTimeConstantSeconds = timeConstant;
    parameterRows(modeIndex).stability = stability;
    parameterRows(modeIndex).finiteRealMatrix = true;

    classificationRows(modeIndex).pointId = pointId;
    classificationRows(modeIndex).modelKind = modelKind;
    classificationRows(modeIndex).modeIndex = modeIndex;
    classificationRows(modeIndex).classification = classification;
    classificationRows(modeIndex).classificationConfidence = confidence;
    classificationRows(modeIndex).dominantGroup = dominantGroup;
    classificationRows(modeIndex).dominantGroupScore = dominantScore;
    classificationRows(modeIndex).secondGroupScore = secondScore;
    classificationRows(modeIndex).longitudinalRigidBodyScore = ...
        scores.longitudinal;
    classificationRows(modeIndex).lateralDirectionalRigidBodyScore = ...
        scores.lateral;
    classificationRows(modeIndex).symmetricNacelleScore = ...
        scores.nacelleSym;
    classificationRows(modeIndex).differentialNacelleScore = ...
        scores.nacelleDiff;
    classificationRows(modeIndex).actuatorRateScore = ...
        scores.actuatorRate;
    classificationRows(modeIndex).pathologicalEigenvectors = pathological;
    classificationRows(modeIndex).modeTrackingStatus = ...
        'NOT_TRACKED_ACROSS_EXPLICIT_TRIM_MODE_BOUNDARIES';

    for stateIndex = 1:n
        participationRowIndex = participationRowIndex+1;
        participationRows(participationRowIndex).pointId = pointId;
        participationRows(participationRowIndex).modelKind = modelKind;
        participationRows(participationRowIndex).modeIndex = modeIndex;
        participationRows(participationRowIndex).stateIndex = stateIndex;
        participationRows(participationRowIndex).stateName = ...
            stateNames{stateIndex};
        participationRows(participationRowIndex).rightEigenvectorReal = ...
            real(V(stateIndex,modeIndex));
        participationRows(participationRowIndex).rightEigenvectorImag = ...
            imag(V(stateIndex,modeIndex));
        participationRows(participationRowIndex).leftEigenvectorReal = ...
            real(W(stateIndex,modeIndex));
        participationRows(participationRowIndex).leftEigenvectorImag = ...
            imag(W(stateIndex,modeIndex));
        participationRows(participationRowIndex).participationRawReal = ...
            real(participationRaw(stateIndex,modeIndex));
        participationRows(participationRowIndex).participationRawImag = ...
            imag(participationRaw(stateIndex,modeIndex));
        participationRows(participationRowIndex).participationMagnitude = ...
            participationMagnitude(stateIndex,modeIndex);
        participationRows(participationRowIndex).normalizedMagnitude = ...
            participationNormalized(stateIndex,modeIndex);
    end
end

conditioningRow = struct('pointId',{{pointId}}, ...
    'modelKind',{{modelKind}}, ...
    'matrixOrder',n,'eigenvectorConditionNumber',conditionNumber, ...
    'eigenvectorReciprocalCondition',rcondV, ...
    'biorthogonalityError',biorthogonalityError, ...
    'minimumEigenvalueSeparation',minimumSeparation, ...
    'relativeMinimumSeparation',relativeMinimumSeparation, ...
    'nearRepeatedRoot',nearRepeated, ...
    'pathologicalEigenvectors',pathological, ...
    'leftEigenvectorMethod',{{leftEigenvectorMethod}}, ...
    'participationScaleSensitivityStatus', ...
    {{'STATE_SCALING_DEPENDENT_REPORTED_WITH_RAW_EIGENVECTORS'}}, ...
    'modeTrackingStatus', ...
    {{'NOT_TRACKED_ACROSS_EXPLICIT_TRIM_MODE_BOUNDARIES'}});

result.parameters = struct2table(parameterRows);
result.participation = struct2table(participationRows);
result.classification = struct2table(classificationRows);
result.conditioning = struct2table(conditioningRow);
result.eigenvalues = lambda;
result.rightEigenvectors = V;
result.leftEigenvectors = W;
result.participationRaw = participationRaw;
result.participationNormalizedMagnitude = participationNormalized;
end

function scores = group_scores(p,stateNames)
scores.longitudinal = sum_named(p,stateNames,{'u','w','q','theta'});
scores.lateral = sum_named(p,stateNames,{'v','p','r','phi','psi'});
scores.nacelleSym = sum_named(p,stateNames,{'betaSym','betaSymDot'});
scores.nacelleDiff = sum_named(p,stateNames,{'betaDiff','betaDiffDot'});
scores.actuatorRate = sum_named(p,stateNames, ...
    {'betaMLdot','betaMRdot','betaSymDot','betaDiffDot'});
end

function value = sum_named(p,stateNames,names)
value = sum(p(ismember(stateNames,names)));
end

function [classification,confidence,dominantGroup, ...
        dominantScore,secondScore] = classify_mode( ...
        lambda,scores,stateNames,p,pathological,zeroTolerance)
groupNames = {'LONGITUDINAL_RIGID_BODY','LATERAL_DIRECTIONAL_RIGID_BODY', ...
    'SYMMETRIC_NACELLE','DIFFERENTIAL_NACELLE'};
values = [scores.longitudinal,scores.lateral, ...
    scores.nacelleSym,scores.nacelleDiff];
[sorted,index] = sort(values,'descend');
dominantScore = sorted(1);
if numel(sorted) > 1
    secondScore = sorted(2);
else
    secondScore = 0;
end
dominantGroup = groupNames{index(1)};

psiIndex = find(strcmp(stateNames,'psi'),1);
heading = ~isempty(psiIndex) && abs(lambda) <= zeroTolerance && ...
    p(psiIndex) >= 0.5;
if pathological
    classification = 'MIXED_OR_UNCERTAIN_MODE';
    confidence = 'LOW';
elseif heading
    classification = 'HEADING_KINEMATIC_INTEGRATOR';
    confidence = 'HIGH';
elseif dominantScore < 0.55 || ...
        dominantScore-secondScore < 0.15
    classification = 'MIXED_OR_UNCERTAIN_MODE';
    confidence = 'LOW';
else
    oscillatory = abs(imag(lambda)) > zeroTolerance;
    suffix = 'APERIODIC_MODE';
    if oscillatory
        suffix = 'OSCILLATORY_MODE';
    end
    switch dominantGroup
        case 'LONGITUDINAL_RIGID_BODY'
            classification = ['LONGITUDINAL_' suffix];
        case 'LATERAL_DIRECTIONAL_RIGID_BODY'
            classification = ['LATERAL_DIRECTIONAL_' suffix];
        case 'SYMMETRIC_NACELLE'
            classification = 'SYMMETRIC_NACELLE_ACTUATOR_MODE';
        case 'DIFFERENTIAL_NACELLE'
            classification = 'DIFFERENTIAL_NACELLE_ACTUATOR_MODE';
        otherwise
            classification = 'MIXED_OR_UNCERTAIN_MODE';
    end
    if dominantScore >= 0.75 && dominantScore-secondScore >= 0.30
        confidence = 'HIGH';
    else
        confidence = 'MEDIUM';
    end
end
end

function row = empty_parameter_row()
row = struct('pointId','','modelKind','','modeIndex',NaN, ...
    'realPartPerSecond',NaN,'imagPartRadPerSecond',NaN, ...
    'naturalFrequencyRadPerSecond',NaN,'dampingRatio',NaN, ...
    'oscillationPeriodSeconds',NaN,'halfAmplitudeTimeSeconds',NaN, ...
    'doublingTimeSeconds',NaN,'realRootTimeConstantSeconds',NaN, ...
    'stability','','finiteRealMatrix',false);
end

function row = empty_classification_row()
row = struct('pointId','','modelKind','','modeIndex',NaN, ...
    'classification','','classificationConfidence','', ...
    'dominantGroup','','dominantGroupScore',NaN, ...
    'secondGroupScore',NaN,'longitudinalRigidBodyScore',NaN, ...
    'lateralDirectionalRigidBodyScore',NaN, ...
    'symmetricNacelleScore',NaN,'differentialNacelleScore',NaN, ...
    'actuatorRateScore',NaN,'pathologicalEigenvectors',false, ...
    'modeTrackingStatus','');
end

function row = empty_participation_row()
row = struct('pointId','','modelKind','','modeIndex',NaN, ...
    'stateIndex',NaN,'stateName','','rightEigenvectorReal',NaN, ...
    'rightEigenvectorImag',NaN,'leftEigenvectorReal',NaN, ...
    'leftEigenvectorImag',NaN,'participationRawReal',NaN, ...
    'participationRawImag',NaN,'participationMagnitude',NaN, ...
    'normalizedMagnitude',NaN);
end
