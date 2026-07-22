function database = evaluate_generic_trim_grid(P13,opts)
%EVALUATE_GENERIC_TRIM_GRID Run the frozen grid with full 13-state checks.

if nargin < 1 || isempty(P13), P13 = params_berger13(); end
if nargin < 2, opts = struct(); end
grid = generic_trim_design_grid();
variantName = get_option(opts,'variantName','UNNAMED_VARIANT');
initialVectors = get_option(opts,'initialVectors',cell(height(grid),1));
runMultipleSeeds = get_option(opts,'runMultipleSeeds',true);
if ~iscell(initialVectors) || numel(initialVectors) ~= height(grid)
    error('evaluate_generic_trim_grid:InvalidInitialVectors', ...
        'opts.initialVectors must be a cell for every grid point.');
end

emptyPoint = struct('id','','condition',[],'mode','','status','FAILED', ...
    'failureIdentifier','','failureMessage','','trim',[], ...
    'elapsedSeconds',NaN);
points = repmat(emptyPoint,height(grid),1);
previousBeta = NaN;
previousZ = [];
for k = 1:height(grid)
    condition = grid.condition{k};
    trimOpts = struct('mode',grid.mode{k});
    if ~isempty(initialVectors{k})
        trimOpts.initialValues = initialVectors{k};
    elseif grid.betaDeg(k) == previousBeta && ~isempty(previousZ)
        trimOpts.initialValues = previousZ;
    else
        trimOpts.runMultipleSeeds = runMultipleSeeds;
    end
    points(k).id = grid.pointId{k};
    points(k).condition = condition;
    points(k).mode = grid.mode{k};
    started = tic;
    try
        [~,~,trimReport] = trim_berger13_symmetric( ...
            condition,P13,trimOpts);
        points(k).trim = trimReport;
        points(k).status = trimReport.status;
        if trimReport.credible
            previousZ = trimReport.trimVariableVector;
        else
            previousZ = [];
        end
    catch ME
        points(k).failureIdentifier = ME.identifier;
        points(k).failureMessage = ME.message;
        previousZ = [];
    end
    points(k).elapsedSeconds = toc(started);
    previousBeta = grid.betaDeg(k);
end

summary = summarize(points,grid,variantName);
database.variantName = variantName;
database.grid = grid;
database.points = points;
database.summary = summary;
database.credibleCount = sum(strcmp(summary.status,'CREDIBLE'));
database.failedCount = height(summary)-database.credibleCount;
database.finiteReal = all(summary.finiteReal);
database.createdWith = version;
database.claimBoundary = ['Internal trim credibility and numerical ' ...
    'consistency only; not an XV-15 or flight-test validation result.'];
end

function T = summarize(points,grid,variantName)
n = numel(points);
variant = repmat({variantName},n,1);
status = {points.status}.';
thetaDeg = NaN(n,1); collectiveDeg = NaN(n,1);
cyclicLongDeg = NaN(n,1); elevatorDeg = NaN(n,1);
residualNorm = Inf(n,1); conditionNumber = Inf(n,1);
minimumMarginFraction = -Inf(n,1); finiteReal = false(n,1);
atLimit = true(n,1); failureReason = cell(n,1);
for k = 1:n
    failureReason{k} = points(k).failureMessage;
    if isempty(points(k).trim), continue; end
    tr = points(k).trim;
    thetaDeg(k) = tr.x13(8)*180/pi;
    collectiveDeg(k) = tr.u10Torque(1)*180/pi;
    cyclicLongDeg(k) = tr.u10Torque(3)*180/pi;
    elevatorDeg(k) = tr.u10Torque(7)*180/pi;
    residualNorm(k) = tr.dynamicResidualNorm;
    conditionNumber(k) = tr.conditionNumber;
    minimumMarginFraction(k) = tr.minimumUnknownMarginFraction;
    finiteReal(k) = tr.finiteReal && isreal(tr.x13) && ...
        all(isfinite(tr.x13)) && isreal(tr.u10Torque) && ...
        all(isfinite(tr.u10Torque));
    atLimit(k) = any(tr.activeLimits);
    if isempty(failureReason{k}) && ~tr.credible
        failureReason{k} = strjoin(tr.reasons,'; ');
    end
end
T = table(variant,grid.pointId,grid.betaDeg,grid.speedMps,grid.mode, ...
    status,thetaDeg,collectiveDeg,cyclicLongDeg,elevatorDeg, ...
    residualNorm,conditionNumber,minimumMarginFraction,atLimit, ...
    finiteReal,[points.elapsedSeconds].',failureReason, ...
    'VariableNames',{'variant','pointId','betaMDeg','speedMps','mode', ...
    'status','thetaDeg','collectiveDeg','cyclicLongDeg','elevatorDeg', ...
    'dynamicResidualNorm','conditionNumber','minimumMarginFraction', ...
    'atLimit','finiteReal','elapsedSeconds','failureReason'});
end

function value = get_option(opts,name,defaultValue)
if isfield(opts,name), value = opts.(name); else, value = defaultValue; end
end
