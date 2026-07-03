# Production Integration Report

- Public entry point: `model/wing_model.m`.
- Legacy implementation: `model/wing/wing_model_legacy.m`.
- New implementation: `model/wing/wing_model_full_angle.m`.
- Default: legacy.
- Opt-in selector: `P.wing.fullAngleModelEnabled = 1` or `P.wing.modelType = 'fullAngle'`.

The full-angle path uses one coefficient law for free-stream and rotor-wake strip portions. It does not blend complete `FNear` and `FLiftLine` force results and does not add legacy linear aileron increments outside the database.

Runtime database: `wing_full_angle_standard_naca64a223_multidim_v1_20260703`.
