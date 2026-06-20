# CODEX_TASK.md

STATUS: COMPLETE / GUI ANALYSIS WORKBENCH / MATLAB R2021a VERIFIED / HOLD

Branch: `feature/gui-analysis-workbench`

Base branch: `main`

Draft PR: #9 (`https://github.com/x162645/tiltrotor-matlab/pull/9`)

## Purpose

Complete and verify a user-friendly MATLAB R2021a visual workbench for the existing tiltrotor concept model. The workbench must provide:

- critical parameter editing and validation;
- symmetric trim;
- numerical linearization and modal display;
- linear small-disturbance control response;
- analysis-session export.

The current implementation has already been added to the branch. Local Codex must review it, run the staged MATLAB checks, make only necessary compatibility or correctness fixes, and push the verified result.

## Read first

1. `AGENTS.md`
2. `CODEX_TASK.md`
3. `docs/GUI_ARCHITECTURE_AND_REQUIREMENTS.md`
4. `startup.m`
5. `run_app.m`
6. `app/launch_tiltrotor_app.m`
7. all files in `services/`
8. `tests/check_gui_services.m`
9. `params_nominal.m`
10. `analysis/trim_symmetric.m`
11. `analysis/linearize_numeric.m`
12. `model/tiltrotor_eom.m`
13. `model/total_forces_moments.m`
14. `tests/run_all_checks.m`

Before editing, run:

```powershell
git status --short
git branch --show-current
git log -1 --oneline
```

Stop and report if the branch is wrong or the worktree contains unrelated modifications.

## Architectural boundaries

The GUI and service layer may call existing model and analysis functions. They must not duplicate or alter the physical equations.

Do not modify:

- rotor, wing, fuselage, tail, mass-property, force/moment, or rigid-body formulas;
- control mapping or control signs;
- nominal physical parameter values;
- trim objective, solver settings, thresholds, limits, or seeds;
- numerical linearization equations or current default steps;
- parameter-source inventory or the separate Draft PR #8 work.

The GUI must continue to hold a runtime copy of `P`; it must not write user edits back into `params_nominal.m`.

## Required review

### 1. Static MATLAB R2021a compatibility

Review all new `.m` files for:

- valid function and nested-function structure;
- APIs available in MATLAB R2021a;
- valid `uigridlayout`, `uitabgroup`, `uitable`, `uiaxes`, callback, and layout usage;
- row/column spans and table sizing;
- correct use of cell arrays, strings, character vectors, and `newline`;
- finite-value and dimension checks;
- no hidden Control System Toolbox dependency;
- no swallowed exceptions.

If a UI component is not supported exactly as written in R2021a, replace it with the smallest compatible implementation.

### 2. Service contract checks

Confirm:

- `validate_parameter_set` accepts default parameters and rejects invalid mass/inertia/steps/limits;
- `run_trim_case` converts degree inputs to radians exactly once;
- `run_linearization_case` rejects unconverged trim and returns finite 9x9/9x7 matrices;
- `simulate_linear_response` integrates `delta_x_dot=A*delta_x+B*delta_u` without `ss` or `lsim`;
- step, pulse, sine, and doublet signals have correct timing and amplitude;
- actual state/control values equal trim values plus perturbations;
- control-limit warnings evaluate left/right collective and cyclic combinations correctly;
- MAT export retains parameters and available results.

### 3. UI workflow checks

Open the application and verify:

1. `run_app` opens one workbench window;
2. parameter table fills the available tab area and edits only the numeric column;
3. invalid edits are rejected and reverted;
4. valid parameter edits invalidate all old results;
5. default hover trim completes and displays states, controls, residuals, forces, and moments;
6. linearization remains disabled until trim is accepted;
7. A/B tables and eigenvalue plot are legible;
8. response remains disabled until linearization succeeds;
9. selected input/output plots update correctly;
10. switching between perturbation and actual-state display works;
11. exported `.mat` file can be loaded and contains the expected `session` structure;
12. closing the UI leaves no destructive project changes.

## Runtime discipline

Do not start with dense speed sweeps, transition scans, multiple response grids, Jacobian maps, or Monte Carlo runs.

### Stage 0 — static checks

Run lightweight parser/path checks first:

```powershell
& 'F:\matlab\R2021a\bin\matlab.exe' -batch "cd('E:\tiltrotor'); startup; which run_app; which launch_tiltrotor_app; which validate_parameter_set; which run_trim_case; which run_linearization_case; which simulate_linear_response;"
```

Use `checkcode` on every new or modified `.m` file. Record errors and actionable warnings.

### Stage 1 — focused service integration

Run exactly one focused service chain:

```powershell
& 'F:\matlab\R2021a\bin\matlab.exe' -batch "cd('E:\tiltrotor'); startup; report = check_gui_services; assert(report.allPassed);"
```

This performs one default hover trim, one linearization, and one short response. If it fails, stop the staged sequence, diagnose the first failure, make a minimal fix, and repeat Stage 0 and Stage 1.

### Stage 2 — existing regression

Only after Stage 1 passes:

```powershell
& 'F:\matlab\R2021a\bin\matlab.exe' -batch "cd('E:\tiltrotor'); startup; summary = run_all_checks; assert(summary.allPassed);"
```

Do not add the GUI integration chain to `run_all_checks` if doing so would duplicate the expensive hover trim and linearization. Keep it as the focused pre-regression check.

### Stage 3 — interactive UI smoke test

Open MATLAB normally and run:

```matlab
cd('E:\tiltrotor');
run_app;
```

Use the manual sequence in `docs/GUI_ARCHITECTURE_AND_REQUIREMENTS.md`. Capture only concise observations; do not perform broad parameter sweeps.

The known R2021a shutdown-stage `mwboost::archive::archive_exception: output stream error` must be reported separately from completed test-body assertions.

## Allowed files

Necessary fixes are limited to:

```text
CODEX_TASK.md
startup.m
run_app.m
app/launch_tiltrotor_app.m
services/validate_parameter_set.m
services/run_trim_case.m
services/run_linearization_case.m
services/simulate_linear_response.m
services/save_analysis_case.m
tests/check_gui_services.m
docs/GUI_ARCHITECTURE_AND_REQUIREMENTS.md
```

A new focused GUI test helper may be added only when an R2021a compatibility defect cannot be tested inside `check_gui_services.m`.

## Prohibited changes

- no `.mlapp` binary replacement during this task;
- no changes to physical model files;
- no changes to `params_nominal.m` values;
- no changes to trim or linearization formulas;
- no new toolboxes or third-party dependencies;
- no suppression of NaN, Inf, complex values, nonconvergence, or UI errors;
- no large refactor unrelated to the GUI workflow;
- no merge of this Draft PR;
- no changes to Draft PR #8 or branch `refactor/split-rh-mass-hub`.

## Acceptance criteria

The task is complete only when:

- Stage 0 has no parser errors;
- `check_gui_services` passes all focused checks;
- existing `run_all_checks` remains all PASS;
- R2021a opens the application successfully;
- the default hover trim -> linearization -> 0.1 deg response workflow succeeds;
- invalid parameter edits are rejected;
- no Control System Toolbox dependency exists;
- no physical-model or nominal-parameter change appears in the diff;
- the exported session loads successfully;
- the final Git diff contains only allowed changes;
- the worktree is clean after commit and push.

## Closeout

After all acceptance criteria pass, update this file to:

```text
STATUS: COMPLETE / GUI ANALYSIS WORKBENCH / MATLAB R2021a VERIFIED / HOLD
```

Final report must include:

- files read;
- files changed;
- static `checkcode` findings and fixes;
- Stage 1 and Stage 2 results;
- interactive smoke-test observations;
- confirmation that model equations and nominal physical values were unchanged;
- confirmation that Control System Toolbox is not required;
- commit SHA;
- clean `git status --short` output.

Commit and push to `feature/gui-analysis-workbench`.

Do not merge the Draft PR.
