# CODEX_TASK.md

STATUS: COMPLETE / HOLD

Branch: `audit/mass-inertia-cg-geometry`

Base branch: `main`

Current phase: mass, inertia, CG-shift, and component-geometry audit.

## Completed scope

- mass/inertia/CG/geometry audit completed;
- `check_mass_inertia_geometry`: 12/12 PASS;
- `check_physical_sanity`: 7/7 PASS;
- `run_all_checks`: 12/12 PASS;
- numeric parameters unchanged;
- `mNac` interpreted as combined left/right moving mass;
- `RH` dual-use recorded as MEDIUM conceptual parameter coupling;
- no CRITICAL/HIGH/MEDIUM production-code bug found;
- Draft PR #3 awaits final review and user authorization;
- do not merge PR #3;
- do not begin aerodynamic-component or trim-envelope work.

## Goal

Verify that the current conceptual mass-property and geometry chain is internally correct, dimensionally consistent, physically plausible at broad scale, continuous across nacelle tilt, and used consistently by every component model.

Exact XV-15 identification is outside this phase. Preserve all production parameter values during the first pass. Do not tune parameters to make checks pass.

## Read first

- `AGENTS.md`
- `CODEX_TASK.md`
- `params_nominal.m`
- `model/mass_properties.m`
- `model/rotor_model_bemt.m`
- `model/total_forces_moments.m`
- `model/wing_model.m`
- `model/fuselage_model.m`
- `model/horizontal_tail_model.m`
- `model/vertical_tail_model.m`
- `model/tiltrotor_eom.m`
- `tests/check_physical_sanity.m`
- `tests/check_rotor_force_moment_chain.m`
- `tests/run_all_checks.m`
- `docs/PHYSICS_AND_CODE_AUDIT.md`
- `docs/ROTOR_FORCE_MOMENT_AUDIT.md`

Search all uses of:

```text
P.mass
cgShift
mass_properties
pivotX
pivotY
pivotZ
xAC
yAC
zAC
rAC
RH
I0
KI
```

## Audit questions

### Mass and CG semantics

- Confirm the meaning of `P.mass.m`, `P.mass.mNac`, and `P.mass.RH`.
- Determine whether `mNac` is interpreted consistently as total moving nacelle/rotor mass or per-side mass.
- Verify the endpoint and sign of:

```matlab
dx = mNac*RH*sin(betaM)/m
dz = mNac*RH*(1-cos(betaM))/m
```

- Check `betaM = 0`, `pi/4`, and `pi/2`, including zero shift at helicopter mode and finite forward/down shift at airplane mode under body axes x-forward, y-right, z-down.
- Check continuity and finite derivatives across the supported tilt range.
- Confirm every component position is referenced to the same current CG and that `cgShift` is subtracted exactly once.

### Inertia model

- Verify `I0`, `KI`, and `I(betaM) = I0 - betaM*KI` units and code semantics.
- Confirm symmetry and positive definiteness at representative tilt angles.
- Compute principal moments and radii of gyration over the three representative tilt angles.
- Identify the linear-in-angle inertia law as an assumed low-order model unless a source is already documented.
- Check that no code treats `KI` as per-degree.
- Inspect the omission of tilt-dependent cross-inertia changes and classify it as a model limitation when appropriate; do not redesign the inertia law in this phase.

### Geometry consistency

- Check left/right mirror symmetry of rotor hubs and twin vertical tails.
- Check rotor-center separation, disk overlap clearance, rotor radius, wing semispan, and pivot location relationships.
- Check that tail aerodynamic centers are aft of the reference CG under the body-axis convention.
- Check broad ordering and scale of wing, fuselage, horizontal-tail, and vertical-tail reference locations.
- Confirm each component's moment arm uses its current-CG-relative position exactly once.

### Parameter provenance

Create a table for the mass and geometry parameters classifying each as:

```text
DERIVED
ASSUMED_CONCEPT
DOCUMENTED_SOURCE
REFERENCE_PENDING
NUMERICAL
```

Do not invent a source. Existing comments and repository documents are the only accepted provenance in this phase.

## Allowed changes

Allowed without further approval:

- create `docs/MASS_INERTIA_GEOMETRY_AUDIT.md`;
- create `tests/check_mass_inertia_geometry.m`;
- add diagnostics to `mass_properties.m` only when they expose already-computed quantities and do not alter `cgShift`, `I`, or `mass`;
- add diagnostics to component outputs only when they expose already-used current-CG-relative position vectors without changing forces or moments;
- update `tests/run_all_checks.m` to include the new lightweight check;
- clarify comments or parameter semantics without changing numeric values;
- update this task file.

Potential diagnostic fields include:

```text
principalMoments
radiusOfGyration
betaM
inertiaSymmetryError
minInertiaEigenvalue
```

Forbidden:

- changing any numeric value in `params_nominal.m`;
- replacing the linear inertia law;
- adding new moving masses or a detailed mass build-up;
- changing component force or moment equations;
- changing coordinates or sign conventions;
- broad tilt sweeps, speed sweeps, Monte Carlo, optimization, or multi-start runs;
- claiming XV-15 fidelity.

If a clear production-code bug is found, document a focused failing case and stop before changing mass, inertia, CG, geometry, force, or moment behavior.

## Required lightweight checks

Create `check_mass_inertia_geometry` with named PASS/FAIL cases. Keep the first run small and deterministic.

At minimum cover:

1. mass is positive and invariant with tilt;
2. CG shift endpoint identities at `0`, `pi/4`, and `pi/2`;
3. CG shift continuity and finite central-difference derivatives at one interior angle;
4. inertia symmetry and positive definiteness at three tilt angles;
5. principal moments and radii of gyration finite and broadly plausible;
6. `KI` is interpreted per radian and the implemented endpoint change matches `betaM*KI`;
7. left/right rotor-hub mirror geometry;
8. rotor disk non-overlap and positive centerline clearance;
9. rotor hubs, wing semispan, and nacelle pivot broad geometry relation;
10. tail locations are aft of the current CG at representative tilt angles;
11. component current-CG-relative position identity for every component that exposes a position diagnostic;
12. repeated calls are deterministic and outputs are finite real values.

Use only `betaM = 0`, `pi/4`, `pi/2`, plus one small central-difference pair around `pi/4`. Avoid a dense tilt scan.

## Runtime order

Run:

```text
new target check -> existing physical sanity check -> run_all_checks once
```

Suggested target command:

```powershell
& 'F:\matlab\R2021a\bin\matlab.exe' -batch "cd('E:\tiltrotor'); run('startup.m'); r = check_mass_inertia_geometry; disp(r); assert(r.allPassed);"
```

Then run `check_physical_sanity`. Run `run_all_checks` once only after both focused checks pass.

Record the MATLAB R2021a shutdown-stage `output stream error` separately from test-body results.

## Deliverables

- `docs/MASS_INERTIA_GEOMETRY_AUDIT.md`;
- focused test results and actual MATLAB output summary;
- parameter provenance/classification table;
- explicit interpretation of `mNac` and `RH`;
- list of assumptions and unsupported claims;
- exact modified files;
- explicit statement that numeric parameters changed or did not change;
- commit SHA and clean working-tree status.

Commit and push to `audit/mass-inertia-cg-geometry`.

Do not merge the PR and do not begin aerodynamic-component or trim-envelope work after completion.
