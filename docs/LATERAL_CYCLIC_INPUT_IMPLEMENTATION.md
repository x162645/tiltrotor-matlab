# Opt-in Symmetric Lateral Cyclic Input

This change adds an opt-in 8-flight-input mode for symmetric lateral cyclic.
The default legacy control vector remains unchanged:

```text
[collective diffCollective cyclicLong diffCyclic aileron elevator rudder]
```

When `P.control.enableLateralCyclic = true`, the active order becomes:

```text
[collective diffCollective cyclicLong diffCyclic lateralCyclic aileron elevator rudder]
```

`map_control_inputs` is the single point that maps the active vector to named
fields. In legacy mode it requires 7 inputs and sets `lateralCyclic = 0`. In
opt-in mode it requires 8 inputs and shifts the fixed surfaces to positions
6, 7, and 8.

## Rotor Mapping

The existing `diffCyclic` path remains differential longitudinal cyclic:

```text
right cyclicLong = cyclicLong + diffCyclic
left  cyclicLong = cyclicLong - diffCyclic
```

The new `lateralCyclic` command is symmetric at the aircraft control-vector
level. With the default opt-in mapping, `rotor_model_bemt` weights the command
by local rotor direction before applying it to the first-harmonic blade-pitch
cosine term:

```text
thetaBlade = collective + twist + theta1c*cos(psi) + theta1s*sin(psi)
theta1c = rotDir*lateralCyclic
theta1s = -rotDir*cyclicLong
```

In the current model-internal convention, positive `lateralCyclic` means the
left and right rotor disk normals tilt together toward `+eY`. The earlier
`theta1c = lateralCyclic` candidate remains available as the diagnostic
`current` mapping, but it drives opposite left/right `beta1s` and `nDisk_y`
responses for counter-rotating rotors, which cancels the intended lateral
response. The `minusRotDir` diagnostic option is also retained for sign
comparison.

This sign convention is local to the current rotor azimuth and flapping model.
It does not introduce a new lateral flapping-dynamics model and is not an
external Berger/XV-15 validation.

## Compatibility

- Default `P.control.enableLateralCyclic = false` keeps the legacy 7-input
  behavior.
- Linearization uses 7 columns by default and 8 columns only when the flag is
  enabled.
- Control labels and units are provided by `get_control_input_names` and
  `get_control_input_units`.
- GUI/service labels follow the active input count, but the GUI does not yet
  provide a dedicated user-facing toggle for enabling the 8-input mode.

## Non-goals

- No 13-state / 10-input implementation.
- No Berger 51-state reproduction.
- No nacelle torque implementation.
- No left/right independent nacelle dynamic states.
- No change to legacy default behavior.
- No claim of completed lateral/directional validation.

## Known Limitations

- The lateral cyclic sign convention is now internally effective for the
  current model, but still needs future validation against a documented rotor
  azimuth and disk-response convention.
- The new input is connected through the current conceptual BEMT/flapping
  path only; it is not a high-fidelity rotor model.
- Lateral/directional derivatives are checked for finite, nonzero response in
  a focused test, not validated numerically against reference data.
