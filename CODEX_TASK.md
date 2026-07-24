# CODEX_TASK.md

STATUS: FINAL VALIDATION AND DELIVERY / MASTER THESIS FINAL MULTIROUND REVISION / 2026-07-25

## Version contract

- Repository: `x162645/tiltrotor-matlab`.
- Base Draft PR: #57.
- Base branch: `codex/master-thesis-validation-full-expansion`.
- Exact base SHA: `97694120eff16f0edab4b5671fb5606638d30f8e`.
- Task branch: `codex/master-thesis-final-multiround-revision`.
- Isolated worktree: `E:\tiltrotor-master-thesis-final-iteration`.
- Protected workspace `E:\tiltrotor` is read-only.
- Final external output root:
  `E:\tiltrotor-work-output\master-thesis-final-multiround`.

## Objective

Complete, in separate retained rounds, the scientific audit, argument
restructure, technical expansion, Chinese academic-language revision,
simulated blind review, author response, consistency audit, and actual
XeLaTeX/Biber build of the thesis
《倾转旋翼机部件级飞行动力学建模、短舱动态状态扩展与可信度分析》.

## Frozen scientific boundary

- The research object is a generic, low-order, component-level nonlinear
  tiltrotor flight-dynamics model.
- Do not modify production physical-model functions, default parameters,
  state/input order, control limits, credibility gates, or frozen numerical
  results.
- Preserve failed and ill-conditioned trim points.
- Separate program verification, internal consistency, numerical
  convergence, independent-model comparison, literature trend comparison,
  and external-data correlation.
- Do not claim XV-15 reproduction, high fidelity, aircraft-level external
  validation, a flight-safety envelope, mechanical-jam loads, or complete
  bidirectional hinge-servo-structure coupling.

## Required stages

1. Fact freeze.
2. Scientific and evidence audit.
3. Structure and argument reconstruction.
4. Equation, figure, and physical-interpretation expansion.
5. Chinese academic-language revision.
6. Simulated blind review, author response, and final revision.
7. Actual XeLaTeX/Biber compilation, PDF render QA, MATLAB regression, archive,
   push, and a new Draft PR.

Each stage retains its artifacts and uses an independent Git commit.

## Stop conditions

- A code defect that invalidates the central physical conclusions must be
  recorded as blocking and must not be silently fixed in this thesis task.
- No fabricated data, page numbers, references, uncertainty, or validation
  claims.
- No tuning against external validation data.
- Do not merge any pull request.
