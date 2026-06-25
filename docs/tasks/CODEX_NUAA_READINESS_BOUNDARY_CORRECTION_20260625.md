# Correction — preserve the exact 45 deg conversion baseline

This file overrides only the 45 deg boundary rule in `CODEX_NUAA_READINESS_BLOCKER_RESOLUTION_20260625.md`.

## Root cause of the new regression

The original production code used:

```matlab
if betaM < pi/4
    % low-angle seed
elseif betaM < pi/2
    % high-angle seed
else
    % airplane endpoint seed
end
```

Therefore `betaM == pi/4` belonged to the original high-angle branch. The prior blocker-resolution instruction incorrectly described `betaM <= 45 deg` as preserving the original low-angle behavior. Implementing that instruction changed the exact 45 deg factory seed and consequently changed the exact 45 deg trim/Jacobian regression baseline in `check_trim_credibility`.

The approved blocker fix is intended only to make `45 deg < betaM < 90 deg` use the dominant elevator channel. It must not alter the already validated exact 45 deg baseline.

## Approved correction

Do not modify `tests/check_trim_credibility.m` and do not update its expected Jacobian or margin values at this stage.

Use these factory seed rules:

```text
betaM < 45 deg:
    preserve original low-angle seed
    theta0 = 4 deg
    collective0 = 16 deg
    target cyclicLong = +2 deg
    invert through cyclic channel

betaM == 45 deg, within a machine-precision boundary test:
    preserve the original exact-45 seed
    theta0 = 4 deg
    collective0 = 8 deg
    target cyclicLong = -4 deg
    invert through cyclic channel

45 deg < betaM < 90 deg:
    use the corrected high-angle seed
    theta0 = 4 deg
    collective0 = 8 deg
    target elevator = -4 deg
    invert through elevator channel

betaM == 90 deg:
    preserve endpoint seed
    theta0 = 4 deg
    collective0 = 8 deg
    target elevator = 0 deg
```

Use a narrow numerical equality check for the exact `pi/4` boundary, such as a tolerance based on machine epsilon. Do not create a broad angular band around 45 deg.

At exact 45 deg the preserved seed should retain the original semantics, approximately:

```text
pitchCommand = +0.2285714286
cyclicLong   = -4.000000 deg
elevator     = -2.285714 deg
collective0  = 8.000000 deg
```

At 75 deg the corrected seed remains approximately:

```text
pitchCommand = +0.214359354
cyclicLong   = -0.502577 deg
elevator     = -4.000000 deg
```

## Allowed files

Continue to modify only:

```text
analysis/make_trim_definition.m
tests/check_trim_mode_framework.m
```

Do not modify `tests/check_trim_credibility.m` unless the exact 45 deg behavior has first been restored and that test still fails for a separately demonstrated reason.

## Tests

Update the factory-domain test so that it explicitly checks all four regions:

```text
44.9 deg -> original low-angle seed
45.0 deg -> original exact-45 high-branch seed
45.1 deg -> corrected elevator-derived high-angle seed
75.0 deg -> corrected elevator-derived seed
90.0 deg -> endpoint seed
```

Retain the old 75 deg invalid cyclic-inversion reproduction test.

Then run:

```matlab
check_trim_mode_framework
check_pitch_allocation
check_trim_credibility
```

Expected outcome:

- exact 45 deg credibility/Jacobian baseline passes unchanged;
- 75 deg factory initial command is valid;
- 75 deg / 100 m/s readiness trim remains converged and credible.

If `check_trim_credibility` still fails after exact 45 deg seed identity is restored, stop and report the exact assertion, actual/expected values, trim state/control differences, Jacobian difference and margin difference. Do not update the baseline automatically.

## Next step after PASS

If all three focused tests and the 75 deg / 100 m/s point pass:

1. commit and push the minimal blocker fix;
2. rerun the full Issue #24 readiness gate;
3. continue the fixed NUAA trend task only if the gate passes;
4. apply the full-grid stability-map amendment.
