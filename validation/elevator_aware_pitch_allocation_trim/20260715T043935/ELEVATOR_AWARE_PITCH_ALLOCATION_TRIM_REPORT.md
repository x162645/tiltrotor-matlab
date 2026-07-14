# Elevator-Aware Pitch Allocation Trim Candidate

## 1. Executive Summary

This report covers an opt-in implementation candidate. It does not replace the default longitudinal trim path, change model equations, alter params_nominal defaults, change default control limits, change GUI defaults, or enable lateralCyclic by default.

The goal is to test whether elevator-aware and scheduled pitch allocation candidates improve the PR #46/#47 non-helicopter longitudinal residuals. The evidence is internal numerical diagnostic evidence only.

## 2. Motivation from PR #46 / PR #47

PR #46 found conversion_mid cyclicLong authority sensitivity, airplane_like elevator qdot/wdot authority, conversion_high formulation/scaling sensitivity, no strict sign-error evidence, and SOURCE_REQUIRED status for cyclicLong and elevator limits. PR #47 recommended an opt-in elevator-aware follow-up without changing defaults.

## 3. Candidate Formulations

- baseline_existing_summary
- theta_collective_cyclicLong
- theta_collective_elevator
- theta_collective_cyclicLong_elevator_regularized
- theta_collective_scheduled_pitch
- scheduled_pitch_force_priority
- scheduled_pitch_moment_priority

The default report run keeps the full candidate matrix but uses single-start finite-budget solves for reproducibility. Solver multistart remains explicitly opt-in through solverRunHeavy.

## 4. Schedule Definition

The scheduled candidates use cyclicWeight = cos(betaM)^2 and elevatorWeight = sin(betaM)^2. This is a candidate schedule only, not an externally validated control law and not a default control allocation change.

## 5. Evidence Matrix

|case_name|candidate_name|success|residual_norm|active_limit_names|diagnosis_label|
|-|-|-|-|-|-|
|helicopter_low_speed|baseline_existing_summary|true|1.78316e-09||BASELINE_REPRODUCED|
|helicopter_low_speed|theta_collective_cyclicLong|false|0.205888||NONLINEAR_SOLVER_LIMITATION|
|helicopter_low_speed|theta_collective_elevator|false|0.125581||ELEVATOR_AWARE_NOT_ENOUGH|
|helicopter_low_speed|theta_collective_cyclicLong_elevator_regularized|false|0.173795||ELEVATOR_AWARE_NOT_ENOUGH|
|helicopter_low_speed|theta_collective_scheduled_pitch|false|0.13179||SCHEDULED_ALLOCATION_NOT_ENOUGH|
|helicopter_low_speed|scheduled_pitch_force_priority|false|0.0466884||SCHEDULED_ALLOCATION_NOT_ENOUGH|
|helicopter_low_speed|scheduled_pitch_moment_priority|false|0.00534357||SCHEDULED_ALLOCATION_NOT_ENOUGH|
|conversion_mid|baseline_existing_summary|false|2.12607|cyclicLong|BASELINE_REPRODUCED|
|conversion_mid|theta_collective_cyclicLong|false|5.36667||FORMULATION_LIMITATION_LIKELY|
|conversion_mid|theta_collective_elevator|false|5.95718||ELEVATOR_AWARE_NOT_ENOUGH|
|conversion_mid|theta_collective_cyclicLong_elevator_regularized|false|5.45117||ELEVATOR_AWARE_NOT_ENOUGH|
|conversion_mid|theta_collective_scheduled_pitch|false|5.5363||SCHEDULED_ALLOCATION_NOT_ENOUGH|
|conversion_mid|scheduled_pitch_force_priority|false|1.46613||FORCE_PRIORITY_SENSITIVE|
|conversion_mid|scheduled_pitch_moment_priority|false|5.63413||SCHEDULED_ALLOCATION_NOT_ENOUGH|
|airplane_like|baseline_existing_summary|false|3.14973|cyclicLong|BASELINE_REPRODUCED|
|airplane_like|theta_collective_cyclicLong|false|6.57269||FORMULATION_LIMITATION_LIKELY|
|airplane_like|theta_collective_elevator|false|0.895738||ELEVATOR_AWARE_IMPROVES|
|airplane_like|theta_collective_cyclicLong_elevator_regularized|false|6.89971||ELEVATOR_AWARE_NOT_ENOUGH|
|airplane_like|theta_collective_scheduled_pitch|false|1.59819||SCHEDULED_ALLOCATION_NOT_ENOUGH|
|airplane_like|scheduled_pitch_force_priority|false|2.82873||FORCE_PRIORITY_SENSITIVE|
|airplane_like|scheduled_pitch_moment_priority|false|6.08641||SCHEDULED_ALLOCATION_NOT_ENOUGH|
|conversion_high|baseline_existing_summary|false|6.19867||BASELINE_REPRODUCED|
|conversion_high|theta_collective_cyclicLong|false|6.88707||FORMULATION_LIMITATION_LIKELY|
|conversion_high|theta_collective_elevator|false|3.42662||ELEVATOR_AWARE_NOT_ENOUGH|
|conversion_high|theta_collective_cyclicLong_elevator_regularized|false|6.50808||ELEVATOR_AWARE_NOT_ENOUGH|
|conversion_high|theta_collective_scheduled_pitch|false|6.21723||SCHEDULED_ALLOCATION_NOT_ENOUGH|
|conversion_high|scheduled_pitch_force_priority|false|2.75704||SCHEDULED_ALLOCATION_IMPROVES|
|conversion_high|scheduled_pitch_moment_priority|false|7.39846||SCHEDULED_ALLOCATION_NOT_ENOUGH|

## 6. Interpretation

|case_name|baseline_residual_norm|best_candidate|best_residual_norm|best_improvement_fraction|best_diagnosis_label|
|-|-|-|-|-|-|
|helicopter_low_speed|1.78316e-09|baseline_existing_summary|1.78316e-09|0|BASELINE_REPRODUCED|
|conversion_mid|2.12607|scheduled_pitch_force_priority|1.46613|0.310402|FORCE_PRIORITY_SENSITIVE|
|airplane_like|3.14973|theta_collective_elevator|0.895738|0.715614|ELEVATOR_AWARE_IMPROVES|
|conversion_high|6.19867|scheduled_pitch_force_priority|2.75704|0.55522|SCHEDULED_ALLOCATION_IMPROVES|


Helicopter low-speed should remain non-degraded. conversion_mid and airplane_like indicate whether elevator-aware or scheduled candidates improve the residuals. conversion_high should be interpreted conservatively because PR #46/#47 already identified formulation/scaling sensitivity.

## 7. Recommended Next Step

Use these results to decide whether an opt-in GUI/service hook is worth reviewing. Continue residual-normalization, force/moment chain, and source-limit audits before any default-path change.

## 8. What Not To Claim

- Do not claim external validation.
- Do not claim all-envelope trim reliability.
- Do not claim NUAA/Berger/XV-15 match.
- Do not claim trend pass/fail.
- Do not claim elevator fix proven.
- Do not claim scheduled allocation is physically validated.
- Do not claim cyclicLong default limit should be widened.
- Do not claim sign wrong.
- Do not claim model equations are wrong solely from non-convergence.
