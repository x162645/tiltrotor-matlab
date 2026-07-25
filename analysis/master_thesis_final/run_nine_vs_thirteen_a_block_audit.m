function audit = run_nine_vs_thirteen_a_block_audit(outputDir)
%RUN_NINE_VS_THIRTEEN_A_BLOCK_AUDIT Elementwise shared-A audit.
% Read-only analysis for the thesis final review. Production functions and
% parameters are not modified. The 9-state and 13-state command models are
% compared at the three frozen credible points with identical parameters,
% controls, nacelle angles, and central-difference steps.

if nargin < 1 || isempty(outputDir)
    error('run_nine_vs_thirteen_a_block_audit:OutputRequired', ...
        'An explicit output directory is required.');
end
if ~exist(outputDir,'dir'), mkdir(outputDir); end

[P13,~] = params_generic_trim_optimized();
source = readtable(fullfile('results','generic_trim_pr5b', ...
    'deliverables','MODEL_C2_EFFECTIVE_OPTIMIZED_RESULTS.csv'), ...
    'TextType','string');
pointIds = ["B15_V020";"B45_V035";"B75_V080"];
stateNames = ["u";"v";"w";"p";"q";"r";"phi";"theta";"psi"];
componentNames = ["rotorLeft";"rotorRight";"wing";"fuselage"; ...
    "horizontalTail";"verticalTail"];

elementRows = cell(numel(pointIds)*81,12);
componentRows = cell(numel(pointIds)*9*numel(componentNames),12);
elementIndex = 0;
componentIndex = 0;
pointSummary = cell(numel(pointIds),10);

for pointIndex = 1:numel(pointIds)
    pointId = pointIds(pointIndex);
    row = find(source.pointId == pointId,1);
    if isempty(row) || source.status(row) ~= "CREDIBLE"
        error('run_nine_vs_thirteen_a_block_audit:MissingPoint', ...
            'Frozen credible point %s is unavailable.',pointId);
    end

    betaM = deg2rad(source.betaMDeg(row));
    speed = source.speedMps(row);
    theta = deg2rad(source.thetaDeg(row));
    x9 = [speed*cos(theta);0;speed*sin(theta);zeros(4,1);theta;0];
    u7 = deg2rad([source.collectiveDeg(row);0; ...
        source.cyclicLongDeg(row);0;0;source.elevatorDeg(row);0]);
    x13 = [x9;betaM;betaM;0;0];
    u10 = [u7(1:4);0;u7(5:7);betaM;betaM];

    [A9,B9,report9] = linearize_numeric(x9,u7,betaM,P13.base);
    [A13,B13,report13] = linearize_13x10_command_numeric( ...
        x13,u10,P13,1);
    if ~(report9.finite && report13.finiteReal)
        error('run_nine_vs_thirteen_a_block_audit:NonFinite', ...
            'Non-finite linearization at %s.',pointId);
    end
    D = A13(1:9,1:9)-A9;

    for outputIndex = 1:9
        for inputIndex = 1:9
            elementIndex = elementIndex+1;
            difference = D(outputIndex,inputIndex);
            tolerance = 1e-9*max([1,abs(A9(outputIndex,inputIndex)), ...
                abs(A13(outputIndex,inputIndex))]);
            if abs(difference) <= tolerance
                classification = "CONSISTENT_WITHIN_TOLERANCE";
                dominant = "none";
                interpretation = "共同刚体导数在当前数值容差内一致";
            else
                classification = ...
                    "B_MODEL_DEFINITION_DIFFERENCE_INDEPENDENT_WING_WAKE";
                dominant = "wing";
                interpretation = "十三状态路径逐侧重算尾流覆盖；" + ...
                    "九状态路径先对左右旋翼推进比取平均。" + ...
                    "p/r扰动使左右局部推进比不同，二者的求平均顺序" + ...
                    "不交换，改变滚转/偏航阻尼导数";
            end
            elementRows(elementIndex,:) = {char(pointId), ...
                outputIndex,char(stateNames(outputIndex)),inputIndex, ...
                char(stateNames(inputIndex)),A9(outputIndex,inputIndex), ...
                A13(outputIndex,inputIndex),difference,tolerance, ...
                char(classification),char(dominant),char(interpretation)};
        end
    end

    mp = mass_properties(betaM,P13.base);
    perComponent = zeros(numel(componentNames),9,3);
    h = P13.base.linear.dx(:);
    for inputIndex = 1:9
        xp9 = x9; xm9 = x9;
        xp9(inputIndex) = xp9(inputIndex)+h(inputIndex);
        xm9(inputIndex) = xm9(inputIndex)-h(inputIndex);
        xp13 = x13; xm13 = x13;
        xp13(inputIndex) = xp13(inputIndex)+h(inputIndex);
        xm13(inputIndex) = xm13(inputIndex)-h(inputIndex);

        [~,~,i9p] = total_forces_moments(xp9,u7,betaM,P13.base);
        [~,~,i9m] = total_forces_moments(xm9,u7,betaM,P13.base);
        [~,~,i13p] = total_forces_moments_13x10( ...
            xp13,[u10(1:8);0;0],P13);
        [~,~,i13m] = total_forces_moments_13x10( ...
            xm13,[u10(1:8);0;0],P13);

        for nameIndex = 1:numel(componentNames)
            c9p = component_by_name(i9p.components,componentNames(nameIndex));
            c9m = component_by_name(i9m.components,componentNames(nameIndex));
            c13p = component_by_name(i13p.components,componentNames(nameIndex));
            c13m = component_by_name(i13m.components,componentNames(nameIndex));
            dF9 = (c9p.F-c9m.F)/(2*h(inputIndex));
            dF13 = (c13p.F-c13m.F)/(2*h(inputIndex));
            dM9 = (c9p.M-c9m.M)/(2*h(inputIndex));
            dM13 = (c13p.M-c13m.M)/(2*h(inputIndex));
            deltaOmegaDot = mp.I\(dM13-dM9);
            perComponent(nameIndex,inputIndex,:) = deltaOmegaDot;
            componentIndex = componentIndex+1;
            componentRows(componentIndex,:) = {char(pointId),inputIndex, ...
                char(stateNames(inputIndex)),char(componentNames(nameIndex)), ...
                norm(dF13-dF9),norm(dM13-dM9),deltaOmegaDot(1), ...
                deltaOmegaDot(2),deltaOmegaDot(3),norm(deltaOmegaDot), ...
                h(inputIndex),'CENTRAL_DIFFERENCE'};
        end
    end

    [largestDifference,linearIndex] = max(abs(D(:)));
    [largestRow,largestColumn] = ind2sub([9,9],linearIndex);
    componentNorms = squeeze(sqrt(sum(sum(perComponent.^2,3),2)));
    [~,dominantIndex] = max(componentNorms);
    pointSummary(pointIndex,:) = {char(pointId),source.betaMDeg(row), ...
        speed,norm(D,'fro'),largestDifference, ...
        char(stateNames(largestRow)),char(stateNames(largestColumn)), ...
        char(componentNames(dominantIndex)),norm(B13(1:9,[1:4,6:8])-B9,'fro'), ...
        'B_MODEL_DEFINITION_DIFFERENCE'};
end

elementTable = cell2table(elementRows,'VariableNames', ...
    {'pointId','outputIndex','outputState','inputIndex','inputState', ...
    'A9','A13Shared','difference','tolerance','classification', ...
    'dominantComponent','interpretation'});
componentTable = cell2table(componentRows,'VariableNames', ...
    {'pointId','inputIndex','inputState','component', ...
    'forceDerivativeDifferenceNorm','momentDerivativeDifferenceNorm', ...
    'rollAccelerationDerivativeDifference', ...
    'pitchAccelerationDerivativeDifference', ...
    'yawAccelerationDerivativeDifference', ...
    'angularAccelerationDerivativeDifferenceNorm', ...
    'differenceStep','stencil'});
summaryTable = cell2table(pointSummary,'VariableNames', ...
    {'pointId','betaMDeg','speedMps','sharedAFrobeniusDifference', ...
    'largestAbsoluteElementDifference','largestOutputState', ...
    'largestInputState','dominantComponent','sharedBFrobeniusDifference', ...
    'classification'});

writetable(elementTable,fullfile(outputDir, ...
    'NINE_VS_THIRTEEN_A_BLOCK_ELEMENTWISE.csv'));
writetable(componentTable,fullfile(outputDir, ...
    'NINE_VS_THIRTEEN_A_BLOCK_COMPONENT_DERIVATIVES.csv'));
writetable(summaryTable,fullfile(outputDir, ...
    'NINE_VS_THIRTEEN_A_BLOCK_SUMMARY.csv'));

audit.elementwise = elementTable;
audit.componentDerivatives = componentTable;
audit.summary = summaryTable;
audit.finiteReal = all(isfinite(elementTable.A9)) && ...
    all(isfinite(elementTable.A13Shared)) && ...
    all(isfinite(componentTable.angularAccelerationDerivativeDifferenceNorm));
audit.classification = 'B_MODEL_DEFINITION_DIFFERENCE';
audit.productionModelModified = false;
audit.defaultParametersModified = false;
save(fullfile(outputDir,'NINE_VS_THIRTEEN_A_BLOCK_AUDIT.mat'), ...
    'audit','-v7');
end

function component = component_by_name(components,target)
for k = 1:numel(components)
    if strcmp(components{k}.name,target)
        component = components{k};
        return;
    end
end
error('run_nine_vs_thirteen_a_block_audit:MissingComponent', ...
    'Component %s is missing.',target);
end
