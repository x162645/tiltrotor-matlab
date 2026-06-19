# 7.5 m/s Helicopter-Mode Trim Midpoint Diagnosis

## Scope and conclusion

This focused diagnostic examined only the previously flagged `5 -> 10 m/s`
interval. Exactly two independent single-start trims were run at `V = 7.5
m/s`, `betaM = 0 rad`, and `gamma = 0 rad`. No rescue, multistart, additional
speed, residual Jacobian, or full linearization was used.

Conclusion: **same midpoint numerical root from both seeds**. The Euclidean
difference between the two final `[theta, collective, cyclicLong]` vectors was
`8.998006127586e-09 deg`, below the declared `1.0e-4 deg` numerical-root
tolerance. The common root has negative longitudinal cyclic,
`cyclicLong approximately -0.169175073 deg`.

This result does not locate the later zero crossing and does not establish
branch uniqueness between 7.5 and 10 m/s.

## Seed provenance and settings

The repository does not contain a MAT file or log with more endpoint digits.
The following values are copied exactly from the highest-precision values
persisted in `docs/REPRESENTATIVE_TRIM_CONTINUATION.md`; no endpoint trim was
rerun and no further rounding was applied:

| Seed | theta (deg) | collective (deg) | cyclicLong (deg) |
|---|---:|---:|---:|
| Recorded 5 m/s solution | -0.740415000000 | 17.044206000000 | -0.725358000000 |
| Recorded 10 m/s solution | 4.211642000000 | 16.238261000000 | 2.287254000000 |

Common solver settings were:

```matlab
opts.gamma = 0;
opts.useMultiStart = false;
opts.alwaysMultiStart = false;
```

For both solves, the actual candidate initial vector exactly matched the
requested vector above. Each solve created one candidate. Rescue behavior is
not part of `trim_symmetric` and was not used.

## Trim results

| Quantity | Low-side 5 m/s seed | High-side 10 m/s seed |
|---|---:|---:|
| final theta (deg) | 0.097205105181 | 0.097205096202 |
| final collective (deg) | 16.809576878591 | 16.809576878806 |
| final cyclicLong (deg) | -0.169175072447 | -0.169175072991 |
| exitflag | 1 | 1 |
| reduced residual norm | 5.098655815040e-10 | 1.539954599739e-09 |
| full residual norm | 5.098655815040e-10 | 1.539954599739e-09 |
| objective cost | 8.602330868026e-21 | 2.763573868431e-20 |
| objective evaluations | 199 | 249 |
| candidates | 1 | 1 |
| trim variable at limit | false | false |
| within trim limits | true | true |
| applied control at/beyond limit | false | false |
| finite real result | true | true |

The diagnostic report retains the full reduced and nine-state full-residual
vectors in `r.solves(k).reducedResidual` and `r.solves(k).fullResidual`.

Applied controls `[collective, diffCollective, cyclicLong, diffCyclic,
aileron, elevator, rudder]` in degrees were:

- low-side seed: `[16.809576878591, 0, -0.169175072447, 0, 0, 0, 0]`;
- high-side seed: `[16.809576878806, 0, -0.169175072991, 0, 0, 0, 0]`.

## Root comparison

The raw component difference is defined as high-side result minus low-side
result:

```text
delta [theta, collective, cyclicLong]
= [-8.979e-09, +2.142e-10, -5.446e-10] deg
```

The three-dimensional Euclidean difference is
`8.998006127586e-09 deg`.

The predeclared same-root tolerance was `1.0e-4 deg` on the Euclidean
difference. This sub-millidegree threshold is far below the representative
screen's `0.25 deg` sign threshold while allowing for solver termination
noise. The observed difference is more than four orders of magnitude below
that tolerance.

## Wing normal-flow blend diagnosis

The current conceptual blend uses center `0.35` and half-width `0.15`, so its
active ratio interval is `(0.20, 0.50)`. A region was called "near" the blend
only when outside the interval but no farther than 10% of the half-width
(`0.015`) from an edge. This is a reporting classification, not a model or
acceptance threshold.

Both midpoint solutions produced the same diagnostics to the displayed
precision:

| Region | alpha (deg) | normal-flow ratio | blend weight | wake velocity (m/s) | In blend |
|---|---:|---:|---:|---:|:---:|
| Left free stream | 0.097205 | 0.999998561 | 1.000000000 | 0 | no |
| Left slipstream | -73.568843 | 0.282863080 | 0.133065419 | 25.444434343 | **yes** |
| Right free stream | 0.097205 | 0.999998561 | 1.000000000 | 0 | no |
| Right slipstream | -73.568843 | 0.282863080 | 0.133065419 | 25.444434343 | **yes** |

Thus both solutions are in, not merely near, the normal-flow blend region in
their left and right slipstream wing panels. The free-stream panels are on the
lift-line side with unit blend weight.

Per-region blended loads for either solution, in body axes, were:

| Region | F (N) | M (N m) |
|---|---|---|
| Left free | `[-4.579307, 0, -27.75420]` | `[47.18215, -8.322793, -7.784822]` |
| Left slip | `[-151.5218, 0, 1661.673]` | `[-6646.693, 176.4718, -606.0873]` |
| Right free | `[-4.579307, 0, -27.75420]` | `[-47.18215, -8.322793, 7.784822]` |
| Right slip | `[-151.5218, 0, 1661.673]` | `[6646.693, 176.4718, 606.0873]` |

The diagnostic structure additionally preserves, without extra EOM calls:

- each wing region's `FNear`, `FLiftLine`, `MNear`, `MLiftLine`, aerodynamic
  moment, arm moment, local velocity, local sideslip, blend margin, and branch
  flags;
- left/right rotor induced velocity, induced-velocity residual, iteration
  count, convergence flag, hub velocity, advance ratios, wake/thrust axes,
  thrust, torque, force, total moment, arm moment, reaction moment, and gyro
  moment;
- force and moment vectors for every component in
  `r.solves(k).components`.

The slipstream `wakeVelocity` above is the existing wing input derived from
the corresponding rotor wake data. No new wake model or diagnostic model was
introduced.

## Execution accounting

- high-level trim solves: 2;
- objective evaluations: 448 total (`199 + 249`);
- direct post-trim EOM calls: 2, exactly one per final solution;
- residual-Jacobian calls: 0;
- full-linearization calls: 0;
- internal diagnostic elapsed time: 13.9255 seconds;
- observed command wall time: 32 seconds;
- `executionCompleted`: true.

The test body completed and the requested assertion passed. MATLAB R2021a
then emitted the known shutdown-stage `output stream error`, which caused a
nonzero process exit after the successful test body. It is recorded separately
from the diagnostic conclusion.

## Change status and next step

No production model, parameter, solver, objective, penalty, tolerance, limit,
default seed, or valid-input behavior was changed.

Recommended next step, requiring separate authorization: first persist
higher-precision endpoint seeds, then perform the smallest reviewed diagnostic
inside only the `7.5 -> 10 m/s` interval to locate whether the observed
`cyclicLong` sign change is a sampled continuous zero crossing. Do not infer a
bifurcation, hysteresis, or unique branch from the present evidence.
