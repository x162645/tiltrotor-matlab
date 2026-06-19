# CODEX_TASK.md

STATUS: ACTIVE

Branch: `audit/rotor-force-moment-chain`

Base branch: `main`

Current phase: rotor model and force/moment call-chain audit.

## Goal

Verify that the current conceptual rotor and load-assembly implementation is internally correct in coordinates, signs, units, moment references, control mapping, convergence handling, and diagnostics. Exact XV-15 identification is outside this phase.

This phase must preserve all production parameters and must not redesign the rotor model. Clear program bugs may be fixed only after a focused reproduction and with a minimal patch.

## Primary files

Read first:

- `AGENTS.md`
- `CODEX_TASK.md`
- `params_nominal.m`
- `model/rotor_model_bemt.m`
- `model/total_forces_moments.m`
- `model/mass_properties.m`
- `model/tiltrotor_eom.m`
- `tests/check_control_architecture.m`
- `tests/check_flapping_model.m`
- `tests/run_all_checks.m`
- `docs/CONTROL_CONVENTIONS.md`
- `docs/PHYSICS_AND_CODE_AUDIT.md`

Search every caller of:

```text
rotor_model_bemt
total_forces_moments
out.rotorLeft
out.rotorRight
appliedRotorControls
```

## Audit questions

### Rotor basis and geometry

- Confirm `eT`, `eD`, and `eY` definitions at `betaM = 0`, `pi/4`, and `pi/2`.
- Verify unit length, mutual orthogonality, sign conventions, and the documented thrust direction.
- Verify `rHub0`, `rHub`, `cgShift`, and `Vhub = Vbody + cross(omegaBody,rHub)` use one reference point and one body-axis convention.
- Check that left/right hub positions are mirror images about the x-z plane.

### Blade-element kinematics and loads

- Check azimuth and rotation-direction definitions.
- Check `UT`, `UP`, `Vrad`, `betaDot`, `betaDDot`, cyclic-pitch phase, twist, inflow angle, angle of attack, lift, drag, thrust, in-plane force, and torque signs.
- Confirm dimensions and MATLAB implicit-expansion shapes for every blade-element array.
- Inspect the use of `abs(UT)` in the inflow-angle denominator. Treat reverse-flow behavior as an applicability issue unless a current covered case actually reaches negative `UT`.
- Inspect the clipping of negative thrust in the induced-velocity update. Record the unsupported windmill/reverse-thrust regime; do not redesign it in this phase.

### Flapping and induced-velocity solve

- Verify residual scaling, Jacobian construction, line search, convergence criteria, and error paths.
- Confirm that a failed flap or coupled solve cannot silently return apparently valid loads.
- Check first-harmonic hover symmetry and left/right phase reversal.

### Forces and moments

- Verify:

```matlab
Fbody = loads.T*nDisk + loads.Hlong*eD + loads.Hlat*eY
Mbody = cross(rHub,Fbody) + Mreaction + Mgyro
```

- Confirm reaction-torque and gyroscopic-moment signs.
- Confirm `total_forces_moments` sums each component exactly once and does not double-count arm moments.
- Confirm gravity is added only in `tiltrotor_eom.m`.
- Confirm output diagnostics correspond to the actual values used in the equations.

## Allowed changes

Production behavior should remain unchanged during the first pass.

Allowed without further approval:

- create `docs/ROTOR_FORCE_MOMENT_AUDIT.md`;
- create `tests/check_rotor_force_moment_chain.m`;
- add diagnostic output fields to `rotor_model_bemt.m` only when they expose already-computed quantities and do not change forces, moments, iteration, or parameters;
- update `tests/run_all_checks.m` only to include the new lightweight check;
- update `CODEX_TASK.md` and the audit document.

Examples of acceptable diagnostic fields:

```text
Marm
Mreaction
Mgyro
Hrot
basisOrthogonalityError
minUT
maxUT
maxAbsAlphaBlade
```

Do not add diagnostics that require a second BEMT solve.

Forbidden in this phase:

- changing `params_nominal.m` values;
- replacing the flapping formulation;
- adding lateral cyclic;
- adding non-uniform inflow;
- adding reverse-flow or windmill-brake physics;
- changing coordinate conventions;
- changing trim or linearization algorithms;
- broad speed sweeps, Monte Carlo, large multi-start studies, or point-by-point Jacobian scans.

If a clear production-code bug is found, document the exact failing case first. Stop and report before changing a force, moment, sign, or solver equation unless the fix is purely diagnostic.

## Required focused tests

Create a lightweight `check_rotor_force_moment_chain` report with named PASS/FAIL cases. Use only a small number of representative calls.

At minimum cover:

1. rotor basis unit length and orthogonality at three nacelle angles;
2. left/right hub mirror geometry;
3. hub local-velocity identity;
4. exact rotor moment decomposition;
5. exact total component force/moment summation;
6. symmetric-hover force and reaction-torque cancellation relations;
7. differential-collective mirror/sign relations;
8. common collective produces monotonic thrust and finite torque over three interior commands;
9. `Jpolar = 0` gives zero gyroscopic moment;
10. a synthetic nonzero `Jpolar` case matches `-cross(omegaBody,Hrot)` without changing nominal parameters;
11. finite real outputs and convergence flags at one helicopter, one transition, and one airplane-mode representative condition;
12. report minimum `UT` for those cases and issue an informational applicability finding if reverse flow is approached or reached.

Do not encode exact XV-15 values. Use broad internal identities and symmetry relations.

## Runtime control

Before running, estimate the number of `total_forces_moments` or `rotor_model_bemt` calls. Keep the first run below roughly 30 model evaluations.

Run in this order:

```text
single target check -> existing focused rotor checks -> full lightweight suite
```

Suggested commands:

```powershell
& 'F:\matlab\R2021a\bin\matlab.exe' -batch "cd('E:\tiltrotor'); run('startup.m'); r = check_rotor_force_moment_chain; disp(r); assert(r.allPassed);"
```

Then, only after the target check passes:

```powershell
& 'F:\matlab\R2021a\bin\matlab.exe' -batch "cd('E:\tiltrotor'); run('startup.m'); r = check_flapping_model; disp(r); assert(r.allPassed);"
```

Finally run `run_all_checks` once if the estimated runtime remains reasonable.

Record any MATLAB R2021a shutdown-stage `output stream error` separately from test-body results.

## Deliverables

- `docs/ROTOR_FORCE_MOMENT_AUDIT.md` with findings classified as `CRITICAL`, `HIGH`, `MEDIUM`, `LOW`, or `INFO`;
- focused test report and actual MATLAB output summary;
- exact count of representative model calls;
- list of modified files;
- explicit statement on parameter changes;
- any unsupported operating regimes found;
- commit SHA and clean working-tree status.

Commit and push to `audit/rotor-force-moment-chain`.

Do not merge the PR and do not begin trim-envelope work after completion.
