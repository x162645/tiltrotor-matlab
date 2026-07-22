from __future__ import annotations

import argparse
import csv
import hashlib
import shutil
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RESULT = ROOT / "results" / "berger13_final"
EXTERNAL = Path(r"E:\tiltrotor-work-output\13x10-correction-20260722")
TITLE = "规定执行器模型下倾转旋翼机左右短舱运动对刚体动态的影响研究"
FINAL_SHA_TOKEN = "见外部 FINAL_GITHUB_EVIDENCE_INDEX.md"
ZIP_NAME = "13X10_CORRECTED_RESEARCH_DELIVERABLES.zip"


def rows(name: str) -> list[dict[str, str]]:
    with (RESULT / name).open("r", encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def f(value: str, digits: int = 6) -> str:
    return f"{float(value):.{digits}g}"


def write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text.strip() + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--pr52-sha", default="PENDING_FINAL_COMMIT")
    parser.add_argument("--package", action="store_true")
    args = parser.parse_args()
    EXTERNAL.mkdir(parents=True, exist_ok=True)

    derivative = rows("13X10_DERIVATIVE_DATABASE.csv")
    eigen = rows("13X10_EIGENVALUE_DATABASE.csv")
    time = rows("13X10_TIME_DOMAIN_CASES.csv")
    convergence = rows("13X10_TIME_STEP_CONVERGENCE.csv")
    sensitivity = rows("13X10_SENSITIVITY_RESULTS.csv")
    tracking = rows("13X10_MODE_TRACKING_DATABASE.csv")
    trim = rows("13X10_TRIM_POINT_DATABASE.csv")

    rep_d = {r["derivativeName"]: r for r in derivative if r["pointId"] == "B45_V035"}
    rep_e = [r for r in eigen if r["pointId"] == "B45_V035"]
    time_by = {r["caseName"]: r for r in time}
    lock = time_by["left_kinematic_lock"]
    freeze = time_by["left_command_freeze"]
    delay = time_by["left_command_delay"]
    diff = time_by["differential_nacelle_step"]
    credible = sum(r["status"] == "CREDIBLE" for r in trim)
    failed = sum(r["status"] != "CREDIBLE" for r in trim)
    heading = next(r for r in rep_e if r["modeName"] == "heading kinematic integrator")
    spiral = next(r for r in rep_e if r["modeName"] == "spiral-like")
    roll = next(r for r in rep_e if r["modeName"] == "roll-like")
    dutch = next(r for r in rep_e if r["modeName"] == "dutch-roll-like" and float(r["imagPartRadPerSecond"]) > 0)
    short = next(r for r in rep_e if r["modeName"] == "short-period-like" and float(r["imagPartRadPerSecond"]) > 0)
    unstable = max((r for r in rep_e if r["modeName"] == "longitudinal aperiodic"), key=lambda r: float(r["realPartPerSecond"]))

    report = f"""
# 《{TITLE}》

## 摘要

本文在既有 Berger13 13 状态、10 输入低阶研究模型上，修正不同重心参考点混合、非对称移动质量惯量重构不完整、故障命名不严谨、航向零根误分类、导数单位推断、时步证据缺失、超包线定量引用、灵敏度量纲混合和跨工况缺口模态配对等问题。修正后的载荷链将左右旋翼、左右半翼、机身、平尾和垂尾均直接关于实际总重心计算；质量属性由固定部分、左移动组件和右移动组件重构。由于现有载荷对象不足以无重复地构造外部铰链广义力矩，最终采用规定二阶执行器到刚体的单向影响边界，不声称完整双向耦合或机械卡死载荷。

九个配平候选中 {credible} 个通过可信度门禁，{failed} 个保留为失败点。代表工况 B45_V035 的差动短舱角导数为 `d(vdot)/d(betaDiff)={f(rep_d['dv_dbetaDiff']['value'])} (m/s^2)/rad`、`d(pdot)/d(betaDiff)={f(rep_d['dp_dbetaDiff']['value'])} (rad/s^2)/rad`、`d(rdot)/d(betaDiff)={f(rep_d['dr_dbetaDiff']['value'])} (rad/s^2)/rad`。航向角零根被单列为 heading kinematic integrator。14 个主要时域工况均完成 0.1、0.05、0.025 s 比较，4 个工况进一步采用 0.0125 s；运动学锁止在 {f(lock['firstEnvelopeViolationTime'])} s 首次因侧滑守卫越界，有效前缀滚转和偏航峰值分别为 {float(lock['validMaxAbsRollMomentNm'])/1000:.3f} 和 {float(lock['validMaxAbsYawMomentNm'])/1000:.3f} kN m，超界后的全轨迹偏航峰值 {float(lock['fullMaxAbsYawMomentNm'])/1000:.3f} kN m 仅作为数值展示。本文结论限于当前低阶模型、所选工况和参数假设的内部一致性，不构成型号验证或飞行安全边界。

**关键词：** 倾转旋翼机；左右短舱；规定执行器；实际重心；模态分类；有效前缀；时间步收敛

## 1 引言

倾转旋翼机转换飞行同时改变推力方向、机翼滑流、局部来流、部件作用点和整机质量属性。左右短舱不同步进一步引入侧向力、滚转力矩和偏航力矩。本文目的不是另建平行模型，而是在现有 13×10 研究链上完成物理闭合与结果纠偏，使每个数值都能回溯到状态、输入、工况、单位、有效性和计算步长。

## 2 国内外研究现状

Sheng、Zhang 与 Xiang 将倾转旋翼机划分为旋翼、机翼、机身、平尾和垂尾，并以部件载荷合成 6DOF 方程。其 PDF 第 3 页列出刚体、小迎角/侧滑及忽略左右旋翼气动干扰等假设；第 5 页公式 (13)-(15) 给出诱导速度、旋翼坐标变换和力臂矩；第 6 页公式 (17)-(20) 给出滑流区局部速度、作用点与力矩；第 12 页公式 (37)-(40) 给出配平点和线性状态空间框架。NASA TM-81244 和 NASA TM X-62407 说明 XV-15 是研究飞行器及其设计/熟悉化背景，但本文没有从中抽取型号级气动或故障载荷参数。

## 3 当前研究定位

本研究是部件级、低阶、可计算的内部研究模型。它不复现 Berger 51 状态模型，不进行 XV-15 试验验证，也不提供操纵品质合格性或安全包线。Berger13 仅是本项目 13 状态命名空间；仓库没有 Berger 原文，因而相关结构对照标为 UNVERIFIED，需另行人工核对原始文献。

## 4 坐标系、符号和正方向

机体系采用前-右-下，状态速度与角速度在机体系表达，欧拉角采用 3-2-1 运动学。短舱正广义坐标绕 `eBeta=[0,-1,0]^T`。差动坐标定义 `betaDiff=(betaMR-betaML)/2`，正差动命令使右侧角增大、左侧角减小。所有角度在动力学中用 rad，图表可转换为 deg。

## 5 13 状态定义

状态为 `[u,v,w,p,q,r,phi,theta,psi,betaML,betaMR,betaMLdot,betaMRdot]^T`。对称/差动变换后末四项为 `[betaSym,betaDiff,betaSymDot,betaDiffDot]^T`。前三个速度单位 m/s，角速度和短舱角速度单位 rad/s，姿态角和短舱角单位 rad。

## 6 两套 10 输入接口

力矩接口末两项为左右短舱力矩，保留 PR1 合同。角指令接口末两项为 `betaMLCommand`、`betaMRCommand`；对称/差动变换后必须显式命名 `betaSymCommand`、`betaDiffCommand`，不得继承 torque 标签。两套接口不混用。

## 7 部件级基础模型

总载荷由左右旋翼、左右独立半翼区域和固定气动部件组成。NUAA 文章 PDF 第 8 页给出部件总力/总矩合成思路，第 9 页给出 6DOF 方程和欧拉运动学。本文复用其方法层级，不把文章参数自动视为当前模型参数。

## 8 左右独立旋翼

左右旋翼分别使用自身短舱角、旋向、局部刚体速度、诱导速度、推力、面内力和反扭矩。对称极限下两侧载荷镜像并退化到既有 NUAA 路径；非对称角度下不以平均角替代任一侧旋翼。

## 9 左右独立半翼滑流

每侧半翼使用对应旋翼诱导速度和短舱角，分别计算滑流区与自由流区。near-normal 与 lift-line 载荷在同一局部来流上连续混合。混合只避免人工跳变，不代表宽迎角试验验证。

## 10 统一实际重心下的力矩合成

旧实现将平均短舱角整机载荷与部分左右增量相加，造成力矩参考点混合。修正后两个旋翼、独立机翼、机身、平尾和垂尾均接收同一个 `cgActual`，直接输出关于实际总重心的力矩；刚体方程只接收这些部件的一次求和。平均角整机栈仅用于控制映射和诊断，不进入修正后的总力矩。

## 11 移动质量与惯量重构

质量分解为 `mTotal=mFixed+mLeft+mRight=6000 kg`，其中固定部分 5100 kg、左右移动点质量各 450 kg。先由平均构型质量矩反求固定部分重心，再从基线总惯量剥离左右平均点质量贡献，得到固定部分自身惯量，最后把固定、左、右三部分全部平移到实际总重心。42°/48° 审计点的 CG 为 `[0.079440493,0,0.033059507] m`，质量矩残差 `2.84e-14 kg m`，惯量重构残差为 0，最小主惯量 `1.7739e4 kg m^2`。未知左右短舱局部转动惯量保持 UNKNOWN，没有编造。

## 12 短舱执行机构

每侧规定二阶执行器为 `betaDDot=omegaN^2(betaCommand-beta)-2*zeta*omegaN*betaDot`，随后施加角度、速率、加速度和等效内力矩限制。`omegaN`、`zeta`、速率比例和外部命令延迟可左右独立。执行器模态的固定位置主要由 RESEARCH_PLACEHOLDER 参数决定。

## 13 单向耦合边界

现有旋翼/机体载荷链没有提供可证明不重复的短舱铰链外载对象，因此未实现 `Qexternal`。模型只支持“规定短舱运动影响刚体载荷与运动”，不支持“机体/气动载荷反馈决定短舱加速度”的双向闭合。执行器内力矩对机体的反力矩按 `-Qactuator eBeta` 施加，外部铰链力矩明确为零且带有未实现标志。

## 14 配平变量与残差

对称直线稳态配平使用固定工况速度、短舱平均角和飞行路径角，求解纵向状态与控制，并回代完整 13 状态方程。残差、缩放、边界、SVD、条件数、初值敏感性和 continuation 都被保存；求解器返回成功不是唯一门禁。

## 15 配平可信度门禁

九个候选中 {credible} 个 CREDIBLE，{failed} 个 FAILED。失败点不删除，也不参与导数、模态或跟踪。该门禁只说明覆盖工况的内部数值可信度，不是飞行包线。

## 16 数值线性化

可信点采用边界感知中心差分，并以 0.1、1、10 倍步长检查 A/B 稳定性。状态和输入的扰动单位由显式合同给出；不能对未配平点形成稳定性结论。NUAA 文章 PDF 第 12 页公式 (37)-(40) 仅支持方法框架，不直接提供本模型矩阵数值。

## 17 导数定义与单位

每个导数单位由输出状态导数单位除以输入变量单位得到。例如 `d(vdot)/d(betaDiff)` 为 `(m/s^2)/rad`，`d(pdot)/d(betaDiffDot)` 为 `(rad/s^2)/(rad/s)`。代表工况主要横航向刚体导数为 `Yv={f(rep_d['Yv']['value'])}`、`Yp={f(rep_d['Yp']['value'])}`、`Yr={f(rep_d['Yr']['value'])}`、`Lp={f(rep_d['Lp']['value'])}`、`Nr={f(rep_d['Nr']['value'])}`，精确单位见 CSV。

## 18 对称/差动坐标

状态变换和输入变换均显式保存正逆矩阵。角指令接口的对称/差动输入名称由 ANGLE_COMMAND 合同产生；力矩接口继续产生 nacelleTorqueSym/Diff。变换不改变特征值，只改变参与解释和控制列语义。

## 19 模态分类

分类综合左右特征向量、双正交参与因子、纵向/横航向状态组、短舱对称/差动参与度和虚部。代表点滚转样根为 `{f(roll['realPartPerSecond'])} 1/s`，荷兰滚样根为 `{f(dutch['realPartPerSecond'])}+{f(dutch['imagPartRadPerSecond'])}i 1/s`，阻尼比 `{f(dutch['dampingRatio'])}`；短周期样根为 `{f(short['realPartPerSecond'])}+{f(short['imagPartRadPerSecond'])}i 1/s`，阻尼比 `{f(short['dampingRatio'])}`；真实螺旋样根为 `{f(spiral['realPartPerSecond'])} 1/s`。另有纵向非振荡根 `{f(unstable['realPartPerSecond'])} 1/s`，说明当前开环低阶模型在代表点存在不稳定方向。

## 20 航向运动学积分根

`lambda={f(heading['realPartPerSecond'])}` 且 psi 参与主导的根单列为 heading kinematic integrator。其阻尼比、时间常数和稳定性资格为不适用，不纳入螺旋稳定性统计，也不与真实螺旋样根竞争 mode ID。

## 21 模态跟踪方法

跟踪先保留航向积分根，再对其余 12 根用特征值距离、MAC 和参与因子 L1 距离构造代价并做 Hungarian 分配。固定短舱角路径分别为 B15_SPEED_PATH、B45_SPEED_PATH 和 B75_SPEED_PATH；路径之间不配对。

## 22 模态跟踪路径与中断

B15 路径含 10/20/30 m/s，最低匹配置信度约 0.772；B45 路径含 25/35/45 m/s，最低置信度约 0.845；B75 仅有 80 m/s 单点，不能形成速度连续性结论。30°/60° 的连续可信同速路径在现有已审核配平数据库中不存在，因此明确标记为路径中断，不伪造跨缺口连续性。

## 23 时间步收敛

所有 14 个主工况比较 0.1、0.05 和 0.025 s。运动学锁止、转换横向周期脉冲、横向周期开环和副翼开环进一步采用 0.0125 s；冻结工况纠偏后在 0.025 s 已通过。最终相邻步长五项峰值的最大尺度化变化均小于 2%。对称性强制为零的滚转/偏航量使用 1 N m 数值比较尺度，避免以近零量作分母产生伪相对误差。

## 24 分析有效性守卫

守卫显式检查体轴速度、迎角、侧滑角、phi、theta、p/q/r、执行器限幅、短舱角界、局部机翼速度/角度和 normal-flow 分支状态。阈值来源为 ASSUMED_ANALYSIS_GUARD，不是型号限制。每个轨迹保存首次越界时间、原因、有效前缀索引、完整轨迹和两套指标。

## 25 线性-非线性一致性

betaSymCommand、betaDiffCommand、lateralCyclic、aileron 和 rudder 五类小扰动分别比较局部线性与非线性响应。该比较只支持代表点、小幅值、有限时段的一阶一致性，不支持大扰动或外部准确性。

## 26 Command freeze

命令冻结保持冻结值，执行器仍计算 beta、betaDot、betaDDot 和内力矩。本研究把左侧冻结值设为初始角加 1°，右侧继续接受 5° 阶跃，使继续追踪行为可观察。该工况在 {f(freeze['firstEnvelopeViolationTime'])} s 因侧滑守卫越界，有效前缀滚转/偏航峰值为 {float(freeze['validMaxAbsRollMomentNm'])/1000:.3f}/{float(freeze['validMaxAbsYawMomentNm'])/1000:.3f} kN m。

## 27 Kinematic lock

运动学锁止把左侧 betaDot 和 betaDDot 置零，仅表示理想几何约束。未解析约束反力矩，故不得称机械卡死。有效前缀差动角峰值 {f(lock['validMaxBetaDiffRad'])} rad，滚转/偏航峰值 {float(lock['validMaxAbsRollMomentNm'])/1000:.3f}/{float(lock['validMaxAbsYawMomentNm'])/1000:.3f} kN m；{f(lock['firstEnvelopeViolationTime'])} s 后的轨迹只作数值展示。

## 28 Mechanical jam 状态

Mechanical jam 未实现。没有外部铰链广义载荷和约束力矩平衡，就不能计算保持锁定所需的反力矩，也不能给出型号级卡死载荷。数据库明确记录 constraintTorqueAvailable=false 和 mechanicalJamImplemented=false。

## 29 代表时域结果

差动 1° 阶跃的有效前缀滚转/偏航峰值为 {float(diff['validMaxAbsRollMomentNm'])/1000:.3f}/{float(diff['validMaxAbsYawMomentNm'])/1000:.3f} kN m。左侧 0.30 s 命令延迟的差动角峰值 {f(delay['validMaxBetaDiffRad'])} rad，滚转/偏航峰值 {float(delay['validMaxAbsRollMomentNm'])/1000:.3f}/{float(delay['validMaxAbsYawMomentNm'])/1000:.3f} kN m。锁止是有效前缀滚转峰值最大的故障工况；其全轨迹更大偏航峰值不能作为可信气动故障载荷。

## 30 参数敏感性

力和力矩敏感性分别报告 `norm(dF/dBetaDiff)` 的 N/rad 与 `norm(dM/dBetaDiff)` 的 N m/rad，不再拼接求范数。对称 omegaN、zeta 和整舱惯量使用有效前缀姿态峰值；左右不对称执行器参数使用 maxBetaDiff；wakeArea 使用力矩导数范数。速率和转矩限制在所选守卫内未激活时保持 CANNOT_RELIABLY_DETERMINE。总体谱横坐标仅作为诊断列，不作为主要分类量。

## 31 与 NUAA 方法对照

本项目与 NUAA 文章在部件划分、旋翼/机翼局部来流、作用点力矩、6DOF 合成和配平后线性化方面方法相似。不同点包括独立左右短舱状态、规定执行器、实际重心重构、连续 near-normal 混合、可信度门禁、三步长 Jacobian、分析守卫和有效前缀。故一致性分类为 SIMILAR，而非 EXACT。

## 32 与 Berger 命名结构对照

Berger13 在本文中仅表示 9 个刚体状态加 4 个左右短舱状态，以及两套 10 输入接口。由于仓库不含 Berger 原文，不能核实其全阶状态、铰链载荷或传动状态定义，也不能宣称复现。任何 Berger 数值/页码对照均标为 UNVERIFIED 和“需要人工核对”。

## 33 讨论

在当前低阶模型和代表工况内，差动短舱角是显著横航向通道；单侧延迟、冻结和锁止可产生明显滚转/偏航载荷。执行器根固定于占位 omegaN/zeta，不能解释为气动反馈决定的耦合模态。模态跟踪在连续路径内可信，但 B75 单点不足以支持完整二维迁移结论。

## 34 局限

模型缺少可靠外部铰链广义力矩、机械卡死约束反力矩、短舱局部惯量张量、全阶动态入流、桨叶弹性、传动扭转、旋翼间干扰和型号级宽迎角/侧滑数据。ASSUMED、RESEARCH_PLACEHOLDER 与 UNKNOWN 参数不能被描述为实测值。分析守卫不是飞行包线。

## 35 结论

在当前低阶模型、所选工况和参数假设范围内，计算结果表明：修正后的 actual-CG 载荷合成和固定/移动惯量重构满足对称退化、质量矩和正定性检查；航向积分根与真实螺旋样根得到分离；14 个主时域工况取得 2% 收敛证据；锁止与冻结的有效前缀和超界全轨迹得到区分。研究只完成内部一致性检验，不构成外部验证。

## 36 参考文献与证据附录

1. Sheng, H.; Zhang, C.; Xiang, Y. *Mathematical Modeling and Stability Analysis of Tiltrotor Aircraft*. Drones 2022, 6, 92. 仓库文件 `references/NUAA_main_paper.pdf`，重点核对 PDF 3、5、6、8、9、12 页及公式 (13)-(20)、(35)-(40)。
2. Dugan, D. C.; Erhart, R. G.; Schroers, L. G. *The XV-15 Tilt Rotor Research Aircraft*. NASA TM-81244, 1980. 仓库文件 `references/NASA_TM_81244.pdf`，仅作研究背景。
3. Tilt Rotor Project Office. *NASA/Army XV-15 Tilt Rotor Research Aircraft Familiarization Document*. NASA TM X-62407, 1975. 仓库文件 `references/NASA_TM_X_62407.pdf`，仅作构型背景。

参数来源分为 REFERENCE、DIGITIZED、DERIVED、ASSUMED_MODEL_PARAMETER、RESEARCH_PLACEHOLDER 和 UNKNOWN。完整公式-代码-测试映射、CSV/MAT、图原始数据、MATLAB 回归和 GitHub SHA 见同目录证据文件。PR52 归档 SHA：`{FINAL_SHA_TOKEN}`。
"""

    report_name = f"{TITLE}.md"
    write(RESULT / report_name, report)
    write(EXTERNAL / report_name, report.replace(FINAL_SHA_TOKEN, args.pr52_sha))

    docs: dict[str, str] = {
        "PR51_PHYSICS_CORRECTION_REPORT.md": f"""
# PR51 物理纠偏报告

- 原 HEAD：`247e3a4b46d39b375152fd5fa8bea9e7a4ba9e74`
- 修正 HEAD：`587a0d3755bdcdc808324827ac131ebc939ad042`
- 路线：`PRESCRIBED_NACELLE_MOTION_TO_RIGID_BODY_ONE_WAY`
- 实际 CG：所有旋翼、机翼、机身、平尾、垂尾力矩统一关于 actual total CG。
- 质量属性：6000=5100+450+450 kg；42°/48° 点质量矩残差 2.84e-14 kg m，惯量重构残差 0。
- 故障：command freeze 与 kinematic lock 分离；mechanical jam 未实现。
- 测试：PR3 聚焦 17/17；完整 run_all_checks 通过；checkcode 0。
""",
        "PR52_ANALYSIS_CORRECTION_REPORT.md": f"""
# PR52 分析纠偏报告

PR52 已 rebase 到 PR51 `587a0d3755bdcdc808324827ac131ebc939ad042`。修正零根分类、导数单位、命令标签、时间步收敛、分析守卫、有效前缀、量纲分离灵敏度和连续路径模态跟踪。新结果为 {credible} 个可信点、{failed} 个失败点、14 个收敛时域工况、36 行灵敏度和 21 幅图。最终 PR52 SHA：`{args.pr52_sha}`。
""",
        "MOMENT_REFERENCE_AUDIT.md": """
# 力矩参考点审计

旧结构“平均整机载荷+局部 delta”混用了平均 CG 与 actual CG。修正结构直接调用左右旋翼、独立机翼、机身、平尾和垂尾并统一传入 actual CG；刚体方程只对六类部件求和一次。对称极限总力、总矩、CG、惯量及前九状态导数保持基线一致。
""",
        "MASS_INERTIA_RECONSTRUCTION.md": """
# 质量与惯量重构

质量分解为 6000 kg=5100 kg fixed+450 kg left+450 kg right。固定 CG 由平均构型质量矩反求；基线总惯量先剥离移动点质量，再把固定、左、右贡献平移到 actual CG。42°/48°：CG=[0.079440493,0,0.033059507] m，质量矩残差 2.84e-14 kg m，惯量残差 0，最小主惯量 1.7739e4 kg m^2。局部短舱惯量张量为 UNKNOWN。
""",
        "NACELLE_COUPLING_BOUNDARY.md": """
# 短舱耦合边界

未实现双向 Qexternal。现有整机外载对象不能可靠拆出作用于短舱铰链、且不与刚体外载重复的广义力矩。最终边界为规定短舱运动单向影响刚体。执行器内力矩反作用于机体；外部铰链力矩和机械卡死约束力矩不可用。
""",
        "FREEZE_LOCK_JAM_DEFINITION.md": f"""
# Freeze、Lock 与 Jam 定义

- command freeze：冻结 command，执行器继续；本研究冻结值为初始左角+1°。
- kinematic lock：beta 固定、betaDot=betaDDot=0，无约束反力矩。
- mechanical jam：未实现，不能给出真实卡死载荷。

冻结首次侧滑越界 {freeze['firstEnvelopeViolationTime']} s；锁止首次侧滑越界 {lock['firstEnvelopeViolationTime']} s。两者最终轨迹已不相同。
""",
        "MODAL_CLASSIFICATION_CORRECTION.md": f"""
# 模态分类纠偏

代表点 psi 主导航向零根 `{heading['realPartPerSecond']}` 单列 heading kinematic integrator，阻尼与稳定性资格不适用。真实螺旋样根为 `{spiral['realPartPerSecond']} 1/s`，不再与零根交换 ID。荷兰滚样根 `{dutch['realPartPerSecond']}+{dutch['imagPartRadPerSecond']}i`，短周期样根 `{short['realPartPerSecond']}+{short['imagPartRadPerSecond']}i`。
""",
        "TIME_STEP_CONVERGENCE.md": """
# 时间步收敛

14 个主时域工况均比较 dt=0.1、0.05、0.025 s。运动学锁止、转换横向周期脉冲、横向周期开环和副翼开环进一步采用 0.0125 s。冻结纠偏后采用 0.025 s。最终相邻步长峰值门限均小于 2%；完整逐项变化见 `13X10_TIME_STEP_CONVERGENCE.csv`。
""",
        "ANALYSIS_VALIDITY_ENVELOPE.md": f"""
# 分析有效性守卫

阈值来源 `ASSUMED_ANALYSIS_GUARD`，不是型号或安全包线。锁止在 {lock['firstEnvelopeViolationTime']} s 首次因 `SIDESLIP_GUARD` 越界：有效前缀滚转/偏航 {float(lock['validMaxAbsRollMomentNm'])/1000:.3f}/{float(lock['validMaxAbsYawMomentNm'])/1000:.3f} kN m；全轨迹偏航 {float(lock['fullMaxAbsYawMomentNm'])/1000:.3f} kN m 仅数值展示。冻结在 {freeze['firstEnvelopeViolationTime']} s 越界。
""",
        "DERIVATIVE_UNIT_AUDIT.md": f"""
# 导数单位审计

单位由显式状态导数与输入单位合同逐项生成。`d(pdot)/d(betaDiffDot)` 为 `(rad/s^2)/(rad/s)`；角指令输入为 betaSymCommand/betaDiffCommand。代表差动角导数：vdot {rep_d['dv_dbetaDiff']['value']}、pdot {rep_d['dp_dbetaDiff']['value']}、rdot {rep_d['dr_dbetaDiff']['value']}，单位分别见数据库。
""",
        "SENSITIVITY_METRIC_CORRECTION.md": """
# 灵敏度指标纠偏

禁止混合 N/rad 与 N m/rad。数据库分别保存 forceDerivativeNormNPerRad 和 momentDerivativeNormNmPerRad。对称带宽/阻尼与整舱惯量使用有效前缀姿态峰值；左右不对称参数使用 maxBetaDiff；wakeArea 使用力矩导数范数。速率和转矩限制未激活时为 CANNOT_RELIABLY_DETERMINE。
""",
        "MODE_TRACKING_PATHS.md": """
# 模态跟踪路径

- B15_SPEED_PATH：10、20、30 m/s，最低置信度 0.772。
- B45_SPEED_PATH：25、35、45 m/s，最低置信度 0.845。
- B75_SPEED_PATH：仅 80 m/s，路径不足。

heading integrator 先保留；路径之间不进行 Hungarian 分配。30°/60° 无连续可信同速路径，明确中断。
""",
        "PRE_CORRECTION_VS_POST_CORRECTION.md": f"""
# 纠偏前后对比

|项目|纠偏前|纠偏后|
|-|-|-|
|PR51 HEAD|247e3a4b46d39b375152fd5fa8bea9e7a4ba9e74|587a0d3755bdcdc808324827ac131ebc939ad042|
|PR52 HEAD|b3abfb78db1f183560e757917482024edbcb9f1f|{args.pr52_sha}|
|力矩参考点|平均 CG 与 actual CG 混合|全部 actual CG|
|航向零根|spiral-like|heading kinematic integrator|
|模态跟踪|跨角度全局相邻|固定角连续路径，跨缺口禁止|
|主时步|0.1 s|0.025 s 或 0.0125 s|
|锁止/卡滞|stuck，整段峰值|kinematic lock，有效前缀|
|锁止偏航峰值|约 7.033 kN m，未门禁|有效前缀 {float(lock['validMaxAbsYawMomentNm'])/1000:.3f} kN m；全轨迹 {float(lock['fullMaxAbsYawMomentNm'])/1000:.3f} kN m 仅展示|
|导数单位|按列号推断|显式合同|
|代表 betaDiff 导数|0.3132/16.7524/-0.5566|{f(rep_d['dv_dbetaDiff']['value'])}/{f(rep_d['dp_dbetaDiff']['value'])}/{f(rep_d['dr_dbetaDiff']['value'])}，数值保留、单位纠正|

保留：7 个可信/2 个失败点、代表刚体导数与主要模态数值。撤销：完整双向耦合、真实机械卡死载荷、航向零根为螺旋、超界全轨迹为可靠故障载荷、跨缺口二维模态连续性。仅作数值展示：锁止/冻结越界后的轨迹与峰值。
""",
        "FINAL_GITHUB_EVIDENCE_INDEX.md": f"""
# GitHub 证据索引

- PR50 未修改：`b96f357b142c4e1cd8c19b9eb39fd49fb74fe94b`
- PR51：`587a0d3755bdcdc808324827ac131ebc939ad042`
- PR52：`{args.pr52_sha}`
- PR51 base：PR50 分支；PR52 base：修正后的 PR51 分支。
- MATLAB：R2021a；聚焦检查、checkcode、完整 run_all_checks 和 finite-real 证据见 PR 描述与最终回复。
- 未合并任何 PR。
""",
    }
    for name, text in docs.items():
        write(EXTERNAL / name, text)

    repository_docs = {
        "README.md": f"# Berger13 corrected result snapshot\n\nMain report: `{TITLE}.md`. Databases, 21 figures, raw CSV/MAT, convergence and guard evidence are generated from the corrected PR51 one-way prescribed-actuator model.\n",
        "13X10_FINAL_MODEL_DEFINITION.md": docs["NACELLE_COUPLING_BOUNDARY.md"] + docs["MOMENT_REFERENCE_AUDIT.md"],
        "13X10_FINAL_STATE_INPUT_CONVENTIONS.md": "# State and input conventions\n\nStates: u,v,w,p,q,r,phi,theta,psi,betaML,betaMR,betaMLdot,betaMRdot. Command inputs 9/10: betaMLCommand/betaMRCommand; transformed names: betaSymCommand/betaDiffCommand. Torque-interface names remain nacelleTorqueLeft/Right.\n",
        "13X10_KNOWN_LIMITATIONS.md": "# Known limitations\n\nNo Qexternal feedback, mechanical jam, local nacelle inertia tensor, full-order inflow/blade/drivetrain states, external validation, XV-15 validation, Berger 51-state reproduction, handling-quality qualification, or safety envelope.\n",
        "13X10_PARAMETER_PROVENANCE.md": "# Parameter provenance\n\nCategories: REFERENCE, DIGITIZED, DERIVED, ASSUMED_MODEL_PARAMETER, RESEARCH_PLACEHOLDER, UNKNOWN. Actuator omegaN/zeta and analysis guards are research assumptions; local nacelle inertia tensor and external hinge load are UNKNOWN/unimplemented.\n",
        "13X10_TRIM_METHOD_AND_RESULTS.md": f"# Trim method and results\n\n{credible} credible and {failed} failed candidates. Failed points remain archived and do not enter linear/modal results.\n",
        "13X10_LINEAR_NONLINEAR_CONSISTENCY.md": "# Linear/nonlinear consistency\n\nFive small-disturbance cases compare local linear and nonlinear responses. This is internal local consistency only.\n",
        "13X10_EXTERNAL_COMPARISON_BOUNDARY.md": "# External comparison boundary\n\nNUAA comparison is methodological. NASA reports provide background only. No external numerical validation is claimed; Berger source is absent and requires manual verification.\n",
        "13X10_FORMULA_CODE_TEST_MAPPING.md": "# Formula-code-test mapping\n\n|Formula/topic|Code|Test|\n|-|-|-|\n|actual-CG component sum|total_forces_moments_13x10.m|check_berger13_pr3_actuator_wing.m|\n|mass/inertia reconstruction|mass_properties_berger13.m|check_berger13_pr3_actuator_wing.m|\n|heading integrator|analyze_berger13_modes.m|check_berger13_pr4_research.m|\n|unit contract|berger13_derivative_contract.m|check_berger13_pr4_research.m|\n|validity guard|berger13_analysis_guard.m|check_berger13_pr4_research.m|\n|continuous paths|track_berger13_modes.m|check_berger13_pr4_research.m|\n",
        "PR2_EVIDENCE.md": "# PR2 evidence\n\nPR2 HEAD b96f357b142c4e1cd8c19b9eb39fd49fb74fe94b is unchanged. Seven credible and two failed points are retained.\n",
        "PR3_EVIDENCE.md": docs["PR51_PHYSICS_CORRECTION_REPORT.md"],
        "PR4_EVIDENCE.md": f"# PR4 evidence\n\nPR52 was rebased onto corrected PR51. Corrected modal classification, units, time-step convergence, validity guards, sensitivity metrics, and continuous-path tracking are archived here. The immutable final SHA is recorded in the external FINAL_GITHUB_EVIDENCE_INDEX.md to avoid a commit self-reference.\n",
    }
    for name, text in repository_docs.items():
        write(RESULT / name, text)

    report_pdf = RESULT / f"{TITLE}.pdf"
    if report_pdf.exists():
        shutil.copy2(report_pdf, EXTERNAL / report_pdf.name)

    snapshot = EXTERNAL / "results_snapshot"
    if snapshot.exists():
        shutil.rmtree(snapshot)
    shutil.copytree(RESULT, snapshot)

    if args.package:
        manifest_path = EXTERNAL / "FINAL_SHA256_MANIFEST.txt"
        zip_path = EXTERNAL / ZIP_NAME
        selected = sorted(
            [path for path in EXTERNAL.iterdir()
             if path.is_file() and path.suffix.lower() in {".md", ".pdf"}]
            + [path for path in snapshot.rglob("*") if path.is_file()],
            key=lambda path: path.relative_to(EXTERNAL).as_posix(),
        )
        manifest_lines = []
        for path in selected:
            digest = hashlib.sha256(path.read_bytes()).hexdigest()
            manifest_lines.append(
                f"{digest}  {path.relative_to(EXTERNAL).as_posix()}"
            )
        write(manifest_path, "\n".join(manifest_lines))
        selected.append(manifest_path)
        with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED,
                             compresslevel=9) as archive:
            for path in selected:
                archive.write(path, path.relative_to(EXTERNAL).as_posix())


if __name__ == "__main__":
    main()
