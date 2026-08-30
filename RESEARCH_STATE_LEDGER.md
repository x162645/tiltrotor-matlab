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

- `M1-D_LOADED_PITCH_TORSIONAL_FLEXIBILITY` — `FORMALLY_RUN_NEGATIVE_DIAGNOSTIC`
  - PR: #72.
  - MATLAB R2021a workflow run: `33284559105`, success.
  - Artifact: `9724006601`, SHA-256 `0d0ad7da250c07e98e9f9c54fcb37060ca6a4d86229e5a15b91332d7de311e1e`.
  - Scope: analysis-only quasi-static comparison of rigid, blade-GJ-only, control-compliance-only, and combined flexibility.
  - Structural inputs: NASA/TP-2004-212262 Appendix A reference-model `GJ(r)`, `XQC(r)`, twist, and `KPL=22400 ft-lb/rad`; these are `NASA_REFERENCE_MODEL_INPUT`, not matched OARF Run 14/15 structural measurements.
  - Same-solver 6–11 deg diagnostic metrics:
    - rigid: CT MAPE 30.8742%, CP MAPE 41.0856%;
    - blade GJ only: CT 35.5729%, CP 46.4690%;
    - control compliance only: CT 33.2340%, CP 43.6762%;
    - combined: CT 37.7791%, CP 48.7759%.
  - Flexible cases unload the blade rather than recover missing thrust: mean theta75 shift is about -0.656 deg for blade GJ, -0.282 deg for control compliance, and -0.937 deg combined; maximum blade elastic twist is about 1.20 deg.
  - 7–11 deg flexible cases converge; 6 deg blade-GJ and combined cases reach the 160-iteration limit and remain explicit boundary failures.
  - Interpretation boundary: the absolute rigid metrics above belong to the compact M1-D diagnostic solver and must not replace formal M1-C metrics. The valid conclusion is the incremental rigid-versus-flexible direction and magnitude within M1-D.
  - Conclusion: quasi-static loaded-pitch/torsional compliance is not a credible explanation for the remaining systematic thrust deficit under the tested independently sourced reference inputs. Do not reopen as a mainline task without new structural evidence or a materially different aeroelastic hypothesis.

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

### `M1-E_NONLOCAL_WAKE`

Research question:

> Does an independently constrained finite-blade nonlocal wake model materially alter the radial/azimuthal induced-velocity field and rotor loading enough to explain a meaningful part of the remaining systematic CT/CP discrepancy after the local/annular and loaded-pitch hypotheses have been screened?

Allowed implementation scope:

1. analysis-only path initially; frozen M0 and production core remain unchanged;
2. implement a genuinely nonlocal finite-blade wake, not a renamed Prandtl/Mangler/local-annular correction;
3. preferred first model: prescribed helical wake + lifting-line/circulation closure + Biot-Savart induced velocity;
4. circulation and induced velocity must be solved self-consistently or by a clearly documented iterative closure;
5. wake pitch, contraction, vortex-core treatment and truncation must come from independent literature/theory or transparent conservation relations;
6. no fitting of wake contraction, core radius, pitch, empirical induction multiplier, or circulation gain to OARF CT/CP/FM;
7. compare against the existing rigid M1-C/local-annular layer on the same declared conditions and preserve negative results;
8. include convergence with radial discretization, wake age/revolutions, azimuthal discretization and vortex-core regularization before interpreting performance changes.

Primary decision criterion:

- If nonlocal wake physics produces a material, physically interpretable improvement that survives numerical convergence checks, freeze it as the next justified M1 layer and then test against reserved independent evidence.
- If the effect is small, wrong-sign, numerically non-robust, or requires OARF-driven tuning, close M1-E as a negative result rather than adding empirical gains.

## Rule

Before proposing a new research task, check this ledger. A completed or screened item may be reopened only if the new task states the new evidence or changed hypothesis that invalidates the previous closure.
