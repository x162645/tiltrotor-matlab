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

## 快速运行

在 MATLAB 中进入本项目根目录：

```matlab
startup
summary = run_all_checks;
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
