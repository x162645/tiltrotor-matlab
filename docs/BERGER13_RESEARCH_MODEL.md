# Berger-Inspired 13x10 Research Model

## Purpose

This is an isolated Berger-inspired 13-state / 10-input research scaffold for
future nacelle dynamics, lateral/directional, and control-allocation studies.
It is intentionally separate from the legacy main model and GUI default path.

## Non-Goals

- Not a Berger 51-state reproduction.
- Not an XV-15 high-fidelity model.
- Not externally validated against Berger, XV-15, or flight-test data.
- Not the GUI default model.
- Not a replacement for the legacy main model.

## States

```text
u v w p q r phi theta psi betaML betaMR betaMLdot betaMRdot
```

The first nine states are the existing rigid-body states. `betaML` and
`betaMR` are left/right nacelle angles in rad. `betaMLdot` and `betaMRdot` are
left/right nacelle rates in rad/s.

## Inputs

```text
collective diffCollective cyclicLong diffCyclic lateralCyclic
aileron elevator rudder nacelleTorqueLeft nacelleTorqueRight
```

The first eight inputs use the opt-in flight-input order. The last two inputs
are research placeholder generalized nacelle torques in N*m.

## Nacelle Dynamics

The initial nacelle dynamics are deliberately simple:

```text
betaML_dot = betaMLdot
betaMR_dot = betaMRdot
betaMLddot = sat(QnacL)/I - D/I*betaMLdot
betaMRddot = sat(QnacR)/I - D/I*betaMRdot
```

Angle and rate guards keep the initial scaffold finite at limits. Parameters
in `params_berger13` are `RESEARCH_PLACEHOLDER` values chosen for numerical
stability and interface development, not aircraft data.

## Force And Moment Reuse

`total_forces_moments_13x10` reuses the existing component stack with the
first eight controls and `betaMAvg = 0.5*(betaML + betaMR)`. Therefore a
symmetric condition with `betaML = betaMR`, zero nacelle rates, and zero
nacelle torques matches the legacy opt-in 9-state EOM for the first nine
derivatives.

Asymmetric left/right nacelle aerodynamic and rotor-load effects are not yet
implemented. When `betaML ~= betaMR`, the scaffold reports a diagnostic warning
that the force/moment loads use the average-angle research approximation.

## Test Coverage

- `check_berger13_interface` verifies labels, parameters, finite EOM output,
  nacelle torque signs, angle guards, and legacy default isolation.
- `check_berger13_linearization` verifies 13x13 / 13x10 finite linearization,
  nacelle torque columns, nonzero `lateralCyclic` column, and symmetric
  equivalence with the legacy opt-in EOM.
- `run_berger13_smoke` runs a lightweight EOM and linearization smoke check.

## Future Work

- Independent left/right nacelle aerodynamics and rotor-load modeling.
- Explicit nacelle actuator and torque-source modeling.
- Nonlinear doublet response workflows.
- Berger/XV-15 derivative comparison after source definitions are audited.
- Optional GUI research-tab integration, not default-path integration.
