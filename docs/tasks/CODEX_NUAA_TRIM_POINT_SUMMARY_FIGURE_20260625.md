# Codex Task — 用 MATLAB 整理配平点总览图与干净数据

日期：2026-06-25

## 目标

基于已经完成并提交的 NUAA 式配平趋势结果，生成一张适合直接查看、汇报和后续对比的 MATLAB 配平点总览图，同时输出整理后的主配平点数据。

本任务只做数据整理和绘图，不重新计算配平、不调参、不修改模型、配平器、分配、限幅、线性化或测试。

在分支：

```text
feature/nuaa-trim-trend-validation
```

上工作。

## 数据源

优先使用本地已保留的完整原始输出：

```text
validation/nuaa_trim_trends/20260625_091852/nuaa_trim_points.csv
validation/nuaa_trim_trends/20260625_091852/nuaa_stability_map.csv
```

若原始目录不存在，使用已提交文件：

```text
docs/validation/nuaa_trim_trends/20260625/nuaa_trim_points.csv
docs/validation/nuaa_trim_trends/20260625/nuaa_stability_map.csv
```

运行前检查数据完整性：

- 主趋势可信点总数应为 100；
- helicopter: 13 点；
- conversion betaM=15 deg: 21 点；
- conversion betaM=75 deg: 33 点；
- airplane betaM=90 deg: 33 点；
- 所有纳入点满足 `isPrimary==1`、`converged==1`、`finite==1`、`credibilityClass=='PASS'`、`atLimit==0`。

若计数不符，停止并报告，不要自行补点或重跑配平。

## 新增 MATLAB 脚本

新增：

```text
analysis/plot_nuaa_trim_point_summary.m
```

脚本应：

1. 读取上述 CSV；
2. 过滤 100 个主趋势可信点；
3. 按 `mode + betaM_deg + V_mps` 与稳定性表连接；
4. 生成整理后的数据表；
5. 生成一张总览 PNG 和一份 PDF；
6. 不依赖 GUI，不弹出对话框，全部使用 `Visible='off'`。

## 主图设计

文件名：

```text
NUAA_TRIM_POINT_OVERVIEW.png
NUAA_TRIM_POINT_OVERVIEW.pdf
```

推荐尺寸：横向 16:10 或接近 A3 横版，PNG 300 dpi。

使用：

```matlab
tiledlayout(4,4,'TileSpacing','compact','Padding','compact')
```

四列依次为：

1. 直升机模式 `betaM=0 deg`
2. 转换模式 `betaM=15 deg`
3. 转换模式 `betaM=75 deg`
4. 固定翼模式 `betaM=90 deg`

前三行画曲线，第四行放每个模式的整理摘要文本。

### 第一行：总距

- 横轴：前飞速度 `V (m/s)`
- 纵轴：总距 `collective (deg)`
- 全部主配平点用线加标记连接。

### 第二行：纵向操纵

- 直升机模式：`paperCyclic_deg`
- 15 deg 转换：同时画 `paperCyclic_deg` 和 `elevator_deg`
- 75 deg 转换：同时画 `elevator_deg` 和 `cyclicLong_deg`
- 固定翼模式：`elevator_deg`
- 所有量单位均为 deg；不要使用双 y 轴。

### 第三行：俯仰姿态

- 画 `theta_deg`
- 横轴统一为 `V (m/s)`
- 纵轴为 `俯仰姿态角 (deg)`

### 稳定性标记

将 `openLoopCandidate==1` 的点在前三行曲线上叠加空心菱形或空心圆标记；无候选正根的点保留实心常规标记。

图例中明确写：

```text
开环候选不稳定点
无候选正根点
```

不要把静态配平存在与开环稳定混为一谈。

### 第四行：模式摘要

每列用 `axis off` + `text` 写出：

- 速度范围；
- 点数；
- 总距端点变化；
- 纵向主操纵端点变化；
- 俯仰姿态端点变化；
- 最大配平残差；
- 最小控制余量；
- 候选不稳定点数/总点数；
- 主导正根最大值与最短增长时间（若存在）。

图底部添加统一说明：

```text
当前结果为低阶部件机理模型的配平趋势与开环稳定性基线，非 XV-15/GTRS 定量验模。
```

## 整理后的数据

输出：

```text
NUAA_TRIM_POINT_CLEAN.csv
NUAA_TRIM_POINT_SUMMARY.csv
```

### `NUAA_TRIM_POINT_CLEAN.csv`

100 行，按以下顺序排序：

```text
betaM_deg, V_mps
```

至少包含：

```text
mode_cn
mode
betaM_deg
V_mps
theta_deg
collective_deg
cyclicLong_deg
paperCyclic_deg
elevator_deg
pitchCommand
residualNorm
jacobianRank
jacobianConditionNumber
collectiveMargin_deg
cyclicLongMargin_deg
elevatorMargin_deg
max_real_full
max_real_longitudinal
max_real_lateral
openLoopCandidate
tau_growth_s
git_sha
```

`mode_cn` 映射：

```text
helicopter_longitudinal + 0   -> 直升机模式
conversion_longitudinal + 15  -> 转换模式 15°
conversion_longitudinal + 75  -> 转换模式 75°
airplane_longitudinal + 90    -> 固定翼模式
```

### `NUAA_TRIM_POINT_SUMMARY.csv`

4 行，每种模式一行，至少包含：

```text
mode_cn
betaM_deg
V_min
V_max
point_count
collective_start_deg
collective_end_deg
collective_change_deg
primary_control_name
primary_control_start_deg
primary_control_end_deg
primary_control_change_deg
theta_start_deg
theta_end_deg
theta_change_deg
max_residual_norm
minimum_control_margin_deg
unstable_point_count
unstable_fraction
max_positive_real
minimum_growth_time_s
```

主纵向操纵定义：

- 直升机模式：`paperCyclic_deg`
- 转换模式 15°：`paperCyclic_deg`
- 转换模式 75°：`elevator_deg`
- 固定翼模式：`elevator_deg`

## 中文和版式

- 图题、坐标、图例和摘要全部中文；
- 字体优先 `Microsoft YaHei`，不存在时使用 MATLAB 默认字体；
- 标题：`倾转旋翼机配平点趋势总览`；
- 副标题包含 Git commit 和数据日期；
- 网格线适度，不要过密；
- 线宽、标记大小和字号应适合 300 dpi 导出；
- 不使用 `yyaxis`；
- 不显示本地绝对路径在图中。

## 输出位置

本地完整输出：

```text
validation/nuaa_trim_trends/20260625_091852/summary_figure/
```

提交交付物：

```text
docs/validation/nuaa_trim_trends/20260625/summary_figure/
```

提交目录只包括：

```text
NUAA_TRIM_POINT_OVERVIEW.png
NUAA_TRIM_POINT_OVERVIEW.pdf
NUAA_TRIM_POINT_CLEAN.csv
NUAA_TRIM_POINT_SUMMARY.csv
```

不要提交 MAT 文件、临时日志或重复中间图。

## 验证

运行：

```matlab
plot_nuaa_trim_point_summary
```

并检查：

- 100 行主点全部进入 clean CSV；
- 四种模式计数正确；
- 图中速度点无缺失；
- 稳定性标记数量与 stability map 一致；
- PNG/PDF 均成功生成且非空；
- CSV 无 NaN/Inf，允许稳定点的 `tau_growth_s` 为空或 NaN；
- 不重新运行配平或线性化；
- `checkcode analysis/plot_nuaa_trim_point_summary.m` 无严重问题。

## Git

当前工作区应先为干净状态。只提交：

- `analysis/plot_nuaa_trim_point_summary.m`
- 四个交付文件

提交信息建议：

```text
analysis: add consolidated trim-point summary figure
```

推送到：

```text
origin/feature/nuaa-trim-trend-validation
```

不创建 PR。

最终报告：

- 使用的数据源；
- 主点计数；
- 图和 CSV 路径；
- 是否发现缺失点或连接失败；
- MATLAB 运行状态；
- Git 提交 SHA；
- `git status --short`。
