# 南航配平趋势对照图版式修复报告

## 一句话结论

已修复标准入口图版式，并已覆盖标准入口总览图和四张单独对照图。本任务只修复验证图片版式，没有修改模型、没有调参、没有切换默认模型。

## 覆盖的标准入口图

- `validation/nuaa_trim_trend_overlay/comparison_boards/nuaa_trim_trend_overlay_overview.png`
- `validation/nuaa_trim_trend_overlay/comparison_boards/compare_fig5a_beta0.png`
- `validation/nuaa_trim_trend_overlay/comparison_boards/compare_fig5b_beta90.png`
- `validation/nuaa_trim_trend_overlay/comparison_boards/compare_fig6a_beta15.png`
- `validation/nuaa_trim_trend_overlay/comparison_boards/compare_fig6b_beta75.png`

## 版式标准

- 总览图：4 行 x 2 列。
- 单图：1 行 x 2 列。
- 左列：南航论文截图。
- 右列：模型计算趋势图。
- 总览图不包含候选变量审计表、CSV 表格或大段说明文字。
- 单图只保留必要图注：`NUAA curve is screenshot reference only; no formal digitization.`

## 变量状态

- 0 deg vertical pitch 使用 `-cyclicLong_deg`。
- 15 deg vertical pitch 暂用 `-cyclicLong_deg`，但未唯一确认；图注保留 `best visual candidate; not uniquely confirmed`。
- 75 deg 和 90 deg 使用 `elevator_deg`。

## 没有做什么

- 没有数字化南航曲线。
- 没有调参。
- 没有修改 `params_nominal.m`。
- 没有修改 `model/`。
- 没有切换默认模型。
- 没有合并 PR。

## 结论

NUAA_LAYOUT_FIX_READY
