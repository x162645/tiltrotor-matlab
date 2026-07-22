function manifest = plot_berger13_research_outputs(results,figureDir,rawDir)
%PLOT_BERGER13_RESEARCH_OUTPUTS Generate 21 traceable research figures.

if ~exist(figureDir,'dir'), mkdir(figureDir); end
if ~exist(rawDir,'dir'), mkdir(rawDir); end
set(groot,'defaultFigureVisible','off');
set(groot,'defaultAxesFontName','Microsoft YaHei');
set(groot,'defaultTextFontName','Microsoft YaHei');
entries = cell(21,6);
figureIndex = 0;
trim = results.trimDatabase.summary;
credible = strcmp(trim.status,'CREDIBLE');
derivatives = results.derivativeTable;
eigenvalues = results.eigenTable;
tracking = results.tracking.table;
representativeIndex = find(strcmp( ...
    results.linearDatabase.pointIds,'B45_V035'),1);
modal = results.linearDatabase.modalModels{representativeIndex};

    function register(fig,slug,titleText,dataTable,notes)
        figureIndex = figureIndex+1;
        base = sprintf('F%02d_%s',figureIndex,slug);
        pngPath = fullfile(figureDir,[base '.png']);
        svgPath = fullfile(figureDir,[base '.svg']);
        csvPath = fullfile(rawDir,[base '.csv']);
        set(fig,'Color','w','Position',[80,80,1000,650]);
        print(fig,pngPath,'-dpng','-r180');
        print(fig,svgPath,'-dsvg');
        if ~isempty(dataTable)
            writetable(dataTable,csvPath);
        else
            csvPath = '';
        end
        entries(figureIndex,:) = ...
            {base,titleText,pngPath,svgPath,csvPath,notes};
        close(fig);
    end

fig = figure; hold on;
scatter(trim.speedMps(credible),trim.betaMDeg(credible),80,'filled');
scatter(trim.speedMps(~credible),trim.betaMDeg(~credible),90,'x', ...
    'LineWidth',2);
xlabel('Speed (m/s)'); ylabel('Nacelle angle (deg)'); grid on;
title('Trim grid and credibility gate');
legend('CREDIBLE','FAILED / NONCREDIBLE','Location','best');
register(fig,'trim_operating_points','Trim operating points',trim, ...
    'Failures are retained and excluded from modal conclusions.');

fig = figure;
plot(trim.speedMps(credible),trim.collectiveDeg(credible),'o-', ...
    trim.speedMps(credible),trim.cyclicLongDeg(credible),'s-', ...
    trim.speedMps(credible),trim.elevatorDeg(credible),'^-','LineWidth',1.2);
xlabel('Speed (m/s)'); ylabel('Control (deg)'); grid on;
title('Controls at credible trim points');
legend('collective','cyclicLong','elevator','Location','best');
register(fig,'trim_controls','Trim controls',trim(credible,:), ...
    'Only credible points are shown.');

fig = figure; hold on;
for k = 1:min(3,numel(results.timeSimulations))
    sim = results.timeSimulations{k};
    plot(sim.time,sim.betaSym*180/pi,'LineWidth',1.2);
    plot(sim.time,sim.betaDiff*180/pi,'--','LineWidth',1.0);
end
xlabel('Time (s)'); ylabel('Nacelle coordinate (deg)'); grid on;
title('Symmetric and differential nacelle coordinates');
register(fig,'symmetric_differential_coordinates', ...
    'Symmetric/differential coordinates',results.timeSummary, ...
    'Solid: symmetric; dashed: differential.');

beta = trim.betaMDeg(credible);
projectedWake = abs(cosd(beta));
fig = figure; plot(beta,projectedWake,'o-','LineWidth',1.4); grid on;
xlabel('Nacelle angle (deg)'); ylabel('Normalized projected-wake index');
title('Independent half-wing wake geometry proxy');
wakeTable = table(beta,projectedWake,projectedWake, ...
    'VariableNames',{'betaMDeg','leftIndex','rightIndex'});
register(fig,'independent_wing_wake_regions','Independent wing wakes', ...
    wakeTable,'Geometry proxy only; loads use independent region models.');

sim = results.timeSimulations{1};
fig = figure; plot_case_beta(sim); title('Commanded actuator response');
register(fig,'actuator_response','Actuator response',time_table(sim), ...
    'Prescribed one-way command-actuator boundary.');

sens = results.sensitivityTable;
fig = figure; hold on;
mask = strcmp(sens.parameter,'omegaN');
plot(sens.factor(mask),sens.actuatorModeFrequencyHz(mask),'o-', ...
    'LineWidth',1.3);
mask = strcmp(sens.parameter,'zeta');
plot(sens.factor(mask),sens.actuatorModeDampingRatio(mask),'s-', ...
    'LineWidth',1.3);
xlabel('Parameter factor'); ylabel('Mode metric'); grid on;
title('Actuator bandwidth and damping sensitivity');
legend('actuator frequency (Hz)','actuator damping ratio','Location','best');
register(fig,'bandwidth_damping_sensitivity', ...
    'Bandwidth and damping sensitivity',sens(ismember(sens.parameter, ...
    {'omegaN','zeta'}),:),'Flight-response metrics remain in the data table.');

stabilityNames = {'Xu','Xw','Zu','Zw','Mu','Mw','Mq','Yv','Yp','Yr', ...
    'Lv','Lp','Lr','Nv','Np','Nr'};
mask = ismember(derivatives.derivativeName,stabilityNames) & ...
    strcmp(derivatives.pointId,'B45_V035');
fig = figure; bar(categorical(derivatives.derivativeName(mask)), ...
    derivatives.value(mask)); grid on;
xlabel('Derivative'); ylabel('Value (see database units)');
title('Representative stability derivatives');
register(fig,'stability_derivatives','Stability derivatives', ...
    derivatives(mask,:),'Different physical units are not compared directly.');

mask = contains(derivatives.derivativeName,'Command') | ...
    contains(derivatives.derivativeName,'lateralCyclic') | ...
    contains(derivatives.derivativeName,'aileron') | ...
    contains(derivatives.derivativeName,'rudder');
fig = figure; scatter(derivatives.speedMps(mask),derivatives.value(mask), ...
    20,derivatives.betaMDeg(mask),'filled'); colorbar; grid on;
xlabel('Speed (m/s)'); ylabel('Derivative value');
title('Control derivatives across credible points');
register(fig,'control_derivatives','Control derivatives', ...
    derivatives(mask,:),'Input names and units use the command contract.');

fig = figure; hold on;
heading = logical(eigenvalues.headingIntegrator);
dynamic = ~heading;
scatter(eigenvalues.realPartPerSecond(dynamic), ...
    eigenvalues.imagPartRadPerSecond(dynamic),22, ...
    eigenvalues.betaMDeg(dynamic),'filled');
scatter(eigenvalues.realPartPerSecond(heading), ...
    eigenvalues.imagPartRadPerSecond(heading),70,'kx','LineWidth',2);
xline(0,'k--'); colorbar; grid on;
xlabel('Real part (1/s)'); ylabel('Imaginary part (rad/s)');
title('Eigenvalues; heading integrator shown separately');
register(fig,'all_eigenvalues','All eigenvalues',eigenvalues, ...
    'The kinematic heading integrator is not stability-qualified.');

low = eigenvalues.naturalFrequencyRadPerSecond < 3;
fig = figure; scatter(eigenvalues.realPartPerSecond(low), ...
    eigenvalues.imagPartRadPerSecond(low),35,eigenvalues.speedMps(low), ...
    'filled'); xline(0,'k--'); colorbar; grid on;
xlabel('Real part (1/s)'); ylabel('Imaginary part (rad/s)');
title('Low-frequency eigenvalues');
register(fig,'low_frequency_eigenvalues','Low-frequency eigenvalues', ...
    eigenvalues(low,:),'Natural frequency below 3 rad/s.');

qualified = logical(eigenvalues.stabilityQualified);
fig = figure; scatter(eigenvalues.frequencyHz(qualified), ...
    eigenvalues.dampingRatio(qualified),25, ...
    eigenvalues.betaSymParticipation(qualified)+ ...
    eigenvalues.betaDiffParticipation(qualified),'filled');
colorbar; grid on; xlabel('Frequency (Hz)'); ylabel('Damping ratio');
title('Damping of stability-qualified modes');
register(fig,'modal_damping','Modal damping',eigenvalues(qualified,:), ...
    'Heading integrator excluded.');

fig = figure; scatter(eigenvalues.speedMps(dynamic), ...
    eigenvalues.frequencyHz(dynamic),25,eigenvalues.betaMDeg(dynamic), ...
    'filled'); colorbar; grid on;
xlabel('Speed (m/s)'); ylabel('Frequency (Hz)');
title('Dynamic-mode frequency across operating points');
register(fig,'modal_frequency','Modal frequency',eigenvalues(dynamic,:), ...
    'Prescribed actuator roots reflect placeholder omegaN and zeta.');

fig = figure; imagesc(modal.participation); colorbar; axis tight;
xlabel('Local mode index'); ylabel('State index');
title('Representative biorthogonal participation factors');
register(fig,'participation_factors','Participation factors',modal.table, ...
    'Representative point B45_V035.');

fig = figure; hold on;
paths = unique(tracking.pathId,'stable');
for k = 1:numel(paths)
    mask = strcmp(tracking.pathId,paths{k}) & ~tracking.headingIntegrator;
    scatter(tracking.sequenceInPath(mask),tracking.realPartPerSecond(mask), ...
        18,'DisplayName',paths{k});
end
grid on; xlabel('Sequence within continuous path');
ylabel('Real part (1/s)'); title('Independent continuous-path mode tracking');
legend('Location','best');
register(fig,'mode_tracking','Mode tracking',tracking, ...
    'No cross-angle or cross-failure-gap assignment is performed.');

cmp = results.comparisons{1};
fig = figure;
plot(cmp.time,cmp.nonlinear(:,9)*180/pi,'LineWidth',1.3); hold on;
plot(cmp.time,cmp.linear(:,9)*180/pi,'--','LineWidth',1.3); grid on;
xlabel('Time (s)'); ylabel('betaSym (deg)');
title('Local linear/nonlinear comparison');
legend('nonlinear','linear','Location','best');
register(fig,'linear_nonlinear_comparison','Linear/nonlinear comparison', ...
    comparison_table(cmp),'Internal local consistency, not validation.');

fig = figure; plot_case_beta(results.timeSimulations{4});
title('Left/right rate-limit mismatch');
register(fig,'left_right_rate_mismatch','Rate mismatch', ...
    time_table(results.timeSimulations{4}),'Valid-prefix guard is archived.');

fig = figure; plot_case_beta(results.timeSimulations{7});
title('Single-side command delay');
register(fig,'single_side_delay','Single-side delay', ...
    time_table(results.timeSimulations{7}),'Left command delay: 0.30 s.');

fig = figure; plot_case_beta(results.timeSimulations{8});
title('Single-side kinematic lock');
register(fig,'single_side_kinematic_lock','Kinematic lock', ...
    time_table(results.timeSimulations{8}), ...
    'No constraint torque or mechanical-jam load is claimed.');

parameters = unique(sens.parameter,'stable');
classCode = NaN(numel(parameters),1);
classOrder = {'CANNOT_RELIABLY_DETERMINE','TREND_ROBUST', ...
    'MAGNITUDE_SENSITIVE','HIGHLY_ASSUMPTION_DEPENDENT'};
for k = 1:numel(parameters)
    mask = strcmp(sens.parameter,parameters{k});
    classCode(k) = find(strcmp(classOrder, ...
        sens.conclusionClass{find(mask,1)}),1);
end
fig = figure; bar(categorical(parameters),classCode); grid on;
ylim([0.5,4.5]); yticks(1:4);
yticklabels({'CANNOT','ROBUST','SENSITIVE','ASSUMPTION DEPENDENT'});
xtickangle(25);
xlabel('Parameter'); ylabel('Conclusion class');
title('Sensitivity conclusion classification');
register(fig,'parameter_sensitivity','Parameter sensitivity',sens, ...
    'Each parameter uses one physical metric; cross-unit magnitudes are not plotted.');

fig = figure;
bar(categorical(trim.pointId),[double(credible),double(~credible)],'stacked');
grid on; xlabel('Research point'); ylabel('Classification flag');
title('Credibility boundary and retained failures');
legend('credible','failed/noncredible','Location','best');
register(fig,'capability_limitations','Capability limitations',trim, ...
    'This is a research credibility gate, not a flight envelope.');

indices = [1,3,7,8];
names = cell(4,1); validL = zeros(4,1); validN = zeros(4,1);
fullL = zeros(4,1); fullN = zeros(4,1); violation = NaN(4,1);
for k = 1:4
    sim = results.timeSimulations{indices(k)};
    names{k} = sim.caseDef.name;
    validL(k) = sim.validPrefixMetrics.maxAbsRollMomentNm;
    validN(k) = sim.validPrefixMetrics.maxAbsYawMomentNm;
    fullL(k) = sim.fullTrajectoryMetrics.maxAbsRollMomentNm;
    fullN(k) = sim.fullTrajectoryMetrics.maxAbsYawMomentNm;
    violation(k) = sim.firstEnvelopeViolationTime;
end
fig = figure; bar(categorical(names),[validL,validN]); grid on;
xtickangle(20); ylabel('Valid-prefix peak moment (N m)');
title('Nacelle-asymmetry lateral/directional loads');
legend('roll','yaw','Location','best');
loadTable = table(names,validL,validN,fullL,fullN,violation, ...
    'VariableNames',{'caseName','validPeakRollMomentNm', ...
    'validPeakYawMomentNm','fullPeakRollMomentNm','fullPeakYawMomentNm', ...
    'firstEnvelopeViolationTime'});
register(fig,'asynchronous_lateral_directional_loads', ...
    'Asynchronous lateral/directional loads',loadTable, ...
    'Quantitative claims use valid-prefix peaks only.');

manifest = cell2table(entries,'VariableNames', ...
    {'figureId','title','pngPath','svgPath','rawDataPath','notes'});
writetable(manifest,fullfile(figureDir,'FIGURE_METADATA.csv'));
save(fullfile(rawDir,'FIGURE_DATA_AND_METADATA.mat'), ...
    'manifest','results','-v7');
end

function tableOut = time_table(sim)
[speed,alpha,sideslip] = guard_columns(sim);
tableOut = array2table([sim.time,sim.x,sim.betaSym,sim.betaDiff, ...
    sim.lateralForceRollYawMoment,double(sim.limitActive), ...
    double(sim.guardValid),speed,alpha,sideslip], ...
    'VariableNames',[{'time'},get_state_names_13x10().', ...
    {'betaSym','betaDiff','lateralForceN','rollMomentNm', ...
    'yawMomentNm','limitActive','analysisGuardValid','bodySpeedMps', ...
    'alphaRad','sideslipRad'}]);
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

function tableOut = comparison_table(cmp)
tableOut = array2table([cmp.time,cmp.nonlinear,cmp.linear,cmp.error]);
end

function plot_case_beta(sim)
plot(sim.time,sim.x(:,10)*180/pi,'LineWidth',1.3); hold on;
plot(sim.time,sim.x(:,11)*180/pi,'--','LineWidth',1.3);
if isfinite(sim.firstEnvelopeViolationTime)
    xline(sim.firstEnvelopeViolationTime,'r:','Guard violation', ...
        'LineWidth',1.4);
end
xlabel('Time (s)'); ylabel('Nacelle angle (deg)'); grid on;
legend('betaML','betaMR','Location','best');
end
