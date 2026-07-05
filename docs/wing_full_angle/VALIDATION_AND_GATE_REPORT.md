# Validation and Gate Report

Date: 2026-07-04

This report is computational evidence for the opt-in full-angle wing path. It is not XV-15 flight-test validation and does not change the legacy default.

## MATLAB Runs

- `run_all_checks`: 33/33 PASS on MATLAB R2021a.
- Focused full-angle checks: PASS.
  - `check_wing_legacy_identity`: max force error = 0, max moment error = 0.
  - `check_wing_full_angle_model`: PASS.
  - `check_wing_full_angle_lookup_multidim`: PASS.
  - `check_wing_full_angle_control_surface`: PASS as a diagnostic audit; differential aileron aero remains explicitly unmodeled.
  - `check_wake_strip_model`: PASS.
  - `check_tm88373_graph_digitization`: PASS.
  - `check_bridge_sensitivity_audit`: PASS.
  - `check_control_surface_aileron_audit`: PASS.
- `run_full_angle_zero_nacelle_validation`: legacy and full-angle 7-12 m/s sweeps both converged; `branchWeightInNew = 0`.
- `check_article_trends`: finite diagnostic, `formalComparable = 0`, `diagnosticMatchFraction = 0.666667`.
- New trim-envelope checks passed: point schema, resumable skip, resume, no placeholder rows, actual execution, mode definitions, and legacy/full-angle pairing.

## Data Chain

- NASA TM-88373 Figure 6a was rendered from the local PDF and digitized from the scanned graph.
- Source: `references/wing_full_angle/NASA_TM_88373.pdf`, PDF page 32, original page 28.
- Configuration: basic leading edge, 30% chord plain flap, configuration b.
- Moment reference: quarter chord.
- Artifacts: source page, crop images, axis calibration JSON, pass1/pass2 CSVs, repeat-difference CSV, uncertainty summary, and overlay image under `data/wing_full_angle/tm88373_digitized/`.
- TM graph points: 126; repeat max difference = 1.177566806187e-02 coefficient units.
- No text-constrained TM rows remain in the selected database.

## Full-Angle Database

- Database: `data/wing_full_angle/full_angle_selected/wing_full_angle_database.csv`.
- Rows: 12,996.
- Schema: `CL/CD/Cm = f(alpha, Re, Mach, flapDeg)`.
- Flap grid follows the Figure 6a symmetric plain-flap curves: 0, 30, 45, 60, 75, 90 deg.
- Source shares:
  - `BRIDGE_MODEL`: 10,386 rows, 79.9169%.
  - `TM88373_DIGITIZED_GRAPH`: 1,116 rows, 8.5873%.
  - `ASSUMED_POSITIVE_DEEP_STALL_MIRROR_UNVALIDATED`: 1,116 rows, 8.5873%.
  - `XFOIL`: 306 rows, 2.3546%.
  - `PERIODIC_CLOSURE`: 72 rows, 0.5540%.

## Resumable Trim Envelope

- Point framework:
  - `analysis/run_full_angle_trim_point.m`
  - `analysis/run_full_angle_trim_envelope_resumable.m`
  - `analysis/collect_full_angle_trim_envelope_results.m`
- Output root: `validation/wing_full_angle/trim_envelope/`.
- Point MAT/CSV/JSON files are written under `validation/wing_full_angle/trim_envelope/points/`.
- No unstarted planned point is emitted as a placeholder row.
- Stage A/B plus Stage C local refinement produced 84 real point rows.
- Status counts: 84 `CONVERGED`, 0 timeout, 0 failed, 0 placeholder.
- Mode routing:
  - 0 deg: `helicopter_longitudinal`.
  - 15/45/75 deg: `conversion_longitudinal`.
  - 90 deg: `airplane_longitudinal`, with `cyclicLong` fixed at zero.

Per-beta/model counts:

| betaM deg | model | attempted | converged | timeout | failed |
|---:|---|---:|---:|---:|---:|
| 0 | legacy | 8 | 8 | 0 | 0 |
| 0 | full_angle | 8 | 8 | 0 | 0 |
| 15 | legacy | 6 | 6 | 0 | 0 |
| 15 | full_angle | 6 | 6 | 0 | 0 |
| 45 | legacy | 8 | 8 | 0 | 0 |
| 45 | full_angle | 8 | 8 | 0 | 0 |
| 75 | legacy | 9 | 9 | 0 | 0 |
| 75 | full_angle | 9 | 9 | 0 | 0 |
| 90 | legacy | 11 | 11 | 0 | 0 |
| 90 | full_angle | 11 | 11 | 0 | 0 |

## Bridge, Control Surfaces, and Wake

- Bridge audit compares the current selected bridge, endpoint/PCHIP proxy, bounded flat-plate asymptote, and a Viterna-type reference.
- Viterna remains only a finite-wing/wind-turbine empirical comparison, not selected as a two-dimensional TM-88373 replacement.
- Bridge status remains `ENVELOPE_PASS`, not deep-stall validation, because unsupported bridge rows still dominate the database.
- Differential aileron evidence audit selected option C: no credible full-angle differential aileron data were found. `CONTROL_SURFACE_GATE` remains `PARTIAL`.
- Wake contraction sensitivity completed over bounded range 0.75-1.15 and remains user-adjustable.
- Strip-count convergence 12/24/48/96 against 96-strip reference was finite with near-zero relative differences for the representative geometry case.

## Gate Table

| Gate | Status | Reason |
|---|---|---|
| TM88373_DATA_GATE | PASS_FOR_SELECTED_FIGURE6A_GRAPH_DIGITIZATION | Figure 6a graph digitization artifacts and repeat statistics are present. |
| BRIDGE_MODEL_GATE | ENVELOPE_PASS | Candidate audit completed; deep-stall bridge rows remain unvalidated. |
| FULL_ANGLE_DATABASE_GATE | ENVELOPE_PASS | Database is finite and traceable for current limited use. |
| CONTROL_SURFACE_GATE | PARTIAL | Differential aileron aerodynamics are explicitly unmodeled. |
| WAKE_GEOMETRY_GATE | ENVELOPE_PASS | Bounded wake contraction and strip-count sensitivity completed. |
| ZERO_NACELLE_BUMP_GATE | ENVELOPE_PASS | Existing 7-12 m/s validation and expanded 0 deg point evidence converged. |
| HELICOPTER_ENVELOPE_GATE | ENVELOPE_PASS | 0-30 m/s point evidence converged for legacy and full-angle. |
| CONVERSION_ENVELOPE_GATE | ENVELOPE_PASS | 15/45/75 deg point evidence converged for legacy and full-angle. |
| AIRPLANE_ENVELOPE_GATE | ENVELOPE_PASS | 90 deg point evidence converged for legacy and full-angle. |
| TRIM_GATE | ENVELOPE_PASS | 84 actual trim point rows converged; no unrun placeholder rows. |
| LINEARIZATION_GATE | PASS | `run_all_checks` finite A/B matrix check passed. |
| FULL_REGRESSION_GATE | PASS | `run_all_checks` passed; legacy remains default. |

FULL_WING_MODEL_GATE = READY_FOR_LIMITED_ENVELOPE_USE

The expanded trim envelope is now real and resumable, but the overall gate is not upgraded to final owner review because `CONTROL_SURFACE_GATE` remains `PARTIAL` and bridge/deep-stall evidence remains envelope-limited rather than fully validated.
