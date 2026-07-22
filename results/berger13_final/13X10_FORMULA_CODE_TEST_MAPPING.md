# 公式—代码—参数—测试映射

|公式/关系|代码|参数分类|测试/证据|
|-|-|-|-|
|刚体 6DOF、完整惯量矩阵|`model/berger13/tiltrotor_eom_13x10*.m`|继承概念模型|legacy 对称回归、有限值、配平回代|
|`M_arm=cross(r,F)`|左右旋翼及半翼模型|DERIVED|镜像、差动力矩与作用点测试|
|`I betaDDot=Q-D betaDot`|`nacelle_derivative`/扭矩 EOM|RESEARCH_PLACEHOLDER|PR1 接口和 PR3 保持测试|
|二阶角指令执行器|`compute_nacelle_command_actuator.m`|RESEARCH_PLACEHOLDER|阶跃、四类限幅、左右差异、故障测试|
|左右独立旋翼与滑流半翼|`compute_berger13_rotor_loads.m`、`wing_model_berger13_independent.m`|继承+假设|对称退化、正负 `betaDiff` 镜像|
|移动 CG/惯量|`mass_properties_berger13.m`|DERIVED+假设|对称退化、左右交换、正定性|
|对称/差动变换|`berger13_symdiff_transform.m`|DERIVED|可逆性和镜像关系|
|正式配平与可信度门|`trim_berger13_symmetric.m`、`evaluate_berger13_trim_point.m`|数值方法|多初值、continuation、SVD、限幅和回代|
|三步长中心/端点单边线性化|`linearize_13x10_*_numeric.m`|数值方法|有限性、步长变化、非可信点拒绝|
|左右特征向量与参与因子|`analyze_berger13_modes.m`|数值方法|双正交误差、归一化测试|
|Hungarian 模态跟踪|`track_berger13_modes.m`、`hungarian_assignment.m`|数值方法|已知最优分配、相同模型连续性|
|非线性固定步长 Heun 仿真|`simulate_berger13_case.m`|数值方法|13 状态、实标量指标、发散显式标志|
|线性—非线性比较|`compare_berger13_linear_nonlinear.m`|数值方法|五种小输入、十个状态误差表|

文献方法映射：Sheng、Zhang、Xiang，*Drones* 2022，PDF 2–10 页，第 2–3 节，式 (1)–(36) 支持部件划分/坐标变换/6DOF 结构；PDF 12 页，第 5 节，式 (37)–(42) 支持“配平后线性化”的方法。Dreier 中文版 PDF 348–360 页（书页 323–335），第 17 章表 17-1/17-2、式 (17-1)–(17-19) 支持明确自由度、约束、残差、Jacobian 和迭代回代。二者均不提供本项目 13×10 参数真值。
