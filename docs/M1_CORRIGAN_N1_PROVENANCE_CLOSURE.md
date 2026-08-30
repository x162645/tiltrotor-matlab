# M1 Corrigan n=1 Provenance Closure

## Purpose

This closure corrects the evidence identity of the Stage-3 `CORRIGAN_GENERIC_N1` case without changing its numerical model definition.

The Corrigan/Koning rotational-stall-delay form remains

`K_L = [1.291 (c/r)^0.0775]^n`.

Koning's XV-15 discussion supports a range of exponent values and a published XV-15/OARF-correlated `n=1.8` case. It does not establish `n=1` as a unique or universal literature default.

Therefore `n=1` is retained only as a predeclared in-range low-order model-form assumption that was not selected from the current OARF CT/CP/FM targets.

## Corrected evidence roles

- `OFF`: `M1_B_RIGID_REFERENCE`
- `CORRIGAN_GENERIC_N1`: `M1_E_PREDECLARED_IN_RANGE_CORRIGAN_N1_MODEL_FORM_ASSUMPTION`
- `KONING_XV15_N1P8`: `M1_E_PUBLISHED_XV15_CORRELATION_REPLICATION`

The independence labels remain:

- `n=1`: `NOT_SELECTED_FROM_CURRENT_OARF_TARGETS`
- `n=1.8`: `NONINDEPENDENT_XV15_OARF_CORRELATED_VARIANT`

No exponent sweep, OARF target optimization, collective offset, CT gain or CP gain is introduced.

## Formal MATLAB rerun

The corrected Stage-3 runner was re-executed in MATLAB R2021a.

- workflow run: `33290207290`
- job: `99200416636`
- result: `success`
- artifact: `9725727353`
- artifact SHA-256: `ca4ecf01ba8874bcfb685af8dfcdd7bd0f4a0ddda7bf0612b7ca95163139af14`

The numerical results remain:

| Variant | CT MAPE | CP MAPE | FM MAPE |
| --- | ---: | ---: | ---: |
| OFF / M1-B | 37.8538088% | 50.5150012% | 7.5480121% |
| Corrigan n=1 | 32.7268553% | 45.8942996% | 7.5918128% |
| Koning XV-15 n=1.8 | 28.3084996% | 41.7309496% | 8.0568562% |

The copied OFF branch reproduces the canonical Stage-1 M1-B metrics to:

- CT: `7.1054e-15 pp`
- CP: `7.1054e-15 pp`
- FM: `8.8818e-16 pp`

Thus the provenance correction does not alter the numerical M1 identity.

## Scientific interpretation

The defensible statement is:

> A predeclared `n=1` Corrigan model-form assumption, lying within the published model family and not selected from the current OARF targets, explains part of the remaining CT/CP discrepancy. Its numerical agreement does not identify `n=1` as the physical XV-15 exponent.

The `n=1.8` result remains useful only as reproduction/context for a published XV-15-correlated choice. Its smaller OARF error must not be promoted as independent validation or used to select the frozen holdout model.

## Decision

`CORRIGAN_N1_PROVENANCE_CLOSED_NUMERICAL_IDENTITY_UNCHANGED`

No rollback or model rerun beyond the formal identity check is required. The remaining M1 audit blocker is WADC input homology sensitivity.
