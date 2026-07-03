# Validation and Gate Report

Date: 2026-07-03

## MATLAB Runs

- `run_all_checks`: 26/26 PASS; actual MATLAB R2021a run completed.
- Focused full-angle checks: PASS.
  - `check_wing_legacy_identity`: max force error = 0, max moment error = 0.
  - `check_wing_full_angle_model`: PASS.
  - `check_wing_full_angle_lookup_multidim`: PASS.
  - `check_wing_full_angle_control_surface`: PASS as a diagnostic audit; aileron aero is explicitly unmodeled.
  - `check_wake_strip_model`: PASS.
  - `check_tm88373_graph_digitization`: PASS.
  - `check_bridge_sensitivity_audit`: PASS.
  - `check_control_surface_aileron_audit`: PASS.
- `run_full_angle_zero_nacelle_validation`: legacy and full-angle 7-12 m/s sweeps both converged; `branchWeightInNew = 0`.
- `check_article_trends`: finite diagnostic, `formalComparable = 0`, `diagnosticMatchFraction = 0.666667`.
- GUI checks passed: parameter modified IDs, parameter catalog, parameter page, and services.

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
- Flap grid now follows the actual Figure 6a symmetric plain-flap curves: 0, 30, 45, 60, 75, 90 deg.
- Source shares:
  - `BRIDGE_MODEL`: 10,386 rows, 79.9169%.
  - `TM88373_DIGITIZED_GRAPH`: 1,116 rows, 8.5873%.
  - `ASSUMED_POSITIVE_DEEP_STALL_MIRROR_UNVALIDATED`: 1,116 rows, 8.5873%.
  - `XFOIL`: 306 rows, 2.3546%.
  - `PERIODIC_CLOSURE`: 72 rows, 0.5540%.

## Bridge and Control Surfaces

- Bridge audit compares `current_selected`, endpoint-linear/PCHIP proxy, bounded flat-plate asymptote, and Viterna-type reference.
- Viterna is retained only as a finite-wing/wind-turbine empirical comparison, not selected for the two-dimensional TM-88373 data chain.
- The selected bridge remains `ENVELOPE_PASS`, not final deep-stall validation, because unsupported bridge rows still dominate the database.
- Differential aileron evidence audit selected option C: no credible full-angle differential aileron data were found. `CONTROL_SURFACE_GATE` remains `PARTIAL`.

## Wake and Envelope

- Wake contraction sensitivity completed over a bounded range 0.75-1.15 and remains user-adjustable.
- Strip-count convergence 12/24/48/96 against 96-strip reference was finite with near-zero relative differences for the representative geometry case.
- Expanded trim-envelope attempts were not completed: two bounded MATLAB automation runs exceeded timeouts before producing reliable expanded 0/15/45/75/90 deg trim tables. These are recorded in `validation/wing_full_angle/final_evidence/limited_envelope_trim_validation.csv` as `NOT_RUN_AUTONOMOUS_TRIM_TIMEOUT`.
- The existing 0 deg nacelle 7-12 m/s validation remains PASS and branchWeight-free; broader trim gates are not upgraded.

## Gate Table

| Gate | Status | Reason |
|---|---|---|
| TM88373_DATA_GATE | PASS_FOR_SELECTED_FIGURE6A_GRAPH_DIGITIZATION | Figure 6a graph digitization artifacts and repeat statistics are present. |
| BRIDGE_MODEL_GATE | ENVELOPE_PASS | Candidate audit completed; deep-stall bridge rows remain unvalidated. |
| FULL_ANGLE_DATABASE_GATE | ENVELOPE_PASS | Database is finite and traceable for current limited use. |
| CONTROL_SURFACE_GATE | PARTIAL | Differential aileron aerodynamics are explicitly unmodeled. |
| WAKE_GEOMETRY_GATE | ENVELOPE_PASS | Bounded wake contraction and strip-count sensitivity completed. |
| ZERO_NACELLE_BUMP_GATE | ENVELOPE_PASS | Existing 7-12 m/s validation converged and full-angle branchWeight is zero. |
| HELICOPTER_ENVELOPE_GATE | PARTIAL | Expanded 0-30 m/s trim sweep not completed in automation. |
| CONVERSION_ENVELOPE_GATE | PARTIAL | Expanded 15/45/75 deg trim sweeps not completed in automation. |
| AIRPLANE_ENVELOPE_GATE | PARTIAL | Expanded 90 deg trim sweep not completed in automation. |
| TRIM_GATE | PARTIAL | Existing representative trims pass; requested expanded envelope remains incomplete. |
| LINEARIZATION_GATE | PASS | `run_all_checks` finite A/B matrix check passed. |
| FULL_REGRESSION_GATE | PASS | `run_all_checks` passed; legacy remains default. |

FULL_WING_MODEL_GATE = READY_FOR_LIMITED_ENVELOPE_USE

The branch is not ready for final owner review because control-surface and expanded-envelope evidence remain partial.
