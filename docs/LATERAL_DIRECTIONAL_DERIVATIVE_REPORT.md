# Lateral/Directional Derivative Report Workflow

## Purpose

This workflow audits the current opt-in `lateralCyclic` input path by
computing representative lateral/directional derivative blocks. It is an
internal model consistency check only. It is not Berger, XV-15, or
flight-test validation.

## Active Inputs

The report runs with:

```matlab
P.control.enableLateralCyclic = true
```

The active flight-input order is:

```text
[collective diffCollective cyclicLong diffCyclic lateralCyclic aileron elevator rudder]
```

The default legacy 7-input behavior remains unchanged when the flag is false.

## Representative Conditions

The workflow evaluates finite representative operating points:

|condition|betaM|V|
|-|-:|-:|
|hover_like_beta0|0 deg|0 m/s|
|low_speed_helicopter|0 deg|20 m/s|
|conversion_mid|45 deg|45 m/s|
|airplane_forward|90 deg|100 m/s|

These points are used to audit derivative connectivity and sign behavior. They
are not certified trim points for stability conclusions.

## Reported Quantities

`A_lat` uses rows:

```text
[vdot pdot rdot]
```

and columns:

```text
[v p r phi psi]
```

`B_lat` uses rows:

```text
[vdot pdot rdot]
```

and columns:

```text
[diffCollective diffCyclic lateralCyclic aileron rudder]
```

The report also computes raw central-difference load derivatives:

```text
dFy/d(input), dMx/d(input), dMz/d(input)
```

Raw load derivatives come from `total_forces_moments`. EOM B-matrix
derivatives come from `linearize_numeric`. They are different quantities and
must not be interpreted interchangeably.

## Current Sign Conclusion

`lateralCyclic` is connected to the rotor blade-pitch cosine harmonic with
the default opt-in `rotDir` mapping:

```text
thetaBlade = collective + twist + theta1c*cos(psi) + theta1s*sin(psi)
theta1c = rotDir*lateralCyclic
```

In the current representative audit, `lateralCyclic` produces finite,
significant model-internal `Y/L/N` target response. Positive `lateralCyclic`
is defined internally as a command that tilts the left and right rotor disk
normals together toward `+eY`. The older diagnostic `current` mapping
(`theta1c = lateralCyclic`) cancels the intended lateral response because
left/right `beta1s` and `nDisk_y` responses are opposite for the
counter-rotating rotors.

This result freezes only the current model-internal convention. It does not
complete external sign validation against Berger, XV-15, or a documented rotor
azimuth convention.

## Why lateralCyclic signs vary with betaM

The default opt-in `rotDir` mapping makes `lateralCyclic` produce significant
model-internal `Y/L/N` response, but the representative signs need not be the
same at every nacelle angle. In the current generated reports, `B_vdot` and
raw `dFy` are positive in betaM = 0 hover/low-speed conditions and can become
negative in betaM = 45/90 deg conversion or airplane-mode conditions.

That sign variation is not automatically a bug. The nacelle angle changes the
rotor thrust axis `eT`, the disk-plane `eD/eY` projections into body axes,
proprotor inflow state, flapping response, moment arms, and aerodynamic
coupling. The B-matrix entries are EOM state-derivative sensitivities, while
raw load derivatives are central differences of `[F; M]`; they are related
diagnostics but not interchangeable quantities. These representative points
are not a broad trim sweep.

The conclusion is therefore limited: `theta1c = rotDir*lateralCyclic` resolves
the current left/right cancellation and is internally effective in this model.
It is not Berger/XV-15 validation and does not complete lateral/directional
handling-quality validation.

## Limitations

- This is not external literature validation.
- This does not mean lateral/directional handling qualities are validated.
- This does not complete external lateral cyclic sign validation.
- This is not a Berger 51-state reproduction.
- This does not implement 13x10.
- This does not implement nacelle torque.
- The representative states are not a broad trim sweep.

## Next Step

The internally effective `rotDir` mapping can inform a later, separate
Berger-inspired 13x10 research design. That later work must still review
`lateralCyclic`, `rotDir`, and `psi` conventions against an external rotor
azimuth reference before claiming sign validation.
