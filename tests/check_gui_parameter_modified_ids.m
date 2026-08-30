function report = check_gui_parameter_modified_ids()
%CHECK_GUI_PARAMETER_MODIFIED_IDS Focused checks for parameter dirty-state service.

tStart = tic;
names = {};
passed = [];
details = {};

run_check('相同参数集返回空集合', @check_identical_empty);
run_check('单个普通标量修改', @check_single_scalar);
run_check('角度参数按内部单位比较', @check_angle_parameter);
run_check('修改后恢复会移除ID', @check_restore_removes_id);
run_check('惯量矩阵独立分量修改', @check_i0_component);
run_check('旋翼派生量不产生修改ID', @check_rotor_derived_ignored);
run_check('容差内浮点扰动不标记', @check_tolerance);
run_check('多项修改保持目录顺序', @check_catalog_order);
run_check('修改筛选消费服务输出', @check_filter_integration);
run_check('倾转惯量变化率必须对称', @check_ki_symmetry_validation);

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

function check_identical_empty()
P = params_nominal();
ids = get_modified_parameter_ids(P, P);
assert_ids(ids, {});
end

function check_single_scalar()
baseline = params_nominal();
item = find_item('env.rho');
[P, result] = set_parameter_catalog_value(baseline, item, baseline.env.rho + 0.01);
assert(result.success, result.message);
assert_ids(get_modified_parameter_ids(P, baseline), {'env.rho'});
end

function check_angle_parameter()
baseline = params_nominal();
item = find_item('control.rudderLim.lower');
oldDisplay = get_parameter_catalog_value(baseline, item);
[P, result] = set_parameter_catalog_value(baseline, item, oldDisplay - 1);
assert(result.success, result.message);
assert_ids(get_modified_parameter_ids(P, baseline), {'control.rudderLim.lower'});
end

function check_restore_removes_id()
baseline = params_nominal();
item = find_item('wing.S');
oldDisplay = get_parameter_catalog_value(baseline, item);
[P, result] = set_parameter_catalog_value(baseline, item, oldDisplay + 0.1);
assert(result.success, result.message);
assert_ids(get_modified_parameter_ids(P, baseline), {'wing.S'});
[P, result] = set_parameter_catalog_value(P, item, oldDisplay);
assert(result.success, result.message);
assert_ids(get_modified_parameter_ids(P, baseline), {});
end

function check_i0_component()
baseline = params_nominal();
item = find_item('mass.I0.Ixz');
oldDisplay = get_parameter_catalog_value(baseline, item);
[P, result] = set_parameter_catalog_value(baseline, item, oldDisplay + 1);
assert(result.success, result.message);
assert(P.mass.I0(1,3) == P.mass.I0(3,1), '惯量矩阵未镜像。');
assert_ids(get_modified_parameter_ids(P, baseline), {'mass.I0.Ixz'});
end

function check_rotor_derived_ignored()
baseline = params_nominal();
item = find_item('rotor.R');
[P, result] = set_parameter_catalog_value(baseline, item, baseline.rotor.R + 0.1);
assert(result.success, result.message);
assert(abs(P.rotor.Ib - P.rotor.bladeMass*P.rotor.R^2/3) < 1e-10);
assert(abs(P.rotor.Sblade - P.rotor.bladeMass*P.rotor.R/2) < 1e-10);
assert_ids(get_modified_parameter_ids(P, baseline), {'rotor.R'});

item = find_item('rotor.bladeMass');
[P, result] = set_parameter_catalog_value(baseline, item, baseline.rotor.bladeMass + 1);
assert(result.success, result.message);
assert(abs(P.rotor.Ib - P.rotor.bladeMass*P.rotor.R^2/3) < 1e-10);
assert(abs(P.rotor.Sblade - P.rotor.bladeMass*P.rotor.R/2) < 1e-10);
assert_ids(get_modified_parameter_ids(P, baseline), {'rotor.bladeMass'});
end

function check_tolerance()
baseline = params_nominal();
P = baseline;
P.env.rho = P.env.rho + 5.0e-13;
assert_ids(get_modified_parameter_ids(P, baseline), {});
P.env.rho = P.env.rho + 5.0e-9;
assert_ids(get_modified_parameter_ids(P, baseline), {'env.rho'});
end

function check_catalog_order()
baseline = params_nominal();
P = baseline;
[P, result] = set_parameter_catalog_value(P, find_item('linear.du.rudder'), 0.02);
assert(result.success, result.message);
[P, result] = set_parameter_catalog_value(P, find_item('wing.S'), baseline.wing.S + 0.1);
assert(result.success, result.message);
[P, result] = set_parameter_catalog_value(P, find_item('env.g'), baseline.env.g + 0.01);
assert(result.success, result.message);
assert_ids(get_modified_parameter_ids(P, baseline), ...
    {'env.g','wing.S','linear.du.rudder'});
end

function check_filter_integration()
baseline = params_nominal();
catalog = build_parameter_catalog();
[P, result] = set_parameter_catalog_value(baseline, find_item('rotor.chord'), ...
    baseline.rotor.chord + 0.01);
assert(result.success, result.message);
ids = get_modified_parameter_ids(P, baseline, catalog);
filtered = filter_parameter_catalog(catalog, struct( ...
    'modifiedOnly', true, 'modifiedIds', {ids}));
assert(numel(filtered) == 1 && strcmp(filtered(1).id, 'rotor.chord'), ...
    '修改筛选未消费服务输出。');
end

function check_ki_symmetry_validation()
P = params_nominal();
P.mass.KI(1,2) = 1;
report = validate_parameter_set(P);
assert(~report.valid, '非对称倾转惯量变化率矩阵未被拒绝。');
assert(any(contains(report.errors, '倾转惯量变化率矩阵必须保持对称')), ...
    '缺少倾转惯量变化率对称性错误。');
end

function item = find_item(id)
catalog = build_parameter_catalog();
idx = find(strcmp({catalog.id}, id), 1);
assert(~isempty(idx), '找不到目录项：%s。', id);
item = catalog(idx);
end

function assert_ids(actual, expected)
actual = reshape(actual, numel(actual), 1);
expected = reshape(expected, numel(expected), 1);
assert(isequal(actual, expected), '修改ID不一致。');
end
