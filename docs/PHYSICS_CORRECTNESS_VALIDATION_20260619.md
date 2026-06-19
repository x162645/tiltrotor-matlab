# Physics Correctness Validation - 2026-06-19

## Context

- Branch: `audit/physics-and-correctness`
- Validation environment: MATLAB R2021a
- MATLAB path: `F:\matlab\R2021a\bin\matlab.exe`

## Results

### `run_physics_correctness_checks`

- `allPassed = 1`
- Runtime: approximately 6.232 s

### `run_all_checks`

- `allPassed = 1`
- Runtime: approximately 6.089 s

Included check results:

- `check_physical_sanity`: PASS
- `check_control_limits`: PASS
- `check_control_architecture`: PASS
- `check_flapping_model`: PASS
- `check_wing_normal_flow_blend`: PASS

## Notes

- Finite-value checks did not report NaN, Inf, or complex values.
- No mass, inertia, geometry, or aerodynamic parameters were changed to obtain PASS results.
- After the test bodies completed and printed PASS, MATLAB R2021a triggered an `output stream error` during batch shutdown.
- Final process exit code: `3`.
- No test assertion failed.
- No MATLAB process remained after completion.
- This validation only demonstrates internal consistency for the covered cases. It is not XV-15 aircraft validation and is not full-flight-envelope validation.

## Follow-up Validation: Applied Rotor Control Diagnostics

Branch: `audit/physics-and-correctness`

Change validated: `info.appliedControls(1:4)` now reports equivalent global rotor controls reconstructed from the clamped left/right rotor controls. `info.commandedControls` continues to preserve the original input vector, and `info.appliedRotorControls.left/right` continue to expose the side-specific clamped controls.

### `check_control_limits`

- Command: `check_control_limits`
- Test body result: PASS
- `report.allPassed = 1`
- Observed command wall time: approximately 16.2 s
- Added PASS coverage:
  - commanded controls preserved
  - upper conventional-surface limits applied
  - lower conventional-surface limits applied
  - total collective rotor limits applied
  - longitudinal cyclic rotor limits applied
  - differential collective reconstruction
  - differential cyclic reconstruction
  - applied rotor controls within limits
  - rotor equivalent controls match diagnostics
  - applied controls finite and real

### `run_physics_correctness_checks`

- Command: `run_physics_correctness_checks`
- Test body result: PASS
- `report.allPassed = 1`
- Observed command wall time: approximately 20.7 s
- Included summary:
  - Existing internal suite: PASS
  - Physical sanity: PASS
  - Control-limit behavior: PASS
  - Overall: PASS

### Shutdown Behavior

- In both runs, the test body completed and printed PASS before MATLAB shutdown.
- MATLAB R2021a again triggered `output stream error` during batch shutdown.
- Shell exit code observed by Codex: `1`.
- MATLAB error status reported in output: `0x00000003`.
- No test assertion failed before shutdown.
- This follow-up did not modify mass, inertia, geometry, aerodynamic parameters, rotor physics, control architecture, or coordinate definitions.
