# Pitch Control Authority and Source Audit

## 1. Executive Summary

This is an audit, not a solver fix. It does not change default model equations,
`params_nominal` defaults, `services/run_trim_case` default behavior, GUI
behavior, default control limits, trim convergence criteria, or default
`lateralCyclic` enablement.

The audit targets the PR #46 findings: `cyclicLong` authority sensitivity,
the airplane-like elevator candidate improvement, and current full6DOF
formulation limitations. It reads the committed PR #46 longitudinal robustness
evidence and computes local finite-difference control authority around the
baseline points.

The current evidence does not justify saying the `cyclicLong` sign is wrong.
The stronger finding is control authority and role allocation: `conversion_mid`
and `airplane_like` are sensitive to `cyclicLong` authority, `airplane_like`
also supports an elevator-aware diagnostic hypothesis, and `conversion_high`
remains scaling/formulation sensitive.

## 2. Control Chain Map

|control|meaning|code location|unit|default limit|source status|notes|
|-|-|-|-|-|-|-|
|`collective`|symmetric rotor collective pitch|`model/get_control_input_names.m`; `model/map_control_inputs.m`|rad internal, deg in reports|`P.control.collectiveLim`|CODE_CONFIRMED|Input 1 in both control architectures.|
|`cyclicLong`|symmetric longitudinal cyclic rotor command|`model/get_control_input_names.m`; `model/total_forces_moments.m`; `model/rotor_model_bemt.m`|rad internal, deg in reports|`P.control.cyclicLim = +/-35 deg`|DOC_CONFIRMED / SOURCE_REQUIRED for limit|Input 3. Right and left side-specific commands receive the common value before clamping.|
|`diffCyclic`|differential longitudinal cyclic rotor command|`model/get_control_input_names.m`; `model/total_forces_moments.m`|rad internal, deg in reports|side command constrained by `P.control.cyclicLim`|DOC_CONFIRMED|Historical code name; docs call it `differentialLongitudinalCyclic`.|
|`lateralCyclic`|opt-in symmetric lateral cyclic command|`model/get_control_input_names.m`; `model/map_control_inputs.m`|rad internal, deg in reports|`P.control.cyclicLim` when opt-in enabled|DOC_CONFIRMED|Only present when `P.control.enableLateralCyclic = true`.|
|`elevator`|horizontal-tail elevator command|`model/get_control_input_names.m`; `model/horizontal_tail_model.m`|rad internal, deg in reports|`P.control.elevatorLim`|SOURCE_REQUIRED|Limit exists in `params_nominal`, but no external source trace is completed here.|

## 3. Source Status Inventory

|item|current implementation|source_status|evidence|action needed|
|-|-|-|-|-|
|`cyclicLong` definition|symmetric longitudinal cyclic, input 3|DOC_CONFIRMED|`AGENTS.md` and `docs/CONTROL_CONVENTIONS.md` define the common longitudinal disk-tilt convention.|Keep definition unless a later sign/source audit shows stricter evidence.|
|`diffCyclic` definition|differential longitudinal cyclic, input 4|DOC_CONFIRMED|`docs/CONTROL_CONVENTIONS.md` documents the historical name and intended physical meaning.|Continue documenting as `differentialLongitudinalCyclic`.|
|`lateralCyclic` definition|opt-in symmetric lateral cyclic inserted as input 5|DOC_CONFIRMED|`get_control_input_names` inserts it only when enabled.|Keep opt-in behavior.|
|`cyclicLong +/-35 deg` limit|`P.control.cyclicLim = [-35, 35] deg`|SOURCE_REQUIRED|The value is defined in `params_nominal.m`; no literature source is traced by this audit.|Audit references before widening any default limit.|
|elevator limit|`P.control.elevatorLim = [-40, 40] deg`|SOURCE_REQUIRED|The value is defined in `params_nominal.m`; no literature source is traced by this audit.|Audit references before using it as validated surface authority.|
|rotor longitudinal cyclic mapping|`cyclicSide` maps to `theta1sSide = -rotDir*cyclicSide`|DOC_CONFIRMED|`AGENTS.md` and `docs/CONTROL_CONVENTIONS.md` record this mapping.|Do not claim the sign is wrong without strict multi-case evidence.|
|pitch attitude trim unknown|`theta` is solved in longitudinal and full6DOF trim modes|CODE_CONFIRMED|`trim_symmetric` and `trim_full_6dof_straight` include `theta`.|Keep as a state unknown.|
|baseline longitudinal elevator role|baseline symmetric trim fixes elevator at zero|CODE_CONFIRMED|`trim_symmetric` fixed controls include `elevator = 0`.|Only add elevator through a future opt-in mode.|
|current full6DOF elevator role|current full6DOF selected controls omit elevator|CODE_CONFIRMED|`trim_full_6dof_straight` unknown set omits elevator.|Future opt-in candidate can add elevator after source/sign audit.|
|fixed-wing pitch control role|not externally validated in this codebase|SOURCE_REQUIRED|No repository document validates fixed-wing allocation against flight data.|Treat elevator-vs-cyclic role as implementation hypothesis.|
|`betaM` convention|0 deg helicopter mode, 90 deg airplane mode|CODE_CONFIRMED|Representative cases and validation reports use `betaMDeg` in `[0, 90]`.|Preserve convention.|
|control units|internal controls are radians; GUI/reports may show degrees|CODE_CONFIRMED|`get_control_input_units` returns rad.|Preserve rad internal units.|

## 4. Local Control Effectiveness

`analysis/audit_pitch_control_authority_source.m` computes central
finite-difference derivatives around each PR #46 baseline point for
`collective`, `cyclicLong`, `elevator`, optional `lateralCyclic`, `aileron`,
and `rudder`. It reports:

|case|control|d_udot|d_wdot|d_qdot|normalized_authority|dominant_channel|sign|
|-|-|-:|-:|-:|-:|-|-|
|`conversion_mid`|`cyclicLong`|0.118|3.428|-0.374|2.094|`wdot`|positive|
|`conversion_mid`|`elevator`|0.075|-1.405|-1.460|1.019|`qdot`|negative|
|`airplane_like`|`cyclicLong`|10.756|-3.894|0.223|6.570|`udot`|positive|
|`airplane_like`|`elevator`|0.057|-7.341|-7.783|5.433|`qdot`|negative|
|`conversion_high`|`cyclicLong`|-11.121|4.740|-0.044|6.794|`udot`|negative|
|`conversion_high`|`elevator`|0.050|-3.587|-3.783|2.641|`qdot`|negative|

The complete numerical table is written under
`validation/pitch_control_authority_source/<timestamp>/`.

## 5. Authority Margin / Allocation Audit

The script performs a local least-squares allocation on `[udot, wdot, qdot]`
for these candidate control sets:

- `cyclicLong` only
- `elevator` only
- `cyclicLong + elevator`
- `collective + cyclicLong`
- `collective + elevator`
- `collective + cyclicLong + elevator`
- current full6DOF selected controls
- full6DOF selected controls with elevator

Diagnoses use only local linear evidence:

- `WITHIN_DEFAULT_AUTHORITY`
- `REQUIRES_CYCLICLONG_BEYOND_DEFAULT`
- `REQUIRES_ELEVATOR_IN_CONTROL_SET`
- `REQUIRES_BOTH_CYCLIC_AND_ELEVATOR`
- `NOT_SOLVABLE_BY_LOCAL_CONTROL_SET`
- `SCALING_WEIGHTING_DEPENDENT`
- `SIGN_CONVENTION_SUSPECT`
- `SOURCE_REQUIRED`

A local linear allocation that reduces residuals is not a nonlinear trim
success and is not a default solver change.

Condensed findings from the committed audit output:

|case|control set|within default limits|residual after local allocation|diagnosis|
|-|-|-:|-:|-|
|`helicopter_low_speed`|`collective+cyclicLong+elevator`|true|near zero|`WITHIN_DEFAULT_AUTHORITY`|
|`conversion_mid`|`cyclicLong`|false|1.638|`REQUIRES_CYCLICLONG_BEYOND_DEFAULT`|
|`conversion_mid`|`collective+cyclicLong+elevator`|false|near zero|`REQUIRES_BOTH_CYCLIC_AND_ELEVATOR`|
|`airplane_like`|`cyclicLong`|false|2.308|`REQUIRES_CYCLICLONG_BEYOND_DEFAULT`|
|`airplane_like`|`collective+cyclicLong+elevator`|false|near zero|`REQUIRES_BOTH_CYCLIC_AND_ELEVATOR`|
|`conversion_high`|`cyclicLong`|true|6.198|`NOT_SOLVABLE_BY_LOCAL_CONTROL_SET`|
|`conversion_high`|`collective+cyclicLong`|false|1.473|`SCALING_WEIGHTING_DEPENDENT`|
|`conversion_high`|`collective+cyclicLong+elevator`|false|near zero|`REQUIRES_BOTH_CYCLIC_AND_ELEVATOR`|

## 6. Sign and Mapping Sensitivity

The sign check is deliberately conservative. `SIGN_SUSPECT` is allowed only if
an audit-only sign flip materially improves multiple cases and does not damage
`helicopter_low_speed`. Otherwise the report must not claim that the
`cyclicLong` sign is wrong.

The current expected conclusion is `SIGN_OK_LIKELY` unless the generated
numeric evidence meets that strict criterion.

The committed audit does not meet the strict sign-suspect criterion:

|case|current cyclicLong residual|sign-flip residual|diagnosis|
|-|-:|-:|-|
|`helicopter_low_speed`|3.73e-10|3.73e-10|`SIGN_OK_LIKELY`|
|`conversion_mid`|1.638|1.638|`AUTHORITY_LIMIT_LIKELY`|
|`airplane_like`|2.308|2.308|`AUTHORITY_LIMIT_LIKELY`|
|`conversion_high`|6.198|6.198|`FORMULATION_LIMITATION_LIKELY`|

## 7. Elevator vs cyclicLong Physical Role

In helicopter-like conditions, rotor cyclic naturally participates in pitch
control and the current low-speed baseline already closes. In conversion
conditions, rotor cyclic and elevator can both influence pitch/force balance,
so a nacelle-angle-dependent allocation schedule is a plausible follow-up
hypothesis.

In airplane-like conditions, the elevator candidate is physically plausible as
a fixed-wing pitch-control participant, but this is not a proven fix. The
current evidence only says that an opt-in elevator-aware formulation deserves
a follow-up implementation and validation PR.

## 8. Recommended Implementation Path

1. Add an opt-in elevator-aware longitudinal trim mode while preserving the
   existing default longitudinal path.
2. Add a nacelle-angle-dependent pitch control allocation schedule that can
   blend `cyclicLong` and elevator in conversion and airplane-like modes.
3. Keep the default `cyclicLong +/-35 deg` limit unchanged until a source audit
   traces its authority basis.
4. Audit residual normalization or a force-priority objective separately,
   because PR #46 found `conversion_mid` and `conversion_high` sensitivity.
5. Deepen force/moment-chain checks if local control sets still cannot close
   dominant residuals.

## 9. What Not To Claim

- Do not claim external validation.
- Do not claim all-envelope trim reliability.
- Do not claim NUAA/Berger/XV-15 match.
- Do not claim trend pass/fail.
- Do not claim `cyclicLong` default limit should be widened.
- Do not claim elevator fix proven.
- Do not claim sign wrong unless strict evidence is met.
- Do not claim `lateralCyclic` ineffective.
- Do not claim model equations are wrong solely from non-convergence.
