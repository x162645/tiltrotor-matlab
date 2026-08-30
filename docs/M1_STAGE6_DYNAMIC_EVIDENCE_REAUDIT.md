# M1 Stage 6：XV-15 动态外部验证证据门槛复核

## 1. 为什么 Stage 6 先审计证据而不直接跑动态模型

本项目主线为：

`冻结模型 -> 外部验模 -> 保留失败 -> 界定可信域 -> 再进入下一层证据`

Stage 5 已经完成旋翼悬停层的 post-freeze 跨设施外部验证，但组件层悬停改善不能自动转化为整机动态模型已经具备 XV-15 验模资格。

整机动态响应同时受以下量控制：

- 飞行速度、姿态、短舱角和操纵面状态；
- 质量和重心；
- 三轴惯量及惯性积；
- 旋翼转速及 governor / engine dynamics；
- 试验环境；
- SCAS 状态；
- 实际飞行控制输入到模型控制变量的映射；
- 输入/输出坐标、符号和测量位置。

如果这些量不能与同一飞行试验记录对应，直接将 generic XV-15 参数代入低阶模型后与图中的响应曲线比较，只能称为低阶趋势比较，不能称为型号外部动态验模。

因此 Stage 6 的首要问题是：

> 当前公开证据中，是否至少存在一个动态案例达到足以冻结输入契约并进行第一性模型外部验证的 HIGH homology？

## 2. 既有 TM-86009 门槛

此前仓库已经建立：

- `results/xv15_validation_baseline/TM86009_HOMOLOGY_MATRIX.csv`；
- `results/xv15_validation_baseline/TM86009_PROGRAM_CAPABILITY_MAPPING.csv`；
- `docs/TM86009_HOMOLOGY_AUDIT.md`。

既有结论为 `BLOCKED`：

- q/elevator：MEDIUM；
- az/elevator：LOW；
- p/aileron：MEDIUM；
- beta/rudder：MEDIUM；
- cruise step plots：MEDIUM；
- hover dynamic cases：此前 PENDING。

Stage 6 重新加入 NASA TM-89428、hover identification publication 和 NASA CR-177406 的来源信息，检查是否能够提升任何案例至 HIGH。

## 3. TM-86009 / 同源 1984 ERF 论文能够关闭什么

公开的同源论文 `Identification and Verification of Frequency-Domain Models for XV-15 Tilt-Rotor Aircraft Dynamics` 给出了巡航案例的明确飞行条件：

- indicated airspeed：170 knots；
- nacelle incidence：0 deg；
- altitude：8000 ft。

并明确给出主要 bare-airframe transfer functions：

- `q / delta_e`；
- `a_z / delta_e`；
- `p / delta_a`；
- `beta_CG / delta_r`。

论文还说明：

- longitudinal closed-loop tests 中直接测量 elevator surface deflection；
- cruise lateral-directional test 为避免 SCAS rudder correlation，重复了 SCAS-off test；
- transfer-function model 后续用 flight-tape step input 驱动，与飞机时域响应比较；
- 对不稳定自由度，初值和湍流调节会使时域曲线快速分离，因此原论文自身也限制了可做的定量 step-fidelity 声明。

这使 cruise 案例在“飞行条件、输入输出变量、SCAS 处理、响应来源”方面比单纯看曲线强得多。

但是，它仍没有将当前低阶程序所需的全部同一点参数合同闭合。

## 4. 为什么 cruise 案例仍然不能升为 HIGH

### 4.1 同一试验点质量 / CG / 惯量仍未闭合

当前审计没有找到与这组 170-knot identification records 一一对应的：

- flight-test gross weight；
- CG；
- `Ixx, Iyy, Izz, Ixz`。

设计总重、一般 XV-15 重量或其他论文采用的 5897 kg 等参数不能替代该试验点记录。

对动态响应而言，这些参数直接进入惯性方程，因此不是可以忽略的背景元数据。

### 4.2 rotor RPM / governor contract 未闭合

源论文明确指出：cruise `a_z / delta_e` 时域响应是主要异常案例，并认为其原因很可能是 **unmodeled rotor rpm dynamics**。

仓库的 `TM86009_PROGRAM_CAPABILITY_MAPPING.csv` 同样记录当前程序没有 engine/governor dynamic state。

因此该通道不能因为有完整图形就升为 HIGH；相反，源论文已经给出了一个与当前程序能力缺口直接相关的 model-form warning。

故：

`CRUISE_AZ_ELEVATOR = LOW / BLOCKED`

### 4.3 atmosphere 仍只部分闭合

8000 ft 高度已明确，但与试验记录完全对应的温度、密度等仍未在当前来源合同中闭合。

不能根据标准大气自动补齐后再称为 exact XV-15 dynamic validation。

## 5. NASA TM-89428 带来的新增信息

NASA TM-89428 的研究目标明确包括：

1. documentation and evaluation of XV-15 bare-airframe dynamics；
2. comparison of aircraft and simulation responses；
3. development of a validated transfer-function description。

其书目/公开摘要还表明：

- flight tests and piloted simulation were planned and executed for four flight conditions from hover to cruise；
- hover 和 cruise 均有频域/时域 verification 内容；
- 该工作比 TM-86009 是更完整的频响识别研究记录。

这说明动态外部证据并非“没有”，而是“公开响应证据存在，但与当前第一性低阶模型逐案例同源所需参数合同不完整”。

因此 TM-89428 能提高 **source-response evidence coverage**，但不能单独把 model-input homology 升至 HIGH。

## 6. Hover 动态案例从 PENDING 改为 MEDIUM-source，但仍 BLOCKED

此前 hover 被标为 PENDING，主要因为仓库审计没有把后续来源纳入。

重新审计后可确认：

- AIAA 83-2695 / 1985 JAHS publication 真实来自 XV-15 hover flight tests；
- 使用 pilot-generated frequency sweeps；
- pitch 和 roll open-loop 低频表现为不稳定振荡；
- 其他自由度总体轻阻尼、较弱耦合；
- flight-test / simulator frequency response 在高于约 1 rad/s 时相关性优于低频；
- extracted transfer functions 还用独立 step-response flight data 做时域验证；
- lateral stick / aileron / roll-rate 等实际输入输出时历和频响比较确实存在。

因此“hover flight-response evidence exists”可以从 PENDING 提升为：

`MEDIUM_SOURCE_EVIDENCE`

但是仍不能执行本仓库的第一性动态外部验证，原因包括：

- exact hover test gross weight / CG / inertia 未闭合；
- exact rotor RPM / governor state 未闭合；
- exact atmosphere 未闭合；
- pilot stick -> XV-15 mixing / SCAS -> rotor control variables 的完整控制链未闭合到当前程序输入；
- 当前公开结果主要是图、频响和识别模型，不是可直接与本仓库统一坐标定义对齐的原始 machine-readable time histories。

所以：

`HOVER_DYNAMIC = MEDIUM homology / BLOCKED_FOR_DIRECT_FIRST_PRINCIPLES_VALIDATION`

这不是程序失败，而是证据合同不完整。

## 7. NASA CR-177406 Vol. III 的角色

公开参考文献能够确认：

`XV-15 Tilt Rotor Research Aircraft Flight Test Data Report, Volume III of V: Structural and Dynamics, NASA CR-177406, June 1985`

确实存在。

但是当前可检索来源尚不足以把 Volume III 内的具体 record、flight/run identifier、同一点 weight/CG/inertia/RPM/atmosphere 逐项提取并与 TM-89428 identification cases 建立一一映射。

因此当前证据角色只能是：

`MEDIUM_SOURCE_POTENTIAL`

不能因为报告标题叫 `Structural and Dynamics` 就推定其中一定存在当前所需的每一个 HIGH-homology 参数，也不能用一般 XV-15 参数表代替尚未检出的 case-specific values。

只有在后续真正取得并逐页审计 CR-177406 对应卷册后，才允许重新打开 HIGH gate。

## 8. Stage 6 更新后的证据矩阵

机器可读矩阵：

`results/m1_stage6_dynamic_gate/M1_STAGE6_DYNAMIC_EVIDENCE_MATRIX.csv`

当前评级：

| 案例 | Source evidence | Model homology | Gate |
|---|---|---|---|
| cruise q/elevator | MEDIUM | MEDIUM | BLOCKED |
| cruise az/elevator | MEDIUM | LOW | BLOCKED |
| cruise p/aileron | MEDIUM | MEDIUM | BLOCKED |
| cruise beta/rudder | MEDIUM | MEDIUM | BLOCKED |
| hover frequency/step response set | MEDIUM | MEDIUM | BLOCKED |
| TM-89428 multi-condition set | MEDIUM | MEDIUM | BLOCKED |
| CR-177406 Vol. III | MEDIUM source potential | LOW until case records retrieved | BLOCKED |

**没有任何一项达到 HIGH。**

因此 Stage 6 总门槛继续为：

`BLOCKED_NO_HIGH_HOMOLOGY_CASE`

## 9. 为什么现在不应该运行 XV-15 动态相关性

如果此时强行运行，必须人为决定：

- aircraft mass；
- CG；
- inertia；
- rotor RPM；
- atmosphere；
- flap setting；
- SCAS/control mixing；
- pilot-stick 到模型控制变量的增益。

这些量一旦从 generic XV-15 database 或概念参数中取值，就会把“动态验模”变成“用一组看起来合理的 XV-15-like 参数做趋势仿真”。

这类计算可以作为未来模型能力演示，但不能回答当前论文主线中的型号外部验模问题。

因此本阶段最严格、也最有研究价值的结果恰恰是：

> **动态验证软件能力基本存在，但公开证据同源性尚不足以支撑至少一个 HIGH-homology XV-15 动态外部验证案例。**

保留 BLOCKED 比制造一张漂亮的响应叠图更符合本研究的方法学主线。

## 10. 对论文结构的意义

到 Stage 6 为止，可以形成很完整的分层验证逻辑：

1. **组件悬停层**：M0 外部验证失败被保留；
2. **物理增强层**：M1 来源受约束增强，并冻结模型身份；
3. **跨设施验证层**：WADC post-freeze 证实 M1 相对改善可泛化，但绝对 CT/CP 仍不够准确；
4. **可信域层**：明确 6-11 deg、Mtip 约 0.53-0.69 内可声明什么、不能声明什么；
5. **整机动态层**：程序能够表示若干目标通道，但 HIGH-homology flight-test input contract 尚未闭合，因此不伪造动态验模。

这比“所有模块都给一条看起来很像的曲线”更能体现一篇低阶模型可信性研究的严谨性。

## 11. 后续唯一合理的动态分叉

Stage 6 之后有两个合法方向：

### A. 继续搜集原始飞行试验卷册

优先目标：取得可审计的 NASA CR-177406 Vol. I/III/appendices 或等价原始记录，寻找：

- flight/run number；
- exact weight and balance；
- inertia / configuration；
- rotor speed/governor state；
- atmospheric condition；
- control-system configuration；
- machine-readable 或可数字化输入/响应时历。

只有关闭到同一 case，才重新评级 HIGH。

### B. 若公开资料始终无法关闭

保留动态 gate = BLOCKED，并将本文研究范围明确限制在：

- 模型结构/程序能力验证；
- 悬停旋翼组件层外部验证；
- 跨设施可信域；
- 动态层证据可获得性与同源性审计。

不得为了“让论文看起来完整”而用 generic XV-15 参数补齐缺失试飞条件。

## 12. 来源

- Tischler, Leung, Dugan, `Identification and Verification of Frequency-Domain Models for XV-15 Tilt-Rotor Aircraft Dynamics`, NASA TM-86009 / 10th European Rotorcraft Forum Paper 75, 1984.
- Tischler, `Frequency-Response Identification of XV-15 Tilt-Rotor Aircraft Dynamics`, NASA TM-89428, 1987.
- Tischler, Leung, Dugan, `Frequency-Domain Identification of XV-15 Tilt-Rotor Aircraft Dynamics in Hovering Flight`, Journal of the American Helicopter Society, 1985 / AIAA 83-2695 lineage.
- Arrington, Kumpel, Marr, McEntire, `XV-15 Tilt Rotor Research Aircraft Flight Test Data Report`, NASA CR-177406, Vol. III: Structural and Dynamics, June 1985.

PDF access note：NASA TM-89428 的 NTRS 直接 PDF 在本次网页工具中返回 403；可访问的 ERF 版同源 1984 paper 已成功解析，但 screenshot 后端随后出现 cache-miss，未伪称完成页面视觉核验。Stage 6 的 HIGH gate 因此没有依据无法逐页核验的内容被提升。
