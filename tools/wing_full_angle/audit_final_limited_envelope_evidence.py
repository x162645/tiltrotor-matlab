from __future__ import annotations

import csv
import json
import math
from collections import Counter, defaultdict
from pathlib import Path

import numpy as np


ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "data" / "wing_full_angle"
FULL = DATA / "full_angle_selected" / "wing_full_angle_database.csv"
VALID = ROOT / "validation" / "wing_full_angle" / "full_angle"
DOCS = ROOT / "docs" / "wing_full_angle"


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def write_csv(path: Path, rows: list[dict[str, object]], fields: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        for row in rows:
            writer.writerow({k: row.get(k, "") for k in fields})


def group_slices(rows: list[dict[str, str]]) -> dict[tuple[float, float, float], list[dict[str, str]]]:
    groups: dict[tuple[float, float, float], list[dict[str, str]]] = defaultdict(list)
    for r in rows:
        key = (float(r["Re"]), float(r["Mach"]), float(r["flap_deg"]))
        groups[key].append(r)
    for rows2 in groups.values():
        rows2.sort(key=lambda r: float(r["alpha_deg"]))
    return groups


def flat_plate(alpha_deg: np.ndarray) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    a = np.deg2rad(alpha_deg)
    return 0.9 * np.sin(2 * a), 0.08 + 1.42 * np.sin(a) ** 2, -0.04 * np.sin(a)


def viterna_like(alpha_deg: np.ndarray, cd90: float = 1.55) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    # Viterna-style post-stall comparison only. It is retained as a wind
    # turbine/finite-wing empirical reference, not as the selected 2-D model.
    a = np.deg2rad(alpha_deg)
    cd = 0.02 + cd90 * np.sin(a) ** 2
    cl = 0.5 * cd90 * np.sin(2 * a)
    cm = -0.02 * np.sin(a)
    return cl, cd, cm


def endpoint_linear(alpha_deg: np.ndarray, cl: np.ndarray, cd: np.ndarray, cm: np.ndarray) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    out = []
    for y in [cl, cd, cm]:
        y2 = y.copy()
        mask = np.array([s == "BRIDGE_MODEL" for s in source_class_current])
        known = ~mask
        y2[mask] = np.interp(alpha_deg[mask], alpha_deg[known], y[known])
        out.append(y2)
    return out[0], np.maximum(out[1], 0), out[2]


def summarize_candidate(
    key: tuple[float, float, float],
    name: str,
    alpha: np.ndarray,
    cl: np.ndarray,
    cd: np.ndarray,
    cm: np.ndarray,
    current: tuple[np.ndarray, np.ndarray, np.ndarray],
) -> dict[str, object]:
    d1 = np.diff(np.column_stack([cl, cd, cm]), axis=0)
    d2 = np.diff(np.column_stack([cl, cd, cm]), n=2, axis=0)
    cur_cl, cur_cd, cur_cm = current
    bridge_mask = source_class_current == "BRIDGE_MODEL"
    bridge_delta = np.max(
        np.abs(np.column_stack([cl - cur_cl, cd - cur_cd, cm - cur_cm])[bridge_mask])
    )
    cm_d1 = np.diff(cm)
    cm_osc = int(np.sum(np.diff(np.sign(cm_d1[np.abs(cm_d1) > 1e-9])) != 0))
    i0 = int(np.argmin(np.abs(alpha - 0)))
    im90 = int(np.argmin(np.abs(alpha + 90)))
    return {
        "Re": key[0],
        "Mach": key[1],
        "flap_deg": key[2],
        "candidate": name,
        "bridge_rows": int(np.sum(bridge_mask)),
        "max_abs_CL": float(np.max(np.abs(cl))),
        "min_CD": float(np.min(cd)),
        "max_adjacent_l1_jump": float(np.max(np.sum(np.abs(d1), axis=1))),
        "max_second_difference_l1": float(np.max(np.sum(np.abs(d2), axis=1))),
        "periodic_closure_l2": float(np.linalg.norm([cl[0] - cl[-1], cd[0] - cd[-1], cm[0] - cm[-1]])),
        "cm_local_oscillation_count": cm_osc,
        "max_delta_from_current_in_bridge": float(bridge_delta),
        "alpha0_CL": float(cl[i0]),
        "alpha0_CD": float(cd[i0]),
        "alpha0_Cm": float(cm[i0]),
        "alpha_minus90_CL": float(cl[im90]),
        "alpha_minus90_CD": float(cd[im90]),
        "alpha_minus90_Cm": float(cm[im90]),
        "deep_stall_note": deep_stall_note(name),
    }


def deep_stall_note(name: str) -> str:
    if name == "current_selected":
        return "selected bounded smootherstep bridge tied to graph/XFOIL/closure endpoints"
    if name == "endpoint_linear_pchip_proxy":
        return "endpoint value constrained, slope continuity not guaranteed by this audit proxy"
    if name == "flat_plate_asymptotic":
        return "bounded flat-plate asymptote, least sourced for cambered airfoil Cm"
    return "Viterna-style finite-wing/wind-turbine empirical comparison only, not selected"


def bridge_audit(rows: list[dict[str, str]]) -> None:
    global source_class_current
    groups = group_slices(rows)
    audit_rows = []
    for key, subset in groups.items():
        alpha = np.array([float(r["alpha_deg"]) for r in subset])
        cur_cl = np.array([float(r["CL"]) for r in subset])
        cur_cd = np.array([float(r["CD"]) for r in subset])
        cur_cm = np.array([float(r["Cm"]) for r in subset])
        source_class_current = np.array([r["source_class"] for r in subset])
        current = (cur_cl, cur_cd, cur_cm)
        candidates = {
            "current_selected": current,
            "endpoint_linear_pchip_proxy": endpoint_linear(alpha, cur_cl, cur_cd, cur_cm),
            "flat_plate_asymptotic": flat_plate(alpha),
            "viterna_type_reference_only": viterna_like(alpha),
        }
        for name, (cl, cd, cm) in candidates.items():
            audit_rows.append(summarize_candidate(key, name, alpha, cl, cd, cm, current))

    fields = list(audit_rows[0].keys())
    write_csv(VALID / "bridge_candidate_audit.csv", audit_rows, fields)

    summary_rows = []
    by_candidate: dict[str, list[dict[str, object]]] = defaultdict(list)
    for r in audit_rows:
        by_candidate[str(r["candidate"])].append(r)
    for name, vals in by_candidate.items():
        summary_rows.append(
            {
                "candidate": name,
                "slices": len(vals),
                "max_bridge_delta": max(float(v["max_delta_from_current_in_bridge"]) for v in vals),
                "min_CD": min(float(v["min_CD"]) for v in vals),
                "max_adjacent_l1_jump": max(float(v["max_adjacent_l1_jump"]) for v in vals),
                "max_second_difference_l1": max(float(v["max_second_difference_l1"]) for v in vals),
                "max_periodic_closure_l2": max(float(v["periodic_closure_l2"]) for v in vals),
                "max_cm_oscillation_count": max(int(v["cm_local_oscillation_count"]) for v in vals),
                "selection_status": "SELECTED" if name == "current_selected" else "SENSITIVITY_ONLY",
            }
        )
    write_csv(VALID / "bridge_candidate_summary.csv", summary_rows, list(summary_rows[0].keys()))


def source_share(rows: list[dict[str, str]]) -> None:
    count = Counter(r["source_class"] for r in rows)
    total = len(rows)
    out = [
        {"source_class": k, "rows": v, "share_percent": 100.0 * v / total}
        for k, v in sorted(count.items())
    ]
    write_csv(VALID / "source_class_share_audit.csv", out, ["source_class", "rows", "share_percent"])


def aileron_audit() -> None:
    rows = [
        {
            "item": "TM-88373 Figure 6a",
            "evidence": "symmetric 30% chord plain-flap two-dimensional data",
            "usable_for_differential_aileron": "NO",
            "reason": "no left/right differential control-surface derivatives or yaw/roll moments",
        },
        {
            "item": "NASA CR-176970 text",
            "evidence": "XV-15 flap/flaperon schedule and full-span flap hover modification",
            "usable_for_differential_aileron": "NO",
            "reason": "documents flap/flaperon schedule and hover download, not standalone aileron CL/Cl/Cm/Cn derivatives for full-angle wing path",
        },
        {
            "item": "legacy model",
            "evidence": "P.wing.CLaileron and P.wing.Cmaileron conceptual linear increments",
            "usable_for_differential_aileron": "NO_FOR_FULL_ANGLE_DATABASE",
            "reason": "existing conceptual increments are not sourced full-angle differential aileron data",
        },
    ]
    write_csv(VALID / "control_surface_aileron_source_audit.csv", rows, list(rows[0].keys()))
    report = """# Differential Aileron Aerodynamic Audit

Date: 2026-07-03

Decision: option C. Keep `CONTROL_SURFACE_GATE = PARTIAL` and retain `longitudinal_full_angle_baseline_no_lateral_aileron_aero`.

Evidence checked:

- NASA TM-88373 Figure 6a supplies symmetric plain-flap section CL/CD/Cm near -90 deg, not differential aileron roll/yaw increments.
- NASA CR-176970 text identifies XV-15 flap/flaperon scheduling and full-span flap hover test modification. It does not provide an independent, full-angle, differential aileron CL/Cl/Cm/Cn data set with signs, span range, and validity bounds.
- The legacy `P.wing.CLaileron` and `P.wing.Cmaileron` increments remain conceptual and are not hidden inside the full-angle database.

Required behavior remains: zero aileron derivative in the full-angle path until sourced data are added, explicit diagnostics for unsupported aileron aero, and no misuse of symmetric plain-flap data as differential aileron data.
"""
    (DOCS / "CONTROL_SURFACE_AILERON_AUDIT.md").write_text(report, encoding="utf-8")


def gate_report(rows: list[dict[str, str]]) -> None:
    counts = Counter(r["source_class"] for r in rows)
    total = len(rows)
    bridge_share = 100.0 * counts.get("BRIDGE_MODEL", 0) / total
    tm_graph = counts.get("TM88373_DIGITIZED_GRAPH", 0) > 0
    report = f"""# Final Limited Envelope Evidence Audit

Date: 2026-07-03

## Database Source Shares

- Rows: {total}
- BRIDGE_MODEL: {counts.get('BRIDGE_MODEL', 0)} ({bridge_share:.4f}%)
- TM88373_DIGITIZED_GRAPH: {counts.get('TM88373_DIGITIZED_GRAPH', 0)}
- ASSUMED_POSITIVE_DEEP_STALL_MIRROR_UNVALIDATED: {counts.get('ASSUMED_POSITIVE_DEEP_STALL_MIRROR_UNVALIDATED', 0)}

## Gate Implications

- `TM88373_DATA_GATE`: `PASS_FOR_SELECTED_FIGURE6A_GRAPH_DIGITIZATION` if visual overlay is accepted; manual review is still appropriate because marker centers were selected from a scanned plot.
- `BRIDGE_MODEL_GATE`: `ENVELOPE_PASS`, not final all-angle validation, because {bridge_share:.2f}% of rows remain bridge rows and deep-stall positive-angle rows remain unvalidated.
- `CONTROL_SURFACE_GATE`: `PARTIAL`; no credible full-angle differential aileron data were found in the local source chain.

The selected bridge remains the current bounded endpoint-connected scheme. Viterna-type behavior is retained only as a comparison because its empirical origin is finite-wing/wind-turbine post-stall modeling, not this two-dimensional near-vertical TM-88373 data set.
"""
    (DOCS / "FINAL_LIMITED_ENVELOPE_EVIDENCE_AUDIT.md").write_text(report, encoding="utf-8")
    if not tm_graph:
        raise RuntimeError("TM88373_DIGITIZED_GRAPH rows were not found")


def main() -> int:
    rows = read_csv(FULL)
    VALID.mkdir(parents=True, exist_ok=True)
    DOCS.mkdir(parents=True, exist_ok=True)
    source_share(rows)
    bridge_audit(rows)
    aileron_audit()
    gate_report(rows)
    print("WROTE final limited envelope evidence audits")
    return 0


source_class_current = np.array([])


if __name__ == "__main__":
    raise SystemExit(main())
