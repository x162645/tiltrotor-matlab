# Mass, Inertia, CG, And Geometry Audit

Branch: `audit/mass-inertia-cg-geometry`

Scope: static audit plus lightweight consistency checks for the conceptual
mass-property, CG-shift, inertia, and component-geometry chain. This audit
does not validate XV-15 data and does not change any production parameter
value.

## Files Reviewed

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

Search covered:

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

## Mass And CG Semantics

Current interpretation:

- `P.mass.m`: total aircraft mass used by translational dynamics.
- `P.mass.mNac`: total moving mass for the left and right nacelle/rotor tilt
  assemblies combined. It is not interpreted as per-side mass in the current
  CG-shift formula.
- `P.mass.RH`: equivalent distance from the nacelle tilt axis to the moving
  mass center. The same scalar is also used in the current rotor hub tilt
  geometry.

The implemented CG shift is:

```matlab
dx = P.mass.mNac * P.mass.RH * sin(betaM) / P.mass.m;
dz = P.mass.mNac * P.mass.RH * (1 - cos(betaM)) / P.mass.m;
mp.cgShift = [dx; 0; dz];
```

Under the body-axis convention used by the model (`x` forward, `y` right, `z`
down), this gives zero shift at `betaM=0` and a finite forward/down shift at
`betaM=pi/2`.

For the current values, the `betaM=pi/2` endpoint shift is:

```text
dx = dz = 900 * 0.75 / 6000 = 0.1125 m
```

This follows the repository's existing conceptual interpretation in
`docs/PHYSICS_AND_CODE_AUDIT.md`; it is not treated as verified aircraft
measurement data.

## Inertia Semantics

The implemented law is:

```matlab
I = P.mass.I0 - betaM * P.mass.KI;
I = 0.5*(I + I.');
```

`P.mass.KI` is interpreted per radian. The code search found no use that treats
`KI` as per degree. The linear-in-tilt law is a low-order conceptual model. The
current model does not include a detailed mass build-up or tilt-dependent
cross-inertia update beyond the terms already present in `I0` and `KI`.

This audit adds derived diagnostics to `mass_properties`:

```text
betaM
principalMoments
radiusOfGyration
inertiaSymmetryError
minInertiaEigenvalue
```

These diagnostics expose values derived from the existing `I` matrix and do not
alter `cgShift`, `I`, or `mass`.

## Geometry Chain

All audited component moment arms are current-CG-relative:

- rotor hubs: `rHub = rHub0 - cgShift`;
- wing free/slipstream regions: `rAC = rAC0 - cgShift`;
- fuselage: `rAC = P.fuselage.rAC - cgShift`;
- horizontal tail: `rAC = P.htail.rAC - cgShift`;
- twin vertical tails: `rAC = rAC0 - cgShift`.

The aggregate force/moment assembly receives component moments that already
include the component `cross(r,F)` arm term. `total_forces_moments` sums these
moments directly and does not add another geometry arm.

Broad geometry checks cover:

- left/right rotor hub mirror symmetry;
- twin vertical tail mirror symmetry through per-side `rAC`;
- positive rotor disk clearance from `2*pivotY - 2*R`;
- wing semispan and nacelle pivot relationship;
- aft horizontal and vertical tail locations after current CG shift.

## Parameter Provenance

|Parameter|Code variable|Classification|Notes|
|-|-|-|-|
|Total mass|`P.mass.m`|`ASSUMED_CONCEPT`|Concept-scale mass in `params_nominal`; not identified as XV-15 measured data.|
|Moving nacelle/rotor mass total|`P.mass.mNac`|`ASSUMED_CONCEPT`|Interpreted as total moving mass for both tilt assemblies from existing repo docs.|
|Moving-mass lever arm|`P.mass.RH`|`ASSUMED_CONCEPT`|Equivalent moving-mass CG distance from tilt axis; also used by rotor hub geometry.|
|Nominal inertia matrix|`P.mass.I0`|`ASSUMED_CONCEPT`|Concept nominal inertia at `betaM=0`; NASA mapping remains unverified.|
|Inertia slope per radian|`P.mass.KI`|`ASSUMED_CONCEPT`|Current comment and implementation interpret this as per radian.|
|Rotor pivot geometry|`P.rotor.pivotX/Y/Z`|`ASSUMED_CONCEPT`|Concept rotor/nacelle pivot locations.|
|Wing load stations|`P.wing.xAC/yFreeAC/ySlipAC/zAC`|`ASSUMED_CONCEPT`|Concept wing free/slipstream aerodynamic centers.|
|Fuselage reference point|`P.fuselage.rAC`|`ASSUMED_CONCEPT`|Concept fuselage aerodynamic center.|
|Horizontal tail reference point|`P.htail.rAC`|`ASSUMED_CONCEPT`|Concept horizontal-tail aerodynamic center.|
|Vertical tail reference points|`P.vtail.xAC/yAC/zAC`|`ASSUMED_CONCEPT`|Concept twin-fin aerodynamic centers.|
|CG shift|`mp.cgShift`|`DERIVED`|Derived from `mNac`, `RH`, `betaM`, and total mass by the implemented formula.|
|Principal moments and radii diagnostics|`mp.principalMoments`, `mp.radiusOfGyration`|`DERIVED`|Derived from the returned inertia matrix.|
|Solver/test tolerances|test tolerances|`NUMERICAL`|Used only for internal consistency checks.|

No `DOCUMENTED_SOURCE` classification is assigned in this phase because no
new literature value was verified against original pages, units, and
configuration.

## Findings

|Severity|Category|Finding|Action|
|-|-|-|-|
|INFO|Parameter provenance|Mass, inertia, and geometry parameters remain conceptual assumptions or derived values unless explicitly traced in a later literature pass.|Do not describe these values as XV-15 measured data.|
|INFO|Model limitation|`I(betaM)=I0-betaM*KI` is a low-order inertia law and omits a detailed moving-mass build-up and tilt-dependent cross-inertia model.|Accept for this phase; revisit only with sourced mass-property data.|
|INFO|Model semantics|`mNac` is interpreted as total moving nacelle/rotor mass for both sides, not per-side mass.|Keep this interpretation explicit in reports and future parameter tables.|

No `CRITICAL`, `HIGH`, or `MEDIUM` production-code issue was identified in the
static audit scope before running the lightweight tests.

## Test Plan

New target:

```matlab
r = check_mass_inertia_geometry;
```

The check uses only `betaM = 0`, `pi/4`, `pi/2`, plus one small central
difference pair around `pi/4`. It avoids dense tilt sweeps, speed sweeps,
Monte Carlo, optimization, and multi-start runs.

Initial target run estimate:

```text
total_forces_moments calls: 3
rotor_model_bemt calls: 6
```

Actual target run result:

```text
check_mass_inertia_geometry: 12/12 PASS
Model calls: total_forces_moments=3, rotor_model_bemt=6
```

Existing physical sanity check:

```text
check_physical_sanity: 7/7 PASS
tipSpeed=235.600 m/s
solidity=0.09549
diskLoading=648.522 N/m^2
viHoverEstimate=16.270 m/s
|cgShift90|=0.15910 m
```

Full lightweight suite:

```text
run_all_checks: 12/12 PASS
```

MATLAB R2021a produced a shutdown-stage `output stream error` after each
successful test-body run. The failure occurred after the PASS summaries and is
recorded separately from model/test assertions.

## Parameter And Interface Status

- Production parameter values changed: no.
- `params_nominal.m` numeric values changed: no.
- Inertia law changed: no.
- Coordinate, force, or moment equations changed: no.
- Public function input/output signatures changed: no.
- Added derived diagnostic fields in `mass_properties` output: yes.
