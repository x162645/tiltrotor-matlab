# 来源角度与符号约定

本文件冻结比较所用映射；所有模型输入角均为 rad，表格展示角为 deg。

|量|本项目约定|来源约定与映射|
|---|---|---|
|机体系|x 前、y 右、z 下；正 My 为右手定则俯仰力矩|所有来源先转换到本项目机体系|
|短舱角 betaM|0° 直升机，90° 飞机|若来源 deltaNac 为 0° 飞机、90° 直升机，则 betaM=90°-deltaNac|
|NUAA|代码已按 betaM=0° 直升机、90° 飞机解释其诱导速度方向|只作方法/趋势比较，不宣称完全同构|
|Berger|论文图中的 nacelle angle 须逐图核实；本项目展示统一转为 betaM|Berger generic model 不是 XV-15 真值|
|NASA XV-15|公开报告常用 conversion angle 0° airplane、90° helicopter|仅在原文定义明确时使用 betaM=90°-deltaNac|
|俯仰角 theta|机体相对惯性系的 3-2-1 欧拉俯仰角，抬头为正|来源曲线若符号不同必须单独标注|
|升降舵|正输入增大平尾 CL、产生更负 My；当前配平通常需负升降舵|不得仅凭曲线形状反转符号|
|总距|左右旋翼共同增加 collective|rad；图表用 deg|
|纵向周期变距|正 cyclicLong 使两盘法向共同向 +eD 倾斜|内部 theta1sSide=-rotDir*cyclicSide|

自动测试同时检查端点角度映射、控制方向与默认路径不变。
