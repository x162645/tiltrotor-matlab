function report = check_nuaa_public_formula_reference()
%CHECK_NUAA_PUBLIC_FORMULA_REFERENCE Focused opt-in reference checks.
% Establishes interface, symmetry, convergence, and default-path isolation;
% it does not validate the model against external measurements.

P = params_nominal();
P13 = params_berger13();
d2r = pi/180;
x = zeros(9,1);
control = struct('collective',18*d2r,'cyclicLong',0);
cg = zeros(3,1);
items = {};
passed = [];
details = {};

[F0,M0,currentBefore] = total_forces_moments( ...
    x,[18*d2r;zeros(6,1)],0,P);
run_check('model identity and finite real output',@identity_finite);
run_check('left/right mirror symmetry',@mirror_symmetry);
run_check('nacelle endpoint thrust direction',@nacelle_endpoints);
run_check('radial/azimuth grid convergence',@grid_convergence);
run_check('induced and flap convergence evidence',@iteration_evidence);
run_check('default stack unchanged by reference calls',@default_isolation);
run_check('13x10 symmetric whole-aircraft interface',@whole_aircraft);

report.names = items;
report.passed = passed;
report.details = details;
report.allPassed = all(passed);
report.claimBoundary = ['INTERNAL_CONSISTENCY_AND_NUMERICAL_' ...
    'CONVERGENCE_NOT_EXTERNAL_VALIDATION'];

fprintf('\nNUAA public-formula reference checks\n');
fprintf('====================================\n');
for k = 1:numel(items)
    fprintf('%-42s : %s\n',items{k},ternary(passed(k),'PASS','FAIL'));
    if ~passed(k)
        fprintf('  %s\n',details{k});
    end
end

    function run_check(name,fun)
        items{end+1,1} = name;
        try
            fun();
            passed(end+1,1) = true;
            details{end+1,1} = '';
        catch ME
            passed(end+1,1) = false;
            details{end+1,1} = sprintf('%s: %s',ME.identifier,ME.message);
        end
    end

    function identity_finite()
        [F,M,out] = nuaa_public_formula_rotor( ...
            x,control,0,-1,cg,P);
        assert(strcmp(out.modelId,'NUAA_PUBLIC_FORMULA_REFERENCE'));
        assert(strcmp(out.modelNameZh,'南航公开公式旋翼参考模型'));
        assert(isreal([F;M]) && all(isfinite([F;M])));
        assert(out.thrust > 0 && out.torque > 0);
        assert(out.defaultRotorPathModified == false);
    end

    function mirror_symmetry()
        [FL,ML] = nuaa_public_formula_rotor(x,control,0,-1,cg,P);
        [FR,MR] = nuaa_public_formula_rotor(x,control,0,+1,cg,P);
        forceScale = max(norm([FL;FR]),1);
        momentScale = max(norm([ML;MR]),1);
        % Independent nonlinear solves differ at the few-ppm level.
        assert(norm(FL-[FR(1);-FR(2);FR(3)])/forceScale < 1e-5);
        assert(norm(ML-[-MR(1);MR(2);-MR(3)])/momentScale < 1e-5);
    end

    function nacelle_endpoints()
        [Fhelicopter,~,out0] = nuaa_public_formula_rotor( ...
            x,control,0,-1,cg,P);
        [Fairplane,~,out90] = nuaa_public_formula_rotor( ...
            x,control,pi/2,-1,cg,P);
        assert(Fhelicopter(3) < 0);
        assert(Fairplane(1) > 0);
        assert(out0.basisOrthogonalityError < 1e-12);
        assert(out90.basisOrthogonalityError < 1e-12);
    end

    function grid_convergence()
        coarse = struct('nRadial',12,'nAzimuth',16);
        refined = struct('nRadial',20,'nAzimuth',36);
        [~,~,a] = nuaa_public_formula_rotor( ...
            x,control,0,-1,cg,P,coarse);
        [~,~,b] = nuaa_public_formula_rotor( ...
            x,control,0,-1,cg,P,refined);
        assert(abs(b.thrust-a.thrust)/max(abs(b.thrust),1) < 0.05);
        assert(abs(b.torque-a.torque)/max(abs(b.torque),1) < 0.05);
    end

    function iteration_evidence()
        [~,~,out] = nuaa_public_formula_rotor( ...
            x,control,0,-1,cg,P);
        assert(out.inducedConverged);
        assert(out.flap.converged);
        assert(out.inducedVelocityError <= P.rotor.inducedTol);
        assert(out.flap.residualNorm <= P.rotor.flapResidualTol);
        assert(size(out.inducedHistory,1) == out.inducedIterations);
    end

    function default_isolation()
        [Fafter,Mafter,currentAfter] = total_forces_moments( ...
            x,[18*d2r;zeros(6,1)],0,P);
        assert(isequaln(Fafter,F0) && isequaln(Mafter,M0));
        assert(isequaln(currentAfter,currentBefore));
    end

    function whole_aircraft()
        x13 = [x;0;0;0;0];
        u10 = [18*d2r;zeros(9,1)];
        [F,M,out] = total_forces_moments_13x10_reference( ...
            x13,u10,P13);
        assert(isreal([F;M]) && all(isfinite([F;M])));
        assert(strcmp(out.modelId,'NUAA_PUBLIC_FORMULA_REFERENCE'));
        assert(out.defaultRotorPathModified == false);
        assert(norm(out.referenceMinusCurrent.F) > 0);
    end

    function value = ternary(condition,a,b)
        if condition
            value = a;
        else
            value = b;
        end
    end
end
