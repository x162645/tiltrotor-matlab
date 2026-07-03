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

Focused MATLAB validation:

- rel12To48 = 6.797920253345e-16.
- rel24To48 = 1.107712450503e-15.
- dWakeForce = 4.903325704935e+03 N.
- PASS.
