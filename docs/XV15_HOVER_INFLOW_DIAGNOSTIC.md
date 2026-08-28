# XV-15 纯悬停入流形式诊断

## 1. 研究问题

在截面气动参数来源和径向 C81 标量化已经逐层检查后，当前 XV-15 原始金属桨悬停计算仍明显低估推力。于是本轮只检查一个模型形式：纯悬停下的诱导速度方位分布。

当前 production 路径采用 NUAA Eq. (12) 一阶谐波形式：

\[
v_i(r,\psi)=\bar v_i\left(1+\cos\psi\frac{r}{R}\right).
\]

本轮方程级复现将其与均匀悬停入流

\[
v_i(r,\psi)=\bar v_i
\]

直接比较。除这一项外保持不变：

- PR #67 的 XV-15 悬停几何映射；
- 四段径向、局部 Mach 的 NASA C81 截面查询；
- 第一谐波挥舞求解；
- 同一动量闭合与诱导速度迭代；
- 同一 OARF Run 15 工况；
- 不使用 OARF CT/CP/FM 识别任何参数。

## 2. 结果

共同区间仍为 \(\theta_{75}=6^\circ\) 到 \(11^\circ\)。

| 入流形式 | CT MAPE | CP MAPE | FM MAPE |
|---|---:|---:|---:|
| Eq. (12) 一阶方位谐波 | 47.005114% | 50.979548% | 20.904980% |
| 均匀悬停入流 | 47.005114% | 50.979548% | 20.904981% |

两者最大相对差：

\[
\max\frac{|\Delta C_T|}{C_T}\approx1.45\times10^{-11},
\]

\[
\max\frac{|\Delta C_P|}{C_P}\approx1.89\times10^{-9}.
\]

因此在当前纯悬停诊断中，两种入流形式对积分推力、功率和 FM 实质上等价。

## 3. 为什么会几乎完全相同

当前第一谐波挥舞写为

\[
\beta=\beta_0+\beta_{1c}\cos\psi+\beta_{1s}\sin\psi.
\]

在当前左旋翼符号约定下，其一阶拍振速度中的余弦项可写成与 \(-\Omega\beta_{1s}\cos\psi\) 等价的形式。叶素法向速度中同时存在

\[
U_P=v_i-\dot\beta r.
\]

因此 Eq. (12) 的余弦入流谐波和挥舞速度项合并后，其余弦系数与

\[
\frac{\bar v_i}{R}+\Omega\beta_{1s}
\]

成正比。

方程级复现显示，当前挥舞解在 6--11° 范围内始终满足

\[
\boxed{\beta_{1s}\approx-\frac{\bar v_i}{\Omega R}}.
\]

例如 10° 点：

\[
\lambda_i=\frac{\bar v_i}{\Omega R}=0.0623630849,
\]

\[
\beta_{1s}=-0.0623663068,
\]

所以

\[
\beta_{1s}+\lambda_i\approx-3.22\times10^{-6}.
\]

这意味着 Eq. (12) 人为引入的 \(\cos\psi\) 入流变化，几乎被当前第一谐波挥舞所产生的 \(-\dot\beta r\) 项抵消。最终叶素看到的有效入流角和积分载荷因此与均匀入流几乎相同。

## 4. 结论

本轮可以较强地排除一个候选主因：

\[
\boxed{\text{当前 Eq. (12) 一阶方位非均匀入流不是 XV-15 纯悬停 CT 缺口的主要来源。}}
\]

这不意味着 Eq. (12) 在前飞、转换飞行或其他状态下无影响；结论仅限于当前纯悬停、当前第一谐波挥舞和当前符号/模型结构。

同时，这一结果也说明不应仅通过“换成均匀入流”来人为增加推力，因为在当前方程结构下它并不会产生这种效果。

## 5. 下一层模型形式

目前已经依次排除了：

1. 数值离散是主要误差源；
2. 弦长/扭转标量等效是主要推力误差源；
3. generic 截面参数是全部误差来源；
4. C81 径向/Mach 信息压成单组参数是主要剩余推力误差源；
5. Eq. (12) 一阶悬停方位入流是主要剩余推力误差源。

下一层应转向当前二维叶素气动无法表达、但可能直接增加旋转桨叶有效升力的模型形式，优先检查：

- 旋转三维效应；
- 失速延迟/旋转升力增强；
- 其次再检查挥舞-载荷耦合低阶化本身。

叶尖损失会降低局部载荷，因此不能把它作为解释“当前推力偏低”的第一候选修正；它可以在后续完整性检查中加入，但不应为了补足 CT 而使用。

## 6. 可复现文件与证据状态

新增：

- `analysis/run_xv15_hover_inflow_cancellation_diagnostic.m`
- `results/xv15_section_aero_validation/XV15_HOVER_INFLOW_EQUATION_REPLICA_PREVIEW.csv`
- `results/xv15_section_aero_validation/XV15_HOVER_INFLOW_METRICS_PREVIEW.csv`

MATLAB runner 使用现有 Eq. (12) 诊断镜像直接输出

\[
\beta_{1s}+\bar v_i/(\Omega R)
\]

及其归一化残差，用于在本机验证上述结构抵消关系。

当前连接环境仍未实际调用项目本机 MATLAB，所以这里的 Eq. (12) 与均匀入流直接比较仍属于方程级复现 preview。正式本机运行建议：

```matlab
startup;
run_xv15_spanwise_c81_diagnostic;
results = run_xv15_hover_inflow_cancellation_diagnostic;
```

在正式 MATLAB 输出产生前，不声称 MATLAB 检查已通过，也不声称完成 XV-15 型号级验证。
