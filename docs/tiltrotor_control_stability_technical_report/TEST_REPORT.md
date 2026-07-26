# Test Report

## Environment

- MATLAB: R2021a at `F:\matlab\R2021a\bin\matlab.exe`
- Operating system: Windows
- Assessment base/head: `65e459504dd473f6dcf18326028f3a8a7991c55a` /
  `99acba44740087fdf3d7cdc82efd191c87cfb2d1`

## Full Regression

The complete MATLAB command `run_all_checks` was executed in the isolated
control-stability worktree. It completed successfully with
`FULL_RUN_ALL_CHECKS_OK=1`.

All 29 registered checks passed. This includes the focused
`check_control_stability_assessment` suite, for which all 14 checks passed:

- input-interface and B-column contracts;
- three representative trim credibility;
- finite real derivatives and three-level differencing;
- direct-load and A/B crosschecks;
- participation normalization and pathological-mode handling;
- control-step time-step refinement and linear/nonlinear direction agreement;
- exclusion of unsupported rotor branches;
- trim-mode separation;
- unchanged production model/default parameters;
- restricted NASA comparison wording.

The complete stdout and stderr records are retained in `logs/` as
`FULL_RUN_ALL_CHECKS.stdout.log` and `FULL_RUN_ALL_CHECKS.stderr.log`.

## Independent Low-Collective Audit

`check_low_collective_quick_audit` was run separately after the full
regression. All nine focused checks passed. It retained, rather than concealed,
the expected boundary behavior:

- 4 deg: a numerical rotor return on an unsupported negative-thrust branch is
  rejected;
- 8 deg and 10 deg: coupled-solve nonconvergence remains a production failure;
- 12 deg: diagnostic and production results agree with physical closure.

Its generated records are retained under `docs/low_collective_quick_audit/`.

## Numerical Output Audit

The current result CSV audit found:

- unexpected missing/NaN values: 0;
- Inf values: 0;
- unexpected complex values: 0.

Some blank or NaN fields are structural not-applicable values, such as modal
time metrics for incompatible root types and `firstInvalidIndex` for a
successful step. They are documented in `NUMERIC_OUTPUT_AUDIT.md` and are not
numerical failures.

All three representative points are credible, physically converged, and finite
for the 9-state model plus both 13-state forms:

| Point | Trim mode | Residual norm | Physical closure |
|---|---|---:|---|
| 15 deg / 20 m/s | helicopter longitudinal | 4.49e-10 | yes |
| 45 deg / 35 m/s | conversion longitudinal | 6.60e-10 | yes |
| 75 deg / 80 m/s | airplane longitudinal | 1.49e-09 | yes |

At 75 deg / 80 m/s, an exploratory 0.5 deg differential-collective step left
the supported rotor branch. It is recorded in
`CONTROL_STEP_AMPLITUDE_AUDIT.md` and excluded from formal response metrics.
The formal 0.25 deg step for that channel group was independently checked for
physical closure; no limits, parameters, or production physics were changed.

## Static Checks

`checkcode` completed with zero issues for the new MATLAB analysis files.
The final `git diff --check` completed with no whitespace errors.
