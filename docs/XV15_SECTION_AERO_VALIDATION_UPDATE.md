# XV-15 原始金属桨悬停验模：独立截面气动修正

## 1. 本轮目标

PR #67 已经完成第一轮不调参外部验模，并确认：当前通用低阶旋翼模型能够给出随总距增加而上升的推力/功率趋势，但 XV-15 原始金属桨 OARF 悬停试验的绝对量级存在显著系统性低估。

本轮不再增加复杂径向几何，也不使用 OARF 的 CT/CP/FM 反标参数，而是检验一个更直接的物理假设：

> 当前截面升力关系强制 `alpha=0 -> CL=0`，而 XV-15 原始金属桨采用有弯度的 NACA 64 系列翼型，因此缺少零升力角/基准升力是一个真实的低阶模型缺项。

研究对象仍然是**通用低阶部件级模型**，不是 XV-15 数字孪生。

---

## 2. 独立翼型信息与低阶等效方法

公开 XV-15 原始金属桨资料给出的代表性翼型站位为：

| r/R | 翼型 | NACA 6 系列设计升力系数记号 |
|---:|---|---:|
| 0.09 | NACA 64-935 | 0.90 |
| 0.17 | NACA 64-528 | 0.50 |
| 0.51 | NACA 64-118 | 0.10 |
| 0.80 | NACA 64-(1.5)12 | 0.15 |
| 1.00 | NACA 64-208 | 0.20 |

这里的数值是 **NACA 6 系列命名中的设计升力系数**，不是把它直接宣称为 `CL(alpha=0)` 的实测值。

为了保持现有模型的低阶性质，本轮采用透明的一阶约化：

\[
\alpha_{0L}(r)\approx-\frac{C_{l,design}(r)}{a_0}
\]

其中 `a0=5.7 rad^-1` 保持当前通用模型默认值，不由 OARF 数据反标。

悬停叶素的升力敏感度一阶近似满足

\[
dL\propto c(r)r^2dr
\]

因此采用

\[
w(r)=c(r)(r/R)^2
\]

进行径向加权，得到标量低阶等效零升力角：

\[
\boxed{\alpha_{0L,eq}\approx-1.69834^\circ}
\]

这一数值的正确标签是：

> **由公开 XV-15 翼型分布与 NACA 设计升力系数定义得到的低阶等效量。**

它不是 NASA 直接给出的 XV-15 标量零升力角，也没有使用最终 OARF 推力/功率曲线拟合。

---

## 3. 模型实现方式

新增 `model/rotor_model_bemt_section_aero.m`，作为 `rotor_model_bemt` 的 opt-in 包装层。

### 3.1 标量零升力角

当前 production 模型使用

\[
C_L=C_{L,max}\tanh\left(\frac{a\alpha}{C_{L,max}}\right).
\]

对于一个标量 `alpha0L`，替换为

\[
\alpha_{eff}=\alpha-\alpha_{0L}
\]

与将所有桨叶截面的几何桨距统一平移 `-alpha0L` 在当前低阶形式中代数等价，因此包装层只改变传给原 production 模型的有效 collective；其余 BEMT、NUAA Eq.12/13 入流、拍振、力矩链全部保持原代码。

当 `alpha0L` 缺省或为 0 时，包装层调用与 production 基线完全相同。

### 3.2 低阶压缩性修正

第二个变体不引入径向马赫数数据库，而采用一个同样低阶的参考半径处理：

\[
M_{ref}=\frac{\Omega R(0.75)}{a_s}
\]

并按

\[
a_{eff}=\frac{a_0}{\sqrt{1-M_{ref}^2}}
\]

修正升力线斜率。`M_ref` 上限暂设为 0.75，属于有界的模型选择，不是 XV-15 实测参数。

OARF 本组试验的 `M_ref` 约为 0.516，因此升力斜率放大因子约 1.168。

该处理的用途是判断“压缩性是否属于下一层值得保留的低阶物理量”，而不是代替真实 NACA 翼型极曲线。

---

## 4. 重新验模结果

为避免不同低总距收敛区域影响比较，三种方案均只在 PR #67 已使用的共同物理收敛区间 **theta75 = 6°–11°** 上统计 MAPE。

| 方案 | CT MAPE | CP MAPE | FM MAPE |
|---|---:|---:|---:|
| PR67 基线 | 56.42% | 62.61% | 23.02% |
| 独立 `alpha0L_eq` | **43.86%** | **51.90%** | **12.57%** |
| `alpha0L_eq` + 0.75R PG 等效修正 | **39.79%** | **47.53%** | **11.54%** |

因此：

- 仅增加独立零升力角约化，CT MAPE 下降约 **12.56 个百分点**；
- 再加入低阶压缩性，CT MAPE 相对基线共下降约 **16.63 个百分点**；
- CP MAPE 相对基线下降约 **15.09 个百分点**；
- FM MAPE 约减半。

以 `theta75=10°` 为例：

| 量 | 试验 | 基线 | `alpha0L_eq` | `alpha0L_eq + PG075` |
|---|---:|---:|---:|---:|
| CT | 0.013089 | 0.006396 | 0.007856 | 0.008460 |
| CP | 0.001358 | 0.000525 | 0.000663 | 0.000730 |
| FM | 0.7797 | 0.6889 | 0.7422 | 0.7542 |

这说明上一轮从误差形态提出的“截面气动基准缺失”判断得到**独立来源参数的支持**。

同时也必须强调：

\[
\boxed{\text{修正后仍未通过定量外部验模}}
\]

`alpha0L_eq + PG075` 后 CT/CP 仍分别有约 40%/48% 的平均相对误差，绝不能写成“XV-15 已验证通过”。

---

## 5. 对 PR #67 的 +7.70° 事后诊断的重新解释

PR #67 在看过 OARF 曲线后得到约 `+7.70°` 的统一气动桨距偏移，并明确将其标为 post-validation diagnostic。

本轮从独立 NACA 信息得到：

\[
|\alpha_{0L,eq}|\approx1.70^\circ
\]

明显小于 7.70°。

因此现在可以更明确地说：

> **PR #67 的 7.70° 不能解释成真实翼型零升力角。**

它实际上汇总了多个尚未建模/尚未匹配的效应。独立翼型基准只解释了其中一部分，简单压缩性又解释了另一部分。

这恰恰避免了把“事后拟合量”误当成“物理参数”。

---

## 6. 当前剩余误差说明了什么

当前最值得继续检查的不是弦长 1%–2% 的差别，而是下列仍直接进入 CT/CP 的低阶气动假设：

1. **真实截面极曲线**：目前 `alpha0L_eq` 仍由 NACA 设计 Cl 做一阶约化，并非各径向翼型在对应 Re/Mach 下的真实 `CL(alpha)`；
2. **型阻与功率**：`CD0=0.011`、`kCD=0.012` 仍是 generic 参数，CP 偏差对它们非常敏感；
3. **马赫数/Reynolds 数分布**：PG075 只是一个标量低阶修正；
4. **三维/旋转叶片效应与尖部损失**：当前模型没有专门的 tip-loss/3D section correction；
5. **入流模型适用性**：当前仍严格保留 Sheng et al. 低阶模型的 NUAA Eq.12 一阶谐波入流与 Eq.13 闭合；外部悬停数据可以继续用于判断其适用范围，但不应在同一数据上反调后再称独立验证。

下一步最合理的是优先寻找/整理**独立 NACA 64 系列翼型极曲线或可复现的公开翼型计算数据**，把 `CL0/alpha0L` 与 `CD0/kCD` 从“generic 值”提升为独立截面气动约化，再保留 OARF Run 15 作为 hold-out 比较。

---

## 7. 证据与复现状态

新增：

- `model/rotor_model_bemt_section_aero.m`
- `analysis/run_xv15_section_aero_validation.m`
- `tests/check_rotor_section_aero_extension.m`
- `results/xv15_section_aero_validation/XV15_SECTION_AERO_EQUATION_REPLICA_PREVIEW.csv`
- `results/xv15_section_aero_validation/XV15_SECTION_AERO_METRICS_PREVIEW.csv`
- `results/xv15_section_aero_validation/XV15_NACA_ALPHA0_REDUCTION_INPUT_PREVIEW.csv`

当前连接环境不能调用项目本机 MATLAB，因此新增 MATLAB runner/test 尚未实际执行。

preview 数值来自与当前 production BEMT + Eq.12/Eq.13 + 稳态一阶谐波拍振方程逐式一致的复现；该复现首先重新得到 PR #67 基线数值，例如 10° 点 `CT≈0.006396`、`CP≈0.000525`，再启用本轮两个独立低阶修正。

本机最终应执行：

```matlab
startup;
check_rotor_section_aero_extension;
results = run_xv15_section_aero_validation;
```

以 MATLAB 生成的 `XV15_SECTION_AERO_MATLAB_VALIDATION.csv` 与 `XV15_SECTION_AERO_MATLAB_METRICS.csv` 作为最终运行证据，preview 文件只作为当前可审查的预计算证据。

---

## 8. 本轮可以支持的论文式结论

> 基于 XV-15 原始金属桨公开翼型分布，对通用低阶旋翼模型增加独立来源的等效零升力角后，悬停推力、功率及效率预测均出现一致改善；进一步加入参考半径压缩性升力斜率修正后误差继续下降。结果表明，截面气动基准简化是原模型系统性低估的重要来源之一，但并非唯一来源。由于修正参数未由 OARF 性能曲线反标，该结果可用于支持模型结构改进有效性的判断；现阶段剩余 CT/CP 偏差仍较大，不构成 XV-15 定量验证通过。
