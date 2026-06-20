function report = check_gui_ui_text_interactive()
%CHECK_GUI_UI_TEXT_INTERACTIVE Exercise visible UI text and interactions.

fig = [];
tempFolder = '';
report = struct('allPassed', false, 'observations', {{}});
try
    fig = launch_tiltrotor_app();
    drawnow;
    pause(1);
    assert(strcmp(fig.Name, '倾转旋翼机分析工作台'));
    assert(isequal(fig.Position(3:4), [1420 860]), ...
        'Unexpected default window size.');
    assert_no_forbidden_text(fig);
    assert(contains(collect_visible_text(fig), '已载入默认参数'));
    assert(contains(collect_visible_text(fig), ...
        '此页用于调整当前计算使用的关键参数。'));
    assert(contains(collect_visible_text(fig), '阶段：启动'));
    assert(contains(collect_visible_text(fig), '级别：提示'));
    report.observations{end+1,1} = ...
        '窗口标题、默认尺寸、启动页和参数页文案检查通过。';

    tables = find_ui_tables(fig);
    assert(~isempty(tables.parameter), 'Parameter table missing.');
    sourceValues = unique(tables.parameter.Data(:,6));
    assert(all(ismember(sourceValues, {'设定值'; '参考常数'; '数值设置'})));
    assert(~any(ismember(sourceValues, ...
        {'ASSUMED_CONCEPT'; 'REFERENCE_CONSTANT'; 'NUMERICAL'})));
    report.observations{end+1,1} = ...
        '参数来源分类仅在显示层映射为中文。';

    helpButton = find_one(fig, 'uibutton', '使用说明');
    helpCallback = helpButton.ButtonPushedFcn;
    helpCallback(helpButton, []);
    drawnow;
    pause(0.2);
    helpCallbackInfo = functions(helpCallback);
    helpWorkspace = helpCallbackInfo.workspace{1};
    helpDialog = find_dialog('使用说明');
    expectedHelp = sprintf([ ...
        '推荐顺序：\n1. 检查或修改关键参数；\n2. 运行配平；\n' ...
        '3. 在收敛配平点运行线性化；\n4. 设置小幅操纵输入并计算响应。\n\n' ...
        '参数修改只对当前软件会话生效。\n' ...
        '线性响应适用于当前配平点附近的小扰动。\n' ...
        '错误和诊断信息显示在窗口底部的当前操作诊断面板。']);
    helpText = helpWorkspace.helpMessage;
    assert(strcmp(normalize_text(helpText), normalize_text(expectedHelp)), ...
        'Help dialog text is incomplete.');
    assert(contains(normalize_text(collect_visible_text(helpDialog)), ...
        normalize_text(expectedHelp)), 'Rendered help text is incomplete.');
    assert_no_forbidden_text_value(helpText);
    assert(~contains(helpText, 'Tiltrotor Analysis Workbench'));
    closeButton = find_one(helpDialog, 'uibutton', '关闭');
    closeCallback = closeButton.ButtonPushedFcn;
    closeCallback(closeButton, []);
    drawnow;
    pause(0.2);
    assert(isempty(findall(0, 'Type', 'figure', 'Name', '使用说明')));
    assert(isvalid(fig), 'Main window closed with help dialog.');
    assert(strcmp(find_one(fig, 'uibutton', '运行配平').Enable, 'on'));
    report.observations{end+1,1} = ...
        '帮助弹窗完整文案、禁止词和关闭后主界面可用性检查通过。';

    tabs = find_tabs(fig);
    tabs.main.SelectedTab = tabs.parameter;
    drawnow;
    tabs.main.SelectedTab = tabs.trim;
    tabs.trimGroup.SelectedTab = tabs.trimOverview;
    drawnow;
    tabs.trimGroup.SelectedTab = tabs.trimStateControl;
    drawnow;
    tabs.trimGroup.SelectedTab = tabs.trimResidualLimit;
    drawnow;
    tabs.trimGroup.SelectedTab = tabs.trimCandidate;
    drawnow;
    tabs.main.SelectedTab = tabs.linear;
    drawnow;
    tabs.main.SelectedTab = tabs.response;
    drawnow;
    tabs.main.SelectedTab = tabs.trim;
    tabs.trimGroup.SelectedTab = tabs.trimOverview;
    drawnow;
    report.observations{end+1,1} = ...
        '关键参数、四个配平结果页、线性化与模态、操纵响应均已逐页切换。';

    assert_layout(fig, tables);
    defaultPosition = fig.Position;
    fig.Position = [defaultPosition(1:2) 1180 720];
    drawnow;
    pause(0.2);
    assert(isequal(fig.Position(3:4), [1180 720]));
    assert_positive_position(tabs.main);
    assert_positive_position(find_one(fig, 'uibutton', '运行配平'));
    diagnosticPanel = find_one_panel(fig, '当前操作诊断');
    assert(strcmp(diagnosticPanel.Visible, 'on'));
    assert_positive_position(diagnosticPanel);
    fig.Position = [80 60 1420 860];
    drawnow;
    pause(0.2);
    restoredSize = fig.Position(3:4);
    assert(isequal(restoredSize, [1420 860]), ...
        'Unexpected restored size: %.1f x %.1f.', restoredSize(1), restoredSize(2));
    report.observations{end+1,1} = ...
        '默认和 1180x720 尺寸下控件边界、按钮重叠、表格及诊断面板检查通过。';

    runTrimButton = find_one(fig, 'uibutton', '运行配平');
    trimCallback = runTrimButton.ButtonPushedFcn;
    trimCallback(runTrimButton, []);
    drawnow;
    pause(0.5);

    tables = find_ui_tables(fig);
    assert(size(tables.overview.Data, 1) >= 10, 'Overview not populated.');
    assert(any(strcmp(tables.overview.Data(:,1), '原因代码')));
    assert(any(strcmp(tables.overview.Data(:,1), '无效计算次数')));
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
        '默认悬停配平成功，九状态残差、限幅、候选和新诊断文案显示正常。';

    copyButton = find_one(fig, 'uibutton', '复制诊断');
    copyCallback = copyButton.ButtonPushedFcn;
    copyCallback(copyButton, []);
    drawnow;
    copiedText = clipboard('paste');
    assert(contains(copiedText, '阶段：配平'));
    assert(contains(copiedText, '原因代码：'));
    assert(contains(copiedText, '接受状态：是'));

    parameterEdit = tables.parameter.CellEditCallback;
    event = struct('Indices', [3 4], 'NewData', -1);
    parameterEdit(tables.parameter, event);
    drawnow;
    assert_contains_diagnostic(fig, '阶段：参数检查');
    assert_contains_diagnostic(fig, ...
        '错误标识：launch_tiltrotor_app:InvalidParameterEdit');
    assert_contains_diagnostic(fig, '级别：错误');
    close_dialog_if_present('参数修改无效');

    callbackInfo = functions(trimCallback);
    workspace = callbackInfo.workspace{1};
    workspace.trimVField.Limits = [-Inf Inf];
    workspace.trimVField.Value = -1;
    trimCallback(runTrimButton, []);
    drawnow;
    pause(0.5);
    assert_contains_diagnostic(fig, '阶段：配平');
    assert_contains_diagnostic(fig, '级别：错误');
    close_dialog_if_present('配平失败');
    workspace.trimVField.Value = 0;
    workspace.trimVField.Limits = [0 Inf];

    trimCallback(runTrimButton, []);
    drawnow;
    pause(0.5);
    assert_not_contains_diagnostic(fig, 'InvalidParameterEdit');
    assert_not_contains_diagnostic(fig, 'stage:');
    assert_not_contains_diagnostic(fig, 'severity:');

    linearButton = find_one(fig, 'uibutton', '运行线性化');
    assert(strcmp(linearButton.Enable, 'on'));
    linearCallback = linearButton.ButtonPushedFcn;
    linearCallback(linearButton, []);
    drawnow;
    pause(0.5);

    responseButton = find_one(fig, 'uibutton', '运行线性响应');
    assert(strcmp(responseButton.Enable, 'on'));
    responseCallback = responseButton.ButtonPushedFcn;
    responseCallback(responseButton, []);
    drawnow;
    pause(0.5);
    assert_contains_diagnostic(fig, '阶段：响应');
    assert_no_forbidden_text(fig);
    report.observations{end+1,1} = ...
        '参数错误、配平错误恢复、线性化和响应真实回调链检查通过。';

    exportButton = find_one(fig, 'uibutton', '导出工况');
    exportCallbackInfo = functions(exportButton.ButtonPushedFcn);
    exportWorkspace = exportCallbackInfo.workspace{1};
    beforeCancel = collect_diagnostic_text(fig);
    cancelled = exportWorkspace.exportSessionSelection(0, 0);
    assert(~cancelled, 'Cancel path must not report success.');
    assert(strcmp(beforeCancel, collect_diagnostic_text(fig)), ...
        'Cancel path unexpectedly changed the diagnostic.');

    tempFolder = tempname;
    mkdir(tempFolder);
    exportFileName = 'interactive_export.mat';
    exportPath = fullfile(tempFolder, exportFileName);
    exported = exportWorkspace.exportSessionSelection( ...
        exportFileName, [tempFolder filesep]);
    drawnow;
    assert(exported, 'Export path did not report success.');
    assert(exist(exportPath, 'file') == 2, 'Export file was not created.');
    loaded = load(exportPath, 'session');
    assert(isfield(loaded, 'session') && isstruct(loaded.session));
    requiredFields = {'appName','parameters','trim','linearization', ...
        'response','exportedAt','formatVersion'};
    assert(all(isfield(loaded.session, requiredFields)));
    assert(strcmp(loaded.session.appName, '倾转旋翼机分析工作台'));
    assert(loaded.session.formatVersion == 1);
    assert_contains_diagnostic(fig, '阶段：导出');
    assert_contains_diagnostic(fig, '级别：成功');
    assert_contains_diagnostic(fig, '原因代码：EXPORT_COMPLETED');
    delete(exportPath);
    assert(exist(exportPath, 'file') == 0, 'Export file was not deleted.');
    rmdir(tempFolder);
    tempFolder = '';
    report.observations{end+1,1} = ...
        '导出取消不改变状态；成功路径真实生成、重载并删除了临时 MAT 文件。';

    close(fig);
    report.allPassed = true;
    fprintf('INTERACTIVE_UI_TEXT_AUDIT_OK\n');
catch ME
    close_dialog_if_present('使用说明');
    close_dialog_if_present('参数修改无效');
    close_dialog_if_present('配平失败');
    if ~isempty(fig) && isvalid(fig)
        close(fig);
    end
    if ~isempty(tempFolder) && exist(tempFolder, 'dir')
        files = dir(fullfile(tempFolder, '*.mat'));
        for k = 1:numel(files)
            delete(fullfile(tempFolder, files(k).name));
        end
        rmdir(tempFolder);
    end
    rethrow(ME);
end
end

function tabs = find_tabs(fig)
allGroups = findall(fig, 'Type', 'uitabgroup');
assert(numel(allGroups) >= 3, 'Expected main, trim, and matrix tab groups.');
tabs.parameter = find_one_tab(fig, '关键参数');
tabs.trim = find_one_tab(fig, '配平');
tabs.linear = find_one_tab(fig, '线性化与模态');
tabs.response = find_one_tab(fig, '操纵响应');
tabs.main = tabs.parameter.Parent;
tabs.trimOverview = find_one_tab(fig, '总览');
tabs.trimStateControl = find_one_tab(fig, '状态与操纵');
tabs.trimResidualLimit = find_one_tab(fig, '残差与限幅');
tabs.trimCandidate = find_one_tab(fig, '多初值候选');
tabs.trimGroup = tabs.trimOverview.Parent;
end

function tab = find_one_tab(fig, titleValue)
tab = findobj(fig, 'Type', 'uitab', 'Title', titleValue);
assert(numel(tab) == 1, 'Expected exactly one tab: %s.', titleValue);
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

function assert_layout(fig, tables)
controls = [ ...
    findobj(fig, 'Type', 'uibutton', 'Text', '检查参数'); ...
    findobj(fig, 'Type', 'uibutton', 'Text', '恢复默认'); ...
    findobj(fig, 'Type', 'uibutton', 'Text', '导出工况'); ...
    findobj(fig, 'Type', 'uibutton', 'Text', '使用说明'); ...
    findobj(fig, 'Type', 'uibutton', 'Text', '运行配平')];
for k = 1:numel(controls)
    assert_inside_parent(controls(k));
end
assert_no_overlap(controls(1:4));

tableValues = struct2cell(tables);
for k = 1:numel(tableValues)
    if ~isempty(tableValues{k})
        assert_inside_parent(tableValues{k});
        pos = tableValues{k}.Position;
        assert(pos(3) > 20 && pos(4) > 20, 'Table is fully obscured.');
    end
end

diagnosticPanel = find_one_panel(fig, '当前操作诊断');
assert(strcmp(diagnosticPanel.Visible, 'on'));
assert_inside_parent(diagnosticPanel);
diagnosticAreas = findall(diagnosticPanel, 'Type', 'uitextarea');
assert(~isempty(diagnosticAreas), 'Diagnostic text area missing.');
assert_inside_parent(diagnosticAreas(1));
end

function assert_positive_position(object)
pos = object.Position;
assert(pos(3) > 0 && pos(4) > 0, 'UI object has non-positive size.');
assert(strcmp(object.Visible, 'on'), 'UI object is not visible.');
end

function assert_inside_parent(object)
pos = object.Position;
assert(pos(3) > 0 && pos(4) > 0, 'UI object has non-positive size.');
parent = object.Parent;
[parentWidth,parentHeight] = container_size(parent);
tolerance = 24;
assert(pos(1) >= -tolerance && pos(2) >= -tolerance, ...
    'UI object starts outside its parent.');
assert(pos(1) + pos(3) <= parentWidth + tolerance, ...
    'UI object %s exceeds parent width: right=%.1f parent=%.1f.', ...
    object_label(object), pos(1) + pos(3), parentWidth);
assert(pos(2) + pos(4) <= parentHeight + tolerance, ...
    'UI object %s exceeds parent height: top=%.1f parent=%.1f.', ...
    object_label(object), pos(2) + pos(4), parentHeight);
end

function value = object_label(object)
try
    value = char(object.Text);
catch
    try
        value = char(object.Title);
    catch
        value = class(object);
    end
end
end

function [width,height] = container_size(container)
try
    pos = container.Position;
    width = pos(3);
    height = pos(4);
    return;
catch
end
try
    pos = container.InnerPosition;
    width = pos(3);
    height = pos(4);
    return;
catch
end
if ~isempty(container.Parent)
    [width,height] = container_size(container.Parent);
else
    error('Unable to determine container size.');
end
end

function assert_no_overlap(objects)
for i = 1:numel(objects)
    for j = i+1:numel(objects)
        if objects(i).Parent == objects(j).Parent
            a = objects(i).Position;
            b = objects(j).Position;
            overlapWidth = min(a(1)+a(3), b(1)+b(3)) - max(a(1),b(1));
            overlapHeight = min(a(2)+a(4), b(2)+b(4)) - max(a(2),b(2));
            assert(overlapWidth <= 0 || overlapHeight <= 0, ...
                'Major buttons overlap.');
        end
    end
end
end

function panel = find_one_panel(fig, titleValue)
panel = findobj(fig, 'Type', 'uipanel', 'Title', titleValue);
assert(numel(panel) == 1, 'Expected exactly one panel: %s.', titleValue);
end

function button = find_one(fig, typeName, textValue)
button = findobj(fig, 'Type', typeName, 'Text', textValue);
assert(numel(button) == 1, 'Expected exactly one UI object: %s.', textValue);
end

function dialog = find_dialog(titleValue)
dialog = findall(0, 'Type', 'figure', 'Name', titleValue);
assert(numel(dialog) == 1, 'Expected exactly one dialog: %s.', titleValue);
end

function close_dialog_if_present(titleValue)
dialogs = findall(0, 'Type', 'figure', 'Name', titleValue);
for k = 1:numel(dialogs)
    if isvalid(dialogs(k))
        close(dialogs(k));
    end
end
end

function assert_no_forbidden_text(container)
forbidden = {'XV-15'; '型号验证'; '概念模型'; '概念参数'; ...
    '当前概念模型'; '内部一致性'; '不代表'; ...
    'Tiltrotor Analysis Workbench'; '配平已接受'; ...
    '无效模型评估'; '无效评估标识'};
visibleText = collect_visible_text(container);
for k = 1:numel(forbidden)
    assert(~contains(visibleText, forbidden{k}), ...
        'Forbidden visible phrase: %s', forbidden{k});
end
end

function assert_no_forbidden_text_value(visibleText)
forbidden = {'XV-15'; '型号验证'; '概念模型'; '概念参数'; ...
    '当前概念模型'; '内部一致性'; '不代表'; ...
    'Tiltrotor Analysis Workbench'; '配平已接受'; ...
    '无效模型评估'; '无效评估标识'};
for k = 1:numel(forbidden)
    assert(~contains(visibleText, forbidden{k}), ...
        'Forbidden visible phrase: %s', forbidden{k});
end
end

function text = collect_visible_text(container)
objects = findall(container);
parts = {};
properties = {'Name', 'Text', 'Title', 'Value', 'ColumnName'};
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

function text = normalize_text(text)
text = regexprep(text, '\s+', '');
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
panel = find_one_panel(fig, '当前操作诊断');
areas = findall(panel, 'Type', 'uitextarea');
parts = {};
for k = 1:numel(areas)
    value = areas(k).Value;
    if iscell(value)
        parts{end+1,1} = strjoin(value(:), newline); %#ok<AGROW>
    end
end
text = strjoin(parts, newline);
end
