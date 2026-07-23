# CODEX_TASK.md

STATUS: COMPLETE / FULL MASTER THESIS VALIDATION / 2026-07-24

## Version contract

- Repository: `x162645/tiltrotor-matlab`.
- Base branch: `codex/nuaa-rotor-public-formula-reference-v2`.
- Exact base SHA: `878beef329473d75b0c216954dfd6378ffa38a41`.
- Base Draft PR: #56.
- Head branch: `codex/master-thesis-validation-full-expansion`.
- Isolated worktree: `E:\tiltrotor-master-thesis-validation`.
- Protected workspace `E:\tiltrotor` is read-only and is not a source of
  uncommitted facts.

## Objective

Produce the complete Chinese master thesis
《倾转旋翼机部件级飞行动力学建模、短舱动态状态扩展与模型验证研究》
and its scientific evidence package. The research object is a generic,
low-order, component-level nonlinear tiltrotor flight-dynamics model.

## Frozen scientific boundary

- Do not change production physical-model functions or default parameters.
- Preserve the frozen 9-state and 13-state contracts and nacelle-angle signs.
- Preserve every failed and ill-conditioned trim point.
- Separate program verification, internal consistency, numerical convergence,
  independent-model comparison, literature trend comparison, external-data
  correlation, and true external validation.
- Do not claim XV-15 reproduction, Berger 51-state reproduction, high fidelity,
  flight-envelope certification, or complete bidirectional nacelle mechanics.

## Required outputs

- Exact external output root:
  `E:\tiltrotor-work-output\master-thesis-validation-full-20260723`.
- Exact final archive:
  `TILTROTOR_MASTER_THESIS_VALIDATION_FULL_DELIVERABLES.zip`.
- Ten thesis chapters with separate validation-method and validation-results
  chapters, at least 26 Chinese figures, raw data, generation scripts, matrices,
  QA reports, Markdown, XeLaTeX, PDF, SHA-256 manifest, and Draft PR.

## Stop conditions

- No fabricated data, page numbers, uncertainty, or validation claims.
- No tuning against validation data.
- If an external dataset cannot be matched in configuration and definitions,
  retain it as a benchmark/trend source and explain the limitation.
- Do not merge any pull request.

## Completed evidence

- Ten chapters, 62,576 main-body non-whitespace characters, 43 figures,
  8 Markdown tables, 18 displayed formula groups, and 20 references.
- MATLAB R2021a external rotor-correlation calculation completed without
  parameter tuning; all low-collective failures remain explicit.
- The inherited production/reference focused checks are 7/7 PASS and the
  complete inherited regression is 26/26 PASS at exact base SHA
  `878beef329473d75b0c216954dfd6378ffa38a41`.
- The final local PDF has 90 A4 pages and every page was rendered to PNG for
  visual inspection; no blank, clipped, or missing-font page was found.
- The Overleaf-compatible XeLaTeX/Biber project is present. A local XeLaTeX
  executable was not installed, so local XeLaTeX execution is an explicitly
  retained verification gap; the delivered PDF was generated with the
  documented CJK PDF fallback.
- No production physical-model function, default parameter, state/input
  ordering, control boundary, credibility gate, or frozen result was changed.
- Final external ZIP SHA-256:
  `26d64f82d5c2cd806c2680167375393e25c7f7268ac4b1520d45fe6ac083e41c`.
