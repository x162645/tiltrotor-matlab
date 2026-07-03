# Full-Angle Database Formal Rebuild

Date: 2026-07-03

This rebuild uses the standard NACA 64A223 coordinates generated from the PDAS/NASA TM-X-3069 6A method, not the `surrogate_v0` four-digit-like geometry.

## Dimensions

- alpha: -180 to 180 deg, 1 deg spacing
- Reynolds: 0.6e6, 1.0e6, 1.4e6
- Mach: 0, 0.10
- flap: 0, 20, 40, 50, 60 deg
- runtime interpolation: PCHIP in alpha within each slice, linear interpolation across Re, Mach and the supported symmetric plain-flap family
- grid outside policy: `P.wing.fullAngleOutOfRangePolicy = 'clamp'`, reported through lookup diagnostics

## Source Counts

| Source class | Rows | Share |
|---|---:|---:|
| BRIDGE_MODEL | 8604 | 79.4460% |
| TM88373_DIGITIZED_TEXT_CONSTRAINED | 930 | 8.5873% |
| ASSUMED_POSITIVE_DEEP_STALL_MIRROR_UNVALIDATED | 930 | 8.5873% |
| XFOIL | 299 | 2.7608% |
| PERIODIC_CLOSURE | 60 | 0.5540% |
| XFOIL_GRID_INTERPOLATED | 7 | 0.0646% |

The original formal XFOIL accepted file has 305 rows. Those rows include duplicated positive/negative sweep conditions, so the unique `(Re, Mach, flap, alpha)` accepted set contains 299 cells. The selected database carries a complete integer-alpha low-angle clean grid of 306 cells: 299 direct accepted unique cells plus 7 `XFOIL_GRID_INTERPOLATED` cells filled from accepted neighboring points. The 7 filled cells are listed in `validation/wing_full_angle/full_angle/xfoil_grid_fill_audit.csv`.

## Bridge Audit

Bridge rows are the dominant source class. The independent candidate audit in `validation/wing_full_angle/full_angle/bridge_candidate_summary.csv` compares:

- `current_selected`;
- `endpoint_pchip_candidate`;
- `flat_plate_reference_candidate`.

Maximum coefficient delta from the selected bridge in bridge-only regions is 1.925816 for the endpoint PCHIP candidate and 0.820028 for the flat-plate reference candidate. This is material in unsupported deep-stall intervals, so the database is suitable for the current limited-envelope full-angle structural validation but is not a final aerodynamic validation of all post-stall states.

## Limitations

TM-88373 curves are text-constrained digitization artifacts for the configurations actually used by the model. Page images, calibration, repeat digitization and overlays are saved under `data/wing_full_angle/tm88373_digitized`, but graphical point-picking from the scanned plots is not claimed. Positive deep-stall rows are explicitly marked `UNVALIDATED_POSITIVE_DEEP_STALL`.
