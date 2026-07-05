# ChatGPT Review File Guide

This note identifies the files to review for the one-stop model validation
evidence audit. The package is an automated evidence chain for a concept-level
tiltrotor MATLAB model. It does not claim strict XV-15 validation and does not
use NUAA 0 deg or 15 deg trim angles as hard gates.

## Review Entry Points

| File | Purpose |
|-|-|
| `analysis/run_model_validation_evidence_audit.m` | Main one-stop audit entry point. Generates source inventory, evidence matrix, Gate 0-8 outputs, reports, owner package, and `finalConclusion`. |
| `analysis/validation_model_evidence_enums.m` | Central enum definitions for comparison types, evidence strengths, and allowed final conclusions. |
| `tests/check_model_validation_evidence_audit.m` | Regression check for required artifacts, enum validity, protected-path cleanliness, and NUAA comparability classification. |

## Primary Generated Evidence

| File | Purpose |
|-|-|
| `validation/model_validation_evidence/evidence_matrix.csv` | Machine-readable evidence matrix. Use this first to see what is hard, soft, internal-only, or non-comparable. |
| `docs/validation/MODEL_VALIDATION_EVIDENCE_MATRIX.md` | Human-readable evidence matrix summary. |
| `validation/model_validation_evidence/gate_summary.csv` | Gate 0-8 machine-readable status. |
| `validation/model_validation_evidence/final_status.csv` | Final conclusion and key classification counts. |
| `docs/validation/MODEL_VALIDATION_ONE_STOP_REPORT.md` | Main owner-facing report. |
| `validation/model_validation_evidence/owner_review_package/` | Minimal review package for owner/ChatGPT comparison review. |

## Gate Reports

| Gate | Report |
|-|-|
| Gate 0 runtime/default protection | `docs/validation/GATE0_RUNTIME_DEFAULT_REPORT.md` |
| Gate 1 trim closure | `docs/validation/GATE1_TRIM_CLOSURE_REPORT.md` |
| Gate 2 component balance | `docs/validation/GATE2_COMPONENT_BALANCE_REPORT.md` |
| Gate 3 rotor/control derivatives | `docs/validation/GATE3_ROTOR_CONTROL_REPORT.md` |
| Gate 4 wing/wake/full-angle checks | `docs/validation/GATE4_WING_WAKE_REPORT.md` |
| Gate 5 trim-trend comparability | `docs/validation/GATE5_TRIM_TREND_COMPARABILITY_REPORT.md` |
| Gate 6 linearization/stability | `docs/validation/GATE6_LINEARIZATION_STABILITY_REPORT.md` |
| Gate 7 numerical robustness | `docs/validation/GATE7_NUMERICAL_ROBUSTNESS_REPORT.md` |
| Gate 8 owner package | `docs/validation/GATE8_OWNER_PACKAGE_REPORT.md` |

## Current Review Facts

| Item | Current Value |
|-|-|
| Final conclusion | `MODEL_VALIDATION_PARTIAL_WITH_LIMITATIONS` |
| Hard gate failures | `0` |
| Non-comparable items | `1` |
| 0 deg NUAA trend classification | `PARTIAL_COMPARABLE` |
| 15 deg NUAA trend classification | `NON_COMPARABLE_OR_UNRESOLVED` |
| 75/90 deg NUAA trend classification | `SOFT_COMPARABLE` |
| Protected production paths | `params_nominal.m`, `model/`, and `app/` unchanged |

## Suggested Review Order

1. Read `docs/validation/MODEL_VALIDATION_ONE_STOP_REPORT.md`.
2. Check `validation/model_validation_evidence/gate_summary.csv`.
3. Check `validation/model_validation_evidence/hard_gate_failures.csv`.
4. Check `validation/model_validation_evidence/non_comparable_items.csv`.
5. Review Gate 5 before judging NUAA trim trend plots.
6. Review `tests/check_model_validation_evidence_audit.m` for the automated guardrails.

## Important Interpretation Rules

- Do not treat NUAA 0 deg or 15 deg vertical pitch/cyclic curves as hard
  pass/fail gates for this model.
- Treat 75 deg and 90 deg elevator trend comparisons as soft, screenshot-level
  owner-review evidence only.
- Treat `MODEL_VALIDATION_PARTIAL_WITH_LIMITATIONS` as concept-model readiness
  with limitations, not as strict flight-test validation.
- Do not infer that XFLR5 is connected to the GUI or that the default model has
  changed.
