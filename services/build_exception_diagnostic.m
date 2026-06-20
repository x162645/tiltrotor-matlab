function diagnostic = build_exception_diagnostic(ME, stage, inputSnapshot)
%BUILD_EXCEPTION_DIAGNOSTIC Convert a caught MException to GUI diagnostics.

if nargin < 2 || isempty(stage)
    stage = 'unknown';
end
if nargin < 3
    inputSnapshot = struct();
end

diagnostic.kind = 'exception-diagnostic';
diagnostic.stage = char(stage);
diagnostic.severity = 'error';
diagnostic.identifier = ME.identifier;
diagnostic.summary = make_summary(ME, stage);
diagnostic.details = ME.message;
diagnostic.suggestions = make_suggestions(ME.identifier);
diagnostic.inputSnapshot = inputSnapshot;
diagnostic.stackSummary = make_stack_summary(ME);
end

function summary = make_summary(ME, stage)
if isempty(ME.identifier)
    idText = 'MATLAB:unknown';
else
    idText = ME.identifier;
end
summary = sprintf('%s阶段发生异常：%s', stage_display(stage), idText);
end

function suggestions = make_suggestions(identifier)
suggestions = {};
if contains_text(identifier, 'run_trim_case:InvalidParameters')
    suggestions{end+1,1} = '先修正参数检查失败项，再重新运行配平。';
elseif contains_text(identifier, 'run_trim_case:InvalidConfig')
    suggestions{end+1,1} = '检查界面工况输入是否为有限实数并处在允许范围内。';
elseif starts_with(identifier, 'trim_symmetric:')
    suggestions{end+1,1} = '检查配平输入、初值和详细错误信息。';
elseif starts_with(identifier, 'linearize_numeric:')
    suggestions{end+1,1} = '确认当前配平点有效，并检查线性化步长。';
elseif starts_with(identifier, 'rotor_model_bemt:')
    suggestions{end+1,1} = '旋翼内部求解未完成，请保留错误标识并检查当前工况。';
else
    suggestions{end+1,1} = '请记录错误标识和消息，并按当前输入重新检查。';
end
end

function stackSummary = make_stack_summary(ME)
rawStack = ME.stack;
n = min(numel(rawStack), 6);
stackSummary = repmat(struct('name', '', 'file', '', 'line', NaN), n, 1);
for k = 1:n
    stackSummary(k).name = rawStack(k).name;
    stackSummary(k).file = rawStack(k).file;
    stackSummary(k).line = rawStack(k).line;
end
end

function tf = starts_with(textValue, prefix)
tf = strncmp(char(textValue), prefix, numel(prefix));
end

function tf = contains_text(textValue, pattern)
tf = contains(char(textValue), pattern);
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
        value = '未知';
    otherwise
        value = char(stage);
end
end
