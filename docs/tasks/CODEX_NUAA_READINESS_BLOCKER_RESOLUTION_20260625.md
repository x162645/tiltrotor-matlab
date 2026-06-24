# Amendment — 高倾角转换配平 readiness blocker 的确定性修复

本文件补充 Issue #24 的主任务和稳定性地图 amendment。先执行本文件；通过后恢复主任务 Stage 2，并继续趋势计算。

## 1. 已确认的根因

`conversion_longitudinal` 在 `betaM=75 deg, V=100 m/s` 尚未进入求解器就失败。失败来自 `make_trim_definition` 的默认初值，不是配平方程、物理控制权限或 `pitch_allocation_schedule` 动态边界本身。

当前高倾角分支仍通过小权重周期变距通道反算虚拟命令：

```matlab
initialPitchCommand = initialCyclic / ...
    (cyclicDirection*gCyclic*cyclicReference)
```

在 75 deg：

```text
gCyclic = cos(75 deg)^2 = 0.0669873
gElevator = 0.9330127
cyclicReference = 35 deg
elevatorReference = 20 deg
pitchCommandLimit = 1/max(gCyclic,gElevator) = 1.0717968
```

用 `initialCyclic=-4 deg` 反算得到：

```text
pitchCommand ~= 1.706
```

超过 `+1.0718`。这是“用接近退出的执行器通道反推虚拟命令”的数值初值缺陷。不得通过放宽命令边界、升降舵限幅或修改余弦分配解决。

## 2. 唯一批准的生产代码修复

只允许修改：

```text
analysis/make_trim_definition.m
tests/check_trim_mode_framework.m
```

如已有更聚焦的 factory 测试文件，可在不重复测试逻辑的前提下使用该文件。

保持 `pitch_allocation_schedule.m`、`trim_general.m`、参数、方程、控制方向、动态命令范围和执行器限幅不变。

### 2.1 初值规则

在 `conversion_longitudinal` 中采用“主导执行器通道反算”的确定性初值：

```text
betaM <= 45 deg:
    theta0 = 4 deg
    collective0 = 16 deg
    direct target = cyclicLong +2 deg
    由 cyclic 通道反算 pitchCommand

45 deg < betaM < 90 deg:
    theta0 = 4 deg
    collective0 = 8 deg
    direct target = elevator -4 deg
    由 elevator 通道反算 pitchCommand

betaM = 90 deg:
    theta0 = 4 deg
    collective0 = 8 deg
    direct target = elevator 0 deg
    由 elevator 通道反算 pitchCommand
```

方向和公式必须从现有 `direction`、`zeroAllocation.gCyclic/gElevator`、`cyclicReference/elevatorReference` 读取，不得复制限幅常数。

高倾角公式：

```matlab
initialPitchCommand = (initialElevatorDeg*d2r)/( ...
    direction.elevatorDirection*zeroAllocation.gElevator* ...
    zeroAllocation.elevatorReference);
```

这只是 NUMERICAL initial seed，不改变物理分配。75 deg 时应约为：

```text
pitchCommand ~= +0.21436
cyclicLong ~= -0.5026 deg
elevator ~= -4.0000 deg
```

且明显位于 `[-1.0718,+1.0718]` 内。

`betaM=45 deg` 保持原低倾角分支，避免改变已经验证的 45 deg 默认初值。

### 2.2 Factory 自校验

在生成初值后，用现有 `pitch_allocation_schedule` 对该初值调用一次。若初值不在动态命令边界内，应由 `make_trim_definition` 抛出专用内部一致性错误，而不是把无效定义交给求解器。不要钳位初值。

## 3. 必须新增的测试

### 3.1 初值域测试

对：

```text
betaM = [0, 15, 45, 60, 75, 89.9, 90] deg
```

创建 `conversion_longitudinal` definition，并验证：

- `initialValues(3)` 有限、实数；
- 严格位于 definition 的 pitchCommand bounds 内；
- 将初值送入 `pitch_allocation_schedule` 不报错；
- 生成的 cyclicLong 和 elevator 均在直接执行器限幅内；
- 0/45/90 deg 已有端点/中点语义不被破坏；
- 75 deg 初值对应 elevator 约 -4 deg，而不是通过小 cyclic 权重反算。

### 3.2 失败复现测试

测试中明确记录旧公式在 75 deg 会得到越界命令，以防回归。不要在生产代码保留旧公式。

### 3.3 聚焦回归

运行：

```matlab
check_trim_mode_framework
check_pitch_allocation
check_trim_credibility
```

然后只运行 readiness 代表点：

```text
conversion_longitudinal, betaM=75 deg, V=100 m/s
```

使用修复后的标准 factory 初值，不先覆盖为其他初值。

通过要求：

- definition 创建成功；
- 配平有限、收敛、可信；
- pitchCommand、cyclicLong、elevator 均不贴限、不越界；
- 不改变当前参数和控制分配。

若标准修复初值仍不收敛，只允许额外运行一次诊断：

```text
theta=4 deg, collective=8 deg, pitchCommand=0
```

该零命令仅用于区分“初值质量”与“工况不可配平”。运行后停止并报告，不得搜索更多种子、不得继续趋势任务。

## 4. 通过后的流程

若 75 deg / 100 m/s readiness 点通过：

1. 提交并推送本次最小 factory 修复；
2. 重新执行主任务 Stage 2 的五个代表点；
3. gate 全部通过后继续固定的南航式配平趋势策略；
4. 稳定性分析按 `CODEX_NUAA_STABILITY_MAP_AMENDMENT_20260625.md` 对全部可信配平点建立地图。

本修复不授权改变主任务规定的速度范围、锚点、延拓方向、参数、限幅或分配。

## 5. 报告要求

报告必须明确区分：

- readiness blocker 是 factory 初值越界；
- 不是 75 deg 工况已经证明缺乏物理控制权限；
- 修复只改变数值初值生成；
- 75 deg 标准初值和最终配平解各自的 pitchCommand / cyclicLong / elevator；
- 是否需要零命令诊断；
- gate 是否允许继续趋势任务。
