# Rotor Force/Moment Chain Audit

Branch: `audit/rotor-force-moment-chain`

Scope: static audit plus lightweight internal consistency tests for
`rotor_model_bemt`, `total_forces_moments`, `mass_properties`, and
`tiltrotor_eom`. This audit does not validate XV-15 data and does not change
production parameters.

## Files Reviewed

- `AGENTS.md`
- `CODEX_TASK.md`
- `params_nominal.m`
- `model/rotor_model_bemt.m`
- `model/total_forces_moments.m`
- `model/mass_properties.m`
- `model/tiltrotor_eom.m`
- `model/wing_model.m`
- `model/fuselage_model.m`
- `model/horizontal_tail_model.m`
- `model/vertical_tail_model.m`
- `model/aero_force_body.m`
- `model/validate_inputs.m`
- `tests/check_control_architecture.m`
- `tests/check_flapping_model.m`
- `tests/run_all_checks.m`
- `docs/CONTROL_CONVENTIONS.md`
- `docs/PHYSICS_AND_CODE_AUDIT.md`

Caller search covered:

```text
rotor_model_bemt
total_forces_moments
out.rotorLeft
out.rotorRight
appliedRotorControls
```

## Static Audit Summary

### Rotor Basis And Geometry

The current rotor basis is:

```matlab
eT = [sin(betaM); 0; -cos(betaM)];
eD = [cos(betaM); 0;  sin(betaM)];
eY = [0; 1; 0];
```

At `betaM=0`, thrust is body-up (`[0;0;-1]`). At `betaM=pi/2`, thrust is
body-forward (`[1;0;0]`). At `betaM=pi/4`, thrust is forward/up at equal
magnitude components. The basis vectors are unit length and mutually
orthogonal for the checked angles.

The hub position is formed from the nacelle pivot and then shifted to the
current CG reference:

```matlab
rHub = rHub0 - cgShift
Vhub = Vbody + cross(omegaBody, rHub)
```

Left and right hub positions remain mirror images about the body x-z plane for
the checked nacelle angles.

### Rotor Loads And Moment Reference

The code path uses:

```matlab
Fbody = loads.T*nDisk + loads.Hlong*eD + loads.Hlat*eY
Marm = cross(rHub,Fbody)
Mreaction = -rotDir*loads.Q*eT
Hrot = rotDir*P.rotor.Jpolar*P.rotor.Omega*eT
Mgyro = -cross(omegaBody,Hrot)
Mbody = Marm + Mreaction + Mgyro
```

The audit adds diagnostic output fields for the already-computed terms above.
No force, moment, solver, control, or parameter behavior is changed.

### Total Force/Moment Assembly

`total_forces_moments` calls each component once, stores each component force
and moment in `info.components`, and sums:

```matlab
Ftotal = FrotL + FrotR + Fwing + Ffus + Fht + Fvt
Mtotal = MrotL + MrotR + Mwing + Mfus + Mht + Mvt
```

Each component model returns a moment already referenced to the current CG via
its local `cross(r,F)` term plus any local aerodynamic or propulsion moment.
No second arm moment is added in `total_forces_moments`.

Gravity is not included in `total_forces_moments`; it is added only in
`tiltrotor_eom`.

## Lightweight Test Coverage

New test entry:

```matlab
r = check_rotor_force_moment_chain;
```

The focused test covers:

1. rotor basis unit length and orthogonality at `0`, `pi/4`, and `pi/2`;
2. left/right hub mirror geometry;
3. hub local-velocity identity;
4. exact rotor force and moment decomposition;
5. exact total component force/moment summation;
6. symmetric-hover force and reaction-torque cancellation;
7. differential-collective mirror/sign relations;
8. common collective monotonic thrust and finite torque over three commands;
9. `Jpolar=0` gyroscopic moment shutdown;
10. synthetic local `Jpolar` gyroscopic identity;
11. finite real outputs and convergence flags for helicopter, transition, and
    airplane representative conditions;
12. representative minimum `UT` recording.

Initial focused run estimate: 8 `total_forces_moments` calls and 16
`rotor_model_bemt` calls. This stays below the requested lightweight first-pass
budget and avoids broad speed sweeps, Monte Carlo, multi-start studies, and
point-by-point Jacobian scans.

Actual focused run result:

```text
check_rotor_force_moment_chain: 12/12 PASS
Model calls: total_forces_moments=8, rotor_model_bemt=16
hover:      betaM=0        minUT=5.045767e+01, maxUT=2.275503e+02
transition: betaM=pi/4     minUT=3.518750e+01, maxUT=2.428205e+02
airplane:   betaM=pi/2     minUT=4.930710e+01, maxUT=2.287009e+02
```

Existing focused rotor check:

```text
check_flapping_model: 14/14 PASS
```

Full lightweight suite:

```text
run_all_checks: 11/11 PASS
```

MATLAB R2021a produced a shutdown-stage `output stream error` after each
successful test-body run. The failure occurred after the PASS summaries and is
recorded separately from model/test assertions.

## Findings

|Severity|Category|Finding|Action|
|-|-|-|-|
|INFO|Temporarily allowed engineering simplification|The representative test records blade-element `minUT` and `maxUT`. Reverse-flow and windmill-brake regimes remain outside the current model applicability because `phiInflow` uses `atan2(UP,max(abs(UT),...))` and the induced-velocity update clips negative thrust for the momentum target.|Do not redesign in this phase. Revisit only when reverse-flow or windmill-brake physics are explicitly in scope.|
|INFO|Diagnostics|`rotor_model_bemt` now exposes `Marm`, `Mreaction`, `Mgyro`, `Hrot`, basis orthogonality error, `minUT`, `maxUT`, and maximum blade angle of attack as diagnostics.|Use these fields for audits and tests only; they do not change production behavior.|
|INFO|Model verification boundary|Passing tests prove internal identities for the covered conceptual cases only. They do not prove XV-15 fidelity or literature agreement.|Keep model claims limited to internal consistency until external data are traced and validated.|

No `CRITICAL`, `HIGH`, or `MEDIUM` force/moment/sign production-code bug was
identified in the covered static and lightweight test scope.

## Parameter And Interface Status

- Production parameter values changed: no.
- Rotor physical model redesigned: no.
- Control architecture changed: no.
- Public function input/output signatures changed: no.
- Added diagnostic fields in `rotor_model_bemt` output: yes.
