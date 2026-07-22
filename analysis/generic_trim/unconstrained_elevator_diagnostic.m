function [T,details] = unconstrained_elevator_diagnostic(baseDatabase,P13)
%UNCONSTRAINED_ELEVATOR_DIAGNOSTIC Relax elevator only in a copied P13.
% Production limits are neither mutated nor returned as part of the model.

if nargin < 2 || isempty(P13), P13 = params_berger13(); end
productionLimit = P13.base.control.elevatorLim;
d2r = pi/180;
indices = find([baseDatabase.grid.betaDeg] == 75);
rows = repmat(empty_row(),numel(indices),1);
details = repmat(struct('pointId','','trim',[]),numel(indices),1);
for ii = 1:numel(indices)
    k = indices(ii);
    basePoint = baseDatabase.points(k);
    row = empty_row();
    row.pointId = basePoint.id;
    row.betaMDeg = basePoint.condition.betaM/d2r;
    row.speedMps = basePoint.condition.V;
    row.productionStatus = basePoint.status;
    row.productionElevatorLowerDeg = productionLimit(1)/d2r;
    row.productionElevatorUpperDeg = productionLimit(2)/d2r;
    if isempty(basePoint.trim)
        row.failureClass = 'UNKNOWN';
        row.note = 'No finite production candidate was available.';
        rows(ii) = row;
        continue;
    end
    baseTrim = basePoint.trim;
    row.productionElevatorDeg = baseTrim.u10Torque(7)/d2r;
    row.productionPitchMomentGapNm = baseTrim.momentBalanceBody(2);
    row.productionResidualNorm = baseTrim.dynamicResidualNorm;
    Pdiag = P13;
    Pdiag.base.control.elevatorLim = [-80 80]*d2r;
    opts = struct('mode',basePoint.mode, ...
        'initialValues',baseTrim.trimVariableVector, ...
        'runMultipleSeeds',false);
    try
        [~,~,diagTrim] = trim_berger13_symmetric( ...
            basePoint.condition,Pdiag,opts);
        details(ii).pointId = basePoint.id;
        details(ii).trim = diagTrim;
        row.unconstrainedStatus = diagTrim.status;
        row.unconstrainedElevatorDeg = diagTrim.u10Torque(7)/d2r;
        row.unconstrainedThetaDeg = diagTrim.x13(8)/d2r;
        row.unconstrainedResidualNorm = diagTrim.dynamicResidualNorm;
        row.elevatorExceedanceDeg = max(0,abs(row.unconstrainedElevatorDeg) ...
            - max(abs(productionLimit/d2r)));
    catch ME
        row.unconstrainedStatus = 'FAILED_EXCEPTION';
        row.note = [ME.identifier,': ',ME.message];
    end
    row = add_equivalent_requirements(row,baseTrim,P13);
    if baseTrim.credible
        row.failureClass = 'NONE_CREDIBLE_BASELINE';
    elseif strcmp(row.unconstrainedStatus,'CREDIBLE') && ...
            row.elevatorExceedanceDeg > 0
        row.failureClass = 'CONTROL_AUTHORITY_LIMITED';
    elseif any(baseTrim.activeLimits) && ...
            ~strcmp(row.unconstrainedStatus,'CREDIBLE')
        row.failureClass = 'MULTIPLE_CAUSES';
    elseif baseTrim.conditionNumber > 1e8
        row.failureClass = 'NUMERICALLY_ILL_CONDITIONED';
    else
        row.failureClass = 'GEOMETRY_MOMENT_BALANCE_LIMITED';
    end
    rows(ii) = row;
end
if ~isequaln(P13.base.control.elevatorLim,productionLimit)
    error('unconstrained_elevator_diagnostic:ProductionLimitMutation', ...
        'The diagnostic modified the supplied production limit.');
end
T = struct2table(rows,'AsArray',true);
end

function row = add_equivalent_requirements(row,trim,P13)
components = trim.point.eomOut.components13.components;
tail = component(components,'horizontalTail');
row.equivalentAdditionalTailFzN = NaN;
row.equivalentTailArmXM = NaN;
row.equivalentCGShiftXM = NaN;
row.equivalentCLelevatorDelta = NaN;
row.equivalentWingCm0Delta = NaN;
requiredMoment = -trim.momentBalanceBody(2);
data = tail.data;
if isfield(data,'rAC') && abs(data.rAC(1)) > 1e-8
    row.equivalentAdditionalTailFzN = -requiredMoment/data.rAC(1);
end
if isfield(data,'Maero') && abs(tail.F(3)) > 1e-8
    requiredTailMy = tail.M(2)+requiredMoment;
    row.equivalentTailArmXM = ...
        (data.rAC(3)*tail.F(1)+data.Maero(2)-requiredTailMy)/tail.F(3);
end
row.equivalentCGShiftXM = fixed_state_parameter_delta( ...
    trim,P13,'cgX',requiredMoment);
row.equivalentCLelevatorDelta = fixed_state_parameter_delta( ...
    trim,P13,'CLelevator',requiredMoment);
row.equivalentWingCm0Delta = fixed_state_parameter_delta( ...
    trim,P13,'wingCm0',requiredMoment);
end

function delta = fixed_state_parameter_delta(trim,P13,name,requiredMoment)
Pp = P13; Pm = P13;
switch name
    case 'CLelevator'
        p0 = P13.base.htail.CLelevator; h = 1e-3*max(abs(p0),1);
        Pp.base.htail.CLelevator = p0+h;
        Pm.base.htail.CLelevator = p0-h;
    case 'wingCm0'
        p0 = P13.base.wing.Cm0; h = 1e-3*max(abs(p0),0.01);
        Pp.base.wing.Cm0 = p0+h;
        Pm.base.wing.Cm0 = p0-h;
    case 'cgX'
        if isfield(P13.base.mass,'baselineCG')
            p0 = P13.base.mass.baselineCG(1);
        else
            p0 = 0;
            Pp.base.mass.baselineCG = zeros(3,1);
            Pm.base.mass.baselineCG = zeros(3,1);
        end
        h = 1e-3;
        Pp.base.mass.baselineCG(1) = p0+h;
        Pm.base.mass.baselineCG(1) = p0-h;
    otherwise
        delta = NaN; return;
end
[~,Mp] = total_forces_moments_13x10(trim.x13,trim.u10Torque,Pp);
[~,Mm] = total_forces_moments_13x10(trim.x13,trim.u10Torque,Pm);
derivative = (Mp(2)-Mm(2))/(2*h);
if abs(derivative) < 1e-12, delta = NaN; else, delta = requiredMoment/derivative; end
end

function c = component(components,name)
for k = 1:numel(components)
    if strcmp(components{k}.name,name), c=components{k}; return; end
end
error('unconstrained_elevator_diagnostic:MissingComponent', ...
    'Missing component %s.',name);
end

function row = empty_row()
row = struct('pointId','','betaMDeg',NaN,'speedMps',NaN, ...
    'productionStatus','','productionElevatorLowerDeg',NaN, ...
    'productionElevatorUpperDeg',NaN,'productionElevatorDeg',NaN, ...
    'productionPitchMomentGapNm',NaN,'productionResidualNorm',NaN, ...
    'unconstrainedStatus','','unconstrainedElevatorDeg',NaN, ...
    'unconstrainedThetaDeg',NaN,'unconstrainedResidualNorm',NaN, ...
    'elevatorExceedanceDeg',NaN,'equivalentAdditionalTailFzN',NaN, ...
    'equivalentTailArmXM',NaN,'equivalentCGShiftXM',NaN, ...
    'equivalentCLelevatorDelta',NaN,'equivalentWingCm0Delta',NaN, ...
    'failureClass','','note','');
end
