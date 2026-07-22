# 参数可辨识性分析

方法为中心参数差分与局部隐函数配平修正。矩阵覆盖 5 个代表工况、11 个候选量及姿态/控制/裕度代理/部件俯仰力矩输出。

数值秩：11 / 11；条件数：1829.99。

条件数较高表示仅凭这些稳态配平输出仍存在强相关；后续每阶段最多选择 4–6 个变量，且优先选择几何层。有效气动参数只能称为 `CALIBRATED_EFFECTIVE`。

## 奇异值

|index|singularValue|
|---|---|
|1|59.63355|
|2|12.766832|
|3|8.9998744|
|4|6.7646355|
|5|1.8677576|
|6|1.2036131|
|7|0.74137722|
|8|0.37041422|
|9|0.094417997|
|10|0.058032546|
|11|0.032586882|

## |相关系数|≥0.95 的参数对

|parameterA|parameterB|absoluteCorrelation|
|---|---|---|
|cgX|wingACX|0.96785126|
|cgX|wingCm0|0.95945716|
|cgZ|rotorHubZ|0.98684652|
|tailArea|tailArmX|0.99883526|
|tailIncidence|tailCLelevator|0.99676975|
|tailIncidence|tailDownwashAlpha|0.99324217|
|wingACX|wingCm0|0.9940281|
|tailCLelevator|tailDownwashAlpha|0.99528853|
