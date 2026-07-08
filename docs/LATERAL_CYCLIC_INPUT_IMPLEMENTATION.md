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

The new `lateralCyclic` command is symmetric. Both rotors receive the same
side command, and `rotor_model_bemt` maps it directly to the first-harmonic
blade-pitch cosine term:

```text
thetaBlade = collective + twist + theta1c*cos(psi) + theta1s*sin(psi)
theta1c = lateralCyclic
theta1s = -rotDir*cyclicLong
```

The sign convention is intentionally minimal and local to the current rotor
azimuth definition. It does not introduce a new lateral flapping-dynamics
model.

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

- The lateral cyclic sign convention still needs future validation against a
  documented rotor azimuth and disk-response convention.
- The new input is connected through the current conceptual BEMT/flapping
  path only; it is not a high-fidelity rotor model.
- Lateral/directional derivatives are checked for finite, nonzero response in
  a focused test, not validated numerically against reference data.
