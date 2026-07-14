function diag = diagnose_berger13_conditioning(A13, B13, stateNames, controlNames)
%DIAGNOSE_BERGER13_CONDITIONING Internal conditioning diagnostics for 13x10.
% This helper reports raw, scaled, and dynamic-submatrix SVD/rank metrics.
% It does not alter A13/B13 and does not represent external validation.

if nargin < 3 || isempty(stateNames)
    stateNames = default_names('x', size(A13, 2));
end
if nargin < 4 || isempty(controlNames)
    controlNames = default_names('u', size(B13, 2));
end
validate_inputs(A13, B13, stateNames, controlNames);

stateScale = default_state_scale(stateNames);
scaledA = scale_state_matrix(A13, stateScale);
zeroColumnTolA = zero_tolerance(A13);
zeroRowTolA = zeroColumnTolA;
zeroColumnIndicesA = find_column_indices(A13, zeroColumnTolA);
zeroRowIndicesA = find_row_indices(A13, zeroRowTolA);
dynamicIdx = dynamic_indices(stateNames, zeroColumnIndicesA);

rawA = matrix_diagnostics(A13);
scaledADiag = matrix_diagnostics(scaledA);
dynamicA = A13(dynamicIdx, dynamicIdx);
scaledDynamicA = scaledA(dynamicIdx, dynamicIdx);
dynamicADiag = matrix_diagnostics(dynamicA);
scaledDynamicADiag = matrix_diagnostics(scaledDynamicA);

controlColumnNorms = column_norms(B13);
controlColumnTol = zero_tolerance(B13);
nearZeroControlColumns = find(controlColumnNorms <= controlColumnTol);
activeControlColumns = find(controlColumnNorms > controlColumnTol);

diag.raw.rankA = rawA.rank;
diag.raw.singularValuesA = rawA.singularValues;
diag.raw.minSingularA = rawA.minSingular;
diag.raw.maxSingularA = rawA.maxSingular;
diag.raw.rawCondA = rawA.conditionNumber;
diag.raw.nearZeroSingularCount = rawA.nearZeroSingularCount;
diag.raw.zeroColumnIndicesA = zeroColumnIndicesA(:);
diag.raw.zeroColumnNamesA = names_by_index(stateNames, zeroColumnIndicesA);
diag.raw.zeroRowIndicesA = zeroRowIndicesA(:);
diag.raw.zeroRowNamesA = names_by_index(stateNames, zeroRowIndicesA);

diag.scaled.stateScale = stateScale;
diag.scaled.scaledA = scaledA;
diag.scaled.rankScaledA = scaledADiag.rank;
diag.scaled.singularValuesScaledA = scaledADiag.singularValues;
diag.scaled.minSingularScaledA = scaledADiag.minSingular;
diag.scaled.maxSingularScaledA = scaledADiag.maxSingular;
diag.scaled.scaledCondA = scaledADiag.conditionNumber;
diag.scaled.nearZeroSingularCountScaled = ...
    scaledADiag.nearZeroSingularCount;

diag.dynamic.dynamicIdx = dynamicIdx(:);
diag.dynamic.dynamicNames = names_by_index(stateNames, dynamicIdx);
diag.dynamic.rankADynamic = dynamicADiag.rank;
diag.dynamic.condADynamic = dynamicADiag.conditionNumber;
diag.dynamic.rankScaledADynamic = scaledDynamicADiag.rank;
diag.dynamic.condScaledADynamic = ...
    scaledDynamicADiag.conditionNumber;
diag.dynamic.singularValuesADynamic = dynamicADiag.singularValues;
diag.dynamic.singularValuesScaledADynamic = ...
    scaledDynamicADiag.singularValues;

diag.B.rankB = rank(B13);
diag.B.controlColumnNorms = controlColumnNorms;
diag.B.nearZeroControlColumns = nearZeroControlColumns(:);
diag.B.nearZeroControlColumnNames = ...
    names_by_index(controlNames, nearZeroControlColumns);
diag.B.activeControlColumns = activeControlColumns(:);
diag.B.activeControlColumnNames = ...
    names_by_index(controlNames, activeControlColumns);

diag.notes = diagnostic_notes(diag);
diag.interpretation = interpretation_text(diag);
end

function validate_inputs(A13, B13, stateNames, controlNames)
if ~(isnumeric(A13) && isreal(A13) && all(isfinite(A13(:))))
    error('diagnose_berger13_conditioning:InvalidA', ...
        'A13 must be finite and real.');
end
if ~(isnumeric(B13) && isreal(B13) && all(isfinite(B13(:))))
    error('diagnose_berger13_conditioning:InvalidB', ...
        'B13 must be finite and real.');
end
if size(A13, 1) ~= size(A13, 2)
    error('diagnose_berger13_conditioning:InvalidA', ...
        'A13 must be square.');
end
if size(B13, 1) ~= size(A13, 1)
    error('diagnose_berger13_conditioning:InvalidB', ...
        'B13 row count must match A13.');
end
if numel(stateNames) ~= size(A13, 1)
    error('diagnose_berger13_conditioning:InvalidStateNames', ...
        'stateNames must match A13 size.');
end
if numel(controlNames) ~= size(B13, 2)
    error('diagnose_berger13_conditioning:InvalidControlNames', ...
        'controlNames must match B13 column count.');
end
end

function names = default_names(prefix, n)
names = cell(n, 1);
for k = 1:n
    names{k} = sprintf('%s%d', prefix, k);
end
end

function scale = default_state_scale(stateNames)
n = numel(stateNames);
scale = ones(n, 1);
for k = 1:n
    name = stateNames{k};
    if any(strcmp(name, {'u', 'v', 'w'}))
        scale(k) = 100;
    else
        scale(k) = 1;
    end
end
if any(~isfinite(scale)) || any(scale <= 0)
    error('diagnose_berger13_conditioning:InvalidScale', ...
        'State scale values must be positive and finite.');
end
end

function scaledA = scale_state_matrix(A, stateScale)
scaledA = bsxfun(@rdivide, bsxfun(@times, A, stateScale.'), stateScale);
end

function details = matrix_diagnostics(M)
s = svd(M);
details.singularValues = s;
if isempty(s)
    details.minSingular = NaN;
    details.maxSingular = NaN;
    details.conditionNumber = NaN;
    details.rank = 0;
    details.nearZeroSingularCount = 0;
    return;
end
details.minSingular = min(s);
details.maxSingular = max(s);
if details.minSingular == 0
    details.conditionNumber = Inf;
else
    details.conditionNumber = details.maxSingular/details.minSingular;
end
tol = singular_tolerance(s, size(M));
details.rank = rank(M);
details.nearZeroSingularCount = sum(s <= tol);
end

function tol = singular_tolerance(s, matrixSize)
sigmaMax = max(s);
tol = max(matrixSize)*eps(max(sigmaMax, 1));
end

function tol = zero_tolerance(M)
tol = max(1, norm(M, 'fro'))*1e-12;
end

function indices = find_column_indices(M, tol)
norms = column_norms(M);
indices = find(norms <= tol);
end

function indices = find_row_indices(M, tol)
norms = sqrt(sum(M.^2, 2));
indices = find(norms <= tol);
end

function norms = column_norms(M)
norms = sqrt(sum(M.^2, 1)).';
end

function idx = dynamic_indices(stateNames, zeroColumnIndices)
psiIdx = find(strcmp(stateNames, 'psi'));
if isempty(psiIdx) && numel(stateNames) >= 9
    psiIdx = 9;
end
removeIdx = unique([psiIdx(:); zeroColumnIndices(:)]);
idx = setdiff((1:numel(stateNames)).', removeIdx);
if isempty(idx)
    idx = (1:numel(stateNames)).';
end
end

function names = names_by_index(allNames, indices)
indices = indices(:);
names = cell(numel(indices), 1);
for k = 1:numel(indices)
    names{k} = allNames{indices(k)};
end
end

function notes = diagnostic_notes(diag)
notes = { ...
    'scaled diagnostics are internal numerical health checks, not validation'; ...
    'raw severe condition can be structural when heading invariance creates null columns'; ...
    'finite operating points are not trim-envelope or handling-quality criteria'};
if any(strcmp(diag.raw.zeroColumnNamesA, 'psi'))
    notes{end+1,1} = ...
        'psi column is zero, consistent with heading invariance in this state set';
end
if ~isempty(diag.B.nearZeroControlColumns)
    notes{end+1,1} = ...
        'one or more B control columns are near zero under this diagnostic tolerance';
end
end

function text = interpretation_text(diag)
parts = {};
if isinf(diag.raw.rawCondA)
    parts{end+1} = 'raw A is structurally singular';
elseif diag.raw.rawCondA > 1e6
    parts{end+1} = 'raw A condition is severe';
else
    parts{end+1} = 'raw A condition is finite';
end
if any(strcmp(diag.raw.zeroColumnNamesA, 'psi'))
    parts{end+1} = 'psi is a zero column';
end
if isinf(diag.scaled.scaledCondA)
    parts{end+1} = 'scaled A remains structurally singular';
else
    parts{end+1} = 'scaled A condition is finite';
end
if isinf(diag.dynamic.condScaledADynamic)
    parts{end+1} = 'scaled dynamic submatrix remains singular';
else
    parts{end+1} = 'scaled dynamic submatrix has finite condition';
end
parts{end+1} = 'diagnostics do not change validation/pass-fail criteria';
text = strjoin(parts, '; ');
end
