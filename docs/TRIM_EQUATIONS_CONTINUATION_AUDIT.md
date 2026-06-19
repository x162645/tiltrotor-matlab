# Trim Equations And Continuation Audit

Branch: `audit/trim-equations-continuation`

Baseline: `002dd6bdae38e4f1b4632c74d68f202e5ff87b8c`

Scope: static review and a focused three-solve MATLAB check of the existing
symmetric helicopter-mode trim equations, solver contract, limits, residuals,
Jacobian, and continuation bookkeeping. This audit does not establish a
transition/airplane trim formulation, a flight envelope, or XV-15 fidelity.

## Static Contract

The state uses body axes x-forward, y-right, z-down and
`x=[u v w p q r phi theta psi]'`. For prescribed airspeed and flight-path
angle, the current symmetric mapping is

```text
alpha = theta - gamma
u = V cos(alpha)
w = V sin(alpha)
```

This is consistent with positive body-z down: positive angle of attack gives
positive `w`, and `gamma=theta-alpha`.

The closure has exactly three variables in rad:

```text
[theta; collective; cyclicLong]
```

It fixes `v=p=q=r=phi=psi=0`, `diffCollective=diffCyclic=0`, and all
conventional control surfaces, including elevator, at zero. The solved
residual is exactly `xdot([1,3,5])=[udot;wdot;qdot]` from
`tiltrotor_eom`. Remaining derivatives must be checked separately; they are
not part of the optimization objective.

The objective uses residual scaling `[g;g;1]`, so its residual contribution is
`sum((R./[g;g;1]).^2)`. `P.trim.variableScale` is a numerical search scale in
rad, not a physical aircraft parameter. Forward `fminsearch` maps its
dimensionless variable through
`z=zSeed+variableScale.*(y-ones(3,1))`; the initial physical simplex step is
`0.05*variableScale` under MATLAB's nonzero-variable simplex rule.

Exact-hover search uses `fminbnd` on collective and forces `theta=0` and
`cyclicLong=0`. This is a modeling assumption, not a general hover trim with
attitude or longitudinal cyclic freedom.

## Threshold Semantics

- `V < 1e-9` selects collective-only hover search and suppresses multistart.
- `V < 1e-10` forces constructed `u=w=0`.
- Therefore `1e-10 <= V < 1e-9` uses collective-only search while retaining a
  tiny nonzero prescribed velocity in the state.

This mismatch is numerically negligible at the stated magnitude but should be
described as a numerical near-hover convention, not an exact equality of the
two branches.

## Limits, Objective, And Candidate Selection

Collective, cyclic, and theta limits are all represented in rad. The model
clamps applied rotor and surface controls. The trim report retains commanded
controls, exposes applied controls, and rejects a candidate if it is at or
outside a trim-variable limit. Thus an out-of-limit solution cannot be
silently accepted solely because its scaled residual is small.

Equality at a limit is rejected by the current `report.converged` contract.
`trim_symmetric` uses `1e-8 rad` for at-limit reporting, while the sweep's
common-control report uses `1e-10 rad`. Exact equality agrees; near-limit
labels can differ within that tolerance band.

Single-start forward solves generate one candidate. Multistart stops at the
first acceptable candidate unless `alwaysMultiStart=true`; otherwise the best
candidate is selected by objective cost, with reduced residual norm as a tie
breaker at a `1e-14` cost difference. Invalid rotor coupled-solve evaluations
are counted and assigned the existing large objective value. No selection,
weight, penalty, tolerance, limit, initial seed, or solver behavior was changed
by this audit.

## Continuation And Rescue

`trim_sweep_helicopter` passes a successful point's
`[theta,collective,cyclicLong]` solution forward once, at the end of that
point's loop iteration. The update is guarded by `point.status.success`, so a
failed point does not overwrite the last successful seed.

Rescue initials are opt-in through `allowRescueInitials`. Attempt records carry
`source`, `usedRescue`, `rescueIndex`, initial values, solution values,
exit flag, residual norm, and success. A successful rescue is selected
immediately. If all attempts fail, the lowest existing failure score is
returned and a `best_failed_attempt` bookkeeping record is appended.

Continuity jump and sign-flip checks operate on adjacent array points and mark
a pair failed unless both endpoints succeeded. They do not bridge across an
intervening failed point.

## Applicability

The present closure is a conceptual helicopter-mode longitudinal symmetric
closure. The repository contains no justification that theta, collective, and
longitudinal cyclic with elevator fixed at zero can close transition or
airplane-mode trim. Using it at transition or airplane nacelle angles must be
reported as unsupported by the current audit. No elevator, additional trim
variable, or control channel was added.

## Findings

|Severity|Category|Finding|Reproduction / consequence|
|-|-|-|-|
|HIGH|Input validation|`trim_symmetric` does not validate `V`. Any negative finite `V` satisfies both less-than thresholds and is treated as zero-velocity collective-only hover.|For example `V=-1 m/s` makes `V<1e-9` and `V<1e-10` true. The solver therefore fixes theta/cyclic and constructs `u=w=0`, which is misleading for the requested input. Solver behavior was not changed pending review.|
|MEDIUM|Input validation|`betaM`, `gamma`, option booleans, theta limit, and complete initial-vector finiteness/type are not comprehensively validated at the trim entry.|Malformed inputs can fail downstream or be interpreted inconsistently. No solver-side validation was added in this phase.|
|LOW|Numerical semantics|The `1e-9` search-selection and `1e-10` state-construction thresholds define a narrow mixed near-hover interval.|Documented above; no numeric threshold was changed.|
|LOW|Limit reporting|Trim-variable and sweep common-control at-limit tolerances are `1e-8` and `1e-10 rad`, respectively.|Exact limits agree, but values near a limit can receive different at-limit labels.|
|INFO|Engineering assumption|Exact hover fixes theta and longitudinal cyclic at zero and solves collective only.|Valid only for the current symmetric no-wind conceptual hover assumption.|
|INFO|Applicability|The three-variable closure is not established for transition/airplane nacelle angles.|A broader closure requires a separately reviewed future phase.|

## MATLAB Results

Target command:

```powershell
& 'F:\matlab\R2021a\bin\matlab.exe' -batch "cd('E:\tiltrotor'); run('startup.m'); r = check_trim_equations; disp(r); assert(r.allPassed);"
```

Test-body result: 15/15 named cases passed in 38.3 seconds. The three requested
high-level trim solves all converged: exact hover, 10 m/s single-start, and
20 m/s seeded exactly from the 10 m/s solution. Total reported objective
evaluations were 563, compared with the conservative pre-run upper estimate of
18,000. No rescue initial or internal multistart was used.

The test verified that reduced residuals and full nine-state derivatives were
finite and real, that the unsolved symmetric derivatives were near zero, and
that accepted points were not at active limits. It also verified exact
commanded/applied control agreement at all three accepted points. No test-body
warning, NaN, Inf, or complex value was observed.

One Jacobian location was evaluated at 10 m/s. Central-difference steps
`1e-3`, `1e-4`, and `1e-5 rad` required exactly 18 residual/EOM evaluations.
All raw and scaled matrices were finite, rank three, had finite condition
numbers, and met the test's 5 percent adjacent-step relative-change criterion.
No full-state linearization was called by the focused test.

MATLAB R2021a emitted the known shutdown-stage `output stream error` after the
PASS summary and successful `assert(r.allPassed)`. This made the batch process
exit nonzero and is recorded separately from the passing test body.

An earlier 27.4-second invocation failed before any trim solve because the new
test initially omitted its local result-recording helper. The test-only defect
was corrected; it consumed zero high-level solves. The successful invocation
above is the only run that consumed the three-solve budget.

`check_trim_continuity` was not run. Its current implementation scans 21 speeds
and computes both a residual Jacobian and a full linearization at every
successful speed, contrary to this phase's explicit restrictions. The default
five-speed sweep was also not run. `run_all_checks` was not run because the
three successful high-level trim solves exhausted the first-pass budget and
the existing flapping check invokes an additional trim solve.

## Change Status

- Production parameter values changed: no.
- `params_nominal.m` changed: no.
- Solver algorithm, objective, penalties, tolerances, limits, or defaults
  changed: no.
- Trim solution behavior changed: no.
- Diagnostic fields exposing existing calculations added: yes.
- Full linearization called by the focused test: no.
