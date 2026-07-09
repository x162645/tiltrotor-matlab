# Lateral/Directional Derivative Report

This report audits the current opt-in 8-flight-input model. It does not validate the model against Berger, XV-15, or flight-test data.

Active control order:

```text
collective diffCollective cyclicLong diffCyclic lateralCyclic aileron elevator rudder
```

Legacy default 7-input behavior remains controlled by `P.control.enableLateralCyclic = false`. The audited mode sets it to true.

`lateralCyclic` is connected to the rotor blade-pitch term `theta1c*cos(psi)` with the default opt-in mapping `theta1c = rotDir*lateralCyclic`. `diffCyclic` remains differential longitudinal cyclic.

EOM B derivatives are state-derivative sensitivities from `linearize_numeric`. Raw load derivatives are central differences of `[F; M]` from `total_forces_moments`; they are not the same quantity.

## Conditions

|condition|status|V_mps|betaM_deg|reason|
|-|-:|-:|-:|-|
|hover_like_beta0|OK|0|0|representative finite operating point|
|low_speed_helicopter|OK|20|0|representative finite operating point|
|conversion_mid|OK|45|45|representative finite operating point|
|airplane_forward|OK|100|90|representative finite operating point|

## Derivative Blocks

### hover_like_beta0

B size: 9 x 8. `lateralCyclic` full-column norm: 5.828399450749e+00.

A_lat rows [vdot pdot rdot], columns [v p r phi psi]

| |v|p|r|phi|psi|
|-|-:|-:|-:|-:|-:|
|vdot|-1.028821799472e-02|1.235440493409e-02|-1.112595826244e-02|9.806649698157e+00|0.000000000000e+00|
|pdot|4.184568878414e-03|-1.258180682841e+00|-2.959833353584e-03|-4.963717555726e-05|0.000000000000e+00|
|rdot|1.563189871601e-03|-3.272918477958e-02|-4.018778280907e-03|-1.115230646193e-03|0.000000000000e+00|

B_lat rows [vdot pdot rdot], columns [diffCollective diffCyclic lateralCyclic aileron rudder]

| |diffCollective|diffCyclic|lateralCyclic|aileron|rudder|
|-|-:|-:|-:|-:|-:|
|vdot|-1.017271399058e-12|-1.710517147954e-03|5.654078893697e+00|0.000000000000e+00|0.000000000000e+00|
|pdot|-8.152993278466e+01|-1.680887036182e-01|1.414586739587e+00|0.000000000000e+00|0.000000000000e+00|
|rdot|1.790055426225e+00|-3.772374172750e+00|2.400786393929e-02|0.000000000000e+00|0.000000000000e+00|

### low_speed_helicopter

B size: 9 x 8. `lateralCyclic` full-column norm: 3.676157860722e+00.

A_lat rows [vdot pdot rdot], columns [v p r phi psi]

| |v|p|r|phi|psi|
|-|-:|-:|-:|-:|-:|
|vdot|-3.824514501368e-02|9.888726316876e-03|-1.994728017877e+01|9.806646915307e+00|0.000000000000e+00|
|pdot|-2.611268640186e-04|-2.456115999484e+00|5.971485569218e-01|1.071634480675e-03|0.000000000000e+00|
|rdot|9.322197604377e-03|-6.568132169069e-02|-2.083673510514e-02|-3.384951240902e-04|0.000000000000e+00|

B_lat rows [vdot pdot rdot], columns [diffCollective diffCyclic lateralCyclic aileron rudder]

| |diffCollective|diffCyclic|lateralCyclic|aileron|rudder|
|-|-:|-:|-:|-:|-:|
|vdot|2.710517324209e-01|-9.151852931026e-03|3.556918116500e+00|0.000000000000e+00|9.146666666667e-02|
|pdot|-8.496877713760e+01|2.305775387642e-01|9.285503172789e-01|1.226146276108e-01|3.824295739844e-03|
|rdot|-2.256907118275e+00|-2.333818621363e+00|1.626154197849e-02|-1.433722840783e-03|-5.115334585351e-02|

### conversion_mid

B size: 9 x 8. `lateralCyclic` full-column norm: 3.983483984350e+00.

A_lat rows [vdot pdot rdot], columns [v p r phi psi]

| |v|p|r|phi|psi|
|-|-:|-:|-:|-:|-:|
|vdot|-9.149172066591e-02|-2.000138994519e-02|-4.488146373927e+01|9.806635110077e+00|0.000000000000e+00|
|pdot|-6.312843922690e-03|-3.188130241081e+00|-2.029929977166e+00|-2.510818730504e-03|0.000000000000e+00|
|rdot|2.105503881420e-02|-7.050756614232e-01|-7.304714744882e-01|-6.803057102922e-04|0.000000000000e+00|

B_lat rows [vdot pdot rdot], columns [diffCollective diffCyclic lateralCyclic aileron rudder]

| |diffCollective|diffCyclic|lateralCyclic|aileron|rudder|
|-|-:|-:|-:|-:|-:|
|vdot|-7.893643095846e-01|1.721210105752e-02|-3.917922619238e+00|0.000000000000e+00|4.630500000000e-01|
|pdot|-1.019048526330e+02|-4.364414853779e+00|-6.827716363569e-01|1.261932525615e+00|2.447004772717e-02|
|rdot|-3.342524283407e+01|1.972492382843e+00|-2.277057219866e-01|1.434793943113e-02|-2.656388730370e-01|

### airplane_forward

B size: 9 x 8. `lateralCyclic` full-column norm: 6.706538354794e+00.

A_lat rows [vdot pdot rdot], columns [v p r phi psi]

| |v|p|r|phi|psi|
|-|-:|-:|-:|-:|-:|
|vdot|-8.216142092695e-02|5.288206155246e-02|-9.960749704055e+01|9.806649983649e+00|0.000000000000e+00|
|pdot|-3.243227371084e-02|-1.919927394606e+00|-8.161588792123e-01|1.613580849023e-02|0.000000000000e+00|
|rdot|5.687327268433e-02|-3.030119132890e-02|-6.172025156223e-01|2.909208388039e-04|0.000000000000e+00|

B_lat rows [vdot pdot rdot], columns [diffCollective diffCyclic lateralCyclic aileron rudder]

| |diffCollective|diffCyclic|lateralCyclic|aileron|rudder|
|-|-:|-:|-:|-:|-:|
|vdot|5.927501264523e-02|3.202955021209e-05|-6.676462283253e+00|0.000000000000e+00|2.286666666667e+00|
|pdot|-5.392898232739e+00|-1.143590792270e+01|-2.649482986579e-01|7.627001056347e+00|1.838915423196e-01|
|rdot|-6.822015803114e+00|-2.061809853538e-01|-5.764637748145e-01|8.799931707256e-02|-1.330136357510e+00|

## Control Derivative Summary

|condition|control|classification|B_vdot|B_pdot|B_rdot|raw_dFy|raw_dMx|raw_dMz|reason|
|-|-|-:|-:|-:|-:|-:|-:|-:|-|
|hover_like_beta0|diffCollective|PASS_NONZERO|-1.017271e-12|-8.152993e+01|1.790055e+00|-6.103628e-09|-1.468971e+06|1.457764e+05|finite nonzero model-internal response|
|hover_like_beta0|diffCyclic|PASS_NONZERO|-1.710517e-03|-1.680887e-01|-3.772374e+00|-1.026310e+01|-7.697327e+00|-1.696224e+05|finite nonzero model-internal response|
|hover_like_beta0|lateralCyclic|PASS_NONZERO|5.654079e+00|1.414587e+00|2.400786e-02|3.392447e+04|2.544336e+04|-5.131551e+01|finite nonzero model-internal response|
|hover_like_beta0|aileron|FAIL_ZERO_COLUMN|0.000000e+00|0.000000e+00|0.000000e+00|0.000000e+00|0.000000e+00|0.000000e+00|full B column and raw load response are near zero|
|hover_like_beta0|rudder|FAIL_ZERO_COLUMN|0.000000e+00|0.000000e+00|0.000000e+00|0.000000e+00|0.000000e+00|0.000000e+00|full B column and raw load response are near zero|
|low_speed_helicopter|diffCollective|PASS_NONZERO|2.710517e-01|-8.496878e+01|-2.256907e+00|1.626310e+03|-1.527632e+06|-3.358580e+04|finite nonzero model-internal response|
|low_speed_helicopter|diffCyclic|PASS_NONZERO|-9.151853e-03|2.305775e-01|-2.333819e+00|-5.491112e+01|6.017451e+03|-1.052063e+05|finite nonzero model-internal response|
|low_speed_helicopter|lateralCyclic|PASS_NONZERO|3.556918e+00|9.285503e-01|1.626154e-02|2.134151e+04|1.670090e+04|-1.107086e+01|finite nonzero model-internal response|
|low_speed_helicopter|aileron|PASS_NONZERO|0.000000e+00|1.226146e-01|-1.433723e-03|0.000000e+00|2.208210e+03|-1.626092e+02|finite nonzero model-internal response|
|low_speed_helicopter|rudder|PASS_NONZERO|9.146667e-02|3.824296e-03|-5.115335e-02|5.488000e+02|1.097600e+02|-2.304960e+03|finite nonzero model-internal response|
|conversion_mid|diffCollective|PASS_NONZERO|-7.893643e-01|-1.019049e+02|-3.342524e+01|-4.736186e+03|-1.783536e+06|-1.412111e+06|finite nonzero model-internal response|
|conversion_mid|diffCyclic|PASS_NONZERO|1.721210e-02|-4.364415e+00|1.972492e+00|1.032726e+02|-7.910912e+04|9.163401e+04|finite nonzero model-internal response|
|conversion_mid|lateralCyclic|PASS_NONZERO|-3.917923e+00|-6.827716e-01|-2.277057e-01|-2.350754e+04|-1.194685e+04|-9.629004e+03|finite nonzero model-internal response|
|conversion_mid|aileron|PASS_NONZERO|0.000000e+00|1.261933e+00|1.434794e-02|0.000000e+00|2.240597e+04|-3.683963e+02|finite nonzero model-internal response|
|conversion_mid|rudder|PASS_NONZERO|4.630500e-01|2.447005e-02|-2.656389e-01|2.778300e+03|6.472063e+02|-1.188987e+04|finite nonzero model-internal response|
|airplane_forward|diffCollective|PASS_NONZERO|5.927501e-02|-5.392898e+00|-6.822016e+00|3.556501e+02|-8.907321e+04|-2.983900e+05|finite nonzero model-internal response|
|airplane_forward|diffCyclic|PASS_NONZERO|3.202955e-05|-1.143591e+01|-2.061810e-01|1.921773e-01|-2.002924e+05|1.293310e-01|finite nonzero model-internal response|
|airplane_forward|lateralCyclic|PASS_NONZERO|-6.676462e+00|-2.649483e-01|-5.764638e-01|-4.005877e+04|-4.183044e+03|-2.536671e+04|finite nonzero model-internal response|
|airplane_forward|aileron|PASS_NONZERO|0.000000e+00|7.627001e+00|8.799932e-02|0.000000e+00|1.336215e+05|-2.196923e+03|finite nonzero model-internal response|
|airplane_forward|rudder|PASS_NONZERO|2.286667e+00|1.838915e-01|-1.330136e+00|1.372000e+04|4.287500e+03|-5.916750e+04|finite nonzero model-internal response|

## Key Sign Findings

- `lateralCyclic` has a finite nonzero full B column in all successful representative conditions.
- With the default opt-in `rotDir` mapping, `lateralCyclic` produces significant model-internal `Y/L/N` target response in the representative set.
- Positive `lateralCyclic` is the current internal convention for common `+eY` rotor disk-normal tilt; this is not external sign validation.
- `aileron` produces positive raw `Mx` in forward-speed representative points and is zero in hover-like zero-speed wing loading.
- `rudder` produces positive raw `Fy` and negative raw `Mz` in forward-speed representative points.
- `diffCollective` produces a strong raw `Mx` response across the representative set.
- `diffCyclic` produces a strong raw `Mz` response, with sign depending on nacelle angle and operating condition.

## Limitations

- This is an internal derivative/sign audit only, not Berger or XV-15 validation.
- The representative states are finite operating points, not certified trims for stability conclusions.
- This does not implement 13x10, nacelle torque, independent left/right nacelle states, or Berger 51 states.
- The `rotDir` sign convention remains model-internal until checked against a documented external rotor azimuth and disk-response convention.
