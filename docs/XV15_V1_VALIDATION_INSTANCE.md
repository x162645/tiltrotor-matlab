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
- `sourceData` 承载需要由真实分布降阶或重建的资料，例如径向扭转、截面气动和桨叶质量一阶矩；
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

## 4. `c(r) -> c_eq`：保留低阶模型形式

当前 production BEMT 在所有叶素中使用单一：

```matlab
P.rotor.chord
```

因此 V1 首先不升级为径向弦长模型，而采用保持桨叶有效展向面积积分的常弦长等效：

\[
c_{eq}=\frac{1}{R-r_0}\int_{r_0}^{R}c(r)\,dr.
\]

当前默认 chord source reconstruction 使用 PR #64 已登记的公开金属桨几何摘要：

- `r/R = 0.0875`：约 17 in；
- `r/R = 0.25`：14 in；
- `r/R = 1.0`：14 in；
- 0.0875R 至 0.25R 之间按线性过渡处理。

由此：

\[
c_{eq}=14.2671232877\ \mathrm{in}
=0.362384931507\ \mathrm{m}.
\]

**该数值属于 `DERIVED / EQUIVALENT_REDUCTION`，不是 NASA 直接给出的“XV-15 常弦长”。**

诊断同时输出：

- source chord stations；
- `c_eq`；
- distributed area integral；
- equivalent area integral；
- relative area residual。

当前分段曲线是由已登记公开几何摘要重建的低阶输入。若后续对原始 chord 图进行高质量数字化，应把数字化站点作为显式 `sourceData.chord` 输入，并重新生成 `c_eq` 与映射误差；不得将当前三点重建误写为完整原始测量分布。

---

## 5. `theta(r) -> twistTip_eq`

当前 production BEMT 的扭转形式是：

\[
\theta_{twist}(r)=twistTip\frac{r-r_0}{R-r_0}.
\]

所以公开的“总扭转约 -45°”不能直接等同于 `P.rotor.twistTip`。V1 builder 要求调用者显式提供径向扭转站点：

```matlab
sourceData.twist.rR
sourceData.twist.theta_deg   % 或 theta_rad
sourceData.twist.weights     % 可选
```

然后拟合：

\[
\theta_{source}(r)\approx a_0+twistTip_{eq}\,x,
\qquad
x=\frac{r-r_0}{R-r_0}.
\]

其中：

- 截距 `a0` 不写入 `P.rotor.twistTip`；
- 斜率 `twistTip_eq` 才进入当前低阶模型；
- 绝对桨距参考由 collective adapter 处理。

必须报告：

- RMS fit residual；
- max absolute residual；
- 是否覆盖 rootCut-to-tip。

如果没有显式径向扭转资料，builder 保留 generic `P.rotor.twistTip` 不变，并产生：

`RADIAL_TWIST_RECONSTRUCTION_REQUIRED`

阻塞项。此时不得宣称 V1 参数包已冻结。

---

## 6. `theta_0.75 -> collective_model`

当前代码中的 collective 直接形成：

\[
\theta_{blade}=collective+twist(r)+cyclic.
\]

而公开旋翼试验常以 0.75R 桨距 `theta75` 定义 collective。若把 `theta75` 直接赋给程序 `collective`，会引入定义误差。

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

因此当前低阶模型真正需要的不是一整套高阶翼型数据库，而是：

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
2. chord 等效面积闭合；
3. radial twist 已降阶且覆盖 root-to-tip；
4. test-point RPM 明确；
5. test-point density 明确；
6. `theta75 -> collective_model` adapter 完成；
7. 四个截面气动低阶参数已独立重建；
8. `Ib/Sblade` 耦合质量属性已闭合。

缺失项会保存在 `mapping.blockingIssues`，而不是以 generic/placeholder 值静默通过。

需要特别区分：

- `readyForMappingDiagnostics`：只说明当前映射可被审计；
- `readyForHoldout`：才允许进入最终 TM-86833 独立外部验证。

---

## 9. 数值收敛与参数冻结

V1 builder 完成并补齐所有阻塞项后，仍不能立刻把结果称为外部验证。应依次：

1. 对 `nRadial`、`nAzimuth`、诱导速度/挥舞求解容差做数值收敛检查；
2. 对 `c_eq`、`twistTip_eq` 的降阶残差和敏感性做检查；
3. 固定 V1 参数包版本与 SHA；
4. 固定所有允许的 calibration 数据及其与 hold-out 数据的隔离关系；
5. 之后才读取/运行 TM-86833 hold-out performance correlation；
6. 最后将误差归因到 mapping、section aero、model form 与 numerical error，而不是看到误差后直接调参。

只有在敏感性/误差归因表明 constant chord、linear twist 等低阶假设是主导且不可接受的误差来源时，才进入 radial geometry / higher-order model-form upgrade。

---

## 10. 当前人工复核项

在 V1 参数包冻结前仍需完成：

- 从原始公开资料重建/数字化完整 radial twist distribution；
- 核对 TM-86833 每个最终 test point 的 RPM、density/atmospheric correction 和 `theta75` 定义；
- 重建当前四参数形式所需的 section aero equivalent；
- 获取或推导与 `Ib=105 slug ft^2` 同一金属桨构型一致的 blade first mass moment / `Sblade`；
- 明确上述重建所用的数据集与最终 TM-86833 hold-out 点之间的隔离关系。

这些项目在完成之前均不得用“合理值”补齐，也不得把 V1 instance 称为已完成 XV-15 验模。
