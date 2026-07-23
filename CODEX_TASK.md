# CODEX_TASK.md

STATUS: COMPLETE / THESIS NACELLE-STATE CONSOLIDATION / 2026-07-23

## Version contract

- Base branch: `codex/generic-trim-envelope-optimization`.
- Exact base SHA: `e3e604d81d038a34866e4104ab993255d26bcc79`.
- Head branch: `codex/thesis-nacelle-state-consolidation`.
- Isolated worktree: `E:\tiltrotor-thesis-nacelle-consolidation`.
- The protected original workspace `E:\tiltrotor` must not be used or modified.
- Open a stacked Draft PR against the PR54 head branch; do not merge or
  rewrite PR #49-#54.

## Scientific objective

Consolidate the accepted PR49-PR54 evidence into the Chinese thesis
《倾转旋翼机部件级飞行动力学建模与短舱动态状态影响研究》.  The primary
scientific line is the necessity and effect of independent left/right nacelle
states.  Parameter provenance and trim-feasibility optimization remain
supporting evidence rather than the principal innovation.

## Frozen model and parameter boundary

- Do not modify physical model functions, `params_nominal.m`, state/input
  ordering, control limits, credibility gates, numerical tolerances, or C2
  frozen parameters.
- Do not add optimization variables, rerun parameter optimization, or make C2
  the default.
- New work is limited to analysis/report/plot scripts, terminology mapping,
  result databases, and read-only tests.
- Retain all failed and ill-conditioned trim records.

## Required supplemental calculation

At the three archived credible C2 points B15/V20, B45/V35, and B75/V80,
compare:

1. the legacy 9-state fixed-nacelle model;
2. the 13-state command model on the symmetric invariant manifold;
3. the 13-state model with independent left/right nacelle motion.

The comparison must quantify common rigid-body degradation, four added state
roots, symmetric/differential response channels, angle-rate effects,
asynchronous lateral/directional response, dynamic trim departure, and
finite-difference/time-step sensitivity.  It must not create an artificial
11-state model.

## Deliverables and validation

- Produce the prescribed Markdown/CSV/LaTeX/XeLaTeX-project/PDF/figure/raw-data
  package under
  `E:\tiltrotor-work-output\thesis-nacelle-consolidation-20260723`.
- Apply the frozen Chinese terminology and academic-language rules.
- Run focused MATLAB checks, `checkcode`, complete `run_all_checks`, finite-real
  scans, language/figure audits, PDF render inspection, full Git diff review,
  SHA-256 manifest, and final ZIP verification.
- Push the branch and create a Draft PR.  Do not merge it.

## Claim boundary

This is a generic low-order component-level flight-dynamics study.  It is not
a high-fidelity aircraft model, a Berger 51-state reproduction, a complete
XV-15 model, flight-test validation, handling-quality qualification, or a
bidirectionally closed nacelle/rigid-body multibody model.  The prescribed
nacelle actuator supplies one-way dynamic influence only; external hinge-load
feedback and mechanical-jam constraint loads are not implemented.

## Completed evidence

- Three representative credible points and three model layers were evaluated.
- All new matrices, roots, response histories, force/moment outputs, and
  summaries are finite and real-valued.
- Maximum adjacent time-step peak change: 0.015247522 (below the 0.02 gate).
- Focused consolidation check: PASS; `checkcode` messages: 0.
- Complete MATLAB R2021a regression: 25/25 PASS.
- The complete 31-page Chinese report, 18 Chinese figures, Markdown, LaTeX,
  XeLaTeX project, raw data, QA reports, manifest, and verified ZIP are archived
  under the prescribed external output directory.
- No physical-model function, default parameter, frozen C2 value, state/input
  ordering, credibility gate, or historical result was modified.
