# CODEX_TASK.md

STATUS: ACTIVE / BERGER13 PR2 FORMAL TRIM / 2026-07-22

## Version contract

- Stage: PR2 - formal 13-state trim, credibility gating, symmetric/differential coordinates, and trim-point linearization.
- Base branch: `origin/codex/berger13-pr1-baseline-port`.
- Base SHA: `c1189ee59ddfda7e5b5032867c91a148039c2e30`.
- Head branch: `codex/berger13-pr2-formal-trim`.
- PR base after push: `codex/berger13-pr1-baseline-port`.
- PR must remain Draft and must not be merged automatically.

## Allowed scope

- `CODEX_TASK.md`.
- Namespace-local implementation under `analysis/berger13/`.
- Namespace-local metadata helpers under `model/berger13/` only when required by the trim or coordinate contract.
- Berger13-focused tests and their registration in `tests/run_all_checks.m`.
- PR2 evidence and model-boundary documentation under `docs/`.

## Prohibited scope

- No changes to legacy production equations or default interfaces under `model/` outside `model/berger13/`.
- No changes to `params_nominal.m`, physical parameter values, legacy trim algorithms, GUI, or reference PDFs.
- No angle-command actuator, independent-wing, modal naming, handling-quality, or external-validation claims in PR2.
- No replacement of failed points by tuned parameters or relaxed hidden tolerances.

## Frozen contracts and equations

- State order: `[u v w p q r phi theta psi betaML betaMR betaMLdot betaMRdot]^T`.
- Torque-input order: `[collective diffCollective cyclicLong diffCyclic lateralCyclic aileron elevator rudder nacelleTorqueLeft nacelleTorqueRight]^T`.
- Straight symmetric trim requires rigid-body acceleration residuals `udot..rdot = 0`, nacelle rates and accelerations zero, `v=p=r=phi=0`, and `betaML=betaMR`.
- Static torque-model trim uses zero left/right nacelle torque because the reviewed PR1 equation is `I*betaDDot = Q-D*betaDot` with no active stiffness term.
- `betaSym=(betaML+betaMR)/2`, `betaDiff=(betaMR-betaML)/2`, with identical definitions for rates and torques.
- Only points classified `CREDIBLE` may be passed to `linearize_13x10_numeric` through the formal trim-point entry.

## Parameter and literature boundary

- Existing nacelle inertia, damping, limits, and torque limits remain `RESEARCH_PLACEHOLDER`; they may support internal calculations and sensitivity studies only.
- Numerical scales, finite-difference steps, rank tolerances, and credibility thresholds are numerical-method metadata, not aircraft parameters.
- Method references: Berger dissertation PDF 93-95 (printed 58-60), Section 2.1.3.3; Sheng et al. Drones 2022 PDF 12, Eqs. (38)-(42); Dreier Chinese edition PDF 348-360 (printed 323-335), Chapter 17, Eqs. (17-13)-(17-19).
- The 13-state model is not Berger's 51-state model and is not an XV-15 validation model.

## Required validation

- Pre-change and post-change MATLAB R2021a `run_all_checks`.
- Focused tests for formal trim, substitution, multiple seeds, continuation, Jacobian three-step stability, limits, coordinate transforms, mirror relations, credibility rejection, PR1 regression, and legacy 9-state regression.
- `checkcode` for every modified or added MATLAB file.
- Explicit checks for finite real values and absence of unexpected NaN, Inf, or complex results.
- Record commands, elapsed time, converged/credible/failed points, and known limitations in `docs/BERGER13_PR2_EVIDENCE.md`.

## Stop conditions

Stop only for an unavailable/mismatched PR1 base, inability to use an isolated worktree, MATLAB R2021a launch failure, inaccessible critical references/repository, an unrepairable legacy regression, a requirement to invent data, or missing push/PR permission. Individual trim failures are retained as data and are not blockers.

