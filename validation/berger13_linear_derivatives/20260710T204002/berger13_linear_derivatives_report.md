# Berger13 Linear Derivative Internal Audit

Generated: `20260710T204002`

This is an internal derivative audit for the isolated berger13 13x10 research model. It is not Berger/XV-15 validation, not a handling-quality conclusion, and not nonlinear response validation. The representative points are finite operating points, not a full trim envelope.

Non-rotor aero and mass properties still use `betaMAvg = 0.5*(betaML + betaMR)`.

## Conditioning Diagnostics

The report includes raw A SVD/rank diagnostics, scaled A diagnostics using internal state scales, a dynamic submatrix diagnostic that removes structural heading/null columns, and B-column rank/norm checks. These are internal numerical health diagnostics, not validation or handling-quality pass/fail criteria.

The report also includes nullspace and effective condition diagnostics. These identify numerical null directions and linearized control dependencies only; they are not validation or modal classifications.

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

#### Nullspace / Effective Conditioning

- A nullity: 2
- A effective condition: 3.101040141619e+03
- dominant A null states: v1:psi|v|w|betaMR|betaML; v2:u|betaML|betaMR|w|v
- scaled A effective condition: 8.093606678254e+01
- reduced A nullity: 2
- reduced A effective condition: 1.129443007273e+03
- dominant reduced A null states: v1:v|phi|r|betaML|betaMR; v2:u|betaMR|betaML|w|theta
- B rank: 8
- B nullity: 2
- B effective condition: 4.123183256107e+04
- dominant B null controls: v1:aileron|diffCyclic|diffCollective|rudder|lateralCyclic; v2:rudder|lateralCyclic|diffCyclic|cyclicLong|aileron
- interpretation: A has 2 linearized nullspace direction(s); dominant state coordinates: v1:psi=1|v=1.76e-16|w=1.03e-16|betaMR=2.23e-17|betaML=2.22e-17; v2:u=1|betaML=0.0151|betaMR=0.015|w=0.0103|v=0.00344; scaled A has 2 linearized nullspace direction(s); dominant state coordinates: v1:psi=1|r=2.28e-16|phi=7.82e-17|v=2.21e-17|betaMR=1.81e-17; v2:betaML=0.639|betaMR=0.638|u=0.425|theta=0.0605|w=0.00437; reduced A has 2 linearized nullspace direction(s); dominant state coordinates: v1:v=0.932|phi=0.323|r=0.161|betaML=0.0143|betaMR=0.0143; v2:u=1|betaMR=0.0151|betaML=0.015|w=0.0103|theta=0.00142; B has 2 linearized nullspace direction(s); dominant control coordinates: v1:aileron=1|diffCyclic=0.00769|diffCollective=0.00213|rudder=0.00023|lateralCyclic=0.000183; v2:rudder=0.998|lateralCyclic=0.0531|diffCyclic=0.0452|cyclicLong=0.00297|aileron=0.000585; not validation/pass-fail criteria

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

#### Nullspace / Effective Conditioning

- A nullity: 2
- A effective condition: 1.762165925467e+04
- dominant A null states: v1:psi|v|w|theta|betaMR; v2:w|theta|betaMR|betaML|u
- scaled A effective condition: 1.442087929968e+02
- reduced A nullity: 2
- reduced A effective condition: 1.761729879375e+04
- dominant reduced A null states: v1:v|phi|r|betaMR|w; v2:w|theta|betaMR|betaML|u
- B rank: 8
- B nullity: 2
- B effective condition: 2.364308203090e+04
- dominant B null controls: v1:aileron|diffCyclic|diffCollective|rudder|lateralCyclic; v2:rudder|lateralCyclic|diffCyclic|aileron|diffCollective
- interpretation: A has 2 linearized nullspace direction(s); dominant state coordinates: v1:psi=1|v=4.25e-17|w=1.95e-17|theta=9.54e-18|betaMR=6.09e-18; v2:w=0.83|theta=0.408|betaMR=0.257|betaML=0.257|u=0.106; scaled A has 2 linearized nullspace direction(s); dominant state coordinates: v1:psi=1|theta=1.76e-16|betaML=1.1e-16|betaMR=1.09e-16|phi=5.93e-17; v2:theta=0.747|betaMR=0.47|betaML=0.469|w=0.0152|phi=0.00533; reduced A has 2 linearized nullspace direction(s); dominant state coordinates: v1:v=0.997|phi=0.0752|r=0.0184|betaMR=0.00408|w=0.00302; v2:w=0.831|theta=0.408|betaMR=0.257|betaML=0.257|u=0.106; B has 2 linearized nullspace direction(s); dominant control coordinates: v1:aileron=0.996|diffCyclic=0.0881|diffCollective=0.00857|rudder=0.00813|lateralCyclic=0.000344; v2:rudder=0.994|lateralCyclic=0.0912|diffCyclic=0.0619|aileron=0.0135|diffCollective=0.00458; not validation/pass-fail criteria

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

#### Nullspace / Effective Conditioning

- A nullity: 2
- A effective condition: 2.290804013476e+03
- dominant A null states: v1:psi|v|w|phi|betaML; v2:u|theta|w|v|betaML
- scaled A effective condition: 3.471545349384e+02
- reduced A nullity: 2
- reduced A effective condition: 1.197516148088e+03
- dominant reduced A null states: v1:v|phi|r|betaML|betaMR; v2:u|theta|w|betaMR|betaML
- B rank: 8
- B nullity: 2
- B effective condition: 7.536091665278e+03
- dominant B null controls: v1:aileron|diffCyclic|diffCollective|rudder|cyclicLong; v2:rudder|lateralCyclic|diffCollective|diffCyclic|aileron
- interpretation: A has 2 linearized nullspace direction(s); dominant state coordinates: v1:psi=1|v=1.99e-16|w=6.84e-17|phi=3.8e-17|betaML=3.57e-17; v2:u=1|theta=0.0146|w=0.00592|v=0.00314|betaML=0.00307; scaled A has 2 linearized nullspace direction(s); dominant state coordinates: v1:psi=1|phi=1.21e-16|betaMR=1.52e-17|betaML=1.41e-17|r=7.09e-18; v2:theta=0.801|u=0.549|betaML=0.168|betaMR=0.168|phi=0.0116; reduced A has 2 linearized nullspace direction(s); dominant state coordinates: v1:v=0.758|phi=0.649|r=0.0633|betaML=0.00212|betaMR=0.0021; v2:u=1|theta=0.0146|w=0.00592|betaMR=0.00306|betaML=0.00306; B has 2 linearized nullspace direction(s); dominant control coordinates: v1:aileron=0.831|diffCyclic=0.557|diffCollective=0.00614|rudder=0.000166|cyclicLong=3.37e-05; v2:rudder=0.922|lateralCyclic=0.314|diffCollective=0.209|diffCyclic=0.0725|aileron=0.0503; not validation/pass-fail criteria

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

#### Nullspace / Effective Conditioning

- A nullity: 2
- A effective condition: 1.665274928814e+04
- dominant A null states: v1:psi|v|phi|betaMR|theta; v2:v|u|phi|w|theta
- scaled A effective condition: 3.379729079107e+02
- reduced A nullity: 2
- reduced A effective condition: 1.462057349643e+04
- dominant reduced A null states: v1:v|phi|r|w|theta; v2:phi|u|r|v|w
- B rank: 8
- B nullity: 2
- B effective condition: 2.506269706721e+04
- dominant B null controls: v1:aileron|rudder|diffCyclic|lateralCyclic|elevator; v2:rudder|aileron|diffCyclic|lateralCyclic|cyclicLong
- interpretation: A has 2 linearized nullspace direction(s); dominant state coordinates: v1:psi=1|v=2.01e-14|phi=1.32e-16|betaMR=9.1e-17|theta=7.23e-17; v2:v=0.998|u=0.0683|phi=0.00899|w=0.00652|theta=0.0048; scaled A has 2 linearized nullspace direction(s); dominant state coordinates: v1:psi=1|v=2.9e-16|phi=1.96e-16|betaMR=1.32e-16|theta=9.04e-17; v2:v=0.668|phi=0.602|theta=0.322|betaMR=0.291|u=0.0457; reduced A has 2 linearized nullspace direction(s); dominant state coordinates: v1:v=0.991|phi=0.128|r=0.0261|w=0.0153|theta=0.00892; v2:phi=0.842|u=0.487|r=0.184|v=0.115|w=0.0612; B has 2 linearized nullspace direction(s); dominant control coordinates: v1:aileron=0.93|rudder=0.361|diffCyclic=0.0593|lateralCyclic=0.0353|elevator=0.00947; v2:rudder=0.925|aileron=0.356|diffCyclic=0.0992|lateralCyclic=0.0871|cyclicLong=0.0271; not validation/pass-fail criteria

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
