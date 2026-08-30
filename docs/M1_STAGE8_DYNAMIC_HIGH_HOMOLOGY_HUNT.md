# M1 Stage 8：XV-15 动态 HIGH-homology 证据闭合检索

## 1. 与项目主线的关系

本阶段不修改 M0，也不修改 frozen `M1_HOLDOUT_V1`，不使用 OARF/WADC 继续调参。

项目固定方法学主线仍为：

`冻结模型身份 -> 外部验模 -> 保留失败 -> 机理诊断 -> 新模型身份 -> 再冻结 -> 跨数据集/跨设施外部检验 -> 可信适用域 -> 下一证据层级`

Stage 5 已完成悬停组件层跨设施外部验证；Stage 6 已确认动态层不存在 HIGH-homology case。Stage 8 的任务不是“想办法跑一张动态叠图”，而是主动关闭动态试验输入合同：只有同一 flight/run 的重量、CG、惯量、RPM/governor、环境、控制链和响应记录均达到足够同源性，才允许进入定量第一性动态外部验模。

## 2. 本轮新增公开证据

### 2.1 NASA TM-89428 的公开身份进一步确认

NASA NTRS 公开记录确认：

- 标题：`Frequency-response identification of XV-15 tilt-rotor aircraft dynamics`；
- NASA TM-89428；
- May 1987；
- NTRS document ID `19870013257`；
- 另有报告号 `AD-A182143`；
- distribution = public；
- NTRS 记录存在可下载 PDF。

这确认 TM-89428 是动态响应主来源，不是二手转述。

### 2.2 巡航数据库 #2 的控制链闭合增强

Tischler 后续系统辨识专著对 XV-15 数据库给出了更明确的实验合同：

- database #2 = 170-kn indicated-airspeed cruise flight-test data；
- cruise flight tests entirely SCAS-off；
- cruise 时 rotor controls disabled；
- lateral stick 驱动 aileron surfaces；
- pedals 驱动 rudder；
- 数据采样率 250 Hz；
- 匹配输入/输出 anti-aliasing filtering 50 Hz；
- measurement-system bandwidth 20 Hz。

因此 Stage 6 中 cruise `p/aileron` 和 `beta/rudder` 的控制链同源性可以提高，但仍不能升为 HIGH，因为同一 flight/run 的质量属性和其他状态合同尚未闭合。

### 2.3 公开研究对缺失质量属性的独立确认

当前可检索的后续 XV-15 建模研究明确指出：可获得的 flight-test data 没有提供案例所需的精确 CG location、moments of inertia、weight 和 flap setting，因此难以作确定性的定量验证结论。

这一点与本仓库 Stage 6 的阻塞项一致，说明我们此前拒绝使用 generic XV-15 参数补齐试验点不是过度保守，而是符合公开研究实际数据可获得性。

## 3. CR-177406 Volume III 的本轮检索结果

NASA 后续正式文献能够继续确认以下卷册真实存在：

`Arrington, Kumpel, Marr, McEntire, XV-15 Tilt Rotor Research Aircraft Flight Test Data Report, Volume III of V: Structural and Dynamics, NASA CR-177406, June 1985.`

本轮围绕：

- 完整标题；
- `CR-177406 Vol III`；
- `USAAVSCOM TR-86-A-1`；
- 可能的 DTIC/NTRS 镜像；
- 相关 Flight Test Report 引用链；

进行定向检索。

结果仍然只关闭了“卷册存在”，没有获得一个可逐页审计且能与 TM-89428 flight/run 建立一一映射的公开 Volume III case record。因此不能假定该卷一定包含当前缺失的每一个参数，也不能将设计值或一般 XV-15 参数表替代 case-specific values。

## 4. 当前各动态案例评级

机器可读矩阵：

`results/m1_stage8_dynamic_high_homology/M1_STAGE8_SOURCE_CLOSURE_MATRIX.csv`

### cruise p / aileron

新增信息：SCAS-off、rotor controls disabled、lateral stick -> aileron 明确。

结论：控制链证据增强，但 exact weight/CG/inertia/RPM/atmosphere/raw matched record 仍未闭合。

`MEDIUM / BLOCKED`

### cruise beta / rudder

新增信息：SCAS-off、pedal -> rudder 明确。

结论：与 p/aileron 相同，仍缺同一 run 的质量属性、RPM、环境及原始匹配记录。

`MEDIUM / BLOCKED`

### cruise q / elevator

已有 170 kn、8000 ft、nacelle 0 deg 和实测 elevator surface deflection 证据，但 exact run mass properties / exact atmosphere / rotor state 未闭合。

`MEDIUM / BLOCKED`

### cruise az / elevator

除上述缺失外，原始研究已经指出 unmodeled rotor-RPM dynamics 是主要异常解释之一。因此当前低阶程序若无 governor/rotor-speed dynamic state，更不能将该通道晋升为 HIGH。

`LOW / BLOCKED`

### hover dynamic set

hover flight-response、频响和 step-response 证据真实存在，SCAS 配置也比 Stage 6 时更明确，但 exact test mass properties、rotor/governor state、atmosphere 和完整 pilot-control-to-model mapping 仍未闭合。

`MEDIUM / BLOCKED`

## 5. Stage 8 gate

本轮没有发现能够满足 HIGH-homology 的案例。

总门槛保持：

`BLOCKED_NO_HIGH_HOMOLOGY_CASE`

这不是软件失败，也不是项目停滞，而是验证证据本身的边界。

## 6. 明确禁止的下一步

在 HIGH case 尚未闭合前，不允许：

1. 用 generic/design XV-15 weight 填同一 flight-test case；
2. 用一般 CG 或 Ferguson/其他模型惯量替代试验点惯量；
3. 用 ISA 自动补 exact atmosphere 后称为 exact validation；
4. 假设固定 rotor RPM/governor state 后称为 TM-89428 同源验证；
5. 从频响图反调低阶模型参数；
6. 因为程序可以 trim/linearize/time-response 就强行运行伪 XV-15 动态验模。

## 7. 下一步优先级

动态主线仍只允许做证据闭合，优先级如下：

1. 寻找并取得可审计的 `NASA CR-177406 Vol. III` 或 USAAVSCOM 同卷原始扫描；
2. 若取得卷册，先建立 flight/run index，不立即跑模型；
3. 对每个 candidate run 建立 `weight/CG/inertia/RPM/atmosphere/control-chain/input-output` 一行式合同；
4. 只有至少一个案例达到 HIGH，才冻结 dynamic validation case；
5. 然后才运行当前通用低阶模型的第一性动态外部验模，并保留所有失败。

如果公开资料最终仍不能关闭 HIGH，则论文主线应如实把动态层结论写成“证据同源性不足”，而不是补造验证结果。

## 8. 本阶段结论

Stage 8 没有改变悬停 M1 的模型身份，也没有扩大可信域。

它完成的是动态证据合同的进一步收紧：巡航控制链可以更明确，但真正决定 HIGH-homology 的 run-specific mass properties、rotor/governor state、atmosphere 和 matched raw record 仍然缺失。

因此，当前论文/研究主线仍然成立：

> 一个通用低阶倾转旋翼飞行动力学模型，应通过分层、来源受约束、失败保留的外部验证来建立可信适用域；当动态试验同源条件不足时，正确结论是保留验证门槛，而不是用型号通用参数制造“看起来一致”的结果。
