# 17.5 m/s Helicopter-Mode Trim Midpoint Diagnosis

## Scope and conclusion

This diagnostic examined only the representative `15 -> 20 m/s` sign-flip
interval. Exactly two independent single-start trims were run at `V = 17.5
m/s`, `betaM = 0 rad`, and `gamma = 0 rad`.

Conclusion: **same 17.5 m/s numerical root from both seeds**. The Euclidean
difference between the two final `[theta, collective, cyclicLong]` vectors was
`8.626264725850e-09 deg`, below the retained `1.0e-4 deg` same-root tolerance.
The common solution has negative `cyclicLong`, approximately
`-0.416693329 deg`.

No extra speed, rescue, multistart, reverse sweep, residual Jacobian, or full
linearization was used. This result does not locate the zero crossing or prove
global branch uniqueness.

## Seeds and solver settings

The requested seeds used the highest precision persisted in repository
evidence. The 15 m/s seed has six decimal places and the 20 m/s seed has four;
the endpoints were not rerun to obtain more digits.

| Seed | theta (deg) | collective (deg) | cyclicLong (deg) |
|---|---:|---:|---:|
| Recorded 15 m/s solution | 4.555587000000 | 15.593765000000 | 0.769241000000 |
| Recorded 20 m/s solution | 3.110700000000 | 15.168400000000 | -1.391800000000 |

For each solve the actual candidate initial vector exactly matched its
requested seed. Common settings were `useMultiStart = false` and
`alwaysMultiStart = false`; rescue was not used. Each solve produced exactly
one candidate.

## Trim results

| Quantity | Low-side 15 m/s seed | High-side 20 m/s seed |
|---|---:|---:|
| final theta (deg) | 3.774686179733 | 3.774686185574 |
| final collective (deg) | 15.368703848185 | 15.368703844841 |
| final cyclicLong (deg) | -0.416693326063 | -0.416693331459 |
| exitflag | 1 | 1 |
| reduced residual norm | 1.674550306910e-09 | 1.099921953937e-09 |
| full residual norm | 1.674550306910e-09 | 1.099921953938e-09 |
| objective cost | 4.349519868367e-20 | 2.915856989167e-20 |
| objective evaluations | 267 | 212 |
| candidates | 1 | 1 |
| trim variable at limit | false | false |
| within trim limits | true | true |
| applied control at/beyond limit | false | false |
| multistart / rescue | false / false | false / false |

The full reduced- and full-residual vectors are retained in
`r.solves(k).reducedResidual` and `r.solves(k).fullResidual`.

Applied controls `[collective, diffCollective, cyclicLong, diffCyclic,
aileron, elevator, rudder]` in degrees were:

- low-side seed: `[15.368703848185, 0, -0.416693326063, 0, 0, 0, 0]`;
- high-side seed: `[15.368703844841, 0, -0.416693331459, 0, 0, 0, 0]`.

## Root comparison

High-side result minus low-side result was:

```text
[+5.8409e-09, -3.3430e-09, -5.3963e-09] deg
```

The Euclidean difference was `8.626264725850e-09 deg`. The `1.0e-4 deg`
same-root tolerance was retained unchanged from the 7.5 m/s diagnosis. The
observed difference is more than four orders of magnitude below that
tolerance.

## Wing branch and blend diagnosis

The model's active normal-flow blend ratio interval is `(0.20, 0.50)`, from
center `0.35` and half-width `0.15`. The diagnostic's reporting-only "near"
band extends `0.015` beyond either edge.

Both final solutions produced the same branch diagnostics to displayed
precision:

| Region | alpha (deg) | normal-flow ratio | blend weight | wake velocity (m/s) | Branch state |
|---|---:|---:|---:|---:|---|
| Left free stream | 3.774686 | 0.997830651 | 1.000000000 | 0 | lift-line, outside blend |
| Left slipstream | -48.372081 | 0.664290521 | 1.000000000 | 20.800750583 | lift-line, outside blend |
| Right free stream | 3.774686 | 0.997830651 | 1.000000000 | 0 | lift-line, outside blend |
| Right slipstream | -48.372081 | 0.664290521 | 1.000000000 | 20.800750583 | lift-line, outside blend |

No wing region was in or near the normal-flow blend interval.

Per-region force and moment evidence for the low-side solution was:

| Region | F (N) | M (N m) |
|---|---|---|
| Left free | `[-5.929062, 0, -465.2446]` | `[790.9158, -87.76296, -10.07941]` |
| Left slip | `[1579.355, 0, 1702.411]` | `[-6809.644, 920.4960, 6317.420]` |
| Right free | `[-5.929062, 0, -465.2446]` | `[-790.9158, -87.76296, 10.07941]` |
| Right slip | `[1579.355, 0, 1702.411]` | `[6809.644, 920.4960, -6317.420]` |

The high-side-seed result matched these values at the displayed precision.

## Rotor wake evidence

The left and right rotors were symmetric for each solution.

| Quantity | Low-side-seed solution | High-side-seed solution |
|---|---:|---:|
| induced velocity (m/s) | 13.000469114504 | 13.000469112643 |
| induced-velocity error | 1.559e-05 | 1.559e-05 |
| coupled iterations | 6 | 6 |
| coupled converged | true | true |
| thrust per rotor (N) | 30490.875803865 | 30490.875796407 |
| torque per rotor (N m) | 8068.679576704 | 8068.679573122 |
| axial hub velocity (m/s) | -1.152078476 | -1.152078478 |
| longitudinal hub velocity (m/s) | 17.462036399 | 17.462036398 |
| `muLong` | 0.074117302 | 0.074117302 |

The wing slipstream wake velocity is the existing
`P.rotor.wakeFactor * inducedVelocity` quantity. No new wake model was added.

## Execution accounting

- high-level trim solves: 2;
- objective evaluations: 479 total (`267 + 212`);
- direct post-trim EOM calls: 2;
- residual-Jacobian calls: 0;
- full-linearization calls: 0;
- internal diagnostic elapsed time: 20.9736 seconds;
- observed command wall time: 38 seconds;
- `executionCompleted`: true.

The diagnostic body completed and its requested assertion passed. MATLAB
R2021a subsequently emitted the known shutdown-stage `output stream error`,
causing a nonzero process exit after evidence capture.

## Change status and next step

No production model, parameter, threshold, solver, objective, penalty,
tolerance, limit, default seed, or valid-input behavior changed.

Recommended next step, requiring separate authorization: review both midpoint
same-root findings together and decide whether a narrowly bounded zero-crossing
location task is warranted. Do not infer bifurcation, hysteresis, physical
discontinuity, or global uniqueness from the two midpoint checks.
