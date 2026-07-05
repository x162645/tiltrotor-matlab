# CR-114614 Wake Extraction

Input: `references/wing_full_angle/NASA_CR_114614_source_verified_technical_extract_NOT_FACSIMILE.pdf`

Verification record: `data/wing_full_angle/local_reference_zip_manifest.csv`

The local CR-114614 input is a source-verified technical extract from the user-provided package, not the 268-page original facsimile. It passed local checks for PDF header, nonzero size, page count, SHA256, title/report match and text extraction. It is used here for model-structure and formula traceability; it is not used for graphical curve digitization.

## Adopted Terms

- Left and right rotor wakes are treated independently.
- Wake-covered and free strip areas call the same `CL/CD/Cm(alpha,Re,Mach,flapDeg)` database.
- Region differences are only local velocity, angle of attack, Reynolds number, Mach number, dynamic pressure, covered area and moment arm.
- Local dynamic pressure follows `q = 0.5*rho*|Vlocal|^2`.
- Wake coverage uses rotor hub position, rotor-axis direction, disk-to-wing projection distance, wake radius at the wing plane and strip area overlap.
- Model 301 empirical induced-velocity constants are not copied; the current rotor model's induced velocity vector is used.

## Implementation Map

| Extracted item | Implementation |
|-|-|
| left/right wake separation | `model/wing/wing_wake_coverage.m` |
| wake centerline and disk-wing distance | `model/wing/wing_wake_coverage.m` |
| immersed strip area | `model/wing/wing_wake_coverage.m`, `model/wing/wing_integrate_strips.m` |
| local alpha, Re, Mach and dynamic pressure | `model/wing/wing_local_flow.m` |
| common coefficient law | `model/wing/wing_full_angle_lookup.m` |

Detailed row-level extraction is saved in `data/wing_full_angle/cr114614_wake_formula_extract.csv`.
