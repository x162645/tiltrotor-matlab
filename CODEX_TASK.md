# CODEX_TASK.md

STATUS: ACTIVE / GUI COMPREHENSIVE REVIEW AND REDESIGN / 2026-06-23

Branch: `feature/gui-v1.2-parameter-workbench`
Base branch: `main`

## Objective

Complete the GUI comprehensive review and redesign in one continuous task:

- remove the old user-level parameter classification system;
- classify parameters only by physical component and calculation module;
- rebuild parameter editing, trim, diagnostics, linearization, response,
  save/load, unsaved-change protection, and layout behavior;
- preserve MATLAB R2021a compatibility;
- do not change physical parameter values, model equations, trim algorithm,
  linearization algorithm, or response algorithm unless a clear interface bug
  is found and reported first.

## Required Instructions

Read and follow:

- `AGENTS.md`
- the remote task document
  `origin/docs/gui-comprehensive-review-20260623:docs/GUI_COMPREHENSIVE_REVIEW_AND_REDESIGN_TASK.md`

## Validation

Run focused GUI, parameter catalog, trim service, linearization service, and
response service tests first. Run a representative hover trim, linearization,
and response chain. Run `checkcode` on modified MATLAB files. Decide whether
`run_all_checks` is reasonable after focused tests and representative checks.

## Git

Protect existing uncommitted GUI work. Do not use destructive Git commands.
When the task is complete and tests are recorded, commit and push to the
current GUI work branch. Do not create or merge a PR.
