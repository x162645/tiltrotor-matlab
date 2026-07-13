# Longitudinal Trim Robustness Audit

## 1. Executive Summary

This is an audit, not a solver fix. It does not change default model equations, params_nominal defaults, GUI behavior, control limits, trim convergence criteria, or default lateralCyclic enablement.

The audit investigates PR #44/#45 conversion and high-speed longitudinal/full6DOF failures using opt-in candidate formulations. The committed evidence input has 24 total rows, 6 successes, 18 failure/non-converged rows, and 0 run errors.

Improvement thresholds: meaningful >= 50% residual reduction, strong >= 80% residual reduction, near miss when residual/tolerance < 10, far from tolerance when ratio >= 100.

## Audit Matrix

|case|baseline|cyclic limit|elevator unknown|multistart|scaling/weighting|full6DOF|
|-|-|-|-|-|-|-|
|helicopter_low_speed|BASELINE_REPRODUCED|NOT_CYCLIC_LIMIT_ONLY|ELEVATOR_CANDIDATE_NOT_ENOUGH|MULTISTART_NOT_ENOUGH|FORMULATION_LIMITATION_LIKELY|FORMULATION_LIMITATION_LIKELY|
|conversion_mid|BASELINE_REPRODUCED|CYCLIC_LIMIT_SENSITIVE|ELEVATOR_CANDIDATE_NOT_ENOUGH|MULTISTART_NOT_ENOUGH|SCALING_WEIGHTING_SENSITIVE|FORMULATION_LIMITATION_LIKELY|
|airplane_like|BASELINE_REPRODUCED|CYCLIC_LIMIT_SENSITIVE|ELEVATOR_CANDIDATE_IMPROVES|MULTISTART_NOT_ENOUGH|FORMULATION_LIMITATION_LIKELY|FORMULATION_LIMITATION_LIKELY|
|conversion_high|BASELINE_REPRODUCED|NOT_CYCLIC_LIMIT_ONLY|ELEVATOR_CANDIDATE_NOT_ENOUGH|MULTISTART_NOT_ENOUGH|SCALING_WEIGHTING_SENSITIVE|FORMULATION_LIMITATION_LIKELY|

## 2. Baseline Reproduction

|case_name|residual_norm|dominant_residual_label|active_limit_names|diagnosis_label|
|-|-|-|-|-|
|helicopter_low_speed|1.78316e-09|udot||BASELINE_REPRODUCED|
|conversion_mid|2.12607|udot|cyclicLong|BASELINE_REPRODUCED|
|airplane_like|3.14973|wdot|cyclicLong|BASELINE_REPRODUCED|
|conversion_high|6.19867|wdot||BASELINE_REPRODUCED|

## 3. CyclicLong Limit Sensitivity

|case_name|candidate_name|residual_norm|improvement_fraction|active_limit_names|diagnosis_label|
|-|-|-|-|-|-|
|helicopter_low_speed|cyclicLong_limit_35deg|1.78316e-09|0||NOT_CYCLIC_LIMIT_ONLY|
|helicopter_low_speed|cyclicLong_limit_25deg|1.78316e-09|0||NOT_CYCLIC_LIMIT_ONLY|
|helicopter_low_speed|cyclicLong_limit_45deg|1.78316e-09|0||NOT_CYCLIC_LIMIT_ONLY|
|helicopter_low_speed|cyclicLong_limit_60deg|1.78316e-09|0||NOT_CYCLIC_LIMIT_ONLY|
|conversion_mid|cyclicLong_limit_35deg|2.12607|0|cyclicLong|NOT_CYCLIC_LIMIT_ONLY|
|conversion_mid|cyclicLong_limit_25deg|3.35771|-0.579303|cyclicLong|NOT_CYCLIC_LIMIT_ONLY|
|conversion_mid|cyclicLong_limit_45deg|1.10774|0.478975|cyclicLong|NOT_CYCLIC_LIMIT_ONLY|
|conversion_mid|cyclicLong_limit_60deg|0.758341|0.643313||CYCLIC_LIMIT_SENSITIVE|
|airplane_like|cyclicLong_limit_35deg|3.14973|0|cyclicLong|NOT_CYCLIC_LIMIT_ONLY|
|airplane_like|cyclicLong_limit_25deg|5.082|-0.61347|cyclicLong|NOT_CYCLIC_LIMIT_ONLY|
|airplane_like|cyclicLong_limit_45deg|6.55605e-09|1||CYCLIC_LIMIT_SENSITIVE|
|airplane_like|cyclicLong_limit_60deg|3.84038e-09|1||CYCLIC_LIMIT_SENSITIVE|
|conversion_high|cyclicLong_limit_35deg|6.19867|0||NOT_CYCLIC_LIMIT_ONLY|
|conversion_high|cyclicLong_limit_25deg|6.2336|-0.00563452|cyclicLong|NOT_CYCLIC_LIMIT_ONLY|
|conversion_high|cyclicLong_limit_45deg|6.19867|0||NOT_CYCLIC_LIMIT_ONLY|
|conversion_high|cyclicLong_limit_60deg|6.19867|0||NOT_CYCLIC_LIMIT_ONLY|

## 4. Elevator Unknown-Set Hypothesis

|case_name|candidate_name|residual_norm|improvement_fraction|dominant_residual_label|diagnosis_label|
|-|-|-|-|-|-|
|helicopter_low_speed|longitudinal_theta_collective_cyclicLong_elevator|0.150002|-8.41214e+07|udot|ELEVATOR_CANDIDATE_NOT_ENOUGH|
|helicopter_low_speed|longitudinal_theta_collective_elevator|0.125581|-7.04265e+07|udot|ELEVATOR_CANDIDATE_NOT_ENOUGH|
|helicopter_low_speed|longitudinal_theta_collective_cyclicLong_with_elevator_regularized|0.0951893|-5.33824e+07|udot|ELEVATOR_CANDIDATE_NOT_ENOUGH|
|conversion_mid|longitudinal_theta_collective_cyclicLong_elevator|5.45573|-1.56611|wdot|ELEVATOR_CANDIDATE_NOT_ENOUGH|
|conversion_mid|longitudinal_theta_collective_elevator|5.95718|-1.80197|wdot|ELEVATOR_CANDIDATE_NOT_ENOUGH|
|conversion_mid|longitudinal_theta_collective_cyclicLong_with_elevator_regularized|4.88789|-1.29903|wdot|ELEVATOR_CANDIDATE_NOT_ENOUGH|
|airplane_like|longitudinal_theta_collective_cyclicLong_elevator|6.9599|-1.20968|wdot|ELEVATOR_CANDIDATE_NOT_ENOUGH|
|airplane_like|longitudinal_theta_collective_elevator|0.895738|0.715614|wdot|ELEVATOR_CANDIDATE_IMPROVES|
|airplane_like|longitudinal_theta_collective_cyclicLong_with_elevator_regularized|6.90228|-1.19139|wdot|ELEVATOR_CANDIDATE_NOT_ENOUGH|
|conversion_high|longitudinal_theta_collective_cyclicLong_elevator|6.5604|-0.0583561|wdot|ELEVATOR_CANDIDATE_NOT_ENOUGH|
|conversion_high|longitudinal_theta_collective_elevator|3.42662|0.447201|wdot|ELEVATOR_CANDIDATE_NOT_ENOUGH|
|conversion_high|longitudinal_theta_collective_cyclicLong_with_elevator_regularized|6.453|-0.04103|wdot|ELEVATOR_CANDIDATE_NOT_ENOUGH|


Elevator entry is a diagnostic hypothesis only, not a proven fix, and not implemented as default.

## 5. Multi-start Sensitivity

|case_name|candidate_name|residual_norm|improvement_fraction|diagnosis_label|
|-|-|-|-|-|
|helicopter_low_speed|baseline_multistart_small|0.018991|-1.06502e+07|MULTISTART_NOT_ENOUGH|
|helicopter_low_speed|baseline_multistart_medium|0.0210891|-1.18268e+07|MULTISTART_NOT_ENOUGH|
|helicopter_low_speed|elevator_candidate_multistart|0.0266479|-1.49442e+07|MULTISTART_NOT_ENOUGH|
|conversion_mid|baseline_multistart_small|5.38882|-1.53464|MULTISTART_NOT_ENOUGH|
|conversion_mid|baseline_multistart_medium|4.09721|-0.927127|MULTISTART_NOT_ENOUGH|
|conversion_mid|elevator_candidate_multistart|3.89416|-0.831623|MULTISTART_NOT_ENOUGH|
|airplane_like|baseline_multistart_small|6.56778|-1.08519|MULTISTART_NOT_ENOUGH|
|airplane_like|baseline_multistart_medium|6.53247|-1.07398|MULTISTART_NOT_ENOUGH|
|airplane_like|elevator_candidate_multistart|3.82407|-0.214093|MULTISTART_NOT_ENOUGH|
|conversion_high|baseline_multistart_small|5.85873|0.0548401|MULTISTART_NOT_ENOUGH|
|conversion_high|baseline_multistart_medium|5.85873|0.0548401|MULTISTART_NOT_ENOUGH|
|conversion_high|elevator_candidate_multistart|5.60957|0.095037|MULTISTART_NOT_ENOUGH|

## 6. Scaling / Weighting Sensitivity

|case_name|candidate_name|residual_norm|improvement_fraction|diagnosis_label|
|-|-|-|-|-|
|helicopter_low_speed|baseline_force_priority|0.0503429|-2.82325e+07|FORMULATION_LIMITATION_LIKELY|
|helicopter_low_speed|baseline_scaled_udot_wdot_qdot|0.207256|-1.1623e+08|FORMULATION_LIMITATION_LIKELY|
|helicopter_low_speed|baseline_moment_priority|0.697082|-3.90926e+08|FORMULATION_LIMITATION_LIKELY|
|helicopter_low_speed|elevator_candidate_scaled|0.150002|-8.41214e+07|FORMULATION_LIMITATION_LIKELY|
|conversion_mid|baseline_force_priority|0.979112|0.539473|SCALING_WEIGHTING_SENSITIVE|
|conversion_mid|baseline_scaled_udot_wdot_qdot|5.35982|-1.521|FORMULATION_LIMITATION_LIKELY|
|conversion_mid|baseline_moment_priority|7.15736|-2.36647|FORMULATION_LIMITATION_LIKELY|
|conversion_mid|elevator_candidate_scaled|5.45573|-1.56611|FORMULATION_LIMITATION_LIKELY|
|airplane_like|baseline_force_priority|2.09895|0.333609|FORMULATION_LIMITATION_LIKELY|
|airplane_like|baseline_scaled_udot_wdot_qdot|6.57362|-1.08704|FORMULATION_LIMITATION_LIKELY|
|airplane_like|baseline_moment_priority|7.99841|-1.53939|FORMULATION_LIMITATION_LIKELY|
|airplane_like|elevator_candidate_scaled|6.9599|-1.20968|FORMULATION_LIMITATION_LIKELY|
|conversion_high|baseline_force_priority|2.25699|0.635891|SCALING_WEIGHTING_SENSITIVE|
|conversion_high|baseline_scaled_udot_wdot_qdot|6.95561|-0.122113|FORMULATION_LIMITATION_LIKELY|
|conversion_high|baseline_moment_priority|8.48989|-0.369631|FORMULATION_LIMITATION_LIKELY|
|conversion_high|elevator_candidate_scaled|6.5604|-0.0583561|FORMULATION_LIMITATION_LIKELY|

## 7. Full 6-DOF Formulation Comparison

|case_name|candidate_name|architecture|residual_norm|improvement_fraction|dominant_residual_label|diagnosis_label|
|-|-|-|-|-|-|-|
|helicopter_low_speed|current_full6dof|7-input|2.64616e-10|0|udot|FORMULATION_LIMITATION_LIKELY|
|helicopter_low_speed|full6dof_with_elevator|7-input|0.131845|-4.98249e+08|udot|FORMULATION_LIMITATION_LIKELY|
|helicopter_low_speed|full6dof_with_theta_phi_collective_cyclicLong_elevator_rudder|7-input|0.253273|-9.57132e+08|vdot|FORMULATION_LIMITATION_LIKELY|
|helicopter_low_speed|full6dof_8input_with_lateralCyclic_and_elevator|8-input|0.128772|-4.86637e+08|vdot|FORMULATION_LIMITATION_LIKELY|
|conversion_mid|current_full6dof|7-input|2.19742|0|udot|FORMULATION_LIMITATION_LIKELY|
|conversion_mid|full6dof_with_elevator|7-input|4.91263|-1.23563|wdot|FORMULATION_LIMITATION_LIKELY|
|conversion_mid|full6dof_with_theta_phi_collective_cyclicLong_elevator_rudder|7-input|4.92398|-1.24079|wdot|FORMULATION_LIMITATION_LIKELY|
|conversion_mid|full6dof_8input_with_lateralCyclic_and_elevator|8-input|4.91245|-1.23555|wdot|FORMULATION_LIMITATION_LIKELY|
|airplane_like|current_full6dof|7-input|3.15728|0|wdot|FORMULATION_LIMITATION_LIKELY|
|airplane_like|full6dof_with_elevator|7-input|8.54766|-1.70729|wdot|FORMULATION_LIMITATION_LIKELY|
|airplane_like|full6dof_with_theta_phi_collective_cyclicLong_elevator_rudder|7-input|6.36217|-1.01508|wdot|FORMULATION_LIMITATION_LIKELY|
|airplane_like|full6dof_8input_with_lateralCyclic_and_elevator|8-input|8.54748|-1.70723|wdot|FORMULATION_LIMITATION_LIKELY|
|conversion_high|current_full6dof|7-input|6.19505|0|wdot|FORMULATION_LIMITATION_LIKELY|
|conversion_high|full6dof_with_elevator|7-input|6.4791|-0.0458514|wdot|FORMULATION_LIMITATION_LIKELY|
|conversion_high|full6dof_with_theta_phi_collective_cyclicLong_elevator_rudder|7-input|6.4791|-0.0458514|wdot|FORMULATION_LIMITATION_LIKELY|
|conversion_high|full6dof_8input_with_lateralCyclic_and_elevator|8-input|6.47954|-0.045922|wdot|FORMULATION_LIMITATION_LIKELY|

## 8. Root Cause Ranking

|case|family|best candidate|best residual|improvement|diagnosis|
|-|-|-|-:|-:|-|
|helicopter_low_speed|baseline|baseline_longitudinal|1.78316e-09|0|BASELINE_REPRODUCED|
|helicopter_low_speed|cyclic_limit|cyclicLong_limit_35deg|1.78316e-09|0|NOT_CYCLIC_LIMIT_ONLY|
|helicopter_low_speed|elevator_unknown|longitudinal_theta_collective_cyclicLong_with_elevator_regularized|0.0951893|-5.33824e+07|ELEVATOR_CANDIDATE_NOT_ENOUGH|
|helicopter_low_speed|multistart|baseline_multistart_small|0.018991|-1.06502e+07|MULTISTART_NOT_ENOUGH|
|helicopter_low_speed|scaling_weighting|baseline_force_priority|0.0503429|-2.82325e+07|FORMULATION_LIMITATION_LIKELY|
|helicopter_low_speed|full6dof_comparison|current_full6dof|2.64616e-10|0|FORMULATION_LIMITATION_LIKELY|
|conversion_mid|baseline|baseline_longitudinal|2.12607|0|BASELINE_REPRODUCED|
|conversion_mid|cyclic_limit|cyclicLong_limit_60deg|0.758341|0.643313|CYCLIC_LIMIT_SENSITIVE|
|conversion_mid|elevator_unknown|longitudinal_theta_collective_cyclicLong_with_elevator_regularized|4.88789|-1.29903|ELEVATOR_CANDIDATE_NOT_ENOUGH|
|conversion_mid|multistart|elevator_candidate_multistart|3.89416|-0.831623|MULTISTART_NOT_ENOUGH|
|conversion_mid|scaling_weighting|baseline_force_priority|0.979112|0.539473|SCALING_WEIGHTING_SENSITIVE|
|conversion_mid|full6dof_comparison|current_full6dof|2.19742|0|FORMULATION_LIMITATION_LIKELY|
|airplane_like|baseline|baseline_longitudinal|3.14973|0|BASELINE_REPRODUCED|
|airplane_like|cyclic_limit|cyclicLong_limit_60deg|3.84038e-09|1|CYCLIC_LIMIT_SENSITIVE|
|airplane_like|elevator_unknown|longitudinal_theta_collective_elevator|0.895738|0.715614|ELEVATOR_CANDIDATE_IMPROVES|
|airplane_like|multistart|elevator_candidate_multistart|3.82407|-0.214093|MULTISTART_NOT_ENOUGH|
|airplane_like|scaling_weighting|baseline_force_priority|2.09895|0.333609|FORMULATION_LIMITATION_LIKELY|
|airplane_like|full6dof_comparison|current_full6dof|3.15728|0|FORMULATION_LIMITATION_LIKELY|
|conversion_high|baseline|baseline_longitudinal|6.19867|0|BASELINE_REPRODUCED|
|conversion_high|cyclic_limit|cyclicLong_limit_35deg|6.19867|0|NOT_CYCLIC_LIMIT_ONLY|
|conversion_high|elevator_unknown|longitudinal_theta_collective_elevator|3.42662|0.447201|ELEVATOR_CANDIDATE_NOT_ENOUGH|
|conversion_high|multistart|elevator_candidate_multistart|5.60957|0.095037|MULTISTART_NOT_ENOUGH|
|conversion_high|scaling_weighting|baseline_force_priority|2.25699|0.635891|SCALING_WEIGHTING_SENSITIVE|
|conversion_high|full6dof_comparison|current_full6dof|6.19505|0|FORMULATION_LIMITATION_LIKELY|

## 9. Recommended Next Implementation PR

- If elevator candidates materially improve a case, add a future opt-in elevator-aware longitudinal/full6DOF trim mode and test it before changing defaults.
- If cyclicLong limit sensitivity appears, audit physical control authority, sign, units, and limit sources rather than directly widening default limits.
- If multistart sensitivity appears, improve solver robustness in a separate PR without relabeling failures as success.
- If scaling sensitivity appears, audit residual normalization separately.
- If none of these candidates is enough, audit the force/moment chain, wing/tail/rotor coupling, and representative condition definition.

## 10. What Not To Claim

- No external validation passed.
- No all-envelope trim reliability is proven.
- No NUAA/Berger/XV-15 match is claimed.
- Do not claim the elevator fix is proven without a later implementation and validation PR.
- Do not claim default cyclicLong limits should be widened.
- Do not claim model equations are wrong solely from non-convergence.
- Do not claim lateralCyclic is ineffective.
