function modal = analyze_berger13_modes(A,B,stateNames,inputNames)
%ANALYZE_BERGER13_MODES Biorthogonal modal metrics and participation.

if ~isequal(size(A),[13,13]) || size(B,1) ~= 13 || ...
        ~isreal(A) || ~isreal(B) || any(~isfinite(A(:))) || ...
        any(~isfinite(B(:)))
    error('analyze_berger13_modes:InvalidModel', ...
        'A and B must be finite real matrices with 13 state rows.');
end
if nargin < 3 || isempty(stateNames)
    stateNames = get_state_names_13x10();
end
if nargin < 4 || isempty(inputNames)
    inputNames = get_command_input_names_13x10();
end

[V,D] = eig(A);
lambda = diag(D);
if rcond(V) < 1e-12
    error('analyze_berger13_modes:DefectiveEigenvectors', ...
        'Right eigenvector matrix is too ill-conditioned for participation.');
end
W = conj(inv(V)).';
biorthogonalityError = norm(W'*V-eye(13),'fro');
participation = abs(V.*conj(W));
participation = participation./max(sum(participation,1),eps);
controlParticipation = abs(W'*B);
controlParticipation = controlParticipation./ ...
    max(sum(controlParticipation,2),eps);

realPart = real(lambda);
imagPart = imag(lambda);
naturalFrequency = abs(lambda);
dampingRatio = -realPart./max(naturalFrequency,eps);
frequencyHz = abs(imagPart)/(2*pi);
timeConstant = NaN(13,1);
doublingTime = NaN(13,1);
halvingTime = NaN(13,1);
for k = 1:13
    if realPart(k) < 0
        timeConstant(k) = -1/realPart(k);
        halvingTime(k) = log(2)/(-realPart(k));
    elseif realPart(k) > 0
        timeConstant(k) = 1/realPart(k);
        doublingTime(k) = log(2)/realPart(k);
    end
end

modeName = cell(13,1);
dominantState = cell(13,1);
dominantStateParticipation = zeros(13,1);
betaSymParticipation = participation(10,:).'+participation(12,:).';
betaDiffParticipation = participation(11,:).'+participation(13,:).';
rigidBodyParticipation = sum(participation(1:9,:),1).';
for k = 1:13
    [dominantStateParticipation(k),idx] = max(participation(:,k));
    dominantState{k} = stateNames{idx};
    modeName{k} = classify_mode(lambda(k),participation(:,k), ...
        betaSymParticipation(k),betaDiffParticipation(k));
end

modeIndex = (1:13).';
stable = realPart < 0;
tableOut = table(modeIndex,modeName,realPart,imagPart,dampingRatio, ...
    naturalFrequency,frequencyHz,timeConstant,doublingTime,halvingTime, ...
    dominantState,dominantStateParticipation,betaSymParticipation, ...
    betaDiffParticipation,rigidBodyParticipation,stable, ...
    'VariableNames',{'localModeIndex','modeName','realPartPerSecond', ...
    'imagPartRadPerSecond','dampingRatio','naturalFrequencyRadPerSecond', ...
    'frequencyHz','timeConstantSeconds','doublingTimeSeconds', ...
    'halvingTimeSeconds','dominantState','dominantStateParticipation', ...
    'betaSymParticipation','betaDiffParticipation', ...
    'rigidBodyParticipation','stable'});

modal.A = A;
modal.B = B;
modal.eigenvalues = lambda;
modal.rightEigenvectors = V;
modal.leftEigenvectors = W;
modal.biorthogonalityError = biorthogonalityError;
modal.participation = participation;
modal.controlParticipation = controlParticipation;
modal.stateNames = stateNames(:);
modal.inputNames = inputNames(:);
modal.table = tableOut;
modal.claimBoundary = ['mode names use participation and symmetric/' ...
    'differential structure but remain low-order model interpretations'];
end

function name = classify_mode(lambda,p,betaSym,betaDiff)
rigid = sum(p(1:9));
if max(betaSym,betaDiff) > 0.45
    if rigid > 0.30
        if betaSym >= betaDiff
            name = 'mixed symmetric nacelle-rigid-body';
        else
            name = 'mixed differential nacelle-rigid-body';
        end
    elseif betaSym >= betaDiff
        name = 'symmetric nacelle actuator';
    else
        name = 'differential nacelle actuator';
    end
    return;
end
longitudinal = sum(p([1,3,5,8,10,12]));
lateral = sum(p([2,4,6,7,9,11,13]));
oscillatory = abs(imag(lambda)) > 1e-5;
if lateral >= longitudinal
    if oscillatory && p(2)+p(6) > 0.20
        name = 'dutch-roll-like';
    elseif oscillatory
        name = 'lateral oscillatory';
    elseif p(4) == max(p)
        name = 'roll-like';
    else
        name = 'spiral-like';
    end
else
    if oscillatory && p(3)+p(5) > p(1)+p(8)
        name = 'short-period-like';
    elseif oscillatory
        name = 'long-period-like';
    else
        name = 'longitudinal aperiodic';
    end
end
end
