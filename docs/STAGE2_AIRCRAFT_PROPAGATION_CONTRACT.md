# Stage 2 Whole-Aircraft Propagation Contract

## Question

Does the rotor evidence improvement frozen as `M1_EVIDENCE_V1` materially change whole-aircraft trim, rotor/wing load allocation, linear dynamics, stability/control, or nacelle-dynamics conclusions relative to the permanent M0 production control?

## Fixed controls

- M0 production rotor and production whole-aircraft defaults are read-only.
- M1 rotor evidence identity is frozen by `docs/M1_EVIDENCE_FREEZE_GATE_20260830.md` as `M1_HOLDOUT_V1_GENERIC_CORRIGAN_N1`.
- No OARF/WADC retuning, empirical CT/CP gain, collective offset, new wake correction, or validation-error-selected parameter is allowed.
- The existing generic conceptual airframe remains unchanged between M0 and M1 runs.

## Forward-flight evidence boundary

`M1_HOLDOUT_V1_GENERIC_CORRIGAN_N1` was frozen and externally checked as a hover rotor identity. It does not itself constitute a validated forward-flight rotor implementation. Stage 2 therefore uses an analysis-only forward-flight propagation extension.

Before any aircraft delta is accepted, the extension must pass:

1. **M0 backend identity gate** — the analysis whole-aircraft M0 backend reproduces the production path at the same state/control/parameter point.
2. **M1 hover-limit identity gate** — at zero translational/body rate, helicopter nacelle angle, zero cyclic, and the same rotor-instance mapping, the forward-capable M1 implementation reproduces the frozen Stage-3 Corrigan `n=1` hover CT/CP/FM over 6–11 deg within a declared numerical tolerance.

A failed identity gate blocks aircraft interpretation and must not be bypassed by solver retuning.

## Control-coordinate contract

The whole-aircraft control coordinate remains the existing production collective command. For the M1 evidence-informed rotor instance, the same command is converted to a common physical 0.75R pitch reference before applying the frozen source-informed nonlinear twist distribution. Both commanded collective and resulting `theta75` must be reported.

## Initial operating points

Use the already frozen explicit-mode representative definitions:

- `B15_V020`: betaM = 15 deg, V = 20 m/s, helicopter-longitudinal definition;
- `B45_V035`: betaM = 45 deg, V = 35 m/s, conversion-longitudinal definition;
- `B75_V080`: betaM = 75 deg, V = 80 m/s, airplane-longitudinal definition.

No continuous conversion corridor is inferred from these three discrete points.

## First accepted observables

- trim credibility / physical support / residual;
- pitch attitude and aerodynamic angle;
- collective, theta75, longitudinal cyclic, elevator where used by the explicit trim definition;
- per-rotor thrust, torque/power, induced velocity and in-plane force;
- wing loads/slipstream quantities already exposed by the model;
- after trim closure: linear A/B matrices, eigenvalues, modal classification/participation and supported control-stability metrics.

## Claim boundary

Stage-2 results are **whole-aircraft propagation/sensitivity evidence on the repository's generic conceptual airframe**. They are not XV-15 full-aircraft validation, handling-quality certification, or proof that the hover-validated M1 rotor has independently validated forward-flight fidelity.
