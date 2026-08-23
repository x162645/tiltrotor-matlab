# XV-15 悬停径向环带动量诊断

## 目的

本诊断继续沿用“通用低阶模型 + XV-15 验证实例”的误差归因路线。目标不是新增 XV-15 专用 production 模型，而是隔离检查当前旋翼悬停模型采用单一全盘平均诱导速度这一低阶假设是否构成主要误差源。

外部比较数据仍为 NASA OARF 原始金属桨 Run 15。OARF 的 CT/CP/FM 不参与本诊断任何参数拟合或入流分布反求。

## 理论依据

经典 combined blade-element and momentum theory 可将旋翼盘划分为径向环带，并在每个 annulus 上独立满足叶素载荷与动量关系。NASA-CR-3082《Rotary-Wing Aerodynamics, Volume 1》明确将该方法描述为 combined blade-element and momentum / annular-disk momentum theory；NASA-TM-81258 进一步给出了 local momentum theory，将局部叶素载荷与局部诱导速度闭合，并讨论悬停尾迹收缩扩展。

本诊断使用最简单的悬停环带动量关系：

`dT_j = 2*rho*dA_j*vi_j^2`

其中 `dA_j = pi*(r_outer^2-r_inner^2)`。因此 `vi_j` 不是人为规定的径向形状，也不是用 OARF 拟合，而是由该环带当前叶素推力自洽迭代得到。

## 隔离变量

保持不变：

- XV-15 PR67 的 R、Nb、rootCut、RPM/试验总距映射；
- NASA C81 -> 当前低阶形式得到的 scalar section parameters；
- 第一谐波挥舞；
- Eq. (12) 的方位一阶入流形状；
- 叶素力分解和动量松弛方式；
- OARF 仅作外部比较。

唯一变化：

- GLOBAL：全盘只使用一个平均诱导速度 `viMean`；
- ANNULAR：每个径向环带使用独立 `vi_j`，按局部环带动量闭合。

## 低阶几何下的方程级复现结果

使用当前 production-compatible 的 12 个径向叶素、面积等效 chord 和线性 twist：

| theta75 | CT exp | CT global | CT annular | CP exp | CP global | CP annular | annular supported |
|---:|---:|---:|---:|---:|---:|---:|:---:|
| 6 | 0.009208 | 0.004252 | 0.005034 | 0.000796 | 0.000350 | 0.000450 | no |
| 7 | 0.010104 | 0.005213 | 0.006151 | 0.000913 | 0.000421 | 0.000513 | no |
| 8 | 0.011063 | 0.006203 | 0.006980 | 0.001044 | 0.000503 | 0.000592 | no |
| 9 | 0.012035 | 0.007209 | 0.007893 | 0.001188 | 0.000596 | 0.000681 | yes |
| 10 | 0.013089 | 0.008220 | 0.008761 | 0.001358 | 0.000700 | 0.000776 | yes |
| 11 | 0.013929 | 0.009225 | 0.009641 | 0.001523 | 0.000812 | 0.000879 | yes |

6–8 deg 出现至少一个局部负推力环带。简单悬停环带动量关系 `dT=2 rho dA vi^2` 无法表示负局部推力与相邻正载荷环带之间的尾迹耦合，因此这些点明确标记为 unsupported，不通过 `abs(dT)` 或 signed square-root 人为续接。

在共同可支持的 9–11 deg 区间：

- CT MAPE：37.025% -> 32.756%
- CP MAPE：48.322% -> 42.610%
- FM MAPE：4.078% -> 3.902%

因此局部径向动量闭合确实能改善部分 CT/CP，但不能解释全部剩余误差。

## 数值网格检查

10 deg 工况的 radial-grid sensitivity：

| nRadial | CT global | CT annular | CP global | CP annular |
|---:|---:|---:|---:|---:|
| 12 | 0.008220 | 0.008761 | 0.000700 | 0.000776 |
| 24 | 0.008186 | 0.008746 | 0.000698 | 0.000775 |
| 48 | 0.008177 | 0.008742 | 0.000697 | 0.000775 |
| 96 | 0.008175 | 0.008741 | 0.000697 | 0.000775 |

因此 10 deg 的 annular 改善不是 12 个径向叶素的离散偶然。

## 与实际径向几何的交叉检查

为了避免把 annular 改善误认为纯入流效应，又做了一个 equation-replica cross-check：恢复 NASA 公布的径向 chord 分布和原始金属桨非线性 twist polynomial，同时仍使用同一套 scalar C81 低阶截面气动。

该交叉检查采用 48 个径向叶素。9–11 deg：

- actual-geometry + GLOBAL：CT MAPE 28.684%，CP MAPE 41.062%；
- actual-geometry + ANNULAR：CT MAPE 28.235%，CP MAPE 39.968%。

这说明：

1. 先前“几何降阶不是全部主因”的结论仍成立，但几何降阶并非可以忽略；在高总距区间它具有中等量级贡献；
2. 在恢复实际径向几何之后，ANNULAR 相对 GLOBAL 的额外 CT 改善只剩约 0.45 个 MAPE 百分点；
3. 因而低阶几何与全盘平均诱导速度之间存在明显误差耦合。单独在低阶线性 twist 上观察到的 annular 改善，部分是在补偿几何低阶化造成的径向载荷偏差；
4. 即使 actual geometry + annular closure，10 deg 的 CT 仍只有约 0.009362，而 OARF 为 0.013089，仍低约 28.5%。

所以更稳妥的结论是：**径向几何降阶有中等贡献；全盘平均诱导速度也有贡献，但它们都不是剩余推力低估的唯一主导来源。**

## 方法学边界

本 annular 模型仍是独立环带的简单局部动量闭合，没有表达：

- 环带之间通过收缩尾迹和根/尖涡形成的径向耦合；
- 真实有限叶片 wake contraction；
- prescribed/free-wake Biot-Savart induced velocity；
- swirl/切向诱导速度与局部压力耦合。

因此它用于判断“一个全盘平均 vi 是否过度低阶”，而不能被称为高保真尾迹模型。

## 下一步指向

当前证据把问题进一步收敛到：简单 independent-annulus momentum 仍不足以填补约 28% 的 CT 缺口，而且低总距时还会遇到局部负载环带的理论适用性边界。

下一层最有辨识度的对象应是 **wake-coupled radial inflow**：在保持实际径向几何和独立截面数据不变的前提下，引入有文献约束的尾迹收缩/有限叶片诱导分布，检查环带之间的诱导耦合能否解释剩余载荷分布，而不是继续增加任意 CL 增益。

## 证据状态

`run_xv15_annular_momentum_diagnostic.m` 已加入仓库，可在 MATLAB 中生成正式 CSV/MAT 结果；当前连接环境不能运行用户本机 MATLAB，因此仓库内 `*_PREVIEW.csv` 为方程级独立复现，不声称 MATLAB runner 已执行通过。

建议本机执行：

```matlab
startup;
results = run_xv15_annular_momentum_diagnostic;
```
