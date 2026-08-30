# M0/M1 全物理链可信度审核（2026-08-30）

## 0. 审核结论

本审核不把“MATLAB 能运行”“结果可复现”视为物理正确性的充分条件。每一层均按以下八项检查：

1. 原始来源是否存在且可定位；
2. 文献参数与代码变量的物理语义是否同一；
3. 单位与无量纲化是否正确；
4. 方程形式、符号和适用域是否与来源一致；
5. 代码是否忠实实现所声明的模型；
6. 新模型关闭时是否退化回前一级模型；
7. 数值求解是否闭合并对离散/迭代稳健；
8. 外部证据是否支持所作的科学声明。

审核后的总体判断：

- **M0 冻结基线：可保留。** 其身份是 generic low-order production core；NUAA 公开式的来源链和内部闭合已有审计，但 Eq. (12) 在严格悬停的局部一阶载荷上存在已知退化病态。该问题目前没有证据表明会显著改变积分 CT/CP，但必须正式 MATLAB 复核后才能用于悬停局部载荷/挥舞结论。
- **M1 第一阶段的“模型阶梯数值结果”可复现，但几何来源表述过强。** C81 四段边界有 NASA/TP-2004-212262 明确输入依据；当前 chord law 和 twist polynomial 则是来源约束的重构/拟合，不应无条件称为“真实径向几何”。
- **正式 M1-D（PR #71）可保留为来源约束的准静态扭转诊断。** GJ、XQC、KPL、C81 CM 的单位、语义、符号和刚性退化检查均较完整；结论仅能排除该公开参考结构包下的准静态扭转作为主要缺推力解释。
- **Corrigan 模型形式可保留，但 `n=1` 的来源身份必须纠正。** Koning 2016 支持公式和 `n=0.8–1.8` 的范围，并在 XV-15 相关中采用 `n=1.8`；当前代码把 `n=1` 称为 “literature default” 缺少充分依据。`n=1` 应重新分类为“预先声明、位于公开范围内的模型形式假设”，而不是唯一或默认文献参数。
- **M1-F Landgrebe/Biot-Savart 只能保留为模型形式诊断。** Landgrebe tip-vortex 轨迹公式和有限涡段 Biot-Savart 有来源，但当前把同一归一化 tip-vortex 收缩/轴向轨迹推广到全部内段尾涡，且用动量理论强制归一化盘面平均入流；它不是完整 Landgrebe inboard sheet，也不是自由尾迹自洽解。Stage-4 首轮固定窗口 0 个 M1-F1 点获得支持，因此不得把该层写成“已验证的非局部尾迹增强”。
- **WADC Stage 5 的 post-freeze 设计可保留，但应把结论限定为“冻结模型包的跨设施泛化”。** 数据选择、模型冻结和 identity check 做得正确；然而 M1 使用固定 `aSound=340 m/s`、generic `rho`，没有把 WADC 已报告 `Mtip` 作为逐点气动输入，因此它不是严格的试验环境同源复现。必须做 post-hoc 输入同源性敏感度审计，且不能用该敏感度反向改写原 holdout。
- **PR #72 为重复且科学证据等级低于 PR #71 的 M1-D，应标记为 superseded / invalid-for-scientific-evidence。** 其中 XQC 语义处理与正式 #71 不一致，且存在无独立来源的 Cm Mach multiplier，不得进入论文证据链。

因此，当前最重要的工作不是继续新增 M1 物理，而是完成以下四个阻断性复核：

1. `GEOMETRY_SOURCE_FIDELITY_AUDIT`：三套公开 chord 表达 + 直接 51 点 TWISTA 的无调参敏感度；
2. `HOVER_EQ12_LIMIT_AUDIT`：Eq. (12) 与均匀悬停入流的正式 MATLAB 对照，除 CT/CP 外同时比较 beta1c/beta1s、H-force 和一阶局部载荷；
3. `CORRIGAN_N1_PROVENANCE_CORRECTION`：纠正 n=1 证据身份，保留数值身份不变；
4. `WADC_INPUT_HOMOLOGY_SENSITIVITY`：用报告的 Vtip/Mtip 推导逐点声速进行 post-hoc 敏感度，并对未知密度做透明范围检查；不得重新定义 holdout 结果。

在这四项完成前，不建议继续建立新的 M1-G/M2 物理层。

---

## 1. 评级规则

| 评级 | 含义 |
|---|---|
| `PASS` | 来源、语义、单位、公式、代码和数值证据足以支持当前声明 |
| `PASS_WITH_CAVEAT` | 主体可保留，但声明必须限定或需要次级敏感度 |
| `MAJOR_REAUDIT` | 结果可运行，但关键来源/语义/适用域尚不足以支撑现有因果表述 |
| `DIAGNOSTIC_ONLY` | 只允许作为模型形式/失败证据，不允许晋升为主模型 |
| `INVALID_AS_EVIDENCE` | 不允许进入论文/正式证据链 |

---

## 2. M0 generic production low-order core

### 2.1 模型身份

冻结分支：`frozen/m0-xv15-hover-v1-20260828`  
冻结提交：`27f40883633ca14acc0e928649b62d7abb855491`

M0 的 generic 参数不要求逐项来自 XV-15；其审核重点是方程、内部一致性和 XV-15 validation-instance 输入映射，而不是把 generic core 改成 XV-15 专用模型。

### 2.2 NUAA 公开公式链

现有 `docs/NUAA_ROTOR_FORMULA_AUDIT.md` 已把公开式 (4)–(15) 分成 `EXACT_PUBLIC_FORMULA`、`STANDARD_CLOSURE`、`SHARED_CURRENT_PARAMETER`、`NUMERICAL_IMPLEMENTATION_CHOICE` 等类别。该分类思想正确。

关键项：

- Eq. (13) 内部采用 `CT = T/[0.5 rho A (Omega R)^2]`，并非与外部常规定义冲突；代码注释已说明它与当前 Eq. (13) 的代数形式配套。外部报告 CT/CP 仍使用常规 `rho A Vtip^2` / `rho A Vtip^3` 定义。
- 诱导速度固定点、挥舞 Newton 解、动量闭合残差、正推力物理分支均有 fail-closed 检查。

评级：`PASS_WITH_CAVEAT`。

### 2.3 Eq. (12) 严格悬停极限

生产路径使用：

`viField = viMean * (1 + cos(psi) * r/R)`。

较早的独立 NUAA 公式审核已经明确记录：在盘内来流严格为零时，风轴方位本身退化，但 Eq. (12) 仍保留一阶方位项，因此单旋翼可以产生依赖任意零方位的一阶挥舞和面内载荷。该审核已经把它定义为公开公式在悬停极限的病态，而不是实际悬停侧向载荷证据。

PR #68 的方程级 preview 又显示，在当前一阶挥舞方程中，`beta1s ≈ -vi/(Omega R)` 会近乎抵消 Eq. (12) 的 cos(psi) 速度项，使积分 CT/CP 与均匀入流几乎相同。但该对照当时仍是 `EQUATION_REPLICA_PREVIEW`。

因此：

- 对 **积分悬停 CT/CP**：当前风险预计较低，但需正式 MATLAB 确认；
- 对 **beta1c/beta1s、Hlong/Hlat、局部 1/rev 载荷、后续整机悬停横侧向结论**：属于重大适用域风险。

评级：积分性能 `PASS_WITH_CAVEAT`；局部/一阶载荷 `MAJOR_REAUDIT`。

必须补做：正式同方程、同参数的 `EQ12` vs `UNIFORM_HOVER` MATLAB 运行，并报告积分量与一阶量。

---

## 3. M1 Stage 1：截面气动、径向几何、C81、环带动量

正式 MATLAB R2021a workflow run `33157075441` 已执行；固定 6–11 deg 结果为：

| 身份 | CT MAPE | CP MAPE | FM MAPE |
|---|---:|---:|---:|
| M0 | 56.4224% | 62.6130% | 23.0180% |
| scalar C81 bridge | 42.8716% | 51.1184% | 12.2221% |
| M1-A | 33.9549% | 45.2392% | 4.4100% |
| M1-B | 37.8538% | 50.5150% | 7.5480% |
| M1-C | 35.7519% | 47.9006% | 5.9849% |

### 3.1 C81 四区段与局部 Mach

NASA/TP-2004-212262 Appendix A 明确写有：

- `NRB=4`
- radial boundaries `0.20, 0.55, 0.80, 0.95`
- 后续依次给出四组 C81 CL/CD/CM 输入表。

因此当前 `xv15_c81_section_lookup.m` 用 0.55/0.80/0.95 硬边界划分四段，在 **TP-2004-212262 CAMRAD II reference-input interpretation** 下有明确来源。

当前实现把第一段从公开起点 0.20R 延伸到 aerodynamic root cutout 0.0875R。该处理不能称为表格直接覆盖，但 Koning 2016 对 XV-15 C81 处理中也明确采用将最内侧 X25 数据复制到 root cutout 以避免根部外推的做法，因此“内延第一翼型数据”是可辩护的建模处理。

正式 Stage-1 结果中，6–11 deg 的 full-C81 global 路径 alpha clamp 和 Mach clamp 均为 0，说明当前报告窗口没有依靠边界截断产生结果。

注意：Koning 2016 的另一套处理会在径向翼型站之间插值，而不是仅使用 TP 的四个离散 radial regions。因此当前模型应称为：

`NASA_TP_2004_212262_FOUR_REGION_C81_REFERENCE_LOOKUP`

而不是无条件称为“精确 XV-15 全径向 C81 真值”。

评级：`PASS_WITH_CAVEAT`。

### 3.2 chord：当前“真实径向几何”表述过强

当前 Stage-1/3/5 多处采用：

- 0.0875R 处 17 in；
- 0.25R 处 14 in；
- 两点之间线性；
- 0.25R 到 tip 保持 14 in。

该表达具有公开几何依据，但并非唯一公开 XV-15 几何表达：

1. NASA/TP-2004-212262 正文描述 original steel blade 在约 0.12R 处 17 in，至 0.25R 收缩到 14 in；
2. Koning 2016 的 XV-15 几何汇总给出 root cutout 0.0875R、root chord 17 in、tip chord 14 in；
3. NASA/TP-2004-212262 Appendix A CAMRAD II reference model 的 aerodynamic property input 使用另一组分段 `RPROP/CHORD` 数值（约 15.855 in、14.085 in、13.995 in），不是当前 17-to-14 线性表达。

因此当前 chord law 应分类为：

`SOURCE_INFORMED_GEOMETRY_RECONSTRUCTION`

而不是未经限定的 `ACTUAL_GEOMETRY_TRUTH`。

这非常重要，因为 M1-A 的约 9 pp CT 改善被解释为“真实径向几何”的贡献。当前证据只能说明“该公开信息约束下的更细径向几何表达”有贡献，尚不能证明该贡献对不同合法公开几何映射不敏感。

评级：`MAJOR_REAUDIT`。

必须补做三分支、无 OARF 调参的 geometry sensitivity：

- `GEOM_CURRENT_17_AT_ROOTCUT_TO_14_AT_025`；
- `GEOM_TEXT_17_AT_012_TO_14_AT_025`；
- `GEOM_TP_APPENDIX_CAMRAD_CHORD_TABLE`。

如果三者的 CT/CP 变化远小于当前 M1-A 增量，可把现有结论升级；否则必须把“几何贡献”改成 source-contract-sensitive。

### 3.3 twist polynomial

当前共享函数：

`289.98*x^5 - 892.87*x^4 + 987.06*x^3 - 438.31*x^2 + 15.695*x + 32.057`。

NASA/TP-2004-212262 Appendix A 已公开 51 点 TWISTA（RPROP=0:0.02:1），因此没有必要在最终证据路径中继续依赖多项式拟合。

独立数值核对表明：

- 在全 0–1 范围，多项式与 51 点源表最大差约 2.37 deg（主要发生在 x=0）；
- 在当前 aerodynamic root 以上，最大差约 0.57 deg；
- root cutout 附近差约 0.18 deg。

这不意味着当前结果失效，但精确源表已存在时继续使用拟合会引入不必要的来源误差。

评级：`PASS_WITH_CAVEAT`。

必须补做：新增直接 TWISTA 插值分支，作为 source-fidelity sensitivity；不得按 OARF 误差选择拟合或表值。

### 3.4 scalar C81 reduction

标量 C81 reduction 是把公开 C81 压到 generic low-order 参数形式，目标是桥接/归因，不是高保真翼型模型。其拟合输入来自公开参考 C81 而不是 OARF CT/CP/FM。

评级：作为 `ATTRIBUTION_BRIDGE` 为 `PASS`；不得把 M1-A 较低 MAPE解释成“标量 C81 比完整 C81 更真实”。

### 3.5 annular momentum M1-C

M1-C 只把全盘平均动量闭合替换为独立径向环带闭合。形式上属于标准局部动量近似；它没有非局部尾迹、环带耦合、tip/root vortex interaction。

现有代码保留 local closure residual，并明确不把它称为 nonlocal wake。

评级：`PASS_WITH_CAVEAT`，仅作为局部 inflow model-form diagnostic。

---

## 4. M1-D：准静态受载扭转（PR #71 正式版本）

### 4.1 参数来源与单位

`build_xv15_metal_torsion_reference.m` 使用 NASA/TP-2004-212262 Appendix A：

- 51 点 `GJ`；
- 51 点 `XQC`；
- `KPL=22400 ft-lbf/rad`。

代码将：

- `GJ [lbf ft^2] -> [N m^2]`；
- `KPL [ft lbf/rad] -> [N m/rad]`；
- `XQC/R -> XQC [m]`。

量纲一致。

### 4.2 物理语义与符号

来源 nomenclature 定义 QC 相对 elastic axis 向后为正。正式 #71 采用：

- 正弹性扭转 = 增大局部桨距；
- C81 `CM` 正值按 nose-up；
- 正法向力作用于 aft-of-EA 正 XQC 时产生 nose-down，因此 `dMoffset=-dNormal*xqc_m`。

该符号在运行前固定，不根据 OARF 误差翻转。

### 4.3 结构关系

采用：

- `dMcm = q c^2 CM dr`；
- `dMoffset = -N xQC`；
- tip-to-root 内扭矩积分；
- `dtheta/dr = T_internal/GJ`；
- pitch-link compliance `theta_link=M_total/KPL`。

作为准静态 torsional-compliance diagnostic，公式与量纲成立。

### 4.4 退化极限

runner 强制要求 M1-D 的 rigid branch 与 Stage-1 M1-B 指标差小于 `1e-6 percentage point`，否则 fail closed。正式结果差异远低于该阈值。

这是当前 M1 链中非常重要且正确的 regression/identity gate。

### 4.5 证据边界

NASA/TP-2004-212262 自身说明该 CAMRAD II reference rotor 使用较早/preproduction blade 信息，且 control-system representation 不完全等同真实 XV-15 overhead spider。因此不能称其为 OARF Run 14/15 记录级结构真值。

评级：`PASS_WITH_CAVEAT`。

正式结论允许：当前公开参考结构包下，准静态扭转为负并恶化 CT/CP 低估，因此不支持把未知正受载桨距偏置作为主要解释。

正式结论不允许：已经排除生产 XV-15 的全部气弹性效应。

### 4.6 PR #72

PR #72 重复实现了 M1-D，但低于 #71 的证据等级：

- 把 `XQC` 乘 chord 形成 offset，和 #71 对 XQC/R 的来源解释不一致；
- 使用无独立来源的 `machFactor = 1 + 0.10*...` 修正 Cm；
- 没有保持 #71 那套完整 C81 CM 与刚性 M1-B identity gate。

评级：`INVALID_AS_EVIDENCE / SUPERSEDED_BY_PR71`。

---

## 5. M1-E：Felker 机制与 Corrigan-Schillings 旋转失速延迟

### 5.1 研究假设来源

Felker 1993 对 tiltrotor hover performance 的公开研究支持：高载荷内段旋转桨叶可能在超过二维翼型峰值的状态仍保持附着/高升力。因此“二维 C81 高迎角可能过于保守”是有独立依据的研究假设。

现有 Stage-3 high-alpha audit 先记录局部 alpha/Mach/CL/径向贡献，不修改气动，这是正确的先验诊断设计。

评级：`PASS`。

### 5.2 Corrigan 公式

Koning 2016 给出的简化关系：

`K_L = [1.291 (c/r)^0.0775]^n`

并在 0 < alpha < 30 deg、正升力区对 CL 乘 `K_L`；当前代码在实际 M1 hover 评估范围内保持 CD 不变，与该简化实现一致。

公式和 apply-domain 基本忠实。

评级：模型形式 `PASS`。

### 5.3 n=1 的来源身份

问题在参数证据身份，而不是公式。

Koning 2016 明确给出 `n` 可在约 0.8–1.8 变化，并在其 XV-15/OARF 相关研究中因相关性更好采用 `n=1.8`。当前代码：

- 正确把 `n=1.8` 标成 `NONINDEPENDENT_XV15_OARF_CORRELATED_VARIANT`；
- 但把 `n=1` 标成 `GENERAL_CORRIGAN_SCHILLINGS_LITERATURE_DEFAULT`。

本审核尚未找到足以证明 `n=1` 是唯一/默认文献值的来源。因此 `n=1` 应改为：

`PREDECLARED_IN_RANGE_CORRIGAN_N1_MODEL_FORM_ASSUMPTION`

它的优点是：在看 WADC 前已经冻结，并且不由当前 OARF 误差搜索得到；它的不足是：不是由独立试验唯一识别出来的物理参数。

评级：`MAJOR_REAUDIT`（证据身份/措辞），数值公式本身无需因此作废。

### 5.4 对 WADC 泛化结果的含义

WADC post-freeze 改善可以支持：

> “这个预先冻结的 n=1 Corrigan 模型包在另一设施仍保持相对 M0 的改善。”

不能支持：

> “WADC 证明 n=1 就是真实 XV-15 旋转失速参数。”

---

## 6. M1-F：Landgrebe + lifting-line circulation + Biot-Savart

### 6.1 来源正确部分

当前 helper 使用经典 Landgrebe hover wake trajectory 参数：

- `A=0.78`；
- `k1=-0.25*(CT/sigma+0.001*theta_tw)`；
- `k2=-(1.41+0.0141*theta_tw)*sqrt(CT/2)`；
- `gamma=0.145+27*CT`。

离散 bound circulation 用 `Gamma = 0.5 W c CL`，trailing strength 用径向 Gamma jump，诱导速度用有限直线涡段 Biot-Savart。

这些模型形式有明确理论/公开资料支撑。

### 6.2 当前内段尾迹不是完整 Landgrebe

代码明确把同一归一化 tip-vortex contraction/axial trajectory 推广给所有内段 trailing filaments，并将其标成：

`ASSUMED_UNIFORM_NORMALIZED_CONTRACTION_EXTENSION`。

经典 Landgrebe 体系对 tip vortex 与 inboard vortex sheet 有不同处理。当前推广是透明假设，但不是完整来源复现。

### 6.3 盘面平均诱导不是纯 Biot-Savart 自洽预测

Stage-4/4B 计算先得到 raw Biot-Savart radial shape，再执行：

`viTarget = viMomentum * (rawWake/rawWakeMean)`。

因此：

- momentum theory 决定盘面平均诱导；
- wake model 只决定 radial redistribution shape。

这种 closure 作为低阶诊断可以成立，但不能描述成“由完整非局部尾迹独立预测了诱导速度绝对水平”。

### 6.4 数值证据

Stage-4 首轮正式汇总：

- M1-E1 reference：6/6 supported；
- F0 uniform control：6/6 supported；
- `M1_F1_LANDGREBE_NONLOCAL`：`0/6 supported`，完整窗口指标为 NaN。

Stage-4B 后续通过更稳健的数值初始化/relaxation 检查数学固定点，但该 runner 明确没有改变物理模型。数值收敛不能消除内段 wake geometry 的模型形式不确定性。

评级：`DIAGNOSTIC_ONLY`。

允许结论：非局部径向入流重分配可能对部分载荷区间产生可辨影响；现有 prescribed-wake extension 暴露出低载荷病态和适用性限制。

禁止结论：M1-F 已经验证/复现 XV-15 非局部尾迹，或已经作为正式 M1 主模型通过。

---

## 7. Stage 5 WADC post-freeze cross-facility validation

### 7.1 数据录入

`analysis/data/xv15_wadc_metal_table_a3.csv` 保存 NASA/CR-2017-219486 Appendix A Table A-3 formal Runs 1–3 数据。当前值与公开表中 Vtip、Mtip、collective75、CT、CP、FM 相符。

验证窗口继承冻结前 6–11 deg：每 Run 实际使用 6,8,9,10,11，共 15 点；无 7 deg 插值、无按误差删点。

评级：`PASS`。

### 7.2 模型冻结与身份等价

M1 在读取 WADC 数值前冻结为 `M1_HOLDOUT_V1 = M1_E1_GENERIC_CORRIGAN_N1`。Stage-5 copied solver 在 OARF 冻结参考点上要求与 Stage-3 逐点一致，最大 CT/CP/FM 差 <= 1e-10；正式记录为 0。

因此 WADC 后没有通过复制 runner 偷改模型。

评级：`PASS`。

### 7.3 环境输入同源性

当前 M1 WADC runner：

- 用 Table A-3 `Vtip` 设置 Omega；
- C81 local Mach 用 `W / aSound`；
- `aSound` 固定 340 m/s；
- 报告的 WADC `Mtip` 只保存为 metadata，不用于逐点反推出试验声速；
- `rho` 沿用 generic environment，因为 Table A-3 没有给出逐点密度。

这是一个有意冻结的输入契约，因此原 holdout 没有 data leakage；但从物理同源性角度，它不是最强试验复现。

基于 Vtip/Mtip，WADC 不同 Run 的实际等效声速与 340 m/s 存在小幅差异。因为 C81 对 Mach 有显式依赖，必须量化这种差异是否可忽略。

评级：`PASS_WITH_CAVEAT`，需要 post-hoc input-homology sensitivity。

该敏感度只能回答“原 holdout 对未映射试验环境有多敏感”，不能在看完 WADC 后用新输入替换原冻结结果并继续称为同一个 holdout。

### 7.4 当前 WADC 结论的正确表述

正式 pooled 指标：

- M0：CT 59.15%、CP 66.10%、FM 23.05%；
- frozen M1：CT 37.90%、CP 51.11%、FM 9.26%。

三个 Run 上 M1 相对 M0 的改善量高度一致，这是一条有价值的跨设施证据。

它验证的是 **冻结模型包的泛化改善**，不是单独验证：

- 当前 chord reconstruction 唯一正确；
- twist polynomial 唯一正确；
- Corrigan n=1 是真实物理常数；
- Eq. (12) 是严格悬停唯一正确入流。

因此论文中的因果措辞应从“这些物理被独立验证”为：

> “由这些来源受约束/预声明假设组成的冻结低阶模型包，在未利用 WADC 调参的条件下，相对 M0 的改善跨设施保持；各单项机制的唯一性仍受 source-contract 和 model-form 限制。”

---

## 8. 证据矩阵

| 层级 | 来源 | 参数语义/单位 | 方程实现 | 退化/身份检查 | 数值闭合 | 外部证据 | 最终评级 |
|---|---|---|---|---|---|---|---|
| M0 NUAA low-order | 有 | 基本清楚 | 有公开式 + 标准闭合 | 有 | 强 | OARF/WADC 趋势 | `PASS_WITH_CAVEAT` |
| M0 Eq12 strict hover local loads | 有公式 | 悬停方位退化 | 已实现 | 待正式 uniform 对照 | 可收敛 | 无局部试验 | `MAJOR_REAUDIT` |
| scalar C81 bridge | 有 | 清楚 | 低阶约化 | 有 | 强 | OARF | `PASS` as bridge |
| M1 chord reconstruction | 多个冲突/不同公开表达 | 当前语义清楚但来源非唯一 | 可运行 | 无多源 sensitivity | 强 | OARF/WADC bundle | `MAJOR_REAUDIT` |
| M1 twist polynomial | 51 点源表存在 | 清楚 | polynomial approximation | 无 direct-table sensitivity | 强 | OARF/WADC bundle | `PASS_WITH_CAVEAT` |
| four-region C81 + local Mach | TP 输入明确 | 清楚 | 忠实于 TP region mapping | OFF/baseline 有 | 强、无 clamp | OARF/WADC bundle | `PASS_WITH_CAVEAT` |
| annular momentum | 标准理论 | 清楚 | 局部环带 | 与 global 比较 | 强 | OARF | `PASS_WITH_CAVEAT` |
| formal M1-D #71 | NASA reference input | 单位/符号已审 | 合理准静态 | rigid=M1-B gate | 强 | OARF diagnostic | `PASS_WITH_CAVEAT` |
| duplicate M1-D #72 | 部分来源 | XQC/Cm 存疑 | 存无源项 | 弱 | 可运行 | 无独立价值 | `INVALID_AS_EVIDENCE` |
| Felker local-state audit | 有 | 清楚 | 不改模型 | N/A | 强 | 机制相关 | `PASS` |
| Corrigan formula | 有 | 清楚 | 与 Koning 简化式一致 | OFF=M1-B gate | 强 | OARF + WADC bundle | `PASS` formula |
| Corrigan n=1 provenance | 只确认 0.8–1.8 范围 | n=1 非唯一来源参数 | 数值稳定 | 预先冻结 | 强 | WADC tests bundle | `MAJOR_REAUDIT` wording/provenance |
| Landgrebe/Biot-Savart | tip wake 公式有 | inboard extension 为假设 | 低阶混合 closure | uniform control 有 | 初始 0/6；4B 数值审计 | 无独立 wake 数据 | `DIAGNOSTIC_ONLY` |
| WADC source data | 有 | 清楚 | 转录一致 | manifest gate | 15/15 | post-freeze | `PASS` |
| WADC environment mapping | 部分缺失 | Vtip 有、Mtip 未用于 solver、rho 未闭合 | frozen contract | identity gate 有 | 强 | 跨设施 | `PASS_WITH_CAVEAT` |

---

## 9. 必须执行的四项修正/复核

### A. Geometry source-fidelity sensitivity

同一 solver、同一 OARF/WADC，不调参，比较：

1. current chord reconstruction；
2. TP 正文 17 in @ 0.12R -> 14 in @ 0.25R；
3. TP Appendix A CAMRAD CHORD/RPROP input；
4. polynomial twist；
5. direct 51-point TWISTA interpolation。

输出 CT/CP/FM 以及径向 loading 差异。目标不是选误差最小者，而是判断既有结论对合法来源映射是否稳健。

### B. Strict-hover Eq. (12) limit audit

正式 MATLAB 运行两条完全相同的路径，仅切换：

- `NUAA_EQ12_FIRST_HARMONIC`；
- `UNIFORM_HOVER_INFLOW`。

除 CT/CP/FM 外必须输出：

- beta0, beta1c, beta1s；
- Hlong/Hlat；
- 1/rev flap moment；
- radial/azimuthal alpha and dT harmonics。

若积分性能相同但一阶载荷显著不同，则 M1 悬停性能相关可保留，而后续整机 hover lateral dynamics 不得沿用 Eq.12 一阶结果作为真实物理证据。

### C. Corrigan n=1 provenance correction

不改数值，只改证据身份：

从：

`GENERAL_CORRIGAN_SCHILLINGS_LITERATURE_DEFAULT`

改为：

`PREDECLARED_IN_RANGE_CORRIGAN_N1_MODEL_FORM_ASSUMPTION`

并同步文档。WADC 结果仍保留为对这一冻结假设模型包的 post-freeze 外部检验。

### D. WADC input-homology sensitivity

保持原 holdout 不动，新增明确标成 `POSTHOC_INPUT_HOMOLOGY_SENSITIVITY` 的分析：

- `aSound_test = Vtip / Mtip` 逐点计算；
- 与 frozen `aSound=340` 结果比较；
- 若缺密度，按公开设施/标准大气可辩护范围作透明 rho sensitivity，而不是选择最佳 rho；
- 报告对 CT/CP/FM、local Mach/clamp count 的影响。

若影响远小于 M1-M0 改善，可提升跨设施泛化结论；若不可忽略，则应把 WADC 结果明确描述为“cross-facility under frozen generic-environment contract”。

---

## 10. 当前可以继续保留的科学结论

1. M0 在 OARF 和 WADC 上均存在大的、同方向的 CT/CP 系统低估；这不是单一 Run 的偶然数值现象。
2. Stage-1 所引入的更细截面气动/径向表示显著改变积分性能，说明 generic M0 的气动/几何降阶确实是误差来源的一部分。
3. 更完整 TP four-region C81 并没有比 scalar reduction 更接近 OARF，因此 M1-A 的低 MAPE 存在 error cancellation 风险；“更准”不能直接等于“更真实”。
4. 独立 annular momentum 只能提供有限增量改善，不能闭合主要残差。
5. 正式 #71 M1-D 在公开参考结构包下产生负受载扭转并恶化当前低估，因此不支持任意正 collective offset 解释。
6. Corrigan rotational-stall-delay 是有独立文献依据的合理低阶模型形式，但当前 n=1 是预声明模型选择而非已唯一识别的真实参数。
7. WADC 在 post-freeze 条件下保持 M1 相对 M0 的改善，支持“冻结增强模型包具有跨设施泛化价值”，但不单独证明每个内部参数/机制唯一正确。
8. 当前 Landgrebe/Biot-Savart 实现只属于模型形式诊断，不能作为最终 M1 身份。

---

## 11. 当前必须撤回或降级的表述

以下表述在四项阻断复核完成前不应出现在论文结论中：

- “M1-A 恢复了 XV-15 **真实**径向 chord/twist，且该真实几何贡献已被定量识别。”
- “Corrigan `n=1` 是通用文献默认参数。”
- “M1-F 已完成非局部尾迹增强并验证其有效性。”
- “WADC 证明完整 C81、n=1 Corrigan、当前几何映射分别都正确。”
- “Eq. (12) 在严格悬停的局部/横侧向载荷上具有物理可信度。”
- “PR #72 的 M1-D 结果可作为正式证据。”

---

## 12. 下一步研究决策

当前唯一合理的下一步不是再加物理，而是完成 A–D 四项 source/limit/homology 审核。

若 A–D 表明核心结论对这些来源与极限处理稳健，则可以冻结一个**经过来源完整性复核的 M1_HOLDOUT_V1 证据包**，随后回到整机层研究 M0/M1 对 trim、conversion、linear modes、stability/control 与 nacelle dynamics 的影响。

若 A–D 中任何一项显著改变既有结论，则先修正模型身份与论文因果链，再决定是否需要建立新的 M2；不得通过继续堆叠新物理掩盖 source-contract 问题。
