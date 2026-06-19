# CODEX_TASK.md

STATUS: COMPLETE / HOLD

Branch: `audit/aero-components`

Base branch: `main`

Current phase: wing, fuselage, horizontal-tail, vertical-tail, and aerodynamic force-transform audit.

## Completed scope

- aerodynamic component audit completed;
- `check_aerodynamic_components`: 10/10 PASS;
- `check_wing_normal_flow_blend`: PASS;
- `check_control_architecture`: PASS;
- `run_all_checks`: 13/13 PASS;
- focused top-level call count: 29;
- numeric parameters unchanged;
- aerodynamic derivatives unchanged;
- slipstream, downwash, transform, force, and moment equations unchanged;
- slipstream direction, downwash sign, control-effectiveness signs, and fuselage rate damping verified as internally consistent in covered canonical cases;
- no CRITICAL/HIGH/MEDIUM production-code bug found;
- LOW test-interpretation limitation recorded for finite-amplitude aileron/rudder mirror checks;
- Draft PR #4 awaits final review and user authorization;
- do not merge PR #4;
- do not begin trim-equation, continuation, or flight-envelope work.

## Goal

Verify that the non-rotor aerodynamic component chain is internally correct in coordinate transforms, force and moment signs, local-flow construction, control-effectiveness signs, damping behavior, slipstream coupling, branch continuity, symmetry, units, and diagnostics.

This is an internal-consistency and broad-physics audit for the current conceptual model. Exact XV-15 identification remains outside this phase. Preserve all production parameter values during the first pass and do not tune coefficients to make tests pass.
