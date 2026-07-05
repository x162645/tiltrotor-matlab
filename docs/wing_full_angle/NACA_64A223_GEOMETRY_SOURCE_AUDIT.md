# NACA 64A223 Geometry Source Audit

Date: 2026-07-03

## Acquired Sources

| Source | Local status | Use |
|-|-|-|
| NASA TM-X-3069 | Local ZIP verified PDF | Primary NACA 6/6A ordinate-program route. |
| NASA TM-4741 | Local ZIP verified PDF | Secondary ordinate-program source. |
| NACA TR-903 | Local ZIP verified PDF | Published 6A validation tables. |
| PDAS AIRFOLS/BROOKS.FOR | Archived under `references/wing_full_angle/naca_geometry/pdas_airfols/` | Public implementation containing 64A table arrays and CAL6SF/ML6S logic. |

## Result

The branch now contains a traceable standard NACA 64A223 coordinate set:

- Generator: `tools/wing_full_angle/generate_naca64a223_pdas.py`.
- Coordinates: `data/wing_full_angle/airfoils/naca64a223_standard_pdas.dat`.
- Validation: `data/wing_full_angle/naca64a223_pdas_validation.csv`.
- Geometry checks: `data/wing_full_angle/naca64a223_standard_geometry_checks.csv`.

Validation summary:

| Section | RMS error | Max error | Status |
|-|-:|-:|-|
| NACA 64A010 | 5.6475e-05 | 2.0998e-04 | PASS |
| NACA 64A210 | 1.2788e-04 | 7.9802e-04 | PASS |
| NACA 64A410 | 8.6625e-04 | 6.0663e-03 | REVIEW |

Generated NACA 64A223 geometry:

- point count = 801;
- max thickness ratio = 0.230016;
- max thickness x/c = 0.378240;
- max camber = 0.013310;
- trailing-edge gap = 1.1384e-07 chord;
- leading edge closed = true;
- self-intersection check = `PASS_MONOTONE_SURFACE_X`;
- XFOIL `LOAD/PANE` = PASS.

## Gate Decision

`AIRFOIL_GEOMETRY = PASS`

The model claims standard NACA 64A223 only. The exact XV-15 `NACA 64A223 Modified` geometry remains unrecovered and is not part of the current model claim. The old surrogate geometry remains archived under `data/wing_full_angle/surrogate_v0` and is not used for final gate evidence.
