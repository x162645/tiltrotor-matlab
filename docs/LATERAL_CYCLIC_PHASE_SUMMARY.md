# Lateral Cyclic Phase Summary

## Background

The legacy flight-control vector had seven inputs:

```text
collective diffCollective cyclicLong diffCyclic aileron elevator rudder
```

The audit showed that `diffCyclic` is differential longitudinal cyclic, not
lateral cyclic. A future Berger-inspired 13-state / 10-input research path
therefore needs an eighth flight input for symmetric lateral cyclic before
adding nacelle generalized torque inputs.

## PR Stack Summary

- PR #30, `codex/lateral-cyclic-optin`: added the opt-in 8-input
  `lateralCyclic` path while leaving the legacy 7-input default unchanged.
- PR #31, `codex/lateral-directional-derivative-report`: added representative
  lateral/directional derivative reporting and showed the original
  `current` mapping had very small target response.
- PR #32, `codex/lateral-cyclic-mapping-comparison`: compared `current`,
  `rotDir`, and `minusRotDir`, confirming `current` cancels left/right
  `beta1s` / `nDisk_y` and recommending `rotDir`.
- PR #33, `codex/lateral-cyclic-rotDir-mapping`: changed the opt-in default
  mapping to `theta1c = rotDir*lateralCyclic`.
- PR #34, `codex/lateral-cyclic-premerge-hardening`: added hardcoded-index
  audit documentation, stronger `beta1s` / `nDisk_y` tests, betaM sign
  variation explanation, and a long-timeout `run_all_checks` pass.

## Frozen Conclusions

- Legacy default remains `P.control.enableLateralCyclic = false` with 7 inputs.
- Opt-in order is:

```text
collective diffCollective cyclicLong diffCyclic lateralCyclic aileron elevator rudder
```

- Current model-internal default:

```text
theta1c = rotDir*lateralCyclic
```

- Positive `lateralCyclic` is defined internally as a common `+eY` rotor
  disk-normal tendency.
- `theta1c = lateralCyclic` remains as the diagnostic `current` mapping and
  cancels left/right `beta1s` / `nDisk_y`.
- `minusRotDir` remains as an opposite-sign diagnostic option.

## What This Supports

- The opt-in 8-input `lateralCyclic` path is model-internally effective.
- The `rotDir` mapping resolves the current left/right cancellation.
- Representative finite operating points classify `lateralCyclic` as
  `PASS_NONZERO`.

## What This Does Not Support

- No Berger/XV-15 external validation is claimed.
- No flight-test validation is claimed.
- No lateral/directional handling-quality validation is claimed.
- The 13x10 scaffold is not equivalent to a Berger model.
- No high-fidelity nacelle torque model is implemented.

## Relationship To 13x10

`lateralCyclic` is the fifth flight input in the future Berger-inspired
13-state / 10-input research interface. The 13x10 path must remain independent
from the legacy main model and GUI default path until it has its own validation
record.
