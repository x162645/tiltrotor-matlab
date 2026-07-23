#!/usr/bin/env python3
"""Render every thesis PDF page and produce contact sheets for visual QA."""

from __future__ import annotations

import argparse
from pathlib import Path

import pypdfium2 as pdfium
from PIL import Image, ImageDraw, ImageFont


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("pdf", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    pdf = pdfium.PdfDocument(str(args.pdf))
    thumbs = []
    font_path = Path(r"C:\Windows\Fonts\msyh.ttc")
    font = ImageFont.truetype(str(font_path), 18)
    for i, page in enumerate(pdf):
        bitmap = page.render(scale=1.25)
        image = bitmap.to_pil().convert("RGB")
        page_path = args.output / f"page-{i+1:03d}.png"
        image.save(page_path)
        thumb = image.copy()
        thumb.thumbnail((260, 370))
        thumbs.append((i + 1, thumb))
    for batch_start in range(0, len(thumbs), 20):
        batch = thumbs[batch_start:batch_start + 20]
        sheet = Image.new("RGB", (5 * 290, 4 * 410), "white")
        draw = ImageDraw.Draw(sheet)
        for j, (page_no, thumb) in enumerate(batch):
            x = (j % 5) * 290 + 15
            y = (j // 5) * 410 + 28
            sheet.paste(thumb, (x, y))
            draw.text((x, 4 + (j // 5) * 410), f"第{page_no}页", font=font, fill="black")
        sheet.save(args.output / f"contact-{batch_start+1:03d}-{batch_start+len(batch):03d}.png")
    print(f"rendered_pages={len(thumbs)}")


if __name__ == "__main__":
    main()
