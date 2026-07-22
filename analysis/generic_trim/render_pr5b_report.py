"""Render the generated Chinese Markdown report to a paginated PDF."""
from __future__ import annotations

import argparse
import csv
import re
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (Image, PageBreak, Paragraph, SimpleDocTemplate,
                                Spacer, Table, TableStyle)


FONT_PATH = Path(r"C:\Windows\Fonts\msyh.ttc")


def register_fonts() -> str:
    if FONT_PATH.exists():
        pdfmetrics.registerFont(TTFont("MSYH", str(FONT_PATH), subfontIndex=0))
        return "MSYH"
    return "Helvetica"


def escape(text: str) -> str:
    return (text.replace("&", "&amp;").replace("<", "&lt;")
            .replace(">", "&gt;").replace("`", ""))


def markdown_story(markdown: str, styles: dict) -> list:
    story = []
    lines = markdown.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        if not line:
            story.append(Spacer(1, 2.5*mm)); i += 1; continue
        if line.startswith("# "):
            story.append(Paragraph(escape(line[2:]), styles["title"])); story.append(Spacer(1, 6*mm)); i += 1; continue
        if line.startswith("## "):
            story.append(Paragraph(escape(line[3:]), styles["h2"])); i += 1; continue
        if line.startswith("### "):
            story.append(Paragraph(escape(line[4:]), styles["h3"])); i += 1; continue
        if line.startswith("|"):
            block=[]
            while i < len(lines) and lines[i].strip().startswith("|"):
                block.append(lines[i].strip()); i += 1
            rows=[]
            for j,b in enumerate(block):
                cells=[c.strip() for c in b.strip("|").split("|")]
                if j==1 and all(set(c) <= {"-",":"} for c in cells): continue
                rows.append([Paragraph(escape(c),styles["table"]) for c in cells])
            if rows:
                n=len(rows[0]); widths=[(170*mm)/n]*n
                t=Table(rows,colWidths=widths,repeatRows=1,hAlign="LEFT")
                t.setStyle(TableStyle([("FONTNAME",(0,0),(-1,-1),styles["font"]),
                    ("BACKGROUND",(0,0),(-1,0),colors.HexColor("#D9EAF7")),
                    ("GRID",(0,0),(-1,-1),.35,colors.HexColor("#888888")),
                    ("VALIGN",(0,0),(-1,-1),"TOP"),
                    ("LEFTPADDING",(0,0),(-1,-1),3),("RIGHTPADDING",(0,0),(-1,-1),3)]))
                story.extend([t,Spacer(1,3*mm)])
            continue
        if line.startswith("- "):
            story.append(Paragraph("• "+escape(line[2:]),styles["body"])); i += 1; continue
        para=[line]; i += 1
        while i < len(lines) and lines[i].strip() and not lines[i].lstrip().startswith(("#","|","- ")):
            para.append(lines[i].strip()); i += 1
        story.append(Paragraph(escape(" ".join(para)),styles["body"]))
    return story


def page_number(canvas, doc):
    canvas.saveState(); canvas.setFont(doc._font_name, 8)
    canvas.setFillColor(colors.HexColor("#555555"))
    canvas.drawCentredString(A4[0]/2, 11*mm, f"第 {doc.page} 页")
    canvas.restoreState()


def main() -> None:
    ap=argparse.ArgumentParser(); ap.add_argument("markdown",type=Path); ap.add_argument("pdf",type=Path); args=ap.parse_args()
    font=register_fonts(); base=getSampleStyleSheet()
    styles={"font":font}
    styles["title"]=ParagraphStyle("CNTitle",parent=base["Title"],fontName=font,fontSize=20,leading=30,alignment=TA_CENTER,textColor=colors.HexColor("#17365D"),spaceAfter=8*mm)
    styles["h2"]=ParagraphStyle("CNH2",parent=base["Heading2"],fontName=font,fontSize=15,leading=22,textColor=colors.HexColor("#1F4E79"),spaceBefore=5*mm,spaceAfter=2.5*mm)
    styles["h3"]=ParagraphStyle("CNH3",parent=base["Heading3"],fontName=font,fontSize=12,leading=18,textColor=colors.HexColor("#2F5597"),spaceBefore=3*mm,spaceAfter=2*mm)
    styles["body"]=ParagraphStyle("CNBody",parent=base["BodyText"],fontName=font,fontSize=10.5,leading=18,alignment=TA_JUSTIFY,firstLineIndent=2*10.5,spaceAfter=2*mm)
    styles["caption"]=ParagraphStyle("CNCaption",parent=base["BodyText"],fontName=font,fontSize=9,leading=14,alignment=TA_CENTER,textColor=colors.HexColor("#444444"),spaceAfter=4*mm)
    styles["table"]=ParagraphStyle("CNTable",parent=base["BodyText"],fontName=font,fontSize=7.5,leading=10)
    text=args.markdown.read_text(encoding="utf-8")
    story=markdown_story(text,styles)
    fig_dir=args.markdown.parent/"figures"
    metadata=fig_dir/"FIGURE_METADATA.csv"
    if metadata.exists():
        story.extend([PageBreak(),Paragraph("附录：完整图表",styles["h2"])])
        with metadata.open("r",encoding="utf-8-sig",newline="") as f:
            rows=list(csv.DictReader(f))
        pngs=sorted(fig_dir.glob("*.png"))
        for idx,row in enumerate(rows,1):
            num=int(row["figureNumber"])
            candidates=[p for p in pngs if p.name.startswith(f"{num:02d}_")]
            if not candidates: continue
            im=Image(str(candidates[0])); maxw,maxh=170*mm,105*mm
            scale=min(maxw/im.imageWidth,maxh/im.imageHeight)
            im.drawWidth=im.imageWidth*scale; im.drawHeight=im.imageHeight*scale
            story.extend([Spacer(1,3*mm),im,Paragraph(f"图{num} {escape(row['chineseTitle'])}<br/><font size='8'>{escape(row['claimBoundary'])}</font>",styles["caption"])])
            if num in {7,13,19}: story.append(PageBreak())
    args.pdf.parent.mkdir(parents=True,exist_ok=True)
    doc=SimpleDocTemplate(str(args.pdf),pagesize=A4,rightMargin=20*mm,leftMargin=20*mm,topMargin=18*mm,bottomMargin=18*mm,title="通用倾转旋翼机纵向布局参数设计与转换走廊配平优化研究",author="Codex autonomous research workflow")
    doc._font_name=font
    doc.build(story,onFirstPage=page_number,onLaterPages=page_number)
    print(args.pdf)


if __name__ == "__main__":
    main()
