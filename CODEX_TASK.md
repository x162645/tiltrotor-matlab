# CODEX_TASK.md

STATUS: VALIDATION MAINLINE SYNTHESIZED / M1 HOLDOUT FROZEN / STAGE 6 DYNAMIC GATE BLOCKED / 2026-08-28

## 版本契约

- 仓库：`x162645/tiltrotor-matlab`。
- M0 冻结分支：`frozen/m0-xv15-hover-v1-20260828`。
- M0 冻结提交：`27f40883633ca14acc0e928649b62d7abb855491`。
- M1 研究分支：`research/m1-xv15-physics-enhanced-20260828`。
- M1 Draft PR：#71。
- 未经用户明确授权不得合并 PR #71。

## 本项目主线

研究对象是**通用低阶倾转旋翼飞行动力学模型**。XV-15 用于提供外部证据，不用于把通用模型反调成数字孪生。

固定方法学顺序：

`冻结模型身份 -> 外部验模 -> 保留失败 -> 机理诊断 -> 新模型身份 -> 再冻结 -> 跨数据集/跨设施外部检验 -> 可信适用域 -> 下一证据层级`

禁止把“验证误差大”自动转化为“继续调到通过”。

## M0：冻结通用低阶基线

冻结提交：`27f40883633ca14acc0e928649b62d7abb855491`。

OARF original-metal-blade 6-11 deg：

- Run 15：CT MAPE 56.4224%，CP 62.6130%，FM 23.0180%；
- Run 14：CT MAPE 56.1864%，CP 64.0809%，FM 19.1169%。

结论：

- 定性载荷趋势可辨识；
- CT/CP 绝对值存在约 50%-65% 系统性低估；
- 低 collective 存在分支/求解限制；
- M0 不是 XV-15 定量悬停性能模型。

这一失败被保留，不修改 production M0。

## M1 来源受约束物理阶梯

正式 MATLAB R2021a 证据：

- C81 section bridge：42.8716 / 51.1184 / 12.2221%；
- M1-A actual radial geometry + scalar C81：33.9549 / 45.2392 / 4.4100%；
- M1-B actual geometry + full radial/Mach C81：37.8538 / 50.5150 / 7.5480%；
- M1-C M1-B + annular momentum：35.7519 / 47.9006 / 5.9849%；
- M1-D source-constrained loaded torsion：方向减小有效桨距，不能支持未知正总距偏置作为主要解释；
- M1-E-1 generic Corrigan n=1：32.7287 / 45.8916 / 7.5923%；
- M1-E-2 Koning XV-15/OARF-correlated n=1.8：28.3075 / 41.7337 / 8.0567%，但属于非独立相关性复现，不可晋升为 holdout 主模型；
- M1-F Landgrebe/Biot-Savart：7-11 deg 有稳定非局部尾迹分支并改善 CT/CP 数个百分点；6 deg 病态/非物理解，因此仅为 `MODEL_FORM_DIAGNOSTIC`。

不得依据 Run 15 MAPE 排名选择“最好看”的物理模型。

## M1 holdout 冻结

首次冻结记录提交：

`d313296a35319dc8a5e6c398adbed0d54e0f8ede`

发生在 WADC Table A-3 数值读取之前。

冻结模型：

`M1_HOLDOUT_V1 = M1_E1_GENERIC_CORRIGAN_N1`

固定内容：

1. XV-15 original-metal-blade 实际径向弦长；
2. 非线性扭转及 0.75R collective 映射；
3. 四径向区域完整 C81 + local Mach/alpha；
4. generic Corrigan-Schillings `n=1`；
5. 冻结 M1-E-1 的全盘标量动量闭合及既有一阶方位入流形状；
6. 当前低阶一阶谐波挥舞；
7. 无 CT/CP/FM gain；
8. 无固定 collective offset；
9. 无 OARF/WADC target fitting。

Stage-5 identity gate 对冻结 Stage-3 六个 OARF 点逐点复算，CT/CP/FM 最大绝对差为 `0`。

## Stage 5：WADC post-freeze 跨设施外部验证已完成

数据：NASA/CR-2017-219486 Appendix A Table A-3 formal WADC Runs 1-3。

角色：

`POST_FREEZE_CROSS_FACILITY_EXTERNAL_VALIDATION`

不是 blind validation；分析者执行时可见数据，但模型、参数和窗口已在数据读取前冻结。

固定窗口继承 6-11 deg；WADC 每 Run 使用源表实际存在的 `6,8,9,10,11 deg`，不插值 7 deg，共 15 点。

最新正式 MATLAB R2021a：

- run：`33163232175`；
- head：`1b3ddee13972e20a404ad15572bc1794fbd2e60a`；
- artifact：`9682515346`；
- artifact SHA-256：`df5251cfd8d1b6e559be1125d7620e06d4009d3a0a188089c06cebdc96debbfa`；
- status：SUCCESS。

WADC pooled：

### M0
- CT 59.1465%；
- CP 66.0974%；
- FM 23.0497%。

### frozen M1_HOLDOUT_V1
- CT 37.8956%；
- CP 51.1078%；
- FM 9.2559%。

### M1 relative improvement
- CT：21.2509 pp；
- CP：14.9896 pp；
- FM：13.7938 pp。

三个 WADC Run（Mtip 约 0.53、0.62、0.66）CT 改善均约 21.2 pp，CP 均约 15.0 pp，说明来源受约束的 M1 改善跨设施/跨转速保持。

但 CT/CP 绝对误差仍大，因此不得声称 M1 已经成为 XV-15 高精度性能模型。

## 当前悬停可信适用域

在 original-metal-blade hover、collective 约 6-11 deg、Mtip 约 0.53-0.69 的现有证据范围：

### 可以声明
- CT/CP 随 collective 变化的基本趋势；
- M1 相对 M0 的改善方向具有跨设施支持；
- source-constrained geometry/aero/rotational-augmentation 组合具有可泛化价值；
- FM 可作中等可信度诊断，但必须报告逐点误差避免抵消误导。

### 不可以声明
- XV-15 数字孪生；
- 高精度绝对 CT；
- 高精度绝对 CP；
- collective < 6 deg 已验证；
- >11 deg 因 WADC 有数据就自动扩域；
- Mtip <0.53 或 >0.69 已验证；
- 悬停组件验模自动等于整机前飞动态验模。

## Stage 6：动态证据同源性复核已完成

新增复核来源包括：

- NASA TM-86009 / 同源 1984 ERF paper；
- NASA TM-89428；
- XV-15 hover frequency-domain identification publication；
- NASA CR-177406 Vol. III existence / archive target。

更新结果：

- cruise q/elevator：MEDIUM / BLOCKED；
- cruise az/elevator：LOW / BLOCKED；
- cruise p/aileron：MEDIUM / BLOCKED；
- cruise beta/rudder：MEDIUM / BLOCKED；
- hover frequency/step-response evidence：从 PENDING 提升为 MEDIUM-source，但 model homology 仍 MEDIUM / BLOCKED；
- TM-89428 multi-condition set：MEDIUM / BLOCKED；
- CR-177406 Vol. III：MEDIUM source potential，case records 未闭合，LOW until retrieved / BLOCKED。

总门槛：

`BLOCKED_NO_HIGH_HOMOLOGY_CASE`

阻塞项是同一试验记录的：

- weight；
- CG；
- inertia tensor；
- rotor RPM / governor；
- exact atmosphere；
- complete control-chain mapping；
- matched machine-readable input/output records。

仓库已有 trim、linearization、modal、time-response 能力，但软件能力不能代替试验同源性。

因此**没有运行伪 XV-15 动态验模**。

## Stage 7：主线综合已完成

机器可读总矩阵：

`results/VALIDATION_CREDIBLE_DOMAIN_MATRIX.csv`

完整研究主线综述：

`docs/VALIDATION_MAINLINE_SYNTHESIS.md`

Stage 5 结果：

`docs/M1_STAGE5_WADC_RESULTS.md`

Stage 6 动态证据复核：

`docs/M1_STAGE6_DYNAMIC_EVIDENCE_REAUDIT.md`

这四个文件共同定义当前项目的正式验证结论、证据角色、允许声明、禁止声明和可信域。

## 当前研究停止点

现有 M1 悬停主线已经达到合理停止点。

**禁止**继续使用 OARF Run14/15 或 WADC 调整 `M1_HOLDOUT_V1`。

下一步只有两条方法学上合法的研究分叉：

### A. 动态 HIGH-homology 证据闭合

若取得 CR-177406 或其他原始试飞卷册，必须先建立同一 flight/run 的 weight/CG/inertia/RPM/atmosphere/control-chain/raw-response 合同；只有达到 HIGH 后才允许冻结动态 case 并执行定量外部验模。

### B. 新的 M2 物理模型

若未来研究更可靠的 tiltrotor free-wake / lifting-line / aeroelastic coupling，必须建立新的 M2 model identity 和新的 development/validation split。不得用 WADC 调好后继续称为当前 M1 holdout。

在上述条件未满足前，当前最合理工作是论文/报告整理、结果可视化和方法学表达，而不是继续调模型。

## 永久停止规则

- 不修改 frozen M0；
- 不用 OARF/WADC 反调 frozen M1；
- 不用 generic XV-15 weight/CG/inertia/RPM 填补动态试飞缺口后称为验证；
- 不删除失败点或大误差点；
- 不将 reused/correlated source 改称 blind；
- 不用更小 MAPE 代替证据独立性与模型身份规则；
- 未经用户明确授权不得合并 PR #71。
