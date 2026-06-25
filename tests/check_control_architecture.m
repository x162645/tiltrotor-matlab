function controlReport = check_control_architecture()
%CHECK_CONTROL_ARCHITECTURE Validate the documented seven-control architecture.
%
% This test records structural properties of the current control definition:
% uCtrl(4), named diffCyclic in code, is documented as
% differentialLongitudinalCyclic and is not a lateral cyclic input.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir,'model'));
addpath(fullfile(rootDir,'analysis'));

P = params_nominal();
d2r = pi/180;

x0 = zeros(9,1);
betaM = 0;
u0 = [18*d2r; 0; 0; 0; 0; 0; 0];
labels = {'Fx','Fy','Fz','Mx','My','Mz'};
controlNames = {'collective','diffCollective','cyclicLong','diffCyclic'};
documentedNames = {'collective','differentialCollective', ...
    'longitudinalCyclic','differentialLongitudinalCyclic'};

hRef = 1e-4;
D = zeros(6,4);
for k = 1:4
    D(:,k) = load_derivative(k, hRef);
end

controlReport.controlVector = struct( ...
    'index', num2cell((1:7).'), ...
    'codeName', {'collective'; 'diffCollective'; 'cyclicLong'; ...
        'diffCyclic'; 'aileron'; 'elevator'; 'rudder'}, ...
    'documentedName', {'collective'; 'differentialCollective'; ...
        'longitudinalCyclic'; 'differentialLongitudinalCyclic'; ...
        'aileron'; 'elevator'; 'rudder'}, ...
    'unit', repmat({'rad'},7,1));
controlReport.derivativeStep = hRef;
controlReport.derivativeLabels = labels;
controlReport.derivatives = D;
controlReport.derivativeColumns = controlNames;
controlReport.derivativeDocumentedColumns = documentedNames;
controlReport.cases = struct('name',{},'passed',{},'message',{});

add_case('symmetric collective', test_symmetric_collective());
add_case('differential collective', test_differential_collective());
add_case('symmetric longitudinal cyclic', test_symmetric_longitudinal_cyclic());
add_case('differential longitudinal cyclic', test_differential_longitudinal_cyclic());
add_case('+diff/-diff mirror relation', test_diff_mirror_relation());
add_case('finite-difference stability h=1e-3,1e-4,1e-5', ...
    test_difference_stability());

controlReport.allPassed = all([controlReport.cases.passed]);

fprintf('\nControl architecture checks\n');
fprintf('===========================\n');
fprintf('Control derivative columns use h = %.1e rad.\n', hRef);
fprintf('%-38s : %s\n', 'case', 'status');
for k = 1:numel(controlReport.cases)
    status = ternary(controlReport.cases(k).passed, 'PASS', 'FAIL');
    fprintf('%-38s : %s\n', controlReport.cases(k).name, status);
    if ~controlReport.cases(k).passed
        fprintf('  %s\n', controlReport.cases(k).message);
    end
end
fprintf('\nDerivative d[F;M]/d(control), rows [Fx Fy Fz Mx My Mz]\n');
for k = 1:numel(controlNames)
    fprintf('%s (%s):\n', controlNames{k}, documentedNames{k});
    fprintf('% .12e ', D(:,k));
    fprintf('\n');
end
fprintf('All control architecture checks passed: %d\n', controlReport.allPassed);

    function result = test_symmetric_collective()
        d = D(:,1);
        ok = d(3) < -1e5 && near_zero(d([2 4 6]), d);
        msg = ['Expected collective to increase upward thrust (dFz<0) ' ...
            'without lateral force, roll moment, or yaw moment.'];
        result = make_result(ok, msg);
    end

    function result = test_differential_collective()
        d = D(:,2);
        ok = d(2) < -1e4 && d(4) < -1e5 && d(6) > 1e4 && ...
            near_zero(d([1 3 5]), d);
        msg = ['Expected differential collective to produce roll and yaw ' ...
            'moments, with the NUAA Eq12 inflow field also producing an ' ...
            'odd lateral-force derivative.'];
        result = make_result(ok, msg);
    end

    function result = test_symmetric_longitudinal_cyclic()
        d = D(:,3);
        ok = d(1) > 1e4 && d(5) < -1e4 && near_zero(d([2 4 6]), d) && ...
            abs(d(3)) < 1e-4*max(abs(d(1)),1);
        msg = ['Expected symmetric longitudinal cyclic to enter blade pitch ' ...
            'as theta1s*sin(psi), changing longitudinal load and ' ...
            'pitch moment without lateral/yaw differential effect.'];
        result = make_result(ok, msg);
    end

    function result = test_differential_longitudinal_cyclic()
        d = D(:,4);
        ok = d(6) < -1e5 && near_zero(d([1 3 5]), d) && ...
            abs(d(2)) < 1e-3*max(abs(d(6)),1) && ...
            abs(d(4)) < 1e-3*max(abs(d(6)),1);
        msg = ['Expected differentialLongitudinalCyclic (code diffCyclic) ' ...
            'to map right + / left - cyclic commands into theta1s, producing an odd yaw ' ...
            'response under the steady harmonic flapping model.'];
        result = make_result(ok, msg);
    end

    function result = test_diff_mirror_relation()
        amp = 2*d2r;
        base = generalized_load(u0);
        diffCollectiveOk = mirror_ok(2, amp, base);
        diffCyclicOk = mirror_ok(4, amp, base);
        ok = diffCollectiveOk && diffCyclicOk;
        msg = ['Expected +diff and -diff commands to swap left/right rotor ' ...
            'effects: Fx,Fz,My even; Fy,Mx,Mz odd about the symmetric baseline.'];
        result = make_result(ok, msg);
    end

    function result = test_difference_stability()
        steps = [1e-3, 1e-4, 1e-5];
        ok = true;
        worstRel = 0;
        worstName = '';
        for j = 1:4
            derivs = zeros(6,numel(steps));
            for kk = 1:numel(steps)
                derivs(:,kk) = load_derivative(j, steps(kk));
            end
            ref = derivs(:,2);
            significant = abs(ref) > max(1e-6, 1e-8*max(norm(ref),1));
            if any(significant)
                rel13 = max(abs(derivs(significant,1) - ref(significant)) ./ ...
                    max(abs(ref(significant)),1));
                rel53 = max(abs(derivs(significant,3) - ref(significant)) ./ ...
                    max(abs(ref(significant)),1));
                localWorst = max(rel13, rel53);
            else
                localWorst = max(abs(derivs(:)));
            end
            if localWorst > worstRel
                worstRel = localWorst;
                worstName = controlNames{j};
            end
            ok = ok && localWorst < 1e-3;
        end
        msg = sprintf('Worst relative difference %.3e for %s exceeds tolerance.', ...
            worstRel, worstName);
        result = make_result(ok, msg);
    end

    function ok = mirror_ok(index, amp, base)
        up = u0;
        um = u0;
        up(index) = up(index) + amp;
        um(index) = um(index) - amp;
        lp = generalized_load(up);
        lm = generalized_load(um);

        evenIdx = [1 3 5];
        oddIdx = [2 4 6];
        evenErr = lp(evenIdx) - lm(evenIdx);
        oddErr = (lp(oddIdx) - base(oddIdx)) + (lm(oddIdx) - base(oddIdx));

        scale = max([norm(lp), norm(lm), norm(base), 1]);
        ok = norm(evenErr) <= 1e-9*scale + 1e-6 && ...
             norm(oddErr) <= 1e-9*scale + 1e-6;
    end

    function d = load_derivative(index, h)
        up = u0;
        um = u0;
        up(index) = up(index) + h;
        um(index) = um(index) - h;
        d = (generalized_load(up) - generalized_load(um))/(2*h);
    end

    function y = generalized_load(u)
        [F, M] = total_forces_moments(x0, u, betaM, P);
        y = [F(:); M(:)];
        assert(all(isfinite(y)) && isreal(y), ...
            'Generalized load contains NaN, Inf, or complex values.');
    end

    function tf = near_zero(value, scaleValue)
        scale = max(norm(scaleValue),1);
        tf = all(abs(value(:)) <= 1e-9*scale + 1e-6);
    end

    function result = make_result(ok, msg)
        result.passed = logical(ok);
        if ok
            result.message = '';
        else
            result.message = msg;
        end
    end

    function add_case(name, result)
        controlReport.cases(end+1,1).name = name;
        controlReport.cases(end).passed = result.passed;
        controlReport.cases(end).message = result.message;
    end

    function value = ternary(condition, a, b)
        if condition
            value = a;
        else
            value = b;
        end
    end
end
