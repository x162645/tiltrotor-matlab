# CODEX_TASK.md

STATUS: COMPLETE / HOLD

Branch: `audit/representative-trim-continuation`

Base branch: `main`

## Completed scope

- The five representative helicopter-mode trims at `V = [0, 5, 10, 15,
  20] m/s` all converged successfully with finite real results.
- Reduced and full residuals passed, no trim variable or applied control
  reached a limit, and continuation seeds were handed forward exactly.
- The original significant-sign-flip criterion remains triggered over both
  5--10 m/s and 15--20 m/s; the original representative-screen result remains
  **FAIL**.
- Independent endpoint-seeded trims at 7.5 m/s converged to the same numerical
  root with difference norm `8.998006e-09 deg`; the common `cyclicLong` was
  negative.
- Independent endpoint-seeded trims at 17.5 m/s converged to the same numerical
  root with difference norm `8.626265e-09 deg`; the common `cyclicLong` was
  negative.
- Midpoint seed dependence was not observed in either tested interval.
- No parameter, production-model, limit, residual, objective, penalty,
  tolerance, or solver error was found in this scope.
- Residual-Jacobian and full-linearization call counts were zero throughout
  the representative screen and both midpoint diagnoses.
- No zero-crossing location, additional speed, reverse sweep, multistart, or
  rescue calculation will be performed in this task.
- Draft PR #6 is waiting for final human review. Codex must not merge it.

## Preserved result and interpretation

The five-point representative screen remains **FAIL** under the unchanged
`signFlipThresholdDeg = 0.25 deg` acceptance logic. This result has not been
rewritten as PASS, and no threshold or test logic was changed.

Both midpoint diagnoses found the same numerical root from the two tested
endpoint seeds. The 7.5 m/s common solution had negative `cyclicLong`, with
the slipstream wing regions inside the normal-flow blend interval. The
17.5 m/s common solution also had negative `cyclicLong`, with every wing
region outside the blend interval.

The combined evidence is limited to the following interpretation:

- neither midpoint showed a different numerical root caused by the tested
  endpoint seeds;
- the coarse five-point sample detected two `cyclicLong` zero crossings whose
  exact locations have not been determined;
- continuity, monotonicity, and global uniqueness over either interval remain
  unproved;
- the current evidence does not support conclusions of bifurcation,
  hysteresis, or physical discontinuity.

## Final issue classification

- Original five-point screen: **FAIL — preserved**.
- Production-code defect: **not found**.
- Midpoint seed dependence: **not observed at either midpoint**.
- Remaining issue: **LOW / INFO** — zero-crossing locations are not resolved,
  and coarse sampling is insufficient to prove full-interval continuity.

## Evidence

- `docs/REPRESENTATIVE_TRIM_CONTINUATION.md`
- `docs/TRIM_MIDPOINT_7P5_DIAGNOSIS.md`
- `docs/TRIM_MIDPOINT_17P5_DIAGNOSIS.md`
- 7.5 m/s evidence commit:
  `7c327d332ffbffc369e9e80e813a8632f22ae681`
- 17.5 m/s evidence commit:
  `572d42d5b716b566b1f062e9970825ec2dad3bc1`

No MATLAB execution is authorized or required for this documentation-only
closeout.
