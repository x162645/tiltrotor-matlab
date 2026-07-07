# Nacelle Dynamic Validation

This document defines the Phase 1 validation workflow for the opt-in
symmetric nacelle dynamic-state extension.

## Scope

The default model remains the legacy 9-state path:

```matlab
P.nacelleDynamics.enabled = false;
```

When the extension is explicitly enabled, the nonlinear state is:

```text
x = [u v w p q r phi theta psi betaM betaM_dot]
```

The project convention is:

```text
betaM = 0 deg  -> helicopter mode
betaM = 90 deg -> airplane mode
```

The current validation criteria are not a Berger 51-state reproduction. Berger
2019 is used only as background for the idea that nacelle angle and nacelle
angular rate can be states. Phase 1 uses only a symmetric 2-state nacelle
extension and keeps the existing quasi-static force, mass, CG, inertia, rotor,
and wing-slipstream paths.

The 8 deg/s value is used as the default nacelle-rate scale reference. Internal
angle calculations use radians; degree-valued parameters are converted at the
parameter/model boundary.

## Reproducible Workflow

Run the full validation workflow from the project root:

```matlab
run('startup.m');
result = run_nacelle_dynamics_validation();
```

The workflow writes outputs to:

```text
validation/nacelle_dynamics/<timestamp>/
```

The generated run directory contains:

- `NACELLE_DYNAMIC_VALIDATION_REPORT.md`
- `actuator_response.csv`
- `dynamic_response_demo.csv`
- `nacelle_dynamics_validation.mat`
- `actuator_response.png`
- `dynamic_response_demo.png`

The lightweight automated check is:

```matlab
report = check_nacelle_dynamics_validation();
```

This check runs a reduced set of cases and does not generate the full plot set.

## Validation Items

The workflow checks:

- `enabled=false` state dimension remains 9.
- `enabled=false` EOM output length remains 9.
- `enabled=false` EOM output is strictly identical to the legacy disabled path.
- Default trim and numeric linearization remain 9-state.
- `enabled=true` actuator responses remain bounded in `[0,90] deg`.
- The actual EOM output `d(betaM)/dt` remains within the 8 deg/s default rate
  limit plus numerical tolerance. The raw internal rate state is reported
  separately in generated CSV/report files for diagnostics.
- At `betaM=command` and `betaM_dot=0`, the nacelle acceleration is zero within
  numerical tolerance.
- With `x11 = [x9; condition.betaM; 0]` and an empty command, `f11(1:9)` matches
  the legacy 9-state EOM at representative speeds and nacelle angles.
- Enabled numeric linearization returns finite real `A` and `B` matrices of
  size `11x11` and `11x7`.
- The open-loop response demo remains finite and real.

The open-loop response only validates nacelle dynamic-state connection and
quasi-static aerodynamic/load variation with `betaM`. It does not represent
complete real conversion flight. Real conversion requires flight-control,
pilot, and control-scheduling logic.

## Known Risks

Endpoint linearization at `betaM = 0 deg` or `betaM = 90 deg` has medium risk
because the model uses angle clamp and boundary guards. Linearization studies
should prefer interior nacelle angles such as 15, 45, or 75 deg unless the
endpoint discontinuity is the subject of the study.

## Deferred Items

Phase 1 does not implement:

- `rCG_dot` or `rCG_ddot`;
- `I_dot*omega`;
- nacelle gyroscopic moments;
- nacelle actuator reaction torque;
- left/right independent nacelle states;
- PID or torque actuator dynamics;
- blade modal states;
- dynamic inflow states;
- closed-loop flight-control dynamics.
