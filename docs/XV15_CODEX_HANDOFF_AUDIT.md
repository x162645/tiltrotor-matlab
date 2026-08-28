# Codex 接手工作审计与证据边界修正

## 审计结论

本次审计针对 `e3fd6b244e27a55870489722d8518743dfeb0878` 之后由 Codex 在 PR #68 分支继续提交的工作。结论不是“整体接受”或“整体推翻”，而是：

- **数值与资料追溯工作大部分合理，应保留**；
- **证据等级、外部验证术语和下一步研究边界存在方法学错误，必须修正**；
- 不需要回滚生产模型，因为 Codex 没有修改 `params_nominal.m` 或核心 `model/rotor_model_bemt.m`；
- 修正重点应放在“哪些结果已经由 MATLAB 实跑、哪些仍只是方程级 preview、OARF 数据集可以支持什么结论、以及非局部尾迹是否允许继续验证”。

## 1. 可以保留的工作

### 1.1 冻结低阶配置的数值结果

`analysis/run_xv15_frozen_low_order_validation.m` 给出的 6°–11°结果可以保留为一个**冻结后的外部相关性比较**：

- CT MAPE = 42.8716%；
- CP MAPE = 51.1184%；
- FM MAPE = 12.2221%；
- CT、CP 均为系统性低估。

这组数值支持“当前冻结低阶验证配置不能定量复现 XV-15 原始金属桨 OARF Run 15 的绝对悬停性能”。这一结论合理。

但它不应被称为严格意义上的“盲 hold-out 验证”。OARF Run 15 已经在 PR #67/#68 的误差诊断中反复用于判断模型误差形态和选择后续诊断方向，因此该数据集在方法学上已经参与了模型开发过程。正确称谓应是：

> **post-development frozen external correlation / 冻结后的外部相关性比较**。

若论文需要严格独立的最终验证，应另选一套此前未参与模型选择的数据，或在研究开始前冻结训练/诊断集与最终验证集。

### 1.2 质量属性单因素核验

`analysis/run_xv15_mass_property_single_factor.m` 的做法合理：

- 使用 NASA 公开质量分布积分一阶质量矩；
- 使用报告直接给出的 105 slug·ft² 作为挥舞惯量；
- 把质量、一阶矩、挥舞惯量作为耦合包一次替换；
- 只做 10°代表点；
- 不使用 OARF 目标调参；
- 明确说明该公开质量分布是参考模型输入，不冒充直接称重真值。

因此它只支持一个窄结论：在当前低阶方程的 10°悬停点，替换为该来源质量属性包显著改变锥度角，但 CT/CP/FM 的变化低于可解释数值精度，故该质量属性差异不能解释该代表点数十个百分点的性能误差。不能把这一单点结果外推成全工况物理上界。

### 1.3 Prandtl 根/尖损失筛查

`analysis/run_xv15_prandtl_root_tip_loss_screen.m` 作为**量级筛查**是合理的：

- 真实径向几何；
- 完整四区 C81 + 局部 Mach；
- 当前第一谐波挥舞和 Eq. (12) 方位入流；
- Prandtl 因子仅进入环带动量闭合 `dT = 2 rho dA F vi^2`，没有再把叶素升阻力重复乘一次 `F`；
- 不使用 OARF 拟合损失因子；
- 做了 12/24/48/96 径向离散检查；
- 对负局部推力环带和不收敛点保留 unsupported 状态。

MATLAB 实跑结果表明，在 9°–11°共同支持区间：

- 无损失 CT MAPE = 31.5313%；
- 根尖损失 CT MAPE = 32.9662%；
- 无损失 CP MAPE = 45.7771%；
- 根尖损失 CP MAPE = 46.0928%。

因此经典局部 Prandtl 根/尖损失不能解释当前已经偏低的绝对推力和功率，方向上反而略微恶化 CT/CP。这一结论合理。

## 2. 必须修正的问题

### 2.1 OARF Run 15 不能再称为“未见过的 hold-out”

代码中“先预测再附加目标值”只能证明**同一次 runner 内没有用目标值做数值反调**，不能恢复数据集层面的独立性。

PR #67/#68 已经根据 OARF 误差形态进行了：

- 截面气动误差诊断；
- 等效零升力角解释；
- C81 低阶约化；
- 几何、入流、旋转增升、环带动量等诊断方向选择。

因此现阶段应把 OARF Run 15 定位为：

> **开发过程中反复使用的外部基准数据集**，可用于相关性与误差归因，但不是严格盲验证集。

### 2.2 6°–11°不是“事前盲选”的评分窗口

该区间此前已经因为低总距点的物理不收敛而被反复使用。现在可以冻结它作为**固定报告窗口**，但不能写成在看到模型行为之前就预注册的 blind/predeclared window。

推荐表述：

> `FIXED_REPORT_WINDOW_6_TO_11_DEG_FROM_PREVIOUSLY_ESTABLISHED_PHYSICAL_SUPPORT`

### 2.3 “当前通用低阶模型”需要区分生产核心和验证适配层

冻结 runner 调用的是 `rotor_model_bemt_section_aero`，并给入由 NASA C81 独立约化得到的 `alpha0L/liftSlope/CLmax/CD0/kCD`。因此更准确的对象是：

> **生产核心方程不变的冻结低阶验证配置，其中启用了 opt-in 截面气动适配层。**

不能把它写成“完全未扩展的默认 production 参数配置”，也不能写成 XV-15 专用高阶重建。

### 2.4 `PREVIEW` 结果不能标成“MATLAB 已验证”

`docs/XV15_ERROR_ATTRIBUTION.csv` 中多个历史诊断引用的证据文件仍明确带有 `PREVIEW`：

- `XV15_SECTION_AERO_METRICS_PREVIEW.csv`
- `XV15_ACTUAL_GEOMETRY_C81_CROSSCHECK_METRICS_PREVIEW.csv`
- `XV15_HOVER_INFLOW_METRICS_PREVIEW.csv`
- `XV15_DELTA3_PITCH_FLAP_METRICS_PREVIEW.csv`
- `XV15_FLAP_INFLOW_INTERACTION_METRICS_PREVIEW.csv`
- `XV15_MANGLER_HOVER_METRICS_PREVIEW.csv`
- `XV15_ROTATIONAL_AUGMENTATION_EQUATION_REPLICA_PREVIEW.csv`

这些结果可以作为**方程级复现证据**，但在对应 MATLAB runner 未实际运行并产生非 preview 输出前，证据等级不能写成“已验证”。

本项目从现在开始统一采用以下证据分级：

| 等级 | 含义 |
|---|---|
| `MATLAB_RUN` | 本机 MATLAB 实际运行，正式结果文件已提交 |
| `EQUATION_REPLICA_PREVIEW` | 与代码方程逐项复现的方程级结果，尚未由对应 MATLAB runner 实跑闭环 |
| `SOURCE_AUDIT` | 原始文献/试验资料的定义、单位、构型或参数追溯 |
| `ASSUMPTION` | 模型或数值假设，不声称真实型号来源 |

`PREVIEW` 可以支持“当前方程级诊断显示……”，不能写成“MATLAB 已验证……”。

### 2.5 “尚未验证非局部尾迹”不能推出“严格停止扩模”

这是 Codex 工作中最重要的方法学矛盾。

`docs/XV15_PRANDTL_ROOT_TIP_LOSS_SCREEN.md` 正确指出：经典 Prandtl 因子只是一种局部有限叶片修正，并没有描述：

- 收缩螺旋尾迹；
- 根涡/尖涡对其他径向站位的非局部诱导；
- 环带之间的耦合；
- 尾迹年龄与涡核；
- 自由尾迹形变。

因此 Prandtl 筛查失败只允许推出：

> **经典局部根/尖损失因子不是当前 30% 左右 CT 低估的解释。**

它不能推出：

> **非局部有限叶片尾迹不重要，或不得继续验证。**

“尚未验证”与“已证伪”不是同一证据状态。

## 3. 修正后的研究路线

当前允许继续的下一层是一个**独立、诊断性、文献约束的规定尾迹模型**，而不是把生产核心升级成 XV-15 高保真模型。

建议最低阶实现：

1. 保持现有通用 production core 不变；
2. 另建 `analysis/` 下的 prescribed-helical-wake diagnostic；
3. 用升力线/束缚环量 `Gamma(r)` 生成尾缘脱落涡与尖涡；
4. 用 Biot–Savart 计算非局部诱导速度；
5. 使 `Gamma(r)` 与 `vi(r,psi)` 自洽迭代；
6. 尾迹收缩、螺距、涡核等参数必须来自独立文献或透明理论关系，**不得由 OARF Run 15 反调**；
7. 仍以 OARF 作为外部相关性基准，只比较结果，不拟合；
8. 若误差没有改善，同样记录为负结果，不再添加任意增益。

其基本闭环应为：

```text
Gamma(r)
  -> prescribed helical trailing/tip wake
  -> Biot-Savart induced velocity vi(r,psi)
  -> local alpha(r,psi)
  -> section CL/CD
  -> updated Gamma(r)
```

而不是再规定一个经验 `vi(r)` 函数。

## 4. 不允许的做法

- 不得用 OARF CT/CP/FM 拟合尾迹收缩率、螺距、涡核半径或经验诱导增益；
- 不得把 XV-15 专用参数硬编码进 `params_nominal.m`；
- 不得为改善误差直接修改 `model/rotor_model_bemt.m` 的默认生产路径；
- 不得把 `PREVIEW` 结果写成 MATLAB 实跑验证；
- 不得把 OARF Run 15 再描述成 blind hold-out；
- 不得因为某一局部经验修正无效就宣称整个有限叶片/尾迹物理无效；
- 不得声称当前 XV-15 定量验模已经通过。

## 5. 当前可发表的严谨结论

目前最稳妥的学术表述是：

> 当前通用低阶旋翼模型在冻结的 XV-15 参数映射与独立 C81 低阶约化配置下，对原始金属桨 OARF Run 15 悬停推力和功率存在显著系统性低估。资料追溯和逐层诊断表明，通用截面参数与几何约化均贡献部分误差，而经典局部 Prandtl 根/尖损失、简单环带动量及若干低阶入流/挥舞修正不能闭合剩余差距。由于 OARF Run 15 已参与前期模型诊断，其结果应视为开发后冻结外部相关性而非盲验证。非局部有限叶片尾迹耦合目前仍属于未验证模型形式，后续可在不修改生产核心、不使用 OARF 反调参数的前提下，通过文献约束的规定螺旋尾迹—升力线—Biot–Savart 诊断进行独立检验。

## 6. 审计后 GitHub 状态原则

本审计**保留 Codex 的三个数值/资料工作包**，不回滚其 MATLAB 结果；只重建证据等级和研究决策边界。后续 PR 描述、误差归因表和论文文字均应以本文件的边界为准。