function report = check_gui_complete_parameter_workbench()
%CHECK_GUI_COMPLETE_PARAMETER_WORKBENCH Verify full parameter catalog wiring.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir,'model'));
addpath(fullfile(rootDir,'services'));

P = params_nominal();
P0 = P;
rows = build_parameter_catalog(P);

names = {};
passed = [];
messages = {};

run_case('catalog has broad coverage', @check_catalog_size);
run_case('required groups are present', @check_groups);
run_case('representative parameters are present', @check_representative_keys);
run_case('source labels are user readable', @check_source_labels);
run_case('derived and compatibility fields are read-only', @check_read_only_fields);
run_case('catalog build does not alter defaults', @check_no_default_change);
run_case('write service validates editable scalar', @check_write_service);

report.names = names;
report.passed = passed;
report.messages = messages;
report.allPassed = all(passed);
report.rowCount = numel(rows);
report.groups = unique({rows.group}).';

fprintf('\nGUI complete parameter workbench checks\n');
fprintf('=======================================\n');
for k = 1:numel(names)
    fprintf('%-40s : %s\n', names{k}, ternary(passed(k),'PASS','FAIL'));
    if ~passed(k)
        fprintf('  %s\n', messages{k});
    end
end
fprintf('Catalog rows: %d\n', report.rowCount);
fprintf('All passed: %d\n', report.allPassed);

    function run_case(name, fun)
        names{end+1,1} = name;
        try
            fun();
            passed(end+1,1) = true;
            messages{end+1,1} = '';
        catch ME
            passed(end+1,1) = false;
            messages{end+1,1} = sprintf('%s: %s', ME.identifier, ME.message);
        end
    end

    function check_catalog_size()
        assert(numel(rows) > 80, ...
            'Catalog should be much larger than the old hard-coded short list.');
    end

    function check_groups()
        required = {'环境','质量/惯量','旋翼','机翼','机身','平尾', ...
            '垂尾','控制','短舱动态','配平','线性化'};
        groups = unique({rows.group});
        missing = setdiff(required, groups);
        assert(isempty(missing), 'Missing groups: %s', strjoin(missing, ', '));
    end

    function check_representative_keys()
        required = {'env.rho','env.g','mass.m','mass.mNac', ...
            'mass.I0(1,1)','mass.I0(2,2)','mass.I0(3,3)', ...
            'mass.KI(1,1)','rotor.R','rotor.Nb','rotor.Omega', ...
            'rotor.chord','rotor.twistTip','rotor.CLmax', ...
            'rotor.bladeMass','rotor.flapResidualTol', ...
            'wing.S','wing.b','wing.c','wing.CLalpha','wing.Cm0', ...
            'wing.normalFlowRatio','fuselage.S','fuselage.CD0', ...
            'fuselage.Cmalpha','htail.S','htail.CLalpha', ...
            'htail.CLelevator','vtail.SEach','vtail.CYbeta', ...
            'vtail.CYrudder','control.collectiveLim(1)', ...
            'control.collectiveLim(2)','control.cyclicLim(1)', ...
            'control.cyclicLim(2)','control.aileronLim(1)', ...
            'control.elevatorLim(2)','control.rudderLim(2)', ...
            'control.enableLateralCyclic','nacelleDynamics.enabled', ...
            'nacelleDynamics.rateLimitDegPerSec','nacelleDynamics.omega', ...
            'nacelleDynamics.zeta','trim.residualTolerance', ...
            'trim.maxIterations','trim.variableScale(1)', ...
            'linear.dx(1)','linear.du(1)','linear.stabilityTolerance'};
        keys = {rows.key};
        missing = setdiff(required, keys);
        assert(isempty(missing), 'Missing representative keys: %s', ...
            strjoin(missing, ', '));
    end

    function check_source_labels()
        labels = {rows.sourceLabel};
        assert(any(strcmp(labels, '概念假设')));
        assert(any(strcmp(labels, '模型假设')));
        assert(any(strcmp(labels, '数值设置')));
        assert(any(strcmp(labels, '派生计算')));
        assert(~any(strcmp(labels, 'ASSUMED_CONCEPT')), ...
            'Internal source enum leaked into sourceLabel.');
    end

    function check_read_only_fields()
        assert(is_readonly('rotor.Ib'));
        assert(is_readonly('rotor.Sblade'));
        assert(is_readonly('mass.RH'));
    end

    function check_no_default_change()
        assert(isequaln(P, P0), 'build_parameter_catalog changed P.');
    end

    function check_write_service()
        Ptest = write_parameter_value(P, 'wing.S', P.wing.S + 0.25);
        assert(abs(Ptest.wing.S - (P.wing.S + 0.25)) < eps);
        validation = validate_parameter_set(Ptest);
        assert(validation.valid, strjoin(validation.errors, newline));
    end

    function tf = is_readonly(key)
        idx = find(strcmp({rows.key}, key), 1);
        assert(~isempty(idx), 'Missing key %s.', key);
        tf = ~rows(idx).editable;
    end
end

function value = ternary(condition,a,b)
if condition
    value = a;
else
    value = b;
end
end
