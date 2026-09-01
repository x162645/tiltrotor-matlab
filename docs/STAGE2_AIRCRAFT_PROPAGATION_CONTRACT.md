# Stage 2 Whole-Aircraft Propagation Contract

## Question

Does the rotor evidence improvement frozen as `M1_EVIDENCE_V1` materially change whole-aircraft trim, rotor/wing load allocation, linear dynamics, stability/control, or nacelle-dynamics conclusions relative to the permanent M0 production control?

## Current phase decision — 2026-08-31

The temporary `B45 numerical closure` substage is closed. Stage 2 has formally returned to its original mainline:

`B15–B45–B75 whole-aircraft propagation -> paper closure`.

B45 is retained as a sufficiently diagnosed intermediate conversion case: the M1 credible equilibrium and supported control-effectiveness propagation are accepted, while incomplete full-state linearization is retained as an explicit limitation rather than pursued through further B45-only solver complexity.

See `docs/STAGE2_B45_NUMERICAL_CLOSURE_EXIT_20260831.md` for the frozen phase-exit decision and reopening rule.

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

## Three-case comparison gates — frozen before B15/B75 result inspection

The following gates apply identically to B15, B45 and B75. They are frozen before inspecting the new B15/B75 closure outputs so that result quality cannot change the acceptance rule.

### Trim gate

An operating point may enter a matched M0–M1 comparison only when the existing production trim credibility definition is satisfied, including:

- finite-real state and control solution;
- trim residual below the existing `P.trim.residualTolerance`;
- physical rotor convergence;
- `physicalBranchSupported = true`;
- all existing trim bounds satisfied and no active-limit solution admitted as a credible interior trim.

Branch-aware continuation may change only the numerical path used to reach the same fixed trim problem. It may not change model equations, physical parameters, tolerances, production iteration limits, trim bounds or trim/control DOFs.

### Fixed finite-difference contract

All accepted whole-aircraft numerical linearizations use the same predeclared central-difference probes already established by the B45 audit:

- states `[u v w p q r phi theta psi]`;
- controls `[collective diffCollective cyclicLong diffCyclicLong aileron elevator rudder]`;
- base state steps `[0.05 0.05 0.05 5e-4 5e-4 5e-4 5e-4 5e-4 5e-4]`;
- base control step `5e-4 rad` for every control coordinate;
- two numerical scales: `1.0` and `0.5`.

M1 perturbations may carry only converged left/right flap states from the accepted center or along a branch-tracked path to the exact same prescribed endpoint. A failed endpoint may not be moved, clipped, sign-flipped or replaced by a tuned perturbation.

### A-matrix / modal gate

A complete state Jacobian is admissible at a model/case point only if:

- the center trim is credible and the center EOM evaluation is physically supported;
- all `9/9` state columns have both plus and minus endpoints physically supported at both fixed step scales;
- both A matrices are finite and real.

Eigenvalues, spectral abscissa, unstable-root count, damping/frequency and modal-shift claims require this complete-A gate. If even one state column is blocked, no complete eigenstructure claim is admitted for that model/case point.

### B-matrix / control-effectiveness gate

A complete control Jacobian is admissible independently of the A gate when:

- the center trim is credible and the center EOM evaluation is physically supported;
- all `7/7` control columns have both plus and minus endpoints physically supported at both fixed step scales;
- both B matrices are finite and real.

Therefore a case such as the frozen B45 M1 result may support quantitative control-effectiveness propagation while its full modal comparison remains blocked.

### Partial-column gate

A single state or control derivative column may be retained as explicitly partial evidence only when the same named column is supported at both fixed scales for both compared model identities. A partial-column result must not be used to reconstruct or imply a complete A/B matrix, eigenstructure or handling-quality conclusion.

### Two-scale numerical sensitivity

For every complete A or B matrix, report the relative Frobenius difference between the `1.0` and `0.5` step scales. For retained individual columns, report the corresponding two-scale column difference. Step-size sensitivity is numerical-quality evidence, not a model calibration target: perturbation sizes are not changed after viewing M0–M1 differences.

Any M0–M1 physical interpretation must be presented together with its two-scale numerical sensitivity. A model-to-model shift that is of the same order as, or smaller than, its finite-difference step sensitivity is treated as numerically unresolved rather than as a physical M1 effect.

### Comparison hierarchy

The paper-facing evidence hierarchy is:

1. credible trim and equilibrium load/control allocation;
2. complete or explicitly partial B/control-effectiveness propagation;
3. complete A/stability derivatives;
4. eigenstructure/modal evolution only where the complete-A gate passes.

A blocked higher-level quantity does not invalidate lower-level quantities that independently pass their own gate, and does not justify case-specific solver retuning solely to complete a table.

## First accepted observables

- trim credibility / physical support / residual;
- pitch attitude and aerodynamic angle;
- collective, theta75, longitudinal cyclic, elevator where used by the explicit trim definition;
- per-rotor thrust, torque/power, induced velocity and in-plane force;
- wing loads/slipstream quantities already exposed by the model;
- after trim closure: linear A/B matrices, eigenvalues, modal classification/participation and supported control-stability metrics.

Only quantities that pass their declared credibility gate may enter M0–M1 comparison. A blocked quantity at one representative point does not justify case-specific retuning or expansion of numerical complexity solely to complete a table.

## Claim boundary

Stage-2 results are **whole-aircraft propagation/sensitivity evidence on the repository's generic conceptual airframe**. They are not XV-15 full-aircraft validation, handling-quality certification, or proof that the hover-validated M1 rotor has independently validated forward-flight fidelity.
