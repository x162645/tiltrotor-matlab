function report = check_gui_parameter_catalog()
%CHECK_GUI_PARAMETER_CATALOG Focused checks for Stage 2 parameter services.

tStart = tic;
names = {};
passed = [];
details = {};

run_check('目录数量严格为139', @check_count);
run_check('ID唯一且稳定', @check_ids);
run_check('类别数量符合审计结果', @check_category_counts);
run_check('用户可见字段完整', @check_user_fields);
run_check('用户可见字段不含禁止词', @check_forbidden_words);
run_check('排除字段不存在', @check_exclusions);
run_check('全部条目读取为有限实数', @check_read_all);
run_check('全部条目写回原值不改变结构', @check_write_original);
run_check('每个类别可修改并恢复一个参数', @check_category_edits);
run_check('旋翼半径依赖更新正确', @check_rotor_radius_dependency);
run_check('桨叶质量依赖更新正确', @check_blade_mass_dependency);
run_check('惯量矩阵镜像正确', @check_inertia_mirror);
run_check('非正定惯量矩阵被拒绝', @check_bad_inertia_rejected);
run_check('非法倾转惯量变化率被拒绝', @check_bad_ki_rejected);
run_check('操纵上下限错误被拒绝', @check_bad_limit_rejected);
run_check('整数参数非法值被拒绝', @check_bad_integer_rejected);
run_check('角度单位往返转换正确', @check_angle_round_trip);
run_check('线性化状态步长独立写入', @check_dx_independent);
run_check('线性化操纵步长独立写入', @check_du_independent);
run_check('搜索类别和修改筛选正确', @check_filtering);
run_check('默认参数通过扩展校验', @check_default_validation);

report.names = names(:);
report.passed = passed(:);
report.details = details(:);
report.passCount = sum(report.passed);
report.failCount = numel(report.passed) - report.passCount;
report.allPassed = all(report.passed);
report.runtimeSeconds = toc(tStart);

    function run_check(name, fcn)
        names{end+1,1} = name;
        try
            fcn();
            passed(end+1,1) = true;
            details{end+1,1} = 'passed';
        catch ME
            passed(end+1,1) = false;
            details{end+1,1} = ME.message;
        end
    end
end

function check_count()
catalog = build_parameter_catalog();
assert(numel(catalog) == 139, '目录数量为 %d，不是139。', numel(catalog));
end

function check_ids()
c1 = build_parameter_catalog();
c2 = build_parameter_catalog();
ids1 = {c1.id}.';
ids2 = {c2.id}.';
assert(isequal(ids1, ids2), '目录排序不稳定。');
assert(numel(unique(ids1)) == numel(ids1), '目录ID存在重复。');
end

function check_category_counts()
catalog = build_parameter_catalog();
allowed = {'环境','整机质量与惯量','倾转机构','旋翼几何','旋翼运行', ...
    '旋翼气动','旋翼入流与挥舞','机翼','机身','平尾','垂尾', ...
    '操纵系统','配平计算','线性化计算','响应计算'};
categories = {catalog.category};
for k = 1:numel(categories)
    assert(any(strcmp(categories{k}, allowed)), ...
        '存在未批准分类：%s。', categories{k});
end
required = {'环境','整机质量与惯量','倾转机构','旋翼几何','旋翼气动', ...
    '旋翼入流与挥舞','机翼','机身','平尾','垂尾','操纵系统', ...
    '配平计算','线性化计算'};
for k = 1:numel(required)
    assert(any(strcmp(categories, required{k})), ...
        '缺少分类：%s。', required{k});
end
end

function check_user_fields()
catalog = build_parameter_catalog();
for k = 1:numel(catalog)
    item = catalog(k);
    assert(~isempty(item.category), '类别为空。');
    assert(~isempty(item.name), '名称为空。');
    assert(~isempty(item.description), '说明为空。');
    assert(~isempty(item.basis), '依据为空。');
    assert(~isempty(item.displayUnit), '显示单位为空。');
end
end

function check_forbidden_words()
catalog = build_parameter_catalog();
forbidden = {'ASSUMED_CONCEPT','NUMERICAL','REFERENCE_CONSTANT', ...
    'reason code','Stage 1','Stage 2','Git','PR','内部字段路径'};
forbidden = [forbidden, forbidden_classification_words()];
fields = {'category','name','description','basis','displayUnit'};
for k = 1:numel(catalog)
    for i = 1:numel(fields)
        text = catalog(k).(fields{i});
        for j = 1:numel(forbidden)
            assert(~contains(text, forbidden{j}), ...
                '用户可见字段包含禁止词：%s。', forbidden{j});
        end
    end
end
end

function check_exclusions()
catalog = build_parameter_catalog();
ids = {catalog.id}.';
paths = cell(numel(catalog),1);
for k = 1:numel(catalog)
    paths{k} = strjoin(catalog(k).path, '.');
end
excluded = {'mass.RH','rotor.inflowHarmonic','rotor.flapCyclicGain', ...
    'rotor.flapMuGain','rotor.flapLatMuGain','rotor.flapQGain', ...
    'rotor.flapPGain','rotor.flapMax','rotor.Ib','rotor.Sblade', ...
    'rotor.flapInitial','wing.b','vtail.c','bladeMassDistribution', ...
    'trim.display'};
for k = 1:numel(excluded)
    assert(~any(strcmp(ids, excluded{k})), '排除ID仍存在。');
    assert(~any(strcmp(paths, excluded{k})), '排除路径仍存在。');
end
assert(~any(strcmp(ids, 'mass.I0.Iyx')), '惯量矩阵重复项仍存在。');
assert(~any(strcmp(ids, 'mass.KI.KIxy')), '倾转惯量变化率非对角项仍存在。');
end

function check_read_all()
P = params_nominal();
catalog = build_parameter_catalog();
for k = 1:numel(catalog)
    value = get_parameter_catalog_value(P, catalog(k));
    assert(isnumeric(value) && isreal(value) && isscalar(value) && ...
        isfinite(value), '读取值非法：%s。', catalog(k).id);
end
end

function check_write_original()
P = params_nominal();
catalog = build_parameter_catalog();
for k = 1:numel(catalog)
    value = get_parameter_catalog_value(P, catalog(k));
    [P2, result] = set_parameter_catalog_value(P, catalog(k), value);
    assert(result.success, '原值写回失败：%s。%s', catalog(k).id, result.message);
    assert(isequaln(P2, P), '原值写回改变结构：%s。', catalog(k).id);
end
end

function check_category_edits()
samples = {'env.rho','mass.m','rotor.chord','wing.S','fuselage.S', ...
    'htail.S','vtail.SEach','control.aileronLim.upper', ...
    'trim.maxIterations','linear.stabilityTolerance'};
for k = 1:numel(samples)
    P = params_nominal();
    item = find_item(samples{k});
    oldValue = get_parameter_catalog_value(P, item);
    if item.integerRequired
        newValue = oldValue + 1;
    else
        newValue = oldValue + max(abs(oldValue)*0.01, 1.0e-6);
    end
    [P2, result] = set_parameter_catalog_value(P, item, newValue);
    assert(result.success, '修改失败：%s。', samples{k});
    changed = get_parameter_catalog_value(P2, item);
    assert(abs(changed-newValue) < 1.0e-10*max(1, abs(newValue)), ...
        '修改后读数不一致：%s。', samples{k});
    [P3, result] = set_parameter_catalog_value(P2, item, oldValue);
    assert(result.success, '恢复失败：%s。', samples{k});
    assert(isequaln(P3, P), '恢复后结构不一致：%s。', samples{k});
end
end

function check_rotor_radius_dependency()
P = params_nominal();
item = find_item('rotor.R');
[P2, result] = set_parameter_catalog_value(P, item, P.rotor.R + 0.1);
assert(result.success, '旋翼半径修改失败。');
assert(abs(P2.rotor.Ib - P2.rotor.bladeMass*P2.rotor.R^2/3) < 1e-10, ...
    'Ib 未同步。');
assert(abs(P2.rotor.Sblade - P2.rotor.bladeMass*P2.rotor.R/2) < 1e-10, ...
    'Sblade 未同步。');
end

function check_blade_mass_dependency()
P = params_nominal();
item = find_item('rotor.bladeMass');
[P2, result] = set_parameter_catalog_value(P, item, P.rotor.bladeMass + 1);
assert(result.success, '桨叶质量修改失败。');
assert(abs(P2.rotor.Ib - P2.rotor.bladeMass*P2.rotor.R^2/3) < 1e-10, ...
    'Ib 未同步。');
assert(abs(P2.rotor.Sblade - P2.rotor.bladeMass*P2.rotor.R/2) < 1e-10, ...
    'Sblade 未同步。');
end

function check_inertia_mirror()
P = params_nominal();
item = find_item('mass.I0.Ixy');
[P2, result] = set_parameter_catalog_value(P, item, 12);
assert(result.success, '惯量积修改失败。');
assert(P2.mass.I0(1,2) == 12 && P2.mass.I0(2,1) == 12, ...
    '惯量矩阵未镜像。');
end

function check_bad_inertia_rejected()
P = params_nominal();
item = find_item('mass.I0.Ixx');
[P2, result] = set_parameter_catalog_value(P, item, -1);
assert(~result.success, '非正定惯量矩阵未被拒绝。');
assert(isequaln(P2, P), '失败写入改变了原结构。');
end

function check_bad_ki_rejected()
P = params_nominal();
item = find_item('mass.KI.KIzz');
[P2, result] = set_parameter_catalog_value(P, item, 1.0e6);
assert(~result.success, '非法倾转惯量变化率未被拒绝。');
assert(isequaln(P2, P), '失败写入改变了原结构。');
end

function check_bad_limit_rejected()
P = params_nominal();
item = find_item('control.collectiveLim.lower');
[P2, result] = set_parameter_catalog_value(P, item, 100);
assert(~result.success, '操纵限幅顺序错误未被拒绝。');
assert(isequaln(P2, P), '失败写入改变了原结构。');
end

function check_bad_integer_rejected()
P = params_nominal();
item = find_item('rotor.nRadial');
[P2, result] = set_parameter_catalog_value(P, item, 12.5);
assert(~result.success, '非法整数未被拒绝。');
assert(isequaln(P2, P), '失败写入改变了原结构。');
end

function check_angle_round_trip()
P = params_nominal();
item = find_item('rotor.twistTip');
[P2, result] = set_parameter_catalog_value(P, item, -5);
assert(result.success, '角度写入失败。');
assert(abs(P2.rotor.twistTip - (-5*pi/180)) < 1e-14, '角度内部转换错误。');
value = get_parameter_catalog_value(P2, item);
assert(abs(value + 5) < 1e-12, '角度显示转换错误。');
end

function check_dx_independent()
P = params_nominal();
item = find_item('linear.dx.phi');
old = P.linear.dx;
[P2, result] = set_parameter_catalog_value(P, item, 0.02);
assert(result.success, '状态差分步长写入失败。');
changed = find(abs(P2.linear.dx - old) > 0);
assert(isequal(changed(:), 7), '状态差分步长影响了其他通道。');
assert(abs(P2.linear.dx(7) - 0.02*pi/180) < 1e-14, '状态角度步长转换错误。');
end

function check_du_independent()
P = params_nominal();
item = find_item('linear.du.rudder');
old = P.linear.du;
[P2, result] = set_parameter_catalog_value(P, item, 0.02);
assert(result.success, '操纵差分步长写入失败。');
changed = find(abs(P2.linear.du - old) > 0);
assert(isequal(changed(:), 7), '操纵差分步长影响了其他通道。');
assert(abs(P2.linear.du(7) - 0.02*pi/180) < 1e-14, '操纵角度步长转换错误。');
end

function check_filtering()
catalog = build_parameter_catalog();
filtered = filter_parameter_catalog(catalog, struct('category','环境'));
assert(numel(filtered) == 2, '类别筛选错误。');
filtered = filter_parameter_catalog(catalog, struct('query','空气'));
assert(any(strcmp({filtered.id}, 'env.rho')), '中文搜索错误。');
filtered = filter_parameter_catalog(catalog, struct('query','clmax'));
assert(any(strcmp({filtered.id}, 'rotor.CLmax')), '英文搜索错误。');
filtered = filter_parameter_catalog(catalog, struct( ...
    'modifiedOnly', true, 'modifiedIds', {{'rotor.R','wing.S'}}));
assert(numel(filtered) == 2 && all(ismember({filtered.id}, {'rotor.R','wing.S'})), ...
    '修改筛选错误。');
end

function check_default_validation()
report = validate_parameter_set(params_nominal());
assert(report.valid, '%s', report.summary);
end

function item = find_item(id)
catalog = build_parameter_catalog();
idx = find(strcmp({catalog.id}, id), 1);
assert(~isempty(idx), '找不到目录项：%s。', id);
item = catalog(idx);
end

function words = forbidden_classification_words()
words = {char([24120 29992]), char([39640 32423]), ...
    char([19987 23478]), char([20840 37096 23618 32423]), ...
    char([21442 25968 23618 32423])};
end
