function fig = launch_tiltrotor_app()
%LAUNCH_TILTROTOR_APP Open the tiltrotor trim and linear-response workbench.
% The application is implemented as text-based MATLAB code for version
% control and R2021a compatibility. Model equations remain in model/analysis.

P = params_nominal();
trimResult = [];
linearResult = [];
responseResult = [];
nacelleResponseResult = [];
parameterRows = make_parameter_rows();
stateNames = {'u','v','w','p','q','r','phi','theta','psi'};
controlNames = {'collective','diffCollective','cyclicLong', ...
    'diffCyclic','aileron','elevator','rudder'};

fig = uifigure('Name','Tiltrotor Analysis Workbench', ...
    'Position',[80 60 1420 860]);
root = uigridlayout(fig,[2 1]);
root.RowHeight = {54,'1x'};
root.Padding = [10 8 10 10];
root.RowSpacing = 8;

header = uigridlayout(root,[1 8]);
header.Layout.Row = 1;
header.ColumnWidth = {270,22,'1x',120,120,120,120,150};
header.ColumnSpacing = 8;

uilabel(header,'Text','倾转旋翼机分析工作台', ...
    'FontSize',20,'FontWeight','bold');
statusLamp = uilamp(header,'Color',[0.93 0.69 0.13]);
statusLabel = uilabel(header,'Text','已载入名义概念参数');
uibutton(header,'Text','检查参数', ...
    'ButtonPushedFcn',@onValidateParameters);
uibutton(header,'Text','恢复默认', ...
    'ButtonPushedFcn',@onResetParameters);
uibutton(header,'Text','导出工况', ...
    'ButtonPushedFcn',@onExportSession);
uibutton(header,'Text','使用说明', ...
    'ButtonPushedFcn',@onShowHelp);
uilabel(header,'Text','内部角度：rad｜界面角度：deg', ...
    'HorizontalAlignment','right');

mainTabs = uitabgroup(root);
mainTabs.Layout.Row = 2;
parameterTab = uitab(mainTabs,'Title','关键参数');
trimTab = uitab(mainTabs,'Title','配平');
linearTab = uitab(mainTabs,'Title','线性化与模态');
responseTab = uitab(mainTabs,'Title','操纵响应');
nacelleTab = uitab(mainTabs,'Title','短舱动态（实验）');

%% Parameter tab
parameterLayout = uigridlayout(parameterTab,[2 1]);
parameterLayout.RowHeight = {'1x',95};
parameterLayout.Padding = [8 8 8 8];
parameterTable = uitable(parameterLayout, ...
    'ColumnName',{'分组','参数','字段','数值','单位','来源分类'}, ...
    'ColumnEditable',[false false false true false false], ...
    'ColumnWidth',{100,190,180,110,100,150}, ...
    'CellEditCallback',@onParameterEdited);
uitextarea(parameterLayout,'Editable','off', ...
    'Value',{ ...
    '这里仅暴露会直接影响当前概念模型和数值计算的关键参数。'; ...
    '修改参数后，已有配平、线性化和响应结果会自动失效。'; ...
    '“检查通过”仅表示结构、单位和基本数值条件合理，不代表完成 XV-15 型号验证。'});
refresh_parameter_table();

%% Trim tab
trimLayout = uigridlayout(trimTab,[1 2]);
trimLayout.ColumnWidth = {330,'1x'};
trimLayout.Padding = [8 8 8 8];

trimInputPanel = uipanel(trimLayout,'Title','工况与初值');
trimInputGrid = uigridlayout(trimInputPanel,[11 2]);
trimInputGrid.RowHeight = repmat({34},1,11);
trimInputGrid.ColumnWidth = {165,'1x'};
trimInputGrid.Padding = [10 10 10 10];

uilabel(trimInputGrid,'Text','目标空速 V (m/s)');
trimVField = uieditfield(trimInputGrid,'numeric','Value',0,'Limits',[0 Inf]);
uilabel(trimInputGrid,'Text','短舱倾转角 betaM (deg)');
trimBetaField = uieditfield(trimInputGrid,'numeric','Value',0,'Limits',[0 90]);
uilabel(trimInputGrid,'Text','航迹角 gamma (deg)');
trimGammaField = uieditfield(trimInputGrid,'numeric','Value',0);
uilabel(trimInputGrid,'Text','初始俯仰角 (deg)');
trimTheta0Field = uieditfield(trimInputGrid,'numeric','Value',0);
uilabel(trimInputGrid,'Text','初始总距 (deg)');
trimCollective0Field = uieditfield(trimInputGrid,'numeric','Value',18);
uilabel(trimInputGrid,'Text','初始纵向周期变距 (deg)');
trimCyclic0Field = uieditfield(trimInputGrid,'numeric','Value',0);
uilabel(trimInputGrid,'Text','俯仰搜索限幅 (deg)');
trimThetaLimitField = uieditfield(trimInputGrid,'numeric','Value',35,'Limits',[1 89]);
uilabel(trimInputGrid,'Text','启用多初值');
trimMultiStartCheck = uicheckbox(trimInputGrid,'Value',true,'Text','');
uilabel(trimInputGrid,'Text','总是完成全部初值');
trimAlwaysMultiCheck = uicheckbox(trimInputGrid,'Value',false,'Text','');
runTrimButton = uibutton(trimInputGrid,'Text','运行配平', ...
    'FontWeight','bold','ButtonPushedFcn',@onRunTrim);
runTrimButton.Layout.Column = [1 2];
trimStatusLabel = uilabel(trimInputGrid,'Text','尚未运行', ...
    'HorizontalAlignment','center');
trimStatusLabel.Layout.Column = [1 2];

trimOutputTabs = uitabgroup(trimLayout);
trimStateTab = uitab(trimOutputTabs,'Title','状态量');
trimControlTab = uitab(trimOutputTabs,'Title','操纵量');
trimResidualTab = uitab(trimOutputTabs,'Title','残差与载荷');
trimStateGrid = make_fill_grid(trimStateTab);
trimControlGrid = make_fill_grid(trimControlTab);
trimResidualGrid = make_fill_grid(trimResidualTab);
trimStateTable = uitable(trimStateGrid, ...
    'ColumnName',{'状态','数值','单位'},'ColumnWidth',{140,160,120});
trimControlTable = uitable(trimControlGrid, ...
    'ColumnName',{'操纵','数值','单位'},'ColumnWidth',{180,160,120});
trimResidualTable = uitable(trimResidualGrid, ...
    'ColumnName',{'项目','数值','单位'},'ColumnWidth',{210,180,140});

%% Linearization tab
linearLayout = uigridlayout(linearTab,[2 2]);
linearLayout.RowHeight = {52,'1x'};
linearLayout.ColumnWidth = {'1.2x','1x'};
linearLayout.Padding = [8 8 8 8];
linearTop = uigridlayout(linearLayout,[1 3]);
linearTop.Layout.Row = 1;
linearTop.Layout.Column = [1 2];
linearTop.ColumnWidth = {160,220,'1x'};
runLinearButton = uibutton(linearTop,'Text','运行线性化', ...
    'Enable','off','FontWeight','bold', ...
    'ButtonPushedFcn',@onRunLinearization);
linearStatusLabel = uilabel(linearTop,'Text','需要先获得收敛配平点');
uilabel(linearTop,'Text','A/B 尺寸随当前状态维度变化；中心差分步长来自当前参数', ...
    'HorizontalAlignment','right');

matrixTabs = uitabgroup(linearLayout);
matrixTabs.Layout.Row = 2;
matrixTabs.Layout.Column = 1;
aTab = uitab(matrixTabs,'Title','A 矩阵');
bTab = uitab(matrixTabs,'Title','B 矩阵');
aGrid = make_fill_grid(aTab);
bGrid = make_fill_grid(bTab);
aTable = uitable(aGrid,'ColumnName',stateNames,'RowName',stateNames);
bTable = uitable(bGrid,'ColumnName',controlNames,'RowName',stateNames);

modePanel = uipanel(linearLayout,'Title','特征值与稳定性');
modePanel.Layout.Row = 2;
modePanel.Layout.Column = 2;
modeGrid = uigridlayout(modePanel,[2 1]);
modeGrid.RowHeight = {'1x','1x'};
eigenAxes = uiaxes(modeGrid);
title(eigenAxes,'特征值复平面');
xlabel(eigenAxes,'Real (1/s)');
ylabel(eigenAxes,'Imag (rad/s)');
grid(eigenAxes,'on');
eigenTable = uitable(modeGrid, ...
    'ColumnName',{'Real','Imag','wn','zeta','时间尺度(s)','分类'});

%% Response tab
responseLayout = uigridlayout(responseTab,[1 2]);
responseLayout.ColumnWidth = {345,'1x'};
responseLayout.Padding = [8 8 8 8];
responseInputPanel = uipanel(responseLayout,'Title','小扰动输入设置');
responseInputGrid = uigridlayout(responseInputPanel,[12 2]);
responseInputGrid.RowHeight = [repmat({34},1,11), {'1x'}];
responseInputGrid.ColumnWidth = {165,'1x'};
responseInputGrid.Padding = [10 10 10 10];

uilabel(responseInputGrid,'Text','操纵通道');
responseControlDrop = uidropdown(responseInputGrid,'Items',controlNames, ...
    'Value','cyclicLong');
uilabel(responseInputGrid,'Text','输入波形');
responseWaveformDrop = uidropdown(responseInputGrid, ...
    'Items',{'step','pulse','sine','doublet'},'Value','step');
uilabel(responseInputGrid,'Text','幅值 (deg)');
responseAmplitudeField = uieditfield(responseInputGrid,'numeric','Value',0.5);
uilabel(responseInputGrid,'Text','开始时间 (s)');
responseStartField = uieditfield(responseInputGrid,'numeric','Value',1,'Limits',[0 Inf]);
uilabel(responseInputGrid,'Text','持续时间 (s)');
responseDurationField = uieditfield(responseInputGrid,'numeric','Value',1,'Limits',[0 Inf]);
uilabel(responseInputGrid,'Text','正弦频率 (Hz)');
responseFrequencyField = uieditfield(responseInputGrid,'numeric','Value',0.5,'Limits',[0.001 Inf]);
uilabel(responseInputGrid,'Text','仿真总时长 (s)');
responseTotalTimeField = uieditfield(responseInputGrid,'numeric','Value',10,'Limits',[0.01 Inf]);
uilabel(responseInputGrid,'Text','输出时间步长 (s)');
responseStepField = uieditfield(responseInputGrid,'numeric','Value',0.02,'Limits',[0.001 Inf]);
uilabel(responseInputGrid,'Text','显示状态');
responseStateDrop = uidropdown(responseInputGrid,'Items',stateNames, ...
    'Value','theta','ValueChangedFcn',@onResponseDisplayChanged);
uilabel(responseInputGrid,'Text','显示实际总量');
responseActualCheck = uicheckbox(responseInputGrid,'Value',false,'Text','', ...
    'ValueChangedFcn',@onResponseDisplayChanged);
runResponseButton = uibutton(responseInputGrid,'Text','运行线性响应', ...
    'Enable','off','FontWeight','bold', ...
    'ButtonPushedFcn',@onRunResponse);
runResponseButton.Layout.Column = [1 2];
responseSummaryTable = uitable(responseInputGrid, ...
    'ColumnName',{'指标','数值'},'RowName',{});
responseSummaryTable.Layout.Column = [1 2];

responsePlotGrid = uigridlayout(responseLayout,[2 1]);
responsePlotGrid.RowHeight = {'1x','1x'};
responseInputAxes = uiaxes(responsePlotGrid);
title(responseInputAxes,'操纵输入扰动');
xlabel(responseInputAxes,'Time (s)');
ylabel(responseInputAxes,'Input (deg)');
grid(responseInputAxes,'on');
responseOutputAxes = uiaxes(responsePlotGrid);
title(responseOutputAxes,'状态响应');
xlabel(responseOutputAxes,'Time (s)');
grid(responseOutputAxes,'on');

%% Experimental nacelle dynamics tab
nacelleLayout = uigridlayout(nacelleTab,[1 2]);
nacelleLayout.ColumnWidth = {360,'1x'};
nacelleLayout.Padding = [8 8 8 8];

nacelleInputPanel = uipanel(nacelleLayout,'Title','实验设置');
nacelleInputGrid = uigridlayout(nacelleInputPanel,[13 2]);
nacelleInputGrid.RowHeight = [repmat({34},1,10), {42}, {70}, {'1x'}];
nacelleInputGrid.ColumnWidth = {170,'1x'};
nacelleInputGrid.Padding = [10 10 10 10];

uilabel(nacelleInputGrid,'Text','启用短舱动态状态');
nacelleEnableCheck = uicheckbox(nacelleInputGrid,'Value',false,'Text','');
uilabel(nacelleInputGrid,'Text','代表空速 V (m/s)');
nacelleVField = uieditfield(nacelleInputGrid,'numeric','Value',70,'Limits',[0 Inf]);
uilabel(nacelleInputGrid,'Text','初始短舱角 (deg)');
nacelleInitialBetaField = uieditfield(nacelleInputGrid,'numeric', ...
    'Value',15,'Limits',[0 90]);
uilabel(nacelleInputGrid,'Text','目标短舱角 (deg)');
nacelleCommandBetaField = uieditfield(nacelleInputGrid,'numeric','Value',75);
uilabel(nacelleInputGrid,'Text','最大短舱角速度 (deg/s)');
nacelleRateLimitField = uieditfield(nacelleInputGrid,'numeric', ...
    'Value',8,'Limits',[0.1 Inf]);
uilabel(nacelleInputGrid,'Text','短舱动态频率 (rad/s)');
nacelleOmegaField = uieditfield(nacelleInputGrid,'numeric', ...
    'Value',2.0,'Limits',[0.01 Inf]);
uilabel(nacelleInputGrid,'Text','短舱阻尼比');
nacelleZetaField = uieditfield(nacelleInputGrid,'numeric', ...
    'Value',0.8,'Limits',[0.01 Inf]);
uilabel(nacelleInputGrid,'Text','仿真时长 (s)');
nacelleDurationField = uieditfield(nacelleInputGrid,'numeric', ...
    'Value',6,'Limits',[0.1 60]);
uilabel(nacelleInputGrid,'Text','输出时间步长 (s)');
nacelleStepField = uieditfield(nacelleInputGrid,'numeric', ...
    'Value',0.05,'Limits',[0.001 Inf]);
runNacelleButton = uibutton(nacelleInputGrid,'Text','运行短舱动态响应', ...
    'FontWeight','bold','ButtonPushedFcn',@onRunNacelleResponse);
runNacelleButton.Layout.Column = [1 2];
nacelleStatusLabel = uilabel(nacelleInputGrid,'Text','默认关闭，尚未运行', ...
    'HorizontalAlignment','center');
nacelleStatusLabel.Layout.Column = [1 2];
nacelleInfoArea = uitextarea(nacelleInputGrid,'Editable','off','Value',{ ...
    '该功能为实验扩展，默认关闭。启用后模型状态由 9 个增加到 11 个，用于研究短舱角滞后和速率限制。'; ...
    '响应为开环代表工况，不代表完整转换过程。'});
nacelleInfoArea.Layout.Column = [1 2];

nacellePlotGrid = uigridlayout(nacelleLayout,[3 1]);
nacellePlotGrid.RowHeight = {'1x','1x',120};
nacelleBetaAxes = uiaxes(nacellePlotGrid);
title(nacelleBetaAxes,'短舱角响应');
xlabel(nacelleBetaAxes,'Time (s)');
ylabel(nacelleBetaAxes,'betaM (deg)');
grid(nacelleBetaAxes,'on');
nacelleRateAxes = uiaxes(nacellePlotGrid);
title(nacelleRateAxes,'短舱角速度');
xlabel(nacelleRateAxes,'Time (s)');
ylabel(nacelleRateAxes,'deg/s');
grid(nacelleRateAxes,'on');
nacelleSummaryTable = uitable(nacellePlotGrid, ...
    'ColumnName',{'指标','数值'},'RowName',{});

set_status('已载入名义概念参数，请先检查参数或运行配平。','warning');

    function onParameterEdited(~, event)
        row = event.Indices(1);
        newValue = event.NewData;
        if ischar(newValue) || isstring(newValue)
            newValue = str2double(newValue);
        end
        try
            candidate = set_parameter_value(P, parameterRows(row).key, newValue);
            validation = validate_parameter_set(candidate);
            if ~validation.valid
                error('launch_tiltrotor_app:InvalidParameterEdit', '%s', ...
                    strjoin(validation.errors,newline));
            end
            P = candidate;
            invalidate_analysis('参数已修改，旧计算结果已失效。');
            refresh_parameter_table();
        catch ME
            refresh_parameter_table();
            uialert(fig,ME.message,'参数修改无效');
        end
    end

    function onValidateParameters(~,~)
        validation = validate_parameter_set(P);
        if validation.valid
            message = validation.summary;
            if ~isempty(validation.warnings)
                message = sprintf('%s\n%s',message,strjoin(validation.warnings,newline));
                set_status(message,'warning');
            else
                set_status(message,'success');
            end
            uialert(fig,message,'参数检查');
        else
            message = sprintf('%s\n%s',validation.summary, ...
                strjoin(validation.errors,newline));
            set_status(message,'error');
            uialert(fig,message,'参数检查失败');
        end
    end

    function onResetParameters(~,~)
        P = params_nominal();
        refresh_parameter_table();
        invalidate_analysis('已恢复名义参数，旧计算结果已失效。');
    end

    function onRunTrim(~,~)
        set_busy(true);
        cleanup = onCleanup(@() set_busy(false));
        try
            trimResult = [];
            clear_trim_dependent_results();
            trimStateTable.Data = {};
            trimControlTable.Data = {};
            trimResidualTable.Data = {};
            trimStatusLabel.Text = '正在运行配平...';
            config = struct( ...
                'V',trimVField.Value, ...
                'betaMDeg',trimBetaField.Value, ...
                'gammaDeg',trimGammaField.Value, ...
                'initialThetaDeg',trimTheta0Field.Value, ...
                'initialCollectiveDeg',trimCollective0Field.Value, ...
                'initialCyclicLongDeg',trimCyclic0Field.Value, ...
                'thetaLimitDeg',trimThetaLimitField.Value, ...
                'useMultiStart',logical(trimMultiStartCheck.Value), ...
                'alwaysMultiStart',logical(trimAlwaysMultiCheck.Value));
            trimResult = run_trim_case(config,P);
            linearResult = [];
            responseResult = [];
            update_trim_tables();
            if trimResult.success
                trimStatusLabel.Text = sprintf('配平收敛：残差范数 %.3e', ...
                    trimResult.report.residualNorm);
                runLinearButton.Enable = 'on';
                runResponseButton.Enable = 'off';
                linearStatusLabel.Text = '配平点已就绪，可运行线性化';
                set_status('配平完成，可以继续线性化。','success');
            else
                trimStatusLabel.Text = sprintf('配平未通过：残差范数 %.3e', ...
                    trimResult.report.residualNorm);
                runLinearButton.Enable = 'off';
                runResponseButton.Enable = 'off';
                set_status('配平未满足收敛、限幅或有限性条件。','error');
            end
        catch ME
            set_status(ME.message,'error');
            uialert(fig,ME.message,'配平失败');
        end
    end

    function onRunLinearization(~,~)
        set_busy(true);
        cleanup = onCleanup(@() set_busy(false));
        try
            linearResult = run_linearization_case(trimResult,P);
            responseResult = [];
            update_linearization_views();
            runResponseButton.Enable = 'on';
            if linearResult.hasUnstableMode
                linearStatusLabel.Text = '线性化完成：存在右半平面特征值';
                set_status('线性化完成，当前配平点存在不稳定模态。','warning');
            else
                linearStatusLabel.Text = '线性化完成：未发现右半平面特征值';
                set_status('线性化与模态计算完成。','success');
            end
        catch ME
            set_status(ME.message,'error');
            uialert(fig,ME.message,'线性化失败');
        end
    end

    function onRunResponse(~,~)
        set_busy(true);
        cleanup = onCleanup(@() set_busy(false));
        try
            config = struct( ...
                'controlChannel',find(strcmp(controlNames,responseControlDrop.Value),1), ...
                'waveform',responseWaveformDrop.Value, ...
                'amplitudeDeg',responseAmplitudeField.Value, ...
                'startTime',responseStartField.Value, ...
                'duration',responseDurationField.Value, ...
                'frequencyHz',responseFrequencyField.Value, ...
                'totalTime',responseTotalTimeField.Value, ...
                'timeStep',responseStepField.Value, ...
                'outputState',find(strcmp(stateNames,responseStateDrop.Value),1));
            responseResult = simulate_linear_response(linearResult,config,P);
            stateNames = responseResult.stateNames(:).';
            update_response_views();
            if responseResult.limitWarning
                set_status('响应完成；实际操纵历史触及或越过当前限幅。','warning');
            else
                set_status('线性小扰动响应计算完成。','success');
            end
        catch ME
            set_status(ME.message,'error');
            uialert(fig,ME.message,'响应计算失败');
        end
    end

    function onRunNacelleResponse(~,~)
        set_busy(true);
        cleanup = onCleanup(@() set_busy(false));
        try
            config = struct( ...
                'enableNacelleDynamics',logical(nacelleEnableCheck.Value), ...
                'V',nacelleVField.Value, ...
                'initialBetaDeg',nacelleInitialBetaField.Value, ...
                'commandBetaDeg',nacelleCommandBetaField.Value, ...
                'rateLimitDegPerSec',nacelleRateLimitField.Value, ...
                'omega',nacelleOmegaField.Value, ...
                'zeta',nacelleZetaField.Value, ...
                'duration',nacelleDurationField.Value, ...
                'timeStep',nacelleStepField.Value);
            nacelleResponseResult = run_nacelle_dynamics_response_case(config,P);
            update_nacelle_response_views();
            if nacelleResponseResult.enabled
                nacelleStatusLabel.Text = sprintf( ...
                    '实验响应完成：状态维度 %d，实际速率限幅 %d', ...
                    nacelleResponseResult.stateDimension, ...
                    nacelleResponseResult.rateLimited);
            else
                nacelleStatusLabel.Text = sprintf( ...
                    '已按默认关闭路径运行：状态维度 %d', ...
                    nacelleResponseResult.stateDimension);
            end
            set_status('短舱动态实验响应计算完成。','success');
        catch ME
            set_status(ME.message,'error');
            uialert(fig,ME.message,'短舱动态响应失败');
        end
    end

    function onResponseDisplayChanged(~,~)
        if ~isempty(responseResult)
            update_response_views();
        end
    end

    function onExportSession(~,~)
        [fileName,pathName] = uiputfile('*.mat','导出分析工况', ...
            'tiltrotor_analysis_case.mat');
        if isequal(fileName,0)
            return;
        end
        session = struct();
        session.appName = 'Tiltrotor Analysis Workbench';
        session.parameters = P;
        session.trim = trimResult;
        session.linearization = linearResult;
        session.response = responseResult;
        session.nacelleDynamics = nacelleResponseResult;
        try
            save_analysis_case(fullfile(pathName,fileName),session);
            set_status(sprintf('已导出：%s',fullfile(pathName,fileName)),'success');
        catch ME
            uialert(fig,ME.message,'导出失败');
        end
    end

    function onShowHelp(~,~)
        uialert(fig,sprintf([ ...
            '推荐顺序：\n1. 检查或修改关键参数；\n2. 运行配平；\n' ...
            '3. 在收敛配平点运行线性化；\n4. 设置小幅操纵输入并计算响应。\n\n' ...
            '响应结果属于配平点附近的小扰动结果。界面不会修改 params_nominal.m。\n' ...
            '短舱动态页为实验入口，默认关闭。']), ...
            '使用说明');
    end

    function refresh_parameter_table()
        parameterTable.Data = parameter_table_data(P,parameterRows);
    end

    function update_trim_tables()
        stateNames = trimResult.stateNames(:).';
        responseStateDrop.Items = stateNames;
        if ~any(strcmp(stateNames, responseStateDrop.Value))
            responseStateDrop.Value = stateNames{min(8, numel(stateNames))};
        end
        trimStateTable.Data = make_state_display(trimResult.xTrim,stateNames);
        trimControlTable.Data = make_control_display(trimResult.uTrim,controlNames);
        residual = trimResult.report.residual(:);
        residualLabels = trimResult.report.residualLabels(:);
        residualUnits = trimResult.report.residualScaleUnits(:);
        loadLabels = {'Fx total';'Fy total';'Fz total';'Mx total';'My total';'Mz total'};
        loadValues = [trimResult.loads.Ftotal(:);trimResult.loads.Mtotal(:)];
        loadUnits = {'N';'N';'N';'N m';'N m';'N m'};
        labels = [residualLabels;loadLabels];
        values = [num2cell(residual);num2cell(loadValues)];
        units = [residualUnits;loadUnits];
        trimResidualTable.Data = [labels values units];
    end

    function update_linearization_views()
        stateNames = linearResult.stateNames(:).';
        aTable.ColumnName = stateNames;
        aTable.RowName = stateNames;
        bTable.RowName = stateNames;
        responseStateDrop.Items = stateNames;
        if ~any(strcmp(stateNames, responseStateDrop.Value))
            responseStateDrop.Value = stateNames{min(8, numel(stateNames))};
        end
        aTable.Data = linearResult.A;
        bTable.Data = linearResult.B;
        lambda = linearResult.eigenvalues;
        eigenTable.Data = [num2cell(real(lambda)) num2cell(imag(lambda)) ...
            num2cell(linearResult.naturalFrequency) ...
            num2cell(linearResult.dampingRatio) ...
            num2cell(linearResult.timeScale) linearResult.classification];
        cla(eigenAxes);
        plot(eigenAxes,real(lambda),imag(lambda),'o','LineWidth',1.4);
        hold(eigenAxes,'on');
        xline(eigenAxes,0,'--');
        hold(eigenAxes,'off');
        grid(eigenAxes,'on');
        title(eigenAxes,'特征值复平面');
    end

    function update_nacelle_response_views()
        t = nacelleResponseResult.time;
        plot(nacelleBetaAxes,t,nacelleResponseResult.betaMDeg,'LineWidth',1.3);
        hold(nacelleBetaAxes,'on');
        plot(nacelleBetaAxes,t,nacelleResponseResult.betaMCommandDeg, ...
            '--','LineWidth',1.1);
        hold(nacelleBetaAxes,'off');
        grid(nacelleBetaAxes,'on');
        title(nacelleBetaAxes,'短舱角响应');
        ylabel(nacelleBetaAxes,'betaM (deg)');
        legend(nacelleBetaAxes,{'状态','目标'},'Location','best');

        plot(nacelleRateAxes,t,nacelleResponseResult.betaMDotDegPerSec, ...
            'LineWidth',1.3);
        hold(nacelleRateAxes,'on');
        plot(nacelleRateAxes,t,nacelleResponseResult.qDegPerSec, ...
            'LineWidth',1.0);
        hold(nacelleRateAxes,'off');
        grid(nacelleRateAxes,'on');
        title(nacelleRateAxes,'短舱角速度与俯仰角速度');
        ylabel(nacelleRateAxes,'deg/s');
        legend(nacelleRateAxes,{'d betaM/dt','q'},'Location','best');

        summary = { ...
            '启用短舱动态状态',logical(nacelleResponseResult.enabled); ...
            '状态维度',nacelleResponseResult.stateDimension; ...
            '末端 betaM (deg)',nacelleResponseResult.betaMDeg(end); ...
            '最大 |d betaM/dt| (deg/s)', ...
                max(abs(nacelleResponseResult.betaMDotDegPerSec)); ...
            '末端 theta (deg)',nacelleResponseResult.thetaDeg(end); ...
            '末端 u (m/s)',nacelleResponseResult.u(end); ...
            '末端 w (m/s)',nacelleResponseResult.w(end)};
        nacelleSummaryTable.Data = summary;
    end

    function update_response_views()
        selectedState = find(strcmp(stateNames,responseStateDrop.Value),1);
        selectedControl = responseResult.config.controlChannel;
        t = responseResult.time;
        inputDeg = responseResult.deltaControl(:,selectedControl)*180/pi;
        if responseActualCheck.Value
            rawOutput = responseResult.actualState(:,selectedState);
            prefix = '实际';
        else
            rawOutput = responseResult.deltaState(:,selectedState);
            prefix = '扰动';
        end
        [displayOutput,displayUnit] = convert_state_for_display(rawOutput,selectedState);
        plot(responseInputAxes,t,inputDeg,'LineWidth',1.3);
        grid(responseInputAxes,'on');
        title(responseInputAxes,sprintf('%s 输入扰动',controlNames{selectedControl}));
        ylabel(responseInputAxes,'deg');
        plot(responseOutputAxes,t,displayOutput,'LineWidth',1.3);
        grid(responseOutputAxes,'on');
        title(responseOutputAxes,sprintf('%s %s响应',prefix,stateNames{selectedState}));
        ylabel(responseOutputAxes,displayUnit);
        [peakValue,peakIndex] = max(abs(displayOutput));
        summary = { ...
            '最大绝对值',peakValue; ...
            '峰值时刻 (s)',t(peakIndex); ...
            '末值',displayOutput(end); ...
            '操纵限幅警告',logical(responseResult.limitWarning)};
        responseSummaryTable.Data = summary;
    end

    function invalidate_analysis(message)
        trimResult = [];
        clear_trim_dependent_results();
        trimStateTable.Data = {};
        trimControlTable.Data = {};
        trimResidualTable.Data = {};
        trimStatusLabel.Text = '参数已变化，需要重新配平';
        set_status(message,'warning');
    end

    function clear_trim_dependent_results()
        linearResult = [];
        responseResult = [];
        runLinearButton.Enable = 'off';
        runResponseButton.Enable = 'off';
        linearStatusLabel.Text = '需要先获得新的收敛配平点';
        aTable.Data = [];
        bTable.Data = [];
        eigenTable.Data = {};
        responseSummaryTable.Data = {};
        nacelleResponseResult = [];
        nacelleStatusLabel.Text = '参数已变化，实验响应结果已失效';
        cla(eigenAxes);
        cla(responseInputAxes);
        cla(responseOutputAxes);
        cla(nacelleBetaAxes);
        cla(nacelleRateAxes);
        nacelleSummaryTable.Data = {};
    end

    function set_status(message,kind)
        statusLabel.Text = message;
        switch kind
            case 'success'
                statusLamp.Color = [0.20 0.68 0.32];
            case 'error'
                statusLamp.Color = [0.82 0.22 0.20];
            otherwise
                statusLamp.Color = [0.93 0.69 0.13];
        end
    end

    function set_busy(isBusy)
        if isBusy
            fig.Pointer = 'watch';
            runTrimButton.Enable = 'off';
            runLinearButton.Enable = 'off';
            runResponseButton.Enable = 'off';
            runNacelleButton.Enable = 'off';
            drawnow;
        else
            if isvalid(fig)
                fig.Pointer = 'arrow';
                runTrimButton.Enable = 'on';
                if ~isempty(trimResult) && trimResult.success
                    runLinearButton.Enable = 'on';
                end
                if ~isempty(linearResult) && linearResult.success
                    runResponseButton.Enable = 'on';
                end
                runNacelleButton.Enable = 'on';
                drawnow;
            end
        end
    end
end

function grid = make_fill_grid(parent)
grid = uigridlayout(parent,[1 1]);
grid.RowHeight = {'1x'};
grid.ColumnWidth = {'1x'};
grid.Padding = [0 0 0 0];
grid.RowSpacing = 0;
grid.ColumnSpacing = 0;
end

function rows = make_parameter_rows()
raw = { ...
    '环境','空气密度','env.rho','kg/m^3','ASSUMED_CONCEPT'; ...
    '环境','重力加速度','env.g','m/s^2','REFERENCE_CONSTANT'; ...
    '质量惯量','总质量','mass.m','kg','ASSUMED_CONCEPT'; ...
    '质量惯量','倾转组件总质量','mass.mNac','kg','ASSUMED_CONCEPT'; ...
    '质量惯量','Ixx','mass.Ixx','kg m^2','ASSUMED_CONCEPT'; ...
    '质量惯量','Iyy','mass.Iyy','kg m^2','ASSUMED_CONCEPT'; ...
    '质量惯量','Izz','mass.Izz','kg m^2','ASSUMED_CONCEPT'; ...
    '质量惯量','Ixz','mass.Ixz','kg m^2','ASSUMED_CONCEPT'; ...
    '旋翼','旋翼半径','rotor.R','m','ASSUMED_CONCEPT'; ...
    '旋翼','旋翼角速度','rotor.Omega','rad/s','ASSUMED_CONCEPT'; ...
    '旋翼','桨叶弦长','rotor.chord','m','ASSUMED_CONCEPT'; ...
    '旋翼','径向离散数','rotor.nRadial','-','NUMERICAL'; ...
    '旋翼','方位离散数','rotor.nAzimuth','-','NUMERICAL'; ...
    '机翼','机翼面积','wing.S','m^2','ASSUMED_CONCEPT'; ...
    '机翼','翼展','wing.b','m','ASSUMED_CONCEPT'; ...
    '机翼','平均弦长','wing.c','m','ASSUMED_CONCEPT'; ...
    '配平','残差容限','trim.residualTolerance','mixed','NUMERICAL'; ...
    '配平','最大迭代数','trim.maxIterations','-','NUMERICAL'; ...
    '线性化','控制差分步长','linear.du','rad','NUMERICAL'};
rows = repmat(struct('group','','name','','key','','unit','','source',''),size(raw,1),1);
for k = 1:size(raw,1)
    rows(k).group = raw{k,1};
    rows(k).name = raw{k,2};
    rows(k).key = raw{k,3};
    rows(k).unit = raw{k,4};
    rows(k).source = raw{k,5};
end
end

function data = parameter_table_data(P,rows)
data = cell(numel(rows),6);
for k = 1:numel(rows)
    data{k,1} = rows(k).group;
    data{k,2} = rows(k).name;
    data{k,3} = rows(k).key;
    data{k,4} = get_parameter_value(P,rows(k).key);
    data{k,5} = rows(k).unit;
    data{k,6} = rows(k).source;
end
end

function value = get_parameter_value(P,key)
switch key
    case 'env.rho', value = P.env.rho;
    case 'env.g', value = P.env.g;
    case 'mass.m', value = P.mass.m;
    case 'mass.mNac', value = P.mass.mNac;
    case 'mass.Ixx', value = P.mass.I0(1,1);
    case 'mass.Iyy', value = P.mass.I0(2,2);
    case 'mass.Izz', value = P.mass.I0(3,3);
    case 'mass.Ixz', value = P.mass.I0(1,3);
    case 'rotor.R', value = P.rotor.R;
    case 'rotor.Omega', value = P.rotor.Omega;
    case 'rotor.chord', value = P.rotor.chord;
    case 'rotor.nRadial', value = P.rotor.nRadial;
    case 'rotor.nAzimuth', value = P.rotor.nAzimuth;
    case 'wing.S', value = P.wing.S;
    case 'wing.b', value = P.wing.b;
    case 'wing.c', value = P.wing.c;
    case 'trim.residualTolerance', value = P.trim.residualTolerance;
    case 'trim.maxIterations', value = P.trim.maxIterations;
    case 'linear.du', value = P.linear.du(1);
    otherwise, error('Unknown parameter key %s.',key);
end
end

function P = set_parameter_value(P,key,value)
if ~(isnumeric(value) && isreal(value) && isscalar(value) && isfinite(value))
    error('Parameter value must be a finite real scalar.');
end
switch key
    case 'env.rho', P.env.rho = value;
    case 'env.g', P.env.g = value;
    case 'mass.m', P.mass.m = value;
    case 'mass.mNac', P.mass.mNac = value;
    case 'mass.Ixx', P.mass.I0(1,1) = value;
    case 'mass.Iyy', P.mass.I0(2,2) = value;
    case 'mass.Izz', P.mass.I0(3,3) = value;
    case 'mass.Ixz'
        P.mass.I0(1,3) = value;
        P.mass.I0(3,1) = value;
    case 'rotor.R'
        P.rotor.R = value;
        P.rotor.Ib = P.rotor.bladeMass*P.rotor.R^2/3;
        P.rotor.Sblade = P.rotor.bladeMass*P.rotor.R/2;
    case 'rotor.Omega', P.rotor.Omega = value;
    case 'rotor.chord', P.rotor.chord = value;
    case 'rotor.nRadial', P.rotor.nRadial = value;
    case 'rotor.nAzimuth', P.rotor.nAzimuth = value;
    case 'wing.S', P.wing.S = value;
    case 'wing.b', P.wing.b = value;
    case 'wing.c', P.wing.c = value;
    case 'trim.residualTolerance', P.trim.residualTolerance = value;
    case 'trim.maxIterations', P.trim.maxIterations = value;
    case 'linear.du', P.linear.du = value*ones(7,1);
    otherwise, error('Unknown parameter key %s.',key);
end
end

function data = make_state_display(x,stateNames)
nState = numel(x);
data = cell(nState,3);
for k = 1:nState
    data{k,1} = stateNames{k};
    if k <= 3
        data{k,2} = x(k);
        data{k,3} = 'm/s';
    elseif k <= 6 || strcmp(stateNames{k}, 'betaM_dot')
        data{k,2} = x(k)*180/pi;
        data{k,3} = 'deg/s';
    else
        data{k,2} = x(k)*180/pi;
        data{k,3} = 'deg';
    end
end
end

function data = make_control_display(u,controlNames)
data = cell(7,3);
for k = 1:7
    data{k,1} = controlNames{k};
    data{k,2} = u(k)*180/pi;
    data{k,3} = 'deg';
end
end

function [displayValue,unit] = convert_state_for_display(rawValue,index)
if index <= 3
    displayValue = rawValue;
    unit = 'm/s';
elseif index <= 6
    displayValue = rawValue*180/pi;
    unit = 'deg/s';
elseif index == 11
    displayValue = rawValue*180/pi;
    unit = 'deg/s';
else
    displayValue = rawValue*180/pi;
    unit = 'deg';
end
end
