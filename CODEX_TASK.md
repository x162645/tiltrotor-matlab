# CODEX_TASK.md

STATUS: COMPLETE / GENERIC TILTROTOR TRIM-ENVELOPE OPTIMIZATION AND VALIDATION / 2026-07-23

## Version contract

- Stage: PR5B constrained multi-condition design, frozen-parameter validation, stability/mode impact, figures, academic report, and final delivery bundle.
- Base branch: `codex/generic-trim-parameter-provenance`.
- Base SHA: `40eb097a952036ef99b1399bcf6d71efcf5f390f`.
- Head branch: `codex/generic-trim-envelope-optimization`.
- Worktree: `E:\tiltrotor-generic-trim-opt`.
- Open a stacked Draft PR against PR5A; do not merge or rewrite PR #49-#53.

## Required model variants

- Model A: unchanged generic conceptual baseline.
- Model B: opt-in partial public XV-15 overlay, with inherited fields explicitly non-XV-15.
- Model C1: bounded geometry/layout optimization only.
- Model C2: bounded joint optimization, adding only selected `CALIBRATED_EFFECTIVE` aerodynamic parameters when C1 is insufficient.

## Protected behavior

- `params_nominal.m`, default GUI/model behavior, production control limits, trim credibility gates, numerical tolerances, finite-difference steps, iteration limits, and inertias are not optimization variables.
- The frozen 9-point design-feasibility grid retains all failures.
- Optimization history, failed trials, objective terms, bounds, runtimes, seeds, and final frozen values are archived.
- Validation/holdout data are not used to select variables, bounds, weights, or the final solution.
- No optimized generic variant is called a full or validated XV-15 model.

## Required validation

- Pre-change and post-change complete `run_all_checks` under MATLAB R2021a.
- Focused bound, invariant-field, objective reproducibility, design-grid, margin, dense-corridor continuity, data-split isolation, frozen-parameter, provenance, legacy, and 13x10 regression checks.
- Independent initial values and bounded parameter perturbations after parameter freeze.
- Stability derivatives, representative modes, and retained lateral/directional conclusions.
- `checkcode`, finite-real checks, full diff inspection, clean worktree after commit/push.

## Deliverables

- All PR5B CSV/Markdown/MAT/figure deliverables in the user contract.
- Complete Chinese academic report in Markdown and visually verified PDF.
- Final output tree and SHA-256 ZIP at the prescribed external output path.
- Commit, push, and create a stacked Draft PR with explicit failures, limitations, claim boundary, tests, and SHAs.

## Claim boundary

This branch performs bounded design and effective-parameter calibration on a generic low-order component model. Internal trim coverage, qualitative public-data trend comparison, and held-out numerical checks do not establish a complete XV-15 reproduction or flight-test validation.

## Frozen outcome

- Model A: 7/9 CREDIBLE.
- Model B: 5/9 CREDIBLE, 2/9 ILL_CONDITIONED, 2/9 FAILED.
- Model C1: 8/9 CREDIBLE with three geometry variables only.
- Model C2: 8/9 CREDIBLE; C1 plus `htail.CLelevator=2.35 /rad`.
- B75/V60 C2 elevator: -15.8305319 deg; full-span margin: 10.4236704%.
- B75/V40 remains FAILED at the -20 deg elevator limit.
- Post-freeze dense extra grid: 10/13 CREDIBLE; failures retained.
- Post-freeze perturbations: 14/21 credible combinations; every scenario retains the same 2/3 key-point pattern.
- External holdout is qualitative only and contributes zero to the objective.
- Representative derivatives are finite, but ill-conditioned eigenvectors prevent reliable participation-based mode classification.

## Test evidence

- Exact PR5A base pre-change: 24/24 PASS, 387.555047 s.
- PR5B focused: 16/16 PASS, 2.110712 s; checkcode messages: 0.
- PR5B post-change: 25/25 PASS, 387.654684 s.
- Exact log scan: no warning, NaN, Inf, or unexpected complex output.
- Draft PR: https://github.com/x162645/tiltrotor-matlab/pull/54 (stacked on PR #53; unmerged).
