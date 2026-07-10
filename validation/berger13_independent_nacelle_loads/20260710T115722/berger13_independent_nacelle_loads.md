# Berger13 Independent Nacelle Loads

Generated: `20260710T115722`

Independent left/right rotor loads are implemented for the berger13 research path. Non-rotor aero still uses `betaMAvg = 0.5*(betaML + betaMR)`.

This report is not Berger/XV-15 validation and does not make a handling-quality conclusion.

## Symmetric Case

- betaML: 1.57079632679 rad
- betaMR: 1.57079632679 rad
- first 9 derivative norm difference vs legacy opt-in: 0.000000000000e+00

## Asymmetric Case

- betaML: 1.3962634016 rad
- betaMR: 1.57079632679 rad
- independent vs betaMAvg-only force difference norm: 7.018508229299e+02
- independent vs betaMAvg-only moment difference norm: 3.616493074973e+04
- rotorLeft betaMUsed: 1.3962634016 rad
- rotorRight betaMUsed: 1.57079632679 rad
- usedIndependentRotorAngles: true
- usedAverageNonRotorAero: true

## Linearization

- A13 size: 13 x 13
- B13 size: 13 x 10
- norm(A13(1:9,10)): 6.919195470588e+00
- norm(A13(1:9,11)): 6.907992387505e+00
- norm(A13(4:6,10)-A13(4:6,11)): 1.193653666868e+01
- B13(12,9): 2.000000000000e-03
- B13(13,10): 2.000000000000e-03
