function P = params_nominal()
%PARAMS_NOMINAL 倾转旋翼机名义参数。
% 所有单位使用 SI；所有内部角度使用弧度。
% 当前参数为自洽概念参数，并非完整 XV-15 型号数据库。

d2r = pi / 180;

%% 环境
P.env.rho = 1.225;
P.env.g   = 9.80665;

%% 质量、重心和惯量
P.mass.m     = 6000.0;
% mNac is the combined moving mass of the left and right tilting
% nacelle/rotor assemblies. It is not a per-side mass.
P.mass.mNac  = 900.0;
% Equivalent moving-mass CG radius from the nacelle tilt axis, m.
% ASSUMED_CONCEPT: structural split only; not an XV-15 sourced value.
P.mass.RH_mass = 0.75;
% Deprecated compatibility metadata. Production calculations do not read
% this alias, so modifying it does not affect model results.
P.mass.RH = P.mass.RH_mass;

P.mass.I0 = [18000,     0,  -800;
                 0, 30000,     0;
              -800,     0, 45000];

% I(betaM) = I0 - betaM * KI；KI 按每弧度解释。
P.mass.KI = diag([300, 500, 400]);

%% 旋翼/螺旋桨
P.rotor.R              = 3.80;
P.rotor.Nb             = 3;
P.rotor.Omega          = 62.0;
P.rotor.chord          = 0.38;
P.rotor.rootCut        = 0.18;
P.rotor.twistTip       = -6.0*d2r;

P.rotor.liftSlope      = 5.7;
P.rotor.CLmax          = 1.35;
P.rotor.CD0            = 0.011;
P.rotor.kCD            = 0.012;

% 短舱转轴基准位置。左右旋翼的 y 坐标由 side 决定。
P.rotor.pivotX         = 0.0;
P.rotor.pivotY         = 5.0;
P.rotor.pivotZ         = 0.0;
% Rotor-hub tilt radius from the nacelle tilt axis, m.
% ASSUMED_CONCEPT: structural split only; not an XV-15 sourced value.
P.rotor.RH_hub         = 0.75;

P.rotor.nRadial        = 12;
P.rotor.nAzimuth       = 16;

P.rotor.inducedMaxIter = 20;
P.rotor.inducedRelax   = 0.45;
P.rotor.inducedTol     = 1.0e-4;
% Deprecated placeholder. The formal flapping/BEMT path uses uniform
% induced velocity viField=vi; non-uniform inflow is not implemented yet.
P.rotor.inflowHarmonic = 1.0;

% Deprecated empirical disk-tilt gains. These fields are retained only for
% structure compatibility and are not read by the formal flapping path.
P.rotor.flapCyclicGain = 1.20;
P.rotor.flapMuGain     = 0.10;
P.rotor.flapLatMuGain  = 0.05;
P.rotor.flapQGain      = 10.0;
P.rotor.flapPGain      = 5.0;
P.rotor.flapMax        = 18.0*d2r;

% Steady first-harmonic flapping model parameters.
% bladeMass: ASSUMED conceptual single-blade mass, not an XV-15 reference.
% bladeMassDistribution: ASSUMED uniform distribution over 0 <= r <= R.
% Ib and Sblade: DERIVED from bladeMass and the uniform distribution.
P.rotor.bladeMass      = 45.0;
P.rotor.bladeMassDistribution = 'ASSUMED_UNIFORM_FULL_SPAN';
P.rotor.Ib             = P.rotor.bladeMass*P.rotor.R^2/3;
P.rotor.Sblade         = P.rotor.bladeMass*P.rotor.R/2;
P.rotor.flapInitial    = [0; 0; 0];

% Flapping/induced coupled-solve numerical settings: NUMERICAL.
P.rotor.flapResidualTol = 1.0e-7;
P.rotor.flapMaxIter = 40;
P.rotor.flapJacobianStep = 1.0e-5;
P.rotor.flapNewtonDamping = 0.5;
P.rotor.flapNewtonRegularization = 1.0e-8;
P.rotor.flapLineSearchMaxIter = 18;
P.rotor.flapDivergenceAngle = 80.0*d2r;

P.rotor.wakeFactor     = 1.60;

% 可选旋翼陀螺项。缺乏可信转动惯量时默认关闭。
P.rotor.Jpolar         = 0.0;

%% 机翼
P.wing.S               = 18.0;
P.wing.b               = 10.0;
P.wing.c               = 1.50;

P.wing.xAC             = 0.0;
P.wing.yFreeAC         = 1.70;
P.wing.ySlipAC         = 4.00;
P.wing.zAC             = 0.05;

P.wing.CL0             = 0.15;
P.wing.CLalpha         = 5.20;
P.wing.CLmax           = 1.45;
P.wing.CD0             = 0.025;
P.wing.kInduced        = 0.055;
P.wing.CYbeta          = -0.35;

% CALIBRATED_EFFECTIVE_PARAMETER: bounded trim-trend correction; not a
% directly measured XV-15 component value. Cm0=-0.03 preserves a nonzero
% baseline intrinsic wing pitching moment about the current aerodynamic
% reference point, while lift/drag still contribute through rAC x F.
P.wing.Cm0             = -0.03;
% INITIAL_MECHANISTIC_ASSUMPTION: the current wing rAC is treated as an
% equivalent aerodynamic center, so direct attached-flow Cm_alpha is set to
% zero for now. This is not a statement that the real slope is zero.
P.wing.Cmalpha         = 0.00;
P.wing.CLaileron       = 0.45;
P.wing.Cmaileron       = -0.08;

P.wing.SslipMaxHalf    = 4.0;
P.wing.muMax           = 0.35;
P.wing.CDnormal        = 1.10;
% ASSUMED_MODEL_PARAMETER: transition center for near-normal/lift-line blend.
P.wing.normalFlowRatio = 0.35;
% ASSUMED_MODEL_PARAMETER: half-width in abs(Vx)/V ratio space.
% Width 0.15 is a provisional concept value selected from continuity,
% blend-coverage and sensitivity checks, not literature or test data.
P.wing.normalFlowBlendHalfWidth = 0.15;

%% 机身
P.fuselage.S           = 8.0;
P.fuselage.b           = 3.0;
P.fuselage.c           = 4.0;
P.fuselage.rAC         = [0.20; 0.0; 0.10];

P.fuselage.CD0         = 0.08;
P.fuselage.CDalpha2    = 0.50;
P.fuselage.CDbeta2     = 0.40;
P.fuselage.CL0         = 0.00;
P.fuselage.CLalpha     = 0.35;
P.fuselage.CYbeta      = -0.55;

P.fuselage.Clbeta      = -0.08;
P.fuselage.Clp         = -0.30;
P.fuselage.Clr         = 0.08;
P.fuselage.Cm0         = 0.00;
% INITIAL_MECHANISTIC_ASSUMPTION: reliable fuselage/wing-body pitch-moment
% slope data are not yet available. Aerodynamic forces and their moment arms
% remain active; the real direct Cm_alpha may be nonzero.
P.fuselage.Cmalpha     = 0.00;
P.fuselage.Cmq         = -4.0;
P.fuselage.Cnbeta      = 0.12;
P.fuselage.Cnp         = -0.04;
P.fuselage.Cnr         = -0.30;

%% 平尾
P.htail.S              = 4.5;
P.htail.c              = 1.0;
P.htail.rAC            = [-5.0; 0.0; 0.15];
% CALIBRATED_EFFECTIVE_PARAMETER: bounded trim-trend correction; not a
% directly measured XV-15 component value. Downwash and incidence compensate
% each other in the current 70 m/s airplane trim and are not uniquely
% identified by this diagnostic alone.
P.htail.incidence      = -2.0*d2r;
P.htail.downwashAlpha  = 0.40;

P.htail.CL0            = 0.0;
P.htail.CLalpha        = 4.5;
P.htail.CLmax          = 1.25;
% CALIBRATED_EFFECTIVE_PARAMETER: bounded trim-trend correction; not a
% directly measured XV-15 component value. This changes elevator authority
% per degree, not the zero-elevator baseline tail load.
P.htail.CLelevator     = 2.00;
P.htail.CD0            = 0.018;
P.htail.kInduced       = 0.060;
P.htail.Cm0            = 0.0;
P.htail.Cmelevator     = -0.08;

%% 双垂尾
P.vtail.SEach          = 1.6;
P.vtail.c              = 0.8;
P.vtail.xAC            = -4.20;
P.vtail.yAC            = 1.10;
P.vtail.zAC            = -0.20;

P.vtail.CD0            = 0.020;
P.vtail.CYbeta         = -2.20;
P.vtail.CYrudder       = 0.70;

%% 控制限制
P.control.collectiveLim = [0, 70]*d2r;
P.control.cyclicLim     = [-35, 35]*d2r;
P.control.aileronLim    = [-30, 30]*d2r;
P.control.elevatorLim   = [-20, 20]*d2r;
P.control.rudderLim     = [-30, 30]*d2r;

%% 配平
P.trim.residualTolerance = 5.0e-3;
P.trim.maxIterations      = 600;
P.trim.display            = 'off';
% NUMERICAL: fminsearch dimensionless variable scales for
% [theta; collective; cyclicLong], rad. These are solver search scales,
% not aircraft physical parameters. With fminsearch's 5% nonzero simplex
% rule, this gives initial physical steps of about [0.1; 0.9; 0.1] deg.
P.trim.variableScale      = [2; 18; 2]*(pi/180);

%% 线性化差分步长
P.linear.dx = [0.05; 0.05; 0.05; ...
               1e-3; 1e-3; 1e-3; ...
               1e-4; 1e-4; 1e-4];

P.linear.du = 1e-4*ones(7,1);
P.linear.stabilityTolerance = 1e-7;
end
