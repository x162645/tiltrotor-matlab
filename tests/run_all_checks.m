function summary = run_all_checks()
%RUN_ALL_CHECKS 执行模型内部一致性与静态数值检查。
%
% 这些检查不能代替真实 XV-15 试验验证。

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir,'model'));
addpath(fullfile(rootDir,'analysis'));

P = params_nominal();
d2r = pi/180;

tests = {};
passed = [];
messages = {};

run_test('参数和惯量检查', @test_parameters);
run_test('短舱端点推力方向', @test_nacelle_endpoints);
run_test('总距—推力单调性', @test_collective_monotonicity);
run_test('左右对称性', @test_symmetry);
run_test('机翼 V^2 规律', @test_wing_v2);
run_test('旋翼网格收敛', @test_grid_convergence);
run_test('线性化有限性', @test_linearization);

summary.names = tests;
summary.passed = passed;
summary.messages = messages;
summary.allPassed = all(passed);

fprintf('\nInternal checks\n');
fprintf('===============\n');
for k = 1:numel(tests)
    fprintf('%-24s : %s\n',tests{k},ternary(passed(k),'PASS','FAIL'));
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

    function test_nacelle_endpoints()
        x0 = zeros(9,1);
        u0 = [18*d2r;0;0;0;0;0;0];

        [F0,~,~] = total_forces_moments(x0,u0,0,P);
        [F90,~,~] = total_forces_moments(x0,u0,pi/2,P);

        assert(F0(3) < 0, '直升机模式应产生向上推力，即 Fz<0。');
        assert(F90(1) > 0, '固定翼模式应产生向前推力，即 Fx>0。');
    end

    function test_collective_monotonicity()
        x0 = zeros(9,1);
        u1 = [12*d2r;0;0;0;0;0;0];
        u2 = [18*d2r;0;0;0;0;0;0];

        [~,~,o1] = total_forces_moments(x0,u1,0,P);
        [~,~,o2] = total_forces_moments(x0,u2,0,P);

        T1 = o1.rotorLeft.thrust + o1.rotorRight.thrust;
        T2 = o2.rotorLeft.thrust + o2.rotorRight.thrust;

        assert(T2 > T1, '总距增大后总推力没有增大。');
    end

    function test_symmetry()
        x0 = zeros(9,1);
        u0 = [18*d2r;0;0;0;0;0;0];

        [F,M,~] = total_forces_moments(x0,u0,0,P);
        scaleF = max(norm(F),1);
        scaleM = max(norm(M),1);

        assert(abs(F(2))/scaleF < 1e-8, '对称工况 Fy 不接近零。');
        assert(abs(M(1))/scaleM < 1e-8, '对称工况 Mx 不接近零。');
        assert(abs(M(3))/scaleM < 1e-8, '对称工况 Mz 不接近零。');
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
            '机翼力未近似满足速度平方规律。');
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
        assert(rel < 0.05, '默认旋翼网格与加密网格差异超过 5%%。');
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
