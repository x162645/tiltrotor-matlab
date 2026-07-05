# Open Issues and Assumptions

- The exact XV-15 `NACA 64A223 Modified` coordinates were not recovered. The model claims standard NACA 64A223 only.
- The CR-114614 input is a verified local technical extract, not the 268-page original facsimile.
- TM-88373 selected Figure 6a curves now have graph digitization artifacts, but the evidence is limited to the selected database curves, not the full report.
- The database contains 10,386 `BRIDGE_MODEL` rows, 79.9169% of all rows. Candidate bridge sensitivity is material in unsupported deep-stall intervals.
- Positive deep-stall rows are explicitly tagged `ASSUMED_POSITIVE_DEEP_STALL_MIRROR_UNVALIDATED`.
- The database flap dimension is symmetric plain-flap data. It is not a validated differential aileron model.
- The full-angle production path is a longitudinal/full-angle-wing baseline with no validated lateral aileron aerodynamics; `CONTROL_SURFACE_GATE = PARTIAL`.
- `P.wing.fullAngleWakeContraction = 1.0` is an engineering assumption retained as a user-adjustable parameter, not a measured contraction curve.
- The wake model is a rotor-axis projected strip-area method, not a validated free-wake or CFD method.
- The expanded 0/15/45/75/90 deg trim envelope has real point evidence, but it is computational trim evidence only, not flight-test validation.
- Full-angle point rows may report out-of-range database clamping for local Re/Mach/flap dimensions. These are disclosed diagnostics and do not upgrade the underlying experimental evidence.
- Legacy remains the default model until explicit owner approval.
