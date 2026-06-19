# CODEX_TASK.md

STATUS: ACTIVE

Branch: `audit/trim-equations-continuation`

Base branch: `main`

Current phase: symmetric trim equations, solver contract, limits, residuals, and continuation audit.

## Goal

Verify that the current symmetric trim formulation is internally correct, dimensionally coherent, deterministic in representative cases, explicit about its applicability limits, and safe for later continuation work.

This phase audits the existing conceptual helicopter-mode trim closure. It does not establish a full transition/airplane trim formulation, a flight envelope, or XV-15 fidelity. Preserve all production parameter values during the first pass. Do not tune parameters or broaden the trim variable set to make cases converge.

## Read first

- `AGENTS.md`
- `CODEX_TASK.md`
- `params_nominal.m`
- `analysis/trim_symmetric.m`
- `analysis/trim_sweep_helicopter.m`
- `analysis/trim_residual_jacobian.m`
- `analysis/linearize_numeric.m`
- `model/tiltrotor_eom.m`
- `model/total_forces_moments.m`
- `tests/check_trim_continuity.m`
- `tests/check_physical_sanity.m`
- `tests/run_all_checks.m`
- `docs/CONTROL_CONVENTIONS.md`
- `docs/PHYSICS_AND_CODE_AUDIT.md`
- `docs/ROTOR_FORCE_MOMENT_AUDIT.md`
- `docs/AERODYNAMIC_COMPONENTS_AUDIT.md`

Search all callers and uses of:

```text
trim_symmetric
trim_sweep_helicopter
trim_residual_jacobian
residualTolerance
variableScale
initialDeg
useMultiStart
alwaysMultiStart
allowRescueInitials
fullResidualTolerance
```

## Audit questions

### Trim-state and flight-path mapping

- Verify the relation `alpha = theta - gamma` and the mapping `u = V*cos(alpha)`, `w = V*sin(alpha)` under body axes x-forward, z-down.
- Verify the exact-hover special case and the thresholds `1e-9` and `1e-10` used by search selection and state construction.
- Verify all fixed symmetric states and controls are documented and consistent with the current 9-state model.
- Confirm the formulation is a three-variable helicopter-mode closure: `theta`, collective, and longitudinal cyclic with elevator fixed at zero.
- Identify any use at transition or airplane nacelle angles as an applicability issue unless the repository explicitly justifies the same closure.

### Residual definition

- Verify the solved residual is exactly `[udot; wdot; qdot]` from `tiltrotor_eom`.
- Verify all remaining state derivatives are near zero at accepted representative symmetric trims.
- Distinguish reduced residual norm, full 9-state derivative norm, objective cost, and penalty in reports and tests.
- Verify the residual scaling `[g; g; 1]` and variable scaling units and semantics.
- Confirm objective penalties do not silently turn an out-of-limit point into an accepted trim.

### Solver and candidate selection

- Verify exact-hover `fminbnd` behavior and the fixed `theta=0`, `cyclicLong=0` assumption.
- Verify forward-flight `fminsearch` dimensionless mapping and initial-simplex physical step.
- Verify primary and multi-start candidate generation, early stopping, tie breaking, invalid-evaluation handling, and candidate reports.
- Verify `report.converged`, `solverConverged`, `atLimit`, and `withinLimits` semantics.
- Check input validation for `V`, `betaM`, `gamma`, initial guesses, angle limits, and option types. If missing validation can produce a focused unsafe or misleading result, document the exact case and stop before changing solver behavior.

### Limits and controls

- Verify collective, cyclic, and theta limits use radians consistently.
- Verify `make_limit_report` and sweep control-limit reporting agree for common controls.
- Verify equality-at-limit policy is explicit: a point exactly at a limit is currently rejected as converged.
- Verify applied controls used by the model agree with reported trim controls.

### Jacobian and conditioning

- Verify `trim_residual_jacobian` matches the same state/control mapping as `trim_symmetric`.
- At one representative successful forward-flight point only, compare central-difference Jacobians at `1e-3`, `1e-4`, and `1e-5` rad.
- Report raw and scaled conditioning separately. Do not compute Jacobians at every speed.
- Verify rank and condition-number diagnostics remain finite or explicitly report singularity.

### Continuation and rescue logic

- Verify a successful point is passed forward as the next initial guess exactly once.
- Verify failed points do not overwrite the continuation seed.
- Verify rescue initials are opt-in and reported clearly.
- Verify attempt selection, `initialSource`, `usedRescueInitial`, and best-failed-attempt bookkeeping.
- Verify continuity and sign-flip checks use only adjacent successful points and documented thresholds.
- Do not run the default five-speed sweep during the first pass.

## Allowed changes

Allowed without further approval:

- create `docs/TRIM_EQUATIONS_CONTINUATION_AUDIT.md`;
- create `tests/check_trim_equations.m`;
- add diagnostic/report fields exposing already-computed quantities without changing the trim solution;
- update `tests/run_all_checks.m` to include a lightweight trim-contract check only if runtime remains acceptable;
- clarify comments and input semantics without changing numeric values;
- update this task file.

Potential diagnostics include:

```text
residualScale
scaledResidual
objectiveResidualCost
penaltyBreakdown
requestedInitialDeg
actualInitialDeg
candidateAcceptance
fullResidualLabels
```

Forbidden:

- changing numeric values in `params_nominal.m`;
- changing the trim variable set;
- adding elevator or other controls to the closure;
- changing objective weights, penalties, tolerances, limits, initial seeds, or solver algorithms before a focused failing case is documented and reviewed;
- broad speed sweeps, reverse sweeps, dense nacelle-angle sweeps, multi-start grids, Monte Carlo, or optimization studies;
- running point-by-point Jacobians or linearizations over a sweep;
- entering flight-envelope or handling-quality conclusions;
- claiming XV-15 fidelity.

If a possible production-code bug is found, document the exact inputs, expected contract, actual output, severity, and minimal reproduction. Stop before changing solver behavior. Purely diagnostic additions may continue.

## Required lightweight checks

Create `check_trim_equations` with named PASS/FAIL cases. Keep the first execution small.

At minimum cover:

1. state/flight-path mapping identity for one positive `gamma` and one zero-`gamma` case;
2. exact residual extraction `[udot;wdot;qdot]` from the full EOM output;
3. exact-hover closure and full-state derivative consistency;
4. one representative forward-flight single-start trim with finite outputs and no active limits;
5. a second forward-flight point seeded from the first, verifying continuation handoff;
6. reduced residual and full residual acceptance semantics;
7. trim-variable and applied-control limit-report consistency;
8. deterministic repeat of one single-start case;
9. objective/report scaling and penalty diagnostic identity when available;
10. one-point Jacobian step comparison at `1e-3`, `1e-4`, and `1e-5` rad;
11. static or synthetic verification that a failed point cannot replace a successful continuation seed;
12. explicit applicability result for transition/airplane nacelle angles with elevator fixed at zero.

First-pass solver budget:

- maximum 3 successful high-level trim solves;
- `useMultiStart=false` for all first-pass solves;
- no rescue initials;
- one Jacobian location only;
- no full linearization calls in the new target check.

Use representative helicopter-mode speeds only: exact hover plus at most two forward speeds selected from `10` and `20 m/s`. Reuse earlier solutions as seeds.

## Runtime discipline

Before running MATLAB, estimate the expected number of high-level trim solves, residual evaluations, and Jacobian evaluations. Print the estimate in the final report.

Run in stages:

```text
static audit
-> check_trim_equations
-> existing check_trim_continuity only if the target check passes and estimated runtime is acceptable
-> run_all_checks once only if the added check does not make the suite unreasonably long
```

Do not run `trim_sweep_helicopter` with its default five speeds in the first pass. A three-point `[0,10,20]` continuation check is optional only after the direct target check passes. If estimated or observed runtime exceeds about 3 minutes for one command, stop and report before expanding.

Suggested target command:

```powershell
& 'F:\matlab\R2021a\bin\matlab.exe' -batch "cd('E:\tiltrotor'); run('startup.m'); r = check_trim_equations; disp(r); assert(r.allPassed);"
```

Record the MATLAB R2021a shutdown-stage `output stream error` separately from test-body results.

## Deliverables

- `docs/TRIM_EQUATIONS_CONTINUATION_AUDIT.md` with findings classified as `CRITICAL`, `HIGH`, `MEDIUM`, `LOW`, or `INFO`;
- focused test results and actual runtime;
- estimated and actual high-level trim-solve count;
- exact residual/Jacobian evaluation count where practical;
- explicit conclusions on state mapping, residual closure, bounds, candidate selection, hover assumptions, and continuation behavior;
- clear applicability statement for transition/airplane nacelle angles;
- exact modified files;
- explicit statement that parameters and solver behavior changed or did not change;
- commit SHA and clean working-tree status.

Commit and push to `audit/trim-equations-continuation`.

Do not merge the PR and do not begin dense continuation, reverse sweeps, linearization maps, or flight-envelope work after completion.
