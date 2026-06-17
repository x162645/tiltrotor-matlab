# 论文公式与 MATLAB 文件对应关系

| 论文内容 | MATLAB 实现 |
|---|---|
| 式(1)–(3)：重心与惯量随短舱角变化 | `model/mass_properties.m` |
| 式(4)：挥舞运动 | `model/rotor_model_bemt.m` 中的一阶谐波准定常闭合 |
| 式(5)：轮毂局部速度与坐标关系 | `model/rotor_model_bemt.m` |
| 式(6)–(11)：叶素速度、升阻力、推力和扭矩 | `rotor_model_bemt.m` 内部函数 `blade_loads` |
| 式(12)：一阶非均匀入流 | `viField` |
| 式(13)：诱导速度迭代 | 固定点动量迭代 |
| 式(14)–(15)：旋翼力矩转换和力臂矩 | 基向量转换及 `cross(rHub,F)` |
| 式(16)–(22)：机翼滑流区和自由流区 | `model/wing_model.m` |
| 式(23)–(24)：机身 | `model/fuselage_model.m` |
| 式(25)–(26)：平尾 | `model/horizontal_tail_model.m` |
| 式(27)–(30)：双垂尾 | `model/vertical_tail_model.m` |
| 式(31)–(32)：整机合力与合矩 | `model/total_forces_moments.m` |
| 式(33)–(36)：六自由度动力学与运动学 | `model/tiltrotor_eom.m` |
| 式(37)：配平 | `analysis/trim_symmetric.m` |
| 式(38)–(42)：线性化 | `analysis/linearize_numeric.m` |
| 特征值分析 | `analysis/stability_report.m` |

## 必要差异

论文没有公开完整翼型曲线、挥舞气动力矩闭合、桨叶惯量和铰参数、全部气动系数、完整三维部件位置、真实控制分配规律和原始程序。

当前程序复现的是论文的部件分解方法、正向力学链路、坐标转换、六自由度、配平和线性化过程。缺失部分采用可替换的低阶闭合。
