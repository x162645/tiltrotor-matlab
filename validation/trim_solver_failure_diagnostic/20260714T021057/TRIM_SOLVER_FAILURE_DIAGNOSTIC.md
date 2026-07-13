# Trim Solver Failure Diagnostic

This diagnostic classifies the committed PR #44 trim solver evidence. It does not rerun trim solvers, tune parameters, change equations, or relabel non-converged rows as success.

## 1. Executive Summary

- Records: 24
- Success: 6
- Failures/non-converged: 18
- Run errors: 0
- Low-speed helicopter case succeeds for all modes and both architectures.
- All non-helicopter representative cases fail in all three modes.


## 2. Failure Matrix

|case|architecture|longitudinal|lateral|full6dof|notes|
|-|-|-|-|-|-|
|helicopter_low_speed|7-input|PASS|PASS|PASS|all modes converge|
|helicopter_low_speed|8-input|PASS|PASS|PASS|all modes converge|
|conversion_mid|7-input|FAIL|FAIL|FAIL|longitudinal cyclicLong=-35 deg limit; lateral blocked by base failure; full6dof residual about 2.20|
|conversion_mid|8-input|FAIL|FAIL|FAIL|longitudinal cyclicLong=-35 deg limit; lateral blocked by base failure; full6dof residual about 2.20|
|airplane_like|7-input|FAIL|FAIL|FAIL|longitudinal cyclicLong=+35 deg limit; lateral blocked by base failure; full6dof residual about 3.16|
|airplane_like|8-input|FAIL|FAIL|FAIL|longitudinal cyclicLong=+35 deg limit; lateral blocked by base failure; full6dof residual about 3.16|
|conversion_high|7-input|FAIL|FAIL|FAIL|no active longitudinal limit, but residual remains about 6.20; lateral blocked by base failure|
|conversion_high|8-input|FAIL|FAIL|FAIL|no active longitudinal limit, but residual remains about 6.20; lateral blocked by base failure|


## 3. Failure Category Counts

|category|count|affected modes|interpretation|
|-|-|-|-|
|BASE_TRIM_DEPENDENCY_FAILURE|6|lateral_directional_balance|lateral mode did not run because base trim failed|
|FULL6DOF_FORMULATION_LIMITATION|6|full_6dof_straight_trim|full 6-DOF residual remains far above tolerance|
|CONTROL_OR_STATE_LIMIT_CONTACT|4|longitudinal_symmetric|active trim/control limit prevents success|
|PRIMARY_RESIDUAL_NOT_REDUCED|2|longitudinal_symmetric|residual remains high without active limit contact|
|NONFINITE_OR_INVALID_EVAL|0||nonfinite or invalid evaluation|
|STRICT_SUCCESS_CRITERION_FAILURE|0||near tolerance but strict success checks failed|
|UNKNOWN_FAILURE|0||unclassified failure|


## 4. Dominant Residual Analysis

|case|dominant residual|affected modes|interpretation|
|-|-|-|-|
|conversion_mid|udot|longitudinal_symmetric;full_6dof_straight_trim|body-x acceleration / longitudinal force balance dominates|
|airplane_like|wdot|longitudinal_symmetric;full_6dof_straight_trim|body-z acceleration / lift-thrust balance dominates|
|conversion_high|wdot|longitudinal_symmetric;full_6dof_straight_trim|body-z acceleration / lift-thrust balance dominates|


## 5. Limit and Control Analysis

|case|mode|arch|at limit|within limits|selected controls|suspected limitation|
|-|-|-|-|-|-|-|
|conversion_mid|longitudinal_symmetric|7-input|true|true|theta;collective;cyclicLong|A trim variable or control reached an active limit: cyclicLong atLimit=1 violated=0.|
|conversion_mid|lateral_directional_balance|7-input|false|false|diffCollective;diffCyclic;aileron;rudder|Longitudinal base trim did not converge, so the lateral objective was not evaluated.|
|conversion_mid|full_6dof_straight_trim|7-input|false|true|collective;cyclicLong;aileron;rudder|Full 6-DOF objective ran, but udot dominates and the residual remains far above tolerance.|
|conversion_mid|longitudinal_symmetric|8-input|true|true|theta;collective;cyclicLong|A trim variable or control reached an active limit: cyclicLong atLimit=1 violated=0.|
|conversion_mid|lateral_directional_balance|8-input|false|false|lateralCyclic;diffCollective;diffCyclic;aileron;rudder|Longitudinal base trim did not converge, so the lateral objective was not evaluated.|
|conversion_mid|full_6dof_straight_trim|8-input|false|true|collective;cyclicLong;lateralCyclic;rudder|Full 6-DOF objective ran, but udot dominates and the residual remains far above tolerance.|
|airplane_like|longitudinal_symmetric|7-input|true|true|theta;collective;cyclicLong|A trim variable or control reached an active limit: cyclicLong atLimit=1 violated=0.|
|airplane_like|lateral_directional_balance|7-input|false|false|diffCollective;diffCyclic;aileron;rudder|Longitudinal base trim did not converge, so the lateral objective was not evaluated.|
|airplane_like|full_6dof_straight_trim|7-input|false|true|collective;cyclicLong;aileron;rudder|Full 6-DOF objective ran, but wdot dominates and the residual remains far above tolerance.|
|airplane_like|longitudinal_symmetric|8-input|true|true|theta;collective;cyclicLong|A trim variable or control reached an active limit: cyclicLong atLimit=1 violated=0.|
|airplane_like|lateral_directional_balance|8-input|false|false|lateralCyclic;diffCollective;diffCyclic;aileron;rudder|Longitudinal base trim did not converge, so the lateral objective was not evaluated.|
|airplane_like|full_6dof_straight_trim|8-input|false|true|collective;cyclicLong;lateralCyclic;rudder|Full 6-DOF objective ran, but wdot dominates and the residual remains far above tolerance.|
|conversion_high|longitudinal_symmetric|7-input|false|true|theta;collective;cyclicLong|Residual remains high without active limits; wdot is the dominant residual.|
|conversion_high|lateral_directional_balance|7-input|false|false|diffCollective;diffCyclic;aileron;rudder|Longitudinal base trim did not converge, so the lateral objective was not evaluated.|
|conversion_high|full_6dof_straight_trim|7-input|false|true|collective;cyclicLong;aileron;rudder|Full 6-DOF objective ran, but wdot dominates and the residual remains far above tolerance.|
|conversion_high|longitudinal_symmetric|8-input|false|true|theta;collective;cyclicLong|Residual remains high without active limits; wdot is the dominant residual.|
|conversion_high|lateral_directional_balance|8-input|false|false|lateralCyclic;diffCollective;diffCyclic;aileron;rudder|Longitudinal base trim did not converge, so the lateral objective was not evaluated.|
|conversion_high|full_6dof_straight_trim|8-input|false|true|collective;cyclicLong;lateralCyclic;rudder|Full 6-DOF objective ran, but wdot dominates and the residual remains far above tolerance.|


## 6. 7-input vs 8-input Comparison

|case|mode|residual 7|residual 8|improvement|lateralCyclic selected|interpretation|
|-|-|-|-|-|-|-|
|helicopter_low_speed|longitudinal_symmetric|1.78316e-09|1.78316e-09|0|false|both architectures already converge|
|helicopter_low_speed|lateral_directional_balance|5.59019e-17|5.59019e-17|0|true|both architectures already converge|
|helicopter_low_speed|full_6dof_straight_trim|2.64616e-10|2.05445e-10|0.223613|true|both architectures already converge|
|conversion_mid|longitudinal_symmetric|2.12607|2.12607|0|false|lateralCyclic is not selected by this mode|
|conversion_mid|lateral_directional_balance|Inf|Inf|NaN|true|both architectures blocked by dependency failure|
|conversion_mid|full_6dof_straight_trim|2.19742|2.13104|0.0302105|true|8-input modestly improves residual, but the case still fails tolerance|
|airplane_like|longitudinal_symmetric|3.14973|3.14973|0|false|lateralCyclic is not selected by this mode|
|airplane_like|lateral_directional_balance|Inf|Inf|NaN|true|both architectures blocked by dependency failure|
|airplane_like|full_6dof_straight_trim|3.15728|3.13491|0.00708452|true|8-input has no meaningful total residual change; dominant residual remains longitudinal|
|conversion_high|longitudinal_symmetric|6.19867|6.19867|0|false|lateralCyclic is not selected by this mode|
|conversion_high|lateral_directional_balance|Inf|Inf|NaN|true|both architectures blocked by dependency failure|
|conversion_high|full_6dof_straight_trim|6.19505|6.19709|-0.000329883|true|8-input has no meaningful total residual change; dominant residual remains longitudinal|


## 7. Most Likely Root Causes

- Solver/formulation level: lateral failures mostly reflect base-trim dependency failures; full 6-DOF runs remain far above tolerance in conversion/high-speed cases.
- Control allocation level: conversion_mid and airplane_like reach cyclicLong limits; lateralCyclic participates in 8-input full6dof rows but does not remove longitudinal residuals.
- Model/physics level: representative conversion and airplane-like cases expose stronger thrust/lift/pitch coupling than the current trim variable set resolves.
- Numerical optimization level: conversion_high remains high without active limits, so scaling, multistart, or residual weighting sensitivity is a follow-up diagnostic.

## 8. Recommended Next Actions

- A. Run a longitudinal trim robustness audit first.
- B. Audit whether elevator should enter the full6dof unknown set in conversion/fixed-wing-like conditions.
- C. Audit lateral objectives only on cases with converged base trim.
- D. Run cyclicLong limit sensitivity.
- E. Run lateralCyclic allocation / regularization sensitivity.
- F. Run multistart / variable scaling / residual weighting sensitivity.

## 9. What Not To Claim

- No external validation passed.
- No all-envelope trim reliability is proven.
- No NUAA/Berger/XV-15 trend consistency is claimed.
- Solver failure does not prove model equations are wrong.
- Do not claim lateralCyclic is ineffective.
- Non-convergence is not a run error.
