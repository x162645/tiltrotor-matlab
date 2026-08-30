# M1 Geometry Source Fidelity Audit

## Purpose

This audit closes the source-fidelity blocker on the Stage-1 M1-A radial-geometry attribution. It does not calibrate geometry to OARF data and does not select the lowest-error geometry as a new model identity.

The question is narrower: does the conclusion that source-informed radial geometry materially changes the scalar-C81 low-order hover prediction survive legitimate differences in how public XV-15 geometry is interpreted?

## Primary public source

NASA/TP-2004-212262 is used as the independent geometry source.

The report's rotor-model narrative states that the original XV-15 steel-blade rotor has an inboard aerodynamic section with 17-in chord at 0.12R, tapering linearly to 14-in chord at 0.25R, with 14-in chord from there to the tip. The same report's Appendix A separately supplies the CAMRAD II reference-model aerodynamic input `RPROP=[0,.1,.2,.3,1]`, `CHORD=[1.32125,1.32125,1.17375,1.16625,1.16625] ft`, and a 51-station `TWISTA` array on `RPROP=0:0.02:1.0`.

These two representations are not treated as interchangeable measured truth. The Appendix-A values are `NASA_REFERENCE_MODEL_INPUT`; the narrative planform is a source description of the original rotor. Neither is labelled OARF Run-15 measured geometry.

## Cases

Four cases were fixed before comparing performance:

1. `CURRENT_RECONSTRUCTION`: current M1-A chord, 17 in at 0.0875R to 14 in at 0.25R, plus the existing fifth-order twist representation.
2. `CURRENT_CHORD_DIRECT_TWISTA`: current chord plus direct interpolation of the published 51-point TWISTA table.
3. `TP_TEXT_CHORD_DIRECT_TWISTA`: narrative 17 in at 0.12R to 14 in at 0.25R, with 17 in transparently extended inward to the present 0.0875R integration boundary, plus direct TWISTA.
4. `TP_APPENDIX_A_CAMRAD_DIRECT_TWISTA`: Appendix-A CAMRAD CHORD/RPROP plus direct TWISTA.

No OARF or WADC error is used to choose, tune, or modify these cases.

## Solver identity gate

All four cases use the same M1-A scalar-C81 / global-momentum / Eq.(12) / first-harmonic-flapping solver.

The `CURRENT_RECONSTRUCTION` branch is fail-closed against the already formal Stage-1 scalar-C81 geometry result. MATLAB R2021a run `33289747465` reproduced the canonical M1-A metrics with maximum difference `0 pp` under the `1e-6 pp` gate.

## Formal MATLAB result

Workflow run: `33289747465`

Artifact: `9725590921`

Artifact SHA-256: `a4a65fa869d8cb29240f7ee1dee6e3128a89154923f99fb465612a9e4c04e6ac`

All four cases were physically converged at all six fixed 6--11 deg collective points.

| Geometry source interpretation | CT MAPE | CP MAPE | FM MAPE |
| --- | ---: | ---: | ---: |
| Current reconstruction | 33.9549% | 45.2392% | 4.4100% |
| Current chord + direct TWISTA | 32.4018% | 43.7198% | 3.9806% |
| TP text chord + direct TWISTA | 32.3694% | 43.6878% | 3.9778% |
| TP Appendix-A chord + direct TWISTA | 32.5002% | 43.8204% | 3.9868% |

Across all source interpretations, the total MAPE spread is only:

- CT: `1.5855 pp`
- CP: `1.5515 pp`
- FM: `0.4322 pp`

All four interpretations retain lower CT, CP and FM MAPE than the frozen Stage-1 `DIAG_SECTION` bridge (42.8716%, 51.1184%, 12.2221%). This comparison is used only as a robustness direction test, not as a geometry-selection objective.

## What causes the source sensitivity?

The current fifth-order twist representation differs from direct Appendix-A TWISTA, after both are anchored at 0.75R, by:

- ordinary RMS: about `0.244 deg`
- c*r^2 weighted RMS: about `0.268 deg`
- maximum absolute difference: about `0.567 deg`

Replacing only the current twist representation with direct TWISTA changes CT/CP/FＭ MAPE by approximately `-1.553 / -1.519 / -0.429 pp`.

By contrast, once direct TWISTA is held fixed, changing among the three chord interpretations produces only about `0.131 pp` CT-MAPE spread, `0.133 pp` CP-MAPE spread, and `0.009 pp` FM-MAPE spread.

The chord-source integrals are also close in the load-dominant outer blade region. Relative to the current reconstruction:

- TP-text active blade area is about `+0.374%`, but the c*r^2 and c*r^3 integrals change only about `+0.026%` and `+0.006%`.
- Appendix-A CAMRAD active blade area is about `-0.945%`, while c*r^2 and c*r^3 change only about `-0.099%` and `-0.050%`.

Therefore most of the observed source-fidelity sensitivity in this audit comes from the twist representation rather than from the alternative public chord interpretations.

## Scientific decision

`ROBUST_DIRECTION_GEOMETRY_CONTRIBUTION_SURVIVES_SOURCE_SEMANTICS_AUDIT`

The Stage-1 conclusion survives: moving from the reduced constant-chord/linear-twist representation to a source-informed radial geometry representation makes a material and directionally robust difference under the tested M1-A solver.

However, the prior wording `actual geometry` or `real geometry` is too strong. The scientifically defensible wording is:

> source-informed radial chord and nonlinear-twist representation

The audit does **not** prove that any one of the four mappings is the exact OARF Run-15 blade geometry. Direct TWISTA has a stronger source contract than the polynomial representation because it uses the published Appendix-A table directly, but its smaller OARF error is not used to retroactively replace the frozen M1 model used for WADC holdout evidence.

## Downstream consequence

This blocker does not require rollback of M1-A/B/C or the frozen WADC evidence package. The source-interpretation uncertainty is materially smaller than the M0-to-M1 discrepancy reduction and does not reverse the Stage-1 geometry-attribution direction.

The next unresolved physics-audit blocker is the strict-hover Eq.(12) limit audit.
