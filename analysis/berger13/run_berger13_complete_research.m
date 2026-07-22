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
reuseExisting = exist(trimCache,'file') && exist(linearCache,'file') && ...
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
    tracking.method = ['Hungarian global adjacent assignment; cost=0.35 ' ...
        'normalized eigenvalue distance + 0.45*(1-MAC) + 0.20 ' ...
        'participation L1 distance'];
else
    trimDatabase = build_berger13_pr2_database(rawDir);
    writetable(trimDatabase.summary, ...
        fullfile(outputDir,'13X10_TRIM_POINT_DATABASE.csv'));
    nCredible = trimDatabase.credibleCount;
    linearModels = cell(nCredible,1);
    commandTrims = cell(nCredible,1);
    modalModels = cell(nCredible,1);
    crediblePointIds = cell(nCredible,1);
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
    tracking = track_berger13_modes(modalModels,crediblePointIds);
    writetable(derivativeTable,derivativeCache);
    writetable(eigenTable,eigenCache);
    writetable(tracking.table,trackingCache);
    linearDatabase.pointIds = crediblePointIds;
    linearDatabase.commandTrims = commandTrims;
    linearDatabase.linearModels = linearModels;
    linearDatabase.modalModels = modalModels;
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

[timeSimulations,timeSummary] = run_time_cases( ...
    representativeTrim,P13,rawDir);
writetable(timeSummary, ...
    fullfile(outputDir,'13X10_TIME_DOMAIN_CASES.csv'));

[comparisons,comparisonTable] = run_comparisons( ...
    representativeTrim,representativeLinear,P13,rawDir);
writetable(comparisonTable, ...
    fullfile(rawDir,'13X10_LINEAR_NONLINEAR_METRICS.csv'));

sensitivityTable = run_sensitivity(representativeTrim,P13);
writetable(sensitivityTable, ...
    fullfile(outputDir,'13X10_SENSITIVITY_RESULTS.csv'));

results.trimDatabase = trimDatabase;
results.linearDatabase = linearDatabase;
results.derivativeTable = derivativeTable;
results.eigenTable = eigenTable;
results.tracking = tracking;
results.timeSimulations = timeSimulations;
results.timeSummary = timeSummary;
results.comparisons = comparisons;
results.comparisonTable = comparisonTable;
results.sensitivityTable = sensitivityTable;
results.representativePointId = 'B45_V035';
results.outputDir = outputDir;
results.finiteReal = check_finite(results);
results.claimBoundary = ['low-order internally consistent research output; ' ...
    'not Berger 51-state reproduction or XV-15 validation'];
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
stateNames = get_state_names_13x10();
for k = 1:size(stateItems,1)
    row = stateItems{k,2};
    column = stateItems{k,3};
    rows(end+1,:) = make_row(point.id,betaDeg,speed,stateItems{k,1}, ...
        A(row,column),stateNames{row},stateNames{column}, ...
        derivative_unit(row,column,false), ...
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
            derivative_unit(row,column,false), ...
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
            derivative_unit(row,column,true), ...
            linearModel.stepScaleModels(2).report.du(column),limitActive, ...
            variation,source); %#ok<AGROW>
    end
end
end

function row = make_row(id,beta,speed,name,value,output,input,units, ...
        step,limit,variation,source)
row = {id,beta,speed,name,value,output,input,units,step,limit,variation,source};
end

function unit = derivative_unit(outputIndex,inputIndex,isControl)
if outputIndex <= 3
    outputUnit = 'm/s^2';
else
    outputUnit = 'rad/s^2';
end
if isControl || inputIndex >= 7
    inputUnit = 'rad';
elseif inputIndex <= 3
    inputUnit = 'm/s';
else
    inputUnit = 'rad/s';
end
unit = sprintf('(%s)/(%s)',outputUnit,inputUnit);
end

function [simulations,summary] = run_time_cases(trimReport,P13,rawDir)
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
stuckCase = named(base,'left_nacelle_stuck');
stuckCase.amplitude = 5*d2r;
stuckCase.leftActuator = struct('stuck',true);
cases{end+1} = stuckCase;
degradeCase = named(base,'left_rate_degradation');
degradeCase.amplitude = 5*d2r;
degradeCase.leftActuator = struct('rateScale',0.20);
cases{end+1} = degradeCase;
freezeCase = named(base,'left_command_freeze');
freezeCase.amplitude = 5*d2r;
freezeCase.leftActuator = struct('commandFreeze',true, ...
    'frozenCommand',trimReport.x13(10));
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
summaryRows = cell(numel(cases),11);
for k = 1:numel(cases)
    simulations{k} = simulate_berger13_case(trimReport,P13,cases{k});
    sim = simulations{k};
    summaryRows(k,:) = {cases{k}.name,cases{k}.inputType, ...
        cases{k}.amplitude,cases{k}.duration,sim.metrics.maxAttitudeDeviationRad, ...
        sim.metrics.maxAngularRateRadPerSecond,sim.metrics.maxBetaDiffRad, ...
        sim.metrics.maxAbsRollMomentNm,sim.metrics.maxAbsYawMomentNm, ...
        sim.metrics.recoveryTimeSeconds,sim.diverged || ~sim.finiteReal};
    timeTable = array2table([sim.time,sim.x,sim.betaSym,sim.betaDiff, ...
        sim.lateralForceRollYawMoment,double(sim.limitActive)], ...
        'VariableNames',[{'time'},get_state_names_13x10().', ...
        {'betaSym','betaDiff','lateralForceN','rollMomentNm', ...
        'yawMomentNm','limitActive'}]);
    writetable(timeTable,fullfile(rawDir,[cases{k}.name '.csv']));
end
summary = cell2table(summaryRows,'VariableNames', ...
    {'caseName','inputType','amplitudeRad','durationSeconds', ...
    'maxAttitudeDeviationRad','maxAngularRateRadPerSecond', ...
    'maxBetaDiffRad','maxAbsRollMomentNm','maxAbsYawMomentNm', ...
    'recoveryTimeSeconds','diverged'});
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

function tableOut = run_sensitivity(trimReport,P13)
d2r = pi/180;
rows = {};
rows = [rows; linear_sweep('omegaN',[0.5,1,1.5],trimReport,P13)];
rows = [rows; linear_sweep('zeta',[0.625,1,1.375],trimReport,P13)];
rows = [rows; linear_sweep('lateralCyclicScale',[0.5,1,1.5], ...
    trimReport,P13)];
timeParameters = {'leftOmegaN','leftZeta','rateScale','accelLim', ...
    'torqueLim','movingMassLeft','nacelleInertia','leftDelay','wakeArea'};
factors = [0.5,1,1.5];
for p = 1:numel(timeParameters)
    for k = 1:numel(factors)
        [Ptest,def] = sensitivity_case(P13,timeParameters{p}, ...
            factors(k),trimReport,d2r);
        if strcmp(timeParameters{p},'wakeArea')
            metric = beta_diff_load_derivative(trimReport,Ptest);
            rows(end+1,:) = {timeParameters{p},factors(k),NaN,NaN,NaN, ...
                NaN,metric,'norm(d[F;M]/d betaDiff)', ...
                'PENDING_CLASSIFICATION'}; %#ok<AGROW>
        else
            sim = simulate_berger13_case(trimReport,Ptest,def);
            rows(end+1,:) = {timeParameters{p},factors(k),NaN, ...
                sim.metrics.maxAttitudeDeviationRad, ...
                sim.metrics.maxAngularRateRadPerSecond, ...
                sim.metrics.maxBetaDiffRad, ...
                hypot(sim.metrics.maxAbsRollMomentNm, ...
                sim.metrics.maxAbsYawMomentNm), ...
                'hypot(peak roll moment,peak yaw moment) [N m]', ...
                'PENDING_CLASSIFICATION'}; %#ok<AGROW>
        end
    end
end
tableOut = cell2table(rows,'VariableNames', ...
    {'parameter','factor','spectralAbscissaPerSecond', ...
    'maxAttitudeDeviationRad','maxAngularRateRadPerSecond', ...
    'maxBetaDiffRad','primaryLoadMetric','primaryMetricDefinition', ...
    'conclusionClass'});
numericNames = {'factor','spectralAbscissaPerSecond', ...
    'maxAttitudeDeviationRad','maxAngularRateRadPerSecond', ...
    'maxBetaDiffRad','primaryLoadMetric'};
for columnIndex = 1:numel(numericNames)
    name = numericNames{columnIndex};
    if iscell(tableOut.(name))
        tableOut.(name) = numeric_cell_column(tableOut.(name),name);
    end
end
parameters = unique(tableOut.parameter,'stable');
for k = 1:numel(parameters)
    mask = strcmp(tableOut.parameter,parameters{k});
    primaryValues = tableOut.primaryLoadMetric(mask);
    primaryValues = primaryValues(isfinite(primaryValues));
    primaryInactive = ~isempty(primaryValues) && ...
        max(abs(primaryValues)) < 1e-8;
    values = primaryValues;
    if primaryInactive
        values = tableOut.maxAttitudeDeviationRad(mask);
        values = values(isfinite(values));
    end
    if isempty(values)
        classification = 'CANNOT_RELIABLY_DETERMINE';
    else
        relativeRange = (max(values)-min(values))/max(max(abs(values)),eps);
        if primaryInactive && relativeRange < 1e-8
            classification = 'CANNOT_RELIABLY_DETERMINE';
        elseif relativeRange < 0.05
            classification = 'TREND_ROBUST';
        elseif relativeRange < 0.5
            classification = 'MAGNITUDE_SENSITIVE';
        else
            classification = 'HIGHLY_ASSUMPTION_DEPENDENT';
        end
    end
    tableOut.conclusionClass(mask) = repmat({classification},sum(mask),1);
end
end

function values = numeric_cell_column(column,name)
values = NaN(numel(column),1);
for rowIndex = 1:numel(column)
    item = column{rowIndex};
    while iscell(item) && isscalar(item)
        item = item{1};
    end
    if ~isnumeric(item) || ~isscalar(item) || ~isreal(item)
        error('run_berger13_complete_research:InvalidSensitivityValue', ...
            'Sensitivity column %s row %d is not a real scalar.', ...
            name,rowIndex);
    end
    values(rowIndex) = double(item);
end
end

function rows = linear_sweep(parameter,factors,trimReport,P13)
rows = cell(numel(factors),9);
for k = 1:numel(factors)
    Ptest = P13;
    switch parameter
        case 'omegaN'
            Ptest.commandActuator.left.omegaN = ...
                factors(k)*P13.commandActuator.left.omegaN;
            Ptest.commandActuator.right.omegaN = ...
                factors(k)*P13.commandActuator.right.omegaN;
        case 'zeta'
            Ptest.commandActuator.left.zeta = ...
                factors(k)*P13.commandActuator.left.zeta;
            Ptest.commandActuator.right.zeta = ...
                factors(k)*P13.commandActuator.right.zeta;
        case 'lateralCyclicScale'
            Ptest.interface.lateralCyclicScale = factors(k);
    end
    [A,B] = linearize_13x10_command_numeric( ...
        trimReport.x13,trimReport.u10Command,Ptest,1);
    lambda = eig(A);
    switch parameter
        case 'omegaN'
            primaryMetric = norm(B(:,9:10),'fro');
            metricDefinition = 'Frobenius norm of command B columns 9:10';
        case 'zeta'
            primaryMetric = norm(A(12:13,12:13),'fro');
            metricDefinition = 'Frobenius norm of nacelle-rate A subblock';
        otherwise
            primaryMetric = norm(B(:,5));
            metricDefinition = '2-norm of lateralCyclic B column';
    end
    rows(k,:) = {parameter,factors(k),max(real(lambda)),NaN,NaN,NaN, ...
        primaryMetric,metricDefinition,'PENDING_CLASSIFICATION'};
end
end

function [Ptest,def] = sensitivity_case(P13,parameter,factor,trimReport,d2r)
Ptest = P13;
def = struct('name',['sensitivity_' parameter], ...
    'duration',3,'dt',0.1,'inputType','betaSym', ...
    'amplitude',5*d2r,'startTime',0.5);
switch parameter
    case 'leftOmegaN'
        Ptest.commandActuator.left.omegaN = ...
            factor*P13.commandActuator.left.omegaN;
    case 'leftZeta'
        Ptest.commandActuator.left.zeta = ...
            factor*P13.commandActuator.left.zeta;
    case 'rateScale'
        Ptest.commandActuator.left.rateScale = factor;
    case 'accelLim'
        Ptest.commandActuator.left.accelLim = ...
            factor*P13.commandActuator.left.accelLim;
    case 'torqueLim'
        Ptest.nacelle.torqueLim = factor*P13.nacelle.torqueLim;
    case 'movingMassLeft'
        Ptest.movingComponents.left.mass = ...
            factor*P13.movingComponents.left.mass;
        def.inputType = 'betaDiff'; def.amplitude = d2r;
    case 'nacelleInertia'
        Ptest.nacelle.I = factor*P13.nacelle.I;
    case 'leftDelay'
        Ptest.commandActuator.left.commandDelay = 0.2*factor;
    case 'wakeArea'
        Ptest.base.wing.SslipMaxHalf = ...
            factor*P13.base.wing.SslipMaxHalf;
end
if strcmp(parameter,'leftDelay') && factor == 0
    Ptest.commandActuator.left.commandDelay = 0;
end
if strcmp(parameter,'wakeArea')
    def.amplitude = trimReport.x13(10)*0;
end
end

function metric = beta_diff_load_derivative(trimReport,P13)
h = 1e-4;
xp = trimReport.x13;
xm = trimReport.x13;
xp(10:11) = xp(10:11)+[-h;+h];
xm(10:11) = xm(10:11)+[+h;-h];
uTorque = [trimReport.u10Command(1:8);0;0];
[Fp,Mp] = total_forces_moments_13x10(xp,uTorque,P13);
[Fm,Mm] = total_forces_moments_13x10(xm,uTorque,P13);
metric = norm(([Fp;Mp]-[Fm;Mm])/(2*h));
end

function finite = check_finite(results)
finite = all(isfinite(results.derivativeTable.value)) && ...
    all(isfinite(results.eigenTable.realPartPerSecond)) && ...
    all(isfinite(results.eigenTable.imagPartRadPerSecond));
for k = 1:numel(results.timeSimulations)
    finite = finite && results.timeSimulations{k}.finiteReal;
end
end
