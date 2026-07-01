# NUAA Trend Root-Cause Report

## Scope

- Git commit: `361baa17633b85471044b872dcc23879b7e7cfa4`
- MATLAB elapsed seconds: 568.320
- Diagnostic type: reduced representative run plus fixed-trim sensitivities.
- Production model/default parameters/trim algorithm/control limits were not modified.

## Stage 0 Static Findings

- NUAA PDF page 10 describes Figure 5(a) helicopter mode and Figure 5(b) flight mode; PDF pages 10-11 describe Figure 6(a) as 15 deg transition with helicopter manipulation and Figure 6(b) as 75 deg transition with fixed-wing aircraft control.
- Current code solves 0 deg with unknowns theta, collective, cyclicLong and elevator fixed to zero.
- Current code solves 15 deg conversion with unknowns theta, collective, pitchCommand; pitchCommand is mapped to cyclicLong and elevator by a cos^2/sin^2 assumed open-loop allocation.
- Current code uses `paperCyclic_deg = +cyclicLong_deg` in the final validation plotting path.

## Point Summary

|mode|betaM deg|V m/s|theta deg|collective deg|cyclicLong deg|elevator deg|residual|success|
|-|-:|-:|-:|-:|-:|-:|-:|-|
|helicopter_longitudinal|0.0|0.0|-1.03016e-08|16.7696|0.00104493|0|1.666e-09|1|
|helicopter_longitudinal|0.0|2.5|-0.213087|16.732|-0.310102|0|8.114e-10|1|
|helicopter_longitudinal|0.0|5.0|0.0256488|16.6072|-0.536786|0|9.842e-10|1|
|helicopter_longitudinal|0.0|7.5|1.49381|16.3647|-0.743599|0|1.479e-09|1|
|helicopter_longitudinal|0.0|10.0|1.56501|16.1823|-0.965311|0|1.551e-09|1|
|helicopter_longitudinal|0.0|12.5|1.49302|15.969|-1.14496|0|5.598e-10|1|
|helicopter_longitudinal|0.0|15.0|1.4224|15.7286|-1.28198|0|4.031e-10|1|
|helicopter_longitudinal|0.0|20.0|1.28089|15.223|-1.4167|0|1.692e-09|1|
|helicopter_longitudinal|0.0|25.0|1.15014|14.7453|-1.34968|0|2.398e-09|1|
|helicopter_longitudinal|0.0|30.0|1.06123|14.3149|-1.08194|0|2.517e-09|1|
|conversion_longitudinal|15.0|10.0|12.3973|16.0103|-7.05071|-0.289267|7.222e-10|1|
|conversion_longitudinal|15.0|20.0|9.99846|14.887|-10.8938|-0.446936|4.092e-10|1|
|conversion_longitudinal|15.0|30.0|7.54938|14.1465|-13.5626|-0.556429|2.086e-09|1|
|conversion_longitudinal|15.0|35.0|6.56556|14.0016|-14.2423|-0.584314|2.790e-09|1|
|conversion_longitudinal|15.0|37.5|6.13801|13.9741|-14.4364|-0.592279|1.284e-09|1|
|conversion_longitudinal|15.0|40.0|5.74988|13.9708|-14.5445|-0.596713|2.280e-09|1|
|conversion_longitudinal|15.0|42.5|5.39794|13.9879|-14.5746|-0.59795|1.468e-09|1|
|conversion_longitudinal|15.0|45.0|5.07885|14.0223|-14.5342|-0.596293|1.612e-09|1|
|conversion_longitudinal|15.0|50.0|4.52645|14.1324|-14.2673|-0.585342|1.618e-09|1|
|conversion_longitudinal|15.0|55.0|4.06915|14.2863|-13.7868|-0.565626|1.432e-09|1|
|conversion_longitudinal|15.0|60.0|3.68726|14.476|-13.1218|-0.538345|2.137e-09|1|
|helicopter_longitudinal|15.0|40.0|5.50592|14.0767|-14.9915|0|1.836e-09|1|
|helicopter_longitudinal|15.0|50.0|4.25305|14.3052|-14.8253|0|3.608e-09|1|
|helicopter_longitudinal|15.0|60.0|3.41644|14.7079|-13.7895|0|1.965e-09|1|

## Key Root-Cause Evidence

- 0 deg theta range: start -0.000 deg, max 1.565 deg at 10.0 m/s, end 1.061 deg.
- 15 deg collective minimum 13.971 deg at 40.0 m/s; largest adjacent positive slope 0.190 deg over 55.0->60.0 m/s.
- Wing slipstream region normal-flow ratio range 0.000 to 1.000; blend weight range 0.000 to 1.000.
- Cyclic probe -0.1 deg: deltaFx -5.272e+01 N, deltaFz -1.005e+00 N, deltaMy 3.956e+01 N-m, deltaQdot 1.319e-03 rad/s^2.
- Cyclic probe +0.1 deg: deltaFx 5.268e+01 N, deltaFz 1.047e+00 N, deltaMy -3.952e+01 N-m, deltaQdot -1.317e-03 rad/s^2.

## Conclusion Table

|Issue|Direct evidence|Excluded causes|Root-cause class|Confidence|Needs code fix?|Needs model expansion?|Needs parameter source?|Next minimal action|
|-|-|-|-|-|-|-|-|-|
|0 deg pitch rises near 5-15 m/s|theta from representative trims forms a positive hump; wing regions enter active normal-flow/slipstream blend and rotor cyclic probe gives expected nose-down authority|solver branch mismatch not seen in final branch comparison; cyclic sign not primary|model physics/parameter sensitivity, especially wing slipstream/near-normal and tail moment balance|Medium|No clear literal bug found|Yes|Yes|Run focused re-trim sensitivity on wing normal-flow/tail parameters after sourcing data|
|15 deg collective high-speed rebound|current 15 deg mode uses cos^2/sin^2 cyclic/elevator allocation, not strict helicopter manipulation; allocation contrast rows show elevator-free trim differs|not explained by residual/Jacobian failure in representative points|control-definition mismatch plus drag/lift parameter sensitivity|Medium-High|No production bug; comparison definition mismatch|Possibly|Yes|Add a separate paper-comparison trim definition instead of changing production model|
|paperCyclic sign|fixed-trim +/-cyclicLong perturbation records disk-normal and qdot response; current plotting uses + sign|plot-only sign guessing|definition/mapping unresolved without direct paper actuator sign convention|Medium|No immediate fix|No|Yes|Digitize/trace paper vertical-pitch convention before changing sign|
|75 deg control comparison|paper says fixed-wing aircraft control; current conversion path still mixes cyclic/elevator unless mode is airplane endpoint|pure model equation error not shown|comparison-definition mismatch|High|No immediate production fix|No|No|Use a paper-specific fixed-wing comparison trim for 75 deg diagnostics|

## Outputs

- `E:\tiltrotor\validation\nuaa_trend_root_cause_20260701_011349\trend_root_cause_components.csv`
- `E:\tiltrotor\validation\nuaa_trend_root_cause_20260701_011349\trend_root_cause_sensitivity.csv`
- `E:\tiltrotor\validation\nuaa_trend_root_cause_20260701_011349\0deg_component_balance.png`
- `E:\tiltrotor\validation\nuaa_trend_root_cause_20260701_011349\0deg_wing_region_diagnostics.png`
- `E:\tiltrotor\validation\nuaa_trend_root_cause_20260701_011349\15deg_force_balance.png`
- `E:\tiltrotor\validation\nuaa_trend_root_cause_20260701_011349\15deg_allocation_comparison.png`

## Limitations

- Full Stage 4 re-trim sensitivity was not executed because one measured trim point took about 43 seconds, making the full requested matrix likely exceed the 20 minute threshold.
- Fixed-trim sensitivities classify local load response only; they do not prove re-trimmed trend elimination.
- No default parameter or production code change is recommended from this reduced diagnostic alone.
