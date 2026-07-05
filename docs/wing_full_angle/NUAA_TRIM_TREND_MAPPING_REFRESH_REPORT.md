# 南航配平点趋势对照图变量映射翻新报告（owner 修正版）

## 一句话结论

本报告原先把 0° 和 15° 的 Vertical pitch 都翻新为 `-cyclicLong_deg` 最佳视觉候选；经 owner 人工复查后，该结论必须修正：

- Fig.5(a) 0°：`-cyclicLong_deg` 仍只能作为临时视觉候选，但 owner-visible vertical-pitch / cyclic 曲线仍有明显弯折，不能说 0°最终配平曲线已经完全干净。
- Fig.6(a) 15°：`-cyclicLong_deg` 与南航截图红线的符号和趋势明显不一致，已否决为 15°主对照变量；Fig.6(a) 当前状态为 `FAIL_OR_UNRESOLVED`。
- Fig.5(b) 90° 和 Fig.6(b) 75°：继续使用 `elevator_deg`，趋势方向尚可作为截图级人工对照，但不是数字化验模。

本次更正只修改文档结论与 owner 判读状态，不代表生产模型修复。

## 为什么要更正

原翻新任务的判断过度依赖 0°的符号修正经验，把 `-cyclicLong_deg` 同时用于 0°和15°。后续人工复查标准入口图后发现：

1. 15°南航 Fig.6(a) 的 Vertical pitch 红线位于负值区，并总体向更负方向变化；
2. 当前模型的 `-cyclicLong_deg` 在 15°图中为正值并上升；
3. 因此 Fig.6(a) 的 `-cyclicLong_deg` 不是“未唯一确认的最佳候选”，而是应被否决的候选；
4. 15°问题不能再被描述为单纯版式问题或轻微映射不确定。

## 修正后的映射/趋势状态表

| 图 | 工况 | 南航变量 | 原翻新结论 | owner 修正结论 | 当前状态 |
|---|---:|---|---|---|---|
| Fig.5(a) | 0° | Vertical pitch | 使用 `-cyclicLong_deg` 最佳视觉候选 | 仍可暂作候选，但曲线有明显弯折，0°最终配平曲线未完全干净 | PARTIAL_UNDER_REVIEW |
| Fig.6(a) | 15° | Vertical pitch | 使用 `-cyclicLong_deg` 最佳视觉候选 | `-cyclicLong_deg` 与南航符号和趋势明显不一致，不能作为主候选 | FAIL_OR_UNRESOLVED |
| Fig.5(b) | 90° | Elevator | `elevator_deg` | 继续使用 `elevator_deg` | VISUAL_TREND_ACCEPTABLE_ONLY |
| Fig.6(b) | 75° | Elevator | `elevator_deg` | 继续使用 `elevator_deg` | VISUAL_TREND_ACCEPTABLE_ONLY |

## 当前标准图入口

继续以以下标准入口图为人工判读对象：

- `validation/nuaa_trim_trend_overlay/comparison_boards/nuaa_trim_trend_overlay_overview.png`
- `validation/nuaa_trim_trend_overlay/comparison_boards/compare_fig5a_beta0.png`
- `validation/nuaa_trim_trend_overlay/comparison_boards/compare_fig5b_beta90.png`
- `validation/nuaa_trim_trend_overlay/comparison_boards/compare_fig6a_beta15.png`
- `validation/nuaa_trim_trend_overlay/comparison_boards/compare_fig6b_beta75.png`

但 Fig.6(a) 不得再作为趋势通过证据。

## 这次更正不代表什么

- 不代表模型修复。
- 不代表生产代码修改。
- 不代表严格 XV-15 验模。
- 不代表 full-angle 可以切默认。
- 不代表 XFLR5 已接入 GUI。

## 当前人工判断建议

- 0°：继续保留为 PARTIAL；不要再声称“0°凸起完全消失”。更准确表述是：旧 branchWeight 完整结果混合触发源被移除，但 owner-visible vertical-pitch / cyclic 曲线仍有明显弯折。
- 15°：判为 FAIL_OR_UNRESOLVED；不能继续使用 `-cyclicLong_deg` 作为主对照变量。
- 75°/90°：可以说截图级趋势尚可，但不能说严格验模通过。

## 结论

NUAA_MAPPING_REFRESH_CORRECTED_PARTIAL_WITH_FIG6A_FAIL_OR_UNRESOLVED
