# 优化问题定义

本研究在不修改默认参数、控制限制、惯量、可信度门禁和数值容差的前提下，对冻结的9点设计可行性集求解。

目标函数为 `J = J_fail + J_residual + J_conditioning + J_margin + J_external`。失败点权重为每点10000；残差和条件数采用对数罚项；控制/未知量裕度以5%、10%、15%三档假设设计要求构造罚项；`J_external=0`，外部留出资料不参与参数选择。C1只允许三个几何变量；C2只额外允许一个 `CALIBRATED_EFFECTIVE` 升降舵效能导数。`downwashAlpha` 因可辨识性风险冻结。

随机种子固定为 `20260723`。探索失败、接口失败、边界触碰与未收敛状态均保存在运行数据库。该有限搜索不能证明全局最优。

## 冻结边界

|path|lowerBound|upperBound|frozenValue|unit|class|formalC1|formalC2|
|---|---|---|---|---|---|---|---|
|wing.xAC|-0.4|0.4|0.1|m|GEOMETRY|True|True|
|rotor.pivotZ|-0.6|0.6|0.1|m|GEOMETRY|True|True|
|htail.incidence|-5|2|-5|deg|GEOMETRY|True|True|
|htail.CLelevator|1.6|2.4|2.35|1/rad|CALIBRATED_EFFECTIVE|False|True|
|htail.downwashAlpha|0.3|0.5|0.4|1|REJECTED_CORRELATED|False|False|
