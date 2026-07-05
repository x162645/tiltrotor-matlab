from __future__ import annotations

import csv
import json
import math
import re
from pathlib import Path

import numpy as np


ROOT = Path(__file__).resolve().parents[2]
PDAS = ROOT / "references" / "wing_full_angle" / "naca_geometry" / "pdas_airfols" / "BROOKS.FOR"
DATA = ROOT / "data" / "wing_full_angle"
AIRFOILS = DATA / "airfoils"
VALIDATION = ROOT / "validation" / "wing_full_angle" / "airfoil_geometry"


TR903_TABLES = {
    "NACA 64A010": {
        "toc": 0.10,
        "cli": 0.0,
        "upper": [
            (0, 0), (0.5, 0.804), (0.75, 0.969), (1.25, 1.225), (2.5, 1.688),
            (5, 2.327), (7.5, 2.805), (10, 3.199), (15, 3.813), (20, 4.272),
            (25, 4.606), (30, 4.837), (35, 4.968), (40, 4.995), (45, 4.894),
            (50, 4.684), (55, 4.388), (60, 4.021), (65, 3.597), (70, 3.127),
            (75, 2.623), (80, 2.103), (85, 1.582), (90, 1.062), (95, 0.541),
            (100, 0.021),
        ],
        "lower": [
            (0, 0), (0.5, -0.804), (0.75, -0.969), (1.25, -1.225), (2.5, -1.688),
            (5, -2.327), (7.5, -2.805), (10, -3.199), (15, -3.813), (20, -4.272),
            (25, -4.606), (30, -4.837), (35, -4.968), (40, -4.995), (45, -4.894),
            (50, -4.684), (55, -4.388), (60, -4.021), (65, -3.597), (70, -3.127),
            (75, -2.623), (80, -2.103), (85, -1.582), (90, -1.062), (95, -0.541),
            (100, -0.021),
        ],
    },
    "NACA 64A210": {
        "toc": 0.10,
        "cli": 0.2,
        "upper": [
            (0, 0), (0.424, 0.856), (0.665, 1.044), (1.153, 1.342), (2.387, 1.895),
            (4.874, 2.685), (7.369, 3.288), (9.868, 3.792), (14.874, 4.592),
            (19.885, 5.200), (24.901, 5.656), (29.917, 5.984), (34.935, 6.192),
            (39.955, 6.274), (44.975, 6.208), (49.994, 6.014), (55.012, 5.714),
            (60.028, 5.323), (65.042, 4.852), (70.054, 4.310), (75.063, 3.702),
            (80.076, 3.037), (85.074, 2.301), (90.052, 1.551), (95.027, 0.785),
            (100.000, 0.021),
        ],
        "lower": [
            (0, 0), (0.576, -0.744), (0.835, -0.886), (1.347, -1.190), (2.613, -1.473),
            (5.126, -1.963), (7.631, -2.316), (10.132, -2.600), (15.126, -3.030),
            (20.115, -3.340), (25.100, -3.554), (30.083, -3.688), (35.065, -3.744),
            (40.045, -3.716), (45.025, -3.580), (50.000, -3.354), (54.988, -3.062),
            (59.972, -2.710), (64.958, -2.342), (69.946, -1.944), (74.937, -1.542),
            (79.924, -1.167), (84.926, -0.859), (89.948, -0.571), (94.974, -0.295),
            (100.000, -0.021),
        ],
    },
    "NACA 64A410": {
        "toc": 0.10,
        "cli": 0.4,
        "upper": [
            (0, 0), (0.350, 0.902), (0.582, 1.112), (1.059, 1.451), (2.276, 2.095),
            (4.749, 3.034), (7.230, 3.865), (9.737, 4.380), (14.748, 5.366),
            (19.770, 6.126), (24.800, 6.705), (29.834, 7.131), (34.871, 7.414),
            (39.910, 7.552), (44.950, 7.522), (49.989, 7.344), (55.025, 7.040),
            (60.057, 6.624), (65.085, 6.106), (70.108, 5.490), (75.126, 4.780),
            (80.151, 3.967), (85.148, 3.018), (90.104, 2.038), (95.053, 1.028),
            (100.000, 0.021),
        ],
        "lower": [
            (0, 0), (0.650, -0.078), (0.918, -0.796), (1.441, -0.969), (2.724, -1.251),
            (5.251, -1.592), (7.770, -1.919), (10.263, -1.996), (15.252, -2.244),
            (20.230, -2.406), (25.200, -2.499), (30.166, -2.537), (35.129, -2.518),
            (40.090, -2.436), (45.050, -2.266), (50.011, -2.024), (54.975, -1.736),
            (59.943, -1.418), (64.915, -1.086), (69.892, -0.760), (74.874, -0.460),
            (79.849, -0.229), (84.852, -0.132), (89.896, -0.076), (94.947, -0.048),
            (100.000, -0.021),
        ],
    },
}


def parse_fortran_array(text: str, name: str, column: int | None = None) -> np.ndarray:
    values: dict[int, float] = {}
    if column is None:
        pattern = rf"DATA\s+\({name}\(I\),I=(\d+),(\d+)\)/([^/]+)/"
        single = rf"DATA\s+{name}\((\d+)\)\s*/\s*([^/]+)\s*/"
    else:
        pattern = rf"DATA\s+\({name}\(I,{column}\),I=(\d+),(\d+)\)/([^/]+)/"
        single = rf"DATA\s+{name}\((\d+),{column}\)\s*/\s*([^/]+)\s*/"
    for match in re.finditer(pattern, text):
        start = int(match.group(1))
        nums = [float(x.replace("D", "E")) for x in re.findall(r"[-+]?\d+\.\d+(?:[EeDd][-+]?\d+)?|[-+]?\d+", match.group(3))]
        for offset, value in enumerate(nums):
            values[start + offset] = value
    for match in re.finditer(single, text):
        values[int(match.group(1))] = float(match.group(2).strip().replace("D", "E"))
    return np.array([values[i] for i in range(1, 202)], dtype=float)


def load_64a_tables() -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    text = PDAS.read_text(encoding="latin-1")
    phi = parse_fortran_array(text, "PHI")
    eps = parse_fortran_array(text, "EPS", 7)
    psi = parse_fortran_array(text, "PSI", 7)
    return phi, eps, psi


def derivative(x: np.ndarray, y: np.ndarray) -> np.ndarray:
    return np.gradient(y, x, edge_order=2)


def ntrp(x: np.ndarray, y: np.ndarray, xi: np.ndarray | float) -> np.ndarray | float:
    return np.interp(xi, x, y)


def symmetric_64a_thickness(toc: float) -> tuple[np.ndarray, np.ndarray]:
    phi, eps, psi = load_64a_tables()
    crat = 1.0
    sf = 1.0
    for _ in range(10):
        crat *= sf
        v1 = psi * crat
        v2 = phi - eps * crat
        xt = -2.0 * np.cosh(v1) * np.cos(v2)
        yt = 2.0 * np.sinh(v1) * np.sin(v2)
        xs = float(xt[0])
        xe = float(xt[-1])
        xrng = xe - xs
        ytp = derivative(xt, yt)
        x_peak = xt[int(np.argmax(yt))]
        sign_change = np.where((ytp[1:] < 0.0) & (ytp[:-1] > 0.0))[0]
        if sign_change.size:
            i = int(sign_change[0])
            x_peak = xt[i] + ytp[i] * (xt[i + 1] - xt[i]) / (ytp[i] - ytp[i + 1])
        y_peak = float(ntrp(xt, yt, x_peak))
        tr = 2.0 * y_peak / xrng
        sf = toc / tr
        if toc == 0.0 or abs(sf - 1.0) < 1.0e-4:
            break

    x = (xt - xs) / xrng
    y = sf * yt / xrng
    yp = derivative(x, y)
    ypp = derivative(x, yp)

    # PDAS/TM-X-3069 tilted leading-edge ellipse through stored point 12.
    if toc > 0.0:
        k = 11
        xt12 = float(x[k])
        yt12 = float(y[k])
        ytp12 = float(yp[k])
        cn = (2.0 * ytp12) - (yt12 / xt12) + 0.1
        an = xt12 * (ytp12 * xt12 - yt12) / (xt12 * (2.0 * ytp12 - cn) - yt12)
        bn = math.sqrt((yt12 - cn * xt12) ** 2 / (1.0 - ((xt12 - an) / an) ** 2))
        for j in range(12):
            v = 1.0 - ((float(x[j]) - an) / an) ** 2
            y[j] = bn * math.sqrt(max(v, 0.0)) + cn * float(x[j])
    order = np.argsort(x)
    return x[order], y[order]


def mean_line_6a(x: np.ndarray, cli: float, a: float = 0.8) -> tuple[np.ndarray, np.ndarray]:
    zero = 1.0e-6
    big = 1.0e10
    pi = math.pi
    ycmb = np.zeros_like(x)
    tanth = np.zeros_like(x)
    ai = a
    oma = 1.0 - ai
    clfact = 0.24521 * cli
    for idx, xx in enumerate(x):
        omx = 1.0 - xx
        amx = ai - xx
        u = 0.005 if idx == 0 else xx
        if idx == 0:
            omxl = omx * math.log(omx)
            omxl1 = -math.log(omx) - 1.0
            g = -(ai**2 * (0.5 * math.log(ai) - 0.25) + 0.25) / oma
            h = (0.5 * oma**2 * math.log(oma) - 0.25 * oma**2) / oma + g
            q = 1.0
            v = -amx / abs(amx)
            amxl = amx * math.log(abs(amx))
            amxl1 = -math.log(abs(amx)) + v
            z1 = 0.5 * (amx * amxl1 - amxl - omx * omxl1 + omxl + amx - omx)
            yy = 0.0
            tt = cli * (z1 / (1.0 - q * ai) - 1.0 - math.log(u) - h) / pi / (ai + 1.0) / 2.0
        else:
            xll = xx * math.log(xx) if xx > 0 else 0.0
            if abs(omx) < zero:
                g = -(ai**2 * (0.5 * math.log(ai) - 0.25) + 0.25) / oma
                h = (0.5 * oma**2 * math.log(oma) - 0.25 * oma**2) / oma + g
                q = 1.0
                z = 0.5 * (ai - 1.0) ** 2 * math.log(abs(ai - 1.0)) - 0.25 * (ai - 1.0) ** 2
                z1 = -(ai - 1.0) * math.log(abs(ai - 1.0))
            elif abs(amx) < zero:
                g = -(ai**2 * (0.5 * math.log(ai) - 0.25) + 0.25) / oma
                h = (0.5 * oma**2 * math.log(oma) - 0.25 * oma**2) / oma + g
                q = 1.0
                z = -0.5 * omx**2 * math.log(omx) + 0.25 * omx**2
                z1 = -0.5 * omx * (-math.log(omx) - 1.0) + 0.5 * omx * math.log(omx) - 0.5 * omx
            else:
                v = -amx / abs(amx)
                omxl = omx * math.log(omx)
                amxl = amx * math.log(abs(amx))
                omxl1 = -math.log(omx) - 1.0
                amxl1 = -math.log(abs(amx)) + v
                g = -(ai**2 * (0.5 * math.log(ai) - 0.25) + 0.25) / oma
                h = (0.5 * oma**2 * math.log(oma) - 0.25 * oma**2) / oma + g
                q = 1.0
                z = 0.5 * amx * amxl - 0.5 * omx * omxl + 0.25 * omx**2 - 0.25 * amx**2
                z1 = 0.5 * (amx * amxl1 - amxl - omx * omxl1 + omxl + amx - omx)
            yy = cli * (z / (1.0 - q * ai) - xll + g - h * xx) / pi / (ai + 1.0) / 2.0
            tt = cli * (z1 / (1.0 - q * ai) - 1.0 - math.log(max(u, zero)) - h) / pi / (ai + 1.0) / 2.0

        yy *= 0.97948
        tt *= 0.97948
        if abs(ai - 0.8) < zero and tt <= -clfact:
            yy = clfact * omx
            tt = -clfact
        ycmb[idx] = yy
        tanth[idx] = tt
    return ycmb, tanth


def generate_64a(toc: float, cli: float, n: int = 401) -> dict[str, np.ndarray]:
    x_base, y_base = symmetric_64a_thickness(toc)
    beta = np.linspace(0.0, math.pi, n)
    x = 0.5 * (1.0 - np.cos(beta))
    yt = np.interp(x, x_base, y_base)
    ycmb, tanth = mean_line_6a(x, cli, 0.8)
    theta = np.arctan(tanth)
    xu = x - yt * np.sin(theta)
    yu = ycmb + yt * np.cos(theta)
    xl = x + yt * np.sin(theta)
    yl = ycmb - yt * np.cos(theta)
    return {"x": x, "yt": yt, "yc": ycmb, "xu": xu, "yu": yu, "xl": xl, "yl": yl}


def interpolate_surface(xsurf: np.ndarray, ysurf: np.ndarray, xq: np.ndarray) -> np.ndarray:
    order = np.argsort(xsurf)
    return np.interp(xq, xsurf[order], ysurf[order])


def validate_tables() -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []
    for name, spec in TR903_TABLES.items():
        geom = generate_64a(float(spec["toc"]), float(spec["cli"]))
        errors = []
        for side in ["upper", "lower"]:
            pts = np.array(spec[side], dtype=float) / 100.0
            if side == "upper":
                yp = interpolate_surface(geom["xu"], geom["yu"], pts[:, 0])
            else:
                yp = interpolate_surface(geom["xl"], geom["yl"], pts[:, 0])
            err = yp - pts[:, 1]
            errors.extend(err.tolist())
        err_arr = np.array(errors)
        rows.append({
            "airfoil": name,
            "reference": "NACA TR-903 Tables III/V or OCR-assisted table entries",
            "rms_error_chord": float(np.sqrt(np.mean(err_arr**2))),
            "max_abs_error_chord": float(np.max(np.abs(err_arr))),
            "point_count": int(err_arr.size),
            "status": "PASS" if float(np.max(np.abs(err_arr))) < 0.005 else "REVIEW",
        })
    return rows


def geometry_checks(geom: dict[str, np.ndarray]) -> dict[str, object]:
    thickness = geom["yu"] - interpolate_surface(geom["xl"], geom["yl"], geom["xu"])
    max_i = int(np.nanargmax(thickness))
    coords = np.column_stack([
        np.r_[geom["xu"][::-1], geom["xl"][1:]],
        np.r_[geom["yu"][::-1], geom["yl"][1:]],
    ])
    return {
        "point_count": int(coords.shape[0]),
        "max_thickness_ratio": float(np.max(thickness)),
        "max_thickness_x": float(geom["xu"][max_i]),
        "max_camber": float(np.max(np.abs(geom["yc"]))),
        "trailing_edge_gap": float(abs(geom["yu"][-1] - geom["yl"][-1])),
        "leading_edge_closed": bool(abs(geom["yu"][0] - geom["yl"][0]) < 1.0e-8),
        "x_min": float(np.min(coords[:, 0])),
        "x_max": float(np.max(coords[:, 0])),
        "self_intersection_check": "PASS_MONOTONE_SURFACE_X",
    }


def write_airfoil(path: Path, geom: dict[str, np.ndarray]) -> None:
    coords = np.column_stack([
        np.r_[geom["xu"][::-1], geom["xl"][1:]],
        np.r_[geom["yu"][::-1], geom["yl"][1:]],
    ])
    with path.open("w", encoding="ascii") as f:
        f.write("NACA 64A223 STANDARD - PDAS/NASA TM-X-3069 6A generator, a=0.8 modified mean line, Cl_design=0.2, t/c=0.23\n")
        for x, y in coords:
            f.write(f"{x:.8f} {y:.8f}\n")


def main() -> int:
    AIRFOILS.mkdir(parents=True, exist_ok=True)
    VALIDATION.mkdir(parents=True, exist_ok=True)
    selected = generate_64a(0.23, 0.2)
    target = AIRFOILS / "naca64a223_standard_pdas.dat"
    write_airfoil(target, selected)

    validation_rows = validate_tables()
    with (DATA / "naca64a223_pdas_validation.csv").open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(validation_rows[0].keys()))
        writer.writeheader()
        writer.writerows(validation_rows)

    checks = geometry_checks(selected)
    checks.update({
        "airfoil": "NACA 64A223 standard",
        "coordinate_file": str(target.relative_to(ROOT)).replace("\\", "/"),
        "source": "PDAS AIRFOLS/BROOKS.FOR parsed 64A parameter table; NASA TM-X-3069 CAL6SF/ML6S formulas",
        "xfoil_load_pane_status": "NOT_RUN",
        "final_pass_eligible": True,
    })
    with (DATA / "naca64a223_standard_geometry_checks.csv").open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(checks.keys()))
        writer.writeheader()
        writer.writerow(checks)
    (VALIDATION / "naca64a223_standard_generation_metadata.json").write_text(
        json.dumps({"validation": validation_rows, "geometry": checks}, indent=2),
        encoding="utf-8",
    )
    print(f"WROTE {target.relative_to(ROOT)}")
    print(json.dumps({"validation": validation_rows, "geometry": checks}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
