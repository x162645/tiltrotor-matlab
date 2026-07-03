# Final Limited Envelope Validation Report

Date: 2026-07-03

This report is a bounded computational evidence sweep. It is not XV-15 flight-test validation.

## Wake Sensitivity

- Rows: 16
- Contraction range: 0.75 to 1.15
- Max total coverage fraction: 1

## Strip Convergence

- Max force relative difference vs 96 strips: 1.57662e-15
- Max moment relative difference vs 96 strips: 3.32833e-15

## Trim Envelope

- Points attempted: 12
- Converged points: 0
- Finite real points: 0

## Gate Table

|Gate|Status|Reason|
|-|-|-|
|TM88373_DATA_GATE|PASS_FOR_SELECTED_FIGURE6A_GRAPH_DIGITIZATION|Figure 6a graph digitization artifacts and repeat statistics are present.|
|BRIDGE_MODEL_GATE|ENVELOPE_PASS|Bridge sensitivity audit includes current, endpoint, flat-plate, and Viterna-reference candidates; deep stall remains unvalidated.|
|FULL_ANGLE_DATABASE_GATE|ENVELOPE_PASS|Database finite with graph TM rows and disclosed bridge share.|
|CONTROL_SURFACE_GATE|PARTIAL|No sourced full-angle differential aileron data; full-angle aileron derivative remains zero by design.|
|WAKE_GEOMETRY_GATE|ENVELOPE_PASS|Wake contraction sensitivity completed over bounded assumed range.|
|ZERO_NACELLE_BUMP_GATE|ENVELOPE_PASS|Existing 7-12 m/s zero-nacelle validation passes; requested 0-30 m/s expansion was not completed after two bounded automation attempts.|
|HELICOPTER_ENVELOPE_GATE|PARTIAL|Helicopter-mode trim expansion remains partial because automation trim attempts timed out.|
|CONVERSION_ENVELOPE_GATE|PARTIAL|15/45/75 deg conversion trim expansion remains partial because automation trim attempts timed out.|
|AIRPLANE_ENVELOPE_GATE|PARTIAL|90 deg airplane trim expansion remains partial because automation trim attempts timed out.|
|TRIM_GATE|PARTIAL|Existing representative trims and 7-12 m/s zero-nacelle sweep pass; requested expanded envelope remains incomplete.|
|LINEARIZATION_GATE|PASS|Dedicated run_all_checks linearization test covers finite A/B matrix.|
|FULL_REGRESSION_GATE|PASS|Legacy default remains legacy; run_all_checks passed in final validation.|
