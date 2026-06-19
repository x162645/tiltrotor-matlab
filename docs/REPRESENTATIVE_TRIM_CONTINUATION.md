# Representative Helicopter-Mode Trim Continuation Screen

## Scope and conclusion

This audit ran the prescribed five-point helicopter-mode continuation screen at `V = [0, 5, 10, 15, 20] m/s`, `betaM = 0 rad`, and `gamma = 0 rad`.

This is a representative sampled screen only. It cannot exclude local branch changes or multiple trim solutions between sampled speeds.

Result: **FAIL**. All five individual trim points converged with acceptable residuals, finite real outputs, one single-start attempt per point, no rescue initial, and no trim-variable or applied-control limit contact/violation. The configured `0.25 deg` significant-sign-flip screen detected `cyclicLong` sign reversals over `5 -> 10 m/s` and `15 -> 20 m/s`.

The 7.5 m/s two-seed diagnosis subsequently showed that the 5--10 m/s interval's midpoint converges to the same numerical root from both endpoint seeds. The common midpoint root has negative `cyclicLong`. This strongly reduces evidence for midpoint seed dependence in that interval, while leaving the exact zero-crossing location and global branch uniqueness unresolved.

The 15--20 m/s interval remains unclassified and is the next authorized focused diagnosis. Draft PR #6 remains on hold.

No threshold, parameter, solver setting, initial seed, trim variable, objective, penalty, tolerance, or limit was changed to alter the representative result. No reverse sweep, multistart, rescue initial, residual Jacobian, or full linearization was used.

## Configuration

```matlab
opts.speeds = [0, 5, 10, 15, 20];
opts.betaM = 0;
opts.gamma = 0;
opts.initialDeg = [0, 18, 0];
opts.useContinuation = true;
opts.useTrimMultiStart = false;
opts.allowRescueInitials = false;
opts.failOnRescueInitial = true;
opts.computeResidualJacobian = false;
opts.computeLinearization = false;
```

The existing representative thresholds were retained:

- `maxDeltaThetaDeg = 10`
- `maxDeltaControlDeg = 10`
- `signFlipThresholdDeg = 0.25`

Reduced and full residual tolerances were both `5.0e-3` for this run.

## Execution estimate and actual cost

Before execution, the estimate was five high-level trim solves and about `563 * 5 / 3 = 938` objective evaluations, based on the earlier three-point count. Residual-Jacobian and full-linearization calls were estimated as zero. Expected runtime was 50--75 seconds.

Actual representative-screen results:

- elapsed command time: 41.8 seconds;
- high-level trim solves: 5;
- objective-function evaluations: 1025;
- residual-Jacobian calls: 0;
- full-linearization calls: 0.

## Per-point results

All angles are degrees. `limit = false` means no reported trim variable, commanded control, or applied control was at or beyond its configured limit.

| V (m/s) | theta | collective | cyclicLong | reduced residual norm | full residual norm | limit | initial source | objective evaluations |
|---:|---:|---:|---:|---:|---:|:---:|:---|---:|
| 0 | 0.000000 | 17.179977 | 0.000000 | 2.4053e-08 | 2.4053e-08 | false | continuation | 12 |
| 5 | -0.740415 | 17.044206 | -0.725358 | 7.8813e-10 | 7.8813e-10 | false | continuation | 227 |
| 10 | 4.211642 | 16.238261 | 2.287254 | 1.4186e-09 | 1.4186e-09 | false | continuation | 268 |
| 15 | 4.555587 | 15.593765 | 0.769241 | 1.5532e-09 | 1.5532e-09 | false | continuation | 243 |
| 20 | 3.1107 | 15.1684 | -1.3918 | 1.6094e-09 | 1.6094e-09 | false | continuation | 275 |

The initial seed at 0 m/s was `[0, 18, 0] deg`. For every later point, the test verified exact element-by-element equality between that point's recorded initial seed and the preceding successful point's solution. Each point had exactly one high-level attempt and one internal candidate.

## Adjacent changes

| Interval (m/s) | delta theta (deg) | delta collective (deg) | delta cyclicLong (deg) | jump | significant sign flip |
|:---:|---:|---:|---:|:---:|:---:|
| 0 -> 5 | -0.7404 | -0.1358 | -0.7254 | false | false |
| 5 -> 10 | 4.9521 | -0.8059 | 3.0126 | false | true |
| 10 -> 15 | 0.3439 | -0.6445 | -1.5180 | false | false |
| 15 -> 20 | -1.4449 | -0.4253 | -2.1610 | false | true |

The theta and control jump limits were not exceeded. The representative FAIL result comes from the significant-sign-flip criterion only.

## 7.5 m/s focused diagnosis

Two independent single-start trims at 7.5 m/s used the recorded 5 and 10 m/s endpoint solutions as seeds.

```text
low-seed result  = [0.097205105181, 16.809576878591, -0.169175072447] deg
high-seed result = [0.097205096202, 16.809576878806, -0.169175072991] deg
difference norm  = 8.998006127586e-09 deg
same-root tolerance = 1.0e-4 deg
```

Both seeds converged to the same numerical root. The common root has negative `cyclicLong`. The slipstream wing panels were inside the existing normal-flow blend interval with ratio `0.282863080` and blend weight `0.133065419`.

Focused diagnosis accounting:

- high-level trim solves: 2;
- objective evaluations: 448;
- direct post-trim EOM calls: 2;
- residual Jacobians: 0;
- full linearizations: 0;
- internal elapsed time: 13.9255 s;
- command wall time: 32 s.

Full evidence is stored in `docs/TRIM_MIDPOINT_7P5_DIAGNOSIS.md`.

## Optional diagnostic implementation

`trim_sweep_helicopter` now accepts validated options:

```text
computeResidualJacobian
computeLinearization
```

Both default to `true`, preserving existing caller behavior. When disabled, the corresponding routines are not called. Point reports distinguish `NOT_REQUESTED`, `COMPUTED`, and `FAILED`, and `sweepReport.allPassed` requires a diagnostic only when it was requested.

## Next diagnosis boundary

The next authorized calculation is limited to the 15--20 m/s event. At 17.5 m/s, run exactly two single-start trims using the highest-precision persisted 15 and 20 m/s solutions as independent seeds. Do not add further speed points, multistart, rescue, Jacobians, full linearizations, or zero-crossing searches.

## Change status

- production parameter values changed: no;
- trim variable set changed: no;
- solver, objective, penalties, tolerances, limits, or default seeds changed: no;
- existing default sweep diagnostic behavior changed: no;
- representative-screen result: FAIL;
- 5--10 m/s midpoint seed dependence: not observed at 7.5 m/s;
- 15--20 m/s midpoint classification: pending;
- Draft PR #6 merge status: HOLD.
