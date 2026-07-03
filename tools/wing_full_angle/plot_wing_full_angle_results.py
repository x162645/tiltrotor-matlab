from __future__ import annotations

import csv
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[2]
FIG = ROOT / "docs" / "wing_full_angle" / "figures"
FIG.mkdir(parents=True, exist_ok=True)


def read_rows(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def to_float(row: dict[str, str], key: str) -> float:
    return float(row[key])


def draw_plot(path: Path, title: str, xlabel: str, ylabel: str, series: list[tuple[str, list[tuple[float, float]]]]) -> None:
    width, height = 1000, 640
    margin_l, margin_r, margin_t, margin_b = 90, 30, 70, 70
    img = Image.new("RGB", (width, height), "white")
    draw = ImageDraw.Draw(img)
    try:
        font = ImageFont.truetype("arial.ttf", 17)
        small = ImageFont.truetype("arial.ttf", 13)
    except Exception:
        font = ImageFont.load_default()
        small = ImageFont.load_default()

    points = [pt for _, pts in series for pt in pts]
    xs = [p[0] for p in points]
    ys = [p[1] for p in points]
    xmin, xmax = min(xs), max(xs)
    ymin, ymax = min(ys), max(ys)
    if xmax == xmin:
        xmax += 1.0
    if ymax == ymin:
        ymax += 1.0
    xpad = 0.03 * (xmax - xmin)
    ypad = 0.08 * (ymax - ymin)
    xmin -= xpad
    xmax += xpad
    ymin -= ypad
    ymax += ypad

    x0, y0 = margin_l, height - margin_b
    x1, y1 = width - margin_r, margin_t
    draw.rectangle((x0, y1, x1, y0), outline="black")
    draw.text((margin_l, 25), title, fill="black", font=font)
    draw.text((width // 2 - 45, height - 38), xlabel, fill="black", font=font)
    draw.text((15, margin_t), ylabel, fill="black", font=font)

    for i in range(6):
        tx = x0 + i * (x1 - x0) / 5
        ty = y0 - i * (y0 - y1) / 5
        draw.line((tx, y1, tx, y0), fill=(230, 230, 230))
        draw.line((x0, ty, x1, ty), fill=(230, 230, 230))
        xv = xmin + i * (xmax - xmin) / 5
        yv = ymin + i * (ymax - ymin) / 5
        draw.text((tx - 22, y0 + 8), f"{xv:.1f}", fill="black", font=small)
        draw.text((25, ty - 8), f"{yv:.2f}", fill="black", font=small)

    colors = [(31, 119, 180), (214, 39, 40), (44, 160, 44), (148, 103, 189), (255, 127, 14), (23, 190, 207)]
    for idx, (label, pts) in enumerate(series):
        color = colors[idx % len(colors)]
        mapped = []
        for x, y in pts:
            px = x0 + (x - xmin) / (xmax - xmin) * (x1 - x0)
            py = y0 - (y - ymin) / (ymax - ymin) * (y0 - y1)
            mapped.append((px, py))
        if len(mapped) > 1:
            draw.line(mapped, fill=color, width=3)
        for px, py in mapped:
            draw.ellipse((px - 3, py - 3, px + 3, py + 3), fill=color)
        ly = margin_t + idx * 20
        draw.line((width - 260, ly + 8, width - 225, ly + 8), fill=color, width=3)
        draw.text((width - 215, ly), label, fill="black", font=small)

    img.save(path)


def group_xfoil(rows: list[dict[str, str]]) -> list[tuple[str, list[tuple[float, float]]]]:
    grouped: dict[tuple[float, float], list[tuple[float, float]]] = {}
    for row in rows:
        key = (to_float(row, "Re"), to_float(row, "Mach"))
        grouped.setdefault(key, []).append((to_float(row, "alpha_deg"), to_float(row, "CL")))
    out = []
    for key, pts in sorted(grouped.items()):
        pts = sorted(pts)
        out.append((f"Re={key[0]/1e6:.1f}e6 M={key[1]:.2f}", pts))
    return out


def main() -> int:
    xfoil = read_rows(ROOT / "data" / "wing_full_angle" / "xfoil_standard" / "parsed" / "xfoil_clean_polars_standard.csv")
    db = read_rows(ROOT / "data" / "wing_full_angle" / "full_angle_selected" / "wing_full_angle_database.csv")
    legacy = read_rows(ROOT / "validation" / "wing_full_angle" / "zero_nacelle_bump" / "legacy_zero_nacelle_7_12_step025.csv")
    full = read_rows(ROOT / "validation" / "wing_full_angle" / "zero_nacelle_bump" / "full_angle_zero_nacelle_7_12_step025.csv")

    draw_plot(FIG / "xfoil_clean_cl_grid.png", "Standard NACA 64A223 XFOIL CL grid", "alpha [deg]", "CL", group_xfoil(xfoil))

    nominal = [r for r in db if abs(to_float(r, "Re") - 1.0e6) < 1 and abs(to_float(r, "Mach")) < 1e-12 and abs(to_float(r, "flap_deg")) < 1e-12]
    draw_plot(
        FIG / "full_angle_database_nominal.png",
        "Full-angle coefficient database, Re=1.0e6 M=0 flap=0",
        "alpha [deg]",
        "coefficient",
        [(key, [(to_float(r, "alpha_deg"), to_float(r, key)) for r in nominal]) for key in ["CL", "CD", "Cm"]],
    )

    draw_plot(
        FIG / "zero_nacelle_theta_comparison.png",
        "0-deg nacelle trim comparison",
        "V [m/s]",
        "trim theta [deg]",
        [
            ("legacy theta", [(to_float(r, "V"), to_float(r, "thetaDeg")) for r in legacy]),
            ("full-angle theta", [(to_float(r, "V"), to_float(r, "thetaDeg")) for r in full]),
        ],
    )

    draw_plot(
        FIG / "branch_weight_removed.png",
        "Legacy blend weight removed from full-angle model",
        "V [m/s]",
        "diagnostic branch weight",
        [
            ("legacy branchWeight", [(to_float(r, "V"), to_float(r, "branchWeight")) for r in legacy]),
            ("full-angle branchWeight", [(to_float(r, "V"), to_float(r, "branchWeight")) for r in full]),
        ],
    )
    print(f"figures written to {FIG}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
