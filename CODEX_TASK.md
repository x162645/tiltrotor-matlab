# CODEX_TASK.md

STATUS: ACTIVE / FULL WING MODEL WORKFLOW

Instruction branch: `task/full-angle-wing-offline-prototype-20260702`

## Objective

Execute the complete workflow in:

`CODEX_FULL_WING_MODEL_AUTONOMOUS_WORKFLOW.md`

The work covers preservation of the current wing model, source acquisition, airfoil selection, XFOIL data generation, full-angle data construction, rotor-wake strip modeling, parallel production implementation, parameter and GUI integration, validation, reporting, milestone commits, push, and Draft PR preparation.

## Workspace

The original local repository may contain protected uncommitted work. Leave it unchanged.

Create an isolated worktree from the original repository's current committed `HEAD`:

- worktree: `E:\tiltrotor-full-wing-model`
- branch: `task/full-wing-model-autonomous-20260702`

Perform engineering work only in that isolated worktree. Do not clean, reset, stash, delete, or overwrite the original worktree.

## Autonomy

The user authorizes continuous execution of routine work without intermediate approval. This includes source download and verification, OCR, digitization, script creation and debugging, XFOIL runs, MATLAB runs, long validation sweeps, new-model implementation, tests, reports, milestone commits, push, and Draft PR creation.

Continue through independent stages when one sub-item is partial. Stop only for the hard-stop conditions listed in the workflow.

## Physical requirement

The new wing model must remove speed-dependent blending of complete `FNear` and `FLiftLine` results. Free-stream and rotor-wake regions must use one common full-angle aerodynamic coefficient law and differ only through local flow and geometry.

## Protection

- Preserve the legacy model.
- Implement the new model in parallel.
- Keep the legacy model as default.
- Do not delete the legacy model.
- Do not switch the default model.
- Do not merge the final PR.

## Completion

Return only after all workflow stages have been attempted, tests and validation have been run as far as possible, reports are complete, commits are pushed, a Draft PR is prepared, and `FULL_WING_MODEL_GATE` is reported.
