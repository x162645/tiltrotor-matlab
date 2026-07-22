# 线性—非线性一致性

在可信工况 `B45_V035`，分别施加 `betaSymCommand`、`betaDiffCommand`、`lateralCyclic`、副翼和方向舵小阶跃。比较状态为 `u,v,p,q,r,phi,theta,psi,betaSym,betaDiff`，使用相同固定步长时间网格。

|输入|最大峰值绝对误差|最大 RMS 误差|说明|
|-|-:|-:|-|
|`betaSymCommand` 0.05°|`2.79e-5`|`1.17e-5`|局部一致|
|`betaDiffCommand` 0.05°|`2.38e-3`|`8.58e-4`|五项中误差最大，仍为小扰动局部比较|
|`lateralCyclic` 0.02°|`2.59e-6`|`1.32e-6`|局部一致|
|副翼 0.05°|`2.70e-8`|`1.59e-8`|局部一致|
|方向舵 0.05°|`2.05e-6`|`8.93e-7`|局部一致|

峰时差对极小/单调响应并非稳健的相位指标，因此原始表保留数值但不单独据此判定有效性。上述结果只确定本幅值与时域内线性化的一阶局部一致性，不是外部验证。原始逐状态结果见 `raw_data/13X10_LINEAR_NONLINEAR_METRICS.csv`。
