# CODEX_TASK.md

STATUS: MIDPOINT DIAGNOSIS COMPLETE / PR HOLD REMAINS

## Midpoint closeout (2026-06-20)

The authorized two-seed diagnosis at `V = 7.5 m/s` completed. Both independent
single-start solves converged to the same numerical root within the declared
`1.0e-4 deg` Euclidean tolerance:

```text
low-seed result  = [0.097205105181, 16.809576878591, -0.169175072447] deg
high-seed result = [0.097205096202, 16.809576878806, -0.169175072991] deg
difference norm  = 8.998006127586e-09 deg
```

Both solutions place the slipstream wing regions inside the current
normal-flow blend interval (`ratio = 0.282863080`, `weight = 0.133065419`).
The common root has negative `cyclicLong`. This does not locate or classify
the sign change between 7.5 and 10 m/s. Full evidence is recorded in
`docs/TRIM_MIDPOINT_7P5_DIAGNOSIS.md`.

Execution used 2 high-level trims, 448 objective evaluations, 2 direct
post-trim EOM calls, zero residual Jacobians, and zero full linearizations.
No production code or parameter changed. Draft PR #6 remains on hold.
Diagnostic evidence commit: `7c327d332ffbffc369e9e80e813a8632f22ae681`.

Branch: `audit/representative-trim-continuation`

Base branch: `main`

Current phase: focused diagnosis of the failed five-point representative helicopter-mode trim continuation screen.

## Preserved representative result

The prescribed five-point run at `V = [0, 5, 10, 15, 20] m/s` completed in 41.8 seconds.

- all five single-start trims succeeded;
- all outputs were finite and real;
- no rescue initial was used;
- each point had one attempt and one candidate;
- no trim variable or applied control reached a limit;
- continuation seeds were handed forward exactly;
- residual-Jacobian calls: 0;
- full-linearization calls: 0;
- objective evaluations: 1025;
- the configured significant-sign-flip screen failed for `cyclicLong` over 5--10 m/s and 15--20 m/s.

This is a HIGH representative-screen finding and a PR merge blocker. It is not yet classified as a HIGH production-equation bug. The present evidence cannot distinguish a continuous zero crossing, sparse-sampling aliasing, multiple roots, or path-dependent branch selection.

## Immediate goal

Diagnose the larger 5--10 m/s event with the smallest useful calculation. Do not investigate the 15--20 m/s event in this pass.

At `V = 7.5 m/s`, perform exactly two independent single-start trim solves:

```text
low-side seed  = the recorded 5 m/s solution
high-side seed = the recorded 10 m/s solution
```

Use the exact full-precision values stored in the five-point sweep report or audit document. Do not round the seeds to the display table when higher precision is available.

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
tests/diagnose_trim_midpoint_7p5.m
docs/TRIM_MIDPOINT_7P5_DIAGNOSIS.md
```

The diagnostic must:

1. execute exactly two high-level trim solves at 7.5 m/s;
2. use the recorded 5 m/s and 10 m/s solutions as the two requested seeds;
3. preserve and report each requested seed, actual candidate seed, final solution, exit flag, reduced residual, full residual, objective cost, objective-evaluation count, limits, and applied controls;
4. prove each solve used one candidate and no multistart/rescue behavior;
5. compare the two final `[theta, collective, cyclicLong]` vectors without changing either result;
6. report the raw componentwise difference and Euclidean difference in degrees;
7. state whether the two solves converged to numerically indistinguishable or materially different roots, while showing the exact comparison tolerance and its rationale;
8. call `tiltrotor_eom` once at each final solution and record existing component diagnostics only;
9. record wing free/slip-region forces, moments, local angles, normal-flow ratios, blend weights/branch diagnostics, and rotor wake quantities already available in the returned structures;
10. report whether either solution lies in or near a wing normal-flow blend region;
11. use zero residual-Jacobian calls and zero full-linearization calls;
12. make no production-model, parameter, solver, threshold, objective, penalty, tolerance, limit, or seed-default changes.

If the two midpoint seeds converge to different valid roots, stop after documenting the evidence. Do not add more speeds or starts.

If they converge to the same valid root, stop after documenting the common root and its `cyclicLong` sign. Do not immediately search for the zero crossing.

## Runtime budget

Estimate before execution:

- high-level trim solves: 2;
- expected objective evaluations: approximately 350--600 total, based on the five-point run;
- direct post-trim EOM evaluations: 2;
- residual Jacobians: 0;
- full linearizations: 0;
- expected runtime: below 60 seconds.

Run only:

```powershell
& 'F:\matlab\R2021a\bin\matlab.exe' -batch "cd('E:\tiltrotor'); run('startup.m'); r = diagnose_trim_midpoint_7p5; disp(r); assert(r.executionCompleted);"
```

The assertion must confirm execution and evidence capture, not force the two roots to match.

If the command exceeds about 2 minutes, stop and report.

## Forbidden

- modifying the five-point result or its FAIL conclusion;
- changing `signFlipThresholdDeg`;
- changing any numeric parameter;
- changing the trim model, variable set, solver, objective, penalties, tolerances, limits, or defaults;
- multistart or rescue initials;
- extra speeds such as 6, 7, 8, or 9 m/s;
- diagnosing 15--20 m/s in this pass;
- reverse sweeps;
- Jacobians or full linearizations;
- running `check_trim_continuity` or `run_all_checks`;
- claiming a physical bifurcation, hysteresis, or unique branch without evidence.

## Closeout

Update `docs/TRIM_MIDPOINT_7P5_DIAGNOSIS.md` and this task file with:

- exact two seeds and two final roots;
- all residual, limit, cost, and evaluation evidence;
- component diagnostics relevant to the midpoint difference;
- actual runtime and call counts;
- conclusion limited to one of:
  - same midpoint root from both seeds;
  - distinct midpoint roots from the two seeds;
  - one or both midpoint solves failed;
- explicit next-step recommendation, without executing it;
- commit SHA and clean working-tree status.

Commit and push to `audit/representative-trim-continuation`.

Do not merge Draft PR #6 and do not begin broader continuation or linearization work.
