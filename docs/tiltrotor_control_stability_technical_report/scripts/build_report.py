#!/usr/bin/env python3
"""Build the independent control/stability technical report.

The script treats MATLAB CSV files as the numerical source of truth, retains
the validated model-principle chapters from the historical report, and builds
new Markdown, XeLaTeX and editable Word deliverables.  It does not change any
production model or default parameter.
"""

from __future__ import annotations

import csv
import math
import re
import subprocess
import sys
import zipfile
from datetime import datetime
from pathlib import Path

from docx import Document
from docx.enum.table import WD_ALIGN_VERTICAL, WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_BREAK
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Mm, Pt, RGBColor
from docx.text.paragraph import Paragraph


TITLE = "倾转旋翼机部件级飞行动力学建模、短舱动态状态扩展与开环操纵稳定特性分析研究报告"
ROOT = Path(__file__).resolve().parents[3]
REPORT = Path(__file__).resolve().parents[1]
HISTORICAL_MD = (
    ROOT
    / "docs"
    / "master_thesis_final_multiround"
    / "final"
    / "MASTER_THESIS_FINAL_CANDIDATE.md"
)
PANDOC = Path(r"C:\Program Files\Pandoc\pandoc.exe")
MD_OUT = REPORT / "TECHNICAL_REPORT.md"
DOCX_OUT = REPORT / "TECHNICAL_REPORT_EDITABLE.docx"
TEX_DIR = REPORT / "xelatex_project"
TEX_OUT = TEX_DIR / "main.tex"
BIB_OUT = TEX_DIR / "references.bib"
BUILD_LOG = REPORT / "logs" / "REPORT_SOURCE_BUILD.log"


REQUIRED_CSV = [
    "STATIC_STABILITY_DERIVATIVES.csv",
    "DAMPING_DERIVATIVES.csv",
    "DERIVATIVE_CROSSCHECK.csv",
    "CONTROL_EFFECTIVENESS_DERIVATIVES.csv",
    "CONTROL_DERIVATIVE_CROSSCHECK.csv",
    "MODAL_PARAMETERS.csv",
    "MODAL_PARTICIPATION.csv",
    "MODAL_CLASSIFICATION.csv",
    "MODAL_CONDITIONING.csv",
    "CONTROL_STEP_RESPONSE_METRICS.csv",
    "CONTROL_STEP_LINEAR_NONLINEAR_COMPARISON.csv",
    "CONTROL_STEP_TIMESTEP_CONVERGENCE.csv",
    "TRIM_CHARACTERISTICS_BY_MODE.csv",
    "REPRESENTATIVE_POINT_AUDIT.csv",
]


def rows(name: str) -> list[dict[str, str]]:
    path = REPORT / name
    with path.open("r", encoding="utf-8-sig", newline="") as stream:
        return list(csv.DictReader(stream))


def num(value: str | float | None) -> float:
    try:
        return float(value)  # type: ignore[arg-type]
    except (TypeError, ValueError):
        return math.nan


def yes(value: str | bool | None) -> bool:
    return str(value).strip().lower() in {"1", "true", "yes"}


def fmt(value: str | float | None, digits: int = 5) -> str:
    number = num(value)
    if math.isnan(number):
        text = "" if value is None else str(value)
        return text.replace("|", r"\|")
    if number == 0:
        return "0"
    if abs(number) >= 1e4 or abs(number) < 1e-3:
        return f"{number:.{digits}e}"
    return f"{number:.{digits}f}".rstrip("0").rstrip(".")


def md_table(data: list[dict[str, str]], columns: list[tuple[str, str]], limit=None) -> str:
    if limit is not None:
        data = data[:limit]
    head = "| " + " | ".join(label for _, label in columns) + " |"
    rule = "|" + "|".join("---" for _ in columns) + "|"
    body = []
    for row in data:
        values = []
        for key, _ in columns:
            value = row.get(key, "")
            value = {
                "CREDIBLE": "可信",
                "FAILED": "未满足可信度判据",
                "VALID_CENTRAL_DIFFERENCE": "有效中心差分",
                "true": "是",
                "false": "否",
                "1": "是" if key in {"nearRepeatedRoot", "pathologicalEigenvectors"} else "1",
                "0": "否" if key in {"nearRepeatedRoot", "pathologicalEigenvectors"} else "0",
                "NINE_STATE_PHYSICAL_CONTROL": "九状态直接物理操纵",
                "THIRTEEN_STATE_TORQUE": "十三状态短舱力矩输入",
                "THIRTEEN_STATE_ANGLE_COMMAND": "十三状态短舱角命令输入",
            }.get(value, value)
            if re.fullmatch(r"[-+]?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?", value or ""):
                value = fmt(value)
            values.append((value or "").replace("|", r"\|"))
        body.append("| " + " | ".join(values) + " |")
    return "\n".join([head, rule, *body])


def extract_core_model_chapters() -> str:
    text = HISTORICAL_MD.read_text(encoding="utf-8")
    start = text.index("# 第二章")
    end = text.index("# 第六章")
    core = text[start:end]
    # The report is independent from the historical thesis and uses the new
    # task's figures.  Remove historical image/caption pairs but retain all
    # equations and model-principle prose.
    core = re.sub(r"\n!\[[^\]]*\]\([^)]+\)\n", "\n", core)
    core = re.sub(r"\n\*图\s*\d+[^*]*\*\n", "\n", core)
    historical_result_markers = (
        "联合优化",
        "三个新增工况",
        "三个点的九状态",
        "三个工况的该项",
        "本文代表点中",
        "B15和B45",
        "0.0079至0.2006",
        "75°构型俯仰平衡",
    )
    paragraphs = re.split(r"\n{2,}", core)
    core = "\n\n".join(
        paragraph
        for paragraph in paragraphs
        if not any(marker in paragraph for marker in historical_result_markers)
    )
    replacements = {
        "论文": "报告",
        "送审": "技术审查",
        "门禁": "可信度判据",
        "冻结": "预先规定",
        "PASS": "满足判据",
        "FAIL": "不满足判据",
        "production": "正式计算",
        "owner-visible": "可追溯",
    }
    for old, new in replacements.items():
        core = core.replace(old, new)
    return core.strip()


def select_mid(data: list[dict[str, str]], names: list[str]) -> list[dict[str, str]]:
    return [
        row
        for row in data
        if row.get("stepLevel") == "2" and row.get("coefficientName") in names
    ]


def build_markdown() -> str:
    rep = rows("REPRESENTATIVE_POINT_AUDIT.csv")
    trim = rows("TRIM_CHARACTERISTICS_BY_MODE.csv")
    static = rows("STATIC_STABILITY_DERIVATIVES.csv")
    damping = rows("DAMPING_DERIVATIVES.csv")
    controls = rows("CONTROL_EFFECTIVENESS_DERIVATIVES.csv")
    deriv_cross = rows("DERIVATIVE_CROSSCHECK.csv")
    control_cross = rows("CONTROL_DERIVATIVE_CROSSCHECK.csv")
    modal = rows("MODAL_PARAMETERS.csv")
    classes = rows("MODAL_CLASSIFICATION.csv")
    conditioning = rows("MODAL_CONDITIONING.csv")
    steps = rows("CONTROL_STEP_RESPONSE_METRICS.csv")
    step_compare = rows("CONTROL_STEP_LINEAR_NONLINEAR_COMPARISON.csv")
    step_dt = rows("CONTROL_STEP_TIMESTEP_CONVERGENCE.csv")

    key_static_names = [
        "CX_alpha",
        "CZ_alpha",
        "Cm_alpha",
        "CY_betaSlip",
        "Cl_betaSlip",
        "Cn_betaSlip",
    ]
    key_damping_names = ["Cl_p", "Cl_r", "Cm_q", "Cn_p", "Cn_r"]
    key_control_names = [
        "Cm_elevator",
        "Cl_aileron",
        "Cn_rudder",
        "Cl_diffCollective",
        "Cn_diffCollective",
        "Cl_diffCyclic",
        "Cn_diffCyclic",
        "Cm_cyclicLong",
    ]
    static_key = select_mid(static, key_static_names)
    damping_key = select_mid(damping, key_damping_names)
    control_key = select_mid(controls, key_control_names)
    full_a = sum(row.get("status") == "FULL_CROSSCHECK" for row in deriv_cross)
    partial_a = sum(row.get("status") == "PARTIAL_CROSSCHECK" for row in deriv_cross)
    full_b = sum(row.get("status") == "FULL_CROSSCHECK" for row in control_cross)
    partial_b = sum(row.get("status") == "PARTIAL_CROSSCHECK" for row in control_cross)
    unstable = sum(row.get("stability") == "UNSTABLE" for row in modal)
    pathological = sum(yes(row.get("pathologicalEigenvectors")) for row in conditioning)
    uncertain = sum(row.get("classification") == "MIXED_OR_UNCERTAIN_MODE" for row in classes)
    max_bio = max(num(row.get("biorthogonalityError")) for row in conditioning)
    max_dt = max(num(row.get("relativeChangeFromFinest")) for row in step_dt)
    direction_fraction = sum(yes(row.get("directionAgreement")) for row in step_compare) / max(
        len(step_compare), 1
    )
    all_rep = all(yes(row.get("credible")) and yes(row.get("physicalConverged")) for row in rep)

    abstract = rf"""# 摘要与符号说明

本报告在统一机体系和部件级载荷合成框架下，对通用低阶倾转旋翼机模型开展开环操纵稳定特性后处理。研究对象包括九状态刚体模型与包含左右短舱角、角速度的十三状态规定运动模型。三个代表点分别为短舱角 15°/20 m/s、45°/35 m/s 和 75°/80 m/s；复算结果显示三点可信度与旋翼物理闭合状态均为“{'满足' if all_rep else '存在未满足项'}”。分析采用保持空速模长的迎角和侧滑角重构、三档中心差分、完整质量与惯量换算、左右特征向量双正交归一化以及线性—非线性同时间步小扰动对照。

结果文件给出静稳定导数、阻尼导数、七个物理控制通道的直接力/矩导数、九状态和十三状态全部特征根、参与因子、控制阶跃与分模式配平特性。A 矩阵链式反推中 {full_a} 项满足完整交叉核查，{partial_a} 项因刚体、重力或运动学耦合保留为部分核查；B 矩阵换算中 {full_b} 项满足完整交叉核查，{partial_b} 项保留为部分核查。全部模态表中记录 {unstable} 个局部不稳定根；{uncertain} 个根因状态参与不集中或数值条件限制标为 `MIXED_OR_UNCERTAIN_MODE`，没有强行套用经典模态名称。参与因子最大双正交误差为 {max_bio:.3e}。控制阶跃最细时间步相对差异最大值为 {max_dt:.3e}，线性与非线性响应方向一致比例为 {direction_fraction:.1%}。

NASA TM-86854 图 25 仅用于总距增加时推力增加的趋势方向对照。该文献横轴为 \(0.75R\) 桨距，而当前模型命令总距是叠加于既定扭转分布的控制量，尚未形成同构横坐标。因此既有 MAE/RMSE 只能称为“未经同构映射的原始曲线差异诊断”，不作为模型预测误差、型号验证或结论核心指标。

本报告的适用范围是通用低阶模型的飞行动力学机理、开环稳定性、操纵效能和短舱动态状态影响研究；不支持 XV-15 定量复现、具体型号性能预测、飞行安全包线认证、正式操纵品质评级或完整伺服—铰链—结构双向耦合结论。

**关键词：** 倾转旋翼机；部件级建模；开环稳定性；操纵导数；参与因子；短舱动态状态

## 主要符号

|符号|含义|单位|
|---|---|---|
|\(u,v,w\)|机体系速度分量|m/s|
|\(p,q,r\)|机体系角速度|rad/s|
|\(\phi,\theta,\psi\)|滚转、俯仰、偏航欧拉角|rad|
|\(\beta_M\)|短舱构型角|rad|
|\(\beta_{{\\rm slip}}\)|侧滑角|rad|
|\(\mathbf F_b,\mathbf M_b\)|机体系合力、关于重心的合力矩|N，N·m|
|\(\mathbf A,\mathbf B\)|状态矩阵、输入矩阵|按状态与输入定义|
|\(V,W\)|右、左特征向量矩阵|1|
|\(P_{{ki}}\)|状态 \(k\) 对模态 \(i\) 的参与因子|1|

# 第一章　研究背景与技术目标

## 1.1 研究对象

倾转旋翼机在短舱转换过程中同时改变旋翼推力方向、机翼局部来流、尾翼动压、质量属性和操纵权限。公开数据不足以唯一辨识具体型号的完整气动和执行机构参数，因此本研究采用通用、低阶、部件级正向机理模型，强调坐标、单位、力矩参考点、物理分支与数值闭合的一致性。

## 1.2 技术目标与问题分解

报告依次回答四类问题：部件载荷如何在统一坐标系中闭合；可信配平点附近的静稳定、阻尼与操纵导数如何由直接力/矩扰动得到；九状态和十三状态模型的局部根、参与因子及短舱执行机构模态如何解释；小幅操纵阶跃在有限时间内的线性—非线性一致性和相对效能如何变化。

## 1.3 研究边界

本研究不通过调参追求“更稳定”或“更像文献”的结果，不删除不收敛点，不跨不同显式配平模式连接曲线，也不将数值可积、配平可信或局部特征根稳定混为模型正确性证明。分析结果只对应列出的离散工况和概念参数。
""".replace("\\\\", "\\")

    chapter7 = rf"""# 第六章　模型校核、外部趋势参考和适用边界

## 6.1 可信度证据层级

可信度证据由接口核查、极限工况、对称性、质量与惯量、旋翼物理闭合、配平回代、差分步长、线性—非线性局部对照和外部趋势参考组成。程序测试通过仅说明覆盖工况下的内部一致性，不表示具体型号试验验证。

## 6.2 控制接口核查

九状态输入依次为对称总距、差动总距、对称纵向周期变距、差动纵向周期变距、副翼、升降舵和方向舵。短舱角是外部构型参数。十三状态力矩输入在八个常规操纵之后使用左右短舱力矩；命令输入则使用左右短舱角命令。详细证据见 `CONTROL_INPUT_INTERFACE_AUDIT.md`。

## 6.3 NASA 旋翼曲线声明边界

NASA TM-86854 的 `COLL` 是 \(0.75R\) 桨距；当前命令总距的零点与该局部桨距零点不同。两条曲线仅在各自坐标中保留“总距增加、推力增加”的方向对照。原始 MAE/RMSE 是未经同构映射的原始曲线差异诊断，不得称为模型预测误差。低总距失败点全部保留。详细核查见 `EXTERNAL_ROTOR_COMPARISON_CLAIM_AUDIT.md`。

# 第七章　分模式配平特性

## 7.1 三个代表点

{md_table(rep, [
    ("pointId", "工况"),
    ("mode", "显式模式"),
    ("betaMDeg", "短舱角/(°)"),
    ("speedMps", "速度/(m/s)"),
    ("thetaDeg", "俯仰角/(°)"),
    ("alphaDeg", "迎角/(°)"),
    ("collectiveDeg", "总距/(°)"),
    ("cyclicLongDeg", "纵向周期/(°)"),
    ("elevatorDeg", "升降舵/(°)"),
    ("dynamicResidualNorm", "动态残差"),
    ("conditionNumber", "条件数"),
    ("minimumControlMarginFraction", "最小余度"),
])}

三点均采用显式配平模式并检查完整残差、控制边界、Jacobian/SVD 条件与左右旋翼物理闭合。75°/40 m/s 等失败点只保留在分模式离散表中，不进入导数、模态和阶跃分析。

## 7.2 分模式离散特性

{md_table(trim, [
    ("pointId", "工况"),
    ("mode", "模式"),
    ("speedMps", "速度"),
    ("betaMDeg", "短舱角"),
    ("thetaDeg", "俯仰角"),
    ("alphaDeg", "迎角"),
    ("collectiveDeg", "总距"),
    ("cyclicLongDeg", "纵向周期"),
    ("elevatorDeg", "升降舵"),
    ("minimumControlMarginFraction", "控制余度"),
    ("dynamicResidualNorm", "残差"),
    ("status", "状态"),
])}

![分模式离散配平特性](figures/FIG04_TRIM_CHARACTERISTICS_BY_MODE.png)

图中各模式分别连线，仅用于同一显式配平定义内的离散变化展示。跨模式边界不计算连续梯度，也不将九点集合解释为连续转换走廊。

# 第八章　静稳定性、阻尼导数和操纵导数

## 8.1 定义与归一化

机体系采用 \(x\) 向前、\(y\) 向右、\(z\) 向下。迎角和侧滑角分别为

$$
\\alpha=\\operatorname{{atan2}}(w,u),\\qquad
\\beta_{{\\rm slip}}=\\arcsin(v/V).
$$

扰动迎角或侧滑角时保持 \(V=\sqrt{{u^2+v^2+w^2}}\) 不变。力系数以 \(q_\\infty S\) 归一化，滚转和偏航矩系数以 \(q_\\infty Sb\) 归一化，俯仰矩系数以 \(q_\\infty S\\bar c\) 归一化。角速度导数采用 \(pb/(2V)\)、\(q\\bar c/(2V)\)、\(rb/(2V)\) 的无量纲角速度。

中心差分为

$$
f_\\xi\\approx\\frac{{f(\\xi+h)-f(\\xi-h)}}{{2h}}.
$$

角度和物理控制采用 \(10^{{-3}},10^{{-4}},10^{{-5}}\) rad；角速度采用 \(10^{{-2}},10^{{-3}},10^{{-4}}\) rad/s。CSV 保存正负扰动力/矩、三档步长、有量纲与无量纲导数、离散差异和有效性状态。

## 8.2 关键静稳定导数

{md_table(static_key, [
    ("pointId", "工况"),
    ("coefficientName", "导数"),
    ("step", "中档步长"),
    ("dimensionalDerivative", "有量纲导数"),
    ("coefficientDerivative", "无量纲导数"),
    ("relativeStepVariation", "三步长相对差异"),
    ("status", "有效性"),
])}

## 8.3 关键阻尼导数

{md_table(damping_key, [
    ("pointId", "工况"),
    ("coefficientName", "导数"),
    ("step", "中档步长"),
    ("dimensionalDerivative", "有量纲导数"),
    ("coefficientDerivative", "无量纲导数"),
    ("relativeStepVariation", "三步长相对差异"),
    ("status", "有效性"),
])}

## 8.4 关键操纵导数

{md_table(control_key, [
    ("pointId", "工况"),
    ("coefficientName", "导数"),
    ("step", "中档步长"),
    ("coefficientDerivative", "无量纲导数"),
    ("relativeStepVariation", "三步长相对差异"),
    ("status", "有效性"),
])}

![三个代表点的关键直接导数](figures/FIG01_KEY_DERIVATIVES.png)

副翼、差动总距和差动纵向周期变距分别报告。对称纵向周期变距主要通过共同盘面倾斜进入俯仰通道；差动通道同时可能产生滚转和偏航交叉效应，符号必须结合左右分配和旋向解释。

## 8.5 A/B 矩阵交叉核查

\(\mathbf A\) 和 \(\mathbf B\) 分别是状态导数对状态和输入的 Jacobian，不直接等于气动力系数导数。反推过程使用质量、完整惯量矩阵、速度角链式关系和角速度运动学项。A 路径有 {full_a} 项满足完整核查、{partial_a} 项标记为部分核查；B 路径有 {full_b} 项满足完整核查、{partial_b} 项标记为部分核查。部分核查状态被保留，不伪造成一致。

# 第九章　特征根、模态参数及参与分析

## 9.1 参数定义

对复根 \(\lambda=\\sigma+j\\omega\)，采用

$$
\\omega_n=\\sqrt{{\\sigma^2+\\omega^2}},\\qquad
\\zeta=-\\frac{{\\sigma}}{{\\omega_n}},\\qquad
T=\\frac{{2\\pi}}{{|\\omega|}}.
$$

稳定实根报告 \(\tau=-1/\\lambda\)，不稳定根报告倍增时间 \(\ln 2/\\Re(\\lambda)\)。左右特征向量按 \(W^H V=I\) 双正交归一化，参与因子定义为 \(P_{{ki}}=V_{{ki}}W_{{ik}}\)，同时保存原始复数分量和按模态归一化的幅值。

## 9.2 条件性

{md_table(conditioning, [
    ("pointId", "工况"),
    ("modelKind", "模型"),
    ("matrixOrder", "阶数"),
    ("eigenvectorConditionNumber", "特征向量条件数"),
    ("biorthogonalityError", "双正交误差"),
    ("relativeMinimumSeparation", "最小相对间隔"),
    ("nearRepeatedRoot", "近重根"),
    ("pathologicalEigenvectors", "病态"),
])}

本批次共有 {pathological} 个模型矩阵触发病态判据，最大双正交误差为 {max_bio:.3e}。测试还使用人工近重根矩阵核实：病态情形不会被强制命名。

## 9.3 分类原则与结果

状态参与按纵向刚体、横航向刚体、短舱对称、短舱差动和执行机构速率分组。主导组得分不足、前两组差距过小、近重根或特征向量条件不良时统一标记 `MIXED_OR_UNCERTAIN_MODE`。本次共有 {uncertain} 个根采用该标签；报告不在证据不足时套用经典短周期、长周期、荷兰滚、螺旋或滚转收敛名称。

![九状态与十三状态开环特征根](figures/FIG02_OPEN_LOOP_EIGENVALUES.png)

![45°/35 m/s 十三状态命令模型参与因子](figures/FIG03_MODAL_PARTICIPATION.png)

不同显式配平模式之间未执行连续模态追踪。表中局部索引只在本工况、本模型内有效。

# 第十章　常规操纵响应

## 10.1 事件定义

对升降舵、副翼、方向舵、差动总距、差动纵向周期变距和对称纵向周期变距施加 0.5° 直接物理控制阶跃。非线性模型与九状态线性模型使用同一 Heun 积分和相同时间步。默认检查 0.02 s 与 0.01 s；当主响应峰值变化超过 2% 时增加 0.005 s。

## 10.2 峰值与相对效能

{md_table(steps, [
    ("pointId", "工况"),
    ("controlName", "输入"),
    ("stepAmplitudeDeg", "幅值/(°)"),
    ("dtSeconds", "最细步长/(s)"),
    ("primaryStateName", "主响应"),
    ("primaryPeak", "主峰值"),
    ("primaryPeakTimeSeconds", "峰值时间/(s)"),
    ("validDomainDurationSeconds", "有效域/(s)"),
    ("maximumLinearNonlinearStateError", "最大线性—非线性差"),
    ("relativeToB45V35", "相对45°/35"),
])}

![各通道直接物理控制相对效能](figures/FIG05_CONTROL_EFFECTIVENESS.png)

## 10.3 收敛性与解释边界

最细时间步相对差异最大值为 {max_dt:.3e}；线性和非线性状态峰值方向一致比例为 {direction_fraction:.1%}。初始角加速度是状态方程瞬时响应，有限时间角速度和姿态峰值还包含状态耦合，二者均不能替代静态力/矩操纵导数。短舱角命令经过执行机构动态，与本章直接物理控制阶跃分开解释。

# 第十一章　短舱动态状态与开环响应

十三状态模型在九个刚体状态之外引入左右短舱角及角速度。对称、差动坐标分别揭示共同倾转和左右不同步通道；二阶规定运动执行机构、移动质量、反作用力矩与转子陀螺接口均保留。其执行机构相关特征根主要由概念带宽与阻尼参数决定，不能解释为真实结构模态或完整伺服—铰链耦合。

九状态与十三状态固定短舱角的静态载荷基准可对应，但角速度扰动下的动态载荷重算会改变共同刚体子块。因此，十三状态扩展不是简单把四个极点附加在九状态矩阵末尾。对称和差动短舱运动的时域研究沿用既有有效域、物理分支和时间步判据，本报告不把它扩展为负推力、风车或机械卡滞载荷模型。

# 第十二章　讨论、结论与后续工作

## 12.1 主要结论

1. 三个代表点在显式配平模式下保持可信并满足左右旋翼物理闭合，可作为本报告局部分析基点。
2. 直接力/矩中心差分给出了可追溯的静稳定、阻尼和操纵导数；A/B 交叉核查严格区分完整与部分可比项。
3. 九状态与十三状态根必须结合参与因子和条件数解释。局部正实部根被保留，数值可积不等于开环动态稳定。
4. 六类 0.5° 物理操纵阶跃给出了初始角加速度、峰值、有效域和时间步收敛。相对效能随短舱角和速度改变，不代表型号级操纵品质等级。
5. NASA 图 25 只支持原始坐标中的斜率方向对照；在 \(0.75R\) 桨距映射建立前，MAE/RMSE 不是模型预测误差。

## 12.2 局限

模型使用概念参数、稳态低阶旋翼与简化干扰关系，缺少同构型整机载荷、飞行辨识、短舱时历和执行机构载荷数据。三个代表点是离散局部证据，不是连续飞行包线。参与因子对状态尺度敏感，跨模式连续追踪尚未实施。

## 12.3 后续工作

后续可在不改变本报告结论的前提下，逐项引入来源明确的公开参数、同构控制坐标、更多同模式局部点和独立飞行辨识数据。动态入流、自由尾迹、CFD、动态失速、负推力/风车分支、正式操纵品质评级与飞控设计均属于独立后续任务。

# 第十三章　附录与复现说明

## 13.1 状态与输入顺序

九状态顺序为 \([u,v,w,p,q,r,\\phi,\\theta,\\psi]^T\)。九状态控制顺序为 `collective`、`diffCollective`、`cyclicLong`、`diffCyclic`、`aileron`、`elevator`、`rudder`。十三状态、力矩输入和命令输入的完整顺序见接口审计。

## 13.2 复现入口

MATLAB 入口为 `analysis/control_stability/run_full_assessment_batch.m`。该入口从默认 `params_berger13()` 参数集重新计算九点显式模式数据库，在三个代表点生成全部 CSV、MAT 文件、原始时历、图件与日志。报告构建入口为 `docs/tiltrotor_control_stability_technical_report/scripts/build_report.py`。

## 13.3 结果文件

原始数据包含静稳定、阻尼、A 矩阵交叉核查、操纵导数、B 矩阵交叉核查、模态参数、参与因子、模态分类、模态条件性、控制阶跃指标、线性—非线性对照、时间步收敛和分模式配平特性。SHA-256 清单用于核对交付完整性。

## 13.4 公式—代码—参数—测试追溯

|对象|分析代码|正式计算接口|结果或测试|
|---|---|---|---|
|迎角/侧滑重构|`perturb_body_flow_angles.m`|九状态速度定义|静稳定 CSV、聚焦测试|
|直接导数|`compute_direct_derivatives.m`|`total_forces_moments.m`|静稳定、阻尼、操纵 CSV|
|A/B 交叉核查|`compute_direct_derivatives.m`、`crosscheck_control_derivatives.m`|质量、惯量、状态方程|交叉核查 CSV|
|参与因子|`analyze_modal_participation.m`|九/十三状态 A 矩阵|模态 CSV、病态矩阵测试|
|控制阶跃|`simulate_direct_control_step.m`|`tiltrotor_eom.m`|阶跃 CSV、原始时历|
|配平特性|`run_control_stability_assessment.m`|显式模式配平入口|分模式 CSV|

## 13.5 参考资料

- Felker, F. F., Young, L. A., and Signor, D. B. *Full-Scale Hover Testing of the XV-15 Advanced Technology Blade Rotor*. NASA TM-86854, 1987.
- NASA TM-X-62407 与 NASA TM-81244：公开倾转旋翼机几何、气动与试验资料候选；数值引用须逐项复核构型、页码和单位。
- 南航公开论文 `references/NUAA_main_paper.pdf`：部件划分、坐标变换、六自由度方程、配平与数值线性化的方法参考。
""".replace("\\\\", "\\")

    return "\n\n".join([abstract, extract_core_model_chapters(), chapter7]) + "\n"


def pandoc_latex_body(markdown_path: Path) -> str:
    command = [
        str(PANDOC),
        str(markdown_path),
        "--from=markdown+tex_math_dollars",
        "--to=latex",
        "--top-level-division=chapter",
        f"--resource-path={REPORT}",
    ]
    result = subprocess.run(command, text=True, encoding="utf-8", capture_output=True)
    if result.returncode:
        raise RuntimeError(result.stderr)
    return result.stdout


def build_tex(markdown_path: Path) -> None:
    TEX_DIR.mkdir(parents=True, exist_ok=True)
    body = pandoc_latex_body(markdown_path)
    body = body.replace(r"\tightlist", "")
    preamble = rf"""\documentclass[UTF8,11pt,oneside,openany,fontset=windows]{{ctexbook}}
\usepackage[a4paper,left=24mm,right=24mm,top=25mm,bottom=24mm,headheight=15pt]{{geometry}}
\usepackage{{fontspec,xeCJK,graphicx,booktabs,longtable,array,amsmath,amssymb,bm}}
\usepackage{{caption,float,fancyhdr,hyperref,bookmark,microtype,xcolor}}
\graphicspath{{{{../}}}}
\usepackage[backend=biber,style=gb7714-2015,sorting=none]{{biblatex}}
\addbibresource{{references.bib}}
\setmainfont{{Times New Roman}}
\hypersetup{{hidelinks,pdftitle={{{TITLE}}},pdfauthor={{技术研究报告}}}}
\captionsetup{{font=small,labelsep=quad}}
\setlength{{\parindent}}{{2em}}
\setlength{{\parskip}}{{0pt}}
\linespread{{1.32}}
\raggedbottom
\pagestyle{{fancy}}
\fancyhf{{}}
\fancyhead[C]{{\small 倾转旋翼机开环操纵稳定特性分析研究报告}}
\fancyfoot[C]{{\thepage}}
\setcounter{{secnumdepth}}{{3}}
\setcounter{{tocdepth}}{{2}}
\emergencystretch=3em
\begin{{document}}
\begin{{titlepage}}
\centering
\vspace*{{28mm}}
{{\zihao{{1}}\bfseries\color[HTML]{{2E74B5}} {TITLE}\par}}
\vspace{{14mm}}
\rule{{0.78\textwidth}}{{0.8pt}}\par
\vspace{{12mm}}
{{\zihao{{3}} 通用低阶部件级模型技术研究报告\par}}
\vfill
{{\zihao{{-4}} 数值基线：MATLAB R2021a\par}}
\vspace{{4mm}}
{{\zihao{{-4}} 生成日期：{datetime.now():%Y年%m月%d日}\par}}
\end{{titlepage}}
\frontmatter
\tableofcontents
\listoffigures
\listoftables
\mainmatter
"""
    ending = r"""
\backmatter
\nocite{*}
\printbibliography[heading=bibintoc,title={参考文献}]
\end{document}
"""
    TEX_OUT.write_text(preamble + body + ending, encoding="utf-8")
    BIB_OUT.write_text(
        """@techreport{felker1987,
  author={Felker, Fort F. and Young, Larry A. and Signor, David B.},
  title={Full-Scale Hover Testing of the XV-15 Advanced Technology Blade Rotor},
  institution={NASA},
  number={TM-86854},
  year={1987}
}
@techreport{nasa62407,
  author={{NASA}},
  title={Tiltrotor Research Reference, NASA TM-X-62407},
  institution={NASA},
  number={TM-X-62407},
  year={1970}
}
@techreport{nasa81244,
  author={{NASA}},
  title={Tiltrotor Research Reference, NASA TM-81244},
  institution={NASA},
  number={TM-81244},
  year={1980}
}
""",
        encoding="utf-8",
    )


def set_style_font(style, east_asia: str, latin: str, size: float, bold=None, color=None):
    style.font.name = latin
    style.font.size = Pt(size)
    if bold is not None:
        style.font.bold = bold
    if color:
        style.font.color.rgb = RGBColor.from_string(color)
    rpr = style.element.get_or_add_rPr()
    rfonts = rpr.rFonts
    if rfonts is None:
        rfonts = OxmlElement("w:rFonts")
        rpr.insert(0, rfonts)
    for attr, value in (("eastAsia", east_asia), ("ascii", latin), ("hAnsi", latin)):
        rfonts.set(qn(f"w:{attr}"), value)


def set_run_font(run, east_asia="微软雅黑", latin="Calibri", size=11, bold=None, color=None):
    run.font.name = latin
    run.font.size = Pt(size)
    if bold is not None:
        run.bold = bold
    if color:
        run.font.color.rgb = RGBColor.from_string(color)
    rpr = run._element.get_or_add_rPr()
    rfonts = rpr.rFonts
    if rfonts is None:
        rfonts = OxmlElement("w:rFonts")
        rpr.insert(0, rfonts)
    for attr, value in (("eastAsia", east_asia), ("ascii", latin), ("hAnsi", latin)):
        rfonts.set(qn(f"w:{attr}"), value)


def insert_before(anchor: Paragraph, text="", style=None) -> Paragraph:
    new_p = OxmlElement("w:p")
    anchor._p.addprevious(new_p)
    paragraph = Paragraph(new_p, anchor._parent)
    if style:
        paragraph.style = style
    if text:
        paragraph.add_run(text)
    return paragraph


def add_field(paragraph: Paragraph, instruction: str, placeholder: str = ""):
    run = paragraph.add_run()
    begin = OxmlElement("w:fldChar")
    begin.set(qn("w:fldCharType"), "begin")
    instr = OxmlElement("w:instrText")
    instr.set(qn("xml:space"), "preserve")
    instr.text = instruction
    separate = OxmlElement("w:fldChar")
    separate.set(qn("w:fldCharType"), "separate")
    text = OxmlElement("w:t")
    text.text = placeholder
    end = OxmlElement("w:fldChar")
    end.set(qn("w:fldCharType"), "end")
    run._r.extend([begin, instr, separate, text, end])


def set_table_geometry(table):
    widths_total = 9360
    count = len(table.columns)
    widths = [widths_total // count] * count
    widths[-1] += widths_total - sum(widths)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.autofit = False
    tbl_pr = table._tbl.tblPr
    tbl_w = tbl_pr.find(qn("w:tblW"))
    if tbl_w is None:
        tbl_w = OxmlElement("w:tblW")
        tbl_pr.append(tbl_w)
    tbl_w.set(qn("w:w"), str(widths_total))
    tbl_w.set(qn("w:type"), "dxa")
    tbl_ind = tbl_pr.find(qn("w:tblInd"))
    if tbl_ind is None:
        tbl_ind = OxmlElement("w:tblInd")
        tbl_pr.append(tbl_ind)
    tbl_ind.set(qn("w:w"), "120")
    tbl_ind.set(qn("w:type"), "dxa")
    grid = table._tbl.tblGrid
    for child in list(grid):
        grid.remove(child)
    for width in widths:
        col = OxmlElement("w:gridCol")
        col.set(qn("w:w"), str(width))
        grid.append(col)
    for row_index, row in enumerate(table.rows):
        for col_index, cell in enumerate(row.cells):
            cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
            tc_pr = cell._tc.get_or_add_tcPr()
            tc_w = tc_pr.find(qn("w:tcW"))
            if tc_w is None:
                tc_w = OxmlElement("w:tcW")
                tc_pr.append(tc_w)
            tc_w.set(qn("w:w"), str(widths[col_index]))
            tc_w.set(qn("w:type"), "dxa")
            if row_index == 0:
                shd = OxmlElement("w:shd")
                shd.set(qn("w:fill"), "F4F6F9")
                tc_pr.append(shd)
            for paragraph in cell.paragraphs:
                paragraph.paragraph_format.space_after = Pt(2)
                paragraph.paragraph_format.line_spacing = 1.0
                paragraph.alignment = (
                    WD_ALIGN_PARAGRAPH.CENTER
                    if row_index == 0
                    else WD_ALIGN_PARAGRAPH.LEFT
                )
                for run in paragraph.runs:
                    set_run_font(run, size=8.3, bold=(row_index == 0))


def style_docx(path: Path) -> None:
    doc = Document(path)
    section = doc.sections[0]
    section.page_width = Mm(210)
    section.page_height = Mm(297)
    section.left_margin = Mm(22.45)
    section.right_margin = Mm(22.45)
    section.top_margin = Mm(24)
    section.bottom_margin = Mm(22)
    section.header_distance = Mm(10)
    section.footer_distance = Mm(10)
    section.different_first_page_header_footer = True

    # narrative_proposal preset, exact core tokens
    normal = doc.styles["Normal"]
    set_style_font(normal, "微软雅黑", "Calibri", 11)
    pf = normal.paragraph_format
    pf.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    pf.space_after = Pt(8)
    pf.line_spacing = 1.333
    for name, size, color, before, after in (
        ("Heading 1", 16, "2E74B5", 18, 10),
        ("Heading 2", 13, "2E74B5", 12, 6),
        ("Heading 3", 12, "1F4D78", 8, 4),
    ):
        style = doc.styles[name]
        set_style_font(style, "微软雅黑", "Calibri", size, bold=True, color=color)
        style.paragraph_format.space_before = Pt(before)
        style.paragraph_format.space_after = Pt(after)
        style.paragraph_format.keep_with_next = True
    for name in ("List Paragraph", "List Bullet", "List Number"):
        if name not in doc.styles:
            continue
        style = doc.styles[name]
        set_style_font(style, "微软雅黑", "Calibri", 11)
        style.paragraph_format.left_indent = Mm(9.525)  # 0.375 in
        style.paragraph_format.first_line_indent = Mm(-4.928)  # 0.194 in
        style.paragraph_format.space_after = Pt(4)
        style.paragraph_format.line_spacing = 1.208
    if "Caption" in doc.styles:
        caption = doc.styles["Caption"]
        set_style_font(caption, "微软雅黑", "Calibri", 9.5, color="555555")
        caption.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.CENTER
        caption.paragraph_format.space_after = Pt(8)

    for paragraph in doc.paragraphs:
        if paragraph.style.name == "Normal":
            paragraph.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
            for run in paragraph.runs:
                if not paragraph._p.xpath(".//m:oMath"):
                    set_run_font(run)
    for table in doc.tables:
        set_table_geometry(table)

    # Quiet running header/footer.
    header = section.header.paragraphs[0]
    header.alignment = WD_ALIGN_PARAGRAPH.CENTER
    header.text = "倾转旋翼机开环操纵稳定特性分析研究报告"
    for run in header.runs:
        set_run_font(run, size=9, color="777777")
    footer = section.footer.paragraphs[0]
    footer.alignment = WD_ALIGN_PARAGRAPH.CENTER
    add_field(footer, " PAGE ", "1")
    for run in footer.runs:
        set_run_font(run, size=9, color="777777")

    # editorial_cover: title, rule, subtitle, report identity, date.
    anchor = doc.paragraphs[0]
    title_p = insert_before(anchor, TITLE)
    title_p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    title_p.paragraph_format.space_before = Pt(100)
    title_p.paragraph_format.space_after = Pt(28)
    for run in title_p.runs:
        set_run_font(run, size=28, bold=True, color="2E74B5")
    rule_p = insert_before(anchor, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    rule_p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    for run in rule_p.runs:
        set_run_font(run, size=10, color="2E74B5")
    type_p = insert_before(anchor, "通用低阶部件级模型技术研究报告")
    type_p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    for run in type_p.runs:
        set_run_font(run, size=15, color="1F4D78")
    date_p = insert_before(anchor, f"生成日期：{datetime.now():%Y年%m月%d日}")
    date_p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    page_break_cover = insert_before(anchor)
    page_break_cover.add_run().add_break(WD_BREAK.PAGE)
    toc_heading = insert_before(anchor, "目录")
    toc_heading.alignment = WD_ALIGN_PARAGRAPH.CENTER
    for run in toc_heading.runs:
        set_run_font(run, size=18, bold=True, color="2E74B5")
    toc = insert_before(anchor)
    add_field(toc, r' TOC \o "1-3" \h \z \u ', "更新域后显示目录")
    page_break_after_toc = insert_before(anchor)
    page_break_after_toc.add_run().add_break(WD_BREAK.PAGE)

    doc.core_properties.title = TITLE
    doc.core_properties.subject = "开环操纵稳定特性后处理与技术研究报告"
    doc.core_properties.author = "倾转旋翼机模型研究项目"
    settings = doc.settings.element
    update_fields = settings.find(qn("w:updateFields"))
    if update_fields is None:
        update_fields = OxmlElement("w:updateFields")
        settings.append(update_fields)
    update_fields.set(qn("w:val"), "true")
    doc.save(path)


def build_docx(markdown_path: Path) -> None:
    command = [
        str(PANDOC),
        str(markdown_path),
        "--from=markdown+tex_math_dollars",
        "--to=docx",
        f"--resource-path={REPORT}",
        "--output",
        str(DOCX_OUT),
    ]
    result = subprocess.run(command, text=True, encoding="utf-8", capture_output=True)
    if result.returncode:
        raise RuntimeError(result.stderr)
    style_docx(DOCX_OUT)


def docx_structure(path: Path) -> dict[str, int]:
    doc = Document(path)
    with zipfile.ZipFile(path) as archive:
        xml = archive.read("word/document.xml").decode("utf-8")
    return {
        "paragraphs": len(doc.paragraphs),
        "tables": len(doc.tables),
        "figures": len(doc.inline_shapes),
        "omml_display": xml.count("<m:oMathPara"),
        "omml_total": xml.count("<m:oMath"),
        "toc_fields": xml.count('TOC \\\\o') + xml.count('TOC \\o'),
    }


def main() -> None:
    missing = [name for name in REQUIRED_CSV if not (REPORT / name).exists()]
    if missing:
        raise SystemExit("Missing MATLAB evidence: " + ", ".join(missing))
    if not PANDOC.exists():
        raise SystemExit(f"Pandoc missing: {PANDOC}")
    (REPORT / "logs").mkdir(parents=True, exist_ok=True)
    (REPORT / "figures").mkdir(parents=True, exist_ok=True)
    markdown = build_markdown()
    MD_OUT.write_text(markdown, encoding="utf-8")
    build_tex(MD_OUT)
    build_docx(MD_OUT)
    structure = docx_structure(DOCX_OUT)
    log = [
        f"timestamp={datetime.now().isoformat()}",
        f"python={sys.version}",
        f"pandoc={PANDOC}",
        f"markdown={MD_OUT}",
        f"tex={TEX_OUT}",
        f"docx={DOCX_OUT}",
        *(f"{key}={value}" for key, value in structure.items()),
    ]
    BUILD_LOG.write_text("\n".join(log) + "\n", encoding="utf-8")
    print("\n".join(log))


if __name__ == "__main__":
    main()
