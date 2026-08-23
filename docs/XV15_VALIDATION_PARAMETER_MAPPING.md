# XV-15 验证参数映射：从程序实际使用出发

## 1. 研究定位

本项目的正式研究对象仍然是**通用低阶、部件级、非线性倾转旋翼飞行动力学模型**。`params_nominal.m` 中的数值用于构造自洽 generic configuration；通用模型本身不要求每一个数值参数均可追溯到 XV-15。

XV-15 参数来源只在建立 **validation instance** 时成为约束。验证逻辑应写成

\[
y_{model}=\mathcal{M}(P_{low\text{-}order}^{XV15},u_{test}),\qquad
P_{low\text{-}order}^{XV15}=\mathcal{T}(P_{XV15,test}),
\]

其中 `M` 是冻结的低阶模型形式，`T` 是“真实试验构型 -> 当前程序参数”的透明映射。只有在映射无法维持试验定义、且该差异对验证结果不可忽略时，才考虑升级模型形式。

因此，本轮不采用“XV-15 有什么参数就向模型添加什么”的路线，而是逐项检查**程序真正读取什么、以什么物理意义读取、在什么验证阶段需要处理**。

## 2. 程序实际使用带来的关键修正

### 2.1 `rotor.chord` 应优先考虑等效映射，而不是直接升级为径向表

当前 `rotor_model_bemt.m` 在每个叶素上使用同一个 `P.rotor.chord`：

\[
dL=\tfrac12\rho W^2 c_{model} C_L\,dr,\qquad
dD=\tfrac12\rho W^2 c_{model} C_D\,dr.
\]

因此 XV-15 的真实 `c(r)` 首先应映射为保持桨叶平面面积的等效常弦长：

\[
c_{eq}=\frac{1}{R-r_0}\int_{r_0}^{R} c(r)\,dr.
\]

按 PR #64 已登记的公开几何（`r0/R=0.0875`，根部约 17 in，至 `0.25R` 过渡为 14 in，外段保持 14 in）作分段线性面积等效，可得到约

\[
c_{eq}\approx0.3624\;m.
\]

该值是**从公开几何推导出的低阶等效量**，不是 XV-15 文献直接给出的“常弦长”。只有后续敏感性/验证表明常弦长近似构成主要误差源，才有充分理由升级为 `c(r)` 接口。

### 2.2 `rotor.twistTip` 不能直接装入公开的总扭转

当前程序使用

\[
\theta(r)=\theta_{model}+\theta_{twist}\frac{r-r_0}{R-r_0},
\]

其中 `P.rotor.twistTip` 是**从积分根部到桨尖的线性扭转量**。公开 XV-15 总扭转及其径向分布不能直接等同于该字段。

处理顺序应是：

1. 从公开径向扭转数据重建真实 `theta_XV15(r)`；
2. 选定低阶等效准则（例如加权最小二乘、75%R 局部斜率/载荷权重保持）；
3. 得到 `twistTip_eq`；
4. 单独记录等效误差并做敏感性分析。

这属于 `EQUIVALENT_REDUCTION`，而不是 `DIRECT_REPLACE`。

### 2.3 collective 定义必须通过验证适配器转换

当前 BEMT 直接使用

```matlab
thetaBlade = rotorCtrl.collective + twist + theta1s*sin(psi);
```

因此 `rotorCtrl.collective` 是当前低阶线性扭转律的基准桨距。若 NASA 试验的 collective 定义为 `theta_0.75R`，则试验输入不能直接赋值给程序 collective。对于已确定的等效扭转，应使用

\[
\theta_{model}=\theta_{0.75,test}-\theta_{twist,eq}(0.75R).
\]

该转换属于**验证输入同构问题**，不要求改变通用模型控制接口。

### 2.4 `rotor.Omega` 在单工况验证中可直接赋值，不需要先实现完整 RPM schedule

程序实际读取的是一个标量 `P.rotor.Omega`。对 TM-86833 悬停验证，验证实例只需把它设置为对应试验转速即可。完整的 `Omega(beta_M)` 只有在后续转换段/整机多构型验证时才成为接口问题。

因此：

- hover validation：`TEST_POINT_DIRECT`；
- conversion-envelope validation：需要构型调度数据或明确的模型假设；
- 不应为了单一悬停验证先引入无公开依据的全包线插值律。

### 2.5 `rotor.Ib` 不能孤立视为“安全替换”

这是本轮最重要的程序级发现之一。

当前挥舞残差同时使用：

\[
I_b\ddot\beta+I_b\Omega^2\beta
\]

和

\[
S_{blade}\,g(\beta,\psi).
\]

在 `params_nominal.m` 中，`Ib` 与 `Sblade` 都由假设的均匀桨叶质量分布导出。PR #64 V2 虽然把公开 XV-15 `Ib` 直接覆盖为 105 slug ft² 的换算值，但 `Sblade` 仍保留 generic 均匀质量分布结果。

所以：

> `Ib` 的字段语义可以与公开量同构，但**验证参数集的物理闭合不是单字段问题**。

在 XV-15 rotor validation instance 中，`Ib` 应与 `Sblade`、质量分布/一阶质量矩一起处理。若无法公开重建 `Sblade`，必须：

- 将其列为 flapping 子模型的不确定项并做敏感性；或
- 在严格限定的验证任务中证明结果对该项不敏感；
- 不能仅凭 `Ib` 有直接来源就把整套旋翼称为同构参数化。

PR #64 的 V2 overlay 因而应理解为**公开证据 overlay**，不是可以直接拿来做最终 XV-15 验模的 validation pack。

### 2.6 `mass.m` 在 rotor hover 与整机验证中的意义不同

程序在 `rotor_model_bemt.m` 中用 `P.mass.m` 构造诱导速度迭代的初值：

\[
v_{i,0}=\sqrt{\frac{mg/2}{2\rho A}},
\]

而收敛后的诱导速度由旋翼推力/动量闭合重新决定。因此在**孤立 rotor hover correlation** 中，整机质量不是旋翼试验的直接物理输入，主要影响求解初值；只要证明收敛结果对初值无关，就不应为了旋翼验模强行追溯/替换整机质量。

但在整机配平、运动方程和动态验证中，`mass.m`、`I0`、CG 及短舱质量/惯量变化又是核心验证构型参数。因此参数处理必须按验证阶段分类，不能建立一个“所有 XV-15 参数一次性覆盖”的万能 overlay。

## 3. 参数处理类别

本轮采用以下处理类别：

- `TEST_CONDITION_DIRECT`：试验工况直接给定，如 hover RPM、密度；
- `DIRECT_CONFIGURATION`：当前字段与真实构型量语义同构，如 R、Nb、rootCut；
- `EQUIVALENT_REDUCTION`：真实对象更复杂，但当前低阶模型可通过透明的等效规则映射，如 radial chord -> constant chord；
- `AERO_RECONSTRUCTION`：需要由公开翼型/气动数据重建当前低阶系数，如 rotor liftSlope/CD0/kCD；
- `COUPLED_RECONSTRUCTION_REQUIRED`：单字段可知，但必须与其他程序字段共同保持物理闭合，如 Ib/Sblade；
- `CALIBRATION_ONLY_WITH_SEPARATE_DATA`：无法直接重建的等效干扰/控制效率参数，只允许用与最终验证集分离的数据辨识；
- `MODEL_FORM_PARAMETER`：属于低阶模型自身的过渡/封闭假设，不应伪装成 XV-15 飞机参数；
- `NUMERICAL_PARAMETER`：网格、收敛阈值、差分步长等，通过数值收敛验证，不需要 XV-15 来源；
- `STAGE_IRRELEVANT`：在当前验证层级不参与目标量，无需追溯；
- `MODEL_FORM_UPGRADE_ONLY_IF_NEEDED`：先做等效/敏感性，只有证据表明当前简化主导误差才升级模型形式。

## 4. 建议的验证层级

### V1：原始金属桨稳态悬停性能

目标量：`CT/CQ/FM` 或等价 thrust/torque 曲线。

优先处理：

- `env.rho`：试验条件；
- `rotor.R/Nb/rootCut/Omega`：直接构型/工况；
- `rotor.chord`：面积保持的等效常弦长；
- `rotor.twistTip`：由公开径向扭转重建等效线性扭转；
- collective：`theta75 -> model collective` 转换；
- `liftSlope/CLmax/CD0/kCD`：由公开 section aero 重建，或在明确分离的 calibration dataset 上辨识；
- `Ib/Sblade`：保持挥舞子模型闭合并做敏感性。

无需为了 V1 处理：整机 wing/fuselage/tail、I0/KI、控制面限制、完整 RPM schedule。

### V2：前飞 rotor / rotor-wing interaction

在 V1 基础上增加：

- cyclic 定义与试验输入映射；
- `pivot/RH_hub` 及局部速度几何（若目标量受其影响）；
- NUAA Eq.12/17 当前低阶 inflow/interference 模型的模型形式不确定性；
- wing slipstream 参数只允许采用独立数据重建或校准。

### V3：整机 trim / static aerodynamics

此时才需要：

- aircraft mass/CG；
- wing/fuselage/tail geometry；
- 将 GTRS/风洞多维表**降阶为当前程序系数形式**，而不是任取表中一点替换 `CLalpha/CD0/...`；
- control definition/limits；
- 短舱角对应的验证工况 RPM。

### V4：flight-ID dynamic validation

进一步需要：

- `I0`、惯量积、CG；
- 控制效率/执行机构定义；
- 与 flight-test 状态点一致的质量、构型、速度和 RPM；
- 任何为配平或静态拟合使用的数据不得再次作为独立动态 validation 证据。

## 5. 下一步实施顺序

1. **不修改 generic `params_nominal.m`。**
2. 建立 stage-specific `XV15 validation instance builder`，而不是继续扩大通用 XV-15 overlay。
3. 首先实现 V1 所需的低阶映射：`c(r)->c_eq`、`theta(r)->twist_eq`、`theta75->collective_model`。
4. 审计/重建 `liftSlope/CLmax/CD0/kCD`；确定哪些可由公开 section polar 导出，哪些需要单独 calibration dataset。
5. 解决 `Ib/Sblade` 的耦合闭合或量化其敏感性。
6. 冻结 V1 参数后，TM-86833 作为 hold-out rotor validation，不再针对其曲线调参。
7. 只有当 V1 误差分解证明 constant chord / linear twist 等低阶形式构成主要不可接受误差时，才升级为 radial lookup。

## 6. 本轮边界

本轮是**验证参数映射设计与程序使用审计**，不是新的 XV-15 参数回填，也不是把 generic model 改成 XV-15 专用模型。生产物理函数和 `params_nominal.m` 均不修改。