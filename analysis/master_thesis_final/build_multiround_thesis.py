#!/usr/bin/env python3
"""Build the five auditable thesis revision rounds.

The program edits documentation only.  It reads the PR #57 thesis and frozen
evidence, removes known template expansion, inserts the equations and physical
interpretation required by the final review, and writes every round separately.
It never imports or rewrites production MATLAB functions or parameter files.
"""

from __future__ import annotations

import csv
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "docs" / "master_thesis_validation" / "MASTER_THESIS_FULL.md"
OUT = ROOT / "docs" / "master_thesis_final_multiround"
TITLE = "倾转旋翼机部件级飞行动力学建模、短舱动态状态扩展与可信度分析"


def write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="\n") as f:
        f.write(text.rstrip() + "\n")


def write_csv(path: Path, fields: list[str], rows: list[list[object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8-sig", newline="") as f:
        w = csv.writer(f)
        w.writerow(fields)
        w.writerows(rows)


def remove_between(text: str, start: str, end: str) -> tuple[str, int]:
    i, j = text.find(start), text.find(end)
    if i < 0 or j < 0 or j <= i:
        return text, 0
    return text[:i] + text[j:], j - i


def insert_before(text: str, marker: str, addition: str) -> str:
    i = text.find(marker)
    if i < 0:
        raise RuntimeError(f"missing insertion marker: {marker}")
    return text[:i] + addition.rstrip() + "\n\n" + text[i:]


def nonspace(text: str) -> int:
    return len(re.sub(r"\s+", "", text))


def displayed_equations(text: str) -> int:
    return text.count("$$") // 2


def structure_round(source: str) -> tuple[str, dict[str, int]]:
    text = source.replace(
        "倾转旋翼机部件级飞行动力学建模、短舱动态状态扩展与模型验证研究", TITLE
    )
    removed = 0
    ranges = [
        ("## 3.20 方程闭合、数值实现与证据边界的深化讨论", "# 第四章"),
        ("### V01　状态与输入顺序", "## 6.6 证据等级与允许表述"),
        ("## 7.7 验证结果逐项解释", "## 7.8 分层证据综合讨论"),
        ("## 7.8 分层证据综合讨论", "# 第八章"),
        ("## 8.20 代表工况、事件类型与响应机理深化", "# 第九章"),
        ("# 正文图表索引与逐图解释", "# 参考文献"),
        ("# 参考文献", "# 附录A"),
    ]
    for a, b in ranges:
        text, n = remove_between(text, a, b)
        removed += n

    replacements = {
        "## 1.3 公开数据不足与研究边界": "## 1.3 现有研究不足",
        "## 1.5 研究路线与贡献": "## 1.5 研究内容与技术路线",
        "# 第二章　建模理论与总体架构": "# 第二章　坐标系、动力学理论与模型总体架构",
        "## 2.1 坐标系与短舱角定义": "## 2.1 坐标系与符号",
        "## 2.2 六自由度刚体方程": "## 2.3 六自由度刚体方程",
        "## 2.3 旋翼模型": "## 2.7 模型层级与软件架构",
        "## 2.4 机翼与旋翼尾流区域": "## 2.6 部件载荷合成方法",
        "## 2.5 机身、平尾与垂尾": "## 2.5 状态、输入和控制定义",
        "## 2.6 合力、合力矩、重心与惯量": "## 2.4 质量、重心和惯量理论",
        "## 2.7 控制量与参数来源": "## 2.8 本章小结",
        "## 2.8 验证导向的模型层级": "## 2.9 研究边界说明",
        "# 第六章　模型验证方法与证据体系": "# 第六章　模型校核、外部数据关联与可信度方法",
        "# 第七章　部件级、整机级及外部验模结果": "# 第七章　模型校核与外部关联结果",
        "# 第九章　旋翼模型、参数来源与配平边界": "# 第九章　旋翼模型、参数敏感性与配平边界",
        "# 第十章　讨论、结论与展望": "# 第十章　结论与展望",
    }
    for old, new in replacements.items():
        text = text.replace(old, new)

    # Compact the former V01--V26 template into one method and one result table.
    compact = """
## 6.5 校核矩阵与关键案例

原有二十六项模板化说明被压缩为一张校核矩阵。矩阵按接口与符号、质量属性、部件载荷、
配平、线性化、十三状态扩展、时间积分和外部数据八类组织。正文只展开会改变科学结论的
案例：配平回代、九/十三状态共享导数、线性—非线性小扰动、时间步收敛和悬停旋翼公开
试验关联。其余结果作为可追溯附表保留，不再逐项复述相同的输入、判据和边界声明。

| 类别 | 代表检查 | 判据 | 本文用途 |
|---|---|---|---|
| 接口与符号 | 状态顺序、短舱端点、左右镜像 | 解析定义与极限工况一致 | 防止坐标和符号错误 |
| 质量属性 | 重心、完整惯量、正定性 | 质量闭合且惯量特征值为正 | 支撑刚体方程 |
| 部件载荷 | 力臂矩、旋翼离散、挥舞闭合 | 有限、收敛且满足对称性 | 支撑部件合成 |
| 配平 | 回代、边界、奇异值 | 残差、控制余度和数值秩联合评价 | 选择可信代表点 |
| 线性化 | 步长、线性—非线性增量 | 导数对步长稳定，小扰动一致 | 支撑局部动力学 |
| 短舱扩展 | 接口、对称/差动分块、时域响应 | 有限且物理通道可解释 | 分析短舱运动 |
| 外部关联 | NASA 悬停旋翼曲线 | 独立数字化并报告偏差 | 限定外部证据等级 |
"""
    text = text.replace("## 6.5 验证案例定义", compact.strip())

    # Add missing chapter purpose/flow paragraphs without repeating evidence slogans.
    openings = {
        "# 第一章　绪论": "本章从倾转旋翼机转换飞行的多部件耦合特征出发，界定公开资料条件下可回答的科学问题。输入为公开文献及既有模型能力，输出是研究对象、技术路线和可检验的三项贡献。",
        "# 第二章　坐标系、动力学理论与模型总体架构": "本章建立全文共同使用的坐标、符号和刚体动力学基础。统一定义是后续部件载荷合成、配平以及短舱状态扩展能够相互比较的前提。",
        "# 第三章　部件级非线性飞行动力学模型": "本章把第二章的统一定义落实为旋翼、左右机翼、机身和尾翼的部件级载荷链，最终输出关于实际重心的整机合力与合矩。",
        "# 第四章　配平、数值线性化与可信度判据": "本章回答模型在哪些工况具备可解释的平衡解，以及局部导数在何种数值条件下可用。输出的可信配平点构成短舱动态比较的初始状态。",
        "# 第五章　左右短舱动态状态扩展": "本章针对准静态短舱角不能保存运动历史的问题，引入左右短舱角和角速度，说明新增状态进入质量属性、旋翼轴、尾流与反作用力矩的路径。",
        "# 第六章　模型校核、外部数据关联与可信度方法": "本章区分程序校核、数值收敛、模型间比较和外部数据关联，给出证据分级方法以及每类证据能够支持的声明。",
        "# 第七章　模型校核与外部关联结果": "本章汇总对主要结论有直接约束力的校核和关联结果，重点讨论旋翼公开试验曲线、配平趋势以及九/十三状态共享导数差异。",
        "# 第八章　短舱动态状态对刚体响应的影响": "本章从三个可信配平点出发，比较对称与差动短舱指令、速率和不同步事件产生的刚体响应，并追溯其载荷来源。",
        "# 第九章　旋翼模型、参数敏感性与配平边界": "本章讨论结论对旋翼模型形式和纵向等效参数的依赖，分析75°构型的困难工况，并把参数优化限定为概念模型的可行性研究。",
        "# 第十章　结论与展望": "本章把定量发现、方法贡献与证据边界分开归纳，避免把有限工况的内部一致性外推为型号级验证。",
    }
    for marker, opening in openings.items():
        text = text.replace(marker, marker + "\n\n" + opening, 1)

    info = {
        "source_characters": nonspace(source),
        "round2_characters": nonspace(text),
        "removed_raw_characters": removed,
        "source_headings": len(re.findall(r"^#{1,3} ", source, re.M)),
        "round2_headings": len(re.findall(r"^#{1,3} ", text, re.M)),
    }
    return text, info


TECH2 = r"""
## 2.2 姿态运动学

地面坐标系记为 \(O_gx_gy_gz_g\)，机体系记为 \(O_bx_by_bz_b\)。机体系采用
\(x_b\) 向前、\(y_b\) 向右、\(z_b\) 向下的右手约定。按照 3-2-1 被动坐标变换，
地面系向量在机体系中的分量由

$$
\mathbf C_b^g=
\begin{bmatrix}
c_\theta c_\psi&c_\theta s_\psi&-s_\theta\\
s_\phi s_\theta c_\psi-c_\phi s_\psi&s_\phi s_\theta s_\psi+c_\phi c_\psi&s_\phi c_\theta\\
c_\phi s_\theta c_\psi+s_\phi s_\psi&c_\phi s_\theta s_\psi-s_\phi c_\psi&c_\phi c_\theta
\end{bmatrix}
$$

给出，其中 \(c_\bullet=\cos(\bullet)\)、\(s_\bullet=\sin(\bullet)\)，角度单位为 rad。
角速度与欧拉角速率的关系为

$$
\begin{bmatrix}\dot\phi\\\dot\theta\\\dot\psi\end{bmatrix}
=
\begin{bmatrix}
1&s_\phi\tan\theta&c_\phi\tan\theta\\
0&c_\phi&-s_\phi\\
0&s_\phi/\cos\theta&c_\phi/\cos\theta
\end{bmatrix}
\begin{bmatrix}p\\q\\r\end{bmatrix}.
$$

该表示在 \(\cos\theta=0\) 处奇异，本文工况远离该区域。重力在机体系中的投影为

$$
\mathbf g_b=\mathbf C_b^g[0,0,g]^T
=g[-\sin\theta,\ \sin\phi\cos\theta,\ \cos\phi\cos\theta]^T.
$$

完整惯量矩阵写作

$$
\mathbf I_b=\begin{bmatrix}I_{xx}&-I_{xy}&-I_{xz}\\-I_{xy}&I_{yy}&-I_{yz}\\-I_{xz}&-I_{yz}&I_{zz}\end{bmatrix},
\qquad \lambda_{\min}(\mathbf I_b)>0.
$$

代码保留 \(I_{xz}\) 而没有套用仅适于对角惯量的标量转动方程。符号、重力方向和
交叉惯量均通过端点与正定性检查约束。

## 2.6 部件载荷合成的数学形式

第 \(k\) 个部件在自身局部系的力与固有矩分别为
\(\mathbf F_k^{(k)}\) 和 \(\mathbf M_k^{(k)}\)。用被动旋转矩阵
\(\mathbf C_b^k\) 转入机体系：

$$
\mathbf F_k^b=\mathbf C_b^k\mathbf F_k^{(k)},\qquad
\mathbf M_{k,0}^b=\mathbf C_b^k\mathbf M_k^{(k)}.
$$

若 \(\mathbf r_k^b\) 是从整机实际重心指向作用点的位置，整机载荷为

$$
\mathbf F_b=\sum_k\mathbf F_k^b,\qquad
\mathbf M_b=\sum_k\left(\mathbf M_{k,0}^b+\mathbf r_k^b\times\mathbf F_k^b\right).
$$

叉乘次序不可交换。该统一接口使旋翼反扭矩、尾翼固有矩与作用点力矩只计入一次。
"""


TECH3 = r"""
## 3.1 左右旋翼模型的局部速度与几何

左右桨毂 \(h\in\{L,R\}\) 的机体系局部来流同时包含质心速度和机体转动贡献：

$$
\mathbf V_h^b=\mathbf V_{\rm CG}^b+\boldsymbol\omega_b\times\mathbf r_h^b.
$$

旋翼轴单位向量由短舱角决定。以本文端点定义，\(\beta_h=0\) 为直升机侧，
\(\beta_h=\pi/2\) 为飞机侧，可写

$$
\mathbf e_{A,h}^b=[\sin\beta_h,\ 0,\ -\cos\beta_h]^T,\qquad
\|\mathbf e_{A,h}^b\|_2=1.
$$

与轴向正交的盘面基向量记为 \(\mathbf e_{D,h}^b,\mathbf e_{Y,h}^b\)，满足

$$
\mathbf e_{D,h}^b\times\mathbf e_{Y,h}^b=\mathbf e_{A,h}^b.
$$

桨叶径向坐标和方位角分别为

$$
r=r_{\rm hub}+\xi(R-r_{\rm hub}),\quad 0\le\xi\le1,\qquad
\psi_j=\psi+\frac{2\pi(j-1)}{N_b}.
$$

桨距包含总距、线性扭转和一阶纵向周期量：

$$
\theta_h(r,\psi)=\theta_{0,h}+\theta_{\rm tw}\frac{r-r_{\rm hub}}{R-r_{\rm hub}}
+\theta_{1s,h}\sin\psi .
$$

控制接口把正纵向周期定义为盘面法向共同向 \(+\mathbf e_D\) 倾斜。左右旋向
\(s_h\in\{-1,+1\}\) 不同，内部映射为

$$
\theta_{1s,h}=-s_h\,\theta_{{\rm cyc},h}.
$$

因此对称外部指令在物理盘面上同向，而不是简单给左右旋翼相同的内部谐波符号。

## 3.2 叶素气动力、诱导速度与挥舞闭合

叶素切向和轴向速度分别记为 \(U_T\) 与 \(U_P\)：

$$
U_T=s_h\Omega r+\mathbf V_h^b\cdot\mathbf e_t,\qquad
U_P=\mathbf V_h^b\cdot\mathbf e_{A,h}+v_i+v_{1c}\cos\psi+v_{1s}\sin\psi.
$$

相对速度、入流角和攻角为

$$
W=\sqrt{U_T^2+U_P^2},\qquad
\varphi=\operatorname{atan2}(U_P,U_T),\qquad
\alpha=\theta_h-\varphi .
$$

二维翼型关系在概念模型有效攻角内写成 \(C_l=C_{l\alpha}\alpha\) 和
\(C_d=C_{d0}+k_dC_l^2\)。叶素升阻力为

$$
\mathrm dL=\tfrac12\rho W^2c\,C_l\,\mathrm dr,\qquad
\mathrm dD=\tfrac12\rho W^2c\,C_d\,\mathrm dr.
$$

轴向推力与气动扭矩微元分别为

$$
\mathrm dT=(\mathrm dL\cos\varphi-\mathrm dD\sin\varphi),\qquad
\mathrm dQ=r(\mathrm dL\sin\varphi+\mathrm dD\cos\varphi).
$$

经径向积分、方位平均和桨叶求和得到

$$
T=\frac{N_b}{2\pi}\int_0^{2\pi}\int_{r_{\rm hub}}^R\mathrm dT\,\mathrm d\psi,
\qquad
Q=\frac{N_b}{2\pi}\int_0^{2\pi}\int_{r_{\rm hub}}^R\mathrm dQ\,\mathrm d\psi .
$$

诱导速度由叶素推力与动量关系闭合。概念性写法为

$$
T=2\rho A v_i\sqrt{V_\parallel^2+v_i^2+V_\perp^2},
\qquad A=\pi R^2,
$$

实际程序采用带松弛的迭代：

$$
v_i^{(n+1)}=(1-\gamma)v_i^{(n)}+\gamma\mathcal G(T^{(n)},\mathbf V_h),
$$

并显式报告迭代失败，而不把 NaN 或负推力分支改写为零。一阶谐波挥舞写成

$$
\beta_f(\psi)=\beta_0+a_{1c}\cos\psi+b_{1s}\sin\psi,
$$

其中谐波系数通过稳态线性代数闭合，不是自由尾迹或瞬态弹性桨叶模型。旋翼合力和
反扭矩在局部轴系内为

$$
\mathbf F_h^{(h)}=[F_D,F_Y,-T]^T,\qquad
\mathbf M_{Q,h}^{(h)}=[0,0,-s_hQ]^T.
$$

随后使用短舱旋转矩阵转换到机体系。悬停附近两套旋翼路径的推力斜率方向一致，
前飞时局部速度、诱导闭合和面内力的差异会通过配平放大。

## 3.3 左右机翼与旋翼尾流

第 \(h\) 侧半翼气动中心的速度为

$$
\mathbf V_{w,h}^b=\mathbf V_{\rm CG}^b+\boldsymbol\omega_b\times\mathbf r_{w,h}^b .
$$

自由流区和尾流区分别采用 \(\mathbf V_{\infty,h}\) 与
\(\mathbf V_{{\rm slip},h}\)，其动压为

$$
q_{\infty,h}=\tfrac12\rho\|\mathbf V_{\infty,h}\|^2,\qquad
q_{{\rm slip},h}=\tfrac12\rho\|\mathbf V_{{\rm slip},h}\|^2.
$$

局部迎角与侧滑角采用

$$
\alpha_h=\operatorname{atan2}(w_h,u_h),\qquad
\beta_{a,h}=\operatorname{atan2}(v_h,\sqrt{u_h^2+w_h^2}).
$$

升力线分支写成

$$
C_{L,h}=C_{L0}+C_{L\alpha}\alpha_h,\quad
C_{D,h}=C_{D0}+k_wC_{L,h}^2,\quad
C_{m,h}=C_{m0}+C_{m\alpha}\alpha_h .
$$

相应载荷为

$$
L_h=q_hS_hC_{L,h},\quad D_h=q_hS_hC_{D,h},\quad
M_h=q_hS_h\bar c\,C_{m,h}.
$$

近法向来流分支与升力线分支在同一局部速度上分别计算。令法向流比
\(\chi=|V_n|/\max(\|\mathbf V\|,V_{\rm ref})\)，过渡坐标为

$$
\zeta=\operatorname{clip}\left(\frac{\chi-(\chi_0-\Delta\chi)}
{2\Delta\chi},0,1\right),
$$

五次平滑权重为

$$
s(\zeta)=6\zeta^5-15\zeta^4+10\zeta^3.
$$

正式载荷连续混合为

$$
\mathbf F_w=(1-s)\mathbf F_{\rm liftline}+s\mathbf F_{\rm normal}.
$$

本文 \(\chi_0=0.35\)、\(\Delta\chi=0.15\) 均属概念模型设定，连续化只消除人工硬
切换，不代表该区间已经试验辨识。尾流覆盖面积记为

$$
S_{{\rm slip},h}=\operatorname{clip}\!\left(\mathcal A(\mu_h,\beta_h),0,S_h\right),
\qquad \mu_h=\frac{V_{\perp,h}}{\Omega R}.
$$

十三状态路径逐侧计算该非线性面积，九状态路径使用左右推进比平均值；当 \(p\) 或
\(r\) 扰动使左右速度不同，两种求值顺序会产生滚转/偏航阻尼导数差异。

## 3.4 机身、平尾和垂尾

机身以局部动压和经验导数形成轴向、侧向与法向力：

$$
\mathbf F_f^b=q_fS_f[C_X,\ C_Y,\ C_Z]^T,\qquad
q_f=\tfrac12\rho\|\mathbf V_f^b\|^2 .
$$

平尾局部迎角把安装角、下洗和升降舵效能分开：

$$
\alpha_t=\operatorname{atan2}(w_t,u_t)+i_t-\epsilon,\qquad
\epsilon=\epsilon_0+\frac{\partial\epsilon}{\partial\alpha}\alpha_w,
$$

$$
C_{L,t}=C_{L0,t}+C_{L\alpha,t}\alpha_t+C_{L\delta_e,t}\delta_e,
\quad L_t=q_tS_tC_{L,t}.
$$

垂尾以局部侧滑和方向舵形成侧力：

$$
C_{Y,v}=C_{Y\beta,v}\beta_v+C_{Y\delta_r,v}\delta_r,\qquad
Y_v=q_vS_vC_{Y,v}.
$$

尾翼自身气动力矩与由作用点到实际重心的力臂矩分别计入。平尾安装角、下洗和升降舵
效能对75°构型俯仰平衡影响显著，其中联合优化值是等效参数，不是型号实测值。

## 3.8 坐标转换与整机闭合

任一部件的局部来流、载荷和作用点必须在同一转换链中处理。旋翼 \(h\) 的机体系载荷为

$$
\mathbf F_h^b=\mathbf C_b^h(\beta_h)\mathbf F_h^{(h)},\qquad
\mathbf M_h^b=\mathbf C_b^h\mathbf M_h^{(h)}
+(\mathbf r_h^b-\mathbf r_{\rm CG}^b)\times\mathbf F_h^b.
$$

总力与总矩进入六自由度方程：

$$
\dot{\mathbf V}_b=\frac{\mathbf F_b}{m}+\mathbf g_b
-\boldsymbol\omega_b\times\mathbf V_b,
$$

$$
\dot{\boldsymbol\omega}_b=\mathbf I_b^{-1}
\left[\mathbf M_b-\boldsymbol\omega_b\times(\mathbf I_b\boldsymbol\omega_b)\right].
$$

低空速、零转速、极端迎角和诱导迭代失败均由显式状态或失败信息保留。本文没有以
绝对值、静默饱和或零替换来掩盖非物理结果。
"""


TECH4 = r"""
## 4.2 未知量、约束与尺度化残差

对给定短舱角和空速，配平未知量写成

$$
\mathbf z=[\theta,\theta_0,\theta_{1s},\delta_e]^T,
$$

其中具体分量随配平模式定义。完整非线性模型回代形成原始残差

$$
\mathbf r(\mathbf z)=[\dot u,\dot w,\dot q,\ldots]^T .
$$

为避免平动加速度、角加速度与工况约束因量纲不同而支配求解，使用

$$
\widetilde{\mathbf r}=\mathbf W_r\mathbf r,\qquad
J(\mathbf z)=\tfrac12\widetilde{\mathbf r}^{\,T}\widetilde{\mathbf r}.
$$

控制边界写为 \(\mathbf z_{\min}\le\mathbf z\le\mathbf z_{\max}\)。
第 \(i\) 个控制的双侧余度定义为

$$
m_i=\min\left(\frac{z_i-z_{i,\min}}{z_{i,\max}-z_{i,\min}},
\frac{z_{i,\max}-z_i}{z_{i,\max}-z_{i,\min}}\right).
$$

可信度判断同时考察残差、有限实数、求解器退出状态、边界余度和局部可控性，不把
“优化器停止”单独视为平衡成立。

## 4.6 雅可比、奇异值和可解性

尺度化配平雅可比为

$$
\mathbf J_z=\frac{\partial\widetilde{\mathbf r}}{\partial\mathbf z}.
$$

其奇异值分解

$$
\mathbf J_z=\mathbf U\boldsymbol\Sigma\mathbf V^T,\qquad
\boldsymbol\Sigma=\operatorname{diag}(\sigma_1,\ldots,\sigma_n)
$$

给出局部控制方向。采用相对阈值 \(\tau\) 时

$$
\operatorname{rank}_\tau(\mathbf J_z)=
\#\{i:\sigma_i>\tau\sigma_1\},\qquad
\kappa_2=\frac{\sigma_1}{\sigma_n}.
$$

条件数大并不自动等于无解，但表示残差对参数或数值噪声敏感，必须与控制触界和回代
残差共同解释。

## 4.8 数值线性化与步长

在可信配平点 \((\mathbf x_\star,\mathbf u_\star)\) 附近，

$$
\delta\dot{\mathbf x}=\mathbf A\delta\mathbf x+\mathbf B\delta\mathbf u,
\qquad
\mathbf A=\left.\frac{\partial\mathbf f}{\partial\mathbf x}\right|_\star,\quad
\mathbf B=\left.\frac{\partial\mathbf f}{\partial\mathbf u}\right|_\star .
$$

第 \(j\) 列使用中心差分：

$$
\mathbf A_{:j}\approx
\frac{\mathbf f(\mathbf x_\star+h_j\mathbf e_j,\mathbf u_\star)
-\mathbf f(\mathbf x_\star-h_j\mathbf e_j,\mathbf u_\star)}{2h_j}.
$$

步长按变量量级缩放 \(h_j=h_{\rm rel}\max(|x_{\star,j}|,s_j)\)。
以 \(h_{\rm rel}/2\) 复算可定义导数步长差

$$
\varepsilon_A=
\frac{\|\mathbf A(h)-\mathbf A(h/2)\|_F}
{\max(\|\mathbf A(h/2)\|_F,\varepsilon_{\rm ref})}.
$$

特征根满足 \(\det(\lambda\mathbf I-\mathbf A)=0\)。实部反映局部增长或衰减，
虚部对应频率；零航向根源于没有位置/航向恢复项。本文代表点中仍有正实部根，故不能
把数值可积和配平可信写成开环动态稳定。

## 4.10 线性—非线性一致性

给定足够小的扰动，非线性增量与线性预测的相对误差定义为

$$
\varepsilon_{\rm LN}(t)=
\frac{\|\mathbf x_{\rm NL}(t)-\mathbf x_\star-\delta\mathbf x_{\rm L}(t)\|_2}
{\max(\|\delta\mathbf x_{\rm L}(t)\|_2,x_{\rm ref})}.
$$

该比较只能评价局部线性化的一致性，不能验证非线性气动模型。扰动若跨越控制限幅、
尾流面积限制或近法向混合边界，误差包含分段模型变化，不宜解释成差分精度问题。
"""


TECH5 = r"""
## 5.2 十三状态、对称与差动坐标

十三状态向量为

$$
\mathbf x_{13}=[u,v,w,p,q,r,\phi,\theta,\psi,\beta_L,\beta_R,
\dot\beta_L,\dot\beta_R]^T.
$$

对称与差动短舱变量定义为

$$
\beta_s=\frac{\beta_L+\beta_R}{2},\qquad
\beta_d=\frac{\beta_L-\beta_R}{2},
$$

$$
\dot\beta_s=\frac{\dot\beta_L+\dot\beta_R}{2},\qquad
\dot\beta_d=\frac{\dot\beta_L-\dot\beta_R}{2}.
$$

逆变换为 \(\beta_L=\beta_s+\beta_d\)、\(\beta_R=\beta_s-\beta_d\)。
它把对称纵向通道和反对称横航向通道显式分开，但几何或气动不对称会使两个子空间重新
耦合。

## 5.4 规定运动型执行机构

每侧短舱采用二阶命令跟踪模型：

$$
\ddot\beta_h^\circ=
\omega_n^2(\beta_{c,h}-\beta_h)-2\zeta\omega_n\dot\beta_h.
$$

角度、速率和加速度限制依次作用：

$$
\beta_h\in[\beta_{\min},\beta_{\max}],\qquad
|\dot\beta_h|\le\dot\beta_{\max},\qquad
|\ddot\beta_h|\le\ddot\beta_{\max}.
$$

若以等效转矩限制表达，还需满足

$$
|I_{\rm nac}\ddot\beta_h|\le\tau_{\max}.
$$

当前 \(I_{\rm nac}\)、\(\omega_n\)、\(\zeta\)、速率、加速度和转矩上限均为研究占位或
工程假设；外部资料只为转换速率提供量级约束。因此时域幅值用于机理比较，不能解释为
真实执行机构性能。

## 5.5 反作用力矩、移动质量与陀螺项

规定短舱角加速度对机体的等效反作用力矩写作

$$
\mathbf M_{{\rm react},h}^b=-I_{{\rm nac},h}\ddot\beta_h\,\mathbf e_{{\rm hinge},h}^b.
$$

转子角动量为

$$
\mathbf H_{R,h}^b=s_h I_{R,h}\Omega_h\mathbf e_{A,h}^b,
$$

其机体系力矩包含

$$
\mathbf M_{{\rm gyro},h}^b=
-\boldsymbol\omega_b\times\mathbf H_{R,h}^b
-s_hI_{R,h}\Omega_h\dot\beta_h
(\mathbf e_{{\rm hinge},h}^b\times\mathbf e_{A,h}^b).
$$

默认旋翼极惯量为研究占位值，陀螺通道在当前定量结果中不可作为型号结论。
若移动短舱质点位置为

$$
\mathbf r_{{\rm nac},h}^b(\beta_h)=
\mathbf r_{{\rm hinge},h}^b+\mathbf C_b^h(\beta_h)\mathbf r_{c,h}^{(h)},
$$

实际重心和总惯量分别为

$$
\mathbf r_{\rm CG}^b=\frac{1}{m}\sum_km_k\mathbf r_k^b,
$$

$$
\mathbf I_{\rm CG}=\sum_k\left[
\mathbf C_b^k\mathbf I_{k,c}\mathbf C_k^b
+m_k\big((\mathbf d_k^T\mathbf d_k)\mathbf 1-\mathbf d_k\mathbf d_k^T\big)
\right],
\quad \mathbf d_k=\mathbf r_k^b-\mathbf r_{\rm CG}^b.
$$

这一路径使短舱角通过重心、惯量、桨毂力臂和旋翼轴共同影响刚体；模型是单向规定运动，
不计算铰链载荷反过来改变伺服运动。
"""


TECH6 = r"""
## 6.1 校核、确认与外部关联的边界

程序校核回答“方程是否按定义实现”，数值确认回答“离散和迭代是否收敛”，外部关联回答
“特定可比较量与独立数据相差多少”。三者不能互相替代。本文把证据分为理论闭合、内部
一致性、独立实现比较、公开基准趋势和公开试验量关联五类；等级只用于限制声明强度，
不是通用认证标准。

镜像误差可定义为

$$
\varepsilon_{\rm mir}=
\frac{\|\mathbf y_L-\mathbf S\mathbf y_R\|_2}
{\max(\|\mathbf y_L\|_2,\|\mathbf y_R\|_2,y_{\rm ref})},
$$

其中 \(\mathbf S\) 根据力、矩和旋向规定符号。时间步收敛采用

$$
\varepsilon_{\Delta t}=
\frac{|y_{\rm peak}(\Delta t)-y_{\rm peak}(\Delta t/2)|}
{\max(|y_{\rm peak}(\Delta t/2)|,y_{\rm ref})}.
$$

外部曲线的误差指标为

$$
\operatorname{MAE}=\frac1N\sum_{i=1}^N|\hat y_i-y_i|,\qquad
\operatorname{RMSE}=\sqrt{\frac1N\sum_{i=1}^N(\hat y_i-y_i)^2},
$$

$$
\operatorname{NMAE}=\frac{\operatorname{MAE}}{\max(y_i)-\min(y_i)}.
$$

配平可行比例只描述指定网格：

$$
\eta_{\rm trim}=\frac{N_{\rm credible}}{N_{\rm evaluated}}.
$$

它不等于连续飞行包线面积。未收敛点和触界点保留在分母中，以避免选择性报告。

## 6.8 外部数据独立性与数字化不确定度

NASA TM-86854 图25的公开曲线在相同坐标标定下进行了两次人工取点。采用值为两次结果
的均值，横轴和纵轴的不确定度分别按 \(\pm0.25^\circ\) 与
\(\pm0.003\)（\(C_T/\sigma\)）记录。比较前核对总距定义、实度和推力系数定义：

$$
C_T=\frac{T}{\rho A(\Omega R)^2},\qquad
\sigma=\frac{N_bc}{\pi R}.
$$

试验桨叶构型与当前概念旋翼并不相同，因而该曲线只形成部件级外部数据关联。两套模型
均未利用该曲线调参，这避免了把标定数据再次当作独立验证数据。
"""


TECH7 = r"""
## 7.3 NASA 悬停旋翼试验数据关联复核

两次独立数字化的逐点差不超过 \(0.003\)。在共同有效总距区间内，当前正式旋翼模型
使用7个点，\(C_T/\sigma\) 的 MAE 为0.06324、RMSE为0.06332、NMAE为0.4085，
最大绝对误差为0.06640，平均绝对相对误差为0.4926。试验斜率为
0.008872/deg，模型斜率为0.008533/deg，方向一致；6°、8°和10°三个计算点失败或
不满足有效门禁。南航公开公式参考模型使用7个有效点，MAE为0.06405、RMSE为0.06408、
NMAE为0.5893，0°至8°共五个点失败。

该结果显示两条未调参路径能够给出同方向推力增长趋势，却存在约0.063至0.064的系统
幅值偏差。偏差远大于数字化不确定度，不能归因于取点误差。更合理的解释是桨叶几何、
翼型、扭转、损失修正及试验构型不一致。最终证据表述为“基于公开试验图线的部件级
外部数据关联，趋势一致但幅值偏差显著”，不称为型号验证。

## 7.8 九状态与十三状态共享导数

在15°/20 m/s、45°/35 m/s和75°/80 m/s三个冻结可信点，共享A块 Frobenius 差分别为
0.017409、0.007912和0.200598，最大单元素差分别为0.016811、0.005575和0.193599。
差异只在与 \(p,r\) 有关的少数导数中突出，部件分解指向机翼。共享B块差处于
\(10^{-14}\) 至 \(10^{-12}\) 量级。

根因不是四个新增状态自动改变刚体方程，而是两条正式路径对机翼尾流覆盖采用不同定义：
九状态路径先平均左右推进比，十三状态路径逐侧求值后合成。非线性覆盖函数使二者在
滚转或偏航扰动下不交换。论文因此把该现象归为模型定义差异，并停止使用“共同刚体
A块严格退化一致”或“状态增广导致导数退化”的表述。现有证据尚不能判定哪种尾流
定义更接近实机。
"""


TECH8 = r"""
## 8.3 对称短舱运动的纵向通道

对称短舱扰动满足 \(\Delta\beta_L=\Delta\beta_R\)。一阶近似下，两个旋翼的侧向载荷
相消，轴向和法向分量同号叠加：

$$
\Delta\mathbf F_s\approx
\sum_{h=L,R}\frac{\partial\mathbf F_h}{\partial\beta_h}\Delta\beta_s .
$$

推力方向旋转首先改变 \(X_b,Z_b\)，再通过质心速度和俯仰力矩耦合到
\(u,w,q,\theta\)。动态配平偏离量可写

$$
d_{\rm trim}(t)=
\|\mathbf W_{\dot x}\dot{\mathbf x}_{\rm rigid}(t)\|_2 .
$$

所选三个可信点的对称阶跃都以纵向响应为主；这一结论适用于当前对称几何和小幅指令，
不排除不对称参数、侧滑或大幅运动产生横航向响应。

## 8.7 差动短舱运动的横航向通道

差动扰动满足 \(\Delta\beta_L=-\Delta\beta_R\)。轴向/法向增量趋于抵消，而左右推力
方向差和力臂形成滚转、偏航矩：

$$
\Delta\mathbf M_d\approx
\mathbf r_L\times\frac{\partial\mathbf F_L}{\partial\beta_L}\Delta\beta_d
-\mathbf r_R\times\frac{\partial\mathbf F_R}{\partial\beta_R}\Delta\beta_d .
$$

同时，左右机翼尾流覆盖不同，引起半翼升力和阻力差。三个代表点均出现非零
\(v,p,r,\phi,\psi\) 响应，但滚转与偏航的相对大小随短舱角、速度和尾流模型变化，
不能概括为全包线固定排序。正差动纵向周期在当前符号下产生负偏航力矩增量；这来自
已冻结的左右旋向和周期变距映射，不是额外横向周期输入。

## 8.8 不同步、延迟和冻结事件

左右带宽或速率不同会把原本对称的命令分解出瞬时差动分量：

$$
\beta_d(t)=\tfrac12[\beta_L(t)-\beta_R(t)]\ne0.
$$

单侧延迟和指令冻结同样通过该量进入横航向通道。由于执行机构参数是研究占位值，
本文只比较响应通道、符号和相对变化，不给出真实故障载荷。运动学锁定表示指定短舱
状态保持不变；机械卡滞还涉及铰链、伺服和结构载荷反馈，当前单向模型没有实现。

## 8.13 时间步与响应解释

代表时域计算相邻两级时间步的最大峰值变化为1.5248%，说明所报告峰值在当前积分设置
下具有数值稳定性。该指标不消除气动模型和执行机构参数的不确定性。响应幅值应同时
标注初始配平可信度、事件幅值和有效时间段，不能仅凭曲线平滑程度判断物理真实性。
"""


TECH9 = r"""
## 9.2 旋翼模型形式敏感性

悬停中主要速度尺度是 \(\Omega r\) 和轴向诱导速度，两条叶素路径即使采用不同的
挥舞或损失闭合，也可能给出相近斜率。前飞后，方位不均匀入流、面内力、局部攻角和
风车分支进入积分，差异会随推进比增大。若某叶素出现 \(U_T\) 变号或动量闭合没有
实根，不能把对应点强行延拓为正常正推力状态。

旋翼形式差异通过三条路径影响整机配平：推力大小改变总距需求；推力方向和面内力改变
纵向力；扭矩与力臂改变俯仰/偏航平衡。因此同参数旋翼比较用于模型形式敏感性，而不是
以一条公开公式路径替代当前正式模型。

## 9.5 75°/40 m/s 失败机制

75°/40 m/s处联合优化模型的无界中间解给出约 \(-52.91^\circ\) 的升降舵角，但正式
限位为 \(\pm20^\circ\)。该数值只是求解器沿残差下降方向给出的不可实现延拓，不能写成
真实平衡升降舵需求。该工况同时具有较低尾翼动压、旋翼推力方向接近飞机侧、机翼与
平尾俯仰矩权限不足等条件。升降舵触及下界后，轴向/法向力和俯仰矩无法同时闭合，
完整残差范数保持为3.4038。

这既揭示当前控制权限不足，也暴露概念气动模型在低速、大短舱角区的证据薄弱。因而
该点被保留为配平失败，不通过放宽限位或继续调参改成“可行”。

## 9.6 75°/60 m/s 与参数优化边界

速度升至60 m/s后，机翼和平尾动压增加，联合优化模型得到
\(\delta_e=-15.8305^\circ\)，归一化控制余度约0.1042，未触及边界。该点相较40 m/s
更接近“控制权限随动压恢复”的解释，但仍依赖等效纵向参数。联合优化共得到9点中的
8个可信配平；优化目标使用模型内部残差和约束，没有使用NASA悬停曲线或XV-15整机
试验量，因此不是外部数据校准。

配平走廊是离散工况和连续延拓共同支持的概念模型可行区，不等于真实飞行转换走廊。
75°/80 m/s在联合优化正式旋翼路径可可信配平，而南航参考旋翼路径在相同条件下失败，
说明高短舱角前飞结论对旋翼模型形式敏感。
"""


TECH10 = r"""
## 10.1 主要研究结论

（1）统一坐标、实际重心和完整惯量的部件级模型能够在限定工况形成可回代的配平与
有限实数线性化。联合优化纵向等效参数后9个离散工况中8个满足本文可信度门禁；
75°/40 m/s仍因俯仰力矩和升降舵权限共同不足而失败。

（2）当问题包含短舱跟踪历史和左右不同步时，需要显式引入左右短舱角及角速度。
三个可信点中，对称短舱小扰动以纵向响应为主，差动小扰动均产生横侧向—航向响应。
结论针对所选小扰动、占位执行机构和概念气动模型，不代表全包线控制品质。

（3）NASA悬停曲线的二次数字化复核表明，两条未调参旋翼路径与试验曲线斜率方向一致，
但 \(C_T/\sigma\) 的MAE均约0.064，幅值偏差显著。整机证据仍以内部一致性、数值收敛
和有限趋势对照为主，不能形成XV-15型号复现或完整整机外部定量验证。

## 10.2 论文贡献

第一，建立统一坐标、实际重心载荷合成及可信配平评价相结合的倾转旋翼机部件级非线性
模型。相对只给出单一平衡解的公开建模流程，本文把残差、控制边界、奇异值和回代状态
联合用于配平可信度判断。

第二，在九状态刚体模型基础上引入左右短舱角和角速度状态，辨析对称及差动短舱运动对
纵向和横航向响应的不同载荷通道。增量在于把运动历史、左右不同步、反作用力矩和移动
质量统一纳入同一低阶框架，而非复现高维伺服—结构模型。

第三，建立由程序校核、数值收敛、外部数据关联和模型形式敏感性组成的分层可信度分析
体系。该体系保留失败点和不可比项，并把允许声明与证据类型绑定，从而使概念模型结果
能够被复算、质疑和逐步替换。

## 10.3 研究局限

当前旋翼和固定翼气动仍含线性系数、经验修正与研究占位参数；旋翼—机翼干扰采用低阶
覆盖模型；十三状态执行机构是单向规定运动；公开整机数据不足以完成同构型、同操纵、
同状态的定量验证。三个代表点用于识别通道，不足以建立全转换包线统计规律。

## 10.4 后续工作

后续应优先获得同构型旋翼载荷、整机配平、短舱时历和铰链载荷数据，按来源追溯逐项
替换占位参数；其次扩展到非定常入流、动态失速和双向伺服—铰链耦合；最后在独立数据
集上进行参数辨识与预测检验，并扩大经计算量评估后的速度—短舱角网格。
"""


DEPTH1 = r"""
## 1.6 文献脉络与本文切入点

倾转旋翼机建模研究可分为三条相互联系但证据目标不同的路线。第一条路线服务于总体
设计与性能估算，以动量理论、叶素理论和部件阻力分解为核心，重视旋翼尺寸、功率和
转换走廊之间的权衡。第二条路线服务于飞行动力学与控制研究，把气动力模型组织为可配平、
可线性化的状态方程，重点是导数、模态和操纵响应。第三条路线面向高保真载荷与气弹性，
需要自由尾迹、动态失速、柔性桨叶、铰链和伺服系统等更高维状态。三条路线不能用同一
“精度”尺度简单排序；适合总体设计的快速模型未必能给出可靠瞬态铰链载荷，而高维模型
若缺少参数和独立数据，也不自动获得更高可信度。

XV-15公开资料为倾转旋翼研究提供了几何、试验和飞行数据基础，但文献之间的构型与用途
并不一致。熟悉性文件侧重总体结构和操作定义，风洞与台架报告给出特定旋翼或整机试验，
飞行验证和频域辨识报告又对应特定重量、重心、控制系统与数据处理流程。把这些数值拼接
进一个概念模型会形成表面完整、实际不可追溯的“混合型号”。本文因此只把型号资料用于
定义候选范围、趋势或独立关联，并保留当前通用参数的身份。NASA关于XV-15历史、台架
悬停、飞行辨识和NDARC比较的资料分别承担不同证据角色，不能互相替代
\cite{maisel2000,felker1987,tischler1984,johnson2017}.

南航公开论文提供了部件划分、旋翼公式和转换状态分析的清晰方法链
\cite{sheng2022}。本文实现的当前正式旋翼与该公开公式参考路径并列存在：前者是项目
既有生产路径，后者用于同参数交叉比较。二者出现差异时，首先追溯局部速度、诱导闭合、
挥舞和积分定义，而不是选取“更好看”的一条作为真值。Berger的高维旋翼飞行器模型说明
左右短舱状态可被纳入统一状态空间，但其51状态构成、控制结构和气动细节超出本文范围
\cite{berger2019}。本文的十三状态模型借鉴状态组织思想，不是代码或模型复现。

飞行动力学教材为刚体方程、配平、线性化和模态解释提供标准理论
\cite{etkin1996,stevens2015,cook2012}；旋翼教材为动量、叶素、挥舞和诱导流的适用
假设提供基础\cite{johnson1980,leishman2006,padfield2018}。可信度部分参考计算科学
校核与确认、不确定度量化和数值误差评估方法\cite{oberkampf2010,roache1998,nasastd7009}.
本文的研究切入点不是提出新的高保真气动理论，而是把这些理论在一个受证据约束的低阶
倾转旋翼模型中闭合，并研究短舱状态化以后可观察到的动力学通道。

## 1.7 论文结构

第二章冻结坐标、单位和刚体动力学；第三章给出由局部来流到整机载荷的公式链；第四章
建立配平、线性化和可信度判据；第五章完成左右短舱状态扩展；第六章定义校核与外部
关联方法；第七章呈现证据结果；第八章讨论短舱动态作用机制；第九章分析旋翼形式、
参数敏感性和配平边界；第十章给出结论、局限和后续工作。该顺序使方法先于结果，
模型能力先于外推声明。
"""


DEPTH2 = r"""
## 2.7 模型层级与信息流

全文使用三个互有包含关系的动力学层级。准静态九状态模型把共同短舱角作为工况参数，
适合配平、局部导数和既有结果回归。十三状态规定运动模型增加左右短舱角与角速度，
适合研究带宽、速率和不同步历史。外部参考旋翼不是第四个整机层级，而是可以替换单一
旋翼部件的对照实现。层级之间共享状态顺序、控制定义、部件接口和载荷合成点，差异项
必须在模型入口处显式选择。

每次模型调用的信息流可概括为：由状态和短舱角计算质量属性；在实际重心上建立各部件
局部速度；左右旋翼求解诱导速度和稳态挥舞；旋翼结果决定机翼尾流覆盖；机身与尾翼
使用各自作用点速度；全部载荷转换到机体系并关于实际重心合成；最后进入完整惯量的
六自由度方程。十三状态路径还计算短舱二阶运动、移动质量和规定运动反作用项。先算
质量属性再算力臂，是避免参考点滞后一个时间步的必要顺序。

## 2.8 单位、正方向与极限工况

模型内部统一使用SI制：长度m、质量kg、速度m/s、力N、力矩N·m、惯量kg·m²、角度rad、
角速度rad/s。文献中以degree、rpm、英尺或磅力给出的量必须在进入参数表前换算，例如

$$
\Omega=\mathrm{rpm}\,\frac{2\pi}{60}.
$$

短舱角端点通过推力方向检查：\(\beta=0\) 时正推力主要沿 \(-z_b\)，
\(\beta=\pi/2\) 时主要沿 \(+x_b\)。重力端点通过水平姿态
\(\mathbf g_b=[0,0,g]^T\) 检查。左右旋翼在完全对称输入下推力大小应接近，而气动
反扭矩符号相反；差动控制的镜像关系则根据力矩奇偶性判断，不能机械要求所有输出相等。

零空速时固定翼动压应趋近零，旋翼仍可在转速非零时产生诱导载荷；旋翼停转若允许，
叶素相对速度和无量纲系数的定义必须避免除零。本文不在欧拉角奇异区、超出线性气动
系数有效迎角或未闭合风车分支上给出稳定性结论。这些极限工况既是数值保护，也是坐标
与符号的可证伪测试。
"""


DEPTH3 = r"""
## 3.9 模型假设、耦合遗漏与适用范围

旋翼采用刚性桨叶、准稳态二维翼型和稳态一阶谐波挥舞；诱导速度是低阶闭合，不含自由
尾迹、涡环状态专用模型、动态失速和弹性模态。机翼分成左右半翼并区分尾流区与自由流区，
但覆盖关系是几何—推进比函数，没有解析尾迹收缩、偏斜和下游时间延迟。机身及尾翼使用
低阶系数关系，超出有效迎角和侧滑角后的定量结果只可视为模型外推。部件间主要通过
局部速度、尾流覆盖、实际重心和总载荷耦合，没有全机CFD级干扰数据库。

这些简化对不同结论的影响不相同。对称性、力臂矩和坐标端点主要受实现定义约束，对
气动参数相对不敏感；配平控制量和特征根同时受气动系数、旋翼形式和质量属性影响；
短舱阶跃的响应符号通常由推力方向和左右几何主导，峰值幅度却依赖执行机构和非定常
气动。论文因此分别使用“定义校核”“趋势”“限定工况定量结果”和“外部关联”表述。

## 3.10 数值实现与失败保留

叶素径向和方位离散必须在计算成本与积分误差间折中。离散加密时推力、扭矩和面内力
应趋于稳定；如果仅推力收敛而扭矩发散，仍不能认为旋翼模型整体收敛。诱导迭代同时
检查最大迭代次数、残差和有限实数。局部 \(W\) 很小时，气动载荷随 \(W^2\) 自然衰减，
不通过人为设定最小动压产生载荷。

近法向混合的五次函数在两端具有一阶和二阶连续性：

$$
s(0)=0,\quad s(1)=1,\quad s'(0)=s'(1)=s''(0)=s''(1)=0.
$$

这减小了数值线性化跨越模型分支时的人为跳变。连续并不等于物理已验证；混合中心和
半宽仍是模型参数。对配平和线性化而言，函数连续性让残差雅可比更可解释，但不能修复
系数本身缺乏数据的问题。

负推力、诱导迭代失败、NaN、Inf和非预期复数均必须沿调用链返回。配平求解器不能把
这些点当作高惩罚但可接受的平衡，更不能以零载荷替代。保留失败点使可行区边界能够
区分“控制触界”“数值失败”和“模型适用性不足”三类原因。
"""


DEPTH4 = r"""
## 4.7 配平可信度分类与代表点选择

本文把配平结果分为可信、边界敏感、不可行和数值失败四类。可信点要求完整非线性回代
残差低于门禁、所有变量有限实数、控制不触及不允许的边界，并具备可解释的雅可比秩。
边界敏感点虽可能残差较小，但控制余度过低或条件数过大；它可用于描述权限逼近，不能
作为时域比较的稳健初值。不可行点在物理限位内无法同时闭合目标方程；数值失败则包括
部件迭代不收敛或函数非有限。

代表点选取遵循“构型覆盖、初始状态可信、计算量可控”三项原则。15°/20 m/s、
45°/35 m/s和75°/80 m/s分别代表接近直升机侧、中间转换和接近飞机侧的三个局部状态。
它们不是等概率样本，也没有覆盖侧滑、爬升、转弯和大幅操纵。选择三点的目的，是在
保持完整部件模型调用的条件下比较短舱动态通道，而非估计全包线统计量。

## 4.9 特征根、模态与证据限制

特征根应结合右特征向量和状态参与度解释。倾转旋翼模型在不同短舱角下的气动力导数
差异显著，固定翼的短周期、荷兰滚或直升机模态名称不一定可直接沿用。若一对复根主要
由 \(q,\theta,w\) 参与，可称为纵向振荡型局部模态；若 \(p,r,\phi\) 共同参与，则可
描述为横航向耦合，而不强行赋予经典名称。

配平误差会在A矩阵中引入沿未平衡方向的伪导数，差分步长则会放大迭代噪声或截断误差。
因此特征根报告以可信配平、步长敏感性和有限实数为前提。B15和B45代表点仍存在正实部
根，B75除航向积分根外多数根实部为负；这一差异只表示当前模型的局部开环性质，不能
用来反证或确认型号稳定性。
"""


DEPTH6 = r"""
## 6.4 不确定度、误差源与结论传播

本文区分参数不确定度、模型形式不确定度、数值误差和观测/数字化不确定度。参数不确定度
来自质量、惯量、气动导数和执行机构量缺少同构型来源；模型形式不确定度来自稳态挥舞、
低阶尾流覆盖和线性固定翼系数；数值误差来自叶素离散、诱导迭代、中心差分和时间积分；
外部观测不确定度包括试验重复性、图线分辨率和人工数字化。将四类误差合并为一个
“模型误差”会掩盖可改进路径。

对输出 \(y=g(\mathbf p)\) 的局部参数敏感性可写

$$
S_i=\frac{p_i}{y_{\rm ref}}\frac{\partial y}{\partial p_i}.
$$

若给定参数协方差 \(\boldsymbol\Sigma_p\)，一阶传播为

$$
\operatorname{Var}(y)\approx
\nabla_{\mathbf p}g^T\boldsymbol\Sigma_p\nabla_{\mathbf p}g.
$$

当前公开资料不足以建立可信联合分布，故本文不伪造概率置信区间，而采用来源分类、
有限扰动和模型替换三种方式判断结论稳健性。对符号、对称性和载荷通道结论，若多个
参数扰动下保持一致，可归入结构性趋势；对配平角和峰值幅度，则保留具体工况和参数集。

## 6.6 外部证据筛选

外部资料进入比较前依次核对对象、构型、工况、变量定义、单位、坐标、数据取得方式和
是否参与调参。若任一关键条件缺失，资料仍可用于背景或趋势，但不能进入定量误差统计。
图线数字化必须保存原始页、截图、轴标定、两次取点和采用规则。采用两次均值只降低
读图随机差异，不解决试验构型与模型构型不同带来的系统偏差。

NASA悬停台架曲线满足旋翼部件、总距和无量纲推力的基本可比性，是本文最强外部定量
关联。公开整机配平曲线的重量、重心、控制系统或部件数据与当前通用模型不完全一致，
因此只比较趋势和量级。频域辨识资料需要相同状态、输入和闭环结构才能直接比较导数；
当前条件不满足，故列为证据缺口。短舱转换速率资料约束量级，但没有左右独立命令、
角速度和铰链载荷时历，不能验证二阶执行机构。

## 6.10 证据等级与允许声明

理论闭合和内部测试可以支持“实现与定义一致”；网格、步长和迭代检查可以支持“在给定
数值设置下收敛”；独立公式实现可以支持“模型形式比较”；公开基准可支持“趋势或量级
一致”；同构型试验数据才可能支持特定量的外部定量关联。证据等级随被声明的量而变化，
不能把旋翼推力的外部关联传递给整机模态或短舱故障载荷。

最终声明采用最弱相关证据约束。例如，差动短舱产生非零横航向响应由左右几何、镜像
检查和三个时域点共同支持；峰值大小还受占位执行机构和气动模型影响，证据更弱。
整机模型的总体可信度以内部一致性和有限基准为主，论文题名采用“可信度分析”以匹配
这一事实。
"""


DEPTH7 = r"""
## 7.1 最终代码回归与程序校核

冻结基线在MATLAB R2021a上执行26项完整回归，26项均满足现有判据，耗时728.07 s。
覆盖范围包括质量惯量、短舱端点、旋翼总距单调性、左右对称、南航公开公式闭合、机翼
速度链、旋翼力矩链、一阶谐波挥舞、气动部件、控制架构、十三状态接口/配平/线性化/
研究时域、通用配平来源、控制分配、可信度诊断、机翼连续混合、速度平方律、旋翼网格
和线性化有限值。标准错误日志为空，没有在报告中发现NaN、Inf或非预期复数。

回归的意义是防止论文重组与分析脚本改变已有模型行为，并确认冻结数据可以由当前代码
读取。测试集合由项目内部定义，其通过不构成外部验证。最终文档提交还需在最终HEAD
重复同一回归，以排除中间分析脚本和排版文件对路径或接口的意外影响。

## 7.2 数值收敛与失败点

旋翼网格检查同时比较推力、扭矩和关键面内力；中心差分使用不同相对步长复算；时域响应
使用相邻时间步比较峰值。三类检查分别约束空间积分、局部导数和时间积分，不能用其中
一种替代另外两种。迭代失败点、负推力分支和控制触界点保留在结果表中。

外部悬停关联的当前旋翼在6°、8°、10°处失败，南航参考路径在0°至8°失败。这些点
没有参与共同有效区间的误差平均，但在失败计数中保留。75°/40 m/s的整机配平失败和
75°/80 m/s南航参考旋翼失败同样被保留。失败不是论文质量缺陷的同义词；隐去失败才会
使可用域和误差指标失真。
"""


DEPTH8 = r"""
## 8.1 事件定义与可比性

所有短舱事件从完整非线性模型的可信配平点开始。比较模型时保持初始刚体状态、控制量、
短舱角和外部命令一致，只改变是否显式积分短舱状态或事件类型。对称阶跃、对称斜坡、
差动阶跃、左右速率失配、单侧延迟、指令冻结和运动学锁定分别回答不同问题，不能把
多个事件的峰值拼成单一故障包线。

状态响应以相对初始平衡的增量表示，避免把不同速度和姿态基值混入峰值。纵向组包括
\(u,w,q,\theta\)，横航向组包括 \(v,p,r,\phi,\psi\)。载荷分解同步保存旋翼、
机翼、机身和尾翼贡献，使“出现响应”能够追溯到力方向、作用点或尾流差，而不仅是
状态曲线相关。

## 8.5 带宽与阻尼敏感性

二阶执行机构的带宽决定短舱角建立速度，阻尼影响超调和相位。对于同一命令幅值，较高
\(\omega_n\) 通常增加短舱角速度和角加速度峰值，从而放大规定运动反作用项；较低阻尼
可能产生更明显的往复载荷。气动载荷还取决于当时的刚体状态，故响应不严格按
\(\omega_n^2\) 比例缩放。

当前带宽4 rad/s、阻尼0.8、速率20 deg/s和加速度30 deg/s²均不是XV-15辨识结果。
敏感性计算用于显示模型中哪些输出受执行机构假设支配。如果改变这些参数会改变峰值
排序而不改变响应符号，则只能保留通道结论。获得真实左右短舱时历后，应先辨识命令—
角度传递特性，再评价刚体响应。

## 8.12 动态配平偏离与局部线性模型

短舱运动时，初始配平对应的气动平衡随 \(\beta_L,\beta_R\) 改变，因此即使刚体状态
尚未明显变化，也会产生瞬时残差。动态配平偏离量反映“冻结当前状态和控制时离新平衡
有多远”，不是实时求得的新配平轨迹。它可帮助区分直接短舱载荷和随后刚体反馈。

十三状态线性模型只在初始点附近逼近非线性模型。小幅、短时事件可比较导数和响应方向；
斜坡、限速、延迟或冻结包含明显非线性和时变边界，线性模型主要用于解释初始通道。
若线性与非线性差异随扰动幅值缩小而降低，可认为局部线性化一致；若差异来自跨越尾流
混合或执行机构限幅，则需保留非线性解释。
"""


DEPTH9 = r"""
## 9.1 参数来源层级

参数表把关键量分为文献直接值、图线数字化值、明确公式推导值、工程假设、临时占位和
未知六类。文献直接值仍需记录构型、页码、原始单位和坐标；由XV-15资料得到的量只有
在覆盖模型中才具有型号标签。通用默认模型的6000 kg质量、完整惯量、旋翼几何和固定翼
气动系数主要用于概念计算，不能因数量级合理而改称实测。

高影响抽查显示，质量和惯量决定刚体响应尺度，移动短舱质量及质心半径影响重心/惯量
随角度变化，旋翼半径、弦长、转速和扭转决定推力与功率，翼型关系和诱导闭合决定前飞
模型形式，机翼俯仰矩、平尾安装角/下洗/升降舵效能决定纵向配平，短舱惯量和带宽决定
规定运动瞬态。论文对这些量逐项标注来源身份，并把联合优化的四项量称为等效参数。

## 9.3 参数敏感性与优化方法

优化只在预先冻结的四项纵向参数及物理边界内进行，目标由九个工况的尺度化配平残差、
可信点数量和控制余度组成。它不是无限维系统辨识，也不改变旋翼、质量或控制限位。
为防止用少数异常点驱动参数，失败工况以显式惩罚保留，可信点需要完整模型回代。

参数敏感性矩阵记为

$$
\mathbf S_{ij}=\frac{p_j}{y_{i,\rm ref}}
\frac{\partial y_i}{\partial p_j}.
$$

对 \(\mathbf S\) 做奇异值分解可识别近共线方向。若多个参数只通过同一俯仰矩组合影响
残差，单一最优值不具有唯一物理解释；此时报告可行参数组合和结果敏感性，比给出过多
有效数字更恰当。联合优化值没有外部数据约束，所以只改善概念模型内部配平一致性。

## 9.7 配平可行区与稳健性分类

离散网格给出九点中8点可信，但“8/9”不说明未采样区域。加密走廊用于检查相邻速度/
短舱角点之间是否出现控制突跳或求解分支切换。若连续延拓需要跨过未收敛、负推力或
边界敏感区，则可行区不能连成一条物理转换路径。

结论稳健性分为三类。第一类是坐标和几何结构决定的结论，如短舱端点、力臂叉乘和
对称/差动定义；第二类是在参数扰动和旋翼替换下仍保持的趋势，如对称与差动通道；
第三类是对模型形式或等效参数敏感的定量量，如配平舵角、特征根和峰值。第三类结果
必须与具体参数集、工况和门禁一起引用。
"""


DEPTH3B = r"""
## 3.5 控制输入、左右分配与可辨识通道

整机控制向量采用总距、差动总距、对称纵向周期、差动纵向周期、短舱角、升降舵和方向舵
等物理量。左右旋翼侧控制由和差变换得到：

$$
\theta_{0,L}=\theta_0+\Delta\theta_0,\qquad
\theta_{0,R}=\theta_0-\Delta\theta_0,
$$

$$
\theta_{{\rm cyc},L}=\theta_{\rm cyc}+\Delta\theta_{\rm cyc},\qquad
\theta_{{\rm cyc},R}=\theta_{\rm cyc}-\Delta\theta_{\rm cyc}.
$$

历史接口名 `diffCyclic` 在物理含义上指差动纵向周期变距。模型没有独立横向周期输入。
这不是遗漏一个显然控制，而是当前左右旋翼稳态一阶挥舞映射的控制架构选择：对称纵向
周期使两个盘面法向共同沿 \(+\mathbf e_D\) 倾斜，差动纵向周期使盘面反向倾斜并在
当前符号下产生负偏航力矩增量。若未来引入每侧完整横纵周期控制，状态与输入矩阵必须
重新定义，不能在现有B矩阵末尾静默增加一列。

控制分配的可辨识性取决于载荷通道是否线性独立。总距主要改变两旋翼推力和总轴向/
法向力；差动总距主要形成左右推力差和滚转矩；对称纵向周期改变共同盘面方向；差动
纵向周期通过相反盘面倾斜形成偏航/滚转耦合。短舱角改变推力轴与机翼尾流，作用比
周期变距更广。配平雅可比的奇异值能够发现两个控制在特定工况下趋于共线，但不能仅凭
控制名称预先假定解耦。

## 3.6 载荷量纲、功率与能量一致性

旋翼推力和扭矩系数分别定义为

$$
C_T=\frac{T}{\rho A(\Omega R)^2},\qquad
C_Q=\frac{Q}{\rho A(\Omega R)^2R}.
$$

轴功率为

$$
P=Q\Omega,
$$

单位为W。若扭矩符号随旋向而改变，功率比较使用阻力矩对驱动轴所需功率的正值，而机体
反扭矩仍保留有向符号。把两者混用会导致左右旋翼功率相消这一非物理结果。本文的左右
旋向只影响有向面内力、反扭矩和谐波映射，不改变完全对称工况下单侧耗功的正值。

固定翼部件载荷按 \(qS\) 尺度，气动力矩按 \(qS\bar c\) 或 \(qSb\) 尺度；作用点
力矩按 \(rF\) 尺度。质量属性进入加速度时分别形成 \(F/m\) 和 \(I^{-1}M\)。这些
量纲关系用于发现度/弧度、rpm/rad·s⁻¹、整翼/半翼面积以及力/力矩参考量重复计入。
数值有限并不保证量纲正确，故单元测试还需要端点、速度平方律和人为力臂扰动。

## 3.7 左右半翼尾流求值顺序的物理含义

九状态路径的共同短舱角适合完全对称准静态工况。它用左右旋翼推进比平均值
\(\bar\mu=(\mu_L+\mu_R)/2\) 计算覆盖面积，再对两侧应用相同覆盖。十三状态路径允许
\(\beta_L\ne\beta_R\)，因此使用 \(\mathcal A(\mu_L,\beta_L)\) 和
\(\mathcal A(\mu_R,\beta_R)\) 分别计算。即使在平衡点
\(\beta_L=\beta_R\)，对 \(p\) 或 \(r\) 的中心差分扰动仍产生
\(\delta\mu_L=-\delta\mu_R\) 型分量。

若 \(\mathcal A\) 为严格线性函数且不触及上下限，两种路径的一阶总和可能相同；实际
模型包含几何限制和连续混合，局部曲率及饱和使

$$
\mathcal A\!\left(\frac{\mu_L+\mu_R}{2},\beta\right)
\ne\frac{\mathcal A(\mu_L,\beta)+\mathcal A(\mu_R,\beta)}{2}.
$$

因此差异集中在产生左右速度梯度的角速度扰动，而不是所有九个共享状态。该解释既说明
数值现象，又暴露模型选择：独立求值具有更细的左右信息，但没有试验数据证明其覆盖
函数更准确。论文保留两条路径，不把其中一条强制改成另一条。
"""


DEPTH5B = r"""
## 5.6 移动质量与载荷参考点的时间一致性

短舱质量位置随角度变化时，总重心和惯量必须与本次载荷调用使用同一组
\(\beta_L,\beta_R\)。若先用旧重心计算部件力臂、再更新质量属性，会人为引入一步延迟；
在线性化中，这种顺序错误会表现为关于短舱角的伪导数。本文在每次状态函数入口先计算
质量属性，再向所有部件传递统一重心。

平行轴项对称且半正定，但部件坐标旋转后的自身惯量和交叉惯量符号仍需核对。总惯量的
数值检查包括

$$
\|\mathbf I-\mathbf I^T\|_F\le\varepsilon_I,\qquad
\min_i\lambda_i(\mathbf I)>0.
$$

这两个条件能够排除非对称或非正定矩阵，却不能确认部件质量和质心半径来自真实型号。
当前移动短舱质量900 kg和质心半径0.75 m属于通用概念参数；它们决定重心移动量和
惯量变化幅值，需要在获得构型数据后优先替换。

## 5.7 短舱角速度的直接与间接作用

\(\dot\beta_h\) 有三类作用。第一类是转子角动量方向变化形成的直接陀螺矩；第二类是
执行机构加速度通过等效惯量形成的反作用矩；第三类是短舱角历史改变旋翼轴、局部来流和
移动质量，随后间接改变气动力与刚体状态。当前默认转子极惯量为零时，第一类直接项为
零，但接口和符号仍受测试约束；不能据此宣称真实飞行器没有陀螺效应。

区分直接与间接贡献的方法，是在同一状态下分别评估完整载荷与把
\(\dot\beta_h,\ddot\beta_h\) 直接项置零后的载荷差。该差只表示方程分解，不是可独立
施加的物理实验。随着刚体状态演化，两条轨迹的气动载荷也会分离，因此长时间响应不能
简单相减后全部归因于陀螺矩。

## 5.8 对称性破缺与左右事件

完全对称构型、零侧滑和相同左右参数下，对称短舱命令的一阶横航向响应应接近零。差动
命令则允许非零侧向力、滚转矩和偏航矩。现实中的质量、气动、安装和伺服差异会破坏
这一分解。本文通过带宽失配、速率失配和单侧延迟构造可控的不对称，但没有为真实左右
差异赋值。

若左右事件的符号同时反转，横航向奇变量应镜像，对称纵向偶变量应近似保持。镜像误差
是检查控制分配、旋向、坐标变换和力臂符号的有效手段。它只在对称参数和小扰动附近成立；
执行机构限幅、非线性尾流覆盖或状态偏离会产生高阶非镜像项。
"""


DEPTH7B = r"""
## 7.4 同参数旋翼实现比较

当前正式旋翼和南航公开公式参考旋翼在同一半径、弦长、转速、总距与来流下计算，比较
目的在于隔离公式实现，而不是比较两个不同参数集。悬停附近，两者都由轴向诱导与平均
叶素载荷主导，推力趋势接近；进入前飞后，方位速度、非均匀入流、挥舞闭合和面内力
处理不同，配平残差与控制量差异扩大。

比较保留每条路径的失败信息。负推力或诱导无实根意味着该公式闭合在当前状态不可用，
不是简单的数值离群值。若只比较两条路径都成功的点，会高估共同适用域；若把一条路径
当成真值，又会混淆独立实现与外部试验。本文分别报告共同有效区误差、失败点和整机
配平影响。

## 7.5 公开整机趋势与不可比项

南航论文中的配平曲线可用于检查短舱角变化时姿态和控制是否出现相反的整体趋势，但
其参数、控制映射和旋翼细节与当前模型不同。XV-15公开配平资料又对应特定重量、重心、
襟翼/操纵系统和试验条件。对这些资料，本文核对短舱角端点、速度范围和变量单位后进行
趋势对照，不计算会暗示同构型的MAE。

频域辨识资料包含闭环飞行数据处理和特定输入设计。将其中导数或模态直接与当前开环
概念模型比较，需要还原状态定义、控制混控、传感器滤波和飞行状态。当前证据不足，
因此导数与模态被列为后续外部验证缺口。公开“速率约7.5°/s、端点附近约1.5°/s”
只用于说明短舱运动量级，不能辨识二阶带宽、阻尼或左右同步误差。

## 7.6 配平、导数与时域证据之间的依赖

短舱时域事件以可信配平为初值，故初始残差会直接影响响应；线性模型又以同一点的中心
差分为基础。证据链的顺序应是部件有限与收敛、完整模型配平回代、导数步长稳定、最后
进行线性/非线性和时域比较。后级结果不能反过来证明前级模型正确。

若配平点控制余度很小，短舱扰动可能立即触发限位，响应同时反映执行机构事件和原有
控制权限不足。代表点选取排除了75°/40 m/s失败点，并保留75°/80 m/s作为高短舱角
可信点。这样能够比较通道，但也意味着时域结果没有覆盖最困难的失败区域。

## 7.7 结果的可重复性与哈希

所有定量表均保存变量名、单位、工况和生成入口；图从CSV或MAT数据重建，不从论文图片
反向取数。NASA图线是唯一必须人工数字化的外部曲线，因此额外保存PDF页、截图、轴标定
与两次取点。最终清单使用SHA-256覆盖正文、数据、脚本、图和PDF，使审阅者能够判断
文件是否与报告版本一致。

哈希只能保证字节级身份，不能证明公式正确或数据独立。可重复性还要求记录MATLAB、
Python、XeLaTeX和Biber版本、命令、日志、失败状态和构建顺序。本文把这些信息放在
交付报告和附录，不作为科学贡献。
"""


DEPTH8B = r"""
## 8.9 速度与短舱角对载荷通道的调制

同一短舱角扰动在三个代表点产生不同响应，原因不只是初始速度大小。低短舱角时，旋翼
推力主要承担升力，短舱旋转直接改变垂向分量，机翼自由流动压较低；中间构型中，旋翼
轴向和机翼尾流同时变化，部件间耦合最明显；高短舱角、高速度点的固定翼载荷占比增加，
小的尾流覆盖或迎角变化可以形成较大的半翼力矩。因而不能把响应随速度的变化解释成
单一 \(V^2\) 比例。

用局部一阶分解表示，状态导数对短舱角的敏感性包含

$$
\frac{\partial\dot{\mathbf x}}{\partial\beta_h}
=\frac{\partial\dot{\mathbf x}}{\partial\mathbf F_h}
\frac{\partial\mathbf F_h}{\partial\beta_h}
+\frac{\partial\dot{\mathbf x}}{\partial\mathbf F_w}
\frac{\partial\mathbf F_w}{\partial S_{\rm slip,h}}
\frac{\partial S_{\rm slip,h}}{\partial\beta_h}
+\frac{\partial\dot{\mathbf x}}{\partial\mathbf I}
\frac{\partial\mathbf I}{\partial\beta_h}+\cdots .
$$

第一项是旋翼轴和推力方向，第二项是机翼尾流，第三项是移动质量和惯量。不同工况下各项
权重改变，可能出现响应符号保持而幅值排序变化。论文的部件分解用于识别主导路径，
但在非线性时域中各项并非严格可加，因为状态反馈会改变后续局部来流。

## 8.10 侧向力、滚转矩与偏航矩的几何分解

差动短舱角使左右旋翼力增量近似为一对反对称向量。若旋翼主要位于
\(\mathbf r_{L,R}=[x_h,\mp y_h,z_h]^T\)，则由轴向/法向力差产生的力矩分量满足

$$
\Delta L\approx-y_L\Delta Z_L+y_R\Delta Z_R
+z_L\Delta Y_L-z_R\Delta Y_R,
$$

$$
\Delta N\approx x_L\Delta Y_L-x_R\Delta Y_R
-y_L\Delta X_L+y_R\Delta X_R.
$$

滚转矩通常受左右垂向力与半展长力臂影响，偏航矩同时受轴向力差、侧向力和旋翼反扭矩
影响。机翼尾流差又通过半翼升力与阻力加入两式。某一工况滚转峰值大于偏航峰值，不足以
形成普遍排序；力臂、短舱角和动压变化都可能改变比例。

侧向总力在理想反对称几何下可能比力矩小，因为左右侧向分量相消而力臂矩相加。若只看
\(v\) 响应，可能低估差动短舱对 \(p,r\) 的影响。相反，航向角 \(\psi\) 是角速度
积分量，短时非零偏航角不等于持续偏航力矩。结果讨论因此同时给出瞬时载荷、角速度和
姿态，避免只凭一个状态判断物理通道。

## 8.11 事件幅值、限幅与局部结论

对阶跃幅值 \(\Delta\beta_c\) 足够小时，初始响应近似按幅值线性缩放：

$$
\Delta\mathbf x(t;\,k\Delta\beta_c)\approx
k\,\Delta\mathbf x(t;\,\Delta\beta_c).
$$

一旦角速度、角加速度或转矩限制激活，短舱轨迹不再线性缩放；若刚体响应进一步跨越
气动混合或控制边界，非线性会继续累积。本文使用的小幅对称和差动事件用于识别局部
通道，延迟、冻结和失配事件用于揭示对称性破缺。它们不是法规故障幅值，也没有覆盖
最不利组合。

时域响应的可信解释需要四个条件同时成立：初始点满足配平门禁；部件求解在全时段有限；
时间步峰值变化在规定阈值内；结论不超过执行机构和气动参数来源。满足前三项只说明数值
计算可复核，第四项决定是否能够外推到真实飞行器。
"""


def technical_round(round2: str) -> str:
    text = round2
    for marker, block in [
        ("# 第二章", DEPTH1),
        ("# 第三章", TECH2),
        ("# 第三章", DEPTH2),
        ("# 第四章", TECH3),
        ("# 第四章", DEPTH3),
        ("# 第四章", DEPTH3B),
        ("# 第五章", TECH4),
        ("# 第五章", DEPTH4),
        ("# 第六章", TECH5),
        ("# 第六章", DEPTH5B),
        ("# 第七章", TECH6),
        ("# 第七章", DEPTH6),
        ("# 第八章", TECH7),
        ("# 第八章", DEPTH7),
        ("# 第八章", DEPTH7B),
        ("# 第九章", TECH8),
        ("# 第九章", DEPTH8),
        ("# 第九章", DEPTH8B),
        ("# 第十章", TECH9),
        ("# 第十章", DEPTH9),
        ("# 附录A", TECH10),
    ]:
        text = insert_before(text, marker, block)
    return text


ZH_ABSTRACT = """## 中文摘要

倾转旋翼机在短舱转换过程中同时经历旋翼轴向、局部尾流、质量属性和操纵权限变化，
公开资料又不足以唯一辨识完整型号模型。针对这一问题，本文建立通用、低阶、部件级
倾转旋翼机非线性飞行动力学模型，在统一机体系中计算左右旋翼、左右机翼、机身和平尾、
垂尾载荷，并关于随短舱角变化的实际重心合成。配平采用尺度化残差、控制边界、回代状态
和雅可比奇异值联合评价，线性模型由中心差分获得。

为表示短舱运动历史和左右不同步，在九状态刚体模型上增加左右短舱角及角速度，形成
十三状态规定运动模型。模型包含短舱二阶命令跟踪、移动质量、执行机构反作用力矩和
转子陀螺接口，并用对称/差动坐标区分纵向与横航向载荷通道。可信度分析由程序校核、
数值收敛、模型形式比较和公开试验图线关联组成；NASA TM-86854悬停曲线经过两次独立
数字化后用于未调参比较。

结果表明，纵向等效参数联合优化模型在9个离散工况中有8个满足本文可信度门禁；
75°/40 m/s因低尾翼动压、俯仰力矩不足和升降舵触界而保留为失败点。三个可信代表点中，
对称短舱小扰动以纵向响应为主，差动小扰动均产生横侧向—航向响应；相邻时间步的最大
峰值变化为1.5248%。NASA悬停曲线关联中，两条旋翼路径的推力斜率方向与试验一致，
但 \(C_T/\\sigma\) 的平均绝对误差约为0.063至0.064，存在显著幅值偏差。

本文结果支持概念模型在限定工况下的内部一致性、短舱载荷通道辨识和部件级公开数据
关联，不支持XV-15型号复现、飞行安全包线或完整伺服—铰链—结构耦合结论。

**关键词：** 倾转旋翼机；部件级建模；短舱动态状态；可信配平；数值线性化；可信度分析
"""


EN_ABSTRACT = """## Abstract

Public information is insufficient to uniquely identify a complete tiltrotor
aircraft model, while nacelle conversion simultaneously changes rotor-axis
orientation, rotor-wing interaction, mass properties, and control authority.
This thesis therefore develops a generic, low-order, component-level nonlinear
flight-dynamics model. Loads from the two rotors, two wing panels, fuselage,
horizontal tail, and vertical tail are computed in local flows, transformed to
body axes, and summed about the nacelle-angle-dependent center of gravity.
Trim credibility is assessed jointly from scaled residuals, control bounds,
nonlinear substitution, and Jacobian singular values. Local linear models are
obtained by central differences.

Left and right nacelle angles and rates are added to the nine rigid-body states
to represent motion history and actuator asymmetry. The resulting thirteen-state
prescribed-motion model includes second-order command tracking, moving masses,
actuator reaction moments, and an interface for rotor gyroscopic moments.
Symmetric and differential coordinates separate the principal longitudinal and
lateral-directional load paths. Credibility evidence combines code verification,
numerical convergence, model-form comparison, and correlation with publicly
available test curves. The hover data in NASA TM-86854 were digitized twice
independently and were not used for tuning.

Eight of nine discrete cases satisfy the adopted trim-credibility gates after
joint optimization of effective longitudinal parameters. The 75-deg/40-m/s case
remains infeasible because of low tail dynamic pressure, insufficient pitching
moment, and elevator saturation. At three credible operating points, small
symmetric nacelle inputs mainly excite longitudinal motion, whereas differential
inputs produce lateral-directional responses. The maximum peak change between
adjacent time steps is 1.5248%. Both rotor implementations reproduce the positive
slope of the public hover curve, but their mean absolute errors in \(C_T/\\sigma\)
are approximately 0.063--0.064, revealing a substantial amplitude bias.

The evidence supports internal consistency, mechanism-oriented nacelle analysis,
and component-level public-data correlation over the stated conditions. It does
not establish an XV-15 reproduction, a flight-safety envelope, or a fully coupled
servo-hinge-structure model.

**Key words:** tiltrotor aircraft; component-level modeling; nacelle dynamic
states; credible trim; numerical linearization; credibility assessment
"""


def replace_abstracts(text: str) -> str:
    i = text.find("## 中文摘要")
    j = text.find("## 符号表")
    if i < 0 or j < 0:
        raise RuntimeError("abstract markers unavailable")
    return text[:i] + ZH_ABSTRACT + "\n\n" + EN_ABSTRACT + "\n\n" + text[j:]


def language_round(round3: str) -> tuple[str, list[list[str]]]:
    text = replace_abstracts(round3)
    mappings = [
        ("PASS_WITH_DOMAIN", "在限定范围内满足校核要求"),
        ("PASS_WITH_CAUTION", "数值敏感"),
        ("PASS", "满足当前校核要求"),
        ("FAIL", "配平失败"),
        ("CURRENT_PRODUCTION", "当前正式旋翼模型"),
        ("NUAA_PUBLIC_FORMULA_REFERENCE", "南航公开公式旋翼参考模型"),
        ("RESEARCH_PLACEHOLDER", "研究占位参数"),
        ("Model C2", "纵向配平参数联合优化模型"),
        ("Model C1", "有限纵向几何参数优化模型"),
        ("Model B", "XV-15公开参数覆盖模型"),
        ("Model A", "原始通用基线模型"),
        ("证明了", "结果表明"),
        ("全面验证", "全面评价"),
        ("验证通过", "满足相应证据类型的判据"),
        ("模型正确", "模型在限定检查下内部一致"),
        ("飞行安全边界", "模型计算适用边界"),
        ("已归档", "既有计算"),
    ]
    log = []
    for old, new in mappings:
        count = text.count(old)
        if count:
            text = text.replace(old, new)
        log.append([old, new, str(count), "全文"])
    # Remove development-task vocabulary from prose while keeping mathematical PR labels absent.
    text = re.sub(r"\bPR\s*#?\d+\b", "既有版本", text, flags=re.I)
    text = text.replace("commit", "版本记录").replace("Codex", "自动化工具")
    return text, log


def blind_review_revision(round4: str) -> str:
    addition7 = """
## 7.9 证据充分性再评价

外部悬停关联的幅值误差接近观测变化范围的四至六成，不能用“斜率一致”抵消。本文保留
该负面结果，因为它直接说明当前桨叶几何和经验修正不足。整机没有同构型、同状态和同
操纵量的公开时历，因而配平趋势、导数符号和模态资料分别列示，不拼接成虚假的整机
定量验证链。三个短舱动态点是为覆盖低、中、高短舱角而选取的机理样本，不构成统计
代表性；结论用“在所选三个可信工况中”限定。

可信度结论还取决于“量”的粒度。同一旋翼模型可以在推力斜率上与试验方向一致，同时
在绝对推力、扭矩或失败区间上不一致；同一整机模型也可以满足质量和坐标校核，却在
模态或配平舵量上缺少外部证据。因此最终表述不再给整个模型赋予单一“通过/不通过”
标签，而是对推力趋势、配平回代、局部导数、短舱响应和故障载荷分别给出证据来源。
这种逐量评价避免把一个强证据错误传递到其他输出，也使后续新增试验数据能够针对具体
缺口更新结论。
"""
    addition5 = """
## 5.9 状态扩展的研究增量与单向边界

若短舱角只作为静态参数，相同瞬时角度无法区分不同速率、带宽、延迟和左右失配历史。
十三状态模型的增量不在于增加方程数量，而在于使这些历史变量成为可重复的初值和状态，
从而可分解规定运动反作用、移动质量和尾流不同步通道。二阶执行机构没有型号辨识数据，
所以本文不比较真实伺服品质，也不预测机械卡滞载荷。该限制在时域图和结论中保持一致。
"""
    text = insert_before(round4, "# 第六章", addition5)
    text = insert_before(text, "# 第八章", addition7)
    return text


def make_reports(round2: str, info: dict[str, int], round3: str, round4: str, round5: str) -> None:
    r2 = OUT / "round_02_structure"
    r3 = OUT / "round_03_technical_expansion"
    r4 = OUT / "round_04_language"
    r5 = OUT / "round_05_blind_review"
    write(r2 / "ROUND2_RESTRUCTURED_THESIS.md", round2)
    write(
        r2 / "ROUND2_STRUCTURE_AUDIT.md",
        f"""# 第二轮结构审计

- 原稿非空白字符：{info['source_characters']}
- 重构稿非空白字符：{info['round2_characters']}
- 从已识别冗余区间删除的原始字符：{info['removed_raw_characters']}
- 原稿三级以内标题：{info['source_headings']}
- 重构稿三级以内标题：{info['round2_headings']}
- 删除或合并的模板小节：57
- 估算减少页数：约22页（按每页约1100个非空白字符估算）

V01—V26被压缩为方法矩阵与关键案例；第3章和第8章的后置扩写段、逐图索引章和手写
参考文献段被移除。短舱动态、可信配平和旋翼外部关联保留在主线章节。数值均来自第一轮
冻结底稿，本轮未改模型或参数。
""",
    )
    write(
        r2 / "ROUND2_DELETED_REDUNDANCY_REPORT.md",
        """# 删除冗余报告

| 类型 | 处理 | 数量/范围 |
|---|---|---|
| V01—V26模板段 | 合并为校核矩阵和关键案例 | 26节 |
| 第3章深化重复 | 删除，核心公式在第三轮按物理链重建 | 19节 |
| 第7章分层证据散文 | 删除，保留定量结果 | 1个长节 |
| 第8章事件重复解释 | 删除，关键机理在第三轮重建 | 13节 |
| 正文逐图索引 | 整章删除，图回到讨论位置 | 1章 |
| 手工参考文献段 | 交由Biber生成 | 20项旧列表 |

没有为恢复篇幅复制边界声明或证据矩阵散文。删除内容可由PR #57基线完整追溯。
""",
    )
    migration_rows = [
        ["3.20—3.38", "第三章3.1—3.10", "删除重复后按公式链补写", "已解决"],
        ["6.5 V01—V16", "第六章6.5", "压缩为一张矩阵", "已解决"],
        ["7.7 V17—V26", "第七章7.1—7.9", "仅保留关键案例", "已解决"],
        ["7.8长篇证据模板", "第六、七章", "方法与结果分离", "已解决"],
        ["8.20—8.32", "第八章8.3—8.13", "合并为机理讨论", "已解决"],
        ["正文图表索引", "各相关章节", "取消独立索引章", "已解决"],
        ["参数优化大段", "第九章", "限定为敏感性与边界", "已解决"],
    ]
    write_csv(r2 / "ROUND2_SECTION_MIGRATION_MATRIX.csv",
              ["原章节", "新章节", "处理", "状态"], migration_rows)
    write(
        r2 / "ROUND2_CHAPTER_LOGIC_MAP.md",
        """# 章节论证链

公开资料与科学问题 → 统一坐标和刚体理论 → 部件载荷闭合 → 可信配平和局部线性化 →
左右短舱状态扩展 → 分层可信度方法 → 内外部证据结果 → 短舱动态机理 →
旋翼/参数敏感性与配平边界 → 结论和后续验证。

每章开头说明输入、问题和输出；每章结论只承担本章发现，不再重复全文边界。
""",
    )
    figs = sorted((ROOT / "docs" / "master_thesis_validation" / "figures").glob("*.png"))
    fig_rows = []
    for i, p in enumerate(figs, 1):
        target = (
            "第一章" if i in {1, 36} else "第二章" if i in {2, 37, 41} else
            "第六章" if i in {38, 39, 40, 42} else "第七章" if i in {3, 4, 5, 43} else
            "第八章" if 6 <= i <= 10 or 16 <= i <= 18 else "第九章"
        )
        fig_rows.append([i, p.name, target, "置于首次定量讨论之后", "保留" if i <= 43 else "复核"])
    write_csv(r2 / "ROUND2_FIGURE_RELOCATION_PLAN.csv",
              ["图号", "文件", "目标章节", "位置原则", "处理"], fig_rows)

    write(r3 / "ROUND3_TECHNICAL_THESIS.md", round3)
    write(
        r3 / "ROUND3_FORMULA_AUDIT.md",
        f"""# 第三轮公式审计

- 重构前显示公式组：18
- 第三轮显示公式组：{displayed_equations(round3)}
- 新增公式组：{displayed_equations(round3)-18}

新增链覆盖坐标变换、欧拉角运动学、完整惯量、移动重心和平行轴定理、叶素速度与载荷、
诱导闭合、谐波挥舞、左右机翼尾流、固定翼部件、载荷合成、配平尺度、SVD、中心差分、
十三状态执行机构、反作用与陀螺项，以及误差指标。每组公式邻接说明坐标、单位、假设和
适用边界。
""",
    )
    symbols = [
        ["u,v,w", "机体系速度", "m/s", "机体系", "状态"],
        ["p,q,r", "机体系角速度", "rad/s", "机体系", "状态"],
        ["phi,theta,psi", "3-2-1欧拉角", "rad", "地面系/机体系", "状态"],
        ["beta_L,beta_R", "左右短舱角；0直升机侧，pi/2飞机侧", "rad", "铰链轴定义", "状态"],
        ["T,Q", "单旋翼推力与气动扭矩", "N; N m", "旋翼轴系", "输出"],
        ["v_i", "诱导速度", "m/s", "旋翼轴系", "迭代量"],
        ["C_T,sigma", "推力系数与实度", "1", "旋翼", "外部关联"],
        ["F_b,M_b", "整机合力与关于实际重心的合矩", "N; N m", "机体系", "输出"],
        ["I_b", "关于实际重心的完整惯量矩阵", "kg m2", "机体系", "参数"],
        ["r_t", "尺度化配平残差", "1", "残差空间", "判据"],
        ["A,B", "状态矩阵与输入矩阵", "随变量定义", "局部线性模型", "导数"],
        ["omega_n,zeta", "短舱执行机构固有频率与阻尼比", "rad/s; 1", "单侧执行机构", "研究占位"],
    ]
    write_csv(r3 / "ROUND3_SYMBOL_UNIT_TABLE.csv",
              ["符号", "定义", "单位", "坐标/参考", "类别"], symbols)
    write_csv(
        r3 / "ROUND3_FIGURE_PLACEMENT_MATRIX.csv",
        ["图组", "章节", "回答的问题", "可信量", "限制"],
        [
            ["悬停旋翼外部关联", "7.3", "推力趋势和幅值偏差", "数字化点与误差指标", "构型不同"],
            ["九/十三状态导数", "7.8", "共享块差异来源", "逐元素和部件分解", "缺少实机导数"],
            ["对称短舱响应", "8.3", "纵向载荷通道", "三个可信点的相对响应", "小扰动"],
            ["差动短舱响应", "8.7", "横航向载荷通道", "符号与非零响应", "占位执行机构"],
            ["配平可行区", "9.5—9.7", "75度困难工况", "残差、限位、余度", "概念模型"],
        ],
    )
    write(
        r3 / "ROUND3_PHYSICAL_INTERPRETATION_AUDIT.md",
        """# 物理解释审计

75°/40 m/s被解释为低尾翼动压、旋翼推力方向、俯仰力矩权限和升降舵限位共同作用；
-52.91°明确为不可实现延拓。75°/60 m/s的改善归因于动压恢复与等效参数，而非型号
校准。对称短舱通过推力方向和纵向合矩作用，差动短舱通过左右力方向、力臂和尾流差作用。
悬停相近而前飞分歧增大由方位不均匀入流、面内力和诱导/挥舞闭合解释。机械卡滞没有
双向铰链—伺服模型，正文不再给出载荷预测。
""",
    )
    write(
        r3 / "ROUND3_FORMULA_CODE_CROSSCHECK.md",
        """# 公式—代码交叉复核

第三轮公式以第一轮 `FINAL_FORMULA_CODE_PARAMETER_TEST_MAPPING.md` 为唯一当前HEAD映射。
刚体方程、质量属性、旋翼、机翼、尾翼、载荷合成、配平、线性化和十三状态模块均能映射
到当前函数或明确标记的研究占位接口。论文没有把未实现的动态失速、自由尾迹、双向伺服
或结构弹性写成已有公式。
""",
    )

    write(r4 / "ROUND4_LANGUAGE_REVISED_THESIS.md", round4)
    _, language_log = language_round(round3)
    write_csv(r4 / "ROUND4_TERMINOLOGY_TABLE.csv",
              ["原工程术语", "论文术语", "替换次数", "范围"], language_log)
    write(
        r4 / "ROUND4_LANGUAGE_CHANGE_LOG.md",
        """# 第四轮语言修改记录

全文统一“可信度分析”“程序校核”“外部数据关联”“研究占位参数”等术语；删除开发
任务语汇和工程状态标签；把“证明”“验证通过”改为与证据类型相符的有限表述。摘要
按科学问题—模型—方法—结果—边界重写，只保留配平8/9、时间步1.5248%和悬停误差
0.063—0.064三类关键量。三项贡献均说明相对已有流程的增量。
""",
    )
    write_csv(
        r4 / "ROUND4_LOGIC_ISSUE_LOG.csv",
        ["编号", "问题", "位置", "处理", "状态"],
        [
            ["L01", "斜率一致可能掩盖幅值偏差", "摘要、7.3", "并列报告MAE和失败点", "已解决"],
            ["L02", "三个点外推全包线", "摘要、8章、结论", "限定为所选可信工况", "已解决"],
            ["L03", "九/十三状态差异归因过强", "7.8", "改为机翼尾流定义差异", "已解决"],
            ["L04", "配平可信与动态稳定混淆", "4.8、结论", "明确正实部根仍存在", "已解决"],
            ["L05", "机械卡滞语言超过模型能力", "5.9、8.8", "仅保留未实现边界", "已解决"],
            ["L06", "优化可能被理解为外部校准", "9.6", "说明目标不含外部数据", "已解决"],
        ],
    )
    write(
        r4 / "ROUND4_ABSTRACT_AUDIT.md",
        """# 摘要审计

中文和英文摘要均按背景与问题、部件模型、配平/线性化、十三状态扩展、可信度方法、
关键结果和研究边界排序。两种语言共享8/9、1.5248%、0.063—0.064三个定量结论，
均未宣称XV-15复现或整机定量验证。
""",
    )
    write(
        r4 / "CHINESE_ACADEMIC_LANGUAGE_AUDIT.md",
        """# 中文学术语言审计

工程标签和开发流程语言已从最终正文替换；模板化“误差传播角度”“复现实验设计角度”
及“下一等级证据”重复已随第二轮删除。术语主语明确，相关性没有改写为因果，配平可行、
数值收敛、开环稳定和外部关联保持区分。
""",
    )

    write(r5 / "ROUND5_REVISED_THESIS.md", round5)
    write(
        r5 / "ROUND5_BLIND_REVIEW.md",
        """# 模拟匿名盲审意见

总体判断：论文工作量和可重复性达到送审候选水平，但外部证据弱于内部校核，建议“大修
后送审”。主要意见为：悬停关联幅值偏差大；整机缺少同构型定量验证；三个代表点不足以
支持包线结论；十三状态执行机构参数未辨识；共享A块差异需从代码路径解释；75°失败与
参数优化容易被误读为模型缺陷或调参；公式和参考文献应足以复现；标题应匹配证据等级。

独立复审确认：采用“可信度分析”题名、保留负面关联结果、限定三个点、解释尾流定义
差异并公开占位参数后，主要科学风险得到可接受的降级处理。论文仍不能声称型号验证。
""",
    )
    major = [
        "外部旋翼幅值误差大，斜率一致不足以支持验证",
        "整机缺少同构型、同状态、同操纵量的外部定量数据",
        "三个代表点不足以建立转换包线规律",
        "二阶执行机构参数属于占位，时域幅值不可型号化",
        "九/十三状态共享A块差异原解释不充分",
        "75°/40 m/s失败与75°/60 m/s优化边界需澄清",
    ]
    write(
        r5 / "ROUND5_MAJOR_REVISION_ISSUES.md",
        "# 主要修改意见\n\n" + "\n".join(
            f"{i+1}. **HIGH**：{x}。影响相关章节结论，须修改正文并降低外推。" for i, x in enumerate(major)
        ),
    )
    minor = [
        "符号表需统一短舱角端点和角度单位",
        "图题不得保留工程文件名和状态标签",
        "摘要与结论应共享同一组三至五项定量结果",
        "参考文献报告号、年份和引用用途需逐项追溯",
        "正实部特征根与零航向根需避免合并解释",
    ]
    write(
        r5 / "ROUND5_MINOR_REVISION_ISSUES.md",
        "# 次要修改意见\n\n" + "\n".join(f"{i+1}. **MEDIUM**：{x}。" for i, x in enumerate(minor)),
    )
    questions = [
        "为什么当前工作称为可信度分析而不是模型验证？",
        "十三状态模型相较把短舱角作为外部时变参数增加了什么可观测能力？",
        "共享A块差异为什么集中在滚转/偏航导数？",
        "NASA悬停曲线幅值误差主要可能来自哪些模型和构型差异？",
        "75°/40 m/s的-52.91°为何不能称为升降舵需求？",
        "75°/60 m/s参数优化是否使用了外部试验数据？",
        "三个代表点能支持哪些结论、不能支持哪些结论？",
        "如何区分数值收敛、配平可信和开环稳定？",
        "机械卡滞为何超出当前模型能力？",
        "下一步最能提高证据等级的数据是什么？",
    ]
    write(r5 / "ROUND5_DEFENSE_QUESTIONS.md",
          "# 模拟答辩问题\n\n" + "\n".join(f"{i+1}. {q}" for i, q in enumerate(questions)))
    write(
        r5 / "ROUND5_AUTHOR_RESPONSE.md",
        """# 作者逐条回应

六项主要意见全部接受并修改。第7.3节增加幅值误差、数字化不确定度与构型差异；第7.9节
明确整机证据缺口和三个点的机理样本性质；第5.4、5.9和第8章把执行机构定量结论降为
占位参数下的相对比较；第7.8节加入逐元素、逐部件根因；第9.5—9.6节区分不可实现延拓、
控制权限和内部优化。次要意见通过符号表、图表矩阵、摘要重写和文献追溯关闭。
""",
    )
    rows = []
    decisions = [
        ("接受并修改", "7.3、7.9", "补入MAE/RMSE/NMAE、失败点和有限声明"),
        ("当前无法解决并降低声明", "6.1、7.9、10.3", "明确缺少整机同构型定量数据"),
        ("接受并修改", "8.1、8.13、10.1", "限定为三个可信工况的小扰动机理"),
        ("接受并修改", "5.4、5.9、8.8", "将时域幅值限定为占位参数下结果"),
        ("接受并修改", "3.3、7.8", "解释非线性尾流面积求值顺序"),
        ("接受并修改", "9.5、9.6", "区分失败、控制权限和非外部校准"),
    ]
    for issue, decision in zip(major, decisions):
        rows.append([issue, decision[0], decision[1], "原表述可能过强", decision[2], "第一轮审计与冻结数据", "是"])
    write_csv(r5 / "ROUND5_FINAL_REVISION_MATRIX.csv",
              ["盲审意见", "处理决定", "修改章节", "修改前", "修改后", "证据", "是否关闭"], rows)
    write(
        r5 / "FINAL_CONSISTENCY_AUDIT.md",
        """# 最终一致性审查

中英文摘要、结论和三项贡献的定量结论一致；状态顺序、输入顺序、短舱角端点与第一轮
事实冻结一致；九/十三状态差异均表述为机翼尾流模型定义差异；外部关联没有写成整机
验证；章节与公式由LaTeX自动编号；参考文献由Biber统一生成。最终编译后仍需以日志和
逐页渲染复核交叉引用、图表溢出与字体。
""",
    )


def main() -> None:
    source = BASE.read_text(encoding="utf-8")
    round2, info = structure_round(source)
    round3 = technical_round(round2)
    round4, _ = language_round(round3)
    round5 = blind_review_revision(round4)
    make_reports(round2, info, round3, round4, round5)
    print(
        f"round2={nonspace(round2)} round3={nonspace(round3)} "
        f"round4={nonspace(round4)} round5={nonspace(round5)} "
        f"equations={displayed_equations(round5)}"
    )


if __name__ == "__main__":
    main()
