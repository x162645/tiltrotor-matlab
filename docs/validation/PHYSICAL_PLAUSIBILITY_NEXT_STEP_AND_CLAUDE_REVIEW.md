# 验模推进止损说明、下一步交付物与 Claude 独立复核任务

## 1. 本文件的用途

本文件不是新的验模框架，也不用于再次重写“证据等级”“可信度支柱”或“分层验证体系”。

当前项目目标已经冻结：

> 建立可运行、可配平、可线性化的通用低阶部件级倾转旋翼机模型，用于机理分析和相对趋势研究；不以 XV-15 定量性能复现或型号级预测为目标。

此前多轮讨论中，验模方向已基本明确。当前真正阻碍推进的不是缺少方法论，而是反复用更完整的框架文档替代可独立核验的具体交付物。

因此，本文件只规定两件事：

1. 独立核验 PR #59 中关于 NASA TM-86854 的 `0.75R` 桨距定义及当前代码桨距映射；
2. 在核验完成前，唯一优先的工程交付为“物理合理性检查表”，不得继续扩展新框架或提前修求解器。

---

## 2. 为什么必须停止继续写验模框架

已经出现过多轮性质相同的输出：

- L0–L5 证据等级体系；
- 可信度分析的多支柱讨论；
- 六层验模框架；
- 进一步的主张—证据矩阵建议。

这些内容方向未必错误，但继续增加方法论文件不会自然产生新的可核验证据。之后的进展只接受以下形式：

- 可复现脚本；
- 固定字段 CSV；
- 明确数值；
- 异常点及其来源；
- 第三方可以根据仓库和原始文献独立复核的结论。

不得再把“又写了一份更完整的验模说明”视为项目进展。

---

## 3. PR #59 中必须独立复核的关键结论

PR #59 提出：

- NASA TM-86854 中 `COLL` 定义为 `0.75R` 处桨距；
- 当前 MATLAB 模型的 `collective` 是叠加在线性 `-6 deg` 扭转上的命令量；
- 当前模型在 `0.75R` 处的局部桨距可写成近似关系：

```text
pitch_075R = theta_cmd - 4.1707317 deg
```

- 因此 NASA 曲线横轴与当前代码输入不能按相同数字直接逐点比较。

这组结论具有重要解释力，但不能因为它能解释旧异常就直接采信。必须由独立审阅者同时核对：

1. NASA TM-86854 原文中 `COLL` 的定义；
2. NASA 图 25 使用的具体旋翼构型、扭转、桨距测量与作动器关系；
3. 当前 `params_nominal.m` 中 `rootCut` 与 `twistTip`；
4. `model/rotor_model_bemt.m` 中局部桨距表达式；
5. `4.1707317 deg` 是否严格由已提交公式和参数计算得到；
6. 该换算是否只是参考站位换算，而不是对不同旋翼构型进行同构映射；
7. PR #59 是否有把“参考角不一致”“构型不一致”“求解器失败”和“负推力分支缺失”混为同一结论。

独立复核不得只阅读 PR 描述或审计报告摘要，必须直接查看原文、代码和 CSV。

---

## 4. 当前唯一优先工程任务：物理合理性检查表

在上述独立复核完成前：

- 不实施正推力括区求解器修复；
- 不建立 XV-15/ATB 同构参数模型；
- 不开展负推力或风车分支开发；
- 不新建验模方法论框架；
- 不重写论文整章。

只完成一个可在短周期内独立核验的交付物：

> 导出既有代表工况的部件级和整机关键物理量，形成固定字段 CSV，并标记正常、异常和无法判定项。

### 4.1 固定代表工况

优先复用仓库中已经存在、已经用于配平或线性化的代表工况，不新增大范围扫掠。至少包括：

- 直升机模式代表点；
- 低转换角代表点；
- 中转换角代表点；
- 75 deg 困难工况中的一个失败点和一个成功点；
- 飞机模式代表点；
- 十三状态模型的对称短舱与差动短舱代表点。

具体速度和短舱角必须引用仓库当前已提交的正式案例，不能凭空新造。

### 4.2 固定输出字段

交付 CSV 至少包含：

```text
case_id
model_variant
state_dimension
speed_mps
nacelle_angle_deg
trim_status
credibility_status
trim_residual_norm
collective_deg
collective_pitch_075R_deg
cyclic_long_deg
elevator_deg
rotor_thrust_left_N
rotor_thrust_right_N
rotor_torque_left_Nm
rotor_torque_right_Nm
rotor_induced_velocity_left_mps
rotor_induced_velocity_right_mps
rotor_power_total_W
rotor_CT_left
rotor_CT_right
rotor_disk_loading_left_Pa
rotor_disk_loading_right_Pa
blade_alpha_min_deg
blade_alpha_max_deg
blade_mach_max
wing_force_norm_N
wing_moment_norm_Nm
htail_force_norm_N
htail_moment_norm_Nm
control_margin_min
finite_flag
real_valued_flag
range_status
range_basis
evidence_source
review_status
review_note
```

### 4.3 只允许三种审阅结论

每一项只允许标记：

- `NORMAL_WITH_STATED_BASIS`
- `ANOMALOUS_REQUIRES_FOLLOWUP`
- `INSUFFICIENT_BASIS`

不得用长篇文字把异常重新解释成正常，也不得在没有公开范围或工程依据时自行发明合理区间。

### 4.4 完成判据

该任务完成只需要满足：

1. CSV 由可复现脚本生成；
2. 所有数值可追溯到具体案例和代码路径；
3. 不修改正式物理模型和默认参数；
4. 不隐藏失败点；
5. 输出明确说明哪些量正常、哪些异常、哪些缺少判断依据；
6. 不附带新的验模框架长文。

---

## 5. 公开核查入口

### 5.1 PR #59

- PR：<https://github.com/x162645/tiltrotor-matlab/pull/59>
- Commit：`65e459504dd473f6dcf18326028f3a8a7991c55a`

### 5.2 PR #59 关键文件

- 审计报告：<https://github.com/x162645/tiltrotor-matlab/blob/65e459504dd473f6dcf18326028f3a8a7991c55a/docs/low_collective_quick_audit/LOW_COLLECTIVE_QUICK_AUDIT.md>
- 定义映射：<https://github.com/x162645/tiltrotor-matlab/blob/65e459504dd473f6dcf18326028f3a8a7991c55a/docs/low_collective_quick_audit/LOW_COLLECTIVE_DEFINITION_MAPPING.csv>
- 四点诊断：<https://github.com/x162645/tiltrotor-matlab/blob/65e459504dd473f6dcf18326028f3a8a7991c55a/docs/low_collective_quick_audit/LOW_COLLECTIVE_POINT_DIAGNOSTICS.csv>
- 8 deg 残差：<https://github.com/x162645/tiltrotor-matlab/blob/65e459504dd473f6dcf18326028f3a8a7991c55a/docs/low_collective_quick_audit/LOW_COLLECTIVE_RESIDUAL_AT_8DEG.csv>
- 种子测试：<https://github.com/x162645/tiltrotor-matlab/blob/65e459504dd473f6dcf18326028f3a8a7991c55a/docs/low_collective_quick_audit/LOW_COLLECTIVE_SEED_TESTS.csv>
- 审计脚本：<https://github.com/x162645/tiltrotor-matlab/blob/65e459504dd473f6dcf18326028f3a8a7991c55a/analysis/low_collective_quick_audit.m>
- 正式旋翼模型：<https://github.com/x162645/tiltrotor-matlab/blob/65e459504dd473f6dcf18326028f3a8a7991c55a/model/rotor_model_bemt.m>
- 参数文件：<https://github.com/x162645/tiltrotor-matlab/blob/65e459504dd473f6dcf18326028f3a8a7991c55a/params_nominal.m>

### 5.3 NASA 原始资料

- NASA NTRS：<https://ntrs.nasa.gov/citations/19870014976>

---

## 6. Claude 独立复核任务书

以下内容可直接复制给 Claude：

```text
请对 GitHub 仓库 `x162645/tiltrotor-matlab` 的 PR #59 做一次独立事实核查。

项目目标必须保持：这是一个用于通用低阶机理分析和相对趋势研究的倾转旋翼机部件级模型，不以 XV-15 定量复现或型号级预测为目标。你的任务不是重新设计一套验模框架，也不是评价模型是否足以代表 XV-15，而是独立核实 PR #59 的具体事实陈述是否成立。

公开入口：

1. PR #59
https://github.com/x162645/tiltrotor-matlab/pull/59

2. PR #59 精确提交
65e459504dd473f6dcf18326028f3a8a7991c55a

3. 审计报告
https://github.com/x162645/tiltrotor-matlab/blob/65e459504dd473f6dcf18326028f3a8a7991c55a/docs/low_collective_quick_audit/LOW_COLLECTIVE_QUICK_AUDIT.md

4. 定义映射 CSV
https://github.com/x162645/tiltrotor-matlab/blob/65e459504dd473f6dcf18326028f3a8a7991c55a/docs/low_collective_quick_audit/LOW_COLLECTIVE_DEFINITION_MAPPING.csv

5. 四点诊断 CSV
https://github.com/x162645/tiltrotor-matlab/blob/65e459504dd473f6dcf18326028f3a8a7991c55a/docs/low_collective_quick_audit/LOW_COLLECTIVE_POINT_DIAGNOSTICS.csv

6. 8°残差 CSV
https://github.com/x162645/tiltrotor-matlab/blob/65e459504dd473f6dcf18326028f3a8a7991c55a/docs/low_collective_quick_audit/LOW_COLLECTIVE_RESIDUAL_AT_8DEG.csv

7. 种子测试 CSV
https://github.com/x162645/tiltrotor-matlab/blob/65e459504dd473f6dcf18326028f3a8a7991c55a/docs/low_collective_quick_audit/LOW_COLLECTIVE_SEED_TESTS.csv

8. 审计脚本
https://github.com/x162645/tiltrotor-matlab/blob/65e459504dd473f6dcf18326028f3a8a7991c55a/analysis/low_collective_quick_audit.m

9. 正式旋翼模型
https://github.com/x162645/tiltrotor-matlab/blob/65e459504dd473f6dcf18326028f3a8a7991c55a/model/rotor_model_bemt.m

10. 参数文件
https://github.com/x162645/tiltrotor-matlab/blob/65e459504dd473f6dcf18326028f3a8a7991c55a/params_nominal.m

11. NASA TM-86854 原始资料
https://ntrs.nasa.gov/citations/19870014976

必须直接检查 NASA 原文、正式代码、参数和原始 CSV；不能只根据 PR 描述或 Markdown 总结下结论。

请只核查以下问题：

A. NASA TM-86854 是否明确把 `COLL` 定义为 `0.75R` 处桨叶总距角？请给出原文页码、表号或图号，并说明是否存在报告内部矛盾。

B. 当前代码中局部桨距是否确实按类似下式生成：
`thetaBlade = collective + linear_twist + cyclic_term`
请给出精确文件、函数和表达式。

C. 当前默认参数是否确实为 `rootCut=0.18R`、桨尖扭转约 `-6 deg`？

D. 由正式代码和默认参数计算时，当前命令角到 `0.75R` 局部桨距的差值是否严格为约 `-4.1707317 deg`？请自行计算，不要复述审计报告。

E. 这个差值是否只能证明“桨距参考站位不同”，而不能证明当前通用旋翼与 NASA ATB 旋翼完成了同构横轴映射？

F. PR #59 关于 NASA ATB 与当前旋翼在扭转、弦长、实度、翼型、根部构型和转速方面的匹配/不匹配分类是否有直接依据？逐项标记：
- VERIFIED
- PARTIALLY_VERIFIED
- UNVERIFIED
- CONTRADICTED

G. 4°工况的外段负载荷大于内段正载荷、最终总推力为负的结论，是否可由审计 CSV 和脚本独立复算或追踪？

H. 正式路径是否对诱导速度目标使用了类似 `max(T,0)` 的正推力守卫？该守卫是否意味着负推力状态没有完成原始动量闭合？

I. 8°残差采样是否真的存在有限实数的符号变化区间？这一结果最多能证明“存在至少一个可括区根区间”，还是足以证明单根、唯一根或物理模型正确？

J. PR #59 是否存在以下风险：
- 把参考站位换算误写成旋翼同构映射；
- 把数值求解器失败全部归因于定义偏移；
- 把局部残差换号夸大为全局唯一物理解；
- 用审计包装器复制正式模型时产生实现偏差；
- 为了形成解释而事后选择有利区间或参数。

输出必须使用固定表格：

| Claim ID | PR #59 claim | Independent finding | Status | Direct evidence | Remaining uncertainty | Blocking? |

状态只允许：
- VERIFIED
- PARTIALLY_VERIFIED
- UNVERIFIED
- CONTRADICTED

最后只给出：

1. 是否可以把 `0.75R` 参考定义和 `-4.1707317 deg` 换算写入论文事实底稿；
2. 哪些表述必须降级；
3. 是否存在阻止后续“物理合理性检查表”任务的 blocking 问题；
4. 是否存在足以支持立即修改正式求解器的证据。

不要输出新的验模框架，不要给长期路线图，不要替项目重新定义研究目标。
```

---

## 7. 硬性止损规则

完成 Claude 独立核查和物理合理性检查表后，下一轮只接受以下类型的回复：

> 已检查 N 个代表工况；其中 X 项正常、Y 项异常、Z 项缺少判断依据。异常项及数值见 CSV。

如果下一轮再次交付新的分层验模框架、证据体系或长篇方法论说明，而没有固定字段数据表，则视为没有推进任务。
