# Stage 2 Three-Case Mechanism Hypotheses — 2026-08-31

This note is frozen before inspection of the new B15/B75 trim-closure outputs. Its purpose is to prevent post-hoc mechanism storytelling after the three representative operating points are available.

## Evidence boundary

The hypotheses below concern **whole-aircraft propagation/sensitivity on the repository generic conceptual airframe**. They are not XV-15 full-aircraft validation claims and they do not upgrade the frozen hover-supported M1 rotor identity into independently validated forward-flight fidelity.

No hypothesis may be used to retune M1, alter a trim definition, change a finite-difference endpoint, or select a numerical path because it gives the expected sign.

## H1 — equilibrium control demand responds to frozen rotor-physics propagation

If the frozen M1 rotor physics produces greater useful rotor force/moment per common physical command than M0 on a supported forward-flight branch, the matched equilibrium should generally move toward lower rotor control demand, most visibly in collective and/or longitudinal cyclic. If the sign is reversed, the result is retained and explained through local inflow, force orientation, trim coupling and airframe load sharing rather than tuned away.

The already accepted B45 equilibrium shift provides one observed anchor, not a calibration target: M1 required lower collective magnitude and less-negative longitudinal cyclic/elevator than the matched M0 B45 trim.

## H2 — regime dependence is expected, monotonic nacelle-angle behavior is not assumed

B15, B45 and B75 are three discrete representative regimes. The M0-to-M1 propagation delta is allowed to vary in sign and magnitude between them. No monotonic interpolation with nacelle angle is assumed from only three points.

The paper should therefore compare regime-specific mechanisms first and describe any apparent cross-regime trend only after each point passes its own credibility gate.

## H3 — load allocation mediates trim changes

Changes in collective, cyclic, pitch attitude or elevator are not interpreted in isolation. A credible mechanism requires consistency with the corresponding rotor thrust/in-plane force/torque or power and with the wing/airframe loads exposed by the existing model.

A control shift without a corresponding physically coherent load-allocation shift is treated as incomplete mechanism evidence.

## H4 — rotor-control derivatives should be the most direct propagation channel

The frozen M1 change enters through the rotor model, so the most direct local dynamic effect is expected in rotor-mediated B-matrix columns such as collective, differential collective, longitudinal cyclic and differential longitudinal cyclic. Airframe-surface columns may also change because the equilibrium point and rotor-airframe coupling change, but such changes are a secondary propagation pathway rather than direct modification of the airframe model.

This is a testable ordering expectation, not a required result.

## H5 — trim/control evidence can remain publishable when full modal evidence is blocked

A case may pass credible trim and complete B/control-effectiveness gates while failing the complete-A gate because one or more state perturbations cannot remain on a supported rotor branch. Such a case still contributes lower-level propagation evidence under the frozen comparison hierarchy; it must not be represented as having a complete eigenstructure result.

B45 is the current concrete example: credible M1 trim and 7/7 control columns are accepted, while the full 9-state M1 Jacobian remains incomplete.

## H6 — numerical path sensitivity is evidence about the solver, not automatically the physics

If the same fixed physical endpoint can be reached or not reached depending on initialization/path while the endpoint definition itself is unchanged, the discrepancy is treated first as numerical basin/branch-tracking evidence. It becomes evidence for physical/model unsupportedness only when supported-path attempts fail in a way that is reproducible and not explained by solver-path dependence.

This rule applies identically to B15, B45 and B75 and does not create a separate numerical-support-domain model dimension.

## Paper-facing falsifiability rule

For every accepted mechanism statement, retain both:

1. the predicted/expected propagation pathway from the frozen M1 rotor change; and
2. the actual observed trim/load/derivative evidence, including sign reversals, blocked quantities and numerical uncertainty.

If the observed evidence contradicts one of these hypotheses, the hypothesis is rejected or narrowed. The model is not retuned to restore the expected narrative.
