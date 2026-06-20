# CODEX_TASK.md

STATUS: ACTIVE / GUI V1.1A TRIM DIAGNOSTICS / LOCAL MATLAB VERIFICATION REQUIRED

Branch: `feature/gui-v1.1-trim-diagnostics`

Base branch: `main`

Previous completed work: PR #9, merged into `main` at `34c27a874bc2c856eb69f68ff0905b3234f644bb`.

## Purpose

Improve the existing MATLAB R2021a tiltrotor analysis workbench in one tightly scoped step:

1. make symmetric-trim success and failure easier to understand;
2. expose diagnostic information already produced by `trim_symmetric`;
3. convert caught MATLAB exceptions into a consistent user-facing diagnostic structure;
4. preserve all existing model, trim, linearization, and response calculations.

This task is GUI/service/test work only. Do not change physical equations, nominal parameters, trim equations, solver behavior, thresholds, seeds, control mapping, or linearization formulas.

## Read first

Read these files before editing:

1. `AGENTS.md`
2. `CODEX_TASK.md`
3. `docs/GUI_ARCHITECTURE_AND_REQUIREMENTS.md`
4. `app/launch_tiltrotor_app.m`
5. `services/run_trim_case.m`
6. `services/validate_parameter_set.m`
7. `tests/check_gui_services.m`
8. `analysis/trim_symmetric.m` — read only
9. `model/tiltrotor_eom.m` — read only
10. `model/total_forces_moments.m` — read only
11. `params_nominal.m` — read only
12. `tests/run_all_checks.m` — read only unless a compatibility defect requires a minimal test registration change; do not duplicate the expensive GUI service chain.

Before editing, run and report:

```powershell
git status --short
git branch --show-current
git log -1 --oneline
git diff --stat main...HEAD
```

Stop immediately if:

- the branch is not `feature/gui-v1.1-trim-diagnostics`;
- the worktree contains unrelated modifications;
- the branch is not based on the merged GUI work from `main`.

## Scope

Implement only the following V1.1a features.

### A. Trim diagnostic service

Add a pure service function, preferably:

```text
services/build_trim_diagnostic.m
```

It must accept a trim result returned by `run_trim_case` and return one stable structure for GUI display and tests.

Required fields:

```text
diagnostic.kind
diagnostic.success
diagnostic.severity
diagnostic.summary
diagnostic.reasonCodes
diagnostic.suggestions
diagnostic.overview
diagnostic.fullResiduals
diagnostic.limitItems
diagnostic.candidates
diagnostic.invalidEvaluationCount
diagnostic.invalidEvaluationIdentifiers
```

Required semantics:

- `kind`: `trim-diagnostic`;
- `success`: follows the accepted trim result;
- `severity`: `success`, `warning`, or `error`;
- `summary`: concise Chinese user-facing conclusion;
- `reasonCodes`: stable machine-readable cell array of codes;
- `suggestions`: concise Chinese actions grounded in actual report fields;
- `overview`: solver convergence, accepted status, residual norm, tolerance, full residual norm, at-limit state, violation state, candidate count, accepted candidate count, invalid evaluation count;
- `fullResiduals`: all nine state derivatives with names, values, units, and an objective/non-objective indicator;
- `limitItems`: theta, collective, and cyclicLong values, lower/upper limits, lower/upper margins, at-limit, violated, and display units in degrees;
- `candidates`: initial and final theta/collective/cyclicLong in degrees, cost, residual norm, exit flag, acceptable, at-limit, and within-limits;
- invalid-evaluation identifiers must be preserved exactly from the trim report.

Do not infer a cause that the report cannot support. Example reason codes may include:

```text
SOLVER_NOT_CONVERGED
OBJECTIVE_RESIDUAL_TOO_LARGE
NONFINITE_FULL_DERIVATIVE
CONTROL_AT_LIMIT
CONTROL_LIMIT_VIOLATION
INVALID_MODEL_EVALUATIONS
NO_ACCEPTABLE_CANDIDATE
```

Use only report data already produced by `trim_symmetric`. Do not rerun trim inside the diagnostic builder.

### B. Exception diagnostic service

Add a pure service function, preferably:

```text
services/build_exception_diagnostic.m
```

It must convert a caught `MException` plus stage and optional input snapshot into a stable structure:

```text
diagnostic.kind = 'exception-diagnostic'
diagnostic.stage
diagnostic.severity
diagnostic.identifier
diagnostic.summary
diagnostic.details
diagnostic.suggestions
diagnostic.inputSnapshot
diagnostic.stackSummary
```

Requirements:

- preserve `ME.identifier` and `ME.message`;
- include only a concise stack summary, not a giant raw dump;
- provide grounded suggestions for known identifiers already present in the project;
- use a safe generic suggestion for unknown identifiers;
- never suppress or relabel NaN, Inf, complex, nonconvergence, or model-domain failures as success;
- do not classify the known MATLAB shutdown-stage `mwboost::archive::archive_exception` as a model failure when it occurs after completed batch assertions; this batch-only distinction belongs in reporting/tests, not in ordinary GUI callbacks.

### C. Trim-page UI improvements

Modify `app/launch_tiltrotor_app.m` with the smallest R2021a-compatible change.

The Trim page must expose four result views:

1. **总览**
   - accepted/pass status;
   - solver status;
   - objective residual norm and tolerance;
   - full nine-state derivative norm;
   - limit status;
   - candidate accepted/total count;
   - invalid model evaluation count;
   - concise explanation and suggestions.

2. **状态与操纵**
   - preserve the existing state and control displays.

3. **残差与限幅**
   - show all nine state derivatives;
   - visually distinguish the three trim-objective derivatives `udot`, `wdot`, `qdot` from the other six;
   - show theta, collective, cyclicLong limits and remaining lower/upper margins in degrees;
   - show at-limit and violation flags.

4. **多初值候选**
   - show every candidate returned by the existing trim report;
   - display initial and final theta/collective/cyclicLong, cost, residual norm, exit flag, accepted, at-limit, within-limits;
   - handle exact hover, where only one candidate may exist.

Do not add charts in this step. Tables and concise status cards are sufficient and lower risk for R2021a.

### D. Current-operation diagnostic panel

Add a compact diagnostic panel in the workbench UI that displays the latest operation diagnostic for:

- parameter validation;
- trim;
- linearization;
- response;
- export.

Minimum functions:

- stage;
- severity;
- identifier or reason codes;
- summary;
- details;
- suggestions;
- a button to copy a plain-text diagnostic summary to the clipboard when supported by MATLAB R2021a.

Do not implement a persistent database, searchable log manager, source-code opener, or large history system. Keeping only the current/latest diagnostic is sufficient for V1.1a.

### E. State invalidation and error behavior

Preserve and verify:

- starting a new trim clears all old trim-dependent linearization and response results;
- a failed trim cannot enable linearization;
- caught errors leave the UI in a usable state;
- the busy pointer and button enables are restored by cleanup;
- invalid parameter edits still revert;
- no stale result appears as current after an error.

## UI wording

Use clear Chinese labels for user-facing text. Keep exact internal field names and error identifiers visible in technical-detail fields.

Avoid claims that the model is a validated XV-15 model. Continue to describe it as the current concept/mechanism model.

## Architectural boundaries

Allowed flow:

```text
GUI -> diagnostic service -> existing trim result/report
GUI -> existing run_trim_case -> existing trim_symmetric
```

Prohibited flow:

```text
GUI -> duplicated trim equations
Diagnostic service -> rerun trim
Diagnostic service -> modify P
GUI -> write params_nominal.m
```

Do not modify:

- `analysis/trim_symmetric.m`;
- `analysis/linearize_numeric.m`;
- `params_nominal.m`;
- any file under `model/`;
- physical formulas or nominal physical values;
- trim tolerance, objective, penalty, seeds, multistart logic, solver options, or limit definitions;
- response integration or waveform behavior;
- PR #8 or branch `refactor/split-rh-mass-hub`.

## Allowed files

Modify only when necessary:

```text
CODEX_TASK.md
app/launch_tiltrotor_app.m
services/build_trim_diagnostic.m
services/build_exception_diagnostic.m
services/run_trim_case.m
tests/check_gui_services.m
docs/GUI_ARCHITECTURE_AND_REQUIREMENTS.md
```

`services/run_trim_case.m` may only be extended to attach a diagnostic generated from the completed result. It must not change input conversion, trim invocation, success criteria, or returned physical values.

Do not modify `startup.m` unless a new folder is introduced. No new folder is needed for this task.

## Test requirements

Extend `tests/check_gui_services.m` without adding broad sweeps.

Required focused tests:

1. successful default hover diagnostic;
2. diagnostic contains nine finite full residual entries;
3. limit table contains theta, collective, cyclicLong with correct degree conversion and margins;
4. candidate table exists and accepted count is consistent with `report.candidateAcceptance`;
5. a synthetic nonconverged trim report produces `SOLVER_NOT_CONVERGED`;
6. a synthetic excessive-residual report produces `OBJECTIVE_RESIDUAL_TOO_LARGE`;
7. a synthetic at-limit report produces `CONTROL_AT_LIMIT`;
8. invalid-evaluation identifiers are preserved;
9. known and unknown `MException` values produce structured exception diagnostics;
10. existing trim -> linearization -> response chain still passes;
11. entry points resolve in MATLAB R2021a.

Prefer synthetic copies of the already computed default trim result to exercise failure classifications. Do not run extra expensive trim cases for each diagnostic condition.

## Runtime discipline

Follow this exact staged sequence.

### Stage 0 — static/path checks

Run `checkcode` on every changed or new `.m` file.

Then run:

```powershell
& 'F:\matlab\R2021a\bin\matlab.exe' -batch "cd('E:\tiltrotor'); startup; which run_app; which launch_tiltrotor_app; which build_trim_diagnostic; which build_exception_diagnostic;"
```

Stop and fix the first parser/path issue before continuing.

### Stage 1 — focused service test

```powershell
& 'F:\matlab\R2021a\bin\matlab.exe' -batch "cd('E:\tiltrotor'); startup; report = check_gui_services; assert(report.allPassed);"
```

This may perform the existing one hover trim, one linearization, and short response. Do not add speed sweeps, transition scans, Monte Carlo runs, or repeated full linearizations.

### Stage 2 — existing regression

Only after Stage 1 passes:

```powershell
& 'F:\matlab\R2021a\bin\matlab.exe' -batch "cd('E:\tiltrotor'); startup; summary = run_all_checks; assert(summary.allPassed);"
```

### Stage 3 — interactive UI smoke test

Open MATLAB normally:

```matlab
cd('E:\tiltrotor');
run_app;
```

Verify only:

1. one workbench window opens;
2. default hover trim succeeds;
3. overview values agree with the existing trim report;
4. all nine residual rows appear;
5. limit margins display in degrees;
6. candidate table displays;
7. a deliberately invalid GUI input creates a clear current diagnostic and leaves the UI usable;
8. a new valid trim clears the old error diagnostic;
9. linearization and response still work after a valid trim;
10. closing the UI leaves no project-file changes.

Report the known R2021a shutdown-stage `mwboost::archive::archive_exception: output stream error` separately from completed test-body assertions.

## Acceptance criteria

The task is complete only when:

- all required diagnostic fields exist and have stable types;
- default hover produces a successful trim diagnostic;
- synthetic failure classifications pass;
- no extra trim/linearization sweeps were introduced;
- the Trim page clearly displays overview, nine residuals, limits, and candidates;
- latest-operation exception diagnostics are visible and copyable;
- existing GUI workflow remains functional;
- `checkcode` has no parser errors or actionable warnings;
- `check_gui_services` passes;
- `run_all_checks` passes;
- no model, analysis, nominal-parameter, solver, or response-algorithm file changed;
- final diff contains only allowed files;
- worktree is clean after commit and push.

## Closeout

After all acceptance criteria pass, change the status line to:

```text
STATUS: COMPLETE / GUI V1.1A TRIM DIAGNOSTICS / MATLAB R2021A VERIFIED / HOLD
```

Commit and push to:

```text
feature/gui-v1.1-trim-diagnostics
```

Suggested commit message:

```text
feat(gui): add trim diagnostics and structured errors
```

Do not open or merge a pull request unless explicitly instructed after local verification.

Final report must include:

- files read;
- files changed;
- implementation summary;
- diagnostic reason codes implemented;
- `checkcode` results;
- path-check results;
- `check_gui_services` results;
- `run_all_checks` results;
- interactive UI observations;
- confirmation that no model/analysis/nominal-parameter files changed;
- confirmation that no broad sweep was run;
- final commit SHA;
- final `git status --short`;
- remaining limitations or unresolved issues.