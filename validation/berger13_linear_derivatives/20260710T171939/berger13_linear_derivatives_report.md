# Berger13 Linear Derivative Internal Audit

Generated: `20260710T171939`

This is an internal derivative audit for the isolated berger13 13x10 research model. It is not Berger/XV-15 validation, not a handling-quality conclusion, and not nonlinear response validation. The representative points are finite operating points, not a full trim envelope.

Non-rotor aero and mass properties still use `betaMAvg = 0.5*(betaML + betaMR)`.

## Conditioning Diagnostics

The report includes raw A SVD/rank diagnostics, scaled A diagnostics using internal state scales, a dynamic submatrix diagnostic that removes structural heading/null columns, and B-column rank/norm checks. These are internal numerical health diagnostics, not validation or handling-quality pass/fail criteria.

## Cases

### helicopter_like

- V: 20 m/s
- betaML: 0 rad
- betaMR: 0 rad
- betaMAvg: 0 rad
- usedIndependentRotorAngles: true
- usedAverageNonRotorAero: true
- A size: 13 x 13
- B size: 13 x 10
- norm(A): 3.194012733722e+01
- norm(B): 9.587038641717e+01
- conditionNumber: 2.600530710417e+17 (SEVERE)
- norm(A13(1:9,10)): 3.030747715541e+00
- norm(A13(1:9,11)): 3.024922660861e+00
- norm(A13(4:6,10)): 2.538863327564e+00
- norm(A13(4:6,11)): 2.531957969655e+00
- norm(A13(4:6,10)-A13(4:6,11)): 5.070598983802e+00
- A13(10,12): 5.000000000000e-01
- A13(11,13): 5.000000000000e-01
- A13(12,12): -1.800000000000e+00
- A13(13,13): -1.800000000000e+00
- first9DifferenceNorm vs legacy opt-in: 0.000000000000e+00
- independent vs betaMAvg-only force delta norm: 0.000000000000e+00
- independent vs betaMAvg-only moment delta norm: 0.000000000000e+00

#### Conditioning Diagnostics

- raw A rank: 11
- raw A condition: Inf
- raw A min singular value: 0.000000000000e+00
- raw near-zero singular count: 2
- zero A columns: psi
- scaled A rank: 11
- scaled A condition: Inf
- scaled A min singular value: 0.000000000000e+00
- scaled near-zero singular count: 2
- dynamic A rank: 10
- dynamic A condition: Inf
- scaled dynamic A rank: 10
- scaled dynamic A condition: Inf
- B rank: 8
- near-zero B control columns: none
- interpretation: raw A is structurally singular; psi is a zero column; scaled A remains structurally singular; scaled dynamic submatrix remains singular; diagnostics do not change validation/pass-fail criteria

| Control | norm(B column) |
|-|-:|
| collective | 4.882179346688e+01 |
| diffCollective | 8.246217859313e+01 |
| cyclicLong | 1.704381479614e+00 |
| diffCyclic | 1.126835468262e+00 |
| lateralCyclic | 1.778167843071e+00 |
| aileron | 1.764346629758e-01 |
| elevator | 4.169966657994e-01 |
| rudder | 1.048686852260e-01 |
| nacelleTorqueLeft | 2.000000000000e-03 |
| nacelleTorqueRight | 2.000000000000e-03 |

- B13(12,9): 2.000000000000e-03
- B13(13,10): 2.000000000000e-03

### conversion_mid

- V: 45 m/s
- betaML: 0.785398163397 rad
- betaMR: 0.785398163397 rad
- betaMAvg: 0.785398163397 rad
- usedIndependentRotorAngles: true
- usedAverageNonRotorAero: true
- A size: 13 x 13
- B size: 13 x 10
- norm(A): 6.676836230763e+01
- norm(B): 1.151886518573e+02
- conditionNumber: 8.346634440493e+17 (SEVERE)
- norm(A13(1:9,10)): 1.064768545741e+01
- norm(A13(1:9,11)): 1.063967323474e+01
- norm(A13(4:6,10)): 6.720022508324e+00
- norm(A13(4:6,11)): 6.705514880483e+00
- norm(A13(4:6,10)-A13(4:6,11)): 1.342163514293e+01
- A13(10,12): 1.000000000000e+00
- A13(11,13): 1.000000000000e+00
- A13(12,12): -3.600000000000e+00
- A13(13,13): -3.600000000000e+00
- first9DifferenceNorm vs legacy opt-in: 0.000000000000e+00
- independent vs betaMAvg-only force delta norm: 0.000000000000e+00
- independent vs betaMAvg-only moment delta norm: 0.000000000000e+00

#### Conditioning Diagnostics

- raw A rank: 11
- raw A condition: Inf
- raw A min singular value: 0.000000000000e+00
- raw near-zero singular count: 2
- zero A columns: psi
- scaled A rank: 11
- scaled A condition: Inf
- scaled A min singular value: 0.000000000000e+00
- scaled near-zero singular count: 2
- dynamic A rank: 10
- dynamic A condition: Inf
- scaled dynamic A rank: 10
- scaled dynamic A condition: Inf
- B rank: 8
- near-zero B control columns: none
- interpretation: raw A is structurally singular; psi is a zero column; scaled A remains structurally singular; scaled dynamic submatrix remains singular; diagnostics do not change validation/pass-fail criteria

| Control | norm(B column) |
|-|-:|
| collective | 6.517874546475e+01 |
| diffCollective | 9.445321473078e+01 |
| cyclicLong | 5.300091517940e+00 |
| diffCyclic | 6.097385286973e+00 |
| lateralCyclic | 5.197052219464e+00 |
| aileron | 1.262014089688e+00 |
| elevator | 2.142466918120e+00 |
| rudder | 5.343950753929e-01 |
| nacelleTorqueLeft | 4.000000000000e-03 |
| nacelleTorqueRight | 4.000000000000e-03 |

- B13(12,9): 4.000000000000e-03
- B13(13,10): 4.000000000000e-03
### airplane_like

- V: 100 m/s
- betaML: 1.57079632679 rad
- betaMR: 1.57079632679 rad
- betaMAvg: 1.57079632679 rad
- usedIndependentRotorAngles: true
- usedAverageNonRotorAero: true
- A size: 13 x 13
- B size: 13 x 10
- norm(A): 1.433259680202e+02
- norm(B): 2.400891359161e+01
- conditionNumber: 1.486188053146e+18 (SEVERE)
- norm(A13(1:9,10)): 1.809995092605e+01
- norm(A13(1:9,11)): 1.808998707375e+01
- norm(A13(4:6,10)): 1.562735583851e+01
- norm(A13(4:6,11)): 1.561551548498e+01
- norm(A13(4:6,10)-A13(4:6,11)): 3.123383397280e+01
- A13(10,12): 5.000000000000e-01
- A13(11,13): 5.000000000000e-01
- A13(12,12): -1.800000000000e+00
- A13(13,13): -1.800000000000e+00
- first9DifferenceNorm vs legacy opt-in: 0.000000000000e+00
- independent vs betaMAvg-only force delta norm: 0.000000000000e+00
- independent vs betaMAvg-only moment delta norm: 0.000000000000e+00

#### Conditioning Diagnostics

- raw A rank: 11
- raw A condition: Inf
- raw A min singular value: 0.000000000000e+00
- raw near-zero singular count: 2
- zero A columns: psi
- scaled A rank: 11
- scaled A condition: Inf
- scaled A min singular value: 0.000000000000e+00
- scaled near-zero singular count: 2
- dynamic A rank: 10
- dynamic A condition: Inf
- scaled dynamic A rank: 10
- scaled dynamic A condition: Inf
- B rank: 8
- near-zero B control columns: none
- interpretation: raw A is structurally singular; psi is a zero column; scaled A remains structurally singular; scaled dynamic submatrix remains singular; diagnostics do not change validation/pass-fail criteria

| Control | norm(B column) |
|-|-:|
| collective | 9.981207955450e+00 |
| diffCollective | 8.704067503432e+00 |
| cyclicLong | 6.736340177139e+00 |
| diffCyclic | 1.144277257081e+01 |
| lateralCyclic | 6.724808290171e+00 |
| aileron | 7.627508701622e+00 |
| elevator | 1.069081094208e+01 |
| rudder | 2.651777380051e+00 |
| nacelleTorqueLeft | 2.000000000000e-03 |
| nacelleTorqueRight | 2.000000000000e-03 |

- B13(12,9): 2.000000000000e-03
- B13(13,10): 2.000000000000e-03

### asymmetric_nacelle_probe

- V: 45 m/s
- betaML: 0.610865238198 rad
- betaMR: 0.959931088597 rad
- betaMAvg: 0.785398163397 rad
- usedIndependentRotorAngles: true
- usedAverageNonRotorAero: true
- A size: 13 x 13
- B size: 13 x 10
- norm(A): 6.722798263501e+01
- norm(B): 1.179962845175e+02
- conditionNumber: 2.622014278729e+19 (SEVERE)
- norm(A13(1:9,10)): 1.413688204888e+01
- norm(A13(1:9,11)): 9.407143390483e+00
- norm(A13(4:6,10)): 1.080390233130e+01
- norm(A13(4:6,11)): 5.149256343530e+00
- norm(A13(4:6,10)-A13(4:6,11)): 1.321320151477e+01
- A13(10,12): 1.000000000000e+00
- A13(11,13): 1.000000000000e+00
- A13(12,12): -3.600000000000e+00
- A13(13,13): -3.600000000000e+00
- first9DifferenceNorm vs legacy opt-in: NaN
- independent vs betaMAvg-only force delta norm: 3.504680438243e+03
- independent vs betaMAvg-only moment delta norm: 8.302566616355e+04

#### Conditioning Diagnostics

- raw A rank: 11
- raw A condition: Inf
- raw A min singular value: 0.000000000000e+00
- raw near-zero singular count: 2
- zero A columns: psi
- scaled A rank: 11
- scaled A condition: Inf
- scaled A min singular value: 0.000000000000e+00
- scaled near-zero singular count: 2
- dynamic A rank: 10
- dynamic A condition: Inf
- scaled dynamic A rank: 10
- scaled dynamic A condition: Inf
- B rank: 8
- near-zero B control columns: none
- interpretation: raw A is structurally singular; psi is a zero column; scaled A remains structurally singular; scaled dynamic submatrix remains singular; diagnostics do not change validation/pass-fail criteria

| Control | norm(B column) |
|-|-:|
| collective | 6.785191600651e+01 |
| diffCollective | 9.600296173057e+01 |
| cyclicLong | 5.714671506800e+00 |
| diffCyclic | 6.194670198742e+00 |
| lateralCyclic | 5.017183441784e+00 |
| aileron | 1.262014089689e+00 |
| elevator | 2.142466918120e+00 |
| rudder | 5.343950753940e-01 |
| nacelleTorqueLeft | 4.000000000000e-03 |
| nacelleTorqueRight | 4.000000000000e-03 |

- B13(12,9): 4.000000000000e-03
- B13(13,10): 4.000000000000e-03
