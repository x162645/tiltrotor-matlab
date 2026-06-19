# Control Conventions

This document records the current code-level control definitions. All control
angles are in rad. This is an internal modeling convention, not an XV-15
validation statement.

## Control Vector

The public control architecture remains:

```text
collective / diffCollective / cyclicLong / diffCyclic
```

`diffCyclic` is the historical code name. Documentation should call it
`differentialLongitudinalCyclic`. It is not a public lateral cyclic channel,
and no public `cyclicLat` input is added.

## Body And Rotor Axes

- Body axes: `x` forward, `y` right, `z` down.
- Left rotor: `side = -1`; right rotor: `side = +1`.
- Rotor rotation direction in the flapping model: `rotDir = side`.
- `betaM = 0` is helicopter mode; `betaM = pi/2` is airplane mode.
- For `betaM = 0`, `eT=[0;0;-1]`, `eD=[1;0;0]`, `eY=[0;1;0]`.
- `psi=0` is the blade radial direction `+eD`.

## External Allocation

`model/total_forces_moments.m` allocates the public controls to each side:

```matlab
cyclicSideRight = cyclicLong + diffCyclic;
cyclicSideLeft  = cyclicLong - diffCyclic;
```

The rotor function receives only the side-specific `cyclicLong` command. It
must not add public `cyclicLong` or `diffCyclic` again.

## Blade Pitch Phase

The formal steady first-harmonic flapping path maps the side-specific
longitudinal cyclic command to sine-phase blade pitch:

```matlab
theta1cSide = 0;
theta1sSide = -rotDir*cyclicSide;
thetaBlade = collectiveSide + twist + theta1sSide*sin(psi);
```

The old `cyclicSide*cos(psi)` formal channel is retired. This phase convention
matches the current `psi`, `rotDir`, and `betaDot` definitions.

## Positive Direction

With the current disk-normal definition

```matlab
nDisk = normalize(eT - beta1c*eD - beta1s*eY);
```

positive common `cyclicLong` is defined to produce:

- left and right `beta1c < 0`;
- both disk normals tilted toward `+eD`;
- positive body-axis longitudinal force increment in helicopter mode;
- lateral force cancellation between the two rotors.

Positive `diffCyclic` is defined by the existing public allocation:

```text
right cyclicSide positive, left cyclicSide negative
```

Under the current `theta1s=-rotDir*cyclicSide` mapping, this produces opposite
left/right longitudinal disk tilt and a negative yaw-moment increment in the
current body-axis moment convention. The small lateral force and roll moment
from residual in-plane forces are diagnostics, not the primary intended
effect.

## Inflow Status

The formal flapping/BEMT path currently uses uniform induced velocity:

```matlab
viField = vi;
```

The legacy `P.rotor.inflowHarmonic` field is deprecated and is not read by the
formal path. A non-uniform inflow model is still missing. Future work must
introduce a model that depends on advance ratio or wake skew and tends to zero
in axisymmetric hover.

## Tests

The current control and flapping checks are:

```matlab
flapReport = check_flapping_model;
controlReport = check_control_architecture;
summary = run_all_checks;
```

These tests check internal consistency only. They do not prove agreement with
NUAA data or XV-15 flight/test data.
