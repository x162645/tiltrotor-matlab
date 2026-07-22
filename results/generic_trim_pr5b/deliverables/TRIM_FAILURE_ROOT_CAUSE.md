# 配平失败根因

## 证据链

1. 生产控制限位保持不变；失败点和所有有限候选均保留。
2. 仅在复制的诊断参数结构中将升降舵临时放宽到 ±80°，该结果不是可飞工况。
3. 75°/60 m/s 在放宽后恢复内部可信配平，表明以控制权不足为主；75°/40 m/s 放宽后仍失败，表明存在几何/模型形式与多重限制。
4. 俯仰力矩分解表明低速 75° 工况存在旋翼、机翼和平尾共同形成的显著低头力矩缺口。

## 基线失败点

|pointId|betaMDeg|speedMps|mode|status|thetaDeg|collectiveDeg|cyclicLongDeg|elevatorDeg|dynamicResidualNorm|conditionNumber|minimumMarginFraction|elapsedSeconds|failureReason|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|B75_V040|75|40|airplane_longitudinal|FAILED|19.186356|18.441714|0|-20|4.6032794|144.51316|-9.5725456e-10|32.980443|solver or full dynamic-equilibrium residual failed|
|B75_V060|75|60|airplane_longitudinal|FAILED|15.401146|23.272499|0|-20|1.3147563|78.048744|-4.5557502e-10|42.403494|solver or full dynamic-equilibrium residual failed|

## 独立升降舵诊断

|pointId|betaMDeg|speedMps|productionStatus|productionElevatorLowerDeg|productionElevatorUpperDeg|productionElevatorDeg|productionPitchMomentGapNm|productionResidualNorm|unconstrainedStatus|unconstrainedElevatorDeg|unconstrainedThetaDeg|unconstrainedResidualNorm|elevatorExceedanceDeg|equivalentAdditionalTailFzN|equivalentTailArmXM|equivalentCGShiftXM|equivalentCLelevatorDelta|equivalentWingCm0Delta|failureClass|note|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|B75_V040|75|40|FAILED|-20|20|-20|-6490.4957|4.6032794|FAILED|-52.909963|35.10296|2.940324|32.909963|1270.4872|23.115315|-0.230194|0.8773246|0.23833886|MULTIPLE_CAUSES|NaN|
|B75_V060|75|60|FAILED|-20|20|-20|-1668.2827|1.3147563|CREDIBLE|-30.382485|21.936465|9.5565804e-10|10.382485|326.55931|-6.5178495|-0.034124316|0.099650385|0.027833556|CONTROL_AUTHORITY_LIMITED|NaN|
|B75_V080|75|80|CREDIBLE|-20|20|-9.6560033|-2.060728e-05|1.4877993e-09|CREDIBLE|-9.6560033|8.0914444|3.6945109e-09|0|4.0337884e-06|-5.1086667|-3.5374797e-10|1.3871961e-09|1.9409543e-10|NONE_CREDIBLE_BASELINE|NaN|

## 关于实际重心的总俯仰力矩

|pointId|MyNm|elevatorDeg|controlAtLimit|
|---|---|---|---|
|B75_V040|-6490.4957|-20|true|
|B75_V060|-1668.2827|-20|true|
