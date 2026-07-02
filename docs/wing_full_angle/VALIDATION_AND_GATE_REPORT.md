# Validation and Gate Report

## MATLAB Runs

- check_wing_normal_flow_blend: PASS; saved validation/wing_full_angle/baseline/legacy_wing_normal_flow_blend.mat.
- wing_blend_repair_diagnostics: completed; runtime 2394.378 s; saved validation/wing_full_angle/baseline/legacy_wing_blend_repair_diagnostics.mat and .log.
- focused full-angle checks: GUI 21/21 PASS, legacy identity PASS, full-angle model PASS, wake strip PASS.
- run_all_checks: 21/21 PASS; runtime 429.835 s.
- run_full_angle_zero_nacelle_validation: legacy and full-angle sweeps both 21/21 converged; runtime 262.568 s.
- check_article_trends: finite diagnostic, formalComparable = 0, diagnosticMatchFraction = 0.666667. This remains a diagnostic, not a formal pass/fail reproduction test.

## Legacy Regression

- Public wing_model defaults to wing_model_legacy.
- check_wing_legacy_identity maxForceError = 0, maxMomentError = 0.
- Existing near-normal blend test remains PASS.
- No default switch to the full-angle model was made.

## 0-Deg Nacelle Bump Comparison

CSV outputs:

- validation/wing_full_angle/zero_nacelle_bump/legacy_zero_nacelle_7_12_step025.csv
- validation/wing_full_angle/zero_nacelle_bump/full_angle_zero_nacelle_7_12_step025.csv

Results:

- Legacy all converged = 1; full-angle all converged = 1.
- Legacy theta max abs second difference = 2.459186600300e-02 deg.
- Full-angle theta max abs second difference = 8.361422386464e-04 deg.
- branchWeightInNew = 0.
- No NaN or Inf found in the regenerated full-angle zero-nacelle CSV.

Figures:

- docs/wing_full_angle/figures/zero_nacelle_theta_comparison.png
- docs/wing_full_angle/figures/branch_weight_removed.png

## GUI and Default State

- services/build_parameter_catalog.m exposes fullAngleModelEnabled, fullAngleStripCount and fullAngleWakeContraction.
- tests/check_gui_parameter_catalog.m updated to 142 entries and passed 21/21.
- Default remains legacy: P.wing.fullAngleModelEnabled = 0 and P.wing.modelType = 'legacy'.

## Gate Table

| Gate | Status | Reason |
|---|---|---|
| Legacy preservation and identity | PASS | Exact force/moment identity through dispatcher. |
| Default remains old model | PASS | New model is opt-in only. |
| Source acquisition | PARTIAL | TM-88373 and CR-176970 downloaded; CR-114614 endpoint unavailable. |
| Airfoil coordinate credibility | PARTIAL | Surrogate NACA 64A223 geometry, not exact sourced coordinates. |
| XFOIL clean grid | PASS | 297 accepted clean points. |
| Flap XFOIL grid | PARTIAL | Not attempted without verified flap geometry route. |
| TM-88373 digitization | PARTIAL | Anchor-based use only, not full-curve digitization. |
| Full-angle database continuity | PASS | Closure and slope checks pass. |
| Wake strip architecture | PASS | Same coefficient law for free and wake strip portions. |
| Production integration | PASS | New model parallel, legacy default. |
| GUI integration | PASS | Catalog test passes. |
| Trim and regression tests | PASS | run_all_checks and zero-nacelle sweeps pass. |

FULL_WING_MODEL_GATE = PARTIAL

The gate is not PASS because source traceability remains incomplete for CR-114614, exact NACA 64A223 coordinates, flap XFOIL data, and full TM-88373 curve digitization. The implementation is suitable as an offline prototype, not as the default model or a validated XV-15 wing model.

## 2026-07-02 Gate-Correction Update

- The current surrogate coordinate/XFOIL/database chain is archived under `data/wing_full_angle/surrogate_v0` and marked `PROVISIONAL_SURROGATE_V0_DO_NOT_USE_FOR_FINAL_PASS`.
- `wing_full_angle_lookup` now accepts `alpha, Re, Mach, flapDeg, P` and reports `dimensionReductionActive`. The current selected database remains alpha-only and is therefore a reduced provisional database, not a multidimensional final database.
- `wing_local_flow` now computes local Reynolds number and Mach number for each strip region. Legacy linear aileron CL/Cm increments are no longer added outside the database in the full-angle path.
- `wing_wake_coverage` now uses rotor hub position, rotor axis, disk-wing projection, wake radius/contraction, side-specific wake centers and strip span-overlap area. It is a `PROVISIONAL_STRUCTURAL_PASS`, not a final CR-114614/CR-176970 formula extraction.
- NASA CR-114614 was retried through the official NTRS endpoint, but local scripted and PowerShell requests still returned HTTP 404 JSON. Browser-side NTRS availability is noted, but no local verified CR-114614 PDF/text artifact is promoted in this commit.
- NASA TM-X-3069, NASA TM-4741 and NACA TR-903 are valid local PDFs and support the geometry-source audit. They do not, by themselves, provide a recovered true NACA 64A223 coordinate file in this branch.

Updated gate statuses:

| Gate | Status | Reason |
|---|---|---|
| Source acquisition | PARTIAL | CR-114614 still lacks a local verified PDF/text artifact despite official endpoint retry. |
| Airfoil coordinate credibility | PARTIAL | True NACA 64A223 coordinates were not generated; surrogate_v0 is archived only. |
| XFOIL clean grid | PARTIAL | Existing XFOIL grid depends on surrogate_v0 and is ineligible for final PASS. |
| Flap XFOIL grid | PARTIAL | TM-88373 plain-flap geometry transform and final coordinate basis are not complete. |
| TM-88373 digitization | PARTIAL | Curve-level repeat digitization remains incomplete. |
| Full-angle database continuity | PROVISIONAL_STRUCTURAL_PASS | Current database is continuous but alpha-only and surrogate-based. |
| Wake strip architecture | PROVISIONAL_STRUCTURAL_PASS | Geometry is no longer pivotY-only, but source formula extraction remains partial. |
| Zero-nacelle bump test | PROVISIONAL_STRUCTURAL_PASS | Prior comparison used surrogate_v0 and cannot be promoted to PASS. |

FULL_WING_MODEL_GATE = PARTIAL
