# Lateral Cyclic Premerge Hardening Audit

## Scope

This audit checks whether the opt-in 8-flight-input `lateralCyclic` path leaves
any unsafe 7-input hardcoded indexing before merging the `rotDir` default
mapping. It does not implement 13x10, nacelle torque, independent nacelle
states, or any time-domain doublet response.

## Search Terms

Searched terms included:

```text
u(5), u(6), u(7), u(8)
uCtrl(5), uCtrl(6), uCtrl(7), uCtrl(8)
7 controls, nx x 7, 9-by-7
controlChannel <= 7
repmat({'rad'}, 7
zeros(...,7)
P.linear.du size 7
aileron = uCtrl(5), elevator = uCtrl(6), rudder = uCtrl(7)
map_control_inputs, get_control_input_names, appliedControls
```

## Classification

|Category|Locations|Result|
|-|-|-|
|ALREADY_MAPPED|`model/map_control_inputs.m`, `model/total_forces_moments.m`, `model/wing_model.m`, `model/validate_inputs.m`, `analysis/linearize_numeric.m`, `analysis/trim_general.m`, `analysis/trim_symmetric.m`, `services/run_linearization_case.m`, `services/run_trim_case.m`, `services/validate_parameter_set.m`, `app/launch_tiltrotor_app.m`|Active dimensions and labels come from `get_control_input_names`; conventional-surface columns shift only behind explicit 7/8 input-count logic.|
|SAFE_LEGACY_ONLY|`params_nominal.m` default `P.linear.du = 1e-4*ones(7,1)`, `analysis/trim_sweep_helicopter.m`, `tests/check_article_trends.m`, `tests/check_control_architecture.m`, `tests/check_control_limits.m`|These paths use the default legacy mode or explicitly document the seven-control architecture. `linearize_numeric` expands a 7-element `P.linear.du` to the 8-input opt-in case.|
|TEST_ONLY|`tests/check_lateral_cyclic_input.m`, `tests/check_lateral_directional_derivative_report.m`, `tests/check_lateral_cyclic_mapping_comparison.m`, `tests/check_aerodynamic_components.m`, `tests/check_pitch_allocation.m`, `tests/check_trim_mode_framework.m`|Hardcoded indices are intentional assertions for legacy ordering, opt-in surface shifting, or focused component fixtures.|
|DOCUMENTATION_ONLY|`docs/LATERAL_DIRECTIONAL_INPUT_AUDIT.md`, `docs/NACELLE_DYNAMIC_STATE_AUDIT.md`, `docs/ebook_packets/*`, `docs/PARAMETER_SOURCE_INVENTORY.md`|Older audit or packet text documents 7-input assumptions and does not drive runtime behavior.|

## NEEDS_FIX Result

No runtime `NEEDS_FIX` item was found. The active model path is governed by
`map_control_inputs`, `get_control_input_names`, and dimension checks. The
legacy 7-input default behavior remains unchanged because
`P.control.enableLateralCyclic = false`. When opt-in 8-input mode is enabled,
the fixed surfaces are shifted to `[aileron elevator rudder] = [6 7 8]` through
the named-control mapping.

## Boundary

This audit only checks hardcoded input-index risk for the current model. It
does not claim Berger/XV-15 validation, flight-test validation,
lateral/directional handling-quality validation, 13x10 implementation, or
nacelle torque implementation.
