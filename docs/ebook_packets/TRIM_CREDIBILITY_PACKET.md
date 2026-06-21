# 配平可信度诊断方法包

## 1. 任务定位

本方法包服务于电子书升级路线优先级第 4 项：在已经完成的通用模式配平核心和开环俯仰操纵分配之上，建立配平解的数值可信度诊断。

当前主线：

1. `RH_mass/RH_hub` 语义拆分：已完成并合并；
2. 通用模式配平核心：已完成并合并；
3. 开环俯仰操纵分配：已完成并合并；
4. **配平可信度诊断：当前任务；**
5. 线性化可信度诊断；
6. 诱导速度显式残差和稳健求根。

本任务不修改配平方程、求解器、容差、模型参数或执行器限幅。它只回答：一个已经求得的低残差配平点，是否具有足够的局部独立性、数值稳定性、控制裕度和解支一致性。

## 2. 电子书依据

参考书：《直升机和倾转旋翼飞行器飞行仿真引论》。PDF 为扫描件，PDF 页码与书内页码不同。

本方法包只使用以下范围：

- PDF 348-351；书内页 323-326；第 17.1-17.2 节：配平条件、自由度和独立变量选择；
- PDF 352-356；书内页 327-331；第 17.4-17.5.2 节：操纵匹配和连续修正；
- PDF 358-361；书内页 333-336；第 17.5.3 节：以加速度残差和操纵/姿态变量构造配平 Jacobian；
- 电子书数值方法中关于中心、前向和后向差分的通用原则。

电子书的 Jacobian 修正形式用于解释变量—残差局部关系。本任务不把现有 `fminsearch` 改成 Newton 或 `fsolve`，也不改变配平求解路径。

## 3. 当前代码基线

当前通用配平接口：

```matlab
[xTrim, uTrim, report] = trim_general(condition, definition, P, opts)
```

当前定义包含：

```text
unknownNames
residualNames
initialValues
variableScale
bounds
fixedStates
fixedControls
allocation (optional)
```

当前报告已经包含：

```text
residual
residualScale
scaledResidual
fullStateDerivative
limitReport
commandedControls
appliedControls
trimVariables
trimVariableScale
allocation
```

现有 `report.converged` 只证明：

- 求解器正常结束；
-被选中的配平残差低于当前容差；
- 完整状态导数有限实数；
- 没有变量贴限或越限。

它尚未证明：

- 残差对未知量的 Jacobian 满秩；
- Jacobian 条件良好；
- 差分步长改变时 Jacobian 稳定；
- 未选中的状态导数足够小；
- 控制裕度充足；
- 小初值或小工况扰动不会切换到不同解支。

## 4. 诊断对象

对固定 `condition`、`definition` 和已接受配平点，定义未知量向量：

```math
z=[z_1,\ldots,z_n]^T
```

配平残差：

```math
F(z)=[F_1,\ldots,F_n]^T
```

原始 Jacobian：

```math
J_{raw}=\frac{\partial F}{\partial z}
```

为了避免 rad、无量纲虚拟命令、线加速度和角加速度的单位直接影响条件数，使用与求解器一致的缩放：

```math
J_s=
\operatorname{diag}(1/s_F)
J_{raw}
\operatorname{diag}(s_z)
```

其中：

```text
s_F = definition 对应的 residualScale
s_z = definition.variableScale
```

`J_s` 等价于“缩放残差对无量纲搜索变量的导数”，是本任务主要用于秩、奇异值和条件数分析的矩阵。

必须同时保留 `J_raw` 和 `J_s`。不得只输出条件数而丢失原始变量/残差标签。

## 5. Jacobian 差分方法

### 5.1 无量纲步长

在缩放搜索变量中使用三档诊断步长：

```text
hScaled = [1e-2, 1e-3, 1e-4]
```

其中 `1e-3` 为主报告步长，另外两档用于步长敏感性比较。

第 `j` 个未知量的物理扰动为：

```math
\Delta z_j=h_s\,s_{z,j}
```

这些步长分类为 `NUMERICAL_DIAGNOSTIC`，不是物理参数或真实操纵精度。

### 5.2 中心差分

若 `z_j ± Δz_j` 均满足未知量边界和由分配器生成的直接执行器边界，使用：

```math
\frac{\partial F}{\partial y_j}
\approx
\frac{F(z+\Delta z_j e_j)-F(z-\Delta z_j e_j)}{2h_s}
```

这里分母使用无量纲 `h_s`，因此直接得到 `J_s` 的列。

### 5.3 单边差分

若中心差分越过边界，优先使用二阶单边公式：

前向：

```math
\frac{-3F_0+4F_1-F_2}{2h_s}
```

后向：

```math
\frac{3F_0-4F_{-1}+F_{-2}}{2h_s}
```

若 `2h_s` 仍不可用，可逐级减小当前列步长；若无法得到合法有限点，必须将该列标记为 `UNAVAILABLE`，不能用隐藏钳位或越界残差代替。

报告每列实际使用：

```text
central
forward-second-order
backward-second-order
unavailable
```

## 6. SVD、秩和条件数

对主步长的 `J_s` 计算：

```math
J_s=U\Sigma V^T
```

报告：

```text
singularValues
sigmaMax
sigmaMin
conditionNumber = sigmaMax/sigmaMin
defaultRank
effectiveRank
```

同时使用两个秩阈值：

```text
MATLAB 默认 rank 阈值
effectiveRankTolerance = 1e-8*sigmaMax
```

`effectiveRankTolerance` 分类为 `NUMERICAL_DIAGNOSTIC`。

判定：

- `effectiveRank < nUnknown`：`FAIL / EFFECTIVE_RANK_DEFICIENT`；
- 满秩但条件数较大：记录为警告，不自动修改配平定义。

条件数提示等级：

```text
conditionNumber <= 1e3        LOW
1e3 < conditionNumber <= 1e6  CAUTION
conditionNumber > 1e6         SEVERE
```

这些等级是数值诊断启发式，不代表飞行品质等级或型号验收标准。

## 7. 差分步长稳定性

以 `hScaled=1e-3` 的 Jacobian 为基准，计算另外两档：

```math
\epsilon_J(h)=
\frac{\|J_s(h)-J_s(10^{-3})\|_F}
{\max(\|J_s(10^{-3})\|_F,\epsilon)}
```

并比较奇异值的相对变化。

提示等级：

```text
max epsilon_J <= 0.05      STABLE
0.05 < max epsilon_J <= 0.20  CAUTION
max epsilon_J > 0.20       SEVERE
```

若某一档因边界无法计算，应报告实际差分方法和缺失项，不得静默忽略。

## 8. 完整状态导数回代

状态顺序：

```text
[u v w p q r phi theta psi]
```

完整导数缩放：

```text
[udot vdot wdot] / g
[pdot qdot rdot] / 1
[phidot thetadot psidot] / 1
```

报告：

```text
fullStateDerivative
scaledFullStateDerivative
maxScaledFullDerivative
selectedResidualMask
unselectedDerivativeLabels
unselectedDerivativeValues
```

硬要求：

- 全部有限实数；
- `maxScaledFullDerivative < P.trim.residualTolerance`。

这不会替代各分量的原始单位报告。

## 9. 控制和未知量裕度

对每个有上下界的未知量和生成执行器，定义中心归一化裕度：

```math
marginFraction=
\frac{2\min(z-l,u-z)}{u-l}
```

它在区间中点为 1，在任一边界为 0。不得对负裕度进行隐藏钳位；越界应单独报告。

报告每项：

```text
name
value
lower
upper
marginAbsolute
marginFraction
atLimit
violated
```

提示等级：

```text
marginFraction >= 0.10      ADEQUATE
0.02 <= marginFraction < 0.10  LOW
marginFraction < 0.02       CRITICAL
```

45 deg 转换工况已知 `pitchCommand`、周期变距和升降舵的剩余裕度约为 6.63%，预期被标记为 `LOW`。该结果是诊断输出，不允许在本任务调权重、参数、限幅或容差。

同时报告：

```text
max(abs(commandedControls-appliedControls))
```

若差异超过 `1e-10 rad`，标记为 `FAIL / COMMAND_APPLIED_MISMATCH`，用于发现隐藏裁剪或不同控制路径。

## 10. 解支和初值敏感性

为了避免大范围多初值扫描，只对最关键的 35 m/s、45 deg 转换工况运行两个确定性初值扰动：

```text
seedPlus  = zTrim + 0.25*variableScale.*[+1,-1,+1]^T
seedMinus = zTrim - 0.25*variableScale.*[+1,-1,+1]^T
```

初值必须先检查边界；若越界，只沿同方向缩短到区间内部，不得改变符号模式或随机生成新初值。

比较两个结果与基准：

```text
max state difference
max control difference
residual norm difference
convergence status
limit status
```

解支一致性提示阈值：

```text
state/control difference <= 1e-6  CONSISTENT
difference > 1e-6                 CAUTION / POSSIBLE_BRANCH_SENSITIVITY
```

该阈值为 `NUMERICAL_DIAGNOSTIC`。

直升机端和飞机端只做 Jacobian、完整导数和裕度诊断，不再重复多初值求解，以控制运行时间。

## 11. 局部工况敏感性

只对 35 m/s、45 deg、gamma=0 工况进行四个小扰动：

```text
V = 34.5 m/s
V = 35.5 m/s
betaM = 44.5 deg
betaM = 45.5 deg
```

每个扰动使用基准配平解作为延拓初值，只运行一次。不得扩大为速度扫、倾转角扫或正反扫。

报告：

```text
converged
residualNorm
state/control change
conditionNumber
minimumMarginFraction
active/violated limits
```

45 deg 处的 `pitchCommandLimit=1/max(gCyclic,gElevator)` 存在连续但一阶导数不连续的边界特征。因此 44.5 deg 和 45.5 deg 必须分别报告，不得平均为一个对称导数。

局部扰动失败或进入限幅应产生 `CAUTION` 或 `FAIL` 诊断，但不允许为了让诊断“通过”而修改模型。

## 12. 总体可信度等级

建议报告：

```text
PASS
CAUTION
FAIL
```

### FAIL

满足任一项：

- 原配平 `report.converged=false`；
- 状态、控制、残差或 Jacobian 含 NaN/Inf/复数；
- `effectiveRank < nUnknown`；
- 变量/执行器越界；
- commanded/applied mismatch 超过阈值；
- 完整缩放导数超过当前配平容差。

### CAUTION

无 FAIL，但满足任一项：

- condition number 大于 `1e3`；
- Jacobian 步长变化大于 5%；
- 任一 `marginFraction < 0.10`；
- 两个确定性初值收敛到差异超过 `1e-6` 的解；
- 任一局部工况扰动失败、贴限或裕度显著降低；
- 使用单边差分或存在不可用 Jacobian 列。

### PASS

无 FAIL 或 CAUTION。

预期 35 m/s、45 deg 工况会因约 6.63% 的控制裕度得到 `CAUTION`。这表示“可配平但裕度偏低”，不表示实现失败。

## 13. 推荐接口

推荐新增：

```matlab
credibility = diagnose_trim_credibility( ...
    condition, definition, xTrim, uTrim, trimReport, P, opts)
```

报告至少包含：

```text
credibility.status
credibility.reasons
credibility.rawJacobian
credibility.scaledJacobian
credibility.stepResults
credibility.columnDifferenceMethods
credibility.singularValues
credibility.defaultRank
credibility.effectiveRank
credibility.rankTolerance
credibility.conditionNumber
credibility.conditionLevel
credibility.jacobianStepVariation
credibility.fullDerivative
credibility.scaledFullDerivative
credibility.marginItems
credibility.minimumMarginFraction
credibility.commandAppliedDifference
credibility.seedSensitivity
credibility.conditionSensitivity
credibility.classification = NUMERICAL_DIAGNOSTIC
```

允许增加少量辅助函数。若为了避免复制 `trim_general` 的点构造逻辑而抽取共享评估函数，必须先证明 legacy、端点和转换配平结果逐项不变。

不得把诊断结果反向写入求解器、权重、参数或限幅。

## 14. 代表工况

固定三个基准工况：

### 直升机端

```text
mode = helicopter_longitudinal
V = 20 m/s
betaM = 0
gamma = 0
```

### 转换工况

```text
mode = conversion_longitudinal
V = 35 m/s
betaM = pi/4
gamma = 0
```

### 飞机端

```text
mode = airplane_longitudinal
V = 100 m/s
betaM = pi/2
gamma = 0
```

不得增加工况网格。

## 15. 分阶段实施和计算预算

### Stage 0：基线

运行：

- `check_trim_mode_framework`；
- `check_pitch_allocation`；
- `run_all_checks` 一次。

记录三个代表配平点和运行时间。基线失败立即停止。

### Stage 1：只读 Jacobian 原型

在临时脚本中对三个基准工况计算三档 Jacobian、SVD、秩、条件数、完整导数和裕度。不得修改生产文件。

检查：

- 差分公式和缩放是否正确；
- 是否出现不可用列；
- 条件数和步长变化量级；
- 45 deg 是否按预期触发低裕度警告。

Stage 1 结果审查前不得实现生产诊断函数。

### Stage 2：实现诊断接口

Stage 1 通过后实现诊断函数、报告结构和聚焦测试。

### Stage 3：关键工况敏感性

只运行第 10、11 节规定的两个初值和四个局部工况扰动。

### Stage 4：回归

聚焦测试通过后注册新测试，并运行一次 `run_all_checks`。

预计总墙钟时间约 3-8 分钟。执行顺序必须是：快速静态检查 → 三个基准点 → 45 deg 局部敏感性 → 一次总回归。

## 16. 建议文件范围

允许修改：

```text
CODEX_TASK.md
analysis/diagnose_trim_credibility.m
analysis/evaluate_trim_definition_point.m   # 仅在确需共享点构造时新增
tests/check_trim_credibility.m
tests/run_all_checks.m
docs/TRIM_CREDIBILITY_AUDIT.md
docs/EBOOK_MODEL_UPGRADE_PRIORITY.md
```

如抽取共享点构造，允许最小修改：

```text
analysis/trim_general.m
```

原则上不修改：

```text
analysis/make_trim_definition.m
analysis/trim_symmetric.m
analysis/pitch_allocation_schedule.m
```

禁止修改：

```text
params_nominal.m
model/*
app/*
services/*
analysis/linearize_numeric.m
控制限幅
配平容差
求解器设置
```

## 17. 禁止事项

- 不得把诊断任务改成配平求解器重写；
- 不得切换到 `fsolve`、Newton 或 Optimization Toolbox；
- 不得修改模型参数、余弦分配、命令方向、动态命令范围、执行器限幅或残差容差；
- 不得根据条件数自动重配操纵量；
- 不得用随机多初值或密集扫描寻找更好结果；
- 不得进入线性化 A/B 诊断；
- 不得声称通过诊断等同于 XV-15 验证或飞行试验验证；
- 不得把 `CAUTION` 当作代码测试失败，只要分类和原因正确、数据有限可追踪即可。

## 18. 完成标准

本工作包完成时必须满足：

1. 三个代表点均生成可追踪的 raw/scaled Jacobian；
2. 三档步长、每列差分方法和步长稳定性均被记录；
3. SVD、默认秩、有效秩和条件数均被报告；
4. 完整九状态导数、commanded/applied 差异和控制裕度均被报告；
5. 45 deg 低裕度被标记为 `CAUTION`，没有通过调参消除；
6. 只运行规定的两个初值和四个局部工况扰动；
7. 诊断结果不影响原配平求解和 acceptance；
8. 原 legacy、直升机端、转换点和飞机端结果保持；
9. 聚焦测试和总回归通过；
10. 没有进入模型、参数、线性化、入流或飞控修改。
