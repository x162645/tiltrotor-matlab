# BranchWeight To NUAA Wing Zone Audit

Date: 2026-07-07

Workspace: `E:\tiltrotor-nuaa-wing-zone`

Task branch: `task/nuaa-wing-eq16-22-zone-sum-20260707`

Baseline commit: `3550e5b855bac1c38e9d275cf3f8e608cb519c70`

## Scope

This audit tracks the move from the old complete-load `branchWeight` wing
blend to the NUAA Drones 2022 Eq. (16)-(22) slipstream/free-stream zone sum.
It is limited to the wing aerodynamic model, wing tests, and documentation.

The original dirty workspace at `E:\tiltrotor` was not modified. Initial
read-only status there was:

```text
branch: fix/nuaa-paper-trend-comparison
 M model/rotor_model_bemt.m
 M model/wing_model.m
?? CODEX_XFOIL_PREFLIGHT_TASK.md
?? analysis/make_nuaa_paper_comparison_definition.m
?? analysis/run_nuaa_15deg_collective_slope_root_cause.m
?? analysis/run_nuaa_15deg_rotor_force_product_decomposition.m
?? analysis/run_nuaa_15deg_rotor_load_derivative.m
?? analysis/run_nuaa_15deg_rotor_thrust_root_cause.m
?? analysis/run_nuaa_direct_physics_root_cause.m
?? analysis/run_nuaa_paper_comparison_correction.m
?? tests/check_nuaa_paper_comparison_smoke.m
?? tests/check_nuaa_paper_cyclic_mapping.m
?? tests/check_nuaa_paper_trim_definitions.m
?? tools/
```

## Classification Key

`A`: complete-result `branchWeight` blend.

`B`: NUAA Eq. (16)-(22) slipstream/free-stream zone sum.

`C`: full-angle experimental or opt-in path.

`D`: deprecated compatibility field or diagnostic output.

## Audit Table

| File path | Function / location | Current behavior classification | Needs modification | Reason |
|-|-|-|-|-|
| `model/wing_model.m` | Top-level area split, `SslipRawHalf`, `S_slip`, `S_free`, `Swss`, `Swfs` | B | Yes, completed | Eq. (16) area split already existed per half wing; this task added total-wing `Swss/Swfs` diagnostics and explicit `NUAA_EQ16_22_ZONE_SUM` assembly metadata. |
| `model/wing_model.m` | `one_region`, Eq. (17) local velocity | B | No production change | Slipstream regions use `V_body + omega_body x r + [v1d*sin(betaM);0;-v1d*cos(betaM)]`; free-stream regions use rigid-body local velocity only. |
| `model/wing_model.m` | `one_region`, old lines computing `FNear`, `FLiftLine`, `branchWeight` | D | Yes, completed | `FNear`, `FLiftLine`, `MNear`, `MLiftLine`, and `normalFlowBranchWeight` remain only as deprecated diagnostics. |
| `model/wing_model.m` | Former production `Freg = (1 - branchWeight)*FNear + branchWeight*FLiftLine` and matching `Maero` blend | A | Yes, completed | This complete-load blend was the target removal. Production now sets `Freg = FLiftLine` and `Maero = MaeroLiftLine` for each independent zone. |
| `model/wing_model.m` | `Mreg = cross(rAC,Freg)+Maero` | B | No conceptual change | This is the Eq. (20)/(22)-style moment assembly in body axes. |
| `model/total_forces_moments.m` | Call to `wing_model(x,uApplied,betaM,mp.cgShift,rotL,rotR,P)` | B | No | External `wing_model` signature and caller contract were preserved. |
| `params_nominal.m` | `P.wing.normalFlowRatio`, `P.wing.normalFlowBlendHalfWidth` | D | No | Retained as deprecated diagnostic controls only; not used in production wing force or moment. No parameters were changed. |
| `params_nominal.m` | `P.wing.SslipMaxHalf`, `P.wing.muMax` | B | No | Existing assumed Eq. (16) scale and advance-ratio normalization are still used; no tuning was done. |
| `params_nominal.m` | `P.rotor.wakeFactor` | D | No | Deprecated compatibility metadata; production wing Eq. (17) uses `rotor.inducedVelocity` directly. |
| `tests/check_nuaa_eq12_13_16.m` | Eq. (16) area checks | B | No | Existing focused Eq. (16) checks remain valid. |
| `tests/check_nuaa_eq17_wing_velocity.m` | Eq. (17)-(22) velocity and moment identity checks | B / D | No required change | Still verifies Eq. (17) and moment identities; diagnostic `FNear/FLiftLine` fields remain available. |
| `tests/check_wing_normal_flow_blend.m` | Old blend continuity test | A | Yes, completed | Replaced by a deprecated wrapper around `check_wing_nuaa_zone_sum`; old continuity requirement no longer describes production physics. |
| `tests/check_wing_nuaa_zone_sum.m` | New focused test | B / D | Yes, added | Covers source guard, area conservation, finite outputs, branchWeight insensitivity, trim smoke, and lightweight NUAA Fig.5/Fig.6 status. |
| `tests/run_all_checks.m` | Internal test list | B | Yes, completed | Replaced old wing near-normal blend check with new NUAA zone-sum check. |
| `analysis/near_normal_branch_diagnostics.m` | Historical branch diagnostics | D | No | Diagnostic script still reads branch metadata; it is not production. |
| `analysis/wing_blend_repair_diagnostics.m` | Historical branchWeight diagnostics | D | No | Diagnostic script only; not part of production path. |
| `docs/REPRESENTATIVE_TRIM_CONTINUATION.md` | Historical notes mentioning blend weights | D | No | Existing historical report. Not updated to avoid rewriting prior evidence. |
| `docs/TRIM_MIDPOINT_7P5_DIAGNOSIS.md` and `docs/TRIM_MIDPOINT_17P5_DIAGNOSIS.md` | Historical near-normal/blend diagnosis | D | No | Existing historical reports. Not updated to avoid rewriting prior evidence. |
| `docs/PROJECT_CURRENT_BASELINE.md` | Baseline description | B / D | No | Describes the branch baseline and historical state; this task adds a dedicated implementation note instead of editing the broad baseline. |
| `docs/PAPER_CODE_MAPPING.md` | Existing NUAA mapping, including old blend row | B / D | No | Existing mapping is not rewritten in this focused task; this audit and implementation note supersede the branchWeight production-load statement for this task. |
| `docs/NUAA_WING_EQ16_22_IMPLEMENTATION.md` | New implementation note | B / D | Yes, added | Records the new zone-sum implementation and non-changes. |

## Findings

- The old production problem was local to `model/wing_model.m`: each wing
  region computed two complete aerodynamic results and blended the final
  force/moment using `branchWeight`.
- The code already had the correct structural split into left/right and
  slipstream/free-stream regions. This task kept that call graph and removed
  only the production complete-load blend.
- `branchWeight`, `nearNormal`, `FNear`, and `FLiftLine` still exist as
  deprecated diagnostics. They are not physical model authority and are not
  used by final wing `F/M`.
- No full-angle experimental path was enabled or made default.
- No GUI, trim strategy, pitch allocation, rotor model, tail model, default
  parameters, or control limits were changed.

## Remaining Risk

- The lift/drag/side-force coefficient model is still conceptual and uses
  current project coefficients; this is not a NUAA or XV-15 data validation.
- `P.wing.SslipMaxHalf` and `P.wing.muMax` remain assumed/current-model
  parameters, not aircraft-source values.
- Existing historical reports still describe the old blend diagnostics. They
  are intentionally left untouched and should not be read as current
  production-path documentation.
