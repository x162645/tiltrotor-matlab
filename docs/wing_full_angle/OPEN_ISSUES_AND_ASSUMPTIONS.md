# Open Issues and Assumptions

- The exact XV-15 `NACA 64A223 Modified` coordinates were not recovered. The model claims standard NACA 64A223 only.
- The CR-114614 input is a verified local technical extract, not the 268-page original facsimile.
- TM-88373 selected curves are text-constrained with rendered page images, overlays and repeat checks; full scanned graphical point-picking is not claimed.
- The database contains 8604 `BRIDGE_MODEL` rows, 79.4460% of all rows. Candidate bridge sensitivity is material in unsupported deep-stall regions.
- Positive deep-stall rows are explicitly tagged `UNVALIDATED_POSITIVE_DEEP_STALL`.
- The database flap dimension is symmetric plain-flap data. It is not a validated differential aileron model.
- The full-angle production path is a longitudinal/full-angle-wing baseline with no validated lateral aileron aerodynamics; `CONTROL_SURFACE_GATE = PARTIAL`.
- `P.wing.fullAngleWakeContraction = 1.0` is an engineering assumption retained as a user-adjustable parameter, not a measured contraction curve.
- The wake model is a rotor-axis projected strip-area method, not a validated free-wake or CFD method.
- Legacy remains the default model until user approval.
