function report = validate_parameter_set(P)
%VALIDATE_PARAMETER_SET Validate the active concept-model parameter structure.
% Passing this check means the edited parameter structure is internally
% usable by the current conceptual model; it is not aircraft validation.

errors = cell(256,1);
warnings = cell(64,1);
errorCount = 0;
warningCount = 0;

catalog = build_parameter_catalog();
for k = 1:numel(catalog)
    item = catalog(k);
    [ok, value] = lookup_value(P, item.path);
    if ~ok
        add_error(sprintf('缺少参数“%s”。', item.name));
        continue;
    end
    if ~isempty(item.subscript)
        if ~valid_subscript(value, item.subscript)
            add_error(sprintf('参数“%s”的尺寸不正确。', item.name));
            continue;
        end
        if numel(item.subscript) == 1
            value = value(item.subscript(1));
        else
            value = value(item.subscript(1), item.subscript(2));
        end
    end
    check_catalog_scalar(item, value);
end

check_inertia_matrix();
check_inertia_rate();
check_control_limits();
check_linear_vectors();
check_rotor_dependencies();
check_wing_blend();
check_mass_warning();

errors = errors(1:errorCount);
warnings = warnings(1:warningCount);
report.valid = isempty(errors);
report.errors = errors;
report.warnings = warnings;
report.errorCount = errorCount;
report.warningCount = warningCount;
if report.valid
    if isempty(warnings)
        report.summary = '参数校验通过。';
    else
        report.summary = sprintf('参数校验通过，有 %d 条警告。', numel(warnings));
    end
else
    report.summary = sprintf('参数校验失败，有 %d 条错误。', numel(errors));
end

    function check_catalog_scalar(item, value)
        if ~(isnumeric(value) && isreal(value) && isscalar(value) && ...
                isfinite(value))
            add_error(sprintf('参数“%s”必须是有限实数。', item.name));
            return;
        end
        displayValue = value*item.displayScale + item.displayOffset;
        if ~within_bound(displayValue, item.minimum, ...
                item.minimumInclusive, true)
            add_error(sprintf('参数“%s”低于允许下限。', item.name));
        end
        if ~within_bound(displayValue, item.maximum, ...
                item.maximumInclusive, false)
            add_error(sprintf('参数“%s”高于允许上限。', item.name));
        end
        if item.integerRequired && value ~= round(value)
            add_error(sprintf('参数“%s”必须是整数。', item.name));
        end
        if abs(value) > 1.0e4 && ismember(item.basis, {'气动模型设定'})
            add_warning(sprintf('参数“%s”数值很大，请复核适用范围。', item.name));
        end
    end

    function check_inertia_matrix()
        [ok, I0] = lookup_value(P, {'mass','I0'});
        if ~ok || ~(isnumeric(I0) && isreal(I0) && isequal(size(I0), [3 3]) && ...
                all(isfinite(I0(:))))
            add_error('名义惯量矩阵必须是有限实数三乘三矩阵。');
            return;
        end
        symmetryError = norm(I0 - I0.', 'fro');
        if symmetryError > 1.0e-10*max(norm(I0, 'fro'), 1)
            add_error('名义惯量矩阵必须保持对称。');
            return;
        end
        if any(eig(0.5*(I0 + I0.')) <= 0)
            add_error('名义惯量矩阵必须保持正定。');
        end
    end

    function check_inertia_rate()
        [okI, I0] = lookup_value(P, {'mass','I0'});
        [okK, KI] = lookup_value(P, {'mass','KI'});
        if ~okK || ~(isnumeric(KI) && isreal(KI) && isequal(size(KI), [3 3]) && ...
                all(isfinite(KI(:))))
            add_error('倾转惯量变化率矩阵必须是有限实数三乘三矩阵。');
            return;
        end
        symmetryError = norm(KI - KI.', 'fro');
        if symmetryError > 1.0e-10*max(norm(KI, 'fro'), 1)
            add_error('倾转惯量变化率矩阵必须保持对称。');
            return;
        end
        if okI && isnumeric(I0) && isreal(I0) && isequal(size(I0), [3 3])
            betaList = [0, pi/2];
            for ib = 1:numel(betaList)
                I = I0 - betaList(ib)*KI;
                I = 0.5*(I + I.');
                if any(~isfinite(I(:))) || any(eig(I) <= 0)
                    add_error('倾转惯量变化率会导致零到九十度范围内的惯量矩阵失效。');
                    return;
                end
            end
        end
    end

    function check_control_limits()
        limitFields = {'collectiveLim','cyclicLim','aileronLim', ...
            'elevatorLim','rudderLim'};
        limitNames = {'总距','周期变距','副翼','升降舵','方向舵'};
        for i = 1:numel(limitFields)
            [ok, value] = lookup_value(P, {'control',limitFields{i}});
            if ~ok || ~(isnumeric(value) && isreal(value) && numel(value) == 2 && ...
                    all(isfinite(value(:))))
                add_error(sprintf('%s限幅必须包含两个有限实数。', ...
                    limitNames{i}));
            elseif value(1) >= value(2)
                add_error(sprintf('%s限幅必须满足下限小于上限。', ...
                    limitNames{i}));
            end
        end
    end

    function check_linear_vectors()
        check_positive_vector({'linear','dx'}, '状态差分步长', 9);
        check_positive_vector({'linear','du'}, '操纵差分步长', 7);
    end

    function check_positive_vector(pathParts, label, expectedLength)
        [ok, value] = lookup_value(P, pathParts);
        if ~ok || ~(isnumeric(value) && isreal(value) && ...
                numel(value) == expectedLength && all(isfinite(value(:))) && ...
                all(value(:) > 0))
            add_error(sprintf('%s必须包含 %d 个有限正值。', ...
                label, expectedLength));
        end
    end

    function check_rotor_dependencies()
        required = {'R','bladeMass','Ib','Sblade'};
        for i = 1:numel(required)
            if ~isfield(P.rotor, required{i})
                add_error('旋翼派生量所需参数不完整。');
                return;
            end
        end
        expectedIb = P.rotor.bladeMass*P.rotor.R^2/3;
        expectedSblade = P.rotor.bladeMass*P.rotor.R/2;
        if ~nearly_equal(P.rotor.Ib, expectedIb) || ...
                ~nearly_equal(P.rotor.Sblade, expectedSblade)
            add_error('旋翼半径或桨叶质量变化后，桨叶派生量必须同步更新。');
        end
    end

    function check_wing_blend()
        if isfield(P, 'wing') && isfield(P.wing, 'normalFlowRatio') && ...
                isfield(P.wing, 'normalFlowBlendHalfWidth')
            lower = P.wing.normalFlowRatio - P.wing.normalFlowBlendHalfWidth;
            upper = P.wing.normalFlowRatio + P.wing.normalFlowBlendHalfWidth;
            if lower < -1 || upper > 2
                add_warning('机翼近法向混合区间较宽，请复核连续化范围。');
            end
        end
    end

    function check_mass_warning()
        [okMass, totalMass] = lookup_value(P, {'mass','m'});
        [okNac, nacelleMass] = lookup_value(P, {'mass','mNac'});
        if okMass && okNac && isnumeric(totalMass) && isnumeric(nacelleMass) && ...
                isscalar(totalMass) && isscalar(nacelleMass) && ...
                isfinite(totalMass) && isfinite(nacelleMass) && ...
                nacelleMass >= totalMass
            add_warning('倾转组件总质量不应大于或等于整机总质量，请复核。');
        end
    end

    function add_error(message)
        errorCount = errorCount + 1;
        errors{errorCount,1} = message;
    end

    function add_warning(message)
        warningCount = warningCount + 1;
        warnings{warningCount,1} = message;
    end
end

function tf = within_bound(value, bound, inclusive, isLower)
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

function tf = valid_subscript(value, subscript)
sz = size(value);
if numel(subscript) == 1
    tf = numel(value) >= subscript(1);
else
    tf = numel(sz) >= 2 && sz(1) >= subscript(1) && sz(2) >= subscript(2);
end
end

function tf = nearly_equal(a, b)
tf = isnumeric(a) && isnumeric(b) && isscalar(a) && isscalar(b) && ...
    isfinite(a) && isfinite(b) && abs(a-b) <= 1.0e-10*max(1, abs(b));
end

function [ok, value] = lookup_value(S, pathParts)
value = S;
ok = true;
for k = 1:numel(pathParts)
    if ~isstruct(value) || ~isfield(value, pathParts{k})
        ok = false;
        value = [];
        return;
    end
    value = value.(pathParts{k});
end
end
