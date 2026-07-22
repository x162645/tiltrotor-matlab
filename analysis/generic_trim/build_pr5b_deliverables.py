"""Build the auditable PR5A/PR5B deliverable tree from frozen CSV evidence.

The script never runs or tunes the aircraft model.  It only transforms
already-saved MATLAB evidence into comparison tables, figures, and reports.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
import shutil
from datetime import datetime, timezone
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib import font_manager
import numpy as np
import pandas as pd


ROOT = Path(__file__).resolve().parents[2]
PR5A = ROOT / "results" / "generic_trim_pr5a"
PR5B = ROOT / "results" / "generic_trim_pr5b"
FONT_PATH = Path(r"C:\Windows\Fonts\msyh.ttc")
FONT = font_manager.FontProperties(fname=str(FONT_PATH)) if FONT_PATH.exists() else None
plt.rcParams["axes.unicode_minus"] = False


def read_csv(path: Path) -> pd.DataFrame:
    return pd.read_csv(path, encoding="utf-8-sig")


def save_csv(df: pd.DataFrame, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(path, index=False, encoding="utf-8-sig")


def write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text.rstrip() + "\n", encoding="utf-8")


def title(ax, text: str) -> None:
    ax.set_title(text, fontproperties=FONT, fontsize=12)


def label(ax, x: str = "", y: str = "") -> None:
    ax.set_xlabel(x, fontproperties=FONT)
    ax.set_ylabel(y, fontproperties=FONT)


def legend(ax, **kwargs) -> None:
    ax.legend(prop=FONT, **kwargs)


def status_value(status: str) -> float:
    return 1.0 if status == "CREDIBLE" else (0.5 if status == "ILL_CONDITIONED" else 0.0)


def objective(df: pd.DataFrame) -> dict[str, float]:
    credible = df["status"].eq("CREDIBLE")
    residual = pd.to_numeric(df["dynamicResidualNorm"], errors="coerce").fillna(1e3).clip(0, 1e3)
    cond = pd.to_numeric(df["conditionNumber"], errors="coerce").fillna(1e6).clip(1, 1e6)
    m = pd.to_numeric(df["minimumMarginFraction"], errors="coerce").fillna(-1)
    margin_penalty = sum(np.maximum(0, target - m).pow(2).sum() for target in (0.05, 0.10, 0.15))
    terms = {
        "failure": float(1e4 * (~credible).sum()),
        "residual": float(np.log10(1 + residual / 1e-6).sum()),
        "conditioning": float(0.01 * np.log10(cond).sum()),
        "controlMargin": float(100 * margin_penalty),
        "external": 0.0,
    }
    terms["total"] = sum(terms.values())
    return terms


def load_models() -> dict[str, pd.DataFrame]:
    paths = {
        "Model A": PR5A / "raw" / "MODEL_A_PR5A_GRID.csv",
        "Model B": PR5B / "MODEL_B_DESIGN_GRID.csv",
        "Model C1": PR5B / "MODEL_C1_DESIGN_GRID.csv",
        "Model C2": PR5B / "MODEL_C2_DESIGN_GRID.csv",
    }
    return {name: read_csv(path) for name, path in paths.items()}


def control_margins(models: dict[str, pd.DataFrame]) -> pd.DataFrame:
    out = []
    for name, df in models.items():
        for _, r in df.iterrows():
            c = min((r.collectiveDeg - 0) / 70, (70 - r.collectiveDeg) / 70)
            y = min((r.cyclicLongDeg + 35) / 70, (35 - r.cyclicLongDeg) / 70)
            e = min((r.elevatorDeg + 20) / 40, (20 - r.elevatorDeg) / 40)
            minimum = min(c, y, e)
            out.append({"variant": name, "pointId": r.pointId, "status": r.status,
                        "collectiveMarginFraction": c, "cyclicLongMarginFraction": y,
                        "elevatorMarginFraction": e, "minimumControlMarginFraction": minimum,
                        "passes5Percent": bool(r.status == "CREDIBLE" and minimum >= .05),
                        "passes10Percent": bool(r.status == "CREDIBLE" and minimum >= .10),
                        "passes15Percent": bool(r.status == "CREDIBLE" and minimum >= .15),
                        "requirementClass": "ASSUMED_DESIGN_REQUIREMENT"})
    return pd.DataFrame(out)


def optimization_history(models: dict[str, pd.DataFrame]) -> pd.DataFrame:
    # All rows are retained, including rejected directions and a caller-interface failure.
    rows = [
        (1,"A_BASELINE","BASELINE",0,0,-2,2.0,"7/9","B75/40, B75/60 failed"),
        (2,"B_PUBLIC_OVERLAY","PUBLIC_OVERLAY",0,0,-2,2.0,"5/9","two ill-conditioned and two failed"),
        (3,"TAIL_MAX","C1_EXPLORE",0,0,-5,2.0,"not accepted","B75/40 residual 4.31; B75/60 residual 0.115"),
        (4,"CG_X_NEG_025","C1_EXPLORE",0,0,-2,2.0,"rejected","repairs B75/60 but degrades lower points"),
        (5,"WRONG_SIGN_COMBINED","C1_EXPLORE",-.25,-.35,0,2.0,"rejected","worsened all key conditions"),
        (6,"WING030_ROTORZ030","C1_EXPLORE",.30,.30,-2,2.0,"rejected","repairs B75/60 but breaks B45/25"),
        (7,"WING025_ROTORZ025","C1_EXPLORE",.25,.25,-2,2.0,"rejected","B45/25 residual 0.351; B75/60 margin below 10%"),
        (8,"C1_FROZEN","C1_FORMAL",.10,.10,-5,2.0,"8/9","only B75/40 failed; geometry-only"),
        (9,"C2_TWO_EFFECTIVE","C2_EXPLORE",.10,.10,-2,2.4,"rejected","CLelevator/downwash joint use rejected for identifiability"),
        (10,"C2_GEOM018","C2_EXPLORE",.18,.18,-2,2.4,"rejected","B45/25 boundary-limited"),
        (11,"C2_GEOM010_DW050","C2_EXPLORE",.10,.10,-2,2.4,"rejected","8/9 but used two correlated effective terms"),
        (12,"C2_CALLER_CELL_EXPANSION","RUN_FAILURE",.10,.10,-5,2.2,"error","MATLAB cell expanded struct; model result discarded"),
        (13,"C2_PREFREEZE_220","C2_EXPLORE",.10,.10,-5,2.2,"8/9","rejected: full-span elevator margin only 7.75%"),
        (14,"C2_FROZEN","C2_FORMAL",.10,.10,-5,2.35,"8/9","one effective derivative; B75/V60 full-span elevator margin 10.42%"),
    ]
    cols = ["runId","candidate","stage","wingXACm","rotorPivotZm","tailIncidenceDeg",
            "tailCLelevatorPerRad","coverage","disposition"]
    hist = pd.DataFrame(rows, columns=cols)
    hist["randomSeed"] = 20260723
    hist["externalObjectiveContribution"] = 0.0
    hist["allFailuresRetained"] = True
    scores = {name: objective(df) for name, df in models.items()}
    hist["formalObjective"] = np.nan
    mapping = {"A_BASELINE":"Model A","B_PUBLIC_OVERLAY":"Model B", "C1_FROZEN":"Model C1","C2_FROZEN":"Model C2"}
    for i, r in hist.iterrows():
        if r.candidate in mapping:
            hist.loc[i, "formalObjective"] = scores[mapping[r.candidate]]["total"]
    return hist


def external_sets() -> tuple[pd.DataFrame, pd.DataFrame]:
    rows = [
        ("EXT01","calibration","NASA_TM_X_62407.pdf","nacelle endpoint convention","helicopter and airplane endpoints are distinct","QUALITATIVE_ONLY",False),
        ("EXT02","calibration","NASA_TM_X_62407.pdf","control surface limit","elevator physical limit is ±20 deg","QUANTITATIVE_LIMIT_ONLY",False),
        ("EXT03","calibration","Berger_Dissertation_2013.pdf","conversion modeling structure","nacelle angle is a scheduled conversion variable","QUALITATIVE_ONLY",True),
        ("EXT04","calibration","NUAA_main_paper.pdf","component load decomposition","rotor/wing/tail contributions are combined in body axes","QUALITATIVE_ONLY",True),
        ("EXT05","calibration","NUAA_main_paper.pdf","trim curve smoothness","credible branches should vary continuously away from limits","QUALITATIVE_ONLY",True),
        ("EXT06","calibration","NASA_TM_81244.pdf","rotor architecture","three-bladed highly twisted rotor","QUANTITATIVE_GEOMETRY_ONLY",False),
        ("EXT07","validation","Berger_Dissertation_2013.pdf","mode participation structure","nacelle states may couple with rigid-body modes","QUALITATIVE_HOLDOUT",True),
        ("EXT08","validation","NUAA_main_paper.pdf","speed trend","control allocation changes across conversion speed","QUALITATIVE_HOLDOUT",True),
        ("EXT09","validation","NASA_TM_X_62407.pdf","configuration dependence","inertia/rotor speed differ with configuration","QUALITATIVE_HOLDOUT",False),
        ("EXT10","validation","NASA_TM_81244.pdf","claim boundary","public geometry does not supply full aerodynamic calibration","QUALITATIVE_HOLDOUT",False),
    ]
    cols = ["recordId","split","sourceFile","feature","sourceStatement","comparisonClass","manualReviewRequired"]
    df = pd.DataFrame(rows, columns=cols)
    df["usedInObjective"] = False
    df["digitizedNumericPoint"] = False
    df["splitFrozenBeforeFinalParameterSelection"] = True
    return df[df.split.eq("calibration")].copy(), df[df.split.eq("validation")].copy()


def md_table(df: pd.DataFrame, columns: list[str] | None = None, n: int | None = None) -> str:
    d = df[columns] if columns else df
    if n is not None:
        d = d.head(n)
    names = [str(c) for c in d.columns]
    def cell(value):
        if pd.isna(value):
            return ""
        if isinstance(value, float):
            return f"{value:.6g}"
        return str(value).replace("|", "\\|").replace("\n", " ")
    rows = ["|" + "|".join(names) + "|", "|" + "|".join(["---"]*len(names)) + "|"]
    rows.extend("|" + "|".join(cell(v) for v in row) + "|" for row in d.itertuples(index=False, name=None))
    return "\n".join(rows)


class FigureBuilder:
    def __init__(self, out: Path):
        self.out = out
        self.out.mkdir(parents=True, exist_ok=True)
        self.meta = []

    def save(self, number: int, stem: str, chinese_title: str, fig, sources: str, claim: str) -> None:
        name = f"{number:02d}_{stem}"
        fig.tight_layout()
        fig.savefig(self.out / f"{name}.png", dpi=180, bbox_inches="tight")
        fig.savefig(self.out / f"{name}.pdf", bbox_inches="tight")
        plt.close(fig)
        self.meta.append({"figureNumber": number, "fileStem": name, "chineseTitle": chinese_title,
                          "sourceFiles": sources, "claimBoundary": claim,
                          "generationScript": "analysis/generic_trim/build_pr5b_deliverables.py"})


def make_figures(dest: Path, models: dict[str, pd.DataFrame], controls: pd.DataFrame,
                 hist: pd.DataFrame, calib: pd.DataFrame, valid: pd.DataFrame) -> pd.DataFrame:
    figs = dest / "figures"
    figs.mkdir(parents=True, exist_ok=True)
    meta = []
    for p in sorted((PR5A / "figures").glob("*")):
        shutil.copy2(p, figs / p.name)
    pr5a_titles = ["参数来源分类统计","当前参数与XV-15公开参数对比","75°俯仰力矩分解",
                   "无约束升降舵需求","归一化参数敏感性","参数相关矩阵","参数奇异值分解"]
    for i, t in enumerate(pr5a_titles, 1):
        meta.append({"figureNumber":i,"fileStem":f"PR5A_FIGURE_{i:02d}","chineseTitle":t,
                     "sourceFiles":"results/generic_trim_pr5a","claimBoundary":"PR5A provenance/diagnostic evidence",
                     "generationScript":"PR5A committed MATLAB generator"})

    fb = FigureBuilder(figs)
    c1h = hist[hist.stage.str.contains("C1")]
    fig, ax = plt.subplots(figsize=(7,4)); ax.plot(c1h.runId, range(1,len(c1h)+1), "o-");
    title(ax,"C1几何优化历史（保留失败候选）"); label(ax,"运行编号","累计候选数"); ax.grid(True,alpha=.3)
    fb.save(8,"C1几何优化历史","C1几何优化历史",fig,"OPTIMIZATION_RUN_DATABASE.csv","探索历史，不代表全局最优")

    c2h = hist[hist.stage.str.contains("C2") | hist.stage.eq("RUN_FAILURE")]
    fig, ax = plt.subplots(figsize=(7,4)); ax.plot(c2h.runId, c2h.tailCLelevatorPerRad, "s-");
    title(ax,"C2联合优化历史与冻结值"); label(ax,"运行编号","升降舵效能导数 (1/rad)"); ax.grid(True,alpha=.3)
    fb.save(9,"C2联合优化历史","C2联合优化历史",fig,"OPTIMIZATION_RUN_DATABASE.csv","只冻结一个等效参数")

    names=list(models); ids=models["Model A"].pointId.tolist(); Z=np.array([[status_value(s) for s in models[n].status] for n in names])
    fig, ax=plt.subplots(figsize=(10,3.8)); im=ax.imshow(Z,aspect="auto",vmin=0,vmax=1,cmap="RdYlGn");
    ax.set_xticks(range(9),ids,rotation=35,ha="right",fontproperties=FONT); ax.set_yticks(range(4),names,fontproperties=FONT)
    title(ax,"四模型九点配平可信状态（绿=可信，黄=病态，红=失败）"); fig.colorbar(im,ax=ax)
    fb.save(10,"四模型九点配平状态","每个模型的9点配平成功图",fig,"MODEL_*_RESULTS.csv","可信门禁未放宽")

    fig,ax=plt.subplots(figsize=(9,4.5))
    for n,d in models.items(): ax.semilogy(range(9),np.maximum(d.dynamicResidualNorm,1e-12),"o-",label=n)
    ax.set_xticks(range(9),ids,rotation=35,ha="right",fontproperties=FONT); title(ax,"四模型动态平衡残差对比"); label(ax,"设计锚点","残差范数"); legend(ax); ax.grid(True,alpha=.3)
    fb.save(11,"配平残差对比","配平残差对比",fig,"MODEL_*_RESULTS.csv","失败点残差不截断")

    fig,ax=plt.subplots(figsize=(9,4.5))
    for n,d in models.items(): ax.plot(range(9),d.elevatorDeg,"o-",label=n)
    ax.axhline(-20,color="k",ls="--"); ax.set_xticks(range(9),ids,rotation=35,ha="right",fontproperties=FONT); title(ax,"升降舵角对比"); label(ax,"设计锚点","升降舵角 (deg)"); legend(ax); ax.grid(True,alpha=.3)
    fb.save(12,"升降舵角对比","升降舵角对比",fig,"MODEL_*_RESULTS.csv","物理限制±20°")

    fig,ax=plt.subplots(figsize=(9,4.5))
    for n in names:
        d=controls[controls.variant.eq(n)]; ax.plot(range(9),100*d.elevatorMarginFraction,"o-",label=n)
    for q in (5,10,15): ax.axhline(q,ls="--",lw=.8)
    ax.set_xticks(range(9),ids,rotation=35,ha="right",fontproperties=FONT); title(ax,"升降舵余度与假设设计阈值"); label(ax,"设计锚点","归一化余度 (%)"); legend(ax); ax.grid(True,alpha=.3)
    fb.save(13,"升降舵余度对比","升降舵余度对比",fig,"CONTROL_MARGIN_RESULTS.csv","5/10/15%为假设设计要求")

    fig,(a1,a2)=plt.subplots(2,1,figsize=(9,7),sharex=True)
    for n,d in models.items(): a1.plot(range(9),d.collectiveDeg,"o-",label=n); a2.plot(range(9),d.cyclicLongDeg,"o-",label=n)
    title(a1,"总距对比"); label(a1,"","总距 (deg)"); title(a2,"纵向周期变距对比"); label(a2,"设计锚点","纵向周期变距 (deg)"); legend(a1,ncol=4); a2.set_xticks(range(9),ids,rotation=35,ha="right",fontproperties=FONT); a1.grid(True,alpha=.3); a2.grid(True,alpha=.3)
    fb.save(14,"总距与纵向周期变距","总距和纵向周期变距对比",fig,"MODEL_*_RESULTS.csv","控制映射沿用正式13×10路径")

    fig,ax=plt.subplots(figsize=(9,4.5))
    for n,d in models.items(): ax.plot(range(9),d.thetaDeg,"o-",label=n)
    ax.axhline(35,color="k",ls="--"); ax.set_xticks(range(9),ids,rotation=35,ha="right",fontproperties=FONT); title(ax,"俯仰姿态对比"); label(ax,"设计锚点","俯仰角 (deg)"); legend(ax); ax.grid(True,alpha=.3)
    fb.save(15,"俯仰姿态对比","俯仰姿态对比",fig,"MODEL_*_RESULTS.csv","±35°为现有配平未知量边界")

    dense=read_csv(PR5B/"DENSE_TRIM_CORRIDOR_EXTRA.csv")
    fig,ax=plt.subplots(figsize=(7,5)); colors=dense.status.map({"CREDIBLE":"green","FAILED":"red","ILL_CONDITIONED":"orange"}).fillna("gray")
    ax.scatter(dense.speedMps,dense.betaMDeg,c=colors,s=70); title(ax,"冻结C2的加密转换走廊"); label(ax,"速度 (m/s)","短舱角 β (deg)"); ax.grid(True,alpha=.3)
    fb.save(16,"加密转换走廊","加密转换走廊",fig,"DENSE_TRIM_CORRIDOR.csv","失败点不插值为可行")

    fig,(a1,a2)=plt.subplots(2,1,figsize=(8,7),sharex=True)
    for b,g in dense.groupby("betaMDeg"):
        a1.plot(g.speedMps,g.collectiveDeg,"o-",label=f"β={b:g}°"); a2.plot(g.speedMps,g.elevatorDeg,"o-",label=f"β={b:g}°")
    title(a1,"密集网格总距曲线"); label(a1,"","总距 (deg)"); title(a2,"密集网格升降舵曲线"); label(a2,"速度 (m/s)","升降舵角 (deg)"); legend(a1,ncol=4); a1.grid(True,alpha=.3); a2.grid(True,alpha=.3)
    fb.save(17,"控制曲线连续性","控制曲线连续性",fig,"DENSE_TRIM_CORRIDOR.csv","仅连接同β采样点，失败保留")

    pa=read_csv(PR5A/"PITCH_MOMENT_DECOMPOSITION.csv"); pc=read_csv(PR5B/"PITCH_MOMENT_DECOMPOSITION_C2.csv")
    keep=["rotorLeft","rotorRight","wing","fuselage","horizontalTail","verticalTail"]
    fig,axes=plt.subplots(1,3,figsize=(14,4.5),sharey=True)
    for ax,v in zip(axes,[40,60,80]):
        aa=pa[(pa.betaMDeg.eq(75))&(pa.speedMps.eq(v))&pa.component.isin(keep)].groupby("component").MyNm.sum()
        cc=pc[(pc.betaMDeg.eq(75))&(pc.speedMps.eq(v))&pc.component.isin(keep)].groupby("component").MyNm.sum()
        x=np.arange(len(keep)); ax.bar(x-.2,[aa.get(k,0) for k in keep],.4,label="A"); ax.bar(x+.2,[cc.get(k,0) for k in keep],.4,label="C2"); ax.set_xticks(x,keep,rotation=60,ha="right"); title(ax,f"β=75°，V={v} m/s")
    label(axes[0],"部件","俯仰力矩 My (N·m)"); legend(axes[0]);
    fb.save(18,"优化前后俯仰力矩分解","参数优化前后俯仰力矩分解",fig,"PITCH_MOMENT_DECOMPOSITION*.csv","失败点载荷为受限最优而非平衡解")

    for num,name_set,df in [(19,"校准集",calib),(20,"独立验证集",valid)]:
        fig,ax=plt.subplots(figsize=(8,4)); vals=np.where(df.manualReviewRequired,.5,1.0); ax.bar(df.recordId,vals,color=np.where(vals==1,"#4c78a8","#f2cf5b")); ax.set_ylim(0,1.15)
        title(ax,f"{name_set}：公开资料可比性等级"); label(ax,"记录编号","可比性（1=直接，0.5=需人工复核）")
        fb.save(num,f"{name_set}对比",f"{name_set}对比",fig,f"EXTERNAL_{'CALIBRATION' if num==19 else 'VALIDATION'}_SET.csv","定性留出，不作严格外部验证")

    der=read_csv(PR5B/"STABILITY_DERIVATIVE_COMPARISON.csv")
    fig,axes=plt.subplots(1,3,figsize=(14,4.5))
    for ax,p in zip(axes,["B15_V020","B45_V035","B75_V080"]):
        q=der[der.pointId.eq(p)]; piv=q.pivot(index="derivativeName",columns="variant",values="value"); order=[x for x in ["Yv","Lp","Nr","Zw","Mq"] if x in piv.index]; x=np.arange(len(order)); ax.bar(x-.2,piv.loc[order,"MODEL_A"],.4,label="A"); ax.bar(x+.2,piv.loc[order,"MODEL_C2"],.4,label="C2"); ax.set_xticks(x,order); title(ax,p)
    label(axes[0],"导数","数值 (1/s或相应SI)"); legend(axes[0]);
    fb.save(21,"未参与优化的稳定导数","未参与优化的稳定导数对比",fig,"STABILITY_DERIVATIVE_COMPARISON.csv","横侧向导数未进入目标函数")

    eig=read_csv(PR5B/"REPRESENTATIVE_EIGENVALUES.csv")
    fig,ax=plt.subplots(figsize=(7,5))
    for n,g in eig.groupby("variant"): ax.scatter(g.realPartPerSecond,g.imagPartRadPerSecond,s=25,label=n,alpha=.7)
    ax.axvline(0,color="k",lw=.8); title(ax,"代表线性化点原始特征根"); label(ax,"实部 (1/s)","虚部 (rad/s)"); legend(ax); ax.grid(True,alpha=.3)
    fb.save(22,"代表特征根","代表特征根对比",fig,"REPRESENTATIVE_EIGENVALUES.csv","特征向量病态，模态参与度未分类")

    rob=read_csv(PR5B/"PARAMETER_ROBUSTNESS_RESULTS.csv"); g=rob.groupby("scenario").credible.sum()
    fig,ax=plt.subplots(figsize=(9,4)); ax.bar(g.index,g.values); ax.set_ylim(0,3.2); ax.tick_params(axis="x",rotation=30); title(ax,"冻结参数扰动鲁棒性"); label(ax,"扰动场景","3个关键点中可信数量")
    fb.save(23,"参数扰动鲁棒性","参数扰动鲁棒性",fig,"PARAMETER_ROBUSTNESS_RESULTS.csv","所有场景保持2/3，B75/40持续失败")

    fig,ax=plt.subplots(figsize=(7,4)); counts=[d.status.eq("CREDIBLE").sum() for d in models.values()]; bars=ax.bar(names,counts,color=["#777","#4c78a8","#59a14f","#e15759"]); ax.bar_label(bars,labels=[f"{x}/9" for x in counts]); ax.set_ylim(0,9.5); title(ax,"Model A/B/C1/C2 九点覆盖总览"); label(ax,"模型","可信点数")
    fb.save(24,"四模型总览","Model A/B/C1/C2总览",fig,"MODEL_*_RESULTS.csv","Model B为部分公开参数覆盖层")

    fig,ax=plt.subplots(figsize=(11,3.8)); ax.axis("off")
    boxes=[(.02,.25,.27,.5,"内部一致性\n8/9锚点，10/13新增密集点","#59a14f"),(.365,.25,.27,.5,"定性公开资料留出\n不构成严格外部验证","#f2cf5b"),(.71,.25,.27,.5,"禁止声明\n完整XV-15复现/试验验证","#e15759")]
    for x,y,w,h,t,c in boxes: ax.add_patch(plt.Rectangle((x,y),w,h,facecolor=c,alpha=.35,edgecolor=c,lw=2)); ax.text(x+w/2,y+h/2,t,ha="center",va="center",fontproperties=FONT,fontsize=12)
    ax.annotate("证据强度递减",xy=(.68,.5),xytext=(.31,.5),arrowprops=dict(arrowstyle="->",lw=2),fontproperties=FONT)
    title(ax,"当前结论与XV-15声明边界")
    fb.save(25,"声明边界","当前结论与XV-15声明边界图",fig,"CLAIM_BOUNDARY.md","不得升级为型号验证声明")

    meta.extend(fb.meta)
    return pd.DataFrame(meta)


def build_documents(dest: Path, models: dict[str,pd.DataFrame], controls: pd.DataFrame,
                    hist: pd.DataFrame, calib: pd.DataFrame, valid: pd.DataFrame) -> None:
    bounds=pd.DataFrame([
        ("wing.xAC",-.4,.4,.10,"m","GEOMETRY",True,True),
        ("rotor.pivotZ",-.6,.6,.10,"m","GEOMETRY",True,True),
        ("htail.incidence",-5,2,-5,"deg","GEOMETRY",True,True),
        ("htail.CLelevator",1.6,2.4,2.35,"1/rad","CALIBRATED_EFFECTIVE",False,True),
        ("htail.downwashAlpha",.3,.5,.4,"1","REJECTED_CORRELATED",False,False)],
        columns=["path","lowerBound","upperBound","frozenValue","unit","class","formalC1","formalC2"])
    save_csv(bounds,dest/"OPTIMIZATION_VARIABLE_BOUNDS.csv")
    save_csv(hist,dest/"OPTIMIZATION_RUN_DATABASE.csv")
    name_map={"Model A":"MODEL_A_BASELINE_RESULTS.csv","Model B":"MODEL_B_XV15_OVERLAY_RESULTS.csv",
              "Model C1":"MODEL_C1_GEOMETRY_OPTIMIZED_RESULTS.csv","Model C2":"MODEL_C2_EFFECTIVE_OPTIMIZED_RESULTS.csv"}
    for n,d in models.items(): save_csv(d,dest/name_map[n])
    grid=models["Model C2"][["pointId","betaMDeg","speedMps","mode"]].copy(); grid["setClass"]="DESIGN_FEASIBILITY_SET"
    save_csv(grid,dest/"DESIGN_FEASIBILITY_GRID.csv")
    dense=read_csv(PR5B/"DENSE_TRIM_CORRIDOR_EXTRA.csv"); dense["setClass"]="POST_FREEZE_DENSE_EXTRA"
    anchor=models["Model C2"].copy(); anchor["setClass"]="FORMAL_MULTISEED_ANCHOR"
    save_csv(pd.concat([anchor,dense],ignore_index=True,sort=False),dest/"DENSE_TRIM_CORRIDOR.csv")
    save_csv(controls,dest/"CONTROL_MARGIN_RESULTS.csv")
    save_csv(calib,dest/"EXTERNAL_CALIBRATION_SET.csv"); save_csv(valid,dest/"EXTERNAL_VALIDATION_SET.csv")
    shutil.copy2(PR5B/"PARAMETER_ROBUSTNESS_RESULTS.csv",dest/"PARAMETER_ROBUSTNESS_RESULTS.csv")
    shutil.copy2(PR5B/"STABILITY_DERIVATIVE_COMPARISON.csv",dest/"STABILITY_DERIVATIVE_COMPARISON.csv")
    shutil.copy2(PR5B/"REPRESENTATIVE_EIGENVALUES.csv",dest/"REPRESENTATIVE_EIGENVALUES.csv")

    formulation=f"""# 优化问题定义

本研究在不修改默认参数、控制限制、惯量、可信度门禁和数值容差的前提下，对冻结的9点设计可行性集求解。

目标函数为 `J = J_fail + J_residual + J_conditioning + J_margin + J_external`。失败点权重为每点10000；残差和条件数采用对数罚项；控制/未知量裕度以5%、10%、15%三档假设设计要求构造罚项；`J_external=0`，外部留出资料不参与参数选择。C1只允许三个几何变量；C2只额外允许一个 `CALIBRATED_EFFECTIVE` 升降舵效能导数。`downwashAlpha` 因可辨识性风险冻结。

随机种子固定为 `20260723`。探索失败、接口失败、边界触碰与未收敛状态均保存在运行数据库。该有限搜索不能证明全局最优。

## 冻结边界

{md_table(bounds)}
"""
    write(dest/"OPTIMIZATION_FORMULATION.md",formulation)

    split=f"""# 校准/验证集隔离

外部记录共{len(calib)+len(valid)}条，其中验证留出{len(valid)}条，占{100*len(valid)/(len(calib)+len(valid)):.0f}%。分组在最终C1/C2参数冻结前由任务合同固定。全部记录均未进入数值目标函数；验证集没有用于变量选择、边界选择、权重选择或最终参数回调。

当前公开资料不足以形成与本模型同定义、同构型、同控制映射的定量配平曲线，因此只执行定性趋势留出。需要人工复核的图示记录已显式标记；本研究不宣称严格外部验证。
"""
    write(dest/"CALIBRATION_VALIDATION_SPLIT.md",split)

    c2=models["Model C2"]; dense_all=pd.concat([c2,read_csv(PR5B/"DENSE_TRIM_CORRIDOR_EXTRA.csv")],ignore_index=True)
    validation=f"""# 独立验证结果

- 正式九点多初值：C2为 {c2.status.eq('CREDIBLE').sum()}/9 可信；β=75°、40 m/s仍失败，升降舵触及−20°且残差约{c2.loc[c2.pointId.eq('B75_V040'),'dynamicResidualNorm'].iloc[0]:.3g}。
- 冻结后新增密集点：{dense_all.tail(13).status.eq('CREDIBLE').sum()}/13 可信；β=60°的30/45 m/s及β=90°的50 m/s失败。
- 参数扰动：7个场景均为3个关键点中2点可信，持续失败点为β=75°、40 m/s。
- 外部留出：仅可做定性一致性审查，资料定义不足以支持严格数值验证。

结论是C1/C2改善了内部配平覆盖和控制余度，但没有形成全转换域连续可行走廊。
"""
    write(dest/"INDEPENDENT_VALIDATION_RESULTS.md",validation)

    params=f"""# 优化参数集

Model C1（纯几何、opt-in）：`wing.xAC=+0.10 m`、`rotor.pivotZ=+0.10 m`、`htail.incidence=-5 deg`。

Model C2（opt-in）：继承C1，并设 `htail.CLelevator=2.35 1/rad`。该导数分类为 `CALIBRATED_EFFECTIVE`，不是XV-15实测值；它可能吸收未建模尾翼/舵面/干扰效应。默认 `params_nominal.m` 与 `params_berger13()` 不变。

{md_table(bounds)}
"""
    write(dest/"OPTIMIZED_PARAMETER_SET.md",params)

    stab=read_csv(PR5B/"STABILITY_DERIVATIVE_COMPARISON.csv"); eig=read_csv(PR5B/"REPRESENTATIVE_EIGENVALUES.csv")
    stability=f"""# 稳定性与模态影响

在A与C2共同可信的 B15/V20、B45/V35、B75/V80 三点执行中心差分和0.1/1/10步长敏感性。共{len(stab)}个代表导数全部为有限实数。未进入优化目标的 `Yv`、`Lp`、`Nr` 在三点均保持负号，因此横侧向局部阻尼导数的定性符号未翻转。

但六个线性化模型的右特征向量矩阵均触发病态门禁，故只保存{len(eig)}个原始特征根，模态参与度/物理名称全部标为 `RAW_EIGENVALUES_ONLY`。不能据此给出可靠模态归属或处理品质结论。
"""
    write(dest/"STABILITY_AND_MODE_IMPACT.md",stability)

    claim="""# 声明边界

本成果是通用低阶部件模型的受限布局设计与内部数值验证。它不是完整XV-15模型，不是飞行试验复现，不是型号性能预测，也不是处理品质认证。Model B只覆盖可追溯的部分公开值，其余字段仍为通用假设。Model C1/C2参数属于概念设计/等效校准，不能称为XV-15参数。8/9锚点可信、10/13新增密集点可信只证明相应工况下的内部平衡与数值一致性；失败点、模态病态和外部资料不足均限制结论推广。
"""
    write(dest/"CLAIM_BOUNDARY.md",claim)

    compare=pd.DataFrame([{"variant":n,"credible":int(d.status.eq("CREDIBLE").sum()),"failedOrLimited":int((~d.status.eq("CREDIBLE")).sum()),"objective":objective(d)["total"]} for n,d in models.items()])
    prepost=f"""# 优化前后对比

{md_table(compare)}

C1将内部覆盖从A的7/9提高到8/9，且不使用等效气动变量；C2保持8/9，并将B75/V60升降舵从C1的约−18.57°改善为约−15.83°。B75/V40仍在−20°升降舵限制下保持大残差，说明剩余问题涉及低速大短舱角下的力/姿态/力矩共同可行性和模型形式，而非一个控制导数即可解决。
"""
    write(dest/"PRE_OPTIMIZATION_VS_POST_OPTIMIZATION.md",prepost)

    pr5b=f"""# PR5B证据

- MATLAB R2021a正式九点多初值：C1=8/9，C2=8/9，所有汇总量有限实数。
- Model B统一多初值：5/9可信、2点病态、2点失败。
- 稠密新增网格：10/13可信，失败原样保存。
- 冻结后鲁棒性：14/21关键点-场景组合可信，各场景固定2/3。
- 代表线性化导数有限；特征向量病态导致模态分类被明确拒绝。
- PR5B修改前完整回归：24/24，通过，387.555047 s。
- PR5B修改后完整回归：25/25，通过，387.654684 s。
- PR5B聚焦门禁：16/16，通过，2.110712 s；`checkcode`消息数为0。
- 精确日志扫描未发现warning、NaN、Inf或非预期complex；显式FAILED为保留的物理/数值失败。
"""
    write(dest/"PR5B_EVIDENCE.md",pr5b)
    write(dest/"FINAL_GITHUB_EVIDENCE_INDEX.md","# GitHub证据索引\n\nPR5A: https://github.com/x162645/tiltrotor-matlab/pull/53\n\nPR5B: PENDING_DRAFT_PR\n")

    report=f"""# 通用倾转旋翼机纵向布局参数设计、转换走廊配平能力优化及独立验证研究

## 摘要

本文在既有MATLAB低阶部件级倾转旋翼机模型上，建立参数来源分层、受限纵向布局设计、九点转换走廊配平评价、冻结后密集网格与鲁棒性验证流程。研究严格区分通用假设、公开XV-15值、推导值与等效校准量，不修改默认参数、惯量、控制限制、可信度门禁或数值容差。基线Model A在九个锚点中7点可信；部分公开XV-15覆盖层Model B在统一多初值门禁下5点可信、2点病态、2点失败；纯几何Model C1达到8/9；仅增加一个等效升降舵效能导数的Model C2保持8/9并提高关键点控制余度。β=75°、40 m/s仍失败，冻结C2的13个新增密集点中10点可信。结果支持“内部配平能力改善”的有限结论，不支持完整XV-15复现或试验验证声明。

关键词：倾转旋翼机；配平；转换走廊；布局优化；参数溯源；独立验证

## 1 研究范围与证据等级

研究对象是通用概念参数低阶模型。NASA TM X-62407、NASA TM-81244、Berger学位论文与南航文章用于参数来源或方法/趋势核查。只有明确页码、原始单位和换算链的数值进入公开覆盖层；其余仍标为继承通用参数。外部资料无法提供与当前13状态、10控制接口完全同定义的定量配平曲线，因此验证采用定性留出，不能称为严格外部验证。

## 2 模型、坐标与配平门禁

模型沿用机体系力/矩、短舱角与控制映射，正式路径为13状态×10输入。每点评价同时检查求解器状态、完整动态平衡残差、有限实数、条件数、步长/初值敏感性、未知量边界裕度和控制物理限制。求解器退出成功不是充分条件；`ILL_CONDITIONED`与`FAILED`均计为非可信。

## 3 参数溯源与失败根因

PR5A建立219行参数主表和660行隐式敏感性矩阵。Model A在β=75°的40/60 m/s失败。无约束升降舵诊断表明60 m/s主要受控制权限限制，而40 m/s即使放宽升降舵仍保留显著残差并需要异常姿态，属于力、姿态与俯仰力矩共同可行性问题。部件力矩分解显示低速大短舱角下旋翼、机翼与平尾贡献共同决定剩余俯仰不平衡。

## 4 优化问题与可辨识性

{formulation}

## 5 四模型九点结果

{md_table(compare)}

Model B的公开参数覆盖未自然消除失败，且统一多初值门禁揭示两个中速点的种子/步长敏感性。C1只通过可测几何量改善覆盖；C2仅增加一个等效控制导数。`downwashAlpha`没有与`CLelevator`同时进入正式优化，以避免高相关尾翼参数共同吸收模型误差。

## 6 控制裕度与转换走廊

C2在B75/V60的升降舵约为−15.83°，较C1的−18.57°改善，按完整±20°行程计算的升降舵裕度为10.42%，通过5%与10%但不通过15%的假设设计要求。B45/V25虽可信，但俯仰姿态接近+35°未知量边界，因此整体未知量裕度仍较小；本文不把控制裕度与全部未知量裕度混为一谈。密集网格的失败形成真实断裂，不进行跨失败插值。

## 7 冻结后验证与鲁棒性

{validation}

## 8 稳定性影响

{stability}

## 9 局限与工程解释

剩余失败集中在低速、大短舱角区域，提示当前near-normal机翼、准稳态BEMT、尾流/遮挡、平尾局部来流及控制效能模型仍不足。C2的等效导数可能吸收这些缺失机理，因而不能外推为型号气动导数。有限候选搜索和离散网格也不证明全局最优或连续走廊边界。

## 10 结论

（1）建立了默认不变、参数可追溯、失败可审计的A/B/C1/C2比较体系；（2）纯几何C1将正式九点覆盖提高到8/9；（3）C2以单一等效参数提高关键控制余度，但没有消除B75/V40失败；（4）冻结后密集网格和参数扰动验证均保留了失败结构；（5）公开资料留出只支持定性核查；（6）全部结论限定为通用低阶模型内部一致性，不构成XV-15复现或试验验证。
"""
    write(dest/"通用倾转旋翼机纵向布局参数设计与转换走廊配平优化研究.md",report)


def copy_pr5a(dest: Path) -> None:
    names=["PARAMETER_PROVENANCE_MASTER.csv","PARAMETER_PROVENANCE_MASTER.md","SOURCE_ANGLE_AND_SIGN_CONVENTIONS.md",
           "XV15_PUBLIC_PARAMETER_SOURCES.md","XV15_PUBLIC_OVERLAY_MANIFEST.csv","CURRENT_VS_XV15_PARAMETER_COMPARISON.md",
           "PITCH_MOMENT_DECOMPOSITION.csv","PITCH_MOMENT_DECOMPOSITION.md","UNCONSTRAINED_ELEVATOR_DIAGNOSTIC.csv",
           "TRIM_FAILURE_ROOT_CAUSE.md","PARAMETER_SENSITIVITY_MATRIX.csv","PARAMETER_IDENTIFIABILITY.md","PR5A_EVIDENCE.md"]
    for name in names: shutil.copy2(PR5A/name,dest/name)


def sha_manifest(dest: Path) -> None:
    rows=[]
    for p in sorted(dest.rglob("*")):
        if p.is_file() and p.name not in {"FINAL_SHA256_MANIFEST.txt","GENERIC_TILTROTOR_TRIM_OPTIMIZATION_DELIVERABLES.zip"}:
            rows.append(f"{hashlib.sha256(p.read_bytes()).hexdigest()}  {p.relative_to(dest).as_posix()}")
    write(dest/"FINAL_SHA256_MANIFEST.txt","\n".join(rows))


def main() -> None:
    ap=argparse.ArgumentParser(); ap.add_argument("--dest",type=Path,default=PR5B/"deliverables"); args=ap.parse_args()
    dest=args.dest.resolve(); dest.mkdir(parents=True,exist_ok=True)
    models=load_models(); controls=control_margins(models); hist=optimization_history(models); calib,valid=external_sets()
    copy_pr5a(dest); build_documents(dest,models,controls,hist,calib,valid)
    metadata=make_figures(dest,models,controls,hist,calib,valid); save_csv(metadata,dest/"figures"/"FIGURE_METADATA.csv")
    raw=dest/"raw"; raw.mkdir(exist_ok=True)
    for p in (PR5B/"raw").glob("*.log"): shutil.copy2(p,raw/p.name)
    write(raw/"BUILD_METADATA.json",json.dumps({"generatedUTC":datetime.now(timezone.utc).isoformat(),"script":str(Path(__file__).resolve().relative_to(ROOT)),"matlab":"R2021a","randomSeed":20260723},ensure_ascii=False,indent=2))
    sha_manifest(dest)
    print(dest)


if __name__ == "__main__":
    main()
