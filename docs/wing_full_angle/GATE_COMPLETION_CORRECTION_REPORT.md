# Full Wing Model Gate Completion Correction Report

Date: 2026-07-03

## Source Status

- NASA CR-114614 is represented by a user-provided local source-verified technical extract, not the original 268-page facsimile.
- NASA TM-X-3069, NASA TM-4741 and NACA TR-903 were verified locally and support the NACA 6/6A coordinate audit.
- NACA TN-4322 local acquisition produced a non-PDF response. NASA TR R-84 is retained only as a secondary source; it is not required for the selected standard NACA 64A223 route.

## Surrogate Archive

The existing `naca64a223_surrogate.dat`, its XFOIL outputs, selected full-angle database and validation artifacts are archived under `data/wing_full_angle/surrogate_v0` and `validation/wing_full_angle/surrogate_v0`.

These artifacts are retained for comparison only. They are marked `PROVISIONAL_SURROGATE_V0_DO_NOT_USE_FOR_FINAL_PASS` and cannot support a final gate by themselves.

## Code Corrections

- `wing_full_angle_lookup` now accepts `alpha, Re, Mach, flapDeg, P`.
- The lookup now uses PCHIP in alpha and linear interpolation across Re, Mach and supported symmetric plain-flap dimensions.
- `wing_local_flow` computes local Reynolds number and Mach number from the strip velocity and chord.
- The full-angle path no longer adds legacy linear aileron lift or moment increments outside the database.
- The full-angle path explicitly labels differential aileron aerodynamics as unmodeled because the local source chain only supports symmetric plain flaps.
- `wing_wake_coverage` uses rotor hub position, rotor axis, disk-wing distance, projected wake centerline, wake radius/contraction, left/right independent wakes and strip overlap area.

## Gate Result

`FULL_WING_MODEL_GATE=READY_FOR_LIMITED_ENVELOPE_USE`

The branch passes software-architecture, legacy-safety, multidimensional-lookup and regression gates while keeping the legacy model as the default. It does not claim final all-angle physical validation because TM-88373 data remain text-constrained, the bridge model materially affects unsupported deep-stall intervals, differential aileron aerodynamics are not sourced, and wake contraction remains an engineering assumption.
