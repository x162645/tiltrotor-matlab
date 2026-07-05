# PR #27 Owner 自检审查包

## 一句话结论

可以保留为 Draft 的有限包线研究模型

不建议合并；不建议切默认。

## 红绿灯结果

| 项目 | 结果 | 解释 |
|---|---|---|
| 旧模型安全 | 绿 | legacy identity 通过，最大力误差 0.000e+00，最大力矩误差 0.000e+00。 |
| 默认模型安全 | 绿 | 默认 P.wing.modelType=legacy，fullAngleModelEnabled=0。 |
| branchWeight 移除 | 绿 | full-angle opt-in 路径使用共同系数律，不再混合完整 FNear/FLiftLine 结果，branchWeightInNew=0。 |
| 配平包线真实性 | 绿 | 84 attempted、84 completed、84 converged、0 timeout、0 failed、0 placeholder rows。 |
| 纵向有限包线 | 黄 | 0/15/45/75/90 度包线有真实点证据，但结论只适用于有限纵向研究范围。 |
| 差动副翼 | 黄 | CONTROL_SURFACE_GATE=PARTIAL，差动副翼气动仍未建模。 |
| 深失速桥接 | 黄 | BRIDGE_MODEL_GATE=ENVELOPE_PASS，深失速桥接仍不是完整实验验证。 |
| 尾流假设 | 黄 | WAKE_GEOMETRY_GATE=ENVELOPE_PASS，尾流收缩系数仍是工程假设。 |
| 是否可合并 | 红 | 当前仍是 Draft 有限包线研究模型，不建议合并。 |
| 是否可切默认 | 红 | legacy 必须继续保持默认，不建议切换给普通用户。 |

绿 = 当前证据支持；黄 = 可用于有限范围，但有限制；红 = 不可接受或不应继续。

## 旧模型有没有被破坏

默认模型仍是 `legacy`，`P.wing.modelType=legacy`，`P.wing.fullAngleModelEnabled=0`。
`check_wing_legacy_identity` 通过，最大力误差 0.000e+00，最大力矩误差 0.000e+00。
这说明旧模型仍可按默认路径独立使用，没有被 full-angle opt-in 路径替换。

## 新模型到底能干什么

- 能用于 0 度短舱局部凸起根因验证。
- 能用于纵向有限包线内的新旧模型对比。
- 能作为 full-angle 机翼模型框架继续开发。

## 新模型不能干什么

- 不能声称完整 XV-15 复现。
- 不能声称完整深失速实验验证。
- 不能声称完整横航向操纵品质。
- 不能默认给普通用户使用。
- 不能直接合并后切默认。

## 配平包线是不是真跑了

- 84 attempted；
- 84 completed；
- 84 converged；
- 0 timeout；
- 0 failed；
- 0 placeholder rows。

这些数字来自 `validation/wing_full_angle/trim_envelope/full_angle_trim_envelope_results.csv`、`full_angle_trim_envelope_summary.csv`、`full_angle_trim_envelope_gate_status.csv`，并与 `points/` 下实际 `.mat` 点文件交叉检查。

| betaM deg | model | planned | attempted | completed | converged | timeout | failed | atLimit | clamped | max residual | max full residual | theta range | collective range | cyclicLong range | elevator range |
|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|---|---|---|
| 0 | full_angle | 8 | 8 | 8 | 8 | 0 | 0 | 0 | 8 | 3.766e-09 | 3.766e-09 | 1.349 to 2.712 | 15.440 to 17.203 | -3.513 to 4.306 | 0.000 to 0.000 |
| 0 | legacy | 8 | 8 | 8 | 8 | 0 | 0 | 0 | 0 | 1.856e-09 | 1.856e-09 | -0.000 to 1.565 | 14.315 to 16.770 | -1.417 to 0.001 | 0.000 to 0.000 |
| 15 | full_angle | 6 | 6 | 6 | 6 | 0 | 0 | 0 | 6 | 2.294e-09 | 2.294e-09 | 4.578 to 13.565 | 15.083 to 16.448 | -15.661 to -6.233 | -0.643 to -0.256 |
| 15 | legacy | 6 | 6 | 6 | 6 | 0 | 0 | 0 | 0 | 1.789e-09 | 1.789e-09 | 3.687 to 12.397 | 13.971 to 16.010 | -14.544 to -7.051 | -0.597 to -0.289 |
| 45 | full_angle | 8 | 8 | 8 | 8 | 0 | 0 | 0 | 8 | 5.292e-09 | 5.292e-09 | 4.269 to 21.996 | 14.661 to 27.365 | -27.459 to -4.811 | -15.691 to -2.749 |
| 45 | legacy | 8 | 8 | 8 | 8 | 0 | 0 | 0 | 0 | 2.453e-09 | 2.453e-09 | 4.030 to 21.751 | 14.487 to 28.078 | -28.930 to -5.355 | -16.531 to -3.060 |
| 75 | full_angle | 9 | 9 | 9 | 9 | 0 | 0 | 0 | 9 | 2.461e-08 | 2.461e-08 | 1.677 to 12.383 | 25.743 to 46.417 | -1.772 to 0.146 | -14.105 to 1.162 |
| 75 | legacy | 9 | 9 | 9 | 9 | 0 | 0 | 0 | 0 | 1.396e-08 | 1.396e-08 | 1.077 to 12.132 | 26.194 to 47.018 | -1.987 to 0.159 | -15.815 to 1.268 |
| 90 | full_angle | 11 | 11 | 11 | 11 | 0 | 0 | 0 | 11 | 4.451e-08 | 4.451e-08 | 1.669 to 12.701 | 27.299 to 47.668 | 0.000 to 0.000 | -14.999 to 1.112 |
| 90 | legacy | 11 | 11 | 11 | 11 | 0 | 0 | 0 | 0 | 2.617e-08 | 2.617e-08 | 1.103 to 13.019 | 27.671 to 48.191 | 0.000 to 0.000 | -17.358 to 1.234 |

## 为什么还不能切默认

- 差动副翼没建模，`CONTROL_SURFACE_GATE = PARTIAL`。
- 深失速大部分仍是桥接模型，不是完整实验验证。
- 尾流收缩仍有工程假设。
- 所以当前只能是 `READY_FOR_LIMITED_ENVELOPE_USE`。

## owner 最终建议

继续保留 Draft，不合并，不切默认。
