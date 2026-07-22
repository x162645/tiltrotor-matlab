function P13 = params_berger13()
%PARAMS_BERGER13 Isolated PR1 parameters and provenance declarations.
% Nacelle values are research placeholders for interface development only.
% They are not Berger, XV-15, NUAA, or flight-test data.

d2r = pi/180;
Pbase = params_nominal();

P13.base = Pbase;
P13.meta.physicalBaseSHA = ...
    '3550e5b855bac1c38e9d275cf3f8e608cb519c70';
P13.meta.portSourceSHA = ...
    '370c7aef13a5dca98c0436616548729859c399a9';
P13.meta.scope = 'PR1_ISOLATED_RESEARCH_SCAFFOLD';

P13.interface.lateralCyclicTheta1cMapping = 'rotDir';
P13.interface.lateralCyclicLimitSource = 'P13.base.control.cyclicLim';
P13.interface.parameterSource = 'ASSUMED_MODEL_PARAMETER';

P13.nacelle.I = 250;
P13.nacelle.D = 900;
P13.nacelle.K = 0;
P13.nacelle.betaMin = 0*d2r;
P13.nacelle.betaMax = 90*d2r;
P13.nacelle.betaDotLim = 20*d2r;
P13.nacelle.torqueLim = 5.0e4;
P13.nacelle.parameterSource = 'RESEARCH_PLACEHOLDER';
P13.nacelle.parameterSources = struct( ...
    'I', 'RESEARCH_PLACEHOLDER', ...
    'D', 'RESEARCH_PLACEHOLDER', ...
    'K', 'RESEARCH_PLACEHOLDER', ...
    'betaMin', 'RESEARCH_PLACEHOLDER', ...
    'betaMax', 'RESEARCH_PLACEHOLDER', ...
    'betaDotLim', 'RESEARCH_PLACEHOLDER', ...
    'torqueLim', 'RESEARCH_PLACEHOLDER');
P13.nacelle.stiffnessImplemented = false;

% Closed-loop angle-command parameters are research placeholders. Berger
% PDF 95 (printed 60) supports the command-to-torque PID structure but does
% not provide these numerical values for the present conceptual aircraft.
actuator = struct();
actuator.omegaN = 4.0;
actuator.zeta = 0.8;
actuator.accelLim = 30*d2r;
actuator.rateScale = 1.0;
actuator.commandDelay = 0;
actuator.kinematicLock = false;
actuator.commandFreeze = false;
actuator.frozenCommand = 45*d2r;
actuator.parameterSource = 'RESEARCH_PLACEHOLDER';
actuator.parameterSources = struct( ...
    'omegaN','RESEARCH_PLACEHOLDER', ...
    'zeta','RESEARCH_PLACEHOLDER', ...
    'accelLim','RESEARCH_PLACEHOLDER', ...
    'rateScale','ASSUMED_MODEL_PARAMETER', ...
    'commandDelay','RESEARCH_PLACEHOLDER', ...
    'faultFlags','ASSUMED_MODEL_PARAMETER');
P13.commandActuator.left = actuator;
P13.commandActuator.right = actuator;

% Per-side masses are derived by splitting the existing combined moving
% mass. The asymmetric inertia correction uses only point-mass translation;
% unavailable local nacelle inertia tensors are not silently invented.
P13.movingComponents.left.mass = 0.5*Pbase.mass.mNac;
P13.movingComponents.right.mass = 0.5*Pbase.mass.mNac;
P13.movingComponents.radius = Pbase.mass.RH_mass;
P13.movingComponents.parameterSources = struct( ...
    'leftMass','DERIVED', 'rightMass','DERIVED', ...
    'radius','ASSUMED_MODEL_PARAMETER', ...
    'localInertia','UNKNOWN');
P13.movingComponents.localInertiaCorrectionImplemented = false;

P13.mechanics.actuatorReactionTorqueImplemented = true;
P13.mechanics.nacelleRateGyroImplemented = true;
P13.mechanics.iDotOmegaImplemented = false;
P13.mechanics.movingMassAccelerationImplemented = false;
P13.mechanics.transmissionHigherOrderImplemented = false;
P13.mechanics.externalHingeTorqueImplemented = false;
P13.mechanics.mechanicalJamImplemented = false;
P13.mechanics.couplingBoundary = ...
    'PRESCRIBED_NACELLE_MOTION_TO_RIGID_BODY_ONE_WAY';

P13.linear.dx = [Pbase.linear.dx(:); 1e-4; 1e-4; 1e-4; 1e-4];
P13.linear.du = [Pbase.linear.du(1:4); 1e-4; ...
    Pbase.linear.du(5:7); 10; 10];
P13.linear.parameterSource = 'ASSUMED_MODEL_PARAMETER';
P13.linearCommand.dx = P13.linear.dx;
P13.linearCommand.du = [P13.linear.du(1:8); 1e-4; 1e-4];
P13.linearCommand.parameterSource = 'ASSUMED_MODEL_PARAMETER';
end
