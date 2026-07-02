# Full Wing Model Gate Completion Correction Report

Date: 2026-07-02

## Source Status

- NASA CR-114614 was verified on the official NTRS citation page and the official PDF endpoint, but local direct download still returned HTTP 404 JSON during scripted retries. The PDF is therefore not promoted as a local verified artifact in this commit.
- NASA TM-X-3069, NASA TM-4741 and NACA TR-903 were downloaded as valid PDFs and text-extracted for the NACA 6/6A coordinate audit.
- NACA TN-4322 local acquisition produced a non-PDF response and NASA TR R-84 remains locally readable only as a damaged PDF stream. They are not used as authoritative inputs.

## Surrogate Archive

The existing `naca64a223_surrogate.dat`, its XFOIL outputs, selected full-angle database and validation artifacts are archived under `data/wing_full_angle/surrogate_v0` and `validation/wing_full_angle/surrogate_v0`.

These artifacts are retained for comparison only. They are marked `PROVISIONAL_SURROGATE_V0_DO_NOT_USE_FOR_FINAL_PASS` and cannot support `FULL_WING_MODEL_GATE=PASS`.

## Code Corrections

- `wing_full_angle_lookup` now accepts `alpha, Re, Mach, flapDeg, P` and reports whether dimensional reduction is active.
- `wing_local_flow` computes local Reynolds number and Mach number from the strip velocity and chord.
- The full-angle path no longer adds legacy linear aileron lift or moment increments outside the database.
- `wing_wake_coverage` now uses rotor hub position, rotor axis, disk-wing distance, projected wake centerline, wake radius/contraction, left/right independent wakes and strip overlap area.

## Gate Result

`FULL_WING_MODEL_GATE=PARTIAL`

The branch is improved structurally but remains blocked from PASS by missing final NACA 64A223 coordinates, unavailable local CR-114614 extraction, incomplete TM-88373 curve digitization, and an alpha-only provisional database.
