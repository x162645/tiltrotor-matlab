function report = check_wing_nuaa_zone_sum()
%CHECK_WING_NUAA_ZONE_SUM Focused checks for NUAA Eq. (16)-(22) wing assembly.
%
% These checks verify the current implementation structure and finite
% numerical behavior. They do not constitute XV-15 or NUAA quantitative
% validation.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir,'model'));
addpath(fullfile(rootDir,'analysis'));

P = params_nominal();
d2r = pi/180;
tol = 1.0e-10;

report.cases = struct('name',{},'passed',{},'message',{});
report.nuaaTrendStatus = 'NOT_RUN';
report.nuaaTrendMessage = '';
report.trimSmoke = struct([]);

add_case('source has no branchWeight complete-load blend', ...
    test_source_no_complete_load_blend());
add_case('Eq16 total-area conservation and bounds', ...
    test_area_conservation());
add_case('finite real wing outputs over representative conditions', ...
    test_numeric_robustness());
add_case('deprecated branchWeight diagnostics do not affect final loads', ...
    test_branch_weight_insensitive());
add_case('trim smoke: helicopter, conversion, airplane', ...
    test_trim_smoke());
add_case('NUAA Fig5/Fig6 lightweight trend status', ...
    test_lightweight_nuaa_trend());

report.allPassed = all([report.cases.passed]);

fprintf('\nNUAA Eq. (16)-(22) wing zone-sum checks\n');
fprintf('=======================================\n');
fprintf('%-62s : %s\n','case','status');
for k = 1:numel(report.cases)
    status = ternary(report.cases(k).passed, 'PASS', 'FAIL');
    fprintf('%-62s : %s\n', report.cases(k).name, status);
    if ~report.cases(k).passed
        fprintf('  %s\n', report.cases(k).message);
    end
end
fprintf('NUAA Fig.5/Fig.6 lightweight trend status: %s\n', ...
    report.nuaaTrendStatus);
if ~isempty(report.nuaaTrendMessage)
    fprintf('  %s\n', report.nuaaTrendMessage);
end
fprintf('All NUAA wing zone-sum checks passed: %d\n', report.allPassed);

assert(report.allPassed, 'NUAA wing zone-sum checks failed.');

    function result = test_source_no_complete_load_blend()
        text = fileread(fullfile(rootDir, 'model', 'wing_model.m'));
        patterns = { ...
            'branchWeight\s*\*\s*FNear', ...
            'FNear\s*\*\s*branchWeight', ...
            'branchWeight\s*\*\s*FLiftLine', ...
            'FLiftLine\s*\*\s*branchWeight', ...
            'branchWeight\s*\*\s*MNear', ...
            'MNear\s*\*\s*branchWeight', ...
            'branchWeight\s*\*\s*MLiftLine', ...
            'MLiftLine\s*\*\s*branchWeight', ...
            'branchWeight\s*\*\s*MaeroNear', ...
            'MaeroNear\s*\*\s*branchWeight', ...
            'branchWeight\s*\*\s*MaeroLiftLine', ...
            'MaeroLiftLine\s*\*\s*branchWeight'};
        hits = {};
        for iPattern = 1:numel(patterns)
            if ~isempty(regexp(text, patterns{iPattern}, 'once'))
                hits{end+1} = patterns{iPattern}; %#ok<AGROW>
            end
        end
        required = {'NUAA_EQ16_22_ZONE_SUM', ...
            'diagnostic only; not used in production wing force or moment'};
        requiredOk = true;
        for iReq = 1:numel(required)
            requiredOk = requiredOk && contains(text, required{iReq});
        end
        ok = isempty(hits) && requiredOk;
        result = make_result(ok, sprintf('hits=%s requiredOk=%d', ...
            strjoin(hits, ';'), requiredOk));
    end

    function result = test_area_conservation()
        betasDeg = [0, 15, 35, 45, 75, 90];
        mus = [0, 0.25, P.wing.muMax, 1.2*P.wing.muMax];
        ok = true;
        maxSumErr = 0;
        minArea = Inf;
        maxArea = -Inf;
        for iBeta = 1:numel(betasDeg)
            betaM = betasDeg(iBeta)*d2r;
            for iMu = 1:numel(mus)
                rotor = make_rotor(betaM, 4.0, mus(iMu));
                [~,~,out] = wing_model(zeros(9,1), zeros(7,1), betaM, ...
                    zeros(3,1), rotor, rotor, P);
                sumErr = abs(out.Swss + out.Swfs - P.wing.S);
                halfErr = abs(out.SslipHalf + out.SfreeHalf - P.wing.S/2);
                maxSumErr = max(maxSumErr, max(sumErr, halfErr));
                minArea = min(minArea, min([out.Swss, out.Swfs, ...
                    out.SslipHalf, out.SfreeHalf]));
                maxArea = max(maxArea, max([out.Swss, out.Swfs]));
                ok = ok && sumErr < 1e-12 && halfErr < 1e-12 && ...
                    out.Swss >= -tol && out.Swfs >= -tol && ...
                    out.Swss <= P.wing.S + tol && ...
                    out.Swfs <= P.wing.S + tol && ...
                    strcmp(out.wingLoadAssemblyModel, ...
                    'NUAA_EQ16_22_ZONE_SUM');
            end
        end
        result = make_result(ok, sprintf(['maxAreaSumErr=%.3e ' ...
            'minArea=%.6g maxArea=%.6g'], maxSumErr, minArea, maxArea));
    end

    function result = test_numeric_robustness()
        cases = [ ...
            0,   0,   5.0; ...
            5,   0,   6.0; ...
            35, 45,   8.0; ...
            100,90,   3.0; ...
            60, 75,  10.0];
        ok = true;
        maxNorm = 0;
        messages = cell(size(cases,1), 1);
        for iCase = 1:size(cases,1)
            V = cases(iCase,1);
            betaM = cases(iCase,2)*d2r;
            vi = cases(iCase,3);
            x = [V; 0.2; 0.05*max(V,1); 0.01; -0.02; 0.015; 0; 0; 0];
            rotor = make_rotor(betaM, vi, min(0.9*P.wing.muMax, V/180));
            [F,M,out] = wing_model(x, zeros(7,1), betaM, zeros(3,1), ...
                rotor, rotor, P);
            y = [F; M; collect_region_values(out)];
            caseOk = is_real_finite(y) && is_real_finite(out.Swss) && ...
                is_real_finite(out.Swfs);
            ok = ok && caseOk;
            maxNorm = max(maxNorm, norm([F; M]));
            messages{iCase} = sprintf('V=%.1f beta=%.1f ok=%d', ...
                V, cases(iCase,2), caseOk);
        end
        result = make_result(ok, sprintf('%s; maxLoadNorm=%.3e', ...
            strjoin(messages, '; '), maxNorm));
    end

    function result = test_branch_weight_insensitive()
        betaM = 35*d2r;
        x = [32; -0.4; 18; 0.02; -0.03; 0.015; 0; 0; 0];
        uCtrl = zeros(7,1);
        uCtrl(5) = 1.5*d2r;
        rotor = make_rotor(betaM, 7.5, 0.08);

        P1 = P;
        P2 = P;
        P1.wing.normalFlowRatio = 0.05;
        P1.wing.normalFlowBlendHalfWidth = 0.02;
        P2.wing.normalFlowRatio = 0.90;
        P2.wing.normalFlowBlendHalfWidth = 0.20;

        [F1,M1,out1] = wing_model(x, uCtrl, betaM, zeros(3,1), ...
            rotor, rotor, P1);
        [F2,M2,out2] = wing_model(x, uCtrl, betaM, zeros(3,1), ...
            rotor, rotor, P2);
        loadErr = norm([F1-F2; M1-M2]);
        weightDelta = max_abs_region_delta(out1, out2, ...
            'normalFlowBranchWeight');
        deprecatedOk = all_weighted_regions_deprecated(out1) && ...
            all_weighted_regions_deprecated(out2);
        ok = loadErr < 1e-9 && weightDelta > 0.1 && deprecatedOk;
        result = make_result(ok, sprintf(['loadErr=%.3e ' ...
            'weightDelta=%.3e deprecatedOk=%d'], loadErr, weightDelta, ...
            deprecatedOk));
    end

    function result = test_trim_smoke()
        cases = trim_smoke_cases();
        points = repmat(empty_trim_point(), numel(cases), 1);
        ok = true;
        messages = cell(numel(cases), 1);
        for iCase = 1:numel(cases)
            points(iCase) = run_trim_case(cases(iCase));
            ok = ok && points(iCase).finite && points(iCase).converged && ...
                points(iCase).residualNorm < P.trim.residualTolerance;
            messages{iCase} = sprintf('%s conv=%d finite=%d res=%.3e', ...
                points(iCase).label, points(iCase).converged, ...
                points(iCase).finite, points(iCase).residualNorm);
        end
        report.trimSmoke = points;
        result = make_result(ok, strjoin(messages, '; '));
    end

    function result = test_lightweight_nuaa_trend()
        if isempty(report.trimSmoke)
            result = make_result(false, 'trim smoke did not run first');
            return;
        end
        finite = all([report.trimSmoke.finite]);
        converged = all([report.trimSmoke.converged]);
        if finite && converged
            report.nuaaTrendStatus = 'PARTIAL';
            report.nuaaTrendMessage = ['Lightweight Fig.5/Fig.6-related ' ...
                'coverage used three representative trim points only; no ' ...
                'digitized NUAA curve comparison was performed.'];
            ok = true;
        elseif finite
            report.nuaaTrendStatus = 'PARTIAL';
            report.nuaaTrendMessage = ['Some representative trim points did ' ...
                'not converge; outputs remained finite.'];
            ok = true;
        else
            report.nuaaTrendStatus = 'FAIL';
            report.nuaaTrendMessage = ['At least one representative trim ' ...
                'point produced non-finite output.'];
            ok = false;
        end
        result = make_result(ok, report.nuaaTrendMessage);
    end

    function cases = trim_smoke_cases()
        cases = repmat(struct('label','', 'mode','', 'V',NaN, ...
            'betaM',NaN), 3, 1);
        cases(1) = struct('label','helicopter_endpoint', ...
            'mode','helicopter_longitudinal', 'V',0, 'betaM',0);
        cases(2) = struct('label','conversion_35mps_45deg', ...
            'mode','conversion_longitudinal', 'V',35, 'betaM',45*d2r);
        cases(3) = struct('label','airplane_100mps', ...
            'mode','airplane_longitudinal', 'V',100, 'betaM',90*d2r);
    end

    function point = run_trim_case(caseDef)
        point = empty_trim_point();
        point.label = caseDef.label;
        point.V = caseDef.V;
        point.betaM = caseDef.betaM;
        try
            condition = struct('V', caseDef.V, 'betaM', caseDef.betaM, ...
                'gamma', 0);
            definition = make_trim_definition(caseDef.mode, condition, P);
            [xTrim,uTrim,trimReport] = trim_general(condition, ...
                definition, P);
            [xdot,eomOut] = tiltrotor_eom(xTrim, uTrim, ...
                caseDef.betaM, P);
            point.converged = trimReport.converged;
            point.residualNorm = trimReport.residualNorm;
            point.fullResidualNorm = norm(xdot);
            point.finite = is_real_finite(xTrim) && ...
                is_real_finite(uTrim) && is_real_finite(xdot) && ...
                is_real_finite([eomOut.components.F; eomOut.components.M]);
            point.exitflag = trimReport.exitflag;
        catch ME
            point.errorIdentifier = ME.identifier;
            point.errorMessage = ME.message;
        end
    end

    function point = empty_trim_point()
        point = struct('label','', 'V',NaN, 'betaM',NaN, ...
            'converged',false, 'finite',false, 'residualNorm',Inf, ...
            'fullResidualNorm',Inf, 'exitflag',NaN, ...
            'errorIdentifier','', 'errorMessage','');
    end

    function values = collect_region_values(out)
        values = [];
        for iRegion = 1:numel(out.regions)
            r = out.regions{iRegion};
            if isfield(r, 'F')
                values = [values; r.F(:); r.M(:); r.Vlocal(:); ...
                    r.qbar; r.alpha; r.beta; r.CL; r.CD; r.Cm]; %#ok<AGROW>
            end
        end
    end

    function rotor = make_rotor(betaM, inducedVelocity, mu)
        rotor.inducedVelocity = inducedVelocity;
        rotor.eT = [sin(betaM); 0; -cos(betaM)];
        rotor.muLong = mu;
        rotor.muLat = 0;
    end

    function value = max_abs_region_delta(outA, outB, fieldName)
        value = 0;
        for iRegion = 1:numel(outA.regions)
            if isfield(outA.regions{iRegion}, fieldName) && ...
                    isfield(outB.regions{iRegion}, fieldName)
                value = max(value, abs(outA.regions{iRegion}.(fieldName) - ...
                    outB.regions{iRegion}.(fieldName)));
            end
        end
    end

    function ok = all_weighted_regions_deprecated(out)
        ok = true;
        checked = false;
        for iRegion = 1:numel(out.regions)
            r = out.regions{iRegion};
            if ~isfield(r, 'normalFlowBranchWeight')
                continue;
            end
            checked = true;
            ok = ok && isfield(r, 'normalFlowBranchWeightDeprecated') && ...
                logical(r.normalFlowBranchWeightDeprecated);
        end
        ok = ok && checked;
    end

    function tf = is_real_finite(value)
        tf = isreal(value) && all(isfinite(value(:)));
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
        report.cases(end+1,1).name = name;
        report.cases(end).passed = result.passed;
        report.cases(end).message = result.message;
    end

    function value = ternary(condition, a, b)
        if condition
            value = a;
        else
            value = b;
        end
    end
end
