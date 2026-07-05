# Production Integration Report

- Public entry point: `model/wing_model.m`.
- Legacy implementation: `model/wing/wing_model_legacy.m`.
- New implementation: `model/wing/wing_model_full_angle.m`.
- Default: legacy.
- Opt-in selector: `P.wing.fullAngleModelEnabled = 1` or `P.wing.modelType = 'fullAngle'`.

The full-angle path uses one coefficient law for free-stream and rotor-wake strip portions. It does not blend complete `FNear` and `FLiftLine` force results and does not add legacy linear aileron increments outside the database.

Runtime database: `wing_full_angle_standard_naca64a223_multidim_v1_20260703`.

Runtime lookup policy:

- alpha: PCHIP interpolation in each selected database slice;
- Reynolds: linear interpolation between adjacent database values;
- Mach: linear interpolation between adjacent database values;
- flap: linear interpolation only inside the supported symmetric plain-flap family;
- out-of-range dimensions: `P.wing.fullAngleOutOfRangePolicy = 'clamp'`, exposed by `outOfRangeClamped`.

Control-surface interface status:

- The database flap dimension is a TM-88373 symmetric plain-flap family.
- The aircraft 7-input `aileron` command is a left/right differential lateral control input.
- No credible full-angle differential aileron data chain is present in the current local sources.
- The production full-angle path is therefore explicitly labeled `longitudinal_full_angle_baseline_no_lateral_aileron_aero`.
- `check_wing_full_angle_control_surface` verifies that the aileron force/moment derivative remains zero and that this status is exposed in diagnostics.

Default state remains unchanged: the legacy model is still selected by `params_nominal.m`.
