# XV-15 径向 C81 截面气动诊断

## 1. 研究问题

PR #68 已将 NASA XV-15 C81 参考气动表约化为当前通用低阶模型能够读取的一组标量参数：

\[
\alpha_{0L},\quad a,\quad C_{L\max},\quad C_{D0},\quad k_D.
\]

本诊断保持 PR #67 的 XV-15 悬停几何映射、OARF Run 15 工况、诱导速度迭代、NUAA Eq. (12) 入流、第一谐波挥舞和叶素积分不变，只解除一项低阶化：

\[
\text{一组标量截面气动}
\rightarrow
\text{NASA 四个径向 C81 区段 + 局部 Mach 查询}.
\]

因此本轮回答：**把 C81 的径向/Mach 信息压成一组标量，是否是当前外部验模剩余误差的主要来源？** OARF 的 CT/CP/FM 仍只用于最终比较，不参与参数识别。

## 2. 证据链纠正

此前提交的 `XV15_SPANWISE_C81_EQUATION_REPLICA_PREVIEW.csv` 与当前 MATLAB 诊断镜像 `xv15_hover_bemt_section_diagnostic.m + xv15_c81_section_lookup.m` 不一致。重新逐项复核后，generic 与 scalar-C81 两条路径能够精确复现 PR #67/#68 的既有数值，而旧 spanwise-C81 preview 不能由当前镜像得到，因此旧 preview 不能继续作为误差归因依据。

本文件及对应 preview 已改为与当前诊断镜像一致的方程级复现结果。正式 MATLAB 运行仍应作为最终证据。

## 3. 当前一致的方程级复现结果

共同物理收敛区间仍为 \(\theta_{75}=6^\circ\) 到 \(11^\circ\)：

| 截面方案 | CT MAPE | CP MAPE | FM MAPE |
|---|---:|---:|---:|
| 通用默认参数 | 56.42% | 62.61% | 23.02% |
| C81 单组低阶参数 | **42.87%** | 51.12% | **12.22%** |
| C81 四段径向 + 局部 Mach | 47.01% | **50.98%** | 20.90% |

10° 点：

| | 试验 | C81 单组低阶参数 | C81 四段径向 + 局部 Mach |
|---|---:|---:|---:|
| CT | 0.013089 | 0.008220 | 0.007779 |
| CP | 0.001358 | 0.000700 | 0.000675 |
| FM | 0.7797 | 0.7530 | 0.7188 |

## 4. 结论

### 4.1 推力

恢复四段径向 C81 和局部 Mach 后，CT MAPE 从标量 C81 的 42.87% 变为 47.01%，没有向试验明显靠近。

因此可以保留此前对推力的核心判断：

\[
\boxed{\text{把径向/Mach C81 压成一组标量，不是当前 CT 缺口的主因。}}
\]

### 4.2 功率

纠正证据链后，不能再声称完整 C81 将 CP MAPE 从 51.12% 大幅改善到约 28%。当前一致镜像给出 50.98%，与标量 C81 几乎相同。

因此目前能够支持的更谨慎结论是：

\[
\boxed{\text{当前 C81 标量化本身也不是 CP 剩余误差的主要来源。}}
\]

旧 preview 中关于“完整 C81 显著修正功率”的结论已撤销。

### 4.3 FM

完整径向 C81 下 FM MAPE 为约 20.90%，仍不应单独用 FM 判断模型验证质量。CT 和 CP 必须独立检查。

## 5. 下一层：悬停入流形式

当前 production 悬停仍使用

\[
v_i(r,\psi)=\bar v_i\left(1+\cos\psi\frac{r}{R}\right).
\]

因此下一层只检查这一项：保持完整 C81、几何、挥舞和动量闭合不变，比较 Eq. (12) 一阶方位谐波入流与均匀悬停入流。

方程级复现进一步发现一个重要结构关系：在当前第一谐波挥舞模型中，悬停解满足近似

\[
\beta_{1s}\approx-\frac{\bar v_i}{\Omega R}.
\]

而当前叶素法中的法向速度为

\[
U_P=\bar v_i\left(1+\cos\psi\frac rR\right)-\dot\beta r.
\]

对左旋翼当前符号约定，\(\beta_{1s}\) 项会几乎完全抵消 Eq. (12) 的 \(\cos\psi\) 入流谐波。因此 Eq. (12) 与均匀入流在纯悬停下可能给出几乎相同的有效迎角与载荷。

该结论已单独整理到 `docs/XV15_HOVER_INFLOW_DIAGNOSTIC.md` 和对应 preview CSV 中。

## 6. 证据状态

正式 MATLAB 证据仍需本机执行：

```matlab
startup;
check_xv15_spanwise_c81_diagnostic;
results = run_xv15_spanwise_c81_diagnostic;
```

在 MATLAB 结果产生前，只称为“方程级复现诊断”，不声称 MATLAB 检查已经通过，也不声称完成 XV-15 型号级验证。
