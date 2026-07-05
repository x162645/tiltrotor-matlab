# Full-Angle Wing Autonomous Workflow Report

Branch: `task/full-wing-model-autonomous-20260702`

Draft PR: #27

## Implemented

- Isolated worktree continued at `E:\tiltrotor-full-wing-model`.
- Legacy wing model remains preserved and default.
- Full-angle wing model remains opt-in and parallel under `model/wing/`.
- TM-88373 Figure 6a selected curves use graph digitization artifacts with repeat statistics.
- Multidimensional full-angle database remains `CL/CD/Cm(alpha,Re,Mach,flapDeg)`.
- CR-114614/CR-176970 wake strip geometry sensitivity remains bounded and parameterized.
- The full-angle path uses one coefficient lookup for free-stream and wake strip portions.
- The full-angle path explicitly does not claim validated differential aileron aerodynamics.
- New point-by-point trim envelope framework:
  - atomic point executor;
  - resumable envelope runner;
  - aggregate collector with summary, gates, and figures.

## Validation

- `run_all_checks`: 33/33 PASS on MATLAB R2021a.
- Legacy identity: PASS, exact force/moment identity.
- TM-88373 graph digitization: PASS, 126 points, repeat max difference 1.177566806187e-02.
- Database checks: PASS, 12,996 rows.
- Bridge candidate audit: PASS as `ENVELOPE_PASS`; deep stall remains unvalidated.
- Wake strip focused check: PASS; contraction remains an adjustable assumption.
- 0-deg nacelle formal sweep: legacy and full-angle both 21/21 converged; `branchWeightInNew = 0`.
- Resumable trim envelope: 84 actual point rows, all converged, no timeout, no placeholder rows.
- GUI checks: catalog, modified IDs, parameter page and services all PASS.

## Envelope Evidence

The formal point files are stored in:

`validation/wing_full_angle/trim_envelope/points/`

Aggregates:

- `validation/wing_full_angle/trim_envelope/full_angle_trim_envelope_results.csv`
- `validation/wing_full_angle/trim_envelope/full_angle_trim_envelope_summary.csv`
- `validation/wing_full_angle/trim_envelope/full_angle_trim_envelope_gate_status.csv`

Coverage:

| betaM deg | speeds covered | models |
|---:|---|---|
| 0 | 0, 5, 10, 12, 15, 20, 25, 30 | legacy, full_angle |
| 15 | 10, 20, 30, 40, 50, 60 | legacy, full_angle |
| 45 | 35, 50, 60, 65, 70, 75, 80, 95 | legacy, full_angle |
| 75 | 70, 85, 100, 115, 125, 130, 135, 140, 145 | legacy, full_angle |
| 90 | 70, 85, 100, 115, 120, 125, 130, 135, 140, 145, 150 | legacy, full_angle |

## Scope Statements

- The model claims standard NACA 64A223, not the unrecovered XV-15 modified airfoil.
- The CR-114614 artifact is a verified local technical extract, not the 268-page original facsimile.
- Positive deep-stall rows are present for full-angle closure and are explicitly tagged unvalidated.
- The wake model is a source-traced strip projection, not a free-wake or CFD method.
- The database plain-flap dimension is not a differential aileron validation.
- Full-angle database clamping diagnostics are reported in point rows; clamped full-angle rows remain inside the disclosed finite envelope, not experimental validation.

## Gate

`FULL_WING_MODEL_GATE = READY_FOR_LIMITED_ENVELOPE_USE`

The branch has stronger trim-envelope evidence than the prior limited-use gate, but it is still not ready for final owner review because differential aileron aerodynamics remain unsupported and deep-stall bridge rows are not fully validated.
