function report = check_berger13_pr3_actuator_wing()
%CHECK_BERGER13_PR3_ACTUATOR_WING Focused PR3 physics/interface checks.

P13 = params_berger13();
d2r = pi/180;
x = zeros(13,1);
x(10:11) = 45*d2r;
u = zeros(10,1);
u(9:10) = x(10:11);

names = {};
passed = [];
messages = {};
run_case('distinct torque and angle-command contracts', @case_contracts);
run_case('nominal command step and reaction torque', @case_step);
run_case('angle rate acceleration and torque limits observable', @case_limits);
run_case('left/right bandwidth and damping may differ', @case_asymmetry);
run_case('external delay context is explicit', @case_delay);
run_case('command freeze and kinematic lock are distinct', @case_faults);
run_case('independent wing symmetric degradation', @case_wing_symmetric);
run_case('positive/negative betaDiff mirror loads', @case_wing_mirror);
run_case('all component moments use actual total CG', @case_moment_reference);
run_case('actual CG changes fixed-component load evaluation', @case_fixed_component);
run_case('mass moment and complete inertia reconstruction', @case_mass);
run_case('fixed inertia residual is invariant at fixed mean angle', @case_fixed_inertia);
run_case('actuator action-reaction sign and coupling boundary', @case_reaction);
run_case('component sum has no force or moment double count', @case_component_sum);
run_case('parameterized nacelle-rate gyroscopic moment', @case_gyro);
run_case('command trim and three-step A/B', @case_trim_linear);
run_case('torque interface remains callable and finite', @case_torque);

report.names = names;
report.passed = passed;
report.messages = messages;
report.allPassed = all(passed);
fprintf('\nBerger13 PR3 actuator/wing checks\n');
fprintf('=================================\n');
for k = 1:numel(names)
    fprintf('%-56s : %s\n',names{k},ternary(passed(k),'PASS','FAIL'));
    if ~passed(k)
        fprintf('  %s\n',messages{k});
    end
end
fprintf('All passed: %d\n',report.allPassed);

    function case_contracts()
        torqueNames = get_control_input_names_13x10();
        commandNames = get_command_input_names_13x10();
        assert(strcmp(torqueNames{9},'nacelleTorqueLeft'));
        assert(strcmp(commandNames{9},'betaMLCommand'));
        assert(~strcmp(torqueNames{9},commandNames{9}));
    end

    function case_step()
        us = u;
        us(9:10) = us(9:10)+2*d2r;
        [xdot,out] = tiltrotor_eom_13x10_command(x,us,P13);
        assert(all(xdot(12:13) > 0));
        assert(out.MactuatorReaction(2) > 0);
        assert(all(isfinite(xdot)) && isreal(xdot));
    end

    function case_limits()
        Plim = P13;
        Plim.commandActuator.left.accelLim = 1*d2r;
        Plim.nacelle.torqueLim = Plim.nacelle.I*0.5*d2r;
        xlim = x;
        xlim(12) = 2*Plim.nacelle.betaDotLim;
        ulim = u;
        ulim(9) = 2*pi;
        [~,out] = tiltrotor_eom_13x10_command(xlim,ulim,Plim);
        flags = out.nacelle.left.flags;
        assert(flags.commandClamped && flags.rateClamped);
        assert(flags.accelerationClamped || flags.torqueClamped);
        assert(abs(out.nacelle.left.betaDot) <= ...
            Plim.nacelle.betaDotLim);
    end

    function case_asymmetry()
        Pa = P13;
        Pa.commandActuator.left.omegaN = 2;
        Pa.commandActuator.right.omegaN = 6;
        ua = u;
        ua(9:10) = ua(9:10)+0.2*d2r;
        [xdot,~] = tiltrotor_eom_13x10_command(x,ua,Pa);
        assert(xdot(13) > xdot(12));
    end

    function case_delay()
        Pd = P13;
        Pd.commandActuator.left.commandDelay = 0.1;
        ud = u;
        ud(9:10) = ud(9:10)+d2r;
        context.left.delayedCommand = x(10);
        [xdot,out] = tiltrotor_eom_13x10_command(x,ud,Pd,context);
        assert(abs(xdot(12)) < 1e-14 && xdot(13) > 0);
        assert(out.nacelle.left.flags.delayActive);
    end

    function case_faults()
        Pf = P13;
        Pf.commandActuator.left.kinematicLock = true;
        Pf.commandActuator.right.commandFreeze = true;
        Pf.commandActuator.right.frozenCommand = x(11)+0.5*d2r;
        Pf.commandActuator.left.rateScale = 0.25;
        xf = x;
        xf(12) = P13.nacelle.betaDotLim;
        uf = u;
        uf(9:10) = uf(9:10)+d2r;
        [xdot,out] = tiltrotor_eom_13x10_command(xf,uf,Pf);
        assert(xdot(10) == 0 && xdot(12) == 0);
        assert(xdot(13) > 0);
        assert(out.nacelle.left.flags.kinematicLock);
        assert(out.nacelle.right.flags.commandFrozen);
        assert(out.nacelle.left.unresolvedKinematicLockTorque ~= 0);
        assert(~out.nacelle.left.constraintTorqueAvailable);
        assert(out.nacelle.left.rateLimitApplied == ...
            0.25*P13.nacelle.betaDotLim);
    end

    function case_wing_symmetric()
        [~,~,info] = total_forces_moments_13x10(x,zeros(10,1),P13);
        assert(norm(info.wingIndependent.deltaF) < 1e-8);
        assert(norm(info.wingIndependent.deltaM) < 1e-8);
        assert(info.usedIndependentWingLoads);
    end

    function case_wing_mirror()
        delta = 0.5*d2r;
        xp = x;
        xm = x;
        xp(10:11) = [45-delta/d2r;45+delta/d2r]*d2r;
        xm(10:11) = [45+delta/d2r;45-delta/d2r]*d2r;
        [Fp,Mp] = total_forces_moments_13x10(xp,zeros(10,1),P13);
        [Fm,Mm] = total_forces_moments_13x10(xm,zeros(10,1),P13);
        assert(norm(Fp-[Fm(1);-Fm(2);Fm(3)]) < 1e-5*max(1,norm(Fp)));
        assert(norm(Mp-[-Mm(1);Mm(2);-Mm(3)]) < 1e-5*max(1,norm(Mp)));
    end

    function case_mass()
        mp = mass_properties_berger13(45*d2r,45*d2r,P13);
        base = mass_properties(45*d2r,P13.base);
        assert(norm(mp.cgShift-base.cgShift) < 1e-12);
        assert(norm(mp.I-base.I,'fro') < 1e-10);
        mpa = mass_properties_berger13(44*d2r,46*d2r,P13);
        mpb = mass_properties_berger13(46*d2r,44*d2r,P13);
        mirror = diag([1,-1,1]);
        assert(norm(mpa.cgShift-mirror*mpb.cgShift) < 1e-12);
        assert(norm(mpa.I-mirror*mpb.I*mirror,'fro') < 1e-8);
        assert(all(eig(mpa.I)>0));
        assert(abs(sum(struct2array(mpa.massDecomposition))- ...
            2*mpa.massDecomposition.total) < 1e-10);
        assert(norm(mpa.massMomentResidual) < 1e-10);
        assert(norm(mpa.inertiaReconstructionResidual,'fro') < 1e-10);
    end

    function case_moment_reference()
        xa = x;
        xa(10:11) = [42;48]*d2r;
        [~,~,info] = total_forces_moments_13x10( ...
            xa,zeros(10,1),P13);
        assert(strcmp(info.forceMomentReference,'ACTUAL_TOTAL_CG'));
        assert(norm(info.momentReferenceCG- ...
            info.massProperties.cgShift) < 1e-14);
        namesActual = cellfun(@(c)c.name,info.components, ...
            'UniformOutput',false);
        assert(isequal(namesActual(:),{'rotorLeft';'rotorRight';'wing'; ...
            'fuselage';'horizontalTail';'verticalTail'}));
    end

    function case_fixed_component()
        xa = x;
        xa(1:6) = [35;2;8;0.03;-0.02;0.04];
        xa(10:11) = [42;48]*d2r;
        [~,~,info] = total_forces_moments_13x10( ...
            xa,zeros(10,1),P13);
        [Fdirect,Mdirect] = fuselage_model(xa(1:9), ...
            info.massProperties.cgShift,P13.base);
        assert(norm(Fdirect-info.fuselage.F) < 1e-12);
        assert(norm(Mdirect-info.fuselage.M) < 1e-12);
        baseCG = info.massProperties.baseAverage.cgShift;
        [~,Mbase] = fuselage_model(xa(1:9),baseCG,P13.base);
        assert(norm(Mdirect-Mbase) > 1e-8);
    end

    function case_fixed_inertia()
        mpa = mass_properties_berger13(43*d2r,47*d2r,P13);
        mpb = mass_properties_berger13(44*d2r,46*d2r,P13);
        assert(norm(mpa.fixedComponent.inertiaAboutOwnCG- ...
            mpb.fixedComponent.inertiaAboutOwnCG,'fro') < 1e-10);
        assert(norm(mpa.fixedComponent.cg-mpb.fixedComponent.cg) < 1e-12);
    end

    function case_reaction()
        us = u;
        us(9:10) = us(9:10)+d2r;
        [~,out] = tiltrotor_eom_13x10_command(x,us,P13);
        eBeta = [0;-1;0];
        expected = -(out.nacelle.left.internalTorque+ ...
            out.nacelle.right.internalTorque)*eBeta;
        assert(norm(out.MactuatorReaction-expected) < 1e-12);
        assert(~out.mechanics.externalHingeTorqueImplemented);
        assert(~out.mechanics.mechanicalJamImplemented);
        assert(strcmp(out.couplingBoundary, ...
            'PRESCRIBED_NACELLE_MOTION_TO_RIGID_BODY_ONE_WAY'));
        assert(norm(out.MexternalHinge) == 0);
    end

    function case_component_sum()
        xa = x;
        xa(10:11) = [44;46]*d2r;
        [F,M,info] = total_forces_moments_13x10( ...
            xa,zeros(10,1),P13);
        Fsum = zeros(3,1);
        Msum = zeros(3,1);
        for componentIndex = 1:numel(info.components)
            Fsum = Fsum+info.components{componentIndex}.F;
            Msum = Msum+info.components{componentIndex}.M;
        end
        assert(norm(F-Fsum) < 1e-12);
        assert(norm(M-Msum) < 1e-12);
    end

    function case_gyro()
        Pg = P13;
        Pg.base.rotor.Jpolar = 50;
        xg = x;
        xg(12) = d2r;
        [~,out] = tiltrotor_eom_13x10_command(xg,u,Pg);
        assert(norm(out.MnacelleRateGyro) > 0);
        assert(out.mechanics.nacelleRateGyroImplemented);
    end

    function case_trim_linear()
        condition = struct('V',35,'betaM',45*d2r,'gamma',0);
        opts = struct('mode','conversion_longitudinal');
        [~,~,tr] = trim_berger13_command_symmetric(condition,P13,opts);
        assert(tr.credible && strcmp(tr.inputContract,'ANGLE_COMMAND'));
        lm = linearize_berger13_command_trim_point(tr,P13);
        assert(isequal(size(lm.A13Command),[13,13]));
        assert(isequal(size(lm.B13Command),[13,10]));
        assert(lm.finiteReal && lm.maximumRelativeStepVariation < 1e-2);
        assert(norm(lm.f0([1:6,10:13]),inf) < ...
            10*P13.base.trim.residualTolerance);
    end

    function case_torque()
        [xdot,out] = tiltrotor_eom_13x10(x,zeros(10,1),P13);
        torqueNames = get_control_input_names_13x10();
        assert(isreal(xdot) && all(isfinite(xdot)));
        assert(strcmp(torqueNames{9},'nacelleTorqueLeft'));
        assert(isfield(out,'components13'));
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
