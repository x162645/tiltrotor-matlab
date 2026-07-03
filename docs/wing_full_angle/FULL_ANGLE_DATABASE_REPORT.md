# Full-Angle Database Formal Rebuild

Date: 2026-07-03

This rebuild uses the standard NACA 64A223 coordinates generated from the PDAS/NASA TM-X-3069 6A method, not the `surrogate_v0` four-digit-like geometry.

## Dimensions

- alpha: -180 to 180 deg, 1 deg spacing
- Reynolds: 0.6e6, 1.0e6, 1.4e6
- Mach: 0, 0.10
- flap: 0, 20, 40, 50, 60 deg

## Source Counts

{
  "PERIODIC_CLOSURE": 60,
  "BRIDGE_MODEL": 8604,
  "TM88373_DIGITIZED_TEXT_CONSTRAINED": 930,
  "XFOIL": 306,
  "ASSUMED_POSITIVE_DEEP_STALL_MIRROR_UNVALIDATED": 930
}

## Limitations

TM-88373 curves are text-constrained digitization artifacts for the configurations actually used by the model. Page images, calibration, repeat digitization and overlays are saved under `data/wing_full_angle/tm88373_digitized`, but graphical point-picking from the scanned plots is not claimed. Positive deep-stall rows are explicitly marked `UNVALIDATED_POSITIVE_DEEP_STALL`.
