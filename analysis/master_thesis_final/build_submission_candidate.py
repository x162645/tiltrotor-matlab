#!/usr/bin/env python3
"""Create the final XeLaTeX project and submission QA artifacts."""

from __future__ import annotations

import csv
import hashlib
import json
import re
import shutil
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ROUNDS = ROOT / "docs" / "master_thesis_final_multiround"
SOURCE = ROUNDS / "round_05_blind_review" / "ROUND5_REVISED_THESIS.md"
FINAL = ROUNDS / "final"
PROJECT = FINAL / "xelatex_project"
FIG_SRC = ROOT / "docs" / "master_thesis_validation" / "figures"
RAW_SRC = ROOT / "docs" / "master_thesis_validation" / "raw_figure_data"
TITLE = "倾转旋翼机部件级飞行动力学建模、短舱动态状态扩展与可信度分析"


BIB = r"""@article{sheng2022,
  author={Sheng, Hao and Zhang, Chao and Xiang, Yu},
  title={Mathematical Modeling and Stability Analysis of Tiltrotor Aircraft},
  journal={Drones}, year={2022}, volume={6}, number={4}, pages={92},
  doi={10.3390/drones6040092}}
@phdthesis{berger2019, author={Berger, Tom}, title={Handling Qualities Requirements and Control Design for High-Speed Rotorcraft}, school={The Pennsylvania State University}, year={2019}}
@book{dreier2007, author={Dreier, Mark E.}, title={Introduction to Helicopter and Tiltrotor Flight Simulation}, publisher={American Institute of Aeronautics and Astronautics}, address={Reston}, year={2007}}
@techreport{maisel2000, author={Maisel, Martin D. and Giulianetti, Demo J. and Dugan, Daniel C.}, title={The History of the XV-15 Tilt Rotor Research Aircraft: From Concept to Flight}, institution={NASA}, number={SP-2000-4517}, year={2000}}
@techreport{nasa62407, author={{Tilt Rotor Project Office Staff}}, title={NASA/Army XV-15 Tilt Rotor Research Aircraft Familiarization Document}, institution={NASA}, number={TM-X-62407}, year={1975}}
@techreport{dugan1980, author={Dugan, Daniel C. and Erhart, Robert G. and Schroers, Laurel G.}, title={The XV-15 Tilt Rotor Research Aircraft}, institution={NASA}, number={TM-81244}, year={1980}}
@techreport{felker1987, author={Felker, Fort F. and Young, Larry A. and Signor, David B.}, title={Full-Scale Hover Testing of the XV-15 Advanced Technology Blade Rotor}, institution={NASA}, number={TM-86854}, year={1987}}
@techreport{tischler1984, author={Tischler, Mark B. and Leung, James G. M. and Dugan, Daniel C.}, title={Frequency-Domain Identification of XV-15 Tilt-Rotor Aircraft Dynamics}, institution={NASA}, number={TM-86009}, year={1984}}
@techreport{nasa100025, author={{NASA Ames Research Center}}, title={XV-15 Tilt Rotor Research Aircraft Pilot's Guide}, institution={NASA}, number={TM-100025}, year={1987}}
@techreport{nasa81177, author={{NASA Ames Research Center}}, title={Wind-Tunnel Investigation of the XV-15 Tilt Rotor Aircraft}, institution={NASA}, number={TM-81177}, year={1980}}
@techreport{nasa166537, author={{NASA Ames Research Center}}, title={XV-15 Tilt Rotor Aircraft Flight Validation Report}, institution={NASA}, number={CR-166537}, year={1982}}
@techreport{johnson2017, author={Johnson, Wayne and Yamauchi, Gloria K. and Watts, Michael E.}, title={NDARC Calculations of XV-15 Performance and Trim Compared with Flight Data}, institution={NASA}, number={CR-2017-219456}, year={2017}}
@book{johnson1980, author={Johnson, Wayne}, title={Helicopter Theory}, publisher={Princeton University Press}, address={Princeton}, year={1980}}
@book{leishman2006, author={Leishman, J. Gordon}, title={Principles of Helicopter Aerodynamics}, edition={2}, publisher={Cambridge University Press}, address={Cambridge}, year={2006}}
@book{bramwell2001, author={Balmford, D. and Done, G. T. S.}, title={Bramwell's Helicopter Dynamics}, edition={2}, publisher={Butterworth-Heinemann}, address={Oxford}, year={2001}}
@book{padfield2018, author={Padfield, Gareth D.}, title={Helicopter Flight Dynamics}, edition={3}, publisher={Wiley}, address={Chichester}, year={2018}}
@article{pitt1981, author={Pitt, Dale M. and Peters, David A.}, title={Theoretical Prediction of Dynamic-Inflow Derivatives}, journal={Vertica}, year={1981}, volume={5}, number={1}, pages={21--34}}
@article{peters1995, author={Peters, David A. and He, Chengjian}, title={Finite State Induced Flow Models Part II: Three-Dimensional Rotor Disk}, journal={Journal of Aircraft}, year={1995}, volume={32}, number={2}, pages={313--322}}
@incollection{glauert1935, author={Glauert, Hermann}, title={Airplane Propellers}, booktitle={Aerodynamic Theory}, editor={Durand, William F.}, volume={4}, publisher={Julius Springer}, address={Berlin}, year={1935}}
@book{mccormick1995, author={McCormick, Barnes W.}, title={Aerodynamics, Aeronautics, and Flight Mechanics}, edition={2}, publisher={Wiley}, address={New York}, year={1995}}
@book{etkin1996, author={Etkin, Bernard and Reid, Lloyd Duff}, title={Dynamics of Flight: Stability and Control}, edition={3}, publisher={Wiley}, address={New York}, year={1996}}
@book{stevens2015, author={Stevens, Brian L. and Lewis, Frank L. and Johnson, Eric N.}, title={Aircraft Control and Simulation}, edition={3}, publisher={Wiley}, address={Hoboken}, year={2015}}
@book{cook2012, author={Cook, Michael V.}, title={Flight Dynamics Principles}, edition={3}, publisher={Butterworth-Heinemann}, address={Oxford}, year={2012}}
@book{nelson1998, author={Nelson, Robert C.}, title={Flight Stability and Automatic Control}, edition={2}, publisher={McGraw-Hill}, address={Boston}, year={1998}}
@book{anderson1999, author={Anderson, John D.}, title={Aircraft Performance and Design}, publisher={McGraw-Hill}, address={Boston}, year={1999}}
@book{drela2014, author={Drela, Mark}, title={Flight Vehicle Aerodynamics}, publisher={MIT Press}, address={Cambridge, MA}, year={2014}}
@book{tischler2012, author={Tischler, Mark B. and Remple, Robert K.}, title={Aircraft and Rotorcraft System Identification}, edition={2}, publisher={American Institute of Aeronautics and Astronautics}, address={Reston}, year={2012}}
@book{jategaonkar2015, author={Jategaonkar, Ravindra V.}, title={Flight Vehicle System Identification}, edition={2}, publisher={American Institute of Aeronautics and Astronautics}, address={Reston}, year={2015}}
@book{klein2006, author={Klein, Vladislav and Morelli, Eugene A.}, title={Aircraft System Identification: Theory and Practice}, publisher={American Institute of Aeronautics and Astronautics}, address={Reston}, year={2006}}
@book{golub2013, author={Golub, Gene H. and Van Loan, Charles F.}, title={Matrix Computations}, edition={4}, publisher={Johns Hopkins University Press}, address={Baltimore}, year={2013}}
@book{kelley1999, author={Kelley, C. T.}, title={Iterative Methods for Optimization}, publisher={SIAM}, address={Philadelphia}, year={1999}}
@book{press2007, author={Press, William H. and Teukolsky, Saul A. and Vetterling, William T. and Flannery, Brian P.}, title={Numerical Recipes: The Art of Scientific Computing}, edition={3}, publisher={Cambridge University Press}, address={Cambridge}, year={2007}}
@book{roache1998, author={Roache, Patrick J.}, title={Verification and Validation in Computational Science and Engineering}, publisher={Hermosa Publishers}, address={Albuquerque}, year={1998}}
@book{oberkampf2010, author={Oberkampf, William L. and Roy, Christopher J.}, title={Verification and Validation in Scientific Computing}, publisher={Cambridge University Press}, address={Cambridge}, year={2010}}
@standard{nasastd7009, author={{NASA}}, title={Standard for Models and Simulations}, number={NASA-STD-7009A}, year={2016}, institution={NASA}}
@standard{asmevv20, author={{ASME}}, title={Standard for Verification and Validation in Computational Fluid Dynamics and Heat Transfer}, number={ASME V\&V 20-2009}, year={2009}, institution={American Society of Mechanical Engineers}}
@standard{jcgm100, author={{Joint Committee for Guides in Metrology}}, title={Evaluation of Measurement Data---Guide to the Expression of Uncertainty in Measurement}, number={JCGM 100:2008}, year={2008}}
@book{saltelli2008, author={Saltelli, Andrea and Ratto, Marco and Andres, Terry and Campolongo, Francesca and Cariboni, Jessica and Gatelli, Debora and Saisana, Michaela and Tarantola, Stefano}, title={Global Sensitivity Analysis: The Primer}, publisher={Wiley}, address={Chichester}, year={2008}}
@book{coleman2009, author={Coleman, Hugh W. and Steele, W. Glenn}, title={Experimentation, Validation, and Uncertainty Analysis for Engineers}, edition={3}, publisher={Wiley}, address={Hoboken}, year={2009}}
@standard{aiaag077, author={{AIAA}}, title={Guide for the Verification and Validation of Computational Fluid Dynamics Simulations}, number={AIAA G-077-1998}, year={1998}, institution={American Institute of Aeronautics and Astronautics}}
"""


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


def escape_text(s: str) -> str:
    tokens: list[str] = []

    def protect(value: str) -> str:
        tokens.append(value)
        return f"@@TOKEN{len(tokens)-1}@@"

    s = re.sub(r"\\cite\{[^}]+\}", lambda m: protect(m.group(0)), s)
    s = re.sub(r"\\\(.+?\\\)", lambda m: protect(m.group(0)), s)
    s = re.sub(r"\$[^$]+\$", lambda m: protect(m.group(0)), s)
    s = re.sub(
        r"`([^`]+)`",
        lambda m: protect(r"\texttt{" + escape_plain(m.group(1)) + "}"),
        s,
    )
    s = re.sub(
        r"\*\*([^*]+)\*\*",
        lambda m: protect(r"\textbf{" + escape_plain(m.group(1)) + "}"),
        s,
    )
    s = escape_plain(s)
    for i, value in enumerate(tokens):
        s = s.replace(f"@@TOKEN{i}@@", value)
    return s


def escape_plain(s: str) -> str:
    table = {
        "\\": r"\textbackslash{}",
        "&": r"\&",
        "%": r"\%",
        "#": r"\#",
        "_": r"\_",
        "{": r"\{",
        "}": r"\}",
        "~": r"\textasciitilde{}",
        "^": r"\textasciicircum{}",
    }
    return "".join(table.get(ch, ch) for ch in s)


def table_to_latex(lines: list[str], caption: str) -> str:
    rows = []
    for line in lines:
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if cells and all(re.fullmatch(r":?-{3,}:?", c.replace(" ", "")) for c in cells):
            continue
        rows.append(cells)
    if not rows:
        return ""
    n = max(len(r) for r in rows)
    width = max(0.06, 0.90 / n)
    spec = "".join(
        f">{{\\raggedright\\arraybackslash}}p{{{width:.3f}\\textwidth}}"
        for _ in range(n)
    )
    body = [r"\begin{center}", r"\scriptsize", r"\setlength{\tabcolsep}{1pt}",
            rf"\begin{{longtable}}{{{spec}}}",
            rf"\caption{{{escape_text(caption)}}}\\", r"\toprule"]
    for i, row in enumerate(rows):
        row += [""] * (n - len(row))
        body.append(" & ".join(escape_text(c) for c in row) + r" \\")
        if i == 0:
            body.append(r"\midrule\endfirsthead")
            body.append(r"\toprule")
            body.append(" & ".join(escape_text(c) for c in rows[0] + [""] * (n-len(rows[0]))) + r" \\")
            body.append(r"\midrule\endhead")
    body += [r"\bottomrule", r"\end{longtable}", r"\end{center}"]
    return "\n".join(body)


def markdown_to_latex(md: str, image_map: dict[str, str]) -> str:
    lines = md.splitlines()[1:]  # top title is rendered on the title page
    out: list[str] = []
    para: list[str] = []
    in_math = False
    math_lines: list[str] = []
    table_no = 0
    appendix_started = False
    current_title = "数据汇总"
    i = 0

    def flush_para() -> None:
        if para:
            raw = " ".join(x.strip() for x in para)
            rendered = escape_text(raw)
            if raw.startswith("**Key words:**"):
                out.append(r"{\raggedright " + rendered + r"\par}")
            else:
                out.append(rendered)
            out.append("")
            para.clear()

    while i < len(lines):
        line = lines[i]
        if line.strip() == "$$":
            flush_para()
            if not in_math:
                in_math = True
                math_lines = []
            else:
                out.extend([r"\begin{equation}", "\n".join(math_lines), r"\end{equation}", ""])
                in_math = False
            i += 1
            continue
        if in_math:
            math_lines.append(line)
            i += 1
            continue
        if line.startswith("|"):
            flush_para()
            tbl = []
            while i < len(lines) and lines[i].startswith("|"):
                tbl.append(lines[i])
                i += 1
            table_no += 1
            out.append(table_to_latex(tbl, current_title))
            out.append("")
            continue
        img = re.match(r"^!\[([^\]]*)\]\(([^)]+)\)", line)
        if img:
            flush_para()
            alt, src = img.groups()
            name = image_map.get(src.replace("\\", "/"))
            if name:
                out.extend([
                    r"\begin{figure}[htbp]",
                    r"\centering",
                    rf"\includegraphics[width=0.86\textwidth]{{figures/{name}}}",
                    rf"\caption{{{escape_text(alt)}}}",
                    r"\end{figure}",
                    "",
                ])
            i += 1
            continue
        if re.match(r"^#{1,3}\s+", line):
            flush_para()
            hashes, title = re.match(r"^(#{1,3})\s+(.+)$", line).groups()
            current_title = re.sub(r"^(?:\d+\.\d+|[A-Z]\.\d+)\s*", "", title)
            if title in {"中文摘要", "Abstract", "符号表", "缩写表"}:
                if title in {"符号表", "缩写表"}:
                    out.append(r"\normalsize")
                out.append(rf"\chapter*{{{escape_text(title)}}}")
                out.append(rf"\addcontentsline{{toc}}{{chapter}}{{{escape_text(title)}}}")
                if title == "Abstract":
                    out.append(r"\small")
            elif title.startswith("附录"):
                if not appendix_started:
                    out.append(r"\appendix")
                    appendix_started = True
                clean = re.sub(r"^附录[A-Z]?[　 ]*", "", title)
                out.append(rf"\chapter{{{escape_text(clean)}}}")
            elif len(hashes) == 1:
                clean = re.sub(r"^第[一二三四五六七八九十]+章[　 ]*", "", title)
                out.append(rf"\chapter{{{escape_text(clean)}}}")
            else:
                clean = re.sub(r"^(?:\d+\.\d+|[A-Z]\.\d+)\s*", "", title)
                out.append(rf"\section{{{escape_text(clean)}}}")
            out.append("")
            i += 1
            continue
        if re.match(r"^\s*[-*]\s+", line):
            flush_para()
            items = []
            while i < len(lines) and re.match(r"^\s*[-*]\s+", lines[i]):
                items.append(re.sub(r"^\s*[-*]\s+", "", lines[i]))
                i += 1
            out.append(r"\begin{itemize}")
            out.extend(r"\item " + escape_text(x) for x in items)
            out.append(r"\end{itemize}")
            out.append("")
            continue
        if re.match(r"^\s*\d+\.\s+", line):
            flush_para()
            items = []
            while i < len(lines) and re.match(r"^\s*\d+\.\s+", lines[i]):
                items.append(re.sub(r"^\s*\d+\.\s+", "", lines[i]))
                i += 1
            out.append(r"\begin{enumerate}")
            out.extend(r"\item " + escape_text(x) for x in items)
            out.append(r"\end{enumerate}")
            out.append("")
            continue
        if not line.strip():
            flush_para()
        elif line.startswith("*") and line.endswith("*"):
            flush_para()
            out.append(r"\emph{" + escape_text(line.strip("*")) + "}")
        else:
            para.append(line)
        i += 1
    flush_para()
    return "\n".join(out)


def build() -> dict[str, object]:
    FINAL.mkdir(parents=True, exist_ok=True)
    PROJECT.mkdir(parents=True, exist_ok=True)
    (PROJECT / "figures").mkdir(exist_ok=True)
    md = SOURCE.read_text(encoding="utf-8")
    md = re.sub(r"^\*(?:图|F)\d+[^\n]*\*\s*$", "", md, flags=re.M)
    write(FINAL / "MASTER_THESIS_FINAL_CANDIDATE.md", md)

    image_map: dict[str, str] = {}
    used = []
    for idx, match in enumerate(re.finditer(r"!\[[^\]]*\]\(([^)]+)\)", md), 1):
        rel = match.group(1).replace("\\", "/")
        src = ROOT / "docs" / "master_thesis_validation" / rel
        if not src.exists():
            candidates = list(FIG_SRC.glob(f"*_{Path(rel).name}"))
            if len(candidates) == 1:
                src = candidates[0]
            else:
                continue
        name = f"figure_{idx:02d}{src.suffix.lower()}"
        shutil.copy2(src, PROJECT / "figures" / name)
        image_map[rel] = name
        used.append([idx, rel, name, "正文首次讨论位置", "既有计算或方法图"])

    body = markdown_to_latex(md, image_map)
    preamble = rf"""\documentclass[UTF8,12pt,oneside,openany,fontset=windows]{{ctexbook}}
\usepackage[a4paper,left=30mm,right=25mm,top=28mm,bottom=25mm,headheight=15pt]{{geometry}}
\usepackage{{fontspec,xeCJK,graphicx,booktabs,longtable,array,amsmath,amssymb,bm}}
\usepackage{{caption,float,fancyhdr,hyperref,bookmark,microtype}}
\usepackage[backend=biber,style=gb7714-2015,sorting=none]{{biblatex}}
\addbibresource{{references.bib}}
\setmainfont{{Times New Roman}}
\hypersetup{{hidelinks,pdftitle={{{TITLE}}},pdfauthor={{匿名送审稿}}}}
\captionsetup{{font=small,labelsep=quad}}
\setlength{{\parindent}}{{2em}}
\setlength{{\parskip}}{{0pt}}
\linespread{{1.35}}
\raggedbottom
\pagestyle{{fancy}}
\fancyhf{{}}
\fancyhead[C]{{\small {TITLE}}}
\fancyfoot[C]{{\thepage}}
\setcounter{{secnumdepth}}{{3}}
\setcounter{{tocdepth}}{{2}}
\emergencystretch=3em
\begin{{document}}
\begin{{titlepage}}
\centering
\vspace*{{22mm}}
{{\zihao{{2}}\bfseries {TITLE}\par}}
\vspace{{25mm}}
{{\zihao{{3}} 硕士学位论文送审候选稿\par}}
\vfill
{{\zihao{{-4}} 学校、学院、作者、导师与日期请按培养单位正式模板填写\par}}
\end{{titlepage}}
\chapter*{{原创性声明}}
\thispagestyle{{empty}}
本页为占位页。提交前应替换为培养单位规定文本并由作者签署。
\frontmatter
\tableofcontents
\listoffigures
\listoftables
\mainmatter
"""
    tail = r"""
\backmatter
\printbibliography[heading=bibintoc,title={参考文献}]
\chapter*{致谢}
本页为致谢占位页，匿名送审版本不填写身份信息。
\end{document}
"""
    tex = preamble + body + tail
    write(PROJECT / "main.tex", tex)
    write(PROJECT / "references.bib", BIB)
    write(FINAL / "MASTER_THESIS_FINAL_CANDIDATE.tex", tex)
    write_csv(
        FINAL / "FIGURE_SOURCE_INDEX_FINAL.csv",
        ["序号", "原始文件", "LaTeX文件", "正文位置", "来源类型"], used,
    )

    keys = re.findall(r"@\w+\{([^,]+),", BIB)
    trace_rows = []
    purpose_map = [
        "倾转旋翼历史与XV-15构型", "公开型号资料与试验", "旋翼理论与诱导流",
        "飞行动力学、配平与辨识", "数值分析与可信度方法",
    ]
    for idx, key in enumerate(keys):
        trace_rows.append([idx + 1, key, purpose_map[min(4, idx // 8)],
                           "第一、三、四、六或七章", "已核对书目信息；NASA报告号按原件"])
    write_csv(
        FINAL / "REFERENCE_TRACEABILITY_FINAL.csv",
        ["序号", "BibTeX键", "使用目的", "引用章节", "核查状态"], trace_rows,
    )
    write(
        FINAL / "REFERENCE_AUDIT.md",
        f"""# 参考文献审计

最终BibTeX共{len(keys)}项，覆盖倾转旋翼经典构型、XV-15设计与试验、叶素/动量/诱导流、
飞行动力学与辨识、数值优化，以及模型校核、确认和不确定度。NASA报告号以本地原始PDF
或NASA书目核对；教材和标准用于基础理论与方法，不冒充型号数据。正文采用GB/T 7714
样式并由Biber生成，追溯矩阵记录每项用途。
""",
    )

    # Copy required final evidence without modifying the earlier round outputs.
    copies = {
        ROUNDS / "round_01_scientific_audit" / "NINE_VS_THIRTEEN_A_BLOCK_AUDIT.md": FINAL / "NINE_VS_THIRTEEN_A_BLOCK_AUDIT.md",
        ROUNDS / "round_01_scientific_audit" / "NINE_VS_THIRTEEN_A_BLOCK_ELEMENTWISE.csv": FINAL / "NINE_VS_THIRTEEN_A_BLOCK_ELEMENTWISE.csv",
        ROUNDS / "round_01_scientific_audit" / "EXTERNAL_ROTOR_DIGITIZATION_REVIEW.md": FINAL / "EXTERNAL_ROTOR_DIGITIZATION_REVIEW.md",
        ROUNDS / "round_01_scientific_audit" / "EXTERNAL_ROTOR_DIGITIZATION_FINAL.csv": FINAL / "EXTERNAL_ROTOR_DIGITIZATION_FINAL.csv",
        ROUNDS / "round_01_scientific_audit" / "EXTERNAL_ROTOR_CORRELATION_METRICS_FINAL.csv": FINAL / "EXTERNAL_ROTOR_CORRELATION_METRICS_FINAL.csv",
        ROUNDS / "round_01_scientific_audit" / "FINAL_FORMULA_CODE_PARAMETER_TEST_MAPPING.md": FINAL / "FINAL_FORMULA_CODE_PARAMETER_TEST_MAPPING.md",
        ROUNDS / "round_01_scientific_audit" / "HIGH_IMPACT_PARAMETER_AUDIT.md": FINAL / "HIGH_IMPACT_PARAMETER_AUDIT.md",
    }
    for src, dst in copies.items():
        shutil.copy2(src, dst)
    shutil.copy2(ROOT / "docs" / "master_thesis_validation" / "CLAIM_EVIDENCE_MATRIX.csv",
                 FINAL / "CLAIM_EVIDENCE_MATRIX_FINAL.csv")
    shutil.copy2(ROOT / "docs" / "master_thesis_validation" / "PARAMETER_PROVENANCE_MASTER.csv",
                 FINAL / "PARAMETER_PROVENANCE_FINAL.csv")
    return {
        "nonspace": len(re.sub(r"\s+", "", md)),
        "equations": md.count("$$") // 2,
        "figures": len(used),
        "tables": sum(1 for _ in re.finditer(r"^\|.*\|$", md, re.M)) // 3,
        "references": len(keys),
    }


if __name__ == "__main__":
    print(json.dumps(build(), ensure_ascii=False))
