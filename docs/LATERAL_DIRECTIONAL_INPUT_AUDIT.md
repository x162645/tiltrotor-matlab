# Lateral/Directional Input Audit

This audit prepares the current concept model for a possible future
Berger-inspired 13-state / 10-input extension. It is a documentation-only
audit. No production code, parameters, tests, services, or GUI logic were
changed.

The Berger comparison in this document uses the task-provided Berger facts as
context. This audit does not claim an independent reproduction of Berger's
51-state model and does not claim XV-15 or flight-test validation.

## 1. Executive Summary

The current production interface is a 7-control model:

```text
[collective diffCollective cyclicLong diffCyclic aileron elevator rudder]
```

The active default state vector is 9 states:

```text
[u v w p q r phi theta psi]
```

With the opt-in symmetric nacelle-dynamics extension enabled, the active state
vector becomes 11 states:

```text
[u v w p q r phi theta psi betaM betaM_dot]
```

The model is not "longitudinal only": it contains lateral/directional states,
lateral/directional aerodynamic terms, differential rotor inputs, aileron, and
rudder. However, the most mature trim and verification path is still
longitudinal/symmetric. Lateral/directional capability exists as component and
linearization behavior, not yet as a Berger-level handling-quality analysis
workflow.

The key missing Berger-inspired flight input is symmetric lateral cyclic. The
current rotor model has first-harmonic variables and a placeholder output field
for `theta1c`, but it fixes `theta1c = 0` and only maps external
`cyclicLong/diffCyclic` into the sine-phase longitudinal cyclic term
`theta1s`. Therefore a future 8-flight-input mode must add a real lateral
cyclic command path; it must not add an inert placeholder column to force a
matrix dimension.

Recommended sequence:

1. Add an opt-in 8-flight-input mode with a physically active symmetric lateral
   cyclic channel.
2. Only after that, revisit independent left/right nacelle states and nacelle
   torque inputs.
3. Treat 13 states / 10 inputs as `8 flight inputs + QnacL + QnacR`, not as a
   target dimension to be reached artificially.

## 2. Current State/Input Inventory

### State Vectors

| Mode | State vector | Evidence | Notes |
|-|-|-|-|
| Legacy/default | `[u v w p q r phi theta psi]` | `model/tiltrotor_eom.m`; `model/get_state_names.m`; `model/get_state_units.m` | Default when `P.nacelleDynamics.enabled = false`. |
| Opt-in symmetric nacelle dynamics | `[u v w p q r phi theta psi betaM betaM_dot]` | `model/tiltrotor_eom.m`; `model/get_state_names.m`; `model/get_state_units.m`; `params_nominal.m` | Adds symmetric nacelle angle and rate only. No left/right independent nacelle states. |

Lateral/directional states in the rigid-body vector are:

```text
v, p, r, phi, psi
```

The derivative rows used for lateral/directional linear analysis are:

```text
vdot, pdot, rdot, phidot, psidot
```

For stability derivatives usually named in force/moment form:

| Conventional derivative | Current matrix location | Important caveat |
|-|-|-|
| `Y_v`, `Y_p`, `Y_r` | `A(vdot, v/p/r)` | This is acceleration derivative, not raw side-force derivative. |
| `L_v`, `L_p`, `L_r` | `A(pdot, v/p/r)` | Includes full inertia coupling through `mp.I \ (...)`. |
| `N_v`, `N_p`, `N_r` | `A(rdot, v/p/r)` | Includes full inertia coupling through `mp.I \ (...)`. |

### Control Vector

| Index | Code name | Physical meaning in current code | Unit | Evidence |
|-:|-|-|-|-|
| 1 | `collective` | Symmetric rotor collective | rad | `total_forces_moments`, `run_trim_case`, `linearize_numeric` |
| 2 | `diffCollective` | Right collective plus, left collective minus | rad | `total_forces_moments` |
| 3 | `cyclicLong` | Symmetric longitudinal cyclic | rad | `CONTROL_CONVENTIONS.md`, `rotor_model_bemt` |
| 4 | `diffCyclic` | Historical code name for differential longitudinal cyclic | rad | `CONTROL_CONVENTIONS.md`, `check_control_architecture` |
| 5 | `aileron` | Wing aileron increment | rad | `wing_model` |
| 6 | `elevator` | Horizontal-tail elevator increment | rad | `horizontal_tail_model` |
| 7 | `rudder` | Twin-vertical-tail rudder increment | rad | `vertical_tail_model` |

The same 7-control order is hard-coded or reported in:

- `model/total_forces_moments.m`
- `analysis/evaluate_trim_definition_point.m`
- `analysis/linearize_numeric.m`
- `services/run_trim_case.m`
- `services/run_linearization_case.m`
- `services/simulate_linear_response.m`
- `app/launch_tiltrotor_app.m`
- `tests/check_control_architecture.m`
- `tests/run_all_checks.m`

## 3. Current Lateral/Directional Capability Boundary

Current lateral/directional capability:

- The equations of motion propagate `v`, `p`, `r`, `phi`, and `psi`.
- Body axes are documented as `x` forward, `y` right, `z` down.
- `total_forces_moments` returns total body-axis force and moment.
- `rotor_model_bemt` contributes force, arm moment, reaction torque, and
  gyroscopic moment.
- `wing_model` includes sideslip side force, aileron lift/moment increments,
  left/right regions, slipstream regions, and `cross(rAC, Freg)`.
- `fuselage_model` includes `CYbeta`, `Clbeta`, `Clp`, `Clr`, `Cnbeta`, `Cnp`,
  and `Cnr`.
- `vertical_tail_model` includes twin-tail sideslip and rudder side force.
- `linearize_numeric` can return `A` rows for `vdot/pdot/rdot` and `B` columns
  for all 7 current controls.

Current boundary:

- Trim definitions are explicitly longitudinal: residuals are `udot`, `wdot`,
  and `qdot`.
- The symmetric trim path fixes `v = p = r = phi = psi = 0` and fixes
  `diffCollective`, `diffCyclic`, `aileron`, and `rudder` at zero.
- There is no lateral/directional trim mode with nonzero sideslip, bank angle,
  roll/yaw residual closure, or coordinated-turn constraints.
- There is no dedicated lateral/directional stability-derivative report.
- There is no symmetric lateral cyclic control channel.
- Current lateral/directional tests are internal consistency checks, not a
  full handling-quality or Berger-equivalent validation workflow.

## 4. Mapping to Berger Inputs

This mapping is conceptual only. The current project is not a reproduction of
Berger's 51-state model.

| Berger-inspired input class | Current code input | Status | Notes |
|-|-|-|-|
| Symmetric collective | `collective` | Present | Rotor common collective. |
| Differential collective | `diffCollective` | Present | Right plus, left minus. |
| Symmetric longitudinal cyclic | `cyclicLong` | Present | Enters `theta1s` after side/rotation-direction mapping. |
| Differential longitudinal cyclic | `diffCyclic` | Present, historically named | Should be documented as `differentialLongitudinalCyclic`. |
| Symmetric lateral cyclic | none | Missing | Required before claiming an 8-flight-input concept. |
| Aileron | `aileron` | Present | Wing-only conventional surface path. |
| Elevator | `elevator` | Present | Horizontal-tail path and pitch allocation path. |
| Rudder | `rudder` | Present | Twin vertical-tail path. |
| Left nacelle torque | none | Missing | Future 13-state / 10-input concept only. |
| Right nacelle torque | none | Missing | Future 13-state / 10-input concept only. |

If symmetric lateral cyclic is not added, then adding left/right nacelle torque
would naturally produce 13 states / 9 inputs, not 13 states / 10 inputs.

If only symmetric nacelle torque were added to the current opt-in 11-state
model, the natural size would be 11 states / 8 inputs, not 13 states / 10
inputs.

## 5. Existing Lateral/Directional Input Path Audit

### `diffCollective`

| Field | Audit result |
|-|-|
| Physical meaning | Differential collective: right rotor collective is `collective + diffCollective`; left rotor collective is `collective - diffCollective`. |
| Code location | `model/total_forces_moments.m` allocation before calling `rotor_model_bemt`. |
| Affected components | Left and right rotors only. Wing can be indirectly affected through rotor slipstream diagnostics because it receives rotor outputs. |
| Expected `Y/L/N` effect | Primary roll moment `L = Mx` from unequal thrust and lateral rotor arm; yaw moment `N = Mz` from unequal reaction torque and rotor force/moment changes. Side force `Y = Fy` should be small/zero in symmetric hover by architecture tests. |
| Current evidence | `tests/check_control_architecture.m` expects positive `diffCollective` to produce `dMx < 0`, `dMz > 0`, while symmetric force and pitch axes remain near zero. |
| Risk/uncertainty | Signs depend on body-axis convention, side convention, reaction torque sign, and rotor rotation direction `rotDir = side`. The current tests cover hover-like local derivatives, not the full flight envelope. |

### `diffCyclic`

| Field | Audit result |
|-|-|
| Physical meaning | Historical code name for differential longitudinal cyclic, not generic differential cyclic and not lateral cyclic. |
| Code location | `model/total_forces_moments.m` maps right side to `cyclicLong + diffCyclic` and left side to `cyclicLong - diffCyclic`; `model/rotor_model_bemt.m` maps the side command to `theta1s = -rotDir*rotorCtrl.cyclicLong`. |
| Affected components | Left and right rotors only, with possible indirect wing slipstream coupling through rotor outputs. |
| Expected `Y/L/N` effect | Primary yaw moment increment in the current hover-like control-architecture test; residual lateral force and roll moment are treated as diagnostics, not intended primary effects. |
| Current evidence | `docs/CONTROL_CONVENTIONS.md` says positive `diffCyclic` gives right cyclicSide positive and left cyclicSide negative and produces a negative yaw-moment increment. `tests/check_control_architecture.m` checks `dMz < 0`. |
| Risk/uncertainty | The code name is ambiguous and can block clean future insertion of symmetric lateral cyclic unless future docs/API distinguish `differentialLongitudinalCyclic` from `lateralCyclic`. |

### `aileron`

| Field | Audit result |
|-|-|
| Physical meaning | Conventional wing aileron effect. |
| Code location | `model/wing_model.m` reads `uCtrl(5)` and applies `dCLail = -side*P.wing.CLaileron*aileron` plus `Cmaileron*(-side*aileron)`. |
| Affected components | Wing free-stream and slipstream regions only. |
| Expected `Y/L/N` effect | Primary roll moment `L = Mx` through left/right lift differential and wing arm. Secondary yaw/side-force effects are not the primary modeled path. |
| Current evidence | `tests/check_aerodynamic_components.m` checks aileron sign-reversal mirror behavior and expects positive aileron to increase wing `Mx` relative to baseline. |
| Risk/uncertainty | Aileron authority is a conceptual coefficient path; there is no dedicated lateral trim or handling-quality report that evaluates aileron effectiveness across operating points. |

### `rudder`

| Field | Audit result |
|-|-|
| Physical meaning | Conventional rudder increment applied to both vertical tails. |
| Code location | `model/vertical_tail_model.m` receives `uApplied(7)` and computes `CY = CYbeta*beta + CYrudder*rudder`; moments are from `cross(rAC, Ffin)`. |
| Affected components | Twin vertical tails. |
| Expected `Y/L/N` effect | Direct side force `Y = Fy` and yaw moment `N = Mz`; possible roll moment from vertical and lateral force arms. |
| Current evidence | `tests/check_aerodynamic_components.m` checks twin-tail sideslip/rudder response, including rudder side force and yaw moment mirror behavior. |
| Risk/uncertainty | Current vertical-tail model is low-order and not yet tied to a lateral/directional derivative report or validated coefficient source. |

### `elevator`

| Field | Audit result |
|-|-|
| Physical meaning | Horizontal-tail elevator increment. |
| Code location | `model/horizontal_tail_model.m` receives `uApplied(6)` and affects `CL` and `Cm`. |
| Affected components | Horizontal tail. |
| Expected `Y/L/N` effect | Primarily pitch-axis effect through `My`; lateral/directional effects can occur indirectly through local flow from `v/p/r` and force-arm coupling, but elevator is not a lateral/directional primary control. |
| Current evidence | `tests/check_aerodynamic_components.m` checks elevator response and downwash consistency. |
| Risk/uncertainty | Elevator participates in conversion pitch allocation, but not in lateral/directional trim closure. |

### `cyclicLong`

| Field | Audit result |
|-|-|
| Physical meaning | Symmetric longitudinal cyclic. |
| Code location | `total_forces_moments` sends equal side cyclic when `diffCyclic = 0`; `rotor_model_bemt` maps it into `theta1s`. |
| Affected components | Left and right rotors, indirectly wing slipstream. |
| Expected `Y/L/N` effect | Primary longitudinal force and pitch moment; lateral force and yaw moment cancel in the symmetric hover-like architecture test. |
| Current evidence | `tests/check_control_architecture.m` expects `dFx > 0`, `dMy < 0`, and near-zero lateral/yaw effects for symmetric longitudinal cyclic. |
| Risk/uncertainty | The rotor has no external lateral cyclic input; `theta1c` remains fixed at zero. |

### `collective`

| Field | Audit result |
|-|-|
| Physical meaning | Symmetric rotor collective. |
| Code location | `total_forces_moments` sends equal side collective when `diffCollective = 0`. |
| Affected components | Left and right rotors, indirectly wing slipstream. |
| Expected `Y/L/N` effect | Symmetric thrust path; lateral force, roll moment, and yaw moment should cancel in symmetric hover-like conditions. |
| Current evidence | `tests/check_control_architecture.m` expects upward thrust increase and near-zero `Fy/Mx/Mz`. |
| Risk/uncertainty | Asymmetric states or nonzero rates can still introduce cross-coupled lateral/directional derivatives through force arms and equations of motion. |

## 6. Current Y/L/N Derivative and Linearization Capability

### What can be extracted today

`linearize_numeric` returns finite-difference matrices:

```text
A = d(xdot)/d(x)
B = d(xdot)/d(u)
```

With current state names, the following lateral/directional acceleration
derivatives can be extracted from `A`:

| Derivative family | Matrix entries |
|-|-|
| Side acceleration | `A(vdot, v)`, `A(vdot, p)`, `A(vdot, r)`, `A(vdot, phi)`, `A(vdot, psi)` |
| Roll acceleration | `A(pdot, v)`, `A(pdot, p)`, `A(pdot, r)`, `A(pdot, phi)`, `A(pdot, psi)` |
| Yaw acceleration | `A(rdot, v)`, `A(rdot, p)`, `A(rdot, r)`, `A(rdot, phi)`, `A(rdot, psi)` |
| Kinematic lateral/directional rows | `A(phidot, *)`, `A(psidot, *)` |

The following current control derivatives can be extracted from `B`:

| Control | Relevant `B` rows | Current expected relevance |
|-|-|-|
| `diffCollective` | `B(vdot/pdot/rdot, 2)` | Roll/yaw rotor differential path. |
| `diffCyclic` | `B(vdot/pdot/rdot, 4)` | Differential longitudinal cyclic yaw path. |
| `aileron` | `B(vdot/pdot/rdot, 5)` | Wing roll-control path. |
| `rudder` | `B(vdot/pdot/rdot, 7)` | Vertical-tail side-force/yaw path. |
| `collective` | `B(vdot/pdot/rdot, 1)` | Expected mostly symmetric, but cross-coupling may exist at asymmetric states. |
| `cyclicLong` | `B(vdot/pdot/rdot, 3)` | Expected mostly longitudinal in symmetric hover-like checks. |
| `elevator` | `B(vdot/pdot/rdot, 6)` | Primarily longitudinal/pitch, possible cross-coupling through state and geometry. |

Important caveat: these are state-derivative entries, not raw aerodynamic
stability derivatives. `pdot` and `rdot` include the full inertia matrix solve
and gyroscopic/coriolis terms. Raw generalized-load derivatives can be audited
separately through `total_forces_moments`, as done in
`tests/check_control_architecture.m`.

### Missing derivative/test/report coverage

| Gap | Current status | Recommended future artifact |
|-|-|-|
| Dedicated lateral/directional derivative report | Missing | `analysis/report_lateral_directional_derivatives.m` or equivalent service/report. |
| Raw `Y/L/N` load derivative audit over representative trims | Partial local hover-like control checks only | Focused test comparing raw `d[F;M]/d(input)` and state `B` rows. |
| Lateral/directional trim/linearization credibility | Missing | A trim definition with lateral/directional residuals and a credibility packet. |
| `L_aileron`, `N_rudder` report | Extractable manually from `B`, not reported as named metrics | Named derivative table with state/control labels and units. |
| Symmetric lateral cyclic derivatives | Not available | Add opt-in `lateralCyclic` before reporting this column. |

### Structural consequence of missing symmetric lateral cyclic

The current 7-control `B` matrix can represent:

- differential collective roll/yaw effects;
- differential longitudinal cyclic yaw effects;
- aileron roll effects;
- rudder yaw/side-force effects.

It cannot represent the rotor symmetric lateral cyclic channel. Therefore any
future claim of 8 non-nacelle flight inputs must wait until that channel exists
as a real force/moment-producing path.

## 7. Missing Symmetric Lateral Cyclic

The current rotor model has enough internal harmonic structure to identify
where a lateral cyclic input would probably enter:

- blade flapping state:
  `beta = beta0 + beta1c*cos(psi) + beta1s*sin(psi)`;
- disk normal:
  `nDisk = normalize(eT - beta1c*eD - beta1s*eY)`;
- current blade pitch:
  `thetaBlade = collective + twist + theta1s*sin(psi)`;
- current command mapping:
  `theta1c = 0`;
  `theta1s = -rotDir*rotorCtrl.cyclicLong`.

Thus the missing concept is the external command that produces a nonzero
cosine-phase blade pitch term, likely:

```text
thetaBlade = collective + twist + theta1c*cos(psi) + theta1s*sin(psi)
```

This audit does not define the final sign convention. A future implementation
must explicitly document:

- whether positive `lateralCyclic` tilts disk normals toward `+eY` or `-eY`;
- whether the command maps directly to `theta1c` or includes `rotDir`;
- expected sign of the resulting roll moment in hover;
- expected symmetry between left and right rotors;
- interaction with current `diffCyclic` naming.

Recommended public name:

```text
lateralCyclic
```

Reason: it is clearer than `cyclicLat` in prose and less implementation-phase
specific than `cyclic1c`. It also avoids confusion with the historical
`diffCyclic`, which should be documented as `differentialLongitudinalCyclic`.

## 8. Proposed Safe Path to 8 Flight Inputs

Minimum safe opt-in plan:

1. Keep the legacy/default 7-control path unchanged.
2. Add a feature flag or mode that explicitly enables an 8-flight-input vector.
3. In that mode, define control order as:

```text
[collective
 diffCollective
 cyclicLong
 diffCyclic
 lateralCyclic
 aileron
 elevator
 rudder]
```

4. Add a side-control field such as `rotorCtrl.cyclicLat` or
   `rotorCtrl.lateralCyclic` only in the enabled path.
5. Map lateral cyclic into a real blade-pitch harmonic, not a placeholder.
6. Update all dimension checks and labels together:
   `params_nominal.m`, `validate_inputs`, `total_forces_moments`,
   `rotor_model_bemt`, `tiltrotor_eom`, `linearize_numeric`,
   trim definitions, services, GUI, and tests.
7. Add tests before using the new input in trim or response studies.

Required tests for the future implementation:

| Test | Purpose |
|-|-|
| `enabled = false` legacy test | Prove 7-control behavior and matrix sizes are unchanged. |
| `enabled = true` dimension test | Prove 8-control input vectors are accepted and labeled. |
| Lateral cyclic force/moment test | Prove `lateralCyclic` produces a nonzero, sign-defined roll moment. |
| Sign convention test | Document the positive-direction convention for disk tilt and `Mx`. |
| `B` matrix size test | Prove `B` changes from `nx x 7` to `nx x 8` only in the enabled mode. |
| GUI/service test | Prove response controls and table labels do not desynchronize. |
| No inert column test | Prove the new column changes physical loads under a representative condition. |

Things not to do:

- Do not add an eighth zero column just to match Berger's input count.
- Do not rename `diffCyclic` as lateral cyclic.
- Do not change the default 7-control interface silently.
- Do not alter mass, inertia, geometry, rotor rotation signs, or existing
  control signs to make a new test pass.
- Do not claim Berger 51-state reproduction or XV-15 validation.

## 9. Long-Term Path to 13 States / 10 Inputs

Current:

| Mode | Natural size | Meaning |
|-|-:|-|
| Legacy/default | 9 states / 7 inputs | Rigid body, static nacelle angle argument. |
| Symmetric nacelle opt-in | 11 states / 7 inputs | Adds symmetric `betaM` and `betaM_dot`; no new control input. |

Recommended route:

| Stage | Natural size | Required physical addition |
|-|-:|-|
| Add symmetric lateral cyclic to legacy path | 9 states / 8 flight inputs | Real lateral cyclic rotor pitch harmonic. |
| Add symmetric lateral cyclic to nacelle opt-in path | 11 states / 8 flight inputs | Same input plus current symmetric nacelle states. |
| Add independent left/right nacelle states and torque inputs | 13 states / 10 inputs | `betaL`, `betaL_dot`, `betaR`, `betaR_dot`, plus `QnacL`, `QnacR`. |

Long-term 13-state concept:

```text
[u v w p q r phi theta psi betaL betaL_dot betaR betaR_dot]
```

Long-term 10-input concept:

```text
8 flight inputs + QnacL + QnacR
```

This is Berger-inspired in the limited sense of input/state architecture. It is
not Berger's 51-state model.

## 10. Risks and Non-Goals

### Risks

| Severity | Category | Finding | Impact |
|-|-|-|-|
| HIGH | Model missing | Symmetric lateral cyclic is absent. | Cannot claim 8 flight inputs or 13x10 architecture. |
| MEDIUM | Naming/sign convention | `diffCyclic` is ambiguous unless consistently documented as `differentialLongitudinalCyclic`. | Future lateral cyclic integration may confuse longitudinal and lateral cyclic effects. |
| MEDIUM | Test/report gap | There is no dedicated lateral/directional derivative report. | `Y/L/N` capability is extractable but not packaged or regression-tested as named derivatives. |
| MEDIUM | Trim boundary | Current trim framework is longitudinal/symmetric. | Lateral/directional dynamics should not be interpreted as validated handling-quality analysis. |
| LOW | GUI/service coupling | GUI and response services assume exactly 7 controls. | Future 8-control mode requires coordinated label, dimension, and UI changes. |

### Non-Goals For This Audit

- No code implementation.
- No MATLAB execution.
- No parameter edits.
- No model equation edits.
- No change to `docs/NACELLE_DYNAMIC_STATE_AUDIT.md`.
- No commit or push.
- No Berger PDF copy or submission.
- No claim that the current concept model reproduces XV-15, Berger, or flight
  test data.

## 11. Recommended Next Codex Task

Recommended next task:

```text
Design, but do not yet implement, an opt-in 8-flight-input lateralCyclic
interface and test plan.
```

Scope for that next task:

- Decide the public flag and 7-vs-8 control labeling strategy.
- Define the positive sign convention for `lateralCyclic`.
- Specify the exact rotor harmonic mapping for `theta1c`.
- Specify expected hover-limit force/moment signs.
- Enumerate required code touch points and tests.
- Keep default 7-control behavior unchanged.

Stop condition for that next task:

- Produce a design document and proposed tests only.
- Do not modify model equations until the sign convention and expected
  derivative behavior are reviewed.

