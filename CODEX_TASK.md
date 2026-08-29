# CODEX_TASK.md

STATUS: STAGE 9 SHENG PUBLIC-FORMULA COMPARISON / M2 IDENTITY PREPARATION / 2026-08-29

## Version contract

- repository: `x162645/tiltrotor-matlab`
- current branch: `research/sheng-comparison-m2-nacelle-20260829`
- branch base: `9c7014ba7322eca220e4ff635e0b6f0d987ad025`
- frozen M0: `frozen/m0-xv15-hover-v1-20260828` @ `27f40883633ca14acc0e928649b62d7abb855491`
- frozen M1 research branch remains `research/m1-xv15-physics-enhanced-20260828`
- M1 Draft PR #71 remains open/unmerged and must not be merged without explicit user authorization.

Read `AGENTS.md` and `SHENG_COMPARISON_M2_CHARTER.md` before modification.

## Mainline

The research object is a generic low-order component-level tiltrotor flight-dynamics model. XV-15 is external evidence, not a reverse-fitting target.

Fixed method sequence:

`freeze identity -> external validation -> retain failures -> mechanism diagnosis -> new identity -> refreeze -> cross-data/facility validation -> credible domain -> next evidence layer`

M0 and frozen M1 evidence are immutable baselines for this branch.

## Stage 9 task

Convert the already-completed Sheng/NUAA audits into an executable comparison experiment. Do NOT redo the formula/parameter/assumption audit.

### Model identities

- `S0 = NUAA_PUBLIC_FORMULA_REFERENCE`
  - public-formula reproducible reference only;
  - not Sheng author code;
  - not an XV-15 model.
- `S0_XV15_MAPPED`
  - S0 evaluated with the same XV-15 metal-blade geometry/operating-point mapping used by M0;
  - role: `MODEL_FORM_DIAGNOSTIC`.
- `S0-N`
  - post-processing amplitude/shape decomposition only;
  - not a model, not a validation score.
- `M0`
  - frozen production low-order baseline.
- `M1_HOLDOUT_V1`
  - frozen generic Corrigan n=1 holdout identity; reuse without tuning.
- `D13`
  - existing 13-state one-way commanded nacelle dynamic scaffold.
- `M2`
  - reserved for future two-way nacelle mechanics; no M2 physics change is authorized until Stage 9 comparison evidence and mechanics contract are written.

### Fixed Stage 9 data window

Use OARF Run 15 original-metal-blade hover points at 0.75R collective:

`6, 7, 8, 9, 10, 11 deg`

Role: `DEVELOPMENT_EXTERNAL_CORRELATION` because these data have already been seen/used.

Do not redefine the window after execution.

### Required Stage 9 outputs

1. Point table for S0, M0 and frozen M1 with CT/CP/FM and retained failure status.
2. Raw error metrics on the fixed window.
3. S0-N diagnostic per CT/CP/FM:
   - least-squares scale `k*`;
   - scaled RMSE/MAPE for diagnostic characterization only;
   - Pearson correlation;
   - Spearman rank correlation;
   - local external/model ratio mean/std/CV;
   - raw vs scaled error change.
4. Explicit metadata saying `S0-N = DIAGNOSTIC_ONLY_NOT_MODEL_NOT_VALIDATION_SCORE`.
5. No parameter selection from OARF targets.
6. Real MATLAB R2021a GitHub Actions execution; never infer numerical results without execution.

## S1 boundary

Do not call conceptual-vs-XV-15 parameter differences bugs. Existing audits already distinguish true correctness issues, model simplifications and comparison-definition mismatches.

The next S1 experiment, after Stage 9, may implement analysis-only paper-specific trim definitions previously recommended by the NUAA root-cause audit, especially:

- NUAA 15 deg comparison with strict helicopter manipulation rather than the production cos^2/sin^2 mixed allocation;
- NUAA 75 deg comparison with fixed-wing control definition rather than mixed conversion control.

Do not modify production allocation merely to match the paper.

## D13 / M2 mechanics boundary

Existing D13 implements:

- left/right nacelle angle and rate states;
- second-order commanded actuator;
- actuator reaction torque;
- angle-dependent moving-point-mass CG/inertia;
- nacelle-rate rotor gyroscopic moment.

Existing metadata explicitly says the following are not implemented:

- `I_dot*omega` term;
- moving-mass acceleration reaction;
- external hinge torque feedback;
- mechanical jam load;
- higher-order transmission mechanics.

Current coupling identity: `PRESCRIBED_NACELLE_MOTION_TO_RIGID_BODY_ONE_WAY`.

Any addition of two-way hinge-load mechanics is M2 and requires a new model identity plus source/derivation audit before code implementation.

## Hard stop rules

- no frozen M0 changes;
- no frozen M1 changes;
- no OARF/WADC gain or offset fitting;
- no Corrigan exponent search;
- no wake tuning;
- no deleting failed points;
- no relabeling reused data blind;
- no generic XV-15 mass/CG/inertia substitution for blocked dynamic validation;
- no claim that S0 is author code;
- no claim that scaled S0-N is a physical model;
- no claim that D13 is full two-way multibody nacelle dynamics;
- no PR merge without explicit user authorization.
