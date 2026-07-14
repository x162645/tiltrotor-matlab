# Pitch Control Authority and Source Audit

## 1. Executive Summary

This is an audit, not a solver fix. It does not change default model equations, params_nominal defaults, services/run_trim_case default behavior, GUI behavior, default control limits, trim convergence criteria, or default lateralCyclic enablement.

The audit targets the PR #46 cyclicLong authority sensitivity, elevator candidate improvement, and full6DOF formulation limitation. It uses the committed PR #46 matrix with 76 records, 4 cases, 19 candidates, and 0 run errors as input evidence.

Main conclusion: cyclicLong sign is not marked wrong by this strict audit. The stronger evidence is authority/control-role allocation: conversion_mid and airplane_like are cyclicLong-authority sensitive, airplane_like also supports an elevator-aware hypothesis, and conversion_high remains formulation/scaling sensitive.

## 2. Control Chain Map

|control|meaning|code_location|unit|default_limit|source_status|notes|
|-|-|-|-|-|-|-|
|collective|symmetric rotor collective pitch|model/get_control_input_names.m:6; model/map_control_inputs.m:17|rad internal; deg only for display/report output|[0, 70] deg|CODE_CONFIRMED|input 1 in both 7-input and 8-input architectures|
|cyclicLong|symmetric longitudinal cyclic rotor command|model/get_control_input_names.m:6; model/total_forces_moments.m:14; model/rotor_model_bemt.m theta1s mapping|rad internal; deg only for display/report output|[-35, 35] deg|DOC_CONFIRMED|input 3; right/left side commands receive common cyclicLong before clamping|
|diffCyclic|differential longitudinal cyclic rotor command|model/get_control_input_names.m:7; model/total_forces_moments.m:15|rad internal; deg only for display/report output|[-35, 35] deg side command after split|DOC_CONFIRMED|historical code name; docs call it differentialLongitudinalCyclic|
|lateralCyclic|opt-in symmetric lateral cyclic theta1c command|model/get_control_input_names.m:10; model/map_control_inputs.m:18|rad internal; deg only for display/report output|[-35, 35] deg|DOC_CONFIRMED|only present when P.control.enableLateralCyclic is true|
|elevator|horizontal-tail elevator command|model/get_control_input_names.m:7; model/horizontal_tail_model.m|rad internal; deg only for display/report output|[-40, 40] deg|ASSUMED_MODEL_PARAMETER|surface limit exists in params_nominal but literature trace is pending|

## 3. Source Status Inventory

|item|current_implementation|source_status|evidence|action_needed|
|-|-|-|-|-|
|cyclicLong definition|symmetric longitudinal cyclic; input 3 in active control vector|DOC_CONFIRMED|AGENTS.md and docs/CONTROL_CONVENTIONS.md define common longitudinal disk tilt|Keep current definition; audit source literature before changing limits|
|diffCyclic definition|differential longitudinal cyclic; input 4 in active control vector|DOC_CONFIRMED|docs/CONTROL_CONVENTIONS.md documents historical name and physical meaning|Keep documentation name differentialLongitudinalCyclic|
|lateralCyclic definition|opt-in symmetric lateral cyclic inserted as input 5 in 8-input mode|DOC_CONFIRMED|get_control_input_names inserts lateralCyclic only when enabled|Keep opt-in behavior|
|cyclicLong limit +/-35 deg|P.control.cyclicLim = [-35, 35] deg|SOURCE_REQUIRED|params_nominal.m defines the value; no literature source is traced here|Audit references before widening any default limit|
|elevator limit|P.control.elevatorLim = [-40, 40] deg|SOURCE_REQUIRED|params_nominal.m defines the value; no literature source is traced here|Audit references before using it as validated surface authority|
|rotor longitudinal cyclic mapping|cyclicSide maps to theta1sSide = -rotDir*cyclicSide|DOC_CONFIRMED|AGENTS.md and docs/CONTROL_CONVENTIONS.md record the mapping|Do not call sign wrong unless strict multi-case evidence is met|
|pitch attitude trim unknown|theta is solved in longitudinal and full6DOF trim modes|CODE_CONFIRMED|trim_symmetric and trim_full_6dof_straight include theta|Keep as state unknown|
|elevator excluded from baseline longitudinal trim|baseline symmetric trim fixes elevator at zero|CODE_CONFIRMED|trim_symmetric fixedControls sets elevator = 0|Consider only a future opt-in elevator-aware trim mode|
|elevator excluded from current full6DOF selected controls|current full6DOF unknown set uses aileron/rudder or lateralCyclic/rudder, not elevator|CODE_CONFIRMED|trim_full_6dof_straight full_unknown_set omits elevator|Future implementation can add opt-in candidate after source/sign audit|
|fixed-wing pitch control role|airplane-like pitch control role is not externally sourced in this codebase|SOURCE_REQUIRED|No repository document validates the fixed-wing allocation against flight data|Treat elevator-vs-cyclic role as implementation hypothesis|
|betaM convention|0 deg helicopter mode, 90 deg airplane mode|CODE_CONFIRMED|trim/evidence representative cases and validation docs use betaMDeg in [0,90]|Keep existing convention|
|control unit rad/deg|internal controls are radians; GUI/reports may show degrees|CODE_CONFIRMED|get_control_input_units returns rad; services accept config angles in deg|Preserve rad internal units|

## 4. Local Control Effectiveness

|case_name|control|d_udot|d_wdot|d_qdot|normalized_authority|dominant_channel|sign|
|-|-|-|-|-|-|-|-|
|helicopter_low_speed|collective|5.33272|-47.2553|0.0459056|57.7332|wdot|negative|
|helicopter_low_speed|cyclicLong|5.18769|0.281536|-0.780188|3.16898|udot|positive|
|helicopter_low_speed|elevator|0.00934259|-0.287689|-0.290349|0.202702|qdot|negative|
|helicopter_low_speed|lateralCyclic|3.78956e-13|1.21266e-11|-7.57912e-14|7.40772e-12|wdot|positive|
|helicopter_low_speed|aileron|0|0|0|0|udot|zero|
|helicopter_low_speed|rudder|0|0|0|0|udot|zero|
|conversion_mid|collective|33.8718|-40.5036|0.395412|49.4845|wdot|negative|
|conversion_mid|cyclicLong|0.118273|3.428|-0.373714|2.09405|wdot|positive|
|conversion_mid|elevator|0.0751596|-1.4051|-1.45969|1.01905|qdot|negative|
|conversion_mid|lateralCyclic|0|0|0|0|udot|zero|
|conversion_mid|aileron|0|0|0|0|udot|zero|
|conversion_mid|rudder|0|0|0|0|udot|zero|
|airplane_like|collective|71.5931|11.4422|-3.40822|87.4674|udot|positive|
|airplane_like|cyclicLong|10.7557|-3.89368|0.222618|6.57027|udot|positive|
|airplane_like|elevator|0.0569213|-7.34079|-7.78279|5.43341|qdot|negative|
|airplane_like|lateralCyclic|3.33067e-12|-6.66134e-12|-2.77556e-13|4.06918e-12|wdot|negative|
|airplane_like|aileron|0|-6.66134e-12|0|3.48787e-12|wdot|negative|
|airplane_like|rudder|0|0|0|0|udot|zero|
|conversion_high|collective|63.3362|-27.2152|0.211019|77.3798|udot|positive|
|conversion_high|cyclicLong|-11.1211|4.74019|-0.0435926|6.7935|udot|negative|
|conversion_high|elevator|0.049922|-3.58701|-3.78285|2.64093|qdot|negative|
|conversion_high|lateralCyclic|6.66134e-12|-8.88178e-12|5.55112e-13|5.42557e-12|wdot|negative|
|conversion_high|aileron|0|0|0|0|udot|zero|
|conversion_high|rudder|0|0|0|0|udot|zero|

## 5. Authority Margin / Allocation Audit

|case_name|control_set|within_default_limits|required_delta_control|residual_after_linear_allocation|diagnosis|
|-|-|-|-|-|-|
|helicopter_low_speed|cyclicLong|true|1.90174033e-08|3.72818e-10|WITHIN_DEFAULT_AUTHORITY|
|helicopter_low_speed|elevator|true|-2.50281021e-08|1.77419e-09|WITHIN_DEFAULT_AUTHORITY|
|helicopter_low_speed|cyclicLong+elevator|true|1.9351184e-08;-4.74869204e-08|1.58459e-10|WITHIN_DEFAULT_AUTHORITY|
|helicopter_low_speed|collective+cyclicLong|true|-1.48473475e-10;1.90944619e-08|3.51934e-10|WITHIN_DEFAULT_AUTHORITY|
|helicopter_low_speed|collective+elevator|true|2.42558456e-10;-4.48085532e-08|1.76837e-09|WITHIN_DEFAULT_AUTHORITY|
|helicopter_low_speed|collective+cyclicLong+elevator|true|2.67750038e-10;1.93658141e-08;-6.93387048e-08|1.06588e-24|WITHIN_DEFAULT_AUTHORITY|
|helicopter_low_speed|collective+cyclicLong+aileron+rudder|true|-1.48473475e-10;1.90944619e-08;0;0|3.51934e-10|WITHIN_DEFAULT_AUTHORITY|
|helicopter_low_speed|collective+cyclicLong+elevator+rudder|true|2.67750038e-10;1.93658141e-08;-6.93387048e-08;0|9.6106e-24|WITHIN_DEFAULT_AUTHORITY|
|conversion_mid|cyclicLong|false|-22.5151604|1.63763|REQUIRES_CYCLICLONG_BEYOND_DEFAULT|
|conversion_mid|elevator|true|21.0953334|1.99071|NOT_SOLVABLE_BY_LOCAL_CONTROL_SET|
|conversion_mid|cyclicLong+elevator|false|-23.7966206;-3.57920048|1.63454|NOT_SOLVABLE_BY_LOCAL_CONTROL_SET|
|conversion_mid|collective+cyclicLong|false|-2.62551609;-52.2856624|0.203814|NOT_SOLVABLE_BY_LOCAL_CONTROL_SET|
|conversion_mid|collective+elevator|true|-0.773466222;32.1743528|1.89962|NOT_SOLVABLE_BY_LOCAL_CONTROL_SET|
|conversion_mid|collective+cyclicLong+elevator|false|-2.68753615;-50.3425621;7.39139849|9.18139e-16|REQUIRES_BOTH_CYCLIC_AND_ELEVATOR|
|conversion_mid|collective+cyclicLong+aileron+rudder|false|-2.62551609;-52.2856624;0;0|0.203814|NOT_SOLVABLE_BY_LOCAL_CONTROL_SET|
|conversion_mid|collective+cyclicLong+elevator+rudder|false|-2.68753615;-50.3425621;7.39139849;0|1.57015e-15|REQUIRES_BOTH_CYCLIC_AND_ELEVATOR|
|airplane_like|cyclicLong|false|10.7333973|2.30808|REQUIRES_CYCLICLONG_BEYOND_DEFAULT|
|airplane_like|elevator|true|10.023829|2.53327|NOT_SOLVABLE_BY_LOCAL_CONTROL_SET|
|airplane_like|cyclicLong+elevator|false|9.08780953;7.84343655|1.81388|NOT_SOLVABLE_BY_LOCAL_CONTROL_SET|
|airplane_like|collective+cyclicLong|false|-3.72104165;31.3355424|0.177494|NOT_SOLVABLE_BY_LOCAL_CONTROL_SET|
|airplane_like|collective+elevator|true|0.69459689;10.3478417|2.37631|NOT_SOLVABLE_BY_LOCAL_CONTROL_SET|
|airplane_like|collective+cyclicLong+elevator|false|-3.52900558;30.0260713;1.17362852|2.48253e-15|REQUIRES_BOTH_CYCLIC_AND_ELEVATOR|
|airplane_like|collective+cyclicLong+aileron+rudder|false|-3.72104165;31.3355424;0;0|0.177494|NOT_SOLVABLE_BY_LOCAL_CONTROL_SET|
|airplane_like|collective+cyclicLong+elevator+rudder|false|-3.52900558;30.0260713;1.17362852;0|2.0479e-15|REQUIRES_BOTH_CYCLIC_AND_ELEVATOR|
|conversion_high|cyclicLong|true|0.56179035|6.19754|NOT_SOLVABLE_BY_LOCAL_CONTROL_SET|
|conversion_high|elevator|true|39.6674406|5.03945|NOT_SOLVABLE_BY_LOCAL_CONTROL_SET|
|conversion_high|cyclicLong+elevator|false|5.71812584;43.326786|4.90421|NOT_SOLVABLE_BY_LOCAL_CONTROL_SET|
|conversion_high|collective+cyclicLong|false|1681.82325;9590.70141|1.47315|SCALING_WEIGHTING_DEPENDENT|
|conversion_high|collective+elevator|false|-0.995262025;43.3287493|4.90644|NOT_SOLVABLE_BY_LOCAL_CONTROL_SET|
|conversion_high|collective+cyclicLong+elevator|false|2198.15949;12531.7523;-27.0242511|1.27519e-12|REQUIRES_BOTH_CYCLIC_AND_ELEVATOR|
|conversion_high|collective+cyclicLong+aileron+rudder|false|1681.82325;9590.70141;0;0|1.47315|SCALING_WEIGHTING_DEPENDENT|
|conversion_high|collective+cyclicLong+elevator+rudder|false|2198.15949;12531.7523;-27.0242511;0|3.72591e-13|REQUIRES_BOTH_CYCLIC_AND_ELEVATOR|


This is a local linear audit only. A successful linear allocation is not equivalent to nonlinear trim convergence.

## 6. Sign and Mapping Sensitivity

|case_name|candidate|baseline_residual_norm|residual_after_linear_allocation|improvement_fraction|diagnosis|
|-|-|-|-|-|-|
|helicopter_low_speed|current_cyclicLong|1.78316e-09|3.72818e-10|0.790922|SIGN_OK_LIKELY|
|helicopter_low_speed|inverted_cyclicLong_sign|1.78316e-09|3.72818e-10|0.790922|SIGN_OK_LIKELY|
|helicopter_low_speed|zero_cyclic_plus_elevator|1.78316e-09|1.77419e-09|0.0050282|SIGN_OK_LIKELY|
|conversion_mid|current_cyclicLong|2.12607|1.63763|0.22974|AUTHORITY_LIMIT_LIKELY|
|conversion_mid|inverted_cyclicLong_sign|2.12607|1.63763|0.22974|AUTHORITY_LIMIT_LIKELY|
|conversion_mid|zero_cyclic_plus_elevator|2.12607|1.99071|0.0636651|AUTHORITY_LIMIT_LIKELY|
|airplane_like|current_cyclicLong|3.14973|2.30808|0.267215|AUTHORITY_LIMIT_LIKELY|
|airplane_like|inverted_cyclicLong_sign|3.14973|2.30808|0.267215|AUTHORITY_LIMIT_LIKELY|
|airplane_like|zero_cyclic_plus_elevator|3.14973|2.53327|0.195719|AUTHORITY_LIMIT_LIKELY|
|conversion_high|current_cyclicLong|6.19867|6.19754|0.000182859|FORMULATION_LIMITATION_LIKELY|
|conversion_high|inverted_cyclicLong_sign|6.19867|6.19754|0.000182859|FORMULATION_LIMITATION_LIKELY|
|conversion_high|zero_cyclic_plus_elevator|6.19867|5.03945|0.187011|FORMULATION_LIMITATION_LIKELY|


SIGN_SUSPECT is assigned only if sign flip materially improves multiple cases without damaging helicopter_low_speed. That criterion is not met here, so the conservative sign conclusion is SIGN_OK_LIKELY.

## 7. Elevator vs cyclicLong Physical Role

- Helicopter low-speed trim already closes with the current symmetric longitudinal cyclic path.
- Conversion cases expose mixed thrust/lift/pitch coupling; cyclicLong and elevator should be studied together in an opt-in allocation schedule rather than by changing defaults.
- The airplane_like case suggests elevator is a more natural fixed-wing pitch-control candidate than forcing cyclicLong to carry the entire pitch role, but this remains a diagnostic hypothesis, not a proven fix.

## 8. Recommended Implementation Path

1. Add an opt-in elevator-aware longitudinal trim mode; keep the legacy longitudinal path unchanged.
2. Add a nacelle-angle-dependent pitch control allocation schedule that can blend cyclicLong and elevator as a candidate path.
3. Keep the default cyclicLong +/-35 deg limit unchanged until a source audit traces its authority basis.
4. Audit residual normalization / force-priority objective separately, because conversion_mid and conversion_high are weighting sensitive.
5. Deepen model force/moment-chain checks if the local control sets still cannot close the dominant residuals.

## 9. What Not To Claim

- Do not claim external validation.
- Do not claim all-envelope trim reliability.
- Do not claim NUAA/Berger/XV-15 match.
- Do not claim trend pass/fail.
- Do not claim cyclicLong default limit should be widened.
- Do not claim elevator fix proven.
- Do not claim sign wrong unless strict evidence is met.
- Do not claim lateralCyclic ineffective.
- Do not claim model equations are wrong solely from non-convergence.
