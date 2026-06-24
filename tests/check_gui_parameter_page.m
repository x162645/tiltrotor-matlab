function report = check_gui_parameter_page()
%CHECK_GUI_PARAMETER_PAGE Focused checks for the Stage 3 GUI parameter page.

tStart = tic;
names = {};
passed = [];
details = {};

fig = launch_tiltrotor_app();
cleanup = onCleanup(@() close_if_valid(fig));
drawnow;
api = getappdata(fig,'ParameterWorkbenchApi');

run_check('GUI loads 139 catalog items', @check_catalog_count);
run_check('parameter page has no user-rank controls or columns', @check_no_rank_ui);
run_check('category names are approved physical or module groups', @check_category_counts);
run_check('staged edit is retained before apply', @check_staged_edit);
run_check('legal scalar edit updates current parameters', @check_scalar_edit);
run_check('deg display writes back as rad internally', @check_angle_edit);
run_check('integer edit is accepted', @check_integer_edit);
run_check('invalid edit is rejected and rolled back', @check_invalid_rollback);
run_check('failed write leaves all GUI states unchanged', @check_failed_state_unchanged);
run_check('single edit produces the expected modified id', @check_single_modified_id);
run_check('multiple edits preserve catalog order', @check_modified_order);
run_check('restoring baseline value removes modified mark', @check_restore_removes_mark);
run_check('undo all restores baseline', @check_undo_all);
run_check('rotor radius updates derived quantities', @check_rotor_radius_derived);
run_check('blade mass updates derived quantities', @check_blade_mass_derived);
run_check('I0 cross inertia mirrors symmetric element', @check_i0_mirror);
run_check('KI validation rejects invalid inertia rate', @check_ki_validation);
run_check('control lower and upper limits are validated', @check_control_limits);
run_check('combined category query modified filtering works', @check_combined_filter);
run_check('excluded items are not shown', @check_exclusions);
run_check('baseline is not overwritten by normal edits', @check_baseline_stable);
run_check('trim linearization and response tabs still exist', @check_analysis_tabs);
run_check('tilt angle UI text is unambiguous', @check_tilt_angle_text);

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
            api.resetAll();
            fcn();
            passed(end+1,1) = true;
            details{end+1,1} = 'passed';
        catch ME
            passed(end+1,1) = false;
            details{end+1,1} = ME.message;
        end
    end

    function check_catalog_count()
        state = api.getState();
        assert(numel(state.parameterCatalog) == 139, 'Catalog count is not 139.');
        assert(size(state.tableData,1) == 139, 'Parameter table does not show 139 rows.');
    end

    function check_no_rank_ui()
        state = api.getState();
        forbiddenColumn = char([23618 32423]);
        assert(~any(strcmp(state.tableData(1,:), forbiddenColumn)), ...
            'Table exposes a user-rank column.');
        oldFilter = [char([116 105 101 114]) 'FilterDrop'];
        assert(~isfield(api.handles, oldFilter), ...
            'User-rank filter handle still exists.');
        catalog = state.parameterCatalog;
        oldField = char([116 105 101 114]);
        assert(~isfield(catalog, oldField), 'Catalog still contains user-rank field.');
    end

    function check_category_counts()
        catalog = api.getState().parameterCatalog;
        allowed = {'环境','整机质量与惯量','倾转机构','旋翼几何','旋翼运行', ...
            '旋翼气动','旋翼入流与挥舞','机翼','机身','平尾','垂尾', ...
            '操纵系统','配平计算','线性化计算','响应计算'};
        for k = 1:numel(catalog)
            assert(any(strcmp(catalog(k).category, allowed)), ...
                'Unapproved category: %s.', catalog(k).category);
        end
    end

    function check_staged_edit()
        baseline = api.getState().baselineP;
        result = api.stageEditById('env.rho', baseline.env.rho + 0.02);
        assert(result.success, result.message);
        state = api.getState();
        assert(abs(state.currentP.env.rho - baseline.env.rho) < 1e-12, ...
            'Staged edit was applied immediately.');
        assert(isfield(state.pendingEdits, 'env_rho'), 'Pending edit was not retained.');
        result = api.applyPending();
        assert(result.success, result.message);
        assert(abs(api.getState().currentP.env.rho - (baseline.env.rho + 0.02)) < 1e-12);
    end

    function check_scalar_edit()
        baseline = api.getState().baselineP;
        result = api.editById('env.rho', baseline.env.rho + 0.01);
        assert(result.success, result.message);
        state = api.getState();
        assert(abs(state.currentP.env.rho - (baseline.env.rho + 0.01)) < 1e-12);
    end

    function check_angle_edit()
        state0 = api.getState();
        item = find_item(state0.parameterCatalog, 'rotor.twistTip');
        oldDisplay = get_parameter_catalog_value(state0.currentP, item);
        result = api.editById('rotor.twistTip', oldDisplay + 1);
        assert(result.success, result.message);
        state = api.getState();
        assert(abs(state.currentP.rotor.twistTip - ...
            (state0.currentP.rotor.twistTip + pi/180)) < 1e-12);
    end

    function check_integer_edit()
        baseline = api.getState().baselineP;
        result = api.editById('rotor.nRadial', baseline.rotor.nRadial + 1);
        assert(result.success, result.message);
        assert(api.getState().currentP.rotor.nRadial == baseline.rotor.nRadial + 1);
    end

    function check_invalid_rollback()
        before = api.getState();
        result = api.editById('rotor.R', -1);
        assert(~result.success, 'Invalid radius was accepted.');
        after = api.getState();
        assert(isequaln(after.currentP, before.currentP), 'currentP changed after invalid edit.');
        assert(size(after.tableData,1) == 139, 'Table did not refresh after rollback.');
    end

    function check_failed_state_unchanged()
        before = api.getState();
        result = api.editById('rotor.nRadial', 12.5);
        assert(~result.success, 'Non-integer value was accepted.');
        after = api.getState();
        assert(isequaln(after.currentP, before.currentP), 'currentP changed after failure.');
        assert(isequaln(after.baselineP, before.baselineP), 'baselineP changed after failure.');
        assert(isequal(after.modifiedIds, before.modifiedIds), 'modifiedIds changed after failure.');
    end

    function check_single_modified_id()
        baseline = api.getState().baselineP;
        result = api.editById('env.g', baseline.env.g + 0.01);
        assert(result.success, result.message);
        assert_ids(api.getState().modifiedIds, {'env.g'});
    end

    function check_modified_order()
        baseline = api.getState().baselineP;
        result = api.editById('linear.du.rudder', 0.02);
        assert(result.success, result.message);
        result = api.editById('wing.S', baseline.wing.S + 0.1);
        assert(result.success, result.message);
        result = api.editById('env.g', baseline.env.g + 0.01);
        assert(result.success, result.message);
        assert_ids(api.getState().modifiedIds, ...
            {'env.g','wing.S','linear.du.rudder'});
    end

    function check_restore_removes_mark()
        baseline = api.getState().baselineP;
        result = api.editById('wing.S', baseline.wing.S + 0.1);
        assert(result.success, result.message);
        assert_ids(api.getState().modifiedIds, {'wing.S'});
        result = api.editById('wing.S', baseline.wing.S);
        assert(result.success, result.message);
        assert_ids(api.getState().modifiedIds, {});
    end

    function check_undo_all()
        baseline = api.getState().baselineP;
        result = api.editById('env.rho', baseline.env.rho + 0.01);
        assert(result.success, result.message);
        api.resetAll();
        state = api.getState();
        assert(isequaln(state.currentP, state.baselineP), 'Undo did not restore baseline.');
        assert_ids(state.modifiedIds, {});
    end

    function check_rotor_radius_derived()
        baseline = api.getState().baselineP;
        result = api.editById('rotor.R', baseline.rotor.R + 0.1);
        assert(result.success, result.message);
        P = api.getState().currentP;
        assert(abs(P.rotor.Ib - P.rotor.bladeMass*P.rotor.R^2/3) < 1e-10);
        assert(abs(P.rotor.Sblade - P.rotor.bladeMass*P.rotor.R/2) < 1e-10);
        assert_ids(api.getState().modifiedIds, {'rotor.R'});
    end

    function check_blade_mass_derived()
        baseline = api.getState().baselineP;
        result = api.editById('rotor.bladeMass', baseline.rotor.bladeMass + 1);
        assert(result.success, result.message);
        P = api.getState().currentP;
        assert(abs(P.rotor.Ib - P.rotor.bladeMass*P.rotor.R^2/3) < 1e-10);
        assert(abs(P.rotor.Sblade - P.rotor.bladeMass*P.rotor.R/2) < 1e-10);
        assert_ids(api.getState().modifiedIds, {'rotor.bladeMass'});
    end

    function check_i0_mirror()
        baseline = api.getState().baselineP;
        result = api.editById('mass.I0.Ixy', baseline.mass.I0(1,2) + 1);
        assert(result.success, result.message);
        P = api.getState().currentP;
        assert(P.mass.I0(1,2) == P.mass.I0(2,1), 'I0 mirror element was not updated.');
    end

    function check_ki_validation()
        result = api.editById('mass.KI.KIxx', 1.0e6);
        assert(~result.success, 'Invalid KI was accepted.');
    end

    function check_control_limits()
        baseline = api.getState().baselineP;
        upper = baseline.control.rudderLim(2)*180/pi;
        result = api.editById('control.rudderLim.lower', upper + 1);
        assert(~result.success, 'Invalid control limit order was accepted.');
    end

    function check_combined_filter()
        baseline = api.getState().baselineP;
        result = api.editById('wing.S', baseline.wing.S + 0.1);
        assert(result.success, result.message);
        api.setFilters('机翼','面积',true);
        state = api.getState();
        assert(numel(state.visibleCatalog) == 1, 'Combined filter should leave one row.');
        assert(strcmp(state.visibleCatalog(1).id,'wing.S'), 'Combined filter returned wrong item.');
    end

    function check_exclusions()
        ids = {api.getState().parameterCatalog.id};
        forbidden = {'mass.RH','rotor.Ib','rotor.Sblade','rotor.flapInitial', ...
            'rotor.bladeMassDistribution','trim.display','wing.b','vtail.c', ...
            'mass.I0.I21','mass.I0.I31','mass.I0.I32', ...
            'mass.KI.KIxy','mass.KI.KIxz','mass.KI.KIyz'};
        for k = 1:numel(forbidden)
            assert(~any(strcmp(ids, forbidden{k})), ...
                'Forbidden item is present: %s.', forbidden{k});
        end
    end

    function check_baseline_stable()
        before = api.getState();
        result = api.editById('env.rho', before.baselineP.env.rho + 0.01);
        assert(result.success, result.message);
        after = api.getState();
        assert(isequaln(after.baselineP, before.baselineP), ...
            'baselineP was overwritten by a normal edit.');
    end

    function check_analysis_tabs()
        state = api.getState();
        assert(isfield(state, 'parameterCatalog'));
        api.switchTab('trim');
        api.switchTab('linear');
        api.switchTab('response');
        api.switchTab('parameter');
    end

    function check_tilt_angle_text()
        assert(isfield(api.handles, 'trimBetaLabel'), ...
            'Trim beta label handle is not exposed for UI text checks.');
        assert(strcmp(api.handles.trimBetaLabel.Text, ...
            '旋翼向前倾转角 (deg)'), ...
            'Trim angle label does not state the program angle semantics.');
    end
end

function item = find_item(catalog, id)
idx = find(strcmp({catalog.id}, id), 1);
assert(~isempty(idx), 'Missing catalog item: %s.', id);
item = catalog(idx);
end

function assert_ids(actual, expected)
actual = reshape(actual, numel(actual), 1);
expected = reshape(expected, numel(expected), 1);
assert(isequal(actual, expected), 'Modified ids do not match expected ids.');
end

function close_if_valid(fig)
if ~isempty(fig) && isvalid(fig)
    delete(fig);
end
end
