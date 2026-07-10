# Berger13 Conditioning Diagnostics

## Background

The berger13 linear derivative report introduced in PR #37 records raw
condition diagnostics for the isolated 13-state / 10-input research model. The
representative finite operating points currently report severe raw condition
numbers. A severe raw condition number does not automatically mean the A/B
matrices are constructed incorrectly.

The current full-state A matrix mixes translational velocities, angular rates,
Euler angles, nacelle angles, and nacelle rates. It also includes heading
invariance: the `psi` state can be a structural zero column at the representative
points. Those properties can make raw full-state conditioning severe even when
the derivative matrix is finite and the expected input/state wiring is active.

## Method

`analysis/berger13/diagnose_berger13_conditioning.m` reports:

- Raw A SVD, rank, condition number, near-zero singular values, and zero
  rows/columns.
- Scaled A SVD, rank, and condition number using internal state scales:
  `u/v/w = 100`, angular rates = `1`, Euler angles = `1`, nacelle angles = `1`,
  and nacelle rates = `1`.
- Dynamic-submatrix diagnostics after removing structural heading/null columns.
- B rank, B-column norms, near-zero control columns, and active control columns.

The state scaling is a numerical diagnostic convention only. It does not change
the model, the operating point, or the A/B matrices used by other workflows.

## Interpretation

- A zero `psi` column is consistent with heading invariance in the current
  state set and can make the full raw A matrix structurally singular.
- Mixed state units and magnitudes can amplify raw condition numbers.
- Representative finite operating points are not a trim envelope and should not
  be interpreted as handling-quality cases.
- Scaled and dynamic-submatrix diagnostics are internal numerical health checks.
  They are not external validation, flight-test validation, or handling-quality
  pass/fail criteria.

## Limitations

- No Berger 51-state reproduction is claimed.
- No Berger/XV-15 validation is claimed.
- No flight-test validation is claimed.
- No handling-quality validation is claimed.
- No nonlinear response validation is included.
- The diagnostics do not modify model equations, parameters, controls, or
  default GUI behavior.
