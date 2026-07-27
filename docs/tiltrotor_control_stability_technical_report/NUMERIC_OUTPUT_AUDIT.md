# 数值输出完整性核查

- 核查时间：2026-07-26T23:12:36.628027
- CSV 数量：14
- Inf：0
- 非预期复数文本：0
- 非预期缺失/NaN：0

## 结构性不适用值

模态周期、半衰时间、倍增时间和实根时间常数只对相应根型适用；阶跃上升时间、超调和首个失效索引也可能按定义不适用；失败配平点不具有可用配平量。这些字段保留为空或 NaN，不能解释为数值计算失败。

|文件|字段|数量|
|---|---|---:|
|CONTROL_STEP_RESPONSE_METRICS.csv|firstInvalidIndex|18|
|MODAL_PARAMETERS.csv|dampingRatio|15|
|MODAL_PARAMETERS.csv|doublingTimeSeconds|96|
|MODAL_PARAMETERS.csv|halfAmplitudeTimeSeconds|24|
|MODAL_PARAMETERS.csv|oscillationPeriodSeconds|57|
|MODAL_PARAMETERS.csv|realRootTimeConstantSeconds|72|
|TRIM_CHARACTERISTICS_BY_MODE.csv|pitchCommand|6|

## 非预期项

- 无。
