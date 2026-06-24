# Codex Task — 清理工作区并执行南航式配平趋势验证

日期：2026-06-25

## 0. 权限、目标与禁止自行改题

本文件给出完整执行策略。Codex 负责检查代码、实现脚本、运行 MATLAB、保存证据和报告结果，不得自行重新设计配平策略、控制分配、速度区间、参数组合或验收口径。

项目长期目标：参考南航部件级机理建模路线，在 MATLAB 中建立可运行、可计算、物理自洽、可替换参数的倾转旋翼机模型；不要求严格复现 XV-15；当前最低验证标准是公开文献趋势一致、物理方向正确、数值连续、结果可解释，并支持配平、线性化、稳定性与后续控制设计。

本任务输出前必须再次对照上述目标。不得把“某个工况收敛”“所有点曲线平滑”或“全部特征值稳定”单独当作模型验证完成。

禁止：

- 修改当前已批准的物理参数；
- 放宽升降舵 ±20 deg 限幅；
- 修改模型方程、配平残差、求解器、控制分配或线性化算法；
- 使用新参数扫描来强行匹配南航曲线；
- 把南航、GTRS 或 XV-15 图线称为当前模型的定量目标；
- 遇到不稳定特征值就自动判定配平错误；
- 使用 `git clean`、`git reset --hard` 或覆盖未知工作。

当前批准参数必须保持：

```matlab
P.wing.Cm0            = -0.03;
P.wing.Cmalpha        = 0.00;
P.fuselage.Cmalpha    = 0.00;
P.htail.downwashAlpha = 0.40;
P.htail.incidence     = -2*d2r;
P.htail.CLelevator    = 2.00;
P.control.elevatorLim = [-20,20]*d2r;
```

固定翼模式必须保持 `cyclicLong=0`。转换模式只能使用仓库现有的开放环 `pitchCommand` 分配，不能另造混控策略。

---

## 1. 必须先阅读的证据

按顺序读取：

1. `AGENTS.md`
2. `CODEX_TASK.md`
3. `references/NUAA_main_paper.pdf`
4. `docs/PAPER_CODE_MAPPING.md`
5. `docs/PARAMETER_SOURCE_INVENTORY.md`
6. 当前配平、分配与可信度实现：
   - `analysis/trim_general.m`
   - `analysis/evaluate_trim_definition_point.m`
   - `analysis/diagnose_trim_credibility.m`
   - `analysis/linearize_numeric.m`
   - 与 `pitchCommand` / `airplane_longitudinal` / `conversion_longitudinal` 有关的实际文件
7. 当前未跟踪诊断脚本：
   - `analysis/issue20_trim_authority_diagnostics.m`
   - `analysis/issue23_airplane_pitch_balance_diagnostics.m`
   - `analysis/run_nuaa_trim_trend_baseline.m`

南航文章第 4 节的验模方式必须在报告中准确复述：

- 配平条件是稳态下状态导数为零、合力合矩平衡；
- 分别计算直升机模式、固定翼模式以及短舱角 15 deg、75 deg 的转换模式；
- Figure 5、Figure 6 比较各模式下操纵量和俯仰姿态随速度的变化；
- Figure 7 用固定翼配平结果与 GTRS 和 XV-15 实际配平结果比较；
- 因完整 XV-15 数据不足，文章把“趋势一致、数值接近”作为合理性证据；
- 文章随后在线性化配平点上分析稳定性导数与特征值，未要求所有模式开环稳定。

当前项目没有完整 GTRS/XV-15 数字数据，因此本任务只能完成“南航式配平趋势基线与物理合理性检查”，不得声称完成 Figure 7 的定量复现。

---

## 2. Stage 0 — 运行量与工作区状态

开始时打印：

```text
git branch --show-current
git status --short
git diff --stat
git ls-files --others --exclude-standard
```

报告：

- 当前分支和上游；
- 所有修改、未跟踪文件的归属；
- `validation/` 文件数、总大小和主要扩展名；
- 预计配平调用约 100 个粗网格点，加直升机局部双向细化和代表点线性化；
- 预计 MATLAB 总耗时。

若发现已知清单之外、无法解释的未跟踪源文件，停止，不得清理。

---

## 3. Stage 1 — 非破坏性清理当前工作区

目标是先把已完成工作保存为可追溯提交，再开始趋势任务；“清理”不等于删除证据。

### 3.1 分类并保存现有修改

检查每个 diff 后，按实际内容拆成连贯提交，不得 `git add .`。预期类别：

1. GUI 参数工作台既有修改；
2. Issue #23 固定翼纵向参数纠偏、参数目录和测试；
3. Issue #20/#23 诊断脚本及现有南航基线脚本。

Issue #23 相关内容至少包括当前实际修改中的：

- `params_nominal.m`
- `services/build_parameter_catalog.m`
- `docs/PARAMETER_SOURCE_INVENTORY.md`
- `tests/check_control_limits.m`
- `tests/check_gui_parameter_page.m`
- `tests/check_pitch_allocation.m`
- `tests/check_trim_credibility.m`
- `analysis/issue23_airplane_pitch_balance_diagnostics.m`

`app/launch_tiltrotor_app.m` 必须先核对 diff；只有确认属于此前已完成且测试通过的 GUI 工作才可提交。任何无法归属的 diff 必须停止并报告。

保留三个分析脚本，不得删除；后续允许按本文件修订 `run_nuaa_trim_trend_baseline.m` 或新增正式脚本。

### 3.2 处理 `validation/`

不得提交整个历史 `validation/`。不得删除现有内容。

- 列出目录清单和大小；
- 将 `validation/` 加入本地 `.git/info/exclude`（仅当尚未忽略），保留所有本地证据；
- 不得仅为了本任务修改仓库 `.gitignore`；
- 需要版本控制的最终报告和小型 CSV/PNG，后续复制到 `docs/validation/` 的专用目录。

### 3.3 提交与推送

对分类明确、测试已经通过的现有修改创建最少数量的语义化提交并推送到当前分支。不要创建或合并 PR。

提交后要求：

```text
git status --short
```

除被本地忽略的 `validation/` 外必须为空。若无法达到干净状态，停止，不进入趋势计算。

随后从清理后的当前 HEAD 新建并切换到：

```text
feature/nuaa-trim-trend-validation
```

推送该分支并设置上游。

---

## 4. Stage 2 — 是否具备趋势计算条件的门槛

不要重新运行完整 `run_all_checks`；它已在当前最终参数下通过。运行以下聚焦检查：

```matlab
check_trim_mode_framework
check_pitch_allocation
check_trim_credibility
```

再运行下列代表配平点：

| 模式 | betaM | V m/s | 目的 |
|---|---:|---:|---|
| helicopter_longitudinal | 0 deg | 0 | 悬停入口 |
| helicopter_longitudinal | 0 deg | 20 | 直升机前飞 |
| conversion_longitudinal | 15 deg | 35 | 低倾角转换入口 |
| conversion_longitudinal | 75 deg | 100 | 高倾角转换入口 |
| airplane_longitudinal | 90 deg | 100 | 固定翼入口 |

门槛：全部有限、收敛、可信，控制未触限，模式和分配与定义一致。若失败，停止并报告；不得修改策略或参数。

满足门槛后，明确写出：

> 当前软件已具备计算第一版南航式配平趋势基线的条件，但结果仍属于低阶概念模型趋势验证，不是 XV-15 定量验模完成。

---

## 5. Stage 3 — 固定的配平策略

实现正式脚本：

```text
analysis/run_nuaa_trim_trend_validation.m
```

可以复用现有基线脚本的通用代码，但以下工况、变量和延拓策略不得改变。

### 5.1 直升机模式 — 对应 Figure 5(a)

- `betaM = 0 deg`
- `V = 0:2.5:30 m/s`
- 模式：`helicopter_longitudinal`
- 求解：`theta, collective, cyclicLong`
- 固定：`elevator=0`，其余对称横侧向操纵为零
- 主曲线：从 0 m/s 悬停解向上连续延拓
- 反向审计：从 30 m/s 的独立标准初值解向下延拓
- 不允许把正反扫分支拼接成一条“更平滑”的曲线

已知 9 m/s 附近曾存在多解/路径依赖。额外执行：

- `V = 7.5:0.25:10.5 m/s`
- 从低速端和高速端分别延拓
- 保存两个分支；主图采用悬停连通分支，并用标记显示分支不一致区间

### 5.2 15 deg 转换模式 — 对应 Figure 6(a)

- `betaM = 15 deg`
- `V = 10:2.5:60 m/s`
- 模式：`conversion_longitudinal`
- 求解：`theta, collective, pitchCommand`
- 直接操纵由现有分配产生：
  - `cyclicLong = cos(betaM)^2 * pitchCommand`
  - `elevator = sin(betaM)^2 * pitchCommand`
- 以 35 m/s 为锚点，分别向 10 m/s 和 60 m/s 延拓
- 不改变现有分配权重和限幅

### 5.3 75 deg 转换模式 — 对应 Figure 6(b)

- `betaM = 75 deg`
- `V = 70:2.5:150 m/s`
- 模式：`conversion_longitudinal`
- 求解：`theta, collective, pitchCommand`
- 使用相同的现有 `cos^2/sin^2` 分配
- 以 100 m/s 为锚点，分别向 70 m/s 和 150 m/s 延拓

### 5.4 固定翼模式 — 对应 Figure 5(b)

- `betaM = 90 deg`
- `V = 70:2.5:150 m/s`
- 模式：`airplane_longitudinal`
- 求解：`theta, collective, elevator`
- 强制 `cyclicLong=0`
- 以已验证的 100 m/s 解为锚点，分别向 70 m/s 和 150 m/s 延拓
- 不向 70 m/s 以下外推；低速边界属于后续独立任务

### 5.5 种子与失败规则

- 每条分支只使用锚点的标准现有初值和相邻已接受点延拓；
- 不做随机、多参数或大范围初值搜索；
- 锚点失败时停止该模式；
- 中间点失败时记录失败，允许用前后相邻已接受点各重试一次；仍失败则保留缺口，不得改参数或拼接其他根。

---

## 6. Stage 4 — 输出字段与南航趋势判读

每个点至少保存：

- mode、betaM_deg、V_mps、sweep_direction、branch_id；
- theta_deg、alpha_deg；
- collective_deg、cyclicLong_deg、elevator_deg、pitchCommand；
- residualNorm、converged、finite、credibilityClass；
- Jacobian rank、condition number（仅现有接口可得时）；
- 每个操纵的限幅余量和 atLimit；
- 旋翼、机翼、机身、平尾、垂尾俯仰矩；
- 机翼 CL、CL/CLmax；
- 当前参数身份和 Git commit SHA。

原始代码符号必须原样输出。论文图中的“vertical pitch”与代码 `cyclicLong` 的符号映射必须复用 `check_article_trends` 中已经审查过的映射；若不存在明确映射，报告原始符号并停止做正负方向断言，不得猜测。

生成四张主图，布局和变量含义对应南航 Figure 5、Figure 6：

1. helicopter：collective、paper-oriented longitudinal cyclic、pitch attitude；
2. airplane：collective、elevator、pitch attitude；
3. betaM=15 deg：collective、paper-oriented longitudinal cyclic（并附直接 elevator 小量）、pitch attitude；
4. betaM=75 deg：collective、elevator（并附直接 cyclic 小量）、pitch attitude。

趋势比较依据南航正文，不要求逐点数值一致：

- helicopter：速度增加时机翼分担增强，总距总体下降；前向操纵需求增强；俯仰姿态总体向低头方向变化；
- airplane：速度增加、阻力增加，总距总体上升；动压增大后升降舵所需偏转幅值总体下降；
- betaM=15 deg：保持直升机式操纵特征，总距相对 helicopter 较小并总体下降；
- betaM=75 deg：保持固定翼式操纵特征，总距随速度/阻力总体上升，升降舵幅值总体减小。

计算并报告端点变化、Spearman 相关系数和相邻差分方向比例；这些是诊断量，不得用单一阈值自动宣称“通过”。以下情况必须标记：

- 相邻 2.5 m/s 点 `theta` 跳变超过 3 deg；
- 任一主操纵跳变超过 5 deg；
- 正反扫在同一速度的状态或控制显著不一致；
- 控制触限、可信度下降或 Jacobian 明显病态；
- 总体趋势与南航正文相反。

---

## 7. Stage 5 — 配平点出现不稳定模态时的处理

配平存在与开环动态稳定是两件事。稳态配平点可以具有右半平面特征值。南航文章明确报告：

- 直升机悬停纵向和横侧向存在右半平面根，需要控制系统改善；
- 固定翼 100 m/s 的纵向模态稳定性更好，但其表中仍出现小的正实横侧向根；
- 因此“不稳定模态”不能自动判定为配平错误，也不能为了得到全稳定结果修改参数。

对以下代表点线性化：

- helicopter：0、10、20、30 m/s；
- betaM=15 deg：10、35、60 m/s；
- betaM=75 deg：70、100、150 m/s；
- airplane：70、100、150 m/s。

每点要求：

1. 先确认配平残差和可信度合格；
2. 使用现有 `linearize_numeric`；
3. 在内存中将现有差分步长统一乘以 0.5、1、2，得到三组特征值；不得修改默认参数文件；
4. 对三组特征值做最近距离匹配，报告实部、虚部和参与状态；
5. `abs(lambda)<1e-6` 的航向/运动学中性根单独标记，不算不稳定；
6. `real(lambda)>1e-3` 标记为候选开环不稳定模态；
7. 若该正实部在三种步长下持续存在，且实部/虚部变化小于 `max(5%,1e-3)`，视为数值稳健的物理候选；
8. 若符号随步长翻转、数值剧烈漂移、配平不可信或处于分支跳变点，标记为数值可疑，不作物理结论。

最终报告必须分别回答：

- 哪些配平点开环稳定；
- 哪些存在稳健的不稳定模态；
- 这些不稳定是否与南航“直升机模式较差、固定翼模式较好但可有慢不稳定模态”的定性结论相容；
- 哪些结果因九状态低阶模型、无动态入流和无飞控而不能与论文特征值定量比较。

不要把南航具体特征值当作数值验收目标。

---

## 8. Stage 6 — 产物

时间戳输出目录：

```text
validation/nuaa_trim_trends/<timestamp>/
```

至少生成：

- `nuaa_trim_points.csv`
- `nuaa_trim_branch_comparison.csv`
- `nuaa_trim_component_moments.csv`
- `nuaa_trim_stability.csv`
- 四张主趋势 PNG
- `NUAA_TRIM_TREND_VALIDATION_REPORT.md`

报告开头和结尾都必须包含“与项目目标对照”：

- 是否保持部件级机理链；
- 是否只使用当前批准参数；
- 是否得到可计算、连续、可解释的各模式配平趋势；
- 与南航趋势一致到什么程度；
- 是否存在多解、控制余量、低速边界或不稳定模态限制；
- 为什么当前结果仍不能称为严格 XV-15/GTRS 验模。

将最终 Markdown 报告、四张 PNG 和必要的小型 CSV 复制到：

```text
docs/validation/nuaa_trim_trends/20260625/
```

不要复制 MAT、大型日志或重复中间文件。

---

## 9. Stage 7 — 测试、提交与最终状态

对新增/修改 MATLAB 文件运行 `checkcode`。运行聚焦测试，不再重复完整 `run_all_checks`，除非新增代码触及生产模型或通用配平核心；正常情况下趋势脚本不得触及这些文件。

提交到 `feature/nuaa-trim-trend-validation`：

1. 趋势脚本及必要测试；
2. 最终报告、图和小型 CSV。

推送分支，不创建或合并 PR。

最终必须报告：

- 清理前后的 Git 状态；
- 当前工作成果如何分类、提交和推送；
- readiness gate 是否通过；
- 实际配平调用次数和耗时；
- 四个模式的趋势摘要；
- 直升机 9 m/s 附近分支结果；
- 控制触限和可信度问题；
- 代表点特征值与差分步长稳健性；
- 不稳定模态是物理候选还是数值可疑；
- 与项目长期目标的最终对照；
- `git status --short` 必须为空（本地忽略的 `validation/` 除外）。
