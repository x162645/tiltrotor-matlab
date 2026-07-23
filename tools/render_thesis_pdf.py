#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Render the consolidated Chinese Markdown thesis to a polished A4 PDF."""

from __future__ import annotations

import argparse
import hashlib
import re
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    BaseDocTemplate,
    Frame,
    Image,
    KeepTogether,
    NextPageTemplate,
    PageBreak,
    PageTemplate,
    Paragraph,
    Spacer,
    Table,
    TableStyle,
)
from reportlab.platypus.tableofcontents import TableOfContents


FONT_REG = Path(r"C:\Windows\Fonts\msyh.ttc")
FONT_BOLD = Path(r"C:\Windows\Fonts\msyhbd.ttc")
PAGE_W, PAGE_H = A4


def register_fonts() -> tuple[str, str]:
    if not FONT_REG.exists():
        return "Helvetica", "Helvetica-Bold"
    pdfmetrics.registerFont(TTFont("MSYH", str(FONT_REG), subfontIndex=0))
    if FONT_BOLD.exists():
        pdfmetrics.registerFont(TTFont("MSYH-B", str(FONT_BOLD), subfontIndex=0))
    else:
        pdfmetrics.registerFont(TTFont("MSYH-B", str(FONT_REG), subfontIndex=0))
    return "MSYH", "MSYH-B"


def latex_plain(text: str) -> str:
    """Convert the small LaTeX subset in the report to readable Unicode."""
    replacements = {
        r"\times": "×", r"\sum": "Σ", r"\partial": "∂", r"\approx": "≈",
        r"\leq": "≤", r"\geq": "≥", r"\pi": "π", r"\phi": "φ",
        r"\theta": "θ", r"\psi": "ψ", r"\beta": "β", r"\delta": "δ",
        r"\omega": "ω", r"\Omega": "Ω", r"\eta": "η", r"\alpha": "α",
        r"\varphi": "ϕ", r"\zeta": "ζ", r"\quad": "  ", r"\qquad": "    ",
        r"\cdot": "·", r"\in": "∈", r"\pm": "±", r"\left": "", r"\right": "",
    }
    for src, dst in replacements.items():
        text = text.replace(src, dst)
    text = re.sub(r"\\frac\{([^{}]+)\}\{([^{}]+)\}", r"(\1)/(\2)", text)
    text = re.sub(r"\\dot\{([^{}]+)\}", r"d(\1)/dt", text)
    text = re.sub(r"\\(?:mathbf|boldsymbol|mathrm|operatorname)\{([^{}]+)\}", r"\1", text)
    text = re.sub(r"_\{([^{}]+)\}", r"_\1", text)
    text = re.sub(r"\^\{([^{}]+)\}", r"^(\1)", text)
    text = text.replace(r"\\", " ").replace(r"\,", " ")
    text = text.replace("{", "").replace("}", "")
    return text


def esc(text: str) -> str:
    text = text.replace("**", "").replace("`", "")
    text = re.sub(r"\$([^$]+)\$", r"\1", text)
    text = latex_plain(text)
    return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


class ThesisDocTemplate(BaseDocTemplate):
    def __init__(self, *args, font: str, **kwargs):
        self.font = font
        super().__init__(*args, **kwargs)

    def afterFlowable(self, flowable):
        if isinstance(flowable, Paragraph):
            style = flowable.style.name
            if style in {"Chapter", "Heading2", "Heading3"}:
                level = {"Chapter": 0, "Heading2": 1, "Heading3": 2}[style]
                text = flowable.getPlainText()
                key = "heading-" + hashlib.sha1(
                    f"{level}:{text}".encode("utf-8")
                ).hexdigest()[:16]
                self.canv.bookmarkPage(key)
                self.notify("TOCEntry", (level, text, self.page, key))


def header_footer(canvas, doc):
    canvas.saveState()
    if doc.page > 2:
        canvas.setFont(doc.font, 8)
        canvas.setFillColor(colors.HexColor("#666666"))
        canvas.drawCentredString(
            PAGE_W / 2,
            PAGE_H - 12 * mm,
            "倾转旋翼机部件级飞行动力学建模与短舱动态状态影响研究",
        )
        canvas.setStrokeColor(colors.HexColor("#B4C6E7"))
        canvas.line(25 * mm, PAGE_H - 15 * mm, PAGE_W - 25 * mm, PAGE_H - 15 * mm)
    canvas.setFont(doc.font, 8.5)
    canvas.setFillColor(colors.HexColor("#555555"))
    canvas.drawCentredString(PAGE_W / 2, 10 * mm, f"第 {doc.page} 页")
    canvas.restoreState()


def title_page(story: list, styles: dict) -> None:
    story.extend(
        [
            Spacer(1, 32 * mm),
            Paragraph("研究报告", styles["Kicker"]),
            Spacer(1, 12 * mm),
            Paragraph("倾转旋翼机部件级飞行动力学建模<br/>与短舱动态状态影响研究", styles["Title"]),
            Spacer(1, 16 * mm),
            Table(
                [
                    ["研究对象", "通用倾转旋翼机部件级飞行动力学模型"],
                    ["研究范围", "短舱状态扩展、配平、线性化与刚体响应"],
                    ["交付日期", "2026年7月23日"],
                    ["结论性质", "概念模型内部一致性与有限工况计算"],
                ],
                colWidths=[35 * mm, 105 * mm],
                style=TableStyle(
                    [
                        ("FONTNAME", (0, 0), (-1, -1), styles["font"]),
                        ("BACKGROUND", (0, 0), (0, -1), colors.HexColor("#D9EAF7")),
                        ("GRID", (0, 0), (-1, -1), 0.45, colors.HexColor("#7F8C8D")),
                        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                        ("LEFTPADDING", (0, 0), (-1, -1), 7),
                        ("RIGHTPADDING", (0, 0), (-1, -1), 7),
                        ("TOPPADDING", (0, 0), (-1, -1), 7),
                        ("BOTTOMPADDING", (0, 0), (-1, -1), 7),
                    ]
                ),
            ),
            Spacer(1, 28 * mm),
            Paragraph(
                "本报告不宣称完成XV-15型号复现或飞行试验验证。"
                "所有定量结论均受模型、参数、工况与有效域边界约束。",
                styles["Boundary"],
            ),
            PageBreak(),
            Paragraph("目录", styles["TOCTitle"]),
        ]
    )


def make_styles(font: str, bold: str) -> dict:
    base = getSampleStyleSheet()
    styles = {"font": font, "bold": bold}
    styles["Title"] = ParagraphStyle(
        "Title", parent=base["Title"], fontName=bold, fontSize=24, leading=36,
        alignment=TA_CENTER, textColor=colors.HexColor("#17365D"), wordWrap="CJK"
    )
    styles["Kicker"] = ParagraphStyle(
        "Kicker", parent=base["Normal"], fontName=font, fontSize=13, leading=20,
        alignment=TA_CENTER, textColor=colors.HexColor("#5B9BD5"), wordWrap="CJK"
    )
    styles["Boundary"] = ParagraphStyle(
        "Boundary", parent=base["Normal"], fontName=font, fontSize=10.5, leading=18,
        alignment=TA_JUSTIFY, borderColor=colors.HexColor("#BF9000"),
        borderWidth=0.8, borderPadding=10, backColor=colors.HexColor("#FFF2CC"),
        wordWrap="CJK"
    )
    styles["Chapter"] = ParagraphStyle(
        "Chapter", parent=base["Heading1"], fontName=bold, fontSize=18, leading=27,
        textColor=colors.HexColor("#17365D"), spaceBefore=6 * mm, spaceAfter=5 * mm,
        keepWithNext=True, wordWrap="CJK"
    )
    styles["TOCTitle"] = ParagraphStyle(
        "TOCTitle", parent=styles["Chapter"], alignment=TA_LEFT
    )
    styles["Heading2"] = ParagraphStyle(
        "Heading2", parent=base["Heading2"], fontName=bold, fontSize=14, leading=21,
        textColor=colors.HexColor("#1F4E79"), spaceBefore=4.5 * mm, spaceAfter=2.5 * mm,
        keepWithNext=True, wordWrap="CJK"
    )
    styles["Heading3"] = ParagraphStyle(
        "Heading3", parent=base["Heading3"], fontName=bold, fontSize=11.5, leading=18,
        textColor=colors.HexColor("#2F5597"), spaceBefore=3 * mm, spaceAfter=2 * mm,
        keepWithNext=True, wordWrap="CJK"
    )
    styles["Body"] = ParagraphStyle(
        "Body", parent=base["BodyText"], fontName=font, fontSize=10.2, leading=17.5,
        alignment=TA_JUSTIFY, firstLineIndent=20.4, spaceAfter=2.2 * mm, wordWrap="CJK"
    )
    styles["List"] = ParagraphStyle(
        "List", parent=styles["Body"], firstLineIndent=0, leftIndent=8 * mm,
        bulletIndent=2 * mm
    )
    styles["Equation"] = ParagraphStyle(
        "Equation", parent=base["Code"], fontName=font, fontSize=9.2, leading=15,
        alignment=TA_CENTER, leftIndent=8 * mm, rightIndent=8 * mm,
        borderColor=colors.HexColor("#D9E2F3"), borderWidth=0.5, borderPadding=6,
        backColor=colors.HexColor("#F7F9FC"), spaceBefore=2 * mm, spaceAfter=3 * mm,
        wordWrap="CJK"
    )
    styles["Caption"] = ParagraphStyle(
        "Caption", parent=base["BodyText"], fontName=font, fontSize=8.8, leading=14,
        alignment=TA_CENTER, textColor=colors.HexColor("#555555"), spaceAfter=4 * mm,
        wordWrap="CJK"
    )
    styles["Table"] = ParagraphStyle(
        "Table", parent=base["BodyText"], fontName=font, fontSize=7.2, leading=10,
        alignment=TA_LEFT, wordWrap="CJK"
    )
    return styles


def table_from_markdown(block: list[str], styles: dict) -> Table | None:
    rows = []
    for j, line in enumerate(block):
        cells = [c.strip() for c in line.strip("|").split("|")]
        if j == 1 and all(set(c) <= {"-", ":"} for c in cells):
            continue
        rows.append([Paragraph(esc(c), styles["Table"]) for c in cells])
    if not rows:
        return None
    n = max(len(r) for r in rows)
    for row in rows:
        row.extend([""] * (n - len(row)))
    widths = [160 * mm / n] * n
    table = Table(rows, colWidths=widths, repeatRows=1, hAlign="CENTER")
    table.setStyle(
        TableStyle(
            [
                ("FONTNAME", (0, 0), (-1, -1), styles["font"]),
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#D9EAF7")),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.HexColor("#17365D")),
                ("GRID", (0, 0), (-1, -1), 0.35, colors.HexColor("#8EA9C1")),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 3),
                ("RIGHTPADDING", (0, 0), (-1, -1), 3),
                ("TOPPADDING", (0, 0), (-1, -1), 3),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
            ]
        )
    )
    return table


def image_flowable(markdown_path: Path, alt: str, rel: str, styles: dict):
    image_path = markdown_path.parent / rel
    if not image_path.exists():
        return Paragraph(f"图件缺失：{esc(rel)}", styles["Boundary"])
    image = Image(str(image_path))
    max_w, max_h = 158 * mm, 92 * mm
    scale = min(max_w / image.imageWidth, max_h / image.imageHeight)
    image.drawWidth = image.imageWidth * scale
    image.drawHeight = image.imageHeight * scale
    return KeepTogether([image, Paragraph(esc(alt), styles["Caption"])])


def markdown_story(markdown_path: Path, styles: dict) -> list:
    lines = markdown_path.read_text(encoding="utf-8").splitlines()
    story: list = []
    i = 0
    first_h1 = True
    while i < len(lines):
        raw = lines[i]
        line = raw.strip()
        if not line:
            i += 1
            continue
        if line.startswith("# "):
            if first_h1:
                first_h1 = False
                i += 1
                continue
            story.extend([PageBreak(), Paragraph(esc(line[2:]), styles["Chapter"])])
            i += 1
            continue
        if line.startswith("## "):
            story.append(Paragraph(esc(line[3:]), styles["Heading2"]))
            i += 1
            continue
        if line.startswith("### "):
            story.append(Paragraph(esc(line[4:]), styles["Heading3"]))
            i += 1
            continue
        image_match = re.match(r"!\[(.*?)\]\((.*?)\)", line)
        if image_match:
            story.append(image_flowable(markdown_path, image_match.group(1), image_match.group(2), styles))
            i += 1
            if i < len(lines) and lines[i].strip().startswith("*图"):
                i += 1
            continue
        if line.startswith("|"):
            block = []
            while i < len(lines) and lines[i].strip().startswith("|"):
                block.append(lines[i].strip())
                i += 1
            table = table_from_markdown(block, styles)
            if table:
                story.extend([table, Spacer(1, 3 * mm)])
            continue
        if line.startswith("$$"):
            equation = [line]
            i += 1
            if not (line.endswith("$$") and len(line) > 4):
                while i < len(lines):
                    equation.append(lines[i].strip())
                    i += 1
                    if equation[-1].endswith("$$"):
                        break
            text = " ".join(equation).replace("$$", "").replace("\\\\", " ")
            story.append(Paragraph(esc(text), styles["Equation"]))
            continue
        if re.match(r"^\d+\.\s", line):
            story.append(Paragraph(esc(line), styles["List"]))
            i += 1
            continue
        if line.startswith("- "):
            story.append(Paragraph("• " + esc(line[2:]), styles["List"]))
            i += 1
            continue
        if line.startswith("*图"):
            i += 1
            continue
        if line.startswith(">"):
            story.append(Paragraph(esc(line.lstrip("> ")), styles["Boundary"]))
            i += 1
            continue
        para = [line]
        i += 1
        while i < len(lines):
            nxt = lines[i].strip()
            if not nxt or nxt.startswith(("#", "|", "-", "!", "$$", ">")) or re.match(r"^\d+\.\s", nxt):
                break
            para.append(nxt)
            i += 1
        story.append(Paragraph(esc(" ".join(para)), styles["Body"]))
    return story


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("markdown", type=Path)
    parser.add_argument("pdf", type=Path)
    args = parser.parse_args()
    font, bold = register_fonts()
    styles = make_styles(font, bold)

    frame = Frame(24 * mm, 18 * mm, PAGE_W - 48 * mm, PAGE_H - 36 * mm, id="normal")
    template = PageTemplate(id="body", frames=[frame], onPage=header_footer)
    doc = ThesisDocTemplate(
        str(args.pdf),
        pagesize=A4,
        pageTemplates=[template],
        font=font,
        title="倾转旋翼机部件级飞行动力学建模与短舱动态状态影响研究",
        author="研究报告",
        subject="部件级飞行动力学、短舱动态状态与转换走廊配平",
    )
    story: list = []
    title_page(story, styles)
    toc = TableOfContents()
    toc.levelStyles = [
        ParagraphStyle("TOC0", fontName=bold, fontSize=11, leading=18,
                       leftIndent=0, firstLineIndent=0, textColor=colors.HexColor("#17365D")),
        ParagraphStyle("TOC1", fontName=font, fontSize=9.5, leading=15,
                       leftIndent=12, firstLineIndent=0),
        ParagraphStyle("TOC2", fontName=font, fontSize=8.5, leading=13,
                       leftIndent=24, firstLineIndent=0, textColor=colors.HexColor("#666666")),
    ]
    story.extend([toc, PageBreak()])
    story.extend(markdown_story(args.markdown, styles))
    args.pdf.parent.mkdir(parents=True, exist_ok=True)
    doc.multiBuild(story)
    print(args.pdf)


if __name__ == "__main__":
    main()
