from __future__ import annotations

import re
import sys
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    Image,
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)


def inline_markup(text: str) -> str:
    text = text.replace("²", "^2")
    text = text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    text = re.sub(
        r"`([^`]+)`", r"<font name='SimHei' color='#17365d'>\1</font>", text
    )
    text = re.sub(r"\*\*([^*]+)\*\*", r"<b>\1</b>", text)
    return text


def page_number(canvas, doc):
    canvas.saveState()
    canvas.setFont("SimHei", 8)
    canvas.setFillColor(colors.HexColor("#5b6470"))
    canvas.drawString(22 * mm, 13 * mm, "13×10 左右短舱动力学研究｜内部研究模型")
    canvas.drawRightString(188 * mm, 13 * mm, f"第 {doc.page} 页")
    canvas.restoreState()


def markdown_table(lines, style):
    rows = []
    for line in lines:
        cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
        if cells and all(re.fullmatch(r":?-+:?", cell) for cell in cells):
            continue
        rows.append([Paragraph(inline_markup(cell), style) for cell in cells])
    if not rows:
        return None
    table = Table(rows, repeatRows=1, hAlign="LEFT", colWidths=None)
    table.setStyle(
        TableStyle(
            [
                ("FONTNAME", (0, 0), (-1, -1), "SimHei"),
                ("FONTSIZE", (0, 0), (-1, -1), 7.2),
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#dce6f1")),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.HexColor("#17365d")),
                ("GRID", (0, 0), (-1, -1), 0.35, colors.HexColor("#8d99a6")),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 3),
                ("RIGHTPADDING", (0, 0), (-1, -1), 3),
                ("TOPPADDING", (0, 0), (-1, -1), 3),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
            ]
        )
    )
    return table


def main() -> None:
    if len(sys.argv) != 4:
        raise SystemExit("usage: script REPORT.md FIGURE_DIR OUTPUT.pdf")
    markdown_path = Path(sys.argv[1])
    figure_dir = Path(sys.argv[2])
    output_path = Path(sys.argv[3])
    pdfmetrics.registerFont(TTFont("SimHei", r"C:\Windows\Fonts\simhei.ttf"))

    styles = getSampleStyleSheet()
    title = ParagraphStyle(
        "TitleCN", parent=styles["Title"], fontName="SimHei", fontSize=22,
        leading=33, alignment=TA_CENTER, textColor=colors.HexColor("#17365d"),
        spaceAfter=18,
    )
    h1 = ParagraphStyle(
        "H1CN", parent=styles["Heading1"], fontName="SimHei", fontSize=15,
        leading=22, textColor=colors.HexColor("#1f4e79"), spaceBefore=10,
        spaceAfter=7,
    )
    body = ParagraphStyle(
        "BodyCN", parent=styles["BodyText"], fontName="SimHei", fontSize=10,
        leading=17, alignment=TA_JUSTIFY, firstLineIndent=20, spaceAfter=6,
    )
    bullet = ParagraphStyle(
        "BulletCN", parent=body, firstLineIndent=0, leftIndent=14,
        bulletIndent=2,
    )
    table_text = ParagraphStyle(
        "TableCN", parent=body, fontSize=7.2, leading=10, firstLineIndent=0,
        alignment=0,
    )
    caption = ParagraphStyle(
        "CaptionCN", parent=body, fontSize=8.5, leading=12,
        firstLineIndent=0, alignment=TA_CENTER, textColor=colors.HexColor("#555555"),
    )

    doc = SimpleDocTemplate(
        str(output_path), pagesize=A4, leftMargin=22 * mm, rightMargin=22 * mm,
        topMargin=20 * mm, bottomMargin=22 * mm,
        title="倾转旋翼机左右短舱动力学及其与刚体模态耦合研究",
        author="13×10 低阶研究模型工作流",
    )
    story = []
    lines = markdown_path.read_text(encoding="utf-8").splitlines()
    figure_after = {
        "5 配平、可信度与数值线性化": ("F01_trim_operating_points.png", "图 1  配平研究网格及可信度分类"),
        "6 稳定导数、控制导数与对称/差动坐标": ("F07_stability_derivatives.png", "图 2  代表工况稳定导数"),
        "7 模态识别与跟踪": ("F09_all_eigenvalues.png", "图 3  全部可信工况特征根"),
        "8 非线性时域与故障研究": ("F18_single_side_stuck.png", "图 4  单侧短舱卡滞响应"),
        "9 参数敏感性": ("F19_parameter_sensitivity.png", "图 5  参数敏感性筛选"),
        "10 线性—非线性一致性": ("F15_linear_nonlinear_comparison.png", "图 6  小扰动线性—非线性比较"),
    }
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        if not line:
            i += 1
            continue
        if line.startswith("# "):
            story.extend([Spacer(1, 28 * mm), Paragraph(inline_markup(line[2:]), title)])
            story.append(Spacer(1, 12 * mm))
            story.append(Paragraph("完整研究报告｜2026 年 7 月", caption))
            story.append(PageBreak())
        elif line.startswith("## "):
            heading = line[3:]
            story.append(Paragraph(inline_markup(heading), h1))
            if heading in figure_after:
                name, text = figure_after[heading]
                image_path = figure_dir / name
                if image_path.exists():
                    image = Image(str(image_path), width=158 * mm, height=100 * mm)
                    image.hAlign = "CENTER"
                    story.extend([image, Paragraph(text, caption), Spacer(1, 3 * mm)])
        elif line.startswith("|"):
            table_lines = []
            while i < len(lines) and lines[i].strip().startswith("|"):
                table_lines.append(lines[i].strip())
                i += 1
            table = markdown_table(table_lines, table_text)
            if table is not None:
                story.extend([table, Spacer(1, 3 * mm)])
            continue
        elif line.startswith("- ") or re.match(r"\d+\. ", line):
            text = re.sub(r"^(?:- |\d+\. )", "", line)
            story.append(Paragraph(inline_markup(text), bullet, bulletText="•"))
        else:
            story.append(Paragraph(inline_markup(line), body))
        i += 1
    doc.build(story, onFirstPage=page_number, onLaterPages=page_number)


if __name__ == "__main__":
    main()
