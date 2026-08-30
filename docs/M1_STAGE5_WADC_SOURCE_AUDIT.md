# M1 Stage 5：XV-15 原始金属桨 WADC 跨设施外部验证来源审计

## 1. 研究角色

Stage 5 不再开发模型，只验证已经冻结的两个模型身份：

- `M0_PRODUCTION_LOW_ORDER`，冻结提交 `27f40883633ca14acc0e928649b62d7abb855491`；
- `M1_HOLDOUT_V1 = M1_E1_GENERIC_CORRIGAN_N1`，首次冻结记录提交 `d313296a35319dc8a5e6c398adbed0d54e0f8ede`。

`M1_HOLDOUT_V1` 的冻结发生在本阶段读取 WADC Table A-3 数值之前。WADC 数据因此分类为：

`POST_FREEZE_CROSS_FACILITY_EXTERNAL_VALIDATION`

它不是严格意义的 blind validation：模型在读取数据前已冻结，但分析者在执行验证时能够看到数据。禁止将其描述为盲验。

## 2. 原始试验来源

原始试验报告：

- S. Helf, E. Broman, S. Gatchel, B. Charles, *Full-Scale Hover Test of a 25-Foot Tilt Rotor*, Bell Helicopter Company Report 300-099-010, NASA-CR-114626, 16 May 1973.

NASA NTRS 摘要说明，该 25 ft 倾转旋翼在 Wright-Patterson Air Force Base 的 Aero Propulsion Laboratory whirl stand 上进行了悬停性能试验。报告给出的试验尖端马赫数范围约为 0.55-0.71。

本仓库使用的机器可读录入来自后续 NASA 汇编：

- Franklin D. Harris, *Hover Performance of Isolated Proprotors and Propellers - Experimental Data*, NASA/CR-2017-219486, Appendix A, Table A-3.

Appendix A 明确将该组数据列为 `XV-15 Metal Blade Proprotor (NASA OARF and WADC Tests)`，并说明 WADC 性能数据包含 `CP versus CT` 与 `CT versus 3/4 radius collective`，表格为 Table A-3。

## 3. 构型同源性

Appendix A 将 OARF 与 WADC 均归入 XV-15 原始金属桨叶旋翼数据集。该构型为：

- 25 ft 直径；
- 3 片桨叶；
- XV-15 原始金属桨叶；
- 0.75R（3/4 radius）总距作为桨距横坐标。

因此 Stage 5 不需要根据 WADC 输出引入新的总距偏置或重新定义控制输入；沿用已经冻结的 0.75R 总距映射。

## 4. 数据录入规则

仓库文件：

`analysis/data/xv15_wadc_metal_table_a3.csv`

录入 Table A-3 中全部正式 `Run 1`、`Run 2`、`Run 3` 数据，而不是只录入验证窗口内的点。这样可保留源表范围并避免按结果挑点。

`Check Out` 行不属于正式 Run 1-3 试验序列，Stage 5 不将其作为外部验证系列。

正式 Run 的典型尖端马赫数分别约为：

- Run 1：0.53；
- Run 2：0.62；
- Run 3：0.66。

该分层使冻结模型能够在与 OARF 约 0.69 不同的转速/马赫范围内接受跨设施检验。

## 5. 预声明验证窗口

Stage 5 固定使用：

`6 deg <= collective75_deg <= 11 deg`

理由不是 WADC 误差，而是继承冻结 M0/M1 已经建立并在冻结前声明的 6-11 deg 支持/报告窗口。

Table A-3 的 Run 1-3 在该窗口内各包含：

`6, 8, 9, 10, 11 deg`

没有 7 deg 数据，因此：

- 不插值 7 deg；
- 不制造伪试验点；
- 每个 Run 预期 5 个实测点；
- 三个 Run 合计预期 15 个点。

窗口外数据仍保留在源 CSV 中，但不进入本次固定窗口指标。

## 6. 系数和环境映射

试验提供 `Vtip`、`Mtip`、`CT`、`CP`、`FM` 和 0.75R collective。

冻结模型保持既有定义：

- `CT = T/(rho*A*Vtip^2)`；
- `CP = Q*Omega/(rho*A*Vtip^3)`；
- `FM = CT^(3/2)/(sqrt(2)*CP)`。

每个试验点使用 Table A-3 的 `Vtip` 设置旋翼转速。

为保持模型身份冻结：

- M0 继续使用冻结验证路径中的 generic `rho`，不从缺失记录中猜测 WADC 密度；
- M1_HOLDOUT_V1 继续使用冻结 M1-E-1 中 `aSound=340 m/s` 的处理，不利用已经看到的 WADC `Mtip` 反求新的声速；
- Table A-3 的 `Mtip` 作为试验元数据保留，用于跨转速/马赫解释，但不用于冻结后调参。

这些做法可能形成环境输入契约限制，应在可信域结论中保留，而不是用 WADC 数据事后修正。

## 7. 设施效应限制

NASA/CR-2017-219486 对 WADC Rig #3 明确保留设施效应警告：工作平台可能造成干扰地面效应，安全围栏也使测量结果存在疑问。后来的 OARF 数据因此通常被视为更高质量的孤立悬停性能基准。

Stage 5 不对 WADC 进行任何设施经验修正。WADC 的科学角色是：

- 不同设施；
- 不同试验系列；
- 不同尖端速度/马赫数；
- 有已知设施干扰限制的 post-freeze 外部检验。

因此若 WADC 与 OARF 残差不同，不能自动解释为模型失效，也不能自动解释为试验误差；应将“模型形式 + 环境映射 + 设施效应”作为可信域讨论的一部分。

## 8. Stage 5 停止规则

在 Table A-3 数值已经读取后：

- 禁止修改 Corrigan `n=1`；
- 禁止修改 C81；
- 禁止修改径向弦长或扭转；
- 禁止反求 collective offset；
- 禁止经验 CT/CP/FM 增益；
- 禁止用 WADC `Mtip` 事后重新选择 `aSound` 以降低误差；
- 禁止根据某个 Run 的误差删除该 Run；
- 禁止插值缺失的 7 deg 点；
- 禁止根据误差改变 6-11 deg 窗口；
- 禁止把 WADC 转为开发数据后再把同一结果称为独立验证。

若 M1 相对 M0 的改善不能跨设施保持，直接记录为模型可信域边界。

## 9. 来源追踪

1. NASA-CR-114626 / Bell Report 300-099-010, *Full-Scale Hover Test of a 25-Foot Tilt Rotor*, 1973.
2. NASA/CR-2017-219486, Appendix A, `XV-15 Metal Blade Proprotor (NASA OARF and WADC Tests)`, Table A-3.
3. NASA/CR-2017-219486 对 WADC Rig #3 工作平台与安全围栏干扰风险的背景说明。

注：本阶段曾尝试通过网页 PDF screenshot 接口直接渲染 NASA PDF 页，但 NTRS 返回 403、Ames 镜像因 PDF 体积过大未能由该接口加载。因此数值录入使用公开网页索引对 Table A-3 的结构化解析结果，并在仓库中完整保存正式 Run 1-3 数据以便后续人工对照原 PDF。
