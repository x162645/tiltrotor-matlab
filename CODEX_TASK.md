# CODEX_TASK.md

STATUS: ACTIVE / TRIM CREDIBILITY DIAGNOSTICS

Branch: `feature/trim-credibility-diagnostics`

Base branch: `main`

## Priority mainline

1. `RH_mass/RH_hub` split: COMPLETE AND MERGED.
2. General mode-dependent trim core: COMPLETE AND MERGED.
3. Open-loop pitch-actuator allocation: COMPLETE AND MERGED.
4. Trim credibility diagnostics: CURRENT TASK.
5. Linearization credibility diagnostics.
6. Robust induced-velocity root solution.

Do not start items 5-6 in this branch.

## Objective

Implement the electronic-book-grounded trim credibility diagnostic only after a mandatory read-only prototype verifies the finite-difference, scaling, SVD/rank, full-derivative, and margin calculations.

The diagnostic must not change the trim solution, solver, acceptance criteria, parameters, limits, allocation, or model equations.

## Read first

Read only:

```text
AGENTS.md
CODEX_TASK.md
docs/EBOOK_MODEL_UPGRADE_PRIORITY.md
docs/ebook_packets/TRIM_CREDIBILITY_PACKET.md
analysis/trim_general.m
analysis/make_trim_definition.m
analysis/trim_symmetric.m
analysis/pitch_allocation_schedule.m
model/tiltrotor_eom.m
params_nominal.m
tests/check_trim_mode_framework.m
tests/check_pitch_allocation.m
tests/run_all_checks.m
```

Inspect only direct helper functions required to evaluate an existing trim definition. Do not read the 622-page electronic book or unrelated PDFs.

## Stage 0 — repository and baseline gate

Before editing:

```powershell
git status --short
git branch --show-current
git fetch origin
git log -1 --oneline
git diff --stat origin/main...HEAD
```

Require:

- branch is `feature/trim-credibility-diagnostics`;
- working tree is clean;
- branch contains latest `origin/main`;
- relative to `origin/main`, only this task file is changed.

Run in this order:

1. `check_trim_mode_framework`;
2. `check_pitch_allocation`;
3. `run_all_checks` once;
4. the three representative trims:
   - `helicopter_longitudinal`: `V=20 m/s`, `betaM=0`, `gamma=0`;
   - `conversion_longitudinal`: `V=35 m/s`, `betaM=pi/4`, `gamma=0`;
   - `airplane_longitudinal`: `V=100 m/s`, `betaM=pi/2`, `gamma=0`.

Record outputs and runtime. Stop if any baseline test or trim fails.

## Stage 1 — mandatory read-only prototype

Do not modify production or test files in this stage.

Use a temporary script outside the repository or delete it before finishing. Compute the following at all three representative trim points.

### 1.1 Unknown and residual vectors

Use each definition's actual:

```text
unknownNames
residualNames
variableScale
bounds
```

Reconstruct the physical unknown vector `zTrim` from `trimReport.trimVariables` in `definition.unknownNames` order.

### 1.2 Residual evaluation

For a perturbed unknown vector, construct the same 9-state and 7-control point used by `trim_general`, including the current allocation helper when present, and evaluate:

```matlab
[xdot, out] = tiltrotor_eom(x, uCtrl, condition.betaM, P)
```

Extract the residuals by `definition.residualNames`.

The prototype may duplicate minimal point-construction logic temporarily. It must not modify `trim_general` in Stage 1.

### 1.3 Three scaled finite-difference steps

Use:

```text
hScaled = [1e-2, 1e-3, 1e-4]
```

For unknown `j`:

```text
deltaZ = hScaled * definition.variableScale(j)
```

Use central difference if both perturbed points are legal. If a bound or generated actuator limit prevents central differencing, use second-order forward or backward difference. If needed, reduce only that column's step. Never clip an invalid point.

Record for every step and column:

```text
actual physical step
central / forward-second-order / backward-second-order / unavailable
finite-real status
```

### 1.4 Raw and scaled Jacobians

Compute:

```text
Jraw = d(residual)/d(physical unknown)
Jscaled = diag(1./residualScale) * Jraw * diag(variableScale)
```

Use the same residual scales as `trim_general`:

```text
linear acceleration residuals: g
angular/kinematic residuals: 1
```

Retain row and column labels.

### 1.5 SVD, rank, condition

For the main step `hScaled=1e-3`, report:

```text
singularValues
sigmaMax
sigmaMin
conditionNumber
defaultRank
effectiveRank
effectiveRankTolerance = 1e-8*sigmaMax
condition level: LOW / CAUTION / SEVERE
```

Condition levels:

```text
<= 1e3       LOW
1e3 to 1e6   CAUTION
> 1e6        SEVERE
```

These are numerical diagnostics only.

### 1.6 Step sensitivity

Relative to the `1e-3` scaled Jacobian, report for `1e-2` and `1e-4`:

```text
Frobenius relative difference
singular-value relative changes
```

Classify maximum Jacobian variation:

```text
<= 0.05       STABLE
0.05 to 0.20  CAUTION
> 0.20        SEVERE
```

### 1.7 Full-state derivatives

Report all nine derivatives in order:

```text
udot vdot wdot pdot qdot rdot phidot thetadot psidot
```

Scale them as:

```text
translational accelerations / g
angular accelerations and Euler-angle rates / 1
```

Report selected and unselected derivative labels separately, plus the maximum absolute scaled full derivative.

### 1.8 Margins

For every bounded trim unknown and generated direct actuator, compute:

```text
marginAbsolute = min(value-lower, upper-value)
marginFraction = 2*marginAbsolute/(upper-lower)
```

Do not clamp negative values.

Classify:

```text
>= 0.10       ADEQUATE
0.02 to 0.10  LOW
< 0.02        CRITICAL
```

Also report:

```text
max(abs(commandedControls-appliedControls))
```

The 35 m/s, 45 deg conversion point is expected to show about `0.0663` cyclic/elevator margin and must therefore receive a LOW-margin reason.

## Stage 1 stop gate

After the read-only prototype, stop and report. Do not implement the production diagnostic yet.

Report for each of the three representative conditions:

- trim residual and convergence state;
- `Jraw` and `Jscaled` with labels;
- all three step results and difference methods;
- SVD/rank/condition metrics;
- Jacobian step variation;
- all nine full derivatives;
- unknown and direct-actuator margins;
- commanded/applied difference;
- provisional `PASS`, `CAUTION`, or `FAIL` reasons under the method packet rules;
- runtime.

The prototype passes the gate if:

- all required values are finite and real;
- every Jacobian column is available;
- scaled Jacobians are interpretable and effectively full rank;
- finite-difference step behavior is not contradictory;
- the conversion point produces the expected low-margin warning without changing the model.

If the prototype reveals duplicated point construction cannot reproduce the exact trim point, stop and report the mismatch. Do not refactor production code until reviewed.

## Future Stage 2 — implementation after review

Expected production interface:

```matlab
credibility = diagnose_trim_credibility( ...
    condition, definition, xTrim, uTrim, trimReport, P, opts)
```

Expected output and later sensitivity tests are defined in:

```text
docs/ebook_packets/TRIM_CREDIBILITY_PACKET.md
```

Do not execute Stage 2 until the Stage 1 results are reviewed in ChatGPT.

## Allowed future files

```text
CODEX_TASK.md
analysis/diagnose_trim_credibility.m
analysis/evaluate_trim_definition_point.m   # only if shared point evaluation is required
tests/check_trim_credibility.m
tests/run_all_checks.m
docs/TRIM_CREDIBILITY_AUDIT.md
```

A minimal modification to `analysis/trim_general.m` is allowed only after Stage 1 review and only if exact compatibility is demonstrated.

## Forbidden changes

```text
params_nominal.m
model/*
app/*
services/*
analysis/linearize_numeric.m
analysis/trim_symmetric.m
analysis/pitch_allocation_schedule.m
analysis/make_trim_definition.m
control limits
trim tolerances
solver settings
```

Do not:

- rewrite the trim solver;
- switch to Newton, `fsolve`, or Optimization Toolbox;
- alter allocation directions, cosine weights, or dynamic command range;
- use random/dense multistart or broad speed/tilt sweeps;
- start A/B linearization diagnostics;
- tune variables or parameters from condition number;
- claim XV-15 or flight-test validation.

## Current closeout

For this first Codex run:

- modify no files;
- create no commit;
- push nothing;
- keep the Draft PR unchanged;
- finish with a clean `git status --short`.
