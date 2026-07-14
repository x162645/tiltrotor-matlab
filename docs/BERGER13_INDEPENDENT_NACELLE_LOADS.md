# Berger13 Independent Nacelle Rotor Loads

## Scope

This stage updates only the isolated berger13 research path. The legacy main
model, GUI default path, and `params_nominal` default behavior are unchanged.

## Design

`total_forces_moments_13x10` still evaluates the legacy component stack at:

```text
betaMAvg = 0.5*(betaML + betaMR)
```

That average-angle result remains the baseline for mass properties and
non-rotor aerodynamic components. The 13x10 path then computes a rotor-only
delta:

```text
F = Favg - FleftAvg - FrightAvg + Fleft(betaML) + Fright(betaMR)
M = Mavg - MleftAvg - MrightAvg + Mleft(betaML) + Mright(betaMR)
```

The helper `compute_berger13_rotor_loads` reuses the legacy
`rotor_model_bemt` side interface and the average-angle mass-property reference
point. It does not change the legacy `total_forces_moments` external interface.

## Implemented

- Left rotor loads use `betaML`.
- Right rotor loads use `betaMR`.
- Symmetric `betaML = betaMR` cases reduce to the legacy opt-in 9-state EOM for
  the first nine derivatives.
- Nacelle torque inputs still affect the nacelle acceleration states.
- Diagnostics expose `rotorLeft.betaMUsed`, `rotorRight.betaMUsed`, and each
  rotor delta from the average-angle baseline.

## Still Approximate

- Wing, fuselage, horizontal-tail, and vertical-tail loads still use
  `betaMAvg`.
- Mass properties and inertia still use `betaMAvg`.
- The nacelle actuator model remains a research placeholder.
- This is not a Berger 51-state reproduction.
- This is not XV-15 validation.
- No nonlinear doublet workflow or handling-quality conclusion is included.
- No GUI default-path integration is included.

## Validation

The focused validation checks are:

- `check_berger13_interface`
- `check_berger13_linearization`
- `run_berger13_smoke`
- `report_independent_nacelle_loads`

The report script writes small Markdown and CSV artifacts under:

```text
validation/berger13_independent_nacelle_loads/<timestamp>/
```

The report records symmetric equivalence, asymmetric force/moment deltas from
the old average-only result, and 13x13 / 13x10 linearization column checks.

## Next Step

The next modeling step should audit whether independent left/right non-rotor
aero and mass-property effects are needed before using the 13x10 scaffold for
asymmetric nacelle maneuver studies.
