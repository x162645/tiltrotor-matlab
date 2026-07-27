function result = compute_direct_derivatives(pointId,trimReport,P13)
%COMPUTE_DIRECT_DERIVATIVES Direct load derivatives at one credible trim.
% Angle perturbations retain body-speed magnitude. All differences are
% central and preserve the trimmed controls and configuration angle.

if ~isstruct(trimReport) || ~isfield(trimReport,'credible') || ...
        ~trimReport.credible || ~trimReport.physicalConverged
    error('control_stability:NonCredibleTrim', ...
        'A physically converged CREDIBLE trim report is required.');
end

P = P13.base;
x0 = trimReport.x13(1:9);
u0 = trimReport.u10Torque([1:4,6:8]);
betaM = trimReport.condition.betaM;
ref = control_stability_reference_quantities(x0,betaM,P);
[F0,M0,info0] = total_forces_moments(x0,u0,betaM,P);
if ~info0.physicalConverged
    error('control_stability:BaseLoadNotPhysical', ...
        'The unperturbed load point failed rotor physical convergence.');
end

angleSteps = [1e-3;1e-4;1e-5];
rateSteps = [1e-2;1e-3;1e-4];
controlSteps = [1e-3;1e-4;1e-5];
rowsStatic = repmat(empty_row(),0,1);
rowsDamping = repmat(empty_row(),0,1);
rowsControl = repmat(empty_row(),0,1);

flowNames = {'alpha','betaSlip'};
for flowIndex = 1:numel(flowNames)
    for stepIndex = 1:numel(angleSteps)
        h = angleSteps(stepIndex);
        [Fp,Mp,Fm,Mm,valid,status] = flow_loads( ...
            flowNames{flowIndex},h);
        rowsStatic = append_six(rowsStatic,flowNames{flowIndex}, ...
            h,stepIndex,Fp,Mp,Fm,Mm,valid,status,'FLOW_ANGLE');
    end
end

rateNames = {'p','q','r'};
for rateIndex = 1:numel(rateNames)
    for stepIndex = 1:numel(rateSteps)
        h = rateSteps(stepIndex);
        [Fp,Mp,Fm,Mm,valid,status] = state_rate_loads( ...
            rateNames{rateIndex},h);
        rowsDamping = append_six(rowsDamping,rateNames{rateIndex}, ...
            h,stepIndex,Fp,Mp,Fm,Mm,valid,status,'BODY_RATE');
    end
end

contract = control_stability_interface_contract();
for controlIndex = 1:numel(contract.nineInputNames)
    name = contract.nineInputNames{controlIndex};
    for stepIndex = 1:numel(controlSteps)
        h = controlSteps(stepIndex);
        [Fp,Mp,Fm,Mm,valid,status] = control_loads(controlIndex,h);
        rowsControl = append_six(rowsControl,name,h,stepIndex, ...
            Fp,Mp,Fm,Mm,valid,status,'PHYSICAL_CONTROL');
    end
end

staticTable = add_step_variation(struct2table(rowsStatic));
dampingTable = add_step_variation(struct2table(rowsDamping));
controlTable = add_step_variation(struct2table(rowsControl));

[A9,B9,linearReport] = linearize_numeric(x0,u0,betaM,P);
derivativeCrosscheck = make_A_crosscheck(staticTable,dampingTable,A9);

result.staticTable = staticTable;
result.dampingTable = dampingTable;
result.controlTable = controlTable;
result.derivativeCrosscheck = derivativeCrosscheck;
result.A9 = A9;
result.B9 = B9;
result.linearReport9 = linearReport;
result.reference = ref;
result.baseForceN = F0;
result.baseMomentNm = M0;
result.x9 = x0;
result.u7 = u0;
result.finiteReal = linearReport.finite && ...
    all(staticTable.valid) && all(dampingTable.valid) && ...
    all(controlTable.valid);

    function [Fp,Mp,Fm,Mm,valid,status] = flow_loads(name,h)
        alpha0 = ref.alpha;
        beta0 = ref.betaSlip;
        if strcmp(name,'alpha')
            xp = perturb_body_flow_angles(x0,alpha0+h,beta0);
            xm = perturb_body_flow_angles(x0,alpha0-h,beta0);
        else
            xp = perturb_body_flow_angles(x0,alpha0,beta0+h);
            xm = perturb_body_flow_angles(x0,alpha0,beta0-h);
        end
        [Fp,Mp,ip] = total_forces_moments(xp,u0,betaM,P);
        [Fm,Mm,im] = total_forces_moments(xm,u0,betaM,P);
        [valid,status] = load_status(Fp,Mp,Fm,Mm,ip,im);
    end

    function [Fp,Mp,Fm,Mm,valid,status] = state_rate_loads(name,h)
        index = find(strcmp({'p','q','r'},name),1)+3;
        xp = x0; xm = x0;
        xp(index) = xp(index)+h;
        xm(index) = xm(index)-h;
        [Fp,Mp,ip] = total_forces_moments(xp,u0,betaM,P);
        [Fm,Mm,im] = total_forces_moments(xm,u0,betaM,P);
        [valid,status] = load_status(Fp,Mp,Fm,Mm,ip,im);
    end

    function [Fp,Mp,Fm,Mm,valid,status] = control_loads(index,h)
        up = u0; um = u0;
        up(index) = up(index)+h;
        um(index) = um(index)-h;
        [Fp,Mp,ip] = total_forces_moments(x0,up,betaM,P);
        [Fm,Mm,im] = total_forces_moments(x0,um,betaM,P);
        [valid,status] = load_status(Fp,Mp,Fm,Mm,ip,im);
    end

    function [valid,status] = load_status(Fp,Mp,Fm,Mm,ip,im)
        finite = isreal(Fp) && isreal(Mp) && isreal(Fm) && ...
            isreal(Mm) && all(isfinite([Fp;Mp;Fm;Mm]));
        physical = ip.physicalConverged && im.physicalConverged && ...
            ip.physicalBranchSupported && im.physicalBranchSupported;
        valid = finite && physical;
        if valid
            status = 'VALID_CENTRAL_DIFFERENCE';
        elseif ~finite
            status = 'NONFINITE_OR_COMPLEX';
        else
            status = [ip.physicalStatus '__' im.physicalStatus];
        end
    end

    function rows = append_six(rows,name,h,stepIndex, ...
            Fp,Mp,Fm,Mm,valid,status,kind)
        dF = (Fp-Fm)/(2*h);
        dM = (Mp-Mm)/(2*h);
        dimensional = [dF;dM];
        denominators = [ref.qbar*ref.S;ref.qbar*ref.S; ...
            ref.qbar*ref.S;ref.qbar*ref.S*ref.b; ...
            ref.qbar*ref.S*ref.c;ref.qbar*ref.S*ref.b];
        rateFactor = 1;
        coefficientUnit = '1/rad';
        dimensionalDenominatorUnit = 'rad';
        if strcmp(kind,'BODY_RATE')
            dimensionalDenominatorUnit = 'rad/s';
            if strcmp(name,'q')
                rateFactor = 2*ref.V/ref.c;
            else
                rateFactor = 2*ref.V/ref.b;
            end
            coefficientUnit = '1/(normalized_rate)';
        end
        coefficient = dimensional./denominators*rateFactor;
        componentNames = {'CX','CY','CZ','Cl','Cm','Cn'};
        for componentIndex = 1:6
            row = empty_row();
            row.pointId = pointId;
            row.betaMDeg = betaM*180/pi;
            row.speedMps = ref.V;
            row.perturbationKind = kind;
            row.perturbationName = name;
            row.stepLevel = stepIndex;
            row.step = h;
            row.stepUnit = dimensionalDenominatorUnit;
            row.coefficientName = [componentNames{componentIndex} '_' name];
            row.dimensionalDerivative = dimensional(componentIndex);
            if componentIndex <= 3
                row.dimensionalUnit = ['N/(' dimensionalDenominatorUnit ')'];
            else
                row.dimensionalUnit = ['N*m/(' dimensionalDenominatorUnit ')'];
            end
            row.coefficientDerivative = coefficient(componentIndex);
            row.coefficientUnit = coefficientUnit;
            row.plusFxN = Fp(1);
            row.plusFyN = Fp(2);
            row.plusFzN = Fp(3);
            row.plusMxNm = Mp(1);
            row.plusMyNm = Mp(2);
            row.plusMzNm = Mp(3);
            row.minusFxN = Fm(1);
            row.minusFyN = Fm(2);
            row.minusFzN = Fm(3);
            row.minusMxNm = Mm(1);
            row.minusMyNm = Mm(2);
            row.minusMzNm = Mm(3);
            row.relativeStepVariation = NaN;
            row.valid = valid;
            row.status = status;
            rows(end+1,1) = row; %#ok<AGROW>
        end
    end

    function crosscheck = make_A_crosscheck(staticT,dampingT,A)
        rows = repmat(empty_crosscheck(),0,1);
        variableNames = {'alpha','betaSlip','p','q','r'};
        for crossVariableIndex = 1:numel(variableNames)
            variableName = variableNames{crossVariableIndex};
            if crossVariableIndex <= 2
                direct = staticT(strcmp(staticT.perturbationName, ...
                    variableName) & staticT.stepLevel == 2,:);
                alpha0 = ref.alpha;
                beta0 = ref.betaSlip;
                if strcmp(variableName,'alpha')
                    direction = [-ref.V*sin(alpha0)*cos(beta0);0; ...
                        ref.V*cos(alpha0)*cos(beta0)];
                else
                    direction = [-ref.V*cos(alpha0)*sin(beta0); ...
                        ref.V*cos(beta0); ...
                        -ref.V*sin(alpha0)*sin(beta0)];
                end
                derivativeXdot = A(:,1:3)*direction;
                recoveredF = info0.massProperties.mass*derivativeXdot(1:3);
                recoveredM = info0.massProperties.I*derivativeXdot(4:6);
                rateFactor = 1;
            else
                direct = dampingT(strcmp(dampingT.perturbationName, ...
                    variableName) & dampingT.stepLevel == 2,:);
                stateColumn = crossVariableIndex+1;
                unitRate = zeros(3,1);
                unitRate(crossVariableIndex-2) = 1;
                recoveredF = info0.massProperties.mass*( ...
                    A(1:3,stateColumn)+cross(unitRate,x0(1:3)));
                recoveredM = info0.massProperties.I*A(4:6,stateColumn);
                if strcmp(variableName,'q')
                    rateFactor = 2*ref.V/ref.c;
                else
                    rateFactor = 2*ref.V/ref.b;
                end
            end
            recoveredDimensional = [recoveredF;recoveredM];
            denominators = [ref.qbar*ref.S;ref.qbar*ref.S; ...
                ref.qbar*ref.S;ref.qbar*ref.S*ref.b; ...
                ref.qbar*ref.S*ref.c;ref.qbar*ref.S*ref.b];
            recoveredCoefficient = ...
                recoveredDimensional./denominators*rateFactor;
            for componentIndex = 1:height(direct)
                row = empty_crosscheck();
                row.pointId = pointId;
                row.perturbationName = variableName;
                row.coefficientName = direct.coefficientName{componentIndex};
                row.directCoefficientDerivative = ...
                    direct.coefficientDerivative(componentIndex);
                row.ARecoveredCoefficientDerivative = ...
                    recoveredCoefficient(componentIndex);
                row.absoluteDifference = row.ARecoveredCoefficientDerivative- ...
                    row.directCoefficientDerivative;
                row.relativeDifference = abs(row.absoluteDifference)/ ...
                    max(abs(row.directCoefficientDerivative),1e-10);
                if row.relativeDifference <= 5e-3 || ...
                        abs(row.absoluteDifference) <= 1e-6
                    row.status = 'FULL_CROSSCHECK';
                else
                    row.status = 'PARTIAL_CROSSCHECK';
                end
                rows(end+1,1) = row; %#ok<AGROW>
            end
        end
        crosscheck = struct2table(rows);
    end
end

function tableOut = add_step_variation(tableIn)
tableOut = tableIn;
names = unique(tableIn.perturbationName,'stable');
for nameIndex = 1:numel(names)
    nameMask = strcmp(tableIn.perturbationName,names{nameIndex});
    coefficientNames = unique(tableIn.coefficientName(nameMask),'stable');
    for coefficientIndex = 1:numel(coefficientNames)
        mask = nameMask & strcmp(tableIn.coefficientName, ...
            coefficientNames{coefficientIndex});
        indices = find(mask);
        middleIndex = indices(tableIn.stepLevel(indices) == 2);
        if numel(indices) ~= 3 || numel(middleIndex) ~= 1
            continue;
        end
        reference = tableIn.coefficientDerivative(middleIndex);
        difference = abs(tableIn.coefficientDerivative(indices)-reference);
        variation = max(difference)/max(abs(reference),1e-10);
        tableOut.relativeStepVariation(indices) = variation;
    end
end
end

function row = empty_row()
row = struct('pointId','','betaMDeg',NaN,'speedMps',NaN, ...
    'perturbationKind','','perturbationName','','stepLevel',NaN, ...
    'step',NaN,'stepUnit','','coefficientName','', ...
    'dimensionalDerivative',NaN,'dimensionalUnit','', ...
    'coefficientDerivative',NaN,'coefficientUnit','', ...
    'plusFxN',NaN,'plusFyN',NaN,'plusFzN',NaN, ...
    'plusMxNm',NaN,'plusMyNm',NaN,'plusMzNm',NaN, ...
    'minusFxN',NaN,'minusFyN',NaN,'minusFzN',NaN, ...
    'minusMxNm',NaN,'minusMyNm',NaN,'minusMzNm',NaN, ...
    'relativeStepVariation',NaN,'valid',false,'status','');
end

function row = empty_crosscheck()
row = struct('pointId','','perturbationName','', ...
    'coefficientName','','directCoefficientDerivative',NaN, ...
    'ARecoveredCoefficientDerivative',NaN,'absoluteDifference',NaN, ...
    'relativeDifference',NaN,'status','');
end
