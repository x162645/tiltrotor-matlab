# CODEX_TASK.md

STATUS: ACTIVE / READ-ONLY PARAMETER SOURCE INVENTORY

Branch: `audit/parameter-source-inventory`

Base branch: `main`

Current phase: repository-wide parameter, geometry, control-limit, numerical-setting, and model-applicability source inventory.

## Purpose

Build a complete, traceable inventory of every parameter and parameter-like constant currently used by the conceptual tiltrotor model before any further production implementation, parameter replacement, dense continuation, linearization map, transition/airplane trim work, or XV-15 comparison.

This is a documentation and evidence-classification task. It must not change model behavior.

## Mandatory boundaries

- Do not change any numeric value in `params_nominal.m` or any production file.
- Do not change equations, control mappings, limits, solver behavior, tolerances, defaults, tests, or public function signatures.
- Do not run MATLAB.
- Do not run trim, continuation, Jacobian, linearization, optimization, or sensitivity scans.
- Do not claim that a value is an XV-15 value unless a repository-accessible source and exact page/table/equation location support that claim.
- Do not infer missing values from photographs, drawings, or unrelated aircraft in this pass.
- Do not copy unverified web claims into the repository as established facts.
- Do not merge the Draft PR.

## Read first

- `AGENTS.md`
- `CODEX_TASK.md`
- `params_nominal.m`
- all files under `model/`
- all files under `analysis/`
- all files under `tests/`
- all files under `docs/`
- the file list under `references/`
- `references/NUAA_main_paper.pdf`
- `references/NASA_TM_X_62407.pdf`
- `references/NASA_TM_81244.pdf`

If additional references exist, list them. Do not assume their content without reading the relevant page or extracted text.

## Required inventory coverage

Inventory every parameter or embedded constant that can affect physical loads, moments, mass properties, trim, linearization, controls, or applicability. Include at least:

1. environment: density and gravity;
2. total mass, moving mass, CG-shift geometry, inertia matrix, inertia-variation coefficients;
3. rotor radius, blade count, rotational speed, chord, root cutout, twist, airfoil/aerodynamic coefficients;
4. rotor hub/pivot geometry and left/right sign conventions;
5. BEMT discretization, induced-velocity iteration, relaxation, tolerances, wake factor;
6. blade mass, blade mass distribution, flap inertia, first mass moment, flap limits, flap-solver settings, polar inertia;
7. deprecated or retained compatibility fields and whether production code reads them;
8. wing area/span/chord, aerodynamic-center locations, slipstream area, coefficients, saturation values, normal-flow blend parameters;
9. fuselage reference dimensions, aerodynamic-center position, force/moment derivatives and damping derivatives;
10. horizontal-tail geometry, incidence, downwash, coefficients and elevator derivatives;
11. vertical-tail geometry, coefficients and rudder derivative;
12. control limits and any control mixing, clipping, normalization, or unit conversion outside `params_nominal.m`;
13. trim tolerances, iteration limits, search scales, penalty/limit constants, thresholds and default seeds;
14. numerical-linearization steps and stability tolerances;
15. embedded numeric constants in production functions that act as physical, empirical, numerical, saturation, regularization, or applicability parameters;
16. known model applicability limits: reverse flow, windmill state, nonuniform inflow, unsteady aerodynamics, dynamic inflow, transition/airplane trim closure, stall modeling, slipstream interaction, and control mixing.

## Classification vocabulary

Use exactly these source/status labels:

- `DOCUMENTED_PRIMARY` — exact value or relation supported by a primary source with page/table/equation location;
- `DOCUMENTED_SECONDARY` — supported by a thesis, paper, or secondary compilation with exact location;
- `DERIVED` — calculated from other inventoried quantities; show the formula and parent parameters;
- `ASSUMED_CONCEPT` — intentionally selected conceptual physical value without direct source;
- `NUMERICAL` — solver, discretization, tolerance, regularization, or reporting setting;
- `REFERENCE_PENDING` — intended physical parameter whose source has not been established;
- `AMBIGUOUS_COUPLED` — one field is serving two or more physical meanings;
- `DEPRECATED_UNUSED` — retained for compatibility and proven unused by the production path;
- `UNRESOLVED` — insufficient evidence to classify safely.

Use exactly these confidence labels:

- `HIGH`
- `MEDIUM`
- `LOW`

Use exactly these issue-severity labels:

- `CRITICAL`
- `HIGH`
- `MEDIUM`
- `LOW`
- `INFO`
- `NONE`

Severity must describe the risk to model interpretation or behavior if the current value/meaning remains unresolved. Do not assign HIGH merely because a source is missing.

## Required deliverables

Create:

```text
docs/PARAMETER_SOURCE_INVENTORY.md
docs/PARAMETER_GAP_REGISTER.md
docs/PARAMETER_SOURCE_WORKPLAN.md
```

### `PARAMETER_SOURCE_INVENTORY.md`

Include one row per parameter or embedded parameter-like constant with these columns:

```text
ID
parameter / constant
current value or expression
SI unit
category
physical or numerical
consumer files/functions
source-status label
source document
exact page/table/equation/line location
derivation or interpretation
confidence
issue severity
blocks later work? yes/no
notes
```

Requirements:

- preserve expressions such as `bladeMass*R^2/3` rather than replacing them only with decimal values;
- identify all unit conversions and the unit expected by production code;
- list every file/function that consumes the parameter when practical;
- distinguish unused compatibility fields from active fields using code references;
- for exact source claims, record the PDF filename and page/table/equation;
- if a source location cannot be confirmed, leave it explicitly `UNRESOLVED` or `REFERENCE_PENDING`;
- include a summary count by source-status, confidence, severity, and category.

### `PARAMETER_GAP_REGISTER.md`

Organize unresolved issues by priority and dependency. It must include at least:

- `P.mass.RH` serving both moving-mass CG radius and rotor-hub tilt radius;
- meaning and source status of `P.mass.mNac`;
- inertia base values and the per-radian interpretation of `P.mass.KI`;
- rotor twist representation and whether a single `twistTip` can represent the intended blade;
- constant rotor speed versus mode-dependent rotor-speed scheduling;
- blade mass distribution, flap inertia, hinge/offset/stiffness/damping omissions;
- `Jpolar = 0` and the disabled gyro path;
- rotor airfoil-polar simplification;
- wake factor and uniform induced-flow assumptions;
- pivot and component three-dimensional positions;
- wing, fuselage, horizontal-tail, and vertical-tail aerodynamic derivatives;
- normal-flow blend center and width;
- control limits and missing sourced control-mixing gains;
- transition/airplane trim closure applicability;
- any physical constants embedded outside `params_nominal.m`.

For each issue include:

```text
problem statement
current code consequence
evidence available
evidence missing
severity
recommended disposition
required source type
which later phase it blocks
```

### `PARAMETER_SOURCE_WORKPLAN.md`

Create a staged source-verification and later-remediation plan. Separate:

1. claims that can be verified directly from existing repository references;
2. claims requiring additional public NASA/FAA/academic sources;
3. values that can be derived after geometry or mass data are established;
4. values that will remain conceptual unless experimental data are found;
5. structural code changes that should preserve initial numeric behavior, such as splitting `RH_mass` and `RH_hub`;
6. parameter changes that require dedicated regression tests before acceptance.

The workplan must define explicit phase gates. At minimum:

- Gate A: inventory complete and no active field omitted;
- Gate B: source claim verified with exact citation;
- Gate C: proposed numeric replacement reviewed before code change;
- Gate D: one parameter family changed at a time;
- Gate E: family-specific regression passes before broader checks;
- Gate F: no dense envelope or XV-15 fidelity claim before critical parameter families are resolved.

## Required code-use tracing

Search production code for every `P.` field and for numeric literals that act like parameters. Document:

- definition site;
- read sites;
- unit at definition;
- unit at use;
- whether clipped, normalized, transformed, or duplicated;
- whether the field is active, unused, deprecated, or shadowed by a local constant.

Pay special attention to:

- `RH`, `mNac`, `I0`, `KI`;
- `Omega`, `twistTip`, `bladeMass`, `Ib`, `Sblade`, `Jpolar`;
- `inflowHarmonic`, `flapCyclicGain`, `flapMuGain`, `flapLatMuGain`, `flapQGain`, `flapPGain`;
- `wakeFactor`;
- component AC/pivot positions;
- control limits;
- normal-flow blend constants;
- all hard-coded tolerances and saturation thresholds.

## Evidence discipline

- Quote as little as necessary.
- Do not treat a document title, search result, or prior project note as proof of a value.
- Exact page/table/equation references are mandatory for `DOCUMENTED_PRIMARY` and `DOCUMENTED_SECONDARY`.
- If two sources disagree, record both and do not choose a value in this task.
- If coordinate origins, angle conventions, weight conditions, blade variants, or units differ, record the incompatibility explicitly.
- Separate XV-15 steel-blade data from advanced/composite-blade data.
- Separate empty weight, design gross weight, test weight, and maximum gross weight.
- Separate helicopter-mode and airplane-mode rotor speed and inertial data.

## Execution and runtime

This task is static and documentation-only.

- MATLAB calls: 0
- trim solves: 0
- Jacobians: 0
- linearizations: 0
- source-code modifications: 0
- production-parameter modifications: 0

Do not add automated scraping, OCR loops, PDF conversion scripts, or large generated data files.

## Closeout report

Report:

- exact files read;
- exact files created or modified;
- number of inventoried active physical parameters;
- number of numerical settings;
- number of deprecated/unused fields;
- count by source-status label;
- count by severity;
- all CRITICAL/HIGH/MEDIUM gaps;
- parameters whose units or meaning remain ambiguous;
- source disagreements;
- which issues block later linearization, transition-mode, flight-envelope, and XV-15 comparison work;
- confirmation that MATLAB was not run and no production value changed;
- commit SHA and clean working-tree status.

Commit and push to `audit/parameter-source-inventory`.

Do not merge the Draft PR and do not begin parameter replacement, code restructuring, MATLAB validation, dense continuation, transition/airplane trim implementation, or flight-envelope work.
