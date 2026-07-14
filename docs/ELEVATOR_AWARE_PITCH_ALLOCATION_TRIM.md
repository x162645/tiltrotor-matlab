# Elevator-Aware Pitch Allocation Trim Candidate

## 1. Executive Summary

This PR adds an opt-in elevator-aware longitudinal trim candidate and an
internal evidence exporter. It does not replace the default
`longitudinal_symmetric` path, does not change the current full 6-DOF trim
path, and does not change model equations, `params_nominal` defaults, GUI
behavior, default control limits, trim tolerances, or default
`lateralCyclic` enablement.

The goal is to test the PR #46/#47 recommendation that an elevator-aware or
nacelle-angle-dependent pitch allocation candidate may improve non-helicopter
longitudinal residuals. This is internal diagnostic evidence only, not
external validation and not a real-aircraft flight-control law.

## 2. Motivation From PR #46 / PR #47

PR #46 and PR #47 established these input facts:

- `conversion_mid` is sensitive to `cyclicLong` authority and residual
  weighting.
- `airplane_like` shows strong `cyclicLong` authority in `udot` and strong
  elevator authority in `qdot/wdot`, supporting an elevator-aware follow-up
  hypothesis.
- `conversion_high` is not explained by cyclic/elevator authority alone and
  remains formulation/scaling/weighting sensitive.
- The sign/mapping audit did not meet the strict sign-error criterion; the
  conservative conclusion is `SIGN_OK_LIKELY`.
- `cyclicLong +/-35 deg` and elevator limits remain `SOURCE_REQUIRED`.

These facts do not justify widening default cyclic limits or claiming an
elevator fix proven.

## 3. Candidate Formulations

- `theta_collective_cyclicLong`: baseline-comparable direct formulation using
  theta, collective, and `cyclicLong`.
- `theta_collective_elevator`: fixes `cyclicLong` at zero and solves theta,
  collective, and elevator.
- `theta_collective_cyclicLong_elevator_regularized`: solves theta,
  collective, `cyclicLong`, and elevator with regularization.
- `theta_collective_scheduled_pitch`: solves theta, collective, and a virtual
  pitch command allocated into `cyclicLong` and elevator.
- `scheduled_pitch_force_priority`: scheduled pitch candidate with larger
  force residual weights.
- `scheduled_pitch_moment_priority`: scheduled pitch candidate with larger
  qdot residual weight.

All formulations use the longitudinal residual channels `[udot, wdot, qdot]`.
Success requires solver convergence, finite model output, residual norm below
the configured tolerance, no default-limit violation, and no active limit.

## 4. Schedule Definition

The scheduled candidates use:

```text
cyclicWeight = cos(betaM)^2
elevatorWeight = sin(betaM)^2
```

The schedule is a candidate allocation only. It is not externally validated,
not a default control allocation, and not proof that the real aircraft uses
this cyclic/elevator split.

## 5. Evidence Matrix

The committed validation output under
`validation/elevator_aware_pitch_allocation_trim/<timestamp>/` records:

|case|candidate|success|residual|improvement|active limits|diagnosis|
|-|-|-:|-:|-:|-|-|
|helicopter_low_speed|all candidates|reported in validation output|reported in validation output|reported in validation output|reported in validation output|reported in validation output|
|conversion_mid|all candidates|reported in validation output|reported in validation output|reported in validation output|reported in validation output|reported in validation output|
|airplane_like|all candidates|reported in validation output|reported in validation output|reported in validation output|reported in validation output|reported in validation output|
|conversion_high|all candidates|reported in validation output|reported in validation output|reported in validation output|reported in validation output|reported in validation output|

The table is intentionally generated from the script rather than hand-coded in
this static document.

## 6. Interpretation

- `helicopter_low_speed`: the candidate must not be interpreted as a default
  replacement; the existing baseline already closes and should remain
  protected.
- `conversion_mid`: any improvement is evidence for a follow-up candidate, not
  proof that default cyclic authority should be changed.
- `airplane_like`: elevator-aware improvement supports further opt-in testing,
  not a proven fix.
- `conversion_high`: residual reductions must be interpreted with the PR
  #46/#47 formulation and weighting sensitivity in mind.

## 7. Recommended Next Step

Use the generated evidence to decide whether an opt-in GUI/service hook is
worth reviewing. Continue source-limit audit, residual-normalization audit,
and force/moment-chain checks before any default behavior change.

## 8. What Not To Claim

- Do not claim external validation.
- Do not claim all-envelope trim reliability.
- Do not claim NUAA/Berger/XV-15 match.
- Do not claim trend pass/fail.
- Do not claim elevator fix proven.
- Do not claim scheduled allocation is physically validated.
- Do not claim `cyclicLong` default limit should be widened.
- Do not claim sign wrong.
- Do not claim model equations are wrong solely from non-convergence.
