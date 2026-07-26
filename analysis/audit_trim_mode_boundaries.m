function report = audit_trim_mode_boundaries(outputDir)
%AUDIT_TRIM_MODE_BOUNDARIES Check the former implicit 30/60 deg handoffs.
% The thresholds below are numerical audit criteria, not aircraft or
% controller parameters. A failed continuity classification prohibits
% treating the three trim definitions as one continuous control law.

if nargin < 1
    outputDir = '';
end
P13 = params_berger13();
d2r = pi/180;
hDeg = [1e-2;1e-3];
boundaryDeg = [30;60];
speedMps = [45;45];
modeLow = {'helicopter_longitudinal';'conversion_longitudinal'};
modeHigh = {'conversion_longitudinal';'airplane_longitudinal'};

pointRows = repmat(empty_point_row(),0,1);
comparisonRows = repmat(empty_comparison_row(),0,1);
for boundaryIndex = 1:numel(boundaryDeg)
    for stepIndex = 1:numel(hDeg)
        low = solve_side(boundaryDeg(boundaryIndex)-hDeg(stepIndex), ...
            speedMps(boundaryIndex),modeLow{boundaryIndex},'LOW');
        high = solve_side(boundaryDeg(boundaryIndex)+hDeg(stepIndex), ...
            speedMps(boundaryIndex),modeHigh{boundaryIndex},'HIGH');
        pointRows(end+1,1) = low; %#ok<AGROW>
        pointRows(end+1,1) = high; %#ok<AGROW>
        comparisonRows(end+1,1) = compare_pair( ...
            boundaryDeg(boundaryIndex),hDeg(stepIndex),low,high); %#ok<AGROW>
    end
end

pointTable = struct2table(pointRows);
comparisonTable = struct2table(comparisonRows);
smallest = comparisonTable.hDeg == min(hDeg);
boundarySummary = comparisonTable(smallest,:);

report.pointTable = pointTable;
report.comparisonTable = comparisonTable;
report.boundarySummary = boundarySummary;
report.auditCompleted = all(comparisonTable.evaluationCompleted);
report.continuityDemonstrated = all( ...
    strcmp(boundarySummary.classification,'CONTINUITY_DEMONSTRATED'));
report.claimAllowed = report.continuityDemonstrated;
report.allPassed = report.auditCompleted && ...
    all(strcmp(boundarySummary.classification, ...
    'CONTINUITY_NOT_DEMONSTRATED'));
report.thresholds = struct('directAngleJumpDeg',0.25, ...
    'normalizedVirtualCommandJump',0.02, ...
    'controlMarginJump',0.05);

if ~isempty(outputDir)
    if ~exist(outputDir,'dir')
        mkdir(outputDir);
    end
    writetable(pointTable,fullfile(outputDir, ...
        'TRIM_MODE_BOUNDARY_POINTS.csv'));
    writetable(comparisonTable,fullfile(outputDir, ...
        'TRIM_MODE_BOUNDARY_COMPARISON.csv'));
end

fprintf('\nTrim-mode boundary audit\n');
fprintf('========================\n');
for k = 1:height(boundarySummary)
    row = boundarySummary(k,:);
    fprintf(['%2.0f deg: %s; max direct jump=%.6g deg; ' ...
        'virtual jump=%.6g; margin jump=%.6g\n'], ...
        row.boundaryDeg,row.classification{1}, ...
        row.maxDirectAngleJumpDeg, ...
        row.normalizedVirtualCommandJump,row.controlMarginJump);
end

    function row = solve_side(betaDeg,V,mode,sideName)
        row = empty_point_row();
        row.boundaryDeg = round(betaDeg);
        row.hDeg = abs(betaDeg-row.boundaryDeg);
        row.side = sideName;
        row.betaDeg = betaDeg;
        row.speedMps = V;
        row.mode = mode;
        condition = struct('V',V,'betaM',betaDeg*d2r,'gamma',0);
        try
            [~,~,trimReport] = trim_berger13_symmetric( ...
                condition,P13,struct('mode',mode, ...
                'runMultipleSeeds',false));
            row.evaluationCompleted = true;
            row.status = trimReport.status;
            row.solverConverged = ...
                trimReport.baseTrimReport.solverConverged;
            row.physicalConverged = trimReport.physicalConverged;
            row.physicalStatus = trimReport.physicalStatus;
            row.thetaDeg = trimReport.x13(8)/d2r;
            row.collectiveDeg = trimReport.u10Torque(1)/d2r;
            row.cyclicLongDeg = trimReport.u10Torque(3)/d2r;
            row.elevatorDeg = trimReport.u10Torque(7)/d2r;
            [pitchCommand,normalizedCommand] = virtual_command( ...
                condition,trimReport);
            row.pitchCommand = pitchCommand;
            row.normalizedPitchCommand = normalizedCommand;
            row.rawResidualNorm = ...
                norm(trimReport.baseTrimReport.residual);
            row.scaledResidualNorm = ...
                norm(trimReport.baseTrimReport.scaledResidual);
            row.minimumControlMargin = ...
                trimReport.minimumUnknownMarginFraction;
        catch ME
            row.status = 'EVALUATION_ERROR';
            row.physicalStatus = ME.identifier;
            row.errorIdentifier = ME.identifier;
            row.errorMessage = ME.message;
        end
    end

    function [command,normalized] = virtual_command(condition,trimReport)
        direction = struct('cyclicDirection',-1,'elevatorDirection',-1);
        allocation0 = pitch_allocation_schedule( ...
            condition.betaM,0,P13.base,direction);
        if isfield(trimReport.trimVariables,'pitchCommand')
            command = trimReport.trimVariables.pitchCommand;
        elseif strcmp(trimReport.mode,'helicopter_longitudinal')
            command = trimReport.u10Torque(3)/( ...
                direction.cyclicDirection*allocation0.gCyclic* ...
                allocation0.cyclicReference);
        elseif strcmp(trimReport.mode,'airplane_longitudinal')
            command = trimReport.u10Torque(7)/( ...
                direction.elevatorDirection*allocation0.gElevator* ...
                allocation0.elevatorReference);
        else
            command = NaN;
        end
        normalized = command/allocation0.pitchCommandLimit;
    end

    function row = compare_pair(boundary,h,low,high)
        row = empty_comparison_row();
        row.boundaryDeg = boundary;
        row.hDeg = h;
        row.lowMode = low.mode;
        row.highMode = high.mode;
        row.evaluationCompleted = low.evaluationCompleted && ...
            high.evaluationCompleted;
        row.lowStatus = low.status;
        row.highStatus = high.status;
        row.thetaJumpDeg = high.thetaDeg-low.thetaDeg;
        row.collectiveJumpDeg = high.collectiveDeg-low.collectiveDeg;
        row.cyclicLongJumpDeg = high.cyclicLongDeg-low.cyclicLongDeg;
        row.elevatorJumpDeg = high.elevatorDeg-low.elevatorDeg;
        row.maxDirectAngleJumpDeg = max(abs([row.thetaJumpDeg, ...
            row.collectiveJumpDeg,row.cyclicLongJumpDeg, ...
            row.elevatorJumpDeg]));
        row.pitchCommandJump = high.pitchCommand-low.pitchCommand;
        row.normalizedVirtualCommandJump = abs( ...
            high.normalizedPitchCommand-low.normalizedPitchCommand);
        row.rawResidualNormLow = low.rawResidualNorm;
        row.rawResidualNormHigh = high.rawResidualNorm;
        row.scaledResidualNormLow = low.scaledResidualNorm;
        row.scaledResidualNormHigh = high.scaledResidualNorm;
        row.controlMarginJump = abs( ...
            high.minimumControlMargin-low.minimumControlMargin);
        row.lowPhysicalConverged = low.physicalConverged;
        row.highPhysicalConverged = high.physicalConverged;
        withinThreshold = row.evaluationCompleted && ...
            strcmp(low.status,'CREDIBLE') && ...
            strcmp(high.status,'CREDIBLE') && ...
            low.physicalConverged && high.physicalConverged && ...
            row.maxDirectAngleJumpDeg <= 0.25 && ...
            row.normalizedVirtualCommandJump <= 0.02 && ...
            row.controlMarginJump <= 0.05;
        if withinThreshold
            row.classification = 'CONTINUITY_DEMONSTRATED';
        else
            row.classification = 'CONTINUITY_NOT_DEMONSTRATED';
        end
    end
end

function row = empty_point_row()
row = struct('boundaryDeg',NaN,'hDeg',NaN,'side','', ...
    'betaDeg',NaN,'speedMps',NaN,'mode','', ...
    'evaluationCompleted',false,'status','NOT_RUN', ...
    'solverConverged',false,'physicalConverged',false, ...
    'physicalStatus','NOT_RUN','thetaDeg',NaN,'collectiveDeg',NaN, ...
    'cyclicLongDeg',NaN,'elevatorDeg',NaN,'pitchCommand',NaN, ...
    'normalizedPitchCommand',NaN,'rawResidualNorm',NaN, ...
    'scaledResidualNorm',NaN,'minimumControlMargin',NaN, ...
    'errorIdentifier','','errorMessage','');
end

function row = empty_comparison_row()
row = struct('boundaryDeg',NaN,'hDeg',NaN,'lowMode','', ...
    'highMode','','evaluationCompleted',false,'lowStatus','', ...
    'highStatus','','thetaJumpDeg',NaN,'collectiveJumpDeg',NaN, ...
    'cyclicLongJumpDeg',NaN,'elevatorJumpDeg',NaN, ...
    'maxDirectAngleJumpDeg',NaN,'pitchCommandJump',NaN, ...
    'normalizedVirtualCommandJump',NaN,'rawResidualNormLow',NaN, ...
    'rawResidualNormHigh',NaN,'scaledResidualNormLow',NaN, ...
    'scaledResidualNormHigh',NaN,'controlMarginJump',NaN, ...
    'lowPhysicalConverged',false,'highPhysicalConverged',false, ...
    'classification','NOT_RUN');
end
