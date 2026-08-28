# CODEX_TASK.md

STATUS: XV-15 FROZEN-M0 VALIDATION BASELINE EXECUTION / 2026-08-28

## Version contract

- Repository: `x162645/tiltrotor-matlab`.
- Base Draft PR: #69.
- Base branch: `audit/xv15-codex-handoff-metadata-consistency-20260828`.
- Exact base SHA: `ec35d115c65823dbb9e8b4892e8d8f6a510e80f2`.
- Task branch: `codex/xv15-validation-baseline-execution`.
- Draft PR: #70.
- Canonical task definition: `XV15_VALIDATION_TASKS.txt`.
- MATLAB execution environment for reproducible CI evidence: MATLAB R2021a on GitHub-hosted Actions.

## Objective

Validate, rather than modify, the frozen generic low-order production model M0 using XV-15 external evidence. The study must determine the error structure, supported operating domain, and limitations of M0 without changing production physics or tuning parameters against validation targets.

The present branch is limited to:

1. closing the M0 model identity and XV-15 validation-data role ledger;
2. executing the original-metal-blade V1 hover external correlation through the direct `rotor_model_bemt` path;
3. preserving failed and unsupported OARF points;
4. auditing NASA TM-86009 at report level for matched-condition and signal-chain homology;
5. allowing strict quantitative dynamic validation only if a case passes the explicit HIGH-homology gate;
6. packaging actual MATLAB execution evidence and the final applicability conclusion.

## Frozen scientific boundary

M0 is the existing production low-order model. This task shall not modify production physical-model functions, default generic model physics, state/input ordering, or the physical equations in order to improve XV-15 agreement.

The following are excluded from the M0 baseline validation path:

- `rotor_model_bemt_section_aero`;
- nonzero `alpha0L` extension;
- added compressibility correction;
- added Prandtl losses;
- Mangler or other new inflow models;
- prescribed/free-wake or Biot-Savart extensions;
- C81/radially resolved airfoil extensions not present in production M0.

Such items may only be retained as post-validation diagnostic/model-variant work and may not be used to redefine M0 after observing the validation error.

## Evidence roles

- XV-15 OARF Run 15: `DEVELOPMENT_EXTERNAL_CORRELATION`; it is not a blind holdout because it was used in prior diagnostics.
- NASA TM-86009: candidate aircraft-dynamics external evidence; quantitative validation requires report-level HIGH homology.
- Generic XV-15 values from unrelated reports: may support parameter/context research but must not be silently substituted for the exact TM-86009 test condition.
- Reference simulations: model benchmarks only; not independent physical ground truth.

## Required execution stages

1. Model-identity gate and validation-data-role closure.
2. Pure-M0 V1 MATLAB R2021a execution.
3. Numerical-convergence and failed-point preservation audit.
4. Commit textual V1 evidence and execution provenance.
5. TM-86009 report-level condition/input/output audit.
6. Rerun the TM-86009 gate after schema and evidence closure.
7. If at least one case is HIGH, execute matched-condition dynamic validation without tuning.
8. If no case is HIGH, stop strict dynamic validation and record the public-evidence limitation as the scientific result.
9. Update Draft PR #70 with executed results and unresolved evidence blockers.

## Stop conditions

- Do not modify production physics to reduce XV-15 error.
- Do not fit parameter values to OARF CT/CP/FM or TM-86009 response data.
- Do not delete failed or high-error points.
- Do not relabel OARF Run 15 as blind validation.
- Do not promote MEDIUM/LOW/PENDING TM-86009 cases to quantitative validation.
- Do not fill missing exact test mass, CG, inertia, RPM, or atmospheric state using unrelated generic XV-15 values.
- Do not call a successful regression test proof of aircraft validation.
- Do not fabricate page numbers, raw time histories, frequency-response data, uncertainty, or provenance.
- Do not merge any pull request without explicit user authorization.

## Current execution checkpoint

The first GitHub-hosted MATLAB R2021a execution was run at commit `06c0769af9edc6140f1bf9c19bf36ef9e19a74cb`, workflow run `33142436573`.

The pure-M0 V1 runner executed successfully. The initial TM-86009 gate reached the intended blocking stage but exposed an R2021a CSV-import/schema issue; that validation-tool issue is being corrected without altering aircraft physics. Report-level TM-86009 audit currently contains no HIGH-homology case.
