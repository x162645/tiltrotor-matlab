# XV-15 V1 原始金属桨悬停验证实例与映射诊断

## 1. 任务边界

本阶段不修改通用低阶倾转旋翼模型的生产物理函数，也不把 `params_nominal.m` 改造成 XV-15 参数集。本阶段只构造一个独立的 **V1 validation instance**，用于回答：

> 在保持当前低阶模型形式不变的情况下，XV-15 原始金属桨悬停试验构型和输入应怎样映射到程序实际读取的参数字段？

因此研究对象仍为 generic low-order model。XV-15 参数来源约束只在 V1 validation instance 中生效。

本阶段也不读取、不拟合 NASA TM-86833 的最终悬停性能曲线。TM-86833 继续保留为参数包冻结后的 hold-out external validation 数据。

---

## 2. 代码入口

新增：

```matlab
[Pv1, mapping] = build_xv15_v1_hover_validation_instance( ...
    Pbase, testPoint, sourceData);
```

其中：

- `Pbase` 为现有 generic 参数集；
- `testPoint` 只承载对应试验点的输入/环境条件，例如 `rpm`、`rho`、`theta75`；
- `sourceData` 承载需要由真实分布降阶或重建的资料，例如径向 chord/twist、截面气动和桨叶质量一阶矩；
- `Pv1` 仍满足现有 production low-order model 的字段结构；
- `mapping` 保存来源、降阶方法、误差、阻塞项和 hold-out readiness。

映射诊断入口：

```matlab
results = run_xv15_v1_mapping_diagnostics(testPoint, sourceData);
```

该函数只输出映射误差与 readiness，不执行 TM-86833 性能相关性比较。

---

## 3. 当前直接采用的公开事实

### 3.1 `rotor.rootCut`

- 来源：NASA CR-2016-219086，Table 2，XV-15 rotor characteristics；
- 原始量：root cutout = `0.0875 r/R`；
- 代码字段：`P.rotor.rootCut`；
- 单位：无量纲；
- 转换：identity；
- 适用对象：XV-15 原始/基准旋翼公开构型；
- 处理：`DIRECT_CONFIGURATION`。

程序中 `rootCut` 是叶素气动积分起点，因此该字段语义与公开 root-cutout ratio 同构。

### 3.2 `rotor.R` 与 `rotor.Nb`

- 来源：XV-15 公开旋翼资料，PR #53/#64 已登记；NASA CR-2017-219486 Appendix A 汇编亦用于交叉核对；
- `R = 3.81 m`；
- `Nb = 3`；
- 代码字段：`P.rotor.R`、`P.rotor.Nb`；
- 处理：`DIRECT_CONFIGURATION`。

### 3.3 `rotor.Omega`

NASA CR-2017-219486 Appendix A Table A-1 汇编的参考转速包括 565 rpm（helicopter/hover）、534 rpm（conversion）和 458 rpm（airplane）。因此不应把 565 rpm 全局写入全包线 generic model。

V1 是单一悬停验证层，故本阶段按试验点处理：

```matlab
P.rotor.Omega = testPoint.rpm * 2*pi/60;
```

若调用者没有给出 `testPoint.rpm`，builder 可使用 565 rpm 作为 **reference hover default** 生成映射诊断，但会把 `rpmExplicit=false`，并禁止进入 `readyForHoldout=true`。这一区分防止把参考构型转速误称为具体 TM-86833 数据点转速。

### 3.4 `rotor.Ib`

- 来源：NASA CR-2017-219486 Appendix A Table A-1；
- 原始量：105 slug ft²，per blade flapping inertia；
- 换算：`105 * 1.3558179483314004 = 142.360884574797 kg m^2`；
- 代码字段：`P.rotor.Ib`。

但当前挥舞残差同时使用 `Ib` 和 `Sblade`：前者进入惯性/离心恢复项，后者进入重力矩。因此在最终 V1 validation pack 中，**不允许只覆盖 `Ib` 而保留 generic `Sblade`**。

builder 仅保留公开 `Ib` 证据；只有调用者同时提供了具有明确来源的 `Sblade`/blade first mass moment 时，才把两者作为耦合组写入 `Pv1`。

---

## 4. `c(r) -> P.rotor.chord`：必须考虑程序实际如何使用 chord

当前 production BEMT 对所有叶素使用同一个：

```matlab
P.rotor.chord
```

但该标量并不只代表几何面积。在程序中：

\[
dL,\ dD \propto W^2 c\,dr,
\]

悬停时主导切向速度近似：

\[
W\approx \Omega r.
\]

因此，同一个 `chord` 对不同输出具有不同径向权重：

- 几何/桨盘有效面积：近似权重 `1`；
- 悬停局部升阻力、因而推力的一阶近似：近似权重 `r^2`；
- `dQ = dH * r`，因此扭矩/型阻功率贡献进一步近似 `r^3` 权重。

这意味着**不存在一个完全中性的常弦长，可以同时严格保持真实 `c(r)` 的面积、推力贡献和扭矩贡献**。如果直接只选“面积保持”而不说明这一点，会把低阶模型形式误差隐藏进参数映射。

因此 builder 对 piecewise-linear `c(r)` 精确积分，并同时生成三个 geometry-only 候选：

\[
c_{eq}^{(p)}=
\frac{\int_{r_0}^{R}c(r)(r/R)^p\,dr}
{\int_{r_0}^{R}(r/R)^p\,dr},
\]

其中：

- `p=0`：`AREA_PRESERVING`；
- `p=2`：`HOVER_THRUST_R2`；
- `p=3`：`HOVER_TORQUE_R3`。

当前默认 chord source reconstruction 使用 PR #64 已登记的公开金属桨几何摘要：

- `r/R = 0.0875`：约 17 in；
- `r/R = 0.25`：14 in；
- `r/R = 1.0`：14 in；
- 0.0875R 至 0.25R 之间按线性过渡处理。

由该三点 piecewise-linear 重建得到：

| reduction | equivalent chord |
|---|---:|
| `AREA_PRESERVING` | 0.362384931507 m |
| `HOVER_THRUST_R2` | 0.356000280950 m |
| `HOVER_TORQUE_R3` | 0.355686643884 m |

面积候选与 `r^3` 候选相差约 1.85%。这**不是统计置信区间，也不是最终模型误差界**，只是证明 constant-chord reduction 对目标量存在约 2% 量级的几何映射选择差异。

调用者通过：

```matlab
sourceData.chord.reductionPolicy = 'AREA_PRESERVING';
% 或 'HOVER_THRUST_R2'
% 或 'HOVER_TORQUE_R3'
```

显式冻结最终使用的 `P.rotor.chord`。

如果没有显式 policy，builder 为了能够运行 mapping diagnostics，会暂用 `AREA_PRESERVING` 作为诊断展示值，但：

```text
mapping.chord.policyExplicit = false
CHORD_REDUCTION_POLICY_NOT_FROZEN
```

并禁止 `readyForHoldout=true`。

这里的三种数值都属于 `DERIVED / EQUIVALENT_REDUCTION`，不是 NASA 直接给出的“XV-15 常弦长”。

当前分段曲线同样只是由已登记公开几何摘要重建的低阶输入。若后续对原始 chord 图进行高质量数字化，应把数字化站点作为显式 `sourceData.chord` 输入，并重新生成三种候选和 sensitivity；不得将当前三点重建误写为完整原始测量分布。

---

## 5. `theta(r) -> twistTip_eq`：以 0.75R 为锚点降阶

当前 production BEMT 的扭转形式是：

\[
\theta_{twist}(r)=twistTip\frac{r-r_0}{R-r_0}.
\]

而 V1 试验 collective 需要按 0.75R 桨距理解。因此公开的“总扭转约 -45°”既不能直接等同于 `P.rotor.twistTip`，也不应先做一个自由截距线性拟合、再用另一个独立 0.75R adapter 改变绝对桨距基准，否则拟合残差不一定等于最终模型真正使用的 shape error。

V1 builder 要求调用者显式提供径向扭转站点：

```matlab
sourceData.twist.rR
sourceData.twist.theta_deg   % 或 theta_rad
sourceData.twist.weights     % 可选
```

然后先取得 source profile 在 0.75R 的桨距 `theta75_source`，再拟合相对形状：

\[
\theta_{source}(r)-\theta_{75,source}
\approx
 twistTip_{eq}\left[
\frac{r-r_0}{R-r_0}
-
\frac{0.75R-r_0}{R-r_0}
\right].
\]

这样：

- `twistTip_eq` 直接对应 production field 的 slope；
- 拟合对 source profile 的任意整体 pitch offset 不敏感；
- reported residual 就是最终 `theta75`-anchored model profile 的 shape reduction error。

必须报告：

- ordinary RMS shape residual；
- weighted RMS shape residual；
- max absolute shape residual；
- 是否覆盖 rootCut-to-tip；
- source profile 的 `theta75_source`。

如果没有显式径向扭转资料，builder 保留 generic `P.rotor.twistTip` 不变，并产生：

`RADIAL_TWIST_RECONSTRUCTION_REQUIRED`

阻塞项。此时不得宣称 V1 参数包已冻结。

---

## 6. `theta_0.75 -> collective_model`

当前代码中的 collective 直接形成：

\[
\theta_{blade}=collective+twist(r)+cyclic.
\]

若试验 collective 定义为 0.75R 桨距 `theta75`，把 `theta75` 直接赋给程序 `collective` 会产生定义偏差。

在 twist reduction 已确定时：

\[
collective_{model}
=\theta_{75,test}
-twistTip_{eq}\frac{0.75-r_0/R}{1-r_0/R}.
\]

builder 输出 `mapping.collective.modelCollective_rad`，而不改变现有 production control interface。

诊断还回代计算 `theta75Reconstructed` 和 reconstruction error，用来证明输入定义转换自身没有数值误差。

---

## 7. 截面气动只按程序实际四参数重建

当前 rotor BEMT 使用：

\[
C_L=C_{L,max}\tanh\left(\frac{a\alpha}{C_{L,max}}\right),
\]

\[
C_D=C_{D0}+k_D C_L^2.
\]

因此当前低阶模型真正需要的不是先建立一整套高阶翼型数据库，而是针对当前模型形式明确得到：

- `rotor.liftSlope`；
- `rotor.CLmax`；
- `rotor.CD0`；
- `rotor.kCD`。

V1 builder 只有在 `sourceData.sectionAero` 同时提供这四个重建结果时才应用；缺任一项均保留 generic 值并标记：

`SECTION_AERO_RECONSTRUCTION_REQUIRED`

后续可以从公开翼型/极曲线资料构造这四个等效量，也可以使用与 TM-86833 最终 hold-out 数据严格分离的 calibration dataset。不得根据最终 hold-out 曲线反调这四个参数。

---

## 8. V1 readiness gate

`mapping.readiness.readyForHoldout=true` 仅在以下条件全部满足时成立：

1. XV-15 direct geometry 已映射；
2. chord 三种 program-aware reduction 均可计算；
3. 最终 chord reduction policy 已显式冻结；
4. radial twist 已按 0.75R 参考降阶且覆盖 root-to-tip；
5. test-point RPM 明确；
6. test-point density 明确；
7. `theta75 -> collective_model` adapter 完成；
8. 四个截面气动低阶参数已独立重建；
9. `Ib/Sblade` 耦合质量属性已闭合。

缺失项会保存在 `mapping.blockingIssues`，而不是以 generic/placeholder 值静默通过。

需要特别区分：

- `readyForMappingDiagnostics`：只说明当前映射可被审计；
- `readyForHoldout`：才允许进入最终 TM-86833 独立外部验证。

`readyForHoldout` 本身也只表示**输入映射契约完整**，不表示外部验证已经通过。

---

## 9. 数值收敛、敏感性与参数冻结

V1 builder 完成并补齐所有阻塞项后，仍不能立刻把结果称为外部验证。应依次：

1. 对 `nRadial`、`nAzimuth`、诱导速度/挥舞求解容差做数值收敛检查；
2. 对三个 chord reduction candidate 做 sensitivity，报告 `CT/CQ` 对 policy 的响应；
3. 对 `twistTip_eq` 的 shape residual 和合理扰动范围做 sensitivity；
4. 固定 V1 parameter pack、chord policy、sourceData 版本与 commit SHA；
5. 固定所有允许的 calibration 数据及其与 hold-out 数据的隔离关系；
6. 之后才读取/运行 TM-86833 hold-out performance correlation；
7. 最后将误差归因到 mapping、section aero、model form 与 numerical error，而不是看到误差后直接调参。

只有在敏感性/误差归因表明 constant chord、linear twist 等低阶假设是主导且不可接受的误差来源时，才进入 radial geometry / higher-order model-form upgrade。

---

## 10. 当前人工复核项

在 V1 参数包冻结前仍需完成：

- 从原始公开资料重建/数字化完整 radial twist distribution；
- 对当前三点 chord reconstruction 与原始径向 chord 图进行人工复核/必要时重新数字化；
- 决定并冻结 V1 constant-chord reduction policy，同时保留另外两种 candidate 作为 mapping sensitivity；
- 核对 TM-86833 每个最终 test point 的 RPM、density/atmospheric correction 和 `theta75` 定义；
- 重建当前四参数形式所需的 section aero equivalent；
- 获取或推导与 `Ib=105 slug ft^2` 同一金属桨构型一致的 blade first mass moment / `Sblade`；
- 明确上述重建所用的数据集与最终 TM-86833 hold-out 点之间的隔离关系。

这些项目在完成之前均不得用“合理值”补齐，也不得把 V1 instance 称为已完成 XV-15 验模。

---

## 11. 测试声明

新增 focused software-contract test：

```matlab
startup;
summary = check_xv15_v1_validation_instance;
assert(summary.allPassed);
```

该测试包含 synthetic linear twist、synthetic section-aero 和 synthetic `Sblade`，目的仅是验证 mapping algebra、readiness gate 和字段写入逻辑。**synthetic contract 通过也不构成 XV-15 物理验证。**

当前通过 GitHub connector 提交代码的环境无法执行仓库本机 `F:\matlab\R2021a\bin\matlab.exe`，因此本分支只能提供测试入口，不能声称该 MATLAB test 或 full regression 已实际通过。应在仓库规定的本地 MATLAB R2021a 环境运行后再记录真实结果。
