# CODEX_TASK.md

STATUS: COMPLETE / NUAA PUBLIC-FORMULA ROTOR REFERENCE / 2026-07-23

## Version contract

- Base branch: `codex/thesis-nacelle-state-consolidation`.
- Exact base SHA: `e858f07f9d416b292c6568afcd95af59c89d1bdc`.
- Head branch: `codex/nuaa-rotor-public-formula-reference-v2`.
- Isolated worktree: `E:\tiltrotor-nuaa-rotor-reference-20260723-2`.
- The protected original workspace `E:\tiltrotor` must not be used or modified.
- Build an opt-in `NUAA_PUBLIC_FORMULA_REFERENCE` model without changing the
  current default rotor, default parameters, GUI path, or frozen C2 values.
- Push the technical branch so it can serve as the exact base for the final
  master-thesis validation branch. Do not merge or rewrite PR #49-#55.

## Scientific objective

Implement an independent, opt-in rotor path from the equations explicitly
published by Sheng, Zhang, and Xiang, while classifying every unpublished
closure.  Quantify same-parameter differences against the production rotor,
retain unsupported negative-thrust cases as explicit failures, and provide a
committed technical baseline for the subsequent full thesis-validation branch.

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

- Compare production and public-formula rotors with the same current conceptual
  parameters at 0, 15, 45, 75, and 90 degrees.
- Re-evaluate the archived credible B15/V20, B45/V35, and B75/V80 states without
  retrimming or changing parameters.
- Retain the 75-degree negative-thrust/public-closure failure.
- Demonstrate a finite symmetric reference hover trim and report residual,
  bounds, conditioning, and failed trial evaluations.

## Deliverables and validation

- Commit the implementation, audit, provenance, focused tests, comparison
  script, and small generated evidence under this branch.
- Run focused MATLAB checks, `checkcode`, complete `run_all_checks`, and inspect
  the full Git diff.
- Push the branch so the thesis branch can use its exact commit as base.

## Claim boundary

This is a generic low-order component-level flight-dynamics study.  It is not
a high-fidelity aircraft model, a Berger 51-state reproduction, a complete
XV-15 model, flight-test validation, handling-quality qualification, or a
bidirectionally closed nacelle/rigid-body multibody model.  The prescribed
nacelle actuator supplies one-way dynamic influence only; external hinge-load
feedback and mechanical-jam constraint loads are not implemented.

## Completed evidence

- Focused reference checks: 7/7 PASS.
- Complete MATLAB R2021a regression: 26/26 PASS in 672.8 s.
- Same-parameter zero-speed differences remain at numerical-noise scale.
- B15/V20 and B45/V35 loads are model-form sensitive.
- B75/V80 explicitly fails because the public equations do not close a
  negative-thrust/windmill branch.
- Reference hover trim: CREDIBLE, full dynamic residual norm
  `1.262670e-4`, 463 evaluations, zero failed trial evaluations.
- No production physical-model function, default parameter, frozen C2 value,
  state/input ordering, credibility gate, or historical result was modified.
