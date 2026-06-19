# CODEX_TASK.md

## Closeout status (2026-06-20)

The prescribed representative run was executed once and returned **FAIL**.
All five trim points succeeded, but the existing significant-sign-flip test
flagged `cyclicLong` over 5--10 m/s and 15--20 m/s. The raw values and runtime
are preserved in `docs/REPRESENTATIVE_TRIM_CONTINUATION.md`. No threshold,
parameter, solver behavior, additional point, rescue initial, multistart,
Jacobian, or full linearization was used to change the outcome.

STATUS: FAILED — representative `cyclicLong` sign-flip criteria not met

Branch: `audit/representative-trim-continuation`

Base branch: `main`

Current phase: lightweight representative helicopter-mode trim continuation.

## Goal

Refactor the existing helicopter trim sweep so Jacobian and full-linearization diagnostics can be disabled without changing default behavior, then run a five-point representative continuation screen at `V = [0, 5, 10, 15, 20] m/s`.

This phase checks convergence, residuals, limits, continuation seed handoff, adjacent changes, deterministic bookkeeping, and runtime. It is a representative screen only. It does not establish dense branch continuity, uniqueness, a flight envelope, transition/airplane trim validity, handling qualities, or XV-15 fidelity.

## Read first

- `AGENTS.md`
- `CODEX_TASK.md`
- `params_nominal.m`
- `analysis/trim_symmetric.m`
- `analysis/trim_sweep_helicopter.m`
- `analysis/trim_residual_jacobian.m`
- `analysis/linearize_numeric.m`
- `tests/check_trim_equations.m`
- `tests/check_trim_continuity.m`
- `tests/run_all_checks.m`
- `docs/TRIM_EQUATIONS_CONTINUATION_AUDIT.md`
- `docs/AERODYNAMIC_COMPONENTS_AUDIT.md`

## Required implementation

### Optional expensive diagnostics

Add two validated options to `trim_sweep_helicopter`:

```text
computeResidualJacobian
computeLinearization
```

Requirements:

- both default to `true`, preserving all existing caller behavior;
- accept logical scalars or numeric scalar `0/1`, normalized to logical;
- use stable error identifiers for invalid values;
- when disabled, do not call `trim_residual_jacobian` or `linearize_numeric`;
- point reports must explicitly state whether each diagnostic was requested and computed;
- skipped diagnostics must remain distinguishable from failed diagnostics;
- `sweepReport.allPassed` must require a diagnostic to pass only when that diagnostic was requested;
- existing default diagnostic behavior must remain unchanged.

Do not hide a failed requested diagnostic by marking it skipped.

### Representative continuation check

Create:

```text
tests/check_representative_trim_continuation.m
```

Use exactly:

```text
speeds = [0, 5, 10, 15, 20] m/s
betaM = 0 rad
gamma = 0 rad
useContinuation = true
useTrimMultiStart = false
allowRescueInitials = false
failOnRescueInitial = true
computeResidualJacobian = false
computeLinearization = false
```

Use the existing initial seed `[0, 18, 0] deg`.

The check must verify:

1. exactly five requested and returned points;
2. all five high-level trims succeed;
3. no rescue initial is used;
4. one candidate/attempt per speed under the single-start configuration;
5. every point is finite and real;
6. reduced residual and full residual satisfy their documented tolerances;
7. no trim variable or applied control is at/over a limit;
8. each successful point seeds the next point exactly;
9. requested/computed diagnostic flags prove zero Jacobian and zero linearization calls;
10. adjacent theta, collective, and longitudinal-cyclic changes are finite and reported;
11. no adjacent sign-flip or configured jump is reported;
12. repeated execution is not required in the first pass; deterministic bookkeeping is checked structurally from one run;
13. output clearly states this is a five-point representative screen and cannot exclude unsampled local branch changes.

Do not use rescue initials to obtain a passing result. If any point fails, preserve the failure evidence and stop before adding extra starts or intermediate speeds.

## Threshold policy

Use the current `trim_sweep_helicopter` default representative-screen thresholds unless a code-level inconsistency is found:

```text
maxDeltaThetaDeg = 10
maxDeltaControlDeg = 10
signFlipThresholdDeg = 0.25
```

Record observed adjacent deltas. Do not tighten or tune thresholds to manufacture a conclusion. Do not claim smoothness between the five sampled points.

## Allowed changes

- modify `analysis/trim_sweep_helicopter.m` only to support optional diagnostics, explicit requested/computed flags, and behavior-neutral reporting;
- create `tests/check_representative_trim_continuation.m`;
- create `docs/REPRESENTATIVE_TRIM_CONTINUATION.md`;
- update `CODEX_TASK.md` at closeout;
- add lightweight diagnostic counters that do not trigger extra model evaluations.

Do not add this new check to `run_all_checks` in the first pass.

## Forbidden

- changing any numeric parameter in `params_nominal.m`;
- changing the trim variable set, objective, penalties, tolerances, limits, default seeds, or solver algorithms;
- enabling multistart or rescue initials;
- adding intermediate speed points after a failure without review;
- running the existing 21-point `check_trim_continuity`;
- running Jacobian or full linearization at any of the five points;
- reverse sweeps, dense scans, nacelle-angle sweeps, Monte Carlo, optimization grids, or flight-envelope work;
- transition/airplane trim conclusions;
- XV-15 fidelity claims.

## Runtime discipline

Before MATLAB execution, estimate:

- five high-level trim solves;
- expected objective-evaluation order of magnitude using the previous 563 evaluations for three points;
- zero Jacobian residual evaluations;
- zero full linearizations;
- expected runtime.

Run only:

```powershell
& 'F:\matlab\R2021a\bin\matlab.exe' -batch "cd('E:\tiltrotor'); run('startup.m'); r = check_representative_trim_continuation; disp(r); assert(r.allPassed);"
```

If this command exceeds about 3 minutes, stop and report. Do not run `run_all_checks` or the 21-point continuity test afterward.

Record the known MATLAB R2021a shutdown-stage `output stream error` separately from test-body results.

## Deliverables

- exact modified files;
- `docs/REPRESENTATIVE_TRIM_CONTINUATION.md`;
- test-body PASS/FAIL summary;
- actual runtime;
- actual high-level trim-solve and objective-evaluation counts;
- proof of zero Jacobian and zero full-linearization calls;
- per-point theta, collective, cyclic, reduced/full residuals, limit status, and initial source;
- adjacent changes and any sign-flip/jump flags;
- explicit statement that this is representative screening only;
- explicit statement that parameters and valid-input trim behavior changed or did not change;
- commit SHA and clean working-tree status.

Commit and push to `audit/representative-trim-continuation`.

Do not merge the PR and do not begin dense continuation, reverse sweeps, linearization maps, transition/airplane trim work, or flight-envelope analysis after completion.
