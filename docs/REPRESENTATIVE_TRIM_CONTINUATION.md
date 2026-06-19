# Representative Helicopter-Mode Trim Continuation Screen

## Scope and conclusion

This audit ran the prescribed five-point helicopter-mode continuation screen
at `V = [0, 5, 10, 15, 20] m/s`, `betaM = 0 rad`, and `gamma = 0 rad`.
It is a representative sampled screen only. It cannot exclude local branch
changes or multiple trim solutions between sampled speeds.

Result: **FAIL**. All five individual trim points converged with acceptable
residuals, finite real outputs, one single-start attempt per point, no rescue
initial, and no trim-variable or applied-control limit contact/violation.
However, the configured `0.25 deg` significant-sign-flip screen detected
`cyclicLong` sign reversals over `5 -> 10 m/s` and `15 -> 20 m/s`.

No threshold, parameter, solver setting, initial seed, trim variable,
objective, penalty, tolerance, or limit was changed to alter this result. No
intermediate speeds, reverse sweep, multistart, rescue initial, residual
Jacobian, or full linearization were used.

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

Before execution, the estimate was five high-level trim solves and about
`563 * 5 / 3 = 938` objective evaluations, based on the earlier three-point
count. Residual-Jacobian and full-linearization calls were estimated as zero.
Expected runtime was 50--75 seconds.

Actual results:

- elapsed command time: 41.8 seconds;
- high-level trim solves: 5;
- objective-function evaluations: 1025;
- residual-Jacobian calls: 0;
- full-linearization calls: 0.

## Per-point results

All angles are degrees. `limit = false` means no reported trim variable,
commanded control, or applied control was at or beyond its configured limit.

| V (m/s) | theta | collective | cyclicLong | reduced residual norm | full residual norm | limit | initial source | objective evaluations |
|---:|---:|---:|---:|---:|---:|:---:|:---|---:|
| 0 | 0.000000 | 17.179977 | 0.000000 | 2.4053e-08 | 2.4053e-08 | false | continuation | 12 |
| 5 | -0.740415 | 17.044206 | -0.725358 | 7.8813e-10 | 7.8813e-10 | false | continuation | 227 |
| 10 | 4.211642 | 16.238261 | 2.287254 | 1.4186e-09 | 1.4186e-09 | false | continuation | 268 |
| 15 | 4.555587 | 15.593765 | 0.769241 | 1.5532e-09 | 1.5532e-09 | false | continuation | 243 |
| 20 | 3.1107 | 15.1684 | -1.3918 | 1.6094e-09 | 1.6094e-09 | false | continuation | 275 |

The initial seed at 0 m/s was `[0, 18, 0] deg`. For every later point, the
test verified exact element-by-element equality between that point's recorded
initial seed and the preceding successful point's solution. Each point had
exactly one high-level attempt and one internal candidate.

## Adjacent changes

| Interval (m/s) | delta theta (deg) | delta collective (deg) | delta cyclicLong (deg) | jump | significant sign flip |
|:---:|---:|---:|---:|:---:|:---:|
| 0 -> 5 | -0.7404 | -0.1358 | -0.7254 | false | false |
| 5 -> 10 | 4.9521 | -0.8059 | 3.0126 | false | **true** |
| 10 -> 15 | 0.3439 | -0.6445 | -1.5180 | false | false |
| 15 -> 20 | -1.4449 | -0.4253 | -2.1610 | false | **true** |

No configured magnitude jump was detected. The two significant sign flips are
the retained failure evidence; the screen therefore does not support a PASS
continuity conclusion.

## Optional-diagnostic behavior

`trim_sweep_helicopter` now validates `computeResidualJacobian` and
`computeLinearization`. Both default to `true`, accept logical scalars or
numeric scalar `0/1`, and use stable invalid-option identifiers. Each point
reports `requested`, `computed`, and one of `NOT_REQUESTED`, `COMPUTED`, or
`FAILED`. A requested diagnostic that was not computed is not represented as
skipped. `allPassed` evaluates only requested diagnostics.

For this screen both diagnostics were explicitly disabled. Every point
reported `NOT_REQUESTED`, and the lightweight counters proved zero calls to
both expensive functions.

## MATLAB result and shutdown message

The prescribed MATLAB R2021a command was run once. The test body returned
`allPassed = 0`, and the outer assertion failed because of the two significant
sign-flip findings. During shutdown MATLAB also emitted the known
`mwboost::archive::archive_exception: output stream error`. That shutdown-stage
message is recorded separately and does not change the test-body FAIL result.

## Model status

No physical parameter was modified. Valid-input trim equations and solver
behavior were not changed; only optional execution/reporting of the existing
expensive diagnostics was added. This result is an internal consistency audit
of the current conceptual model, not XV-15 validation.
