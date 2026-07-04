# 0°直升机模式配平趋势反向共性根因审计报告

## 一句话结论

本报告不是修复，只是诊断。当前保存的 0° 配平点显示 cyclicLong 的符号映射仍是最优先核查对象；但“collective 随速度上升”的说法没有被保存数值直接复现，旧自动趋势标签可能受容差过宽影响。

full-angle 机翼数据库已经消除了旧 near-normal 混合路径的局部跳变证据，但这不等于 0° cyclic/vertical pitch 方向问题已修复。

## 背景

- 本审计只检查 `betaM=0 deg`、`helicopter_longitudinal`、`V=[0 5 10 12 15 20 25 30] m/s`。
- 输入数据复用 `validation/wing_full_angle/trim_envelope/points/` 下已保存的 legacy/full_angle 配平点。
- 没有修改 `params_nominal.m`，没有修改 `model/` 生产模型，没有切换 full-angle 为默认。
- 没有数字化南航曲线，因此本文只给趋势和共性根因判断，不给严格误差结论。

## 已确认事实

- legacy collective: 16.7696 deg -> 14.3149 deg，严格数值趋势 `decreasing`。
- full_angle collective: 17.2035 deg -> 15.4403 deg，严格数值趋势 `decreasing`。
- full_angle cyclicLong: 4.30638 deg -> -3.51334 deg，严格数值趋势 `decreasing`。
- 0° full_angle 点存在 `outOfRangeClamped=1`，报告结论必须保留这一限制。
- 0° full_angle 的 `branchWeight=0`，说明这批结果没有重新启用旧 `FNear/FLiftLine branchWeight` 路径。

## cyclicLong / vertical pitch 映射审计

- `CYCLIC_MAPPING_GATE = PASS_IF_SIGN_OR_EQUIVALENT_EXPLAINS`。
- `cyclicLong_deg`、`-cyclicLong_deg` 和旋翼盘面等效俯仰候选均已输出到 `zero_cyclic_mapping_audit.csv`。
- 当前证据支持先核查南航图中 vertical pitch 与代码输出变量的符号/物理量映射，而不是直接改生产模型中的 cyclicLong 符号。

## collective 反向审计

- `COLLECTIVE_REVERSAL_GATE = MIXED_OR_UNRESOLVED`。
- 保存的 legacy/full_angle 数值中，collective 在 0-30 m/s 范围内严格趋势为下降，不支持“数值上随速度上升”的诊断前提。
- 旧 `model_trend_diagnostics.csv` 使用的自动趋势标签与原始 collective 数值不一致，后续不应直接据此修改模型。

## 部件 Fz / My 贡献

- `zero_component_slope_audit.csv` 已记录 rotor/wing/htail/fuselage/vtail/total 的 Fx、Fz、My 斜率。
- 这些斜率只能说明哪些部件随速度变化明显；由于本次未做真实部件关闭重配平，不能单独证明某个部件就是根因。

## 和其他角度的对比

- `cross_mode_trend_context.csv` 复用了现有 overlay 诊断，用于说明问题主要集中在 0° helicopter_longitudinal 链路。
- 75°/90° 主要由 elevator 闭合，不足以证明 0° cyclicLong 映射全局正确。

## 当前不应做什么

- 不应直接调参贴合南航曲线。
- 不应直接把 `cyclicLong` 乘以 -1 写进生产模型。
- 不应继续修改机翼数据库来解决 cyclic 方向问题。
- 不应把 full-angle 切为默认。
- 不应合并 PR。

## 下一步建议

- `COMMON_CAUSE_CLASSIFICATION = CYCLIC_OUTPUT_MAPPING_LIKELY`。
- `FINAL_RECOMMENDATION = DO_NOT_MODIFY_MODEL_YET_MAPPING_AUDIT_FIRST`。
- 建议先做南航 vertical pitch 的变量定义审计：确认它对应代码的 `cyclicLong`、`-cyclicLong`、还是旋翼盘面/挥舞等效量。
- 若 owner 确认 collective 图确实要求另一方向，应先修正趋势判据并复核保存点原始数值，再做旋翼入流或部件力矩闭合审计。

## 输出文件

- `validation/helicopter_zero_common_cause_audit/zero_cyclic_mapping_audit.csv`
- `validation/helicopter_zero_common_cause_audit/zero_collective_trend_audit.csv`
- `validation/helicopter_zero_common_cause_audit/zero_component_slope_audit.csv`
- `validation/helicopter_zero_common_cause_audit/cross_mode_trend_context.csv`
- `validation/helicopter_zero_common_cause_audit/zero_common_cause_gate_status.csv`
- `validation/helicopter_zero_common_cause_audit/plots/*.png`

## 结论

ZERO_HELI_COMMON_CAUSE_AUDIT_PARTIAL
