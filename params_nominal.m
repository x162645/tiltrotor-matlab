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
P.mass.mNac  = 900.0;
P.mass.RH    = 0.75;

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

P.rotor.nRadial        = 12;
P.rotor.nAzimuth       = 16;

P.rotor.inducedMaxIter = 20;
P.rotor.inducedRelax   = 0.45;
P.rotor.inducedTol     = 1.0e-4;
P.rotor.inflowHarmonic = 1.0;

% 一阶谐波准定常挥舞闭合。
P.rotor.flapCyclicGain = 1.20;
P.rotor.flapMuGain     = 0.10;
P.rotor.flapLatMuGain  = 0.05;
P.rotor.flapQGain      = 10.0;
P.rotor.flapPGain      = 5.0;
P.rotor.flapMax        = 18.0*d2r;

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

P.wing.Cm0             = -0.03;
P.wing.Cmalpha         = -0.45;
P.wing.CLaileron       = 0.45;
P.wing.Cmaileron       = -0.08;

P.wing.SslipMaxHalf    = 4.0;
P.wing.muMax           = 0.35;
P.wing.CDnormal        = 1.10;
P.wing.normalFlowRatio = 0.35;

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
P.fuselage.Cmalpha     = -0.20;
P.fuselage.Cmq         = -4.0;
P.fuselage.Cnbeta      = 0.12;
P.fuselage.Cnp         = -0.04;
P.fuselage.Cnr         = -0.30;

%% 平尾
P.htail.S              = 4.5;
P.htail.c              = 1.0;
P.htail.rAC            = [-5.0; 0.0; 0.15];
P.htail.incidence      = 0.0*d2r;
P.htail.downwashAlpha  = 0.25;

P.htail.CL0            = 0.0;
P.htail.CLalpha        = 4.5;
P.htail.CLmax          = 1.25;
P.htail.CLelevator     = 1.60;
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
P.control.elevatorLim   = [-40, 40]*d2r;
P.control.rudderLim     = [-30, 30]*d2r;

%% 配平
P.trim.residualTolerance = 5.0e-3;
P.trim.maxIterations      = 600;
P.trim.display            = 'off';

%% 线性化差分步长
P.linear.dx = [0.05; 0.05; 0.05; ...
               1e-3; 1e-3; 1e-3; ...
               1e-4; 1e-4; 1e-4];

P.linear.du = 1e-4*ones(7,1);
P.linear.stabilityTolerance = 1e-7;
end
