# CODEX_TASK.md

STATUS: COMPLETE / HOLD

Branch: `audit/physics-and-correctness`

Draft PR: #1

Latest completed task: fixed `info.appliedControls` rotor-control diagnostic semantics so elements 1:4 are reconstructed from the clamped left/right rotor controls, and extended `check_control_limits` to cover rotor control saturation and diagnostic consistency.

Validation:

- `check_control_limits`: test body PASS, `report.allPassed = 1`.
- `run_physics_correctness_checks`: test body PASS, `report.allPassed = 1`.
- MATLAB R2021a still reports `output stream error` during batch shutdown after PASS output, with MATLAB exit status `0x00000003`.

Hold conditions before user or ChatGPT updates this file:

- Do not modify model behavior beyond the completed diagnostic fix.
- Do not modify parameters.
- Do not run broad scans.
- Do not enter the next phase.
- Do not merge PR #1.
