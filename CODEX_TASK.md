# CODEX_TASK.md

STATUS: SECOND MIDPOINT DIAGNOSIS COMPLETE / PR HOLD REMAINS

## 17.5 m/s midpoint closeout (2026-06-20)

The authorized two-seed single-start diagnosis at `V = 17.5 m/s` completed.
Both seeds converged to the same numerical root within the unchanged
`1.0e-4 deg` Euclidean tolerance:

```text
low-seed result  = [3.774686179733, 15.368703848185, -0.416693326063] deg
high-seed result = [3.774686185574, 15.368703844841, -0.416693331459] deg
difference norm  = 8.626264725850e-09 deg
```

The common `cyclicLong` is negative. No wing free-stream or slipstream region
was in or near the normal-flow blend interval; the slipstream ratio was
`0.664290521` with blend weight `1.0`.

Execution used 2 high-level trims, 479 objective evaluations, 2 direct
post-trim EOM calls, zero residual Jacobians, and zero full linearizations.
No production code or parameter changed. Full evidence is in
`docs/TRIM_MIDPOINT_17P5_DIAGNOSIS.md`. Draft PR #6 remains on hold.
Diagnostic evidence commit: `572d42d5b716b566b1f062e9970825ec2dad3bc1`.

Branch: `audit/representative-trim-continuation`

Base branch: `main`

Current phase: focused classification of the two `cyclicLong` sign-flip intervals found by the five-point representative helicopter-mode trim screen.

## Preserved five-point result

The representative run at `V = [0, 5, 10, 15, 20] m/s` remains **FAIL** under the configured significant-sign-flip criterion.

- all five single-start trims succeeded;
- all results were finite and real;
- reduced and full residuals passed;
- no rescue or multistart was used;
- no trim variable or applied control reached a limit;
- continuation seeds were passed forward exactly;
- residual-Jacobian calls: 0;
- full-linearization calls: 0;
- objective evaluations: 1025;
- sign-flip intervals: 5--10 m/s and 15--20 m/s.

The representative FAIL result must remain preserved. Do not change thresholds, parameters, solver behavior, or test acceptance logic to obtain a PASS.

## Completed 7.5 m/s diagnosis

The authorized two-seed single-start diagnosis at `V = 7.5 m/s` is complete.

```text
low-seed result  = [0.097205105181, 16.809576878591, -0.169175072447] deg
high-seed result = [0.097205096202, 16.809576878806, -0.169175072991] deg
difference norm  = 8.998006127586e-09 deg
same-root tolerance = 1.0e-4 deg
```

Both seeds converged to the same numerical root, and the common `cyclicLong` is negative. This strongly reduces evidence for midpoint seed dependence in the 5--10 m/s interval. It does not establish global uniqueness, smoothness, or the exact zero-crossing speed.

Both midpoint solutions place the left and right slipstream wing regions inside the existing normal-flow blend interval:

```text
normal-flow ratio = 0.282863080
blend weight      = 0.133065419
wake velocity     = 25.444434343 m/s
local alpha       = -73.568843 deg
```

Execution accounting:

- high-level trim solves: 2;
- objective evaluations: 448;
- direct post-trim EOM calls: 2;
- residual Jacobians: 0;
- full linearizations: 0;
- internal elapsed time: 13.9255 s;
- command wall time: 32 s.

Evidence is stored in `docs/TRIM_MIDPOINT_7P5_DIAGNOSIS.md` and commit `7c327d332ffbffc369e9e80e813a8632f22ae681`.

## Immediate goal

Classify the remaining 15--20 m/s sign-flip interval with the same smallest useful calculation.

At `V = 17.5 m/s`, perform exactly two independent single-start trim solves:

```text
low-side seed  = the recorded 15 m/s solution
high-side seed = the recorded 20 m/s solution
```

Use the highest precision persisted in repository evidence. Do not rerun the 15 or 20 m/s endpoints solely to obtain more digits.

Common settings:

```text
betaM = 0 rad
gamma = 0 rad
useMultiStart = false
alwaysMultiStart = false
no rescue initial
```

## Required implementation

Create:

```text
tests/diagnose_trim_midpoint_17p5.m
docs/TRIM_MIDPOINT_17P5_DIAGNOSIS.md
```

The diagnostic must:

1. execute exactly two high-level trim solves at 17.5 m/s;
2. use the recorded 15 and 20 m/s solutions as the two requested seeds;
3. preserve and report each requested seed, actual candidate seed, final solution, exit flag, reduced residual, full residual, objective cost, objective-evaluation count, limits, and applied controls;
4. prove each solve used one candidate and no multistart or rescue behavior;
5. compare the two final `[theta, collective, cyclicLong]` vectors componentwise and by Euclidean norm in degrees;
6. use the same declared same-root tolerance of `1.0e-4 deg` unless a documented code-level reason requires a different value;
7. call `tiltrotor_eom` once at each final solution and record existing component diagnostics only;
8. record wing free/slip-region forces, moments, local angles, normal-flow ratios, blend weights/branch diagnostics, and rotor wake quantities already available;
9. report whether either solution lies in or near a wing normal-flow blend region;
10. use zero residual-Jacobian calls and zero full-linearization calls;
11. make no production-model, parameter, threshold, solver, objective, penalty, tolerance, limit, or default-seed changes.

The conclusion must be limited to one of:

- same 17.5 m/s numerical root from both seeds;
- distinct 17.5 m/s numerical roots from the two seeds;
- one or both 17.5 m/s solves failed.

If the two seeds converge to different valid roots, stop after documenting the evidence. If they converge to the same root, record the common `cyclicLong` sign and stop. Do not locate the zero crossing in this pass.

## Runtime budget

Estimate before execution:

- high-level trim solves: 2;
- expected objective evaluations: approximately 350--600 total;
- direct post-trim EOM evaluations: 2;
- residual Jacobians: 0;
- full linearizations: 0;
- expected runtime: below 60 seconds.

Run only:

```powershell
& 'F:\matlab\R2021a\bin\matlab.exe' -batch "cd('E:\tiltrotor'); run('startup.m'); r = diagnose_trim_midpoint_17p5; disp(r); assert(r.executionCompleted);"
```

The assertion confirms execution and evidence capture. It must not force the two roots to match.

If the command exceeds about 2 minutes, stop and report.

## Forbidden

- modifying the original five-point FAIL result;
- changing `signFlipThresholdDeg` or any other threshold;
- changing any numeric parameter;
- changing the trim model, variable set, solver, objective, penalties, tolerances, limits, or defaults;
- multistart or rescue initials;
- extra speeds such as 16, 17, 18, or 19 m/s;
- further 5--10 m/s calculations in this pass;
- reverse sweeps;
- Jacobians or full linearizations;
- running `check_trim_continuity` or `run_all_checks`;
- claiming bifurcation, hysteresis, physical discontinuity, or branch uniqueness without evidence.

## Closeout

Update `docs/TRIM_MIDPOINT_17P5_DIAGNOSIS.md` and this task file with:

- exact two seeds and two final roots;
- residual, cost, limit, candidate, and evaluation evidence;
- component diagnostics relevant to the midpoint result;
- actual runtime and call counts;
- the restricted conclusion listed above;
- explicit next-step recommendation without executing it;
- commit SHA and clean working-tree status.

Commit and push to `audit/representative-trim-continuation`.

Do not merge Draft PR #6 and do not begin broader continuation, reverse sweeps, zero-crossing searches, or linearization work.
