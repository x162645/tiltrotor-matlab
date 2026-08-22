# XV-15 公开数据第二轮回填审计

## 1. 任务定位

本审计不是重复 PR #53 的 219 行参数来源审计，而是在其基础上进行第二轮公开资料回填。基线为 PR #62 当前 head `117abaac56b778570597500c028af7543ea4cd63`。本轮坚持两个约束：

1. 只有公开来源中的物理量与当前代码字段语义同构时，才允许进入 opt-in XV-15 overlay；
2. 已有公开数据但当前模型接口无法忠实表达时，必须标记为接口/模型形式阻塞，不允许用一个标量“代替整张表、整条径向分布或构型调度”。

`params_nominal.m` 和默认物理路径均不修改。本轮新增 `GENERIC_MODEL_WITH_XV15_PUBLIC_OVERLAY_V2`，用于科研对照而不是宣称完整 XV-15 型号模型。

## 2. 第二轮得到的直接结论

| 当前字段/物理量 | 当前基线 | 公开 XV-15 信息 | 处置 | 原因 |
|---|---:|---:|---|---|
| `rotor.rootCut` | 0.18 R | **0.0875 R** | **SAFE_DIRECT_OVERLAY** | NASA CR-2016-219086 Table 2 直接给出 root cutout = 0.0875 r/R；与当前叶素积分起点语义同构 |
| `rotor.Ib` | 216.6 kg m² | 105 slug ft² = **142.3608846 kg m²** | **SAFE_DIRECT_OVERLAY** | 当前挥舞方程按单桨叶挥舞惯量使用 `Ib`，与公开 per-blade flapping inertia 同构 |
| `rotor.Omega` | 62 rad/s 单标量 | 565 rpm 直升机、534 rpm 转换、458 rpm 飞机 | **INTERFACE_BLOCKED_MODE_SCHEDULE** | 一个全局标量不能表达构型相关转速 |
| `rotor.chord` | 0.38 m 常弦长 | 基本弦长 14 in；根部 0.0875R 处约 17 in，至 0.25R 过渡到 14 in | **INTERFACE_BLOCKED_RADIAL_GEOMETRY** | 当前常弦长字段无法表达径向根部过渡 |
| `rotor.twistTip` | 线性总扭转 -6° | 总扭转约 -45°且有径向分布 | **INTERFACE_BLOCKED_NONLINEAR_TWIST** | 把 -45° 塞进现有字段会把公开径向分布压缩成当前简单线性律 |
| `rotor.flapMax` | 18°，兼容字段 | ±12° flapping design clearance | **SEMANTIC_MISMATCH_METADATA_ONLY** | 公开量是机械设计间隙，当前 active flap solver 实际使用的是另一发散角门限 |
| 预锥 | 无 active field | +2.5° | **MODEL_FIELD_MISSING** | 模型未显式表示 |
| `delta3` | 无 active field | -15° | **MODEL_FIELD_MISSING** | 当前挥舞/桨距耦合没有同构参数 |
| Lock number | 无 active field | 3.83 | **MODEL_FIELD_MISSING** | 可用于参数重建一致性核查，但不能直接写入现有模型 |
| mast/hub spring rate | 无 active field | 2700 in·lbf/deg ≈ **17478.6 N·m/rad** | **MODEL_FIELD_MISSING** | 当前一阶谐波挥舞模型没有同构弹簧项 |

`rootCut` 采用 NASA CR-2016-219086 Table 2 的直接无量纲值。其余上述旋翼特性主要由 NASA CR-2017-219486 Appendix A / Table A-1 交叉核对；该报告同时整理了 OARF/WADC 悬停试验数据，可作为原始金属桨部件验证的重要公开来源。

## 3. 对 PR #53 旧 overlay 的修正

PR #53 的第一轮 overlay 将 `rotor.Omega=565 rpm`、`rotor.chord=14 in`、`rotor.twistTip=-45 deg` 作为可应用字段。这些数值本身来自公开资料，但第二轮审计发现其**字段语义并不完全同构**：

- 565 rpm 只对应 CR-2017-219486 所列直升机/悬停参考；同一表还列出转换 534 rpm、飞机 458 rpm；
- 14 in 是基本桨叶弦长，根部 0.0875R 处约 17 in，并向 0.25R 过渡；
- -45° 是总扭转描述，公开资料同时给出径向扭转分布，不能把它等同于当前代码的简单线性 `twistTip` 参数。

因此 V2 overlay 保留第一轮审计以保证历史可追溯性，但明确阻止这三个字段自动覆盖。换言之，本轮不是否定来源，而是提升“来源值—代码字段”同源性要求。

## 4. 旋翼验证数据的同构性边界

### 4.1 NASA TM-86833

`Performance and Loads Data from a Hover Test of a Full-Scale XV-15 Rotor`，1985。该试验对象是**原始金属桨全尺度 XV-15 旋翼**，报告性能、尾流下洗和载荷，试验尖速马赫数约 0.60–0.73。

对于计划重建的原始金属桨 XV-15 低阶旋翼模型，这是当前最优先的悬停外部验证目标。模型几何、桨距定义和转速必须先与试验同构，再计算 CT、CQ、CP 或 FM 误差。

### 4.2 NASA TM-86854

`Performance and Loads Data from a Hover Test of a Full-Scale Advanced Technology XV-15 Rotor`，1986。对象是**Advanced Technology Blade (ATB)** 复合材料旋翼，并非原始金属桨。现有工程曾使用其图线进行外部关联，但 PR #59 已经证明横坐标 collective 定义和旋翼构型并不同构。

因此 V2 将 TM-86854 定位为：ATB 构型研究/比较数据，不作为当前原始金属桨模型的无条件定量验证数据。

## 5. GTRS：数据存在，但不能“抄成几个标量”

NASA CR-166536A 的 Generic Tilt-Rotor Simulation 来源于 Bell 的 XV-15 模型并经过重构。报告把机身、翼-短舱、尾翼、旋翼及干扰分别建模。对于机身，报告明确指出 XV-15 的相关数据列于 Appendix B（B-26 至 B-30）；在约 ±20° 迎角/侧滑范围内，系数主要基于 XV-15 风洞数据，更大角度包含近似扩展。翼-短舱同样采用随工况变化的数据表/经验模型。

这意味着 PR #53 中当前的：

- `wing.CL0 / CLalpha / CLmax / CD0 / kInduced / Cm0 ...`
- `fuselage.CD0 / CDalpha2 / CLalpha / CYbeta / Cm...`

不能仅靠从 GTRS 某一点读取一个值就升级成 `XV15_DIRECT`。公开数据已经存在，但**当前标量多项式接口与 GTRS 数据表模型不等价**。

本轮因此把 `wing.aeroTables`、`fuselage.aeroTables` 登记为 `TABLE_MODEL_REQUIRED`。下一步应实现独立 lookup/fitted-surface 层，然后逐表录入/数字化，而不是继续调 `CLalpha`、`CD0` 等几个等效参数去追配平。

## 6. 当前真正仍缺或接口不支持的高影响量

经过 PR #53/#58 和本轮二次核对后，可将问题进一步收缩：

### 已有公开值且可立即同构回填

- 原始/基准 XV-15 旋翼 root cutout ratio：0.0875；
- 单桨叶 flapping inertia：142.3608846 kg m²。

### 已有公开值但当前接口不支持

- 565/534/458 rpm 构型相关转速（CR-2017-219486 所列工况）；
- 根部径向弦长过渡；
- 径向扭转分布；
- precone、delta3、Lock number、mast/hub spring；
- GTRS 机身与翼-短舱多维气动表。

### 仍不能由本轮资料唯一确定

- 与所选桨叶径向站、Mach、Reynolds 数完全同构的二维 `Cl/Cd/Cm` 极曲线全集；
- 当前低阶 `wing`、`htail`、`fuselage` 标量等效参数与真实 XV-15 数据表之间的唯一映射；
- 十三状态短舱执行机构带宽、阻尼、力矩限制等型号级动态参数。

## 7. 对论文/验模路线的影响

本轮结果改变了此前“先把第一轮 XV-15 overlay 全部打开再验模”的做法。推荐顺序变为：

1. 保留 `params_nominal` 作为 generic baseline；
2. 用 V2 overlay 只覆盖语义同构的公开几何/惯性参数；
3. 新增径向 chord/twist 与 mode-dependent rpm 接口；
4. 以 NASA TM-86833 原始金属桨试验重新做悬停部件验证；
5. 再实现 GTRS Appendix B lookup/fitted-surface 气动层；
6. 做整机配平和转换段对比；
7. 最后用 XV-15 飞行辨识频响作为动态独立验证。

这条路线避免两个错误：一是“公开数值存在 = 当前字段可以直接替换”；二是“与 GTRS/试验趋势接近 = 已完成 XV-15 型号验证”。

## 8. 本 PR 的代码边界

本 PR：

- 不修改 `params_nominal.m`；
- 不修改默认生产物理；
- 不修改已有 PR #53 overlay，保证历史结果可复现；
- 新增 V2 opt-in overlay；
- V2 自动应用 `rootCut` 和 `Ib` 两个第二轮同构字段；
- V2 主动阻止 `Omega/chord/twistTip` 三个第一轮非同构标量覆盖；
- 对缺失字段和 GTRS 气动表只登记证据及实现阻塞，不伪造替代参数。

因此本 PR 的科学意义是**缩小参数不确定性并修正公开数据的映射方式**，而不是宣称已经得到完整 XV-15 数据库。
