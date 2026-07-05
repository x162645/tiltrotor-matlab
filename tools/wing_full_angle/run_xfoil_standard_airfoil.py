from __future__ import annotations

import csv
import hashlib
import shutil
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
XFOIL = Path(r"E:\tiltrotor\tools\external\xfoil\xfoil.exe")
AIRFOIL = ROOT / "data" / "wing_full_angle" / "airfoils" / "naca64a223_standard_pdas.dat"
OUT = ROOT / "data" / "wing_full_angle" / "xfoil_standard"
VALIDATION = ROOT / "validation" / "wing_full_angle" / "xfoil_standard"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def write_csv(path: Path, rows: list[dict[str, object]], fields: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        for row in rows:
            writer.writerow({key: row.get(key, "") for key in fields})


def run_xfoil(run_dir: Path, commands: list[str], timeout_s: int = 180) -> tuple[str, str]:
    run_dir.mkdir(parents=True, exist_ok=True)
    inp = run_dir / "xfoil.inp"
    log = run_dir / "xfoil.log"
    inp.write_text("\n".join(commands) + "\n", encoding="ascii")
    try:
        with inp.open("rb") as fin, log.open("wb") as fout:
            proc = subprocess.run(
                [str(XFOIL)],
                stdin=fin,
                stdout=fout,
                stderr=subprocess.STDOUT,
                cwd=str(run_dir),
                timeout=timeout_s,
            )
        return ("RAN" if proc.returncode == 0 else f"EXIT_{proc.returncode}", "")
    except subprocess.TimeoutExpired:
        return ("TIMEOUT", f"timeout {timeout_s} s")


def parse_polar(path: Path, re_value: float, mach: float, sweep: str) -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []
    if not path.exists():
        return rows
    for line in path.read_text(errors="ignore").splitlines():
        parts = line.split()
        if len(parts) < 5:
            continue
        try:
            alpha, cl, cd, cdp, cm = [float(parts[i]) for i in range(5)]
        except ValueError:
            continue
        rows.append(
            {
                "Re": re_value,
                "Mach": mach,
                "flap_deg": 0.0,
                "sweep": sweep,
                "alpha_deg": alpha,
                "CL": cl,
                "CD": cd,
                "Cm": cm,
                "source": "XFOIL_CLEAN_STANDARD_NACA64A223_PDAS",
                "accepted": 1,
            }
        )
    return rows


def update_geometry_status(status: str) -> None:
    path = ROOT / "data" / "wing_full_angle" / "naca64a223_standard_geometry_checks.csv"
    rows = list(csv.DictReader(path.open("r", encoding="utf-8", newline="")))
    for row in rows:
        row["xfoil_load_pane_status"] = status
    write_csv(path, rows, list(rows[0].keys()))


def main() -> int:
    if not XFOIL.exists():
        raise FileNotFoundError(XFOIL)
    if XFOIL.stat().st_size != 1002125:
        raise RuntimeError(f"Unexpected XFOIL size: {XFOIL.stat().st_size}")
    expected_hash = "C17342F84AE260C2B11A74CD0E2FB8189A5F8954C6BB7A8467A0F27055C7FAEA"
    xfoil_hash = sha256(XFOIL)
    if xfoil_hash != expected_hash:
        raise RuntimeError(f"Unexpected XFOIL SHA256: {xfoil_hash}")

    OUT.mkdir(parents=True, exist_ok=True)
    VALIDATION.mkdir(parents=True, exist_ok=True)
    manifest: list[dict[str, object]] = []
    polar_rows: list[dict[str, object]] = []

    probe = VALIDATION / "load_pane_probe"
    probe.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(AIRFOIL, probe / "airfoil.dat")
    status, error = run_xfoil(probe, ["LOAD airfoil.dat", "PANE", "SAVE paneled.dat", "Y", "QUIT"], timeout_s=60)
    paneled = probe / "paneled.dat"
    pane_status = "PASS" if status == "RAN" and paneled.exists() and paneled.stat().st_size > 0 else status
    update_geometry_status(pane_status)
    manifest.append(
        {
            "case": "LOAD_PANE",
            "Re": "",
            "Mach": "",
            "sweep": "",
            "status": pane_status,
            "accepted_points": "",
            "input": str((probe / "xfoil.inp").relative_to(ROOT)).replace("\\", "/"),
            "polar": "",
            "log": str((probe / "xfoil.log").relative_to(ROOT)).replace("\\", "/"),
            "error": error,
        }
    )

    for re_value in [0.6e6, 1.0e6, 1.4e6]:
        for mach in [0.0, 0.10]:
            for sweep, start, end, step in [("positive", 0, 25, 1), ("negative", 0, -25, -1)]:
                run_dir = OUT / "raw" / f"Re{int(re_value):07d}_M{mach:.2f}_clean_{sweep}"
                run_dir.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(AIRFOIL, run_dir / "airfoil.dat")
                polar = run_dir / "polar.txt"
                if polar.exists():
                    polar.unlink()
                commands = [
                    "LOAD airfoil.dat",
                    "PANE",
                    "OPER",
                    f"VISC {re_value:.0f}",
                    f"MACH {mach:.3f}",
                    "ITER 260",
                    "PACC",
                    "polar.txt",
                    "",
                    f"ASEQ {start} {end} {step}",
                    "PACC",
                    "",
                    "QUIT",
                ]
                status, error = run_xfoil(run_dir, commands, timeout_s=180)
                parsed = parse_polar(polar, re_value, mach, sweep)
                polar_rows.extend(parsed)
                manifest.append(
                    {
                        "case": "clean",
                        "Re": re_value,
                        "Mach": mach,
                        "sweep": sweep,
                        "status": status,
                        "accepted_points": len(parsed),
                        "input": str((run_dir / "xfoil.inp").relative_to(ROOT)).replace("\\", "/"),
                        "polar": str(polar.relative_to(ROOT)).replace("\\", "/") if polar.exists() else "",
                        "log": str((run_dir / "xfoil.log").relative_to(ROOT)).replace("\\", "/"),
                        "error": error,
                    }
                )

    write_csv(
        OUT / "parsed" / "xfoil_clean_polars_standard.csv",
        polar_rows,
        ["Re", "Mach", "flap_deg", "sweep", "alpha_deg", "CL", "CD", "Cm", "source", "accepted"],
    )
    write_csv(
        OUT / "xfoil_attempt_manifest_standard.csv",
        manifest,
        ["case", "Re", "Mach", "sweep", "status", "accepted_points", "input", "polar", "log", "error"],
    )
    print(f"XFOIL_STANDARD_ROWS={len(polar_rows)}")
    for row in manifest:
        print(row)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
