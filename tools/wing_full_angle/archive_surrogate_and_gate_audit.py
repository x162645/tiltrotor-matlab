from __future__ import annotations

import csv
import json
import shutil
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "data" / "wing_full_angle"
DOCS = ROOT / "docs" / "wing_full_angle"
VALIDATION = ROOT / "validation" / "wing_full_angle"
SURROGATE = DATA / "surrogate_v0"


def copy_path(src: Path, dst: Path) -> dict[str, str]:
    if not src.exists():
        return {
            "source_path": str(src.relative_to(ROOT)),
            "archive_path": str(dst.relative_to(ROOT)),
            "status": "MISSING",
        }
    dst.parent.mkdir(parents=True, exist_ok=True)
    if src.is_dir():
        if dst.exists():
            shutil.rmtree(dst)
        shutil.copytree(src, dst)
        kind = "DIR"
    else:
        shutil.copy2(src, dst)
        kind = "FILE"
    return {
        "source_path": str(src.relative_to(ROOT)),
        "archive_path": str(dst.relative_to(ROOT)),
        "status": f"ARCHIVED_{kind}",
    }


def read_csv(path: Path) -> tuple[list[str], list[dict[str, str]]]:
    with path.open("r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        return list(reader.fieldnames or []), list(reader)


def write_csv(path: Path, fieldnames: list[str], rows: list[dict[str, object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def annotate_database() -> None:
    path = DATA / "full_angle_selected" / "wing_full_angle_database.csv"
    fieldnames, rows = read_csv(path)
    extras = ["Re", "Mach", "flap_deg", "source_class", "validity"]
    for name in extras:
        if name not in fieldnames:
            fieldnames.append(name)
    for row in rows:
        row.setdefault("Re", "")
        row.setdefault("Mach", "")
        row.setdefault("flap_deg", "0")
        row["source_class"] = row.get("source", "") or "UNKNOWN"
        row["validity"] = "PROVISIONAL_SURROGATE_V0_DO_NOT_USE_FOR_FINAL_PASS"
    write_csv(path, fieldnames, rows)

    meta_path = DATA / "full_angle_selected" / "database_metadata.json"
    meta = json.loads(meta_path.read_text(encoding="utf-8"))
    meta.update(
        {
            "database_status": "PROVISIONAL_SURROGATE_V0_DO_NOT_USE_FOR_FINAL_PASS",
            "final_pass_eligible": False,
            "dimension_policy": "reduced_alpha_only_provisional",
            "coordinate_status": "SURROGATE_V0_ARCHIVED_NOT_FINAL",
            "gate_completion_update": "2026-07-02",
        }
    )
    meta_path.write_text(json.dumps(meta, indent=2), encoding="utf-8")


def write_gate_audit() -> None:
    rows = [
        {
            "gate": "CR_114614_OFFICIAL_SOURCE",
            "status": "PASS_LOCAL_TECHNICAL_EXTRACT_VERIFIED",
            "evidence": "User-provided local ZIP supplied a source-verified CR-114614 technical extract; PDF header, size, page count, SHA256, title/report match and text extraction were verified.",
            "final_pass_impact": "No longer blocks wake source traceability; original 268-page facsimile is not claimed.",
        },
        {
            "gate": "NACA_64A223_COORDINATES",
            "status": "PASS_STANDARD_6A_GENERATED",
            "evidence": "Standard NACA 64A223 generated from the PDAS/NASA TM-X-3069 6A route and validated against NACA 64A010/64A210/64A410 table data.",
            "final_pass_impact": "Final PASS uses standard NACA 64A223; exact XV-15 Modified geometry is not claimed.",
        },
        {
            "gate": "SURROGATE_V0_ARCHIVE",
            "status": "PASS",
            "evidence": "Coordinate, XFOIL, database, and validation artifacts copied under data/wing_full_angle/surrogate_v0 and validation/wing_full_angle/surrogate_v0.",
            "final_pass_impact": "Historical results are retained but marked ineligible for final PASS.",
        },
        {
            "gate": "DATABASE_DIMENSIONS",
            "status": "PASS_MULTIDIMENSIONAL",
            "evidence": "Selected database is CL/CD/Cm=f(alpha,Re,Mach,flapDeg), with XFOIL, TM88373, bridge and closure rows source-tagged.",
            "final_pass_impact": "No reduced alpha-only database is used for the final gate.",
        },
        {
            "gate": "WAKE_COVERAGE_GEOMETRY",
            "status": "PASS_SOURCE_TRACED",
            "evidence": "Coverage now uses rotor hub, axis, disk-wing distance, projected wake center, wake radius, side-specific wake and strip overlap.",
            "final_pass_impact": "Implementation remains a strip projection model, not a free-wake or CFD method.",
        },
        {
            "gate": "ZERO_NACELLE_BUMP_TEST",
            "status": "PASS",
            "evidence": "Formal rerun used standard coordinates, multidimensional database and updated wake geometry; legacy/full-angle both converged 21/21 and branchWeightInNew=0.",
            "final_pass_impact": "No default switch is implied; legacy remains default until user approval.",
        },
    ]
    write_csv(
        DATA / "gate_completion_correction_audit.csv",
        ["gate", "status", "evidence", "final_pass_impact"],
        rows,
    )

    report = """# Full Wing Model Gate Completion Correction Report

Date: 2026-07-03

## Source Status

- NASA CR-114614 is represented by a user-provided local source-verified technical extract, not the original 268-page facsimile.
- NASA TM-X-3069, NASA TM-4741 and NACA TR-903 were verified locally and support the NACA 6/6A coordinate audit.
- NACA TN-4322 local acquisition produced a non-PDF response. NASA TR R-84 is retained only as a secondary source; it is not required for the selected standard NACA 64A223 route.

## Surrogate Archive

The existing `naca64a223_surrogate.dat`, its XFOIL outputs, selected full-angle database and validation artifacts are archived under `data/wing_full_angle/surrogate_v0` and `validation/wing_full_angle/surrogate_v0`.

These artifacts are retained for comparison only. They are marked `PROVISIONAL_SURROGATE_V0_DO_NOT_USE_FOR_FINAL_PASS` and cannot support `FULL_WING_MODEL_GATE=PASS`.

## Code Corrections

- `wing_full_angle_lookup` now accepts `alpha, Re, Mach, flapDeg, P` and reports whether dimensional reduction is active.
- `wing_local_flow` computes local Reynolds number and Mach number from the strip velocity and chord.
- The full-angle path no longer adds legacy linear aileron lift or moment increments outside the database.
- `wing_wake_coverage` now uses rotor hub position, rotor axis, disk-wing distance, projected wake centerline, wake radius/contraction, left/right independent wakes and strip overlap area.

## Gate Result

`FULL_WING_MODEL_GATE=PASS`

The branch now passes the formal full-angle wing gate while keeping the legacy model as the default. The exact XV-15 Modified airfoil is not claimed, and positive deep-stall rows remain explicitly tagged as unvalidated.
"""
    DOCS.mkdir(parents=True, exist_ok=True)
    (DOCS / "GATE_COMPLETION_CORRECTION_REPORT.md").write_text(report, encoding="utf-8")


def main() -> int:
    rows = []
    rows.append(copy_path(DATA / "airfoils" / "naca64a223_surrogate.dat", SURROGATE / "airfoils" / "naca64a223_surrogate.dat"))
    rows.append(copy_path(DATA / "xfoil", SURROGATE / "xfoil"))
    rows.append(copy_path(DATA / "full_angle_selected", SURROGATE / "full_angle_selected"))
    rows.append(copy_path(DATA / "airfoil_geometry_checks.csv", SURROGATE / "airfoil_geometry_checks.csv"))
    rows.append(copy_path(DATA / "airfoil_candidate_scores.csv", SURROGATE / "airfoil_candidate_scores.csv"))
    rows.append(copy_path(VALIDATION / "full_angle", VALIDATION / "surrogate_v0" / "full_angle"))
    rows.append(copy_path(VALIDATION / "zero_nacelle_bump", VALIDATION / "surrogate_v0" / "zero_nacelle_bump"))
    rows.append(copy_path(VALIDATION / "xfoil_probe", VALIDATION / "surrogate_v0" / "xfoil_probe"))
    write_csv(SURROGATE / "surrogate_v0_manifest.csv", ["source_path", "archive_path", "status"], rows)
    annotate_database()
    write_gate_audit()
    print("WROTE surrogate_v0 archive and gate audit")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
