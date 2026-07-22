from __future__ import annotations

import html
import re
import sys
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    Image,
    KeepTogether,
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)


TITLE = "规定执行器模型下倾转旋翼机左右短舱运动对刚体动态的影响研究"


def markup(text: str) -> str:
    value = html.escape(text)
    value = re.sub(r"`([^`]+)`", r"<font color='#17365d'>\1</font>", value)
    value = re.sub(r"\*\*([^*]+)\*\*", r"<b>\1</b>", value)
    return value


def header_footer(canvas, doc) -> None:
    canvas.saveState()
    canvas.setStrokeColor(colors.HexColor("#9aa7b5"))
    canvas.line(20 * mm, 18 * mm, 190 * mm, 18 * mm)
    canvas.setFillColor(colors.HexColor("#526170"))
    canvas.setFont("SimHei", 7.5)
    canvas.drawString(20 * mm, 12 * mm, "Berger13 13×10 修正研究报告 - 内部一致性研究")
    canvas.drawRightString(190 * mm, 12 * mm, f"第 {doc.page} 页")
    canvas.restoreState()


def image_block(path: Path, caption: str, caption_style: ParagraphStyle):
    if not path.exists():
        return []
    image = Image(str(path), width=160 * mm, height=104 * mm)
    image.hAlign = "CENTER"
    return [Spacer(1, 3 * mm), image, Paragraph(caption, caption_style)]


def main() -> None:
    if len(sys.argv) != 4:
        raise SystemExit("usage: generate_berger13_report_pdf.py REPORT.md FIGURE_DIR OUTPUT.pdf")
    markdown_path = Path(sys.argv[1])
    figure_dir = Path(sys.argv[2])
    output_path = Path(sys.argv[3])
    output_path.parent.mkdir(parents=True, exist_ok=True)

    font_path = Path(r"C:\Windows\Fonts\simhei.ttf")
    if not font_path.exists():
        font_path = Path(r"C:\Windows\Fonts\msyh.ttc")
    pdfmetrics.registerFont(TTFont("SimHei", str(font_path)))

    styles = getSampleStyleSheet()
    title_style = ParagraphStyle(
        "TitleCN", parent=styles["Title"], fontName="SimHei", fontSize=22,
        leading=34, alignment=TA_CENTER, textColor=colors.HexColor("#17365d"),
        spaceAfter=16,
    )
    subtitle = ParagraphStyle(
        "SubtitleCN", parent=styles["BodyText"], fontName="SimHei", fontSize=11,
        leading=20, alignment=TA_CENTER, textColor=colors.HexColor("#526170"),
    )
    h1 = ParagraphStyle(
        "H1CN", parent=styles["Heading1"], fontName="SimHei", fontSize=15,
        leading=23, textColor=colors.HexColor("#1f4e79"), spaceBefore=8,
        spaceAfter=6, keepWithNext=True,
    )
    body = ParagraphStyle(
        "BodyCN", parent=styles["BodyText"], fontName="SimHei", fontSize=9.6,
        leading=17, alignment=TA_JUSTIFY, firstLineIndent=19, spaceAfter=6,
        textColor=colors.HexColor("#202830"),
    )
    bullet = ParagraphStyle(
        "BulletCN", parent=body, alignment=TA_LEFT, firstLineIndent=0,
        leftIndent=14, bulletIndent=2,
    )
    caption = ParagraphStyle(
        "CaptionCN", parent=body, fontSize=8, leading=12, firstLineIndent=0,
        alignment=TA_CENTER, textColor=colors.HexColor("#5b6470"),
    )
    toc_style = ParagraphStyle(
        "TOCCN", parent=body, firstLineIndent=0, leftIndent=8, fontSize=9,
        leading=14,
    )

    doc = SimpleDocTemplate(
        str(output_path), pagesize=A4, leftMargin=21 * mm, rightMargin=21 * mm,
        topMargin=20 * mm, bottomMargin=23 * mm, title=TITLE,
        author="Berger13 13×10 低阶研究模型工作流",
        subject="规定短舱执行器运动对刚体动态的单向影响",
    )

    lines = markdown_path.read_text(encoding="utf-8").splitlines()
    headings = [line[3:].strip() for line in lines if line.startswith("## ")]
    story = [Spacer(1, 38 * mm), Paragraph(f"《{TITLE}》", title_style),
             Spacer(1, 16 * mm),
             Paragraph("Berger13 13 状态 10 输入低阶研究模型", subtitle),
             Paragraph("物理闭合、数值纠偏与内部一致性证据", subtitle),
             Spacer(1, 28 * mm),
             Paragraph("研究边界：规定执行器到刚体的单向影响；不含 Qexternal 双向反馈和机械卡死约束载荷", subtitle),
             Spacer(1, 24 * mm),
             Paragraph("MATLAB R2021a - 2026 年 7 月", subtitle),
             PageBreak(), Paragraph("目录", h1)]
    for heading in headings:
        story.append(Paragraph(markup(heading), toc_style))
    story.append(PageBreak())

    figure_after = {
        "15 配平可信度门禁": ("F01_trim_operating_points.png", "图 1 配平工况与可信度门禁"),
        "17 导数定义与单位": ("F07_stability_derivatives.png", "图 2 代表工况稳定导数"),
        "19 模态分类": ("F09_all_eigenvalues.png", "图 3 动态特征根与独立航向积分根"),
        "21 模态跟踪方法": ("F14_mode_tracking.png", "图 4 独立连续路径模态跟踪"),
        "23 时间步收敛": ("F05_actuator_response.png", "图 5 规定执行器代表响应"),
        "24 分析有效性守卫": ("F18_single_side_kinematic_lock.png", "图 6 运动学锁止及首次守卫越界"),
        "25 线性-非线性一致性": ("F15_linear_nonlinear_comparison.png", "图 7 局部线性-非线性比较"),
        "29 代表时域结果": ("F21_asynchronous_lateral_directional_loads.png", "图 8 有效前缀横航向峰值载荷"),
        "30 参数敏感性": ("F19_parameter_sensitivity.png", "图 9 量纲一致的参数敏感性筛选"),
    }

    for line in lines:
        stripped = line.strip()
        if not stripped or stripped.startswith("# 《"):
            continue
        if stripped.startswith("## "):
            heading = stripped[3:].strip()
            if heading.startswith(("1 ", "7 ", "13 ", "19 ", "25 ", "31 ")) and story:
                story.append(PageBreak())
            story.append(Paragraph(markup(heading), h1))
            if heading in figure_after:
                filename, text = figure_after[heading]
                story.extend(image_block(figure_dir / filename, text, caption))
        elif stripped.startswith("- "):
            story.append(Paragraph(markup(stripped[2:]), bullet, bulletText="•"))
        elif re.match(r"^\d+\. ", stripped):
            story.append(Paragraph(markup(stripped), bullet))
        else:
            story.append(Paragraph(markup(stripped), body))

    doc.build(story, onFirstPage=header_footer, onLaterPages=header_footer)


if __name__ == "__main__":
    main()
