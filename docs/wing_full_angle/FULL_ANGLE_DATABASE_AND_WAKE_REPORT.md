# Full-Angle Database and Wake Strip Report

Database: data/wing_full_angle/full_angle_selected/wing_full_angle_database.csv
Metadata: data/wing_full_angle/full_angle_selected/database_metadata.json

## Construction

- Low/mid angle values use accepted clean-airfoil XFOIL points where available.
- Near negative 90 deg values use task anchor data associated with TM-88373.
- Positive deep-stall and closure regions use mirrored/bridged engineering extension.
- Cm is retained and extended continuously with the same database row structure; it is not claimed as experimentally validated over full angle.
- Periodic closure is explicit at -180/180 deg.

Checks in validation/wing_full_angle/full_angle/full_angle_database_checks.csv:

- periodic_closure_error = 0.0, PASS.
- max_adjacent_coefficient_jump_per_deg = 0.12813826165513573, PASS.
- max_combined_slope_per_rad = 7.341781586982307, PASS.
- xfoil_clean_rows_used = 297, PASS.

Figure: docs/wing_full_angle/figures/full_angle_database_nominal.png.

## Wake Strip Model

Production model files:

- model/wing/wing_model_full_angle.m
- model/wing/wing_integrate_strips.m
- model/wing/wing_strip_geometry.m
- model/wing/wing_wake_coverage.m
- model/wing/wing_local_flow.m
- model/wing/wing_full_angle_lookup.m
- model/wing/load_wing_aero_database.m

Free-stream and rotor-wake strip portions call the same full-angle CL/CD/Cm lookup. Region differences come only from local velocity, alpha, Reynolds/Mach lookup metadata where present, dynamic pressure, covered area, and moment arm. The model does not blend complete FNear/FLiftLine force results and does not use normalFlowBranchWeight.

Focused wake check: rel12To48 = 3.453941651636e-17, rel24To48 = 1.544649664675e-16, dWakeForce = 2434.955878898 N, PASS.
