# External Comparison Field Map

## 1. Purpose and Scope

This document is an external comparison field map for the current tiltrotor
model. Its purpose is to prepare later NUAA / Berger trend-comparison work by
mapping external variables, units, coordinate conventions, signs, operating
conditions, and comparability classes to fields that the current repository can
produce.

This is external audit preparation only. It is not validation and not handling-quality validation.
It is not Berger 51-state reproduction and not XV-15 flight-test validation.
It does not change model equations, parameters, controls, default behavior, or
the GUI default path.

## 2. Current Internal Model Baseline

Baseline branch for this document:

```text
codex/lateral-directional-input-audit
```

Baseline includes PR #39, with the berger13 nullspace helper and documentation
present:

```text
analysis/berger13/diagnose_berger13_nullspace.m
docs/BERGER13_NULLSPACE_DIAGNOSTICS.md
```

Current berger13 state order:

```text
u v w p q r phi theta psi betaML betaMR betaMLdot betaMRdot
```

Current berger13 control order:

```text
collective diffCollective cyclicLong diffCyclic lateralCyclic
aileron elevator rudder nacelleTorqueLeft nacelleTorqueRight
```

Currently available internal fields:

| Internal output | Source script / function | Notes |
|-|-|-|
| `A13`, `B13` | `analysis/berger13/linearize_13x10_numeric.m` | 13x13 and 13x10 finite-difference matrices at representative finite points. |
| State names and control names | `get_state_names_13x10`, `get_control_input_names_13x10` | Label contract for all mapping tables. |
| First-nine legacy consistency | `report_berger13_linear_derivatives` | Symmetric cases compare first nine derivatives to the legacy opt-in EOM. |
| Total force and moment | `tiltrotor_eom_13x10`, `total_forces_moments_13x10` | Includes average-angle non-rotor aero and independent rotor-load correction. |
| Independent rotor-load delta | `compute_berger13_rotor_loads`, `report_independent_nacelle_loads` | Difference from betaMAvg-only rotor loads. |
| Control-column norms | `report_berger13_linear_derivatives` | Useful for input connectivity and scale checks. |
| `betaML` / `betaMR` A columns | `report_berger13_linear_derivatives` | Current independent nacelle-angle state-column audit. |
| Raw / scaled / dynamic conditioning | `diagnose_berger13_conditioning` | Internal numerical health diagnostics only. |
| Nullspace / effective condition | `diagnose_berger13_nullspace` | Internal numerical dependency diagnostics only. |

Currently unavailable or out of model scope:

- Berger 51-state HeliUM state set.
- Blade dynamic states beyond the current steady flapping / rotor-load path.
- Dynamic inflow states.
- Closed-loop flight-control and pilot-task response metrics.
- Nonlinear doublet validation.
- Independent left/right non-rotor aerodynamic and mass-property effects.
- GUI default-path berger13 integration.

## 3. Comparison Classification Rules

| Class | Meaning | Allowed use |
|-|-|-|
| `DIRECT_COMPARABLE` | Physical meaning, unit, sign, condition, and model level are confirmed compatible. | Numerical and trend comparison may be made after source provenance is recorded. |
| `TREND_COMPARABLE` | Physical quantity is similar but parameters, model level, condition, or source data differ. | Trend, sign, or order-of-magnitude comparison only. |
| `PARTIAL_COMPARABLE` | Only part of the quantity is comparable, such as dimensions, trend direction, input existence, or a subset of rows/columns. | Scoped diagnostic comparison with explicit caveats. |
| `SIGN_CONVENTION_REQUIRED` | Variable may be comparable, but axes, nacelle angle direction, control sign, or unit conversion must be confirmed first. | No pass/fail conclusion until sign and unit audit is complete. |
| `NOT_COMPARABLE_CURRENT_MODEL` | Current model lacks the required state, input, flight-control loop, dynamic inflow, blade mode, or external definition. | Record as not currently comparable. |
| `OUT_OF_SCOPE_CURRENT_PHASE` | Requires closed-loop control, handling-quality simulation, pilot tasks, 51-state HeliUM, or flight-test data. | Defer to a later phase. |
| `SOURCE_REQUIRED` | External figure, table, or digitized data is not available in this repository. | Do not compare numerically until source data is provided and frozen. |

## 4. NUAA / Drones 2022 Field Map

Source availability:

- `references/NUAA_main_paper.pdf` is present in this repository.
- The expected source file name `drones-06-00092(1).pdf` is not present.
- The expected digitized image files for NUAA Fig.5, Fig.6, and Fig.7 are
  `SOURCE_NOT_IN_REPO`.
- This document does not parse or digitize the PDF and does not invent exact
  figure values.

### 4.1 Trim Figures

| Source | Figure/Table | External variable | External meaning | External unit | External mode / condition | External sign convention status | Internal candidate field | Internal script/report | Comparison class | Required conversion | Risk / caveat | Next action |
|-|-|-|-|-|-|-|-|-|-|-|-|-|
| NUAA / Drones 2022 | Fig.5(a) | Trim controls and states | Helicopter-mode trim trends | SOURCE_REQUIRED | Helicopter mode | `SIGN_CONVENTION_REQUIRED` | legacy trim outputs, 13x10 symmetric finite point fields | `trim_symmetric`, `report_berger13_linear_derivatives` | `TREND_COMPARABLE` after digitization | deg to rad, confirm betaM convention | Current 13x10 cases are representative finite points, not a trim sweep. | Digitize curve and map each plotted variable. |
| NUAA / Drones 2022 | Fig.5(b) | Trim controls and states | Airplane / flight-mode trim trends | SOURCE_REQUIRED | Airplane mode | `SIGN_CONVENTION_REQUIRED` | legacy trim outputs, 13x10 airplane-like point fields | `trim_symmetric`, `report_berger13_linear_derivatives` | `TREND_COMPARABLE` after digitization | deg to rad, speed units if needed | Current parameters are conceptual and not a strict aircraft dataset. | Freeze source image or CSV. |
| NUAA / Drones 2022 | Fig.6(a) | Trim controls and states | Transition trim trends at betaM=15 deg | SOURCE_REQUIRED | Transition, betaM=15 deg | `SIGN_CONVENTION_REQUIRED` | future trim field mapping, current betaML/betaMR state fields | `trim_symmetric`, future comparison script | `PARTIAL_COMPARABLE` | betaM deg to rad | Current committed berger13 report uses 0, 45, 90, and asymmetric 35/55 deg, not 15 deg. | Add a documented internal trim/report point only in a later PR. |
| NUAA / Drones 2022 | Fig.6(b) | Trim controls and states | Transition trim trends at betaM=75 deg | SOURCE_REQUIRED | Transition, betaM=75 deg | `SIGN_CONVENTION_REQUIRED` | future trim field mapping, current betaML/betaMR state fields | `trim_symmetric`, future comparison script | `PARTIAL_COMPARABLE` | betaM deg to rad | Current committed berger13 report does not include 75 deg. | Add source CSV first, then decide internal point. |
| NUAA / Drones 2022 | Fig.7 | Trim comparison | Comparison against other published trim data | SOURCE_REQUIRED | Source-defined | `SOURCE_REQUIRED` | none until external definitions are known | none | `SOURCE_REQUIRED` | SOURCE_REQUIRED | Cannot judge comparability without plotted variables and provenance. | Require source image or digitized CSV. |

### 4.2 Stability / Derivative Candidates

| Source | Figure/Table | External variable | External meaning | External unit | External mode / condition | External sign convention status | Internal candidate field | Internal script/report | Comparison class | Required conversion | Risk / caveat | Next action |
|-|-|-|-|-|-|-|-|-|-|-|-|-|
| NUAA / Drones 2022 | State-space equations / derivative table candidates | A-matrix entries | Stability derivatives | SOURCE_REQUIRED | Source-defined trim point | `SIGN_CONVENTION_REQUIRED` | `A13`, selected legacy 9-state A rows/columns | `linearize_13x10_numeric`, `linearize_numeric` | `TREND_COMPARABLE` or `PARTIAL_COMPARABLE` | dimensional/nondimensional conversion if needed | State ordering may be similar, but operating point and parameter set must be confirmed. | Build row/column label map after source values are frozen. |
| NUAA / Drones 2022 | Control derivative candidates | B-matrix entries | Control derivatives | SOURCE_REQUIRED | Source-defined trim point | `SIGN_CONVENTION_REQUIRED` | `B13`, lateral/directional B blocks | `report_berger13_linear_derivatives`, `report_lateral_directional_derivatives` | `TREND_COMPARABLE` | control deg/rad, force/moment vs acceleration convention | Current `diffCyclic` and `lateralCyclic` conventions require external sign audit. | Map controls by name and sign before comparison. |
| NUAA / Drones 2022 | Eigenvalue candidates | Eigenvalues | Open-loop modes | SOURCE_REQUIRED | Source-defined trim point | `SOURCE_REQUIRED` | current A eigenvalues can be computed later | future script | `PARTIAL_COMPARABLE` | rad/s or 1/s, damping convention | Current representative 13x10 points are not certified trim points. | Defer until trim point equivalence is documented. |

NUAA uses a component/dividing modeling, trim, linearization, and stability
analysis workflow that is closer to the current project architecture than the
Berger 51-state context. However, NUAA parameters, state definitions, nacelle
angle definition, control signs, and plotted operating conditions must be
confirmed before any trend agreement is interpreted. Trend consistency is not a
strict numerical validation.

NUAA Fig.5/Fig.6 source-freeze scaffolding is available in
`validation/external_sources/nuaa/` and
`validation/external_digitized_data/nuaa/`. The target figure rows remain
`SOURCE_REQUIRED` until reviewed source images or digitized CSV files are
provided.

## 5. Berger Dissertation Field Map

Source availability:

- `TomBerger-Dissertation.pdf` is `SOURCE_NOT_IN_REPO`.
- The expected Berger figure images for Fig.2.16, Fig.2.17, Fig.2.19,
  Fig.2.20, Fig.2.21, Fig.2.22, Fig.2.24, Fig.2.25, and Fig.2.28 are
  `SOURCE_NOT_IN_REPO`.
- This document uses only project context already present in the repository and
  does not claim the dissertation was parsed.

| Source | Figure/Table | External variable | External meaning | External unit | External mode / condition | External sign convention status | Internal candidate field | Internal script/report | Comparison class | Required conversion | Risk / caveat | Next action |
|-|-|-|-|-|-|-|-|-|-|-|-|-|
| Berger dissertation | Fig.2.16 | Conversion corridor and linear model points | Operating points for linear models | SOURCE_REQUIRED | Berger-defined corridor | `SIGN_CONVENTION_REQUIRED` | `helicopter_like`, `conversion_mid`, `airplane_like`, asymmetric probe metadata | `report_berger13_linear_derivatives` | `PARTIAL_COMPARABLE` | speed units, nacelle-angle convention | Current points are representative finite points, not Berger corridor points. | Freeze figure/source and map point definitions. |
| Berger dissertation | Fig.2.17 | Tiltrotor trim data | Trim states/controls | SOURCE_REQUIRED | Berger-defined trim | `SIGN_CONVENTION_REQUIRED` | legacy trim outputs, future 13x10 trim-like reports | `trim_symmetric`, future script | `TREND_COMPARABLE` only after source audit | deg/rad, ft/s/knots/m/s if needed | Current 13x10 report is not a full trim envelope. | Digitize and classify variables one by one. |
| Berger dissertation | Fig.2.19 | Rigid-body stability derivatives | A-matrix / derivative fields | SOURCE_REQUIRED | Berger linear points | `SIGN_CONVENTION_REQUIRED` | `A13`, selected first-nine A rows/columns | `report_berger13_linear_derivatives` | `PARTIAL_COMPARABLE` | dimensional scaling and row/column convention | 13-state research model is not Berger 51-state. | Build derivative row/column map before plotting. |
| Berger dissertation | Fig.2.20 | Lateral/directional control derivatives | B-matrix lateral/directional controls | SOURCE_REQUIRED | Berger linear points | `SIGN_CONVENTION_REQUIRED` | `B13` columns for `diffCollective`, `diffCyclic`, `lateralCyclic`, `aileron`, `rudder` | `report_berger13_linear_derivatives`, `report_lateral_directional_derivatives` | `PARTIAL_COMPARABLE` | control sign and rad/deg conversion | B nullspace diagnostics show point-local dependencies; do not infer allocation equivalence. | Audit control sign conventions first. |
| Berger dissertation | Fig.2.21 | Longitudinal/heave control derivatives | Longitudinal B-matrix controls | SOURCE_REQUIRED | Berger linear points | `SIGN_CONVENTION_REQUIRED` | `B13` columns for `collective`, `cyclicLong`, `elevator`, nacelle torque placeholders | `report_berger13_linear_derivatives` | `PARTIAL_COMPARABLE` | control sign and scaling | Nacelle torque inputs are research placeholders, not Berger actuator model. | Mark torque comparability separately. |
| Berger dissertation | Fig.2.22 | Blade mode fan diagram | Blade mode dynamics | SOURCE_REQUIRED | Berger rotor/blade model | `SOURCE_REQUIRED` | none | none | `NOT_COMPARABLE_CURRENT_MODEL` | Not applicable | Current model has no Berger blade dynamic state set. | Defer until blade-state model exists. |
| Berger dissertation | Fig.2.24 | Eigenvalues | Full-model eigenvalues | SOURCE_REQUIRED | Berger model points | `SOURCE_REQUIRED` | future A eigenvalues | future script | `PARTIAL_COMPARABLE` or `NOT_COMPARABLE_CURRENT_MODEL` | eigenvalue convention | Current representative points are not full Berger trim/linear points. | Do not compare until model point definitions are known. |
| Berger dissertation | Fig.2.25 | Low-frequency eigenvalues | Low-frequency dynamics | SOURCE_REQUIRED | Berger model points | `SOURCE_REQUIRED` | future reduced/eigenvalue diagnostics | future script | `PARTIAL_COMPARABLE` | eigenvalue convention | Reduced-state conditioning is not modal validation. | Defer until trim and state definitions are mapped. |
| Berger dissertation | Fig.2.28 | Tiltrotor control allocation | Control allocation schedule/weights | SOURCE_REQUIRED | Berger closed-loop/control design context | `SIGN_CONVENTION_REQUIRED` | current open-loop controls and column norms only | `report_berger13_linear_derivatives` | `PARTIAL_COMPARABLE` | control sign, allocation units | Current model has no closed-loop allocation law matching Berger. | Treat as architecture audit only. |

Berger's context is high-fidelity flight dynamics / HeliUM / stitched model /
control design. The current `berger13` path is a 13-state / 10-input research
model. It is not equivalent to Berger 51-state HeliUM, cannot directly compare
blade modes, and cannot compare handling-quality results. Current work can
prepare field mapping, unit/sign audits, and partial derivative/control
allocation trend candidates only.

## 6. Sign and Unit Audit Checklist

Before any external comparison, confirm:

- Nacelle angle convention:
  - NUAA `betaM` 0/90 definition.
  - Berger `delta_nac` 0/90 definition.
  - Internal `betaM`, `betaML`, and `betaMR` definition.
- Airspeed units:
  - m/s.
  - knots.
  - ft/s.
- Angle units:
  - rad.
  - deg.
- Body axes:
  - x forward.
  - y right.
  - z down.
- Moment signs:
  - roll.
  - pitch.
  - yaw.
- Control signs:
  - collective.
  - cyclicLong.
  - lateralCyclic.
  - diffCyclic / differentialLongitudinalCyclic definition.
  - elevator.
  - aileron.
  - rudder.
- Derivative definitions:
  - dimensional versus nondimensional.
  - stability-axis versus body-axis.
  - state derivative row/column convention.
  - force/moment derivative versus acceleration derivative.
- Trim quantities:
  - trim value.
  - control allocation weight.
  - commanded input.
  - applied/saturated input.

## 7. External Audit Readiness Matrix

| Row | Source available? | Internal field available? | Unit/sign known? | State/input compatible? | Current comparison class | Ready for digitization? | Ready for numerical comparison? | Notes |
|-|-|-|-|-|-|-|-|-|
| NUAA trim trend | Partial: `NUAA_main_paper.pdf`; figure CSV/images not present | Partial | No | Partial | `SOURCE_REQUIRED` then `TREND_COMPARABLE` | No | No | Digitize Fig.5/Fig.6 first. |
| NUAA stability derivatives | Partial | Yes: A/B candidates | No | Partial | `SIGN_CONVENTION_REQUIRED` | No | No | Need source table/figure values and derivative convention. |
| NUAA eigenvalues | Partial | Future A eigenvalues possible | No | Partial | `PARTIAL_COMPARABLE` | No | No | Must use true trim points before modal interpretation. |
| Berger trim data | No | Partial | No | Partial | `SOURCE_REQUIRED` | No | No | Dissertation/source images not in repo. |
| Berger stability derivatives | No | Yes: A13 candidates | No | Partial | `PARTIAL_COMPARABLE` | No | No | 13-state model is not 51-state HeliUM. |
| Berger control derivatives | No | Yes: B13 candidates | No | Partial | `PARTIAL_COMPARABLE` | No | No | Control sign and unit audit required. |
| Berger blade modes | No | No | No | No | `NOT_COMPARABLE_CURRENT_MODEL` | No | No | Current model lacks blade dynamic states. |
| Berger eigenvalues | No | Future A eigenvalues possible | No | Partial | `OUT_OF_SCOPE_CURRENT_PHASE` | No | No | Do not infer handling qualities. |
| Berger control allocation | No | Partial: control columns and norms | No | Partial | `PARTIAL_COMPARABLE` | No | No | No matching closed-loop allocation law yet. |
| Berger handling qualities | No | No | No | No | `OUT_OF_SCOPE_CURRENT_PHASE` | No | No | Requires closed-loop metrics and pilot-task definitions. |
| Berger nonlinear task simulation | No | No | No | No | `OUT_OF_SCOPE_CURRENT_PHASE` | No | No | Nonlinear doublet/task simulation is not part of this phase. |

## 8. Recommended Next Steps

1. Freeze source PDFs/images or digitized CSVs in a clear
   `validation/external_sources` or `references` workflow.
2. Digitize NUAA Fig.5/Fig.6 trim curves first.
3. Build a NUAA trim field mapping script that reads current model reports and
   digitized CSVs without changing the model.
4. Generate a comparison report with `DIRECT_COMPARABLE`,
   `TREND_COMPARABLE`, and `PARTIAL_COMPARABLE` classifications.
5. Only after NUAA trim mapping is stable, start Berger derivative/control
   allocation field audit.
6. Keep Berger handling-quality comparison out of scope until closed-loop
   control and response metrics exist.

## 9. Explicit Non-Claims

- This document does not validate the model.
- This document does not reproduce Berger 51-state HeliUM.
- This document does not verify handling qualities.
- This document does not prove XV-15 agreement.
- This document does not change model equations or default behavior.
