function rows = build_parameter_catalog(P)
%BUILD_PARAMETER_CATALOG Build GUI-editable parameter rows from current P.
% Rows are grouped by physical component or calculation module. Numeric
% vector/matrix fields are exposed as auditable scalar components.

if nargin < 1 || isempty(P)
    P = params_nominal();
end

rows = struct('group',{},'name',{},'key',{},'unit',{}, ...
    'source',{},'sourceLabel',{},'description',{},'editable',{});

rows = add_row(rows,'环境','空气密度 rho','env.rho','kg/m^3', ...
    'ASSUMED_CONCEPT',true,'Current conceptual atmosphere density.');
rows = add_row(rows,'环境','重力加速度 g','env.g','m/s^2', ...
    'REFERENCE_CONSTANT',true,'Standard gravity used by the model.');

rows = add_row(rows,'质量/惯量','总质量 m','mass.m','kg', ...
    'ASSUMED_CONCEPT',true,'Aircraft total mass in the current concept model.');
rows = add_row(rows,'质量/惯量','左右短舱和旋翼组件总质量','mass.mNac','kg', ...
    'ASSUMED_CONCEPT',true,'Combined moving mass of both tilting nacelle/rotor assemblies.');
rows = add_row(rows,'质量/惯量','倾转组件重心到转轴的距离','mass.RH_mass','m', ...
    'ASSUMED_CONCEPT',true,'Equivalent moving-mass CG radius from the nacelle tilt axis.');
rows = add_row(rows,'质量/惯量','兼容保留半径别名 RH','mass.RH','m', ...
    'DEPRECATED_COMPATIBILITY',false,'Deprecated compatibility alias; production calculations do not read it.');
rows = add_matrix(rows,'质量/惯量','滚转惯量 Ixx','mass.I0(1,1)','kg m^2','ASSUMED_CONCEPT',true);
rows = add_matrix(rows,'质量/惯量','俯仰惯量 Iyy','mass.I0(2,2)','kg m^2','ASSUMED_CONCEPT',true);
rows = add_matrix(rows,'质量/惯量','偏航惯量 Izz','mass.I0(3,3)','kg m^2','ASSUMED_CONCEPT',true);
rows = add_matrix(rows,'质量/惯量','滚转-俯仰耦合惯量 Ixy','mass.I0(1,2)','kg m^2','ASSUMED_CONCEPT',true);
rows = add_matrix(rows,'质量/惯量','滚转-偏航耦合惯量 Ixz','mass.I0(1,3)','kg m^2','ASSUMED_CONCEPT',true);
rows = add_matrix(rows,'质量/惯量','俯仰-偏航耦合惯量 Iyz','mass.I0(2,3)','kg m^2','ASSUMED_CONCEPT',true);
rows = add_matrix(rows,'质量/惯量','惯量变化近似系数 KIx','mass.KI(1,1)','kg m^2/rad', ...
    'ASSUMED_MODEL_PARAMETER',true);
rows = add_matrix(rows,'质量/惯量','惯量变化近似系数 KIy','mass.KI(2,2)','kg m^2/rad', ...
    'ASSUMED_MODEL_PARAMETER',true);
rows = add_matrix(rows,'质量/惯量','惯量变化近似系数 KIz','mass.KI(3,3)','kg m^2/rad', ...
    'ASSUMED_MODEL_PARAMETER',true);

rows = add_row(rows,'旋翼','旋翼半径 R','rotor.R','m','ASSUMED_CONCEPT',true, ...
    'Changing R also updates derived rotor.Ib and rotor.Sblade.');
rows = add_row(rows,'旋翼','桨叶数 Nb','rotor.Nb','-','ASSUMED_CONCEPT',true,'Number of blades per rotor.');
rows = add_row(rows,'旋翼','旋翼角速度 Omega','rotor.Omega','rad/s','ASSUMED_CONCEPT',true,'Rotor angular speed.');
rows = add_row(rows,'旋翼','桨叶弦长','rotor.chord','m','ASSUMED_CONCEPT',true,'Uniform blade chord used by the current BEMT model.');
rows = add_row(rows,'旋翼','叶素计算起始位置','rotor.rootCut','R','ASSUMED_CONCEPT',true,'Root cutout ratio.');
rows = add_row(rows,'旋翼','桨叶总扭转角','rotor.twistTip','rad','ASSUMED_CONCEPT',true,'Tip twist relative to root.');
rows = add_row(rows,'旋翼','升力线斜率','rotor.liftSlope','1/rad','ASSUMED_CONCEPT',true,'Rotor airfoil lift-curve slope.');
rows = add_row(rows,'旋翼','最大升力系数','rotor.CLmax','-','ASSUMED_CONCEPT',true,'Concept stall limit used by blade elements.');
rows = add_row(rows,'旋翼','剖面零升阻力系数','rotor.CD0','-','ASSUMED_CONCEPT',true,'Blade-section drag model constant.');
rows = add_row(rows,'旋翼','剖面诱导阻力系数','rotor.kCD','-','ASSUMED_CONCEPT',true,'Blade-section drag polar coefficient.');
rows = add_row(rows,'旋翼','短舱转轴前后位置','rotor.pivotX','m','ASSUMED_CONCEPT',true,'Body-axis x coordinate of nacelle tilt pivot.');
rows = add_row(rows,'旋翼','短舱转轴到机身中心线的距离','rotor.pivotY','m','ASSUMED_CONCEPT',true,'Half lateral spacing of nacelle tilt pivots.');
rows = add_row(rows,'旋翼','短舱转轴上下位置','rotor.pivotZ','m','ASSUMED_CONCEPT',true,'Body-axis z coordinate of nacelle tilt pivot.');
rows = add_row(rows,'旋翼','桨毂到短舱转轴的距离','rotor.RH_hub','m','ASSUMED_CONCEPT',true,'Rotor hub radius from nacelle tilt axis.');
rows = add_row(rows,'旋翼','径向离散数','rotor.nRadial','-','NUMERICAL',true,'BEMT radial station count.');
rows = add_row(rows,'旋翼','方位离散数','rotor.nAzimuth','-','NUMERICAL',true,'BEMT azimuth station count.');
rows = add_row(rows,'旋翼','诱导速度最大迭代次数','rotor.inducedMaxIter','-','NUMERICAL',true,'Iteration limit for induced velocity solve.');
rows = add_row(rows,'旋翼','诱导速度松弛系数','rotor.inducedRelax','-','NUMERICAL',true,'Relaxation factor for induced velocity iteration.');
rows = add_row(rows,'旋翼','诱导速度收敛精度','rotor.inducedTol','m/s','NUMERICAL',true,'Induced velocity convergence tolerance.');
rows = add_row(rows,'旋翼','桨叶质量','rotor.bladeMass','kg','ASSUMED_CONCEPT',true, ...
    'Changing bladeMass also updates derived rotor.Ib and rotor.Sblade.');
rows = add_row(rows,'旋翼','旋翼自转惯量 Ib','rotor.Ib','kg m^2','DERIVED',false, ...
    'Derived from bladeMass and R for the current uniform-blade assumption.');
rows = add_row(rows,'旋翼','桨叶一阶质量矩 Sblade','rotor.Sblade','kg m','DERIVED',false, ...
    'Derived from bladeMass and R for the current uniform-blade assumption.');
rows = add_row(rows,'旋翼','挥舞残差收敛精度','rotor.flapResidualTol','-','NUMERICAL',true,'Steady flapping residual tolerance.');
rows = add_row(rows,'旋翼','挥舞最大迭代次数','rotor.flapMaxIter','-','NUMERICAL',true,'Steady flapping Newton iteration limit.');
rows = add_row(rows,'旋翼','挥舞雅可比差分步长','rotor.flapJacobianStep','rad','NUMERICAL',true,'Numerical step for flapping residual Jacobian.');
rows = add_row(rows,'旋翼','挥舞牛顿阻尼系数','rotor.flapNewtonDamping','-','NUMERICAL',true,'Newton update damping for flapping solve.');
rows = add_row(rows,'旋翼','挥舞牛顿正则化','rotor.flapNewtonRegularization','-','NUMERICAL',true,'Regularization for flapping Newton system.');
rows = add_row(rows,'旋翼','挥舞线搜索最大次数','rotor.flapLineSearchMaxIter','-','NUMERICAL',true,'Line-search iteration limit.');
rows = add_row(rows,'旋翼','挥舞发散角阈值','rotor.flapDivergenceAngle','rad','NUMERICAL',true,'Angle threshold for flapping divergence guard.');
rows = add_row(rows,'旋翼','尾流系数','rotor.wakeFactor','-','ASSUMED_MODEL_PARAMETER',true,'Concept wake scaling factor.');
rows = add_row(rows,'旋翼','旋翼极惯量','rotor.Jpolar','kg m^2','UNKNOWN',true,'Optional rotor gyroscopic inertia; default is disabled at zero.');

rows = add_row(rows,'机翼','机翼面积','wing.S','m^2','ASSUMED_CONCEPT',true,'Wing reference area.');
rows = add_row(rows,'机翼','翼展','wing.b','m','ASSUMED_CONCEPT',true,'Wing reference span.');
rows = add_row(rows,'机翼','平均弦长','wing.c','m','ASSUMED_CONCEPT',true,'Wing reference chord.');
rows = add_row(rows,'机翼','机翼气动中心前后位置','wing.xAC','m','ASSUMED_CONCEPT',true,'Wing aerodynamic-center x coordinate.');
rows = add_row(rows,'机翼','自由流区域半展位置','wing.yFreeAC','m','ASSUMED_CONCEPT',true,'Representative wing free-stream span station.');
rows = add_row(rows,'机翼','滑流区域半展位置','wing.ySlipAC','m','ASSUMED_CONCEPT',true,'Representative wing slipstream span station.');
rows = add_row(rows,'机翼','机翼气动中心上下位置','wing.zAC','m','ASSUMED_CONCEPT',true,'Wing aerodynamic-center z coordinate.');
rows = add_row(rows,'机翼','零迎角升力系数','wing.CL0','-','ASSUMED_CONCEPT',true,'Wing lift model intercept.');
rows = add_row(rows,'机翼','迎角对机翼升力的影响 CLalpha','wing.CLalpha','1/rad','ASSUMED_CONCEPT',true,'Wing lift-curve slope.');
rows = add_row(rows,'机翼','机翼最大升力系数','wing.CLmax','-','ASSUMED_CONCEPT',true,'Wing lift saturation value.');
rows = add_row(rows,'机翼','机翼零升阻力系数','wing.CD0','-','ASSUMED_CONCEPT',true,'Wing drag polar constant.');
rows = add_row(rows,'机翼','机翼诱导阻力系数','wing.kInduced','-','ASSUMED_CONCEPT',true,'Wing drag polar induced coefficient.');
rows = add_row(rows,'机翼','侧滑对机翼侧向力的影响 CYbeta','wing.CYbeta','1/rad','ASSUMED_CONCEPT',true,'Wing side-force derivative.');
rows = add_row(rows,'机翼','机翼零迎角俯仰力矩系数','wing.Cm0','-','ASSUMED_CONCEPT',true,'Wing pitching-moment intercept.');
rows = add_row(rows,'机翼','迎角对机翼俯仰力矩的影响 Cmalpha','wing.Cmalpha','1/rad','ASSUMED_CONCEPT',true,'Wing pitching-moment derivative.');
rows = add_row(rows,'机翼','副翼对机翼升力的影响','wing.CLaileron','1/rad','ASSUMED_CONCEPT',true,'Aileron lift derivative.');
rows = add_row(rows,'机翼','副翼对俯仰力矩的影响','wing.Cmaileron','1/rad','ASSUMED_CONCEPT',true,'Aileron pitching-moment derivative.');
rows = add_row(rows,'机翼','最大滑流半展','wing.SslipMaxHalf','m','ASSUMED_MODEL_PARAMETER',true,'Slipstream coverage parameter.');
rows = add_row(rows,'机翼','最大滑流速度比','wing.muMax','-','ASSUMED_MODEL_PARAMETER',true,'Slipstream velocity ratio cap.');
rows = add_row(rows,'机翼','近法向流阻力系数','wing.CDnormal','-','ASSUMED_MODEL_PARAMETER',true,'Near-normal-flow model coefficient.');
rows = add_row(rows,'机翼','近法向流过渡中心','wing.normalFlowRatio','-','ASSUMED_MODEL_PARAMETER',true,'Transition center for near-normal/lift-line blend.');
rows = add_row(rows,'机翼','近法向流过渡半宽','wing.normalFlowBlendHalfWidth','-','ASSUMED_MODEL_PARAMETER',true,'Smootherstep blend half-width.');

rows = add_aero_body(rows,'机身','fuselage');
rows = add_tail(rows,'平尾','htail');
rows = add_vtail(rows);

rows = add_limit(rows,'控制','总距最小值','control.collectiveLim(1)','rad','ASSUMED_CONCEPT');
rows = add_limit(rows,'控制','总距最大值','control.collectiveLim(2)','rad','ASSUMED_CONCEPT');
rows = add_limit(rows,'控制','周期变距最小值','control.cyclicLim(1)','rad','ASSUMED_CONCEPT');
rows = add_limit(rows,'控制','周期变距最大值','control.cyclicLim(2)','rad','ASSUMED_CONCEPT');
rows = add_limit(rows,'控制','副翼最小值','control.aileronLim(1)','rad','ASSUMED_CONCEPT');
rows = add_limit(rows,'控制','副翼最大值','control.aileronLim(2)','rad','ASSUMED_CONCEPT');
rows = add_limit(rows,'控制','升降舵最小值','control.elevatorLim(1)','rad','ASSUMED_CONCEPT');
rows = add_limit(rows,'控制','升降舵最大值','control.elevatorLim(2)','rad','ASSUMED_CONCEPT');
rows = add_limit(rows,'控制','方向舵最小值','control.rudderLim(1)','rad','ASSUMED_CONCEPT');
rows = add_limit(rows,'控制','方向舵最大值','control.rudderLim(2)','rad','ASSUMED_CONCEPT');
rows = add_row(rows,'控制','启用横向周期变距 8 输入','control.enableLateralCyclic','logical', ...
    'NUMERICAL',true,'Opt-in switch only; default remains the legacy seven-input architecture.');

rows = add_row(rows,'短舱动态','启用短舱动态状态','nacelleDynamics.enabled','logical', ...
    'NUMERICAL',true,'Default remains disabled to preserve the legacy nine-state path.');
rows = add_row(rows,'短舱动态','短舱角最小值','nacelleDynamics.betaMinDeg','deg','ASSUMED_MODEL_PARAMETER',true,'Nacelle command lower bound.');
rows = add_row(rows,'短舱动态','短舱角最大值','nacelleDynamics.betaMaxDeg','deg','ASSUMED_MODEL_PARAMETER',true,'Nacelle command upper bound.');
rows = add_row(rows,'短舱动态','最大短舱角速率','nacelleDynamics.rateLimitDegPerSec','deg/s', ...
    'ASSUMED_MODEL_PARAMETER',true,'Open-loop nacelle-rate limit used by the dynamic response module.');
rows = add_row(rows,'短舱动态','短舱动态频率','nacelleDynamics.omega','rad/s','ASSUMED_MODEL_PARAMETER',true,'Second-order nacelle dynamic natural frequency.');
rows = add_row(rows,'短舱动态','短舱阻尼比','nacelleDynamics.zeta','-','ASSUMED_MODEL_PARAMETER',true,'Second-order nacelle dynamic damping ratio.');
rows = add_row(rows,'短舱动态','短舱一阶时间常数元数据','nacelleDynamics.tau','s','ASSUMED_MODEL_PARAMETER',true,'Metadata for first-order comparisons.');
rows = add_row(rows,'短舱动态','短舱角差分步长','nacelleDynamics.linearDx(1)','rad','NUMERICAL',true,'Linearization step for appended betaM state.');
rows = add_row(rows,'短舱动态','短舱角速度差分步长','nacelleDynamics.linearDx(2)','rad/s','NUMERICAL',true,'Linearization step for appended betaM_dot state.');

rows = add_row(rows,'配平','配平残差容限','trim.residualTolerance','mixed','NUMERICAL',true,'Scaled trim residual acceptance threshold.');
rows = add_row(rows,'配平','配平最大迭代次数','trim.maxIterations','-','NUMERICAL',true,'Maximum optimizer iterations.');
rows = add_row(rows,'配平','俯仰角搜索尺度','trim.variableScale(1)','rad','NUMERICAL',true,'fminsearch variable scale for theta.');
rows = add_row(rows,'配平','总距搜索尺度','trim.variableScale(2)','rad','NUMERICAL',true,'fminsearch variable scale for collective.');
rows = add_row(rows,'配平','纵向周期变距搜索尺度','trim.variableScale(3)','rad','NUMERICAL',true,'fminsearch variable scale for cyclicLong.');

stateNames = get_state_names(P);
for k = 1:numel(P.linear.dx)
    rows = add_row(rows,'线性化',sprintf('状态差分步长 %s', stateNames{k}), ...
        sprintf('linear.dx(%d)', k),'state unit','NUMERICAL',true, ...
        'Central-difference state perturbation step.');
end
controlNames = get_control_input_names(P);
duCount = numel(controlNames);
for k = 1:duCount
    rows = add_row(rows,'线性化',sprintf('操纵差分步长 %s', controlNames{k}), ...
        sprintf('linear.du(%d)', k),'rad','NUMERICAL',true, ...
        'Central-difference control perturbation step.');
end
rows = add_row(rows,'线性化','稳定性判别容限','linear.stabilityTolerance','1/s', ...
    'NUMERICAL',true,'Real-part tolerance for modal classification.');

end

function rows = add_aero_body(rows, groupName, prefix)
rows = add_row(rows,groupName,'参考面积',sprintf('%s.S',prefix),'m^2','ASSUMED_CONCEPT',true,'Aerodynamic reference area.');
rows = add_row(rows,groupName,'参考展长',sprintf('%s.b',prefix),'m','ASSUMED_CONCEPT',true,'Aerodynamic reference span.');
rows = add_row(rows,groupName,'参考弦长',sprintf('%s.c',prefix),'m','ASSUMED_CONCEPT',true,'Aerodynamic reference chord.');
rows = add_row(rows,groupName,'气动中心 x',sprintf('%s.rAC(1)',prefix),'m','ASSUMED_CONCEPT',true,'Aerodynamic-center x coordinate.');
rows = add_row(rows,groupName,'气动中心 y',sprintf('%s.rAC(2)',prefix),'m','ASSUMED_CONCEPT',true,'Aerodynamic-center y coordinate.');
rows = add_row(rows,groupName,'气动中心 z',sprintf('%s.rAC(3)',prefix),'m','ASSUMED_CONCEPT',true,'Aerodynamic-center z coordinate.');
rows = add_row(rows,groupName,'零升阻力系数',sprintf('%s.CD0',prefix),'-','ASSUMED_CONCEPT',true,'Drag model constant.');
rows = add_row(rows,groupName,'迎角二次阻力系数',sprintf('%s.CDalpha2',prefix),'-','ASSUMED_CONCEPT',true,'Quadratic alpha drag coefficient.');
rows = add_row(rows,groupName,'侧滑二次阻力系数',sprintf('%s.CDbeta2',prefix),'-','ASSUMED_CONCEPT',true,'Quadratic beta drag coefficient.');
rows = add_row(rows,groupName,'零迎角升力系数',sprintf('%s.CL0',prefix),'-','ASSUMED_CONCEPT',true,'Lift model intercept.');
rows = add_row(rows,groupName,'迎角对升力的影响',sprintf('%s.CLalpha',prefix),'1/rad','ASSUMED_CONCEPT',true,'Lift derivative.');
rows = add_row(rows,groupName,'侧滑对侧向力的影响',sprintf('%s.CYbeta',prefix),'1/rad','ASSUMED_CONCEPT',true,'Side-force derivative.');
rows = add_row(rows,groupName,'侧滑对滚转力矩的影响',sprintf('%s.Clbeta',prefix),'1/rad','ASSUMED_CONCEPT',true,'Rolling-moment derivative.');
rows = add_row(rows,groupName,'滚转速度对滚转力矩的影响',sprintf('%s.Clp',prefix),'-','ASSUMED_CONCEPT',true,'Roll damping derivative.');
rows = add_row(rows,groupName,'偏航速度对滚转力矩的影响',sprintf('%s.Clr',prefix),'-','ASSUMED_CONCEPT',true,'Yaw-rate to roll-moment derivative.');
rows = add_row(rows,groupName,'零迎角俯仰力矩系数',sprintf('%s.Cm0',prefix),'-','ASSUMED_CONCEPT',true,'Pitching-moment intercept.');
rows = add_row(rows,groupName,'迎角对俯仰力矩的影响',sprintf('%s.Cmalpha',prefix),'1/rad','ASSUMED_CONCEPT',true,'Pitching-moment derivative.');
rows = add_row(rows,groupName,'俯仰速度对俯仰力矩的影响',sprintf('%s.Cmq',prefix),'-','ASSUMED_CONCEPT',true,'Pitch-rate damping derivative.');
rows = add_row(rows,groupName,'侧滑对偏航力矩的影响',sprintf('%s.Cnbeta',prefix),'1/rad','ASSUMED_CONCEPT',true,'Yawing-moment derivative.');
rows = add_row(rows,groupName,'滚转速度对偏航力矩的影响',sprintf('%s.Cnp',prefix),'-','ASSUMED_CONCEPT',true,'Roll-rate to yaw-moment derivative.');
rows = add_row(rows,groupName,'偏航速度对偏航力矩的影响',sprintf('%s.Cnr',prefix),'-','ASSUMED_CONCEPT',true,'Yaw damping derivative.');
end

function rows = add_tail(rows, groupName, prefix)
rows = add_row(rows,groupName,'参考面积',sprintf('%s.S',prefix),'m^2','ASSUMED_CONCEPT',true,'Tail reference area.');
rows = add_row(rows,groupName,'参考弦长',sprintf('%s.c',prefix),'m','ASSUMED_CONCEPT',true,'Tail reference chord.');
rows = add_row(rows,groupName,'气动中心 x',sprintf('%s.rAC(1)',prefix),'m','ASSUMED_CONCEPT',true,'Tail aerodynamic-center x coordinate.');
rows = add_row(rows,groupName,'气动中心 y',sprintf('%s.rAC(2)',prefix),'m','ASSUMED_CONCEPT',true,'Tail aerodynamic-center y coordinate.');
rows = add_row(rows,groupName,'气动中心 z',sprintf('%s.rAC(3)',prefix),'m','ASSUMED_CONCEPT',true,'Tail aerodynamic-center z coordinate.');
rows = add_row(rows,groupName,'安装角',sprintf('%s.incidence',prefix),'rad','ASSUMED_CONCEPT',true,'Tail incidence angle.');
rows = add_row(rows,groupName,'下洗系数',sprintf('%s.downwashAlpha',prefix),'-','ASSUMED_MODEL_PARAMETER',true,'Downwash coupling coefficient.');
rows = add_row(rows,groupName,'零迎角升力系数',sprintf('%s.CL0',prefix),'-','ASSUMED_CONCEPT',true,'Tail lift intercept.');
rows = add_row(rows,groupName,'迎角对升力的影响',sprintf('%s.CLalpha',prefix),'1/rad','ASSUMED_CONCEPT',true,'Tail lift-curve slope.');
rows = add_row(rows,groupName,'最大升力系数',sprintf('%s.CLmax',prefix),'-','ASSUMED_CONCEPT',true,'Tail lift saturation.');
rows = add_row(rows,groupName,'升降舵对升力的影响',sprintf('%s.CLelevator',prefix),'1/rad','ASSUMED_CONCEPT',true,'Elevator lift derivative.');
rows = add_row(rows,groupName,'零升阻力系数',sprintf('%s.CD0',prefix),'-','ASSUMED_CONCEPT',true,'Tail drag constant.');
rows = add_row(rows,groupName,'诱导阻力系数',sprintf('%s.kInduced',prefix),'-','ASSUMED_CONCEPT',true,'Tail drag polar coefficient.');
rows = add_row(rows,groupName,'零迎角俯仰力矩系数',sprintf('%s.Cm0',prefix),'-','ASSUMED_CONCEPT',true,'Tail pitching-moment intercept.');
rows = add_row(rows,groupName,'升降舵对俯仰力矩的影响',sprintf('%s.Cmelevator',prefix),'1/rad','ASSUMED_CONCEPT',true,'Elevator pitching-moment derivative.');
end

function rows = add_vtail(rows)
rows = add_row(rows,'垂尾','单侧垂尾面积','vtail.SEach','m^2','ASSUMED_CONCEPT',true,'Area of each vertical tail.');
rows = add_row(rows,'垂尾','垂尾参考弦长','vtail.c','m','ASSUMED_CONCEPT',true,'Vertical-tail reference chord.');
rows = add_row(rows,'垂尾','垂尾气动中心 x','vtail.xAC','m','ASSUMED_CONCEPT',true,'Vertical-tail x coordinate.');
rows = add_row(rows,'垂尾','垂尾气动中心 y','vtail.yAC','m','ASSUMED_CONCEPT',true,'Vertical-tail y coordinate.');
rows = add_row(rows,'垂尾','垂尾气动中心 z','vtail.zAC','m','ASSUMED_CONCEPT',true,'Vertical-tail z coordinate.');
rows = add_row(rows,'垂尾','垂尾零升阻力系数','vtail.CD0','-','ASSUMED_CONCEPT',true,'Vertical-tail drag constant.');
rows = add_row(rows,'垂尾','侧滑对垂尾侧向力的影响 CYbeta','vtail.CYbeta','1/rad','ASSUMED_CONCEPT',true,'Vertical-tail side-force derivative.');
rows = add_row(rows,'垂尾','方向舵对侧向力的影响 CYrudder','vtail.CYrudder','1/rad','ASSUMED_CONCEPT',true,'Rudder side-force derivative.');
end

function rows = add_matrix(rows, groupName, name, key, unit, source, editable)
rows = add_row(rows,groupName,name,key,unit,source,editable,'Matrix component exposed as a scalar catalog row.');
end

function rows = add_limit(rows, groupName, name, key, unit, source)
rows = add_row(rows,groupName,name,key,unit,source,true,'Control limit component.');
end

function rows = add_row(rows, groupName, name, key, unit, source, editable, description)
if nargin < 8
    description = '';
end
row.group = groupName;
row.name = name;
row.key = key;
row.unit = unit;
row.source = source;
row.sourceLabel = source_label(source);
row.description = description;
row.editable = logical(editable);
rows(end+1,1) = row;
end

function label = source_label(source)
switch source
    case 'REFERENCE_CONSTANT'
        label = '参考常数';
    case 'ASSUMED_CONCEPT'
        label = '概念假设';
    case 'ASSUMED_MODEL_PARAMETER'
        label = '模型假设';
    case 'NUMERICAL'
        label = '数值设置';
    case 'DERIVED'
        label = '派生计算';
    case 'DEPRECATED_COMPATIBILITY'
        label = '兼容保留';
    case 'SOURCE_REQUIRED'
        label = '外部来源待确认';
    case 'SIGN_CONVENTION_REQUIRED'
        label = '符号待确认';
    otherwise
        label = source;
end
end
