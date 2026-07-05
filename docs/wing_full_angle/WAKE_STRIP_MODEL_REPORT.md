# Wake Strip Model Report

The wake strip model uses a source-traced rotor-axis projection:

- rotor hub position;
- rotor thrust-axis direction;
- disk-to-wing projection distance;
- wake radius at the wing plane;
- left/right independent wakes;
- true strip span-overlap coverage;
- local Re/Mach/dynamic-pressure coefficient lookup.

Traceability:

- `data/wing_full_angle/cr114614_wake_formula_extract.csv`
- `docs/wing_full_angle/CR114614_WAKE_EXTRACTION.md`
- `references/wing_full_angle/NASA_CR_176970.pdf`

The implemented geometry is a straight rotor-axis centerline with `Rwake = P.rotor.R * P.wing.fullAngleWakeContraction`. The default contraction value is 1.0 and is classified as an engineering assumption because no unique contraction curve has been extracted from the local source chain. The parameter remains user-adjustable and is not tuned to improve the 0-deg trim curve.

Focused MATLAB validation:

- rel12To48 = 7.706147818981e-16.
- rel24To48 = 8.788933112605e-16.
- rel48To96 = 3.813755800023e-16.
- dWakeForce = 4.899759254120e+03 N.
- nacelle-angle centerline movement: PASS.
- disk-wing distance diagnostic response: PASS.
- left/right induced-velocity asymmetry diagnostic/load response: PASS.
- sideslip finite local-flow diagnostics: PASS.

Gate interpretation: software geometry and strip integration pass focused tests; source traceability remains limited by the assumed contraction model.
