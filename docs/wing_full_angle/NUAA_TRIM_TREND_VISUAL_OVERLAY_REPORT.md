# 南航配平点趋势截图对照验证报告

## 一句话结论

本任务未数字化南航曲线，只将南航原图截图与当前 legacy/full-angle 模型曲线同版式并排，用于人工趋势判断。

## 本任务做了什么

- 截取了 Fig.5(a)、Fig.5(b)、Fig.6(a)、Fig.6(b)。
- 复用当前真实完成的 legacy/full_angle 配平包线结果。
- 生成了四张对照图和一张总览图。
- 没有调参。
- 没有修改默认模型。
- 没有合并 PR。

## 本任务没有做什么

- 没有数字化南航曲线。
- 没有计算南航-模型逐点误差。
- 没有声称严格复现南航。
- 没有声称严格 XV-15 验证。

## 工况表

| 图 | betaM | V范围 | 南航变量 | 模型变量 |
|---|---:|---|---|---|
| Fig.5(a) | 0 deg | 0-30 m/s | collective, longitudinal cyclic / vertical pitch, pitch angle | collective_deg, cyclicLong_deg, theta_deg |
| Fig.5(b) | 90 deg | 70-150 m/s | collective, elevator, pitch angle | collective_deg, elevator_deg, theta_deg |
| Fig.6(a) | 15 deg | 10-60 m/s | collective, longitudinal cyclic / vertical pitch, pitch angle | collective_deg, cyclicLong_deg, theta_deg |
| Fig.6(b) | 75 deg | 70-145 m/s | collective, elevator, pitch angle | collective_deg, elevator_deg, theta_deg |

## 输出图清单

- `validation/nuaa_trim_trend_overlay/crops/nuaa_fig5a_crop.png`
- `validation/nuaa_trim_trend_overlay/model_plots/model_fig5a_beta0_trim_trend.png`
- `validation/nuaa_trim_trend_overlay/comparison_boards/compare_fig5a_beta0.png`
- `validation/nuaa_trim_trend_overlay/crops/nuaa_fig5b_crop.png`
- `validation/nuaa_trim_trend_overlay/model_plots/model_fig5b_beta90_trim_trend.png`
- `validation/nuaa_trim_trend_overlay/comparison_boards/compare_fig5b_beta90.png`
- `validation/nuaa_trim_trend_overlay/crops/nuaa_fig6a_crop.png`
- `validation/nuaa_trim_trend_overlay/model_plots/model_fig6a_beta15_trim_trend.png`
- `validation/nuaa_trim_trend_overlay/comparison_boards/compare_fig6a_beta15.png`
- `validation/nuaa_trim_trend_overlay/crops/nuaa_fig6b_crop.png`
- `validation/nuaa_trim_trend_overlay/model_plots/model_fig6b_beta75_trim_trend.png`
- `validation/nuaa_trim_trend_overlay/comparison_boards/compare_fig6b_beta75.png`
- `validation/nuaa_trim_trend_overlay/comparison_boards/nuaa_trim_trend_overlay_overview.png`

## 如何人工判断

- 先看趋势方向是否同类，例如随速度增加是上升、下降还是基本平。
- 再看模型曲线是否有突跳或不合理局部凸起。
- 确认控制量是否同类变量：0/15 度主看纵向周期变距，75/90 度主看升降舵。
- 90 度飞机模式中 cyclicLong 应固定为 0，本任务使用的包线结果满足该约束。
- 可以比较 full_angle 是否比 legacy 更平滑，但不要要求数值一模一样。

## 初步自动诊断

- 模型数据完整：1。
- 论文 PDF 找到：1，四张论文图裁剪完成：1。
- 四张对照图和总览图生成完成：1。
- legacy 默认保持：1，`P.wing.modelType=legacy`，`fullAngleModelEnabled=0`。
- 0 度 full_angle 的 branchWeight 为 0，说明本图没有重新启用旧的 branchWeight 触发路径。
- full_angle 对 legacy 是否更平滑由 `model_trend_diagnostics.csv` 中 `fullAngleSmootherThanLegacy` 给出；该诊断只针对模型曲线，不代表南航误差。
- 若对照图中趋势相似性存在争议，应由 owner 在 `nuaa_visual_judgement_checklist.csv` 中人工填写判断。

## 回归检查

- `check_wing_legacy_identity`：PASS，最大力误差 0，最大力矩误差 0。
- `run_full_angle_zero_nacelle_validation`：PASS，legacy 和 full_angle 均收敛，full_angle branchWeightInNew 为 0。
- `check_article_trends`：已运行；该项是南航表格趋势诊断，不是严格复现证明。
- `run_all_checks`：PASS，33/33 项通过。

## 配平包线摘要

| betaM | model | attempted | completed | converged | timeout | failed | atLimit | clamped |
|---:|---|---:|---:|---:|---:|---:|---:|---:|
| 0 | full_angle | 8 | 8 | 8 | 0 | 0 | 0 | 8 |
| 0 | legacy | 8 | 8 | 8 | 0 | 0 | 0 | 0 |
| 15 | full_angle | 6 | 6 | 6 | 0 | 0 | 0 | 6 |
| 15 | legacy | 6 | 6 | 6 | 0 | 0 | 0 | 0 |
| 45 | full_angle | 8 | 8 | 8 | 0 | 0 | 0 | 8 |
| 45 | legacy | 8 | 8 | 8 | 0 | 0 | 0 | 0 |
| 75 | full_angle | 9 | 9 | 9 | 0 | 0 | 0 | 9 |
| 75 | legacy | 9 | 9 | 9 | 0 | 0 | 0 | 0 |
| 90 | full_angle | 11 | 11 | 11 | 0 | 0 | 0 | 11 |
| 90 | legacy | 11 | 11 | 11 | 0 | 0 | 0 | 0 |

## 结论

VISUAL_OVERLAY_READY_FOR_OWNER_REVIEW
