# CODEX_TASK.md

STATUS: M1 XV-15 PHYSICS-ENHANCED LOW-ORDER RESEARCH / STAGE 6 DYNAMIC-VALIDATION EVIDENCE GATE / 2026-08-28

## 版本契约

- 仓库：`x162645/tiltrotor-matlab`。
- M0 冻结分支：`frozen/m0-xv15-hover-v1-20260828`。
- M0 冻结提交：`27f40883633ca14acc0e928649b62d7abb855491`。
- M1 研究分支：`research/m1-xv15-physics-enhanced-20260828`。
- M1 Draft PR：#71。
- 未经用户明确授权不得合并 PR #71。

## 项目主线

本项目研究通用低阶倾转旋翼模型的分层外部验证、模型形式诊断和可信适用域，不以复现 XV-15 数字孪生为目标。

核心方法学顺序固定为：

`冻结模型身份 -> 外部验模 -> 保留失败 -> 界定可信域 -> 再进入下一层证据`

不得把“验模失败”自动转化为“继续调到通过”。M0 保持冻结；M1 只允许采用独立来源约束的物理增强。OARF Run 14/15 和 WADC 已经承担各自的数据角色，不得重新用于反调冻结模型。

## Stage 1-4 已完成证据链

同等级 MATLAB R2021a 结果：

- M0：CT MAPE 56.4224%，CP 62.6130%，FM 23.0180%；
- 截面气动桥接：42.8716%，51.1184%，12.2221%；
- M1-A 真实径向几何 + 标量 C81：33.9549%，45.2392%，4.4100%；
- M1-B 真实径向几何 + 完整径向 C81：37.8538%，50.5150%，7.5480%；
- M1-C M1-B + 分环带动量：35.7519%，47.9006%，5.9849%；
- M1-D 来源约束受载扭转：受载方向减小桨距，不能支持未知正桨距偏置作为主要残差解释；
- M1-E-1 通用 Corrigan n=1：32.7287%，45.8916%，7.5923%；
- M1-E-2 Koning XV-15/OARF 相关 n=1.8：28.3075%，41.7337%，8.0567%，但属于非独立相关性复现，不能作为 holdout 主模型；
- M1-F Landgrebe/Biot-Savart 非局部尾迹：7°-11°存在稳定分支并改善 CT/CP 数个百分点，但 6°出现病态/非物理解，故仅保留为 `MODEL_FORM_DIAGNOSTIC`。

M1-F 不再围绕 OARF 继续调参。若未来继续提高尾迹层级，必须建立新的 M2 身份和新的开发/验证分割。

## M1 holdout 冻结

在读取 WADC 数值之前，已建立 `docs/M1_HOLDOUT_FREEZE.md`。

冻结主模型：

`M1_HOLDOUT_V1 = M1_E1_GENERIC_CORRIGAN_N1`

固定物理内容：

1. XV-15 原始金属桨真实径向弦长；
2. XV-15 原始金属桨非线性扭转；
3. 四径向区域完整 C81 + 局部马赫数；
4. 通用 Corrigan-Schillings `n=1`；
5. 全盘标量动量诱导闭合，并保留冻结 M1-E-1 的一阶方位入流形状 `viField = vi*(1 + cos(psi)*(r/R))`；
6. 当前低阶一阶谐波挥舞；
7. 无 CT/CP 增益、无固定总距偏置、无 OARF 拟合。

首次冻结记录提交：`d313296a35319dc8a5e6c398adbed0d54e0f8ede`。

冻结后曾发现文档把第 5 项简写成“均匀动量”，后续仅进行了文字一致性更正；冻结实现始终以 `analysis/run_m1_stage3_corrigan_stall_delay.m` 的 `CORRIGAN_GENERIC_N1` 分支为准，没有在查看 WADC 后修改模型方程或参数。

## Stage 5 已完成：WADC 跨设施 post-freeze 外部验证

来源审计：`docs/M1_STAGE5_WADC_SOURCE_AUDIT.md`。
结果综述：`docs/M1_STAGE5_WADC_RESULTS.md`。
源数据：`analysis/data/xv15_wadc_metal_table_a3.csv`。

数据角色：

`POST_FREEZE_CROSS_FACILITY_EXTERNAL_VALIDATION`

不是 blind validation：分析者执行时可见数据，但模型身份、参数和报告窗口已事先冻结。

固定验证窗口继承冻结前 6°-11°支持窗口；每个 WADC formal Run 使用实际存在的 `6,8,9,10,11 deg`，不插值 7°，每 Run 5 点，共 15 点。

最新正式 MATLAB R2021a workflow：

- run：`33163232175`；
- head：`1b3ddee13972e20a404ad15572bc1794fbd2e60a`；
- conclusion：`success`；
- artifact：`9682515346`；
- SHA-256：`df5251cfd8d1b6e559be1125d7620e06d4009d3a0a188089c06cebdc96debbfa`。

M1 identity gate：Stage-5 方程副本与冻结 Stage-3 `CORRIGAN_GENERIC_N1` 六个 OARF 点的 CT/CP/FM 最大绝对差为 `0`。

### WADC pooled 结果

M0：

- CT MAPE：59.1465%；
- CP MAPE：66.0974%；
- FM MAPE：23.0497%。

冻结 M1_HOLDOUT_V1：

- CT MAPE：37.8956%；
- CP MAPE：51.1078%；
- FM MAPE：9.2559%。

M1 相对 M0：

- CT MAPE 改善 21.2509 pp；
- CP MAPE 改善 14.9896 pp；
- FM MAPE 改善 13.7938 pp。

三个 WADC Run（典型 Mtip 约 0.53、0.62、0.66）的 CT 改善均约 21.2 pp，CP 均约 15.0 pp，说明来源受约束物理增强的改善跨设施、跨转速保持。

但 M1 仍系统低估 CT/CP，不能称为 XV-15 定量悬停性能模型。

## 当前旋翼悬停可信适用域

- 6°-11°、Mtip 约 0.53-0.69：CT/CP 随总距趋势与 M1 相对 M0 的改善方向具有跨设施证据；
- CT 绝对定量预测：不支持高精度声明，OARF 约 33% MAPE、WADC 约 38%；
- CP 绝对定量预测：不支持高精度声明，OARF 约 46%、WADC 约 51%；
- FM：中等诊断可信度，OARF 约 7.6%、WADC 约 9.3%，但逐点存在正负误差抵消；
- collective < 6°：低可信/当前不支持；
- collective > 11°：未在冻结前预声明，不扩张可信域；
- Mtip 约 0.53-0.69 之外：当前无外部验证；
- M1-F 非局部尾迹：模型形式诊断，不是主模型；
- 前飞/完整飞行动力学：悬停结果不能自动解锁，必须单独经过动态证据同源性门槛。

## Stage 6：动态验模证据门槛

Stage 6 不允许因为悬停层 M1 得到改善，就默认整机动态模型已经具备 XV-15 验模资格。

当前已知 NASA TM-86009 动态同源性门槛仍为 `BLOCKED`。历史审计中：

- q/elevator：MEDIUM；
- az/elevator：LOW；
- p/aileron：MEDIUM；
- beta/rudder：MEDIUM；
- cruise step plots：MEDIUM；
- hover dynamic cases：PENDING。

主要缺口包括：

- 与具体飞行试验点完全匹配的质量；
- CG；
- 惯量张量；
- 实际 RPM / governor 状态；
- 试验密度和温度；
- 完整坐标、符号和控制输入映射；
- 可核对的原始或机器可读动态时历。

禁止用设计总重、generic inertia、generic RPM 或概念参数替代缺失的试验记录，然后声称完成 XV-15 动态验模。

### Stage 6 执行顺序

1. 重新读取现有 `TM86009_HOMOLOGY_MATRIX.csv` 和程序能力映射；
2. 审计仓库现有 NASA TM-89428、CR-177406 或其他公开来源是否能关闭上述缺口；
3. 每个动态案例按 `HIGH / MEDIUM / LOW / BLOCKED` 重新评级；
4. 只有至少一个案例达到 `HIGH`，才允许建立冻结的动态外部验证 runner；
5. 若仍无 HIGH 案例，保留 `BLOCKED`，把“证据不足导致无法验模”作为分层验证结果，不用 generic 参数强行制造动态相关性；
6. 若有 HIGH 案例，先冻结该案例的模型/输入映射，再读取目标响应数据并执行同源外部验模。

## Stage 6 停止规则

- 禁止为匹配动态响应调质量、CG、惯量或控制增益；
- 禁止用 generic 参数填补试飞记录缺口后称为型号验模；
- 禁止只因响应曲线形状相似就提升同源性等级；
- 禁止把文献仿真曲线当作原始飞行试验数据；
- 禁止在看到目标响应后改变模型身份；
- 禁止把 hover 组件验模结论外推为整机动态验证结论；
- 未经用户明确授权不得合并 PR #71。
