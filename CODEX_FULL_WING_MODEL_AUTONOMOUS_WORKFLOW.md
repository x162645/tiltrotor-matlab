# FULL_WING_MODEL_AUTONOMOUS_WORKFLOW

## 0. Mission

Complete the full replacement workflow for the wing aerodynamic model, from preservation of the current working model through data acquisition, XFOIL generation, post-stall/full-angle construction, rotor-wake/wing interaction, parallel production implementation, parameter/GUI integration, automated validation, and final engineering report.

This is a long-running autonomous task. Do not stop for routine approvals.

The current physical trigger already established for the 0 deg nacelle local trim bump is the speed-dependent blending of two complete wing aerodynamic results, `FNear` and `FLiftLine`, through `branchWeight`. The new model must remove that architecture. Free-stream and rotor-wake regions must use one common aerodynamic coefficient model; only their local flow velocity, angle of attack, Reynolds number, Mach number, dynamic pressure, covered area, and moment arm may differ.

The objective is a physically coherent, parameter-complete, source-traceable full-angle wing model. It is not a requirement to reproduce every XV-15 geometric detail. XV-15/NASA material is used where it provides a strong and relevant data chain. A different airfoil or parameter set may be selected only when evidence and validation show it is superior for the intended model.

## 1. Autonomy and approval policy

The user explicitly authorizes Codex to work continuously and autonomously.

Do not ask for approval for:

- creating an isolated git worktree and task branch;
- reading repository files and direct dependencies;
- downloading public NASA/NACA/XFOIL-related sources;
- verifying PDFs, hashes, file headers, and metadata;
- writing task-specific Python, PowerShell, MATLAB, or data-processing scripts;
- local OCR of relevant scanned pages;
- curve and geometry digitization;
- running XFOIL;
- retrying failed XFOIL cases;
- generating airfoil coordinates through a traceable standard method;
- comparing candidate post-stall extensions;
- generating CSV/MAT/JSON datasets;
- implementing the new model in parallel with the legacy model;
- adding tests;
- running MATLAB tests and long validation sweeps;
- fixing defects in newly added task code;
- updating task documentation;
- making milestone commits and pushing the task branch;
- creating or updating a Draft PR.

Only stop and request a user decision when one of these conditions is true:

1. Two materially different physical model structures both remain credible after source review and validation, and the evidence cannot distinguish them.
2. Continuing requires a large, unsourced engineering assumption that materially changes force or moment trends.
3. A step would delete the legacy model, overwrite protected uncommitted work, change the default model to the new model, merge a PR, or publish a release.
4. External sources remain inaccessible after reasonable retries and no equivalent traceable source exists.
5. A suspected malicious or invalid download cannot be safely verified.
6. A direct contradiction in the task rules cannot be resolved conservatively.

Ordinary missing data, one failed script, one failed XFOIL case, OCR difficulty, a noisy curve, a non-critical source conflict, or a long runtime is not a stop condition. Record it, retry or use an alternative method, and continue all independent work.

The sole planned user approval point is after the final gate, before changing the default model and merging the task branch.

## 2. Repository isolation and baseline protection

The original working directory may contain protected uncommitted work. Do not clean, stash, reset, checkout, reformat, delete, or overwrite it.

From the original repository's current committed `HEAD`, create or reuse an isolated worktree:

- worktree: `E:\tiltrotor-full-wing-model`
- branch: `task/full-wing-model-autonomous-20260702`

If the branch already exists remotely only as a task-instruction branch, create the local engineering branch from the current local committed `HEAD`, then copy this workflow file and the branch `CODEX_TASK.md` into that worktree. Do not base the engineering implementation on an outdated remote `main` when the current local committed `HEAD` is newer.

Before editing, record:

- original repository path;
- original branch;
- original `HEAD`;
- original `git status --short --untracked-files=all`;
- new worktree branch;
- new worktree `HEAD`;
- new worktree status.

The isolated worktree must start clean except for the task files intentionally copied into it.

Create a protected-baseline manifest containing path, size, and SHA256 for all production files that will later be touched. At minimum include:

- `model/wing_model.m`;
- `model/rotor_model_bemt.m`;
- `model/total_forces_moments.m`;
- `params_nominal.m`;
- relevant services and GUI files;
- relevant tests;
- current validation baselines.

Do not read the diff of uncommitted files in the original working directory.

## 3. Frozen engineering principles

These principles are mandatory:

1. Preserve the current working wing model.
2. The legacy and new wing models must coexist until final acceptance.
3. The default model remains the legacy model throughout this task.
4. Do not delete or silently alter the legacy model.
5. Do not tune parameters merely to remove the trim bump.
6. Remove the structural cause: speed-dependent mixing of two complete aerodynamic result branches.
7. Use one common full-angle aerodynamic coefficient lookup for all wing regions.
8. Free-stream and wake regions differ through local flow and geometry, not through different aerodynamic laws.
9. All key parameters must be source-tagged as `REFERENCE`, `DIGITIZED`, `DERIVED`, `ASSUMED`, `PLACEHOLDER`, or `UNKNOWN`.
10. No `ASSUMED`, `PLACEHOLDER`, or `UNKNOWN` value may be presented as measured XV-15 data.
11. The new model must be independently testable outside the trim solver.
12. Production integration occurs only after the offline data and physics gates pass.
13. Full project validation must be repeated after integration.
14. Passing internal tests does not constitute flight-test validation or a high-fidelity XV-15 claim.

## 4. Required task directories

Use these task-owned locations:

- `references/wing_full_angle/`
- `tools/wing_full_angle/`
- `data/wing_full_angle/`
- `validation/wing_full_angle/`
- `docs/wing_full_angle/`
- `model/wing/`
- `tests/wing_full_angle/`

Do not scatter temporary scripts into production folders.

Temporary XFOIL run directories may be outside the repository. Final, traceable inputs and outputs must be copied into the task data directory.

## 5. Stage 0 — baseline characterization and legacy preservation

### 5.1 Read first

Read:

- `AGENTS.md`;
- `CODEX_TASK.md`;
- this workflow;
- current model call chain involving `wing_model`;
- current parameter definitions;
- current GUI parameter catalog;
- current trim and validation scripts relevant to the 0 deg nacelle sweep;
- tests that currently exercise wing forces, trim, continuity, and GUI parameter handling.

Inspect only the committed isolated worktree.

### 5.2 Baseline reproduction

Before any production modification:

1. Run the existing focused wing tests.
2. Run the existing 0 deg nacelle trim sweep or the smallest available reproduction of the local bump.
3. Save baseline curves and numerical outputs.
4. Confirm the current `branchWeight`, `FNear`, and `FLiftLine` behavior using the existing diagnostic path.
5. Record runtime and exact commands.
6. Do not alter any parameter to improve the baseline.

If the baseline cannot be reproduced on the task branch, diagnose the branch mismatch or missing committed files. Continue all data stages while documenting the baseline limitation.

### 5.3 Legacy backup and parallel architecture plan

Create a byte-traceable legacy preservation plan.

Preferred structure, adjusted only as required by actual code dependencies:

- extract the existing implementation into `model/wing/wing_model_legacy.m`;
- keep `model/wing_model.m` as the stable public entry point;
- add `model/wing/wing_model_full_angle.m`;
- dispatch using an explicit parameter such as `P.wing.modelType`;
- default `P.wing.modelType = 'legacy'`.

Before changing the entry point, add an exact-regression test proving that the legacy path reproduces the original implementation at representative states to machine precision or a justified floating-point tolerance.

If the current file contains local helper functions that prevent direct extraction, perform the smallest mechanical refactor required and prove output identity before any new physics is enabled.

Gate:

- `LEGACY_PRESERVATION = PASS/PARTIAL/BLOCKED/FAIL`
- `LEGACY_REGRESSION = PASS/PARTIAL/BLOCKED/FAIL`

Do not continue to production default switching at any point in this task.

## 6. Stage 1 — data requirement freeze and source manifest

Build a parameter/data requirement matrix before generating aerodynamic data.

Minimum fields:

- airfoil coordinate source;
- XFOIL Reynolds range;
- Mach range;
- transition/roughness assumptions;
- control-surface hinge location and deflections;
- low-angle `Cl`, `Cd`, `Cm`;
- post-stall bridge;
- near ±90 deg data;
- full-angle periodic closure;
- wing span, area, chord distribution, installation angle, twist;
- strip locations;
- aerodynamic reference point;
- CG-relative moment arms;
- rotor hub positions;
- rotor radius;
- rotor axis direction;
- disk-to-wing distance;
- wake radius or contraction model;
- local induced velocity input;
- wake overlap geometry;
- free-stream and wake-region centroids;
- numerical interpolation settings;
- validity ranges and extrapolation behavior.

For every item record:

- purpose;
- required/optional;
- source;
- page/figure/table/equation;
- original value and unit;
- SI conversion;
- source class;
- uncertainty;
- current status;
- blocking impact.

Create:

- `data/wing_full_angle/source_manifest.csv`;
- `data/wing_full_angle/parameter_requirement_matrix.csv`;
- `docs/wing_full_angle/DATA_REQUIREMENT_FREEZE.md`.

Gate:

- `DATA_REQUIREMENT_FREEZE = PASS/PARTIAL/BLOCKED/FAIL`

Proceed automatically even if some non-critical items remain partial.

## 7. Stage 2 — source acquisition and verification

Acquire and verify, at minimum:

1. NASA TM-88373  
   `https://ntrs.nasa.gov/api/citations/19870005749/downloads/19870005749.pdf`

2. NASA CR-114614  
   `https://ntrs.nasa.gov/api/citations/19730022217/downloads/19730022217.pdf`

3. NASA CR-176970  
   `https://ntrs.nasa.gov/api/citations/19860020297/downloads/19860020297.pdf`

4. Existing repository sources:
   - NASA TM-X-62407;
   - NASA TM-81244;
   - NUAA main paper.

Clarify in the report that `CR-11461` was a truncated reference label and identify the exact source actually used.

For every downloaded source record:

- title;
- report number;
- NASA document ID;
- URL;
- local path;
- file size;
- page count;
- SHA256;
- PDF-header validity;
- whether text extraction is available;
- whether OCR is needed.

Do not accept an HTML error page as a PDF.

Gate:

- `SOURCE_ACQUISITION = PASS/PARTIAL/BLOCKED/FAIL`

## 8. Stage 3 — airfoil candidate selection and coordinate validation

### 8.1 Candidate policy

Do not assume that exact XV-15 reproduction is the project objective.

Evaluate at least:

- NACA 64A223, because TM-88373 provides a directly connected near-vertical-flow test data chain;
- any other airfoil with a stronger complete, traceable coordinate and full-angle data chain discovered during the search.

Score each candidate on:

- coordinate traceability;
- low-angle calculability;
- availability of `Cl/Cd/Cm`;
- near-stall and post-stall evidence;
- near ±90 deg evidence;
- control-surface compatibility;
- relevance to tiltrotor use;
- numerical smoothness and robustness;
- amount of unsupported extrapolation;
- ease of parameterization.

Automatically select the highest-evidence candidate for the new-model baseline. If two candidates remain materially tied and lead to different physics, this is one of the few legitimate user-decision points. Otherwise select and document without stopping.

### 8.2 NACA 64A223 coordinate route

For NACA 64A223:

1. Find an authoritative coordinate table or traceable NACA 6-series generation algorithm.
2. Prefer NASA/NACA original data or a documented standard implementation.
3. Record algorithm, input designation, coordinate convention, point count, and provenance.
4. Validate:
   - point ordering;
   - upper/lower surface monotonicity;
   - leading-edge closure;
   - trailing-edge gap;
   - no self-intersection;
   - thickness ratio;
   - thickness location;
   - camber and camber location;
   - XFOIL `LOAD` and `PANE`.

If a generated geometry and a published coordinate table both exist, compare them.

Create:

- `data/wing_full_angle/airfoils/`;
- `data/wing_full_angle/airfoil_candidate_scores.csv`;
- `data/wing_full_angle/airfoil_geometry_checks.csv`;
- `docs/wing_full_angle/AIRFOIL_SELECTION_REPORT.md`.

Gate:

- `AIRFOIL_SELECTION = PASS/PARTIAL/BLOCKED/FAIL`
- `AIRFOIL_GEOMETRY = PASS/PARTIAL/BLOCKED/FAIL`

## 9. Stage 4 — XFOIL low- and moderate-angle database

Use the verified executable:

`E:\tiltrotor\tools\external\xfoil\xfoil.exe`

Verify its identity before runs:

- size: `1002125` bytes;
- SHA256: `C17342F84AE260C2B11A74CD0E2FB8189A5F8954C6BB7A8467A0F27055C7FAEA`.

### 9.1 Baseline grid

At minimum evaluate:

- Reynolds numbers: `0.6e6`, `1.0e6`, `1.4e6`;
- Mach: incompressible/0 and `0.10`;
- clean airfoil;
- control-surface configurations required by the selected geometry;
- alpha from `-25 deg` to `+25 deg`;
- step `0.5 deg` or `1 deg`;
- positive and negative sweeps separately;
- iteration limit at least 200, increased only with logging.

For a 25 percent chord trailing control surface, run at least:

- `0, 20, 40, 50, 60 deg`

when geometrically meaningful and when XFOIL geometry modification remains valid. Do not fabricate converged results at large deflections.

### 9.2 Autonomous convergence strategy

Automatically:

1. start near zero angle;
2. continue in small increments;
3. retry from the nearest converged state;
4. reverse sweep direction;
5. locally reduce alpha step;
6. increase iterations within a documented cap;
7. separate geometry-generation failure from viscous convergence failure.

Store every attempted point with:

- requested condition;
- convergence status;
- iteration count if available;
- retry path;
- raw output;
- final accepted/rejected status.

Determine each polar's reliable endpoint from convergence and curve behavior. Do not hard-code one universal stall angle.

### 9.3 Outputs

Create:

- raw XFOIL inputs and logs;
- parsed polar CSV files;
- convergence maps;
- plots for `Cl`, `Cd`, and `Cm`;
- source/condition manifest.

Gate:

- `XFOIL_LOW_ANGLE_DATA = PASS/PARTIAL/BLOCKED/FAIL`

## 10. Stage 5 — TM-88373 digitization and full-angle construction

### 10.1 TM-88373 extraction

Systematically extract and digitize:

- airfoil identity;
- model chord/span;
- coefficient definitions;
- moment reference;
- Reynolds range;
- alpha range;
- flap definitions;
- `Cl(alpha)`, `Cd(alpha)`, `Cm(alpha)` curves;
- Reynolds sensitivity;
- discontinuities, unsteadiness, separation, and hysteresis notes.

Priority:

1. baseline leading edge with the flap geometry closest to the selected production candidate;
2. `alpha = -75 deg` to `-105 deg`;
3. control-surface deflections actually shown in the source;
4. `Cl`, `Cd`, and `Cm`;
5. repeated digitization for the most important curves.

For each digitized curve save:

- source page image;
- axis calibration;
- selected points;
- CSV;
- overlay image;
- point count;
- estimated x/y uncertainty;
- repeated digitization;
- RMS and maximum difference;
- notes on multivalued or unstable regions.

Do not smooth away documented physical abrupt changes.

### 10.2 Direct numerical anchors

Verify and include, when confirmed in the source:

- NACA 64A223;
- alpha range approximately `-75 deg` to `-105 deg`;
- Reynolds range approximately `0.6e6` to `1.4e6`;
- quarter-chord moment reference;
- XV-15 wake inflow angle range around `-80 deg` to `-88 deg`, mean about `-84 deg`, and opposite-rotation estimate around `-96 deg`;
- relevant flap minimum-drag and coefficient anchors.

### 10.3 Post-stall candidates

Implement and compare at least:

A. constrained separated-flow/flat-plate asymptotic model;  
B. endpoint-value and endpoint-slope constrained Hermite/PCHIP bridge;  
C. Viterna-type candidate, clearly labeled and prevented from silently importing finite-wing wind-turbine assumptions.

Treat positive and negative alpha sides independently.

### 10.4 Full-angle database rules

The final database must:

- use XFOIL in its reliable range;
- use digitized experiment in its valid near-vertical range;
- use an explicit bridge only where data are absent;
- use fixed alpha-based source transition regions;
- never use flight speed as a source-selection weight;
- blend coefficients or construct one interpolant, not blend complete force/moment model outputs;
- be at least C0 continuous everywhere;
- target C1 continuity except where a documented physical discontinuity requires a narrow, explicit representation;
- have bounded interpolation slopes;
- avoid spline overshoot;
- define behavior through ±180 deg;
- close consistently at periodic boundaries;
- mark all unverified positive deep-stall intervals.

### 10.5 Cm extension

For `Cm`:

- use XFOIL in its reliable range;
- use TM-88373 quarter-chord `Cm` in its valid range;
- use constrained PCHIP/Hermite in gaps;
- prohibit unconstrained high-order polynomial fits;
- check amplitude, slope, oscillation, and periodic closure;
- label untested regions explicitly.

Create:

- `data/wing_full_angle/tm88373_digitized/`;
- `data/wing_full_angle/full_angle_candidates/`;
- `data/wing_full_angle/full_angle_selected/`;
- `validation/wing_full_angle/full_angle/`;
- `docs/wing_full_angle/FULL_ANGLE_DATABASE_REPORT.md`.

Gate:

- `TM88373_DIGITIZATION = PASS/PARTIAL/BLOCKED/FAIL`
- `POST_STALL_EXTENSION = PASS/PARTIAL/BLOCKED/FAIL`
- `CM_EXTENSION = PASS/PARTIAL/BLOCKED/FAIL`
- `FULL_ANGLE_DATABASE = PASS/PARTIAL/BLOCKED/FAIL`

## 11. Stage 6 — rotor-wake/wing strip model

### 11.1 Required structure

Build an offline strip model first.

For every strip compute:

- strip position;
- local chord;
- local twist/incidence;
- free-stream local velocity;
- rotational velocity contribution;
- left/right rotor induced velocity contribution;
- local alpha;
- local Reynolds number;
- local Mach number;
- local dynamic pressure;
- wake coverage fraction;
- common `Cl/Cd/Cm` lookup;
- local aerodynamic force;
- quarter-chord section moment;
- CG-relative force-arm moment.

Free-stream and wake parts of a partially covered strip must use the same coefficient database.

Forbidden:

- `FNear`/`FLiftLine` complete-result blending;
- speed-dependent aerodynamic-branch weights;
- force-level smoothing introduced only to remove the bump;
- hidden coefficient clipping;
- NaN/Inf replacement with zero.

### 11.2 Wake geometry

Use CR-114614 and CR-176970 to extract the minimum required framework:

- wake radius or contraction;
- conversion/nacelle angle;
- rotor-axis direction;
- wing/disk relative position;
- immersed area or strip coverage;
- local wake angle;
- local dynamic pressure;
- left/right asymmetry;
- download integration.

Use existing rotor-model induced velocity outputs when physically compatible. Do not copy a Model 301-specific empirical `Ki` if the current rotor model already provides induced velocity. If the current rotor interface lacks the needed output, define a clean interface in the new model path without changing the legacy path.

Use XV-15 geometric values only where they are source-traceable and needed for the validation case. Keep geometry parameterized.

### 11.3 CR-176970 validation case

Reproduce the report's strip-integration logic using documented values such as:

- rotor diameter around `25 ft`;
- wing chord around `5.25 ft`;
- disk-to-wing distance around `4.67–5 ft`;
- one-foot spanwise strips;
- reported near-vertical flap `Cd` values;
- sum strip download and normalize by rotor thrust.

The exact report table/figure locations and assumptions must be recorded.

### 11.4 Offline tests

At minimum:

1. zero wake coverage equals free-stream-only result;
2. full wake coverage equals wake-only local-flow result;
3. partial coverage is continuous in area fraction;
4. uniform local flow agrees with direct `q*S*C`;
5. left/right symmetric conditions yield zero incremental roll/yaw;
6. asymmetric induced velocity yields physically consistent roll/yaw direction;
7. grid refinement `1 ft -> 0.5 ft -> 0.25 ft` converges;
8. alpha sweep through `-80 deg` to `-96 deg` agrees with experimental anchors;
9. all outputs and derivatives are finite and real;
10. speed sweeps contain no branch-switch curvature;
11. force direction opposes/aligns with the correct local flow axes;
12. moment reference conversion is correct.

Create:

- `tools/wing_full_angle/offline_strip_model/`;
- `validation/wing_full_angle/wake_strip/`;
- `docs/wing_full_angle/WAKE_STRIP_MODEL_REPORT.md`.

Gate:

- `WAKE_STRIP_MODEL = PASS/PARTIAL/BLOCKED/FAIL`
- `WAKE_GRID_CONVERGENCE = PASS/PARTIAL/BLOCKED/FAIL`
- `WAKE_SOURCE_TRACEABILITY = PASS/PARTIAL/BLOCKED/FAIL`

Do not enter production implementation unless the offline strip model is at least `PARTIAL` with no unresolved structural failure. A missing optional validation case may remain partial; a return to complete-result blending is a failure.

## 12. Stage 7 — production parallel implementation

### 12.1 Architecture

Implement a new production path under `model/wing/` with clear modules, for example:

- `wing_model_legacy.m`;
- `wing_model_full_angle.m`;
- `wing_full_angle_lookup.m`;
- `wing_strip_geometry.m`;
- `wing_wake_coverage.m`;
- `wing_local_flow.m`;
- `wing_integrate_strips.m`;
- `load_wing_aero_database.m`.

Names may differ after inspecting project conventions.

Keep `model/wing_model.m` as the stable public API. Add dispatch using an explicit model choice. Default remains legacy.

### 12.2 Data packaging

Package selected data in a format compatible with MATLAB R2021a:

- source CSV retained for audit;
- generated `.mat` allowed for runtime efficiency;
- generation script retained;
- dataset version/hash stored;
- no absolute machine-specific paths;
- project-relative path resolution;
- explicit units and coefficient conventions.

### 12.3 Parameter system

Add only parameters required by the new model:

- model selector;
- database identifier;
- strip count or spacing;
- geometry;
- wake options;
- interpolation/extrapolation settings;
- control-surface geometry;
- source metadata where appropriate.

Default selector remains legacy. New-model parameters may exist without affecting legacy output.

Every new parameter must have:

- user-facing Chinese name;
- physical meaning;
- unit;
- valid range;
- default;
- source/status;
- validation rule;
- whether it affects legacy mode.

### 12.4 Exact legacy regression

Run exact or near-machine-precision comparisons across representative states:

- hover/0 deg nacelle;
- low-speed helicopter;
- conversion;
- airplane mode;
- positive and negative angles;
- control inputs;
- symmetric and asymmetric cases.

Legacy outputs before and after refactor must match within a justified tolerance.

Gate:

- `PRODUCTION_PARALLEL_IMPLEMENTATION = PASS/PARTIAL/BLOCKED/FAIL`
- `LEGACY_OUTPUT_IDENTITY = PASS/PARTIAL/BLOCKED/FAIL`

## 13. Stage 8 — model-level and trim validation

### 13.1 Unit and physics checks

Test:

- coefficient lookup continuity;
- derivative boundedness;
- periodic closure;
- no NaN/Inf/complex values;
- lift/drag direction;
- moment sign conventions;
- left/right symmetry;
- unit consistency;
- strip-grid convergence;
- wake coverage geometry;
- no total-area exceedance;
- action point inside its region;
- data-source metadata completeness.

### 13.2 Focused bump validation

Reproduce the original 0 deg nacelle speed sweep with:

- legacy model;
- new model;
- fixed legacy branchWeight diagnostic if available.

Compare:

- wing force components;
- wing pitching moment;
- local coefficient behavior;
- trim pitch attitude;
- collective;
- longitudinal cyclic;
- elevator where applicable;
- first and second numerical differences with respect to speed.

The new model must not contain a source-selection feature tied to speed. It must demonstrate that the local bump caused by dynamic complete-result blending is removed without tuning trim variables or unrelated parameters.

### 13.3 Full trim/validation suite

Run, at minimum:

- helicopter mode sweep;
- conversion sweeps at representative nacelle angles;
- airplane mode sweep;
- existing NUAA trend checks;
- trim credibility diagnostics;
- numerical linearization smoke tests;
- relevant GUI service tests;
- full `run_all_checks`.

The user authorizes long runs. Estimate work before broad sweeps, log the estimate, then proceed automatically. No approval is required for runs up to 8 hours. If expected runtime exceeds 8 hours, checkpoint results, reduce density only where scientifically justified, and continue with staged sweeps. Do not silently skip required coverage.

### 13.4 Acceptance metrics

Define and report:

- trim convergence rate;
- residuals;
- continuity metrics;
- maximum local curvature;
- coefficient and derivative bounds;
- grid-convergence error;
- legacy regression error;
- trend agreement;
- runtime.

A smoother curve alone is not sufficient. The model must remain physically traceable and consistent.

Gate:

- `MODEL_PHYSICS_TESTS = PASS/PARTIAL/BLOCKED/FAIL`
- `ZERO_NACELLE_BUMP_TEST = PASS/PARTIAL/BLOCKED/FAIL`
- `TRIM_VALIDATION = PASS/PARTIAL/BLOCKED/FAIL`
- `FULL_REGRESSION = PASS/PARTIAL/BLOCKED/FAIL`

## 14. Stage 9 — GUI and user-facing parameter integration

Only after the new production model and regression gates pass:

1. Add a user-facing model selector in an appropriate advanced/model settings area.
2. Keep the default as the legacy model.
3. Do not expose raw code variable names or solver jargon.
4. Group parameters by physical meaning.
5. Show source/status for each parameter.
6. Validate units and ranges.
7. Ensure project save/load preserves model selection and parameters.
8. Add GUI tests.
9. Do not change the home page into an XV-15 validation claim.

Suggested Chinese labels:

- `机翼气动模型`
- `现有模型`
- `全迎角条带模型`
- `翼型气动数据`
- `机翼条带数量`
- `旋翼尾流覆盖`
- `尾流收缩设置`
- `控制面几何`

Gate:

- `GUI_PARAMETER_INTEGRATION = PASS/PARTIAL/BLOCKED/FAIL`

## 15. Stage 10 — documentation, commits, Draft PR, and final gate

### 15.1 Required reports

Create:

- `docs/wing_full_angle/MASTER_WORKFLOW_REPORT.md`;
- `docs/wing_full_angle/AIRFOIL_SELECTION_REPORT.md`;
- `docs/wing_full_angle/FULL_ANGLE_DATABASE_REPORT.md`;
- `docs/wing_full_angle/WAKE_STRIP_MODEL_REPORT.md`;
- `docs/wing_full_angle/PRODUCTION_INTEGRATION_REPORT.md`;
- `docs/wing_full_angle/VALIDATION_REPORT.md`;
- `docs/wing_full_angle/GUI_INTEGRATION_REPORT.md`;
- `docs/wing_full_angle/OPEN_ISSUES_AND_ASSUMPTIONS.md`.

### 15.2 Milestone commits

Create and push milestone commits when each logical package is stable:

1. source/data requirements;
2. airfoil coordinates and XFOIL;
3. TM digitization and full-angle database;
4. offline wake-strip model;
5. legacy extraction and parallel production path;
6. parameter system and GUI;
7. validation and final documentation.

Do not force-push. Do not merge.

Create or update a Draft PR against the appropriate technical base branch. If the remote base is older than the local committed technical baseline, document the situation and avoid pretending that `main` is the current project state.

### 15.3 Final status table

Report each gate:

- `LEGACY_PRESERVATION`
- `LEGACY_REGRESSION`
- `DATA_REQUIREMENT_FREEZE`
- `SOURCE_ACQUISITION`
- `AIRFOIL_SELECTION`
- `AIRFOIL_GEOMETRY`
- `XFOIL_LOW_ANGLE_DATA`
- `TM88373_DIGITIZATION`
- `POST_STALL_EXTENSION`
- `CM_EXTENSION`
- `FULL_ANGLE_DATABASE`
- `WAKE_STRIP_MODEL`
- `WAKE_GRID_CONVERGENCE`
- `WAKE_SOURCE_TRACEABILITY`
- `PRODUCTION_PARALLEL_IMPLEMENTATION`
- `LEGACY_OUTPUT_IDENTITY`
- `MODEL_PHYSICS_TESTS`
- `ZERO_NACELLE_BUMP_TEST`
- `TRIM_VALIDATION`
- `FULL_REGRESSION`
- `GUI_PARAMETER_INTEGRATION`

Each must be one of:

- `PASS`
- `PARTIAL`
- `BLOCKED`
- `FAIL`

Overall:

- `FULL_WING_MODEL_GATE = PASS/PARTIAL/BLOCKED/FAIL`

### 15.4 Meaning of overall PASS

Overall PASS requires:

1. legacy model preserved and default unchanged;
2. selected airfoil and coordinates traceable;
3. low-angle data generated and audited;
4. full-angle data constructed with explicit source boundaries;
5. `Cm` handled without hidden assumptions;
6. wake/free-stream regions use one coefficient law;
7. no dynamic complete-result blending;
8. offline strip model validated;
9. production new model implemented in parallel;
10. legacy output identity demonstrated;
11. zero-nacelle local bump structural trigger removed in the new path;
12. trim and regression tests pass or have only explicitly accepted non-structural partial items;
13. GUI and parameter system integrated without changing default behavior;
14. all assumptions and source gaps disclosed;
15. branch pushed and Draft PR prepared.

Even after PASS:

- do not switch the default model;
- do not delete the legacy model;
- do not merge the PR.

At that point, request one final user approval for default switching and merge.

## 16. Final response requirements

Do not return a progress report after ordinary intermediate stages.

Continue until:

- all autonomous work is complete;
- all possible tests have run;
- reports are generated;
- commits are pushed;
- Draft PR is prepared;
- the final gate is determined.

The final response must include:

- branch;
- commit SHAs;
- Draft PR link/number if created;
- modified/new file list;
- source/data summary;
- chosen airfoil and why;
- full-angle construction summary;
- wake model summary;
- legacy identity results;
- 0 deg nacelle bump results;
- trim/regression results;
- GUI/default status;
- gate table;
- the single remaining approval request, if overall PASS is achieved.

Do not ask the user to approve routine engineering steps.
