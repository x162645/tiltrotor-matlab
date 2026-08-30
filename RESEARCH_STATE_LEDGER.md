# Research State Ledger

This file is the authoritative research-state checkpoint for the current M1 branch. New research work must start from the `NEXT_ALLOWED` item below; completed items must not be re-proposed as new work unless new evidence invalidates the recorded conclusion.

## Frozen baseline

- `M0` — `FROZEN`
  - Branch: `frozen/m0-xv15-hover-v1-20260828`
  - Commit: `27f40883633ca14acc0e928649b62d7abb855491`
  - Role: untuned generic low-order baseline for XV-15 validation-instance correlation.

## M1 completed stages

- `M1-A` — `FORMALLY_RUN`
  - Physics: real radial geometry + independent scalar C81.
  - MATLAB R2021a evidence exists in PR #71.
  - 6–11 deg: CT MAPE 33.9549%, CP MAPE 45.2392%, FM MAPE 4.4100%.
  - Do not re-propose as unfinished work.

- `M1-B` — `FORMALLY_RUN`
  - Physics: real radial geometry + full radial/Mach-dependent C81.
  - MATLAB R2021a evidence exists in PR #71.
  - 6–11 deg: CT MAPE 37.8538%, CP MAPE 50.5150%, FM MAPE 7.5480%.
  - More detailed 2-D aerodynamics did not improve on M1-A; retain this negative/inconclusive result.

- `M1-C` — `FORMALLY_RUN`
  - Physics: M1-B + annular momentum closure.
  - MATLAB R2021a evidence exists in PR #71.
  - 6–11 deg: CT MAPE 35.7519%, CP MAPE 47.9006%, FM MAPE 5.9849%.
  - Annular momentum gives only modest improvement and does not close the main residual.

## Previously screened directions

- `LOCAL_PRANDTL_ROOT_TIP_LOSS` — `FORMALLY_SCREENED_NEGATIVE`
  - PR #68 MATLAB screen showed it cannot explain the already-low CT/CP level.
  - Must not be recycled as a new mainline M1 task.

- `MASS_PROPERTY_SINGLE_FACTOR` — `FORMALLY_SCREENED_LOW_PRIORITY`
  - PR #68 representative-point screen showed no resolvable CT/CP/FM-scale contribution sufficient to explain the main discrepancy.

- `LOCAL_OR_EMPIRICAL_INFLOW_VARIANTS` — `PREVIEW_OR_SCREENED`
  - Mangler / Eq. 12 / related local-flow diagnostics already exist in PR #68.
  - Do not reopen unless a specific new hypothesis requires it.

## NEXT_ALLOWED

### `M1-D_LOADED_PITCH_TORSIONAL_FLEXIBILITY`

Research question:

> Can physically sourced loaded-pitch changes from blade torsional flexibility and control-system compliance explain a substantial part of the remaining systematic CT/CP discrepancy after M1-C?

Allowed implementation scope:

1. analysis-only path; production M0 remains unchanged;
2. use NASA/TP-2004-212262 public structural/reference-model inputs only as `NASA_REFERENCE_MODEL_INPUT`, not as OARF Run 14/15 measured truth;
3. compare four cases: rigid, blade-GJ only, control-system compliance only, combined flexibility;
4. compute resulting radial loaded-pitch change and propagate it through the same M1 aerodynamic/inflow chain;
5. no fitting of stiffness, pitch offset, gain, or correction factor to OARF CT/CP/FM;
6. preserve zero/negative result if flexibility is too small or acts in the wrong direction.

Primary decision criterion:

- If loaded-pitch physics changes CT/CP by a physically meaningful fraction of the remaining M1-C discrepancy, freeze it as a justified M1 layer and proceed to independent validation.
- If its effect is small or wrong-sign, close M1-D as a negative result and advance to `M1-E_NONLOCAL_WAKE`.

## Deferred next stage

- `M1-E_NONLOCAL_WAKE` — `BLOCKED_BY_M1-D`
  - prescribed helical wake / lifting-line / Biot-Savart nonlocal induced coupling;
  - no OARF-based tuning of wake contraction, vortex core, pitch, or empirical induction gain;
  - only starts after M1-D is closed.

## Rule

Before proposing a new research task, check this ledger. A completed or screened item may be reopened only if the new task states the new evidence or changed hypothesis that invalidates the previous closure.
