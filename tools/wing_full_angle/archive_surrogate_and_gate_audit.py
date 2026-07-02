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
            "status": "PARTIAL_LOCAL_DOWNLOAD_BLOCKED",
            "evidence": "NTRS citation/PDF verified in browser source; local urllib/PowerShell direct endpoint returned HTTP_404 JSON.",
            "final_pass_impact": "Wake formula extraction remains partial; code uses projected strip-area geometry with explicit provisional source status.",
        },
        {
            "gate": "NACA_64A223_COORDINATES",
            "status": "PARTIAL_SURROGATE_ARCHIVED",
            "evidence": "TM-X-3069/TM-4741/TR-903 acquired; exact 6A parameter table/program reconstruction not completed; TN-4322 local download not a valid PDF; TR-R-84 pypdf read failed.",
            "final_pass_impact": "No true NACA 64A223 coordinate file is promoted for final PASS.",
        },
        {
            "gate": "SURROGATE_V0_ARCHIVE",
            "status": "PASS",
            "evidence": "Coordinate, XFOIL, database, and validation artifacts copied under data/wing_full_angle/surrogate_v0 and validation/wing_full_angle/surrogate_v0.",
            "final_pass_impact": "Historical results are retained but marked ineligible for final PASS.",
        },
        {
            "gate": "DATABASE_DIMENSIONS",
            "status": "PARTIAL_REDUCED_ALPHA_ONLY",
            "evidence": "Lookup interface now accepts alpha/Re/Mach/flapDeg and reports dimensionReductionActive for alpha-only database slices.",
            "final_pass_impact": "Reduced database can run as prototype only; final PASS still requires sourced multidimensional data or sensitivity proof.",
        },
        {
            "gate": "WAKE_COVERAGE_GEOMETRY",
            "status": "PROVISIONAL_STRUCTURAL_PASS",
            "evidence": "Coverage now uses rotor hub, axis, disk-wing distance, projected wake center, wake radius, side-specific wake and strip overlap.",
            "final_pass_impact": "Implementation no longer uses pivotY-only interval coverage, but CR-114614/CR-176970 formula extraction remains incomplete.",
        },
        {
            "gate": "ZERO_NACELLE_BUMP_TEST",
            "status": "PROVISIONAL_STRUCTURAL_PASS",
            "evidence": "Prior bump result was generated with surrogate_v0 data; full rerun with final coordinates/database is not possible in this pass.",
            "final_pass_impact": "Cannot promote ZERO_NACELLE_BUMP_TEST to PASS.",
        },
    ]
    write_csv(
        DATA / "gate_completion_correction_audit.csv",
        ["gate", "status", "evidence", "final_pass_impact"],
        rows,
    )

    report = """# Full Wing Model Gate Completion Correction Report

Date: 2026-07-02

## Source Status

- NASA CR-114614 was verified on the official NTRS citation page and the official PDF endpoint, but local direct download still returned HTTP 404 JSON during scripted retries. The PDF is therefore not promoted as a local verified artifact in this commit.
- NASA TM-X-3069, NASA TM-4741 and NACA TR-903 were downloaded as valid PDFs and text-extracted for the NACA 6/6A coordinate audit.
- NACA TN-4322 local acquisition produced a non-PDF response and NASA TR R-84 remains locally readable only as a damaged PDF stream. They are not used as authoritative inputs.

## Surrogate Archive

The existing `naca64a223_surrogate.dat`, its XFOIL outputs, selected full-angle database and validation artifacts are archived under `data/wing_full_angle/surrogate_v0` and `validation/wing_full_angle/surrogate_v0`.

These artifacts are retained for comparison only. They are marked `PROVISIONAL_SURROGATE_V0_DO_NOT_USE_FOR_FINAL_PASS` and cannot support `FULL_WING_MODEL_GATE=PASS`.

## Code Corrections

- `wing_full_angle_lookup` now accepts `alpha, Re, Mach, flapDeg, P` and reports whether dimensional reduction is active.
- `wing_local_flow` computes local Reynolds number and Mach number from the strip velocity and chord.
- The full-angle path no longer adds legacy linear aileron lift or moment increments outside the database.
- `wing_wake_coverage` now uses rotor hub position, rotor axis, disk-wing distance, projected wake centerline, wake radius/contraction, left/right independent wakes and strip overlap area.

## Gate Result

`FULL_WING_MODEL_GATE=PARTIAL`

The branch is improved structurally but remains blocked from PASS by missing final NACA 64A223 coordinates, unavailable local CR-114614 extraction, incomplete TM-88373 curve digitization, and an alpha-only provisional database.
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
