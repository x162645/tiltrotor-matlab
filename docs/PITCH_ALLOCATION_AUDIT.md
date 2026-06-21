# Open-loop pitch allocation audit

## Scope and interpretation

This audit records the read-only Stage 0 baseline and Stage 1 local control-sign
checks performed on branch `feature/open-loop-pitch-allocation` before the
allocation implementation. It verifies command direction and local control
authority only. It does not validate a real-aircraft mixer, establish XV-15
fidelity, or prove that the 35 m/s, 45 deg condition can be trimmed.

The state order is `[u v w p q r phi theta psi]` and the control order is
`[collective diffCollective cyclicLong diffCyclic aileron elevator rudder]`.
Angles and controls are in rad. The derivative audit used a central difference
step of `h = 1e-4 rad` and evaluated `xdot(5) = qdot`.

## Stage 0 baseline

| Check | Result | Runtime |
|---|---:|---:|
| `check_trim_mode_framework` | PASS | 84.230 s |
| `run_all_checks` | PASS, 14/14 checks | 97.123 s |
| helicopter endpoint trim | PASS | 9.470892 s |
| airplane endpoint trim | PASS | 12.814452 s |

The framework check reported zero legacy state, control, and residual-norm
differences. Its helicopter and airplane residual norms were respectively
`3.721e-10` and `1.702e-09`.

### Helicopter endpoint: V=20 m/s, betaM=0, gamma=0

```text
x = [ 1.997053126062e+01, 0, 1.085302339798e+00, 0, 0, 0,
      0, 5.429178478438e-02, 0 ]
u = [ 2.647391468318e-01, 0, -2.429163307879e-02, 0, 0, 0, 0 ]
residual = [ 3.197786403083e-10, -1.364254179255e-10,
            -1.327491659116e-10 ]
residualNorm = 3.721459586020e-10
```

The solution converged, remained within and away from active limits, and all
reported states, controls, and derivatives were finite and real.

### Airplane endpoint: V=100 m/s, betaM=pi/2, gamma=0

```text
x = [ 9.966102507257e+01, 0, 8.226790472920e+00, 0, 0, 0,
      0, 8.236098680818e-02, 0 ]
u = [ 6.341324396338e-01, 0, 0, 0, 0, -2.710882650164e-01, 0 ]
residual = [ -6.999099847841e-10, -1.531614543637e-09,
              2.505653751302e-10 ]
residualNorm = 1.702498195093e-09
```

The solution converged, remained within and away from active limits, and all
reported states, controls, and derivatives were finite and real.

## Stage 1 local sign and authority audit

| Local evaluation state | Trim status | d(qdot)/d(cyclicLong) | Sign | d(qdot)/d(elevator) | Sign |
|---|---|---:|:---:|---:|:---:|
| 20 m/s, 0 deg | converged, no active limit | `-7.801879079637e-01` | - | `-2.903485766688e-01` | - |
| 35 m/s, 45 deg | **not converged; cyclic at lower limit** | `-3.342473553242e-01` | - | `-7.729713186257e-01` | - |
| 100 m/s, 90 deg | converged, no active limit | `-3.218810023546e-02` | - | `-7.631271253833e+00` | - |

All six derivatives were finite and real. The expected active-channel values,
`-7.801879079637e-01` at the helicopter endpoint and
`-7.631271253833e+00` at the airplane endpoint, were clearly above numerical
noise. No direction reversal was observed across the three local states.

The 20 m/s and 100 m/s states and controls are recorded in Stage 0. The 45 deg
legacy-compatible local evaluation state was:

```text
x = [ 3.453573713075e+01, 0, 5.681800844439e+00, 0, 0, 0,
      0, 1.630587793002e-01, 0 ]
u = [ 2.930642991390e-01, 0, -6.108652383589e-01, 0, 0, 0, 0 ]
residual = [ 1.520606066455e+00, 1.052508051449e+00,
            -1.397373090473e-01 ]
residualNorm = 1.854600367531e+00
```

This old legacy state did **not** converge. Its `cyclicLong` was exactly
`-35 deg` (`-0.6108652383589 rad`) and active at the lower limit. It was used
only as a local sign-audit state and must not be described as a valid trim.

## Selected directions

For a positive virtual pitch command to produce positive `qdot` under the
current code convention, the audited mappings are:

```text
cyclicDirection   = -1
elevatorDirection = -1
```

These directions are supported by the current control-vector definitions and
the numerical perturbations above. Derivative magnitudes were not used to tune
the cosine allocation weights.

## Stage 2-3 implementation gate outcome

The pure `ASSUMED_CONCEPT` allocation schedule passed its static checks at
`betaM = [0,15,30,45,60,75,90] deg`. The MATLAB-internal runtime was
`0.165315 s`. The gains were finite, real, bounded, complementary, and
monotonic; endpoint and 45 deg identities and invalid-input errors passed.

Endpoint-equivalence checks also passed:

| Endpoint | Max state difference | Max control difference | Residual-norm difference |
|---|---:|---:|---:|
| helicopter | `1.727e-09` | `1.935e-11` | `9.680e-10` |
| airplane | `1.297e-09` | `6.693e-11` | `3.021e-09` |

All differences were below the required `1e-8` thresholds. The focused-test
runtimes were `17.757 s` for the first helicopter endpoint run and `37.175 s`
for the first airplane endpoint run. A repeated focused run after explicit
optimizer-domain handling took `16.467 s` and `35.072 s`, respectively.

The single required conversion point at `V=35 m/s`, `betaM=pi/4`, `gamma=0`
did not pass. The final diagnostic result was:

```text
x = [ 3.425560862991e+01, 0, 7.180061099621e+00, 0, 0, 0,
      0, 2.066114501118e-01, 0 ]
u = [ 2.963750203604e-01, 0, -3.054326190990e-01, 0, 0,
     -3.490658503989e-01, 0 ]
residual = [ 2.082243876843e+00, 1.917772284146e+00,
            -1.605274044366e-01 ]
residualNorm = 2.835376367268e+00
pitchCommand = 1.000000000000e+00
```

The solver returned `exitflag=1`, but the trim acceptance result was false.
`pitchCommand` was active at its upper bound. `theta`, `collective`,
`cyclicLong`, and `elevator` were within and away from their limits. All state,
control, and derivative values were finite and real. The actuator mapping was
exact at the displayed precision:

```text
cyclicLong expected = actual = -3.054326190990e-01 rad
elevator   expected = actual = -3.490658503989e-01 rad
```

There were 141 rejected objective evaluations outside the explicit
`pitchCommand` domain, all identified as
`pitch_allocation_schedule:InvalidPitchCommand`. No clipping was introduced.
The final single-point diagnostic runtime was `34.724451 s`.

Per the task stop condition, no parameter, control limit, solver tolerance,
direction, schedule weight, aerodynamic model, or plant equation was changed.
The allocation test was not registered in `run_all_checks`, and Stage 4 total
regression was not run. The branch remains on HOLD for review of the 45 deg
conversion limitation.

## Authority-preserving read-only feasibility diagnostic

A subsequent read-only diagnostic retained the same directions and cosine
ratio but normalized the available authority by `max(gCyclic,gElevator)` for
the single 35 m/s, 45 deg condition. Two explicitly authorized initial values
were used; no operating-condition scan or parameter change was performed.

| Seed | exitflag | theta | collective | normalized authority command | residual norm | invalid evaluations | runtime |
|---|---:|---:|---:|---:|---:|---:|---:|
| current conversion initial | 1 | `3.404372101535e-01` | `2.615452255016e-01` | `9.337039599145e-01` | `3.187913604244e-09` | 4 | 11.260173 s |
| boundary-informed initial | 1 | `3.404372102836e-01` | `2.615452254391e-01` | `9.337039599390e-01` | `1.043533618256e-09` | 2 | 7.258428 s |

The better result used:

```text
cyclicLong = -5.703672918946e-01 rad
elevator   = -6.518483335938e-01 rad
residual   = [9.664557486152e-10, 3.828778668928e-10,
             -9.127013445538e-11]
```

No state, virtual command, or direct actuator was at or beyond a limit, and all
states, controls, and derivatives were finite and real. This isolated the root
cause: the original fixed `pitchCommand` range `[-1,1]` provided only 50% of
each direct actuator reference at 45 deg because both raw cosine gains are
0.5. The direct cosine ratio itself was not the cause.

The reviewed final correction therefore keeps the original direct-actuator
mapping and changes only the virtual-command range:

```text
authorityDenominator = max(gCyclic,gElevator)
pitchCommandLimit = 1/authorityDenominator
-pitchCommandLimit <= pitchCommand <= pitchCommandLimit
```

At 45 deg, `pitchCommandLimit=2`. The read-only normalized authority command
`0.933703959939` corresponds to an original-cosine `pitchCommand` of about
`1.867407919878`; this value is diagnostic evidence and is not hard-coded.
Both direct actuators use about 93.37% of their reference travel, leaving about
6.63% authority margin. The low margin is recorded for later trim-credibility
diagnostics and is not tuned in this task.

## Final dynamic-command implementation result

The reviewed dynamic command range was implemented while preserving the raw
cosine actuator mapping:

```text
gCyclic   = cos(betaM)^2
gElevator = sin(betaM)^2
authorityDenominator = max(gCyclic,gElevator)
pitchCommandLimit = 1/authorityDenominator
normalizedPitchCommand = pitchCommand/pitchCommandLimit
```

Static tests confirmed that `pitchCommandLimit` is finite and real, lies in
`[1,2]`, equals 1 at both endpoints, and equals 2 at 45 deg. A boundary command
uses the full reference travel of at least one direct actuator without hidden
clipping. The actuator outputs continue to use the original `gCyclic` and
`gElevator` formulas.

Endpoint equivalence remained within the required `1e-8` thresholds:

| Endpoint | Max state difference | Max control difference | Residual-norm difference |
|---|---:|---:|---:|
| helicopter | `1.727e-09` | `1.935e-11` | `9.680e-10` |
| airplane | `1.297e-09` | `6.693e-11` | `3.021e-09` |

The final 35 m/s, 45 deg conversion trim was:

```text
x = [ 3.299130700016e+01, 0, 1.168647348095e+01, 0, 0, 0,
      0, 3.404372103090e-01, 0 ]
u = [ 2.615452254109e-01, 0, -5.703672920348e-01, 0, 0,
     -6.518483337541e-01, 0 ]
pitchCommand = 1.867407919878 approximately
pitchCommandLimit = 2
normalizedPitchCommand = 0.933703959939 approximately
residual = [ -3.767478726028e-10, 5.692891136277e-10,
              9.395500474211e-11 ]
residualNorm = 6.890984e-10
```

The solution converged, remained within the dynamic virtual-command and direct
actuator limits, and all states, controls, and derivatives were finite and
real. Cyclic and elevator reference-travel usage were both `0.933704`, leaving
`0.066296` (about 6.63%) margin on each actuator. This low margin is recorded
only; no parameter, limit, direction, cosine ratio, or solver tolerance was
changed.

The focused allocation suite passed all four cases in `45.155525 s`. After the
allocation test was registered, the complete internal regression passed all
15 checks in `79.720065 s`. These tests establish covered-condition internal
consistency only and do not constitute real-aircraft or XV-15 validation.
