# 开环俯仰操纵分配方法包（修订版）

## 1. 当前技术主线

本工作包是当前优先级第 3 项：

1. `RH_mass/RH_hub` 语义拆分：已完成并合并；
2. 通用模式配平核心：已完成并合并；
3. **开环俯仰操纵分配：当前任务；**
4. 配平可信度诊断；
5. 线性化可信度诊断；
6. 诱导速度显式残差与稳健求根。

本任务不提前开展第 4 项及其后的工作。

项目仍是开环飞行器本体模型。这里的“分配”是一个位于配平器与直接执行器输入之间的开环混合层，不含 SCAS、姿态反馈、角速度反馈、自动驾驶、飞行员模型或控制律设计。

## 2. 修订原因

先前候选方案将 `cyclicLong` 和 `elevator` 同时作为独立配平未知量，再增加一条代数比例残差。该写法在方程计数上可闭合，但没有直接体现电子书图 15-5 所示的“一个纵向输入经混合装置产生两个执行器输出”。

本修订版采用更直接的结构：

- 飞行器本体继续接收直接执行器量；
- 配平层新增一个归一化虚拟纵向开环命令 `pitchCommand`；
- 混合器由 `pitchCommand` 和 `betaM` 计算 `cyclicLong`、`elevator`；
- 转换配平仍使用三个未知量与三个动力学残差。

因此不再通过第四条残差强制两个执行器满足比例关系。分配关系在构造控制向量时已被精确满足。

## 3. 电子书依据

参考书：《直升机和倾转旋翼飞行器飞行仿真引论》。使用范围限定为：

- PDF 298-301；书内页 273-276；第 15.2.3 节；
- 图 15-5：纵向周期变距输入与升降舵输入经过操纵混合装置；
- 表 15-1：纵向周期变距输出随主轴角增加；
- 表 15-2：升降舵输出随主轴角减小。

电子书定义：

```text
主轴角 90 deg = 直升机模式
主轴角 0 deg  = 飞机模式
```

当前代码定义：

```text
betaM = 0       = 直升机模式
betaM = pi/2    = 飞机模式
```

换算关系：

```math
\theta_{mast}=\frac{\pi}{2}-\beta_M
```

电子书中的余弦示例换算到当前代码后为：

```math
g_c(\beta_M)=\cos^2\beta_M
```

```math
g_e(\beta_M)=\sin^2\beta_M
```

其中：

```text
g_c = longitudinal cyclic schedule gain
g_e = elevator schedule gain
```

必须满足：

```math
g_c+g_e=1
```

端点：

```text
betaM = 0       -> g_c=1,   g_e=0
betaM = pi/4    -> g_c=0.5, g_e=0.5
betaM = pi/2    -> g_c=0,   g_e=1
```

该余弦曲线只是电子书提供的通用示例。当前应用分类必须标为：

```text
ASSUMED_CONCEPT
```

不得称为 XV-15 实际混控律。

## 4. 先审计、后实施

实施分为两个门控阶段。

### Phase A：只读符号与可用性审计

在修改生产代码前，Codex 必须使用当前已合并模型运行小扰动检查。

代表点：

1. 直升机端：`V=20 m/s, betaM=0`，使用 `helicopter_longitudinal` 配平；
2. 转换参考点：`V=35 m/s, betaM=pi/4`，使用现有 legacy 配平点仅作局部导数审计；
3. 飞机端：`V=100 m/s, betaM=pi/2`，使用 `airplane_longitudinal` 配平。

在每个适用点，用中心差分 `h=1e-4 rad` 计算：

```math
\frac{\partial \dot q}{\partial cyclicLong}
```

```math
\frac{\partial \dot q}{\partial elevator}
```

只记录：

- 符号；
- 数值是否有限、实数；
- 在该通道应发挥作用的工况下是否明显高于数值噪声；
- 符号是否随三个代表点发生反转。

这些导数不得用于按控制有效性重新加权混合曲线，也不得用于参数调节。

通过条件：

- 两个通道都存在一致、可解释的命令方向；
- 代表转换点没有出现控制方向反转；
- 结果与直接代码坐标约定一致。

若不通过：停止，不修改生产代码，提交只读审计报告并要求修订方法包。

### Phase B：实现与验证

只有 Phase A 通过后，才允许实现本方法包其余内容。

## 5. 虚拟纵向开环命令

新增归一化配平变量：

```text
pitchCommand = eta_p
```

定义范围：

```math
-1\leq\eta_p\leq1
```

它不是驾驶杆模型，也不是闭环控制信号；只是配平层的归一化开环命令。

现有直接执行器限幅的绝对最大值作为归一化参考：

```math
C_{ref}=\max|P.control.cyclicLim|
```

```math
E_{ref}=\max|P.control.elevatorLim|
```

当前数值分别为 35 deg 和 40 deg，但实现必须从现有参数读取，不得复制为新的物理参数。

混合关系：

```math
cyclicLong=s_c\,g_c(\beta_M)\,C_{ref}\,\eta_p
```

```math
elevator=s_e\,g_e(\beta_M)\,E_{ref}\,\eta_p
```

`s_c` 与 `s_e` 是当前代码命令方向映射，只能由 Phase A 审计确定。它们必须是 `+1` 或 `-1`，并在审计文档中说明依据。不得为了改善收敛而试错选择。

使用限幅作为参考尺度也是概念选择，只代表“相同百分比行程”，不代表真实机械传动比。

## 6. 转换模式配平定义

新增显式定义：

```text
conversion_longitudinal
```

未知量：

```text
theta
collective
pitchCommand
```

残差：

```text
udot
wdot
qdot
```

固定状态：

```text
v=p=q=r=phi=psi=0
```

固定控制：

```text
diffCollective=0
diffCyclic=0
aileron=0
rudder=0
```

`cyclicLong` 和 `elevator` 不再作为独立未知量或固定量，由混合层生成。

不得根据 `betaM` 自动选择配平模式。调用者必须显式请求 `conversion_longitudinal`。

## 7. 与端点模式的关系

同一个 `conversion_longitudinal` 定义应在端点退化为：

### betaM = 0

```math
cyclicLong=s_c C_{ref}\eta_p
```

```math
elevator=0
```

这应与 `helicopter_longitudinal` 具有一一对应的有效控制自由度。

### betaM = pi/2

```math
cyclicLong=0
```

```math
elevator=s_e E_{ref}\eta_p
```

这应与 `airplane_longitudinal` 具有一一对应的有效控制自由度。

端点等价必须通过数值结果验证，不能只凭公式宣布。

## 8. 推荐最小代码接口

推荐新增纯函数：

```matlab
allocation = pitch_allocation_schedule(betaM, pitchCommand, P, direction)
```

至少输出：

```text
allocation.type
allocation.classification
allocation.betaM
allocation.gCyclic
allocation.gElevator
allocation.cyclicReference
allocation.elevatorReference
allocation.cyclicDirection
allocation.elevatorDirection
allocation.pitchCommand
allocation.cyclicLong
allocation.elevator
```

建议：

```text
type = 'ebook_cosine_virtual_command'
classification = 'ASSUMED_CONCEPT'
```

`make_trim_definition` 的转换定义可包含：

```text
unknownNames = theta, collective, pitchCommand
residualNames = udot, wdot, qdot
allocation configuration
```

`trim_general` 只在 definition 明确声明 allocation 时识别 `pitchCommand`，并在构造 7 控制向量时调用混合函数。

没有 allocation 配置时，`pitchCommand` 必须被视为非法未知量；原有四执行器未知量、三残差的欠定保护必须保留。

## 9. 数值尺度与限幅

`pitchCommand` 的物理边界固定为 `[-1,1]`。

搜索尺度属于数值设置，建议从 2 deg 的现有端点搜索尺度换算：

```math
\Delta\eta_p=
\frac{2\ deg}{g_c C_{ref}+g_e E_{ref}}
```

分母在整个区间内为正。该值只用于 `fminsearch` 的无量纲搜索尺度，分类为 `NUMERICAL`。

最终直接执行器量必须继续经过现有控制限幅和 applied-control 报告。不得修改任何限幅值。

## 10. 报告要求

转换配平报告至少增加：

```text
report.allocation
report.trimVariables.pitchCommand
report.commandedControls
report.appliedControls
```

`report.allocation` 至少包含第 8 节列出的字段。

收敛判据继续使用三个动力学残差和现有配平容差，并同时要求：

- 求解器收敛；
- 完整状态导数有限、实数；
- `pitchCommand` 不贴限、不越界；
- 生成的 `cyclicLong`、`elevator` 不贴限、不越界；
- applied controls 与 commanded controls 的关系可追踪。

不增加新的代数残差容差。

## 11. 分阶段测试

### Stage 0：旧基线

先运行：

- `check_trim_mode_framework`；
- `run_all_checks` 一次；
- 记录 legacy、helicopter、airplane 端点结果。

### Stage 1：Phase A 审计

运行第 4 节规定的三个代表点与局部导数检查。先报告结果；未通过则停止。

### Stage 2：纯分配函数

检查 `betaM=[0,15,30,45,60,75,90] deg`：

- 权重有限、实数且位于 `[0,1]`；
- `g_c+g_e=1`；
- `g_c` 单调不增；
- `g_e` 单调不减；
- 两端与 45 deg 精确满足预期；
- `betaM` 越界、非有限命令、非法方向映射明确报错；
- 生成执行器量满足公式。

### Stage 3：端点等价

使用 `conversion_longitudinal`：

- `V=20 m/s, betaM=0` 与 `helicopter_longitudinal` 比较；
- `V=100 m/s, betaM=pi/2` 与 `airplane_longitudinal` 比较。

目标：

```text
state absolute difference <= 1e-8
control absolute difference <= 1e-8
residual norm difference <= 1e-8
```

报告实际最大差异。不得放宽容差来掩盖不同解支。

### Stage 4：单一转换点

只运行：

```text
V=35 m/s
betaM=pi/4
gamma=0
```

要求：

- 三个动力学残差满足当前配平容差；
- 状态和控制有限、实数；
- `pitchCommand`、周期变距、升降舵均不贴限、不越界；
- 两个执行器严格满足虚拟命令映射；
- 不修改模型参数和求解器容差。

若失败，报告最佳残差、活动限制、非法求值和失败原因，然后停止。不得扩大到工况扫描或调参。

### Stage 5：回归

聚焦测试通过后运行一次：

```matlab
run_all_checks
```

预计总墙钟时间 2-6 分钟。不得进行速度精扫、倾转角扫描、正反扫、密集多初值或 Jacobian 图。

已知 MATLAB R2021a 退出阶段 `mwboost::archive::archive_exception` 与测试断言结果分开记录。

## 12. 允许修改的文件

```text
CODEX_TASK.md
analysis/trim_general.m
analysis/make_trim_definition.m
analysis/pitch_allocation_schedule.m
tests/check_pitch_allocation.m
tests/run_all_checks.m
docs/PITCH_ALLOCATION_AUDIT.md
```

原则上不修改 `trim_symmetric.m`。若必须修改，需证明旧结果严格不变。

不得修改：

```text
params_nominal.m
model/*
GUI
services
analysis/linearize_numeric.m
电子书方法包
```

## 13. 禁止事项

- 不得把概念分配称为真实型号混控；
- 不得增加或猜测真实机械传动比；
- 不得引入反馈、SCAS、自动驾驶或飞行员模型；
- 不得用控制有效性大小调整 `g_c`、`g_e`；
- 不得为了收敛翻转命令方向、修改参数、限幅或容差；
- 不得把 `cyclicLong`、`elevator` 与 `pitchCommand` 同时作为独立未知量；
- 不得增加第四条隐藏或显式分配残差；
- 不得自动根据 `betaM` 选择模式；
- 不得执行大范围扫描。

## 14. 完成标准

1. Phase A 符号审计通过并有可追踪报告；
2. 余弦权重与角度换算正确；
3. 分配结构采用单一虚拟命令映射到两个直接执行器；
4. `conversion_longitudinal` 仍为三个未知量、三个动力学残差；
5. 两个端点数值上退化到已验证模式；
6. 45 deg 单一转换点通过，或失败被如实记录且没有调参；
7. legacy、helicopter、airplane 原结果保持；
8. 没有引入 GUI、模型方程、真实参数、反馈控制、Jacobian、线性化或诱导速度改动；
9. 聚焦测试和总回归通过；
10. 所有新增分配内容明确标记 `ASSUMED_CONCEPT`。
