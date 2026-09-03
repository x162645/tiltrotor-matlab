# M1 Stage 3B — Large-Angle Local Inflow Closure Experiment

## Decision

**Retain as a negative/mixed model-form diagnostic; do not promote to the frozen M1 rotor identity and do not replace the production rotor inflow model.**

The experiment imported the large-inflow-angle local closure idea associated with Stahlhut and Sosa Henríquez & Lendraitis (2024) into the existing component-level rotor methodology while keeping the established geometry and section-aerodynamic representation fixed.

The result is reproducible across OARF Run 15, OARF Run 14, and the WADC Run 1–3 transport set:

- CT correlation becomes slightly worse;
- CP correlation improves only modestly;
- FM correlation generally improves;
- the large remaining CT/CP deficit is not closed.

Therefore, within the present component-level XV-15 hover model, the dominant residual cannot be attributed simply to the absence of a Stahlhut-style large-angle **local** inflow closure.

## Model identity

Branch:

`research/m1-large-angle-local-closure-20260902`

The production model and frozen M0 were not modified.

Control model:

`M1_E_FROZEN_CORRIGAN_N1`

Diagnostic model:

`M1_G_LARGE_ANGLE_LOCAL_CLOSURE`

The following were held fixed between M1-E and M1-G:

- XV-15 source-informed metal-blade radial chord distribution;
- nonlinear radial twist distribution;
- NASA TP four-region C81 section aerodynamics;
- local Mach lookup;
- frozen Corrigan generic n=1 rotational correction;
- OARF/WADC collective and tip-speed inputs;
- no target-derived collective offset, CT/CP gain, loss-factor coefficient, or Corrigan-exponent change.

Only the steady axial induced-flow closure was replaced.

## Important pre-experiment audit finding

The existing M1 implementation already evaluates the full local velocity triangle with `hypot` and `atan2` and resolves lift/drag into thrust and torque with full trigonometric functions. Therefore this experiment is **not** a test of merely replacing a small-angle expression such as `phi ~= UP/UT` with `atan2`.

The added physics is deeper:

- nonlinear local solution for inflow angle;
- simultaneous axial and tangential/swirl induction;
- finite drag in the local closure;
- large-angle Prandtl decomposition through `K_T` and `K_P`;
- radial scalar root solution by a bracketed bisection method.

The current implementation is explicitly restricted to steady axial/hover conditions. It is neither a prescribed/free wake nor a nonlocal radial induced-field model.

## Run 15 development correlation

MATLAB R2021a workflow run:

`33705232780`

Artifact:

- ID: `9875018973`
- SHA-256: `4337c93261725abf3b7de68c4c514dead43dccceaf4a3e920d7006af12fa3215`

Fixed OARF Run 15 window: 6–11 deg collective at 0.75R.

| Model | CT MAPE | CP MAPE | FM MAPE |
|---|---:|---:|---:|
| M1-E frozen Corrigan n=1 | 32.7269% | 45.8943% | 7.5918% |
| M1-G large-angle local closure | 33.9080% | 44.8044% | 5.6223% |
| M1-G minus M1-E | **+1.1811 pp** | **-1.0899 pp** | **-1.9695 pp** |

Thus the large-angle closure does not recover missing thrust. CP and FM move in a favorable direction, but at a much smaller magnitude than the remaining deficit.

All six points and all radial elements converged. Maximum scalar root residual remained below approximately `1e-8`.

The solved radial inflow angles demonstrate that the diagnostic is exercising a genuine large-angle regime rather than collapsing numerically to the legacy solution. Across the six Run-15 points, the maximum local inflow angle is approximately 21.5–21.6 deg. The solver also produces nonzero tangential/swirl induction.

## Frozen transport check after Run-15 result

After the Run-15 result was known, the M1-G definition was not changed. A second runner transported the same model to OARF Run 14 and WADC.

MATLAB R2021a workflow run:

`33705678377`

Artifact:

- ID: `9875289025`
- SHA-256: `d3fa0c2c32d0bb4919d3f831c64c6d7e2de1494bb0d48f18ebf1ac9ee024647b`

Two fail-closed identity gates were imposed before transport metrics were accepted:

- factored M1-E helper versus frozen Stage-3 M1-E: maximum CT/CP/FM absolute difference = `0` at all six Run-15 points;
- factored M1-G helper versus the first formal Run-15 M1-G execution: maximum CT/CP/FM absolute difference = `0` at all six points.

### OARF Run 14, 6–11 deg

Run 14 is the same OARF campaign and is therefore not treated as an independent facility validation.

| Model | CT MAPE | CP MAPE | FM MAPE |
|---|---:|---:|---:|
| M1-E | 32.3517% | 48.0471% | 10.0490% |
| M1-G | 33.5234% | 46.9715% | 6.8089% |
| M1-G minus M1-E | **+1.1717 pp** | **-1.0756 pp** | **-3.2400 pp** |

The same qualitative pattern as Run 15 is reproduced.

### WADC Runs 1–3, 15 inherited points

The WADC set is used as cross-facility transport evidence. The already-defined 6–11 deg window was inherited without interpolation; available points are 6, 8, 9, 10, and 11 deg in each of Runs 1–3.

| Model | CT MAPE | CP MAPE | FM MAPE |
|---|---:|---:|---:|
| M1-E | 37.8956% | 51.1078% | 9.2559% |
| M1-G | 39.5429% | 50.6735% | 8.1589% |
| M1-G minus M1-E | **+1.6472 pp** | **-0.4343 pp** | **-1.0970 pp** |

Again, the large-angle local closure does not recover thrust and only slightly changes power correlation.

## Why this does not reproduce the very large improvement reported by Sosa Henríquez & Lendraitis (2024)

The difference is scientifically informative rather than contradictory.

First, their control solver is a conventional BEMT formulation that explicitly neglects large-inflow-angle effects. In the present repository, the M1-E control already uses exact `hypot`/`atan2` local kinematics, full trigonometric force resolution, nonlinear C81 data, and a rotational-stall-delay treatment. Therefore M1-E is not equivalent to their conventional small-angle BEMT baseline.

Second, their reported error construction is not identical to the present validation protocol. Their paper states that the Stahlhut collective progression is aligned between experiment and model, whereas the conventional BEMT solver required higher collective angles to match CP. Their principal statistics are based on delta-CT across the CT-versus-CP relationship. In this repository, experimental collective, tip speed, and atmosphere are frozen point by point and CT and CP are evaluated separately; no collective is shifted to match CP.

Third, their section-aerodynamic construction uses a different airfoil database/extrapolation chain. The present experiment intentionally preserves the repository's existing NASA C81/local-Mach/Corrigan section model so that only the induced-flow closure changes.

For those reasons, the 2024 publication provides a strong hypothesis and model-form source, but its 20–88% to approximately single-digit improvement cannot be transferred as an expected numerical outcome for the current M1 architecture.

## Scientific interpretation

Across three evidence sets the sign is remarkably consistent:

1. M1-G slightly **reduces CT** relative to what would be required to close the experiment-model gap;
2. M1-G tends to alter torque/power in a direction that improves CP and therefore FM;
3. these changes are only of order approximately 0.4–3.2 percentage points in MAPE, not the tens of percentage points required to explain the remaining error;
4. the result persists at WADC, so it is not just an OARF Run-15 numerical accident.

This closes a previously untested local-model hypothesis:

`LARGE_ANGLE_LOCAL_INFLOW_CLOSURE = TESTED_NOT_DOMINANT_FOR_REMAINING_CT_DEFICIT`

It does **not** close the broader wake hypothesis. A local annular/Stahlhut-style closure cannot represent radial nonlocal induction, finite-blade wake geometry, tip-vortex trajectory, wake contraction, or Biot–Savart coupling between blade sections.

## Route implication

Do not promote M1-G simply because its FM is lower-error. The primary unresolved absolute CT/CP deficit remains large, and the CT correlation becomes worse on every tested data set.

The next rotor-physics question, if further rotor refinement is justified, must therefore be different from another local BEMT closure adjustment. Candidate work should be framed around genuinely nonlocal induced-field/wake physics or other independently supported model-form gaps, with the same rule that OARF/WADC targets are not used to tune empirical gains.

This experiment should remain in the evidence chain as a negative/mixed result because it materially narrows the plausible explanation space.
