# 南航配平点趋势对照图变量映射翻新报告

## 一句话结论

0° 和 15° 工况中的南航 Vertical pitch 对照变量已从 raw `cyclicLong_deg` 翻新为 `-cyclicLong_deg` 最佳视觉候选。75° 和 90° 工况继续使用 `elevator_deg`，已核查，无需翻新变量定义。本次只影响对照图、CSV 和报告，不影响生产模型。

## 为什么要翻新

- 原对照图直接使用 raw `cyclicLong_deg`，人工审核显示它与南航 Vertical pitch 方向明显相反。
- 0° common-cause 审计显示 `-cyclicLong_deg` 或等效变量更可能与南航截图一致。
- 因此本次翻新对照图变量映射，而不是修改模型方程或参数。

## 映射决策表

| 图 | 南航变量 | 原来使用的程序变量 | 重新核查后的候选 | 最终选择 | 是否翻新 |
|---|---|---|---|---|---|
| Fig.5(a) | Vertical pitch | cyclicLong_deg | cyclicLong_deg, cyclicLong_neg_deg, rotor_disk_pitch_deg | cyclicLong_neg_deg | 1 |
| Fig.6(a) | Vertical pitch | cyclicLong_deg | cyclicLong_deg, cyclicLong_neg_deg, rotor_disk_pitch_deg | cyclicLong_neg_deg | 1 |
| Fig.5(b) | Elevator | elevator_deg | elevator_deg | elevator_deg | 0 |
| Fig.6(b) | Elevator | elevator_deg | elevator_deg | elevator_deg | 0 |

## 哪些图被翻新

- `validation/nuaa_trim_trend_overlay/mapping_refresh/model_fig5a_beta0_trim_trend_refreshed.png`
- `validation/nuaa_trim_trend_overlay/mapping_refresh/compare_fig5a_beta0_refreshed.png`
- `validation/nuaa_trim_trend_overlay/mapping_refresh/model_fig5b_beta90_trim_trend_refreshed.png`
- `validation/nuaa_trim_trend_overlay/mapping_refresh/compare_fig5b_beta90_refreshed.png`
- `validation/nuaa_trim_trend_overlay/mapping_refresh/model_fig6a_beta15_trim_trend_refreshed.png`
- `validation/nuaa_trim_trend_overlay/mapping_refresh/compare_fig6a_beta15_refreshed.png`
- `validation/nuaa_trim_trend_overlay/mapping_refresh/model_fig6b_beta75_trim_trend_refreshed.png`
- `validation/nuaa_trim_trend_overlay/mapping_refresh/compare_fig6b_beta75_refreshed.png`
- `validation/nuaa_trim_trend_overlay/mapping_refresh/nuaa_trim_trend_overlay_overview_refreshed.png`

默认查看入口也已同步重导出到：
- `validation/nuaa_trim_trend_overlay/model_plots/`
- `validation/nuaa_trim_trend_overlay/comparison_boards/`

旧标准路径被新图覆盖；带 `_refreshed` 后缀的新图保留在 `mapping_refresh/` 目录中，便于追溯。

## 哪些图没改变量定义

- Fig.5(b) 90°：已核查，仍使用 `elevator_deg`，无变量定义翻新。
- Fig.6(b) 75°：已核查，仍使用 `elevator_deg`，无变量定义翻新。
- 这两张图可以随总览图同步重导出，但变量定义未变。

## 这次翻新不代表什么

- 不代表模型修复。
- 不代表生产代码修改。
- 不代表严格 XV-15 验模。
- 不代表 full-angle 可以切默认。

## 当前人工判断建议

- 重新看 0°、15°图时，应看映射修正版。
- 75°、90°未改变量定义，可继续看当前标准入口图；若看总览图，则使用刷新后的总览图。

## 结论

NUAA_MAPPING_REFRESH_READY
