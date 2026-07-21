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

P13.linear.dx = [Pbase.linear.dx(:); 1e-4; 1e-4; 1e-4; 1e-4];
P13.linear.du = [Pbase.linear.du(1:4); 1e-4; ...
    Pbase.linear.du(5:7); 10; 10];
P13.linear.parameterSource = 'ASSUMED_MODEL_PARAMETER';
end
