# Research State Ledger

This file is the authoritative research-state checkpoint for the current M1 branch. It was comprehensively synchronized with the actual PR #71 contents on 2026-08-30 after an audit found that the previous ledger had stopped at M1-D even though the branch had already advanced through Stage 5.

## Frozen baseline

- `M0` — `FROZEN`
  - Branch: `frozen/m0-xv15-hover-v1-20260828`
  - Commit: `27f40883633ca14acc0e928649b62d7abb855491`
  - Role: untuned generic low-order baseline for XV-15 validation-instance correlation.

## Completed / screened M1 work

- `M1-A_SOURCE_INFORMED_RADIAL_GEOMETRY_SCALAR_C81` — `FORMALLY_RUN_REAUDIT_REQUIRED`
  - MATLAB R2021a Stage-1 evidence exists.
  - 6–11 deg: CT/CP/FM MAPE = 33.9549 / 45.2392 / 4.4100%.
  - Audit correction: current chord and twist representations are source-informed reconstruction/fit, not unqualified exact geometry truth.
  - Requires geometry source-fidelity sensitivity before final paper causal attribution.

- `M1-B_TP_FOUR_REGION_C81_LOCAL_MACH` — `FORMALLY_RUN_PASS_WITH_CAVEAT`
  - 6–11 deg: CT/CP/FM MAPE = 37.8538 / 50.5150 / 7.5480%.
  - NASA/TP-2004-212262 four radial C81 regions are source-backed; current lookup is a TP reference-input interpretation, not universal exact XV-15 airfoil truth.

- `M1-C_ANNULAR_MOMENTUM` — `FORMALLY_RUN_PASS_WITH_CAVEAT`
  - 6–11 deg: CT/CP/FM MAPE = 35.7519 / 47.9006 / 5.9849%.
  - Local annular closure only; not nonlocal wake.

- `M1-D_LOADED_TORSION_PR71` — `FORMALLY_RUN_NEGATIVE_PASS_WITH_CAVEAT`
  - Formal implementation is `analysis/run_m1_stage2_loaded_torsion.m` in PR #71.
  - Uses NASA reference-model GJ/XQC/KPL and C81 CM with explicit unit/sign/source audit.
  - Rigid branch is fail-closed against M1-B.
  - Result: source-constrained quasi-static flexibility reduces effective pitch and worsens CT/CP correlation.
  - Boundary: does not rule out all real production XV-15 aeroelastic effects.

- `M1-E_FELKER_LOCAL_STATE_AUDIT` — `FORMALLY_RUN_DIAGNOSTIC`
  - Tests whether the solved blade operates in the inboard high-alpha regime implicated by Felker.
  - Does not modify aerodynamics.

- `M1-E_CORRIGAN_FORM` — `FORMALLY_RUN_REAUDIT_REQUIRED`
  - Corrigan/Koning model form is source-backed.
  - `n=1.8` is explicitly non-independent XV-15/OARF-correlated evidence.
  - Audit correction: `n=1` is a predeclared in-range model-form assumption, not a proven universal literature default.
  - `M1_HOLDOUT_V1` numerical identity remains frozen; provenance wording must be corrected without selecting a new n from validation error.

- `M1-F_LANDGREBE_BIOT_SAVART` — `DIAGNOSTIC_ONLY_NOT_PROMOTED`
  - Stage-4 primary run has 0/6 supported M1-F1 points over the fixed window.
  - Stage-4B tests numerical fixed-point convergence only.
  - Tip-vortex Landgrebe geometry is source-backed; applying the same normalized trajectory to the inboard sheet is an explicit model-form assumption.
  - Momentum normalization fixes mean induced velocity; Biot-Savart supplies radial redistribution shape.
  - Must not be described as a validated complete nonlocal wake model.

- `M1_STAGE5_WADC_HOLDOUT` — `FORMALLY_RUN_POST_FREEZE_EXTERNAL_VALIDATION`
  - Model frozen before WADC numerical values were read.
  - Formal Runs 1–3, inherited 6–11 deg window, 15 real points, no interpolation/deletion.
  - M1 copied solver identity is fail-closed against frozen Stage-3 implementation.
  - Pooled M0 CT/CP/FM MAPE = 59.1465 / 66.0974 / 23.0497%.
  - Pooled frozen M1 = 37.8956 / 51.1078 / 9.2559%.
  - Interpretation: the frozen M1 bundle retains improvement across facilities; individual internal mechanisms/parameters are not uniquely validated.
  - Requires post-hoc input-homology sensitivity for reported WADC Mtip/aSound and unavailable density.

## Invalid / superseded work

- `PR72_SIMPLIFIED_M1D` — `INVALID_AS_SCIENTIFIC_EVIDENCE_SUPERSEDED_BY_PR71`
  - Duplicate implementation created after the authoritative PR #71 M1-D already existed.
  - XQC interpretation conflicts with the formal source contract and an unsourced Cm Mach multiplier was introduced.
  - Do not use its numerical results in the paper or project evidence chain.

## Previously screened directions

- `LOCAL_PRANDTL_ROOT_TIP_LOSS` — `FORMALLY_SCREENED_NEGATIVE`
- `MASS_PROPERTY_SINGLE_FACTOR` — `FORMALLY_SCREENED_LOW_PRIORITY`
- `LOCAL_OR_EMPIRICAL_INFLOW_VARIANTS` — `PREVIEW_OR_SCREENED`

These must not be recycled as new mainline tasks without genuinely new evidence or a changed hypothesis.

## NEXT_ALLOWED — audit blockers only

No new M1 physical mechanism is allowed until the following four source/limit/homology checks are closed. See `docs/M1_FULL_PHYSICS_AUDIT_20260830.md`.

1. `GEOMETRY_SOURCE_FIDELITY_AUDIT`
   - Compare current chord reconstruction, TP text-faithful chord, TP Appendix-A CAMRAD CHORD, and direct 51-point TWISTA interpolation.
   - No OARF/WADC-based selection.

2. `HOVER_EQ12_LIMIT_AUDIT`
   - Formal MATLAB Eq. (12) versus uniform-hover inflow comparison.
   - Must include CT/CP/FM plus beta harmonics, H forces and 1/rev/local-load harmonics.

3. `CORRIGAN_N1_PROVENANCE_CORRECTION`
   - Numerical model identity stays frozen.
   - Correct n=1 evidence role from literature-default language to a predeclared in-range model-form assumption.

4. `WADC_INPUT_HOMOLOGY_SENSITIVITY`
   - Preserve original holdout unchanged.
   - Post-hoc sensitivity using reported Vtip/Mtip-derived sound speed and a transparent density range if density remains unavailable.

## Downstream decision

After the four audit blockers close:

- if the main M1/WADC conclusions are robust, freeze the corrected evidence package and return to whole-aircraft M0-vs-M1 trim/conversion/linear-dynamics studies;
- if any blocker materially changes the conclusions, repair the model identity/evidence chain before considering any new M2 physics.

## Rule

Before proposing a new research task, read both this ledger and `docs/M1_FULL_PHYSICS_AUDIT_20260830.md`. A task already marked completed, screened, diagnostic-only, or superseded must not be re-created under a new name.
