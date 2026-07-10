# External Audit Plan

## Phase A: Field Map

This PR performs Phase A only. It creates a document-level field map for NUAA /
Berger comparison preparation and records which quantities are direct, trend,
partial, sign-required, not comparable, out of scope, or source-required.

Phase A does not change model equations, parameters, controls, default behavior,
or GUI default behavior. It is not validation and not handling-quality validation.

## Phase B: Source Freeze / Digitization

Freeze external sources before any numerical comparison:

- NUAA figures first.
- Berger figures second.
- Do not commit large PDFs unless the project explicitly allows them.
- Prefer small digitized CSV files, a README, and provenance metadata.
- Record source file name, figure/table number, page number, original units,
  digitization tool, digitization date, and reviewer.

Recommended source staging:

```text
validation/external_sources/<source_name>/
```

## Phase C: Internal Script Mapping

Later scripts should read current model reports and digitized CSVs. They should
not change the model. They should output comparison Markdown/CSV artifacts with
field-by-field classification.

Candidate internal inputs:

- `validation/berger13_linear_derivatives/<timestamp>/`
- `validation/berger13_independent_nacelle_loads/<timestamp>/`
- future digitized NUAA trim CSVs
- future digitized Berger derivative/control-allocation CSVs

## Phase D: Comparison Classification

Every comparison row must carry one classification:

- `DIRECT_COMPARABLE`
- `TREND_COMPARABLE`
- `PARTIAL_COMPARABLE`
- `SIGN_CONVENTION_REQUIRED`
- `NOT_COMPARABLE_CURRENT_MODEL`
- `OUT_OF_SCOPE_CURRENT_PHASE`
- `SOURCE_REQUIRED`

The classification must be visible in the generated report. A trend match is
not a validation pass/fail result.

## Phase E: Review Gate

Before a figure enters a formal comparison workflow, the user should confirm:

- The source file is the intended source.
- The plotted variables and units are known.
- Coordinate and control signs have been audited.
- The internal field is compatible enough for the selected classification.
- The workflow is not using comparison results to tune parameters.

Until that review gate is passed, do not run broad fitting, do not tune
parameters, and do not claim external agreement.

## Risk Register

| Risk | Impact | Control |
|-|-|-|
| Nacelle angle convention mismatch | Reverses helicopter/airplane interpretation. | Audit NUAA `betaM`, Berger `delta_nac`, and internal `betaM` before comparison. |
| Control sign mismatch | Can flip derivative trends. | Map every control sign before pass/fail language. |
| Unit mismatch | Can create false scale disagreement. | Record deg/rad, m/s/knots/ft/s, dimensional/nondimensional status. |
| State dimension mismatch | Makes direct matrix comparison invalid. | Compare only mapped rows/columns and mark partial comparability. |
| Closed-loop versus bare-airframe mismatch | Can make handling-quality or allocation comparison invalid. | Keep closed-loop claims out of current phase. |
| HeliUM versus conceptual component model mismatch | Can overstate Berger comparability. | State that berger13 is a research scaffold, not Berger 51-state HeliUM. |
| Non-trim finite operating point versus trim data mismatch | Can invalidate eigenvalue/derivative conclusions. | Require trim-point equivalence before modal comparison. |
| Figure digitization uncertainty | Can create false numerical precision. | Store digitization provenance and uncertainty. |

## Stop Rules

- If fields are not comparable, do not force a numerical comparison.
- If sign convention is not confirmed, do not give trend pass/fail results.
- If unit conversion is incomplete, do not compare magnitudes.
- If the source figure/table is absent, mark `SOURCE_REQUIRED`.
- If closed-loop control is required, do not claim handling-quality comparison
  from a bare-airframe model.
- If a comparison would require nonlinear doublet or pilot-task simulation,
  keep it out of the current phase.

## Explicit Non-Claims

- This plan does not validate the model.
- This plan does not complete NUAA validation.
- This plan does not complete Berger/XV-15 validation.
- This plan does not reproduce Berger 51-state HeliUM.
- This plan does not verify handling qualities.
- This plan does not connect berger13 to the GUI default path.
