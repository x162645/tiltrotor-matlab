# XFOIL Preflight Task

Perform a read-only preflight for Stage 1 of `docs/WING_AERO_REPLACEMENT_WORKFLOW.md`.

Read `AGENTS.md` and the workflow document first. Report the current branch, HEAD, `git status --short`, tracked changes, and untracked files. If the worktree is not clean, stop and report `PREFLIGHT_BLOCKED` without changing the repository.

Check whether this provisional local executable is present:

`E:\tiltrotor\tools\external\xfoil\xfoil.exe`

Do not download software. If the executable is absent, report the missing dependency and stop. If present, determine the smallest non-interactive invocation design, required input/output files, timeout behavior, logs, and temporary-directory handling. Do not run a large polar sweep.

Identify the future integration boundaries for:

- XFOIL path configuration;
- an external-process runner;
- polar parsing and data representation;
- focused tests;
- production files that must remain unchanged during the smoke-test stage.

Return:

1. repository state;
2. XFOIL availability;
3. minimal invocation plan;
4. proposed files for the later implementation stage;
5. blockers and risks;
6. `PREFLIGHT_PASS` or `PREFLIGHT_BLOCKED`.

Do not modify, stage, commit, or push files during this preflight.
