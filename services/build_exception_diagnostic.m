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
summary = sprintf('%s 阶段发生异常：%s', char(stage), idText);
end

function suggestions = make_suggestions(identifier)
suggestions = {};
if contains_text(identifier, 'run_trim_case:InvalidParameters')
    suggestions{end+1,1} = '先修正参数检查失败项，再重新运行配平。';
elseif contains_text(identifier, 'run_trim_case:InvalidConfig')
    suggestions{end+1,1} = '检查界面工况输入是否为有限实数并处在允许范围内。';
elseif starts_with(identifier, 'trim_symmetric:')
    suggestions{end+1,1} = '该异常来自对称配平入口；检查配平输入、初值和底层 report。';
elseif starts_with(identifier, 'linearize_numeric:')
    suggestions{end+1,1} = '该异常来自数值线性化；确认当前配平点有效且扰动步长有限。';
elseif starts_with(identifier, 'rotor_model_bemt:')
    suggestions{end+1,1} = '该异常来自旋翼 BEMT/挥舞内部求解；保留标识用于定位模型域或迭代失败。';
elseif contains_text(identifier, 'mwboost') || contains_text(identifier, 'archive')
    suggestions{end+1,1} = '若该错误只在 batch 断言完成后关机阶段出现，应在测试报告中单独记录，不作为模型计算失败。';
else
    suggestions{end+1,1} = '保留错误标识和消息，按当前阶段输入逐项复现并定位。';
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
