# Unified Wing Aerodynamic Data Acquisition and Freeze Task

Date: 2026-07-02

## 1. Objective

Complete all data acquisition, digitization, traceability, geometry/location freeze, and rotor-wake parameter freeze required before any production replacement of the current wing aerodynamic model.

This task is a hard prerequisite for the future unified full-angle wing aerodynamic model. It is not a local repair of the 0 deg pitch hump and it must not tune parameters to match NUAA trim curves.

Authoritative physical baseline at task start:

- `feature/nuaa-equation-17`
- `docs/PROJECT_CURRENT_BASELINE.md`

Authoritative source reports:

- NASA TM-88373 / USAAVSCOM TM 86-A-8, *Aerodynamic Characteristics of Two-Dimensional Wing Configurations at Angles of Attack Near -90 deg*
- NASA CR-114614 / Bell report 301-099-001, *A Mathematical Model for Real Time Flight Simulation of the Bell Model 301 Tilt Rotor Research Aircraft*

The report number is **CR-114614**. Do not use the incomplete identifier `CR-11461`.

## 2. Absolute scope boundary

Until the hard gate in Section 8 passes, do not modify:

- `model/wing_model.m`
- any production force/moment equation
- `params_nominal.m` production values
- GUI parameter catalog or GUI controls
- trim definitions, control allocation, solver behavior, control limits
- baseline validation outputs

The only permitted repository changes in this task are source-data records, digitized data, digitization/verification utilities, audit reports, parameter manifests, and tests that validate those data artifacts.

## 3. Required deliverable structure

Create and populate:

```text
references/wing_aero/
  source_manifest.md
  source_checksums.csv
  TM88373/
    source_page_index.md
    configuration_manifest.csv
    digitized/
      tm88373_force_moment_long.csv
      tm88373_drag_crossplots.csv
      tm88373_reynolds_effects.csv
    uncertainty.md
    verification.md
  CR114614/
    source_page_index.md
    configuration_manifest.csv
    digitized/
      cr114614_wing_pylon_CL.csv
      cr114614_wing_pylon_CD.csv
      cr114614_wing_pylon_Cm.csv
      cr114614_large_negative_alpha_CL.csv
      cr114614_large_negative_alpha_CD.csv
      cr114614_aileron_effectiveness.csv
      cr114614_dihedral_effect.csv
      cr114614_wing_wake_tail_deflection.csv
      cr114614_rotor_wake_wing_parameters.csv
    uncertainty.md
    verification.md
  frozen/
    wing_geometry_and_location.yaml
    wing_control_surfaces.yaml
    wing_aero_dataset_manifest.yaml
    rotor_wake_geometry_and_parameters.yaml
    unresolved_parameter_register.csv
    parameter_freeze_report.md
analysis/data_digitization/
  scripts and reproducible extraction utilities
  generated verification plots

tests/
  data-artifact validation tests only
```

File names may be adjusted minimally if needed, but the semantic coverage must remain complete.

## 4. TM-88373 digitization requirements

Digitize all configurations relevant to a production full-angle wing model, with special priority on the basic NACA 64A223-derived section and plain-flap configurations.

At minimum capture:

- source PDF page and printed figure/table identifier
- configuration identifier from the report
- leading-edge configuration
- flap type
- flap chord ratio
- flap deflection
- angle of attack
- Reynolds number when distinguished
- `CL`
- `CD`
- quarter-chord `Cm`
- whether the point is force-balance or pressure-derived
- sweep direction or hysteresis branch when identifiable
- digitization method
- estimated x/y uncertainty
- reviewer status

The principal range is approximately -75 deg to -105 deg. Preserve the report sign conventions exactly in the raw files. Do not silently transform signs.

Required verification:

- redraw every digitized curve on top of or beside the source figure
- record axis calibration points
- independently review a statistically meaningful subset and every discontinuity/separation jump
- preserve duplicate or hysteretic points instead of averaging them away
- compare digitized summary values with textual checks reported in TM-88373, including the approximate minimum-drag statements

Do not invent values in obscured portions of curves. Use explicit `NaN` plus an unresolved entry.

## 5. CR-114614 digitization requirements

Digitize the complete wing-pylon and relevant rotor-wake/airframe input data required by a replacement wing model.

At minimum include:

### 5.1 Wing-pylon aerodynamics

- wing-pylon `CL(alpha)` for each tabulated flap/flaperon setting
- wing-pylon `CD(alpha)` for each setting
- wing-pylon `Cm` or pitching-moment schedule and its independent variables
- airplane and helicopter mast-angle data
- large-negative-angle `CL` and `CD`
- Mach/compressibility corrections used by the report
- all `Not Defined` regions preserved as missing, not interpolated

### 5.2 Lateral/control data

- aileron effectiveness versus angle/state
- wing-pylon dihedral stability data
- any yaw/drag coupling explicitly tabulated for the aileron/flaperon system

### 5.3 Wake/interference data

- rotor-wake induced velocity/geometry parameters acting on the wing
- immersed wing area definition
- wake contraction model and parameters
- wake incidence/angle-of-attack construction
- wing-wake deflection at the horizontal stabilizer
- any flap, mast-angle, loading, sideslip, or conversion-angle dependencies

For each extracted table, retain:

- table number
- PDF page number
- printed appendix page
- row and column header interpretation
- original engineering units
- converted SI units in separate columns where applicable
- transcription confidence
- unresolved header/scan ambiguity

Do not use OCR output as authoritative without visual verification against the page image.

## 6. Geometry and location freeze

Freeze the geometry/location set needed by the future production model. Every field must have one of four source classes:

- `DIRECT_SOURCE`
- `DERIVED_FROM_SOURCE`
- `EXPLICIT_CONCEPT_ASSUMPTION`
- `UNRESOLVED_BLOCKER`

The freeze must cover at least:

- total wing area, span, chord, aspect ratio
- sweep, dihedral, incidence
- airfoil designation and modification status
- flap and flaperon chord ratios
- flap and flaperon spanwise start/end locations
- pylon/nacelle obscured region
- left/right panel segmentation
- aerodynamic reference point and moment reference
- wing reference point relative to aircraft datum
- current-model CG relationship
- slipstream and free-stream panel aerodynamic-center locations
- rotor center, rotor plane, wing plane, pivot axis and relevant separations

If exact XV-15/Bell-301 datum conversion is unavailable, do not invent a precise mapping. Freeze an explicit conceptual location only if the project owner approves it, and label it as such.

## 7. Rotor-wake parameter freeze

Freeze the complete set needed to compute panel local flow consistently across hover, conversion, and airplane mode:

- wake radius/contraction relationship
- wake centerline/axis definition
- conversion-angle convention
- wake skew/deflection treatment
- induced-velocity magnitude source
- spatial/radial distribution
- axial and in-plane components
- swirl inclusion or explicit omission
- immersed-area calculation
- overlap logic for left/right wakes
- fuselage/nacelle blockage treatment
- rotor-to-wing height and chordwise offset
- validity range and extrapolation behavior

Where CR-114614 and the current NUAA Eq.16-17 implementation differ, document both. Do not choose silently. The freeze report must recommend one production definition and explain why, but production code remains unchanged in this task.

## 8. Hard gate

The task passes only when all of the following are true:

1. Every required parameter/data field appears in the manifest.
2. Every field has a value or an explicit `UNRESOLVED_BLOCKER`.
3. No production-required field is filled by an unlabeled guess.
4. TM-88373 digitized curves have verification plots and uncertainty records.
5. CR-114614 tables have visual double-check records and preserved units/headers.
6. Raw/source sign conventions and transformed project conventions are separately documented.
7. Geometry and location values are internally consistent.
8. Wake parameters define a complete local-flow calculation without hidden constants.
9. Automated artifact tests pass.
10. `unresolved_parameter_register.csv` contains zero hard blockers for the selected future production model.

If any hard blocker remains, the final result is `GATE_FAIL`. Do not proceed to model, parameter, or GUI changes.

## 9. Required final report

Create `references/wing_aero/frozen/parameter_freeze_report.md` containing:

- exact sources used
- data tables/curves acquired
- uncertainty and digitization limitations
- frozen geometry/location set
- frozen wake definition
- selected data hierarchy for the future unified full-angle model
- conflicts between TM-88373, CR-114614, current project assumptions, and NUAA equations
- unresolved items
- final `GATE_PASS` or `GATE_FAIL`
- explicit statement that production code was not changed

Also update the GitHub tracking issue with one final end-to-end report. Do not ask the user to relay intermediate stages between ChatGPT and Codex.

## 10. Git and execution rules

- Preserve existing uncommitted work.
- Stop immediately if unrelated untracked or modified files make non-destructive execution uncertain.
- Work only on the dedicated task branch.
- Commit source-data artifacts and reports in reviewable groups.
- Do not open or merge a production-model PR during this task.
- Do not modify or close Issue #24 as part of this task.
