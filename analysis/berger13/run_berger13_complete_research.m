function results = run_berger13_complete_research(outputDir,forceRecompute)
%RUN_BERGER13_COMPLETE_RESEARCH Reproducible PR4 research/data workflow.

if nargin < 1 || isempty(outputDir)
    error('run_berger13_complete_research:OutputRequired', ...
        'An explicit output directory is required.');
end
if nargin < 2, forceRecompute = false; end
if ~exist(outputDir,'dir')
    mkdir(outputDir);
end
rawDir = fullfile(outputDir,'raw_data');
figureDir = fullfile(outputDir,'figures');
if ~exist(rawDir,'dir'), mkdir(rawDir); end
if ~exist(figureDir,'dir'), mkdir(figureDir); end

resultsCache = fullfile(outputDir,'13X10_RESEARCH_RESULTS.mat');
sensitivityCache = fullfile(outputDir,'13X10_SENSITIVITY_RESULTS.csv');
if ~forceRecompute && exist(resultsCache,'file') && ...
        exist(sensitivityCache,'file')
    cached = load(resultsCache,'results');
    results = cached.results;
    results.outputDir = outputDir;
    plot_berger13_research_outputs(results,figureDir,rawDir);
    return;
end

P13 = params_berger13();
trimCache = fullfile(rawDir,'PR2_LINEAR_MODEL_DATABASE.mat');
linearCache = fullfile(outputDir,'13X10_LINEAR_MODEL_DATABASE.mat');
derivativeCache = fullfile(outputDir,'13X10_DERIVATIVE_DATABASE.csv');
eigenCache = fullfile(outputDir,'13X10_EIGENVALUE_DATABASE.csv');
trackingCache = fullfile(outputDir,'13X10_MODE_TRACKING_DATABASE.csv');
reuseExisting = ~forceRecompute && exist(trimCache,'file') && ...
    exist(linearCache,'file') && ...
    exist(derivativeCache,'file') && exist(eigenCache,'file') && ...
    exist(trackingCache,'file');
if reuseExisting
    trimData = load(trimCache,'database');
    linearData = load(linearCache,'linearDatabase');
    trimDatabase = trimData.database;
    linearDatabase = linearData.linearDatabase;
    crediblePointIds = linearDatabase.pointIds;
    commandTrims = linearDatabase.commandTrims;
    linearModels = linearDatabase.linearModels;
    derivativeTable = readtable(derivativeCache);
    eigenTable = readtable(eigenCache);
    tracking.table = readtable(trackingCache);
    tracking.method = ['independent continuous paths with reserved heading ' ...
        'integrator and Hungarian dynamic-mode assignment'];
    tracking.crossGapAssignment = false;
else
    trimDatabase = build_berger13_pr2_database(rawDir);
    writetable(trimDatabase.summary, ...
        fullfile(outputDir,'13X10_TRIM_POINT_DATABASE.csv'));
    nCredible = trimDatabase.credibleCount;
    linearModels = cell(nCredible,1);
    commandTrims = cell(nCredible,1);
    modalModels = cell(nCredible,1);
    crediblePointIds = cell(nCredible,1);
    trackingPathIds = cell(nCredible,1);
    derivativeRows = {};
    eigenTables = cell(nCredible,1);
    credibleIndex = 0;
    for k = 1:numel(trimDatabase.points)
        point = trimDatabase.points(k);
        if ~strcmp(point.status,'CREDIBLE'), continue; end
        opts = struct('mode',point.mode,'torqueTrimReport',point.trim);
        [~,~,commandTrim] = trim_berger13_command_symmetric( ...
            point.condition,P13,opts);
        linearModel = linearize_berger13_command_trim_point(commandTrim,P13);
        inputNames = get_command_input_names_13x10();
        inputNames(9:10) = {'betaSymCommand';'betaDiffCommand'};
        modal = analyze_berger13_modes(linearModel.symdiff.A, ...
            linearModel.symdiff.B,linearModel.symdiff.stateNames,inputNames);
        credibleIndex = credibleIndex+1;
        crediblePointIds{credibleIndex} = point.id;
        trackingPathIds{credibleIndex} = sprintf('B%02d_SPEED_PATH', ...
            round(point.condition.betaM*180/pi));
        commandTrims{credibleIndex} = commandTrim;
        linearModels{credibleIndex} = linearModel;
        modalModels{credibleIndex} = modal;
        derivativeRows = [derivativeRows; derivative_records( ...
            point,commandTrim,linearModel)]; %#ok<AGROW>
        tablePoint = modal.table;
        tablePoint.pointId = repmat({point.id},height(tablePoint),1);
        tablePoint.betaMDeg = repmat(point.condition.betaM*180/pi, ...
            height(tablePoint),1);
        tablePoint.speedMps = repmat(point.condition.V,height(tablePoint),1);
        eigenTables{credibleIndex} = tablePoint;
    end
    derivativeTable = cell2table(derivativeRows,'VariableNames', ...
        {'pointId','betaMDeg','speedMps','derivativeName','value', ...
        'outputName','inputName','units','differenceStep','limitActive', ...
        'maximumMatrixStepVariation','parameterSource'});
    eigenTable = vertcat(eigenTables{:});
    tracking = track_berger13_modes( ...
        modalModels,crediblePointIds,trackingPathIds);
    writetable(derivativeTable,derivativeCache);
    writetable(eigenTable,eigenCache);
    writetable(tracking.table,trackingCache);
    linearDatabase.pointIds = crediblePointIds;
    linearDatabase.commandTrims = commandTrims;
    linearDatabase.linearModels = linearModels;
    linearDatabase.modalModels = modalModels;
    linearDatabase.trackingPathIds = trackingPathIds;
    linearDatabase.stateContract = get_state_names_13x10();
    linearDatabase.commandInputContract = get_command_input_names_13x10();
    linearDatabase.claimBoundary = ['CREDIBLE internal trim points only; ' ...
        'not external validation'];
    save(linearCache,'linearDatabase','-v7');
end

representativeIndex = find(strcmp(crediblePointIds,'B45_V035'),1);
if isempty(representativeIndex)
    error('run_berger13_complete_research:MissingRepresentativePoint', ...
        'B45_V035 must remain CREDIBLE for the representative workflow.');
end
representativeTrim = commandTrims{representativeIndex};
representativeLinear = linearModels{representativeIndex};

[timeSimulations,timeSummary,timeStepConvergence] = run_time_cases( ...
    representativeTrim,P13,rawDir);
writetable(timeSummary, ...
    fullfile(outputDir,'13X10_TIME_DOMAIN_CASES.csv'));

[comparisons,comparisonTable] = run_comparisons( ...
    representativeTrim,representativeLinear,P13,rawDir);
writetable(comparisonTable, ...
    fullfile(rawDir,'13X10_LINEAR_NONLINEAR_METRICS.csv'));

if ~forceRecompute && exist(sensitivityCache,'file')
    sensitivityTable = readtable(sensitivityCache);
else
    sensitivityTable = run_berger13_sensitivity_corrected( ...
        representativeTrim,P13);
end
writetable(sensitivityTable, ...
    fullfile(outputDir,'13X10_SENSITIVITY_RESULTS.csv'));

results.trimDatabase = trimDatabase;
results.linearDatabase = linearDatabase;
results.derivativeTable = derivativeTable;
results.eigenTable = eigenTable;
results.tracking = tracking;
results.timeSimulations = timeSimulations;
results.timeSummary = timeSummary;
results.timeStepConvergence = timeStepConvergence;
results.comparisons = comparisons;
results.comparisonTable = comparisonTable;
results.sensitivityTable = sensitivityTable;
results.representativePointId = 'B45_V035';
results.outputDir = outputDir;
results.finiteReal = check_finite(results);
results.claimBoundary = ['low-order internally consistent research output; ' ...
    'prescribed nacelle motion affects rigid-body dynamics one-way; not ' ...
    'Berger 51-state reproduction, XV-15 validation, or a safety envelope'];
save(fullfile(outputDir,'13X10_RESEARCH_RESULTS.mat'),'results','-v7');
plot_berger13_research_outputs(results,figureDir,rawDir);
end

function rows = derivative_records(point,trimReport,linearModel)
A = linearModel.A13Command;
Asd = linearModel.symdiff.A;
Bsd = linearModel.symdiff.B;
betaDeg = point.condition.betaM*180/pi;
speed = point.condition.V;
variation = linearModel.maximumRelativeStepVariation;
limitActive = any(trimReport.activeLimits);
source = 'NUMERICAL_THREE_STEP_INTERNAL';
rows = {};
stateItems = { ...
    'Xu',1,1;'Xw',1,3;'Zu',3,1;'Zw',3,3;'Mu',5,1;'Mw',5,3; ...
    'Mq',5,5;'Yv',2,2;'Yp',2,4;'Yr',2,6;'Lv',4,2; ...
    'Lp',4,4;'Lr',4,6;'Nv',6,2;'Np',6,4;'Nr',6,6};
contract = berger13_derivative_contract();
stateNames = contract.stateNames;
for k = 1:size(stateItems,1)
    row = stateItems{k,2};
    column = stateItems{k,3};
    rows(end+1,:) = make_row(point.id,betaDeg,speed,stateItems{k,1}, ...
        A(row,column),stateNames{row},stateNames{column}, ...
        berger13_derivative_unit(stateNames{row},stateNames{column}), ...
        linearModel.stepScaleModels(2).report.dx(column),limitActive, ...
        variation,source); %#ok<AGROW>
end
axisNames = {'betaSym','betaDiff','betaSymDot','betaDiffDot'};
for row = 1:6
    for localColumn = 1:4
        column = 9+localColumn;
        name = sprintf('d%s_d%s',stateNames{row},axisNames{localColumn});
        rows(end+1,:) = make_row(point.id,betaDeg,speed,name, ...
            Asd(row,column),stateNames{row},axisNames{localColumn}, ...
            berger13_derivative_unit(stateNames{row}, ...
            axisNames{localColumn}), ...
            linearModel.stepScaleModels(2).report.dx(column),limitActive, ...
            variation,source); %#ok<AGROW>
    end
end
inputColumns = [9,10,5,6,8];
inputNames = {'betaSymCommand','betaDiffCommand', ...
    'lateralCyclic','aileron','rudder'};
for row = 1:6
    for localColumn = 1:numel(inputColumns)
        column = inputColumns(localColumn);
        name = sprintf('d%s_d%s',stateNames{row},inputNames{localColumn});
        rows(end+1,:) = make_row(point.id,betaDeg,speed,name, ...
            Bsd(row,column),stateNames{row},inputNames{localColumn}, ...
            berger13_derivative_unit(stateNames{row}, ...
            inputNames{localColumn}), ...
            linearModel.stepScaleModels(2).report.du(column),limitActive, ...
            variation,source); %#ok<AGROW>
    end
end
end

function row = make_row(id,beta,speed,name,value,output,input,units, ...
        step,limit,variation,source)
row = {id,beta,speed,name,value,output,input,units,step,limit,variation,source};
end

function [simulations,summary,convergenceTable] = run_time_cases( ...
        trimReport,P13,rawDir)
d2r = pi/180;
base = struct('duration',5,'dt',0.1,'startTime',1, ...
    'amplitude',2*d2r,'inputType','betaSym');
cases = {};
cases{end+1} = named(base,'symmetric_nacelle_step');
ramp = named(base,'symmetric_nacelle_ramp');
ramp.inputType = 'ramp'; ramp.amplitude = 8*d2r; ramp.rampDuration = 2;
cases{end+1} = ramp;
diffCase = named(base,'differential_nacelle_step');
diffCase.inputType = 'betaDiff'; diffCase.amplitude = 1*d2r;
cases{end+1} = diffCase;
rateCase = named(base,'left_rate_limit_reduction');
rateCase.amplitude = 8*d2r;
rateCase.leftActuator = struct('rateScale',0.35);
cases{end+1} = rateCase;
wnCase = named(base,'left_bandwidth_reduction');
wnCase.amplitude = 5*d2r;
wnCase.leftActuator = struct('omegaN',2.5);
wnCase.rightActuator = struct('omegaN',5.0);
cases{end+1} = wnCase;
zetaCase = named(base,'left_right_damping_mismatch');
zetaCase.amplitude = 5*d2r;
zetaCase.leftActuator = struct('zeta',0.45);
zetaCase.rightActuator = struct('zeta',1.10);
cases{end+1} = zetaCase;
delayCase = named(base,'left_command_delay');
delayCase.amplitude = 5*d2r;
delayCase.leftActuator = struct('commandDelay',0.30);
cases{end+1} = delayCase;
lockCase = named(base,'left_kinematic_lock');
lockCase.amplitude = 5*d2r;
lockCase.leftActuator = struct('kinematicLock',true);
cases{end+1} = lockCase;
degradeCase = named(base,'left_rate_degradation');
degradeCase.amplitude = 5*d2r;
degradeCase.leftActuator = struct('rateScale',0.20);
cases{end+1} = degradeCase;
freezeCase = named(base,'left_command_freeze');
freezeCase.amplitude = 5*d2r;
freezeCase.leftActuator = struct('commandFreeze',true, ...
    'frozenCommand',trimReport.x13(10)+1*d2r);
cases{end+1} = freezeCase;
lat = named(base,'conversion_lateral_cyclic_pulse');
lat.inputType = 'lateralCyclic'; lat.amplitude = 0.5*d2r;
lat.pulseEndTime = 2.5;
cases{end+1} = lat;
latOpen = named(base,'lateral_cyclic_open_loop');
latOpen.inputType = 'lateralCyclic'; latOpen.amplitude = 0.25*d2r;
cases{end+1} = latOpen;
ail = named(base,'aileron_open_loop');
ail.inputType = 'aileron'; ail.amplitude = 0.5*d2r;
cases{end+1} = ail;
rud = named(base,'rudder_open_loop');
rud.inputType = 'rudder'; rud.amplitude = 0.5*d2r;
cases{end+1} = rud;

simulations = cell(numel(cases),1);
summaryRows = cell(numel(cases),19);
convergenceRows = {};
convergencePath = fullfile(fileparts(rawDir), ...
    '13X10_TIME_STEP_CONVERGENCE.csv');
if exist(convergencePath,'file')
    archivedConvergence = readtable(convergencePath);
else
    archivedConvergence = table();
end
for k = 1:numel(cases)
    archivedMask = ~strcmp(cases{k}.name,'left_command_freeze') && ...
        ~isempty(archivedConvergence) && ...
        any(strcmp(archivedConvergence.caseName,cases{k}.name));
    if archivedMask
        caseRowsTable = archivedConvergence( ...
            strcmp(archivedConvergence.caseName,cases{k}.name),:);
        if ~caseRowsTable.peakGatePassed(end)
            error('run_berger13_complete_research:InvalidCheckpoint', ...
                'Archived convergence for %s did not pass.',cases{k}.name);
        end
        finalCase = cases{k};
        finalCase.dt = caseRowsTable.fineDt(end);
        simulations{k} = simulate_berger13_case( ...
            trimReport,P13,finalCase);
        simulations{k}.timeStepConverged = true;
        simulations{k}.timeStepTolerance = 0.02;
        simulations{k}.quantitativeClaimAllowed = ...
            simulations{k}.quantitativeClaimAllowed && ...
            simulations{k}.timeStepConverged;
        caseRows = table2cell(caseRowsTable);
    else
        [simulations{k},caseRows] = converged_simulation( ...
            trimReport,P13,cases{k});
    end
    convergenceRows = [convergenceRows;caseRows]; %#ok<AGROW>
    sim = simulations{k};
    summaryRows(k,:) = {cases{k}.name,cases{k}.inputType, ...
        cases{k}.amplitude,cases{k}.duration,sim.caseDef.dt, ...
        sim.validPrefixMetrics.maxAttitudeDeviationRad, ...
        sim.validPrefixMetrics.maxAngularRateRadPerSecond, ...
        sim.validPrefixMetrics.maxBetaDiffRad, ...
        sim.validPrefixMetrics.maxAbsRollMomentNm, ...
        sim.validPrefixMetrics.maxAbsYawMomentNm, ...
        sim.validPrefixMetrics.recoveryTimeSeconds, ...
        sim.fullTrajectoryMetrics.maxAttitudeDeviationRad, ...
        sim.fullTrajectoryMetrics.maxAbsRollMomentNm, ...
        sim.fullTrajectoryMetrics.maxAbsYawMomentNm, ...
        sim.firstEnvelopeViolationTime,sim.violationReason, ...
        sim.validPrefixEndIndex,sim.quantitativeClaimAllowed, ...
        sim.diverged || ~sim.finiteReal};
    [speed,alpha,sideslip] = guard_columns(sim);
    timeTable = array2table([sim.time,sim.x,sim.betaSym,sim.betaDiff, ...
        sim.lateralForceRollYawMoment,double(sim.limitActive), ...
        double(sim.guardValid),speed,alpha,sideslip], ...
        'VariableNames',[{'time'},get_state_names_13x10().', ...
        {'betaSym','betaDiff','lateralForceN','rollMomentNm', ...
        'yawMomentNm','limitActive','analysisGuardValid','bodySpeedMps', ...
        'alphaRad','sideslipRad'}]);
    writetable(timeTable,fullfile(rawDir,[cases{k}.name '.csv']));
end
summary = cell2table(summaryRows,'VariableNames', ...
    {'caseName','inputType','amplitudeRad','durationSeconds','archiveDt', ...
    'validMaxAttitudeDeviationRad','validMaxAngularRateRadPerSecond', ...
    'validMaxBetaDiffRad','validMaxAbsRollMomentNm', ...
    'validMaxAbsYawMomentNm','validRecoveryTimeSeconds', ...
    'fullMaxAttitudeDeviationRad','fullMaxAbsRollMomentNm', ...
    'fullMaxAbsYawMomentNm','firstEnvelopeViolationTime', ...
    'violationReason','validPrefixEndIndex','quantitativeClaimAllowed', ...
    'diverged'});
convergenceTable = cell2table(convergenceRows,'VariableNames', ...
    {'caseName','coarseDt','fineDt','maxBetaDiffRelativeChange', ...
    'rollMomentRelativeChange','yawMomentRelativeChange', ...
    'attitudeRelativeChange','angularRateRelativeChange', ...
    'recoveryTimeRelativeChange','violationTimeRelativeChange', ...
    'peakGatePassed'});
writetable(convergenceTable,convergencePath);
end

function [simulation,rows] = converged_simulation(trimReport,P13,caseDef)
dtValues = [0.1,0.05,0.025];
sims = cell(3,1);
for k = 1:3
    candidate = caseDef;
    candidate.dt = dtValues(k);
    sims{k} = simulate_berger13_case(trimReport,P13,candidate);
end
rows = {};
[rows,~] = append_convergence(rows,caseDef.name,sims{1},sims{2});
[rows,passed] = append_convergence(rows,caseDef.name, ...
    sims{2},sims{3});
if passed
    simulation = sims{3};
else
    extraDt = [0.0125,0.00625,0.003125];
    previous = sims{3};
    simulation = [];
    for extraIndex = 1:numel(extraDt)
        candidate = caseDef;
        candidate.dt = extraDt(extraIndex);
        current = simulate_berger13_case(trimReport,P13,candidate);
        [rows,passed] = append_convergence( ...
            rows,caseDef.name,previous,current);
        if passed
            simulation = current;
            break;
        end
        previous = current;
    end
    if isempty(simulation)
        error('run_berger13_complete_research:TimeStepNotConverged', ...
            ['Case %s did not pass the 2%% adjacent-step peak gate ' ...
            'through dt=0.003125 s.'],caseDef.name);
    end
end
simulation.timeStepConverged = true;
simulation.timeStepTolerance = 0.02;
simulation.quantitativeClaimAllowed = ...
    simulation.quantitativeClaimAllowed && simulation.timeStepConverged;
end

function [rows,passed] = append_convergence(rows,name,coarse,fine)
coarseValues = convergence_metrics(coarse);
fineValues = convergence_metrics(fine);
changes = relative_changes(coarseValues,fineValues);
peakIndices = 1:5;
passed = all(changes(peakIndices) <= 0.02);
rows(end+1,:) = {name,coarse.caseDef.dt,fine.caseDef.dt, ...
    changes(1),changes(2),changes(3),changes(4),changes(5), ...
    changes(6),changes(7),passed};
end

function values = convergence_metrics(sim)
m = sim.validPrefixMetrics;
values = [m.maxBetaDiffRad,m.maxAbsRollMomentNm, ...
    m.maxAbsYawMomentNm,m.maxAttitudeDeviationRad, ...
    m.maxAngularRateRadPerSecond,m.recoveryTimeSeconds, ...
    sim.firstEnvelopeViolationTime];
end

function changes = relative_changes(a,b)
changes = zeros(size(a));
% A pure relative error is undefined for symmetry-enforced zero responses.
% Floors are dimensioned numerical comparison scales, not model tuning:
% [rad, N*m, N*m, rad, rad/s, s, s].
comparisonFloor = [1e-6,1,1,1e-6,1e-6,0.025,0.025];
for k = 1:numel(a)
    if isnan(a(k)) && isnan(b(k))
        changes(k) = 0;
    elseif ~isfinite(a(k)) || ~isfinite(b(k))
        changes(k) = Inf;
    else
        changes(k) = abs(b(k)-a(k))/ ...
            max([abs(a(k)),abs(b(k)),comparisonFloor(k)]);
    end
end
end

function [speed,alpha,sideslip] = guard_columns(sim)
n = numel(sim.guardDiagnostics);
speed = NaN(n,1); alpha = NaN(n,1); sideslip = NaN(n,1);
for k = 1:n
    if isempty(sim.guardDiagnostics{k}), continue; end
    speed(k) = sim.guardDiagnostics{k}.bodySpeedMps;
    alpha(k) = sim.guardDiagnostics{k}.alphaRad;
    sideslip(k) = sim.guardDiagnostics{k}.sideslipRad;
end
end

function value = named(base,name)
value = base;
value.name = name;
end

function [comparisons,tableOut] = run_comparisons( ...
        trimReport,linearModel,P13,rawDir)
d2r = pi/180;
types = {'betaSym','betaDiff','lateralCyclic','aileron','rudder'};
amplitudes = [0.05,0.05,0.02,0.05,0.05]*d2r;
comparisons = cell(numel(types),1);
tables = cell(numel(types),1);
for k = 1:numel(types)
    def = struct('name',['linear_nonlinear_' types{k}], ...
        'duration',4,'dt',0.05,'inputType',types{k}, ...
        'amplitude',amplitudes(k),'startTime',0.5);
    comparisons{k} = compare_berger13_linear_nonlinear( ...
        trimReport,linearModel,P13,def);
    metrics = comparisons{k}.metrics;
    metrics.caseName = repmat({def.name},height(metrics),1);
    metrics.amplitudeRad = repmat(def.amplitude,height(metrics),1);
    tables{k} = metrics;
    raw = array2table([comparisons{k}.time,comparisons{k}.nonlinear, ...
        comparisons{k}.linear,comparisons{k}.error]);
    writetable(raw,fullfile(rawDir,[def.name '.csv']));
end
tableOut = vertcat(tables{:});
end

function finite = check_finite(results)
finite = all(isfinite(results.derivativeTable.value)) && ...
    all(isfinite(results.eigenTable.realPartPerSecond)) && ...
    all(isfinite(results.eigenTable.imagPartRadPerSecond));
for k = 1:numel(results.timeSimulations)
    finite = finite && results.timeSimulations{k}.finiteReal;
end
end
