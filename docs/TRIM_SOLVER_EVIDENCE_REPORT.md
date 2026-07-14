# Trim Solver Evidence Report

`report_trim_solver_evidence` exports internal numerical evidence for the
current trim solver interfaces. The report is a smoke and diagnostic artifact:
it records what the solvers return for representative conditions, including
successful and failed runs.

This report is not external validation. It is not an NUAA, Berger, or XV-15
trend comparison, and it is not a handling qualities assessment.

## Trim Modes

The report covers three GUI/service trim modes:

- `longitudinal_symmetric`: the existing `trim_symmetric` path.
- `lateral_directional_balance`: a solver-backed lateral balance that uses a
  converged longitudinal base point and solves `vdot`, `pdot`, and `rdot`.
- `full_6dof_straight_trim`: a solver-backed straight steady rigid-body trim
  that solves `udot`, `vdot`, `wdot`, `pdot`, `qdot`, and `rdot`.

## Representative Cases

The default evidence run covers:

- `helicopter_low_speed`: `V = 20 m/s`, `betaM = 0 deg`, `gamma = 0 deg`.
- `conversion_mid`: `V = 45 m/s`, `betaM = 45 deg`, `gamma = 0 deg`.
- `airplane_like`: `V = 100 m/s`, `betaM = 90 deg`, `gamma = 0 deg`.
- `conversion_high`: `V = 70 m/s`, `betaM = 75 deg`, `gamma = 0 deg`.

Each case is evaluated for the default 7-input architecture and the opt-in
8-input architecture.

## 7/8 Input Coverage

The default architecture keeps:

```text
P.control.enableLateralCyclic = false
```

The 8-input architecture explicitly sets:

```text
P.control.enableLateralCyclic = true
```

The exported fields record whether `lateralCyclic` exists, whether it is
selected by the solver report, and its command value when present. The report
does not change the project default.

## Output Files

The default output path is:

```text
validation/trim_solver_evidence/<timestamp>/
```

Generated files:

- `trim_solver_evidence.csv`: one row per case, trim mode, and architecture.
- `trim_solver_evidence.json`: structured summary records without large raw
  arrays.
- `TRIM_SOLVER_EVIDENCE_REPORT.md`: a human-readable status, controls, and
  residual summary.

The latest generated evidence output for this branch is:

```text
validation/trim_solver_evidence/20260713T164911/
```

## Field Notes

- `residual_norm`: norm reported by the mode-specific trim report.
- `primary_residual_norm`: six-DOF primary residual norm or lateral residual
  norm when available; otherwise the mode residual norm.
- `full_residual_norm`: full state-derivative norm when reported, or the norm
  of `xdot`.
- `selected_controls`: solver-reported selected controls or unknowns.
- `within_limits`: solver report limit-status flag.
- `at_limit`: solver report active-limit flag.
- `message`: success or failure reason from the service/report.

Failed trim attempts are retained as evidence rows. A failed row is not a test
failure if the service returns complete diagnostics and does not crash.

## Limitations

- The report is internal numerical evidence only.
- It does not prove all-envelope trim reliability.
- It does not perform physical external validation.
- It does not compare trends against NUAA, Berger, or XV-15 data.
- It does not validate handling qualities.
- It does not tune parameters, control limits, or solver settings.
- It does not change model equations or default control architecture.
