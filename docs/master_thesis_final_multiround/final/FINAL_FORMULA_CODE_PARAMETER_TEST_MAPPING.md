# 最终公式—代码—参数—测试映射

本表只对应 PR #57 head 及本任务只读分析，不沿用历史“待填写”条目。

|物理模块|论文公式|文献页码/公式号|当前代码文件|函数/变量|参数来源|测试|状态|
|---|---|---|---|---|---|---|---|
|机体系与短舱角|坐标基与端点映射|NUAA PDF 3 图2；NASA TM-81244 PDF 6|`model/rotor_model_bemt.m`|`eT,eD,eY,betaM`|代码定义与文献映射|`check_nacelle_endpoints`|部分核实|
|Euler 321 运动学|`etaDot=T omega`|Dreier 飞行动力学理论|`model/tiltrotor_eom.m`|`euler_321_dot`|标准理论|`run_all_checks`|标准理论闭合|
|平动方程|`m(Vdot+omega x V)=F+mg`|NUAA PDF 11--12|`model/tiltrotor_eom.m`|`Vdot,Fg`|标准理论|配平回代与有限值|已核实|
|转动方程|`I omegaDot+omega x Iomega=M`|NUAA PDF 11--12|`model/tiltrotor_eom.m`|`omegaDot`|标准理论|惯量与力矩检查|已核实|
|重力投影|`mg[-sin theta,...]`|标准 321 关系|`model/tiltrotor_eom.m`|`Fg`|标准理论|端点/配平回代|已核实|
|总质量与重心|`m=sum mi`、`rcg=sum mi ri/m`|NUAA PDF 3|`model/mass_properties.m`|`mass,cgShift`|概念参数与推导|`check_mass_inertia_geometry`|已核实|
|平行轴与总惯量|`I=sum(RIiR^T+mi S^TS)`|标准刚体理论|`model/berger13/mass_properties_berger13.m`|`I`|推导与研究假设|PR3 mass checks|已核实|
|轮毂局部速度|`Vh=V+omega x rh`|NUAA PDF 5 附近|`model/rotor_model_bemt.m`|`Vhub`|标准运动学|rotor force chain|已核实|
|旋翼轴系|`[eT eD eY]`|NUAA 式(14)--(15)|`model/rotor_model_bemt.m`|`eT,eD,eY`|公开公式/代码映射|端点与镜像|部分核实|
|桨距与扭转|`theta=theta0+theta_tw r/R+...`|NUAA 旋翼公式链|`model/rotor_model_bemt.m`|`thetaLocal`|概念参数|flapping checks|工程假设|
|叶素相对速度|`W=sqrt(UT^2+UP^2)`|叶素理论；NUAA PDF 5--7|`model/rotor_model_bemt.m`|`Ut,Up,W`|标准理论|grid/flapping checks|标准理论闭合|
|入流角与攻角|`phi=atan2(UP,UT)`、`alpha=theta-phi`|叶素理论|`model/rotor_model_bemt.m`|`phiInflow,alpha`|标准理论|rotor checks|已核实|
|叶素升阻力|`dL=0.5rho W^2 c Cl dr`|叶素理论|`model/rotor_model_bemt.m`|`dL,dD`|假设极曲线|grid checks|工程假设|
|推力与扭矩积分|方位/半径数值积分|NUAA 式(9)--(11)附近|`model/rotor_model_bemt.m`|`blade_loads`|公开结构+数值离散|grid convergence|部分核实|
|诱导速度|正推力动量闭合迭代；最终复算未截断推力残差|NUAA 公开公式链|`model/rotor_model_bemt.m`|`viMean,inducedClosureResidual,physicalConverged`|公开结构+工程闭合；无量纲相对残差门限 \(2\times10^{-4}\) 为数值审计判据；负推力/风车分支缺失|`check_rotor_physical_convergence`|正推力部分核实；负推力明确不支持|
|一阶谐波入流|`lambda=lambda0+lambda1c cos psi+...`|NUAA 式(12)|`model/rotor_model_bemt.m`|谐波入流项|公开公式|Eq12 checks|已核实|
|稳态一阶挥舞|`beta=beta0+beta1c cos psi+beta1s sin psi`|NUAA 式(13)|`model/rotor_model_bemt.m`|`flapState`|公开形式+简化闭合|flapping checks|部分核实|
|反扭矩与旋向|`M_Q=-rotDir Q eT`|旋翼力矩平衡|`model/rotor_model_bemt.m`|`rotDir,Q`|标准理论|mirror/torque tests|已核实|
|机翼局部来流|`Vr=V+omega x r+Vwake`|NUAA 式(17)|`model/wing_model.m`|`Vlocal`|公开公式|Eq17 checks|已核实|
|尾流覆盖|式(16)面积关系+物理限界|NUAA 式(16)|`model/wing_model.m`|`SslipHalf`|公开式+代码限界|Eq16 checks|部分核实|
|机翼升阻力|`L=qSCL,D=qSCD`|低阶气动理论|`model/wing_model.m`|`CL,CD,Cm`|概念/等效参数|aero component tests|工程假设|
|near-normal 混合|局部法向流比上的五次 smootherstep|代码连续化设计|`model/wing_model.m`|`normalFlowRatioActual,branchWeight`|假设模型参数；与配平 `pitchCommand` 无共享变量或传参|blend continuity|工程假设|
|机身载荷|动压与低阶系数|无同构试验源|`model/fuselage_model.m`|气动系数|概念参数|aero component tests|工程假设|
|平尾/升降舵|局部来流、下洗和舵效|低阶尾翼理论|`model/horizontal_tail_model.m`|`incidence,downwashAlpha,CLelevator`|假设/等效参数|aero/trim tests|工程假设|
|双垂尾/方向舵|侧滑与双尾合成|低阶尾翼理论|`model/vertical_tail_model.m`|`CYbeta,CYrudder`|概念参数|aero/mirror tests|工程假设|
|整机合力合矩|`sum Fi`、`sum(Mi+ri x Fi)`|标准刚体理论|`model/total_forces_moments.m`|`Ftotal,Mtotal`|部件输出|force/moment chain|已核实|
|配平残差|尺度化动力学残差|Dreier 配平章节|`analysis/trim_general.m`|`residual`|数值方法|trim framework/credibility|已核实|
|控制余度|到上下界的归一化距离|本文定义|`analysis/diagnose_trim_credibility.m`|`minimumMarginFraction`|假设计准|trim credibility|已核实|
|Jacobian/SVD|`J=dr/dz`、`J=U Sigma V^T`|标准数值理论|`analysis/trim_residual_jacobian.m`|`J,singularValues`|数值方法|PR2/PR5 checks|已核实|
|中心差分线性化|`A(:,j)=[f(x+h)-f(x-h)]/(2h)`|标准数值理论|`analysis/linearize_numeric.m`|`A,B`|数值步长|three-step checks|已核实|
|对称/差动变换|和差坐标矩阵|本文接口定义|`analysis/berger13/berger13_symdiff_transform.m`|`T,A,B`|推导|cross-block checks|已核实|
|十三状态向量|`[x9,betaL,betaR,betaDotL,betaDotR]`|Berger PDF 90--96 结构对照|`model/berger13/berger13_names.m`|`stateNames`|结构对照|interface tests|已核实|
|二阶短舱执行机构|`betaDDot=wn^2(betaCmd-beta)-2zeta wn betaDot`|标准二阶形式|`model/berger13/nacelle_command_actuator.m`|`omegaN,zeta`|研究占位参数|PR3 actuator tests|研究占位参数|
|执行机构反作用矩|`Mreact=-sum Qint eBeta`|作用反作用|`model/berger13/tiltrotor_eom_13x10_command.m`|`MactuatorReaction`|标准力学+占位转矩|reaction test|部分核实|
|转子陀螺项|`M=-dH/dt`|角动量理论|同上|`MnacelleRateGyro,Jpolar`|接口；默认 J=0|gyro parameter test|工程假设|
|机械卡滞|未实现|无|同上|`mechanicalJamImplemented=false`|无|boundary tests|未实现|
|MAE/RMSE|误差统计式|标准统计定义|`recompute_external_rotor_metrics.py`|metrics|图线数字化|双数字化复核|已核实|
