function summary = run_all_checks()
%RUN_ALL_CHECKS Execute internal consistency and numerical sanity checks.
% These checks do not represent XV-15 flight-test validation.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir,'model'));
addpath(fullfile(rootDir,'analysis'));
addpath(fullfile(rootDir,'tests'));

P = params_nominal();
d2r = pi/180;

tests = {};
passed = [];
messages = {};

run_test('parameters and inertia', @test_parameters);
run_test('mass/inertia/geometry audit', @test_mass_inertia_geometry);
run_test('nacelle endpoint thrust direction', @test_nacelle_endpoints);
run_test('collective thrust monotonicity', @test_collective_monotonicity);
run_test('left/right symmetry', @test_symmetry);
run_test('rotor force/moment chain audit', @test_rotor_force_moment_chain);
run_test('steady first-harmonic flapping', @test_flapping_model);
run_test('aerodynamic component audit', @test_aerodynamic_components);
run_test('control architecture closure', @test_control_architecture);
run_test('wing near-normal blend continuity', @test_wing_normal_flow_blend);
run_test('wing V^2 scaling', @test_wing_v2);
run_test('rotor grid convergence', @test_grid_convergence);
run_test('linearization finite values', @test_linearization);

summary.names = tests;
summary.passed = passed;
summary.messages = messages;
summary.allPassed = all(passed);

fprintf('\nInternal checks\n');
fprintf('===============\n');
for k = 1:numel(tests)
    fprintf('%-36s : %s\n',tests{k},ternary(passed(k),'PASS','FAIL'));
    if ~passed(k)
        fprintf('  %s\n',messages{k});
    end
end
fprintf('All passed: %d\n',summary.allPassed);

    function run_test(name,fun)
        tests{end+1,1} = name;
        try
            fun();
            passed(end+1,1) = true;
            messages{end+1,1} = '';
        catch ME
            passed(end+1,1) = false;
            messages{end+1,1} = ME.message;
        end
    end

    function test_parameters()
        assert(P.mass.m > 0);
        assert(all(eig(P.mass.I0) > 0));
        mp0 = mass_properties(0,P);
        mp90 = mass_properties(pi/2,P);
        assert(all(eig(mp0.I) > 0));
        assert(all(eig(mp90.I) > 0));
        assert(norm(mp0.cgShift) < 1e-12);
        assert(all(isfinite(mp90.cgShift)));
    end

    function test_mass_inertia_geometry()
        massGeometryReport = check_mass_inertia_geometry();
        assert(massGeometryReport.allPassed, ...
            'Mass/inertia/geometry audit has failed items.');
    end

    function test_nacelle_endpoints()
        x0 = zeros(9,1);
        u0 = [18*d2r;0;0;0;0;0;0];

        [F0,~,~] = total_forces_moments(x0,u0,0,P);
        [F90,~,~] = total_forces_moments(x0,u0,pi/2,P);

        assert(F0(3) < 0, ...
            'Helicopter mode should produce upward thrust, Fz < 0.');
        assert(F90(1) > 0, ...
            'Airplane mode should produce forward thrust, Fx > 0.');
    end

    function test_collective_monotonicity()
        x0 = zeros(9,1);
        u1 = [12*d2r;0;0;0;0;0;0];
        u2 = [18*d2r;0;0;0;0;0;0];

        [~,~,o1] = total_forces_moments(x0,u1,0,P);
        [~,~,o2] = total_forces_moments(x0,u2,0,P);

        T1 = o1.rotorLeft.thrust + o1.rotorRight.thrust;
        T2 = o2.rotorLeft.thrust + o2.rotorRight.thrust;

        assert(T2 > T1, 'Total thrust did not increase with collective.');
    end

    function test_symmetry()
        x0 = zeros(9,1);
        u0 = [18*d2r;0;0;0;0;0;0];

        [F,M,~] = total_forces_moments(x0,u0,0,P);
        scaleF = max(norm(F),1);
        scaleM = max(norm(M),1);

        assert(abs(F(2))/scaleF < 1e-8, ...
            'Symmetric condition should keep Fy near zero.');
        assert(abs(M(1))/scaleM < 1e-8, ...
            'Symmetric condition should keep Mx near zero.');
        assert(abs(M(3))/scaleM < 1e-8, ...
            'Symmetric condition should keep Mz near zero.');
    end

    function test_control_architecture()
        controlReport = check_control_architecture();
        assert(controlReport.allPassed, ...
            'Control architecture closure has failed items.');
    end

    function test_aerodynamic_components()
        aeroReport = check_aerodynamic_components();
        assert(aeroReport.allPassed, ...
            'Aerodynamic component audit has failed items.');
    end

    function test_rotor_force_moment_chain()
        rotorChainReport = check_rotor_force_moment_chain();
        assert(rotorChainReport.allPassed, ...
            'Rotor force/moment chain audit has failed items.');
    end

    function test_flapping_model()
        flapReport = check_flapping_model();
        assert(flapReport.allPassed, ...
            'Steady first-harmonic flapping model has failed items.');
    end

    function test_wing_normal_flow_blend()
        wingBlendReport = check_wing_normal_flow_blend();
        assert(wingBlendReport.allPassed, ...
            'Wing near-normal blend continuity has failed items.');
    end

    function test_wing_v2()
        zeroRotor = struct( ...
            'muLong',0,'muLat',0,'inducedVelocity',0, ...
            'eT',[1;0;0]);

        x30 = [30;0;0;zeros(6,1)];
        x60 = [60;0;0;zeros(6,1)];
        u0 = zeros(7,1);

        [F30,~,~] = wing_model(x30,u0,pi/2,zeros(3,1), ...
            zeroRotor,zeroRotor,P);
        [F60,~,~] = wing_model(x60,u0,pi/2,zeros(3,1), ...
            zeroRotor,zeroRotor,P);

        ratio = norm(F60)/max(norm(F30),eps);
        assert(ratio > 3.7 && ratio < 4.3, ...
            'Wing force does not approximately scale with V^2.');
    end

    function test_grid_convergence()
        x0 = zeros(9,1);
        u0 = [18*d2r;0;0;0;0;0;0];

        P1 = P;
        P1.rotor.nRadial = 12;
        P1.rotor.nAzimuth = 16;
        [~,~,o1] = total_forces_moments(x0,u0,0,P1);
        T1 = o1.rotorLeft.thrust + o1.rotorRight.thrust;

        P2 = P;
        P2.rotor.nRadial = 20;
        P2.rotor.nAzimuth = 36;
        [~,~,o2] = total_forces_moments(x0,u0,0,P2);
        T2 = o2.rotorLeft.thrust + o2.rotorRight.thrust;

        rel = abs(T2-T1)/max(abs(T2),1);
        assert(rel < 0.05, ...
            'Default rotor grid differs from refined grid by more than 5%.');
    end

    function test_linearization()
        x0 = [40;0;0;0;0;0;0;0;0];
        u0 = [8*d2r;0;0;0;0;-2*d2r;0];
        [A,B,rep] = linearize_numeric(x0,u0,pi/2,P);
        assert(rep.finite);
        assert(all(size(A) == [9,9]));
        assert(all(size(B) == [9,7]));
    end

    function value = ternary(condition,a,b)
        if condition
            value = a;
        else
            value = b;
        end
    end
end
