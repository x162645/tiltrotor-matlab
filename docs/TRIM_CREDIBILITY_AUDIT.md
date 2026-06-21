# Trim credibility diagnostics audit

Status: Stage 4 closeout for `feature/trim-credibility-diagnostics`.

This audit documents numerical credibility diagnostics for existing trim
solutions. It does not claim XV-15 or flight-test validation. No model
equations, parameters, limits, trim tolerances, solver settings, or pitch
allocation rules were changed to obtain these results.

## Method

The production interface is:

```matlab
credibility = diagnose_trim_credibility( ...
    condition, definition, xTrim, uTrim, trimReport, P, opts)
```

The diagnostic is read-only with respect to the supplied trim solution.

- `Jraw` is the finite-difference Jacobian of selected trim residuals with
  respect to physical trim unknowns.
- `Jscaled` is the solver-scaled Jacobian:

  ```text
  Jscaled = diag(1./residualScale) * Jraw * diag(variableScale)
  ```

- The finite-difference scaled steps are:

  ```text
  hScaled = [1e-2, 1e-3, 1e-4]
  ```

- Central differences are used when both perturbation directions are legal.
  If a trim unknown bound or generated actuator limit blocks central
  differencing, the diagnostic uses second-order forward or backward
  one-sided differencing. It does not clip invalid perturbed points.
- SVD, default rank, effective rank, effective-rank tolerance, and condition
  number are computed from the primary `hScaled = 1e-3` `Jscaled`.
- Effective rank uses:

  ```text
  effectiveRankTolerance = 1e-8 * sigmaMax
  ```

- Condition number levels:

  ```text
  <= 1e3       LOW
  1e3 to 1e6   CAUTION
  > 1e6        SEVERE
  ```

- Step sensitivity compares the `1e-2` and `1e-4` scaled Jacobians against the
  primary `1e-3` Jacobian using Frobenius relative change and singular-value
  relative changes.
- Full nine-state derivatives are retained in order:

  ```text
  udot vdot wdot pdot qdot rdot phidot thetadot psidot
  ```

- Translational accelerations are scaled by `g`; angular accelerations and
  Euler-angle rates are scaled by `1`.
- Margins are computed for bounded trim unknowns and generated direct
  actuators:

  ```text
  marginAbsolute = min(value-lower, upper-value)
  marginFraction = 2*marginAbsolute/(upper-lower)
  ```

- Margin levels:

  ```text
  >= 0.10       ADEQUATE
  0.02 to 0.10  LOW
  < 0.02        CRITICAL
  ```

- The diagnostic also records maximum commanded/applied control difference.
- Stage 3 sensitivity diagnostics are opt-in:
  - `runSeedSensitivity`, default `false`;
  - `runConditionSensitivity`, default `false`.
- Default calls keep:
  - `seedSensitivity.status = NOT_RUN`;
  - `conditionSensitivity.status = NOT_RUN`;
  - both with `reason = STAGE_3_NOT_REQUESTED`.
- Stage 3 seed sensitivity uses exactly two deterministic seeds:

  ```text
  seedPlus  = zTrim + 0.25*variableScale.*[+1,-1,+1]'
  seedMinus = zTrim - 0.25*variableScale.*[+1,-1,+1]'
  ```

- Stage 3 local condition sensitivity uses exactly four local conversion
  points:
  - `V=34.5 m/s, betaM=45 deg`;
  - `V=35.5 m/s, betaM=45 deg`;
  - `V=35 m/s, betaM=44.5 deg`;
  - `V=35 m/s, betaM=45.5 deg`.

### PASS / CAUTION / FAIL rules

`FAIL` is assigned if any of the following are true:

- the original trim did not converge;
- primary diagnostic data are non-finite or complex;
- effective rank is deficient;
- any trim variable or generated actuator is outside limits;
- commanded/applied control mismatch exceeds the threshold;
- the full scaled derivative exceeds the trim tolerance;
- a deterministic seed result is non-finite, outside limits, or not
  converged.

`CAUTION` is assigned when there is no `FAIL`, but any of the following are
true:

- `conditionNumber > 1e3`;
- Jacobian step variation is greater than 5%;
- any `marginFraction < 0.10`;
- one-sided finite differences are used;
- non-primary steps have unavailable Jacobian columns;
- a deterministic seed converges while at a limit;
- deterministic seeds may indicate solution-branch sensitivity;
- local-condition credibility produces a warning.

`PASS` is assigned only when there is no `FAIL` or `CAUTION`.

`CAUTION / LOW_MARGIN`表示该工况存在可信的配平解，但可用操纵裕度偏低；本任务没有通过调参、扩大限幅或修改分配规律消除该警告。

## Shared trim-point construction compatibility

`trim_general` now delegates the mode-dependent trim point construction and
residual evaluation to `evaluate_trim_definition_point`. The Stage 2
compatibility gate compared the previous inline construction with the shared
path for:

- legacy hover;
- legacy `20 m/s`;
- `helicopter_longitudinal`, `V=20 m/s`, `betaM=0`;
- `conversion_longitudinal`, `V=35 m/s`, `betaM=45 deg`;
- `airplane_longitudinal`, `V=100 m/s`, `betaM=90 deg`.

For all five cases, `x`, `u`, residual, full-state derivative, and complete
trim report were `isequaln` identical with zero numerical difference. The
focused `check_trim_credibility` test also verifies current `trim_general`
outputs are exactly reproduced by the shared evaluator at the representative
trim points.

## Representative results

### Helicopter longitudinal: V=20 m/s, betaM=0

- Final status: `PASS`
- Reasons: `NONE`
- Final state `x`:

  ```text
  [1.997053126062e+01
   0.000000000000e+00
   1.085302339798e+00
   0.000000000000e+00
   0.000000000000e+00
   0.000000000000e+00
   0.000000000000e+00
   5.429178478438e-02
   0.000000000000e+00]
  ```

- Residual norm: `3.721459586020e-10`
- Singular values: `[1.523720199089e+00, 4.607758542030e-02, 3.289070579780e-02]`
- Default rank / effective rank: `3 / 3`
- Effective-rank tolerance: `1.523720199089e-08`
- Condition number: `4.632677110841e+01`
- Condition level: `LOW`
- Maximum Jacobian step variation: `3.966302254045e-05`
- Step-variation level: `STABLE`
- Minimum margin: `4.333838795816e-01`
- Minimum-margin item: `collective`, `ADEQUATE`
- Full derivative:

  ```text
  [ 3.197786403083e-10
   -4.973799150321e-17
   -1.364254179255e-10
   -1.797953349358e-18
   -1.327491659116e-10
   -4.045395036056e-17
    0.000000000000e+00
    0.000000000000e+00
    0.000000000000e+00]
  ```

- Maximum scaled full derivative: `1.327491659116e-10`
- Commanded/applied maximum difference: `0`

### Conversion longitudinal: V=35 m/s, betaM=45 deg

- Final status: `CAUTION`
- Reasons: `LOW_MARGIN`
- Final state `x`:

  ```text
  [3.299130700016e+01
   0.000000000000e+00
   1.168647348095e+01
   0.000000000000e+00
   0.000000000000e+00
   0.000000000000e+00
   0.000000000000e+00
   3.404372103090e-01
   0.000000000000e+00]
  ```

- Residual norm: `6.890983945141e-10`
- Singular values: `[1.698819582804e+00, 8.930059330861e-02, 1.944498639080e-02]`
- Default rank / effective rank: `3 / 3`
- Effective-rank tolerance: `1.698819582804e-08`
- Condition number: `8.736542925062e+01`
- Condition level: `LOW`
- Maximum Jacobian step variation: `2.610572469447e-05`
- Step-variation level: `STABLE`
- Minimum margin: `6.629603983138e-02`
- Minimum-margin item: `pitchCommand`, `LOW`
- Other LOW margin items: `cyclicLong`, `elevator`
- Full derivative:

  ```text
  [-3.767478726028e-10
   -1.444770229379e-16
    5.692891136277e-10
   -7.834336488663e-16
    9.395500474211e-11
   -3.434911853889e-16
    0.000000000000e+00
    0.000000000000e+00
    0.000000000000e+00]
  ```

- Maximum scaled full derivative: `9.395500474211e-11`
- Commanded/applied maximum difference: `0`

Known core values:

```text
conversion:
CAUTION / LOW_MARGIN
minimumMarginFraction = 0.06629604
conditionNumber = 87.365429
maximumStepVariation = 2.611e-05
```

### Airplane longitudinal: V=100 m/s, betaM=90 deg

- Final status: `PASS`
- Reasons: `NONE`
- Final state `x`:

  ```text
  [9.966102507257e+01
   0.000000000000e+00
   8.226790472920e+00
   0.000000000000e+00
   0.000000000000e+00
   0.000000000000e+00
   0.000000000000e+00
   8.236098680818e-02
   0.000000000000e+00]
  ```

- Residual norm: `1.702498195093e-09`
- Singular values: `[2.716143848550e+00, 8.546909989199e-01, 8.649155631209e-02]`
- Default rank / effective rank: `3 / 3`
- Effective-rank tolerance: `2.716143848550e-08`
- Condition number: `3.140357237589e+01`
- Condition level: `LOW`
- Maximum Jacobian step variation: `2.675848046259e-05`
- Step-variation level: `STABLE`
- Minimum margin: `6.116946634759e-01`
- Minimum-margin item: `elevator`, `ADEQUATE`
- Full derivative:

  ```text
  [-6.999099847841e-10
   -5.329070518201e-18
   -1.531614543637e-09
   -9.282270191524e-16
    2.505653751302e-10
   -2.148443048427e-15
    0.000000000000e+00
    0.000000000000e+00
    0.000000000000e+00]
  ```

- Maximum scaled full derivative: `2.505653751302e-10`
- Commanded/applied maximum difference: `0`

## Stage 3 sensitivity results

Baseline:

```text
mode  = conversion_longitudinal
V     = 35 m/s
betaM = 45 deg
gamma = 0
```

### Deterministic seed sensitivity

Both deterministic seeds converged within limits and were classified
`CONSISTENT`.

| Seed | Converged | Residual norm | Max state difference | Max control difference | Runtime |
|---|---:|---:|---:|---:|---:|
| `seedPlus` | 1 | `1.876229115174e-09` | `2.916859642710e-09` | `1.313226194455e-10` | `10.043434 s` |
| `seedMinus` | 1 | `6.193189132000e-10` | `1.317983944205e-09` | `2.388933495467e-11` | `9.976337 s` |

Overall maximum state difference:

```text
2.916859642710e-09
```

No solution-branch sensitivity was found under the Stage 3 threshold
`1e-6`.

### Local condition sensitivity

All four local conversion conditions converged, remained finite and real, kept
full effective rank, had `LOW` condition-number level, and had zero
commanded/applied difference. All four were classified `CAUTION` due to
`LOW_MARGIN`. The `44.5 deg` and `45.5 deg` cases were stored and evaluated as
independent results; they were not averaged into a symmetric derivative.

| Condition | Converged | Residual norm | Condition number | Condition level | Minimum margin | Status | Reason |
|---|---:|---:|---:|---|---:|---|---|
| `V=34.5, betaM=45 deg` | 1 | `9.910605843063e-10` | `8.736809505117e+01` | `LOW` | `6.394548528539e-02` | `CAUTION` | `LOW_MARGIN` |
| `V=35.5, betaM=45 deg` | 1 | `1.148335967846e-09` | `8.735908404162e+01` | `LOW` | `6.886406218979e-02` | `CAUTION` | `LOW_MARGIN` |
| `V=35, betaM=44.5 deg` | 1 | `5.712986461368e-10` | `8.603442385441e+01` | `LOW` | `6.533644466403e-02` | `CAUTION` | `LOW_MARGIN` |
| `V=35, betaM=45.5 deg` | 1 | `6.259413492010e-10` | `8.854631962644e+01` | `LOW` | `3.473459775188e-02` | `CAUTION` | `LOW_MARGIN` |

The local condition numbers are all about `86-89`. The worst condition number
among these four cases is `8.854631962644e+01` at `V=35 m/s, betaM=45.5 deg`.

The lowest margin observed across the representative and Stage 3 sensitivity
results is `3.473459775188e-02` at `V=35 m/s, betaM=45.5 deg`, on
`pitchCommand` and `elevator`. This remains a `LOW` margin, not a `CRITICAL`
margin.

No Stage 3 result contained `NaN`, `Inf`, or complex values.
