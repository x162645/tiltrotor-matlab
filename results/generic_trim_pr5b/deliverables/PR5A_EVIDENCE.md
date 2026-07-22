# PR5A 证据

- MATLAB：9.10.0.1602886 (R2021a)
- 生成耗时：40.886 s
- 参数审计行数：219
- XV-15 覆盖记录：22
- Model A：7/9 CREDIBLE
- 敏感性长表：660 行，全部有限实数=1
- 参数敏感性矩阵秩：11，条件数 1829.99
- 声明：结果证明所覆盖工况下的内部一致性，不构成 XV-15 飞行试验验证。

## MATLAB 验证

- 修改前完整回归：23/23 PASS，490.187737 s。
- PR5A 聚焦测试：11/11 PASS；来源元数据补全后的最终复跑为 184.582509 s。
- 修改后完整回归：24/24 PASS，864.893096 s。
- `checkcode`：全部修改/新增 MATLAB 文件 0 条消息。
- 完整回归日志未出现 warning、NaN、Inf 或非预期复数报告。
- `params_nominal.m` 未修改；生产控制限位、配平容差、差分步长和迭代上限未修改。

## claimClass 统计

|claimClass|count|
|---|---|
|CALIBRATED_EFFECTIVE|4|
|GENERIC_ASSUMED|104|
|NUMERICAL_ONLY|71|
|XV15_DERIVED|5|
|XV15_DIRECT|17|
|XV15_LIKE_UNVERIFIED|18|

## 9 点基线

|pointId|betaMDeg|speedMps|mode|status|thetaDeg|collectiveDeg|cyclicLongDeg|elevatorDeg|dynamicResidualNorm|conditionNumber|minimumMarginFraction|elapsedSeconds|failureReason|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|B15_V010|15|10|helicopter_longitudinal|CREDIBLE|12.382021|16.010531|-7.0801172|0|1.0045216e-09|68.763361|0.22872187|19.786144||
|B15_V020|15|20|helicopter_longitudinal|CREDIBLE|9.9167695|14.896371|-11.043859|0|4.4926123e-10|50.879772|0.2128053|11.170804||
|B15_V030|15|30|helicopter_longitudinal|CREDIBLE|7.3740348|14.192631|-13.875839|0|8.7680352e-10|48.495808|0.20275187|17.568442||
|B45_V025|45|25|conversion_longitudinal|CREDIBLE|27.750814|14.537|-27.237139|-15.56408|2.5753941e-10|71.241704|0.1035598|38.320872||
|B45_V035|45|35|conversion_longitudinal|CREDIBLE|21.751023|14.487386|-28.929865|-16.531352|6.5974836e-10|69.160311|0.086716208|16.667586||
|B45_V045|45|45|conversion_longitudinal|CREDIBLE|16.785145|15.277681|-26.620907|-15.211947|1.2193782e-09|70.987178|0.11970132|20.287763||
|B75_V040|75|40|airplane_longitudinal|FAILED|19.186356|18.441714|0|-20|4.6032794|144.51316|-9.5725456e-10|32.980443|solver or full dynamic-equilibrium residual failed|
|B75_V060|75|60|airplane_longitudinal|FAILED|15.401146|23.272499|0|-20|1.3147563|78.048744|-4.5557502e-10|42.403494|solver or full dynamic-equilibrium residual failed|
|B75_V080|75|80|airplane_longitudinal|CREDIBLE|8.0914444|29.49851|0|-9.6560033|1.4877993e-09|30.233947|0.25859992|46.543486||
