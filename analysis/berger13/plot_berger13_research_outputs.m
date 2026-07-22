function manifest = plot_berger13_research_outputs(results,figureDir,rawDir)
%PLOT_BERGER13_RESEARCH_OUTPUTS Generate figures and traceable raw data.

if ~exist(figureDir,'dir'), mkdir(figureDir); end
if ~exist(rawDir,'dir'), mkdir(rawDir); end
set(groot,'defaultFigureVisible','off');
set(groot,'defaultAxesFontName','Microsoft YaHei');
set(groot,'defaultTextFontName','Microsoft YaHei');

entries = cell(21,6);
index = 0;
trim = results.trimDatabase.summary;
credible = strcmp(trim.status,'CREDIBLE');
derivatives = results.derivativeTable;
eigenvalues = results.eigenTable;
tracking = results.tracking.table;
representativeIndex = find(strcmp( ...
    results.linearDatabase.pointIds,'B45_V035'),1);
modal = results.linearDatabase.modalModels{representativeIndex};

    function register(fig,slug,titleText,dataTable,notes)
        index = index+1;
        base = sprintf('F%02d_%s',index,slug);
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
        entries(index,:) = {base,titleText,pngPath,svgPath,csvPath,notes};
        close(fig);
    end

fig = figure; hold on;
scatter(trim.speedMps(credible),trim.betaMDeg(credible),80,'filled');
scatter(trim.speedMps(~credible),trim.betaMDeg(~credible),90,'x','LineWidth',2);
xlabel('飞行速度 V/(m·s^{-1})'); ylabel('短舱倾转角 \beta_M/(°)');
title('13×10 模型配平工况与可信度分类'); grid on;
legend('CREDIBLE','非可信/失败','Location','best');
register(fig,'trim_operating_points','配平工况图',trim, ...
    '研究网格，不代表经验证的转换走廊');

fig = figure;
plot(trim.speedMps(credible),trim.collectiveDeg(credible),'o-', ...
    trim.speedMps(credible),trim.cyclicLongDeg(credible),'s-', ...
    trim.speedMps(credible),trim.elevatorDeg(credible),'^-','LineWidth',1.2);
xlabel('飞行速度 V/(m·s^{-1})'); ylabel('控制量/(°)');
title('可信配平点控制量'); grid on;
legend('总距','纵向周期变距','升降舵','Location','best');
register(fig,'trim_controls','配平控制量',trim(credible,:), ...
    '仅绘制通过可信度门限的工况');

fig = figure; hold on;
for k = 1:min(3,numel(results.timeSimulations))
    sim = results.timeSimulations{k};
    plot(sim.time,sim.betaSym*180/pi,'LineWidth',1.2);
    plot(sim.time,sim.betaDiff*180/pi,'--','LineWidth',1.0);
end
xlabel('时间/s'); ylabel('对称/差动短舱角/(°)');
title('短舱对称—差动坐标响应'); grid on;
register(fig,'symmetric_differential_coordinates','对称/差动坐标', ...
    results.timeSummary(1:min(3,height(results.timeSummary)),:), ...
    '实线为对称坐标，虚线为差动坐标');

fig = figure;
beta = trim.betaMDeg(credible);
projectedWake = abs(cosd(beta));
plot(beta,projectedWake,'o-','LineWidth',1.4); hold on;
plot(beta,projectedWake,'s--','LineWidth',1.2);
xlabel('短舱倾转角 \beta_M/(°)'); ylabel('归一化投影滑流指标');
title('左右机翼独立滑流区的对称基准'); grid on;
legend('左半翼','右半翼','Location','best');
wakeTable = table(beta,projectedWake,projectedWake, ...
    'VariableNames',{'betaMDeg','leftProjectedWakeIndex', ...
    'rightProjectedWakeIndex'});
register(fig,'independent_wing_wake_regions','左右滑流区',wakeTable, ...
    '几何投影指标；载荷在代码中按左右侧独立求值');

sim = results.timeSimulations{1};
fig = figure; plot_case_beta(sim); title('左右短舱执行机构响应');
register(fig,'actuator_response','执行机构响应',time_table(sim), ...
    '代表工况 B45_V035 的对称角指令阶跃');

sens = results.sensitivityTable;
fig = figure; hold on;
omegaMask = strcmp(sens.parameter,'omegaN');
zetaMask = strcmp(sens.parameter,'zeta');
plot(sens.factor(omegaMask),sens.spectralAbscissaPerSecond(omegaMask), ...
    'o-','LineWidth',1.3);
plot(sens.factor(zetaMask),sens.spectralAbscissaPerSecond(zetaMask), ...
    's-','LineWidth',1.3);
xlabel('参数比例因子'); ylabel('谱横坐标/(s^{-1})');
title('执行机构带宽与阻尼敏感性'); grid on;
legend('\omega_n','\zeta','Location','best');
register(fig,'bandwidth_damping_sensitivity','带宽和阻尼敏感性', ...
    sens(omegaMask | zetaMask,:), ...
    '谱横坐标来自固定可信配平点的局部线性模型');

stabilityNames = {'Xu','Xw','Zu','Zw','Mu','Mw','Mq','Yv','Yp','Yr', ...
    'Lv','Lp','Lr','Nv','Np','Nr'};
mask = ismember(derivatives.derivativeName,stabilityNames);
mask = mask & strcmp(derivatives.pointId,'B45_V035');
fig = figure;
bar(categorical(derivatives.derivativeName(mask)),derivatives.value(mask));
xlabel('稳定导数'); ylabel('数值（单位见数据库）');
title('可信工况稳定导数数据库'); grid on;
register(fig,'stability_derivatives','稳定导数',derivatives(mask,:), ...
    '不同物理单位不得按柱高作跨导数直接比较');

mask = contains(derivatives.derivativeName,'Command') | ...
    contains(derivatives.derivativeName,'lateralCyclic') | ...
    contains(derivatives.derivativeName,'aileron') | ...
    contains(derivatives.derivativeName,'rudder');
fig = figure;
scatter(derivatives.speedMps(mask),derivatives.value(mask),20, ...
    derivatives.betaMDeg(mask),'filled'); colorbar;
xlabel('飞行速度 V/(m·s^{-1})'); ylabel('控制导数（单位见数据库）');
title('控制导数随工况变化'); grid on;
register(fig,'control_derivatives','控制导数',derivatives(mask,:), ...
    '颜色表示短舱倾转角');

fig = figure;
scatter(eigenvalues.realPartPerSecond,eigenvalues.imagPartRadPerSecond, ...
    22,eigenvalues.betaMDeg,'filled'); xline(0,'k--'); colorbar;
xlabel('实部/(s^{-1})'); ylabel('虚部/(rad·s^{-1})');
title('全部可信工况特征根'); grid on;
register(fig,'all_eigenvalues','全部特征根',eigenvalues, ...
    '颜色表示短舱倾转角；仅属内部局部线性结果');

low = eigenvalues.naturalFrequencyRadPerSecond < 3;
fig = figure;
scatter(eigenvalues.realPartPerSecond(low), ...
    eigenvalues.imagPartRadPerSecond(low),35,eigenvalues.speedMps(low),'filled');
xline(0,'k--'); colorbar; grid on;
xlabel('实部/(s^{-1})'); ylabel('虚部/(rad·s^{-1})');
title('低频特征根局部放大');
register(fig,'low_frequency_eigenvalues','低频特征根', ...
    eigenvalues(low,:), '固有频率小于 3 rad/s');

fig = figure;
scatter(eigenvalues.frequencyHz,eigenvalues.dampingRatio,25, ...
    eigenvalues.betaSymParticipation+eigenvalues.betaDiffParticipation,'filled');
xlabel('频率/Hz'); ylabel('阻尼比'); title('模态阻尼特性');
colorbar; grid on;
register(fig,'modal_damping','模态阻尼',eigenvalues, ...
    '颜色为短舱状态参与度之和');

fig = figure;
scatter(eigenvalues.speedMps,eigenvalues.frequencyHz,25, ...
    eigenvalues.betaMDeg,'filled'); colorbar; grid on;
xlabel('飞行速度 V/(m·s^{-1})'); ylabel('频率/Hz');
title('模态频率随速度与短舱角变化');
register(fig,'modal_frequency','模态频率',eigenvalues, ...
    '颜色表示短舱倾转角');

fig = figure; imagesc(modal.participation); colorbar; axis tight;
xlabel('局部模态序号'); ylabel('状态序号');
title('代表工况状态参与因子');
register(fig,'participation_factors','参与因子',modal.table, ...
    'B45_V035；行顺序对应 13 状态契约');

fig = figure; hold on;
modeIds = unique(tracking.modeId).';
for modeId = modeIds
    modeMask = tracking.modeId == modeId;
    plot(find(modeMask),tracking.realPartPerSecond(modeMask),'.-');
end
grid on; xlabel('跟踪序列位置'); ylabel('特征根实部/(s^{-1})');
title('基于全局匹配的模态跟踪');
register(fig,'mode_tracking','模态跟踪',tracking, ...
    '匹配综合特征根距离、MAC 和参与因子距离');

cmp = results.comparisons{1};
fig = figure;
plot(cmp.time,cmp.nonlinear(:,9)*180/pi,'LineWidth',1.3); hold on;
plot(cmp.time,cmp.linear(:,9)*180/pi,'--','LineWidth',1.3);
xlabel('时间/s'); ylabel('\beta_{sym}/(°)');
title('小扰动线性—非线性响应比较'); grid on;
legend('非线性','线性','Location','best');
register(fig,'linear_nonlinear_comparison','线性—非线性比较', ...
    comparison_table(cmp), '小幅 betaSymCommand 阶跃');

fig = figure; plot_case_beta(results.timeSimulations{4});
title('左右速率限制不一致响应');
register(fig,'left_right_rate_mismatch','左右速率差异', ...
    time_table(results.timeSimulations{4}), '左侧速率比例为名义值的 0.35');

fig = figure; plot_case_beta(results.timeSimulations{7});
title('单侧命令延迟响应');
register(fig,'single_side_delay','单侧延迟', ...
    time_table(results.timeSimulations{7}), '左侧外部命令延迟 0.30 s');

fig = figure; plot_case_beta(results.timeSimulations{8});
title('单侧短舱卡滞响应');
register(fig,'single_side_stuck','单侧卡滞', ...
    time_table(results.timeSimulations{8}), '左侧执行机构卡滞');

fig = figure;
parameters = unique(sens.parameter,'stable');
response = NaN(numel(parameters),1);
for k = 1:numel(parameters)
    parameterMask = strcmp(sens.parameter,parameters{k});
    candidates = [sens.maxBetaDiffRad(parameterMask); ...
        sens.primaryLoadMetric(parameterMask)];
    candidates = candidates(isfinite(candidates));
    if ~isempty(candidates), response(k) = max(abs(candidates)); end
end
bar(categorical(parameters),response); grid on;
xlabel('敏感性参数'); ylabel('归档主响应量（各自单位）');
title('参数敏感性筛选'); xtickangle(25);
register(fig,'parameter_sensitivity','参数敏感性',sens, ...
    '跨参数量纲不同，仅用于筛选，不作绝对量直接比较');

fig = figure;
bar(categorical(trim.pointId),[double(credible),double(~credible)],'stacked');
ylabel('分类标记'); xlabel('研究工况');
title('研究能力边界与非可信工况保留'); grid on;
legend('可信','非可信/失败','Location','best');
register(fig,'capability_limitations','研究能力和限制',trim, ...
    '失败点未被删除，也未用于模态结论');

fig = figure;
names = {results.timeSimulations{1}.caseDef.name; ...
    results.timeSimulations{3}.caseDef.name; ...
    results.timeSimulations{7}.caseDef.name; ...
    results.timeSimulations{8}.caseDef.name};
indices = [1,3,7,8]; peakL = zeros(4,1); peakN = zeros(4,1);
for k = 1:4
    peakL(k) = results.timeSimulations{indices(k)}.metrics.maxAbsRollMomentNm;
    peakN(k) = results.timeSimulations{indices(k)}.metrics.maxAbsYawMomentNm;
end
bar(categorical(names),[peakL,peakN]); grid on; xtickangle(20);
ylabel('峰值力矩/(N·m)'); title('短舱不同步引起的横航向载荷');
legend('滚转力矩','偏航力矩','Location','best');
loadTable = table(names,peakL,peakN, ...
    'VariableNames',{'caseName','peakRollMomentNm','peakYawMomentNm'});
register(fig,'asynchronous_lateral_directional_loads', ...
    '短舱不同步横航向载荷',loadTable, ...
    '峰值含代表工况静态载荷；详见原始时程');

manifest = cell2table(entries,'VariableNames', ...
    {'figureId','titleChinese','pngPath','svgPath','rawDataPath','notes'});
writetable(manifest,fullfile(figureDir,'FIGURE_METADATA.csv'));
save(fullfile(rawDir,'FIGURE_DATA_AND_METADATA.mat'), ...
    'manifest','results','-v7');
end

function tableOut = time_table(sim)
tableOut = array2table([sim.time,sim.x,sim.betaSym,sim.betaDiff, ...
    sim.lateralForceRollYawMoment,double(sim.limitActive)], ...
    'VariableNames',[{'time'},get_state_names_13x10().', ...
    {'betaSym','betaDiff','lateralForceN','rollMomentNm', ...
    'yawMomentNm','limitActive'}]);
end

function tableOut = comparison_table(cmp)
tableOut = array2table([cmp.time,cmp.nonlinear,cmp.linear,cmp.error]);
end

function plot_case_beta(sim)
plot(sim.time,sim.x(:,10)*180/pi,'LineWidth',1.3); hold on;
plot(sim.time,sim.x(:,11)*180/pi,'--','LineWidth',1.3);
xlabel('时间/s'); ylabel('短舱角/(°)'); grid on;
legend('\beta_{ML}','\beta_{MR}','Location','best');
end
