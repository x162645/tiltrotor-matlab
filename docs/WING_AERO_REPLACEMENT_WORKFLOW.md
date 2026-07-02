# Wing Aerodynamic Model Replacement Workflow

Date: 2026-07-02

## 1. Objective

Replace the current runtime blend of `FNear` and `FLiftLine` with a traceable, continuous, full-angle-of-attack aerodynamic database and a spanwise sectional wing model suitable for trim, numerical linearization, stability analysis, and GUI-based airfoil selection.

This work does not aim to tune the model to visually match the NUAA trim curves. The goal is a physically self-consistent component-level conceptual model whose assumptions, data sources, validity range, and numerical behavior are auditable.

## 2. Frozen diagnosis

For the 0-degree nacelle-angle helicopter-mode speed sweep, the local trim-curve bump is triggered by the speed-dependent `branchWeight` blend between `FNear` and `FLiftLine` in the wing slipstream region. The two branches do not match in force, pitching moment, or derivatives across the blend region, so the changing weight introduces extra curvature. The trim solver then redistributes that curvature into pitch attitude, collective, and longitudinal cyclic.

Fixing `branchWeight` at either endpoint removes the identified local bump. This identifies the blend as the direct trigger of the bump, but it does not prove that either endpoint model is physically adequate over the full speed range.

The global difference from the NUAA trends is a separate issue. It also depends on wing aerodynamics, rotor wake/slipstream modeling, geometry and moment arms, center of gravity, horizontal-tail parameters, fuselage moment, rotor control effectiveness, trim definitions, and nacelle-angle conventions.

## 3. Backup baseline

The following remote backup branches were created before production-model changes:

- `backup/pre-wing-aero-physics-20260702`, based on `feature/nuaa-equation-17`.
- `backup/pre-wing-aero-gui-20260702`, based on `feature/gui-v1.2-parameter-workbench`.

These branches preserve the committed remote states only. Local uncommitted or untracked files on `E:\tiltrotor` are not included and must be checked and backed up locally before Codex modifies the working tree.

## 4. Tool policy

### Required production dependency

- XFOIL: generate regular-angle two-dimensional airfoil polars.

### Existing production environment

- MATLAB R2021a: orchestration, data validation and fusion, full-angle extension, sectional wing integration, trim, linearization, stability analysis, and GUI.

### Optional future validation tool

- OpenVSP/VSPAERO: optional representative-point three-dimensional cross-check only. It is not a mandatory dependency for airfoil replacement or normal GUI operation.

### Excluded from the production chain at this stage

- CFD
- QBlade
- XFLR5

External executables must not be committed to Git. The repository stores only path configuration, version/source metadata, hashes, smoke tests, and integration code.

## 5. Mandatory staged gates

### Stage 0 — Baseline freeze

Requirements:

- Confirm repository branch, HEAD, and worktree state.
- Preserve the existing production wing model and defaults.
- Keep new and legacy wing models in parallel until final acceptance.
- Record remote backups and local backup limitations.

Gate: `BASELINE_FROZEN`

### Stage 1 — XFOIL availability and smoke test

Requirements:

- Detect a user-configured or project-relative `xfoil.exe`.
- Run XFOIL as an independent process.
- Generate a minimal input file.
- Apply timeout and logging.
- Parse a small test polar.
- Do not modify the production wing model, defaults, or GUI.

Gate: `TOOL_PASS`

### Stage 2 — Airfoil geometry package

Requirements:

- Import a standard `.dat` coordinate file.
- Normalize coordinates.
- Identify leading and trailing edges.
- Remove duplicate points.
- Reject self-intersection and invalid thickness.
- Generate a geometry hash and unique airfoil ID.
- Store geometry, metadata, source, and validation results in a versioned package.

Gate: `GEOMETRY_PASS`

### Stage 3 — Regular-angle XFOIL database

Requirements:

- Determine Reynolds, Mach, angle-of-attack, and control-deflection grids from the current model envelope.
- Generate and run batch jobs.
- Cache identical jobs.
- Retry non-converged points using a fixed documented strategy.
- Never silently fabricate missing points.
- Validate continuity, drag sign, lift slope, moment behavior, and control-effect direction.

Gate: `POLAR_PASS`

### Stage 4 — Full-angle database freeze

Requirements:

- Digitize and review NASA TM-88373 and NASA CR-114614.
- Freeze reference area, chord, moment reference point, configuration, and nacelle-angle definitions.
- Prioritize wind-tunnel/NASA data, then validated XFOIL data, then clearly marked engineering extrapolation.
- Build one continuous `CL/CD/Cm` database with per-point source and confidence labels.
- Do not assign unsupported constant high-angle `Cm` values.

Gate: `FULL_ALPHA_PASS`

### Stage 5 — Sectional wing model

Requirements:

- Divide each wing into spanwise sections.
- Compute local body, rotational, and rotor-slipstream velocity.
- Query a single aerodynamic database using local angle of attack, Reynolds number, Mach number, and control deflection.
- Support root/tip airfoil assignment and spanwise interpolation.
- Include chord, twist, slipstream coverage, finite-span corrections, induced drag, control-surface regions, aerodynamic-center moment, and moment arms to the center of gravity.
- Keep `legacy` and `sectional_database` modes selectable during development.

Gate: `WING_MODEL_PASS`

### Stage 6 — Physics and numerical acceptance

Run representative hover, 0-degree helicopter-mode sweep, 15-degree and 75-degree conversion cases, 90-degree airplane cases, full trim sweeps, numerical linearization, multiple finite-difference step sizes, component force/moment audits, and control-effectiveness checks.

Acceptance must examine more than whether the original bump disappears. It must also check continuity, control limits, database validity, derivative stability, component-level explanations, and absence of new nonphysical curvature.

Gate: `MODEL_PASS`

### Stage 7 — GUI integration

Only after Stage 6:

- Add airfoil/package selection and import.
- Add XFOIL detection, package generation, validation, apply, and rollback actions.
- Hide solver internals from normal users.
- Prevent unvalidated packages from being applied.
- Invalidate old trim, A/B matrices, and stability results after package changes.
- Preserve the previous valid package on failure.

Gate: `GATE_PASS`

## 6. Codex execution rules

- Use a separate Codex conversation for each major stage.
- Always read and follow `AGENTS.md` and the active task document.
- Start with a read-only preflight.
- Stop if the worktree is dirty or contains unconfirmed untracked files.
- Do not reset, clean, stash, stage, commit, or push unless explicitly instructed.
- Do not modify production aerodynamics, defaults, or GUI during the XFOIL smoke-test stage.
- Use command-line and file interfaces; do not automate GUI clicks.
- Run external tools as independent processes with timeouts and logs.
- Do not use NUAA trim-curve similarity as an automatic parameter-tuning objective.
- Do not proceed to production-model replacement until NASA/high-angle data and parameter definitions pass the data gate.

## 7. Immediate next action

The next action is Stage 1 preflight only:

1. User obtains a Windows XFOIL executable from a traceable source.
2. User places it at the configured local path, provisionally:
   `E:\tiltrotor\tools\external\xfoil\xfoil.exe`.
3. Codex performs a read-only repository and tool preflight.
4. If clean and available, Codex implements only a minimal XFOIL smoke-test adapter and focused tests.
5. Production wing equations, parameters, and GUI remain unchanged.
