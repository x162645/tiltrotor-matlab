#!/usr/bin/env python3
"""Make readable contact sheets from rendered thesis pages for visual QA."""

from __future__ import annotations

import argparse
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("render_dir", type=Path)
    p.add_argument("--per-sheet", type=int, default=12)
    args = p.parse_args()
    pages = sorted(
        args.render_dir.glob("page-*.png"),
        key=lambda x: int(x.stem.split("-")[-1]),
    )
    thumb_w, thumb_h = 425, 601
    cols = 3
    rows = math.ceil(args.per_sheet / cols)
    font = ImageFont.truetype(r"C:\Windows\Fonts\arial.ttf", 20)
    for sheet_no, start in enumerate(range(0, len(pages), args.per_sheet), 1):
        subset = pages[start:start + args.per_sheet]
        canvas = Image.new("RGB", (cols * (thumb_w + 20), rows * (thumb_h + 42)), "white")
        draw = ImageDraw.Draw(canvas)
        for slot, page in enumerate(subset):
            image = Image.open(page).convert("RGB")
            image.thumbnail((thumb_w, thumb_h))
            x = (slot % cols) * (thumb_w + 20)
            y = (slot // cols) * (thumb_h + 42) + 30
            canvas.paste(image, (x, y))
            number = int(page.stem.split("-")[-1])
            draw.text((x + 4, 4 + (slot // cols) * (thumb_h + 42)),
                      f"PDF page {number}", fill="black", font=font)
        canvas.save(args.render_dir / f"contact_sheet_{sheet_no:02d}.jpg", quality=88)


if __name__ == "__main__":
    main()
