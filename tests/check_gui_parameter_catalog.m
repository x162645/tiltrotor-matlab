function report = check_gui_parameter_catalog()
%CHECK_GUI_PARAMETER_CATALOG Focused checks for Stage 2 parameter services.

tStart = tic;
names = {};
passed = [];
details = {};

run_check('catalog count is 142', @check_count);
run_check('IDs are unique and stable', @check_ids);
run_check('category set matches audit', @check_category_counts);
run_check('user-visible fields are complete', @check_user_fields);
run_check('user-visible fields avoid forbidden words', @check_forbidden_words);
run_check('excluded fields are absent', @check_exclusions);
run_check('all catalog values read as finite real scalars', @check_read_all);
run_check('writing original values preserves structure', @check_write_original);
run_check('one editable item per category can be restored', @check_category_edits);
run_check('rotor radius dependencies update', @check_rotor_radius_dependency);
run_check('blade mass dependencies update', @check_blade_mass_dependency);
run_check('inertia matrix mirroring works', @check_inertia_mirror);
run_check('non-positive-definite inertia is rejected', @check_bad_inertia_rejected);
run_check('invalid tilt inertia rate is rejected', @check_bad_ki_rejected);
run_check('bad control limits are rejected', @check_bad_limit_rejected);
run_check('bad integer values are rejected', @check_bad_integer_rejected);
run_check('angle unit round trip is correct', @check_angle_round_trip);
run_check('linearization state step writes independently', @check_dx_independent);
run_check('linearization control step writes independently', @check_du_independent);
run_check('search/category/modified filters work', @check_filtering);
run_check('default parameters pass validation', @check_default_validation);

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
assert(numel(catalog) == 142, 'Catalog count is %d, expected 142.', numel(catalog));
end

function check_ids()
c1 = build_parameter_catalog();
c2 = build_parameter_catalog();
ids1 = {c1.id}.';
ids2 = {c2.id}.';
assert(isequal(ids1, ids2), 'Catalog order is unstable.');
assert(numel(unique(ids1)) == numel(ids1), 'Catalog IDs are not unique.');
end

function check_category_counts()
catalog = build_parameter_catalog();
allowed = {u([29615 22659]), u([25972 26426 36136 37327 19982 24815 37327]), ...
    u([20542 36716 26426 26500]), u([26059 32764 20960 20309]), ...
    u([26059 32764 36816 34892]), u([26059 32764 27668 21160]), ...
    u([26059 32764 20837 27969 19982 25381 33310]), u([26426 32764]), ...
    u([26426 36523]), u([24179 23614]), u([22402 23614]), ...
    u([25805 32437 31995 32479]), u([37197 24179 35745 31639]), ...
    u([32447 24615 21270 35745 31639]), u([21709 24212 35745 31639])};
categories = {catalog.category};
for k = 1:numel(categories)
    assert(any(strcmp(categories{k}, allowed)), ...
        'Unexpected category: %s.', categories{k});
end
required = {u([29615 22659]), u([25972 26426 36136 37327 19982 24815 37327]), ...
    u([20542 36716 26426 26500]), u([26059 32764 20960 20309]), ...
    u([26059 32764 27668 21160]), u([26059 32764 20837 27969 19982 25381 33310]), ...
    u([26426 32764]), u([26426 36523]), u([24179 23614]), u([22402 23614]), ...
    u([25805 32437 31995 32479]), u([37197 24179 35745 31639]), ...
    u([32447 24615 21270 35745 31639])};
for k = 1:numel(required)
    assert(any(strcmp(categories, required{k})), ...
        'Missing category: %s.', required{k});
end
end

function check_user_fields()
catalog = build_parameter_catalog();
for k = 1:numel(catalog)
    item = catalog(k);
    assert(~isempty(item.category), 'Category is empty.');
    assert(~isempty(item.name), 'Name is empty.');
    assert(~isempty(item.description), 'Description is empty.');
    assert(~isempty(item.basis), 'Basis is empty.');
    assert(~isempty(item.displayUnit), 'Display unit is empty.');
end
end

function check_forbidden_words()
catalog = build_parameter_catalog();
forbidden = {'ASSUMED_CONCEPT','NUMERICAL','REFERENCE_CONSTANT', ...
    'reason code','Stage 1','Stage 2','Git','PR',u([20869 37096 23383 27573 36335 24452])};
forbidden = [forbidden, forbidden_classification_words()];
fields = {'category','name','description','basis','displayUnit'};
for k = 1:numel(catalog)
    for i = 1:numel(fields)
        text = catalog(k).(fields{i});
        for j = 1:numel(forbidden)
            assert(~contains(text, forbidden{j}), ...
                'User-visible field contains forbidden word: %s.', forbidden{j});
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
    assert(~any(strcmp(ids, excluded{k})), 'Excluded ID still exists.');
    assert(~any(strcmp(paths, excluded{k})), 'Excluded path still exists.');
end
assert(~any(strcmp(ids, 'mass.I0.Iyx')), 'Duplicated inertia matrix item still exists.');
assert(~any(strcmp(ids, 'mass.KI.KIxy')), 'Non-diagonal KI item still exists.');
end

function check_read_all()
P = params_nominal();
catalog = build_parameter_catalog();
for k = 1:numel(catalog)
    value = get_parameter_catalog_value(P, catalog(k));
    assert(isnumeric(value) && isreal(value) && isscalar(value) && ...
        isfinite(value), 'Invalid catalog value: %s.', catalog(k).id);
end
end

function check_write_original()
P = params_nominal();
catalog = build_parameter_catalog();
for k = 1:numel(catalog)
    value = get_parameter_catalog_value(P, catalog(k));
    [P2, result] = set_parameter_catalog_value(P, catalog(k), value);
    assert(result.success, 'Original value write failed: %s. %s', ...
        catalog(k).id, result.message);
    assert(isequaln(P2, P), 'Original value write changed structure: %s.', ...
        catalog(k).id);
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
    assert(result.success, 'Edit failed: %s.', samples{k});
    changed = get_parameter_catalog_value(P2, item);
    assert(abs(changed-newValue) < 1.0e-10*max(1, abs(newValue)), ...
        'Edited value readback mismatch: %s.', samples{k});
    [P3, result] = set_parameter_catalog_value(P2, item, oldValue);
    assert(result.success, 'Restore failed: %s.', samples{k});
    assert(isequaln(P3, P), 'Restored structure mismatch: %s.', samples{k});
end
end

function check_rotor_radius_dependency()
P = params_nominal();
item = find_item('rotor.R');
[P2, result] = set_parameter_catalog_value(P, item, P.rotor.R + 0.1);
assert(result.success, 'Rotor radius edit failed.');
assert(abs(P2.rotor.Ib - P2.rotor.bladeMass*P2.rotor.R^2/3) < 1e-10, ...
    'Ib did not update.');
assert(abs(P2.rotor.Sblade - P2.rotor.bladeMass*P2.rotor.R/2) < 1e-10, ...
    'Sblade did not update.');
end

function check_blade_mass_dependency()
P = params_nominal();
item = find_item('rotor.bladeMass');
[P2, result] = set_parameter_catalog_value(P, item, P.rotor.bladeMass + 1);
assert(result.success, 'Blade mass edit failed.');
assert(abs(P2.rotor.Ib - P2.rotor.bladeMass*P2.rotor.R^2/3) < 1e-10, ...
    'Ib did not update.');
assert(abs(P2.rotor.Sblade - P2.rotor.bladeMass*P2.rotor.R/2) < 1e-10, ...
    'Sblade did not update.');
end

function check_inertia_mirror()
P = params_nominal();
item = find_item('mass.I0.Ixy');
[P2, result] = set_parameter_catalog_value(P, item, 12);
assert(result.success, 'Inertia product edit failed.');
assert(P2.mass.I0(1,2) == 12 && P2.mass.I0(2,1) == 12, ...
    'Inertia matrix did not mirror.');
end

function check_bad_inertia_rejected()
P = params_nominal();
item = find_item('mass.I0.Ixx');
[P2, result] = set_parameter_catalog_value(P, item, -1);
assert(~result.success, 'Non-positive-definite inertia was not rejected.');
assert(isequaln(P2, P), 'Failed write changed original structure.');
end

function check_bad_ki_rejected()
P = params_nominal();
item = find_item('mass.KI.KIzz');
[P2, result] = set_parameter_catalog_value(P, item, 1.0e6);
assert(~result.success, 'Invalid KI was not rejected.');
assert(isequaln(P2, P), 'Failed write changed original structure.');
end

function check_bad_limit_rejected()
P = params_nominal();
item = find_item('control.collectiveLim.lower');
[P2, result] = set_parameter_catalog_value(P, item, 100);
assert(~result.success, 'Bad control limit order was not rejected.');
assert(isequaln(P2, P), 'Failed write changed original structure.');
end

function check_bad_integer_rejected()
P = params_nominal();
item = find_item('rotor.nRadial');
[P2, result] = set_parameter_catalog_value(P, item, 12.5);
assert(~result.success, 'Bad integer value was not rejected.');
assert(isequaln(P2, P), 'Failed write changed original structure.');
end

function check_angle_round_trip()
P = params_nominal();
item = find_item('rotor.twistTip');
[P2, result] = set_parameter_catalog_value(P, item, -5);
assert(result.success, 'Angle write failed.');
assert(abs(P2.rotor.twistTip - (-5*pi/180)) < 1e-14, ...
    'Angle internal conversion failed.');
value = get_parameter_catalog_value(P2, item);
assert(abs(value + 5) < 1e-12, 'Angle display conversion failed.');
end

function check_dx_independent()
P = params_nominal();
item = find_item('linear.dx.phi');
old = P.linear.dx;
[P2, result] = set_parameter_catalog_value(P, item, 0.02);
assert(result.success, 'State step write failed.');
changed = find(abs(P2.linear.dx - old) > 0);
assert(isequal(changed(:), 7), 'State step write affected other channels.');
assert(abs(P2.linear.dx(7) - 0.02*pi/180) < 1e-14, ...
    'State angle step conversion failed.');
end

function check_du_independent()
P = params_nominal();
item = find_item('linear.du.rudder');
old = P.linear.du;
[P2, result] = set_parameter_catalog_value(P, item, 0.02);
assert(result.success, 'Control step write failed.');
changed = find(abs(P2.linear.du - old) > 0);
assert(isequal(changed(:), 7), 'Control step write affected other channels.');
assert(abs(P2.linear.du(7) - 0.02*pi/180) < 1e-14, ...
    'Control angle step conversion failed.');
end

function check_filtering()
catalog = build_parameter_catalog();
filtered = filter_parameter_catalog(catalog, struct('category',u([29615 22659])));
assert(numel(filtered) == 2, 'Category filter failed.');
filtered = filter_parameter_catalog(catalog, struct('query',u([31354 27668])));
assert(any(strcmp({filtered.id}, 'env.rho')), 'Chinese search failed.');
filtered = filter_parameter_catalog(catalog, struct('query','clmax'));
assert(any(strcmp({filtered.id}, 'rotor.CLmax')), 'English search failed.');
filtered = filter_parameter_catalog(catalog, struct( ...
    'modifiedOnly', true, 'modifiedIds', {{'rotor.R','wing.S'}}));
assert(numel(filtered) == 2 && all(ismember({filtered.id}, {'rotor.R','wing.S'})), ...
    'Modified filter failed.');
end

function check_default_validation()
report = validate_parameter_set(params_nominal());
assert(report.valid, '%s', report.summary);
end

function item = find_item(id)
catalog = build_parameter_catalog();
idx = find(strcmp({catalog.id}, id), 1);
assert(~isempty(idx), 'Catalog item not found: %s.', id);
item = catalog(idx);
end

function words = forbidden_classification_words()
words = {char([24120 29992]), char([39640 32423]), ...
    char([19987 23478]), char([20840 37096 23618 32423]), ...
    char([21442 25968 23618 32423])};
end

function text = u(codes)
text = char(codes);
end
