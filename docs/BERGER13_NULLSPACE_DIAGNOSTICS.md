# Berger13 Nullspace Diagnostics

## Background

The berger13 conditioning report shows that the representative 13x10
linearizations can have singular or severely conditioned full-state A matrices
and B matrices with rank below the 10 input columns. This document records the
follow-on internal diagnostic used to identify the numerical null directions and
linearized input dependencies behind those rank results.

These diagnostics are for internal numerical health and model-wiring review.
They are not Berger validation, not XV-15 validation, not flight-test
validation, and not handling-quality pass/fail criteria.

## Method

`analysis/berger13/diagnose_berger13_nullspace.m` reports:

- Full A rank, nullity, SVD tolerance, singular values, and effective
  condition.
- Dominant state coordinates in each right-nullspace vector of A.
- Scaled-A effective condition and dominant scaled-coordinate null entries.
- Reduced-state A diagnostics using the same dynamic-state index convention as
  `diagnose_berger13_conditioning`.
- B rank, nullity, SVD tolerance, singular values, effective condition, and
  dominant control coordinates in each right-nullspace vector of B.

Effective condition is computed from singular values above the diagnostic SVD
tolerance. Singular values at or below the tolerance are treated as numerical
null directions and are excluded from the effective-condition ratio.

## Interpretation Principles

- A dominant entry in a null vector identifies a numerical coordinate in a
  linearized nullspace direction. It is not a modal classification.
- The full A nullspace can include the heading-invariance direction already
  indicated by the zero `psi` column.
- The reduced-state diagnostic removes structural heading/null columns only for
  interpretation. It does not change the model or the A/B matrices.
- B nullspace vectors identify linearized control-column dependencies at the
  representative finite operating point. They do not prove that any control is
  physically redundant outside that point.
- Severe or infinite raw conditioning is reported as a numerical diagnostic,
  not as a validation failure by itself.

## Limitations

- No model equations are changed.
- No parameters are changed.
- No default legacy or GUI path is changed.
- No nonlinear doublet workflow is included.
- No Berger 51-state reproduction is claimed.
- No Berger/XV-15 derivative validation is claimed.
- No flight-test or handling-quality validation is claimed.
