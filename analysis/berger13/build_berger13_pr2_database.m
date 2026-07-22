function database = build_berger13_pr2_database(outputDir)
%BUILD_BERGER13_PR2_DATABASE Formal trim/linear-model operating-point grid.
% Failed and noncredible points are retained. Only CREDIBLE points receive
% a linear model. The grid is a research envelope, not a flight corridor.

if nargin < 1
    outputDir = '';
end
P13 = params_berger13();
d2r = pi/180;
betaDeg = [15;15;15;45;45;45;75;75;75];
speed = [10;20;30;25;35;45;40;60;80];
mode = {'helicopter_longitudinal';'helicopter_longitudinal'; ...
    'helicopter_longitudinal';'conversion_longitudinal'; ...
    'conversion_longitudinal';'conversion_longitudinal'; ...
    'airplane_longitudinal';'airplane_longitudinal'; ...
    'airplane_longitudinal'};
n = numel(speed);

emptyPoint = struct('id','','condition',[],'mode','','status','FAILED', ...
    'failureIdentifier','','failureMessage','','trim',[], ...
    'linearModel',[],'elapsedSeconds',NaN);
points = repmat(emptyPoint,n,1);
previousBeta = NaN;
previousZ = [];
for k = 1:n
    condition = struct('V',speed(k),'betaM',betaDeg(k)*d2r,'gamma',0);
    opts = struct('mode',mode{k});
    if betaDeg(k) == previousBeta && ~isempty(previousZ)
        opts.initialValues = previousZ;
    else
        opts.runMultipleSeeds = true;
    end
    points(k).id = sprintf('B%02d_V%03d',betaDeg(k),speed(k));
    points(k).condition = condition;
    points(k).mode = mode{k};
    started = tic;
    try
        [~,~,trimReport] = trim_berger13_symmetric(condition,P13,opts);
        points(k).trim = trimReport;
        points(k).status = trimReport.status;
        if trimReport.credible
            points(k).linearModel = ...
                linearize_berger13_trim_point(trimReport,P13);
            previousZ = trimReport.trimVariableVector;
        else
            previousZ = [];
        end
    catch ME
        points(k).status = 'FAILED';
        points(k).failureIdentifier = ME.identifier;
        points(k).failureMessage = ME.message;
        previousZ = [];
    end
    points(k).elapsedSeconds = toc(started);
    previousBeta = betaDeg(k);
end

status = cell(n,1);
residualNorm = NaN(n,1);
conditionNumber = NaN(n,1);
minimumMargin = NaN(n,1);
collectiveDeg = NaN(n,1);
cyclicLongDeg = NaN(n,1);
elevatorDeg = NaN(n,1);
thetaDeg = NaN(n,1);
failureReason = cell(n,1);
for k = 1:n
    status{k} = points(k).status;
    failureReason{k} = points(k).failureMessage;
    if ~isempty(points(k).trim)
        tr = points(k).trim;
        residualNorm(k) = tr.dynamicResidualNorm;
        conditionNumber(k) = tr.conditionNumber;
        minimumMargin(k) = tr.minimumUnknownMarginFraction;
        collectiveDeg(k) = tr.u10Torque(1)/d2r;
        cyclicLongDeg(k) = tr.u10Torque(3)/d2r;
        elevatorDeg(k) = tr.u10Torque(7)/d2r;
        thetaDeg(k) = tr.x13(8)/d2r;
        if isempty(failureReason{k}) && ~tr.credible
            failureReason{k} = strjoin(tr.reasons,'; ');
        end
    end
end

summary = table({points.id}.',betaDeg,speed,mode,status,thetaDeg, ...
    collectiveDeg,cyclicLongDeg,elevatorDeg,residualNorm, ...
    conditionNumber,minimumMargin,[points.elapsedSeconds].',failureReason, ...
    'VariableNames',{'pointId','betaMDeg','speedMps','mode','status', ...
    'thetaDeg','collectiveDeg','cyclicLongDeg','elevatorDeg', ...
    'dynamicResidualNorm','conditionNumber','minimumMarginFraction', ...
    'elapsedSeconds','failureReason'});

database.points = points;
database.summary = summary;
database.credibleCount = sum(strcmp(status,'CREDIBLE'));
database.failedCount = n-database.credibleCount;
database.gridDefinition = ['ASSUMED_RESEARCH_GRID selected from current ' ...
    'model trim capability; not a validated conversion corridor'];
database.createdWith = version;
database.finiteReal = all(isfinite(residualNorm(strcmp(status,'CREDIBLE'))));

if ~isempty(outputDir)
    if ~exist(outputDir,'dir')
        mkdir(outputDir);
    end
    writetable(summary,fullfile(outputDir,'PR2_TRIM_POINT_DATABASE.csv'));
    save(fullfile(outputDir,'PR2_LINEAR_MODEL_DATABASE.mat'), ...
        'database','-v7');
end
end
