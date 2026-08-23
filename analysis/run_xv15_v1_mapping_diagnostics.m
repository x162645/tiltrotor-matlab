function results = run_xv15_v1_mapping_diagnostics(testPoint, sourceData, outputDir)
%RUN_XV15_V1_MAPPING_DIAGNOSTICS Audit the V1 low-order mapping itself.
%
% This function deliberately does NOT read or compare TM-86833 hold-out
% performance curves.  It only verifies the transformation from explicit
% XV-15/test inputs into the program fields used by the frozen low-order
% model, and exports the associated reduction/readiness diagnostics.

rootDir = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1 || isempty(testPoint)
    testPoint = struct();
end
if nargin < 2 || isempty(sourceData)
    sourceData = struct();
end
if nargin < 3 || isempty(outputDir)
    outputDir = fullfile(rootDir, 'results', 'xv15_v1_mapping');
end
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

Pbase = params_nominal();
[P, mapping] = build_xv15_v1_hover_validation_instance( ...
    Pbase, testPoint, sourceData);

%% Chord reduction diagnostic.
chordTable = table(mapping.chord.rR(:), mapping.chord.chord_m(:), ...
    repmat(mapping.chord.chordEq_m, numel(mapping.chord.rR), 1), ...
    'VariableNames', {'r_over_R','sourceChord_m','equivalentChord_m'});
writetable(chordTable, fullfile(outputDir, 'V1_CHORD_REDUCTION.csv'));

%% Twist reduction diagnostic, only when source stations were supplied.
if mapping.twist.available
    twistTable = table(mapping.twist.rR(:), ...
        mapping.twist.thetaSource_rad(:), ...
        mapping.twist.thetaFit_rad(:), ...
        mapping.twist.residual_rad(:), ...
        mapping.twist.weights(:), ...
        'VariableNames', {'r_over_R','thetaSource_rad','thetaFit_rad', ...
        'residual_rad','weight'});
    writetable(twistTable, fullfile(outputDir, 'V1_TWIST_REDUCTION.csv'));
else
    twistTable = table();
end

%% Readiness contract.
readinessNames = fieldnames(mapping.readiness);
readinessValues = false(numel(readinessNames),1);
for k = 1:numel(readinessNames)
    readinessValues(k) = logical(mapping.readiness.(readinessNames{k}));
end
readinessTable = table(readinessNames, readinessValues, ...
    'VariableNames', {'criterion','satisfied'});
writetable(readinessTable, fullfile(outputDir, 'V1_READINESS.csv'));

%% Applied fields: compare the builder output to the untouched generic base.
appliedPaths = mapping.appliedPaths(:);
baseValue = cell(size(appliedPaths));
mappedValue = cell(size(appliedPaths));
for k = 1:numel(appliedPaths)
    baseValue{k} = value_to_text(get_nested_value(Pbase, appliedPaths{k}));
    mappedValue{k} = value_to_text(get_nested_value(P, appliedPaths{k}));
end
appliedTable = table(appliedPaths, baseValue, mappedValue, ...
    'VariableNames', {'parameterPath','genericValue','mappedValue'});
writetable(appliedTable, fullfile(outputDir, 'V1_APPLIED_PARAMETER_DIFF.csv'));

%% Scalar mapping summary.
summary = struct();
summary.variantName = mapping.variantName;
summary.readyForMappingDiagnostics = mapping.readiness.readyForMappingDiagnostics;
summary.readyForHoldout = mapping.readiness.readyForHoldout;
summary.chordEq_m = mapping.chord.chordEq_m;
summary.chordAreaRelativeResidual = mapping.chord.relativeAreaResidual;
summary.twistAvailable = mapping.twist.available;
summary.twistTipEq_rad = mapping.twist.twistTipEq_rad;
summary.twistRmsResidual_rad = mapping.twist.rmsResidual_rad;
summary.twistMaxAbsResidual_rad = mapping.twist.maxAbsResidual_rad;
summary.theta75Available = mapping.collective.theta75Available;
summary.modelCollective_rad = mapping.collective.modelCollective_rad;
summary.collectiveReconstructionError_rad = ...
    mapping.collective.reconstructionError_rad;
summary.sectionAeroAvailable = mapping.sectionAero.available;
summary.flapMassClosed = mapping.flapMass.closed;
summary.rpmExplicit = mapping.testCondition.rpmExplicit;
summary.rhoExplicit = mapping.testCondition.rhoExplicit;
summary.blockingIssueCount = numel(mapping.blockingIssues);
summaryTable = struct2table(summary);
writetable(summaryTable, fullfile(outputDir, 'V1_MAPPING_SUMMARY.csv'));

%% Blocking issues are exported explicitly, never silently filled.
if isempty(mapping.blockingIssues)
    blockingTable = table(cell(0,1), 'VariableNames', {'blockingIssue'});
else
    blockingTable = table(mapping.blockingIssues(:), ...
        'VariableNames', {'blockingIssue'});
end
writetable(blockingTable, fullfile(outputDir, 'V1_BLOCKING_ISSUES.csv'));

%% Human-readable audit note.
fid = fopen(fullfile(outputDir, 'V1_MAPPING_AUDIT.md'), 'w');
if fid < 0
    error('run_xv15_v1_mapping_diagnostics:OutputOpenFailed', ...
        'Could not create V1_MAPPING_AUDIT.md.');
end
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '# XV-15 V1 validation mapping audit\n\n');
fprintf(fid, ['This artifact audits the mapping into the generic low-order ' ...
    'program parameters. It does not consume TM-86833 hold-out performance ' ...
    'curves and is not external validation.\n\n']);
fprintf(fid, '- Variant: `%s`\n', mapping.variantName);
fprintf(fid, '- Ready for mapping diagnostics: %d\n', ...
    mapping.readiness.readyForMappingDiagnostics);
fprintf(fid, '- Ready for hold-out validation: %d\n', ...
    mapping.readiness.readyForHoldout);
fprintf(fid, '- Area-equivalent chord: %.12g m\n', mapping.chord.chordEq_m);
fprintf(fid, '- Chord relative area residual: %.3e\n', ...
    mapping.chord.relativeAreaResidual);
fprintf(fid, '- Twist reconstruction available: %d\n', mapping.twist.available);
fprintf(fid, '- Section-aero reconstruction available: %d\n', ...
    mapping.sectionAero.available);
fprintf(fid, '- Ib/Sblade closure available: %d\n\n', mapping.flapMass.closed);
if ~isempty(mapping.blockingIssues)
    fprintf(fid, '## Blocking issues\n\n');
    for k = 1:numel(mapping.blockingIssues)
        fprintf(fid, '- `%s`\n', mapping.blockingIssues{k});
    end
end

results = struct();
results.parameterSet = P;
results.mapping = mapping;
results.chordTable = chordTable;
results.twistTable = twistTable;
results.readinessTable = readinessTable;
results.appliedTable = appliedTable;
results.summaryTable = summaryTable;
results.blockingTable = blockingTable;
results.claimBoundary = 'MAPPING_DIAGNOSTICS_ONLY_NO_HOLDOUT_DATA_CONSUMED';
end

function value = get_nested_value(S, path)
parts = strsplit(path, '.');
value = S;
for k = 1:numel(parts)
    if ~isstruct(value) || ~isfield(value, parts{k})
        value = [];
        return;
    end
    value = value.(parts{k});
end
end

function text = value_to_text(value)
if isempty(value)
    text = '<missing>';
elseif isnumeric(value) || islogical(value)
    text = mat2str(value, 15);
elseif ischar(value)
    text = value;
else
    text = sprintf('<%s>', class(value));
end
end
