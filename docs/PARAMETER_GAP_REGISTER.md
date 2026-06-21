# Parameter Gap Register

## Priority policy

This register preserves the original gap IDs and technical findings, but replaces the previous single severity with two independent labels:

- `Current concept-model risk`: risk to internal physical consistency, behavior, and interpretation of the current conceptual model.
- `XV-15 reproduction blocker`: degree to which the issue blocks future XV-15-specific reproduction, validation, or comparison.

Both dimensions use `CRITICAL`, `HIGH`, `MEDIUM`, `LOW`, `INFO`, and `NONE`. A `HIGH` label does not by itself mean a confirmed production-code defect. Missing a citation alone is not enough to assign `HIGH`; the label reflects model consequence, semantic ambiguity, or downstream claim risk. No item below authorizes a parameter change.

## Retained H-series gaps

### GAP-H01 - structural coupling resolved; independent radius values remain unsourced

- Resolved structural defect: `P.mass.RH_mass` is now read only by `mass_properties`, and `P.rotor.RH_hub` is now read only by `rotor_model_bemt`; both retain the unchanged conceptual value `0.75 m`.
- Compatibility state: `P.mass.RH` remains deprecated, is initialized from `RH_mass`, has zero production reads, and has no model effect when modified.
- Verification: focused tests cover the old shared-radius formulas at `betaM = [0, pi/4, pi/2]`, independent synthetic perturbations, and deprecated-alias inactivity.
- Evidence still missing: separate nacelle/rotor moving-mass centroid relative to conversion axis and mast/hub center relative to that axis, with the same aircraft origin and nacelle-angle convention.
- Current concept-model risk: `MEDIUM` for numeric provenance only; structural coupling status is `RESOLVED`.
- XV-15 reproduction blocker: `HIGH` for the two aircraft-specific values.
- Recommended disposition: keep both conceptual values unchanged until independently sourced; do not infer equality for a future XV-15 dataset.
- Required source type: primary XV-15 mass-properties/build-up report plus dimensioned installation/three-view or manufacturer/NASA geometry.
- Blocks: aircraft-specific mass/CG and rotor force-arm replacement, transition interpretation, and XV-15 comparison; it no longer blocks independent current-model parameter governance.

### GAP-H02 - `I0` and `KI` lack a configuration- and unit-closed source

- Problem: the nominal inertia matrix and linear tilt slope are conceptual. `KI` is consumed per radian.
- Current code consequence: all angular accelerations and eigenvalues depend on an unverified base matrix and linear nacelle-angle law.
- Evidence available: `I=I0-betaM*KI`; NUAA PDF 3 equations (1)-(3) gives a similar low-order relation. NASA TM X-62407 PDF 15, printed page 12, contains airplane/helicopter inertias at 13,000 lb in `slug-ft^2`, but extraction loses at least one label and does not establish cross-inertia axes.
- Evidence missing: verified table image, complete `Ixx/Iyy/Izz/Ixy/Ixz/Iyz`, sign convention, reference CG, weight state, airplane/helicopter nacelle definitions, and whether any reported increment is per degree or endpoint-to-endpoint.
- Current concept-model risk: `HIGH`.
- XV-15 reproduction blocker: `HIGH`.
- Recommended disposition: visually transcribe both endpoint matrices, retain both without choosing, convert `slug-ft^2` to `kg m^2`, then decide whether a linear interpolation is defensible. If a slope is formed, use `KI=(I_heli-I_air)/(pi/2)` under the code angle convention and document sign conversion.
- Required source type: primary mass-properties report/table or NASA design manual with full axes and configuration.
- Blocks: credible linearization/stability, transition trim, flight-envelope loads, XV-15 comparison.

### GAP-H03 - constant `Omega` conflicts with documented mode scheduling

- Problem: one constant `62 rad/s` is used in all modes.
- Current code consequence: tip speed, advance ratio, blade loads, centrifugal flap stiffness, gyro momentum, induced solution and power/torque remain tied to one speed from hover through airplane mode.
- Evidence available: NASA TM X-62407 PDF 22, printed page 19, lists nominal design 565 rpm hover and 458 rpm cruise. NASA TM-81244 PDF 8 records flight-stage 589 rpm, 517 rpm, and 458 rpm values under different load-management choices.
- Evidence missing: intended model configuration, operational schedule versus nacelle angle/airspeed, governor logic, test restrictions, and blade version.
- Current concept-model risk: `HIGH`.
- XV-15 reproduction blocker: `HIGH`.
- Recommended disposition: do not replace the scalar in place. Define the intended configuration and then add a behavior-preserving speed-provider interface before introducing one reviewed schedule.
- Required source type: primary flight manual/governor schedule or test report tied to configuration.
- Blocks: transition/airplane trim, power/loads, dense envelope, XV-15 comparison.

### GAP-H04 - blade mass model omits real distribution and hinge mechanics

- Problem: `bladeMass=45 kg` with uniform full-span distribution creates `Ib=mR^2/3` and `Sblade=mR/2`; the flap model has no sourced hinge offset, hub spring stiffness, structural damping, or lag/elastic representation.
- Current code consequence: gravity and centrifugal flap moments, first-harmonic disk tilt, and rotor force direction rely on a highly coupled conceptual inertia model.
- Evidence available: NUAA PDF 4 equation (4) identifies `Ib`; NASA TM X-62407 PDF 49, printed page 46, describes steel-blade construction and a nonrotating hub-moment spring; PDF 20, printed page 17, lists precone and a Lock-number entry.
- Evidence missing: blade mass, spanwise mass distribution, first and second mass moments about the actual flap axis, hinge offset, spring law, damping, precone implementation, and steel/composite/advanced-blade version.
- Current concept-model risk: `HIGH`.
- XV-15 reproduction blocker: `HIGH`.
- Recommended disposition: preserve current numeric behavior while separating mass distribution, flap-axis location, spring and damping parameters; replace only after one blade configuration is selected.
- Required source type: rotor structural dynamics report, blade property table/drawing, hub-moment-spring report.
- Blocks: rotor flapping validation, transition loads, linearization, XV-15 comparison.

### GAP-H05 - simplified rotor polar and twist are not configuration-valid

- Problem: constant chord, one linear `twistTip`, a constant lift slope, tanh `CLmax`, and quadratic drag replace the documented nonlinear blade geometry and airfoil behavior.
- Current code consequence: thrust, torque, in-plane force, flap moments and stall response are not tied to Mach, Reynolds number, radial airfoil or reverse flow.
- Evidence available: NASA TM X-62407 PDF 20-21, printed pages 17-18, gives a blade-characteristics figure; PDF 49 describes a 14-inch steel NACA 64-series blade. NASA TM-81244 PDF 4 states 45 deg root-to-tip twist. These statements cannot be reduced to the current `-6 deg` linear tip parameter without digitization and convention review.
- Evidence missing: radial chord/twist/airfoil stations, zero-lift-angle definition, blade version, polar tables, Mach/Reynolds ranges and post-stall/reverse-flow data.
- Current concept-model risk: `HIGH`.
- XV-15 reproduction blocker: `HIGH`.
- Recommended disposition: retain the conceptual polar for current internal checks; later digitize one verified blade geometry and add table interfaces before changing values.
- Required source type: primary blade drawing/table and wind-tunnel/airfoil polar report.
- Blocks: rotor performance, transition/airplane trim, envelope, XV-15 comparison.

### GAP-H06 - uniform inflow and scalar `wakeFactor`

- Problem: the production rotor path sets `viField=viMean`; `inflowHarmonic` is unused. Wing slipstream velocity is `wakeFactor*max(vi,0)` with `wakeFactor=1.60`.
- Current code consequence: azimuthal/radial inflow, dynamic inflow, wake contraction, skew, wing blockage/fountain effects, negative induced velocity and feedback from wing to rotor are absent.
- Evidence available: NUAA PDF 4-6 describes induced-flow iteration and rotor/wing interference at a method level. Current code explicitly documents uniform inflow.
- Evidence missing: validated inflow model coefficients, wake geometry, contraction/development, nacelle-angle and advance-ratio dependence, interaction test data.
- Current concept-model risk: `HIGH`.
- XV-15 reproduction blocker: `HIGH`.
- Recommended disposition: treat `wakeFactor` as a conceptual one-way coupling only. Select and validate an inflow/wake model before attempting aircraft-specific calibration.
- Required source type: rotor/wing wind-tunnel data or validated comprehensive-analysis formulation.
- Blocks: transition trim, wing download, loads, envelope, XV-15 comparison.

### GAP-H07 - component and pivot 3-D positions are not traceable

- Problem: rotor pivot, wing free/slip ACs, fuselage AC, horizontal-tail AC and twin-fin ACs are conceptual points relative to an incompletely documented nominal origin.
- Current code consequence: every `cross(r,F)`, local rotational velocity and CG-shift correction depends on these positions.
- Evidence available: code consistently subtracts `cgShift`; NASA TM X-62407 contains general dimensions and CG limits, but no current code-to-station transformation has been established.
- Evidence missing: common fuselage-station/waterline/buttline origin, sign directions, component aerodynamic centers by configuration, conversion-axis line and reference CG.
- Current concept-model risk: `HIGH`.
- XV-15 reproduction blocker: `HIGH`.
- Recommended disposition: establish one coordinate ledger and transformation before replacing any station.
- Required source type: dimensioned three-view, geometry report, aerodynamic database definitions.
- Blocks: force/moment validation, transition trim, linearization, envelope, XV-15 comparison.

### GAP-H08 - aerodynamic derivatives and saturation lack validity ranges

- Problem: wing, fuselage, horizontal-tail and vertical-tail coefficients are conceptual linear/quadratic forms with tanh caps and an embedded vertical-tail drag term.
- Current code consequence: static and damping loads extrapolate outside any documented alpha, beta, rate, flap, Mach or Reynolds range.
- Evidence available: NUAA PDF 6-8 supports component decomposition and generic force/moment structure, not current coefficients. Existing repository audits explicitly classify these values as conceptual/reference pending.
- Evidence missing: configuration-specific coefficient tables/derivatives, reference areas/lengths, sign conventions, control gearing, stall/post-stall and interference data.
- Current concept-model risk: `HIGH`.
- XV-15 reproduction blocker: `HIGH`.
- Recommended disposition: preserve current low-order model until a complete coefficient family and its normalization are reviewed; never replace isolated derivatives without reference geometry.
- Required source type: primary wind-tunnel aerodynamic database or flight-identified derivative report.
- Blocks: stability derivatives, transition/airplane trim, envelope, XV-15 comparison.

### GAP-H09 - control limits and real mixing/phasing are absent

- Problem: code has direct common/differential allocation and fixed broad limits; no nacelle-angle phasing, mechanical gearing, governor overlay, flaperon schedule or SCAS gain schedule.
- Current code consequence: side rotor commands are clipped directly and conventional surfaces remain independently active; actual actuator/blade limits and transition authority are not represented.
- Evidence available: NASA TM X-62407 PDF 56, printed page 53, section 8.1 describes rotor/fixed-control functions and phasing; NASA TM-81244 PDF 4-5 describes control phase-out and governor overlay qualitatively.
- Evidence missing: quantitative mixer gains, gearing, schedules, actuator stops/rates, governor/SCAS contributions and configuration applicability.
- Current concept-model risk: `MEDIUM`.
- XV-15 reproduction blocker: `HIGH`.
- Recommended disposition: retain current code-level convention; source and implement one behavior-preserving mixer interface before adding schedules.
- Required source type: primary control-system schematic, rigging schedule, flight-control report/manual.
- Blocks: transition trim, control margin, handling qualities, envelope, XV-15 comparison.

### GAP-H10 - symmetric trim does not close transition or airplane modes

- Problem: `trim_symmetric` solves only theta, common collective and common longitudinal cyclic for `[udot,wdot,qdot]=0`; elevator is fixed at zero and rotor speed/control phasing are fixed.
- Current code consequence: calling it at transition/airplane nacelle angles does not establish a complete or aircraft-appropriate trim problem.
- Evidence available: code contract in `analysis/trim_symmetric.m`; NUAA PDF 9-12 discusses mode-dependent trims and linearization conceptually.
- Evidence missing: mode-specific unknowns, fixed quantities, control schedules, propulsion closure, aerodynamic database and constraints.
- Current concept-model risk: `MEDIUM`.
- XV-15 reproduction blocker: `HIGH`.
- Recommended disposition: do not tune parameters to force closure. Specify separate transition/airplane trim formulations only after the parameter families above are resolved.
- Required source type: validated model formulation, aircraft control schedule and trim/test data.
- Blocks: transition/airplane linearization, flight envelope, XV-15 comparison.

## Retained M-series gaps

### GAP-M01 - total and moving mass weight-state mapping

- Problem: `m=6000 kg` and combined `mNac=900 kg` have clear code semantics but no component inclusion or weight state.
- Current code consequence: disk loading, gravity, CG shift and inertia normalization are internally consistent but cannot be tied to empty, mission-empty, design-gross, test or maximum-gross conditions.
- Evidence available: NASA TM X-62407 PDF 14, printed page 11, explicitly lists basic empty `9,076 lb`, research mission empty `10,073 lb`, and design gross `13,000 lb`.
- Evidence missing: code target weight state, fuel/payload/crew state and moving-assembly build-up (both sides versus per side).
- Current concept-model risk: `MEDIUM`.
- XV-15 reproduction blocker: `MEDIUM`.
- Recommended disposition: add a weight-state ledger before proposing values; retain combined-both-sides semantics for `mNac`.
- Required source type: primary weight-and-balance/group-weight table.
- Blocks: XV-15 mass comparison and load-specific trim; not conceptual execution.

### GAP-M02 - `Jpolar=0` disables gyroscopic moments

- Problem: the implemented gyro identity is multiplied by zero.
- Current code consequence: rotor gyroscopic coupling is absent in all production results.
- Evidence available: `RB:106-107`; synthetic nonzero test proves the algebraic channel only.
- Evidence missing: polar inertia of the rotating assembly, included shafts/hub/blades, mode-dependent rpm and sign convention.
- Current concept-model risk: `MEDIUM`.
- XV-15 reproduction blocker: `HIGH`.
- Recommended disposition: keep zero explicitly as an omission marker; derive or source `Jpolar` only after rotating assembly and speed schedule are fixed.
- Required source type: rotor/drive-system inertia report or mass build-up.
- Blocks: high-rate maneuver dynamics and aircraft-specific linearization; not static zero-rate trim.

### GAP-M03 - normal-flow blend center and width are code-only

- Problem: center `0.35` and half-width `0.15` blend two different conceptual wing models.
- Current code consequence: loads and derivatives in the transition band depend on a continuity device rather than validated aerodynamics.
- Evidence available: `WG:98-140`, explicit comments in `params_nominal.m`, and smoothness tests. The checked-out `AGENTS.md` section 25.2 still says `0.20`, while executable code and `docs/PAPER_CODE_MAPPING.md:736` say `0.15`.
- Evidence missing: local wing-flow regime map and force/moment data across normal-to-chordwise flow.
- Current concept-model risk: `MEDIUM`.
- XV-15 reproduction blocker: `HIGH`.
- Recommended disposition: retain executable `0.15` as `ASSUMED_CONCEPT` in this read-only phase, reconcile the stale documentation in a separate authorized documentation task, and do not interpret the boundaries as stall or physical regime limits.
- Required source type: wing-in-slipstream wind-tunnel/CFD data with local velocity definition.
- Blocks: derivative interpretation near the band, transition envelope, XV-15 comparison.

### GAP-M04 - embedded physical constants are not centralized

- Problem: wing area heuristics (`0.25`, `0.60`, `0.40`, harmonic `2`), vertical-tail drag `0.02`, and flap residual angle anchor `0.05` are embedded in production functions.
- Current code consequence: source status and sensitivity are difficult to trace; values can be overlooked during parameter-family review.
- Evidence available: exact code lines recorded as `EMB-002` through `EMB-004` and `EMB-012` in the inventory.
- Evidence missing: physical derivation or explicit designation as numerical-only.
- Current concept-model risk: `MEDIUM`.
- XV-15 reproduction blocker: `MEDIUM`.
- Recommended disposition: later perform behavior-preserving extraction into named fields before any numeric replacement; keep exact values initially.
- Required source type: model derivation for physical terms; numerical convergence rationale for solver scaling.
- Blocks: controlled parameter replacement and sensitivity accounting.

### GAP-M05 - reverse-flow, windmill and autorotation applicability

- Problem: `atan2(UP,max(abs(UT),1e-8))` removes the sign of tangential velocity from its denominator; momentum update clips thrust and induced velocity to nonnegative values.
- Current code consequence: reverse-flow elements, windmill-brake state, negative thrust/inflow and autorotation are not modeled physically.
- Evidence available: `RB:72`, `RB:320`; tests only screen small/negative `UT` as an applicability condition. NASA TM-81244 describes autorotation demonstrations but does not validate this implementation.
- Evidence missing: multi-state momentum logic, signed blade-element conventions, reverse-flow polar and validation cases.
- Current concept-model risk: `MEDIUM`.
- XV-15 reproduction blocker: `MEDIUM`.
- Recommended disposition: mark regimes unsupported; do not patch with thresholds during a parameter task.
- Required source type: rotorcraft momentum/BEMT primary formulation and XV-15 autorotation test data.
- Blocks: windmill/autorotation envelope and some high-advance-ratio cases.

### GAP-M06 - numerical differentiation and acceptance settings need family-specific sensitivity

- Problem: linearization steps, flap Jacobian step/regularization, trim Jacobian step, mixed-unit trim norm and at-limit tolerances are fixed.
- Current code consequence: discontinuities, clamps or scale changes may produce step-dependent derivatives or root selection.
- Evidence available: all settings are inventoried as `NUMERICAL`; limited tests use `1e-3,1e-4,1e-5` studies.
- Evidence missing: sensitivity at each retained trim family, conditioning record and branch/clamp distance.
- Current concept-model risk: `MEDIUM`.
- XV-15 reproduction blocker: `MEDIUM`.
- Recommended disposition: after physical parameter families stabilize, run local three-step sensitivity and nonlinear increment checks before accepting any A/B matrix.
- Required source type: numerical verification, not literature.
- Blocks: accepted linearization maps and stability claims.

## Retained LOW / INFO gaps

### GAP-L01 - unused compatibility and metadata fields

- Problem: eight declared compatibility fields, including deprecated `P.mass.RH`, are unused; `bladeMassDistribution` and `vtail.c` are also not consumed by production calculations.
- Current code consequence: readers may mistake them for active physics.
- Evidence available: repository-wide `P.` read search.
- Evidence missing: none for current use status.
- Current concept-model risk: `LOW` for inactive metadata clarity; compatibility fields remain `INFO`-level notes.
- XV-15 reproduction blocker: `NONE`.
- Recommended disposition: retain only with explicit inactive notes until a dedicated compatibility cleanup is authorized.
- Required source type: none.
- Blocks: nothing, provided reports do not count them as active.

## Dependency summary

|later phase|blocking gaps|
|-|-|
|Aircraft-specific linearization/stability|H02, H03, H04, H05, H07, H08, H09, H10, M02, M03, M06|
|Transition/airplane trim|H01-H10, M03, M05|
|Flight envelope|H03-H10, M01-M06|
|XV-15 comparison|H01-H10, M01-M05|

There are no `CRITICAL` gaps in either risk dimension in this static audit: the conceptual code can exist and run with assumptions. `HIGH` current-model risks identify semantic or model-governance hazards; `HIGH` XV-15 blockers prohibit aircraft-specific interpretation, reproduction, or validation claims, not basic execution.
