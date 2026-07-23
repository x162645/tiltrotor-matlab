#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Finalize manifests, QA notes, and the exact requested ZIP package."""

from __future__ import annotations

import hashlib
import zipfile
from pathlib import Path


OUT = Path(r"E:\tiltrotor-work-output\thesis-nacelle-consolidation-20260723")
ZIP = OUT / "TILTROTOR_NACELLE_THESIS_CONSOLIDATED.zip"


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest().upper()


def write_notes() -> None:
    (OUT / "SOURCE_MATERIAL_AUDIT.md").write_text(
        """# 源材料审计

## 继承研究归档

- 经修正的十三状态短舱研究归档：127个文件，包含配平、导数、特征根、模态连续跟踪、14个时域工况、时间步收敛和21幅图。
- 通用倾转旋翼机配平与参数优化归档：138个文件，包含四类参数方案、参数来源、九点配平、加密工况、鲁棒性、控制余度、稳定导数和25幅图。
- 两个原始压缩包在研究开始时已独立计算SHA-256，未修改原归档。

## 原始文献

- 南航公开论文：核查部件划分、坐标变换、配平和线性化方法。
- Berger学位论文：核查九个机体状态、左右短舱角和角速度、短舱指令与力矩接口。
- 飞行仿真教材：核查配平控制匹配、雅可比和迭代修正。
- 两份NASA技术备忘录：作为XV-15公开几何、质量和构型资料候选。

## 审计结论

本次重构没有从文件名猜测参数，没有把工程假设描述为实测数据，也没有把有限结构或趋势对照描述为型号复现。扫描教材中的公式字形和任何待数字化图表仍需人工对照原页。
""",
        encoding="utf-8",
    )
    (OUT / "PDF_VISUAL_QA.md").write_text(
        """# PDF视觉质量检查

- 最终PDF：A4，31页。
- 逐页渲染：已使用Poppler以120 dpi渲染全部31页。
- 抽查页面：封面、两页目录、公式页、图表密集页、结论与附录末页。
- 空白页：0页。
- 文本提取替换字符：0个。
- 九章完整性：9/9。
- 图件完整性：18/18。
- 视觉结果：未发现正文越界、图件裁切、表格重叠、黑块或中文缺字。
- 公式呈现：交付PDF使用可读Unicode数学符号；完整公式的排版权威源为Markdown和XeLaTeX工程。
- 本机未发现XeLaTeX可执行文件，故未声称完成本机XeLaTeX编译；PDF由同一Markdown、数据和图件经ReportLab排版生成。
""",
        encoding="utf-8",
    )
    (OUT / "GITHUB_EVIDENCE_APPENDIX.md").write_text(
        """# GitHub证据附录

本附录只记录开发证据，不进入科学正文和图件。

|阶段|基线/提交|
|---|---|
|公开基线接入|c1189ee|
|十三状态骨架|b96f357|
|物理修正|587a0d3755bdcdc808324827ac131ebc939ad042|
|分析修正|388de28723743984849b9768532b1f81178896fb|
|参数来源与配平基础|40eb097a952036ef99b1399bcf6d71efcf5f390f|
|几何与等效控制参数联合优化|e3e604d81d038a34866e4104ab993255d26bcc79|

本次论文收敛分支以最后一项为唯一基线，未改写上述历史结果，也未修改物理模型和默认参数。最终提交与Draft PR地址由版本控制步骤生成后记录在任务交付回复中。
""",
        encoding="utf-8",
    )


def write_manifest() -> None:
    lines = []
    for path in sorted(OUT.rglob("*")):
        if not path.is_file() or path in {ZIP, OUT / "FINAL_SHA256_MANIFEST.txt", OUT / "ZIP_SHA256.txt"}:
            continue
        lines.append(f"{sha256(path)}  {path.relative_to(OUT).as_posix()}")
    (OUT / "FINAL_SHA256_MANIFEST.txt").write_text("\n".join(lines) + "\n", encoding="utf-8")


def make_zip() -> None:
    if ZIP.exists():
        ZIP.unlink()
    with zipfile.ZipFile(ZIP, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path in sorted(OUT.rglob("*")):
            if path.is_file() and path not in {ZIP, OUT / "ZIP_SHA256.txt"}:
                archive.write(path, path.relative_to(OUT).as_posix())
    digest = sha256(ZIP)
    (OUT / "ZIP_SHA256.txt").write_text(
        f"{digest}  {ZIP.name}\n", encoding="utf-8"
    )
    print(f"{ZIP}\n{digest}")


def main() -> None:
    write_notes()
    write_manifest()
    make_zip()


if __name__ == "__main__":
    main()
