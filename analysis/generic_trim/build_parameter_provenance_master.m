function T = build_parameter_provenance_master()
%BUILD_PARAMETER_PROVENANCE_MASTER Audit active/default and overlay fields.
% One row represents one declared leaf field.  Matrix-valued fields retain
% their shape in currentValue; overlay element records are listed separately.

P = params_nominal();
P13 = params_berger13();
reference = params_xv15_public_reference();

rows = repmat(empty_row(),0,1);
baseLeaves = flatten_struct(P,'');
for k = 1:numel(baseLeaves)
    rows(end+1) = classify_baseline(baseLeaves(k),reference.records); %#ok<AGROW>
end

berger = rmfield(P13,'base');
bergerLeaves = flatten_struct(berger,'');
for k = 1:numel(bergerLeaves)
    rows(end+1) = classify_berger13(bergerLeaves(k)); %#ok<AGROW>
end

for k = 1:numel(reference.records)
    rows(end+1) = overlay_row(reference.records(k),P); %#ok<AGROW>
end

T = struct2table(rows);
T.parameterId = strcat('PAR-',compose('%04d',(1:height(T)).'));
T = movevars(T,'parameterId','Before',1);
end

function row = classify_baseline(leaf,overlayRecords)
row = empty_row();
row.parameterSet = 'PARAMS_NOMINAL_GENERIC_BASELINE';
row.parameterName = leaf.path;
row.codePath = ['params_nominal.',leaf.path];
row.currentValue = value_string(leaf.value);
row.unitSI = infer_unit(leaf.path);
row.roleClass = infer_role(leaf.path);
row.originalSource = 'params_nominal.m and repository audit history';
row.sourceLocation = 'code declaration; no direct aircraft provenance';
row.originalValueUnit = [row.currentValue,' ',row.unitSI];
row.conversion = 'none (current code value)';
row.finalModel = true;
row.manualReview = true;

if is_numerical(leaf.path)
    row.sourceClass = 'ASSUMED_MODEL_PARAMETER';
    row.claimClass = 'NUMERICAL_ONLY';
    row.roleClass = numerical_role(leaf.path);
    row.note = 'Numerical method, discretization, tolerance, or analysis guard.';
    row.manualReview = false;
elseif is_calibrated(leaf.path)
    row.sourceClass = 'ASSUMED_MODEL_PARAMETER';
    row.claimClass = 'CALIBRATED_EFFECTIVE';
    row.note = ['Project effective parameter retained from prior bounded ' ...
        'trim-trend correction; not a measured component value.'];
elseif is_derived(leaf.path)
    row.sourceClass = 'DERIVED';
    row.claimClass = 'GENERIC_ASSUMED';
    row.note = 'Derived from declared generic assumptions in params_nominal.m.';
elseif is_deprecated(leaf.path)
    row.sourceClass = 'ASSUMED_MODEL_PARAMETER';
    row.claimClass = 'NUMERICAL_ONLY';
    row.note = 'Deprecated or compatibility metadata; not active production physics.';
else
    row.sourceClass = 'ASSUMED_MODEL_PARAMETER';
    row.claimClass = 'GENERIC_ASSUMED';
    row.note = 'Generic conceptual-model value without verified aircraft provenance.';
end

matches = find(strcmp({overlayRecords.path},leaf.path));
if ~isempty(matches)
    row.claimClass = 'XV15_LIKE_UNVERIFIED';
    row.xv15PublicValue = overlay_value_string(overlayRecords(matches));
    row.xv15DifferencePercent = comparison_percent(leaf.value, ...
        overlayRecords(matches));
    row.note = [row.note,' A public XV-15 comparison exists, but the ' ...
        'current value is not historically traced to that source.'];
end

[row.optimizable,row.lowerBound,row.upperBound] = design_bounds(leaf.path);
row.sensitivityIncluded = row.optimizable;
end

function row = classify_berger13(leaf)
row = empty_row();
row.parameterSet = 'BERGER13_RESEARCH_EXTENSION';
row.parameterName = leaf.path;
row.codePath = ['params_berger13.',leaf.path];
row.currentValue = value_string(leaf.value);
row.unitSI = infer_unit(leaf.path);
row.roleClass = infer_role(leaf.path);
row.originalSource = 'model/berger13/params_berger13.m';
row.sourceLocation = 'explicit namespace-local declaration';
row.originalValueUnit = [row.currentValue,' ',row.unitSI];
row.conversion = 'none (current code value)';
row.finalModel = true;
row.manualReview = true;
if contains(leaf.path,'parameterSource') || contains(leaf.path,'meta.') || ...
        contains(leaf.path,'mechanics.')
    row.sourceClass = 'ASSUMED_MODEL_PARAMETER';
    row.claimClass = 'NUMERICAL_ONLY';
    row.note = 'Metadata, implementation flag, or claim-boundary field.';
elseif contains(leaf.path,'nacelle.') || contains(leaf.path,'commandActuator.')
    row.sourceClass = 'RESEARCH_PLACEHOLDER';
    row.claimClass = 'GENERIC_ASSUMED';
    row.note = 'Explicit Berger13 research placeholder; not Berger or XV-15 data.';
elseif contains(leaf.path,'movingComponents.')
    row.sourceClass = 'DERIVED';
    row.claimClass = 'GENERIC_ASSUMED';
    row.note = 'Derived split or inherited generic moving-component assumption.';
elseif contains(leaf.path,'linear')
    row.sourceClass = 'ASSUMED_MODEL_PARAMETER';
    row.claimClass = 'NUMERICAL_ONLY';
    row.roleClass = 'NUMERICAL';
    row.note = 'Numerical differentiation metadata.';
    row.manualReview = false;
else
    row.sourceClass = 'ASSUMED_MODEL_PARAMETER';
    row.claimClass = 'GENERIC_ASSUMED';
    row.note = 'Namespace-local generic research assumption.';
end
end

function row = overlay_row(record,P)
row = empty_row();
row.parameterSet = 'XV15_PUBLIC_REFERENCE_PARTIAL';
row.parameterName = record.path;
row.codePath = ['overlay.',record.path,subscript_string(record.subscripts)];
row.currentValue = value_string(record.valueSI);
row.unitSI = record.unitSI;
if strcmp(record.claimClass,'XV15_DERIVED')
    row.sourceClass = 'DERIVED';
else
    row.sourceClass = 'REFERENCE';
end
row.claimClass = record.claimClass;
row.roleClass = record.roleClass;
row.originalSource = sprintf('%s; %s; %s; %d; local file %s', ...
    record.sourceTitle,record.reportNumber,record.authors, ...
    record.publicationYear,record.sourceFile);
row.sourceLocation = sprintf('PDF %d; printed %d; %s', ...
    record.pdfPage,record.printedPage,record.locator);
row.originalValueUnit = [record.originalValue,' ',record.originalUnit];
row.conversion = record.conversion;
row.xv15PublicValue = row.currentValue;
row.xv15DifferencePercent = baseline_difference(P,record);
row.optimizable = false;
row.lowerBound = '';
row.upperBound = '';
row.sensitivityIncluded = false;
row.finalModel = record.applyToModel;
row.manualReview = record.manualReview;
row.note = [record.applicableConfiguration,'; ',record.note];
end

function leaves = flatten_struct(S,prefix)
leaves = repmat(struct('path','','value',[]),0,1);
names = fieldnames(S);
for k = 1:numel(names)
    name = names{k};
    if isempty(prefix), path = name; else, path = [prefix,'.',name]; end
    value = S.(name);
    if isstruct(value) && isscalar(value)
        child = flatten_struct(value,path);
        leaves = [leaves;child]; %#ok<AGROW>
    elseif isnumeric(value) || islogical(value) || ischar(value) || isstring(value)
        leaves(end+1,1) = struct('path',path,'value',value); %#ok<AGROW>
    end
end
end

function row = empty_row()
row = struct('parameterSet','','parameterName','','codePath','', ...
    'currentValue','','unitSI','','sourceClass','','claimClass','', ...
    'roleClass','','originalSource','','sourceLocation','', ...
    'originalValueUnit','','conversion','','xv15PublicValue','', ...
    'xv15DifferencePercent',NaN,'optimizable',false, ...
    'lowerBound','','upperBound','','sensitivityIncluded',false, ...
    'finalModel',false,'manualReview',true,'note','');
end

function text = value_string(value)
if ischar(value)
    text = value;
elseif isstring(value)
    text = char(value);
elseif islogical(value)
    text = mat2str(value);
else
    text = mat2str(value,12);
end
end

function text = subscript_string(subscripts)
if isempty(subscripts)
    text = '';
else
    text = sprintf('(%d,%d)',subscripts(1),subscripts(2));
end
end

function unit = infer_unit(path)
if contains(path,'incidence') || contains(path,'twist') || ...
        contains(path,'Lim') && ~contains(path,'torque') || ...
        contains(path,'flapMax') || contains(path,'flapDivergence') || ...
        contains(path,'betaMin') || contains(path,'betaMax') || ...
        contains(path,'frozenCommand')
    unit = 'rad';
elseif contains(path,'I0') || contains(path,'KI') || contains(path,'Ib')
    unit = 'kg m^2';
elseif endsWith(path,'.m') || contains(path,'mass') && ~contains(path,'Distribution')
    unit = 'kg';
elseif contains(path,'Omega') || contains(path,'omegaN')
    unit = 'rad/s';
elseif contains(path,'torque')
    unit = 'N m';
elseif contains(path,'S') && ~contains(path,'Slope') && ...
        ~contains(path,'Scale') && ~contains(path,'Source')
    unit = 'm^2';
elseif contains(path,'R') || contains(path,'chord') || contains(path,'.b') || ...
        contains(path,'.c') || contains(path,'pivot') || contains(path,'AC')
    unit = 'm';
elseif contains(path,'rho')
    unit = 'kg/m^3';
elseif endsWith(path,'.g')
    unit = 'm/s^2';
else
    unit = '1';
end
end

function role = infer_role(path)
top = regexp(path,'^[^.]+','match','once');
switch top
    case 'mass', role = 'MASS';
    case 'rotor', role = 'ROTOR_AERO';
    case 'wing', role = 'WING_AERO';
    case 'htail', role = 'TAIL_AERO';
    case 'vtail', role = 'TAIL_AERO';
    case 'fuselage', role = 'FUSELAGE_AERO';
    case 'control', role = 'CONTROL_LIMIT';
    case 'env', role = 'ANALYSIS_GUARD';
    case {'trim','linear'}, role = 'NUMERICAL';
    case 'nacelle', role = 'ACTUATOR';
    case 'commandActuator', role = 'ACTUATOR';
    otherwise, role = 'ANALYSIS_GUARD';
end
end

function role = numerical_role(path)
if startsWith(path,'trim.') || startsWith(path,'linear.')
    role = 'NUMERICAL';
else
    role = 'ANALYSIS_GUARD';
end
end

function tf = is_numerical(path)
tokens = {'nRadial','nAzimuth','inducedMaxIter','inducedRelax', ...
    'inducedTol','flapInitial','flapResidualTol','flapMaxIter', ...
    'flapJacobianStep','flapNewtonDamping','flapNewtonRegularization', ...
    'flapLineSearchMaxIter','flapDivergenceAngle','trim.','linear.'};
tf = any(cellfun(@(x) contains(path,x),tokens));
end

function tf = is_calibrated(path)
tf = any(strcmp(path,{'wing.Cm0','htail.incidence', ...
    'htail.downwashAlpha','htail.CLelevator'}));
end

function tf = is_derived(path)
tf = any(strcmp(path,{'mass.RH','rotor.Ib','rotor.Sblade'}));
end

function tf = is_deprecated(path)
tokens = {'inflowHarmonic','flapCyclicGain','flapMuGain', ...
    'flapLatMuGain','flapQGain','flapPGain','wakeFactor'};
tf = any(cellfun(@(x) contains(path,x),tokens));
end

function [tf,lower,upper] = design_bounds(path)
tf = true;
switch path
    case 'htail.S', lower='3.2'; upper='6.0';
    case 'htail.rAC', lower='[-6.5 0 0.0]'; upper='[-4.0 0 0.3]';
    case 'htail.incidence', lower='-5 deg'; upper='+2 deg';
    case 'wing.xAC', lower='-0.4'; upper='+0.4';
    case 'rotor.pivotX', lower='-0.5'; upper='+0.5';
    case 'rotor.pivotZ', lower='-0.6'; upper='+0.6';
    case 'htail.CLalpha', lower='4.0'; upper='5.0';
    case 'htail.CLelevator', lower='1.6'; upper='2.4';
    case 'htail.downwashAlpha', lower='0.30'; upper='0.50';
    case 'wing.Cm0', lower='-0.045'; upper='-0.015';
    otherwise
        tf = false; lower=''; upper='';
end
end

function text = overlay_value_string(records)
parts = cell(numel(records),1);
for k = 1:numel(records)
    parts{k} = [subscript_string(records(k).subscripts),'=', ...
        value_string(records(k).valueSI)];
end
text = strjoin(parts,'; ');
end

function pct = comparison_percent(baseValue,records)
delta = [];
reference = [];
for k = 1:numel(records)
    if isempty(records(k).subscripts) && isequal(size(baseValue), ...
            size(records(k).valueSI)) && isnumeric(baseValue)
        delta = [delta;baseValue(:)-records(k).valueSI(:)]; %#ok<AGROW>
        reference = [reference;records(k).valueSI(:)]; %#ok<AGROW>
    elseif isnumeric(baseValue) && numel(records(k).subscripts)==2
        idx = num2cell(records(k).subscripts);
        delta(end+1,1) = baseValue(idx{:})-records(k).valueSI; %#ok<AGROW>
        reference(end+1,1) = records(k).valueSI; %#ok<AGROW>
    end
end
if isempty(delta)
    pct = NaN;
else
    pct = 100*norm(delta)/max(norm(reference),realmin);
end
end

function pct = baseline_difference(P,record)
parts = strsplit(record.path,'.');
value = P.(parts{1}).(parts{2});
if isempty(record.subscripts)
    if ~isnumeric(value) || ~isequal(size(value),size(record.valueSI))
        pct = NaN;
    else
        pct = 100*norm(value(:)-record.valueSI(:))/ ...
            max(norm(record.valueSI(:)),realmin);
    end
else
    idx = num2cell(record.subscripts);
    pct = 100*abs(value(idx{:})-record.valueSI)/ ...
        max(abs(record.valueSI),realmin);
end
end
