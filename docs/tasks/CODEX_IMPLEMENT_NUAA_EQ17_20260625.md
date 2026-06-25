# Codex Task — Implement NUAA Equation (17) and close the wing slipstream formula chain

Date: 2026-06-25

## 0. Standing review rule

At the end of every execution report, return to the original task objective and explicitly state:

1. why the chosen implementation is correct and reasonable;
2. which parts remain assumptions, approximations, or unresolved;
3. what evidence could falsify the implementation;
4. whether any result is only an intermediate diagnostic and must not be treated as final validation.

Do not end with only “tests passed.” Challenge the implementation before giving the final conclusion.

## 1. Objective and boundary

Implement NUAA Eq. (17) as the active local velocity of the wing slipstream zone. This completes the paper formula chain:

```text
Eq.16 slipstream area
→ Eq.17 slipstream-zone local velocity
→ Eq.18 aerodynamic-center position relative to current CG
→ Eq.19/21 force transformation
→ Eq.20/22 moment assembly
```

Numerical equality with the authors is not required. The paper formula structure, current coordinate convention, and explicit assumptions are required.

The previous full trend outputs under:

```text
docs/validation/nuaa_trim_trends/20260625_eq12_13_16/
docs/validation/nuaa_trim_trends/20260625_eq12_13_16_angle_fix/
```

must be preserved but identified as `INTERMEDIATE_IMPLEMENTATION_DIAGNOSTIC`, because Eq. (17) was still pending when they were generated. Do not delete or overwrite them.

## 2. Git and workspace

Work in `E:\tiltrotor`.

First run:

```text
git status --short
git branch --show-current
git log -3 --oneline
```

Hard stop on unexpected local source changes. Do not clean, reset, restore, or delete `validation/`.

Start from:

```text
origin/feature/nuaa-equations-12-13-16
```

Create:

```text
feature/nuaa-equation-17
```

Read before editing:

```text
AGENTS.md
references/NUAA_main_paper.pdf
model/wing_model.m
model/rotor_model_bemt.m
model/aero_force_body.m
model/mass_properties.m
docs/PAPER_CODE_MAPPING.md
docs/PARAMETER_SOURCE_INVENTORY.md
tests/check_aerodynamic_components.m
tests/check_wing_normal_flow_blend.m
tests/check_nuaa_eq12_13_16.m
tests/check_physical_sanity.m
tests/run_all_checks.m
```

## 3. NUAA Eq. (17)

Paper form:

```text
V_wsl = V_body + omega × r_wsl
        + [v1d*sin(betaM); 0; -v1d*cos(betaM)]
```

Expanded matrix form in the paper is exactly equivalent to `cross(omegaBody,rAC)` under body axes `x forward, y right, z down`.

The current rotor basis already defines:

```matlab
eT = [sin(betaM); 0; -cos(betaM)];
```

Therefore the paper induced-velocity vector is exactly:

```matlab
VwakeEq17 = rotor.inducedVelocity * rotor.eT;
```

for the rotor adjacent to that half-wing.

### 3.1 Production change

In `model/wing_model.m`, replace the current active slipstream addition:

```matlab
wakeVelocity = P.rotor.wakeFactor*max(rotor.inducedVelocity,0);
Vlocal = Vlocal + wakeVelocity*rotor.eT;
```

with the literal Eq. (17) mapping:

```matlab
VrigidLocal = Vbody + cross(omegaBody,rAC);

if inSlipstream
    v1d = rotor.inducedVelocity;
    VwakeEq17 = [v1d*sin(betaM); 0; -v1d*cos(betaM)];
    VwakeBasis = v1d*rotor.eT;
    eq17BasisError = norm(VwakeEq17 - VwakeBasis);
    Vlocal = VrigidLocal + VwakeEq17;
else
    v1d = 0;
    VwakeEq17 = zeros(3,1);
    VwakeBasis = zeros(3,1);
    eq17BasisError = 0;
    Vlocal = VrigidLocal;
end
```

Use `VwakeEq17`, not `wakeFactor*eT`, in the production force calculation.

Do not use `max(v1d,0)` in Eq. (17). Eq. (13) currently supplies a nonnegative normal-working-state induced velocity through its positive-thrust guard. If a negative or nonfinite induced velocity reaches Eq. (17), raise a clear applicability/consistency error instead of silently changing the paper formula.

### 3.2 wakeFactor handling

`P.rotor.wakeFactor` must no longer affect production wing loads after this change.

Do not delete the field in this task because GUI/catalog compatibility may depend on it. Mark it as deprecated/unused for the NUAA Eq. (17) production path in:

```text
params_nominal.m
docs/PARAMETER_SOURCE_INVENTORY.md
services/build_parameter_catalog.m (only if the catalog currently exposes it)
```

If the GUI exposes it, change its status/help text to state that it is retained only for backward compatibility and is not read by the active model. Do not silently leave a visible parameter that no longer changes calculations.

## 4. Required diagnostics

For every wing region output, include:

```text
VrigidLocal
v1dEq17
VwakeEq17
VwakeBasis
eq17BasisError
localVelocityModel
```

Use:

```text
localVelocityModel = 'NUAA_EQ17'
```

for slipstream regions and:

```text
localVelocityModel = 'FREE_STREAM_RIGID_BODY'
```

for free-stream regions.

Retain the final `Vlocal`, speed, angle of attack, sideslip, dynamic pressure, force, and moment outputs.

At model level expose a summary containing:

```text
maxEq17BasisError
maxEq17ReconstructionError
wakeFactorUsed = false
```

where reconstruction error verifies:

```text
Vlocal == Vbody + cross(omegaBody,rAC) + VwakeEq17
```

for slipstream regions.

## 5. Verify Eqs. (18)–(22) before any full trend rerun

Do not rewrite Eqs. (18)–(22), but add focused tests proving the active code is mathematically equivalent.

### Eq. (18)
Verify for several `betaM` values and nonzero `cgShift`:

```matlab
rAC == rAC0 - cgShift
```

for free and slipstream regions on both half-wings.

### Eqs. (19) and (21)
For `beta=0` and a lift-line case, verify `aero_force_body(D,0,L,alpha,0)` equals the paper transformation:

```matlab
[-D*cos(alpha) + L*sin(alpha);
 0;
 -D*sin(alpha) - L*cos(alpha)]
```

Also retain the current three-dimensional side-force extension as a documented generalization.

### Eqs. (20) and (22)
Verify for every wing region:

```matlab
M == cross(rAC,F) + Maero
```

and verify left/right symmetry for a symmetric state and zero aileron.

If any of these identities fail, stop before trim calculations. Do not adjust parameters or snapshots.

## 6. Focused Eq. (17) tests

Create `tests/check_nuaa_eq17_wing_velocity.m` and register it in `run_all_checks`.

Required cases:

### 6.1 Endpoint directions
With zero body motion and zero angular rate:

- `betaM=0`: `VwakeEq17=[0;0;-v1d]`;
- `betaM=pi/2`: `VwakeEq17=[v1d;0;0]`;
- `betaM=15 deg` and `75 deg`: components equal the literal sine/cosine formula.

### 6.2 Rigid-body local velocity
Use nonzero `Vbody`, `omegaBody`, and `rAC`; verify the paper matrix term equals `cross(omegaBody,rAC)` and reconstructs `Vlocal` to tight tolerance.

### 6.3 Basis equivalence
Verify:

```matlab
[v1d*sin(betaM);0;-v1d*cos(betaM)] == v1d*rotor.eT
```

for both rotors and all representative angles.

### 6.4 Free-stream isolation
Verify free-stream regions do not receive induced velocity.

### 6.5 wakeFactor independence
Evaluate the same wing case with widely different finite values of `P.rotor.wakeFactor`. Production wing forces, moments, local velocities, and Eq. (17) diagnostics must be unchanged.

### 6.6 Invalid input
Verify nonfinite or negative `rotor.inducedVelocity` in a slipstream region triggers the intended consistency/applicability error and is not silently clipped.

## 7. Execution gates

### Stage A — code and focused identities
Run only:

```matlab
check_nuaa_eq17_wing_velocity
check_nuaa_eq12_13_16
check_aerodynamic_components
check_wing_normal_flow_blend
check_physical_sanity
check_rotor_force_moment_chain
```

Stop on any failure.

### Stage B — five representative trims
Only after Stage A passes, run:

```text
helicopter 0 deg / 0 m/s
helicopter 0 deg / 20 m/s
conversion 15 deg / 35 m/s
conversion 75 deg / 100 m/s
airplane 90 deg / 100 m/s
```

Report for each:

- convergence, residual, credibility and margins;
- Eq. (16) raw/applied slipstream area;
- Eq. (17) induced-velocity vector and local wing velocities;
- Eq. (17) reconstruction and basis errors;
- wing force and pitching moment split between slipstream and free-stream regions;
- whether any local aerodynamic model is outside its declared applicability screen.

If any representative point fails, stop. Do not search seeds, tune parameters, alter limits, or modify the trim strategy.

### Stage C — full regression
Only after Stage B passes, run `run_all_checks`.

### Stage D — full 100-point trend
Only after Stages A–C pass and the report explicitly confirms that Eqs. (16)–(22) form a complete active wing chain, rerun the 100-point trend and summary figure once.

Write new evidence to:

```text
docs/validation/nuaa_trim_trends/20260625_eq12_17_complete/
validation/nuaa_trim_trends/<timestamp>_eq12_17_complete/
```

Do not overwrite older outputs.

The new report must compare against the pre-Eq.17 version, but must not treat the pre-Eq.17 version as final physical evidence.

## 8. Mark previous intermediate outputs

Add a short `INTERMEDIATE_STATUS.md` inside both previous docs output directories stating:

```text
This result was generated after Eqs. (12), (13), and (16) were implemented but before Eq. (17) replaced the legacy wakeFactor path. It is retained for software regression and sensitivity history only and is not the final NUAA wing-slipstream trend baseline.
```

Do not alter their CSV or figures.

## 9. Documentation

Update `docs/PAPER_CODE_MAPPING.md`:

- Eq. (17): implemented literally through the body-axis vector and verified equivalent to `v1d*eT`;
- Eq. (18): equivalent `rAC0-cgShift` implementation verified;
- Eqs. (19)/(21): paper longitudinal transformation verified as the zero-sideslip limit of `aero_force_body`;
- Eqs. (20)/(22): `cross(rAC,F)+Maero` identity verified;
- current free-flow subregions remain merged into one equivalent free-flow region, if still true.

Update `docs/PARAMETER_SOURCE_INVENTORY.md` and GUI/catalog documentation so `wakeFactor` is clearly deprecated/unused by production calculations.

## 10. Git

Commit code/tests/docs before generating full trend evidence. Suggested stages:

```text
model: implement NUAA equation 17 wing velocity
 test: verify NUAA wing equations 17 through 22
 docs: mark pre-equation-17 results as intermediate
 validation: refresh complete NUAA wing-chain trends
```

Push:

```text
origin/feature/nuaa-equation-17
```

Do not create a PR.

## 11. Mandatory final self-review

The final report must end with a section titled:

```text
Correctness, reasonableness, and remaining doubts
```

It must restate:

- why Eq. (17) is correctly mapped to the current body axes;
- why removing `wakeFactor` is necessary for literal formula implementation;
- why Eqs. (18)–(22) are considered equivalent or generalized implementations;
- what remains unverified, including assumed Eq. (16) parameters, merged free-flow subregions, conceptual aerodynamic coefficients, absence of dynamic inflow states, and any applicability limitations;
- what observations would indicate the implementation is physically unreasonable.
