function [P, manifest] = apply_xv15_public_overlay(Pbase)
%APPLY_XV15_PUBLIC_OVERLAY Apply only audited public XV-15 records.
% The caller must opt in explicitly.  Unlisted fields are inherited from
% Pbase and are not reclassified as XV-15 parameters.

if nargin < 1 || isempty(Pbase)
    Pbase = params_nominal();
end
if ~isstruct(Pbase) || ~isscalar(Pbase)
    error('apply_xv15_public_overlay:InvalidBase', ...
        'Pbase must be a scalar parameter structure.');
end

P = Pbase;
reference = params_xv15_public_reference();
records = reference.records;
for k = 1:numel(records)
    if records(k).applyToModel
        P = set_record_value(P,records(k));
    end
end

manifest.variantName = 'GENERIC_MODEL_WITH_XV15_PUBLIC_OVERLAY';
manifest.parentVariant = 'PARAMS_NOMINAL_GENERIC_BASELINE';
manifest.creationMethod = reference.creationMethod;
manifest.sourceManifest = reference.sourceManifest;
manifest.records = records;
manifest.modifiedPaths = unique({records([records.applyToModel]).path}.', ...
    'stable');
manifest.inheritedFieldLabel = 'INHERITED_GENERIC_NOT_XV15';
manifest.claimBoundary = reference.claimBoundary;
manifest.optimizedFields = {};
manifest.fixedFields = {'all fields absent from records'};
manifest.objectiveDefinition = 'NONE_NOT_OPTIMIZED';
manifest.calibrationSetID = 'NONE';
manifest.validationSetID = 'NONE';
manifest.parameterBoundsID = 'PRIMARY_SOURCE_VALUES_ONLY';
manifest.codeSHA = 'SET_AT_RESULT_GENERATION';
manifest.resultSHA = 'SET_AT_RESULT_GENERATION';
end

function S = set_record_value(S,record)
parts = strsplit(record.path,'.');
if numel(parts) ~= 2 || ~isfield(S,parts{1}) || ...
        ~isfield(S.(parts{1}),parts{2})
    error('apply_xv15_public_overlay:UnknownPath', ...
        'Overlay path %s is absent from the supplied base.',record.path);
end
value = S.(parts{1}).(parts{2});
if isempty(record.subscripts)
    value = record.valueSI;
else
    if numel(record.subscripts) ~= 2
        error('apply_xv15_public_overlay:InvalidSubscript', ...
            'Only two-dimensional numeric subscripts are supported.');
    end
    value(record.subscripts(1),record.subscripts(2)) = record.valueSI;
end
S.(parts{1}).(parts{2}) = value;
end
