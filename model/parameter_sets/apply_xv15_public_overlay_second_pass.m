function [P, manifest] = apply_xv15_public_overlay_second_pass(Pbase)
%APPLY_XV15_PUBLIC_OVERLAY_SECOND_PASS Apply only semantically homologous data.
% The legacy PR #53 overlay is preserved for reproducibility.  This V2
% variant deliberately blocks legacy scalar substitutions that are known to
% compress configuration-dependent or radial XV-15 data into incompatible
% model fields: rotor.Omega, rotor.chord, and rotor.twistTip.

if nargin < 1 || isempty(Pbase)
    Pbase = params_nominal();
end
if ~isstruct(Pbase) || ~isscalar(Pbase)
    error('apply_xv15_public_overlay_second_pass:InvalidBase', ...
        'Pbase must be a scalar parameter structure.');
end

P = Pbase;
legacy = params_xv15_public_reference();
secondPass = params_xv15_public_reference_second_pass();
blockedLegacyPaths = {'rotor.Omega','rotor.chord','rotor.twistTip'};

legacyApplied = repmat(struct('path','','subscripts',[]),0,1);
for k = 1:numel(legacy.records)
    r = legacy.records(k);
    if r.applyToModel && ~ismember(r.path,blockedLegacyPaths)
        P = set_record_value(P,r.path,r.subscripts,r.valueSI);
        legacyApplied(end+1,1) = struct('path',r.path, ...
            'subscripts',r.subscripts); %#ok<AGROW>
    end
end

secondApplied = repmat(struct('path','','subscripts',[]),0,1);
for k = 1:numel(secondPass.records)
    r = secondPass.records(k);
    if r.applyToModel
        P = set_record_value(P,r.path,r.subscripts,r.valueSI);
        secondApplied(end+1,1) = struct('path',r.path, ...
            'subscripts',r.subscripts); %#ok<AGROW>
    end
end

legacyPaths = {legacyApplied.path}.';
secondPaths = {secondApplied.path}.';
manifest.variantName = 'GENERIC_MODEL_WITH_XV15_PUBLIC_OVERLAY_V2';
manifest.parentVariant = 'PARAMS_NOMINAL_GENERIC_BASELINE';
manifest.legacyReference = legacy.variantName;
manifest.secondPassReference = secondPass.variantName;
manifest.modifiedPaths = unique([legacyPaths;secondPaths],'stable');
manifest.blockedLegacyPaths = blockedLegacyPaths(:);
manifest.blockReasons = { ...
    'rotor.Omega: XV-15 uses documented 565/534/458 rpm mode schedule; scalar global substitution is non-homologous'; ...
    'rotor.chord: XV-15 root cuff is 17 in at 0.0875R and tapers to 14 in at 0.25R; scalar constant chord is non-homologous'; ...
    'rotor.twistTip: XV-15 total twist is about -45 deg with a non-linear radial distribution; current field imposes linear twist'};
manifest.secondPassRecords = secondPass.records;
manifest.sourceManifest = unique([legacy.sourceManifest(:); ...
    secondPass.sourceManifest(:)],'stable');
manifest.inheritedFieldLabel = 'INHERITED_GENERIC_OR_INTERFACE_BLOCKED_NOT_XV15';
manifest.claimBoundary = [ ...
    'V2 applies only source-backed fields whose semantics match the active ' ...
    'low-order model. Configuration schedules, radial geometry, nonlinear ' ...
    'twist, missing rotor physics, and GTRS aerodynamic tables remain ' ...
    'explicitly unapplied until the model interface is extended.'];
end

function S = set_record_value(S,path,subscripts,valueSI)
parts = strsplit(path,'.');
if numel(parts) ~= 2 || ~isfield(S,parts{1}) || ...
        ~isfield(S.(parts{1}),parts{2})
    error('apply_xv15_public_overlay_second_pass:UnknownPath', ...
        'Overlay path %s is absent from the supplied base.',path);
end
value = S.(parts{1}).(parts{2});
if isempty(subscripts)
    value = valueSI;
else
    if numel(subscripts) ~= 2
        error('apply_xv15_public_overlay_second_pass:InvalidSubscript', ...
            'Only two-dimensional numeric subscripts are supported.');
    end
    value(subscripts(1),subscripts(2)) = valueSI;
end
S.(parts{1}).(parts{2}) = value;
end
