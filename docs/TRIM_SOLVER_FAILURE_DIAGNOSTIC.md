# Trim Solver Failure Diagnostic

This document explains why 18 rows in the PR #44 trim solver evidence are
recorded as failures or non-converged diagnostic evidence. It is based on:

```text
validation/trim_solver_evidence/20260713T164911/
```

It does not rerun the trim solvers, change solver mathematics, tune
parameters, expand limits, or relabel failures as successes.

## 1. Executive Summary

- Total records: 24.
- Successes: 6.
- Failures/non-converged rows: 18.
- Run errors: 0.
- The low-speed helicopter case succeeds for all trim modes and both
  architectures.
- All non-helicopter representative cases fail in all three modes.
- Main failure categories:
  - `BASE_TRIM_DEPENDENCY_FAILURE`: 6.
  - `FULL6DOF_FORMULATION_LIMITATION`: 6.
  - `CONTROL_OR_STATE_LIMIT_CONTACT`: 4.
  - `PRIMARY_RESIDUAL_NOT_REDUCED`: 2.

The dominant pattern is not a solver crash. Most failures trace to
longitudinal force/pitch balance not being achieved in conversion and
airplane-like representative cases. The lateral balance mode then correctly
refuses to run when its longitudinal base trim dependency has already failed.

## 2. Failure Matrix

|case|architecture|longitudinal|lateral|full6dof|notes|
|-|-|-|-|-|-|
|helicopter_low_speed|7-input|PASS|PASS|PASS|all modes converge|
|helicopter_low_speed|8-input|PASS|PASS|PASS|all modes converge|
|conversion_mid|7-input|FAIL|FAIL|FAIL|longitudinal `cyclicLong = -35 deg` limit; lateral blocked by base failure; full6dof residual about 2.20|
|conversion_mid|8-input|FAIL|FAIL|FAIL|same base failure; 8-input full6dof residual modestly lower but still fails|
|airplane_like|7-input|FAIL|FAIL|FAIL|longitudinal `cyclicLong = +35 deg` limit; full6dof residual about 3.16|
|airplane_like|8-input|FAIL|FAIL|FAIL|lateralCyclic is selected in full6dof, but `wdot` remains dominant|
|conversion_high|7-input|FAIL|FAIL|FAIL|no active longitudinal limit, but residual remains about 6.20|
|conversion_high|8-input|FAIL|FAIL|FAIL|8-input full6dof has no meaningful residual improvement|

## 3. Failure Category Counts

|category|count|meaning|
|-|-:|-|
|`BASE_TRIM_DEPENDENCY_FAILURE`|6|`lateral_directional_balance` did not run because the longitudinal base trim did not converge.|
|`FULL6DOF_FORMULATION_LIMITATION`|6|`full_6dof_straight_trim` ran, but the residual norm stayed far above tolerance.|
|`CONTROL_OR_STATE_LIMIT_CONTACT`|4|A trim/control variable reached an active limit, mainly `cyclicLong = +/-35 deg`.|
|`PRIMARY_RESIDUAL_NOT_REDUCED`|2|Residual remains high without active limit contact, mainly conversion_high longitudinal rows.|

## 4. Dominant Residual Analysis

|case|dominant residual|interpretation|
|-|-|-|
|conversion_mid|`udot`|body-x acceleration / longitudinal force balance dominates.|
|airplane_like|`wdot`|body-z acceleration / lift-thrust balance dominates.|
|conversion_high|`wdot`|body-z acceleration / lift-thrust balance dominates.|

Scaled residuals and raw residuals identify the same dominant channels in
these rows. Moment residuals such as `qdot` are present, but they are not the
largest raw residuals.

## 5. Limit and Control Analysis

- `conversion_mid`: longitudinal trim reaches `cyclicLong = -35 deg`.
- `airplane_like`: longitudinal trim reaches `cyclicLong = +35 deg`.
- `conversion_high`: no active limit is reported, but the residual remains
  high with the current longitudinal unknown set.
- Lateral failures are mostly dependency failures. They should not be used to
  judge the lateral objective itself, because the lateral solver did not run
  after the base trim failed.
- `full_6dof_straight_trim` 8-input rows select `lateralCyclic`, but the
  dominant remaining residual is still a longitudinal force term.
- `elevator_deg` stays zero in the full6dof failure rows. Whether elevator
  should enter the full6dof unknown set in conversion or fixed-wing-like
  conditions is a diagnostic hypothesis, not a proven fix.

## 6. 7-input vs 8-input Comparison

|case|mode|7-input residual|8-input residual|interpretation|
|-|-|-:|-:|-|
|helicopter_low_speed|all modes|near zero|near zero|both architectures already converge.|
|conversion_mid|full6dof|2.197|2.131|8-input modestly improves the residual, but the row still fails tolerance.|
|airplane_like|full6dof|3.157|3.135|lateral residual may improve, but `wdot` dominates.|
|conversion_high|full6dof|6.195|6.197|no meaningful total residual improvement.|

Do not conclude that `lateralCyclic` is ineffective. These rows are dominated
by longitudinal residuals or base-trim dependency failures. A dedicated
allocation, regularization, and sensitivity study is required before making a
control-effectiveness conclusion.

## 7. Most Likely Root Causes

Solver/formulation level:

- Lateral failures mostly reflect base-trim dependency failures, not lateral
  objective failures.
- Full 6-DOF runs are real evaluations, but the current unknown/control set
  does not reduce residuals close to tolerance in conversion/high-speed cases.

Control allocation level:

- `cyclicLong` reaches bounds in conversion_mid and airplane_like.
- `lateralCyclic` participates in 8-input full6dof rows, but it does not remove
  the dominant longitudinal residuals.

Model/physics level:

- Conversion and airplane-like cases expose stronger thrust/lift/pitch
  coupling than the current representative trim variable set resolves.
- This does not prove that model equations are wrong.

Numerical optimization level:

- conversion_high has no active limit but still a high `wdot` residual, so
  multi-start, variable scaling, or residual weighting sensitivity is a
  follow-up diagnostic rather than a code fix in this PR.

## 8. Recommended Next Actions

A. Run a longitudinal trim robustness audit first.

B. Audit whether elevator should enter the full6dof unknown set in
conversion/fixed-wing-like conditions.

C. Audit lateral objectives only on cases with converged base trim.

D. Run `cyclicLong` limit sensitivity.

E. Run `lateralCyclic` allocation / regularization sensitivity.

F. Run multi-start / variable scaling / residual weighting sensitivity.

## 9. What Not To Claim

- No external validation passed.
- No all-envelope trim reliability is proven.
- No NUAA/Berger/XV-15 trend consistency is claimed.
- Solver failure does not prove model equations are wrong.
- Do not claim `lateralCyclic` is ineffective.
- Non-convergence is not a run error.
