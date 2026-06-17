# PAPER_CODE_MAPPING.md

## 1. 文档用途

本文件是倾转旋翼机 MATLAB 项目的正式“文献—代码对应关系”记录。

项目根目录：

```text
E:\tiltrotor
```

主要参考文献：

```text
references\NUAA_main_paper.pdf
references\NASA_TM_X_62407.pdf
references\NASA_TM_81244.pdf
```

本文件用于回答：

1. 论文中的每个主要模型、公式、图表和参数，在代码中由哪个文件、函数和变量实现；
2. 代码实现与论文原式是否一致；
3. 哪些内容属于低阶闭合、工程假设、占位模型或代码独有实现；
4. 哪些关键数据来源于 NASA 文献；
5. 哪些结论已经核验，哪些仍需人工复核。

本文件是可持续更新的审查记录，不是自动证明模型正确的证据。

---

## 2. 与 AGENTS.md 的关系

`AGENTS.md` 定义 Codex 在本项目中的长期工作规则、禁止事项、验证标准和报告要求。

`PAPER_CODE_MAPPING.md` 记录按照这些规则完成的具体核验结果。

两者关系如下：

```text
AGENTS.md
    ↓ 规定如何读取文献、检查代码、记录证据
PAPER_CODE_MAPPING.md
    ↓ 保存逐项核验结果
MATLAB 代码、PDF 原文、MATLAB 实际运行结果
    ↓ 构成最终证据
```

优先级：

1. 用户当前明确指令；
2. `AGENTS.md`；
3. PDF 原文和实际 MATLAB 代码；
4. 本文件中的既有记录。

若本文件与 PDF 原文或实际代码冲突，应修改本文件，不得为了保留既有映射而曲解原文或代码。

---

## 3. 状态定义

每条对应关系只能使用以下状态：

| 状态 | 含义 |
|---|---|
| `EXACT` | 数学形式、变量定义、坐标系、单位和适用条件均已确认一致 |
| `SIMILAR` | 建模思想相近，但公式、闭合关系、状态维数或实现细节不同 |
| `DIFFERENT` | 代码采用了与论文不同的模型或方法 |
| `MISSING_IN_CODE` | 论文明确给出，但当前代码未实现 |
| `CODE_ONLY` | 代码存在，但主要参考论文未给出对应内容 |
| `UNVERIFIED` | 尚未完成原文与实际代码的逐项核验 |

不得仅根据文件名、注释、旧说明文档或变量名标记为 `EXACT`。

---

## 4. 参数来源分类

关键参数使用以下来源分类：

| 分类 | 含义 |
|---|---|
| `REFERENCE` | 直接来自明确文献 |
| `DIGITIZED` | 从文献图表数字化得到 |
| `DERIVED` | 由已知数据和明确公式推导得到 |
| `ASSUMED` | 工程假设 |
| `PLACEHOLDER` | 临时占位，不能用于正式结论 |
| `UNKNOWN` | 当前没有可靠来源 |

每个 `REFERENCE` 或 `DIGITIZED` 参数必须记录文献、页码、图表或公式位置、原始单位及换算过程。

---

## 5. 参考文献分工

### 5.1 南航主要建模论文

```text
references\NUAA_main_paper.pdf
```

主要用于核查：

- 部件级建模架构；
- 坐标系和符号；
- 重心与惯量变化；
- 旋翼、机翼、机身、平尾和垂尾模型；
- 合力与合矩；
- 六自由度方程；
- 配平；
- 数值线性化；
- 稳定性分析。

### 5.2 NASA-TM-X-62407

```text
references\NASA_TM_X_62407.pdf
```

候选用途：

- XV-15 构型与几何信息；
- 质量或部件信息；
- 旋翼或短舱相关公开数据；
- 试验条件和历史构型信息。

实际用途必须在阅读原文后填写，不能根据文件名推断。

### 5.3 NASA-TM-81244

```text
references\NASA_TM_81244.pdf
```

候选用途：

- XV-15 气动或飞行试验数据；
- 稳定性、操纵性或性能数据；
- 验证工况和数据表。

实际用途必须在阅读原文后填写，不能根据文件名推断。

---

## 6. 项目文件调用关系

以下是待核验的候选调用关系，应以实际项目文件为准：

```text
run_demo.m
│
├─ params_nominal.m
│
├─ trim_symmetric.m
│   └─ tiltrotor_eom.m
│       └─ total_forces_moments.m
│           ├─ mass_properties.m
│           ├─ rotor_model_bemt.m
│           ├─ wing_model.m
│           ├─ fuselage_model.m
│           ├─ horizontal_tail_model.m
│           └─ vertical_tail_model.m
│
├─ linearize_numeric.m
└─ stability_report.m
```

核验状态：`UNVERIFIED`

需要确认：

- 文件是否位于根目录、`model`、`analysis` 或其他子目录；
- 实际函数名；
- 每个函数的输入输出；
- 是否存在其他依赖函数；
- 是否存在同名文件；
- `run_demo.m` 的真实入口路径。

---

## 7. 总体文献—代码映射表

下表是初始候选映射。所有条目在完成 PDF 原文和实际代码核验前均为 `UNVERIFIED`。

| 编号 | 论文内容 | 论文位置 | 候选代码位置 | 候选函数/变量 | 状态 | 说明 |
|---:|---|---|---|---|---|---|
| 1 | 重心随短舱角变化 | 待填写 | `mass_properties.m` | 待填写 | `UNVERIFIED` | 核查参考原点、符号和单位 |
| 2 | 惯量随短舱角变化 | 待填写 | `mass_properties.m` | 待填写 | `UNVERIFIED` | 核查完整惯量矩阵和交叉惯量 |
| 3 | 桨叶挥舞方程 | 待填写 | `rotor_model_bemt.m` | 待填写 | `UNVERIFIED` | 可能为低阶准定常闭合 |
| 4 | 轮毂局部速度 | 待填写 | `rotor_model_bemt.m` | 待填写 | `UNVERIFIED` | 核查 `V + ω×r` 与坐标转换 |
| 5 | 叶素局部速度 | 待填写 | `rotor_model_bemt.m` | `blade_loads` 或实际局部函数 | `UNVERIFIED` | 核查切向、法向速度和旋向 |
| 6 | 叶素迎角 | 待填写 | `rotor_model_bemt.m` | 待填写 | `UNVERIFIED` | 核查桨距、入流角与扭转 |
| 7 | 叶素升阻力 | 待填写 | `rotor_model_bemt.m` | 待填写 | `UNVERIFIED` | 核查翼型数据或低阶极曲线 |
| 8 | 推力和扭矩积分 | 待填写 | `rotor_model_bemt.m` | 待填写 | `UNVERIFIED` | 核查桨叶数和方位平均 |
| 9 | 非均匀入流 | 待填写 | `rotor_model_bemt.m` | 待填写 | `UNVERIFIED` | 核查一阶谐波形式 |
| 10 | 诱导速度迭代 | 待填写 | `rotor_model_bemt.m` | 待填写 | `UNVERIFIED` | 核查动量闭合和收敛判据 |
| 11 | 旋翼力矩与坐标转换 | 待填写 | `rotor_model_bemt.m` | 待填写 | `UNVERIFIED` | 核查反扭矩、旋向和 `r×F` |
| 12 | 机翼滑流区与自由流区 | 待填写 | `wing_model.m` | 待填写 | `UNVERIFIED` | 核查滑流面积和局部动压 |
| 13 | 机身气动力与力矩 | 待填写 | `fuselage_model.m` | 待填写 | `UNVERIFIED` | 核查气动系数来源 |
| 14 | 平尾与升降舵 | 待填写 | `horizontal_tail_model.m` | 待填写 | `UNVERIFIED` | 核查下洗、局部来流和力臂 |
| 15 | 双垂尾与方向舵 | 待填写 | `vertical_tail_model.m` | 待填写 | `UNVERIFIED` | 核查左右位置和侧滑符号 |
| 16 | 整机合力 | 待填写 | `total_forces_moments.m` | 待填写 | `UNVERIFIED` | 核查重复或漏算 |
| 17 | 整机合矩 | 待填写 | `total_forces_moments.m` | 待填写 | `UNVERIFIED` | 核查部件自带力矩与力臂矩 |
| 18 | 平动动力学 | 待填写 | `tiltrotor_eom.m` | 待填写 | `UNVERIFIED` | 核查机体系速度和科氏项 |
| 19 | 转动动力学 | 待填写 | `tiltrotor_eom.m` | 待填写 | `UNVERIFIED` | 核查完整惯量矩阵 |
| 20 | 欧拉角运动学 | 待填写 | `tiltrotor_eom.m` | 待填写 | `UNVERIFIED` | 核查旋转顺序和奇异点 |
| 21 | 对称配平 | 待填写 | `trim_symmetric.m` | 待填写 | `UNVERIFIED` | 核查未知量、残差和约束 |
| 22 | 数值线性化 | 待填写 | `linearize_numeric.m` | 待填写 | `UNVERIFIED` | 核查差分方式和步长 |
| 23 | 特征值与稳定性分析 | 待填写 | `stability_report.m` | 待填写 | `UNVERIFIED` | 核查模态解释和配平误差 |
| 24 | 演示与批量工况 | 论文可能无对应 | `run_demo.m` | 待填写 | `UNVERIFIED` | 可能属于 `CODE_ONLY` |

---

## 8. 逐项核验记录格式

每个重要映射按以下格式补充。

### 条目模板

#### M-XXX：条目名称

**论文证据**

- 文献：
- PDF 页码：
- 原文页码：
- 章节：
- 公式号：
- 图号或表号：
- 原文符号：
- 原始单位：
- 适用构型：
- 适用工况：

**代码证据**

- 文件：
- 函数：
- 代码位置：
- 输入：
- 输出：
- 关键变量：
- 坐标系：
- 单位：
- 数学表达式：

**一致性判断**

- 状态：
- 数学形式：
- 坐标系：
- 符号：
- 单位：
- 适用条件：
- 缺失项：
- 额外项：
- 判断依据：

**风险与待办**

- 是否需要人工核对：
- 是否需要 MATLAB 数值测试：
- 是否需要参数来源补充：
- 是否影响其他文件：
- 后续任务：

---

## 9. 初始重点核验条目

### M-001：短舱角定义

**论文证据**

- 文献：`references\NUAA_main_paper.pdf`
- PDF 页码：待填写
- 公式、图或文字位置：待填写
- 论文中直升机模式短舱角：待填写
- 论文中固定翼模式短舱角：待填写

**代码证据**

- 相关文件：`params_nominal.m`、`rotor_model_bemt.m`、`wing_model.m`、`run_demo.m`
- 实际变量名：待填写
- 推力方向表达式：待填写

**一致性判断**

- 状态：`UNVERIFIED`

**必须执行的测试**

- 短舱角取直升机模式极限时，推力方向应符合代码定义；
- 短舱角取固定翼模式极限时，推力方向应符合代码定义；
- 核查所有函数是否使用同一角度定义；
- 核查 degree 和 radian。

---

### M-002：机体系定义

**论文证据**

- 文献：`references\NUAA_main_paper.pdf`
- PDF 页码：待填写
- 机体轴方向：待填写
- 力和力矩正方向：待填写

**代码证据**

- 相关文件：全部动力学和气动函数
- 重力表达式：待填写
- 迎角和侧滑角表达式：待填写
- 力矩叉乘：待填写

**一致性判断**

- 状态：`UNVERIFIED`

---

### M-003：状态向量和控制向量

**论文证据**

- 状态变量：待填写
- 控制变量：待填写
- 页码或公式号：待填写

**代码证据**

- 状态向量顺序：待填写
- 控制向量顺序：待填写
- 相关文件：`tiltrotor_eom.m`、`trim_symmetric.m`、`linearize_numeric.m`

**一致性判断**

- 状态：`UNVERIFIED`

---

### M-004：旋翼挥舞实现

**论文证据**

- 挥舞方程：待填写
- 所需参数：待填写
- 页码和公式号：待填写

**代码证据**

- 文件：`rotor_model_bemt.m`
- 是否存在挥舞状态：待填写
- 是否为一阶谐波、准定常或经验闭合：待填写

**一致性判断**

- 状态：`UNVERIFIED`
- 重点判断：`EXACT`、`SIMILAR`、`DIFFERENT` 或 `MISSING_IN_CODE`

---

### M-005：总力和总力矩合成

**论文证据**

- 合力公式：待填写
- 合矩公式：待填写
- 参考点：待填写

**代码证据**

- 文件：`total_forces_moments.m`
- 各部件返回量：待填写
- 力臂矩：待填写
- 重力是否在此处加入：待填写

**一致性判断**

- 状态：`UNVERIFIED`

**必须执行的测试**

- 左右对称输入；
- 单部件启用；
- 人为改变作用点；
- 检查 `cross(r,F)`；
- 检查重力是否重复。

---

### M-006：配平定义

**论文证据**

- 配平条件：待填写
- 未知量：待填写
- 约束：待填写

**代码证据**

- 文件：`trim_symmetric.m`
- 求解变量：待填写
- 残差向量：待填写
- 求解器：待填写
- 容差：待填写

**一致性判断**

- 状态：`UNVERIFIED`

---

### M-007：线性化定义

**论文证据**

- 线性化公式：待填写
- 状态空间定义：待填写

**代码证据**

- 文件：`linearize_numeric.m`
- 差分方法：待填写
- 状态步长：待填写
- 控制步长：待填写

**一致性判断**

- 状态：`UNVERIFIED`

---

## 10. NASA 参数映射表

以下表格在读取两份 NASA 文献后填写。

| 参数类别 | 参数 | 代码变量 | 当前值 | NASA 文献 | 页码/图表 | 原始单位 | 代码单位 | 来源分类 | 状态 |
|---|---|---|---:|---|---|---|---|---|---|
| 质量 | 总质量 | 待填写 | 待填写 | 待填写 | 待填写 | 待填写 | kg | `UNKNOWN` | `UNVERIFIED` |
| 重心 | 重心位置 | 待填写 | 待填写 | 待填写 | 待填写 | 待填写 | m | `UNKNOWN` | `UNVERIFIED` |
| 惯量 | `Ixx` | 待填写 | 待填写 | 待填写 | 待填写 | 待填写 | kg·m² | `UNKNOWN` | `UNVERIFIED` |
| 惯量 | `Iyy` | 待填写 | 待填写 | 待填写 | 待填写 | 待填写 | kg·m² | `UNKNOWN` | `UNVERIFIED` |
| 惯量 | `Izz` | 待填写 | 待填写 | 待填写 | 待填写 | 待填写 | kg·m² | `UNKNOWN` | `UNVERIFIED` |
| 惯量 | 交叉惯量 | 待填写 | 待填写 | 待填写 | 待填写 | 待填写 | kg·m² | `UNKNOWN` | `UNVERIFIED` |
| 旋翼 | 半径 | 待填写 | 待填写 | 待填写 | 待填写 | 待填写 | m | `UNKNOWN` | `UNVERIFIED` |
| 旋翼 | 桨叶数 | 待填写 | 待填写 | 待填写 | 待填写 | — | — | `UNKNOWN` | `UNVERIFIED` |
| 旋翼 | 转速 | 待填写 | 待填写 | 待填写 | 待填写 | rpm | rad/s | `UNKNOWN` | `UNVERIFIED` |
| 旋翼 | 弦长分布 | 待填写 | 待填写 | 待填写 | 待填写 | 待填写 | m | `UNKNOWN` | `UNVERIFIED` |
| 旋翼 | 扭转分布 | 待填写 | 待填写 | 待填写 | 待填写 | deg | rad | `UNKNOWN` | `UNVERIFIED` |
| 几何 | 旋翼轮毂位置 | 待填写 | 待填写 | 待填写 | 待填写 | 待填写 | m | `UNKNOWN` | `UNVERIFIED` |
| 几何 | 机翼几何 | 待填写 | 待填写 | 待填写 | 待填写 | 待填写 | SI | `UNKNOWN` | `UNVERIFIED` |
| 气动 | 机翼气动表 | 待填写 | 待填写 | 待填写 | 待填写 | 待填写 | — | `UNKNOWN` | `UNVERIFIED` |
| 控制 | 混控关系 | 待填写 | 待填写 | 待填写 | 待填写 | 待填写 | — | `UNKNOWN` | `UNVERIFIED` |

---

## 11. 文档冲突处理

若发现以下内容之间冲突：

- `AGENTS.md`；
- 本文件；
- MATLAB 注释；
- MATLAB 实际计算；
- 南航论文；
- NASA 文献；

应按以下方式处理：

1. 保留原始证据；
2. 明确列出冲突内容；
3. 不擅自选取一个结论；
4. 检查构型、坐标、单位和工况差异；
5. 将条目标记为 `UNVERIFIED`；
6. 在“风险与待办”中记录后续核验方式。

---

## 12. MATLAB 验证记录

### 12.1 运行环境

- MATLAB 版本：待填写
- 操作系统：待填写
- 项目提交或版本：待填写
- 运行日期：待填写
- 实际运行者：待填写

### 12.2 运行命令

```matlab
startup
summary = run_all_checks;
trendReport = check_article_trends;
run_demo
```

以上命令必须以项目中实际存在的文件为准。不存在的入口不得声称已运行。

### 12.3 结果

- MATLAB 是否实际运行：否/是
- 是否出现 error：待填写
- 是否出现 warning：待填写
- 是否出现 NaN：待填写
- 是否出现 Inf：待填写
- 是否出现复数：待填写
- 配平是否收敛：待填写
- 线性化是否成功：待填写
- 特征值是否成功计算：待填写

未实际运行时必须写：

```text
未进行 MATLAB 实际运行验证。
```

---

## 13. 当前模型允许的结论

在核验完成前，只允许描述为：

> 当前项目是一套按照公开论文的部件级机理建模思路构建的 MATLAB 倾转旋翼机正向模型，其代码—论文对应关系、参数来源和数值验证状态仍需逐项核验。

当前不得宣称：

- 已完整复现南航论文；
- 已严格复现 XV-15；
- 已完成全包线验证；
- 所有参数均来自 NASA；
- 所有公式与论文完全一致；
- 模型达到高保真数字孪生水平。

---

## 14. 更新日志

| 日期 | 修改人/工具 | 修改内容 | 核验证据 | 备注 |
|---|---|---|---|---|
| 待填写 | 待填写 | 创建初始核验框架 | 无 | 所有候选映射默认为 `UNVERIFIED` |

---

## 15. 下一步核验顺序

1. 确认项目真实文件结构和调用关系；
2. 核对短舱角定义；
3. 核对机体系、旋翼轴系和力矩符号；
4. 核对状态量和控制量；
5. 核对重心、惯量和部件位置；
6. 核对旋翼 BEMT 和挥舞闭合；
7. 核对机翼、机身和平尾垂尾；
8. 核对总力与总力矩；
9. 核对六自由度方程；
10. 核对配平；
11. 核对数值线性化；
12. 核对稳定性分析；
13. 从 NASA 文献提取参数；
14. 在本地 MATLAB 执行测试；
15. 更新每条映射状态。

---

## 16. 2026-06-17 静态代码与文献核验记录

### 16.1 本轮范围

- 核验方式：静态代码审查、PDF 文本抽取、人工阅读抽取结果。
- 未执行：`run_demo.m`、`run_all_checks.m`、任何 MATLAB 模型运行。
- MATLAB 环境记录：`F:\matlab\R2021a\bin\matlab.exe`，版本 `9.10.0.1602886 (R2021a)`；`-batch` 在命令主体执行后退出阶段存在 `mwboost::archive::archive_exception` / `output stream error`。
- 修改范围：仅更新 `docs\PAPER_CODE_MAPPING.md`。
- 代码状态：未修改任何 `.m` 文件，未修改参数文件。

### 16.2 PDF 可读性

| 文献 | PDF页数 | 文本抽取结论 | 本轮用途 |
|---|---:|---|---|
| `references\NUAA_main_paper.pdf` | 18 | 可抽取英文正文和多数公式编号；部分符号、矩阵和中文/字形编码不可靠 | 部件模型、6DOF、配平、线性化的候选对应关系 |
| `references\NASA_TM_X_62407.pdf` | 101 | 可抽取英文正文；表格排版有丢列风险 | 仅识别 XV-15 参数候选来源 |
| `references\NASA_TM_81244.pdf` | 20 | 可抽取英文正文；图中文字需视觉核对 | 仅识别 XV-15 参数和飞行试验数据候选来源 |

含矩阵、图、表或坐标系示意的结论均需人工视觉核对，不能仅凭文本抽取标记为 `EXACT`。

---

## 17. 实际 MATLAB 文件、接口和调用者

### 17.1 主函数和脚本

| 文件 | 函数/脚本 | 输入 | 输出 | 实际调用者 |
|---|---|---|---|---|
| `params_nominal.m` | `params_nominal` | 无 | `P` | `run_demo.m`；`examples\demo_single_hover.m`；`examples\demo_time_response.m`；`tests\check_article_trends.m`；`tests\run_all_checks.m` |
| `startup.m` | `startup` | 无 | 无 | MATLAB 启动或用户命令 |
| `run_demo.m` | 脚本 | 工作区/路径 | `results\demo_results.mat`、图窗、工作区变量 | 用户入口；本轮未运行 |
| `examples\demo_single_hover.m` | 脚本 | 工作区/路径 | 命令行输出 | 用户入口；本轮未运行 |
| `examples\demo_time_response.m` | 脚本，局部函数 `plant(time,state)` | 工作区/路径 | 图窗 | 用户入口；本轮未运行 |

### 17.2 分析函数

| 文件 | 函数 | 输入 | 输出 | 实际调用者 |
|---|---|---|---|---|
| `analysis\trim_symmetric.m` | `trim_symmetric` | `V, betaM, P, opts` | `xTrim, uTrim, report` | `run_demo.m`；`examples\demo_single_hover.m`；`examples\demo_time_response.m` |
| `analysis\trim_symmetric.m` | 局部 `trim_cost` | `z` | `J` | `fminsearch` |
| `analysis\trim_symmetric.m` | 局部 `build_point` | `z` | `xCandidate, uCandidate, R, penalty` | `trim_cost`；主函数 |
| `analysis\trim_symmetric.m` | 局部 `bound_penalty` | `xValue, limits` | `value` | `build_point` |
| `analysis\linearize_numeric.m` | `linearize_numeric` | `xe, ue, betaM, P` | `A, B, report` | `run_demo.m`；`tests\check_article_trends.m`；`tests\run_all_checks.m` |
| `analysis\stability_report.m` | `stability_report` | `A, tolerance` | `report` | `run_demo.m` |

### 17.3 模型函数

| 文件 | 函数 | 输入 | 输出 | 实际调用者 |
|---|---|---|---|---|
| `model\tiltrotor_eom.m` | `tiltrotor_eom` | `x, uCtrl, betaM, P` | `xdot, out` | `trim_symmetric`；`linearize_numeric`；示例脚本 |
| `model\total_forces_moments.m` | `total_forces_moments` | `x, uCtrl, betaM, P` | `Ftotal, Mtotal, info` | `tiltrotor_eom`；`tests\run_all_checks.m` |
| `model\total_forces_moments.m` | 局部 `clamp` | `value, limits` | `y` | `total_forces_moments` |
| `model\mass_properties.m` | `mass_properties` | `betaM, P` | `mp` | `total_forces_moments`；`tests\run_all_checks.m` |
| `model\rotor_model_bemt.m` | `rotor_model_bemt` | `x, rotorCtrl, betaM, side, cgShift, P` | `Fbody, Mbody, out` | `total_forces_moments` |
| `model\rotor_model_bemt.m` | 局部 `blade_loads` | `viMean` | `loads` | `rotor_model_bemt` |
| `model\wing_model.m` | `wing_model` | `x, uCtrl, betaM, cgShift, rotorLeft, rotorRight, P` | `Fbody, Mbody, out` | `total_forces_moments`；`tests\run_all_checks.m` |
| `model\wing_model.m` | 局部 `one_region` | `rAC, Sreg, side, inSlipstream, rotor` | `Freg, Mreg, data` | `wing_model` |
| `model\fuselage_model.m` | `fuselage_model` | `x, cgShift, P` | `Fbody, Mbody, out` | `total_forces_moments` |
| `model\horizontal_tail_model.m` | `horizontal_tail_model` | `x, elevator, cgShift, P` | `Fbody, Mbody, out` | `total_forces_moments` |
| `model\vertical_tail_model.m` | `vertical_tail_model` | `x, rudder, cgShift, P` | `Fbody, Mbody, out` | `total_forces_moments` |
| `model\aero_force_body.m` | `aero_force_body` | `D, Y, L, alpha, beta` | `Fbody` | `wing_model`；`fuselage_model`；`horizontal_tail_model`；`vertical_tail_model` |
| `model\validate_inputs.m` | `validate_inputs` | `x, uCtrl, betaM, P` | 无 | `total_forces_moments` |

### 17.4 测试和趋势诊断入口

| 文件 | 函数 | 输入 | 输出 | 实际调用者 |
|---|---|---|---|---|
| `tests\run_all_checks.m` | `run_all_checks` | 无 | `summary` | 用户入口；本轮未运行 |
| `tests\check_article_trends.m` | `check_article_trends` | 无 | `trendReport` | 用户入口；本轮未运行 |

---

## 18. 实际调用关系

```text
run_demo.m
├─ params_nominal
├─ trim_symmetric
│  ├─ fminsearch
│  └─ tiltrotor_eom
│     └─ total_forces_moments
│        ├─ validate_inputs
│        ├─ mass_properties
│        ├─ rotor_model_bemt
│        │  └─ blade_loads
│        ├─ wing_model
│        │  ├─ one_region
│        │  └─ aero_force_body
│        ├─ fuselage_model
│        │  └─ aero_force_body
│        ├─ horizontal_tail_model
│        │  └─ aero_force_body
│        └─ vertical_tail_model
│           └─ aero_force_body
├─ linearize_numeric
│  └─ tiltrotor_eom
└─ stability_report

examples\demo_single_hover.m
├─ params_nominal
├─ trim_symmetric
└─ tiltrotor_eom

examples\demo_time_response.m
├─ params_nominal
├─ trim_symmetric
└─ ode45
   └─ plant
      └─ tiltrotor_eom

tests\run_all_checks.m
├─ params_nominal
├─ mass_properties
├─ total_forces_moments
├─ wing_model
└─ linearize_numeric

tests\check_article_trends.m
├─ params_nominal
└─ linearize_numeric
```

---

## 19. 状态、控制、坐标和单位定义

| 项目 | 实际代码定义 | 代码位置 | 与论文关系 | 状态 |
|---|---|---|---|---|
| 状态向量 | `x = [u v w p q r phi theta psi]'` | `model\tiltrotor_eom.m`；`analysis\stability_report.m` | NUAA PDF页12，原文页12，式(39)给出同序状态 | `EXACT` |
| 控制向量 | `uCtrl = [collective diffCollective cyclic diffCyclic aileron elevator rudder]'` | `model\total_forces_moments.m`；`analysis\linearize_numeric.m` | NUAA PDF页12，原文页12，式(40)给出七个控制量；符号命名需人工核对 | `SIMILAR` |
| 机体系 | 代码注释为 `x前、y右、z下` | `model\tiltrotor_eom.m`；`model\aero_force_body.m` | NUAA Figure 2 需要人工视觉核对 | `UNVERIFIED` |
| 惯性/地轴系 | 代码仅通过 Euler 321 运动学隐含使用，未显式输出位置状态 | `model\tiltrotor_eom.m` | NUAA PDF页3 假设地轴系为惯性系；代码缺少位置方程 | `MISSING_IN_CODE` |
| 短舱角 `betaM` | `0` 时推力向上，`pi/2` 时推力向前；`eT=[sin(betaM);0;-cos(betaM)]` | `model\rotor_model_bemt.m` | NUAA 文本采用 `theta_M`；NASA_TM_81244 PDF页6称 XV-15 指示逻辑为 airplane 0、helicopter 90，与本代码相反 | `UNVERIFIED` |
| 旋翼轴系 | `eT,eD,eY` 为代码局部轴；`eT` 推力轴，`eD` 盘内纵向，`eY` 机体右向 | `model\rotor_model_bemt.m` | NUAA 旋翼轴变换矩阵在 PDF页5 式(14)(15)，抽取不完整 | `UNVERIFIED` |
| 角度单位 | 参数文件声明内部角度为 rad；输入演示用 deg 转 rad | `params_nominal.m`；`run_demo.m` | NUAA/NASA 多数图表为 deg，进入代码前需转换 | `SIMILAR` |

---

## 20. 静态风险清单

| 严重度 | 分类 | 位置 | 风险 | 需要的后续确认 |
|---|---|---|---|---|
| `HIGH` | 坐标系或符号错误 | `model\rotor_model_bemt.m` | 本代码 `betaM=0` 为直升机模式、`pi/2` 为飞机模式；NASA_TM_81244 PDF页6的 XV-15 指示逻辑为 airplane 0、helicopter 90，存在定义相反风险 | 明确本项目 `betaM` 是否为论文符号还是代码自定义符号 |
| `HIGH` | 物理模型错误 | `model\rotor_model_bemt.m` | 论文 PDF页4 式(4)给出挥舞运动方程；代码采用一阶谐波准定常闭合且无挥舞状态 | 若要复现论文，需要确认该闭合是否可接受 |
| `HIGH` | 模型缺失 | `model\tiltrotor_eom.m` | 状态只有 9 个，未包含惯性位置；论文 6DOF 框架含地轴假设，代码不能直接输出轨迹位置 | 需要决定是否加入位置状态或保持小扰动模型 |
| `HIGH` | 文献依据不足 | `params_nominal.m` | 质量、惯量、几何、气动系数为概念参数，尚未追溯到 NASA 表格或图 | 建立参数来源表并逐项标记 |
| `MEDIUM` | 数值计算错误 | `model\tiltrotor_eom.m` | Euler 321 在 `cos(theta)` 接近零时用 `1e-6` 替代，避免除零但改变奇异点附近动力学 | 需要极限工况测试和姿态范围约束 |
| `MEDIUM` | 数值计算错误 | `model\rotor_model_bemt.m` | `phiInflow = atan2(UP, max(abs(UT),1e-8))` 丢失 `UT` 符号，反向流工况可能失真 | 需要反向流/低转速工况检查 |
| `MEDIUM` | 数值计算错误 | `model\rotor_model_bemt.m` | 诱导速度迭代未显式报告未收敛；达到最大迭代后仍使用最后值 | 需要将收敛标志纳入输出和测试 |
| `MEDIUM` | 坐标系或符号错误 | `model\aero_force_body.m` | 风轴到机体系转换与 NUAA PDF页7 式(23)(24)符号需视觉核对；文本抽取不足以确认 | 人工核对矩阵方向和 `D/Y/L` 正号 |
| `MEDIUM` | 配平定义风险 | `analysis\trim_symmetric.m` | 仅求解 `[theta, collective, pitchCommand]` 并约束 `[udot,wdot,qdot]`，不是论文完整六分量力矩平衡 trim | 明确“对称纵向配平”的适用范围 |
| `MEDIUM` | 数值线性化风险 | `analysis\linearize_numeric.m` | 中心差分步长固定，未做步长敏感性检查；扰动可能跨越限幅和非光滑 `clamp/tanh` | 增加步长敏感性和线性化点回代检查 |

---

## 21. 逐项文献-代码映射记录

| 编号 | 论文内容 | PDF页码 | 原文页码 | 公式/图/表 | 对应代码文件 | 函数/局部函数 | 变量 | 数学形式 | 坐标系 | 单位 | 缺失项 | 额外项 | 状态 | 判断依据 |
|---:|---|---:|---|---|---|---|---|---|---|---|---|---|---|---|
| M-001 | 重心随短舱角变化 | 3 | 3 of 18 | 式(1)(2) | `model\mass_properties.m` | `mass_properties` | `dx,dz,betaM,mNac,RH,m` | `dx=mNac*RH*sin(betaM)/m`；`dz=mNac*RH*(1-cos(betaM))/m` | 代码为机体参考重心偏移；论文 Figure 2 坐标需视觉核对 | 代码 SI；论文公式为长度量纲 | 论文坐标方向未完成视觉核对 | 无 | `UNVERIFIED` | 数学形式可对应，但坐标定义三方核验未完成 |
| M-002 | 惯量随短舱角变化 | 3 | 3 of 18 | 式(3) | `model\mass_properties.m` | `mass_properties` | `I0,KI,betaM,I` | `I=I0-betaM*KI` 后对称化并正定检查 | 机体系惯量矩阵 | 代码 `kg*m^2`；论文单位未在公式处给出 | `KI` 来源、交叉惯量定义、短舱构型 | 对称化、正定检查 | `UNVERIFIED` | 形式对应，但参数来源和坐标轴未核验 |
| M-003 | 旋翼挥舞方程 | 4 | 4 of 18 | 式(4) | `model\rotor_model_bemt.m` | `rotor_model_bemt` | `a1,b1,flap*Gain` | 代码为代数一阶谐波准定常闭合 | 旋翼局部轴 `eT,eD,eY` | rad | 未实现二阶挥舞微分方程和铰链力矩平衡 | 限幅 `flapMax` 和经验增益 | `DIFFERENT` | 论文给动态方程，代码无挥舞状态且用经验闭合 |
| M-004 | 轮毂局部速度 | 4 | 4 of 18 | 式(5) | `model\rotor_model_bemt.m` | `rotor_model_bemt` | `Vhub,Vaxial,Vlong,Vlat,rHub` | `Vhub=Vbody+cross(omegaBody,rHub)` 后投影到 `eT/eD/eY` | 机体系到旋翼局部投影 | m/s | 论文矩阵链 `CHW...` 未逐项对应 | 代码直接用轴向量点积 | `UNVERIFIED` | 坐标转换矩阵未完成论文、代码、坐标定义三方核验 |
| M-005 | 叶素局部速度 | 4 | 4 of 18 | 式(6)(7) | `model\rotor_model_bemt.m` | `blade_loads` | `UT,UP,viField,VtanTrans` | `UT=Omega*r+VtanTrans`；`UP=Vaxial+viField` | 旋翼叶素局部 | m/s | 论文符号 `mu, lambda` 与代码变量未完全映射 | 非均匀入流形状和反向流保护 | `UNVERIFIED` | 叶素坐标和旋向符号未完成三方核验 |
| M-006 | 叶素升阻力 | 4 | 4 of 18 | 式(8)(9) | `model\rotor_model_bemt.m` | `blade_loads` | `CL,CD,dL,dD` | `dL=q*c*CL*dr`；`dD=q*c*CD*dr` | 旋翼叶素局部 | N | 真实翼型数据缺失 | `tanh` 失速限制、二次阻力极曲线 | `UNVERIFIED` | 叶素局部轴和系数来源未完成三方核验 |
| M-007 | 叶素力转换与推力/扭矩 | 4 | 4 of 18 | 式(10)(11) | `model\rotor_model_bemt.m` | `blade_loads` | `dT,dH,dQ,Tsum,Qsum,HvecSum` | `dT=dL*cos(phi)-dD*sin(phi)`；`dQ=r*dH` | 旋翼叶素局部 | N, N*m | `Ss/Mk` 等论文符号未全部映射 | 盘内 `Hlong/Hlat` 显式输出 | `UNVERIFIED` | 侧向分量、旋向和符号需人工核对 |
| M-008 | 诱导速度迭代 | 5 | 5 of 18 | 式(13) | `model\rotor_model_bemt.m` | `rotor_model_bemt` | `vi,viTarget,inducedRelax` | 动量闭合迭代，松弛更新 | 旋翼轴向等效入流 | m/s | 未输出收敛标志 | 松弛因子和最小分母保护 | `UNVERIFIED` | 诱导速度符号和轴向定义未完成三方核验 |
| M-009 | 旋翼力和力矩转换到机体系 | 5 | 5 of 18 | 式(14)(15) | `model\rotor_model_bemt.m` | `rotor_model_bemt` | `Fbody,Mbody,Mreaction,rHub` | `F=T*eTeff+Hlong*eD+Hlat*eY`；`M=cross(rHub,F)+Mreaction+Mgyro` | 机体系 | N, N*m | 论文矩阵链和旋向符号需视觉核对 | 陀螺项可选 | `UNVERIFIED` | 抽取矩阵不可靠，旋向定义需人工核对 |
| M-010 | 机翼滑流区和自由流区 | 5-6 | 5-6 of 18 | Figure 3；式(17)-(22) | `model\wing_model.m` | `wing_model` / `one_region` | `S_slip,S_free,Vlocal,wakeVelocity` | 左右半翼分自由流/滑流，滑流叠加 `wakeVelocity*rotor.eT` | 机体系局部作用点 | m/s, m^2, N | 滑流面积公式和图示边界未按论文逐项实现 | 经验 `muFactor/orientationFactor` | `UNVERIFIED` | 机翼局部坐标、滑流方向和面积定义需人工核对 |
| M-011 | 机身气动力和力矩 | 7 | 7 of 18 | 式(23)(24) | `model\fuselage_model.m` | `fuselage_model` | `alpha,beta,D,L,Y,Maero` | 风轴力经 `aero_force_body` 转机体系，`M=cross(rAC,F)+Maero` | 机体系/风轴 | N, N*m | 论文气动系数来源未映射 | 阻尼导数 `Clp,Cmq,Cnr` 等 | `UNVERIFIED` | 风轴到机体系矩阵和力正号需视觉核对 |
| M-012 | 平尾与升降舵 | 7-8 | 7-8 of 18 | 式(25)(26) | `model\horizontal_tail_model.m` | `horizontal_tail_model` | `alphaEff,elevator,CL,CD,Cm` | 固定翼尾翼模型，`M=cross(rAC,F)+Maero` | 机体系/风轴 | N, N*m | 论文公式文本抽取不完整 | 下洗修正 `downwashAlpha` | `UNVERIFIED` | 平尾局部来流和力矩符号未完成三方核验 |
| M-013 | 双垂尾与方向舵 | 8 | 8 of 18 | 式(27)-(30) | `model\vertical_tail_model.m` | `vertical_tail_model` | `CY,rudder,Ffin,Mfin` | 左右垂尾分别计算，`Mfin=cross(rAC,Ffin)` | 机体系/风轴 | N, N*m | 垂尾升力方向和论文矩阵需视觉核对 | 诱导阻力 `0.02*CY^2` | `UNVERIFIED` | 垂尾侧力方向和左右符号未完成三方核验 |
| M-014 | 整机合力 | 8 | 8 of 18 | 式(31) | `model\total_forces_moments.m` | `total_forces_moments` | `Ftotal,FrotL,FrotR,Fwing,Ffus,Fht,Fvt` | 各部件机体系力直接求和 | 机体系 | N | 论文将左右机翼和左右垂尾分列；代码将机翼/垂尾内部合并 | 诊断结构 `info.components` | `UNVERIFIED` | 各部件坐标统一性需逐项核验 |
| M-015 | 整机合矩 | 8 | 8 of 18 | 式(32) | `model\total_forces_moments.m` | `total_forces_moments` | `Mtotal,Mrot*,Mwing,Mfus,Mht,Mvt` | 各部件已含 `cross(r,F)` 和气动力矩，总矩直接求和 | 机体系 | N*m | 各部件自带力矩参考点需逐项确认 | 陀螺反扭矩加入旋翼矩 | `UNVERIFIED` | `r×F` 顺序正确，但参考点/坐标需逐项核验 |
| M-016 | 平动动力学 | 8 | 8 of 18 | 式(33) | `model\tiltrotor_eom.m` | `tiltrotor_eom` | `Vdot,Ftotal,Fg,omega,Vbody` | `Vdot=Ftotal/m-cross(omega,Vbody)` | 机体系，重力投影到机体系 | m/s^2 | 论文重力矩阵符号需视觉核对 | 重力在 EOM 单独加入 | `UNVERIFIED` | 重力投影和机体系正方向需视觉核对 |
| M-017 | 转动动力学 | 8 | 8 of 18 | 式(34)(35) | `model\tiltrotor_eom.m` | `tiltrotor_eom` | `omegaDot,mp.I,Mtotal` | `omegaDot=I\(M-cross(omega,I*omega))` | 机体系 | rad/s^2 | 惯量来源未核验 | 使用完整惯量矩阵 | `UNVERIFIED` | 惯量轴、交叉惯量符号和力矩坐标未核验 |
| M-018 | Euler 321 运动学 | 8-9 | 8-9 of 18 | 式(36) | `model\tiltrotor_eom.m` | `tiltrotor_eom` | `T321,eulerDot` | `eulerDot=T321*omega` | 321 Euler 角 | rad/s | 接近奇异点处理未见论文对应 | `cosTheta` 最小值替代 | `UNVERIFIED` | Euler 角旋转顺序和角定义需人工核对 |
| M-019 | 非线性模型结构 | 9 | 9 of 18 | Figure 4 | 多文件 | 主调用链 | 各部件 `F,M,out` | 部件力矩输入 EOM | 机体系 | SI | Simulink S-function 结构未实现 | MATLAB 函数式实现 | `UNVERIFIED` | 架构相近，但部件坐标统一性未核验 |
| M-020 | 配平方法 | 9-10 | 9-10 of 18 | Figure 5-6；trim function | `analysis\trim_symmetric.m` | `trim_symmetric` | `z=[theta,collective,pitchCommand]` | `fminsearch` 最小化 `[udot,wdot,qdot]` | 对称纵向状态 | rad, m/s^2, rad/s^2 | 未配平全部六分量、无边界求解器 | 罚函数和混控 `eta=sin(betaM)^2` | `DIFFERENT` | 论文使用 MATLAB/Simulink `trim`，代码为简化对称配平 |
| M-021 | 平衡点定义 | 12 | 12 of 18 | 式(37) | `analysis\linearize_numeric.m`；`analysis\trim_symmetric.m` | `linearize_numeric`；`trim_symmetric` | `xe,ue,report.f0` | `f(xe,ue)=0` 作为线性化前提 | 状态空间 | SI/rad | 未强制检查 `report.f0` 足够小 | 输出 `report.f0` | `UNVERIFIED` | 线性化点是否真实配平需 MATLAB 回代确认 |
| M-022 | 状态空间线性化 | 12 | 12 of 18 | 式(38)(41)(42) | `analysis\linearize_numeric.m` | `linearize_numeric` | `A,B,dx,du` | 中心差分 `A(:,j)=(fp-fm)/(2dx)` | 9状态、7控制 | 各状态/控制单位 | 未做步长敏感性 | 中心差分优于论文 Linmod 黑箱，但可能跨限幅 | `DIFFERENT` | 论文使用 `Linmod`，代码用数值中心差分 |
| M-023 | 特征值和稳定性分析 | 13-15 | 13-15 of 18 | Tables 1-3 等 | `analysis\stability_report.m` | `stability_report` | `eig(A),idxLong,idxLat` | 全系统和纵/横向子矩阵特征值 | 状态空间 | 1/s | 无模态参与度、频率阻尼整理、论文表格对比 | `openLoopStable` 布尔判据 | `SIMILAR` | 都做特征值分析，但解释深度不同 |
| M-024 | 演示与批量工况 | 9-12 | 9-12 of 18 | Figure 5-8 | `run_demo.m` | 脚本 | `cases,results` | 多工况调用配平/线性化/稳定性 | 代码定义 | SI/rad，输出 deg | 未对应论文具体 XV-15 工况 | 保存 `demo_results.mat` 和图 | `CODE_ONLY` | 论文无该 MATLAB 脚本；代码为项目演示入口 |

### 21.1 状态数量

| 状态 | 数量 |
|---|---:|
| `EXACT` | 0 |
| `SIMILAR` | 1 |
| `DIFFERENT` | 3 |
| `MISSING_IN_CODE` | 0 |
| `CODE_ONLY` | 1 |
| `UNVERIFIED` | 19 |

---

## 22. NASA 参数来源候选记录

本轮不替换任何参数。以下仅记录候选来源，所有数值进入代码前必须再次视觉核对表格/图、原始单位、构型和换算。

| 文献 | PDF页码 | 原文页码 | 图/表/章节 | 候选参数 | 原文单位 | 当前代码变量 | 当前代码值 | 状态 | 备注 |
|---|---:|---|---|---|---|---|---:|---|---|
| `NASA_TM_X_62407.pdf` | 10 | 4 | Aircraft description | 25-ft-diameter, three-bladed rotors | ft, blade count | `P.rotor.R`, `P.rotor.Nb` | `3.80`, `3` | `UNVERIFIED` | 半径应由 25 ft 直径换算，当前值接近但未确认来源 |
| `NASA_TM_X_62407.pdf` | 11 | 5 | 3.1.1 Aircraft weights | Design gross 13,000 lb, maximum gross 15,000 lb | lb | `P.mass.m` | `6000` | `UNVERIFIED` | 当前质量接近 13,000 lb 换算量级，但不能认定来源 |
| `NASA_TM_X_62407.pdf` | 15 | 12 | 3.1.3 Inertias | Airplane/Helicopter `Ixx,Iyy,Izz` | slug-ft^2 | `P.mass.I0`, `P.mass.KI` | 多项 | `UNVERIFIED` | 表格抽取缺 `Izz` 标签和交叉惯量，必须视觉核对 |
| `NASA_TM_X_62407.pdf` | 15 | 12 | 3.3 Dimensions and general data | Wing area/span/chord/tail geometry | sq ft, ft, deg | `P.wing.*`, `P.htail.*`, `P.vtail.*` | 多项 | `UNVERIFIED` | 当前几何与表格量级不一致，未做换算或替换 |
| `NASA_TM_X_62407.pdf` | 21 | 18 | Figure 3.7.1 | Rotor blade aerodynamic twist | deg vs r/R | `P.rotor.twistTip` | `-6 deg` | `UNVERIFIED` | 图需数字化，不能用文本抽取 |
| `NASA_TM_X_62407.pdf` | 22 | 19 | 3.8 Tip Speed | Hover 740 ft/s 565 rpm；Cruise 600 ft/s 458 rpm | ft/s, rpm | `P.rotor.Omega` | `62 rad/s` | `UNVERIFIED` | 当前转速约 592 rpm，需确认工况 |
| `NASA_TM_81244.pdf` | 4 | 约2 | Design characteristics | 25 ft prop-rotor diameter, 45 deg blade twist, 32 ft spinner-to-spinner span, 42 ft length | ft, deg | `P.rotor.R`, `P.rotor.twistTip`, `P.wing.b` | 多项 | `UNVERIFIED` | 综述性数据，适合交叉核对 |
| `NASA_TM_81244.pdf` | 6 | 约4 | Conversion angle indicator | Angle logic airplane `0`, helicopter `90` | deg | `betaM` | `0` helicopter, `pi/2` airplane | `UNVERIFIED` | 与当前代码短舱角定义相反，是最高优先级人工核对点 |
| `NASA_TM_81244.pdf` | 8 | 约6 | Airplane mode flight | Airplane mode rpm reduction 98%/589 to 86%/517, 76%/458 | rpm | `P.rotor.Omega` | `62 rad/s` | `UNVERIFIED` | 需确认是否采用飞行试验还是设计值 |
| `NASA_TM_81244.pdf` | 14 | 图页 | Figure 4 | XV-15 dimensions | ft/in | 几何参数 | 多项 | `UNVERIFIED` | 图形尺寸需视觉读取 |

---

## 23. 最需要人工视觉核对的位置

| 优先级 | 文献 | PDF页码 | 原文页码 | 位置 | 原因 |
|---:|---|---:|---|---|---|
| 1 | `NUAA_main_paper.pdf` | 3 | 3 of 18 | Figure 2 | 坐标系、短舱角、机体系方向是后续所有符号判断的基础 |
| 2 | `NUAA_main_paper.pdf` | 5 | 5 of 18 | 式(14)(15) | 旋翼力/矩从旋翼轴到机体系的矩阵抽取不可靠 |
| 3 | `NUAA_main_paper.pdf` | 7 | 7 of 18 | 式(23)(24) | 风轴到机体系力/矩转换符号需与 `aero_force_body` 对照 |
| 4 | `NUAA_main_paper.pdf` | 8 | 8 of 18 | 式(31)-(36) | 合力、合矩、重力投影和 Euler 运动学矩阵需视觉确认 |
| 5 | `NASA_TM_81244.pdf` | 6 | 约4 | Conversion angle indicator | XV-15 角度逻辑与当前代码 `betaM` 定义相反，不能混用 |

---

## 24. 必须等待 MATLAB 正常运行后确认的结论

- 各核心函数实际输出是否有限：`NaN`、`Inf`、复数均需运行确认。
- `trim_symmetric` 在各工况的残差范数、控制量范围、是否触及限幅。
- `linearize_numeric` 的 `A,B` 是否有限，以及对差分步长是否敏感。
- `stability_report` 的特征值是否受配平误差或步长影响。
- 左右对称工况下 `Fy,Mx,Mz` 是否接近零，以及反扭矩是否按旋向抵消。
- 旋翼诱导速度迭代是否在默认网格和典型工况下收敛。
- 低速、零速、接近 Euler 奇异姿态、近法向机翼流动下的数值稳定性。
- NASA 参数替换后的质量、惯量、几何和气动量级是否仍保持模型可计算。

---

## 25. 2026-06-17 趋势诊断程序修订记录

### 25.1 本轮范围和修改限制

- 本轮阶段：趋势诊断程序修订。
- 允许修改文件：`tests\check_article_trends.m`、`docs\PAPER_CODE_MAPPING.md`。
- 实际修改文件：`tests\check_article_trends.m`、`docs\PAPER_CODE_MAPPING.md`。
- 未修改：`params_nominal.m`、`model\` 目录、`analysis\` 目录、`tests\run_all_checks.m`、`run_demo.m`。
- 未修改任何模型参数。
- 未修改任何函数接口；`check_article_trends` 入口仍为 `trendReport = check_article_trends`。
- 当前没有证据支持修改 `model\rotor_model_bemt.m`；`diffCyclic` 对 `Fy` 的零导数首先记录为当前模型结构限制，而不是通过修改旋翼模型来提高趋势匹配。

### 25.2 MATLAB 运行环境记录

- MATLAB 可执行文件：`F:\matlab\R2021a\bin\matlab.exe`。
- MATLAB 版本：`9.10.0.1602886 (R2021a)`。
- 用户普通 CMD 烟雾测试：返回退出码 `0`。
- Codex 捕获 MATLAB `-batch` 输出时：命令主体完成后，可能在 `shutdown.cpp` 退出阶段出现 `mwboost::archive::archive_exception` / `output stream error` 断言。
- 记录方式：日志中数值计算结果在 shutdown 断言前已完整输出；该计算结果和退出阶段断言必须分开记录。
- 不能把 Codex 输出捕获阶段的 shutdown 断言等同于模型计算失败；也不能忽略该断言。

### 25.3 基础检查和配平结果

- MATLAB 基础检查：`run_all_checks` 中 7 项内部检查均通过。
- 已通过项目内部检查项：
  - 参数和惯量检查；
  - 短舱端点推力方向；
  - 总距-推力单调性；
  - 左右对称性；
  - 机翼 `V^2` 规律；
  - 旋翼网格收敛；
  - 线性化有限性。
- 真实悬停配平点：`V=0 m/s`，`betaM=0 rad`，`trim exitflag=1`，`trim residualNorm=1.612633507884e-08`，完整 9 状态 `norm(f0)=1.612633507884e-08`。
- 真实 `V=20 m/s` 配平点：`betaM=0 rad`，`trim exitflag=1`，`trim residualNorm=3.903537374755e-08`，完整 9 状态 `norm(f0)=3.903537374755e-08`。
- 原 `check_article_trends.m` 使用的 `V=20 m/s` 手工基准点不是配平点，旧诊断中 `norm(f0)=3.071181`，不能作为正式趋势比较基准。

### 25.4 NUAA Table 2 参考数据状态

- 文献：`references\NUAA_main_paper.pdf`。
- PDF 页码：13。
- 原文页码：13 of 18。
- 表号：Table 2。
- Table 2 标题：Linearized input matrix B in helicopter mode。
- Table 2 行标签：`Fx/Fy/Fz/Mx/My/Mz` 等。
- Table 2 控制列：`δc/δcc/δe/δec/δail/δele/δrud`。
- 工况完整性：`UNVERIFIED`。
- 控制单位：`UNVERIFIED`。
- 机体系方向：`UNVERIFIED`；Figure 2 仍需人工视觉确认。
- 行标签物理含义：`UNVERIFIED`；不能在未确认含义时把 Table 2 的 `Mx/Mz` 行直接等同于代码 B 矩阵的 `pdot/rdot` 行。
- 当前 `check_article_trends` 顶层字段 `formalComparable=false`。只有论文工况、控制单位、坐标方向和行标签含义全部确认后，才允许改为 `true`。

### 25.5 状态导数与原始载荷导数必须分开

- `analysis\linearize_numeric.m` 输出的 `B` 矩阵行含义是状态导数：
  `udot/vdot/wdot/pdot/qdot/rdot/phidot/thetadot/psidot`。
- `model\total_forces_moments.m` 输出的原始广义载荷行含义是：
  `Fx/Fy/Fz/Mx/My/Mz`。
- 因此 `Mx` 不得直接写成 `pdot`，`Mz` 不得直接写成 `rdot`。
- 本轮修订后的 `check_article_trends` 分别输出：
  - `linearize_numeric` 的 `B(:,2)` 和 `B(:,4)`；
  - `total_forces_moments` 中心差分得到的 `dFx/dudiff`、`dFy/dudiff`、`dFz/dudiff`、`dMx/dudiff`、`dMy/dudiff`、`dMz/dudiff`。
- 其中 `dudiff` 在程序中对应 `diffCollective` 或 `diffCyclic`，不是飞行速度 `u`。

### 25.6 悬停配平点趋势诊断结论

- 在真实悬停配平点，`dvdot/ddiffCollective` 为负，NUAA Table 2 中 `Fy/δcc` 为正；该项保持 `UNRESOLVED`，倾向原因是低阶盘内侧向力模型差异或坐标/定义差异，仍需人工核对坐标和控制正方向。
- 在真实悬停配平点，`rdot/ddiffCollective` 为正，与 NUAA Table 2 中 `Mz/δcc` 同号；这只是诊断同号，不是正式复现证明。
- 在真实悬停配平点，`pdot/ddiffCyclic` 为负，与 NUAA Table 2 中 `Mx/δec` 同号；但 `pdot` 来自完整惯量矩阵求解，不等同于原始 `Mx`。
- 在真实悬停配平点，`dvdot/ddiffCyclic=0`，而 NUAA Table 2 中 `Fy/δec` 为正；当前代码结构中 `diffCyclic` 只进入 `cyclicLong` 和纵向挥舞 `a1`，不进入横向挥舞 `b1`，因此该项标记为 `MODEL_STRUCTURE_ZERO`。
- 悬停时 `pdot/ddiffCyclic` 主要来自负 `Mz` 通过非对角惯量 `Ixz` 的耦合；原始 `dMx/ddiffCyclic` 近零，不能把这一项解释为原始 `Mx` 与论文完全一致。
- 原三个旧诊断不匹配项中，换成真实悬停配平点后有两个与论文同号：`rdot/ddiffCollective`、`pdot/ddiffCyclic`；`dvdot/ddiffCollective` 仍未解决。

### 25.7 差分步长敏感性记录

在真实悬停配平点，使用 `linearize_numeric` 并分别设置控制差分步长 `1e-3`、`1e-4`、`1e-5`，重点状态导数符号稳定：

| 控制差分步长 | `dvdot/ddiffCollective` | `rdot/ddiffCollective` | `pdot/ddiffCyclic` | `dvdot/ddiffCyclic` |
|---:|---:|---:|---:|---:|
| `1e-3` | `-2.033745817091e+00` | `+1.525354631665e+00` | `-3.720510688974e-01` | `0.000000000000e+00` |
| `1e-4` | `-2.033757284506e+00` | `+1.525368415917e+00` | `-3.720511573000e-01` | `0.000000000000e+00` |
| `1e-5` | `-2.033757399178e+00` | `+1.525368553744e+00` | `-3.720511582972e-01` | `0.000000000000e+00` |

该表只能说明这些导数在当前模型和当前配平点附近对差分步长不敏感，不能说明模型已经复现 NUAA Table 2。

### 25.8 诊断状态规则

- `check_article_trends` 不再输出正式 `PASS/FAIL`。
- 每个比较项只能使用：
  `MATCH`、`MISMATCH`、`NOT_COMPARABLE`、`MODEL_STRUCTURE_ZERO`、`UNVERIFIED`。
- `matchFraction` 保留为兼容旧调用者的别名，但其含义已降级为 `diagnosticMatchFraction`。
- `diagnosticMatchFraction` 只统计可比较的 `MATCH/MISMATCH` 诊断项，不能代表模型正确率、复现程度或验证通过率。
- 当配平失败、`norm(f0)` 超过容差、或出现 NaN/Inf/复数时，程序必须停止 Table 2 趋势比较并标记 `NOT_COMPARABLE`，不得继续给出“通过”。
