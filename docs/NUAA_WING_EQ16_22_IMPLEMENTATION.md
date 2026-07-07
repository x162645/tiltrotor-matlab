# NUAA Wing Eq. (16)-(22) Zone-Sum Implementation

Date: 2026-07-07

Branch: `task/nuaa-wing-eq16-22-zone-sum-20260707`

## What Changed

The default wing production path now follows a zone-sum structure:

1. Compute the slipstream area from the existing NUAA Eq. (16)-style formula.
2. Guard the physical area so `0 <= Swss <= Swing`.
3. Set `Swfs = Swing - Swss`.
4. Evaluate each left/right slipstream region with the Eq. (17) induced
   velocity term.
5. Evaluate each left/right free-stream region without any induced velocity
   term.
6. Transform local lift/drag/side force into body axes for each region.
7. Assemble each region moment as `cross(rAC,F) + Maero`.
8. Sum slipstream plus free-stream regions, then left plus right wing regions.

The external `wing_model` function signature is unchanged, and
`total_forces_moments` still calls it in the same way.

## Area Model

The current code still uses the existing half-wing Eq. (16) implementation:

```text
slipstreamAngleArgument = pi/2 - betaM
SslipRawHalf = P.wing.SslipMaxHalf
             * (sin(1.386*slipstreamAngleArgument)
             +  cos(3.114*slipstreamAngleArgument))
             * ((P.wing.muMax - muMean)/P.wing.muMax)
```

The code then applies a physical guard:

```text
S_slip = clamp(SslipRawHalf, 0, min(P.wing.SslipMaxHalf, P.wing.S/2))
S_free = P.wing.S/2 - S_slip
Swss = 2*S_slip
Swfs = P.wing.S - Swss
```

`P.wing.SslipMaxHalf` and `P.wing.muMax` are unchanged assumed/current-model
parameters. They were not tuned in this task.

## BetaM Convention

The current project convention is:

```text
betaM = 0      helicopter mode
betaM = pi/2   airplane mode
```

In this codebase, the rotor thrust axis is:

```text
eT = [sin(betaM); 0; -cos(betaM)]
```

Therefore the Eq. (17) slipstream velocity term is implemented explicitly as:

```text
[v1d*sin(betaM); 0; -v1d*cos(betaM)]
```

This matches the current body-axis convention used by `rotor_model_bemt`.
The code comment also warns that figure-level nacelle angle annotations may
use a different visual reference; those annotations are not used as the code
formula argument.

## Removed Production Blend

The old production load path blended complete region results:

```text
Freg = (1 - branchWeight)*FNear + branchWeight*FLiftLine
Maero = (1 - branchWeight)*MaeroNear + branchWeight*MaeroLiftLine
```

That path is removed from production. The current production path uses:

```text
Freg = FLiftLine
Maero = MaeroLiftLine
Mreg = cross(rAC,Freg) + Maero
```

`normalFlowBranchWeight`, `nearNormal`, `FNear`, `FLiftLine`, `MNear`, and
`MLiftLine` remain only as deprecated diagnostic fields. The tests perturb the
diagnostic branch-weight controls and require unchanged final wing force and
moment.

## What Did Not Change

- GUI code was not modified.
- Trim strategy was not modified.
- `pitchCommand` was not modified.
- The `cos^2/sin^2` longitudinal control allocation was not modified.
- `rotor_model_bemt.m` was not modified.
- Tail models were not modified.
- Default parameters and control limits were not changed.
- The full-angle experimental path remains sealed/opt-in and was not made
  default.

## Documentation Clarifications

- `branchWeight` is not a trim strategy from "Introduction to Flight
  Simulation of Helicopter and Tiltrotor Aircraft".
- `branchWeight` was an old complete-result wing-load blend patch.
- This task replaces that production patch with the NUAA Drones 2022
  Eq. (16)-(22) slipstream/free-stream zone-sum structure.
- The current model remains a conceptual, checkable mechanism model. It is
  not a high-fidelity XV-15 reproduction and is not validated against
  experiment by these tests.
- NUAA Fig. 5/Fig. 6 are not claimed fully passed. The new focused test reports
  only a lightweight trend status from representative trim smoke points.

## Test Coverage

New focused test:

```text
tests/check_wing_nuaa_zone_sum.m
```

It covers:

- source guard against branchWeight complete-load blending;
- `Swss + Swfs = Swing` and nonnegative bounded areas;
- finite real output for low-speed, conversion, and airplane-like conditions;
- final force/moment insensitivity to deprecated branch-weight diagnostics;
- representative trim smoke at helicopter endpoint, 35 m/s 45 deg conversion,
  and 100 m/s airplane endpoint;
- lightweight NUAA Fig. 5/Fig. 6-related status, reported as `PARTIAL` unless
  a future task runs and compares a full documented sweep.
