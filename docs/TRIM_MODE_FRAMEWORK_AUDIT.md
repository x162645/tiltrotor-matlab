# General Mode Trim Framework Audit

## Scope and architecture

This change adds an analysis-layer longitudinal trim core without modifying the
plant, physical parameters, control limits, solver tolerances, GUI, services,
linearization, induced flow, or continuous control allocation. The existing
`trim_symmetric` solver remains the legacy numerical implementation. A
`legacy_symmetric` definition delegates to that unchanged path, which preserves
its exact-hover collective-only search, dimensionless forward search,
multistart ordering, and acceptance behavior.

`trim_general` validates an explicit definition, maps named values into the
full state vector

```text
[u v w p q r phi theta psi]
```

and full control vector

```text
[collective diffCollective cyclicLong diffCyclic aileron elevator rudder]
```

then calls `tiltrotor_eom`. For prescribed airspeed and flight-path angle,
`alpha = theta - gamma`, `u = V cos(alpha)`, and `w = V sin(alpha)`.

## Definitions

| Definition | Unknowns | Residuals | Required fixed longitudinal control |
|---|---|---|---|
| `legacy_symmetric` | `theta`, `collective`, `cyclicLong` | `udot`, `wdot`, `qdot` | `elevator=0` |
| `helicopter_longitudinal` | `theta`, `collective`, `cyclicLong` | `udot`, `wdot`, `qdot` | `elevator=0` |
| `airplane_longitudinal` | `theta`, `collective`, `elevator` | `udot`, `wdot`, `qdot` | `cyclicLong=0` |

All differential and lateral controls are fixed to zero in these first
definitions. The airplane variable scale `[2, 18, 2] deg` is classified as
`NUMERICAL`; it is not a physical parameter or control limit.

A conversion definition with `theta`, `collective`, `cyclicLong`, and
`elevator` but only three equilibrium residuals is rejected with
`trim_general:AllocationConstraintRequired`. No mixer, betaM threshold, hidden
residual weight, or allocation law is inferred.

## Validation evidence

Stage 0 before editing:

- hover residual norm: `2.4052561154045785e-08`;
- `V=20 m/s`, `betaM=0` residual norm: `3.7214595860198644e-10`;
- existing `run_all_checks`: all passed.

Focused validation after implementation:

- legacy hover worst state/control/residual-norm differences: `0 / 0 / 0`;
- legacy 20 m/s worst state/control/residual-norm differences: `0 / 0 / 0`;
- helicopter endpoint residual norm: `3.7214595860198644e-10`;
- airplane endpoint residual norm: `1.7024981950932638e-09`;
- intended fixed controls were exactly zero and neither endpoint had an active
  or violated limit.

These checks establish internal numerical consistency for the covered
conditions. They do not constitute XV-15 parameter or flight-test validation.

MATLAB R2021a completed every listed assertion before its known shutdown-time
`mwboost::archive::archive_exception` output-stream error. The shutdown issue is
recorded separately from the passing test bodies.
