# 南航配平点趋势截图对照验证报告

## 一句话结论

本报告已更新为变量映射修正版：0° 和 15° 的 Vertical pitch 使用 `-cyclicLong_deg` 作为南航截图对照主变量；75° 和 90° 的 elevator 映射已核查，未改变量定义。

## 本任务做了什么

- 重做 Fig.5(a)、Fig.6(a) 的 Vertical pitch 映射对照。
- 复核 Fig.5(b)、Fig.6(b) 的 elevator 映射，确认不需要变量定义翻新。
- 重导出四张模型图、四张截图对照图和总览图。
- 更新 `model_trend_diagnostics.csv` 和 `nuaa_visual_judgement_checklist.csv`。
- 没有调参，没有修改默认模型，没有合并 PR。

## 本任务没有做什么

- 没有数字化南航曲线。
- 没有计算南航-模型逐点误差。
- 没有声称严格复现南航或 XV-15。
- 没有把 full-angle 切换为默认。

## 工况表

| 图 | betaM | 南航变量 | 当前模型变量映射 |
|---|---:|---|---|
| Fig.5(a) | 0 deg | collective, Vertical pitch mapped: -cyclicLong_deg, pitch angle | collective_deg, verticalPitchMapped_deg, theta_deg |
| Fig.5(b) | 90 deg | collective, elevator_deg, pitch angle | collective_deg, elevator_deg, theta_deg |
| Fig.6(a) | 15 deg | collective, Vertical pitch mapped: -cyclicLong_deg, pitch angle | collective_deg, verticalPitchMapped_deg, theta_deg |
| Fig.6(b) | 75 deg | collective, elevator_deg, pitch angle | collective_deg, elevator_deg, theta_deg |

## 输出图清单

- `validation/nuaa_trim_trend_overlay/model_plots/model_fig5a_beta0_trim_trend.png`
- `validation/nuaa_trim_trend_overlay/comparison_boards/compare_fig5a_beta0.png`
- `validation/nuaa_trim_trend_overlay/mapping_refresh/model_fig5a_beta0_trim_trend_refreshed.png`
- `validation/nuaa_trim_trend_overlay/mapping_refresh/compare_fig5a_beta0_refreshed.png`
- `validation/nuaa_trim_trend_overlay/model_plots/model_fig5b_beta90_trim_trend.png`
- `validation/nuaa_trim_trend_overlay/comparison_boards/compare_fig5b_beta90.png`
- `validation/nuaa_trim_trend_overlay/mapping_refresh/model_fig5b_beta90_trim_trend_refreshed.png`
- `validation/nuaa_trim_trend_overlay/mapping_refresh/compare_fig5b_beta90_refreshed.png`
- `validation/nuaa_trim_trend_overlay/model_plots/model_fig6a_beta15_trim_trend.png`
- `validation/nuaa_trim_trend_overlay/comparison_boards/compare_fig6a_beta15.png`
- `validation/nuaa_trim_trend_overlay/mapping_refresh/model_fig6a_beta15_trim_trend_refreshed.png`
- `validation/nuaa_trim_trend_overlay/mapping_refresh/compare_fig6a_beta15_refreshed.png`
- `validation/nuaa_trim_trend_overlay/model_plots/model_fig6b_beta75_trim_trend.png`
- `validation/nuaa_trim_trend_overlay/comparison_boards/compare_fig6b_beta75.png`
- `validation/nuaa_trim_trend_overlay/mapping_refresh/model_fig6b_beta75_trim_trend_refreshed.png`
- `validation/nuaa_trim_trend_overlay/mapping_refresh/compare_fig6b_beta75_refreshed.png`
- `validation/nuaa_trim_trend_overlay/comparison_boards/nuaa_trim_trend_overlay_overview.png`
- `validation/nuaa_trim_trend_overlay/mapping_refresh/nuaa_trim_trend_overlay_overview_refreshed.png`

## 初步自动诊断

- legacy 默认保持：1，`P.wing.modelType=legacy`，`fullAngleModelEnabled=0`。
- 0°/15° 的 raw cyclicLong 仍保留为灰色审计曲线，但不再作为南航 Vertical pitch 主对照变量。
- `mapping_refresh/nuaa_variable_mapping_decision.csv` 记录所有候选和最终选择。
- 若需要严格判断南航误差，仍需后续人工数字化或原始数据。

## 结论

NUAA_MAPPING_REFRESH_READY
