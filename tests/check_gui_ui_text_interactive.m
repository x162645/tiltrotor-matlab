function report = check_gui_ui_text_interactive()
%CHECK_GUI_UI_TEXT_INTERACTIVE Open the UI and verify visible text behavior.

fig = [];
report = struct('allPassed', false, 'observations', {{}});
try
    fig = launch_tiltrotor_app();
    drawnow;
    pause(1);
    figs = findall(0, 'Type', 'figure', ...
        'Name', 'Tiltrotor Analysis Workbench');
    assert(numel(figs) == 1, 'Expected one workbench window.');

    assert_no_forbidden_text(fig);
    assert(contains(collect_visible_text(fig), '已载入默认参数'));
    assert(contains(collect_visible_text(fig), ...
        '此页用于调整当前计算使用的关键参数。'));
    assert(contains(collect_visible_text(fig), '阶段：启动'));
    assert(contains(collect_visible_text(fig), '级别：提示'));
    report.observations{end+1,1} = '启动页和参数页文案已清理。';

    tables = find_ui_tables(fig);
    assert(~isempty(tables.parameter), 'Parameter table missing.');
    assert(~isempty(tables.candidate), 'Candidate table missing.');
    report.observations{end+1,1} = '候选表标题已中文化并带角度单位。';

    runTrimButton = find_one(fig, 'uibutton', '运行配平');
    trimCallback = runTrimButton.ButtonPushedFcn;
    trimCallback(runTrimButton, []);
    drawnow;
    pause(0.5);

    tables = find_ui_tables(fig);
    assert(size(tables.overview.Data, 1) >= 10, 'Overview not populated.');
    assert(any(strcmp(tables.overview.Data(:,1), '原因代码')));
    assert(size(tables.fullResidual.Data, 1) == 9, ...
        'Nine residual rows missing.');
    assert(size(tables.limit.Data, 1) == 3, 'Limit table missing.');
    assert(any(strcmp(tables.limit.Data(:,1), '俯仰角 theta')));
    assert(all(ismember(tables.limit.Data(:,7), {'是','否'})));
    assert(size(tables.candidate.Data, 1) >= 1, 'Candidate rows missing.');
    assert(all(ismember(tables.candidate.Data(:,10), {'是','否'})));
    assert_contains_diagnostic(fig, '阶段：配平');
    assert_contains_diagnostic(fig, '原因代码：TRIM_ACCEPTED');
    report.observations{end+1,1} = ...
        '默认悬停配平成功，总览、九状态残差、限幅和候选表显示正常。';

    copyButton = find_one(fig, 'uibutton', '复制诊断');
    copyCallback = copyButton.ButtonPushedFcn;
    copyCallback(copyButton, []);
    drawnow;
    copiedText = clipboard('paste');
    assert(contains(copiedText, '阶段：配平'));
    assert(contains(copiedText, '原因代码：'));
    assert(contains(copiedText, '接受状态：是'));
    report.observations{end+1,1} = '复制诊断文本使用中文标题和中文布尔值。';

    parameterEdit = tables.parameter.CellEditCallback;
    event = struct('Indices', [3 4], 'NewData', -1);
    parameterEdit(tables.parameter, event);
    drawnow;
    assert_contains_diagnostic(fig, '阶段：参数检查');
    assert_contains_diagnostic(fig, ...
        '错误标识：launch_tiltrotor_app:InvalidParameterEdit');
    assert_contains_diagnostic(fig, '级别：错误');
    report.observations{end+1,1} = ...
        '参数编辑失败显示中文诊断并保留 MATLAB 错误标识。';

    callbackInfo = functions(trimCallback);
    workspace = callbackInfo.workspace{1};
    workspace.trimVField.Limits = [-Inf Inf];
    workspace.trimVField.Value = -1;
    trimCallback(runTrimButton, []);
    drawnow;
    pause(0.5);
    assert_contains_diagnostic(fig, '阶段：配平');
    assert_contains_diagnostic(fig, '级别：错误');
    workspace.trimVField.Value = 0;
    workspace.trimVField.Limits = [0 Inf];
    report.observations{end+1,1} = ...
        '配平输入异常后状态为失败，旧表格结果被清空。';

    trimCallback(runTrimButton, []);
    drawnow;
    pause(0.5);
    assert_not_contains_diagnostic(fig, 'InvalidParameterEdit');
    assert_not_contains_diagnostic(fig, 'stage:');
    assert_not_contains_diagnostic(fig, 'severity:');
    report.observations{end+1,1} = ...
        '修正输入后重新配平成功，旧错误诊断不再残留。';

    linearButton = find_one(fig, 'uibutton', '运行线性化');
    assert(strcmp(linearButton.Enable, 'on'), ...
        'Linearization button should be enabled after valid trim.');
    linearCallback = linearButton.ButtonPushedFcn;
    linearCallback(linearButton, []);
    drawnow;
    pause(0.5);

    responseButton = find_one(fig, 'uibutton', '运行线性响应');
    assert(strcmp(responseButton.Enable, 'on'), ...
        'Response button should be enabled after linearization.');
    responseCallback = responseButton.ButtonPushedFcn;
    responseCallback(responseButton, []);
    drawnow;
    pause(0.5);
    assert_contains_diagnostic(fig, '阶段：响应');
    assert_no_forbidden_text(fig);
    report.observations{end+1,1} = ...
        '线性化和响应链可继续运行，按钮状态恢复正常。';

    close(fig);
    report.allPassed = true;
    fprintf('INTERACTIVE_UI_TEXT_AUDIT_OK\n');
catch ME
    if ~isempty(fig) && isvalid(fig)
        close(fig);
    end
    rethrow(ME);
end
end

function tables = find_ui_tables(fig)
tables = struct('parameter', [], 'overview', [], 'fullResidual', [], ...
    'limit', [], 'candidate', []);
allTables = findall(fig, 'Type', 'uitable');
for k = 1:numel(allTables)
    columnNames = allTables(k).ColumnName;
    if iscell(columnNames) && ~isempty(columnNames)
        switch columnNames{1}
            case '分组'
                tables.parameter = allTables(k);
            case '项目'
                tables.overview = allTables(k);
            case '状态导数'
                tables.fullResidual = allTables(k);
            case '变量'
                tables.limit = allTables(k);
            case '初始俯仰角(°)'
                tables.candidate = allTables(k);
        end
    end
end
end

function button = find_one(fig, typeName, textValue)
button = findobj(fig, 'Type', typeName, 'Text', textValue);
assert(numel(button) == 1, 'Expected exactly one UI object: %s.', textValue);
end

function assert_no_forbidden_text(fig)
forbidden = {'XV-15'; '型号验证'; '概念模型'; '概念参数'; ...
    '当前概念模型'; '内部一致性'; '不代表'};
visibleText = collect_visible_text(fig);
for k = 1:numel(forbidden)
    assert(~contains(visibleText, forbidden{k}), ...
        'Forbidden visible phrase: %s', forbidden{k});
end
end

function text = collect_visible_text(fig)
objects = findall(fig);
parts = {};
properties = {'Text', 'Title', 'Value', 'ColumnName'};
for iObject = 1:numel(objects)
    for iProperty = 1:numel(properties)
        try
            value = objects(iObject).(properties{iProperty});
            parts = append_text(parts, value);
        catch
        end
    end
end
text = strjoin(parts, newline);
end

function parts = append_text(parts, value)
if ischar(value)
    parts{end+1,1} = value;
elseif isstring(value)
    values = cellstr(value(:));
    for k = 1:numel(values)
        parts{end+1,1} = values{k}; %#ok<AGROW>
    end
elseif iscell(value)
    for k = 1:numel(value)
        if ischar(value{k}) || isstring(value{k})
            parts{end+1,1} = char(value{k}); %#ok<AGROW>
        end
    end
end
end

function assert_contains_diagnostic(fig, expected)
text = collect_diagnostic_text(fig);
assert(contains(text, expected), 'Diagnostic text missing: %s', expected);
end

function assert_not_contains_diagnostic(fig, unexpected)
text = collect_diagnostic_text(fig);
assert(~contains(text, unexpected), ...
    'Diagnostic text unexpectedly contains: %s', unexpected);
end

function text = collect_diagnostic_text(fig)
areas = findall(fig, 'Type', 'uitextarea');
parts = {};
for k = 1:numel(areas)
    value = areas(k).Value;
    if iscell(value)
        parts{end+1,1} = strjoin(value(:), newline); %#ok<AGROW>
    end
end
text = strjoin(parts, newline);
end
