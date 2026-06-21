# CODEX_TASK.md

STATUS: COMPLETE / RH MASS-HUB SPLIT / HOLD

Branch: `refactor/split-rh-mass-hub`

Base branch: `main`

## Purpose

Resolve GAP-H01 by separating the currently coupled field `P.mass.RH` into two independently named parameters while preserving current numerical behavior:

- `P.mass.RH_mass`: equivalent moving-mass CG radius used only by `mass_properties`;
- `P.rotor.RH_hub`: rotor-hub tilt radius used only by `rotor_model_bemt` and geometry checks.

Both new fields must initially equal the current value `0.75 m`. This task is structural only. It does not introduce XV-15 values and does not tune any result.

## Read first

- `AGENTS.md`
- `CODEX_TASK.md`
- `params_nominal.m`
- `model/mass_properties.m`
- `model/rotor_model_bemt.m`
- `model/total_forces_moments.m`
- `tests/check_mass_inertia_geometry.m`
- `tests/check_physical_sanity.m`
- `tests/check_rotor_force_moment_chain.m`
- `tests/run_all_checks.m`
- `docs/PARAMETER_SOURCE_INVENTORY.md`
- `docs/PARAMETER_GAP_REGISTER.md`
- `docs/PARAMETER_SOURCE_WORKPLAN.md`

Before editing, search the whole repository for:

```text
P.mass.RH
RH_mass
RH_hub
```

Report every active read, test read, and documentation occurrence. Do not assume the known two production reads are the only ones.

## Required implementation

### 1. Parameter definition

In `params_nominal.m`:

```matlab
P.mass.RH_mass = 0.75;
P.rotor.RH_hub = 0.75;
```

Use SI units and comments that state the distinct physical meanings.

Retain `P.mass.RH` only if compatibility is genuinely required. If retained:

- mark it clearly as deprecated compatibility metadata;
- initialize it from one of the new fields only to preserve old external callers;
- prove that no production path reads it;
- do not use it as a fallback inside production functions;
- document that modifying the deprecated alias does not affect model results.

If repository-wide evidence shows no compatibility need, removal is allowed, but all repository callers and tests must be updated and the decision must be documented. Do not silently keep three active radii.

### 2. Production reads

Update:

- `model/mass_properties.m` to use only `P.mass.RH_mass` in the CG-shift equations;
- `model/rotor_model_bemt.m` to use only `P.rotor.RH_hub` in hub-position geometry.

Do not change formulas, signs, angle conventions, force arms, CG subtraction, inertia law, or any numeric value.

### 3. Tests

Extend `tests/check_mass_inertia_geometry.m` with explicit behavior-preserving and decoupling checks.

At minimum verify:

1. **legacy-value identity**
   - with `RH_mass = RH_hub = 0.75 m`, representative outputs at `betaM = [0, pi/4, pi/2]` match the old shared-radius formulas to tight floating-point tolerance;
   - CG shift matches the old formula using `0.75 m`;
   - absolute hub geometry `rHub + cgShift` matches the old formula using `0.75 m`.

2. **mass-radius independence**
   - perturb only `P.mass.RH_mass` in a copied parameter struct;
   - verify CG shift changes according to the analytic formula;
   - verify absolute hub geometry remains controlled by unchanged `P.rotor.RH_hub`.

3. **hub-radius independence**
   - perturb only `P.rotor.RH_hub`;
   - verify mass-properties CG shift is unchanged;
   - verify absolute hub geometry changes according to the hub-radius geometry formula.

4. **deprecated alias inactivity**, only if `P.mass.RH` is retained
   - perturb only the deprecated alias;
   - verify `mass_properties`, hub geometry, total forces/moments, and representative outputs are unchanged;
   - repository production search must show zero active reads.

5. preserve the existing mass, inertia, mirror, clearance, component-position, deterministic, and finite checks.

Use synthetic perturbations only to prove separation. Do not introduce sourced XV-15 values.

### 4. Documentation

Update the relevant PR #7 documents so they describe the post-split state accurately:

- `docs/PARAMETER_SOURCE_INVENTORY.md`
- `docs/PARAMETER_GAP_REGISTER.md`
- `docs/PARAMETER_SOURCE_WORKPLAN.md`

Required documentation changes:

- replace the single active `P.mass.RH` inventory item with separate `RH_mass` and `RH_hub` items;
- if an alias remains, classify it as `DEPRECATED_UNUSED` and state that production reads are zero;
- preserve current provenance as `ASSUMED_CONCEPT` for both new active values;
- keep XV-15 target evidence as pending/independent;
- change GAP-H01 from an active coupled-field defect to a resolved structural split with numeric sourcing still pending;
- keep the future XV-15 blocker open for the values themselves;
- mark Track A work package 1 structurally complete only after tests pass;
- do not alter unrelated inventory classifications or counts without a direct consequence of this split.

Create one focused document:

```text
docs/RH_MASS_HUB_SPLIT_AUDIT.md
```

It must record:

- old field meaning and read sites;
- new field meanings and read sites;
- exact unchanged initial values;
- compatibility decision for `P.mass.RH`;
- formulas before and after;
- targeted test cases and tolerances;
- runtime/call counts;
- final conclusion limited to structural decoupling and behavior preservation.

## Runtime discipline

This task must follow the staged execution budget.

### Stage 0 — static and baseline preparation

Before code changes:

- run repository search for all relevant fields;
- estimate MATLAB work;
- run only `check_mass_inertia_geometry` as the baseline focused check;
- if baseline fails, stop and report before editing.

Expected baseline cost: one focused test function, 12 existing cases, limited representative rotor calls; expected wall time roughly 15–45 seconds on the known R2021a environment.

### Stage 1 — targeted validation after modification

Run, in this order:

1. `check_mass_inertia_geometry`
2. `check_rotor_force_moment_chain`
3. `check_physical_sanity`

Record elapsed time, PASS/FAIL counts, and model-call counts when reported.

If any focused check fails, stop. Do not proceed to the total suite and do not tune parameters or tolerances.

### Stage 2 — broader regression

Only after all three focused checks pass, run:

```matlab
run_all_checks
```

Do not run trim sweeps, continuation, Jacobians, linearization maps, transition cases, or dense scans.

The known MATLAB R2021a shutdown-stage `mwboost::archive::archive_exception: output stream error` must be reported separately from test-body results. Do not relabel completed PASS assertions as model failures solely because of that shutdown error.

## Allowed files

Production/test/document changes should be limited to:

```text
CODEX_TASK.md
params_nominal.m
model/mass_properties.m
model/rotor_model_bemt.m
tests/check_mass_inertia_geometry.m
# tests/run_all_checks.m only if registration truly changes
docs/PARAMETER_SOURCE_INVENTORY.md
docs/PARAMETER_GAP_REGISTER.md
docs/PARAMETER_SOURCE_WORKPLAN.md
docs/RH_MASS_HUB_SPLIT_AUDIT.md
```

Do not modify unrelated aerodynamic, rotor-load, control, trim, linearization, or solver files.

## Prohibited changes

- no XV-15 numeric replacement;
- no change to `m`, `mNac`, `I0`, `KI`, pivot coordinates, rotor radius, or control limits;
- no change to equations or signs;
- no change to solver algorithms, seeds, tolerances, limits, or acceptance thresholds;
- no new interpolation, schedule, fallback, or calibration logic;
- no broad refactor beyond the two radius meanings;
- no destructive Git history operation;
- do not merge the Draft PR.

## Acceptance criteria

The task passes only if:

- all active production reads use the correct new field;
- mass and hub radius can be perturbed independently with the expected isolated effect;
- unchanged initial values reproduce old formulas and representative outputs within documented floating-point tolerance;
- retained legacy alias, if any, has zero production effect;
- focused tests pass;
- `run_all_checks` passes after focused tests;
- no unrelated numeric output changes are observed;
- documents and counts are internally consistent;
- MATLAB call scope stays within the staged budget.

## Closeout

Update this file to:

```text
STATUS: COMPLETE / RH MASS-HUB SPLIT / HOLD
```

Final report must include:

- all files read;
- all files changed/created;
- repository-wide old/new field read-site inventory;
- compatibility decision for `P.mass.RH`;
- baseline and post-change test results;
- test elapsed times and call counts;
- exact behavior-preservation tolerances and worst errors;
- confirmation that all initial numeric values remain `0.75 m`;
- confirmation that no XV-15 value was inserted;
- confirmation that no unrelated formula, parameter, solver, threshold, or limit changed;
- commit SHA;
- clean working-tree status.

Commit and push to `refactor/split-rh-mass-hub`.

Do not merge the Draft PR.
