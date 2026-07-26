function report = check_control_stability_assessment()
%CHECK_CONTROL_STABILITY_ASSESSMENT Focused generated-evidence regression.
% The checked CSV files are committed reproducibility artifacts generated
% from the current task entry point, not manually curated pass flags.

rootDir = fileparts(fileparts(mfilename('fullpath')));
outputDir = fullfile(rootDir,'docs', ...
    'tiltrotor_control_stability_technical_report');
names = {};
passed = [];
messages = {};

run_case('nine-state input order and B-column labels',@case_nine_inputs);
run_case('thirteen-state torque and command contracts',@case_13_inputs);
run_case('three representative trims remain credible',@case_trim_points);
run_case('all reported derivatives are finite real values',@case_derivatives);
run_case('three-level central differences are present',@case_three_steps);
run_case('direct-load and A/B crosschecks are explicit',@case_crosschecks);
run_case('participation biorthogonality meets tolerance',@case_participation);
run_case('pathological modes are not force-named',@case_pathological);
run_case('control steps have time-step refinement',@case_step_convergence);
run_case('linear/nonlinear primary directions agree',@case_step_direction);
run_case('unsupported rotor branches are excluded',@case_physical_gate);
run_case('trim data do not cross-connect explicit modes',@case_trim_modes);
run_case('production model and default parameters are unchanged', ...
    @case_unchanged_model);
run_case('NASA comparison wording is downgraded',@case_nasa_claim);

report.names = names;
report.passed = passed;
report.messages = messages;
report.allPassed = all(passed);
fprintf('\nControl-stability assessment checks\n');
fprintf('===================================\n');
for k = 1:numel(names)
    fprintf('%-58s : %s\n',names{k}, ...
        ternary(passed(k),'PASS','FAIL'));
    if ~passed(k)
        fprintf('  %s\n',messages{k});
    end
end
fprintf('All passed: %d\n',report.allPassed);

    function case_nine_inputs()
        contract = control_stability_interface_contract();
        expected = {'collective';'diffCollective';'cyclicLong'; ...
            'diffCyclic';'aileron';'elevator';'rudder'};
        assert(isequal(contract.nineInputNames,expected));
        assert(~contract.betaMIsNineStateBColumn);
        T = readtable(required_file( ...
            'CONTROL_DERIVATIVE_CROSSCHECK.csv'));
        assert(all(ismember(expected,unique(T.controlName))));
    end

    function case_13_inputs()
        contract = control_stability_interface_contract();
        assert(isequal(contract.thirteenTorqueInputNames, ...
            get_control_input_names_13x10()));
        assert(isequal(contract.thirteenCommandInputNames, ...
            get_command_input_names_13x10()));
        assert(strcmp(contract.thirteenTorqueInputNames{9}, ...
            'nacelleTorqueLeft'));
        assert(strcmp(contract.thirteenCommandInputNames{9}, ...
            'betaMLCommand'));
        assert(isequal(contract.nineToThirteenInputColumns, ...
            [1;2;3;4;6;7;8]));
    end

    function case_trim_points()
        T = readtable(required_file('REPRESENTATIVE_POINT_AUDIT.csv'));
        expected = {'B15_V020';'B45_V035';'B75_V080'};
        assert(isequal(sort(T.pointId),sort(expected)));
        assert(all(T.credible) && all(T.physicalConverged) && ...
            all(T.physicalBranchSupported) && all(T.finiteReal));
        assert(all(T.dynamicResidualNorm < 1e-6));
    end

    function case_derivatives()
        files = {'STATIC_STABILITY_DERIVATIVES.csv', ...
            'DAMPING_DERIVATIVES.csv', ...
            'CONTROL_EFFECTIVENESS_DERIVATIVES.csv'};
        for fileIndex = 1:numel(files)
            T = readtable(required_file(files{fileIndex}));
            assert(all(T.valid));
            assert(all(isfinite(T.dimensionalDerivative)));
            assert(all(isfinite(T.coefficientDerivative)));
            assert(all(isreal(T.dimensionalDerivative)));
            assert(all(isreal(T.coefficientDerivative)));
        end
    end

    function case_three_steps()
        files = {'STATIC_STABILITY_DERIVATIVES.csv', ...
            'DAMPING_DERIVATIVES.csv', ...
            'CONTROL_EFFECTIVENESS_DERIVATIVES.csv'};
        for fileIndex = 1:numel(files)
            T = readtable(required_file(files{fileIndex}));
            groups = unique(strcat(T.pointId,'|',T.perturbationName, ...
                '|',T.coefficientName));
            for groupIndex = 1:numel(groups)
                key = strcat(T.pointId,'|',T.perturbationName, ...
                    '|',T.coefficientName);
                selection = strcmp(key,groups{groupIndex});
                assert(isequal(sort(T.stepLevel(selection)),[1;2;3]));
                assert(all(isfinite(T.relativeStepVariation(selection))));
            end
        end
    end

    function case_crosschecks()
        A = readtable(required_file('DERIVATIVE_CROSSCHECK.csv'));
        B = readtable(required_file('CONTROL_DERIVATIVE_CROSSCHECK.csv'));
        assert(all(ismember(A.status, ...
            {'FULL_CROSSCHECK';'PARTIAL_CROSSCHECK'})));
        statusFields = {'statusB9','statusB13Torque','statusB13Command'};
        for fieldIndex = 1:numel(statusFields)
            assert(all(ismember(B.(statusFields{fieldIndex}), ...
                {'FULL_CROSSCHECK';'PARTIAL_CROSSCHECK'})));
        end
        assert(any(strcmp(A.status,'FULL_CROSSCHECK')));
        assert(any(strcmp(B.statusB9,'FULL_CROSSCHECK')));
    end

    function case_participation()
        T = readtable(required_file('MODAL_CONDITIONING.csv'));
        assert(all(isfinite(T.eigenvectorConditionNumber)));
        wellConditioned = ~T.pathologicalEigenvectors;
        assert(all(T.biorthogonalityError(wellConditioned) < 1e-8));
        P = readtable(required_file('MODAL_PARTICIPATION.csv'));
        C = readtable(required_file('MODAL_CLASSIFICATION.csv'));
        keys = unique(strcat(P.pointId,'|',P.modelKind,'|', ...
            string(P.modeIndex)));
        for keyIndex = 1:numel(keys)
            key = strcat(P.pointId,'|',P.modelKind,'|', ...
                string(P.modeIndex));
            selection = key == keys(keyIndex);
            conditioningMask = strcmp(T.pointId,P.pointId{find(selection,1)}) & ...
                strcmp(T.modelKind,P.modelKind{find(selection,1)});
            assert(sum(conditioningMask) == 1);
            assert(all(isfinite(P.normalizedMagnitude(selection))));
            if T.pathologicalEigenvectors(conditioningMask)
                classMask = strcmp(C.pointId,P.pointId{find(selection,1)}) & ...
                    strcmp(C.modelKind,P.modelKind{find(selection,1)}) & ...
                    C.modeIndex == P.modeIndex(find(selection,1));
                assert(sum(classMask) == 1);
                assert(strcmp(C.classification{classMask}, ...
                    'MIXED_OR_UNCERTAIN_MODE'));
            else
                assert(abs(sum(P.normalizedMagnitude(selection))-1) < 1e-10);
            end
        end
    end

    function case_pathological()
        A = [0,1;0,1e-9];
        modal = analyze_modal_participation('SYNTHETIC', ...
            'PATHOLOGICAL_TEST',A,{'u';'w'});
        assert(all(modal.conditioning.pathologicalEigenvectors));
        assert(all(strcmp(modal.classification.classification, ...
            'MIXED_OR_UNCERTAIN_MODE')));
    end

    function case_step_convergence()
        T = readtable(required_file( ...
            'CONTROL_STEP_TIMESTEP_CONVERGENCE.csv'));
        keys = unique(strcat(T.pointId,'|',T.controlName));
        for keyIndex = 1:numel(keys)
            key = strcat(T.pointId,'|',T.controlName);
            selection = strcmp(key,keys{keyIndex});
            assert(sum(selection) >= 2);
            assert(sum(strcmp(T.status(selection),'FINEST_STEP')) == 1);
            assert(all(T.finiteReal(selection)));
        end
    end

    function case_step_direction()
        metrics = readtable(required_file( ...
            'CONTROL_STEP_RESPONSE_METRICS.csv'));
        comparison = readtable(required_file( ...
            'CONTROL_STEP_LINEAR_NONLINEAR_COMPARISON.csv'));
        for rowIndex = 1:height(metrics)
            mask = strcmp(comparison.pointId,metrics.pointId{rowIndex}) & ...
                strcmp(comparison.controlName, ...
                metrics.controlName{rowIndex}) & ...
                strcmp(comparison.stateName, ...
                metrics.primaryStateName{rowIndex});
            assert(sum(mask) == 1);
            assert(comparison.directionAgreement(mask));
        end
    end

    function case_physical_gate()
        T = readtable(required_file('REPRESENTATIVE_POINT_AUDIT.csv'));
        assert(all(T.physicalConverged));
        S = readtable(required_file( ...
            'CONTROL_STEP_RESPONSE_METRICS.csv'));
        assert(all(S.physicalConvergedAtEveryStep));
    end

    function case_trim_modes()
        T = readtable(required_file('TRIM_CHARACTERISTICS_BY_MODE.csv'));
        assert(all(strcmp(T.claimBoundary, ...
            'DISCRETE_EXPLICIT_MODE_POINT_NOT_CONTINUOUS_CORRIDOR')));
        assert(all(ismember(T.mode,{'helicopter_longitudinal'; ...
            'conversion_longitudinal';'airplane_longitudinal'})));
    end

    function case_unchanged_model()
        command = ['git diff --quiet ' ...
            '99acba44740087fdf3d7cdc82efd191c87cfb2d1 -- ' ...
            'model params_nominal.m'];
        status = system(command);
        assert(status == 0, ...
            'Production model or default parameters differ from PR #61.');
    end

    function case_nasa_claim()
        textValue = fileread(required_file( ...
            'EXTERNAL_ROTOR_COMPARISON_CLAIM_AUDIT.md'));
        assert(contains(textValue, ...
            '未经同构映射的原始曲线差异诊断'));
        assert(contains(textValue,'0.75R'));
        assert(contains(textValue,'不得称为模型预测误差'));
    end

    function pathValue = required_file(name)
        pathValue = fullfile(outputDir,name);
        assert(exist(pathValue,'file') == 2, ...
            'Required generated artifact is missing: %s',pathValue);
    end

    function run_case(name,fun)
        names{end+1,1} = name;
        try
            fun();
            passed(end+1,1) = true;
            messages{end+1,1} = '';
        catch ME
            passed(end+1,1) = false;
            messages{end+1,1} = ME.message;
        end
    end
end

function value = ternary(condition,yesValue,noValue)
if condition
    value = yesValue;
else
    value = noValue;
end
end
