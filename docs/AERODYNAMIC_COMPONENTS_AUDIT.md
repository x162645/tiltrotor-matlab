# Aerodynamic Components Audit

Branch: `audit/aero-components`

Scope: `aero_force_body`, wing, fuselage, horizontal-tail, vertical-tail, and
non-rotor interaction diagnostics. This audit checks internal consistency of
the current conceptual model. It does not validate XV-15 data and does not
change any production parameter value.

## Files Reviewed

- `AGENTS.md`
- `CODEX_TASK.md`
- `params_nominal.m`
- `model/aero_force_body.m`
- `model/wing_model.m`
- `model/fuselage_model.m`
- `model/horizontal_tail_model.m`
- `model/vertical_tail_model.m`
- `model/total_forces_moments.m`
- `model/mass_properties.m`
- `model/rotor_model_bemt.m`
- `tests/check_wing_normal_flow_blend.m`
- `tests/check_control_architecture.m`
- `tests/check_mass_inertia_geometry.m`
- `tests/run_all_checks.m`
- `docs/CONTROL_CONVENTIONS.md`
- `docs/PHYSICS_AND_CODE_AUDIT.md`
- `docs/MASS_INERTIA_GEOMETRY_AUDIT.md`

Search covered the requested identifiers:

```text
aero_force_body
wing_model
fuselage_model
horizontal_tail_model
vertical_tail_model
wakeFactor
normalFlowRatio
normalFlowBlendHalfWidth
downwashAlpha
CLaileron
CLelevator
CYrudder
```

`rg` unexpectedly returned no matches for simple literal queries in this
environment, so the recorded search was completed with PowerShell
`Select-String`.

## Diagnostic Changes

The production force, moment, control, coordinate, branch, slipstream, and
downwash equations were not changed. The following diagnostic fields were
added only to expose already-computed values:

- Wing region diagnostics: `qbar`, `Marm`, `Maero`, and zero-speed
  `side/inSlipstream/wakeVelocity/rAC/Vlocal` diagnostics.
- Fuselage diagnostics: `qbar`, normalized rates, `Marm`, `Maero`.
- Horizontal-tail diagnostics: `alphaCG`, `beta`, `qbar`, `Marm`, `Maero`.
- Vertical-tail fin diagnostics: `qbar`, `Marm`.

`tests/run_all_checks.m` now includes the new lightweight aerodynamic component
audit.

## Lightweight Check

New target:

```matlab
r = check_aerodynamic_components;
```

The first-pass target uses direct canonical component calls only. It does not
call trim, continuation, flight-envelope logic, dense sweeps, optimization, or
Monte Carlo.

Actual top-level call count:

|Function|Calls|
|-|-:|
|`aero_force_body`|6|
|`wing_model`|9|
|`fuselage_model`|5|
|`horizontal_tail_model`|4|
|`vertical_tail_model`|5|
|`total_forces_moments`|0|
|Total|29|

Covered cases:

|Case|Result|
|-|-|
|Aero force basis and canonical directions|PASS|
|Positive drag opposes local velocity|PASS|
|Wing area partition and left/right symmetry|PASS|
|Aileron sign-reversal mirror and roll sign|PASS|
|Near-normal blend continuity and diagnostics|PASS|
|Slipstream scope and hover force direction|PASS|
|Fuselage decomposition, drag, and p/q/r damping|PASS|
|Horizontal-tail downwash and elevator response|PASS|
|Twin vertical-tail sideslip and rudder response|PASS|
|Finite real deterministic representative conditions|PASS|

## Test Results

Commands were run with the full MATLAB path:

```powershell
& 'F:\matlab\R2021a\bin\matlab.exe' -batch "cd('E:\tiltrotor'); run('startup.m'); r = check_aerodynamic_components; disp(r); assert(r.allPassed);"
& 'F:\matlab\R2021a\bin\matlab.exe' -batch "cd('E:\tiltrotor'); run('startup.m'); r = check_wing_normal_flow_blend; disp(r.allPassed); assert(r.allPassed);"
& 'F:\matlab\R2021a\bin\matlab.exe' -batch "cd('E:\tiltrotor'); run('startup.m'); r = check_control_architecture; disp(r.allPassed); assert(r.allPassed);"
& 'F:\matlab\R2021a\bin\matlab.exe' -batch "cd('E:\tiltrotor'); run('startup.m'); summary = run_all_checks; disp(summary.allPassed); assert(summary.allPassed);"
```

Test-body results:

- `check_aerodynamic_components`: 10/10 PASS.
- `check_wing_normal_flow_blend`: PASS for half-widths
  `0.030`, `0.050`, `0.080`, and current `0.150`.
- `check_control_architecture`: 6/6 PASS.
- `run_all_checks`: 13/13 PASS, including the new aerodynamic component audit.

MATLAB R2021a produced the known shutdown-stage:

```text
output stream error
```

after each successful test-body run. This occurred after PASS summaries and is
recorded separately from model/test assertions.

No test-body warning, NaN, Inf, or complex output was observed in the covered
checks.

## Force Transform

`aero_force_body` uses the basis:

```matlab
xWind = [cos(alpha)*cos(beta); sin(beta); sin(alpha)*cos(beta)];
yWind = [-cos(alpha)*sin(beta); cos(beta); -sin(alpha)*sin(beta)];
zWind = [-sin(alpha); 0; cos(alpha)];
Fbody = -D*xWind + Y*yWind - L*zWind;
```

The checked basis is unit length, mutually orthogonal, right-handed, and
consistent with body axes `x` forward, `y` right, `z` down. Canonical cases at
zero angle give:

- positive drag: `Fx < 0`;
- positive side force: `Fy > 0`;
- positive lift: `Fz < 0`.

For nonzero alpha/beta, positive drag opposes the model's local velocity
representation, while side force and lift remain perpendicular to the velocity
axis.

## Wing Conclusions

- `SfreeHalf + SslipHalf = P.wing.S/2` exactly in the covered case.
- Both areas remain nonnegative and bounded by the half-wing area.
- The local velocity construction uses `Vbody + cross(omegaBody,rAC)` with
  current-CG-relative `rAC`.
- Slipstream is applied only to slipstream regions.
- Under helicopter hover-like conditions, `rotor.eT=[0;0;-1]` and positive
  induced velocity make the wing local velocity point toward `-z`. Because the
  model's velocity variable is aircraft-relative-to-air, this corresponds to
  downward rotor wake in physical air velocity. The resulting near-normal drag
  force is `+z` body-axis, i.e. downward on the wing. This is internally
  consistent for the current convention.
- Positive aileron gives positive rolling-moment increment in the checked
  small-signal case. Sign reversal is locally mirrored. Larger finite inputs
  are not expected to be perfectly odd because lift saturation is nonlinear.
- Near-normal and lift-line branches are blended by the existing quintic
  smootherstep, with finite monotonic weights and consistent
  `M = Marm + Maero` diagnostics in the checked points.

## Fuselage Conclusions

- Drag coefficient is nonnegative in the checked representative condition.
- Force/moment decomposition satisfies `M = cross(rAC,F) + Maero`.
- Positive `p`, `q`, and `r` produce negative increments in the corresponding
  aerodynamic damping moments from `Clp`, `Cmq`, and `Cnr`, opposing the
  positive body rates.
- Normalized-rate and output diagnostics remain finite for the covered
  condition.

## Horizontal-Tail Conclusions

- Positive forward-flight alpha gives positive `alphaCG`.
- The implemented downwash law reduces effective tail angle of attack:

```matlab
alphaEff = alphaLocal - P.htail.downwashAlpha*alphaCG + incidence
```

- Positive elevator increases tail `CL`, makes tail `Fz` more negative
  (upward lift in body axes), and gives a more negative pitch-moment response
  under the current sign convention.
- Force/moment decomposition satisfies `M = cross(rAC,F) + Maero`.
- The `alphaCG = atan2(w,max(abs(u),1e-8))` expression is robust in the covered
  forward-flow case but remains a reverse-flow limitation: it removes the sign
  of `u` from the denominator and should not be used to claim validated
  reverse-flow tail behavior.

## Vertical-Tail Conclusions

- Twin-fin summation is symmetric at zero beta/rudder in the checked condition.
- Positive sideslip produces negative lateral force and positive yaw-moment
  increment under the current convention.
- Positive rudder produces positive lateral-force increment and negative
  yaw-moment increment.
- Rudder sign reversal is odd in the lateral, roll, and yaw response axes.
  Axial drag and drag-induced pitch components may contain even increments
  because the current model uses `CD = CD0 + 0.02*CY^2`.

## Parameter Provenance

Repository comments and existing documents are the only provenance accepted in
this phase. No new source values were taken from PDFs.

|Parameter group|Code variable(s)|Classification|Notes|
|-|-|-|-|
|Wing geometry|`P.wing.S`, `b`, `c`, `xAC`, `yFreeAC`, `ySlipAC`, `zAC`|`ASSUMED_CONCEPT`|Concept geometry in `params_nominal`; not XV-15 verified.|
|Wing linear coefficients|`CL0`, `CLalpha`, `CD0`, `kInduced`, `CYbeta`, `Cm0`, `Cmalpha`, `CLaileron`, `Cmaileron`|`ASSUMED_CONCEPT` / `REFERENCE_PENDING`|No page/table/unit mapping verified in this phase.|
|Wing saturation|`CLmax`, `CDnormal`|`ASSUMED_CONCEPT`|Concept saturation and normal-force parameters.|
|Wing slipstream area factors|`SslipMaxHalf`, `muMax`, `muFactor`, `orientationFactor`|`ASSUMED_CONCEPT`|Current heuristic interaction model.|
|Rotor wake coupling to wing|`P.rotor.wakeFactor`|`ASSUMED_CONCEPT`|Finite nonnegative induced velocity multiplier; no sourced validation.|
|Wing normal-flow blend|`normalFlowRatio`, `normalFlowBlendHalfWidth`|`ASSUMED_CONCEPT` / `NUMERICAL`|Code-only smoother to avoid artificial load jumps.|
|Fuselage geometry|`P.fuselage.S`, `b`, `c`, `rAC`|`ASSUMED_CONCEPT`|Concept fuselage reference geometry.|
|Fuselage coefficients|`CD0`, `CDalpha2`, `CDbeta2`, `CLalpha`, `CYbeta`, `Cl*`, `Cm*`, `Cn*`|`ASSUMED_CONCEPT` / `REFERENCE_PENDING`|Signs are internally checked; source mapping remains pending.|
|Horizontal-tail geometry|`P.htail.S`, `c`, `rAC`, `incidence`|`ASSUMED_CONCEPT`|Concept tail geometry and incidence.|
|Horizontal-tail downwash|`P.htail.downwashAlpha`|`ASSUMED_CONCEPT`|Simple linear downwash factor.|
|Horizontal-tail coefficients|`CL0`, `CLalpha`, `CLmax`, `CLelevator`, `CD0`, `kInduced`, `Cm0`, `Cmelevator`|`ASSUMED_CONCEPT` / `REFERENCE_PENDING`|No original literature trace completed here.|
|Vertical-tail geometry|`P.vtail.SEach`, `c`, `xAC`, `yAC`, `zAC`|`ASSUMED_CONCEPT`|Concept twin-fin geometry.|
|Vertical-tail coefficients|`CD0`, `CYbeta`, `CYrudder`, `0.02*CY^2` drag increment|`ASSUMED_CONCEPT` / `REFERENCE_PENDING`|The `0.02` induced-drag-like term is code-only in this phase.|
|Dynamic pressure and moment arms|`qbar`, `cross(rAC,F)` diagnostics|`DERIVED`|Derived from current state, geometry, and existing equations.|
|Small velocity thresholds and test tolerances|`1e-8`, test tolerances|`NUMERICAL`|Numerical robustness and audit thresholds.|

No `DOCUMENTED_SOURCE` classification is assigned because no PDF page, table,
figure, unit, or configuration was newly verified in this phase.

## Findings

|Severity|Category|Finding|Action|
|-|-|-|-|
|INFO|Internal consistency|No `CRITICAL`, `HIGH`, or `MEDIUM` non-rotor production force/sign bug was found in the covered canonical cases.|Keep current equations unchanged.|
|INFO|Slipstream convention|The wing slipstream sign is internally consistent with the model's aircraft-relative-to-air velocity convention, but this is not a validation of rotor/wing interference physics.|Future work needs sourced or higher-fidelity interaction data.|
|INFO|Downwash convention|Horizontal-tail downwash reduces positive forward-flight alpha as implemented.|Reverse-flow behavior remains outside validated scope.|
|INFO|Control signs|Aileron, elevator, rudder, and vertical-tail sideslip responses have internally consistent signs in the covered small-signal cases.|Do not infer aircraft-level handling-quality validation.|
|INFO|Rate damping|Fuselage `p/q/r` damping signs oppose positive body rates in the checked condition.|Source and applicability of derivative values remain pending.|
|INFO|Parameter provenance|Aerodynamic geometry, derivatives, interaction factors, and saturation limits remain conceptual assumptions or reference-pending parameters.|Do not describe them as measured XV-15 data.|
|LOW|Test interpretation|Finite-amplitude aileron and rudder mirror checks must account for nonlinear lift saturation and even drag terms from `CY^2`.|Tests use small-signal or axis-specific checks accordingly.|

## Unsupported Regimes

- Reverse-flow horizontal-tail behavior.
- Dense alpha/beta/nacelle-angle sweeps.
- Full trim, continuation, or flight-envelope conclusions.
- Validated rotor/wing interference, nonuniform wake, dynamic stall, ground
  effect, or lookup-table aerodynamics.
- XV-15 fidelity claims.

## Parameter And Interface Status

- Production parameter values changed: no.
- `params_nominal.m` numeric values changed: no.
- Aerodynamic derivatives tuned: no.
- Slipstream, downwash, coordinate transform, force, or moment equations
  changed: no.
- Public function input/output signatures changed: no.
- Diagnostic fields added: yes.
