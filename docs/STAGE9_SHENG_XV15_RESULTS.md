# Stage 9：Sheng 公开公式参考模型与 XV-15 悬停误差分解

## 1. 研究问题

本阶段不重新审计 Sheng 2022，也不修改 frozen M0/M1。研究问题是：在固定 XV-15 OARF Run 15、0.75R collective 6--11 deg 工况下，Sheng 公开公式可复现旋翼链的误差主要是幅值尺度偏差，还是曲线形状/趋势偏差；以及 frozen M1 的来源受约束物理增强改变了什么。

S0 的正式身份为：

`S0_XV15_MAPPED_PUBLIC_FORMULA_REFERENCE`

其核心代码是独立的 `NUAA_PUBLIC_FORMULA_REFERENCE`，但使用与 M0 相同的 XV-15 原始金属桨低阶几何/运行点映射。它不是 Sheng 作者原程序，也不说明 Sheng 作者实际使用了这些 XV-15 映射参数。

S0-N 是后处理尺度/形状诊断，不是模型：

`DIAGNOSTIC_ONLY_NOT_MODEL_NOT_VALIDATION_SCORE`

## 2. 正式 MATLAB 证据

- GitHub Actions run: `33238268565`
- executed head: `e22b4efcce0f90578996be35220cfefe33a9335b`
- MATLAB: R2021a
- artifact: `9710584310`
- artifact SHA-256: `450e981a13f89cafe6ca29fbbc45fbfa0136606d740074a6570f0fe5aecb33c3`
- status: SUCCESS

全部 S0、M0、M1 固定窗口点均保留，6/6 点得到支持结果。

## 3. 原始误差

|模型|CT MAPE|CP MAPE|FM MAPE|
|---|---:|---:|---:|
|S0 XV-15-mapped public formula|56.4224%|62.6130%|23.0180%|
|frozen M0|56.4224%|62.6130%|23.0180%|
|frozen M1_HOLDOUT_V1|32.7269%|45.8943%|7.5918%|

M1 的误差数值与此前 frozen M1 证据一致；本阶段没有重新选择 Corrigan 参数或任何物理参数。

## 4. 关键结果 A：S0 与 M0 在本悬停窗口等价

逐点比较表明：

- CT 最大绝对差 = 0；
- CP 最大绝对差 = 0；
- FM 最大绝对差约 `1.0e-15`。

因此，在零平面来流、对称悬停、相同低阶参数和几何映射的这个特定问题上，独立实现的 Sheng 公开公式参考旋翼与 frozen M0 数值上退化为同一结果。

这不意味着两套程序在前飞、转换、非对称运动或完整整机模型上等价。它只说明：M0 的悬停大误差不能通过“把 M0 改回 Sheng 公开式”消除，因为在这个工况下两者已经等价。

## 5. 关键结果 B：CT/CP 的“趋势一致”性质不同

### CT

- raw MAPE: `56.4224%`
- Pearson: `0.9996509`
- Spearman: `1.0`
- least-squares scale `k* = 2.1707331`
- scaled diagnostic MAPE: `11.7868%`
- local external/model ratio mean: `2.34582`
- local ratio CV: `0.16744`
- local ratios across 6--11 deg: approximately `2.981, 2.603, 2.353, 2.171, 2.046, 1.920`

因此 CT 的单调趋势高度一致，但误差不是一个恒定比例。随着 collective 增大，所需局部比例系统性下降。把 CT 描述成“只差一个放大倍数”过强；更准确的表述是：**模型抓住了主要单调趋势，但幅值误差同时带有明显的工况依赖形状分量。**

### CP

- raw MAPE: `62.6130%`
- Pearson: `0.9998557`
- Spearman: `1.0`
- least-squares scale `k* = 2.6234134`
- scaled diagnostic MAPE: `3.77162%`
- local external/model ratio mean: `2.67968`
- local ratio CV: `0.04725`
- local ratios across 6--11 deg: approximately `2.859, 2.782, 2.703, 2.628, 2.586, 2.519`

CP 明显更接近“稳定幅值尺度偏差 + 很小的形状误差”。这为“趋势结构被低阶模型捕获，但绝对功率尺度严重不足”的论文结论提供了定量证据。

注意：`k*` 是利用当前 OARF 数据事后计算的目标依赖量，因此不能作为模型修正、验证成绩或可泛化校准参数。

## 6. 关键结果 C：FM 不支持“趋势完全一致”

S0/M0 的 FM：

- raw MAPE: `23.0180%`
- Pearson: `-0.64096`
- Spearman: `-0.6`
- scale `k* = 1.26511`
- scaled diagnostic MAPE: `14.4518%`
- local ratio CV: `0.20546`

XV-15 试验 FM 在本窗口内总体接近平坦并在高 collective 有下降，而 S0/M0 FM 从约 0.436 持续上升至约 0.723。因此即使 CT 与 CP 分别具有很强单调相关性，也不能推广成“性能趋势完全一致”。

frozen M1 将 FM MAPE 降至 `7.5918%`，但其 FM Pearson 仍为负（约 `-0.557`），逐点误差从低 collective 负误差跨越到高 collective 正误差。因此 M1 的 FM 绝对误差改善不等于 FM 曲线形状已经正确。

## 7. 对三条论文路线的直接含义

### 路线 1：放大/归一化证明趋势

可保留，但必须写成“幅值误差--形状误差分离”，不能写成“乘一个系数后模型被验证”。

最强证据是 CP；CT 是部分支持；FM 明确不支持“完全一致”。

### 路线 2：Sheng 误差分析

本阶段给出一个新的定量结果：至少在悬停旋翼层，S0 与 M0 完全等价，因此大误差主要不是“我们的实现偏离 Sheng 公开旋翼公式”造成的，而是该低阶公式/闭合和参数表达层级本身对 XV-15 绝对性能的能力边界。后续应继续利用既有审计区分真正错误、比较定义不一致和可接受简化，而不是笼统声称 Sheng 错误。

### 路线 3：优化模型并加入短舱动态

M1 已经证明来源受约束的真实径向几何、完整 C81 和 generic rotational stall-delay 能显著降低 CT/CP/FM 绝对误差，并通过 WADC post-freeze 跨设施验证保持改善方向。

短舱部分现有 D13 已有角度/角速度状态、二阶执行器、执行器反作用、角度相关 CG/惯量和倾转速率陀螺力矩，但其正式边界仍是规定短舱运动到刚体的单向耦合。真正的新模型贡献应定义为 M2 双向短舱机械耦合，而不是重复“加入一个短舱角状态”。

## 8. 当前下一步

Stage 10 应使用既有 NUAA root-cause audit 的结论，建立分析专用的 S1 comparison contract：

1. 15 deg 论文比较采用严格 helicopter manipulation，而不是生产模型 cos^2/sin^2 混合分配；
2. 75 deg 论文比较采用 fixed-wing control definition，而不是混合 conversion allocation；
3. 不修改 production allocation；
4. 量化比较定义修正本身对 trim curves 的影响；
5. 只有存在可靠外部数字化目标的数据通道才计算外部误差，不凭肉眼评分。

Stage 10 之后再冻结 S1/S2 对照定义，并启动 M2 双向短舱力学的来源/方程合同。
