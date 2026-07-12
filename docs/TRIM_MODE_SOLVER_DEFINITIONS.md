# Trim Mode Solver Definitions

This document defines the GUI trim modes implemented by the service layer.
The definitions are numerical model checks for the current concept model.
They are not NUAA, Berger, XV-15, flight-test, handling-quality, or trend
validation.

## longitudinal_symmetric

`longitudinal_symmetric` preserves the existing production path through
`trim_symmetric`.

- Fixed task: prescribed `V`, nacelle angle `betaM`, and flight-path angle
  `gamma`.
- Unknowns: `theta`, `collective`, `cyclicLong`.
- Residuals: `udot`, `wdot`, `qdot`.
- Fixed lateral states and controls: `v`, `p`, `q`, `r`, `phi`, `psi`,
  `diffCollective`, `diffCyclic`, `aileron`, `elevator`, and `rudder`.
- Success criteria: finite trim point, solver convergence, residual norm
  below `P.trim.residualTolerance`, no active-variable limit contact, and no
  limit violation.

This mode remains the default GUI behavior.

## lateral_directional_balance

`lateral_directional_balance` is implemented by
`analysis/trim_lateral_directional_balance.m` and dispatched by
`services/run_trim_case.m`.

The solver first obtains a longitudinal symmetric base trim for the same
`V`, `betaM`, and `gamma`. It then holds that longitudinal state and
longitudinal controls fixed while adjusting lateral control candidates.

- Residuals: `vdot`, `pdot`, `rdot`.
- Default 7-input candidates: `diffCollective`, `diffCyclic`, `aileron`,
  `rudder`.
- Opt-in 8-input candidates: `lateralCyclic`, `diffCollective`,
  `diffCyclic`, `aileron`, `rudder`.
- Objective: normalized residual cost plus a small L2 regularization on
  lateral control deviation from the base point.
- Reported diagnostics: selected controls, control norm, regularization
  weight, effective degrees of freedom, full state derivative, residual
  labels, limit report, finite flag, solver exit status, and message.
- Success criteria: finite evaluation, solver convergence, lateral residual
  norm below `P.trim.residualTolerance`, no active-control limit contact, and
  no limit violation.

Because the lateral problem can have more controls than residuals, the
regularization term is part of the solver definition. Failure is reported as
`success=false`; the service does not substitute the longitudinal trim as a
lateral trim result.

## full_6dof_straight_trim

`full_6dof_straight_trim` is implemented by
`analysis/trim_full_6dof_straight.m` and dispatched by
`services/run_trim_case.m`.

The task is straight steady rigid-body trim. It is not a coordinated turn
trim and not a dynamic conversion or nacelle actuator transient trim.

- Fixed task: prescribed `V`, `betaM`, and `gamma`.
- Fixed rates: `p = q = r = 0`.
- Fixed sideslip state: `v = 0`.
- Residuals: `udot`, `vdot`, `wdot`, `pdot`, `qdot`, `rdot`.
- Default 7-input unknowns: `theta`, `phi`, `collective`, `cyclicLong`,
  `aileron`, `rudder`.
- Opt-in 8-input unknowns: `theta`, `phi`, `collective`, `cyclicLong`,
  `lateralCyclic`, `rudder`.
- Bounds: `theta` and `phi` use explicit safe search limits; controls use
  the active control limit fields in `P.control`.
- Reported diagnostics: unknown list, selected controls, residual labels,
  variable scales, bounds, full state derivative, limit report, finite flag,
  solver exit status, and message.
- Success criteria: finite evaluation, solver convergence, six-residual norm
  below `P.trim.residualTolerance`, no active-variable limit contact, and no
  limit violation.

The solver may use the longitudinal symmetric result only as an initial
guess. It cannot return that result as a full six-DOF success unless the
six-residual evaluation also satisfies the success criteria.

## Limits

These solvers do not alter physical model equations, default parameter
values, default control architecture, or lateralCyclic default enablement.
Nonconvergence is a solver/physics diagnostic and must not be converted into
success. The current implementation does not provide external validation,
trend pass/fail, nonlinear doublet analysis, handling-quality validation, or
Berger13 GUI default integration.
