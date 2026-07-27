# 操纵输入接口事实核查

## 核查结论

本文件记录现有代码接口，不改变控制分配、输入顺序或物理模型。九状态模型的控制向量共 7 列，顺序为：

|列|代码变量|报告术语|单位|正向分配或作用|
|---:|---|---|---|---|
|1|`collective`|对称总距|rad|左右旋翼共同增加|
|2|`diffCollective`|差动总距|rad|右侧加、左侧减|
|3|`cyclicLong`|对称纵向周期变距|rad|左右旋翼纵向周期量共同增加|
|4|`diffCyclic`|差动纵向周期变距|rad|右侧加、左侧减|
|5|`aileron`|副翼|rad|按机翼模型的既有正号|
|6|`elevator`|升降舵|rad|按平尾模型的既有正号|
|7|`rudder`|方向舵|rad|按垂尾模型的既有正号|

短舱角 `betaM`（\(\beta_M\)）是九状态模型的外部构型参数，单位为 rad；它不是九状态 \(B\) 矩阵的第五列。侧滑角在报告和分析代码中另记为 `betaSlip`（\(\beta_{\rm slip}\)），二者不得混用。

`diffCyclic` 是代码接口保留的历史名称。学术正文统一称“差动纵向周期变距”（`differentialLongitudinalCyclic`）。副翼、差动总距和差动纵向周期变距是三个独立通道，不共享符号，也不能统称为同一个横向操纵量。

## 左右旋翼分配与周期变距符号

正式载荷路径采用：

\[
\begin{aligned}
\theta_{0,R}&=\mathrm{collective}+\mathrm{diffCollective},&
\theta_{0,L}&=\mathrm{collective}-\mathrm{diffCollective},\\
\theta_{\mathrm{cyc},R}&=\mathrm{cyclicLong}+\mathrm{diffCyclic},&
\theta_{\mathrm{cyc},L}&=\mathrm{cyclicLong}-\mathrm{diffCyclic}.
\end{aligned}
\]

每侧旋翼内部再按旋向映射：

\[
\theta_{1s,\mathrm{side}}=-\,\mathrm{rotDir}\,
\theta_{\mathrm{cyc},\mathrm{side}} .
\]

因此，外部公共纵向周期变距的正号定义与桨叶一阶谐波系数的正号并不相同；解释导数时必须保留这一级旋向映射。

## 十三状态力矩输入接口

十三状态力矩输入模型共 10 列：

1. `collective`（rad）
2. `diffCollective`（rad）
3. `cyclicLong`（rad）
4. `diffCyclic`（rad）
5. `lateralCyclic`（rad）
6. `aileron`（rad）
7. `elevator`（rad）
8. `rudder`（rad）
9. `nacelleTorqueLeft`（N·m）
10. `nacelleTorqueRight`（N·m）

其中末两列为直接短舱力矩输入。九状态 7 个物理操纵通道映射到该接口的列索引为 `[1 2 3 4 6 7 8]`。

## 十三状态命令输入接口

十三状态命令输入模型共 10 列：

1. `collective`（rad）
2. `diffCollective`（rad）
3. `cyclicLong`（rad）
4. `diffCyclic`（rad）
5. `lateralCyclic`（rad）
6. `aileron`（rad）
7. `elevator`（rad）
8. `rudder`（rad）
9. `betaMLCommand`（rad）
10. `betaMRCommand`（rad）

前 8 列为物理操纵或旋翼操纵命令，后 2 列为左右短舱角命令。短舱角命令经过十三状态执行机构动态，不等于直接物理控制导数；报告分别给出直接物理输入与命令输入的 \(B\) 矩阵结果。

## 代码证据

|事实|权威代码位置|核查结果|
|---|---|---|
|九状态控制顺序与左右分配|`model/total_forces_moments.m`|与上表一致|
|九状态配平控制名|`analysis/evaluate_trim_definition_point.m`|与上表一致|
|十三状态力矩输入名|`model/berger13/get_control_input_names_13x10.m`|10 列顺序与上表一致|
|十三状态力矩输入单位|`model/berger13/get_control_input_units_13x10.m`|前 8 列 rad，后 2 列 N·m|
|十三状态命令输入名|`model/berger13/get_command_input_names_13x10.m`|10 列顺序与上表一致|
|十三状态命令输入单位|`model/berger13/get_command_input_units_13x10.m`|全部为 rad|
|周期变距内部旋向映射|`model/rotor_model_bemt.m`|`theta1s=-rotDir*cyclicLong`|
|短舱角在九状态模型中的角色|`model/tiltrotor_eom.m`|独立函数参数，不在控制向量内|

## 后处理约束

- 所有 \(B\) 矩阵表必须使用上述权威列名，不能按旧文档重命名列。
- \(B\) 矩阵是状态导数对输入的 Jacobian，不直接等于气动力系数导数。
- 从 \(B\) 矩阵反推力和力矩时必须使用总质量、完整惯量矩阵、输入单位以及九状态到十三状态的列映射。
- 直接物理控制输入结果和短舱执行机构命令输入结果分别标识，不合并解释。
