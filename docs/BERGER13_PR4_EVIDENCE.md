# Berger13 PR4 modal and time-domain research evidence

## Version and scope

- Base: `codex/berger13-pr3-commanded-actuator-independent-wing@247e3a4b46d39b375152fd5fa8bea9e7a4ba9e74`.
- Head branch: `codex/berger13-pr4-modes-time-domain-study`.
- Task-contract commit: `b7da3e6c1f5469fafc3c602f6b6d28b6d694d13d`.
- Adds credible-point command A/B databases, stable/control derivatives, left/right eigenvectors and participation, Hungarian mode tracking, nonlinear command/fault simulation, linear/nonlinear comparison, sensitivity sweeps, and traceable PNG/SVG/CSV/MAT output.

## Operating-point and derivative evidence

The nine-point formal grid remains unchanged: 7 `CREDIBLE`, 2 `FAILED`. Failed points B75_V040 and B75_V060 retain residual norms 4.603 and 1.315 at the -20 deg elevator boundary and are excluded from modal claims.

At B45_V035 the maximum three-step matrix variation is `2.85e-6`. Selected derivatives are:

|Derivative|Value|
|-|-:|
|Xu|-0.1196688|
|Zw|-0.3399684|
|Mq|-0.5078054|
|Yv|-0.1043340|
|Lp|-1.6928933|
|Nr|-0.4634783|
|dv/dBetaDiff|0.3132144 (m/s^2)/rad|
|dp/dBetaDiff|16.7524252 (rad/s^2)/rad|
|dr/dBetaDiff|-0.5566303 (rad/s^2)/rad|

## Modal evidence

`analyze_berger13_modes` computes biorthogonal left/right eigenvectors, normalized state/control participation, damping, frequency, time/doubling/halving constants, and symmetric/differential nacelle participation. B45_V035 contains:

- Dutch-roll-like pair `-0.08357 +/- 0.77194i s^-1`, damping 0.1076.
- Short-period-like pair `-0.46688 +/- 1.09949i s^-1`, damping 0.3909.
- Roll-like root `-2.02076 s^-1`.
- Longitudinal aperiodic root `+0.03993 s^-1`; the low-order open-loop point is locally unstable.
- Symmetric and differential actuator pairs `-3.2 +/- 2.4i s^-1`, damping 0.8.

Mode names combine eigenvectors, participation, sym/diff structure, and adjacent-point continuity. They remain low-order interpretations, not externally validated handling-quality modes.

## Time-domain and sensitivity evidence

Fourteen nonlinear cases cover symmetric step/ramp, differential step, rate/bandwidth/damping mismatch, single-side delay/stuck/rate degradation/freeze, conversion lateral pulse, and three open-loop control responses. The most severe covered mismatch is left stuck/frozen command: maximum betaDiff `0.044112 rad`, roll moment `6.552 kN m`, yaw moment `7.033 kN m`, and attitude deviation `1.094 rad`; it does not numerically diverge in 5 s but does not recover. A 0.30 s left delay gives betaDiff `0.020110 rad` and combined peak roll/yaw metric `4.745 kN m`.

Sensitivity uses a documented same-unit primary metric per parameter. Command bandwidth, damping, lateral-cyclic mapping, acceleration limit, single-side bandwidth/damping, and delay are assumption-dependent over the scanned ranges. Moving mass and wake area show robust trends within the selected ranges. Rate and torque limits are classified `CANNOT_RELIABLY_DETERMINE` when the selected excitation does not activate them.

## Linear/nonlinear consistency

Five small steps compare ten states. Maximum RMS error is `8.58e-4` for betaDiffCommand; the other four maximum RMS errors range from `1.59e-8` to `1.17e-5`. This is local numerical consistency only.

## MATLAB R2021a evidence

- Pre-change full regression: 22/22 passed, 340.862 s.
- Focused PR4 workflow: 6/6 passed. It covers biorthogonality, participation normalization, known Hungarian optimum, identical-model tracking, finite nonlinear simulation, and ten-state linear/nonlinear comparison.
- Complete research workflow: `RESEARCH_FINITE_REAL=1`; 7 credible/2 failed points; 21 PNG + 21 SVG figures and paired raw-data files.
- Final all-file `checkcode`: zero findings.
- Post-change full regression: 23/23 passed, `PR4_FINAL_ALL_PASSED=1`, 350.383 s.

The final head SHA is recorded in the Draft PR and final GitHub evidence index after the implementation/results commit exists.

## Claim boundary

The work establishes implementation coverage and internal numerical consistency for an assumed low-order research model. It does not reproduce Berger's 51 states, identify XV-15 parameters, validate against flight/ground test data, or certify handling qualities.
