function report = check_mass_inertia_geometry()
%CHECK_MASS_INERTIA_GEOMETRY Audit mass, inertia, CG, and geometry chain.
% These checks validate internal identities and broad scale only. They are
% not XV-15 validation and do not tune any production parameter.

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir,'model'));
addpath(fullfile(rootDir,'analysis'));

P = params_nominal();
d2r = pi/180;

report.cases = struct('name',{},'passed',{},'message',{});
report.findings = struct('severity',{},'category',{},'message',{});
report.parameterProvenance = parameter_provenance();
report.representativeAngles = [0; pi/4; pi/2];
report.tolerances.geometryIdentity = 1e-12;
report.tolerances.decouplingIdentity = 1e-12;
report.behaviorPreservation = struct();

callCount.total_forces_moments = 0;
callCount.rotor_model_bemt = 0;

add_case('mass positive and invariant with tilt', @test_mass_invariant);
add_case('CG shift endpoint identities', @test_cg_shift_endpoints);
add_case('CG shift continuity and central derivative', @test_cg_shift_derivative);
add_case('legacy shared-radius behavior preserved', @test_legacy_radius_identity);
add_case('moving-mass radius independent of hub radius', @test_mass_radius_independence);
add_case('hub radius independent of moving-mass radius', @test_hub_radius_independence);
add_case('deprecated RH alias has no production effect', @test_deprecated_alias_inactive);
add_case('inertia symmetry and positive definiteness', @test_inertia_spd);
add_case('principal moments and radii plausible', @test_principal_radii);
add_case('KI interpreted per radian', @test_ki_per_radian);
add_case('left/right rotor hub mirror geometry', @test_rotor_mirror);
add_case('rotor disk non-overlap clearance', @test_rotor_clearance);
add_case('rotor/wing/nacelle broad geometry relation', @test_wing_rotor_geometry);
add_case('tail locations aft of current CG', @test_tail_aft);
add_case('component CG-relative position identities', @test_component_positions);
add_case('repeated calls deterministic and finite', @test_deterministic_finite);

report.modelCallCount = callCount;
report.allPassed = all([report.cases.passed]);

fprintf('\nMass/inertia/geometry checks\n');
fprintf('============================\n');
fprintf('%-54s : %s\n', 'case', 'status');
for k = 1:numel(report.cases)
    status = ternary(report.cases(k).passed, 'PASS', 'FAIL');
    fprintf('%-54s : %s\n', report.cases(k).name, status);
    if ~report.cases(k).passed
        fprintf('  %s\n', report.cases(k).message);
    end
end
fprintf('Model calls: total_forces_moments=%d, rotor_model_bemt=%d\n', ...
    report.modelCallCount.total_forces_moments, ...
    report.modelCallCount.rotor_model_bemt);
fprintf(['RH split tolerances: geometry=%.1e m, decoupling=%.1e m; ' ...
    'worst legacy CG=%.3e m, hub=%.3e m\n'], ...
    report.tolerances.geometryIdentity, ...
    report.tolerances.decouplingIdentity, ...
    report.behaviorPreservation.legacyCgMaxError, ...
    report.behaviorPreservation.legacyHubMaxError);
fprintf('All mass/inertia/geometry checks passed: %d\n', report.allPassed);

    function result = test_mass_invariant()
        betas = report.representativeAngles;
        masses = zeros(numel(betas),1);
        for i = 1:numel(betas)
            mp = mass_properties(betas(i), P);
            masses(i) = mp.mass;
        end
        ok = all(masses > 0) && all(abs(masses - P.mass.m) < 1e-12);
        result = make_result(ok, sprintf('Mass values: %s.', mat2str(masses.')));
    end

    function result = test_cg_shift_endpoints()
        betas = report.representativeAngles;
        err = 0;
        for i = 1:numel(betas)
            betaM = betas(i);
            mp = mass_properties(betaM, P);
            expected = [P.mass.mNac*P.mass.RH_mass*sin(betaM)/P.mass.m;
                        0;
                        P.mass.mNac*P.mass.RH_mass*(1 - cos(betaM))/P.mass.m];
            err = max(err, norm(mp.cgShift - expected));
        end
        mp0 = mass_properties(0, P);
        mp90 = mass_properties(pi/2, P);
        signOk = norm(mp0.cgShift) < 1e-14 && ...
            mp90.cgShift(1) > 0 && mp90.cgShift(3) > 0 && ...
            abs(mp90.cgShift(2)) < 1e-14;
        result = make_result(err < 1e-14 && signOk, ...
            sprintf('CG shift identity error %.3e, signOk=%d.', err, signOk));
    end

    function result = test_cg_shift_derivative()
        beta0 = pi/4;
        h = 1e-5;
        mpP = mass_properties(beta0 + h, P);
        mpM = mass_properties(beta0 - h, P);
        dNum = (mpP.cgShift - mpM.cgShift)/(2*h);
        dExact = [P.mass.mNac*P.mass.RH_mass*cos(beta0)/P.mass.m;
                  0;
                  P.mass.mNac*P.mass.RH_mass*sin(beta0)/P.mass.m];
        err = norm(dNum - dExact);
        result = make_result(is_real_finite(dNum) && err < 1e-11, ...
            sprintf('CG derivative error %.3e.', err));
    end

    function result = test_legacy_radius_identity()
        legacyRadius = 0.75;
        cgErr = 0;
        hubErr = 0;
        outputsFinite = true;
        for i = 1:numel(report.representativeAngles)
            betaM = report.representativeAngles(i);
            c = representative_call(betaM, P);
            expectedCg = legacy_cg_shift(betaM, legacyRadius, P);
            cgErr = max(cgErr, norm(c.info.massProperties.cgShift - expectedCg));
            hubErr = max(hubErr, absolute_hub_error(c.info, betaM, legacyRadius, expectedCg, P));
            outputsFinite = outputsFinite && is_real_finite(collect_outputs(c));
        end
        report.behaviorPreservation.legacyCgMaxError = cgErr;
        report.behaviorPreservation.legacyHubMaxError = hubErr;
        report.behaviorPreservation.legacyRepresentativeOutputsFinite = outputsFinite;
        ok = cgErr <= report.tolerances.geometryIdentity && ...
            hubErr <= report.tolerances.geometryIdentity && outputsFinite;
        result = make_result(ok, sprintf( ...
            'Legacy identity errors: CG %.3e m, absolute hub %.3e m, finite=%d.', ...
            cgErr, hubErr, outputsFinite));
    end

    function result = test_mass_radius_independence()
        betaM = pi/4;
        radiusDelta = 0.125; % Synthetic separation perturbation, m.
        Pmass = P;
        Pmass.mass.RH_mass = P.mass.RH_mass + radiusDelta;
        mp0 = mass_properties(betaM, P);
        mp1 = mass_properties(betaM, Pmass);
        expectedDelta = legacy_cg_shift(betaM, radiusDelta, P);
        cgDeltaErr = norm((mp1.cgShift - mp0.cgShift) - expectedDelta);

        c = representative_call(betaM, Pmass);
        hubErr = absolute_hub_error(c.info, betaM, P.rotor.RH_hub, mp1.cgShift, Pmass);
        report.behaviorPreservation.massPerturbCgError = cgDeltaErr;
        report.behaviorPreservation.massPerturbAbsoluteHubError = hubErr;
        ok = cgDeltaErr <= report.tolerances.decouplingIdentity && ...
            hubErr <= report.tolerances.decouplingIdentity;
        result = make_result(ok, sprintf( ...
            'Mass-radius perturbation errors: CG delta %.3e m, absolute hub %.3e m.', ...
            cgDeltaErr, hubErr));
    end

    function result = test_hub_radius_independence()
        betaM = pi/4;
        radiusDelta = 0.125; % Synthetic separation perturbation, m.
        Phub = P;
        Phub.rotor.RH_hub = P.rotor.RH_hub + radiusDelta;
        mp0 = mass_properties(betaM, P);
        mp1 = mass_properties(betaM, Phub);
        cgErr = norm(mp1.cgShift - mp0.cgShift);

        c = representative_call(betaM, Phub);
        hubErr = absolute_hub_error(c.info, betaM, Phub.rotor.RH_hub, mp1.cgShift, Phub);
        report.behaviorPreservation.hubPerturbCgError = cgErr;
        report.behaviorPreservation.hubPerturbAbsoluteHubError = hubErr;
        ok = cgErr <= report.tolerances.decouplingIdentity && ...
            hubErr <= report.tolerances.decouplingIdentity;
        result = make_result(ok, sprintf( ...
            'Hub-radius perturbation errors: CG %.3e m, absolute hub %.3e m.', ...
            cgErr, hubErr));
    end

    function result = test_deprecated_alias_inactive()
        betaM = pi/4;
        Palias = P;
        Palias.mass.RH = P.mass.RH + 10.0; % Synthetic deprecated-field perturbation.
        mp0 = mass_properties(betaM, P);
        mp1 = mass_properties(betaM, Palias);
        c0 = representative_call(betaM, P);
        c1 = representative_call(betaM, Palias);
        cgErr = norm(mp1.cgShift - mp0.cgShift);
        outputErr = norm(collect_outputs(c1) - collect_outputs(c0));
        exactMatch = isequal(collect_outputs(c1), collect_outputs(c0));
        report.behaviorPreservation.deprecatedAliasCgError = cgErr;
        report.behaviorPreservation.deprecatedAliasOutputError = outputErr;
        report.behaviorPreservation.deprecatedAliasExactMatch = exactMatch;
        ok = cgErr == 0 && outputErr == 0 && exactMatch;
        result = make_result(ok, sprintf( ...
            'Deprecated-alias errors: CG %.3e, representative output %.3e, exact=%d.', ...
            cgErr, outputErr, exactMatch));
    end

    function result = test_inertia_spd()
        betas = report.representativeAngles;
        ok = true;
        minEig = Inf;
        symErr = 0;
        for i = 1:numel(betas)
            mp = mass_properties(betas(i), P);
            symErr = max(symErr, mp.inertiaSymmetryError);
            minEig = min(minEig, mp.minInertiaEigenvalue);
            ok = ok && mp.inertiaSymmetryError < 1e-12 && ...
                mp.minInertiaEigenvalue > 0;
        end
        result = make_result(ok, ...
            sprintf('max symmetry error %.3e, min eigenvalue %.6e.', symErr, minEig));
    end

    function result = test_principal_radii()
        betas = report.representativeAngles;
        maxSpan = max([P.wing.b, 2*P.rotor.pivotY, norm(P.htail.rAC)]);
        ok = true;
        worstRadius = 0;
        for i = 1:numel(betas)
            mp = mass_properties(betas(i), P);
            ok = ok && is_real_finite(mp.principalMoments) && ...
                is_real_finite(mp.radiusOfGyration) && ...
                all(mp.principalMoments > 0) && ...
                all(mp.radiusOfGyration > 0.2) && ...
                all(mp.radiusOfGyration < maxSpan);
            worstRadius = max(worstRadius, max(mp.radiusOfGyration));
        end
        result = make_result(ok, ...
            sprintf('Maximum radius of gyration %.6f m.', worstRadius));
    end

    function result = test_ki_per_radian()
        betaM = pi/4;
        mp = mass_properties(betaM, P);
        expected = 0.5*((P.mass.I0 - betaM*P.mass.KI) + ...
            (P.mass.I0 - betaM*P.mass.KI).');
        errMid = norm(mp.I - expected, 'fro');

        mp90 = mass_properties(pi/2, P);
        expectedDelta = 0.5*((pi/2)*P.mass.KI + ((pi/2)*P.mass.KI).');
        actualDelta = 0.5*(P.mass.I0 + P.mass.I0.') - mp90.I;
        errEnd = norm(actualDelta - expectedDelta, 'fro');
        ok = errMid < 1e-10 && errEnd < 1e-10;
        result = make_result(ok, ...
            sprintf('KI per-radian errors: mid %.3e, endpoint %.3e.', errMid, errEnd));
    end

    function result = test_rotor_mirror()
        betas = report.representativeAngles;
        err = 0;
        for i = 1:numel(betas)
            betaM = betas(i);
            mp = mass_properties(betaM, P);
            rL = rotor_hub(betaM, -1, mp.cgShift);
            rR = rotor_hub(betaM, +1, mp.cgShift);
            err = max(err, norm([rL(1)-rR(1); rL(2)+rR(2); rL(3)-rR(3)]));
        end
        result = make_result(err < 1e-12, ...
            sprintf('Rotor hub mirror error %.3e.', err));
    end

    function result = test_rotor_clearance()
        centerlineSeparation = 2*P.rotor.pivotY;
        diskDiameter = 2*P.rotor.R;
        clearance = centerlineSeparation - diskDiameter;
        ok = centerlineSeparation > 0 && clearance > 0;
        result = make_result(ok, ...
            sprintf('Centerline separation %.6f m, disk clearance %.6f m.', ...
                centerlineSeparation, clearance));
    end

    function result = test_wing_rotor_geometry()
        semispan = P.wing.b/2;
        ok = P.rotor.pivotY > P.rotor.R && ...
            P.rotor.pivotY <= semispan + 1e-12 && ...
            P.wing.yFreeAC >= 0 && P.wing.ySlipAC >= 0 && ...
            P.wing.yFreeAC <= semispan && P.wing.ySlipAC <= semispan && ...
            abs(P.rotor.pivotX - P.wing.xAC) <= 2*P.wing.c;
        result = make_result(ok, ...
            sprintf('pivotY %.6f, semispan %.6f, rotor radius %.6f.', ...
                P.rotor.pivotY, semispan, P.rotor.R));
    end

    function result = test_tail_aft()
        betas = report.representativeAngles;
        ok = true;
        worstH = Inf;
        worstV = Inf;
        for i = 1:numel(betas)
            mp = mass_properties(betas(i), P);
            hX = P.htail.rAC(1) - mp.cgShift(1);
            vX = P.vtail.xAC - mp.cgShift(1);
            worstH = min(worstH, -hX);
            worstV = min(worstV, -vX);
            ok = ok && hX < 0 && vX < 0;
        end
        result = make_result(ok, ...
            sprintf('Minimum aft margins: htail %.6f m, vtail %.6f m.', worstH, worstV));
    end

    function result = test_component_positions()
        betaM = pi/4;
        c = representative_call(betaM);
        mp = c.info.massProperties;
        err = 0;

        err = max(err, norm(c.info.rotorLeft.rHub - rotor_hub(betaM, -1, mp.cgShift)));
        err = max(err, norm(c.info.rotorRight.rHub - rotor_hub(betaM, +1, mp.cgShift)));
        err = max(err, wing_region_error(c.info.wing, mp.cgShift));
        err = max(err, norm(c.info.fuselage.rAC - (P.fuselage.rAC - mp.cgShift)));
        err = max(err, norm(c.info.horizontalTail.rAC - (P.htail.rAC - mp.cgShift)));
        err = max(err, vtail_error(c.info.verticalTail, mp.cgShift));

        result = make_result(err < 1e-12, ...
            sprintf('Component current-CG-relative position error %.3e.', err));
    end

    function result = test_deterministic_finite()
        betaM = pi/4;
        c1 = representative_call(betaM);
        c2 = representative_call(betaM);
        y1 = collect_outputs(c1);
        y2 = collect_outputs(c2);
        ok = is_real_finite(y1) && is_real_finite(y2) && isequal(y1, y2);
        result = make_result(ok, ...
            sprintf('Deterministic output difference norm %.3e.', norm(y1-y2)));
    end

    function c = representative_call(betaM, thisP)
        if nargin < 2
            thisP = P;
        end
        x = [28; 1.0; -0.8; 0.02; -0.015; 0.01; 0.01; -0.02; 0];
        u = [14*d2r; 0; 0.5*d2r; 0; 0.5*d2r; -1*d2r; 0.5*d2r];
        callCount.total_forces_moments = callCount.total_forces_moments + 1;
        callCount.rotor_model_bemt = callCount.rotor_model_bemt + 2;
        [F,M,info] = total_forces_moments(x, u, betaM, thisP);
        c = struct('x',x,'u',u,'betaM',betaM,'F',F,'M',M,'info',info);
    end

    function cgShift = legacy_cg_shift(betaM, radius, thisP)
        cgShift = [thisP.mass.mNac*radius*sin(betaM)/thisP.mass.m;
                   0;
                   thisP.mass.mNac*radius*(1 - cos(betaM))/thisP.mass.m];
    end

    function err = absolute_hub_error(info, betaM, radius, cgShift, thisP)
        expectedLeft = legacy_absolute_hub(betaM, -1, radius, thisP);
        expectedRight = legacy_absolute_hub(betaM, +1, radius, thisP);
        actualLeft = info.rotorLeft.rHub + cgShift;
        actualRight = info.rotorRight.rHub + cgShift;
        err = max(norm(actualLeft - expectedLeft), norm(actualRight - expectedRight));
    end

    function rHub0 = legacy_absolute_hub(betaM, side, radius, thisP)
        rHub0 = [thisP.rotor.pivotX + radius*sin(betaM);
                 side*thisP.rotor.pivotY;
                 thisP.rotor.pivotZ - radius*cos(betaM)];
    end

    function err = wing_region_error(wing, cgShift)
        err = 0;
        for i = 1:numel(wing.regions)
            region = wing.regions{i};
            if ~isfield(region, 'rAC') || region.area <= 0
                continue;
            end
            if region.inSlipstream
                expectedY = region.side*P.wing.ySlipAC;
            else
                expectedY = region.side*P.wing.yFreeAC;
            end
            expected = [P.wing.xAC; expectedY; P.wing.zAC] - cgShift;
            err = max(err, norm(region.rAC - expected));
        end
    end

    function err = vtail_error(vtail, cgShift)
        err = 0;
        for i = 1:numel(vtail.fins)
            fin = vtail.fins{i};
            if ~isfield(fin, 'rAC')
                err = Inf;
                return;
            end
            expected = [P.vtail.xAC; fin.side*P.vtail.yAC; P.vtail.zAC] - cgShift;
            err = max(err, norm(fin.rAC - expected));
        end
    end

    function y = collect_outputs(c)
        y = [c.F; c.M; c.info.massProperties.cgShift; ...
            c.info.massProperties.I(:); ...
            c.info.rotorLeft.rHub; c.info.rotorRight.rHub; ...
            c.info.fuselage.rAC; c.info.horizontalTail.rAC];
        for i = 1:numel(c.info.wing.regions)
            region = c.info.wing.regions{i};
            if isfield(region, 'rAC')
                y = [y; region.rAC]; %#ok<AGROW>
            end
        end
        for i = 1:numel(c.info.verticalTail.fins)
            fin = c.info.verticalTail.fins{i};
            if isfield(fin, 'rAC')
                y = [y; fin.rAC]; %#ok<AGROW>
            end
        end
    end

    function rHub = rotor_hub(betaM, side, cgShift)
        rHub0 = [P.rotor.pivotX + P.rotor.RH_hub*sin(betaM);
                 side*P.rotor.pivotY;
                 P.rotor.pivotZ - P.rotor.RH_hub*cos(betaM)];
        rHub = rHub0 - cgShift;
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

    function add_case(name, fun)
        report.cases(end+1,1).name = name;
        try
            result = fun();
            report.cases(end).passed = result.passed;
            report.cases(end).message = result.message;
        catch ME
            report.cases(end).passed = false;
            report.cases(end).message = ME.message;
        end
    end

    function provenance = parameter_provenance()
        provenance = struct('parameter',{},'variable',{},'classification',{},'note',{});
        add_param('total mass', 'P.mass.m', 'ASSUMED_CONCEPT', ...
            'Concept-scale aircraft mass in params_nominal; not treated as XV-15 measured data.');
        add_param('moving nacelle/rotor mass total', 'P.mass.mNac', 'ASSUMED_CONCEPT', ...
            'Interpreted by PHYSICS_AND_CODE_AUDIT as total moving mass for left and right tilt assemblies.');
        add_param('moving-mass lever arm', 'P.mass.RH_mass', 'ASSUMED_CONCEPT', ...
            'Equivalent moving-mass CG distance from tilt axis.');
        add_param('rotor-hub tilt radius', 'P.rotor.RH_hub', 'ASSUMED_CONCEPT', ...
            'Rotor-hub center distance from the tilt axis.');
        add_param('deprecated shared-radius alias', 'P.mass.RH', 'DEPRECATED_UNUSED', ...
            'Compatibility metadata only; production calculations do not read it.');
        add_param('nominal inertia matrix', 'P.mass.I0', 'ASSUMED_CONCEPT', ...
            'Concept nominal inertia at betaM=0; NASA table mapping remains unverified.');
        add_param('inertia slope per radian', 'P.mass.KI', 'ASSUMED_CONCEPT', ...
            'Low-order inertia change coefficient interpreted per radian by current code comments.');
        add_param('rotor pivot x/y/z', 'P.rotor.pivotX/Y/Z', 'ASSUMED_CONCEPT', ...
            'Concept rotor pivot geometry; no verified source in this phase.');
        add_param('wing aerodynamic centers', 'P.wing.xAC/yFreeAC/ySlipAC/zAC', 'ASSUMED_CONCEPT', ...
            'Concept wing load stations and slipstream partition points.');
        add_param('fuselage aerodynamic center', 'P.fuselage.rAC', 'ASSUMED_CONCEPT', ...
            'Concept fuselage reference point.');
        add_param('horizontal tail aerodynamic center', 'P.htail.rAC', 'ASSUMED_CONCEPT', ...
            'Concept tail reference point.');
        add_param('vertical tail aerodynamic centers', 'P.vtail.xAC/yAC/zAC', 'ASSUMED_CONCEPT', ...
            'Concept twin-fin reference points.');
        add_param('CG shift formula', 'mp.cgShift', 'DERIVED', ...
            'Derived from mNac, RH_mass, betaM, and total mass by the implemented low-order formula.');
        add_param('principal moments/radii diagnostics', 'mp.principalMoments/radiusOfGyration', 'DERIVED', ...
            'Derived from the inertia matrix returned by mass_properties.');

        function add_param(parameter, variable, classification, note)
            provenance(end+1,1).parameter = parameter;
            provenance(end).variable = variable;
            provenance(end).classification = classification;
            provenance(end).note = note;
        end
    end

    function value = ternary(condition, a, b)
        if condition
            value = a;
        else
            value = b;
        end
    end
end
