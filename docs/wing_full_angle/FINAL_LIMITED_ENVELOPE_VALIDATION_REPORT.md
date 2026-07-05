# Final Limited Envelope Validation Report

Date: 2026-07-04

This report is a bounded computational evidence sweep. It is not XV-15 flight-test validation.

## Wake Sensitivity

- Rows: 16
- Contraction range: 0.75 to 1.15
- Max total coverage fraction: 1

## Strip Convergence

- Max force relative difference vs 96 strips: 1.57662e-15
- Max moment relative difference vs 96 strips: 3.32833e-15

## Trim Envelope

- Points attempted: 84
- Converged points: 84
- Finite real points: 84
- Timeout points: 0
- Failed points: 0
- Placeholder/unrun rows: 0
- Point evidence root: `validation/wing_full_angle/trim_envelope/points/`
- Aggregates:
  - `validation/wing_full_angle/trim_envelope/full_angle_trim_envelope_results.csv`
  - `validation/wing_full_angle/trim_envelope/full_angle_trim_envelope_summary.csv`
  - `validation/wing_full_angle/trim_envelope/full_angle_trim_envelope_gate_status.csv`

Per-beta/model counts:

| betaM deg | model | attempted | converged | timeout | failed |
|-:|-|-:|-:|-:|-:|
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

## Gate Table

|Gate|Status|Reason|
|-|-|-|
|TM88373_DATA_GATE|PASS_FOR_SELECTED_FIGURE6A_GRAPH_DIGITIZATION|Figure 6a graph digitization artifacts and repeat statistics are present.|
|BRIDGE_MODEL_GATE|ENVELOPE_PASS|Bridge sensitivity audit includes current, endpoint, flat-plate, and Viterna-reference candidates; deep stall remains unvalidated.|
|FULL_ANGLE_DATABASE_GATE|ENVELOPE_PASS|Database finite with graph TM rows and disclosed bridge share.|
|CONTROL_SURFACE_GATE|PARTIAL|No sourced full-angle differential aileron data; full-angle aileron derivative remains zero by design.|
|WAKE_GEOMETRY_GATE|ENVELOPE_PASS|Wake contraction sensitivity completed over bounded assumed range.|
|ZERO_NACELLE_BUMP_GATE|ENVELOPE_PASS|Existing 7-12 m/s zero-nacelle validation passes; expanded point files are reported separately.|
|HELICOPTER_ENVELOPE_GATE|ENVELOPE_PASS|Helicopter-mode status is based only on actual saved point files.|
|CONVERSION_ENVELOPE_GATE|ENVELOPE_PASS|15/45/75 deg conversion status is based only on actual saved point files.|
|AIRPLANE_ENVELOPE_GATE|ENVELOPE_PASS|90 deg airplane status is based only on actual saved point files.|
|TRIM_GATE|ENVELOPE_PASS|Aggregate trim status counts only actual point files; unstarted points are absent.|
|LINEARIZATION_GATE|PASS|Dedicated run_all_checks linearization test covers finite A/B matrix.|
|FULL_REGRESSION_GATE|PASS|Legacy default remains legacy; run_all_checks passed in final validation.|
