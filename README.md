# 倾转旋翼机 MATLAB 正向机理模型 v2

本项目是一套纯 MATLAB、部件级、九状态六自由度倾转旋翼机正向机理模型。

建模主线参考：

- Sheng, Zhang, Xiang (2022), *Mathematical Modeling and Stability Analysis of Tiltrotor Aircraft*；
- 旋翼、机翼、机身、平尾、双垂尾分别计算；
- 部件力和力矩统一转换到当前重心；
- 进入刚体六自由度方程；
- 支持配平、数值线性化、特征值分析和时域仿真。

## 重要定义

机体系：

- x 向前；
- y 向右；
- z 向下。

短舱角：

- `betaM = 0 deg`：直升机模式；
- `betaM = 90 deg`：固定翼模式。

状态：

```matlab
x = [u; v; w; p; q; r; phi; theta; psi];
```

控制：

```matlab
uCtrl = [
    collective;
    differentialCollective;
    longitudinalCyclic;
    differentialLongitudinalCyclic;
    aileron;
    elevator;
    rudder
];
```

控制量均使用 rad。`differentialLongitudinalCyclic` 是文档名称；
当前代码接口中仍使用旧字段名 `diffCyclic`，本阶段暂不改名。

|索引|代码名|文档名|单位|正方向和左右分配|主要作用|
|-:|-|-|-|-|-|
|1|`collective`|`collective`|rad|左右旋翼同加：`right = collective`，`left = collective`|对称总距；直升机模式主要改变总推力，`Fz` 向上增大表现为机体系 `Fz<0`|
|2|`diffCollective`|`differentialCollective`|rad|右旋翼加、左旋翼减：`right = collective + diffCollective`，`left = collective - diffCollective`|差动总距；产生侧向力、滚转力矩和偏航力矩|
|3|`cyclicLong`|`longitudinalCyclic`|rad|左右旋翼同加纵向周期变距：`right = cyclicLong`，`left = cyclicLong`|对称纵向周期变距；倾斜推力并产生俯仰力矩|
|4|`diffCyclic`|`differentialLongitudinalCyclic`|rad|右旋翼加、左旋翼减纵向周期变距：`right = cyclicLong + diffCyclic`，`left = cyclicLong - diffCyclic`|差动纵向周期变距；主要产生偏航力矩；当前定义下 `diffCyclic -> Fy=0` 是结构性零|
|5|`aileron`|`aileron`|rad|正号直接传入机翼副翼模型|机翼滚转控制|
|6|`elevator`|`elevator`|rad|正号直接传入平尾升降舵模型|俯仰控制|
|7|`rudder`|`rudder`|rad|正号直接传入双垂尾方向舵模型|偏航/侧向控制|

当前旋翼控制架构为 `collective / diffCollective / cyclicLong / diffCyclic`。
`diffCyclic` 表示差动纵向周期变距，不是横向周期变距；当前架构物理自洽，
本阶段不增加 `cyclicLat`。

更详细的控制约定见 `docs/CONTROL_CONVENTIONS.md`。

## 快速运行

在 MATLAB 中进入本项目根目录：

```matlab
startup
summary = run_all_checks;
controlReport = check_control_architecture;
trendReport = check_article_trends;
run('examples/demo_single_hover.m');
run_demo
```

时域响应：

```matlab
run('examples/demo_time_response.m');
```

## 目录

```text
tiltrotor_forward_model_v2/
├─ startup.m
├─ params_nominal.m
├─ run_demo.m
├─ model/
│  ├─ validate_inputs.m
│  ├─ mass_properties.m
│  ├─ aero_force_body.m
│  ├─ rotor_model_bemt.m
│  ├─ wing_model.m
│  ├─ fuselage_model.m
│  ├─ horizontal_tail_model.m
│  ├─ vertical_tail_model.m
│  ├─ total_forces_moments.m
│  └─ tiltrotor_eom.m
├─ analysis/
│  ├─ trim_symmetric.m
│  ├─ linearize_numeric.m
│  └─ stability_report.m
├─ examples/
│  ├─ demo_single_hover.m
│  └─ demo_time_response.m
├─ tests/
│  ├─ run_all_checks.m
│  └─ check_article_trends.m
├─ docs/
│  ├─ PAPER_MAPPING.md
│  └─ VALIDATION_STATUS.md
└─ results/
```

## 模型边界

当前参数是自洽的概念参数，不应直接称为精确 XV-15 参数。论文没有完整公开翼型极曲线、全部部件气动数据库、完整挥舞闭合、三维部件位置和实际混控增益，因此这些部分采用可替换的低阶闭合。

本程序包已进行静态组织和方程一致性检查，但生成环境没有 MATLAB/Octave，首次在你的电脑运行时必须先执行：

```matlab
summary = run_all_checks;
```
