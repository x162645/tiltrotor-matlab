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

`lateralCyclic` is connected to the rotor blade-pitch cosine harmonic:

```text
thetaBlade = collective + twist + theta1c*cos(psi) + theta1s*sin(psi)
theta1c = lateralCyclic
```

In the current representative audit, `lateralCyclic` produces a finite,
nonzero full B column, but its `Y/L/N` target entries are small. Therefore the
workflow does not freeze an external lateral/directional sign convention.
Future work should review the rotor azimuth, `rotDir`, and disk-response
conventions before using this as a sign-validated lateral-control model.

## Limitations

- This is not external literature validation.
- This does not mean lateral/directional handling qualities are validated.
- This is not a Berger 51-state reproduction.
- This does not implement 13x10.
- This does not implement nacelle torque.
- The representative states are not a broad trim sweep.

## Next Step

If future audits produce clear, consistent `lateralCyclic` signs across
representative hover and low-speed conditions, the result can inform a separate
Berger-inspired 13x10 research design. If the signs remain small or ambiguous,
review `lateralCyclic`, `rotDir`, and `psi` conventions before extending the
control architecture.
