# Differential Aileron Aerodynamic Audit

Date: 2026-07-03

Decision: option C. Keep `CONTROL_SURFACE_GATE = PARTIAL` and retain `longitudinal_full_angle_baseline_no_lateral_aileron_aero`.

Evidence checked:

- NASA TM-88373 Figure 6a supplies symmetric plain-flap section CL/CD/Cm near -90 deg, not differential aileron roll/yaw increments.
- NASA CR-176970 text identifies XV-15 flap/flaperon scheduling and full-span flap hover test modification. It does not provide an independent, full-angle, differential aileron CL/Cl/Cm/Cn data set with signs, span range, and validity bounds.
- The legacy `P.wing.CLaileron` and `P.wing.Cmaileron` increments remain conceptual and are not hidden inside the full-angle database.

Required behavior remains: zero aileron derivative in the full-angle path until sourced data are added, explicit diagnostics for unsupported aileron aero, and no misuse of symmetric plain-flap data as differential aileron data.
