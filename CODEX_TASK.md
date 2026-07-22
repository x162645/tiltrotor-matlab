# CODEX_TASK.md

STATUS: ACTIVE / BERGER13 PR4 PHYSICS-BASED RESULT CORRECTION / 2026-07-22

## Version contract

- Stage: PR4 correction of derivative, modal, tracking, time-domain, sensitivity, figure, and academic-report evidence.
- Base branch: `codex/berger13-pr3-commanded-actuator-independent-wing`.
- Corrected base SHA: `587a0d3755bdcdc808324827ac131ebc939ad042`.
- Original PR4 head: `b3abfb78db1f183560e757917482024edbcb9f1f`.
- Head branch: `codex/berger13-pr4-modes-time-domain-study`.
- The existing Draft PR #52 is updated; no replacement PR is created and no PR is merged.

## Allowed scope

- `CODEX_TASK.md`, `analysis/berger13/`, Berger13-focused tests and registration, PR4/final evidence documentation, reproducible output/report scripts, and regenerated `results/berger13_final/`.
- Small namespace-local analysis metadata changes are allowed only to expose missing diagnostics, not to tune outcomes.
- Extra audit deliverables are generated under `E:\tiltrotor-work-output\13x10-correction-20260722`.

## Prohibited scope

- No model tuning for expected roots, no hidden failures, no legacy/default-path changes, and no external-validation claim.
- No invented external hinge generalized load, mechanical-jam reaction, or bidirectional nacelle coupling claim.
- No mode name based only on eigenvalue location and no matching across a failed or discontinuous operating-condition gap.
- No unsupported Berger 51-state, XV-15 validation, aircraft-type limit, blade-elastic, dynamic-inflow, or drivetrain claim.

## Required corrections

- Classify the zero `psi` root as `heading kinematic integrator`; exclude it from damping/stability qualification and preserve its identity during tracking.
- Derive every derivative unit from explicit state-derivative and state/input unit contracts. Command inputs 9/10 are `betaSymCommand` and `betaDiffCommand`.
- Establish fixed-step convergence with 0.1, 0.05, and 0.025 s, adding 0.0125 s where the 2% adjacent-step gate requires it. Archive a converged step or withhold quantitative claims.
- Apply an explicit `ASSUMED_ANALYSIS_GUARD`; retain the full numerical trajectory but form quantitative claims from the valid prefix only.
- Keep force and moment sensitivities dimensionally separate. Use flight-response and tracked-mode metrics for actuator bandwidth/damping, and return `CANNOT_RELIABLY_DETERMINE` when a limit is inactive.
- Track fixed-nacelle-angle speed paths independently. Preserve failures/path interruptions and do not force cross-gap assignment.
- Use the prescribed one-way actuator boundary inherited from corrected PR3. Command freeze and kinematic lock remain distinct; mechanical jam is not implemented.

## Evidence, figures, and report

- Regenerate all CSV/MAT databases and all figures with traceable raw data/metadata under `results/berger13_final/`.
- Generate the full Chinese academic report titled `规定执行器模型下倾转旋翼机左右短舱运动对刚体动态的影响研究` and visually verify its PDF rendering.
- Create the requested correction audit documents, pre/post comparison, GitHub evidence index, SHA-256 manifest, and final ZIP.
- Run focused tests, `checkcode`, post-change full MATLAB R2021a regression, finite-real checks, ZIP extraction verification, worktree/diff review, push, and Draft PR update.

## Claim boundary

The model supports internally consistent low-order study of prescribed nacelle motion effects on rigid-body dynamics. It does not establish bidirectional hinge-load closure, mechanical-jam loads, external validation, XV-15 validation, Berger 51-state reproduction, handling-quality compliance, or a flight-safety envelope.

## Stop conditions

Only the user-defined baseline/worktree, MATLAB, critical repository/reference, unrepairable legacy-regression, invented-data, permission, finite-real, or time-step-convergence failures are blockers. Individual trim failures, path interruptions, and post-guard trajectories are retained and reported.
