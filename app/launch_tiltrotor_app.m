function fig = launch_tiltrotor_app()
%LAUNCH_TILTROTOR_APP Open the tiltrotor trim and linear-response workbench.
% The application is implemented as text-based MATLAB code for version
% control and R2021a compatibility. Model equations remain in model/analysis.

P = params_nominal();
trimResult = [];
linearResult = [];
responseResult = [];
currentDiagnostic = [];
parameterRows = make_parameter_rows();
stateNames = {'u','v','w','p','q','r','phi','theta','psi'};
controlNames = {'collective','diffCollective','cyclicLong', ...
    'diffCyclic','aileron','elevator','rudder'};

fig = uifigure('Name','Tiltrotor Analysis Workbench', ...
    'Position',[80 60 1420 860]);
root = uigridlayout(fig,[3 1]);
root.RowHeight = {54,'1x',118};
root.Padding = [10 8 10 10];
root.RowSpacing = 8;

header = uigridlayout(root,[1 8]);
header.Layout.Row = 1;
header.ColumnWidth = {270,22,'1x',120,120,120,120,150};
header.ColumnSpacing = 8;

uilabel(header,'Text','倾转旋翼机分析工作台', ...
    'FontSize',20,'FontWeight','bold');
statusLamp = uilamp(header,'Color',[0.93 0.69 0.13]);
statusLabel = uilabel(header,'Text','已载入默认参数');
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

diagnosticPanel = uipanel(root,'Title','当前操作诊断');
diagnosticPanel.Layout.Row = 3;
diagnosticGrid = uigridlayout(diagnosticPanel,[1 2]);
diagnosticGrid.ColumnWidth = {'1x',92};
diagnosticGrid.Padding = [8 6 8 8];
diagnosticText = uitextarea(diagnosticGrid,'Editable','off', ...
    'Value',{'阶段：启动'; '级别：提示'; '摘要：尚未运行分析。'});
uibutton(diagnosticGrid,'Text','复制诊断', ...
    'ButtonPushedFcn',@onCopyDiagnostic);

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
    '此页用于调整当前计算使用的关键参数。'; ...
    '修改参数后，需要重新运行配平、线性化和响应。'; ...
    '参数修改只对当前软件会话生效。'});
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
trimOverviewTab = uitab(trimOutputTabs,'Title','总览');
trimStateControlTab = uitab(trimOutputTabs,'Title','状态与操纵');
trimResidualLimitTab = uitab(trimOutputTabs,'Title','残差与限幅');
trimCandidateTab = uitab(trimOutputTabs,'Title','多初值候选');

trimOverviewGrid = uigridlayout(trimOverviewTab,[2 1]);
trimOverviewGrid.RowHeight = {'1x',95};
trimOverviewGrid.Padding = [0 0 0 0];
trimOverviewTable = uitable(trimOverviewGrid, ...
    'ColumnName',{'项目','数值'},'ColumnWidth',{230,220});
trimOverviewText = uitextarea(trimOverviewGrid,'Editable','off');

trimStateControlGrid = uigridlayout(trimStateControlTab,[1 2]);
trimStateControlGrid.ColumnWidth = {'1x','1x'};
trimStateControlGrid.Padding = [0 0 0 0];
trimStateTable = uitable(trimStateControlGrid, ...
    'ColumnName',{'状态','数值','单位'},'ColumnWidth',{140,160,120});
trimControlTable = uitable(trimStateControlGrid, ...
    'ColumnName',{'操纵','数值','单位'},'ColumnWidth',{180,160,120});

trimResidualLimitGrid = uigridlayout(trimResidualLimitTab,[2 1]);
trimResidualLimitGrid.RowHeight = {'1x','1x'};
trimResidualLimitGrid.Padding = [0 0 0 0];
trimFullResidualTable = uitable(trimResidualLimitGrid, ...
    'ColumnName',{'状态导数','数值','单位','分类'}, ...
    'ColumnWidth',{140,170,110,110});
trimLimitTable = uitable(trimResidualLimitGrid, ...
    'ColumnName',{'变量','数值(deg)','下限(deg)','上限(deg)', ...
    '下裕度(deg)','上裕度(deg)','触限','越限'}, ...
    'ColumnWidth',{120,95,95,95,105,105,70,70});

trimCandidateGrid = make_fill_grid(trimCandidateTab);
trimCandidateTable = uitable(trimCandidateGrid, ...
    'ColumnName',{'初始俯仰角(°)','初始总距(°)', ...
    '初始纵向周期变距(°)','最终俯仰角(°)','最终总距(°)', ...
    '最终纵向周期变距(°)','目标函数','残差范数','退出标志', ...
    '通过','触限','未越限'}, ...
    'ColumnWidth',{90,105,115,90,105,115,95,95,75,70,70,70});

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
uilabel(linearTop,'Text','A: 9×9，B: 9×7；中心差分步长来自当前参数', ...
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

set_status('已载入默认参数，请先检查参数或运行配平。','warning');

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
            set_current_diagnostic(make_operation_diagnostic( ...
                'parameter-validation','success','PARAMETER_EDIT_ACCEPTED', ...
                '参数修改已通过检查。','当前内存参数副本已更新。', ...
                {'旧配平、线性化和响应结果已失效，需要重新计算。'}));
        catch ME
            refresh_parameter_table();
            set_current_diagnostic(build_exception_diagnostic(ME, ...
                'parameter-validation', struct('row', row, 'newValue', newValue)));
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
            set_current_diagnostic(make_validation_diagnostic(validation));
            uialert(fig,message,'参数检查');
        else
            message = sprintf('%s\n%s',validation.summary, ...
                strjoin(validation.errors,newline));
            set_status(message,'error');
            set_current_diagnostic(make_validation_diagnostic(validation));
            uialert(fig,message,'参数检查失败');
        end
    end

    function onResetParameters(~,~)
        P = params_nominal();
        refresh_parameter_table();
        invalidate_analysis('已恢复默认参数，旧计算结果已失效。');
        set_current_diagnostic(make_operation_diagnostic( ...
            'parameter-validation','warning','PARAMETERS_RESET', ...
            '已恢复默认参数。','界面参数副本已恢复为 params_nominal()。', ...
            {'旧计算结果已清空，需要重新运行配平。'}));
    end

    function onRunTrim(~,~)
        set_busy(true);
        cleanup = onCleanup(@() set_busy(false));
        config = struct();
        try
            trimResult = [];
            clear_trim_dependent_results();
            trimStateTable.Data = {};
            trimControlTable.Data = {};
            trimOverviewTable.Data = {};
            trimOverviewText.Value = {''};
            trimFullResidualTable.Data = {};
            trimLimitTable.Data = {};
            trimCandidateTable.Data = {};
            trimStatusLabel.Text = '正在运行配平...';
            set_current_diagnostic(make_operation_diagnostic( ...
                'trim','warning','TRIM_RUNNING', ...
                '正在运行配平。','旧的线性化和响应结果已清空。', ...
                {'等待本次配平完成后查看新的诊断。'}));
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
            set_current_diagnostic(trimResult.diagnostic);
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
                set_status(trimResult.diagnostic.summary,'error');
            end
        catch ME
            trimResult = [];
            clear_trim_dependent_results();
            trimStateTable.Data = {};
            trimControlTable.Data = {};
            trimOverviewTable.Data = {};
            trimOverviewText.Value = {''};
            trimFullResidualTable.Data = {};
            trimLimitTable.Data = {};
            trimCandidateTable.Data = {};
            trimStatusLabel.Text = '配平失败：输入或模型计算异常';
            diagnostic = build_exception_diagnostic(ME,'trim',config);
            set_current_diagnostic(diagnostic);
            set_status(diagnostic.summary,'error');
            uialert(fig,ME.message,'配平失败');
        end
    end

    function onRunLinearization(~,~)
        set_busy(true);
        cleanup = onCleanup(@() set_busy(false));
        try
            linearResult = [];
            responseResult = [];
            runResponseButton.Enable = 'off';
            aTable.Data = [];
            bTable.Data = [];
            eigenTable.Data = {};
            cla(eigenAxes);
            linearStatusLabel.Text = '正在运行线性化...';
            responseSummaryTable.Data = {};
            cla(responseInputAxes);
            cla(responseOutputAxes);
            set_current_diagnostic(make_operation_diagnostic( ...
                'linearization','warning','LINEARIZATION_RUNNING', ...
                '正在运行线性化。','旧响应结果已清空。', ...
                {'等待线性化完成后查看模态和响应入口状态。'}));
            newLinearResult = run_linearization_case(trimResult,P);
            linearResult = newLinearResult;
            update_linearization_views();
            runResponseButton.Enable = 'on';
            if linearResult.hasUnstableMode
                linearStatusLabel.Text = '线性化完成：存在右半平面特征值';
                set_status('线性化完成，当前配平点存在不稳定模态。','warning');
                set_current_diagnostic(make_operation_diagnostic( ...
                    'linearization','warning','UNSTABLE_MODE_PRESENT', ...
                    '线性化完成，当前配平点存在不稳定模态。', ...
                    'A/B 矩阵和特征值已更新。', ...
                    {'该结果对应当前配平点。'}));
            else
                linearStatusLabel.Text = '线性化完成：未发现右半平面特征值';
                set_status('线性化与模态计算完成。','success');
                set_current_diagnostic(make_operation_diagnostic( ...
                    'linearization','success','LINEARIZATION_COMPLETED', ...
                    '线性化与模态计算完成。', ...
                    'A/B 矩阵和特征值已更新。', ...
                    {'可以继续运行小扰动操纵响应。'}));
            end
        catch ME
            linearResult = [];
            responseResult = [];
            runResponseButton.Enable = 'off';
            aTable.Data = [];
            bTable.Data = [];
            eigenTable.Data = {};
            cla(eigenAxes);
            linearStatusLabel.Text = '线性化失败：输入或模型计算异常';
            diagnostic = build_exception_diagnostic(ME,'linearization',struct());
            set_current_diagnostic(diagnostic);
            set_status(diagnostic.summary,'error');
            uialert(fig,ME.message,'线性化失败');
        end
    end

    function onRunResponse(~,~)
        set_busy(true);
        cleanup = onCleanup(@() set_busy(false));
        config = struct();
        try
            responseResult = [];
            responseSummaryTable.Data = {};
            cla(responseInputAxes);
            cla(responseOutputAxes);
            set_current_diagnostic(make_operation_diagnostic( ...
                'response','warning','RESPONSE_RUNNING', ...
                '正在运行线性响应。','旧响应图和摘要已清空。', ...
                {'等待响应计算完成后查看最新结果。'}));
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
            newResponseResult = simulate_linear_response(linearResult,config,P);
            responseResult = newResponseResult;
            update_response_views();
            if responseResult.limitWarning
                set_status('响应完成；实际操纵历史触及或越过当前限幅。','warning');
                set_current_diagnostic(make_operation_diagnostic( ...
                    'response','warning','RESPONSE_CONTROL_LIMIT_WARNING', ...
                    '响应完成；实际操纵历史触及或越过当前限幅。', ...
                    '线性响应结果已更新，限幅检查仅用于提示。', ...
                    {'减小输入幅值或检查当前配平操纵量与控制限幅的裕度。'}));
            else
                set_status('线性小扰动响应计算完成。','success');
                set_current_diagnostic(make_operation_diagnostic( ...
                    'response','success','RESPONSE_COMPLETED', ...
                    '线性小扰动响应计算完成。', ...
                    '响应图和摘要表已更新。', ...
                    {'响应是当前配平点附近的小扰动线性结果。'}));
            end
        catch ME
            responseResult = [];
            responseSummaryTable.Data = {};
            diagnostic = build_exception_diagnostic(ME,'response',config);
            set_current_diagnostic(diagnostic);
            set_status(diagnostic.summary,'error');
            uialert(fig,ME.message,'响应计算失败');
        end
    end

    function onResponseDisplayChanged(~,~)
        if ~isempty(responseResult)
            update_response_views();
        end
    end

    function onCopyDiagnostic(~,~)
        if isempty(currentDiagnostic)
            return;
        end
        try
            clipboard('copy', diagnostic_to_text(currentDiagnostic));
            set_status('当前诊断已复制到剪贴板。','success');
        catch ME
            diagnostic = build_exception_diagnostic(ME,'copy-diagnostic',struct());
            set_current_diagnostic(diagnostic);
            set_status(diagnostic.summary,'error');
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
        try
            save_analysis_case(fullfile(pathName,fileName),session);
            set_status(sprintf('已导出：%s',fullfile(pathName,fileName)),'success');
            set_current_diagnostic(make_operation_diagnostic( ...
                'export','success','EXPORT_COMPLETED', ...
                '工况导出完成。',sprintf('文件：%s',fullfile(pathName,fileName)), ...
                {'导出文件包含当前内存参数和已有分析结果。'}));
        catch ME
            diagnostic = build_exception_diagnostic(ME,'export', ...
                struct('filePath', fullfile(pathName,fileName)));
            set_current_diagnostic(diagnostic);
            set_status(diagnostic.summary,'error');
            uialert(fig,ME.message,'导出失败');
        end
    end

    function onShowHelp(~,~)
        uialert(fig,sprintf([ ...
            '推荐顺序：\n1. 检查或修改关键参数；\n2. 运行配平；\n' ...
            '3. 在收敛配平点运行线性化；\n4. 设置小幅操纵输入并计算响应。\n\n' ...
            '参数修改只对当前软件会话生效。\n' ...
            '线性响应适用于当前配平点附近的小扰动。\n' ...
            '错误和诊断信息显示在窗口底部的当前操作诊断面板。']), ...
            '使用说明');
    end

    function refresh_parameter_table()
        parameterTable.Data = parameter_table_data(P,parameterRows);
    end

    function update_trim_tables()
        trimStateTable.Data = make_state_display(trimResult.xTrim,stateNames);
        trimControlTable.Data = make_control_display(trimResult.uTrim,controlNames);
        if ~isfield(trimResult, 'diagnostic')
            trimResult.diagnostic = build_trim_diagnostic(trimResult);
        end
        diagnostic = trimResult.diagnostic;
        trimOverviewTable.Data = make_trim_overview_display(diagnostic);
        trimOverviewText.Value = diagnostic_overview_lines(diagnostic);
        trimFullResidualTable.Data = make_full_residual_display( ...
            diagnostic.fullResiduals);
        trimLimitTable.Data = make_limit_display(diagnostic.limitItems);
        trimCandidateTable.Data = make_candidate_display(diagnostic.candidates);
    end

    function update_linearization_views()
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
            '操纵限幅警告',bool_text(responseResult.limitWarning)};
        responseSummaryTable.Data = summary;
    end

    function invalidate_analysis(message)
        trimResult = [];
        clear_trim_dependent_results();
        trimStateTable.Data = {};
        trimControlTable.Data = {};
        trimOverviewTable.Data = {};
        trimOverviewText.Value = {''};
        trimFullResidualTable.Data = {};
        trimLimitTable.Data = {};
        trimCandidateTable.Data = {};
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

    function set_current_diagnostic(diagnostic)
        currentDiagnostic = diagnostic;
        diagnosticText.Value = text_to_lines(diagnostic_to_text(diagnostic));
    end

    function diagnostic = make_validation_diagnostic(validation)
        diagnostic.kind = 'operation-diagnostic';
        diagnostic.stage = 'parameter-validation';
        if validation.valid
            if validation.warningCount > 0
                diagnostic.severity = 'warning';
                diagnostic.identifier = 'PARAMETER_VALIDATION_WARNING';
            else
                diagnostic.severity = 'success';
                diagnostic.identifier = 'PARAMETER_VALIDATION_PASSED';
            end
        else
            diagnostic.severity = 'error';
            diagnostic.identifier = 'PARAMETER_VALIDATION_FAILED';
        end
        diagnostic.reasonCodes = {diagnostic.identifier};
        diagnostic.summary = validation.summary;
        detailParts = [validation.errors(:); validation.warnings(:)];
        if isempty(detailParts)
            diagnostic.details = '无错误或警告。';
        else
            diagnostic.details = strjoin(detailParts, newline);
        end
        if validation.valid
            diagnostic.suggestions = {'可以继续运行配平。'};
        else
            diagnostic.suggestions = {'按错误列表修正参数后重新检查。'};
        end
    end

    function diagnostic = make_operation_diagnostic(stage,severity,identifier, ...
            summary,details,suggestions)
        diagnostic.kind = 'operation-diagnostic';
        diagnostic.stage = stage;
        diagnostic.severity = severity;
        diagnostic.identifier = identifier;
        diagnostic.reasonCodes = {identifier};
        diagnostic.summary = summary;
        diagnostic.details = details;
        diagnostic.suggestions = suggestions(:);
    end

    function data = make_trim_overview_display(diagnostic)
        ov = diagnostic.overview;
        data = { ...
            '接受状态', bool_text(ov.accepted); ...
            '诊断级别', severity_display(diagnostic.severity); ...
            '求解器收敛', bool_text(ov.solverConverged); ...
            '目标残差范数', ov.residualNorm; ...
            '目标残差容限', ov.residualTolerance; ...
            '九状态导数范数', ov.fullResidualNorm; ...
            '触及限幅', bool_text(ov.atLimit); ...
            '存在越限', bool_text(ov.hasLimitViolation); ...
            '候选接受/总数', sprintf('%d / %d', ...
                ov.acceptedCandidateCount, ov.candidateCount); ...
            '无效模型评估', ov.invalidEvaluationCount; ...
            '原因代码', strjoin(diagnostic.reasonCodes(:).', ', ')};
    end

    function lines = diagnostic_overview_lines(diagnostic)
        lines = [{diagnostic.summary}; {'建议：'}; diagnostic.suggestions(:)];
        if ~isempty(diagnostic.invalidEvaluationIdentifiers)
            lines = [lines; {'无效评估标识：'}; ...
                diagnostic.invalidEvaluationIdentifiers(:)];
        end
    end

    function data = make_full_residual_display(residuals)
        data = cell(numel(residuals),4);
        for k = 1:numel(residuals)
            data{k,1} = residuals(k).name;
            data{k,2} = residuals(k).value;
            data{k,3} = residuals(k).unit;
            if residuals(k).isObjective
                data{k,4} = '配平目标';
            else
                data{k,4} = '完整导数';
            end
        end
    end

    function data = make_limit_display(items)
        data = cell(numel(items),8);
        for k = 1:numel(items)
            data{k,1} = limit_name_display(items(k).name);
            data{k,2} = items(k).valueDeg;
            data{k,3} = items(k).lowerDeg;
            data{k,4} = items(k).upperDeg;
            data{k,5} = items(k).lowerMarginDeg;
            data{k,6} = items(k).upperMarginDeg;
            data{k,7} = bool_text(items(k).atLimit);
            data{k,8} = bool_text(items(k).violated);
        end
    end

    function data = make_candidate_display(candidates)
        data = cell(numel(candidates),12);
        for k = 1:numel(candidates)
            data{k,1} = candidates(k).initialThetaDeg;
            data{k,2} = candidates(k).initialCollectiveDeg;
            data{k,3} = candidates(k).initialCyclicLongDeg;
            data{k,4} = candidates(k).finalThetaDeg;
            data{k,5} = candidates(k).finalCollectiveDeg;
            data{k,6} = candidates(k).finalCyclicLongDeg;
            data{k,7} = candidates(k).cost;
            data{k,8} = candidates(k).residualNorm;
            data{k,9} = candidates(k).exitflag;
            data{k,10} = bool_text(candidates(k).acceptable);
            data{k,11} = bool_text(candidates(k).atLimit);
            data{k,12} = bool_text(candidates(k).withinLimits);
        end
    end

    function text = diagnostic_to_text(diagnostic)
        if isempty(diagnostic)
            text = '阶段：未知阶段';
            return;
        end
        switch diagnostic.kind
            case 'trim-diagnostic'
                text = sprintf(['阶段：%s\n级别：%s\n原因代码：%s\n' ...
                    '摘要：%s\n接受状态：%s\n求解器收敛：%s\n' ...
                    '目标残差范数：%.16g\n目标残差容限：%.16g\n' ...
                    '九状态导数范数：%.16g\n候选通过数：%d/%d\n' ...
                    '无效模型评估：%d\n建议：\n%s'], ...
                    stage_display('trim'), severity_display(diagnostic.severity), ...
                    strjoin(diagnostic.reasonCodes(:).', ', '), ...
                    diagnostic.summary, bool_text(diagnostic.overview.accepted), ...
                    bool_text(diagnostic.overview.solverConverged), ...
                    diagnostic.overview.residualNorm, ...
                    diagnostic.overview.residualTolerance, ...
                    diagnostic.overview.fullResidualNorm, ...
                    diagnostic.overview.acceptedCandidateCount, ...
                    diagnostic.overview.candidateCount, ...
                    diagnostic.invalidEvaluationCount, ...
                    prefix_lines(diagnostic.suggestions));
            case 'exception-diagnostic'
                text = sprintf(['阶段：%s\n级别：%s\n错误标识：%s\n' ...
                    '摘要：%s\n详细信息：%s\n建议：\n%s\n调用栈：\n%s'], ...
                    stage_display(diagnostic.stage), ...
                    severity_display(diagnostic.severity), ...
                    diagnostic.identifier, diagnostic.summary, ...
                    diagnostic.details, prefix_lines(diagnostic.suggestions), ...
                    stack_to_text(diagnostic.stackSummary));
            otherwise
                text = sprintf(['阶段：%s\n级别：%s\n原因代码：%s\n' ...
                    '摘要：%s\n详细信息：%s\n建议：\n%s'], ...
                    stage_display(diagnostic.stage), ...
                    severity_display(diagnostic.severity), ...
                    diagnostic_codes_text(diagnostic), ...
                    diagnostic.summary, diagnostic.details, ...
                    prefix_lines(diagnostic.suggestions));
        end
    end

    function text = diagnostic_codes_text(diagnostic)
        if isfield(diagnostic, 'reasonCodes')
            text = strjoin(diagnostic.reasonCodes(:).', ', ');
        elseif isfield(diagnostic, 'identifier')
            text = diagnostic.identifier;
        else
            text = '';
        end
    end

    function text = stack_to_text(stackSummary)
        if isempty(stackSummary)
            text = '  无';
            return;
        end
        rows = cell(numel(stackSummary),1);
        for k = 1:numel(stackSummary)
            rows{k} = sprintf('  %s (%s:%d)', stackSummary(k).name, ...
                stackSummary(k).file, stackSummary(k).line);
        end
        text = strjoin(rows, newline);
    end

    function text = prefix_lines(lines)
        if isempty(lines)
            text = '  无';
            return;
        end
        lines = lines(:);
        for k = 1:numel(lines)
            lines{k} = sprintf('  - %s', lines{k});
        end
        text = strjoin(lines, newline);
    end

    function lines = text_to_lines(text)
        lines = regexp(text, '\r\n|\n|\r', 'split').';
    end

    function value = bool_text(flag)
        if flag
            value = '是';
        else
            value = '否';
        end
    end

    function value = severity_display(severity)
        switch char(severity)
            case 'success'
                value = '成功';
            case 'warning'
                value = '警告';
            case 'error'
                value = '错误';
            otherwise
                value = char(severity);
        end
    end

    function value = stage_display(stage)
        switch char(stage)
            case 'startup'
                value = '启动';
            case 'parameter-validation'
                value = '参数检查';
            case 'trim'
                value = '配平';
            case 'linearization'
                value = '线性化';
            case 'response'
                value = '响应';
            case 'export'
                value = '导出';
            case 'copy-diagnostic'
                value = '复制诊断';
            case 'unknown'
                value = '未知阶段';
            otherwise
                value = char(stage);
        end
    end

    function value = limit_name_display(name)
        switch char(name)
            case 'theta'
                value = '俯仰角 theta';
            case 'collective'
                value = '总距 collective';
            case 'cyclicLong'
                value = '纵向周期变距 cyclicLong';
            otherwise
                value = char(name);
        end
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
