# Parameter Source Workplan

## Objective and boundary

This plan starts after the PR #7 classification correction. It does not authorize parameter replacement, model implementation, MATLAB execution, test changes, production-code changes, new data directories, or PR merge. The correction separates current conceptual-model governance from a future XV-15 target dataset.

Every future numeric proposal must identify aircraft configuration, weight state, blade version, rotor-speed mode, coordinate origin, sign convention, original unit, SI conversion, source page/table/figure/equation, and whether manual review remains required.

## Track A - current conceptual-model parameter governance

Purpose:

- clarify field semantics;
- resolve coupled meanings;
- centralize embedded constants;
- create replaceable interfaces;
- preserve current numerical behavior initially;
- maintain internal physical consistency.

Track A is not an XV-15 parameter replacement track. It governs the existing conceptual model so that later sources can be attached without silently changing unrelated behavior.

### Track A work packages

1. Behavior-preserving `RH_mass` / `RH_hub` split.
   - Initialize both to the current `0.75 m` behavior.
   - Prove unchanged mass-property and rotor-hub force-arm results before any sourced value is considered.
2. Separate endpoint inertia data from the interpolation law.
   - Preserve the current `I0 - betaM*KI` behavior first.
   - Do not enter NASA inertia values until the damaged inertia table is manually verified.
3. Introduce a rotor-speed provider initially returning constant `62 rad/s`.
   - Keep current behavior unchanged.
   - Later schedules must be mode/configuration records, not a direct scalar overwrite.
4. Separate blade geometry, mass distribution, polar, flap-axis, spring, and damping structures.
   - Preserve current constant chord, linear `twistTip`, uniform full-span mass distribution, center-hinge interpretation, and simplified polar until a reviewed blade configuration is selected.
5. Separate command convention, side allocation, limits, and mode scheduling.
   - Preserve current common/differential allocation and side-space clamping initially.
   - Keep quantitative XV-15 mixer schedules out of current parameters until sourced.
6. Extract embedded empirical constants into named fields with unchanged initial values.
   - Include wing slip-area heuristics, normal-flow blend constants, vertical-tail drag increment, flap residual scale anchors, and production hard-coded physical/numerical guards.
   - Extraction must be behavior-preserving and separately reviewed before any numeric change.
7. Record numerical settings as current-model governance items.
   - Solver tolerances, finite-difference steps, regularization, diagnostic thresholds, and test thresholds remain `NUMERICAL`, not aircraft-source claims.

## Track B - future XV-15 target dataset

Purpose:

- build an independent XV-15 dataset;
- do not overwrite current conceptual parameters directly;
- record source, aircraft configuration, weight state, blade version, rpm mode, coordinate system, and uncertainty;
- map generic model fields to XV-15 dataset fields.

Future artifacts may include:

```text
data/xv15/
docs/XV15_PARAMETER_SOURCES.md
docs/XV15_DATA_GAPS.md
docs/XV15_MODEL_MAPPING.md
```

Do not create these artifacts in this correction task.

### Track B source priorities

1. Local references that can be manually verified:
   - `NASA_TM_X_62407.pdf` PDF 14-15 (printed 11-12): weight-state definitions, group weights, inertia table labels, axes, and the 13,000 lb condition. Do not use text extraction alone for the damaged inertia table.
   - `NASA_TM_X_62407.pdf` PDF 15-16: dimension entries and footnotes; distinguish rotor-center spacing, wing aerodynamic span, tail span/chord, MAC, incidence, and tail length.
   - `NASA_TM_X_62407.pdf` PDF 20-22 (printed 17-19): blade count, diameter, chord, solidity, precone, flap clearance, Lock number, twist figure, and nominal design tip-speed/rpm modes.
   - `NASA_TM_X_62407.pdf` PDF 49 and 56 (printed 46 and 53): steel-blade construction, hub spring, and qualitative control mixing/phasing.
   - `NASA_TM_81244.pdf` PDF 4-9: design characteristics, nacelle-angle convention, governor logic, test-stage rpm choices, gross-weight/stall condition, and distinction between design and flight restrictions.
   - `NUAA_main_paper.pdf` PDF 3-12: method-level equations (1)-(42) and coordinate figures. Do not source current numeric coefficients from these equations.
2. Additional primary NASA/FAA/academic sources required:
   - mass build-up for both moving nacelle/rotor assemblies, centroids, and conversion-axis geometry;
   - full inertia tensors by weight/configuration and reference CG/axes;
   - steel versus composite/advanced blade geometry, mass distribution, first/second moments, flap axis, precone, hub spring, and damping;
   - rotor-speed governor schedules versus mode, nacelle angle, airspeed, and load restrictions;
   - rotor airfoil stations and Mach/Reynolds/post-stall/reverse-flow polars;
   - rotor/wing interference, wake contraction/skew, download, and dynamic/nonuniform inflow evidence;
   - component aerodynamic databases with reference dimensions, control gearing, and valid ranges;
   - quantitative flight-control mixing, phase-out, actuator travel/rate, and SCAS/governor schedules;
   - mode-specific trim/test points with weight, CG, atmosphere, flap, rpm, and control configuration.

Secondary compilations may be recorded as `DOCUMENTED_SECONDARY`, but they may not override conflicting primary configurations.

## Derivations after parent evidence is fixed

|derived item|required parents|formula/condition|
|-|-|-|
|SI total mass|selected weight state|`m_kg = weight_lbf * 4.4482216152605 / g` if source reports force, or direct lbm conversion only when explicitly mass|
|Rotor radius|verified diameter|`R = D/2`; `1 ft = 0.3048 m`|
|Rotor angular speed|selected rpm schedule|`Omega = rpm*2*pi/60`|
|`KI` candidate|two verified tensors and code angle convention|`KI = (I(beta=0)-I(beta=pi/2))/(pi/2)` only if linear interpolation is approved|
|Blade `Ib` and `Sblade`|verified spanwise mass density and flap-axis location|`Ib=int r_h^2 dm`; `Sblade=int r_h dm`; do not reuse uniform formulas|
|`Jpolar`|rotating assembly mass distribution|sum polar inertias about mast; state included hub/shaft/blade components|
|Component AC vectors|verified source stations and code origin|apply one documented station/waterline/buttline-to-body transform|
|Dimensionless derivatives|verified dimensional data or vice versa|use source reference area/length, dynamic pressure, and rate normalization exactly|

Every derivation retains parent inventory IDs and uncertainty. A derived value cannot outrank its least-confident parent.

## Values likely to remain conceptual pending experiments

- normal-flow blend center/half-width;
- scalar wing slip-area heuristics;
- simplified post-stall tanh caps if no complete database is found;
- one-way `wakeFactor` if no interference data support a higher-order model;
- solver seeds, tolerances, damping, regularization, reporting, and diagnostic thresholds.

These may remain only as `ASSUMED_CONCEPT` or `NUMERICAL`, with applicability and sensitivity recorded. They must not be relabeled as XV-15 data because they produce plausible behavior.

## Regression required after later numerical replacement

|parameter family|minimum dedicated regression before total suite|
|-|-|
|Mass/CG/inertia|mass conservation, endpoint/intermediate positive definiteness, analytic CG derivative, force-arm identities, angular-acceleration comparison|
|Rotor geometry/speed/polar|hover thrust/torque, radial/azimuth convergence, tip Mach/applicability, reverse-flow screen, mode-speed schedule endpoints|
|Blade mass/flap mechanics|static gravity moment, Fourier residual closure, cyclic/differential signs, grid/step sensitivity, flap limits/spring energy|
|Wake/interference|hover download, transition local-flow continuity, left/right symmetry, zero-wake limit, comparison to selected test points|
|Component aero/stations|single-component force/moment signs, `cross(r,F)` perturbation identity, coefficient valid-range guards, symmetry|
|Controls/mixing|common/differential allocation, mirror relations, actuator/side limits, nacelle-angle schedule continuity, governor/SCAS separation|
|Trim parameters/formulation|full residual back-substitution, bounds, initial-seed sensitivity, mode-specific unknown/equation count|
|Linearization settings|three-step central-difference sensitivity, nonlinear increment versus `A dx+B du`, clamp/branch distance, finite/real matrices|

After a family-specific regression passes, run the existing total regression. Passing tests establishes only covered internal consistency, not aircraft validation.

## Required phase order

1. current conceptual-model semantic and interface governance;
2. behavior-preserving structural separation;
3. current-model dedicated regression;
4. independent XV-15 target-dataset construction;
5. manual source/configuration/unit/coordinate verification;
6. generic-model-to-XV-15 mapping;
7. one XV-15 parameter family integrated at a time;
8. family-specific regression;
9. representative operating-point comparison;
10. only then, explicitly limited XV-15 reproduction claims.

## Phase gates

- Gate A - all active parameters are inventoried. Exit evidence: repository-wide `P.` and production-literal search reconciles with `PARAMETER_SOURCE_INVENTORY.md`; unused fields are explicitly identified.
- Gate B - every documentary source claim has exact PDF page and printed page/table/figure/equation or paragraph, plus original unit, weight/configuration/blade/mode and coordinate definition. Titles and old notes are insufficient.
- Gate C - every proposed numeric replacement receives manual review before code change. Conflicting sources remain side by side; no automatic winner is selected.
- Gate D - change one parameter family at a time. Structural separation precedes value replacement and preserves initial behavior.
- Gate E - family-specific regression passes before the broader suite. Failures, nonconvergence, NaN/Inf/complex values and bound contacts remain visible.
- Gate F - no dense envelope, transition/airplane stability map or XV-15 fidelity claim until critical mass/inertia, rotor geometry/speed/blade, aerodynamic, wake, control-mixing and trim-closure families are resolved.

## Stop conditions

Stop and request review if a source lacks configuration/weight/blade/mode context, a table cannot be visually read, a unit or axis is ambiguous, two primary sources disagree, a proposed change would combine parameter families, or a replacement requires changing equations/limits/solver behavior to make tests pass.
