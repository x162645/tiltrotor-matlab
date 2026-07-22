function result = parameter_sensitivity_analysis(database,P13)
%PARAMETER_SENSITIVITY_ANALYSIS Local implicit trim sensitivities.
% Parameter derivatives are evaluated by a central physical-parameter
% difference and the implicit-function relation dz/dp=-Jz\(dr/dp).  This
% avoids treating solver tolerances or iteration limits as design variables.

if nargin < 2 || isempty(P13), P13 = params_berger13(); end
parameters = candidate_parameters(P13);
selectedIds = {'B15_V020','B45_V035','B75_V040','B75_V060','B75_V080'};
points = database.points(ismember({database.points.id},selectedIds));
rows = repmat(empty_row(),0,1);

for ipt = 1:numel(points)
    source = points(ipt);
    if isempty(source.trim), continue; end
    tr = source.trim;
    z0 = tr.trimVariableVector(:);
    Jz = tr.jacobian;
    if rank(Jz) < min(size(Jz))
        Jsolve = pinv(Jz);
    else
        Jsolve = Jz\eye(size(Jz,1));
    end
    for jp = 1:numel(parameters)
        spec = parameters(jp);
        [Pplus,Pminus] = perturb_pair(P13,spec);
        plusFixed = evaluate_berger13_trim_point(source.condition, ...
            tr.definition,z0,Pplus);
        minusFixed = evaluate_berger13_trim_point(source.condition, ...
            tr.definition,z0,Pminus);
        drdp = (plusFixed.residual-minusFixed.residual)/(2*spec.step);
        dzdp = -Jsolve*drdp;
        plusCoupled = evaluate_berger13_trim_point(source.condition, ...
            tr.definition,z0+spec.step*dzdp,Pplus);
        minusCoupled = evaluate_berger13_trim_point(source.condition, ...
            tr.definition,z0-spec.step*dzdp,Pminus);
        [names,yPlus,scales] = outputs(plusCoupled,tr,z0+spec.step*dzdp);
        [~,yMinus] = outputs(minusCoupled,tr,z0-spec.step*dzdp);
        dydp = (yPlus-yMinus)/(2*spec.step);
        normalized = dydp*spec.reference./scales;
        fixedResidualDerivative = norm(drdp);
        for iy = 1:numel(names)
            row = empty_row();
            row.pointId = source.id;
            row.betaMDeg = source.condition.betaM*180/pi;
            row.speedMps = source.condition.V;
            row.parameter = spec.name;
            row.codePath = spec.path;
            row.layer = spec.layer;
            row.referenceValue = spec.reference;
            row.perturbation = spec.step;
            row.output = names{iy};
            row.outputScale = scales(iy);
            row.derivative = dydp(iy);
            row.normalizedSensitivity = normalized(iy);
            row.fixedStateResidualDerivative = fixedResidualDerivative;
            row.baselineStatus = source.status;
            row.finiteReal = all(isfinite([dydp(iy),normalized(iy), ...
                fixedResidualDerivative])) && isreal([dydp(iy), ...
                normalized(iy),fixedResidualDerivative]);
            rows(end+1) = row; %#ok<AGROW>
        end
    end
end

T = struct2table(rows);
outputNames = unique(T.output,'stable');
parameterNames = {parameters.name}.';
S = zeros(numel(selectedIds)*numel(outputNames),numel(parameters));
labels = cell(size(S,1),1);
rr = 0;
for ipt = 1:numel(selectedIds)
    for iy = 1:numel(outputNames)
        rr = rr+1;
        labels{rr} = [selectedIds{ipt},'/',outputNames{iy}];
        for jp = 1:numel(parameters)
            mask = strcmp(T.pointId,selectedIds{ipt}) & ...
                strcmp(T.output,outputNames{iy}) & ...
                strcmp(T.parameter,parameters(jp).name);
            if any(mask), S(rr,jp) = T.normalizedSensitivity(find(mask,1)); end
        end
    end
end
activeRows = any(abs(S)>0,2) & all(isfinite(S),2);
Sactive = S(activeRows,:);
if isempty(Sactive)
    singularValues = zeros(0,1); correlation = eye(numel(parameters));
    conditionNumber = Inf; numericalRank = 0;
else
    singularValues = svd(Sactive,'econ');
    scale = sqrt(sum(Sactive.^2,1));
    Sn = Sactive./max(scale,eps);
    correlation = Sn.'*Sn;
    conditionNumber = singularValues(1)/max(singularValues(end),realmin);
    numericalRank = sum(singularValues > 1e-8*singularValues(1));
end

result.longTable = T;
result.matrix = S;
result.rowLabels = labels;
result.parameterNames = parameterNames;
result.outputNames = outputNames;
result.singularValues = singularValues;
result.parameterCorrelation = correlation;
result.conditionNumber = conditionNumber;
result.numericalRank = numericalRank;
result.highCorrelationPairs = correlated_pairs(correlation,parameterNames,0.95);
result.method = ['Central parameter differences plus local implicit trim ' ...
    'correction; sensitivity is diagnostic, not an optimized parameter set.'];
end

function specs = candidate_parameters(P13)
P = P13.base;
if ~isfield(P.mass,'baselineCG'), P.mass.baselineCG = zeros(3,1); end
specs = [ ...
    spec('cgX','mass.baselineCG',[1 1],P.mass.baselineCG(1),0.05,1.0,'GEOMETRY');
    spec('cgZ','mass.baselineCG',[3 1],P.mass.baselineCG(3),0.03,0.5,'GEOMETRY');
    spec('tailArea','htail.S',[],P.htail.S,0.02*P.htail.S,P.htail.S,'GEOMETRY');
    spec('tailArmX','htail.rAC',[1 1],P.htail.rAC(1),0.02*abs(P.htail.rAC(1)),abs(P.htail.rAC(1)),'GEOMETRY');
    spec('tailIncidence','htail.incidence',[],P.htail.incidence,0.25*pi/180,5*pi/180,'GEOMETRY');
    spec('wingACX','wing.xAC',[],P.wing.xAC,0.03,1.0,'GEOMETRY');
    spec('rotorHubX','rotor.pivotX',[],P.rotor.pivotX,0.03,1.0,'GEOMETRY');
    spec('rotorHubZ','rotor.pivotZ',[],P.rotor.pivotZ,0.03,1.0,'GEOMETRY');
    spec('tailCLelevator','htail.CLelevator',[],P.htail.CLelevator,0.02*abs(P.htail.CLelevator),abs(P.htail.CLelevator),'EFFECTIVE_AERO');
    spec('tailDownwashAlpha','htail.downwashAlpha',[],P.htail.downwashAlpha,0.02*abs(P.htail.downwashAlpha),abs(P.htail.downwashAlpha),'EFFECTIVE_AERO');
    spec('wingCm0','wing.Cm0',[],P.wing.Cm0,0.002,max(abs(P.wing.Cm0),0.03),'EFFECTIVE_AERO')];
end

function s = spec(name,path,subscripts,value,step,reference,layer)
s = struct('name',name,'path',path,'subscripts',subscripts, ...
    'value',value,'step',step,'reference',reference,'layer',layer);
end

function [Pp,Pm] = perturb_pair(P13,s)
Pp=P13; Pm=P13;
Pp.base = set_value(Pp.base,s,s.value+s.step);
Pm.base = set_value(Pm.base,s,s.value-s.step);
end

function P = set_value(P,s,value)
parts = strsplit(s.path,'.');
if ~isfield(P.(parts{1}),parts{2}) && strcmp(s.path,'mass.baselineCG')
    P.mass.baselineCG=zeros(3,1);
end
field = P.(parts{1}).(parts{2});
if isempty(s.subscripts)
    field=value;
else
    field(s.subscripts(1),s.subscripts(2))=value;
end
P.(parts{1}).(parts{2})=field;
end

function [names,y,scales] = outputs(point,trim,z)
names = {'thetaDeg','collectiveDeg','cyclicLongDeg','elevatorDeg', ...
    'minimumMarginProxy','rotorLeftMyNm','rotorRightMyNm','wingMyNm', ...
    'fuselageMyNm','horizontalTailMyNm','verticalTailMyNm','totalMyNm'};
d2r=pi/180;
bounds=trim.definition.bounds;
margin=min(min(z-bounds(:,1),bounds(:,2)-z)./(bounds(:,2)-bounds(:,1)));
y=[point.x13(8)/d2r; point.u10Torque(1)/d2r; ...
    point.u10Torque(3)/d2r; point.u10Torque(7)/d2r; margin; ...
    component_my(point,'rotorLeft'); component_my(point,'rotorRight'); ...
    component_my(point,'wing'); component_my(point,'fuselage'); ...
    component_my(point,'horizontalTail'); component_my(point,'verticalTail'); ...
    point.momentBalanceBody(2)];
scales=[10;20;20;20;0.2;5000;5000;10000;2000;10000;2000;1000];
end

function value = component_my(point,name)
components=point.eomOut.components13.components;
for k=1:numel(components)
    if strcmp(components{k}.name,name), value=components{k}.M(2); return; end
end
error('parameter_sensitivity_analysis:MissingComponent','Missing %s.',name);
end

function T = correlated_pairs(C,names,threshold)
rows=repmat(struct('parameterA','','parameterB','','absoluteCorrelation',NaN),0,1);
for i=1:numel(names)
    for j=i+1:numel(names)
        if abs(C(i,j))>=threshold
            rows(end+1)=struct('parameterA',names{i},'parameterB',names{j}, ...
                'absoluteCorrelation',abs(C(i,j))); %#ok<AGROW>
        end
    end
end
T=struct2table(rows);
end

function r=empty_row()
r=struct('pointId','','betaMDeg',NaN,'speedMps',NaN,'parameter','', ...
    'codePath','','layer','','referenceValue',NaN,'perturbation',NaN, ...
    'output','','outputScale',NaN,'derivative',NaN, ...
    'normalizedSensitivity',NaN,'fixedStateResidualDerivative',NaN, ...
    'baselineStatus','','finiteReal',false);
end
