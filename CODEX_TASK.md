# CODEX_TASK.md

STATUS: COMPLETE / HOLD

Branch: `audit/trim-equations-continuation`

Base branch: `main`

Current phase: symmetric trim equations, solver contract, limits, residuals, continuation, and input-validation remediation.

## Completed scope

- focused trim, Jacobian, and sweep-entry validation remediation is complete;
- negative, non-finite, non-real, or nonscalar airspeed is rejected before threshold or solver execution;
- nacelle angle, flight-path angle, initial trim vector, theta limit, and multistart option validation is complete for the requested scope;
- sweep speeds, sweep nacelle angle, and sweep flight-path angle are validated before any trim attempt;
- `check_trim_equations`: 34/34 PASS, including 19/19 exact-identifier invalid-input checks;
- three successful valid-input high-level trim solves completed at 0, 10, and 20 m/s;
- valid-input objective evaluations remained 563, unchanged from the pre-fix focused run;
- one 10 m/s Jacobian location remained checked at `1e-3`, `1e-4`, and `1e-5 rad` using 18 residual evaluations;
- no full linearization was called;
- numeric parameters, solver algorithm, objective, penalties, tolerances, limits, seeds, trim-variable set, and valid-input trim behavior were unchanged;
- Draft PR #5 awaits final review and must not be merged by Codex;
- do not begin dense continuation, reverse sweeps, linearization maps, or flight-envelope work.

## Hold boundary

This branch remains in the trim-equation and continuation-audit stage pending
final Draft PR #5 review. Do not merge the PR and do not enter dense
continuation, reverse sweeps, linearization maps, or flight-envelope work.
