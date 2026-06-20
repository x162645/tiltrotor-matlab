# 倾转旋翼机分析工作台：架构与需求

## 1. 目标

本工作台为现有 MATLAB 倾转旋翼机概念机理模型提供用户友好的可视化入口，覆盖：

1. 关键参数查看、运行时修改和合法性检查；
2. 对称稳态配平；
3. 配平点数值线性化；
4. 特征值、自然频率、阻尼比和稳定性分类；
5. 小扰动操纵响应；
6. 参数、配平、线性化和响应结果的 `.mat` 工况导出。

该界面不会把当前模型描述为 XV-15 高保真或试验验证模型。所有基准参数仍来自 `params_nominal.m`，界面修改只作用于内存中的参数副本。

## 2. 技术选择

采用纯文本、程序化 UI：

```text
run_app.m
  -> startup.m
  -> app/launch_tiltrotor_app.m
```

没有使用二进制 `.mlapp` 文件，原因包括：

- 便于 GitHub 审查和逐行 diff；
- 便于 Codex 修改；
- 与现有 MATLAB R2021a 环境配合；
- GUI 与计算服务可以独立测试；
- 不要求 App Designer 工程文件参与版本合并。

## 3. 分层结构

```text
可视化层
app/launch_tiltrotor_app.m
        |
        v
服务层
services/validate_parameter_set.m
services/run_trim_case.m
services/build_trim_diagnostic.m
services/build_exception_diagnostic.m
services/run_linearization_case.m
services/simulate_linear_response.m
services/save_analysis_case.m
        |
        v
现有分析与模型层
analysis/trim_symmetric.m
analysis/linearize_numeric.m
model/tiltrotor_eom.m
model/total_forces_moments.m
```

GUI 回调不得复制旋翼、气动、刚体方程、配平目标或线性化公式。底层模型仍是唯一物理计算来源。

诊断服务只整理已有服务结果或已捕获异常，不重新运行配平、线性化或响应，不修改参数结构。

## 4. 页面功能

### 4.1 关键参数

当前第一版暴露：

- 空气密度、重力；
- 总质量、倾转组件质量；
- `Ixx/Iyy/Izz/Ixz`；
- 旋翼半径、角速度、弦长；
- 旋翼径向和方位离散数；
- 机翼面积、翼展、平均弦长；
- 配平残差容限、最大迭代数；
- 线性化控制差分步长。

界面同时显示字段名、单位和来源分类。参数变化后，旧配平、线性化与响应结果立即失效。

当前未把所有 174 个参数放入 GUI。第一版优先覆盖用户经常调整且语义明确的关键参数；完整参数数据库可在后续版本加入搜索、分组和来源详情页。

### 4.2 配平

输入：

- 空速 `V`，m/s；
- 短舱倾转角 `betaM`，deg；
- 航迹角 `gamma`，deg；
- 初始俯仰角、总距、纵向周期变距，deg；
- 俯仰搜索限幅；
- 多初值选项。

调用：

```matlab
[xTrim,uTrim,report] = trim_symmetric(V,betaM,P,opts)
```

显示：

- 总览：接受状态、求解器状态、目标残差范数、九状态导数范数、限幅状态、候选数量和无效模型评估数量；
- 状态与操纵：9 状态和 7 操纵量；
- 残差与限幅：全部 9 个状态导数，并标出 `udot/wdot/qdot` 三个配平目标；同时显示 `theta/collective/cyclicLong` 限幅和角度裕度；
- 多初值候选：每个候选的初值、终值、代价、残差范数、退出标志、接受状态和限幅状态。

线性化按钮只有在 `report.converged == true` 时启用。

配平结果包含 `diagnostic.kind = 'trim-diagnostic'` 的诊断结构。该结构只使用 `trim_symmetric` 已返回的 report 字段和服务层已知的残差容限。

### 4.3 线性化与模态

调用：

```matlab
[A,B,report] = linearize_numeric(xTrim,uTrim,betaM,P)
```

显示：

- `A`，9×9；
- `B`，9×7；
- 特征值复平面；
- 每个特征值的实部、虚部、自然频率、阻尼比、时间尺度和分类；
- 右半平面特征值警告。

### 4.4 操纵响应

线性小扰动方程：

```text
d(delta x)/dt = A*delta x + B*delta u
```

采用 `ode45` 积分，不依赖 Control System Toolbox。

支持输入：

- step；
- pulse；
- sine；
- doublet。

支持 7 个操纵通道和 9 个状态输出。界面可切换显示扰动量或叠加配平后的实际总量。角度输入以 degree 填写，进入模型前统一转换为 radian。

响应模块检查实际操纵历史是否越过当前控制限幅。该检查用于警告；线性模型本身不执行非线性饱和。

## 5. 数据结构

### 配平结果

```text
trimResult.config
trimResult.xTrim
trimResult.uTrim
trimResult.xdot
trimResult.report
trimResult.loads
trimResult.success
```

### 线性化结果

```text
linearResult.A
linearResult.B
linearResult.eigenvalues
linearResult.naturalFrequency
linearResult.dampingRatio
linearResult.timeScale
linearResult.classification
linearResult.trim
```

### 响应结果

```text
responseResult.time
responseResult.deltaState
responseResult.actualState
responseResult.deltaControl
responseResult.actualControl
responseResult.limitWarning
```

### 当前操作诊断

界面底部保留一个当前操作诊断面板，只显示最新一次参数检查、配平、线性化、响应、导出或异常的信息。字段包括阶段、级别、错误标识或 reason codes、摘要、细节和建议。面板提供复制按钮；若当前 MATLAB 环境支持 `clipboard`，会复制纯文本诊断摘要。

## 6. 运行方式

在 MATLAB 中：

```matlab
cd('E:\tiltrotor');
run_app;
```

或：

```matlab
cd('E:\tiltrotor');
startup;
launch_tiltrotor_app;
```

PowerShell：

```powershell
& 'F:\matlab\R2021a\bin\matlab.exe' -r "cd('E:\tiltrotor'); run_app"
```

## 7. 验证顺序

先运行无图形服务检查：

```powershell
& 'F:\matlab\R2021a\bin\matlab.exe' -batch "cd('E:\tiltrotor'); startup; report = check_gui_services; assert(report.allPassed);"
```

然后运行原总回归：

```powershell
& 'F:\matlab\R2021a\bin\matlab.exe' -batch "cd('E:\tiltrotor'); startup; summary = run_all_checks; assert(summary.allPassed);"
```

最后人工打开界面，依次验证：

1. 默认参数检查；
2. 悬停配平；
3. 悬停线性化；
4. `cyclicLong` 0.1 deg 阶跃、0.5 s 响应；
5. 参数修改导致旧结果失效；
6. 工况导出可成功加载。

## 8. 第一版验收标准

- R2021a 可以打开界面；
- 默认参数通过校验；
- 默认悬停配平通过；
- 可以生成有限实数 `A/B`；
- 可以显示 9 个特征值；
- 四种输入波形可以生成有限响应；
- 不依赖 Control System Toolbox；
- 修改参数不会写回 `params_nominal.m`；
- 未收敛配平不能进入线性化；
- 所有异常均显示真实错误，不把 NaN、Inf、复数或不收敛隐藏为成功；
- 原模型回归保持通过。

## 9. 已知范围

- 配平仍是当前 `trim_symmetric` 定义的三变量对称配平；
- 响应为单个配平点附近的小扰动线性响应；
- 未加入非线性时域响应、位置航迹、控制器、参数扫描和批量包线；
- UI 参数来源标签来自当前概念模型分类，不能作为型号数据证明；
- Draft PR 在本机 MATLAB 验证通过前不得合并。
