# PR #27 Body Update

Status: keep this PR open, Draft, and unmerged.

## Current Gate

`FULL_WING_MODEL_GATE = READY_FOR_LIMITED_ENVELOPE_USE`

The expanded trim-envelope evidence is now real and resumable, but the overall gate is not upgraded to final owner review because:

- `CONTROL_SURFACE_GATE = PARTIAL`; no validated differential aileron aero model was added.
- `BRIDGE_MODEL_GATE = ENVELOPE_PASS`; deep-stall bridge rows remain unvalidated.
- Legacy remains the default model.

## New Evidence Added

- Added atomic point execution: `analysis/run_full_angle_trim_point.m`.
- Added resumable envelope runner: `analysis/run_full_angle_trim_envelope_resumable.m`.
- Added aggregate collector: `analysis/collect_full_angle_trim_envelope_results.m`.
- Removed the previous `NOT_RUN_AUTONOMOUS_TRIM_TIMEOUT` placeholder-row path from the final evidence flow.
- Added tests for schema, resume, hash skip, no placeholder rows, actual execution, mode definitions, and legacy/full-angle pairing.

## Trim Envelope Results

Output root:

`validation/wing_full_angle/trim_envelope/`

Aggregates:

- `full_angle_trim_envelope_results.csv`
- `full_angle_trim_envelope_summary.csv`
- `full_angle_trim_envelope_gate_status.csv`

Point evidence:

- 84 actual point rows.
- 84 converged.
- 0 timeout.
- 0 failed.
- 0 placeholder/unrun rows.

Coverage:

| betaM deg | speeds covered | models |
|---:|---|---|
| 0 | 0, 5, 10, 12, 15, 20, 25, 30 | legacy, full_angle |
| 15 | 10, 20, 30, 40, 50, 60 | legacy, full_angle |
| 45 | 35, 50, 60, 65, 70, 75, 80, 95 | legacy, full_angle |
| 75 | 70, 85, 100, 115, 125, 130, 135, 140, 145 | legacy, full_angle |
| 90 | 70, 85, 100, 115, 120, 125, 130, 135, 140, 145, 150 | legacy, full_angle |

## Tests

MATLAB R2021a:

- Focused full-angle checks: PASS.
- `run_full_angle_zero_nacelle_validation`: PASS.
- `check_article_trends`: finite diagnostic.
- New trim-envelope checks: PASS.
- `run_all_checks`: 33/33 PASS.

## Gate Table

| Gate | Status |
|---|---|
| TM88373_DATA_GATE | PASS_FOR_SELECTED_FIGURE6A_GRAPH_DIGITIZATION |
| BRIDGE_MODEL_GATE | ENVELOPE_PASS |
| FULL_ANGLE_DATABASE_GATE | ENVELOPE_PASS |
| CONTROL_SURFACE_GATE | PARTIAL |
| WAKE_GEOMETRY_GATE | ENVELOPE_PASS |
| ZERO_NACELLE_BUMP_GATE | ENVELOPE_PASS |
| HELICOPTER_ENVELOPE_GATE | ENVELOPE_PASS |
| CONVERSION_ENVELOPE_GATE | ENVELOPE_PASS |
| AIRPLANE_ENVELOPE_GATE | ENVELOPE_PASS |
| TRIM_GATE | ENVELOPE_PASS |
| LINEARIZATION_GATE | PASS |
| FULL_REGRESSION_GATE | PASS |
