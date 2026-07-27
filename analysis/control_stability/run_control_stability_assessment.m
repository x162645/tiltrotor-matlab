function results = run_control_stability_assessment(outputDir,opts)
%RUN_CONTROL_STABILITY_ASSESSMENT Reproducible open-loop post-processing.
% Production physics and default parameters are read-only. The default run
% recomputes the existing nine-point explicit-mode grid, then evaluates the
% three frozen representative points requested by the technical report.

if nargin < 1 || isempty(outputDir)
    rootDir = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    outputDir = fullfile(rootDir,'docs', ...
        'tiltrotor_control_stability_technical_report');
end
if nargin < 2
    opts = struct();
end
opts = default_options(opts);
ensure_directory(outputDir);
figureDir = fullfile(outputDir,'figures');
trajectoryDir = fullfile(outputDir,'raw_trajectories');
logDir = fullfile(outputDir,'logs');
ensure_directory(figureDir);
ensure_directory(trajectoryDir);
ensure_directory(logDir);
diaryFile = fullfile(logDir,'CONTROL_STABILITY_MATLAB_RUN.log');
if exist(diaryFile,'file'), delete(diaryFile); end
diary(diaryFile);
cleanupDiary = onCleanup(@() diary('off'));

fprintf('Control-stability assessment started: %s\n',datestr(now,31));
fprintf('MATLAB: %s\n',version);
fprintf('Output: %s\n',outputDir);
fprintf('Full trim grid: %d\n',opts.fullTrimGrid);

P13 = params_berger13();
contract = control_stability_interface_contract();
representativeDefinitions = control_stability_operating_points();

if ~isempty(opts.trimDatabase)
    trimDatabase = opts.trimDatabase;
elseif opts.fullTrimGrid
    trimDatabase = build_berger13_pr2_database('');
else
    trimDatabase = representative_database( ...
        representativeDefinitions,P13,opts.runMultipleSeeds);
end
trimCharacteristics = trim_characteristics(trimDatabase);
writetable(trimCharacteristics, ...
    fullfile(outputDir,'TRIM_CHARACTERISTICS_BY_MODE.csv'));
save(fullfile(outputDir,'CONTROL_STABILITY_TRIM_DATABASE.mat'), ...
    'trimDatabase','-v7');

representativeRows = repmat(empty_representative_row(), ...
    numel(representativeDefinitions),1);
staticTables = cell(numel(representativeDefinitions),1);
dampingTables = cell(numel(representativeDefinitions),1);
derivativeCrosscheckTables = cell(numel(representativeDefinitions),1);
controlTables = cell(numel(representativeDefinitions),1);
controlCrosscheckTables = cell(numel(representativeDefinitions),1);
modalParameterTables = {};
modalParticipationTables = {};
modalClassificationTables = {};
modalConditioningTables = {};
pointResults = repmat(struct(),numel(representativeDefinitions),1);

for pointIndex = 1:numel(representativeDefinitions)
    pointDefinition = representativeDefinitions(pointIndex);
    databaseIndex = find(strcmp({trimDatabase.points.id}, ...
        pointDefinition.id),1);
    if isempty(databaseIndex) || isempty(trimDatabase.points(databaseIndex).trim)
        error('control_stability:RepresentativeTrimMissing', ...
            'Representative trim %s is missing.',pointDefinition.id);
    end
    trimTorque = trimDatabase.points(databaseIndex).trim;
    if ~trimTorque.credible || ~trimTorque.physicalConverged || ...
            ~trimTorque.physicalBranchSupported
        error('control_stability:RepresentativeTrimNotCredible', ...
            'Representative trim %s is not physically credible.', ...
            pointDefinition.id);
    end
    [~,~,trimCommand] = trim_berger13_command_symmetric( ...
        pointDefinition.condition,P13,struct( ...
        'mode',pointDefinition.mode,'torqueTrimReport',trimTorque));
    if ~trimCommand.credible
        error('control_stability:CommandTrimNotCredible', ...
            'Command-interface trim %s is not credible.',pointDefinition.id);
    end

    if ~isempty(trimDatabase.points(databaseIndex).linearModel)
        linearTorque = trimDatabase.points(databaseIndex).linearModel;
    else
        linearTorque = linearize_berger13_trim_point(trimTorque,P13);
    end
    linearCommand = linearize_berger13_command_trim_point(trimCommand,P13);
    derivative = compute_direct_derivatives( ...
        pointDefinition.id,trimTorque,P13);
    controlCrosscheck = crosscheck_control_derivatives( ...
        pointDefinition.id,derivative.controlTable,derivative, ...
        linearTorque,linearCommand,trimTorque,P13);

    modal9 = analyze_modal_participation(pointDefinition.id, ...
        'NINE_STATE_PHYSICAL_CONTROL',derivative.A9, ...
        contract.nineStateNames);
    modal13Torque = analyze_modal_participation(pointDefinition.id, ...
        'THIRTEEN_STATE_TORQUE',linearTorque.symdiff.A, ...
        linearTorque.symdiff.stateNames);
    modal13Command = analyze_modal_participation(pointDefinition.id, ...
        'THIRTEEN_STATE_ANGLE_COMMAND',linearCommand.symdiff.A, ...
        linearCommand.symdiff.stateNames);

    modalSet = {modal9,modal13Torque,modal13Command};
    for modalIndex = 1:numel(modalSet)
        modalParameterTables{end+1,1} = modalSet{modalIndex}.parameters; %#ok<AGROW>
        modalParticipationTables{end+1,1} = modalSet{modalIndex}.participation; %#ok<AGROW>
        modalClassificationTables{end+1,1} = modalSet{modalIndex}.classification; %#ok<AGROW>
        modalConditioningTables{end+1,1} = modalSet{modalIndex}.conditioning; %#ok<AGROW>
    end

    staticTables{pointIndex} = derivative.staticTable;
    dampingTables{pointIndex} = derivative.dampingTable;
    derivativeCrosscheckTables{pointIndex} = ...
        derivative.derivativeCrosscheck;
    controlTables{pointIndex} = derivative.controlTable;
    controlCrosscheckTables{pointIndex} = controlCrosscheck;
    representativeRows(pointIndex) = representative_row( ...
        pointDefinition,trimTorque,trimCommand,derivative, ...
        linearTorque,linearCommand);

    pointResults(pointIndex).definition = pointDefinition;
    pointResults(pointIndex).trimTorque = trimTorque;
    pointResults(pointIndex).trimCommand = trimCommand;
    pointResults(pointIndex).derivative = derivative;
    pointResults(pointIndex).linearTorque = linearTorque;
    pointResults(pointIndex).linearCommand = linearCommand;
    pointResults(pointIndex).modal9 = modal9;
    pointResults(pointIndex).modal13Torque = modal13Torque;
    pointResults(pointIndex).modal13Command = modal13Command;
    fprintf('Completed derivatives/modal analysis: %s\n', ...
        pointDefinition.id);
end

staticTable = vertcat(staticTables{:});
dampingTable = vertcat(dampingTables{:});
derivativeCrosscheck = vertcat(derivativeCrosscheckTables{:});
controlTable = vertcat(controlTables{:});
controlCrosscheck = vertcat(controlCrosscheckTables{:});
modalParameters = vertcat(modalParameterTables{:});
modalParticipation = vertcat(modalParticipationTables{:});
modalClassification = vertcat(modalClassificationTables{:});
modalConditioning = vertcat(modalConditioningTables{:});
representativeTable = struct2table(representativeRows);

writetable(staticTable, ...
    fullfile(outputDir,'STATIC_STABILITY_DERIVATIVES.csv'));
writetable(dampingTable, ...
    fullfile(outputDir,'DAMPING_DERIVATIVES.csv'));
writetable(derivativeCrosscheck, ...
    fullfile(outputDir,'DERIVATIVE_CROSSCHECK.csv'));
writetable(controlTable, ...
    fullfile(outputDir,'CONTROL_EFFECTIVENESS_DERIVATIVES.csv'));
writetable(controlCrosscheck, ...
    fullfile(outputDir,'CONTROL_DERIVATIVE_CROSSCHECK.csv'));
writetable(modalParameters, ...
    fullfile(outputDir,'MODAL_PARAMETERS.csv'));
writetable(modalParticipation, ...
    fullfile(outputDir,'MODAL_PARTICIPATION.csv'));
writetable(modalClassification, ...
    fullfile(outputDir,'MODAL_CLASSIFICATION.csv'));
writetable(modalConditioning, ...
    fullfile(outputDir,'MODAL_CONDITIONING.csv'));
writetable(representativeTable, ...
    fullfile(outputDir,'REPRESENTATIVE_POINT_AUDIT.csv'));

[stepMetrics,linearNonlinearComparison,timeStepConvergence, ...
    responseTrajectories] = run_step_cases(pointResults,P13,opts, ...
    trajectoryDir);
stepMetrics = add_relative_effectiveness(stepMetrics);
writetable(stepMetrics, ...
    fullfile(outputDir,'CONTROL_STEP_RESPONSE_METRICS.csv'));
writetable(linearNonlinearComparison,fullfile(outputDir, ...
    'CONTROL_STEP_LINEAR_NONLINEAR_COMPARISON.csv'));
writetable(timeStepConvergence,fullfile(outputDir, ...
    'CONTROL_STEP_TIMESTEP_CONVERGENCE.csv'));

make_plots(figureDir,representativeTable,trimCharacteristics, ...
    staticTable,dampingTable,controlTable,modalParameters, ...
    modalParticipation,stepMetrics,responseTrajectories);

results.contract = contract;
results.trimDatabase = trimDatabase;
results.trimCharacteristics = trimCharacteristics;
results.representativeTable = representativeTable;
results.staticTable = staticTable;
results.dampingTable = dampingTable;
results.derivativeCrosscheck = derivativeCrosscheck;
results.controlTable = controlTable;
results.controlCrosscheck = controlCrosscheck;
results.modalParameters = modalParameters;
results.modalParticipation = modalParticipation;
results.modalClassification = modalClassification;
results.modalConditioning = modalConditioning;
results.stepMetrics = stepMetrics;
results.linearNonlinearComparison = linearNonlinearComparison;
results.timeStepConvergence = timeStepConvergence;
results.pointResults = pointResults;
results.finiteReal = all(representativeTable.finiteReal) && ...
    all(staticTable.valid) && all(dampingTable.valid) && ...
    all(controlTable.valid) && all(stepMetrics.finiteReal);
results.allRepresentativeCredible = ...
    all(representativeTable.credible) && ...
    all(representativeTable.physicalConverged);
results.productionModelModified = false;
results.defaultParametersModified = false;
results.claimBoundary = ['generic low-order open-loop control/stability ' ...
    'analysis; not type validation or handling-quality certification'];
save(fullfile(outputDir,'CONTROL_STABILITY_RESULTS.mat'), ...
    'results','-v7');
fprintf('FINITE_REAL=%d\n',results.finiteReal);
fprintf('REPRESENTATIVE_CREDIBLE=%d\n', ...
    results.allRepresentativeCredible);
fprintf('Control-stability assessment finished: %s\n',datestr(now,31));
clear cleanupDiary;
end

function opts = default_options(opts)
defaults = struct('fullTrimGrid',true,'runMultipleSeeds',true, ...
    'trimDatabase',[], ...
    'stepDurationSeconds',0.60,'stepDtSeconds',[0.02,0.01], ...
    'stepThirdDtSeconds',0.005,'stepConvergenceTolerance',0.02, ...
    'stepAmplitudeRad',0.5*pi/180);
names = fieldnames(defaults);
for k = 1:numel(names)
    if ~isfield(opts,names{k})
        opts.(names{k}) = defaults.(names{k});
    end
end
end

function ensure_directory(pathValue)
if ~exist(pathValue,'dir')
    mkdir(pathValue);
end
end

function database = representative_database(definitions,P13,runMultipleSeeds)
emptyPoint = struct('id','','condition',[],'mode','','status','FAILED', ...
    'failureIdentifier','','failureMessage','','trim',[], ...
    'linearModel',[],'elapsedSeconds',NaN);
points = repmat(emptyPoint,numel(definitions),1);
for k = 1:numel(definitions)
    points(k).id = definitions(k).id;
    points(k).condition = definitions(k).condition;
    points(k).mode = definitions(k).mode;
    started = tic;
    [~,~,trimReport] = trim_berger13_symmetric( ...
        definitions(k).condition,P13,struct( ...
        'mode',definitions(k).mode, ...
        'runMultipleSeeds',runMultipleSeeds));
    points(k).trim = trimReport;
    points(k).status = trimReport.status;
    if trimReport.credible
        points(k).linearModel = ...
            linearize_berger13_trim_point(trimReport,P13);
    end
    points(k).elapsedSeconds = toc(started);
end
database.points = points;
database.credibleCount = sum(strcmp({points.status},'CREDIBLE'));
database.failedCount = numel(points)-database.credibleCount;
database.gridDefinition = ...
    'THREE_FROZEN_REPRESENTATIVE_POINTS_ONLY';
database.createdWith = version;
end

function tableOut = trim_characteristics(database)
rows = repmat(empty_trim_row(),numel(database.points),1);
for k = 1:numel(database.points)
    point = database.points(k);
    rows(k).pointId = point.id;
    rows(k).mode = point.mode;
    rows(k).speedMps = point.condition.V;
    rows(k).betaMDeg = point.condition.betaM*180/pi;
    rows(k).status = point.status;
    rows(k).claimBoundary = ...
        'DISCRETE_EXPLICIT_MODE_POINT_NOT_CONTINUOUS_CORRIDOR';
    if isempty(point.trim)
        rows(k).failureReason = point.failureMessage;
        continue;
    end
    tr = point.trim;
    rows(k).thetaDeg = tr.x13(8)*180/pi;
    rows(k).alphaDeg = atan2(tr.x13(3),tr.x13(1))*180/pi;
    rows(k).collectiveDeg = tr.u10Torque(1)*180/pi;
    rows(k).cyclicLongDeg = tr.u10Torque(3)*180/pi;
    rows(k).elevatorDeg = tr.u10Torque(7)*180/pi;
    rows(k).pitchCommand = NaN;
    if isfield(tr,'allocation') && ~isempty(tr.allocation) && ...
            isfield(tr.allocation,'pitchCommand')
        rows(k).pitchCommand = tr.allocation.pitchCommand;
    elseif isfield(tr,'trimVariables') && ...
            isfield(tr.trimVariables,'pitchCommand')
        rows(k).pitchCommand = tr.trimVariables.pitchCommand;
    end
    rows(k).minimumControlMarginFraction = ...
        tr.minimumUnknownMarginFraction;
    rows(k).dynamicResidualNorm = tr.dynamicResidualNorm;
    rows(k).conditionNumber = tr.conditionNumber;
    rows(k).credible = tr.credible;
    rows(k).physicalConverged = tr.physicalConverged;
    rows(k).physicalBranchSupported = tr.physicalBranchSupported;
    rows(k).physicalStatus = tr.physicalStatus;
    rows(k).finiteReal = tr.finiteReal;
    rows(k).atLimit = any(tr.activeLimits);
    if ~tr.credible
        rows(k).failureReason = strjoin(tr.reasons,'; ');
    end
end
tableOut = struct2table(rows);
end

function row = representative_row( ...
        definition,trimTorque,trimCommand,derivative, ...
        linearTorque,linearCommand)
row = empty_representative_row();
row.pointId = definition.id;
row.mode = definition.mode;
row.betaMDeg = definition.betaMDeg;
row.speedMps = definition.speedMps;
row.thetaDeg = trimTorque.x13(8)*180/pi;
row.alphaDeg = atan2(trimTorque.x13(3),trimTorque.x13(1))*180/pi;
row.collectiveDeg = trimTorque.u10Torque(1)*180/pi;
row.cyclicLongDeg = trimTorque.u10Torque(3)*180/pi;
row.elevatorDeg = trimTorque.u10Torque(7)*180/pi;
row.dynamicResidualNorm = trimTorque.dynamicResidualNorm;
row.commandDynamicResidualNorm = ...
    trimCommand.dynamicResidualNormCommand;
row.forceResidualNormN = norm(trimTorque.forceBalanceBody);
row.momentResidualNormNm = norm(trimTorque.momentBalanceBody);
row.conditionNumber = trimTorque.conditionNumber;
row.minimumControlMarginFraction = ...
    trimTorque.minimumUnknownMarginFraction;
row.credible = trimTorque.credible && trimCommand.credible;
row.physicalConverged = trimTorque.physicalConverged;
row.physicalBranchSupported = trimTorque.physicalBranchSupported;
row.physicalStatus = trimTorque.physicalStatus;
row.linear9Finite = derivative.linearReport9.finite;
row.linear13TorqueFinite = linearTorque.finiteReal;
row.linear13CommandFinite = linearCommand.finiteReal;
row.linear13TorqueStepVariation = ...
    linearTorque.maximumRelativeStepVariation;
row.linear13CommandStepVariation = ...
    linearCommand.maximumRelativeStepVariation;
row.finiteReal = derivative.finiteReal && linearTorque.finiteReal && ...
    linearCommand.finiteReal;
end

function [metricsTable,comparisonTable,convergenceTable,trajectories] = ...
        run_step_cases(pointResults,P13,opts,trajectoryDir)
controlNames = {'elevator','aileron','rudder', ...
    'diffCollective','diffCyclic','cyclicLong'};
metricRows = repmat(empty_step_metric_row(),0,1);
comparisonRows = repmat(empty_comparison_row(),0,1);
convergenceRows = repmat(empty_convergence_row(),0,1);
trajectories = repmat(struct('pointId','','controlName','', ...
    'simulation',[]),0,1);
for pointIndex = 1:numel(pointResults)
    point = pointResults(pointIndex);
    for controlIndex = 1:numel(controlNames)
        stepAmplitude = opts.stepAmplitudeRad;
        if strcmp(point.definition.id,'B75_V080') && ...
                ismember(controlNames{controlIndex}, ...
                {'diffCollective','diffCyclic','cyclicLong'})
            % The 0.5 deg trial leaves the supported rotor branch at this
            % trim. A focused 0.25/0.10/0.05 deg check showed 0.25 deg is
            % the largest tested physically closed local disturbance.
            stepAmplitude = 0.25*pi/180;
        end
        simulations = cell(numel(opts.stepDtSeconds)+1,1);
        simulationCount = numel(opts.stepDtSeconds);
        for dtIndex = 1:numel(opts.stepDtSeconds)
            simulations{dtIndex} = simulate_direct_control_step( ...
                point.definition.id,point.trimTorque,P13, ...
                point.derivative.A9,point.derivative.B9, ...
                controlNames{controlIndex},stepAmplitude, ...
                opts.stepDtSeconds(dtIndex), ...
                opts.stepDurationSeconds);
        end
        coarsePeak = simulations{1}.metrics.primaryPeak;
        finePeak = simulations{simulationCount}.metrics.primaryPeak;
        change = abs(finePeak-coarsePeak)/max(abs(finePeak),1e-10);
        if change > opts.stepConvergenceTolerance
            simulationCount = simulationCount+1;
            simulations{simulationCount} = simulate_direct_control_step( ...
                point.definition.id,point.trimTorque,P13, ...
                point.derivative.A9,point.derivative.B9, ...
                controlNames{controlIndex},stepAmplitude, ...
                opts.stepThirdDtSeconds,opts.stepDurationSeconds);
        end
        simulations = simulations(1:simulationCount);
        finest = simulations{end};
        metricRows(end+1,1) = metric_row(finest.metrics); %#ok<AGROW>
        comparisonRows = append_comparison_rows( ...
            comparisonRows,finest,point.definition.id, ...
            controlNames{controlIndex});
        convergenceRows = append_convergence_rows( ...
            convergenceRows,simulations,point.definition.id, ...
            controlNames{controlIndex});
        fileName = sprintf('%s_%s_FINE_TRAJECTORY.csv', ...
            point.definition.id,upper(controlNames{controlIndex}));
        writetable(finest.trajectory,fullfile(trajectoryDir,fileName));
        trajectoryRow = struct('pointId',point.definition.id, ...
            'controlName',controlNames{controlIndex}, ...
            'simulation',finest);
        trajectories(end+1,1) = trajectoryRow; %#ok<AGROW>
        fprintf('Completed step response: %s %s\n', ...
            point.definition.id,controlNames{controlIndex});
    end
end
metricsTable = struct2table(metricRows);
comparisonTable = struct2table(comparisonRows);
convergenceTable = struct2table(convergenceRows);
end

function rows = append_comparison_rows(rows,simulation,pointId,controlName)
stateNames = {'u','v','w','p','q','r','phi','theta','psi'};
for stateIndex = 1:9
    errorValue = simulation.error(:,stateIndex);
    nonlinearDelta = simulation.xNonlinear(:,stateIndex)- ...
        simulation.xNonlinear(1,stateIndex);
    linearDelta = simulation.xLinear(:,stateIndex)- ...
        simulation.xLinear(1,stateIndex);
    [~,nonlinearPeakIndex] = max(abs(nonlinearDelta));
    [~,linearPeakIndex] = max(abs(linearDelta));
    row = empty_comparison_row();
    row.pointId = pointId;
    row.controlName = controlName;
    row.stateName = stateNames{stateIndex};
    row.dtSeconds = simulation.metrics.dtSeconds;
    row.peakAbsoluteError = max(abs(errorValue));
    row.rmsError = sqrt(mean(errorValue.^2));
    row.nonlinearPeak = nonlinearDelta(nonlinearPeakIndex);
    row.linearPeak = linearDelta(linearPeakIndex);
    row.peakTimeDifferenceSeconds = ...
        simulation.time(nonlinearPeakIndex)- ...
        simulation.time(linearPeakIndex);
    row.directionAgreement = sign_with_tolerance(row.nonlinearPeak) == ...
        sign_with_tolerance(row.linearPeak);
    row.status = 'LOCAL_SMALL_DISTURBANCE_COMPARISON';
    rows(end+1,1) = row; %#ok<AGROW>
end
end

function rows = append_convergence_rows( ...
        rows,simulations,pointId,controlName)
finestPeak = simulations{end}.metrics.primaryPeak;
for k = 1:numel(simulations)
    row = empty_convergence_row();
    row.pointId = pointId;
    row.controlName = controlName;
    row.dtSeconds = simulations{k}.metrics.dtSeconds;
    row.primaryStateName = simulations{k}.metrics.primaryStateName;
    row.primaryPeak = simulations{k}.metrics.primaryPeak;
    row.relativeChangeFromFinest = abs(row.primaryPeak-finestPeak)/ ...
        max(abs(finestPeak),1e-10);
    row.finiteReal = simulations{k}.metrics.finiteReal;
    row.physicalConvergedAtEveryStep = ...
        simulations{k}.metrics.physicalConvergedAtEveryStep;
    if k == numel(simulations)
        row.status = 'FINEST_STEP';
    elseif row.relativeChangeFromFinest <= 0.02
        row.status = 'CONVERGED_WITHIN_2_PERCENT';
    else
        row.status = 'REFINEMENT_SENSITIVE';
    end
    rows(end+1,1) = row; %#ok<AGROW>
end
end

function tableOut = add_relative_effectiveness(tableIn)
tableOut = tableIn;
tableOut.effectivenessPerRad = ...
    tableOut.primaryPeak./abs(tableOut.stepAmplitudeRad);
tableOut.relativeToB45V35 = NaN(height(tableOut),1);
controls = unique(tableOut.controlName,'stable');
for k = 1:numel(controls)
    mask = strcmp(tableOut.controlName,controls{k});
    referenceMask = mask & strcmp(tableOut.pointId,'B45_V035');
    if sum(referenceMask) ~= 1
        continue;
    end
    reference = tableOut.effectivenessPerRad(referenceMask);
    tableOut.relativeToB45V35(mask) = ...
        tableOut.effectivenessPerRad(mask)/max(abs(reference),1e-10);
end
end

function make_plots(figureDir,representativeTable,trimTable, ...
        staticTable,dampingTable,controlTable,modalTable, ...
        participationTable,stepMetrics,trajectories)
oldVisibility = get(0,'DefaultFigureVisible');
cleanup = onCleanup(@() set(0,'DefaultFigureVisible',oldVisibility));
set(0,'DefaultFigureVisible','off');

plot_key_derivatives(figureDir,staticTable,dampingTable,controlTable);
plot_eigenvalues(figureDir,modalTable);
plot_modal_participation(figureDir,participationTable);
plot_trim_characteristics(figureDir,trimTable);
plot_step_summary(figureDir,stepMetrics);
plot_step_trajectories(figureDir,trajectories);
plot_representative_credibility(figureDir,representativeTable);
clear cleanup;
end

function plot_key_derivatives(figureDir,staticTable,dampingTable,controlTable)
specification = {
    staticTable,'Cm_alpha','C_{m\alpha}'
    staticTable,'Cn_betaSlip','C_{n\beta}'
    dampingTable,'Cl_p','C_{lp}'
    dampingTable,'Cm_q','C_{mq}'
    dampingTable,'Cn_r','C_{nr}'
    controlTable,'Cm_elevator','C_{m\delta_e}'
    controlTable,'Cl_aileron','C_{l\delta_a}'
    controlTable,'Cn_rudder','C_{n\delta_r}'
    };
pointIds = {'B15_V020','B45_V035','B75_V080'};
values = NaN(numel(pointIds),size(specification,1));
for metricIndex = 1:size(specification,1)
    T = specification{metricIndex,1};
    for pointIndex = 1:numel(pointIds)
        mask = strcmp(T.pointId,pointIds{pointIndex}) & ...
            strcmp(T.coefficientName,specification{metricIndex,2}) & ...
            T.stepLevel == 2;
        if any(mask)
            values(pointIndex,metricIndex) = T.coefficientDerivative(mask);
        end
    end
end
f = figure('Position',[100,100,1300,650]);
bar(values.');
grid on;
set(gca,'XTick',1:size(specification,1), ...
    'XTickLabel',specification(:,3));
ylabel('dimensionless derivative');
legend(pointIds,'Location','best');
title('Key direct load derivatives at representative trim points');
print(f,fullfile(figureDir,'FIG01_KEY_DERIVATIVES.png'),'-dpng','-r180');
close(f);
end

function plot_eigenvalues(figureDir,T)
f = figure('Position',[100,100,1100,700]);
models = unique(T.modelKind,'stable');
colors = lines(numel(models));
hold on;
for k = 1:numel(models)
    mask = strcmp(T.modelKind,models{k});
    scatter(T.realPartPerSecond(mask),T.imagPartRadPerSecond(mask), ...
        35,colors(k,:),'filled','DisplayName',models{k});
end
xline(0,'k--');
grid on;
xlabel('real part (1/s)');
ylabel('imaginary part (rad/s)');
title('Open-loop eigenvalues: nine-state and thirteen-state models');
legend('Location','best');
print(f,fullfile(figureDir,'FIG02_OPEN_LOOP_EIGENVALUES.png'), ...
    '-dpng','-r180');
close(f);
end

function plot_modal_participation(figureDir,T)
mask = strcmp(T.pointId,'B45_V035') & ...
    strcmp(T.modelKind,'THIRTEEN_STATE_ANGLE_COMMAND');
S = T(mask,:);
modeIndices = unique(S.modeIndex);
stateNames = unique(S.stateName,'stable');
matrix = NaN(numel(stateNames),numel(modeIndices));
for i = 1:numel(stateNames)
    for j = 1:numel(modeIndices)
        row = strcmp(S.stateName,stateNames{i}) & ...
            S.modeIndex == modeIndices(j);
        matrix(i,j) = S.normalizedMagnitude(row);
    end
end
f = figure('Position',[100,100,1200,700]);
imagesc(matrix);
colorbar;
set(gca,'YTick',1:numel(stateNames),'YTickLabel',stateNames, ...
    'XTick',1:numel(modeIndices),'XTickLabel',modeIndices);
xlabel('local mode index');
ylabel('state');
title('Normalized participation magnitude at B45 V35');
print(f,fullfile(figureDir,'FIG03_MODAL_PARTICIPATION.png'), ...
    '-dpng','-r180');
close(f);
end

function plot_trim_characteristics(figureDir,T)
credible = T.credible;
f = figure('Position',[100,100,1300,800]);
metrics = {'collectiveDeg','cyclicLongDeg','elevatorDeg', ...
    'thetaDeg','alphaDeg','minimumControlMarginFraction'};
labels = {'collective (deg)','cyclicLong (deg)','elevator (deg)', ...
    'pitch attitude (deg)','angle of attack (deg)', ...
    'minimum control margin fraction'};
modes = unique(T.mode,'stable');
colors = lines(numel(modes));
for metricIndex = 1:numel(metrics)
    subplot(2,3,metricIndex);
    hold on;
    for modeIndex = 1:numel(modes)
        mask = credible & strcmp(T.mode,modes{modeIndex});
        [speed,order] = sort(T.speedMps(mask));
        value = T.(metrics{metricIndex})(mask);
        plot(speed,value(order),'o-', ...
            'Color',colors(modeIndex,:), ...
            'DisplayName',modes{modeIndex});
    end
    grid on;
    xlabel('speed (m/s)');
    ylabel(labels{metricIndex});
    if metricIndex == 1
        legend('Location','best');
    end
end
sgtitle('Explicit-mode discrete trim characteristics');
print(f,fullfile(figureDir,'FIG04_TRIM_CHARACTERISTICS_BY_MODE.png'), ...
    '-dpng','-r180');
close(f);
end

function plot_step_summary(figureDir,T)
controls = unique(T.controlName,'stable');
pointIds = {'B15_V020','B45_V035','B75_V080'};
values = NaN(numel(controls),numel(pointIds));
for i = 1:numel(controls)
    for j = 1:numel(pointIds)
        mask = strcmp(T.controlName,controls{i}) & ...
            strcmp(T.pointId,pointIds{j});
        values(i,j) = T.effectivenessPerRad(mask);
    end
end
f = figure('Position',[100,100,1200,700]);
bar(values);
set(gca,'XTick',1:numel(controls),'XTickLabel',controls);
xtickangle(25);
grid on;
ylabel('primary angular-rate peak per radian command');
legend(pointIds,'Location','best');
title('Relative direct-control effectiveness');
print(f,fullfile(figureDir,'FIG05_CONTROL_EFFECTIVENESS.png'), ...
    '-dpng','-r180');
close(f);
end

function plot_step_trajectories(figureDir,trajectories)
controls = unique({trajectories.controlName},'stable');
pointIds = {'B15_V020','B45_V035','B75_V080'};
rateLabels = {'p','q','r'};
colors = lines(numel(pointIds));
for controlIndex = 1:numel(controls)
    f = figure('Position',[100,100,1200,800]);
    for stateLocal = 1:3
        subplot(3,1,stateLocal);
        hold on;
        for pointIndex = 1:numel(pointIds)
            mask = strcmp({trajectories.controlName},controls{controlIndex}) & ...
                strcmp({trajectories.pointId},pointIds{pointIndex});
            simulation = trajectories(find(mask,1)).simulation;
            stateIndex = stateLocal+3;
            delta = simulation.xNonlinear(:,stateIndex)- ...
                simulation.xNonlinear(1,stateIndex);
            plot(simulation.time,delta,'Color',colors(pointIndex,:), ...
                'DisplayName',pointIds{pointIndex});
        end
        grid on;
        ylabel(sprintf('%s deviation (rad/s)', ...
            rateLabels{stateLocal}));
        if stateLocal == 1
            title(sprintf('%s direct physical-control step', ...
                controls{controlIndex}));
            legend('Location','best');
        end
    end
    xlabel('time (s)');
    fileName = sprintf('STEP_%s_BODY_RATES.png', ...
        upper(controls{controlIndex}));
    print(f,fullfile(figureDir,fileName),'-dpng','-r180');
    close(f);
end
end

function plot_representative_credibility(figureDir,T)
f = figure('Position',[100,100,1100,550]);
yyaxis left;
semilogy(1:height(T),T.dynamicResidualNorm,'o-','LineWidth',1.5);
ylabel('dynamic residual norm');
yyaxis right;
plot(1:height(T),T.minimumControlMarginFraction,'s-', ...
    'LineWidth',1.5);
ylabel('minimum control margin fraction');
set(gca,'XTick',1:height(T),'XTickLabel',T.pointId);
grid on;
title('Representative-point credibility diagnostics');
print(f,fullfile(figureDir,'FIG06_REPRESENTATIVE_CREDIBILITY.png'), ...
    '-dpng','-r180');
close(f);
end

function signValue = sign_with_tolerance(value)
if abs(value) <= 1e-10
    signValue = 0;
else
    signValue = sign(value);
end
end

function row = empty_trim_row()
row = struct('pointId','','mode','','speedMps',NaN,'betaMDeg',NaN, ...
    'thetaDeg',NaN,'alphaDeg',NaN,'collectiveDeg',NaN, ...
    'cyclicLongDeg',NaN,'pitchCommand',NaN,'elevatorDeg',NaN, ...
    'minimumControlMarginFraction',NaN,'dynamicResidualNorm',NaN, ...
    'conditionNumber',NaN,'status','','credible',false, ...
    'physicalConverged',false,'physicalBranchSupported',false, ...
    'physicalStatus','','finiteReal',false,'atLimit',false, ...
    'failureReason','','claimBoundary','');
end

function row = empty_representative_row()
row = struct('pointId','','mode','','betaMDeg',NaN,'speedMps',NaN, ...
    'thetaDeg',NaN,'alphaDeg',NaN,'collectiveDeg',NaN, ...
    'cyclicLongDeg',NaN,'elevatorDeg',NaN, ...
    'dynamicResidualNorm',NaN,'commandDynamicResidualNorm',NaN, ...
    'forceResidualNormN',NaN,'momentResidualNormNm',NaN, ...
    'conditionNumber',NaN,'minimumControlMarginFraction',NaN, ...
    'credible',false,'physicalConverged',false, ...
    'physicalBranchSupported',false,'physicalStatus','', ...
    'linear9Finite',false,'linear13TorqueFinite',false, ...
    'linear13CommandFinite',false, ...
    'linear13TorqueStepVariation',NaN, ...
    'linear13CommandStepVariation',NaN,'finiteReal',false);
end

function row = empty_step_metric_row()
template = struct();
template.pointId = '';
template.controlName = '';
template.stepAmplitudeRad = NaN;
template.stepAmplitudeDeg = NaN;
template.stepSelectionBasis = '';
template.dtSeconds = NaN;
template.durationSeconds = NaN;
template.stepStartSeconds = NaN;
template.initialPdotRadPerSecond2 = NaN;
template.initialQdotRadPerSecond2 = NaN;
template.initialRdotRadPerSecond2 = NaN;
template.pPeakRadPerSecond = NaN;
template.pPeakTimeSeconds = NaN;
template.qPeakRadPerSecond = NaN;
template.qPeakTimeSeconds = NaN;
template.rPeakRadPerSecond = NaN;
template.rPeakTimeSeconds = NaN;
template.phiPeakRad = NaN;
template.phiPeakTimeSeconds = NaN;
template.thetaPeakRad = NaN;
template.thetaPeakTimeSeconds = NaN;
template.psiPeakRad = NaN;
template.psiPeakTimeSeconds = NaN;
template.primaryStateName = '';
template.primaryPeak = NaN;
template.primaryPeakTimeSeconds = NaN;
template.peakBasedRiseTimeSeconds = NaN;
template.endpointOvershootPercent = NaN;
template.validDomainDurationSeconds = NaN;
template.firstInvalidIndex = NaN;
template.firstInvalidReason = '';
template.maximumLinearNonlinearStateError = NaN;
template.rmsLinearNonlinearStateError = NaN;
template.physicalConvergedAtEveryStep = false;
template.validAtEveryStep = false;
template.finiteReal = false;
row = template;
end

function row = metric_row(metrics)
row = empty_step_metric_row();
names = fieldnames(row);
for k = 1:numel(names)
    row.(names{k}) = metrics.(names{k});
end
end

function row = empty_comparison_row()
row = struct('pointId','','controlName','','stateName','', ...
    'dtSeconds',NaN,'peakAbsoluteError',NaN,'rmsError',NaN, ...
    'nonlinearPeak',NaN,'linearPeak',NaN, ...
    'peakTimeDifferenceSeconds',NaN,'directionAgreement',false, ...
    'status','');
end

function row = empty_convergence_row()
row = struct('pointId','','controlName','','dtSeconds',NaN, ...
    'primaryStateName','','primaryPeak',NaN, ...
    'relativeChangeFromFinest',NaN,'finiteReal',false, ...
    'physicalConvergedAtEveryStep',false,'status','');
end
