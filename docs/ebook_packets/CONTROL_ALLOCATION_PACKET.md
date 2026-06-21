# 开环俯仰执行器分配方法包

## 1. 任务定位

本方法包只服务于优先级第 3 项：在已经合并的通用模式配平核心上，为转换模式增加一条明确的开环俯仰执行器分配约束。

当前项目继续保持为开环飞行器本体模型。本任务中的“分配”只表示纵向周期变距与升降舵之间的机械/开环混合关系，用于关闭转换配平的欠定自由度。它不包含姿态反馈、角速度反馈、SCAS、自动驾驶、飞行员模型或控制律设计。

本任务与后续工作的边界：

- 本任务：一个概念性的连续开环分配函数、一条显式代数残差、转换模式配平定义和有限代表工况；
- 下一任务：配平 Jacobian、秩、奇异值、条件数、限幅裕度和完整导数可信度诊断；
- 后续真实型号工作：真实传动比、真实操纵杆—舵面增益、真实 XV-15 混控律和飞行试验验证。

## 2. 电子书依据

参考书：《直升机和倾转旋翼飞行器飞行仿真引论》。PDF 为扫描件，PDF 页码与书内页码不同。

本方法包只使用以下有限范围：

- PDF 296-301；书内页 271-276；第 15.2.2-15.2.3 节；
- 图 15-2：倾转旋翼飞行器纵向输入混合示意；
- 图 15-5：纵向周期变距输入与升降舵输入的开环混合；
- 表 15-1：纵向周期变距输出可采用线性、半线性或余弦型增加函数；
- 表 15-2：升降舵输出可采用线性、半线性或余弦型减小函数。

电子书将主轴角定义为：

```text
90 deg = 直升机模式
0 deg  = 飞机模式
```

当前代码定义为：

```text
betaM = 0       = 直升机模式
betaM = pi/2    = 飞机模式
```

两者换算为：

```math
\theta_{mast}=\frac{\pi}{2}-\beta_M
```

电子书只给出通用示例函数，不提供当前目标构型的真实传动比或型号混控数据。因此本方法包只能建立 `ASSUMED_CONCEPT` 分配，不能声称为 XV-15 实际混控律。

## 3. 方案选择

电子书给出了线性、半线性和余弦型示例。本项目首版只实现余弦型概念方案，因为它：

- 在两个端点连续；
- 在两个端点的一阶导数为零；
- 不产生硬切换；
- 满足两个通道权重之和恒为 1；
- 不需要额外真实型号参数。

本任务不同时实现线性和半线性可选项，避免扩大接口和测试范围。后续真实混控数据到位时，可替换该策略。

## 4. 当前代码角度下的分配权重

电子书主轴角下的余弦示例为：

```math
g_{cyc}(\theta_{mast})=\frac{1-\cos(2\theta_{mast})}{2}
```

```math
g_{ele}(\theta_{mast})=\frac{1+\cos(2\theta_{mast})}{2}
```

换算到当前代码的 `betaM` 后：

```math
g_{cyc}(\beta_M)=\frac{1+\cos(2\beta_M)}{2}=\cos^2\beta_M
```

```math
g_{ele}(\beta_M)=\frac{1-\cos(2\beta_M)}{2}=\sin^2\beta_M
```

必须满足：

```math
g_{cyc}+g_{ele}=1
```

```text
betaM = 0       -> g_cyc = 1,   g_ele = 0
betaM = pi/4    -> g_cyc = 0.5, g_ele = 0.5
betaM = pi/2    -> g_cyc = 0,   g_ele = 1
```

函数仅在 `0 <= betaM <= pi/2` 内有效。超出范围必须明确报错，不得静默外推或钳位。

## 5. 当前模型的控制方向约定

当前模型内部：

- `rotor_model_bemt` 明确规定正的共同纵向周期变距使两侧盘面法向朝 `+eD` 倾斜；
- `horizontal_tail_model` 中正升降舵通过正 `CLelevator` 增加尾翼升力，同时 `Cmelevator` 为负；
- 在当前 `x前、y右、z下` 体轴和当前部件位置下，这两个正控制命令均对应同一纵向俯仰控制方向，即当前代码中的正命令方向可以直接视为同一开环通道方向。

因此首版分配关系使用相同命令符号，不增加隐藏的负号：

```text
s_cyclic = +1
s_elevator = +1
```

这只是当前程序的内部命令约定，不代表真实飞机操纵杆或舵面铰链的正方向。

实现前必须用两个已经验证的端点配平点做一次轻量符号审计：

- 直升机端对 `cyclicLong` 施加一个小正扰动；
- 飞机端对 `elevator` 施加一个小正扰动；
- 记录两者对 `qdot` 的符号。

该审计只用于证明当前代码方向一致，不得把导数大小用作调参、权重或真实控制增益。若符号与上述结论不一致，停止并报告，禁止为了收敛随意翻转符号。

## 6. 归一化尺度

纵向周期变距和升降舵的允许行程不同。为了让分配表示“相同的归一化操纵通道份额”，使用现有控制限幅的正幅值作为归一化参考：

```math
C_{ref}=\max\left(|P.control.cyclicLim|\right)=35\ deg
```

```math
E_{ref}=\max\left(|P.control.elevatorLim|\right)=40\ deg
```

定义：

```math
\eta_c=\frac{cyclicLong}{C_{ref}}
```

```math
\eta_e=\frac{elevator}{E_{ref}}
```

这些参考量来自当前已有控制限幅，只用于无量纲归一化。它们不是传动比、真实操纵增益或新的物理参数。不得修改 `params_nominal.m` 中的限幅。

## 7. 显式分配约束

若存在一个概念性的统一纵向开环命令 `eta`，则：

```math
\eta_c=g_{cyc}(\beta_M)\eta
```

```math
\eta_e=g_{ele}(\beta_M)\eta
```

消去 `eta` 后，得到转换配平的第四条无量纲残差：

```math
r_{alloc}=g_{ele}(\beta_M)\eta_c-g_{cyc}(\beta_M)\eta_e
```

即：

```math
r_{alloc}=g_{ele}(\beta_M)\frac{cyclicLong}{C_{ref}}
-g_{cyc}(\beta_M)\frac{elevator}{E_{ref}}=0
```

端点性质：

- `betaM=0`：`r_alloc=-elevator/E_ref`，强制 `elevator=0`；
- `betaM=pi/2`：`r_alloc=cyclicLong/C_ref`，强制 `cyclicLong=0`；
- `betaM=pi/4`：`cyclicLong/C_ref=elevator/E_ref`。

本约束关闭四个未知量与三个平衡方程之间的欠定自由度。

## 8. 转换配平定义

新增显式模式：

```text
conversion_longitudinal
```

未知量：

```text
theta
collective
cyclicLong
elevator
```

残差：

```text
udot
wdot
qdot
pitchAllocation
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

不得根据 `betaM` 自动切换到直升机或飞机定义。调用者必须显式请求 `conversion_longitudinal`。

不得把 `pitchAllocation` 伪装成状态导数，也不得用隐藏惩罚项代替显式残差。

## 9. 对 `trim_general` 的最小扩展

推荐最小接口：

```matlab
definition.residualNames = {'udot';'wdot';'qdot';'pitchAllocation'};
definition.allocation.type = 'ebook_cosine_concept';
definition.allocation.cyclicReference = max(abs(P.control.cyclicLim));
definition.allocation.elevatorReference = max(abs(P.control.elevatorLim));
definition.allocation.tolerance = 1e-8;
definition.allocation.classification = 'ASSUMED_CONCEPT';
```

允许采用语义等价的字段命名，但必须满足：

- 分配类型显式；
- 参考尺度显式；
- 分类显式；
- `pitchAllocation` 可在报告中单独读取；
- 未提供 allocation 配置时，四未知量/三动态残差仍必须抛出 `trim_general:AllocationConstraintRequired`。

`trim_general` 的残差评估应区分：

- 动态残差：从 `tiltrotor_eom` 获取；
- 代数残差：由显式 allocation 配置计算。

`pitchAllocation` 的残差尺度为 1，因为它已经无量纲。

## 10. 收敛与报告

新的转换模式报告至少增加：

```text
report.allocation.type
report.allocation.classification
report.allocation.gCyclic
report.allocation.gElevator
report.allocation.cyclicReference
report.allocation.elevatorReference
report.allocation.normalizedCyclic
report.allocation.normalizedElevator
report.allocation.residual
report.allocation.tolerance
report.dynamicResidual
report.dynamicResidualNorm
report.scaledResidualNorm
```

转换模式收敛必须同时满足：

```text
solverConverged == true
dynamicResidualNorm < P.trim.residualTolerance
abs(allocationResidual) <= allocationTolerance
fullStateDerivative finite and real
no active or violated limit
```

不得只依据包含不同量纲项的原始总残差范数判定成功。

现有 legacy、helicopter 和 airplane 模式的结果、报告语义和收敛判断不得改变。

## 11. 初值投影

为了避免将不满足分配关系的旧初值直接交给四变量求解器，可将任意初始 `cyclicLong_0`、`elevator_0` 投影到分配流形。

先定义：

```math
\eta_{c0}=cyclicLong_0/C_{ref}
```

```math
\eta_{e0}=elevator_0/E_{ref}
```

最小二乘公共通道初值：

```math
\eta_0=\frac{g_{cyc}\eta_{c0}+g_{ele}\eta_{e0}}
{g_{cyc}^2+g_{ele}^2}
```

再设置：

```math
cyclicLong_0=g_{cyc}\eta_0 C_{ref}
```

```math
elevator_0=g_{ele}\eta_0 E_{ref}
```

该投影只用于数值初值，不改变目标方程，不得作为附加物理模型或隐藏约束。

## 12. 代表工况与运行预算

### Stage 0：基线与方向审计

只运行：

- 已合并框架的 `check_trim_mode_framework`；
- 直升机端 `V=20 m/s, betaM=0`；
- 飞机端 `V=100 m/s, betaM=pi/2`；
- 两个端点各一次小控制扰动，用于核对 `qdot` 符号。

若方向不一致，停止并报告。

### Stage 1：静态函数检查

不调用完整模型，检查：

- `betaM=[0,15,30,45,60,75,90] deg` 的权重；
- 权重有限、实数、位于 `[0,1]`；
- `g_cyc+g_ele=1`；
- `g_cyc` 单调不增，`g_ele` 单调不减；
- 端点准确；
- `betaM` 越界明确报错；
- allocation 配置缺失、尺度非法、类型非法时明确报错。

### Stage 2：端点等价

使用 `conversion_longitudinal`：

- `V=20 m/s, betaM=0` 应与 `helicopter_longitudinal` 端点一致；
- `V=100 m/s, betaM=pi/2` 应与 `airplane_longitudinal` 端点一致。

目标：

```text
state/control absolute difference <= 1e-8
allocation residual <= 1e-10
```

若求解顺序造成更小范围的浮点差异，报告实际最坏值；不得放宽到掩盖不同解支。

### Stage 3：单一转换代表点

只运行：

```text
V=35 m/s
betaM=pi/4
gamma=0
```

该工况对应当前 `run_demo` 中已有的 45 deg 概念转换点，但本任务使用新的四变量分配闭合。

验收：

- 三个动态残差满足当前配平容差；
- allocation residual 满足其独立容差；
- 控制有限、实数、不贴限、不越限；
- `cyclicLong/C_ref` 与 `elevator/E_ref` 在 45 deg 下相等；
- 不修改参数来获得收敛。

若不能收敛，停止并报告最佳动态残差、allocation residual、控制限幅和失败原因。不得增加额外扫描或调参。

### Stage 4：回归

仅在聚焦检查通过后运行：

```matlab
run_all_checks
```

预计完整工作包墙钟时间约 2-6 分钟。不得运行速度精扫、正反扫、大范围倾转角扫描、密集多初值或完整 Jacobian 图。

已知 MATLAB R2021a 退出阶段 `mwboost::archive::archive_exception` 继续与测试主体结果分开记录。

## 13. 建议文件范围

允许修改：

```text
CODEX_TASK.md
analysis/trim_general.m
analysis/make_trim_definition.m
analysis/pitch_allocation_schedule.m       # 推荐新增
tests/check_pitch_allocation.m
tests/run_all_checks.m                     # 仅注册新测试
docs/PITCH_ALLOCATION_AUDIT.md
```

原则上不修改 `trim_symmetric.m`。若确需修改，必须证明 legacy 输出仍精确不变并说明原因。

不得修改：

```text
params_nominal.m
GUI
services
model/*
linearize_numeric.m
电子书方法包
```

## 14. 禁止事项

本任务不得：

- 把概念余弦分配称为 XV-15 真实混控；
- 加入真实或猜测的机械传动比；
- 加入 SCAS、姿态反馈、角速度反馈、自动驾驶或飞行员模型；
- 用控制有效性导数大小调整分配权重；
- 为了收敛修改气动、旋翼、质量、惯量、限幅或求解器容差；
- 根据 `betaM` 隐式选择模式；
- 用惩罚项替代第四条显式残差；
- 执行大范围扫描；
- 修改已经通过的 legacy 和端点定义。

## 15. 完成标准

本任务完成时必须同时满足：

1. 余弦权重和角度换算实现正确；
2. `conversion_longitudinal` 明确包含四个未知量和四个残差；
3. allocation residual 是独立、可报告的无量纲代数残差；
4. 两个端点退化到已验证的直升机/飞机定义；
5. 45 deg 单一代表工况通过，或限制被如实记录且未调参；
6. legacy、helicopter 和 airplane 模式结果不变；
7. 没有引入飞控、真实混控参数、GUI、模型方程或线性化改动；
8. 聚焦测试和 `run_all_checks` 通过；
9. 文档明确标记该方案为 `ASSUMED_CONCEPT`。
