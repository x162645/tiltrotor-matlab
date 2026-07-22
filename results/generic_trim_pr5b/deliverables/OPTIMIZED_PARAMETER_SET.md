# 优化参数集

Model C1（纯几何、opt-in）：`wing.xAC=+0.10 m`、`rotor.pivotZ=+0.10 m`、`htail.incidence=-5 deg`。

Model C2（opt-in）：继承C1，并设 `htail.CLelevator=2.35 1/rad`。该导数分类为 `CALIBRATED_EFFECTIVE`，不是XV-15实测值；它可能吸收未建模尾翼/舵面/干扰效应。默认 `params_nominal.m` 与 `params_berger13()` 不变。

|path|lowerBound|upperBound|frozenValue|unit|class|formalC1|formalC2|
|---|---|---|---|---|---|---|---|
|wing.xAC|-0.4|0.4|0.1|m|GEOMETRY|True|True|
|rotor.pivotZ|-0.6|0.6|0.1|m|GEOMETRY|True|True|
|htail.incidence|-5|2|-5|deg|GEOMETRY|True|True|
|htail.CLelevator|1.6|2.4|2.35|1/rad|CALIBRATED_EFFECTIVE|False|True|
|htail.downwashAlpha|0.3|0.5|0.4|1|REJECTED_CORRELATED|False|False|
