# CODEX_TASK.md

STATUS: COMPLETE / TRIM CREDIBILITY METHOD / HOLD

Branch: `planning/trim-credibility-method-final2`

Base branch: `main`

## Priority mainline

1. `RH_mass/RH_hub` split: COMPLETE AND MERGED.
2. General mode-dependent trim core: COMPLETE AND MERGED.
3. Open-loop pitch-actuator allocation: COMPLETE AND MERGED.
4. Trim credibility diagnostics: CURRENT TARGET; METHOD PACKET READY.
5. Linearization credibility diagnostics.
6. Robust induced-velocity root solution.

Do not start items 5-6 before item 4 is implemented, tested, reviewed, and merged.

## Purpose

Prepare the electronic-book-grounded method packet for evaluating whether a low-residual trim point is locally independent, numerically stable, within adequate control margins, and consistent under limited deterministic perturbations.

The durable method file is:

```text
docs/ebook_packets/TRIM_CREDIBILITY_PACKET.md
```

## Fixed technical route

The future diagnostic will:

- preserve the existing `trim_general` solver and acceptance logic;
- compute raw and solver-scaled trim Jacobians;
- use scaled finite-difference steps `[1e-2, 1e-3, 1e-4]`;
- use central differences where legal and second-order one-sided differences near bounds;
- report SVD, default rank, effective rank, singular values, and condition number;
- report Jacobian step sensitivity;
- report all nine state derivatives;
- report unknown/direct-actuator margins and commanded/applied differences;
- run two deterministic alternate seeds only at the 35 m/s, 45 deg conversion point;
- run only four local condition perturbations around that conversion point;
- classify results as `PASS`, `CAUTION`, or `FAIL` without changing the model or solver.

The 35 m/s, 45 deg point is expected to receive `CAUTION` because the merged pitch-allocation result leaves about 6.63% cyclic/elevator authority margin. That warning is a required diagnostic result, not a reason to tune parameters.

## Representative conditions

```text
helicopter_longitudinal: V=20 m/s, betaM=0, gamma=0
conversion_longitudinal: V=35 m/s, betaM=pi/4, gamma=0
airplane_longitudinal: V=100 m/s, betaM=pi/2, gamma=0
```

No operating-condition grid is allowed.

## Mandatory implementation gate

After this documentation branch is merged, create a separate implementation branch.

Codex must first run a read-only prototype that computes the three-step Jacobians, SVD/rank/condition, full derivatives, and margins at the three representative points. Production diagnostic code may be written only after those prototype results are reviewed.

## Future implementation scope

Expected files:

```text
analysis/diagnose_trim_credibility.m
analysis/evaluate_trim_definition_point.m   # only if shared point evaluation is necessary
tests/check_trim_credibility.m
tests/run_all_checks.m
docs/TRIM_CREDIBILITY_AUDIT.md
CODEX_TASK.md
```

A minimal compatibility-preserving refactor of `analysis/trim_general.m` is allowed only if required to avoid duplicated point-construction logic and only after exact output identity is demonstrated.

## Forbidden changes

```text
params_nominal.m
model/*
app/*
services/*
analysis/linearize_numeric.m
analysis/trim_symmetric.m
analysis/pitch_allocation_schedule.m
control limits
trim tolerances
solver settings
```

Do not:

- rewrite the trim solver;
- switch to Newton, `fsolve`, or Optimization Toolbox;
- alter allocation directions, cosine weights, or dynamic command range;
- use random/dense multistart or broad speed/tilt sweeps;
- enter A/B linearization diagnostics;
- automatically retune variables based on condition number;
- claim XV-15 or flight-test validation.

## Scope of this branch

Documentation only. No MATLAB production file, test, parameter, model equation, GUI, service, solver, limit, linearization, or inflow code is changed.

## Closeout

This branch remains on HOLD for review. Do not add implementation code and do not merge without explicit user authorization.
