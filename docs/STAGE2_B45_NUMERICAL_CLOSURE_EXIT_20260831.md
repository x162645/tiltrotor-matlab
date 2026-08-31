# Stage 2 B45 Numerical-Closure Exit Decision

Date: 2026-08-31

Status: **B45 numerical-closure substage closed; Stage 2 returns to B15–B45–B75 whole-aircraft propagation and paper closure.**

## Strategic context

The project follows the three-step research strategy:

1. **M0 baseline validation** — freeze the generic low-order production core, validate without tuning it to XV-15/OARF error, and use mismatch to define model-form limitations and credible scope.
2. **M1 physics enhancement** — add only source- and physics-supported rotor-model enhancements, with no inverse tuning to OARF/WADC CT/CP/FM error and no winner selection by minimum validation MAPE.
3. **Paper closure** — propagate the frozen M0/M1 rotor-model difference into matched whole-aircraft trim, linear dynamics, stability and control-effectiveness comparisons, then establish a mechanism/evidence chain.

The B45 numerical work was a temporary Stage-2 diagnostic branch needed to determine whether the initially failed M1 conversion-regime trim represented physical/model failure or numerical path/branch failure. It was not intended to become a new project objective.

## B45 closure result

### Credible equilibrium: PASS

The final adaptive-path/branch-aware continuation recovered a credible M1 B45_V035 equilibrium without changing the physical model, physical parameters, trim tolerance, iteration limits, trim bounds, control bounds, or trim/control degrees of freedom.

Final accepted M1 B45 values include:

- residual norm: `6.85989567235717e-05`;
- trim residual tolerance: `0.005`;
- `physicalConverged = true`;
- `physicalBranchSupported = true`;
- `credible = true`;
- minimum bound margin: approximately `0.131719`.

Therefore the original B45 trim failure is classified as a **numerical solver/path/branch-tracking failure, not demonstrated physical no-solution or model-form failure**.

This conclusion is frozen. Earlier failed/intermediate B45 trim tables must not override the final continuation result.

### Local control linearization: PASS

At the credible B45 equilibrium, the matched M1 control Jacobian supports all `7/7` control columns at both prescribed finite-difference scales. The two-scale relative B-matrix Frobenius difference is approximately `3.08e-05`, indicating strong numerical repeatability for the supported control-effectiveness comparison.

The B45 evidence therefore supports the claim that the frozen M1 rotor-physics change can propagate into whole-aircraft control effectiveness on the generic conceptual airframe.

### Full state linearization: PARTIAL / BLOCKED

The branch-tracked fixed-endpoint audit supports `8/9` state columns at both prescribed finite-difference scales, not `9/9`.

The unresolved failures are localized to translational-velocity perturbation directions and terminate through flap-closure nonconvergence (`FlapNotConverged`). The failing direction changes with finite-difference scale, while the remaining common supported state columns are highly repeatable.

Accordingly:

- B45 trim credibility is accepted;
- B45 control Jacobian evidence is accepted;
- a complete M1 B45 A matrix is not accepted;
- M1 B45 eigenstructure, modal damping/frequency shifts, and full M0–M1 modal propagation are **not claimed**.

The unresolved state-linearization limitation is retained as an explicit numerical/model-interface limitation. It is not reclassified as a new physical "support-domain" dimension.

## Exit rule

No additional B45-only solver or continuation complexity will be added solely to force `8/9` state columns to become `9/9`.

B45-specific numerical work may be reopened only if at least one of the following occurs:

1. B15 and/or B75 expose the same failure mode, indicating a shared Stage-2 linearization-infrastructure problem;
2. a later paper-critical comparison requires an unresolved B45 quantity and no scientifically defensible partial comparison is possible;
3. new evidence demonstrates that the present B45 limitation changes the interpretation of already accepted trim or control-effectiveness results.

Otherwise the present B45 result is sufficient for Stage-2 decision-making.

## Stage-2 mainline resumed

The active research question returns to the original propagation contract:

> How does the frozen M0-to-M1 rotor-physics difference propagate across representative nacelle/flight regimes into whole-aircraft equilibrium, load allocation, stability derivatives, modal behavior, and control effectiveness?

The representative matched set remains:

- `B15_V020` — helicopter-longitudinal regime;
- `B45_V035` — conversion-longitudinal regime;
- `B75_V080` — airplane-longitudinal regime.

The next work package is therefore:

1. close credible M1 trims for B15 and B75 using the same no-retuning credibility principles established through B45;
2. create the matched B15–B45–B75 trim comparison;
3. run the same fixed, two-scale A/B audit at each credible point without adding case-specific complexity in advance;
4. compare only quantities that pass the declared credibility gates;
5. examine nacelle-regime evolution of trim, rotor/airframe load allocation, stability derivatives, control derivatives, and modal quantities where complete matrices are credible;
6. connect the observed whole-aircraft changes back to the frozen M1 rotor-physics mechanisms and the rotor-level OARF/WADC evidence;
7. convert the resulting evidence chain into the paper's results, discussion, limitations, and claim boundaries.

## Claim boundary

This decision does not promote Stage-2 results to XV-15 full-aircraft validation. The airframe remains the repository's generic conceptual aircraft, and the M1 forward-flight implementation remains an analysis-only propagation extension of the hover-evidence identity.

The scientific objective is **mechanism-based whole-aircraft propagation/sensitivity evidence**, not fitting or certifying a particular XV-15 conversion trajectory.

## Formal phase decision

**EXIT:** `B45 numerical closure`

**ENTER/RESUME:** `B15–B45–B75 whole-aircraft propagation -> paper closure`

B45 is henceforth treated as a sufficiently diagnosed intermediate conversion case: credible equilibrium and control-effectiveness propagation are accepted; incomplete full-state linearization is retained transparently as a bounded limitation rather than pursued as a standalone optimization target.
