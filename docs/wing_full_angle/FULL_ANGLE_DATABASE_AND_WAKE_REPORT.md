# Full-Angle Database and Wake Strip Report

Database: `data/wing_full_angle/full_angle_selected/wing_full_angle_database.csv`

Metadata: `data/wing_full_angle/full_angle_selected/database_metadata.json`

## Construction

- Geometry basis: standard NACA 64A223 from the traceable 6A generator.
- Schema: `CL/CD/Cm = f(alpha, Re, Mach, flapDeg)`.
- Alpha: -180 to 180 deg, 1 deg spacing.
- Reynolds: 0.6e6, 1.0e6, 1.4e6.
- Mach: 0, 0.10.
- Flap: 0, 20, 40, 50, 60 deg symmetric plain-flap family only.
- Low/mid clean-airfoil rows use formal XFOIL where accepted; 7 integer-alpha fill rows are tagged `XFOIL_GRID_INTERPOLATED`.
- Near negative 90 deg rows use TM-88373 text-constrained selected curve digitization.
- Bridge rows are explicitly tagged `BRIDGE_MODEL`.
- Positive deep-stall rows are tagged `UNVALIDATED_POSITIVE_DEEP_STALL`.
- Periodic closure is explicit at -180/180 deg.

Checks in `validation/wing_full_angle/full_angle/full_angle_database_checks.csv`:

- row_count = 10830, PASS.
- max_adjacent_l1_jump = 0.11699, PASS.
- min_cd = 0.00728, PASS.
- surrogate_v0_used = 0, PASS.

Source-share and XFOIL fill audits:

- `validation/wing_full_angle/full_angle/source_class_share_audit.csv`
- `validation/wing_full_angle/full_angle/xfoil_grid_fill_audit.csv`
- `validation/wing_full_angle/full_angle/bridge_candidate_summary.csv`

TM-88373 selected-curve audit outputs:

- digitized CSV: `data/wing_full_angle/tm88373_digitized/tm88373_selected_curves_digitization.csv`
- repeat CSV: `data/wing_full_angle/tm88373_digitized/tm88373_selected_curves_repeat_digitization.csv`
- uncertainty summary: `data/wing_full_angle/tm88373_digitized/tm88373_digitization_uncertainty_summary.csv`
- source page audit images: `data/wing_full_angle/tm88373_digitized/source_pages/`
- overlays: `data/wing_full_angle/tm88373_digitized/overlays/`

The TM curves are text-constrained from verified local sources. Source page PNGs are rendered from the verified local PDF; graphical point-picking of every scanned curve is not claimed. This supports `TM88373_DATA_GATE = PARTIAL`, not a final graphical digitization PASS.

## Production Lookup

`wing_full_angle_lookup` accepts `alpha, Re, Mach, flapDeg, P`. It now uses PCHIP in alpha inside each discrete slice and linear interpolation across Re, Mach and the physically compatible symmetric plain-flap grid. Old `(alpha,P)` calls are supported only through deterministic diagnostic defaults and report `dimensionReductionActive = true`.

`wing_local_flow` computes local alpha, Reynolds number, Mach number and dynamic pressure for every strip region. The full-angle path does not add legacy linear aileron CL/Cm increments outside the database.

The database flap dimension is a symmetric plain-flap family from TM-88373; it is not a validated differential aileron model for the 7-input aircraft interface.

## Wake Strip Model

Production files:

- `model/wing/wing_model_full_angle.m`
- `model/wing/wing_integrate_strips.m`
- `model/wing/wing_strip_geometry.m`
- `model/wing/wing_wake_coverage.m`
- `model/wing/wing_local_flow.m`
- `model/wing/wing_full_angle_lookup.m`
- `model/wing/load_wing_aero_database.m`

Free-stream and rotor-wake strip portions call the same full-angle CL/CD/Cm lookup. Region differences come only from local velocity, alpha, Reynolds/Mach, dynamic pressure, covered area and moment arm. The model does not blend complete `FNear`/`FLiftLine` force results and does not use `branchWeight`.

Wake coverage uses rotor hub position, rotor axis, disk-wing projection, wake radius/contraction, left/right independent wake centers and strip overlap area. CR-114614 extraction is recorded in `data/wing_full_angle/cr114614_wake_formula_extract.csv` and `docs/wing_full_angle/CR114614_WAKE_EXTRACTION.md`.

The wake contraction default remains an engineering assumption: `P.wing.fullAngleWakeContraction = 1.0`. It is user-adjustable and is not selected by tuning trim smoothness.

Focused wake MATLAB check:

- rel12To48 = 7.706147818981e-16.
- rel24To48 = 8.788933112605e-16.
- rel48To96 = 3.813755800023e-16.
- dWakeForce = 4.899759254120e+03 N.
- PASS for software geometry and finite strip integration.
