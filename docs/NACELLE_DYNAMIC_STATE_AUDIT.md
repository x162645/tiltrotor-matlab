# Nacelle Dynamic State Audit

Generated: 2026-07-08

## Scope And Working Tree

This is a Phase 0 audit for an optional nacelle dynamic-state extension. No
model implementation is included in this report.

Current checked worktree:

```text
E:\tiltrotor
branch: fix/nuaa-paper-trend-comparison
HEAD: 3550e5b855bac1c38e9d275cf3f8e608cb519c70
```

Dirty status observed before this report was written:

```text
 M model/rotor_model_bemt.m
 M model/wing_model.m
?? CODEX_XFOIL_PREFLIGHT_TASK.md
?? analysis/make_nuaa_paper_comparison_definition.m
?? analysis/run_nuaa_15deg_collective_slope_root_cause.m
?? analysis/run_nuaa_15deg_rotor_force_product_decomposition.m
?? analysis/run_nuaa_15deg_rotor_load_derivative.m
?? analysis/run_nuaa_15deg_rotor_thrust_root_cause.m
?? analysis/run_nuaa_direct_physics_root_cause.m
?? analysis/run_nuaa_paper_comparison_correction.m
?? tests/check_nuaa_paper_comparison_smoke.m
?? tests/check_nuaa_paper_cyclic_mapping.m
?? tests/check_nuaa_paper_trim_definitions.m
?? tools/external/xfoil/xfoil.exe
```

Those existing dirty files were not cleaned, reset, stashed, or edited by this
audit. The only intended file addition is this markdown report.

No `TomBerger-Dissertation.pdf`, `*Berger*`, `*Dissertation*`, or `*Tom*`
reference file was found in the repository. This audit therefore uses only the
project code and the Berger nacelle-state background supplied in the task
prompt. No internet search was performed.

## Current State And Input Dimensions

The active nonlinear model is a 9-state rigid-body model:

```matlab
x = [u; v; w; p; q; r; phi; theta; psi]
```

Evidence:

- `model/tiltrotor_eom.m:1-4` declares `tiltrotor_eom(x, uCtrl, betaM, P)`
  and documents `x = [u v w p q r phi theta psi]'`.
- `model/tiltrotor_eom.m:11-48` returns only `[Vdot; omegaDot; eulerDot]`,
  so the EOM output is 9-by-1.
- `model/validate_inputs.m:4` requires `numel(x) == 9`.
- `analysis/linearize_numeric.m:8-12` requires `nx == 9` and `nu == 7`.
- `analysis/evaluate_trim_definition_point.m:9-22` defines nine state names
  and initializes `x = zeros(9,1)`.
- `services/run_trim_case.m:42` and `services/run_linearization_case.m:65`
  publish exactly nine GUI/service state names.
- `services/simulate_linear_response.m:36,82,98` requires 9-by-9 `A`, 9-by-7
  `B`, integrates `zeros(9,1)`, and publishes nine state names.
- `app/launch_tiltrotor_app.m:1181-1184` displays the first nine states in a
  fixed loop.

The active control vector is 7-by-1:

```matlab
uCtrl = [collective; diffCollective; cyclicLong; diffCyclic; aileron; elevator; rudder]
```

Evidence:

- `README.md:35-42` documents the seven-control vector.
- `analysis/evaluate_trim_definition_point.m:6-11` documents and defines the
  same seven controls.
- `model/total_forces_moments.m:11-14` unpacks `uCtrl(1:4)` as collective,
  differential collective, longitudinal cyclic, and differential longitudinal
  cyclic; the remaining controls are used by wing, horizontal tail, and
  vertical tail.

## Nacelle-Angle Convention

The current project and NUAA path use:

```text
betaM = 0 deg  -> helicopter mode
betaM = 90 deg -> airplane mode
```

The Berger background supplied for this task uses the opposite convention:

```text
delta_nac_Berger = 0 deg  -> airplane mode
delta_nac_Berger = 90 deg -> helicopter mode
```

If a Berger angle is referenced in future code or documentation, the required
conversion is:

```text
delta_nac_Berger_deg = 90 - betaM_NUAA_deg
```

The proposed opt-in model should use the project `betaM` convention internally
to avoid mixed symbols.

## Current `betaM` Propagation Paths

`betaM` is currently an external condition parameter, not a state.

### EOM And Force/Moment Assembly

- `model/tiltrotor_eom.m:1` receives `betaM` as a function argument.
- `model/tiltrotor_eom.m:11` passes that external `betaM` to
  `total_forces_moments`.
- `model/total_forces_moments.m:7` validates `x`, `uCtrl`, and external
  `betaM`.
- `model/total_forces_moments.m:9` calls `mass_properties(betaM, P)`.
- `model/total_forces_moments.m:38-45` passes `betaM` into both rotors and the
  wing model.

### Mass, CG, And Inertia

- `model/mass_properties.m:1` receives `betaM`.
- `model/mass_properties.m:5-6` computes the moving nacelle/rotor CG shift:
  `dx = mNac*RH_mass*sin(betaM)/m`,
  `dz = mNac*RH_mass*(1-cos(betaM))/m`.
- `model/mass_properties.m:10` computes a quasi-static inertia schedule
  `I = I0 - betaM*KI`.
- `params_nominal.m:14-19` defines `mNac` and `RH_mass`.
- `params_nominal.m:28` documents `I(betaM) = I0 - betaM*KI`.

These paths can read an instantaneous dynamic `betaM` without large interface
changes, but they currently ignore all time derivatives of mass distribution.

### Rotor Geometry And Rotor Axes

- `model/rotor_model_bemt.m:28-31` defines current code axes:
  `eT=[sin(betaM);0;-cos(betaM)]`,
  `eD=[cos(betaM);0;sin(betaM)]`.
- `model/rotor_model_bemt.m:34-36` moves the hub with
  `RH_hub*sin(betaM)` and `-RH_hub*cos(betaM)`.
- `model/rotor_model_bemt.m:38` subtracts the current `cgShift`.
- `model/rotor_model_bemt.m:127-129` uses `eT` for reaction torque and rotor
  angular momentum direction.

These paths are quasi-static in nacelle angle. They do not include nacelle
angular-rate contributions to hub velocity, rotor-axis acceleration, or
gyroscopic torques from nacelle pitching.

### Wing Slipstream Zone And Local Velocity

- `model/wing_model.m:19-23` explicitly states the NUAA code convention and
  computes `slipstreamAngleArgument = pi/2 - betaM`.
- `model/wing_model.m:26-31` computes and clamps slipstream/free-stream area.
- `model/wing_model.m:99-104` computes the induced-velocity term for the
  slipstream region:
  `VwakeEq17 = [v1d*sin(betaM); 0; -v1d*cos(betaM)]`.
- `model/wing_model.m:107` keeps free-stream regions free of rotor induced
  velocity.

The wing can use an instantaneous dynamic `betaM`, but this remains a
quasi-steady aerodynamic evaluation.

### Control Allocation And Trim-Mode Scheduling

- `analysis/make_trim_definition.m:33,69-85` chooses initial guesses and
  conversion logic based on `condition.betaM`.
- `analysis/make_trim_definition.m:62-63,101` calls
  `pitch_allocation_schedule(condition.betaM, ...)`.
- `analysis/pitch_allocation_schedule.m:6-7` validates `betaM in [0,pi/2]`.
- `analysis/pitch_allocation_schedule.m:31-32` uses
  `gCyclic = cos(betaM)^2` and `gElevator = sin(betaM)^2`.

This is an open-loop trim-layer allocation, not a closed-loop flight-control
system. A dynamic `betaM` opt-in path must not change the default allocation
or the NUAA quasi-static baseline.

### Trim, Linearization, And GUI/Services

- `analysis/trim_general.m:4,151-166` requires `condition.V`, `condition.betaM`,
  and `condition.gamma`; `betaM` is a prescribed trim condition.
- `analysis/trim_general.m:21-22` passes `condition.betaM` to legacy
  `trim_symmetric`.
- `analysis/evaluate_trim_definition_point.m:56` evaluates the EOM with
  `condition.betaM`.
- `analysis/trim_symmetric.m:1,10,30-33` accepts prescribed `betaM`.
- `analysis/trim_symmetric.m:219` evaluates `tiltrotor_eom(..., betaM, P)`.
- `analysis/linearize_numeric.m:1,20-21,46-64` receives prescribed `betaM` and
  passes it unchanged to the EOM during central differences.
- `services/run_trim_case.m:28-30` converts `config.betaMDeg` to radians and
  passes it to `trim_symmetric` and `tiltrotor_eom`.
- `services/run_trim_case.m:78-79` validates GUI trim `betaMDeg` in `[0,90]`.
- `app/launch_tiltrotor_app.m:112-113` exposes a numeric trim nacelle-angle
  field with limits `[0,90]`.
- `app/launch_tiltrotor_app.m:423` sends `betaMDeg` into `run_trim_case`.

Current trim and GUI flows therefore treat `betaM` as an external condition,
not an unknown, state, or actuator command.

## Hard-Coded 9-State Sites

The following sites would need review before any 11-state opt-in path:

| File | Location | Current behavior |
|---|---:|---|
| `model/validate_inputs.m` | line 4 | Requires `numel(x) == 9`. |
| `model/tiltrotor_eom.m` | lines 1-4, 48 | Documents and returns 9-state EOM. |
| `analysis/linearize_numeric.m` | lines 8-12 | Rejects non-9-state `x`. |
| `analysis/evaluate_trim_definition_point.m` | lines 9-22 | Builds only the 9 rigid-body states. |
| `services/run_trim_case.m` | line 42 | Publishes nine state names. |
| `services/run_linearization_case.m` | line 65 | Publishes nine state names. |
| `services/simulate_linear_response.m` | lines 36, 82, 98 | Requires 9-by-9/9-by-7 and integrates nine states. |
| `services/validate_parameter_set.m` | line 142 | Requires `P.linear.dx` length 9. |
| `services/build_parameter_catalog.m` | lines 381-387 | Builds nine linearization state-step parameters. |
| `app/launch_tiltrotor_app.m` | lines 1181-1184 | Displays exactly nine states. |
| tests | many files | Many tests create `zeros(9,1)` for component and regression checks. |

## Dynamic-State Risk Assessment

### Low-Risk Instantaneous Reads

The following code paths mostly need the current `betaM` value and can use a
state-derived `betaM_dyn` in an opt-in wrapper:

- rotor thrust-axis and disk-basis construction;
- rotor hub nominal position;
- mass-properties `cgShift` and scheduled `I(betaM)`;
- wing slipstream area;
- wing slipstream induced-velocity direction;
- trim/report metadata that stores the active `betaM`.

### Coupling Risks Not Covered By A Minimal First Version

If `betaM` becomes a dynamic state, the current equations remain incomplete
unless deliberately treated as quasi-static. Missing couplings include:

- `rCG_dot` and `rCG_ddot` effects from moving nacelle/rotor mass;
- `I_dot*omega` terms in the angular momentum equation;
- nacelle angular acceleration reaction moments;
- rotor gyroscopic moments from changing rotor-axis direction due to
  nacelle-rate motion;
- added hub velocity from nacelle rotation, beyond current
  `Vbody + cross(omegaBody,rHub)`;
- left/right nacelle desynchronization and differential nacelle moments;
- actuator torque dynamics and structural flexibility;
- closed-loop nacelle controller/PID torque logic.

Therefore the first opt-in implementation should be explicitly named a
quasi-static nacelle dynamic model: `betaM` has state lag and rate limiting,
but full-aircraft loads, CG shift, and inertia are still evaluated with the
instantaneous `betaM` in the existing algebraic formulas.

## Recommended Minimal Opt-In Plan

Do not replace the current 9-state legacy model. Keep all existing calls valid.

### Parameters

Add default-off parameters only when Phase 1 is explicitly approved:

```matlab
P.nacelleDynamics.enabled = false;
P.nacelleDynamics.model = 'symmetric_second_order';  % or 'symmetric_first_order'
P.nacelleDynamics.betaMinDeg = 0;
P.nacelleDynamics.betaMaxDeg = 90;
P.nacelleDynamics.rateLimitDegPerSec = 8;
P.nacelleDynamics.tau = ...;      % documented engineering default
P.nacelleDynamics.omega = ...;    % rad/s, documented engineering default
P.nacelleDynamics.zeta = ...;     % dimensionless
P.nacelleDynamics.commandDeg = [];
```

Defaults must preserve legacy behavior exactly because `enabled=false`.

### Interface Strategy

Use a narrow helper layer rather than broad signature churn:

1. Keep `tiltrotor_eom(x,uCtrl,betaM,P)` callable as today.
2. Inside `tiltrotor_eom`, if `P.nacelleDynamics.enabled=false`, keep the
   existing 9-state path unchanged.
3. If `enabled=true`, require `numel(x)==11`, read:

   ```matlab
   betaM_dyn = x(10);
   betaM_rate = x(11);
   ```

   Then use `betaM_dyn` as the effective `betaM` passed into
   `total_forces_moments`.
4. Append the nacelle state derivatives to the existing 9 rigid-body
   derivatives.
5. Keep the external `betaM` argument as a legacy fallback and, for opt-in
   mode, as the default command source when `P.nacelleDynamics.commandDeg=[]`.

This preserves existing trim, validation, and plotting calls unless the user
explicitly enables the new state path.

### First-Order Option

```matlab
betaCmd = clamp(betaCmd, betaMin, betaMax);
betaDotCmd = (betaCmd - betaM_dyn)/tau;
betaM_dot = clamp(betaDotCmd, -rateLimit, rateLimit);
```

For an 11-state model with `x(11)=betaM_rate`, either set
`betaM_dot = clamp(betaM_rate,...)` plus a rate-state lag, or prefer the
second-order form below to make `[betaM; betaM_dot]` physically consistent.

### Second-Order Option

```matlab
betaCmd = clamp(betaCmd, betaMin, betaMax);
betaM_dot = clamp(betaM_rate, -rateLimit, rateLimit);
betaM_rate_dot = omega_n^2*(betaCmd - betaM_dyn) ...
                 - 2*zeta*omega_n*betaM_rate;
```

The rate derivative should also prevent the integrated beta state from driving
far outside `[0,90] deg`; an implementation can zero the outward derivative at
the angle limits or clamp the command and apply a boundary guard.

All internal computations should use radians. Parameters expressed in degrees
must be converted exactly once at the boundary.

### Left/Right Extension Deferred

Do not implement left/right nacelle states in the first version. A future model
can use:

```matlab
[betaL; betaLdot; betaR; betaRdot]
```

and derive symmetric/differential nacelle angles:

```matlab
betaSym = 0.5*(betaL + betaR);
betaDiff = 0.5*(betaR - betaL);
```

The current force/moment model has no differential-nacelle path, so this would
require additional rotor geometry, mass, inertia, and reaction-moment work.

## Phase 1 Test Plan If Approved

Focused tests should be added before any broad regression:

1. `enabled=false` invariance:
   representative EOM, trim residual, and linearization outputs match current
   behavior within roundoff.
2. `enabled=true` dimension:
   `tiltrotor_eom` accepts 11 states and returns 11 derivatives.
3. Rate limit:
   beta command step moves toward the command and `abs(betaM_dot) <= 8 deg/s`.
4. Command clamp:
   commands below 0 deg or above 90 deg are clamped.
5. Unit conversion:
   deg parameters convert to rad once; no deg/rad mixing.
6. Baseline separation:
   NUAA Fig.5/Fig.6 trend comparisons remain on the legacy/quasi-static
   baseline unless a separate opt-in validation is requested.

Do not require NUAA Fig.5/Fig.6 to improve as acceptance criteria. This change
adds actuator/nacelle-state dynamics, not a correction to rotor, wing, trim,
or paper-variable mapping.

## Explicit Non-Goals

- This is not a Berger 51-state reproduction.
- The proposed first version does not include Berger/HeliUM blade modal
  states.
- The proposed first version does not include dynamic inflow states.
- The proposed first version does not include a closed-loop flight controller.
- The proposed first version does not include a full PID torque model for
  nacelle actuation.
- The default legacy/NUAA quasi-static nacelle-angle path must remain
  unchanged.

## Stop Point

Phase 0 is complete with this audit. Phase 1 implementation should not begin
until explicitly requested.
