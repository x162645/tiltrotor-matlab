# CODEX_TASK.md

STATUS: COMPLETE / HOLD

Branch: `audit/aero-components`

Base branch: `main`

Current phase: wing, fuselage, horizontal-tail, vertical-tail, and aerodynamic force-transform audit.

## Completed scope

- aerodynamic component audit completed;
- `check_aerodynamic_components`: 10/10 PASS;
- `check_wing_normal_flow_blend`: PASS;
- `check_control_architecture`: PASS;
- `run_all_checks`: 13/13 PASS;
- focused top-level call count: 29;
- numeric parameters unchanged;
- aerodynamic derivatives unchanged;
- slipstream, downwash, transform, force, and moment equations unchanged;
- slipstream direction, downwash sign, control-effectiveness signs, and fuselage rate damping verified as internally consistent in covered canonical cases;
- no CRITICAL/HIGH/MEDIUM production-code bug found;
- LOW test-interpretation limitation recorded for finite-amplitude aileron/rudder mirror checks;
- Draft PR #4 awaits final review and user authorization;
- do not merge PR #4;
- do not begin trim-equation, continuation, or flight-envelope work.

## Goal

Verify that the non-rotor aerodynamic component chain is internally correct in coordinate transforms, force and moment signs, local-flow construction, control-effectiveness signs, damping behavior, slipstream coupling, branch continuity, symmetry, units, and diagnostics.

This is an internal-consistency and broad-physics audit for the current conceptual model. Exact XV-15 identification remains outside this phase. Preserve all production parameter values during the first pass and do not tune coefficients to make tests pass.

## Read first

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

Search all callers and uses of:

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

## Audit questions

### Aerodynamic force transform

- Verify the wind-axis basis used by `aero_force_body` is unit length, mutually orthogonal, right-handed, and consistent with body axes x-forward, y-right, z-down.
- Verify canonical cases at zero angle, positive angle of attack, positive sideslip, pure drag, pure side force, and pure lift.
- Confirm positive drag opposes the local velocity representation used by each component.
- Confirm lift and side-force directions are perpendicular to the wind-axis velocity direction.
- Confirm the transform is deterministic and finite near small velocity and moderate angles.

### Wing model

- Verify `SfreeHalf + SslipHalf = S/2`, nonnegative areas, and left/right region symmetry.
- Verify local velocity uses `Vbody + cross(omega,rAC)` with current-CG-relative arms.
- Verify the meaning of the velocity variable in slipstream and whether `Vlocal += wakeVelocity*rotor.eT` has the correct sign under the model’s relative-air convention. Do not assume the answer; reproduce canonical hover and forward-flight cases and inspect force direction.
- Verify wake velocity is applied only to slipstream regions and remains finite and nonnegative.
- Verify the near-normal and lift-line branch outputs, smootherstep weight, first derivative continuity, and region diagnostics.
- Verify aileron antisymmetry, rolling-moment sign, and left/right load exchange under sign reversal.
- Verify lift saturation and induced-drag formulas remain finite and broadly monotonic over a small interior range.
- Classify `muFactor`, `orientationFactor`, `SslipMaxHalf`, `wakeFactor`, `normalFlowRatio`, and blend width as model assumptions unless already sourced in repository documents.

### Fuselage model

- Verify drag coefficient is nonnegative and even in alpha/beta contributions.
- Verify `CLalpha`, `CYbeta`, and static moment derivative signs under the documented convention.
- Verify positive p, q, and r produce damping contributions from `Clp`, `Cmq`, and `Cnr` in the expected opposing directions.
- Verify force/moment decomposition exactly matches `cross(rAC,Fbody) + Maero`.
- Verify zero/small-speed behavior and finite normalized-rate calculations.

### Horizontal tail

- Verify local alpha, CG alpha, downwash, incidence, elevator contribution, lift saturation, drag, and pitching-moment decomposition.
- Inspect `alphaCG = atan2(w,max(abs(u),...))`; record reverse-flow limitations and confirm it does not create a covered-case sign inconsistency.
- Verify elevator sign and resulting tail-force/pitch-moment response using the repository’s control convention.
- Verify downwash reduces effective angle of attack for a positive forward-flight alpha under the implemented sign convention.

### Vertical tails

- Verify twin-fin left/right mirror symmetry and summation.
- Verify sideslip and rudder responses, drag increase, side-force direction, and resulting yaw/roll moments.
- Verify rudder sign reversal produces the expected odd response and symmetric fins do not introduce unintended even lateral loads at zero sideslip/rudder.

### Parameter provenance and applicability

Create a table classifying aerodynamic geometry, coefficients, interaction factors, saturation limits, and numerical thresholds as:

```text
DERIVED
ASSUMED_CONCEPT
DOCUMENTED_SOURCE
REFERENCE_PENDING
NUMERICAL
```

Do not invent sources. Repository comments and existing documents are the only accepted provenance in this phase.

## Allowed changes

Allowed without further approval:

- create `docs/AERODYNAMIC_COMPONENTS_AUDIT.md`;
- create `tests/check_aerodynamic_components.m`;
- add diagnostic fields that expose already-computed values and do not alter forces, moments, controls, parameters, or branch logic;
- update `tests/run_all_checks.m` to include the new lightweight check;
- clarify comments and parameter semantics without changing numeric values;
- update this task file.

Potential diagnostics include:

```text
qbar
Maero
Marm
windBasisOrthogonalityError
forcePowerDot
SfreeHalf
SslipHalf
```

Do not add diagnostics that require a second component or rotor solve.

Forbidden:

- changing any numeric value in `params_nominal.m`;
- tuning aerodynamic derivatives;
- replacing the wing branch model;
- changing slipstream, downwash, force-transform, force, or moment equations before a focused failing case is documented and reviewed;
- adding lookup tables, dynamic stall, nonuniform wake, ground effect, or interference models;
- changing coordinate or control conventions;
- broad speed/angle sweeps, Monte Carlo, optimization, multi-start, or full trim-envelope work;
- claiming XV-15 fidelity.

If a possible force/sign/interaction production bug is found, document the exact canonical failing case and stop before changing the equation. Purely diagnostic changes may continue.

## Required lightweight checks

Create `check_aerodynamic_components` with named PASS/FAIL cases. Keep the initial run deterministic and below roughly 30 total component/model evaluations.

At minimum cover:

1. aerodynamic wind basis orthonormality and canonical force directions;
2. positive drag opposes the component local-velocity representation;
3. wing area partition bounds and exact half-area identity;
4. wing left/right symmetry at zero lateral input;
5. aileron sign-reversal mirror relation and rolling response;
6. near-normal blend continuity and diagnostic consistency;
7. slipstream applied only to slip regions and canonical hover wake/force-direction check;
8. fuselage force/moment decomposition and nonnegative drag;
9. fuselage p/q/r damping derivative sign checks;
10. horizontal-tail downwash and elevator response identities;
11. twin-vertical-tail symmetry, sideslip response, and rudder sign reversal;
12. finite real deterministic outputs at one hover-like, one transition, and one airplane-mode representative condition.

Use a small set of canonical direct component calls. Reuse cached rotor/total-model results where rotor diagnostics are needed. Do not use dense alpha, beta, speed, or nacelle-angle sweeps.

## Runtime order

Run in this order:

```text
new target check -> existing wing blend/control checks -> run_all_checks once
```

Suggested target command:

```powershell
& 'F:\matlab\R2021a\bin\matlab.exe' -batch "cd('E:\tiltrotor'); run('startup.m'); r = check_aerodynamic_components; disp(r); assert(r.allPassed);"
```

Then run the existing wing normal-flow blend check and control-architecture check. Run `run_all_checks` once only after the focused checks pass.

Record the MATLAB R2021a shutdown-stage `output stream error` separately from test-body results.

## Deliverables

- `docs/AERODYNAMIC_COMPONENTS_AUDIT.md` with findings classified as `CRITICAL`, `HIGH`, `MEDIUM`, `LOW`, or `INFO`;
- focused test results and actual MATLAB output summary;
- exact component/model call count;
- aerodynamic parameter provenance table;
- explicit conclusion on slipstream direction, downwash sign, control-effectiveness signs, and rate damping;
- unsupported operating regimes and model assumptions;
- exact modified files;
- explicit statement that numeric parameters changed or did not change;
- commit SHA and clean working-tree status.

Commit and push to `audit/aero-components`.

Do not merge the PR and do not begin trim-equation, continuation, or flight-envelope work after completion.
