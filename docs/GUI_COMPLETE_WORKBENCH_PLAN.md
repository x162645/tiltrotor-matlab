# GUI Complete Parameter and Lateral Trim Workbench

This document records the GUI workbench scope implemented for the complete
parameter and lateral-control wiring task. It is an engineering interface
update only. It does not change model equations, default parameter values,
default control architecture, or validation status.

## Parameter Workbench

The parameter page is now driven by `services/build_parameter_catalog.m`
instead of a short hard-coded GUI list. Rows are grouped by physical
component or calculation module:

- environment
- mass/inertia
- rotor
- wing
- fuselage
- horizontal tail
- vertical tail
- controls
- nacelle dynamics
- trim
- linearization

Matrix and vector fields are exposed as scalar rows, including `mass.I0`,
`mass.KI`, control limits, `trim.variableScale`, `linear.dx`, and
`linear.du`. Derived rows such as `rotor.Ib` and `rotor.Sblade`, and
compatibility rows such as `mass.RH`, are read-only.

Source classifications are displayed with user-facing Chinese labels:

- reference constant
- concept assumption
- model assumption
- numerical setting
- derived calculation
- compatibility retention
- external source pending
- sign convention pending

The catalog is descriptive. It does not replace the parameter-source
inventory and does not claim any XV-15, NUAA, or Berger validation.

## Control Architecture

The GUI exposes a control architecture selector:

- default 7 inputs:
  `collective, diffCollective, cyclicLong, diffCyclic, aileron, elevator, rudder`
- opt-in 8 inputs:
  `collective, diffCollective, cyclicLong, diffCyclic, lateralCyclic, aileron, elevator, rudder`

Switching the selector only changes `P.control.enableLateralCyclic`. The
default remains the legacy 7-input architecture. Switching invalidates trim,
linearization, and response results because the control vector and B matrix
columns change.

`linear.du` rows follow the active control architecture. In 8-input mode,
`lateralCyclic` is exposed as the fifth control perturbation.

## Response Page

The response service already supports an active control count from
`get_control_input_names(P)`. The GUI now refreshes the response control
dropdown and B-matrix column names when the control architecture changes.
After an 8-input linearization, `lateralCyclic` can be selected as the
response input.

If the control architecture changes after linearization, old results are
invalidated and the response page requires a new linearization.

## Nacelle Dynamics UI

The nacelle page is named `短舱动态`. User-facing wording removes the
experimental tab label and moves the technical boundary into the help text:

- the module is for open-loop nacelle-angle dynamic response analysis;
- it can evaluate nacelle lag and rate limits;
- it remains disabled by default to preserve the legacy 9-state path;
- it is not a complete conversion-flight closed-loop controller.

No nacelle dynamic equation or default value is changed by this GUI update.

## Trim Modes

The trim page exposes three modes:

- `longitudinal_symmetric`: enabled production path, using the existing
  `trim_symmetric` service behavior.
- `lateral_directional_balance`: enabled solver path. It obtains a
  longitudinal symmetric base trim, then solves `vdot`, `pdot`, and `rdot`
  with lateral control candidates and an explicit small-control
  regularization term.
- `full_6dof_straight_trim`: enabled solver path. It solves straight steady
  six-degree-of-freedom rigid-body residuals `udot`, `vdot`, `wdot`,
  `pdot`, `qdot`, and `rdot`.

The non-default modes return real solver reports. If a representative point
does not converge, the GUI displays `success=false`, residuals, limit status,
and the solver message. The service does not return the longitudinal trim as
a fake lateral or full six-DOF success.

Detailed residuals, unknowns, control candidates, regularization, and
success criteria are recorded in `docs/TRIM_MODE_SOLVER_DEFINITIONS.md`.

## Non-Goals

- No model equation changes.
- No default parameter value changes.
- No default `lateralCyclic` enablement.
- No Berger13 GUI default integration.
- No NUAA, Berger, XV-15, or flight-test validation.
- No external trend pass/fail.
- No nonlinear doublet implementation.
- No source digitization.
