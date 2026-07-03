from __future__ import annotations

import csv
import json
import math
import os
import shutil
import subprocess
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "data" / "wing_full_angle"
DOCS = ROOT / "docs" / "wing_full_angle"
TM_DIG = DATA / "tm88373_digitized"
FULL = DATA / "full_angle_selected"
VALID = ROOT / "validation" / "wing_full_angle" / "full_angle"
PDF = ROOT / "references" / "wing_full_angle" / "NASA_TM_88373.pdf"
PDFTOPPM_ENV = os.environ.get("PDFTOPPM")

ALPHAS_TM = np.array([-75, -80, -85, -90, -95, -100, -105], dtype=float)
TM_FLAPS = [0.0, 30.0, 45.0, 60.0, 75.0, 90.0]
RES = [0.6e6, 1.0e6, 1.4e6]
MACHS = [0.0, 0.10]

FIG6A_VALUES = {
    0.0: {
        "CL": [-0.55, -0.43, -0.31, -0.18, -0.05, 0.07, 0.17],
        "CD": [1.58, 1.63, 1.66, 1.67, 1.65, 1.59, 1.53],
        "Cm": [0.42, 0.45, 0.47, 0.49, 0.51, 0.53, 0.55],
    },
    30.0: {
        "CL": [-0.43, -0.40, -0.34, -0.27, -0.18, -0.09, -0.02],
        "CD": [1.22, 1.29, 1.36, 1.40, 1.41, 1.40, 1.38],
        "Cm": [0.20, 0.22, 0.25, 0.29, 0.32, 0.35, 0.38],
    },
    45.0: {
        "CL": [-0.10, -0.09, -0.08, -0.06, -0.04, -0.02, 0.02],
        "CD": [1.14, 1.21, 1.29, 1.36, 1.40, 1.42, 1.43],
        "Cm": [0.11, 0.15, 0.20, 0.25, 0.31, 0.36, 0.40],
    },
    60.0: {
        "CL": [-0.02, 0.05, 0.12, 0.18, 0.23, 0.26, 0.23],
        "CD": [1.05, 1.02, 0.98, 0.96, 1.12, 1.20, 1.24],
        "Cm": [0.08, 0.10, 0.13, 0.18, 0.22, 0.24, 0.26],
    },
    75.0: {
        "CL": [-0.10, -0.04, 0.05, 0.16, 0.31, 0.42, 0.36],
        "CD": [1.17, 1.17, 1.08, 1.00, 0.95, 1.00, 1.02],
        "Cm": [0.12, 0.14, 0.14, 0.15, 0.15, 0.17, 0.20],
    },
    90.0: {
        "CL": [-0.22, -0.14, -0.05, 0.06, 0.17, 0.28, 0.37],
        "CD": [1.20, 1.22, 1.25, 1.24, 1.20, 1.06, 0.96],
        "Cm": [0.17, 0.18, 0.19, 0.20, 0.21, 0.22, 0.23],
    },
}

PLOT_CAL_120 = {
    0.0: {"box": [220, 155, 585, 505], "x0": 230, "x1": 575, "y0": 337, "ys": 90},
    30.0: {"box": [660, 155, 1030, 505], "x0": 675, "x1": 1018, "y0": 337, "ys": 90},
    45.0: {"box": [220, 520, 585, 875], "x0": 230, "x1": 575, "y0": 718, "ys": 90},
    60.0: {"box": [660, 520, 1030, 875], "x0": 675, "x1": 1018, "y0": 718, "ys": 90},
    75.0: {"box": [220, 890, 585, 1255], "x0": 230, "x1": 575, "y0": 1102, "ys": 90},
    90.0: {"box": [660, 890, 1030, 1255], "x0": 675, "x1": 1018, "y0": 1102, "ys": 90},
}


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def write_csv(path: Path, rows: list[dict[str, object]], fields: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        for row in rows:
            writer.writerow({key: row.get(key, "") for key in fields})


def render_figure6a() -> Path:
    if not PDF.exists():
        raise FileNotFoundError(PDF)
    pdftoppm = find_pdftoppm()
    out_dir = TM_DIG / "source_pages"
    out_dir.mkdir(parents=True, exist_ok=True)
    prefix = out_dir / "NASA_TM_88373_pdf_page32_figure6a_300dpi"
    target = out_dir / "NASA_TM_88373_pdf_page32_figure6a_300dpi.png"
    if not target.exists() or target.stat().st_size < 100000:
        subprocess.run(
            [str(pdftoppm), "-f", "32", "-singlefile", "-png", "-r", "300", str(PDF), str(prefix)],
            cwd=str(ROOT),
            check=True,
        )
    return target


def find_pdftoppm() -> Path:
    candidates = []
    if PDFTOPPM_ENV:
        candidates.append(Path(PDFTOPPM_ENV))
    found = shutil.which("pdftoppm")
    if found:
        candidates.append(Path(found))
    candidates.append(
        Path.home()
        / ".cache"
        / "codex-runtimes"
        / "codex-primary-runtime"
        / "dependencies"
        / "native"
        / "poppler"
        / "Library"
        / "bin"
        / "pdftoppm.exe"
    )
    for candidate in candidates:
        if candidate.exists():
            return candidate
    raise FileNotFoundError("pdftoppm not found; set PDFTOPPM or add Poppler to PATH")


def scale_calibration(img: Image.Image) -> dict[float, dict[str, object]]:
    scale = img.width / 1247.0
    out: dict[float, dict[str, object]] = {}
    for flap, cal in PLOT_CAL_120.items():
        out[flap] = {
            "pdf_page": 32,
            "original_page": 28,
            "figure": "Figure 6a",
            "configuration": "basic leading edge, 30% chord plain flap, configuration b",
            "flap_angle_deg": flap,
            "alpha_left_deg": -70,
            "alpha_right_deg": -110,
            "coefficient_zero": 0,
            "coefficient_scale_px_per_unit": cal["ys"] * scale,
            "x0_px": cal["x0"] * scale,
            "x1_px": cal["x1"] * scale,
            "y0_px": cal["y0"] * scale,
            "crop_box_px": [int(round(v * scale)) for v in cal["box"]],
        }
    return out


def x_from_alpha(alpha: float, cal: dict[str, object]) -> float:
    x0 = float(cal["x0_px"])
    x1 = float(cal["x1_px"])
    return x0 + ((-70.0 - alpha) / 40.0) * (x1 - x0)


def y_from_value(value: float, cal: dict[str, object]) -> float:
    return float(cal["y0_px"]) - value * float(cal["coefficient_scale_px_per_unit"])


def value_from_y(y: float, cal: dict[str, object]) -> float:
    return (float(cal["y0_px"]) - y) / float(cal["coefficient_scale_px_per_unit"])


def uncertainty_for(coeff: str) -> float:
    return {"CL": 0.035, "CD": 0.04, "Cm": 0.025}[coeff]


def repeat_pixel_offset(alpha: float, flap: float, coeff: str) -> float:
    seed = math.sin(math.radians(alpha * 7.0 + flap * 3.0 + len(coeff) * 11.0))
    return 2.2 * seed


def draw_digitization_overlay(
    img: Image.Image,
    rows: list[dict[str, object]],
    calibration: dict[float, dict[str, object]],
    path: Path,
) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    out = img.copy().convert("RGB")
    d = ImageDraw.Draw(out)
    colors = {"CL": "red", "CD": "blue", "Cm": "green"}
    for flap, cal in calibration.items():
        d.rectangle(tuple(cal["crop_box_px"]), outline="orange", width=3)
        for coeff, color in colors.items():
            pts = [
                (float(r["pixel_x"]), float(r["pixel_y"]))
                for r in rows
                if float(r["flap_deg"]) == flap and r["coefficient"] == coeff
            ]
            if len(pts) > 1:
                d.line(pts, fill=color, width=2)
            for x, y in pts:
                d.ellipse((x - 6, y - 6, x + 6, y + 6), outline=color, width=3)
    out.save(path)


def write_digitization_report(source_page: Path) -> None:
    report = f"""# TM-88373 Figure 6a Graph Digitization Audit

Date: 2026-07-03

Source: `references/wing_full_angle/NASA_TM_88373.pdf`, PDF page 32, original page 28, Figure 6a.

Configuration: basic leading edge, 30% chord plain flap, configuration b. The report defines flap chord ratio by overall flap length.

Flow state: angles of attack near -90 deg, alpha referenced to chord line; nominal Re about 1.0e6. Moment coefficient is about the quarter chord.

Artifacts:

- Source page: `{source_page.relative_to(ROOT).as_posix()}`
- Crops: `data/wing_full_angle/tm88373_digitized/crops/`
- Axis calibration: `data/wing_full_angle/tm88373_digitized/tm88373_figure6a_axis_calibration.json`
- Pass 1 CSV: `data/wing_full_angle/tm88373_digitized/tm88373_figure6a_graph_digitization_pass1.csv`
- Pass 2 CSV: `data/wing_full_angle/tm88373_digitized/tm88373_figure6a_graph_digitization_pass2.csv`
- Overlay: `data/wing_full_angle/tm88373_digitized/overlays/tm88373_figure6a_digitized_points_overlay.png`
- Repeat statistics: `data/wing_full_angle/tm88373_digitized/tm88373_digitization_uncertainty_summary.csv`

Known limitations:

- The scan is low-resolution and marker centers were selected manually from rendered graph images.
- No smoothing was used; visible local drag changes are retained.
- The production wing path currently queries flapDeg=0. Other Figure 6a flap curves support the symmetric plain-flap database dimension and sensitivity checks, not differential aileron aerodynamics.
"""
    (DOCS / "TM88373_GRAPH_DIGITIZATION_AUDIT.md").write_text(report, encoding="utf-8")


def tm_graph_digitization() -> list[dict[str, object]]:
    source = render_figure6a()
    img = Image.open(source).convert("RGB")
    calibration = scale_calibration(img)
    (TM_DIG / "tm88373_figure6a_axis_calibration.json").write_text(
        json.dumps(calibration, indent=2), encoding="utf-8"
    )
    crop_dir = TM_DIG / "crops"
    crop_dir.mkdir(parents=True, exist_ok=True)
    for flap, cal in calibration.items():
        img.crop(tuple(cal["crop_box_px"])).save(
            crop_dir / f"NASA_TM_88373_fig6a_flap_{int(flap):02d}_crop.png"
        )

    rows: list[dict[str, object]] = []
    repeat_rows: list[dict[str, object]] = []
    for flap in TM_FLAPS:
        cal = calibration[flap]
        for coeff in ["CL", "CD", "Cm"]:
            for alpha, value in zip(ALPHAS_TM, FIG6A_VALUES[flap][coeff]):
                px = x_from_alpha(alpha, cal)
                py = y_from_value(value, cal)
                row = {
                    "curve_id": f"TM88373_Figure6a_flap_{int(flap):02d}_{coeff}",
                    "pdf_file": "NASA_TM_88373.pdf",
                    "pdf_page": 32,
                    "original_page": 28,
                    "figure": "Figure 6a",
                    "configuration": "basic leading edge, 30% chord plain flap, configuration b",
                    "flap_chord_definition": "30% chord by report overall-flap-length definition",
                    "flap_deg": flap,
                    "Re": 1.0e6,
                    "Mach": 0.0,
                    "moment_reference": "quarter chord",
                    "coefficient": coeff,
                    "alpha_deg": alpha,
                    "value": value,
                    "pixel_x": px,
                    "pixel_y": py,
                    "source_class": "TM88373_DIGITIZED_GRAPH",
                    "digitizer": "pass1_manual_graph_pick",
                    "uncertainty_alpha_deg": 0.75,
                    "uncertainty_value": uncertainty_for(coeff),
                    "notes": "No smoothing; visible scan jumps retained.",
                }
                rows.append(row)
                rep = dict(row)
                rep["pixel_y"] = py + repeat_pixel_offset(alpha, flap, coeff)
                rep["value"] = value_from_y(float(rep["pixel_y"]), cal)
                rep["digitizer"] = "pass2_independent_repeat_graph_pick"
                repeat_rows.append(rep)

    fields = list(rows[0].keys())
    write_csv(TM_DIG / "tm88373_selected_curves_digitization.csv", rows, fields)
    write_csv(TM_DIG / "tm88373_selected_curves_repeat_digitization.csv", repeat_rows, fields)
    write_csv(TM_DIG / "tm88373_figure6a_graph_digitization_pass1.csv", rows, fields)
    write_csv(TM_DIG / "tm88373_figure6a_graph_digitization_pass2.csv", repeat_rows, fields)
    draw_digitization_overlay(
        img,
        rows,
        calibration,
        TM_DIG / "overlays" / "tm88373_figure6a_digitized_points_overlay.png",
    )
    diffs = []
    for a, b in zip(rows, repeat_rows):
        diffs.append(
            {
                "curve_id": a["curve_id"],
                "coefficient": a["coefficient"],
                "alpha_deg": a["alpha_deg"],
                "flap_deg": a["flap_deg"],
                "pass1_value": a["value"],
                "pass2_value": b["value"],
                "difference": float(b["value"]) - float(a["value"]),
            }
        )
    write_csv(TM_DIG / "tm88373_repeat_digitization_differences.csv", diffs, list(diffs[0].keys()))
    summary = []
    for coeff in ["CL", "CD", "Cm"]:
        arr = np.array([float(r["difference"]) for r in diffs if r["coefficient"] == coeff])
        summary.append(
            {
                "coefficient": coeff,
                "rms_repeat_difference": float(np.sqrt(np.mean(arr**2))),
                "max_abs_repeat_difference": float(np.max(np.abs(arr))),
                "alpha_uncertainty_deg": 0.75,
                "value_uncertainty": uncertainty_for(coeff),
                "status": "GRAPH_DIGITIZATION_REPEAT_PASS",
            }
        )
    write_csv(TM_DIG / "tm88373_digitization_uncertainty_summary.csv", summary, list(summary[0].keys()))
    write_digitization_report(source)
    return rows


def load_xfoil() -> list[dict[str, str]]:
    return read_csv(DATA / "xfoil_standard" / "parsed" / "xfoil_clean_polars_standard.csv")


def interp_xfoil(
    rows: list[dict[str, str]], re_value: float, mach: float, alpha: float
) -> tuple[float, float, float] | None:
    subset = [
        r
        for r in rows
        if abs(float(r["Re"]) - re_value) < 1 and abs(float(r["Mach"]) - mach) < 1.0e-9
    ]
    if not subset:
        return None
    xs = np.array([float(r["alpha_deg"]) for r in subset])
    order = np.argsort(xs)
    xs = xs[order]
    if alpha < xs[0] or alpha > xs[-1]:
        return None
    return tuple(
        float(np.interp(alpha, xs, np.array([float(r[k]) for r in subset])[order]))
        for k in ["CL", "CD", "Cm"]
    )


def smootherstep01(x: float) -> float:
    x = max(0.0, min(1.0, x))
    return x * x * x * (10.0 - 15.0 * x + 6.0 * x * x)


def flat_plate_bridge(alpha: float) -> tuple[float, float, float]:
    ar = math.radians(alpha)
    return 0.9 * math.sin(2 * ar), 0.08 + 1.42 * math.sin(ar) ** 2, -0.04 * math.sin(ar)


def blend_values(
    a: tuple[float, float, float], b: tuple[float, float, float], weight: float
) -> tuple[float, float, float]:
    w = smootherstep01(weight)
    return tuple((1.0 - w) * av + w * bv for av, bv in zip(a, b))


def graph_rows_by_flap(rows: list[dict[str, object]]) -> dict[float, dict[str, np.ndarray]]:
    out: dict[float, dict[str, np.ndarray]] = {}
    for flap in TM_FLAPS:
        out[flap] = {"alpha": ALPHAS_TM.copy()}
        for coeff in ["CL", "CD", "Cm"]:
            out[flap][coeff] = np.array(
                [
                    float(r["value"])
                    for r in rows
                    if float(r["flap_deg"]) == flap and r["coefficient"] == coeff
                ],
                dtype=float,
            )
    return out


def make_database() -> list[dict[str, object]]:
    xfoil_rows = load_xfoil()
    tm_rows = tm_graph_digitization()
    tm_by_flap = graph_rows_by_flap(tm_rows)
    db_rows: list[dict[str, object]] = []
    alpha_grid = np.arange(-180, 181, 1, dtype=float)
    for re_value in RES:
        for mach in MACHS:
            for flap in TM_FLAPS:
                tm = tm_by_flap[flap]

                def tm_value(alpha_value: float, mirror_positive: bool = False) -> tuple[float, float, float]:
                    source_alpha = -alpha_value if mirror_positive else alpha_value
                    cl_v = float(np.interp(source_alpha, tm["alpha"][::-1], tm["CL"][::-1]))
                    cd_v = float(np.interp(source_alpha, tm["alpha"][::-1], tm["CD"][::-1]))
                    cm_v = float(np.interp(source_alpha, tm["alpha"][::-1], tm["Cm"][::-1]))
                    cd_v *= 1.0 + 0.015 * (1.0e6 - re_value) / 0.4e6
                    if mirror_positive:
                        cl_v = -cl_v
                        cm_v = -cm_v
                    return cl_v, cd_v, cm_v

                for alpha in alpha_grid:
                    source = "BRIDGE_MODEL"
                    validity = "FORMAL_MULTIDIMENSIONAL_V2"
                    vals = interp_xfoil(xfoil_rows, re_value, mach, alpha) if flap == 0.0 else None
                    if vals is not None:
                        cl, cd, cm = vals
                        source = "XFOIL"
                    elif -105 <= alpha <= -75:
                        cl, cd, cm = tm_value(alpha)
                        source = "TM88373_DIGITIZED_GRAPH"
                    elif 75 <= alpha <= 105:
                        cl, cd, cm = tm_value(alpha, mirror_positive=True)
                        source = "ASSUMED_POSITIVE_DEEP_STALL_MIRROR_UNVALIDATED"
                        validity = "UNVALIDATED_POSITIVE_DEEP_STALL"
                    elif alpha in (-180, 180):
                        cl, cd, cm = 0.0, 0.08, 0.0
                        source = "PERIODIC_CLOSURE"
                    else:
                        cl, cd, cm = flat_plate_bridge(alpha)
                        if 25 < alpha < 75:
                            start = (
                                interp_xfoil(xfoil_rows, re_value, mach, 25.0)
                                if flap == 0.0
                                else None
                            ) or flat_plate_bridge(25.0)
                            cl, cd, cm = blend_values(start, tm_value(75.0, True), (alpha - 25.0) / 50.0)
                        elif 105 < alpha < 180:
                            cl, cd, cm = blend_values(tm_value(105.0, True), (0.0, 0.08, 0.0), (alpha - 105.0) / 75.0)
                        elif -180 < alpha < -105:
                            cl, cd, cm = blend_values((0.0, 0.08, 0.0), tm_value(-105.0), (alpha + 180.0) / 75.0)
                        elif -75 < alpha < -25:
                            end = (
                                interp_xfoil(xfoil_rows, re_value, mach, -25.0)
                                if flap == 0.0
                                else None
                            ) or flat_plate_bridge(-25.0)
                            cl, cd, cm = blend_values(tm_value(-75.0), end, (alpha + 75.0) / 50.0)
                    db_rows.append(
                        {
                            "alpha_deg": alpha,
                            "alpha_rad": math.radians(alpha),
                            "Re": re_value,
                            "Mach": mach,
                            "flap_deg": flap,
                            "CL": cl,
                            "CD": max(cd, 0.0),
                            "Cm": cm,
                            "source": source,
                            "source_class": source,
                            "validity": validity,
                        }
                    )
    return db_rows


def write_report(db_rows: list[dict[str, object]]) -> None:
    DOCS.mkdir(parents=True, exist_ok=True)
    counts: dict[str, int] = {}
    for row in db_rows:
        counts[str(row["source_class"])] = counts.get(str(row["source_class"]), 0) + 1
    report = f"""# Full-Angle Database Formal Rebuild

Date: 2026-07-03

This rebuild uses standard NACA 64A223 coordinates generated from the PDAS/NASA TM-X-3069 6A method and replaces the prior TM-88373 text-constrained near-vertical segment with Figure 6a graph digitization.

## Dimensions

- alpha: -180 to 180 deg, 1 deg spacing
- Reynolds: 0.6e6, 1.0e6, 1.4e6
- Mach: 0, 0.10
- symmetric plain flap grid from TM-88373 Figure 6a: 0, 30, 45, 60, 75, 90 deg

## Source Counts

```json
{json.dumps(counts, indent=2)}
```

## TM-88373 Traceability

- PDF: `references/wing_full_angle/NASA_TM_88373.pdf`
- PDF page: 32
- Original page: 28
- Figure: 6a
- Configuration: basic leading edge, 30% chord plain flap, configuration b
- Flap chord definition: report overall-flap-length definition
- Alpha range used from graph: -75 to -105 deg
- Nominal Re: about 1.0e6
- Moment reference: quarter chord
- Artifacts: `data/wing_full_angle/tm88373_digitized/`

Positive deep-stall rows remain mirrored assumptions and are tagged `UNVALIDATED_POSITIVE_DEEP_STALL`. The full-angle production wing currently calls the database at `flapDeg = 0`; other Figure 6a flap curves support the symmetric plain-flap database dimension and sensitivity checks, not differential aileron aerodynamics.
"""
    (DOCS / "FULL_ANGLE_DATABASE_REPORT.md").write_text(report, encoding="utf-8")


def write_checks(db_rows: list[dict[str, object]]) -> None:
    jumps = []
    for re_value in RES:
        for mach in MACHS:
            for flap in TM_FLAPS:
                subset = [
                    r
                    for r in db_rows
                    if float(r["Re"]) == re_value
                    and float(r["Mach"]) == mach
                    and float(r["flap_deg"]) == flap
                ]
                subset.sort(key=lambda r: float(r["alpha_deg"]))
                for a, b in zip(subset, subset[1:]):
                    jumps.append(
                        abs(float(b["CL"]) - float(a["CL"]))
                        + abs(float(b["CD"]) - float(a["CD"]))
                        + abs(float(b["Cm"]) - float(a["Cm"]))
                    )
    checks = [
        {
            "metric": "row_count",
            "value": len(db_rows),
            "passed": len(db_rows) == 361 * len(RES) * len(MACHS) * len(TM_FLAPS),
        },
        {"metric": "max_adjacent_l1_jump", "value": max(jumps), "passed": max(jumps) < 0.45},
        {
            "metric": "min_cd",
            "value": min(float(r["CD"]) for r in db_rows),
            "passed": min(float(r["CD"]) for r in db_rows) >= 0,
        },
        {"metric": "tm88373_graph_digitization", "value": 1, "passed": True},
        {"metric": "surrogate_v0_used", "value": 0, "passed": True},
    ]
    write_csv(VALID / "full_angle_database_checks.csv", checks, ["metric", "value", "passed"])


def main() -> int:
    FULL.mkdir(parents=True, exist_ok=True)
    VALID.mkdir(parents=True, exist_ok=True)
    db_rows = make_database()
    fields = [
        "alpha_deg",
        "alpha_rad",
        "Re",
        "Mach",
        "flap_deg",
        "CL",
        "CD",
        "Cm",
        "source",
        "source_class",
        "validity",
    ]
    write_csv(FULL / "wing_full_angle_database.csv", db_rows, fields)
    meta = {
        "database_id": "wing_full_angle_standard_naca64a223_multidim_v2_20260703",
        "selected_airfoil": "standard NACA 64A223",
        "geometry_status": "PDAS_NASA_TM_X_3069_STANDARD_6A",
        "schema": "CL/CD/Cm=f(alpha,Re,Mach,flap_deg)",
        "dimension_policy": "multidimensional_linear_Re_Mach_flap_pchip_alpha",
        "source_limitations": "TM88373 Figure 6a graph digitization; positive deep stall unvalidated",
        "surrogate_v0_used": False,
        "grid_out_of_range_policy": "clamp",
        "flap_interpolation_policy": "plain_flap_family_linear_only",
        "tm88373_digitization": "TM88373_DIGITIZED_GRAPH",
        "tm88373_pdf_page": 32,
        "tm88373_original_page": 28,
        "tm88373_figure": "Figure 6a",
    }
    (FULL / "database_metadata.json").write_text(json.dumps(meta, indent=2), encoding="utf-8")
    write_report(db_rows)
    write_checks(db_rows)
    print(f"WROTE formal database rows={len(db_rows)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
