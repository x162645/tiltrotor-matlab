function diag = diagnose_berger13_nullspace(A13, B13, stateNames, ...
    controlNames, conditioningDiag)
%DIAGNOSE_BERGER13_NULLSPACE Internal nullspace diagnostics for 13x10.
% This helper reports numerical null directions and effective condition
% values. It does not alter A13/B13 and does not represent validation.

if nargin < 3 || isempty(stateNames)
    stateNames = default_names('x', size(A13, 2));
end
if nargin < 4 || isempty(controlNames)
    controlNames = default_names('u', size(B13, 2));
end
if nargin < 5
    conditioningDiag = struct();
end

stateNames = stateNames(:);
controlNames = controlNames(:);
validate_inputs(A13, B13, stateNames, controlNames);

rawA = nullspace_diagnostics(A13, stateNames);
scaledA = scaled_matrix(A13, stateNames, conditioningDiag);
scaledADiag = nullspace_diagnostics(scaledA, stateNames);
[reducedA, reducedIdx] = reduced_state_matrix(A13, stateNames, ...
    conditioningDiag);
reducedNames = stateNames(reducedIdx);
reducedADiag = nullspace_diagnostics(reducedA, reducedNames);
Bdiag = nullspace_diagnostics(B13, controlNames);

diag.rankA = rawA.rank;
diag.nullityA = rawA.nullity;
diag.toleranceA = rawA.tolerance;
diag.singularValuesA = rawA.singularValues;
diag.nonzeroSingularValuesA = rawA.nonzeroSingularValues;
diag.effectiveCondA = rawA.effectiveCondition;
diag.nullspaceARightVectors = rawA.rightNullspaceVectors;
diag.dominantStatesPerNullVector = rawA.dominantNames;
diag.dominantStateWeightsPerNullVector = rawA.dominantWeights;
diag.nullVectorInterpretation = interpretation_text('A', rawA, ...
    'state');

diag.scaledToleranceA = scaledADiag.tolerance;
diag.scaledEffectiveCondA = scaledADiag.effectiveCondition;
diag.scaledNullspaceRightVectors = scaledADiag.rightNullspaceVectors;
diag.dominantStatesScaled = scaledADiag.dominantNames;
diag.dominantStateWeightsScaled = scaledADiag.dominantWeights;
diag.scaledNullVectorInterpretation = interpretation_text( ...
    'scaled A', scaledADiag, 'state');

diag.reducedStateNames = reducedNames;
diag.reducedStateIndices = reducedIdx;
diag.reducedRankA = reducedADiag.rank;
diag.reducedNullityA = reducedADiag.nullity;
diag.reducedToleranceA = reducedADiag.tolerance;
diag.reducedEffectiveCondA = reducedADiag.effectiveCondition;
diag.reducedNullspaceRightVectors = ...
    reducedADiag.rightNullspaceVectors;
diag.dominantStatesReducedNullVector = reducedADiag.dominantNames;
diag.dominantStateWeightsReduced = reducedADiag.dominantWeights;
diag.reducedInterpretation = interpretation_text('reduced A', ...
    reducedADiag, 'state');

diag.rankB = Bdiag.rank;
diag.nullityB = Bdiag.nullity;
diag.toleranceB = Bdiag.tolerance;
diag.singularValuesB = Bdiag.singularValues;
diag.nonzeroSingularValuesB = Bdiag.nonzeroSingularValues;
diag.effectiveCondB = Bdiag.effectiveCondition;
diag.controlRightNullspaceVectors = Bdiag.rightNullspaceVectors;
diag.dominantControlsPerNullVector = Bdiag.dominantNames;
diag.dominantControlWeightsPerNullVector = Bdiag.dominantWeights;
diag.controlNullVectorInterpretation = interpretation_text('B', ...
    Bdiag, 'control');

diag.notes = { ...
    'nullspace diagnostics are internal numerical health checks, not validation'; ...
    'dominant entries identify numerical null direction coordinates, not modal interpretations'; ...
    'effective condition ignores singular values at or below the SVD tolerance'; ...
    'reduced-state diagnostics remove structural heading/null columns only for interpretation'};
diag.interpretation = strjoin({diag.nullVectorInterpretation, ...
    diag.scaledNullVectorInterpretation, diag.reducedInterpretation, ...
    diag.controlNullVectorInterpretation, ...
    'not validation/pass-fail criteria'}, '; ');
end

function validate_inputs(A13, B13, stateNames, controlNames)
if ~(isnumeric(A13) && isreal(A13) && all(isfinite(A13(:))))
    error('diagnose_berger13_nullspace:InvalidA', ...
        'A13 must be finite and real.');
end
if ~(isnumeric(B13) && isreal(B13) && all(isfinite(B13(:))))
    error('diagnose_berger13_nullspace:InvalidB', ...
        'B13 must be finite and real.');
end
if size(A13, 1) ~= size(A13, 2)
    error('diagnose_berger13_nullspace:InvalidA', ...
        'A13 must be square.');
end
if size(B13, 1) ~= size(A13, 1)
    error('diagnose_berger13_nullspace:InvalidB', ...
        'B13 row count must match A13.');
end
if numel(stateNames) ~= size(A13, 2)
    error('diagnose_berger13_nullspace:InvalidStateNames', ...
        'stateNames must match A13 size.');
end
if numel(controlNames) ~= size(B13, 2)
    error('diagnose_berger13_nullspace:InvalidControlNames', ...
        'controlNames must match B13 column count.');
end
end

function names = default_names(prefix, n)
names = cell(n, 1);
for k = 1:n
    names{k} = sprintf('%s%d', prefix, k);
end
end

function details = nullspace_diagnostics(M, names)
[~, S, V] = svd(M);
s = diag(S);
tol = singular_tolerance(s, size(M));
rankValue = sum(s > tol);
nullity = size(M, 2) - rankValue;
if nullity > 0
    nullVectors = V(:, rankValue+1:end);
else
    nullVectors = zeros(size(M, 2), 0);
end
nonzeroSingular = s(s > tol);

details.singularValues = s;
details.tolerance = tol;
details.rank = rankValue;
details.nullity = nullity;
details.nonzeroSingularValues = nonzeroSingular;
details.effectiveCondition = effective_condition(nonzeroSingular);
details.rightNullspaceVectors = nullVectors;
[details.dominantNames, details.dominantWeights] = ...
    dominant_entries(nullVectors, names);
end

function tol = singular_tolerance(s, matrixSize)
if isempty(s)
    sigmaMax = 0;
else
    sigmaMax = max(s);
end
tol = max(matrixSize)*eps(max(sigmaMax, 1));
end

function value = effective_condition(nonzeroSingular)
if isempty(nonzeroSingular)
    value = Inf;
else
    value = max(nonzeroSingular)/min(nonzeroSingular);
end
end

function [dominantNames, dominantWeights] = dominant_entries(vectors, names)
nVec = size(vectors, 2);
dominantNames = cell(nVec, 1);
dominantWeights = cell(nVec, 1);
for k = 1:nVec
    vector = vectors(:, k);
    [weights, idx] = sort(abs(vector), 'descend');
    keep = min(5, numel(idx));
    dominantNames{k} = names(idx(1:keep));
    dominantWeights{k} = weights(1:keep);
end
end

function text = interpretation_text(label, details, coordinateLabel)
if details.nullity == 0
    text = sprintf('%s has no numerical null direction above tolerance', ...
        label);
    return;
end
summary = dominant_summary(details.dominantNames, ...
    details.dominantWeights);
text = sprintf(['%s has %d linearized nullspace direction(s); ', ...
    'dominant %s coordinates: %s'], label, details.nullity, ...
    coordinateLabel, summary);
end

function text = dominant_summary(namesPerVector, weightsPerVector)
if isempty(namesPerVector)
    text = 'none';
    return;
end
parts = cell(numel(namesPerVector), 1);
for k = 1:numel(namesPerVector)
    names = namesPerVector{k};
    weights = weightsPerVector{k};
    entries = cell(numel(names), 1);
    for j = 1:numel(names)
        entries{j} = sprintf('%s=%.3g', names{j}, weights(j));
    end
    parts{k} = sprintf('v%d:%s', k, strjoin(entries(:).', '|'));
end
text = strjoin(parts(:).', '; ');
end

function scaledA = scaled_matrix(A13, stateNames, conditioningDiag)
if isstruct(conditioningDiag) && isfield(conditioningDiag, 'scaled') && ...
        isfield(conditioningDiag.scaled, 'scaledA')
    scaledA = conditioningDiag.scaled.scaledA;
    return;
end
stateScale = default_state_scale(stateNames);
scaledA = bsxfun(@rdivide, bsxfun(@times, A13, stateScale.'), ...
    stateScale);
end

function scale = default_state_scale(stateNames)
n = numel(stateNames);
scale = ones(n, 1);
for k = 1:n
    if any(strcmp(stateNames{k}, {'u', 'v', 'w'}))
        scale(k) = 100;
    end
end
end

function [reducedA, reducedIdx] = reduced_state_matrix(A13, stateNames, ...
    conditioningDiag)
if isstruct(conditioningDiag) && isfield(conditioningDiag, 'dynamic') && ...
        isfield(conditioningDiag.dynamic, 'dynamicIdx')
    reducedIdx = conditioningDiag.dynamic.dynamicIdx(:);
else
    zeroColumnIdx = find_column_indices(A13, zero_tolerance(A13));
    psiIdx = find(strcmp(stateNames, 'psi'));
    if isempty(psiIdx) && numel(stateNames) >= 9
        psiIdx = 9;
    end
    reducedIdx = setdiff((1:numel(stateNames)).', ...
        unique([psiIdx(:); zeroColumnIdx(:)]));
end
if isempty(reducedIdx)
    reducedIdx = (1:numel(stateNames)).';
end
reducedA = A13(reducedIdx, reducedIdx);
end

function tol = zero_tolerance(M)
tol = max(1, norm(M, 'fro'))*1e-12;
end

function indices = find_column_indices(M, tol)
norms = sqrt(sum(M.^2, 1)).';
indices = find(norms <= tol);
end
