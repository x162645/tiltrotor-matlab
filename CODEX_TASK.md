# CODEX_TASK.md

STATUS: ACTIVE / BERGER13 PR3 COMMANDED ACTUATORS AND INDEPENDENT WING / 2026-07-22

## Version contract

- Stage: PR3 - independent angle-command actuators, left/right wing slipstream loads, and parameterized moving-component properties.
- Base branch: `codex/berger13-pr2-formal-trim`.
- Base SHA: `b96f357b142c4e1cd8c19b9eb39fd49fb74fe94b`.
- Head branch: `codex/berger13-pr3-commanded-actuator-independent-wing`.
- PR base after push: `codex/berger13-pr2-formal-trim`.
- PR must remain Draft and must not be merged automatically.

## Allowed scope

- `CODEX_TASK.md`, `model/berger13/`, `analysis/berger13/`, Berger13-focused tests, `tests/run_all_checks.m`, and PR3 evidence documentation.
- Add a distinct angle-command EOM and input-name/unit helpers; retain the torque EOM unchanged.
- Add namespace-local independent wing-region loads, symmetric/differential mass-property parameterization, actuator faults, and command-interface trim/linearization.

## Prohibited scope

- No reinterpretation of PR1 input 9/10, no changes to the torque-interface names/order, and no changes to legacy defaults or production `model/wing_model.m`.
- No parameter tuning, no invented reference values, no full-angle wing default, no Berger 51-state or XV-15 validation claim.
- No high-order transmission terms without a derivable equation and declared parameters.

## Equations and physical boundary

- Command interface inputs 9/10 are `betaMLCommand`, `betaMRCommand` in a distinct function.
- Nominal actuator: `betaDDot_i=omegaN_i^2*(betaCommand_i-beta_i)-2*zeta_i*omegaN_i*betaDot_i`, followed by observable angle, rate, acceleration, and internal-torque limits.
- Independent left/right wing loads use each side's nacelle angle, rotor induced velocity, local rigid-body velocity, area partition, aerodynamic center, and `cross(r,F)` moment.
- Parameterized moving components use `rCG=sum(m_i*r_i)/sum(m_i)` and the parallel-axis theorem. Placeholder mass/inertia values remain research assumptions.
- Reliable gyroscopic additions are limited to terms derivable from configured angular momentum and nacelle tilt rate. Unparameterized transmission and moving-mass acceleration terms remain explicit limitations.

## Parameter sources

- Use only `REFERENCE`, `DIGITIZED`, `DERIVED`, `ASSUMED_MODEL_PARAMETER`, `RESEARCH_PLACEHOLDER`, or `UNKNOWN`.
- Existing and new bandwidth, damping, delay, acceleration, torque, moving mass, and component inertia values default to `RESEARCH_PLACEHOLDER` or `ASSUMED_MODEL_PARAMETER`; sensitivity ranges must accompany their use.
- Berger PDF 95 (printed 60), Section 2.1.3.3 supports the command-to-torque PID structure but does not supply this project's bandwidth or damping.

## Required validation

- Pre-change and post-change MATLAB R2021a `run_all_checks`.
- Focused actuator step, angle/rate/acceleration/torque limits, asymmetric parameters, delay, stuck, frozen command, rate degradation, independent-wing mirror/antisymmetry, betaDiff zero, CG/inertia symmetry, command trim, command A/B, torque-interface preservation, PR1/PR2 and legacy regression.
- `checkcode` on every changed MATLAB file and explicit finite-real/NaN/Inf/complex checks.
- Record commands, elapsed times, assumptions, omitted couplings, and limitations in `docs/BERGER13_PR3_EVIDENCE.md`.

## Stop conditions

Stop only under the user-defined environment, MATLAB, reference/repository, unrepairable legacy-regression, invented-data, or permission blockers. Missing high-order parameters are documented and explored parametrically; they are not blockers.

