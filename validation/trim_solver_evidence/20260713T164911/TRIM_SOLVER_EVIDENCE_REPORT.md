# Trim Solver Evidence Report

This is internal numerical evidence for the current trim solver interfaces. It is not external validation, not an NUAA/Berger/XV-15 trend comparison, and not a handling qualities assessment.

Default 7-input architecture keeps `P.control.enableLateralCyclic = false`. The 8-input architecture explicitly enables `lateralCyclic`.

## Case Status

|case|mode|architecture|success|residual norm|within limits|message|
|-|-|-|-:|-:|-:|-|
|helicopter_low_speed|longitudinal_symmetric|7-input|1|1.783157e-09|1|success|
|helicopter_low_speed|lateral_directional_balance|7-input|1|5.590190e-17|1|Lateral-directional balance converged: lateral residual norm 5.590e-17.|
|helicopter_low_speed|full_6dof_straight_trim|7-input|1|2.646164e-10|1|Full 6-DOF straight trim converged: residual norm 2.646e-10.|
|helicopter_low_speed|longitudinal_symmetric|8-input|1|1.783157e-09|1|success|
|helicopter_low_speed|lateral_directional_balance|8-input|1|5.590190e-17|1|Lateral-directional balance converged: lateral residual norm 5.590e-17.|
|helicopter_low_speed|full_6dof_straight_trim|8-input|1|2.054448e-10|1|Full 6-DOF straight trim converged: residual norm 2.054e-10.|
|conversion_mid|longitudinal_symmetric|7-input|0|2.126070e+00|1|Trim did not meet convergence criteria; an active limit was reached.|
|conversion_mid|lateral_directional_balance|7-input|0|Inf|0|Longitudinal base trim did not converge; lateral balance was not run.|
|conversion_mid|full_6dof_straight_trim|7-input|0|2.197425e+00|1|Full 6-DOF straight trim did not meet tolerance: residual norm 2.197e+00.|
|conversion_mid|longitudinal_symmetric|8-input|0|2.126070e+00|1|Trim did not meet convergence criteria; an active limit was reached.|
|conversion_mid|lateral_directional_balance|8-input|0|Inf|0|Longitudinal base trim did not converge; lateral balance was not run.|
|conversion_mid|full_6dof_straight_trim|8-input|0|2.131039e+00|1|Full 6-DOF straight trim did not meet tolerance: residual norm 2.131e+00.|
|airplane_like|longitudinal_symmetric|7-input|0|3.149732e+00|1|Trim did not meet convergence criteria; an active limit was reached.|
|airplane_like|lateral_directional_balance|7-input|0|Inf|0|Longitudinal base trim did not converge; lateral balance was not run.|
|airplane_like|full_6dof_straight_trim|7-input|0|3.157278e+00|1|Full 6-DOF straight trim did not meet tolerance: residual norm 3.157e+00.|
|airplane_like|longitudinal_symmetric|8-input|0|3.149732e+00|1|Trim did not meet convergence criteria; an active limit was reached.|
|airplane_like|lateral_directional_balance|8-input|0|Inf|0|Longitudinal base trim did not converge; lateral balance was not run.|
|airplane_like|full_6dof_straight_trim|8-input|0|3.134911e+00|1|Full 6-DOF straight trim did not meet tolerance: residual norm 3.135e+00.|
|conversion_high|longitudinal_symmetric|7-input|0|6.198669e+00|1|Trim did not meet convergence criteria; residual norm 6.199e+00.|
|conversion_high|lateral_directional_balance|7-input|0|Inf|0|Longitudinal base trim did not converge; lateral balance was not run.|
|conversion_high|full_6dof_straight_trim|7-input|0|6.195048e+00|1|Full 6-DOF straight trim did not meet tolerance: residual norm 6.195e+00.|
|conversion_high|longitudinal_symmetric|8-input|0|6.198669e+00|1|Trim did not meet convergence criteria; residual norm 6.199e+00.|
|conversion_high|lateral_directional_balance|8-input|0|Inf|0|Longitudinal base trim did not converge; lateral balance was not run.|
|conversion_high|full_6dof_straight_trim|8-input|0|6.197091e+00|1|Full 6-DOF straight trim did not meet tolerance: residual norm 6.197e+00.|

## Controls Summary

|case|mode|architecture|collective deg|cyclicLong deg|lateralCyclic deg|aileron deg|elevator deg|rudder deg|selected controls|
|-|-|-|-:|-:|-:|-:|-:|-:|-|
|helicopter_low_speed|longitudinal_symmetric|7-input|15.1684|-1.39181|NaN|0|0|0|theta;collective;cyclicLong|
|helicopter_low_speed|lateral_directional_balance|7-input|15.1684|-1.39181|NaN|0|0|0|diffCollective;diffCyclic;aileron;rudder|
|helicopter_low_speed|full_6dof_straight_trim|7-input|15.1684|-1.39181|NaN|-9.99425e-09|0|-6.48106e-09|collective;cyclicLong;aileron;rudder|
|helicopter_low_speed|longitudinal_symmetric|8-input|15.1684|-1.39181|0|0|0|0|theta;collective;cyclicLong|
|helicopter_low_speed|lateral_directional_balance|8-input|15.1684|-1.39181|0|0|0|0|lateralCyclic;diffCollective;diffCyclic;aileron;rudder|
|helicopter_low_speed|full_6dof_straight_trim|8-input|15.1684|-1.39181|8.24155e-12|0|0|1.68621e-08|collective;cyclicLong;lateralCyclic;rudder|
|conversion_mid|longitudinal_symmetric|7-input|18.4619|-35|NaN|0|0|0|theta;collective;cyclicLong|
|conversion_mid|lateral_directional_balance|7-input|NaN|NaN|NaN|NaN|NaN|NaN|diffCollective;diffCyclic;aileron;rudder|
|conversion_mid|full_6dof_straight_trim|7-input|18.5122|-34.9986|NaN|-0.792783|0|0.637231|collective;cyclicLong;aileron;rudder|
|conversion_mid|longitudinal_symmetric|8-input|18.4619|-35|0|0|0|0|theta;collective;cyclicLong|
|conversion_mid|lateral_directional_balance|8-input|NaN|NaN|NaN|NaN|NaN|NaN|lateralCyclic;diffCollective;diffCyclic;aileron;rudder|
|conversion_mid|full_6dof_straight_trim|8-input|18.4549|-34.9978|-1.91131|0|0|1.21339|collective;cyclicLong;lateralCyclic;rudder|
|airplane_like|longitudinal_symmetric|7-input|29.5839|35|NaN|0|0|0|theta;collective;cyclicLong|
|airplane_like|lateral_directional_balance|7-input|NaN|NaN|NaN|NaN|NaN|NaN|diffCollective;diffCyclic;aileron;rudder|
|airplane_like|full_6dof_straight_trim|7-input|29.5813|35|NaN|-0.0388913|0|0.22096|collective;cyclicLong;aileron;rudder|
|airplane_like|longitudinal_symmetric|8-input|29.5839|35|0|0|0|0|theta;collective;cyclicLong|
|airplane_like|lateral_directional_balance|8-input|NaN|NaN|NaN|NaN|NaN|NaN|lateralCyclic;diffCollective;diffCyclic;aileron;rudder|
|airplane_like|full_6dof_straight_trim|8-input|29.5988|34.9991|3.7691|0|0|0.028007|collective;cyclicLong;lateralCyclic;rudder|
|conversion_high|longitudinal_symmetric|7-input|26.7811|-27.7495|NaN|0|0|0|theta;collective;cyclicLong|
|conversion_high|lateral_directional_balance|7-input|NaN|NaN|NaN|NaN|NaN|NaN|diffCollective;diffCyclic;aileron;rudder|
|conversion_high|full_6dof_straight_trim|7-input|26.6979|-28.3195|NaN|0.078947|0|0.0542084|collective;cyclicLong;aileron;rudder|
|conversion_high|longitudinal_symmetric|8-input|26.7811|-27.7495|0|0|0|0|theta;collective;cyclicLong|
|conversion_high|lateral_directional_balance|8-input|NaN|NaN|NaN|NaN|NaN|NaN|lateralCyclic;diffCollective;diffCyclic;aileron;rudder|
|conversion_high|full_6dof_straight_trim|8-input|26.7614|-27.8791|0.395479|0|0|0.497337|collective;cyclicLong;lateralCyclic;rudder|

## Residual Summary

|case|mode|architecture|labels|values|full residual norm|limit summary|
|-|-|-|-|-|-:|-|
|helicopter_low_speed|longitudinal_symmetric|7-input|udot;wdot;qdot|-1.76703815669e-09;-2.22486657246e-10;-8.78897753391e-11|1.783157e-09|no active limits or violations|
|helicopter_low_speed|lateral_directional_balance|7-input|vdot;pdot;rdot|-5.21064672891e-17;-8.98976674679e-19;-2.02269751803e-17|1.783157e-09|no active limits or violations|
|helicopter_low_speed|full_6dof_straight_trim|7-input|udot;vdot;wdot;pdot;qdot;rdot|2.22079203619e-10;-1.26502795119e-10;-6.55005957621e-11;-1.91154460574e-11;-3.35130696527e-12;5.72106172514e-12|2.646164e-10|no active limits or violations|
|helicopter_low_speed|longitudinal_symmetric|8-input|udot;wdot;qdot|-1.76703815669e-09;-2.22486657246e-10;-8.78897753391e-11|1.783157e-09|no active limits or violations|
|helicopter_low_speed|lateral_directional_balance|8-input|vdot;pdot;rdot|-5.21064672891e-17;-8.98976674679e-19;-2.02269751803e-17|1.783157e-09|no active limits or violations|
|helicopter_low_speed|full_6dof_straight_trim|8-input|udot;vdot;wdot;pdot;qdot;rdot|-5.25877415688e-12;-1.47831370107e-10;-1.41557393363e-10;1.28396925759e-12;7.71449877313e-12;-1.50378498652e-11|2.054448e-10|no active limits or violations|
|conversion_mid|longitudinal_symmetric|7-input|udot;wdot;qdot|1.68302621919;1.29337965898;-0.121508706988|2.126070e+00|cyclicLong atLimit=1 violated=0|
|conversion_mid|lateral_directional_balance|7-input|vdot;pdot;rdot|NaN;NaN;NaN|Inf|atLimit=0 violation=0|
|conversion_mid|full_6dof_straight_trim|7-input|udot;vdot;wdot;pdot;qdot;rdot|1.72249694382;-0.2446674672;1.33763290731;-0.017513502236;-0.110625254249;-0.0032737748866|2.197425e+00|no active limits or violations|
|conversion_mid|longitudinal_symmetric|8-input|udot;wdot;qdot|1.68302621919;1.29337965898;-0.121508706988|2.126070e+00|cyclicLong atLimit=1 violated=0|
|conversion_mid|lateral_directional_balance|8-input|vdot;pdot;rdot|NaN;NaN;NaN|Inf|atLimit=0 violation=0|
|conversion_mid|full_6dof_straight_trim|8-input|udot;vdot;wdot;pdot;qdot;rdot|1.6805267565;-0.0777649653871;1.30244874402;-0.0140091004332;-0.120171991656;-0.0100342811447|2.131039e+00|no active limits or violations|
|airplane_like|longitudinal_symmetric|7-input|udot;wdot;qdot|-1.22810787861;2.89562005898;-0.167165467692|3.149732e+00|cyclicLong atLimit=1 violated=0|
|airplane_like|lateral_directional_balance|7-input|vdot;pdot;rdot|NaN;NaN;NaN|Inf|atLimit=0 violation=0|
|airplane_like|full_6dof_straight_trim|7-input|udot;vdot;wdot;pdot;qdot;rdot|-1.23130688553;-0.226424526256;2.89364180801;-0.00445379656097;-0.166769294132;-0.00519851467828|3.157278e+00|no active limits or violations|
|airplane_like|longitudinal_symmetric|8-input|udot;wdot;qdot|-1.22810787861;2.89562005898;-0.167165467692|3.149732e+00|cyclicLong atLimit=1 violated=0|
|airplane_like|lateral_directional_balance|8-input|vdot;pdot;rdot|NaN;NaN;NaN|Inf|atLimit=0 violation=0|
|airplane_like|full_6dof_straight_trim|8-input|udot;vdot;wdot;pdot;qdot;rdot|-1.13203676725;-0.035786355849;2.91853142996;-0.0117977662774;-0.162147607943;-0.0248861733988|3.134911e+00|no active limits or violations|
|conversion_high|longitudinal_symmetric|7-input|udot;wdot;qdot|2.53646815099;5.64539770029;-0.345411916848|6.198669e+00|no active limits or violations|
|conversion_high|lateral_directional_balance|7-input|vdot;pdot;rdot|NaN;NaN;NaN|Inf|atLimit=0 violation=0|
|conversion_high|full_6dof_straight_trim|7-input|udot;vdot;wdot;pdot;qdot;rdot|2.55599488005;-0.013636468952;5.63252755862;0.00511595368049;-0.346304753414;-0.000542459685582|6.195048e+00|no active limits or violations|
|conversion_high|longitudinal_symmetric|8-input|udot;wdot;qdot|2.53646815099;5.64539770029;-0.345411916848|6.198669e+00|no active limits or violations|
|conversion_high|lateral_directional_balance|8-input|vdot;pdot;rdot|NaN;NaN;NaN|Inf|atLimit=0 violation=0|
|conversion_high|full_6dof_straight_trim|8-input|udot;vdot;wdot;pdot;qdot;rdot|2.54036893866;0.00261583669994;5.64188831682;0.000825369829766;-0.345724049282;-0.00549992321162|6.197091e+00|no active limits or violations|

## Limitations

- These runs are representative internal smoke diagnostics only.
- A failed trim run is recorded as evidence and is not hidden.
- No model equations, default parameters, or control limits are tuned.
- No external validation or trend comparison is claimed.
