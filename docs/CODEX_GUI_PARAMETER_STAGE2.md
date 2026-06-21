# Codex Stage 2：GUI 参数目录与校验服务

## 状态

当前分支：`feature/gui-v1.2-parameter-workbench`

Stage 1 只读参数审计已通过。批准目标为 **139 个可编辑标量分量**。

本轮只执行 Stage 2：参数目录、读写、筛选、依赖更新、完整校验和聚焦测试。

不要修改 GUI 布局，不要运行 `run_all_checks`，不要提交，不要推送。

---

## 一、实现目标

建立唯一参数目录，覆盖审计批准的 139 个可编辑标量分量。

参数目录必须成为后续 GUI 参数页面的唯一来源，统一管理：

- 参数元数据；
- 参数读取；
- 参数写入；
- 显示单位转换；
- 允许范围；
- 参数依赖；
- 校验规则；
- 常用或高级分组；
- 搜索和筛选。

不得为了达到 139 而加入没有生产消费者或意义不明确的字段。若实际目录数量无法达到 139，立即停止并报告差异，不得伪造条目。

---

## 二、允许修改和新增文件

```text
CODEX_TASK.md
services/build_parameter_catalog.m
services/get_parameter_catalog_value.m
services/set_parameter_catalog_value.m
services/filter_parameter_catalog.m
services/validate_parameter_set.m
tests/check_gui_parameter_catalog.m
docs/GUI_PARAMETER_CATALOG.md
```

本轮禁止修改：

```text
app/launch_tiltrotor_app.m
params_nominal.m
model/*
analysis/*
tests/run_all_checks.m
```

---

## 三、批准的目录数量

```text
环境                 2
质量与惯量          12
旋翼                29
机翼                21
机身                21
平尾                15
垂尾                 7
操纵限幅            10
配平计算             5
线性化计算          17
合计               139
```

可以在内部使用子类别，例如：

```text
旋翼几何
旋翼气动
旋翼计算设置
机翼几何
机翼气动
```

但目录主类别必须清晰、稳定。

---

## 四、目录条目结构

`build_parameter_catalog` 返回稳定排序的结构数组。每个条目至少包含：

```text
id
category
name
description
basis
tier
displayUnit
internalUnit
path
subscript
valueType
displayScale
displayOffset
minimum
maximum
minimumInclusive
maximumInclusive
integerRequired
writePolicy
dependencyGroup
```

要求：

- `id` 是稳定内部标识，不显示给用户；
- `category`、`name`、`description`、`basis`、`displayUnit` 必须是自然中文；
- `tier` 只允许 `basic` 或 `advanced`；
- 不使用 `eval`；
- 通用结构路径与索引通过安全遍历实现；
- 特殊依赖仅通过明确、有限的 `writePolicy` 处理；
- 不把 139 个条目重新写成 GUI 回调中的大型 `switch`。

面向用户的 `basis` 仅使用以下类型：

```text
环境设定
质量与惯量设定
几何设定
气动模型设定
操纵范围设定
计算精度设置
```

不得出现在任何面向用户字段中的词语：

```text
ASSUMED_CONCEPT
NUMERICAL
REFERENCE_CONSTANT
reason code
Stage 1
Stage 2
Git
PR
内部字段路径
```

---

## 五、必须排除

参数目录中不得出现：

```text
mass.RH
rotor.inflowHarmonic
rotor.flapCyclicGain
rotor.flapMuGain
rotor.flapLatMuGain
rotor.flapQGain
rotor.flapPGain
rotor.flapMax
rotor.Ib
rotor.Sblade
rotor.flapInitial(1:3)
wing.b
vtail.c
bladeMassDistribution
trim.display
mass.I0 的对称重复项
mass.KI 的非对角零项
```

---

## 六、批准纳入的参数边界

### 环境：2

- 空气密度；
- 重力加速度。

### 质量与惯量：12

- 总质量；
- 倾转组件总质量；
- 移动质量等效半径；
- `I0` 六个独立分量：`Ixx/Iyy/Izz/Ixy/Ixz/Iyz`；
- `KI` 三个对角分量：`KIxx/KIyy/KIzz`。

### 旋翼：29

纳入审计批准的几何、气动、离散、诱导速度、挥舞求解、桨叶质量、尾流与极惯量参数。

### 机翼：21

不得包含 `wing.b`。`wing.SslipMaxHalf` 显示单位为 `m^2`。

### 机身：21

纳入参考面积、参考长度、气动中心三个分量以及全部当前生产代码使用的气动导数。

### 平尾：15

纳入几何、气动中心三个分量、安装角、下洗及当前生产代码使用的气动系数。

### 垂尾：7

不得包含 `vtail.c`。

### 操纵限幅：10

五组上下限分别展开：

```text
总距下限 / 上限
周期变距下限 / 上限
副翼下限 / 上限
升降舵下限 / 上限
方向舵下限 / 上限
```

### 配平计算：5

- 残差容限；
- 最大迭代次数；
- 三个变量搜索尺度。

### 线性化计算：17

- `linear.dx` 九个通道；
- `linear.du` 七个通道；
- 稳定性判据。

---

## 七、读写服务

### 1. 读取

实现：

```matlab
value = get_parameter_catalog_value(P, item)
```

返回 GUI 显示单位下的标量值。

### 2. 写入

实现：

```matlab
[Pnew, result] = set_parameter_catalog_value(P, item, displayValue)
```

要求：

- 先复制候选参数结构；
- 执行显示单位到内部单位转换；
- 完成依赖更新；
- 调用完整参数校验；
- 所有步骤成功后才返回修改后的结构；
- 失败时原 `P` 必须完全不变；
- `result` 至少包含：

```text
success
message
changedIds
derivedUpdates
```

失败消息必须是自然中文，不显示内部字段路径。

---

## 八、特殊写入策略

### 1. 旋翼半径和桨叶质量

修改任一项后，在同一候选结构中原子更新：

```matlab
P.rotor.Ib = P.rotor.bladeMass*P.rotor.R^2/3;
P.rotor.Sblade = P.rotor.bladeMass*P.rotor.R/2;
```

`Ib` 与 `Sblade` 不允许直接编辑。

### 2. 惯量矩阵

只暴露：

```text
Ixx Iyy Izz Ixy Ixz Iyz
```

写入惯量积时同步镜像：

```text
I0(1,2) = I0(2,1)
I0(1,3) = I0(3,1)
I0(2,3) = I0(3,2)
```

校验：

- 有限；
- 对称；
- 正定。

### 3. 倾转惯量变化率

只暴露：

```text
KIxx KIyy KIzz
```

修改后检查：

```matlab
I(betaM) = I0 - betaM*KI
```

至少在 `betaM=0 deg` 和 `betaM=90 deg` 保持正定。

### 4. 操纵限幅

GUI 使用 `deg`，内部使用 `rad`。

任一上下限修改后，必须验证同组：

```text
lower < upper
```

不得自动交换上下限。

### 5. 角度参数

以下参数 GUI 显示为 `deg`，内部存储为 `rad`：

```text
rotor.twistTip
rotor.flapDivergenceAngle
htail.incidence
全部操纵限幅
trim.variableScale 三项
linear.dx 中 phi/theta/psi
linear.du 七项
```

`linear.dx` 中 `p/q/r` 必须明确显示为角速度差分单位，例如 `deg/s`，并进行可逆转换。

### 6. 线性化差分步长

独立展开并独立写入：

```text
dx.u
dx.v
dx.w
dx.p
dx.q
dx.r
dx.phi
dx.theta
dx.psi

du.collective
du.diffCollective
du.cyclicLong
du.diffCyclic
du.aileron
du.elevator
du.rudder
```

修改一个通道不得改变其他通道。

---

## 九、扩展参数校验

扩展 `validate_parameter_set`，覆盖全部目录相关结构。

保持原返回字段兼容：

```text
valid
errors
warnings
errorCount
warningCount
summary
```

所有可能展示到 GUI 的 `summary/errors/warnings` 必须是中文，不显示 `P.xxx` 路径。

硬错误至少包括：

- 非有限值或复数；
- 应为正值却非正；
- 整数参数不是合法整数；
- 面积、长度、质量、惯量非法；
- `I0` 不对称或非正定；
- `I0-betaM*KI` 在 0 或 90 度非正定；
- 操纵上下限顺序错误；
- `rootCut` 不在 `[0,1)`；
- 松弛因子不在 `(0,1]`；
- `CLmax <= 0`；
- 阻力基值或阻力二次项为负；
- 差分步长、容差或正则化量非正；
- 线性化向量长度错误。

对于有符号气动导数，例如：

```text
CLalpha
CYbeta
Cmalpha
Clbeta
Cmq
Cnr
```

只验证有限性与合理数量级，不根据当前符号强制正负。

允许使用警告提示极端值，但不得自动更改参数。

---

## 十、筛选服务

实现：

```matlab
filtered = filter_parameter_catalog(catalog, options)
```

支持：

```text
category
tier = basic / advanced / all
query
modifiedIds
modifiedOnly
```

关键词至少搜索：

```text
name
category
description
basis
```

中文搜索必须正常工作，英文比较忽略大小写。

---

## 十一、文档

新增：

```text
docs/GUI_PARAMETER_CATALOG.md
```

记录：

- 139 项总数；
- 类别数量；
- 常用/高级数量；
- 完整参数目录；
- 显示单位与内部单位；
- 依赖关系；
- 排除目录与原因；
- 校验规则；
- GUI 不显示内部字段路径的约束；
- `wing.SslipMaxHalf` 单位为 `m^2`。

---

## 十二、聚焦测试

新增：

```text
tests/check_gui_parameter_catalog.m
```

至少验证：

1. 目录数量严格为 139；
2. ID 唯一且排序稳定；
3. 类别数量与审计一致；
4. 每项中文名称、单位、说明、依据完整；
5. 禁止词不出现在任何面向用户字段；
6. 排除字段不存在；
7. 139 项读取均为有限实数；
8. 每项写回原值后，参数结构 `isequaln` 不变；
9. 每个类别至少选择一个参数进行真实修改和恢复；
10. `rotor.R` 依赖更新正确；
11. `rotor.bladeMass` 依赖更新正确；
12. `I0` 镜像正确；
13. 非正定 `I0` 被拒绝且原结构不变；
14. 非法 `KI` 被拒绝；
15. 操纵上下限错误被拒绝；
16. 整数参数非法值被拒绝；
17. deg/rad 转换往返正确；
18. `linear.dx` 九个通道独立；
19. `linear.du` 七个通道独立；
20. 搜索、类别、层级和修改筛选正确；
21. 默认 `params_nominal()` 通过扩展校验。

---

## 十三、运行范围

只运行：

```matlab
checkcode('services/build_parameter_catalog.m')
checkcode('services/get_parameter_catalog_value.m')
checkcode('services/set_parameter_catalog_value.m')
checkcode('services/filter_parameter_catalog.m')
checkcode('services/validate_parameter_set.m')
checkcode('tests/check_gui_parameter_catalog.m')

report = check_gui_parameter_catalog();
assert(report.allPassed);
```

以及：

```powershell
git diff --check
```

不要运行：

```text
run_all_checks
GUI 人工启动
配平扫描
线性化扫描
```

---

## 十四、收尾

本轮不要提交，不要推送。

完成后报告：

- 实际目录总数；
- 各类别数量；
- basic/advanced 数量；
- 新增和修改文件；
- 依赖更新实现；
- 校验覆盖；
- 聚焦测试通过数与运行时间；
- checkcode；
- git diff --check；
- git status --short。
