function report = run_nuaa_trim_trend_validation()
%RUN_NUAA_TRIM_TREND_VALIDATION Fixed NUAA-style trim trend validation.
% This script uses only the current approved parameters, trim definitions,
% cosine pitch allocation, limits, and numerical linearization. It does not
% tune parameters, change control allocation, relax limits, or search broad
% alternative initial conditions.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir, 'model'));
addpath(fullfile(rootDir, 'analysis'));

P = params_nominal();
stamp = datestr(now, 'yyyymmdd_HHMMSS');
outDir = fullfile(rootDir, 'validation', 'nuaa_trim_trends', stamp);
docsDir = fullfile(rootDir, 'docs', 'validation', ...
    'nuaa_trim_trends', '20260625');
ensure_dir(outDir);
ensure_dir(docsDir);

gitSha = get_git_sha(rootDir);
fprintf('\nNUAA-style trim trend validation\n');
fprintf('================================\n');
fprintf('Output directory: %s\n', outDir);
fprintf('Git commit: %s\n', gitSha);
fprintf('No parameter, allocation, limit, equation, or solver changes.\n\n');

runTimer = tic;
allPoints = repmat(empty_point_row(), 0, 1);
allComponents = repmat(empty_component_row(), 0, 1);
allPointData = repmat(empty_point(), 0, 1);

[helicopterMain, helicopterMainComponents, helicopterPoints] = ...
    run_ordered_branch('helicopter_longitudinal', 0, 0:2.5:30, ...
    'forward', 'helicopter_hover_connected', true, [], P, gitSha);
allPoints = append_rows(allPoints, helicopterMain);
allComponents = append_rows(allComponents, helicopterMainComponents);
allPointData = append_rows(allPointData, helicopterPoints);

[helicopterReverse, helicopterReverseComponents, helicopterReversePoints] = run_ordered_branch( ...
    'helicopter_longitudinal', 0, 30:-2.5:0, 'reverse', ...
    'helicopter_reverse_audit', false, [], P, gitSha);
allPoints = append_rows(allPoints, helicopterReverse);
allComponents = append_rows(allComponents, helicopterReverseComponents);
allPointData = append_rows(allPointData, helicopterReversePoints);

[localLow, localLowComponents, localLowPoints] = run_ordered_branch( ...
    'helicopter_longitudinal', 0, 7.5:0.25:10.5, 'local_low_to_high', ...
    'helicopter_9ms_low_branch', false, [], P, gitSha);
allPoints = append_rows(allPoints, localLow);
allComponents = append_rows(allComponents, localLowComponents);
allPointData = append_rows(allPointData, localLowPoints);

[localHigh, localHighComponents, localHighPoints] = run_ordered_branch( ...
    'helicopter_longitudinal', 0, 10.5:-0.25:7.5, 'local_high_to_low', ...
    'helicopter_9ms_high_branch', false, [], P, gitSha);
allPoints = append_rows(allPoints, localHigh);
allComponents = append_rows(allComponents, localHighComponents);
allPointData = append_rows(allPointData, localHighPoints);

[conv15Rows, conv15Comp, conv15Points] = run_anchored_case( ...
    'conversion_longitudinal', 15, 10:2.5:60, 35, 'conversion15', P, gitSha);
allPoints = append_rows(allPoints, conv15Rows);
allComponents = append_rows(allComponents, conv15Comp);
allPointData = append_rows(allPointData, conv15Points);

[conv75Rows, conv75Comp, conv75Points] = run_anchored_case( ...
    'conversion_longitudinal', 75, 70:2.5:150, 100, 'conversion75', P, gitSha);
allPoints = append_rows(allPoints, conv75Rows);
allComponents = append_rows(allComponents, conv75Comp);
allPointData = append_rows(allPointData, conv75Points);

[airRows, airComp, airPoints] = run_anchored_case( ...
    'airplane_longitudinal', 90, 70:2.5:150, 100, 'airplane', P, gitSha);
allPoints = append_rows(allPoints, airRows);
allComponents = append_rows(allComponents, airComp);
allPointData = append_rows(allPointData, airPoints);

pointsTable = struct2table(allPoints);
componentTable = struct2table(allComponents);
branchTable = make_branch_comparison(pointsTable);
trendTable = make_trend_summary(pointsTable);

primaryMask = pointsTable.isPrimary & pointsTable.converged & ...
    pointsTable.finite & ~pointsTable.atLimit & ...
    strcmp(pointsTable.credibilityClass, 'PASS');
[stabilityMap, stabilityRows] = run_stability_map( ...
    pointsTable(primaryMask, :), allPointData(primaryMask), P);
stabilityTable = struct2table(stabilityRows);
stabilityMapTable = struct2table(stabilityMap);

paths = write_outputs(outDir, docsDir, pointsTable, branchTable, ...
    componentTable, stabilityTable, stabilityMapTable, trendTable);
figurePaths = write_trend_figures(pointsTable, branchTable, paths);
stabilityFigurePaths = write_stability_figures(stabilityMapTable, paths);
elapsed = toc(runTimer);
write_report(paths.reportMd, pointsTable, branchTable, trendTable, ...
    stabilityMapTable, stabilityTable, figurePaths, stabilityFigurePaths, ...
    elapsed, gitSha);
copy_deliverables(paths, figurePaths, docsDir);

report = struct();
report.generatedAt = datestr(now, 31);
report.outputDir = outDir;
report.docsDir = docsDir;
report.gitSha = gitSha;
report.elapsed_s = elapsed;
report.points = pointsTable;
report.branchComparison = branchTable;
report.componentMoments = componentTable;
report.stability = stabilityTable;
report.stabilityMap = stabilityMapTable;
report.trendSummary = trendTable;
report.figurePaths = figurePaths;
report.stabilityFigurePaths = stabilityFigurePaths;
report.paths = paths;
save(fullfile(outDir, 'nuaa_trim_trend_validation.mat'), 'report', '-v7');

fprintf('\nNUAA trim trend validation complete.\n');
fprintf('Elapsed seconds: %.3f\n', elapsed);
fprintf('Report: %s\n', paths.reportMd);
fprintf('Primary accepted trim points: %d\n', sum(primaryMask));
end

function [rows, comps, points] = run_anchored_case(mode, betaDeg, speeds, ...
        anchorSpeed, casePrefix, P, gitSha)
anchor = make_condition(anchorSpeed, betaDeg);
[anchorRow, anchorPoint, anchorComp, anchorSeed] = solve_one( ...
    mode, anchor, [casePrefix '_anchor'], 'anchor', true, [], P, gitSha);
rows = anchorRow;
comps = anchorComp;
points = anchorPoint;
lowerSpeeds = speeds(speeds < anchorSpeed);
upperSpeeds = speeds(speeds > anchorSpeed);
if ~isempty(lowerSpeeds)
    [lowerRows, lowerComp, lowerPoints] = run_ordered_branch(mode, betaDeg, ...
        fliplr(lowerSpeeds), 'anchor_to_low', [casePrefix '_lower'], ...
        true, anchorSeed, P, gitSha);
    rows = append_rows(rows, lowerRows);
    comps = append_rows(comps, lowerComp);
    points = [points; lowerPoints];
end
if ~isempty(upperSpeeds)
    [upperRows, upperComp, upperPoints] = run_ordered_branch(mode, betaDeg, ...
        upperSpeeds, 'anchor_to_high', [casePrefix '_upper'], ...
        true, anchorSeed, P, gitSha);
    rows = append_rows(rows, upperRows);
    comps = append_rows(comps, upperComp);
    points = [points; upperPoints];
end
end

function [rows, comps, points] = run_ordered_branch(mode, betaDeg, speeds, ...
        sweepDirection, branchId, isPrimary, initialSeed, P, gitSha)
rows = repmat(empty_point_row(), 0, 1);
comps = repmat(empty_component_row(), 0, 1);
points = repmat(empty_point(), 0, 1);
seed = initialSeed;
for i = 1:numel(speeds)
    condition = make_condition(speeds(i), betaDeg);
    [row, point, comp, acceptedSeed] = solve_one(mode, condition, ...
        branchId, sweepDirection, isPrimary, seed, P, gitSha);
    rows = append_rows(rows, row);
    comps = append_rows(comps, comp);
    points = [points; point]; %#ok<AGROW>
    if row.converged && row.finite && strcmp(row.credibilityClass, 'PASS') && ...
            ~isempty(acceptedSeed)
        seed = acceptedSeed;
    end
    fprintf(['%s V=%7.2f beta=%5.1f dir=%s conv=%d cred=%s ' ...
        'res=%.3e theta=% .3f coll=% .3f cyc=% .3f elev=% .3f\n'], ...
        mode, condition.V, betaDeg, sweepDirection, row.converged, ...
        row.credibilityClass, row.residualNorm, row.theta_deg, ...
        row.collective_deg, row.cyclicLong_deg, row.elevator_deg);
end
end

function [row, point, comp, acceptedSeed] = solve_one(mode, condition, ...
        branchId, sweepDirection, isPrimary, seed, P, gitSha)
d2r = pi/180;
row = empty_point_row();
row.mode = mode;
row.betaM_deg = condition.betaM/d2r;
row.V_mps = condition.V;
row.sweep_direction = sweepDirection;
row.branch_id = branchId;
row.isPrimary = isPrimary;
row.git_sha = gitSha;
row.parameterIdentity = approved_parameter_identity();
point = empty_point();
point.mode = mode;
point.betaM_deg = row.betaM_deg;
point.V_mps = row.V_mps;
comp = empty_component_row();
comp.mode = mode;
comp.betaM_deg = row.betaM_deg;
comp.V_mps = row.V_mps;
comp.sweep_direction = sweepDirection;
comp.branch_id = branchId;
acceptedSeed = [];
try
    definition = make_trim_definition(mode, condition, P);
    if ~isempty(seed)
        definition.initialValues = seed(:);
        row.seedSource = 'continuation';
    else
        row.seedSource = 'factory';
    end
    [xTrim, uTrim, trimReport] = trim_general(condition, definition, P);
    credibility = diagnose_trim_credibility( ...
        condition, definition, xTrim, uTrim, trimReport, P);
    acceptedSeed = trim_vector(definition, trimReport);
    row = fill_point_row(row, xTrim, uTrim, trimReport, credibility, ...
        definition, P);
    point.xTrim = xTrim;
    point.uTrim = uTrim;
    point.trimReport = trimReport;
    point.credibility = credibility;
    point.definition = definition;
    point.success = row.converged && row.finite && ...
        strcmp(row.credibilityClass, 'PASS');
    comp = fill_component_row(comp, xTrim, uTrim, condition.betaM, P);
catch ME
    row.errorIdentifier = ME.identifier;
    row.errorMessage = ME.message;
    row.credibilityClass = 'ERROR';
    row.failureReason = sprintf('%s: %s', ME.identifier, ME.message);
    comp.errorIdentifier = ME.identifier;
end
end

function row = fill_point_row(row, xTrim, uTrim, trimReport, credibility, ...
        definition, P)
d2r = pi/180;
row.theta_deg = xTrim(8)/d2r;
row.alpha_deg = (xTrim(8) - 0)/d2r;
row.collective_deg = uTrim(1)/d2r;
row.cyclicLong_deg = uTrim(3)/d2r;
row.paperCyclic_deg = paper_cyclic_sign()*uTrim(3)/d2r;
row.elevator_deg = uTrim(6)/d2r;
row.pitchCommand = NaN;
if isfield(trimReport.trimVariables, 'pitchCommand')
    row.pitchCommand = trimReport.trimVariables.pitchCommand;
end
row.residualNorm = trimReport.residualNorm;
row.converged = trimReport.converged;
row.finite = trimReport.finiteFullStateDerivative && ...
    is_real_finite(xTrim) && is_real_finite(uTrim);
row.credibilityClass = credibility.status;
row.jacobianRank = credibility.effectiveRank;
row.jacobianConditionNumber = credibility.conditionNumber;
row.atLimit = trimReport.atLimit;
[row.collectiveMargin_deg, row.collectiveAtLimit] = ...
    margin_deg(uTrim(1), P.control.collectiveLim);
[row.cyclicLongMargin_deg, row.cyclicLongAtLimit] = ...
    margin_deg(uTrim(3), P.control.cyclicLim);
[row.elevatorMargin_deg, row.elevatorAtLimit] = ...
    margin_deg(uTrim(6), P.control.elevatorLim);
row.anyControlAtLimit = row.collectiveAtLimit || row.cyclicLongAtLimit || ...
    row.elevatorAtLimit;
row.unknownNames = strjoin(definition.unknownNames(:).', ';');
row.failureReason = '';
if ~row.converged || strcmp(row.credibilityClass, 'FAIL')
    row.failureReason = strjoin(credibility.reasons(:).', ';');
end
end

function comp = fill_component_row(comp, xTrim, uTrim, betaM, P)
[~, ~, info] = total_forces_moments(xTrim, uTrim, betaM, P);
comp.rotorPitchMoment_Nm = component_pitch(info, 'rotorLeft') + ...
    component_pitch(info, 'rotorRight');
comp.wingPitchMoment_Nm = component_pitch(info, 'wing');
comp.fuselagePitchMoment_Nm = component_pitch(info, 'fuselage');
comp.htailPitchMoment_Nm = component_pitch(info, 'horizontalTail');
comp.vtailPitchMoment_Nm = component_pitch(info, 'verticalTail');
comp.totalPitchMoment_Nm = comp.rotorPitchMoment_Nm + ...
    comp.wingPitchMoment_Nm + comp.fuselagePitchMoment_Nm + ...
    comp.htailPitchMoment_Nm + comp.vtailPitchMoment_Nm;
[comp.wingCL, comp.wingCLOverCLmax] = wing_cl_summary(info, P);
end

function value = component_pitch(info, name)
value = NaN;
for i = 1:numel(info.components)
    item = info.components{i};
    if strcmp(item.name, name)
        value = item.M(2);
        return;
    end
end
end

function [CL, ratio] = wing_cl_summary(info, P)
values = [];
regions = info.wing.regions;
for i = 1:numel(regions)
    if isfield(regions{i}, 'CL')
        values(end+1) = regions{i}.CL; %#ok<AGROW>
    end
end
if isempty(values)
    CL = NaN;
    ratio = NaN;
else
    CL = mean(values);
    ratio = CL/P.wing.CLmax;
end
end

function [stabilityMap, stabilityRows] = run_stability_map(points, pointData, P)
stabilityMap = repmat(empty_stability_map_row(), 0, 1);
stabilityRows = repmat(empty_stability_row(), 0, 1);
if isempty(points)
    return;
end
for i = 1:height(points)
    point = points(i, :);
    betaM = point.betaM_deg*pi/180;
    try
        xTrim = pointData(i).xTrim;
        uTrim = pointData(i).uTrim;
        [A, ~, linReport] = linearize_numeric(xTrim, uTrim, betaM, P);
        mapRow = classify_stability(point, A, linReport, 1);
        stabilityMap = append_rows(stabilityMap, mapRow);
        stabilityRows = append_rows(stabilityRows, map_to_stability_row(mapRow, 1, ...
            'DEFAULT_MAP'));
    catch ME
        mapRow = empty_stability_map_row();
        mapRow.mode = table_text(point, 'mode');
        mapRow.betaM_deg = point.betaM_deg;
        mapRow.V_mps = point.V_mps;
        mapRow.errorIdentifier = ME.identifier;
        stabilityMap = append_rows(stabilityMap, mapRow);
    end
end
mapTable = struct2table(stabilityMap);
selected = select_robustness_points(mapTable);
for k = 1:numel(selected)
    idx = selected(k);
    point = points(idx, :);
    for scale = [0.5, 1, 2]
        try
            betaM = point.betaM_deg*pi/180;
            xTrim = pointData(idx).xTrim;
            uTrim = pointData(idx).uTrim;
            Pstep = P;
            Pstep.linear.dx = P.linear.dx*scale;
            Pstep.linear.du = P.linear.du*scale;
            [A, ~, linReport] = linearize_numeric(xTrim, uTrim, betaM, Pstep);
            mapRow = classify_stability(point, A, linReport, scale);
            stabilityRows = append_rows(stabilityRows, map_to_stability_row( ...
                mapRow, scale, 'ROBUSTNESS_SAMPLE'));
        catch ME
            srow = empty_stability_row();
            srow.mode = table_text(point, 'mode');
            srow.betaM_deg = point.betaM_deg;
            srow.V_mps = point.V_mps;
            srow.stepScale = scale;
            srow.sampleType = 'ROBUSTNESS_SAMPLE';
            srow.errorIdentifier = ME.identifier;
            stabilityRows = append_rows(stabilityRows, srow);
        end
    end
end
end

function selected = select_robustness_points(mapTable)
selected = [];
if isempty(mapTable)
    return;
end
for i = 1:height(mapTable)
    if mapTable.positiveRootCount(i) > 0
        selected(end+1) = i; %#ok<AGROW>
    end
end
if numel(selected) <= 24
    return;
end
keep = [];
modes = unique(mapTable.mode);
for iMode = 1:numel(modes)
    mask = strcmp(mapTable.mode, modes{iMode}) & mapTable.positiveRootCount > 0;
    idx = find(mask);
    if isempty(idx)
        stableIdx = find(strcmp(mapTable.mode, modes{iMode}) & ...
            mapTable.positiveRootCount == 0, 1);
        if ~isempty(stableIdx)
            keep(end+1) = stableIdx; %#ok<AGROW>
        end
        continue;
    end
    keep = [keep, idx(1), idx(round((numel(idx)+1)/2)), idx(end)]; %#ok<AGROW>
    extras = idx(round(linspace(1, numel(idx), min(5, numel(idx)))));
    keep = [keep, extras(:).']; %#ok<AGROW>
    stableIdx = find(strcmp(mapTable.mode, modes{iMode}) & ...
        mapTable.positiveRootCount == 0, 1);
    if ~isempty(stableIdx)
        keep(end+1) = stableIdx; %#ok<AGROW>
    end
end
selected = unique(keep);
end

function mapRow = classify_stability(point, A, linReport, stepScale)
stateNames = {'u','v','w','p','q','r','phi','theta','psi'};
idxLong = [1, 3, 5, 8];
idxLat = [2, 4, 6, 7, 9];
[fullVec, fullEig] = eig(A);
lambda = diag(fullEig);
eigLong = eig(A(idxLong, idxLong));
eigLat = eig(A(idxLat, idxLat));
[~, iDom] = max(real(lambda));
dom = lambda(iDom);
vec = fullVec(:, iDom);
if max(abs(vec)) > 0
    vec = vec/max(abs(vec));
end
[~, order] = sort(abs(vec), 'descend');
participation = stateNames(order(1:min(4, numel(order))));
neutral = abs(lambda) <= 1e-6;
positive = real(lambda) > 1e-3 & ~neutral;
mapRow = empty_stability_map_row();
mapRow.mode = table_text(point, 'mode');
mapRow.betaM_deg = point.betaM_deg;
mapRow.V_mps = point.V_mps;
mapRow.stepScale = stepScale;
mapRow.max_real_full = max(real(lambda));
mapRow.max_real_longitudinal = max(real(eigLong));
mapRow.max_real_lateral = max(real(eigLat));
mapRow.positiveRootCount = sum(positive);
mapRow.neutralRootCount = sum(neutral);
mapRow.dominantReal = real(dom);
mapRow.dominantImag = imag(dom);
mapRow.dominantNaturalFrequency = abs(dom);
if abs(dom) > 0
    mapRow.dominantDampingRatio = -real(dom)/abs(dom);
else
    mapRow.dominantDampingRatio = NaN;
end
if real(dom) > 0
    mapRow.tau_growth_s = 1/real(dom);
end
mapRow.participationStates = strjoin(participation, ';');
mapRow.linearizationFinite = linReport.finite;
mapRow.openLoopCandidate = any(positive);
mapRow.instabilityBand = instability_band(mapRow.dominantReal);
end

function srow = map_to_stability_row(mapRow, scale, sampleType)
srow = empty_stability_row();
srow.mode = mapRow.mode;
srow.betaM_deg = mapRow.betaM_deg;
srow.V_mps = mapRow.V_mps;
srow.stepScale = scale;
srow.sampleType = sampleType;
srow.max_real_full = mapRow.max_real_full;
srow.max_real_longitudinal = mapRow.max_real_longitudinal;
srow.max_real_lateral = mapRow.max_real_lateral;
srow.positiveRootCount = mapRow.positiveRootCount;
srow.neutralRootCount = mapRow.neutralRootCount;
srow.dominantReal = mapRow.dominantReal;
srow.dominantImag = mapRow.dominantImag;
srow.tau_growth_s = mapRow.tau_growth_s;
srow.participationStates = mapRow.participationStates;
srow.classification = ternary(mapRow.openLoopCandidate, ...
    'OPEN_LOOP_INSTABILITY_CANDIDATE', 'NO_CANDIDATE_POSITIVE_ROOT');
end

function branchTable = make_branch_comparison(T)
branchTable = table();
if isempty(T)
    return;
end
keys = unique(strcat(T.mode, '|', cellstr(num2str(T.betaM_deg)), '|', ...
    cellstr(num2str(T.V_mps))));
mode = {};
betaM_deg = [];
V_mps = [];
branchA = {};
branchB = {};
thetaDiff_deg = [];
collectiveDiff_deg = [];
cyclicDiff_deg = [];
elevatorDiff_deg = [];
significant = [];
for i = 1:numel(keys)
    parts = strsplit(keys{i}, '|');
    mask = strcmp(T.mode, parts{1}) & T.betaM_deg == str2double(parts{2}) & ...
        T.V_mps == str2double(parts{3}) & T.converged;
    idx = find(mask);
    if numel(idx) < 2
        continue;
    end
    a = idx(1);
    b = idx(2);
    mode{end+1,1} = T.mode{a}; %#ok<AGROW>
    betaM_deg(end+1,1) = T.betaM_deg(a); %#ok<AGROW>
    V_mps(end+1,1) = T.V_mps(a); %#ok<AGROW>
    branchA{end+1,1} = T.branch_id{a}; %#ok<AGROW>
    branchB{end+1,1} = T.branch_id{b}; %#ok<AGROW>
    thetaDiff_deg(end+1,1) = abs(T.theta_deg(a)-T.theta_deg(b)); %#ok<AGROW>
    collectiveDiff_deg(end+1,1) = abs(T.collective_deg(a)-T.collective_deg(b)); %#ok<AGROW>
    cyclicDiff_deg(end+1,1) = abs(T.cyclicLong_deg(a)-T.cyclicLong_deg(b)); %#ok<AGROW>
    elevatorDiff_deg(end+1,1) = abs(T.elevator_deg(a)-T.elevator_deg(b)); %#ok<AGROW>
    significant(end+1,1) = max([thetaDiff_deg(end), collectiveDiff_deg(end), ...
        cyclicDiff_deg(end), elevatorDiff_deg(end)]) > 1; %#ok<AGROW>
end
branchTable = table(mode, betaM_deg, V_mps, branchA, branchB, ...
    thetaDiff_deg, collectiveDiff_deg, cyclicDiff_deg, elevatorDiff_deg, ...
    significant);
end

function trendTable = make_trend_summary(T)
primary = T(T.isPrimary & T.converged & strcmp(T.credibilityClass, 'PASS'), :);
modes = unique(primary.branch_id);
mode = {};
pointCount = [];
collectiveEndpointChange_deg = [];
thetaEndpointChange_deg = [];
cyclicEndpointChange_deg = [];
elevatorEndpointChange_deg = [];
collectiveSpearman = [];
thetaSpearman = [];
directionRatioCollective = [];
directionRatioTheta = [];
for i = 1:numel(modes)
    mask = strcmp(primary.branch_id, modes{i});
    S = sortrows(primary(mask, :), 'V_mps');
    if height(S) < 2
        continue;
    end
    mode{end+1,1} = modes{i}; %#ok<AGROW>
    pointCount(end+1,1) = height(S); %#ok<AGROW>
    collectiveEndpointChange_deg(end+1,1) = ...
        S.collective_deg(end)-S.collective_deg(1); %#ok<AGROW>
    thetaEndpointChange_deg(end+1,1) = ...
        S.theta_deg(end)-S.theta_deg(1); %#ok<AGROW>
    cyclicEndpointChange_deg(end+1,1) = ...
        S.cyclicLong_deg(end)-S.cyclicLong_deg(1); %#ok<AGROW>
    elevatorEndpointChange_deg(end+1,1) = ...
        S.elevator_deg(end)-S.elevator_deg(1); %#ok<AGROW>
    collectiveSpearman(end+1,1) = spearman_corr(S.V_mps, ...
        S.collective_deg); %#ok<AGROW>
    thetaSpearman(end+1,1) = spearman_corr(S.V_mps, ...
        S.theta_deg); %#ok<AGROW>
    dc = diff(S.collective_deg);
    dt = diff(S.theta_deg);
    dcMedian = median(dc(isfinite(dc)));
    dtMedian = median(dt(isfinite(dt)));
    directionRatioCollective(end+1,1) = ...
        sum(sign(dc) == sign(dcMedian))/numel(dc); %#ok<AGROW>
    directionRatioTheta(end+1,1) = ...
        sum(sign(dt) == sign(dtMedian))/numel(dt); %#ok<AGROW>
end
trendTable = table(mode, pointCount, collectiveEndpointChange_deg, ...
    thetaEndpointChange_deg, cyclicEndpointChange_deg, ...
    elevatorEndpointChange_deg, collectiveSpearman, thetaSpearman, ...
    directionRatioCollective, directionRatioTheta);
end

function rho = spearman_corr(x, y)
mask = isfinite(x) & isfinite(y);
x = x(mask);
y = y(mask);
if numel(x) < 2
    rho = NaN;
    return;
end
rx = simple_rank(x);
ry = simple_rank(y);
rx = rx - mean(rx);
ry = ry - mean(ry);
den = norm(rx)*norm(ry);
if den == 0
    rho = NaN;
else
    rho = (rx(:).'*ry(:))/den;
end
end

function r = simple_rank(x)
[sorted, order] = sort(x(:));
r = zeros(size(x(:)));
i = 1;
while i <= numel(sorted)
    j = i;
    while j < numel(sorted) && sorted(j+1) == sorted(i)
        j = j + 1;
    end
    r(order(i:j)) = (i+j)/2;
    i = j + 1;
end
end

function paths = write_outputs(outDir, docsDir, pointsTable, branchTable, ...
        componentTable, stabilityTable, stabilityMapTable, trendTable)
paths.outDir = outDir;
paths.docsDir = docsDir;
paths.pointsCsv = fullfile(outDir, 'nuaa_trim_points.csv');
paths.branchCsv = fullfile(outDir, 'nuaa_trim_branch_comparison.csv');
paths.componentCsv = fullfile(outDir, 'nuaa_trim_component_moments.csv');
paths.stabilityCsv = fullfile(outDir, 'nuaa_trim_stability.csv');
paths.stabilityMapCsv = fullfile(outDir, 'nuaa_stability_map.csv');
paths.trendCsv = fullfile(outDir, 'nuaa_trim_trend_summary.csv');
paths.reportMd = fullfile(outDir, 'NUAA_TRIM_TREND_VALIDATION_REPORT.md');
writetable(pointsTable, paths.pointsCsv);
writetable(branchTable, paths.branchCsv);
writetable(componentTable, paths.componentCsv);
writetable(stabilityTable, paths.stabilityCsv);
writetable(stabilityMapTable, paths.stabilityMapCsv);
writetable(trendTable, paths.trendCsv);
end

function figurePaths = write_trend_figures(T, branchTable, paths)
figurePaths = struct();
figurePaths.helicopter = trend_figure(T, branchTable, ...
    'helicopter_longitudinal', 0, 'helicopter_nuaa_fig5a.png', ...
    {'collective_deg','paperCyclic_deg','theta_deg'}, ...
    {'collective','paper-oriented cyclicLong','pitch attitude'}, paths);
figurePaths.airplane = trend_figure(T, branchTable, ...
    'airplane_longitudinal', 90, 'airplane_nuaa_fig5b.png', ...
    {'collective_deg','elevator_deg','theta_deg'}, ...
    {'collective','elevator','pitch attitude'}, paths);
figurePaths.conversion15 = trend_figure(T, branchTable, ...
    'conversion_longitudinal', 15, 'conversion_beta15_nuaa_fig6a.png', ...
    {'collective_deg','paperCyclic_deg','elevator_deg','theta_deg'}, ...
    {'collective','paper-oriented cyclicLong','direct elevator','pitch attitude'}, paths);
figurePaths.conversion75 = trend_figure(T, branchTable, ...
    'conversion_longitudinal', 75, 'conversion_beta75_nuaa_fig6b.png', ...
    {'collective_deg','elevator_deg','cyclicLong_deg','theta_deg'}, ...
    {'collective','elevator','direct cyclicLong','pitch attitude'}, paths);
end

function path = trend_figure(T, branchTable, mode, betaDeg, fileName, vars, labels, paths)
mask = strcmp(T.mode, mode) & T.betaM_deg == betaDeg & T.isPrimary;
S = sortrows(T(mask, :), 'V_mps');
fig = figure('Visible','off','Color','w');
hold on;
styles = {'-o','-s','-^','-d'};
for i = 1:numel(vars)
    y = S.(vars{i});
    y(~S.converged) = NaN;
    plot(S.V_mps, y, styles{i}, 'LineWidth', 1.5, ...
        'DisplayName', labels{i});
end
bm = branchTable(strcmp(branchTable.mode, mode) & ...
    branchTable.betaM_deg == betaDeg & branchTable.significant, :);
if ~isempty(bm)
    yl = ylim;
    plot(bm.V_mps, yl(1)*ones(height(bm),1), 'kx', ...
        'DisplayName', 'branch mismatch');
end
grid on;
xlabel('Velocity (m/s)');
ylabel('Angle (deg)');
title(sprintf('%s betaM %.1f deg', strrep(mode, '_', ' '), betaDeg));
legend('Location','best');
path = fullfile(paths.outDir, fileName);
saveas(fig, path);
close(fig);
end

function pathsOut = write_stability_figures(stabilityMap, paths)
pathsOut = struct();
pathsOut.maxReal = fullfile(paths.outDir, 'stability_max_real_by_mode.png');
pathsOut.coverage = fullfile(paths.outDir, 'stability_long_lateral_coverage.png');
if isempty(stabilityMap)
    return;
end
modes = unique(stabilityMap.mode);
fig = figure('Visible','off','Color','w');
hold on;
for i = 1:numel(modes)
    mask = strcmp(stabilityMap.mode, modes{i});
    S = sortrows(stabilityMap(mask, :), 'V_mps');
    plot(S.V_mps, S.max_real_full, '-o', 'DisplayName', modes{i});
end
grid on;
xlabel('Velocity (m/s)');
ylabel('max real(lambda), full A (1/s)');
legend('Location','best');
saveas(fig, pathsOut.maxReal);
close(fig);

fig = figure('Visible','off','Color','w');
subplot(2,1,1);
hold on;
for i = 1:numel(modes)
    mask = strcmp(stabilityMap.mode, modes{i});
    S = sortrows(stabilityMap(mask, :), 'V_mps');
    plot(S.V_mps, S.max_real_longitudinal > 1e-3, '-o', ...
        'DisplayName', modes{i});
end
grid on;
ylabel('longitudinal unstable');
legend('Location','best');
subplot(2,1,2);
hold on;
for i = 1:numel(modes)
    mask = strcmp(stabilityMap.mode, modes{i});
    S = sortrows(stabilityMap(mask, :), 'V_mps');
    plot(S.V_mps, S.max_real_lateral > 1e-3, '-o', ...
        'DisplayName', modes{i});
end
grid on;
xlabel('Velocity (m/s)');
ylabel('lateral unstable');
saveas(fig, pathsOut.coverage);
close(fig);
end

function copy_deliverables(paths, figurePaths, docsDir)
copyfile(paths.reportMd, fullfile(docsDir, ...
    'NUAA_TRIM_TREND_VALIDATION_REPORT.md'));
copyfile(paths.pointsCsv, fullfile(docsDir, 'nuaa_trim_points.csv'));
copyfile(paths.branchCsv, fullfile(docsDir, ...
    'nuaa_trim_branch_comparison.csv'));
copyfile(paths.componentCsv, fullfile(docsDir, ...
    'nuaa_trim_component_moments.csv'));
copyfile(paths.stabilityCsv, fullfile(docsDir, 'nuaa_trim_stability.csv'));
copyfile(paths.stabilityMapCsv, fullfile(docsDir, 'nuaa_stability_map.csv'));
copyfile(paths.trendCsv, fullfile(docsDir, 'nuaa_trim_trend_summary.csv'));
names = fieldnames(figurePaths);
for i = 1:numel(names)
    copyfile(figurePaths.(names{i}), fullfile(docsDir, ...
        [names{i} '.png']));
end
end

function write_report(filePath, pointsTable, branchTable, trendTable, ...
        stabilityMap, stabilityTable, figurePaths, stabilityFigurePaths, ...
        elapsed, gitSha)
fid = fopen(filePath, 'w');
if fid < 0
    error('run_nuaa_trim_trend_validation:ReportOpenFailed', ...
        'Cannot write report: %s', filePath);
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '# NUAA Trim Trend Validation Report\n\n');
fprintf(fid, '## Project Goal Check\n\n');
fprintf(fid, ['This run preserves the component-level mechanistic chain, uses only ' ...
    'the current approved conceptual parameters, and evaluates whether the ' ...
    'model gives computable, continuous, explainable trim trends. It is not ' ...
    'a strict XV-15 or GTRS quantitative validation.\n\n']);
fprintf(fid, '- Git commit: `%s`\n', gitSha);
fprintf(fid, '- Elapsed seconds: %.3f\n', elapsed);
fprintf(fid, '- Primary accepted PASS trim points: %d\n\n', ...
    sum(pointsTable.isPrimary & pointsTable.converged & ...
    strcmp(pointsTable.credibilityClass, 'PASS')));

fprintf(fid, '## NUAA Section 4 Method Restatement\n\n');
fprintf(fid, ['NUAA Section 4 trims steady conditions by driving state derivatives ' ...
    'to zero so that resultant forces and moments balance. It computes ' ...
    'helicopter mode, fixed-wing mode, and conversion modes at nacelle angles ' ...
    '15 deg and 75 deg. Figures 5 and 6 compare controls and pitch attitude ' ...
    'versus speed. Figure 7 compares fixed-wing trim against GTRS and XV-15 ' ...
    'actual trim results. Because complete XV-15 data are unavailable, the ' ...
    'paper treats trend agreement and numerical closeness as rationality ' ...
    'evidence, then analyzes stability derivatives and eigenvalues at trimmed ' ...
    'linearization points. It does not require every open-loop mode to be stable.\n\n']);
fprintf(fid, ['This project currently has no complete digitized GTRS/XV-15 data, so ' ...
    'the result below is only a NUAA-style trim trend baseline and physical ' ...
    'reasonableness check.\n\n']);

fprintf(fid, '## Trend Summary\n\n');
write_markdown_table(fid, trendTable);
fprintf(fid, '\n## Branch Comparison\n\n');
if isempty(branchTable)
    fprintf(fid, 'No duplicated-speed branch comparisons were available.\n\n');
else
    write_markdown_table(fid, branchTable);
end
fprintf(fid, '\n## Stability Map Summary\n\n');
write_stability_summary(fid, stabilityMap, stabilityTable);
fprintf(fid, '\n## Figures\n\n');
figureNames = fieldnames(figurePaths);
for i = 1:numel(figureNames)
    fprintf(fid, '- %s: `%s`\n', figureNames{i}, figurePaths.(figureNames{i}));
end
stabNames = fieldnames(stabilityFigurePaths);
for i = 1:numel(stabNames)
    fprintf(fid, '- %s: `%s`\n', stabNames{i}, ...
        stabilityFigurePaths.(stabNames{i}));
end
fprintf(fid, '\n## Project Goal Check\n\n');
fprintf(fid, ['The run keeps the current component force/moment chain and approved ' ...
    'parameters. Any continuity, branch, control-margin, low-speed-boundary, ' ...
    'or open-loop instability limitations are reported as model limitations. ' ...
    'The current results cannot be called strict XV-15/GTRS validation because ' ...
    'the parameter set is conceptual, complete public comparison data are not ' ...
    'available in this workflow, and the low-order model omits effects such as ' ...
    'dynamic inflow and flight-control stabilization.\n']);
end

function write_stability_summary(fid, mapTable, stabilityTable)
if isempty(mapTable)
    fprintf(fid, 'No stability map rows were generated.\n');
    return;
end
modes = unique(mapTable.mode);
fprintf(fid, '|mode|points|candidate positive roots %%|longitudinal %%|lateral %%|dominant real min/median/max|\n');
fprintf(fid, '|-|-:|-:|-:|-:|-|\n');
for i = 1:numel(modes)
    S = mapTable(strcmp(mapTable.mode, modes{i}), :);
    pctFull = 100*sum(S.positiveRootCount > 0)/height(S);
    pctLong = 100*sum(S.max_real_longitudinal > 1e-3)/height(S);
    pctLat = 100*sum(S.max_real_lateral > 1e-3)/height(S);
    fprintf(fid, '|%s|%d|%.1f|%.1f|%.1f|%.4g / %.4g / %.4g|\n', ...
        modes{i}, height(S), pctFull, pctLong, pctLat, ...
        min(S.dominantReal), median(S.dominantReal), max(S.dominantReal));
end
fprintf(fid, '\nRobustness sample rows: %d\n', ...
    sum(strcmp(stabilityTable.sampleType, 'ROBUSTNESS_SAMPLE')));
end

function write_markdown_table(fid, T)
if isempty(T)
    fprintf(fid, '_No rows._\n');
    return;
end
names = T.Properties.VariableNames;
fprintf(fid, '|');
fprintf(fid, '%s|', names{:});
fprintf(fid, '\n|');
    separators = repmat({'-'}, size(names));
    fprintf(fid, '%s|', separators{:});
fprintf(fid, '\n');
n = min(height(T), 30);
for i = 1:n
    fprintf(fid, '|');
    for j = 1:numel(names)
        value = T.(names{j})(i);
        if iscell(value)
            text = value{1};
        elseif isnumeric(value) || islogical(value)
            text = mat2str(value);
        else
            text = char(value);
        end
        text = strrep(text, '|', '/');
        fprintf(fid, '%s|', text);
    end
    fprintf(fid, '\n');
end
if height(T) > n
    fprintf(fid, '\n_Only first %d of %d rows shown._\n', n, height(T));
end
end

function text = table_text(row, name)
value = row.(name);
if iscell(value)
    text = value{1};
elseif isstring(value)
    text = char(value);
else
    text = char(value);
end
end

function condition = make_condition(V, betaDeg)
condition = struct('V', V, 'betaM', betaDeg*pi/180, 'gamma', 0);
end

function paths = ensure_dir(path)
if ~exist(path, 'dir')
    mkdir(path);
end
paths = path;
end

function sha = get_git_sha(rootDir)
[status, text] = system(sprintf('git -C "%s" rev-parse HEAD', rootDir));
if status == 0
    sha = strtrim(text);
else
    sha = 'UNKNOWN';
end
end

function z = trim_vector(definition, trimReport)
z = zeros(numel(definition.unknownNames), 1);
for i = 1:numel(z)
    z(i) = trimReport.trimVariables.(definition.unknownNames{i});
end
end

function [margin, atLimit] = margin_deg(value, limits)
d2r = pi/180;
tol = 1e-8;
margin = min(value-limits(1), limits(2)-value)/d2r;
atLimit = abs(value-limits(1)) <= tol || abs(value-limits(2)) <= tol;
end

function signValue = paper_cyclic_sign()
signValue = 1;
end

function identity = approved_parameter_identity()
identity = ['P.wing.Cm0=-0.03; P.wing.Cmalpha=0; ' ...
    'P.fuselage.Cmalpha=0; P.htail.downwashAlpha=0.40; ' ...
    'P.htail.incidence=-2deg; P.htail.CLelevator=2.00; ' ...
    'P.control.elevatorLim=+-20deg'];
end

function band = instability_band(realPart)
if realPart <= 1e-3
    band = 'neutral_or_stable';
elseif realPart <= 0.05
    band = 'very_slow';
elseif realPart <= 0.3
    band = 'slow_to_medium';
else
    band = 'clear';
end
end

function rows = append_rows(rows, moreRows)
if isempty(moreRows)
    return;
end
rows = [rows; moreRows(:)];
end

function tf = is_real_finite(value)
tf = isreal(value) && all(isfinite(value(:)));
end

function value = ternary(condition, trueValue, falseValue)
if condition
    value = trueValue;
else
    value = falseValue;
end
end

function row = empty_point_row()
row = struct('mode', '', 'betaM_deg', NaN, 'V_mps', NaN, ...
    'sweep_direction', '', 'branch_id', '', 'isPrimary', false, ...
    'theta_deg', NaN, 'alpha_deg', NaN, 'collective_deg', NaN, ...
    'cyclicLong_deg', NaN, 'paperCyclic_deg', NaN, ...
    'elevator_deg', NaN, 'pitchCommand', NaN, 'residualNorm', NaN, ...
    'converged', false, 'finite', false, 'credibilityClass', 'NOT_RUN', ...
    'jacobianRank', NaN, 'jacobianConditionNumber', NaN, ...
    'collectiveMargin_deg', NaN, 'collectiveAtLimit', false, ...
    'cyclicLongMargin_deg', NaN, 'cyclicLongAtLimit', false, ...
    'elevatorMargin_deg', NaN, 'elevatorAtLimit', false, ...
    'anyControlAtLimit', false, 'atLimit', false, ...
    'seedSource', '', 'unknownNames', '', 'parameterIdentity', '', ...
    'git_sha', '', 'failureReason', '', 'errorIdentifier', '', ...
    'errorMessage', '');
end

function row = empty_component_row()
row = struct('mode', '', 'betaM_deg', NaN, 'V_mps', NaN, ...
    'sweep_direction', '', 'branch_id', '', ...
    'rotorPitchMoment_Nm', NaN, 'wingPitchMoment_Nm', NaN, ...
    'fuselagePitchMoment_Nm', NaN, 'htailPitchMoment_Nm', NaN, ...
    'vtailPitchMoment_Nm', NaN, 'totalPitchMoment_Nm', NaN, ...
    'wingCL', NaN, 'wingCLOverCLmax', NaN, 'errorIdentifier', '');
end

function point = empty_point()
point = struct('mode', '', 'betaM_deg', NaN, 'V_mps', NaN, ...
    'xTrim', [], 'uTrim', [], 'trimReport', struct(), ...
    'credibility', struct(), 'definition', struct(), 'success', false);
end

function row = empty_stability_map_row()
row = struct('mode', '', 'betaM_deg', NaN, 'V_mps', NaN, ...
    'stepScale', NaN, 'max_real_full', NaN, ...
    'max_real_longitudinal', NaN, 'max_real_lateral', NaN, ...
    'positiveRootCount', NaN, 'neutralRootCount', NaN, ...
    'dominantReal', NaN, 'dominantImag', NaN, ...
    'dominantNaturalFrequency', NaN, 'dominantDampingRatio', NaN, ...
    'tau_growth_s', NaN, 'participationStates', '', ...
    'linearizationFinite', false, 'openLoopCandidate', false, ...
    'instabilityBand', '', 'errorIdentifier', '');
end

function row = empty_stability_row()
row = struct('mode', '', 'betaM_deg', NaN, 'V_mps', NaN, ...
    'stepScale', NaN, 'sampleType', '', 'max_real_full', NaN, ...
    'max_real_longitudinal', NaN, 'max_real_lateral', NaN, ...
    'positiveRootCount', NaN, 'neutralRootCount', NaN, ...
    'dominantReal', NaN, 'dominantImag', NaN, 'tau_growth_s', NaN, ...
    'participationStates', '', 'classification', '', ...
    'errorIdentifier', '');
end
