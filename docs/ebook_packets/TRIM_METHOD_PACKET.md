# 通用模式配平方法包

## 1. 任务定位

本方法包只服务于优先级第 2 项：建立通用、模式可配置的纵向对称配平核心。

当前项目仍是开环飞行器本体模型。本任务不引入 SCAS、自动驾驶、反馈控制律或飞行员模型；也不实现真实型号混控曲线。

本任务与后续工作的边界：

- 本任务：通用配平核心、变量/残差定义、直升机端和飞机端定义、旧接口兼容；
- 下一任务：转换区的开环俯仰执行器分配约束；
- 再下一任务：配平 Jacobian、秩、条件数和限幅可信度诊断。

不得把上述三项合并为一次大改动。

## 2. 电子书依据

参考书：《直升机和倾转旋翼飞行器飞行仿真引论》。该 PDF 为扫描件，PDF 页码与书内页码不同。

本方法包只使用以下有限范围：

### 2.1 配平定义和自由度选择

- PDF 348-351；书内页 323-326；第 17.1-17.2 节。
- 核心原则：
  - 配平变量必须能够影响需要配平的自由度；
  - 变量应保持在物理范围内；
  - 配平问题必须完整；
  - 独立变量应覆盖被配平自由度；
  - 未作为独立变量的量必须有明确固定值或约束；
  - 独立未知量数与独立配平方程数必须匹配。

### 2.2 操纵匹配和方法选择

- PDF 352-356；书内页 327-331；第 17.4-17.5.2 节。
- 核心原则：
  - 一个操纵量可能同时影响多个自由度；
  - 多个操纵量也可能共同影响一个自由度；
  - 连续修正法需要合理的操纵匹配；
  - 对当前强耦合模型，通用数值优化/雅可比方法比硬编码逐通道修正更合适。

### 2.3 Jacobian 配平形式

- PDF 358-361；书内页 333-336；第 17.5.3 节。
- 电子书给出以加速度为残差、以操纵和姿态为独立变量的 Jacobian 修正形式。
- 本任务只保留可扩展的数据接口；不在本任务实现 Jacobian 条件数、奇异值或 Newton 修正，这些属于优先级第 4 项。

### 2.4 倾转旋翼操纵分配背景

- PDF 298-301；书内页 273-276；第 15.2.3 节、表 15-1 和表 15-2。
- 电子书说明：直升机端主要使用纵向周期变距，飞机端主要使用升降舵，转换区可采用线性、半线性或余弦函数连续交接。
- 电子书主轴角约定为 `90 deg` 直升机端、`0 deg` 飞机端；当前代码 `betaM=0` 为直升机端、`betaM=90 deg` 为飞机端，两者方向相反。
- 这些分配函数属于优先级第 3 项，本任务不得实现或选定某一真实混控函数。

## 3. 当前代码基线

当前函数：

```matlab
[xTrim, uTrim, report] = trim_symmetric(V, betaM, P, opts)
```

当前纵向对称状态构造：

```matlab
alpha = theta - gamma;
u = V*cos(alpha);
w = V*sin(alpha);
x = [u; 0; w; 0; 0; 0; 0; theta; 0];
```

当前控制向量顺序：

```text
1 collective
2 diffCollective
3 cyclicLong
4 diffCyclic
5 aileron
6 elevator
7 rudder
```

当前配平未知量：

```text
theta, collective, cyclicLong
```

当前残差：

```text
udot, wdot, qdot
```

当前固定量：

```text
v=p=q=r=phi=psi=0
diffCollective=diffCyclic=aileron=elevator=rudder=0
```

当前 `trim_symmetric` 在所有 `betaM` 下都使用这套直升机式闭合。它必须保留为兼容入口，但其过渡/飞机角结果只能标为 legacy closure，不得再描述为电子书式模式配平。

## 4. 本任务目标架构

### 4.1 通用核心

新增一个不依赖 GUI 的分析层函数，推荐接口：

```matlab
[xTrim, uTrim, report] = trim_general(condition, definition, P, opts)
```

其中：

```matlab
condition.V
condition.betaM
condition.gamma
```

`definition` 至少包含：

```matlab
definition.name
definition.unknownNames
definition.residualNames
definition.fixedStates
definition.fixedControls
definition.initialValues
definition.variableScale
definition.bounds
```

允许增加最小必要字段，但不得把 GUI 结构或型号专用字段写入通用核心。

通用核心必须由变量名映射构造完整 9 状态、7 控制向量，调用现有：

```matlab
tiltrotor_eom(x, uCtrl, betaM, P)
```

### 4.2 未知量与约束计数

在求解前必须检查：

```text
number of independent unknowns == number of independent residuals
```

若不相等，必须抛出带明确标识符的错误，不得悄悄最小二乘选解，也不得增加隐藏权重。

推荐错误标识符：

```text
trim_general:UnderdeterminedDefinition
trim_general:OverdeterminedDefinition
trim_general:InvalidDefinition
```

若未来允许附加代数约束，则应将这些约束作为显式 residual 条目计数。

### 4.3 模式选择必须显式

本任务不得根据 `betaM` 自动选择模式阈值。

调用者必须显式指定：

```text
legacy_symmetric
helicopter_longitudinal
airplane_longitudinal
custom
```

不得自行发明类似 `betaM<45 deg` 的切换规则。

## 5. 首批模式定义

### 5.1 Legacy symmetric

目的：完整保持现有 `trim_symmetric` 行为和测试。

未知量：

```text
theta, collective, cyclicLong
```

残差：

```text
udot, wdot, qdot
```

控制向量：

```matlab
[collective; 0; cyclicLong; 0; 0; 0; 0]
```

适用说明：兼容旧调用；在中间和飞机短舱角只表示旧闭合，不能作为新模式配平的物理结论。

### 5.2 Helicopter longitudinal

未知量：

```text
theta, collective, cyclicLong
```

残差：

```text
udot, wdot, qdot
```

固定控制：

```text
elevator=aileron=rudder=0
differential controls=0
```

控制向量：

```matlab
[collective; 0; cyclicLong; 0; 0; 0; 0]
```

首批验收工况只使用 `betaM=0`。本任务不规定该定义在多大倾转角范围内有效。

### 5.3 Airplane longitudinal

未知量：

```text
theta, collective, elevator
```

残差：

```text
udot, wdot, qdot
```

固定控制：

```text
cyclicLong=0
aileron=rudder=0
differential controls=0
```

控制向量：

```matlab
[collective; 0; 0; 0; 0; elevator; 0]
```

首批验收工况只使用 `betaM=pi/2`。总距在这里调节推进旋翼推力，升降舵提供主要俯仰配平控制。

这是一套概念模型端点定义，不声称等于 XV-15 实际操纵系统。

### 5.4 Conversion mode

本任务不提供默认自动转换配平。

原因：若同时把

```text
theta, collective, cyclicLong, elevator
```

设为未知量，而只使用

```text
udot, wdot, qdot
```

三个残差，则问题欠定。

本任务必须对默认转换定义明确报错或返回 unsupported 状态，提示需要优先级第 3 项的开环执行器分配约束。

推荐错误标识符：

```text
trim_general:AllocationConstraintRequired
```

通用 `custom` 定义可以为未来附加第四个代数约束预留接口，但本任务不得编写线性、余弦或型号专用分配函数。

## 6. 数值方法和兼容要求

### 6.1 求解器

Legacy 路径必须保持现有：

- 精确悬停的一维 collective 搜索；
- 前飞的无量纲 `fminsearch`；
- 当前 multistart 行为；
- 当前残差尺度 `[g; g; 1]`；
- 当前容差、最大迭代数和限幅判断。

不得在本任务切换到 `fsolve`、Newton 法或 Optimization Toolbox 专用求解器。

通用核心可复用/抽取现有求解逻辑，但不得改变 legacy 数值路径。

### 6.2 变量尺度

每个定义必须显式提供与未知量同长度的数值搜索尺度。

Legacy/helicopter 使用当前：

```matlab
[theta; collective; cyclicLong] -> [2; 18; 2] deg
```

Airplane 首版允许使用：

```matlab
[theta; collective; elevator] -> [2; 18; 2] deg
```

该 `2 deg` elevator 尺度必须标为 `NUMERICAL`，不属于真实操纵系统参数。

### 6.3 限幅

使用现有参数：

```matlab
P.control.collectiveLim
P.control.cyclicLim
P.control.elevatorLim
```

不得修改任何限幅数值。通用报告必须区分 commanded 和 applied controls。

### 6.4 输出报告

`report` 至少增加：

```matlab
report.definitionName
report.mode
report.unknownNames
report.residualLabels
report.fixedStates
report.fixedControls
report.trimVariables
report.commandedControls
report.appliedControls
report.fullStateDerivative
report.compatibilityMode
```

Legacy 报告中应明确：

```text
compatibilityMode = true
```

新的 helicopter/airplane 定义应为 false。

## 7. `trim_symmetric` 兼容策略

现有函数签名不得改变。

允许两种实现方式：

1. 保留 `trim_symmetric.m` 的现有求解代码，只新增通用核心；
2. 将现有代码安全抽取到通用核心，使 `trim_symmetric` 成为 legacy wrapper。

优先选择能最大程度保持数值输出和调用者行为的方式。

现有 GUI、services、`run_demo.m` 和旧测试本任务均继续调用 `trim_symmetric`。本任务不修改 GUI，也不将新模式选择暴露到 GUI。

## 8. 禁止事项

本任务不得：

- 修改旋翼、机翼、机身、尾翼、质量或六自由度方程；
- 修改现有物理参数和控制限幅；
- 加入真实 XV-15 数据；
- 实现连续混控函数或选择混控权重；
- 将操纵分配称为飞控；
- 增加 SCAS、控制器或闭环反馈；
- 修改线性化方法；
- 修改诱导速度求解；
- 执行速度精扫、正反扫、大量多初值或密集 Jacobian 图；
- 为了使飞机模式收敛而调整气动、质量或惯量参数。

## 9. 建议文件范围

允许的生产/测试文件应限制在：

```text
CODEX_TASK.md
analysis/trim_general.m
analysis/trim_symmetric.m
analysis/make_trim_definition.m     # 仅在确有必要时
tests/check_trim_mode_framework.m
tests/run_all_checks.m              # 仅注册新检查
```

允许新增一个简短审计文件：

```text
docs/TRIM_MODE_FRAMEWORK_AUDIT.md
```

不得修改 GUI、services 和其他模型文件。

## 10. 分阶段测试和运行预算

### Stage 0 - 旧基线

先运行现有聚焦配平测试和 `run_all_checks`，记录：

- 悬停配平；
- `betaM=0, V=20 m/s` 前飞配平；
- 现有总测试结果。

不得运行整个 `run_demo` 的六工况循环作为第一步。

### Stage 1 - 静态和定义检查

检查：

- 未知量/残差数量不等时明确失败；
- 重复变量名、未知变量名、非法固定状态/控制明确失败；
- 三种定义生成的 9 状态和 7 控制向量尺寸正确；
- conversion 默认定义明确报告缺少 allocation constraint。

### Stage 2 - Legacy 行为保持

至少检查：

- 精确悬停；
- `V=20 m/s, betaM=0, gamma=0`；
- legacy 核心与修改前 `trim_symmetric` 的状态、控制、残差和收敛标志保持一致。

建议行为保持容差：

```text
state/control absolute difference <= 1e-10
residual norm difference <= 1e-10
```

若因内部求解顺序产生可解释的浮点差异，必须报告最坏误差，不得放宽到掩盖分支变化的程度。

### Stage 3 - 新端点模式

单一代表工况：

- helicopter definition：`V=20 m/s, betaM=0, gamma=0`；
- airplane definition：优先尝试当前 demo 的 `V=100 m/s, betaM=pi/2, gamma=0`。

验收要求：

- `udot, wdot, qdot` 达到当前 `P.trim.residualTolerance`；
- 全部状态导数有限、实数；
- 未知量和 applied controls 不越限、不贴限；
- airplane definition 的 `cyclicLong` 精确固定为零；
- helicopter definition 的 `elevator` 精确固定为零。

若飞机端点在不改物理参数的前提下无法收敛，应停止并报告：

- 最佳残差；
- 哪个控制或姿态达到限制；
- 是否为结构/控制权不足；
- 不得调参或切回周期变距冒充飞机模式成功。

### Stage 4 - 回归

仅在聚焦检查通过后运行：

```matlab
run_all_checks
```

预计本任务运行量：

- 旧基线 2 个代表配平；
- 新框架 2 个端点配平；
- 少量非法定义静态测试；
- 1 次总回归。

预计墙钟时间约 2-6 分钟。超过该范围前先停止并报告，不进行工况扫描。

## 11. 完成标准

本任务完成时必须同时满足：

1. 现有 `trim_symmetric` 调用和 GUI 服务不被破坏；
2. legacy 悬停和 20 m/s 前飞行为保持；
3. 通用核心能显式描述 unknowns、fixed values 和 residuals；
4. helicopter 与 airplane 端点定义各自使用正确的执行器集合；
5. conversion 默认模式不会产生欠定伪解；
6. 没有引入混控、飞控或真实型号参数；
7. 聚焦测试和 `run_all_checks` 通过；
8. 文档明确区分 legacy closure、endpoint mode trim 和未来 conversion allocation。
