# CODEX_TASK.md

STATUS: ACTIVE / GENERIC TILTROTOR PARAMETER PROVENANCE AND TRIM DIAGNOSTICS / 2026-07-22

## Version contract

- Stage: PR5A parameter provenance audit, opt-in XV-15 public overlay, pitch-moment diagnosis, sensitivity, and identifiability.
- Base branch: `codex/berger13-pr4-modes-time-domain-study`.
- Base SHA: `388de28723743984849b9768532b1f81178896fb`.
- Head branch: `codex/generic-trim-parameter-provenance`.
- Worktree: `E:\tiltrotor-generic-provenance`.
- Open a stacked Draft PR against the stated base; do not merge or rewrite PR #49-#52.

## Allowed scope

- Parameter provenance code/data/docs/tests for parameters used by trim and longitudinal loads.
- Opt-in `GENERIC_MODEL_WITH_XV15_PUBLIC_OVERLAY` parameter-set implementation and manifest.
- Nacelle/control sign mapping, pitch-moment decomposition, unconstrained-elevator diagnostic, failure classification, sensitivity, and identifiability analysis.
- Reproducible PR5A figures, raw data, metadata, evidence, and focused regression tests.

## Protected behavior

- `params_nominal.m` values and default behavior remain unchanged.
- New parameter sets remain opt-in and do not become GUI/model defaults.
- Production control limits, trim tolerances, numerical steps, model equations, and legacy paths are not tuned to manufacture success.
- XV-15 claims require explicit primary-source evidence; inherited generic fields remain labelled non-XV-15.

## Required validation

- Pre-change and post-change complete `run_all_checks` under MATLAB R2021a.
- Focused provenance, overlay-manifest, unit/sign mapping, moment-sum, diagnostic-isolation, reproducibility, and classification tests.
- `checkcode` on modified MATLAB files; finite-real checks; runtime and evidence capture.
- Inspect full Git diff and keep this worktree clean after commit/push.

## Deliverables

- All PR5A deliverables named in the user task, including provenance tables, sign conventions, XV-15 source/overlay records, moment decomposition, unconstrained elevator results, failure root cause, sensitivity/identifiability, figures/raw data, and `PR5A_EVIDENCE.md`.
- Commit, push, and create a Draft PR with explicit scope, results, failures, tests, limitations, and claim boundary.

## Claim boundary

This branch audits and diagnoses a generic low-order component model and adds a partial public-data overlay. It does not create a full XV-15 model, establish flight-test validation, or identify unknown/effective parameters as measured aircraft properties.
