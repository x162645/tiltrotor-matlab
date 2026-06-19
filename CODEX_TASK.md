# CODEX_TASK.md

STATUS: ACTIVE / FIX REQUIRED

Branch: `audit/trim-equations-continuation`

Base branch: `main`

Current phase: symmetric trim equations, solver contract, limits, residuals, continuation, and input-validation remediation.

## Audit result

- `check_trim_equations`: 15/15 PASS;
- three successful high-level trim solves completed;
- 563 objective evaluations versus an 18,000 conservative upper estimate;
- one 10 m/s Jacobian location checked at `1e-3`, `1e-4`, and `1e-5 rad` using 18 residual evaluations;
- no full linearization was called;
- numeric parameters, solver algorithm, objective, penalties, tolerances, limits, seeds, and trim-variable set were unchanged;
- HIGH input-validation defect remains unresolved: negative `V` enters the collective-only hover path;
- MEDIUM entry-validation gaps remain for `betaM`, `gamma`, option booleans, theta limit, and initial-vector finiteness/type;
- Draft PR #5 must not be merged until focused validation guards and regression checks are reviewed;
- do not begin dense continuation, reverse sweeps, linearization maps, or flight-envelope work.

## Required remediation before closeout

Add focused entry validation without changing valid-input trim results:

- `V`: real finite scalar and `V >= 0`;
- `betaM`: real finite scalar within the supported tilt range `[0, pi/2]`;
- `opts.gamma`: real finite scalar;
- `opts.initialDeg`: real finite vector with at least three elements;
- `opts.thetaLimitDeg`: real finite positive scalar;
- `opts.useMultiStart` and `opts.alwaysMultiStart`: logical scalar or numeric scalar exactly `0` or `1`, then normalize to logical.

Apply consistent physical-input validation to `trim_residual_jacobian`. Validate `trim_sweep_helicopter` speed vectors as real, finite, and nonnegative before any solve. Preserve current thresholds, solver behavior, objective, penalties, limits, and defaults for valid inputs.

Extend focused tests with no-solve invalid-input cases and rerun `check_trim_equations` once. Do not run the 21-point continuity check or `run_all_checks` in this remediation pass.
