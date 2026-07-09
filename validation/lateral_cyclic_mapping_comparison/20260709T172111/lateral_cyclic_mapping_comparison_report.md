# Lateral Cyclic Theta1c Mapping Comparison

This diagnostic compares lateralCyclic theta1c mapping candidates inside the current model. It is not Berger/XV-15 validation and does not implement 13x10 or nacelle torque.

## Problem

The current mapping has a nonzero full B column, but the `v/p/r` target rows and raw `Fy/Mx/Mz` response are small. The nonzero full B column mainly comes from longitudinal/pitch leakage.

## Candidate Mappings

- `current`: `theta1c = lateralCyclic`
- `rotDir`: `theta1c = rotDir*lateralCyclic`
- `minusRotDir`: `theta1c = -rotDir*lateralCyclic`

## Recommendation

Recommended candidate: `rotDir`.

Reason: candidate improves lateral target response and aligns left/right nDiskY in representative conditions. Score: 59.2533.

## Comparison Table

|condition|mapping|classification|lateral_target_norm|longitudinal_leak_norm|ratio|B_vdot|B_pdot|B_rdot|raw_dFy|raw_dMx|raw_dMz|dBeta1s_L|dBeta1s_R|dNDiskY_L|dNDiskY_R|max_B_row|reason|
|-|-|-:|-:|-:|-:|-:|-:|-:|-:|-:|-:|-:|-:|-:|-:|-|-|
|hover_like_beta0|current|CURRENT_CANCELLATION_CONFIRMED|3.750337e-08|1.729653e-03|2.168259e-05|-9.066821e-14|2.031687e-12|2.382288e-13|-5.440093e-10|3.637979e-08|9.094947e-09|1.023329e+00|-1.023329e+00|-1.023329e+00|1.023329e+00|u|left/right beta1s or nDiskY oppose while longitudinal/pitch leakage remains|
|low_speed_helicopter|current|CURRENT_CANCELLATION_CONFIRMED|1.525770e-08|2.314112e-02|6.593327e-07|-6.513308e-14|-7.652539e-13|-1.651870e-13|-3.907985e-10|-1.364242e-08|-6.821210e-09|1.014607e+00|-1.014607e+00|-1.014254e+00|1.014254e+00|w|left/right beta1s or nDiskY oppose while longitudinal/pitch leakage remains|
|conversion_mid|current|CURRENT_CANCELLATION_CONFIRMED|2.057991e-07|5.403077e-02|3.808924e-06|2.131628e-13|8.345006e-12|3.405892e-12|1.278977e-09|1.455192e-07|1.455192e-07|1.038483e+00|-1.038483e+00|-1.038450e+00|1.038450e+00|w|left/right beta1s or nDiskY oppose while longitudinal/pitch leakage remains|
|airplane_forward|current|CURRENT_CANCELLATION_CONFIRMED|7.276377e-08|5.693515e-03|1.278011e-05|-1.302662e-13|4.154287e-12|7.489978e-14|-7.815970e-10|7.275958e-08|0.000000e+00|5.685768e-01|-5.685768e-01|-5.685755e-01|5.685755e-01|u|left/right beta1s or nDiskY oppose while longitudinal/pitch leakage remains|
|hover_like_beta0|rotDir|PROMISING_LATERAL_MAPPING|4.240562e+04|4.246959e-13|9.984938e+16|5.654079e+00|1.414587e+00|2.400786e-02|3.392447e+04|2.544336e+04|-5.131551e+01|-1.023329e+00|-1.023329e+00|1.023329e+00|1.023329e+00|v|left/right nDiskY align and lateral target response improves over current|
|low_speed_helicopter|rotDir|PROMISING_LATERAL_MAPPING|2.709945e+04|5.561947e-13|4.872296e+16|3.556918e+00|9.285503e-01|1.626154e-02|2.134151e+04|1.670090e+04|-1.107086e+01|-1.014607e+00|-1.014607e+00|1.014254e+00|1.014254e+00|v|left/right nDiskY align and lateral target response improves over current|
|conversion_mid|rotDir|PROMISING_LATERAL_MAPPING|2.807221e+04|9.942009e-12|2.823596e+15|-3.917923e+00|-6.827716e-01|-2.277057e-01|-2.350754e+04|-1.194685e+04|-9.629004e+03|-1.038483e+00|-1.038483e+00|1.038450e+00|1.038450e+00|v|left/right nDiskY align and lateral target response improves over current|
|airplane_forward|rotDir|PROMISING_LATERAL_MAPPING|4.759909e+04|5.551115e-13|8.574689e+16|-6.676462e+00|-2.649483e-01|-5.764638e-01|-4.005877e+04|-4.183044e+03|-2.536671e+04|-5.685768e-01|-5.685768e-01|5.685755e-01|5.685755e-01|v|left/right nDiskY align and lateral target response improves over current|
|hover_like_beta0|minusRotDir|PROMISING_LATERAL_MAPPING|4.240562e+04|4.246959e-13|9.984938e+16|-5.654079e+00|-1.414587e+00|-2.400786e-02|-3.392447e+04|-2.544336e+04|5.131551e+01|1.023329e+00|1.023329e+00|-1.023329e+00|-1.023329e+00|v|left/right nDiskY align and lateral target response improves over current|
|low_speed_helicopter|minusRotDir|PROMISING_LATERAL_MAPPING|2.709945e+04|5.561947e-13|4.872296e+16|-3.556918e+00|-9.285503e-01|-1.626154e-02|-2.134151e+04|-1.670090e+04|1.107086e+01|1.014607e+00|1.014607e+00|-1.014254e+00|-1.014254e+00|v|left/right nDiskY align and lateral target response improves over current|
|conversion_mid|minusRotDir|PROMISING_LATERAL_MAPPING|2.807221e+04|9.942009e-12|2.823596e+15|3.917923e+00|6.827716e-01|2.277057e-01|2.350754e+04|1.194685e+04|9.629004e+03|1.038483e+00|1.038483e+00|-1.038450e+00|-1.038450e+00|v|left/right nDiskY align and lateral target response improves over current|
|airplane_forward|minusRotDir|PROMISING_LATERAL_MAPPING|4.759909e+04|5.551115e-13|8.574689e+16|6.676462e+00|2.649483e-01|5.764638e-01|4.005877e+04|4.183044e+03|2.536671e+04|5.685768e-01|5.685768e-01|-5.685755e-01|-5.685755e-01|v|left/right nDiskY align and lateral target response improves over current|

## Mapping Findings

- `current`: 0 promising, 4 current-cancellation, 0 leak-dominant, 0 ambiguous.
- `rotDir`: 4 promising, 0 current-cancellation, 0 leak-dominant, 0 ambiguous.
- `minusRotDir`: 4 promising, 0 current-cancellation, 0 leak-dominant, 0 ambiguous.

## Limits

- This is an internal diagnostic using finite representative points.
- No mass, inertia, geometry, `rotDir`, or `psi` definition is changed.
- No final external sign convention is claimed.
- No 13x10, nacelle torque, or Berger 51-state model is implemented.
