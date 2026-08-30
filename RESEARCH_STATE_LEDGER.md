# Research State Ledger

This file is the authoritative research-state checkpoint for the current M1 branch. It was synchronized with the actual PR #71 contents on 2026-08-30 and must track executed evidence rather than planned workflow state.

## Frozen baseline

- `M0` — `FROZEN`
  - Branch: `frozen/m0-xv15-hover-v1-20260828`
  - Commit: `27f40883633ca14acc0e928649b62d7abb855491`
  - Role: untuned generic low-order baseline for XV-15 validation-instance correlation.

## M1 freeze decision

- `M1_EVIDENCE_V1` — `FREEZE_GATE_PASS_WITH_DOMAIN_CAVEAT`
  - Downstream enhanced rotor identity: `M1_HOLDOUT_V1_GENERIC_CORRIGAN_N1`.
  - Freeze rationale and claim boundaries: `docs/M1_EVIDENCE_FREEZE_GATE_20260830.md`.
  - This is an evidence/model-identity freeze, not a claim of full XV-15 reproduction or unique correctness of every internal parameter.
  - No additional rotor correction may be introduced solely to reduce OARF error before whole-aircraft M0-vs-M1 propagation is completed.

## Completed / screened M1 work

- `M1-A_SOURCE_INFORMED_RADIAL_GEOMETRY_SCALAR_C81` — `FORMALLY_RUN_SOURCE_FIDELITY_AUDIT_PASS`
  - MATLAB R2021a Stage-1 evidence: 6–11 deg CT/CP/FM MAPE = 33.9549 / 45.2392 / 4.4100%.
  - Geometry source-fidelity audit run `33289747465` compared current reconstruction, direct Appendix-A TWISTA, TP narrative chord, and TP Appendix-A CAMRAD chord with no OARF/WADC-based selection.
  - All four source interpretations retained lower CT/CP/FM MAPE than DIAG_SECTION; total source-interpretation spread = 1.5855 / 1.5515 / 0.4322 pp.
  - Current branch reproduced the canonical M1-A result with 0 pp identity difference under the 1e-6 pp gate.
  - Scientific wording: `source-informed radial chord and nonlinear-twist representation`, not unqualified `actual/real geometry`.
  - Direct TWISTA is a stronger source contract than the polynomial representation, but it does not retroactively replace the frozen M1 identity used for WADC evidence.
  - Detailed audit: `docs/M1_GEOMETRY_SOURCE_FIDELITY_AUDIT.md`.

- `M1-B_TP_FOUR_REGION_C81_LOCAL_MACH` — `FORMALLY_RUN_PASS_WITH_CAVEAT`
  - 6–11 deg: CT/CP/FM MAPE = 37.8538 / 50.5150 / 7.5480%.
  - NASA/TP-2004-212262 four radial C81 regions are source-backed; current lookup is a TP reference-input interpretation, not universal exact XV-15 airfoil truth.
  - The degradation relative to M1-A is retained as evidence of model-form interaction/error compensation rather than hidden by model selection.

- `M1-C_ANNULAR_MOMENTUM` — `FORMALLY_RUN_DIAGNOSTIC_NOT_IN_FROZEN_HOLDOUT_IDENTITY`
  - 6–11 deg: CT/CP/FM MAPE = 35.7519 / 47.9006 / 5.9849%.
  - Local annular closure only; not nonlocal wake.
  - Retained as incremental evidence but not promoted into `M1_EVIDENCE_V1`, because the post-freeze WADC-tested identity was based on the M1-B equations plus Corrigan n=1.

- `M1-D_LOADED_TORSION_PR71` — `FORMALLY_RUN_NEGATIVE_PASS_WITH_CAVEAT`
  - Formal implementation: `analysis/run_m1_stage2_loaded_torsion.m` in PR #71.
  - Uses NASA reference-model GJ/XQC/KPL and C81 CM with explicit unit/sign/source audit.
  - Rigid branch is fail-closed against M1-B.
  - Source-constrained quasi-static flexibility reduces effective pitch and worsens CT/CP correlation.
  - Negative diagnostic only; not in the frozen downstream M1 identity.

- `M1-E_FELKER_LOCAL_STATE_AUDIT` — `FORMALLY_RUN_DIAGNOSTIC`
  - Tests whether solved blade states enter the inboard high-alpha regime implicated by Felker.
  - Does not modify aerodynamics.

- `M1-E_CORRIGAN_N1` — `FORMALLY_RUN_PROVENANCE_CLOSED_AND_FROZEN`
  - Corrigan/Koning model form is source-backed.
  - `n=1` is classified as `PREDECLARED_IN_RANGE_CORRIGAN_N1_MODEL_FORM_ASSUMPTION`, not a universal literature default.
  - `n=1.8` remains explicitly `NONINDEPENDENT_XV15_OARF_CORRELATED_VARIANT` and is not selected despite lower OARF CT/CP error.
  - Provenance-only correction was formally rerun in MATLAB R2021a run `33290207290`; numerical identity remained unchanged to ~1e-14 pp.
  - Corrigan n=1 CT/CP/FM MAPE = 32.7269 / 45.8943 / 7.5918% on OARF Run 15, 6–11 deg.
  - Detailed closure: `docs/M1_CORRIGAN_N1_PROVENANCE_CLOSURE.md`.

- `M1-F_LANDGREBE_BIOT_SAVART` — `DIAGNOSTIC_ONLY_NOT_PROMOTED`
  - Stage-4 primary run has 0/6 supported M1-F1 points over the fixed window.
  - Stage-4B tests numerical fixed-point convergence only.
  - Tip-vortex Landgrebe geometry is source-backed; applying the same normalized trajectory to the inboard sheet is an explicit model-form assumption.
  - Momentum normalization fixes mean induced velocity; Biot-Savart supplies radial redistribution shape.
  - Not a validated complete nonlocal-wake model and not part of `M1_EVIDENCE_V1`.

- `M1_STAGE5_WADC_HOLDOUT` — `FORMALLY_RUN_POST_FREEZE_EXTERNAL_VALIDATION_PASS_WITH_DOMAIN_CAVEAT`
  - Model frozen before WADC numerical values were read.
  - Formal Runs 1–3, inherited fixed window, 15 real points, no interpolation/deletion.
  - Pooled M0 CT/CP/FM MAPE = 59.1465 / 66.0974 / 23.0497%.
  - Pooled frozen M1 = 37.8956 / 51.1078 / 9.2559%.
  - Interpretation: the frozen M1 bundle retains improvement across facilities; individual internal mechanisms/parameters are not uniquely validated.
  - Post-hoc input-homology audit is closed below.

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

## Closed audit blockers

1. `GEOMETRY_SOURCE_FIDELITY_AUDIT` — `CLOSED_PASS`
   - MATLAB R2021a run `33289747465`, artifact `9725590921`.
   - M1-A geometry-attribution direction is robust across tested legitimate public-source interpretations.
   - No downstream rollback required.

2. `HOVER_EQ12_LIMIT_AUDIT` — `CLOSED_PASS_WITH_OBSERVABLE_BOUNDARY`
   - MATLAB R2021a run `33290011132`.
   - Eq. (12) versus uniform-hover CT/CP/FM differences are numerical-noise scale.
   - Integrated hover performance may be retained.
   - Strict-hover Eq. (12) first-harmonic flapping coordinates are not independently validated objective observables and must not support hover lateral/1-rev claims without additional evidence.
   - Detailed audit: `docs/M1_HOVER_EQ12_LIMIT_AUDIT.md`.

3. `CORRIGAN_N1_PROVENANCE_CORRECTION` — `CLOSED_PASS`
   - MATLAB R2021a run `33290207290`, artifact `9725727353`.
   - Provenance language corrected with no numerical model change.

4. `WADC_INPUT_HOMOLOGY_SENSITIVITY` — `CLOSED_PASS_WITH_LOW_DENSITY_SUPPORT_LIMITATION`
   - Final MATLAB R2021a run `33292823006`.
   - Artifact `9726500347`, SHA-256 `dc256c45b89fd0343b29e0c182c016f1c52946a49b31a208df89ed3dceb20384`.
   - Frozen Stage-5 reproduction max identity difference = `7.7715611723761e-16`; frozen branch remains 15/15 supported.
   - Reported-Mtip-derived sound speed: 15/15 support and only ~+0.026/+0.029/-0.002 pp pooled CT/CP/FM MAPE change versus frozen a=340 m/s.
   - Reported-Mtip sound speed + 1.1*rho: 15/15 support.
   - Reported-Mtip sound speed + 0.9*rho: 14/15 support; the retained failure is WADC Run 3 point 9, collective75=10 deg.
   - Across the 14-point common-support set, every declared environment variant retains a large M1 advantage over M0: approximately -21.10 pp CT, -14.79 pp CP, -14.61 pp FM.
   - Audit decision: `WADC_ADVANTAGE_ROBUST_ON_COMMON_SUPPORT_WITH_LOW_DENSITY_SUPPORT_LIMITATION`.
   - The original 15-point Stage-5 holdout remains unchanged; common-support analysis is diagnostic only.

## NEXT_ALLOWED — whole-aircraft propagation

The rotor M1 evidence package has passed the freeze gate with explicit domain caveats. The next scientific task is **not** another OARF-error-reduction rotor correction.

Execute:

`M0_aircraft` versus `M1_EVIDENCE_V1_aircraft`

using the already-developed whole-aircraft framework across hover → conversion → airplane-mode operating conditions.

Primary observables include trim controls, rotor thrust/power/inflow, linearized A/B matrices and eigenstructure, stability/control metrics, and nacelle-dynamics quantities already supported by the repository.

Primary research question:

> Does strengthening the rotor-model evidence materially change whole-aircraft trim, control demand, power/thrust allocation, linear modes, stability/control conclusions, or nacelle-dynamics conclusions?

All downstream claims must preserve the M1 freeze-domain boundaries documented in `docs/M1_EVIDENCE_FREEZE_GATE_20260830.md`.

## Rule

Before proposing a new rotor-physics task, read this ledger and `docs/M1_EVIDENCE_FREEZE_GATE_20260830.md`. A task already completed, screened, diagnostic-only, superseded, or excluded from `M1_EVIDENCE_V1` must not be re-created under a new name without genuinely new independent evidence.