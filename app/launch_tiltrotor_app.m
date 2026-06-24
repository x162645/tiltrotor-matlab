function fig = launch_tiltrotor_app()
%LAUNCH_TILTROTOR_APP Open the tiltrotor trim and linear-response workbench.
% The application is implemented as text-based MATLAB code for version
% control and R2021a compatibility. Model equations remain in model/analysis.

currentP = params_nominal();
baselineP = currentP;
parameterCatalog = build_parameter_catalog();
modifiedIds = cell(0,1);
pendingEdits = struct();
pendingErrors = struct();
parameterVisibleCatalog = parameterCatalog;
selectedParameterId = '';
lastParameterError = '';
workflowStatus = struct('parameters','未检查', 'trim','未运行', ...
    'linear','未运行', 'response','未运行');
sessionDirty = false;
analysisDirty = false;
trimResult = [];
linearResult = [];
responseResult = [];
stateDisplayNames = {'纵向速度 u','侧向速度 v','垂向速度 w', ...
    '滚转角速度 p','俯仰角速度 q','偏航角速度 r', ...
    '滚转角 \phi','俯仰角 \theta','航向角 \psi'};
controlDisplayNames = {'总距','左右差动总距','纵向周期变距', ...
    '左右差动周期变距','副翼','升降舵','方向舵'};
waveformCodes = {'step','pulse','sine','doublet'};
waveformDisplayNames = {'阶跃','脉冲','正弦','双脉冲'};

fig = uifigure('Name','Tiltrotor Analysis Workbench', ...
    'Position',[80 60 1420 860], ...
    'CloseRequestFcn',@onCloseRequested);
root = uigridlayout(fig,[2 1]);
root.RowHeight = {54,'1x'};
root.Padding = [10 8 10 10];
root.RowSpacing = 8;

header = uigridlayout(root,[1 9]);
header.Layout.Row = 1;
header.ColumnWidth = {270,22,'1x',100,100,100,100,100,100};
header.ColumnSpacing = 8;

uilabel(header,'Text','倾转旋翼机分析工作台', ...
    'FontSize',20,'FontWeight','bold');
statusLamp = uilamp(header,'Color',[0.93 0.69 0.13]);
statusLabel = uilabel(header,'Text','已载入名义概念参数');
uibutton(header,'Text','加载项目', ...
    'ButtonPushedFcn',@onLoadSession);
uibutton(header,'Text','保存项目', ...
    'ButtonPushedFcn',@onSaveSession);
uibutton(header,'Text','检查参数', ...
    'ButtonPushedFcn',@onValidateParameters);
uibutton(header,'Text','恢复参数', ...
    'ButtonPushedFcn',@onResetParameters);
uibutton(header,'Text','使用说明', ...
    'ButtonPushedFcn',@onShowHelp);

mainTabs = uitabgroup(root);
mainTabs.Layout.Row = 2;
parameterTab = uitab(mainTabs,'Title','参数设置');
trimTab = uitab(mainTabs,'Title','配平');
linearTab = uitab(mainTabs,'Title','线性化与模态');
responseTab = uitab(mainTabs,'Title','操纵响应');

%% Parameter tab
parameterLayout = uigridlayout(parameterTab,[3 1]);
parameterLayout.RowHeight = {42,'1x',88};
parameterLayout.Padding = [8 8 8 8];
parameterFilterGrid = uigridlayout(parameterLayout,[1 9]);
parameterFilterGrid.ColumnWidth = {70,170,70,'1x',110,100,120,120,95};
parameterFilterGrid.ColumnSpacing = 8;
uilabel(parameterFilterGrid,'Text','类别');
categoryFilterDrop = uidropdown(parameterFilterGrid, ...
    'Items',parameter_category_items(parameterCatalog), ...
    'Value','全部类别', ...
    'ValueChangedFcn',@onParameterFilterChanged);
uilabel(parameterFilterGrid,'Text','关键词');
parameterSearchField = uieditfield(parameterFilterGrid,'text', ...
    'Value','', ...
    'ValueChangedFcn',@onParameterFilterChanged);
modifiedOnlyCheck = uicheckbox(parameterFilterGrid, ...
    'Text','仅显示已修改', ...
    'Value',false, ...
    'ValueChangedFcn',@onParameterFilterChanged);
uibutton(parameterFilterGrid,'Text','应用修改', ...
    'ButtonPushedFcn',@onApplyParameterEdits);
uibutton(parameterFilterGrid,'Text','恢复选中参数', ...
    'ButtonPushedFcn',@onRestoreSelectedParameter);
uibutton(parameterFilterGrid,'Text','恢复全部参数', ...
    'ButtonPushedFcn',@onResetParameters);
parameterCountLabel = uilabel(parameterFilterGrid,'Text','');
parameterTable = uitable(parameterLayout, ...
    'ColumnName',{'类别','参数','默认值','当前值','单位','状态','来源'}, ...
    'ColumnEditable',[false false false true false false false], ...
    'ColumnWidth',{135,240,120,120,95,110,170}, ...
    'CellEditCallback',@onParameterEdited, ...
    'CellSelectionCallback',@onParameterSelected);
parameterDescriptionArea = uitextarea(parameterLayout,'Editable','off');
%% Trim tab
trimLayout = uigridlayout(trimTab,[1 2]);
trimLayout.ColumnWidth = {330,'1x'};
trimLayout.Padding = [8 8 8 8];

trimInputPanel = uipanel(trimLayout,'Title','飞行工况与配平计算');
trimInputGrid = uigridlayout(trimInputPanel,[12 2]);
trimInputGrid.RowHeight = repmat({34},1,12);
trimInputGrid.ColumnWidth = {165,'1x'};
trimInputGrid.Padding = [10 10 10 10];

uilabel(trimInputGrid,'Text','空速 V (m/s)');
trimVField = uieditfield(trimInputGrid,'numeric','Value',0,'Limits',[0 Inf]);
trimBetaLabel = uilabel(trimInputGrid,'Text','旋翼向前倾转角 (deg)');
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
uilabel(trimInputGrid,'Text','找到可用解后继续计算其余初值');
trimAlwaysMultiCheck = uicheckbox(trimInputGrid,'Value',false,'Text','');
runTrimButton = uibutton(trimInputGrid,'Text','运行配平', ...
    'FontWeight','bold','ButtonPushedFcn',@onRunTrim);
runTrimButton.Layout.Column = [1 2];
stopTrimButton = uibutton(trimInputGrid,'Text','停止计算', ...
    'Enable','off','ButtonPushedFcn',@onCancelTrim);
stopTrimButton.Layout.Column = [1 2];
trimStatusLabel = uilabel(trimInputGrid,'Text','尚未运行', ...
    'HorizontalAlignment','center');
trimStatusLabel.Layout.Column = [1 2];

trimOutputTabs = uitabgroup(trimLayout);
trimStateTab = uitab(trimOutputTabs,'Title','状态与操纵');
trimControlTab = uitab(trimOutputTabs,'Title','结果总览');
trimResidualTab = uitab(trimOutputTabs,'Title','残差、限幅与载荷');
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
uilabel(linearTop,'Text','线性化点、矩阵单位和差分步长见结果与技术信息', ...
    'HorizontalAlignment','right');

matrixTabs = uitabgroup(linearLayout);
matrixTabs.Layout.Row = 2;
matrixTabs.Layout.Column = 1;
aTab = uitab(matrixTabs,'Title','A 矩阵');
bTab = uitab(matrixTabs,'Title','B 矩阵');
aGrid = make_fill_grid(aTab);
bGrid = make_fill_grid(bTab);
aTable = uitable(aGrid,'ColumnName',stateDisplayNames,'RowName',stateDisplayNames);
bTable = uitable(bGrid,'ColumnName',controlDisplayNames,'RowName',stateDisplayNames);

modePanel = uipanel(linearLayout,'Title','特征值与稳定性');
modePanel.Layout.Row = 2;
modePanel.Layout.Column = 2;
modeGrid = uigridlayout(modePanel,[2 1]);
modeGrid.RowHeight = {'1x','1x'};
eigenAxes = uiaxes(modeGrid);
title(eigenAxes,'特征值复平面');
xlabel(eigenAxes,'实部 (1/s)');
ylabel(eigenAxes,'虚部 (rad/s)');
grid(eigenAxes,'on');
eigenTable = uitable(modeGrid, ...
    'ColumnName',{'实部','虚部','固有频率 \omega_n','阻尼比 \zeta','时间尺度(s)','分类'});

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
responseControlDrop = uidropdown(responseInputGrid,'Items',controlDisplayNames, ...
    'Value','纵向周期变距');
uilabel(responseInputGrid,'Text','输入波形');
responseWaveformDrop = uidropdown(responseInputGrid, ...
    'Items',waveformDisplayNames,'Value','阶跃', ...
    'ValueChangedFcn',@onResponseWaveformChanged);
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
responseStateDrop = uidropdown(responseInputGrid,'Items',stateDisplayNames, ...
    'Value','俯仰角 \theta','ValueChangedFcn',@onResponseDisplayChanged);
uilabel(responseInputGrid,'Text','叠加配平值显示');
responseActualCheck = uicheckbox(responseInputGrid,'Value',false,'Text','', ...
    'ValueChangedFcn',@onResponseDisplayChanged);
runResponseButton = uibutton(responseInputGrid,'Text','运行线性响应', ...
    'Enable','off','FontWeight','bold', ...
    'ButtonPushedFcn',@onRunResponse);
runResponseButton.Layout.Column = [1 2];
responseSummaryTable = uitable(responseInputGrid, ...
    'ColumnName',{'指标','数值','单位'},'RowName',{});
responseSummaryTable.Layout.Column = [1 2];

responsePlotGrid = uigridlayout(responseLayout,[2 1]);
responsePlotGrid.RowHeight = {'1x','1x'};
responseInputAxes = uiaxes(responsePlotGrid);
title(responseInputAxes,'操纵输入扰动');
xlabel(responseInputAxes,'时间 (s)');
ylabel(responseInputAxes,'操纵输入 (deg)');
grid(responseInputAxes,'on');
responseOutputAxes = uiaxes(responsePlotGrid);
title(responseOutputAxes,'状态响应');
xlabel(responseOutputAxes,'时间 (s)');
grid(responseOutputAxes,'on');

update_response_waveform_inputs();
refresh_parameter_table();
set_status('已载入名义概念参数，请先检查参数或运行配平。','warning');

    function onParameterEdited(~, event)
        row = event.Indices(1);
        if row < 1 || row > numel(parameterVisibleCatalog)
            refresh_parameter_table();
            return;
        end
        newValue = event.NewData;
        if ischar(newValue) || isstring(newValue)
            newValue = str2double(newValue);
        end
        item = parameterVisibleCatalog(row);
        selectedParameterId = item.id;
        [ok,message] = validate_single_display_value(item, newValue);
        key = key_from_id(item.id);
        pendingEdits.(key) = newValue;
        if ok
            pendingErrors = remove_struct_field(pendingErrors, key);
            workflowStatus.parameters = '有待应用修改';
            set_status('参数修改已暂存，点击“应用修改”后执行整组校验。','warning');
        else
            pendingErrors.(key) = message;
            workflowStatus.parameters = '输入有误';
            lastParameterError = message;
            set_status(message,'error');
        end
        sessionDirty = true;
        refresh_parameter_table();
    end

    function onApplyParameterEdits(~,~)
        ids = pending_ids();
        if isempty(ids)
            set_status('没有待应用的参数修改。','warning');
            return;
        end
        if ~isempty(fieldnames(pendingErrors))
            message = first_pending_error();
            lastParameterError = message;
            set_status(message,'error');
            uialert(fig,message,'参数输入有误');
            refresh_parameter_table();
            return;
        end
        candidate = currentP;
        for i = 1:numel(parameterCatalog)
            item = parameterCatalog(i);
            key = key_from_id(item.id);
            if isfield(pendingEdits, key)
                [candidate, result] = set_parameter_catalog_value( ...
                    candidate, item, pendingEdits.(key));
                if ~result.success
                    lastParameterError = result.message;
                    set_status(result.message,'error');
                    uialert(fig,result.message,'参数应用失败');
                    refresh_parameter_table();
                    return;
                end
            end
        end
        validation = validate_parameter_set(candidate);
        if ~validation.valid
            message = sprintf('%s\n%s',validation.summary, ...
                strjoin(validation.errors,newline));
            lastParameterError = message;
            set_status(message,'error');
            uialert(fig,message,'参数应用失败');
            refresh_parameter_table();
            return;
        end
        currentP = candidate;
        pendingEdits = struct();
        pendingErrors = struct();
        modifiedIds = get_modified_parameter_ids(currentP, baselineP, parameterCatalog);
        workflowStatus.parameters = '已应用';
        sessionDirty = true;
        invalidate_analysis('参数已应用，后续配平、线性化和响应结果已失效。');
        refresh_parameter_table();
    end

    function onRestoreSelectedParameter(~,~)
        if isempty(selectedParameterId) && ~isempty(parameterVisibleCatalog)
            selectedParameterId = parameterVisibleCatalog(1).id;
        end
        if isempty(selectedParameterId)
            return;
        end
        idx = find(strcmp({parameterCatalog.id}, selectedParameterId), 1);
        if isempty(idx)
            return;
        end
        item = parameterCatalog(idx);
        key = key_from_id(item.id);
        pendingEdits = remove_struct_field(pendingEdits, key);
        pendingErrors = remove_struct_field(pendingErrors, key);
        defaultValue = get_parameter_catalog_value(baselineP, item);
        [candidate,result] = set_parameter_catalog_value(currentP, item, defaultValue);
        if result.success
            currentP = candidate;
            modifiedIds = get_modified_parameter_ids(currentP, baselineP, parameterCatalog);
            workflowStatus.parameters = '已恢复选中参数';
            sessionDirty = true;
            invalidate_analysis('选中参数已恢复，后续结果已失效。');
        else
            lastParameterError = result.message;
            set_status(result.message,'error');
        end
        refresh_parameter_table();
    end

    function onParameterFilterChanged(~,~)
        apply_parameter_filters();
    end

    function onParameterSelected(~, event)
        if isempty(event.Indices)
            return;
        end
        row = event.Indices(1);
        if row >= 1 && row <= numel(parameterVisibleCatalog)
            selectedParameterId = parameterVisibleCatalog(row).id;
            update_parameter_description(row);
        end
    end

    function onValidateParameters(~,~)
        if ~isempty(fieldnames(pendingErrors))
            message = first_pending_error();
            set_status(message,'error');
            uialert(fig,message,'参数输入有误');
            return;
        end
        validation = validate_parameter_set(currentP);
        if validation.valid
            workflowStatus.parameters = '已检查';
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
        currentP = baselineP;
        pendingEdits = struct();
        pendingErrors = struct();
        modifiedIds = cell(0,1);
        workflowStatus.parameters = '已恢复';
        sessionDirty = true;
        apply_parameter_filters();
        invalidate_analysis('已恢复全部参数，后续结果已失效。');
    end
    function onRunTrim(~,~)
        set_busy(true);
        stopTrimButton.Enable = 'on';
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
            trimResult = run_trim_case(config,currentP);
            linearResult = [];
            responseResult = [];
            update_trim_tables();
            if trimResult.success
                trimStatusLabel.Text = sprintf('配平收敛：残差范数 %.3e', ...
                    trimResult.report.residualNorm);
                workflowStatus.trim = '可接受';
                workflowStatus.linear = '未运行';
                workflowStatus.response = '未运行';
                analysisDirty = true;
                runLinearButton.Enable = 'on';
                runResponseButton.Enable = 'off';
                linearStatusLabel.Text = '配平点已就绪，可运行线性化';
                set_status('配平成功：残差满足要求，操纵量未越限，可以继续线性化。','success');
            else
                trimStatusLabel.Text = sprintf('配平未通过：残差范数 %.3e', ...
                    trimResult.report.residualNorm);
                workflowStatus.trim = '失败';
                workflowStatus.linear = '无效';
                workflowStatus.response = '无效';
                runLinearButton.Enable = 'off';
                runResponseButton.Enable = 'off';
                set_status('配平失败：残差、限幅或有限性条件未满足，请检查工况、初值和操纵范围。','error');
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
            linearResult = run_linearization_case(trimResult,currentP);
            responseResult = [];
            update_linearization_views();
            runResponseButton.Enable = 'on';
            workflowStatus.linear = '已运行';
            workflowStatus.response = '未运行';
            analysisDirty = true;
            if linearResult.hasUnstableMode
                linearStatusLabel.Text = '线性化完成：存在不稳定或需复核模态';
                set_status('线性化与模态计算完成：当前配平点存在不稳定或需复核模态。','warning');
            else
                linearStatusLabel.Text = '线性化完成：未发现正实部特征值';
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
                'controlChannel',find(strcmp(controlDisplayNames,responseControlDrop.Value),1), ...
                'waveform',waveformCodes{find(strcmp(waveformDisplayNames,responseWaveformDrop.Value),1)}, ...
                'amplitudeDeg',responseAmplitudeField.Value, ...
                'startTime',responseStartField.Value, ...
                'duration',responseDurationField.Value, ...
                'frequencyHz',responseFrequencyField.Value, ...
                'totalTime',responseTotalTimeField.Value, ...
                'timeStep',responseStepField.Value, ...
                'outputState',find(strcmp(stateDisplayNames,responseStateDrop.Value),1));
            responseResult = simulate_linear_response(linearResult,config,currentP);
            update_response_views();
            workflowStatus.response = '已运行';
            analysisDirty = true;
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

    function onResponseDisplayChanged(~,~)
        if ~isempty(responseResult)
            update_response_views();
        end
    end

    function onCancelTrim(~,~)
        set_status('当前配平求解为同步调用，无法在不破坏求解器状态的情况下安全中断；本次计算将继续到当前候选结束。','warning');
    end

    function onResponseWaveformChanged(~,~)
        update_response_waveform_inputs();
    end

    function onSaveSession(~,~)
        [fileName,pathName] = uiputfile('*.mat','保存项目', ...
            'tiltrotor_analysis_case.mat');
        if isequal(fileName,0)
            return;
        end
        session = make_session();
        try
            save_analysis_case(fullfile(pathName,fileName),session);
            sessionDirty = false;
            analysisDirty = false;
            set_status(sprintf('项目已保存：%s',fullfile(pathName,fileName)),'success');
        catch ME
            uialert(fig,ME.message,'保存失败');
        end
    end

    function onLoadSession(~,~)
        [fileName,pathName] = uigetfile('*.mat','加载项目');
        if isequal(fileName,0)
            return;
        end
        try
            session = load_analysis_case(fullfile(pathName,fileName));
            restore_session(session);
            set_status(sprintf('项目已加载：%s',fullfile(pathName,fileName)),'success');
        catch ME
            uialert(fig,ME.message,'加载失败');
        end
    end

    function onShowHelp(~,~)
        uialert(fig,sprintf([ ...
            '推荐顺序：\n1. 在参数设置页暂存并应用参数修改；\n2. 运行配平；\n' ...
            '3. 在可接受配平点运行线性化；\n4. 设置小幅操纵输入并计算响应。\n\n' ...
            '坐标约定沿用代码：机体系 x 向前、y 向右、z 向下。旋翼向前倾转角在界面以度输入，内部以 rad 计算。' ...
            '\n0°：直升机模式；90°：固定翼模式。' ...
            '\n传统短舱角 = 90° - 程序倾转角。' ...
            '\n总距、左右差动总距、纵向周期变距和左右差动周期变距均以度显示。' ...
            '\n保存项目会保存当前参数以及已有配平、线性化和响应结果。界面不会修改 params_nominal.m。']), ...
            '使用说明');
    end

    function session = make_session()
        session = struct();
        session.appName = 'Tiltrotor Analysis Workbench';
        session.parameters = currentP;
        session.baselineParameters = baselineP;
        session.pendingEdits = pendingEdits;
        session.trim = trimResult;
        session.linearization = linearResult;
        session.response = responseResult;
        session.workflowStatus = workflowStatus;
    end

    function restore_session(session)
        required = {'parameters','trim','linearization','response'};
        for ir = 1:numel(required)
            if ~isfield(session, required{ir})
                error('launch_tiltrotor_app:InvalidSession', ...
                    '项目文件缺少必要字段：%s。', required{ir});
            end
        end
        currentP = session.parameters;
        if isfield(session,'baselineParameters')
            baselineP = session.baselineParameters;
        else
            baselineP = params_nominal();
        end
        pendingEdits = struct();
        pendingErrors = struct();
        if isfield(session,'pendingEdits')
            pendingEdits = session.pendingEdits;
        end
        trimResult = session.trim;
        linearResult = session.linearization;
        responseResult = session.response;
        modifiedIds = get_modified_parameter_ids(currentP, baselineP, parameterCatalog);
        if isfield(session,'workflowStatus')
            workflowStatus = session.workflowStatus;
        else
            workflowStatus.parameters = '已加载';
            workflowStatus.trim = result_status(trimResult);
            workflowStatus.linear = result_status(linearResult);
            workflowStatus.response = result_status(responseResult);
        end
        sessionDirty = false;
        analysisDirty = false;
        apply_parameter_filters();
        update_trim_outputs_after_load();
        update_linear_outputs_after_load();
        update_response_outputs_after_load();
    end

    function onCloseRequested(~,~)
        if has_unsaved_changes()
            choice = questdlg('存在未保存或未应用的修改，是否关闭窗口？', ...
                '未保存提示', '保存项目', '放弃关闭', '取消', '取消');
            if strcmp(choice,'保存项目')
                onSaveSession([],[]);
                if ~has_unsaved_changes()
                    delete(fig);
                end
            elseif strcmp(choice,'放弃关闭')
                delete(fig);
            end
        else
            delete(fig);
        end
    end

    function apply_parameter_filters()
        options = struct();
        if ~strcmp(categoryFilterDrop.Value,'全部类别')
            options.category = categoryFilterDrop.Value;
        end
        query = strtrim(parameterSearchField.Value);
        if ~isempty(query)
            options.query = query;
        end
        if modifiedOnlyCheck.Value
            options.modifiedOnly = true;
            options.modifiedIds = modifiedIds;
        end
        parameterVisibleCatalog = filter_parameter_catalog(parameterCatalog, options);
        refresh_parameter_table();
    end

    function refresh_parameter_table()
        parameterTable.Data = parameter_table_data(currentP, baselineP, ...
            parameterVisibleCatalog, modifiedIds, pendingEdits, pendingErrors);
        parameterCountLabel.Text = sprintf('显示 %d / %d', ...
            numel(parameterVisibleCatalog), numel(parameterCatalog));
        update_parameter_description(1);
        refresh_test_api();
    end

    function update_parameter_description(row)
        if isempty(parameterVisibleCatalog)
            parameterDescriptionArea.Value = {'当前筛选条件下没有参数。'};
            return;
        end
        row = max(1, min(row, numel(parameterVisibleCatalog)));
        item = parameterVisibleCatalog(row);
        parameterDescriptionArea.Value = { ...
            sprintf('%s | %s', item.category, item.name); ...
            sprintf('含义：%s', item.description); ...
            sprintf('当前单位：%s；允许范围：%s', ...
                item.displayUnit, bounds_text(item)); ...
            sprintf('数据来源：%s；编辑方式：%s；关联：%s；代码字段：%s', ...
                source_label(item.basis), edit_policy_label(item), ...
                dependency_label(item), item.id)};
    end

    function refresh_test_api()
        api = struct();
        api.getState = @get_parameter_state_for_test;
        api.editById = @edit_parameter_by_id_for_test;
        api.stageEditById = @stage_parameter_by_id_for_test;
        api.applyPending = @apply_pending_for_test;
        api.restoreSelected = @restore_selected_for_test;
        api.setFilters = @set_parameter_filters_for_test;
        api.resetAll = @reset_parameters_for_test;
        api.switchTab = @switch_tab_for_test;
        api.saveSession = @save_session_for_test;
        api.loadSession = @load_session_for_test;
        api.hasUnsavedChanges = @has_unsaved_changes_for_test;
        api.handles = struct('mainTabs',mainTabs, 'parameterTab',parameterTab, ...
            'trimTab',trimTab, 'linearTab',linearTab, 'responseTab',responseTab, ...
            'parameterTable',parameterTable, 'categoryFilterDrop',categoryFilterDrop, ...
            'parameterSearchField',parameterSearchField, ...
            'modifiedOnlyCheck',modifiedOnlyCheck, ...
            'trimBetaLabel',trimBetaLabel);
        setappdata(fig,'ParameterWorkbenchApi',api);
    end

    function state = get_parameter_state_for_test()
        state = struct();
        state.parameterCatalog = parameterCatalog;
        state.currentP = currentP;
        state.baselineP = baselineP;
        state.modifiedIds = modifiedIds;
        state.pendingEdits = pendingEdits;
        state.pendingErrors = pendingErrors;
        state.visibleCatalog = parameterVisibleCatalog;
        state.tableData = parameterTable.Data;
        state.lastParameterError = lastParameterError;
        state.workflowStatus = workflowStatus;
        state.sessionDirty = sessionDirty;
        state.analysisDirty = analysisDirty;
    end

    function result = edit_parameter_by_id_for_test(id, displayValue)
        result = stage_parameter_by_id_for_test(id, displayValue);
        if result.success
            result = apply_pending_for_test();
        end
    end

    function result = stage_parameter_by_id_for_test(id, displayValue)
        idx = find(strcmp({parameterCatalog.id}, id), 1);
        if isempty(idx)
            error('launch_tiltrotor_app:UnknownParameterId', ...
                '找不到参数目录项：%s。', id);
        end
        item = parameterCatalog(idx);
        selectedParameterId = item.id;
        [ok,message] = validate_single_display_value(item, displayValue);
        key = key_from_id(item.id);
        pendingEdits.(key) = displayValue;
        if ok
            pendingErrors = remove_struct_field(pendingErrors, key);
            workflowStatus.parameters = '有待应用修改';
            result = struct('success',true,'message','参数修改已暂存。');
        else
            pendingErrors.(key) = message;
            lastParameterError = message;
            workflowStatus.parameters = '输入有误';
            result = struct('success',false,'message',message);
        end
        sessionDirty = true;
        apply_parameter_filters();
    end

    function result = apply_pending_for_test()
        onApplyParameterEdits([],[]);
        if ~isempty(lastParameterError) && ~isempty(fieldnames(pendingEdits))
            result = struct('success',false,'message',lastParameterError);
        else
            result = struct('success',isempty(fieldnames(pendingEdits)), ...
                'message','参数修改已应用。');
        end
    end

    function restore_selected_for_test(id)
        selectedParameterId = id;
        onRestoreSelectedParameter([],[]);
    end

    function set_parameter_filters_for_test(category, query, modifiedOnly)
        if nargin >= 1 && ~isempty(category)
            categoryFilterDrop.Value = category;
        end
        if nargin >= 2
            parameterSearchField.Value = query;
        end
        if nargin >= 3
            modifiedOnlyCheck.Value = logical(modifiedOnly);
        end
        apply_parameter_filters();
    end

    function reset_parameters_for_test()
        onResetParameters([],[]);
    end

    function switch_tab_for_test(name)
        switch name
            case 'parameter'
                mainTabs.SelectedTab = parameterTab;
            case 'trim'
                mainTabs.SelectedTab = trimTab;
            case 'linear'
                mainTabs.SelectedTab = linearTab;
            case 'response'
                mainTabs.SelectedTab = responseTab;
            otherwise
                error('launch_tiltrotor_app:UnknownTab', '未知页面：%s。', name);
        end
        drawnow;
    end

    function save_session_for_test(filePath)
        session = make_session();
        save_analysis_case(filePath, session);
        sessionDirty = false;
        analysisDirty = false;
    end

    function load_session_for_test(filePath)
        session = load_analysis_case(filePath);
        restore_session(session);
    end

    function tf = has_unsaved_changes_for_test()
        tf = has_unsaved_changes();
    end

    function ids = pending_ids()
        ids = fieldnames(pendingEdits);
    end

    function message = first_pending_error()
        fields = fieldnames(pendingErrors);
        if isempty(fields)
            message = '';
        else
            message = pendingErrors.(fields{1});
        end
    end

    function update_response_waveform_inputs()
        wave = responseWaveformDrop.Value;
        switch wave
            case '阶跃'
                responseDurationField.Enable = 'off';
                responseFrequencyField.Enable = 'off';
            case '脉冲'
                responseDurationField.Enable = 'on';
                responseFrequencyField.Enable = 'off';
            case '正弦'
                responseDurationField.Enable = 'on';
                responseFrequencyField.Enable = 'on';
            case '双脉冲'
                responseDurationField.Enable = 'on';
                responseFrequencyField.Enable = 'off';
        end
    end

    function tf = has_unsaved_changes()
        tf = sessionDirty || analysisDirty || ~isempty(fieldnames(pendingEdits));
    end

    function text = result_status(result)
        if isempty(result)
            text = '未运行';
        elseif isstruct(result) && isfield(result,'success') && result.success
            text = '已运行';
        else
            text = '失败';
        end
    end

    function update_trim_outputs_after_load()
        if ~isempty(trimResult) && isstruct(trimResult) && isfield(trimResult,'xTrim')
            update_trim_tables();
            if isfield(trimResult,'success') && trimResult.success
                runLinearButton.Enable = 'on';
            end
        else
            trimStateTable.Data = {};
            trimControlTable.Data = {};
            trimResidualTable.Data = {};
        end
    end

    function update_linear_outputs_after_load()
        if ~isempty(linearResult) && isstruct(linearResult) && isfield(linearResult,'A')
            update_linearization_views();
            runResponseButton.Enable = 'on';
        else
            aTable.Data = [];
            bTable.Data = [];
            eigenTable.Data = {};
        end
    end

    function update_response_outputs_after_load()
        if ~isempty(responseResult) && isstruct(responseResult) && ...
                isfield(responseResult,'deltaState')
            update_response_views();
        else
            responseSummaryTable.Data = {};
        end
    end

    function update_trim_tables()
        trimStateTable.Data = make_state_display(trimResult.xTrim,stateDisplayNames);
        trimControlTable.Data = make_control_display(trimResult.uTrim,controlDisplayNames);
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
        aTable.Data = linearResult.A;
        bTable.Data = linearResult.B;
        lambda = linearResult.eigenvalues;
        eigenTable.Data = [num2cell(real(lambda)) num2cell(imag(lambda)) ...
            num2cell(linearResult.naturalFrequency) ...
            num2cell(linearResult.dampingRatio) ...
            num2cell(linearResult.timeScale) ...
            cellfun(@mode_class_label, linearResult.classification, ...
            'UniformOutput', false)];
        cla(eigenAxes);
        plot(eigenAxes,real(lambda),imag(lambda),'o','LineWidth',1.4);
        hold(eigenAxes,'on');
        xline(eigenAxes,0,'--');
        hold(eigenAxes,'off');
        grid(eigenAxes,'on');
        title(eigenAxes,'特征值复平面');
    end

    function update_response_views()
        selectedState = find(strcmp(stateDisplayNames,responseStateDrop.Value),1);
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
        title(responseInputAxes,sprintf('%s 输入扰动',controlDisplayNames{selectedControl}));
        ylabel(responseInputAxes,'deg');
        plot(responseOutputAxes,t,displayOutput,'LineWidth',1.3);
        grid(responseOutputAxes,'on');
        title(responseOutputAxes,sprintf('%s %s响应',prefix,stateDisplayNames{selectedState}));
        ylabel(responseOutputAxes,displayUnit);
        [peakValue,peakIndex] = max(abs(displayOutput));
        summary = { ...
            '峰值',peakValue,displayUnit; ...
            '峰值时间',t(peakIndex),'s'; ...
            '稳态值',displayOutput(end),displayUnit; ...
            '是否触及操纵限幅',limit_text(responseResult.limitWarning),'--'};
        responseSummaryTable.Data = summary;
    end

    function invalidate_analysis(message)
        trimResult = [];
        clear_trim_dependent_results();
        workflowStatus.trim = '需重新计算';
        workflowStatus.linear = '无效';
        workflowStatus.response = '无效';
        analysisDirty = true;
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
        cla(eigenAxes);
        cla(responseInputAxes);
        cla(responseOutputAxes);
    end

    function set_status(message,kind)
        statusLabel.Text = sprintf('%s | 参数：%s | 配平：%s | 线性化：%s | 响应：%s', ...
            message, workflowStatus.parameters, workflowStatus.trim, ...
            workflowStatus.linear, workflowStatus.response);
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
            stopTrimButton.Enable = 'on';
            runLinearButton.Enable = 'off';
            runResponseButton.Enable = 'off';
            drawnow;
        else
            if isvalid(fig)
                fig.Pointer = 'arrow';
                runTrimButton.Enable = 'on';
                stopTrimButton.Enable = 'off';
                if ~isempty(trimResult) && trimResult.success
                    runLinearButton.Enable = 'on';
                end
                if ~isempty(linearResult) && linearResult.success
                    runResponseButton.Enable = 'on';
                end
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

function items = parameter_category_items(catalog)
categories = unique({catalog.category}, 'stable');
items = [{'全部类别'}, categories];
end

function key = key_from_id(id)
key = matlab.lang.makeValidName(strrep(id, '.', '_'));
end

function S = remove_struct_field(S, key)
if isfield(S, key)
    S = rmfield(S, key);
end
end

function [ok,message] = validate_single_display_value(item, value)
ok = false;
message = '';
if ~(isnumeric(value) && isreal(value) && isscalar(value) && isfinite(value))
    message = sprintf('“%s”必须填写有限实数。', item.name);
    return;
end
if ~within_bound_local(value, item.minimum, item.minimumInclusive, true)
    message = sprintf('“%s”低于允许下限。', item.name);
    return;
end
if ~within_bound_local(value, item.maximum, item.maximumInclusive, false)
    message = sprintf('“%s”高于允许上限。', item.name);
    return;
end
if item.integerRequired && value ~= round(value)
    message = sprintf('“%s”必须是整数。', item.name);
    return;
end
ok = true;
end

function tf = within_bound_local(value, bound, inclusive, isLower)
if isinf(bound)
    tf = true;
elseif isLower && inclusive
    tf = value >= bound;
elseif isLower
    tf = value > bound;
elseif inclusive
    tf = value <= bound;
else
    tf = value < bound;
end
end

function text = source_label(basis)
switch basis
    case {'环境设定','几何设定','质量与惯量设定','操纵范围设定','气动模型设定'}
        text = '当前模型设定';
    case '计算精度设置'
        text = '数值计算设置';
    otherwise
        text = basis;
end
end

function text = edit_policy_label(item)
switch item.writePolicy
    case 'readonly'
        text = '自动计算，只读';
    case {'rotorDerived','symmetricI0','diagKI','direct'}
        text = '可以直接编辑';
    otherwise
        text = '编辑方式待确认';
end
end

function text = dependency_label(item)
if isempty(item.dependencyGroup)
    text = '无';
else
    text = item.dependencyGroup;
end
end

function text = bounds_text(item)
lowerBracket = '(';
upperBracket = ')';
if item.minimumInclusive
    lowerBracket = '[';
end
if item.maximumInclusive
    upperBracket = ']';
end
text = sprintf('%s%s, %s%s', lowerBracket, num2str(item.minimum), ...
    num2str(item.maximum), upperBracket);
end

function text = limit_text(flag)
if flag
    text = '是';
else
    text = '否';
end
end

function text = mode_class_label(code)
switch code
    case 'UNSTABLE'
        text = '不稳定';
    case 'STABLE'
        text = '稳定';
    case 'NEUTRAL'
        text = '接近临界稳定';
    otherwise
        text = '数值结果需复核';
end
end

function data = parameter_table_data(P, baselineP, catalog, modifiedIds, ...
    pendingEdits, pendingErrors)
data = cell(numel(catalog),7);
for k = 1:numel(catalog)
    item = catalog(k);
    data{k,1} = item.category;
    data{k,2} = item.name;
    data{k,3} = get_parameter_catalog_value(baselineP,item);
    key = key_from_id(item.id);
    if isfield(pendingEdits, key)
        data{k,4} = pendingEdits.(key);
    else
        data{k,4} = get_parameter_catalog_value(P,item);
    end
    data{k,5} = item.displayUnit;
    if isfield(pendingErrors, key)
        data{k,6} = '输入有误';
    elseif isfield(pendingEdits, key)
        data{k,6} = '待应用';
    elseif strcmp(item.writePolicy,'readonly')
        data{k,6} = '自动计算';
    elseif ismember(item.id, modifiedIds)
        data{k,6} = '已修改';
    else
        data{k,6} = '未修改';
    end
    data{k,7} = source_label(item.basis);
end
end

function data = make_state_display(x,stateNames)
data = cell(9,3);
for k = 1:9
    data{k,1} = stateNames{k};
    if k <= 3
        data{k,2} = x(k);
        data{k,3} = 'm/s';
    elseif k <= 6
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
else
    displayValue = rawValue*180/pi;
    unit = 'deg';
end
end
