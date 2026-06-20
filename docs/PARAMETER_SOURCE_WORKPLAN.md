# Parameter Source Workplan

## Objective and boundary

This plan starts after the read-only inventory. It does not authorize parameter replacement, model implementation, MATLAB execution, or PR merge. Every future numeric proposal must identify the aircraft configuration, weight state, blade version, rotor-speed mode, coordinate origin, sign convention, original unit and SI conversion.

## Track 1 - claims verifiable from current local references

1. Manually verify `NASA_TM_X_62407.pdf` PDF 14-15 (printed 11-12): weight-state definitions, group weights, inertia table labels, axes and the 13,000 lb condition. Do not use text extraction alone for the damaged inertia table.
2. Verify PDF 15-16 dimension entries and their footnotes: distinguish rotor-center spacing, wing aerodynamic span, tail span/chord, MAC, incidence and tail length.
3. Verify PDF 20-22 (printed 17-19): blade count, diameter, chord, solidity, precone, flap clearance, Lock number, twist figure and nominal design tip-speed/rpm modes.
4. Verify PDF 49 and 56 (printed 46 and 53): steel-blade construction/hub spring and qualitative control mixing/phasing.
5. Verify `NASA_TM_81244.pdf` PDF 4-9: design characteristics, nacelle-angle convention, governor logic, test-stage rpm choices, gross-weight/stall condition and the distinction between design and then-current flight restrictions.
6. Verify `NUAA_main_paper.pdf` PDF 3-12: equations (1)-(42), coordinate figures and which relations are only method-level similarities. Do not source current numeric coefficients from these equations.

Expected direct outcomes: confirm `Nb=3`; create candidate records for weight states, endpoint inertias, rotor geometry and speed modes; record unresolved visual/table items. A candidate is not an accepted code value.

## Track 2 - additional primary NASA/FAA/academic sources required

- Mass build-up for both moving nacelle/rotor assemblies, their centroids and conversion-axis geometry.
- Full inertia tensors by weight/configuration and the reference CG/axes.
- Steel versus composite/advanced blade geometry, mass distribution, first/second moments, flap axis, precone, hub spring and damping.
- Rotor-speed governor schedules versus mode, nacelle angle, airspeed and load restrictions.
- Rotor airfoil stations and Mach/Reynolds/post-stall/reverse-flow polars.
- Rotor/wing interference, wake contraction/skew, download and dynamic/nonuniform inflow evidence.
- Component aerodynamic databases with reference dimensions, control gearing and valid ranges.
- Quantitative flight-control mixing, phase-out, actuator travel/rate and SCAS/governor schedules.
- Mode-specific trim/test points with weight, CG, atmosphere, flap, rpm and control configuration.

Search priority must be primary NASA technical reports, contractor reports archived by NASA, FAA certification/flight-manual material where public, and original academic wind-tunnel/identification papers. Secondary compilations remain `DOCUMENTED_SECONDARY` and may not override conflicting primary configurations.

## Track 3 - derivations after parent evidence is fixed

|derived item|required parents|formula/condition|
|-|-|-|
|SI total mass|selected weight state|`m_kg = weight_lbf * 4.4482216152605 / g` if source reports force, or direct lbm conversion only when explicitly mass|
|Rotor radius|verified diameter|`R = D/2`; `1 ft = 0.3048 m`|
|Rotor angular speed|selected rpm schedule|`Omega = rpm*2*pi/60`|
|`KI` candidate|two verified tensors and code angle convention|`KI = (I(beta=0)-I(beta=pi/2))/(pi/2)` only if linear interpolation is approved|
|Blade `Ib` and `Sblade`|verified spanwise mass density and flap-axis location|`Ib=int r_h^2 dm`; `Sblade=int r_h dm`; do not reuse uniform formulas|
|`Jpolar`|rotating assembly mass distribution|sum polar inertias about mast; state included hub/shaft/blade components|
|Component AC vectors|verified source stations and code origin|apply one documented station/waterline/buttline-to-body transform|
|Dimensionless derivatives|verified dimensional data or vice versa|use source reference area/length, dynamic pressure and rate normalization exactly|

Every derivation retains parent inventory IDs and uncertainty; derived values cannot outrank their least-confident parent.

## Track 4 - values likely to remain conceptual pending experiments

- normal-flow blend center/half-width;
- scalar wing slip-area heuristics;
- simplified post-stall tanh caps if no complete database is found;
- one-way `wakeFactor` if no interference data support a higher-order model;
- solver seeds, tolerances, damping, regularization and diagnostic thresholds.

These may remain only as `ASSUMED_CONCEPT` or `NUMERICAL`, with applicability and sensitivity recorded. They must not be relabeled as XV-15 data because they produce plausible behavior.

## Track 5 - behavior-preserving structural separation before sourcing

1. Split `RH` into mass-CG and hub-geometry fields with both initialized to the current value; add identity regression before any replacement.
2. Separate endpoint/configuration inertia storage from an interpolation law; initially reproduce current `I0-betaM*KI` exactly.
3. Introduce a rotor-speed provider that initially returns constant `62 rad/s` for all inputs.
4. Replace embedded wing/vertical-tail empirical constants with named fields, initially unchanged.
5. Separate rotor blade geometry, polar, mass distribution and flap-axis/hub-restraint data structures while retaining the current uniform/center-hinge behavior.
6. Separate command convention, side allocation, actuator limits and nacelle-angle mixing schedules; initial schedule must reproduce current direct mapping.

Each structural change is a distinct task/PR. No structural split and numeric replacement are combined.

## Track 6 - parameter-family regression required after later replacement

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

## Phase gates

- Gate A - all active parameters are inventoried. Exit evidence: repository-wide `P.` and production-literal search reconciles with `PARAMETER_SOURCE_INVENTORY.md`; unused fields are explicitly identified.
- Gate B - every documentary source claim has exact PDF page and printed page/table/figure/equation or paragraph, plus original unit, weight/configuration/blade/mode and coordinate definition. Titles and old notes are insufficient.
- Gate C - every proposed numeric replacement receives manual review before code change. Conflicting sources remain side by side; no automatic winner is selected.
- Gate D - change one parameter family at a time. Structural separation precedes value replacement and preserves initial behavior.
- Gate E - family-specific regression passes before the broader suite. Failures, nonconvergence, NaN/Inf/complex values and bound contacts remain visible.
- Gate F - no dense envelope, transition/airplane stability map or XV-15 fidelity claim until critical mass/inertia, rotor geometry/speed/blade, aerodynamic, wake, control-mixing and trim-closure families are resolved.

## Proposed order

1. Human visual verification of local weight/inertia/rotor tables and figures.
2. Coordinate and configuration ledger.
3. Behavior-preserving `RH` and embedded-constant splits.
4. Mass/inertia family proposal and regression.
5. Rotor geometry, speed schedule and blade-configuration selection.
6. Blade mass/flap mechanics, then polar/inflow/wake families.
7. Airframe aerodynamic database and component stations.
8. Control mixing/limits and mode-specific trim formulation.
9. Local trim/linearization verification.
10. Only after Gate F, limited envelope expansion and explicitly scoped XV-15 comparisons.

## Stop conditions

Stop and request review if a source lacks configuration/weight/blade/mode context, a table cannot be visually read, a unit or axis is ambiguous, two primary sources disagree, a proposed change would combine parameter families, or a replacement requires changing equations/limits/solver behavior to make tests pass.
