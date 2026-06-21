# CODEX_TASK.md

STATUS: ACTIVE / GENERAL MODE TRIM CORE

Branch: `feature/general-mode-trim-core`

Base branch: `main`

## Objective

Implement priority item 2 only: a generic, mode-configurable longitudinal symmetric trim core based on the prepared electronic-book method packet.

This project remains an open-loop aircraft-plant model. Do not add flight-control laws, SCAS, autopilot logic, pilot models, or real-aircraft mixer data.

## Read first

Read only:

```text
AGENTS.md
CODEX_TASK.md
docs/EBOOK_MODEL_UPGRADE_PRIORITY.md
docs/ebook_packets/TRIM_METHOD_PACKET.md
analysis/trim_symmetric.m
model/tiltrotor_eom.m
model/total_forces_moments.m
params_nominal.m
tests/run_all_checks.m
```

Then inspect only the existing focused trim tests and direct callers of `trim_symmetric` that are needed for compatibility.

Do not read the 622-page electronic book or unrelated reference PDFs.

## Required implementation

### 1. Generic trim core

Add:

```matlab
[xTrim, uTrim, report] = trim_general(condition, definition, P, opts)
```

Required condition fields:

```text
V, betaM, gamma
```

The definition must explicitly describe:

```text
name/mode
unknownNames
residualNames
fixedStates
fixedControls
initialValues
variableScale
bounds
```

The core must construct the full 9-state and 7-control vectors by name and call the existing `tiltrotor_eom`.

### 2. Definition validation

Before solving, reject:

- unknown/residual count mismatch;
- duplicate unknown names;
- unsupported state, control, or residual names;
- overlap between an unknown and a fixed item;
- malformed, nonfinite, or incorrectly sized initial values/scales/bounds.

Use clear identifiers, including where applicable:

```text
trim_general:UnderdeterminedDefinition
trim_general:OverdeterminedDefinition
trim_general:InvalidDefinition
trim_general:AllocationConstraintRequired
```

Do not silently solve an underdetermined least-squares problem and do not add hidden weights.

### 3. Explicit first definitions

Provide a small definition factory only if it improves clarity, for these modes:

#### `legacy_symmetric`

Unknowns:

```text
theta, collective, cyclicLong
```

Residuals:

```text
udot, wdot, qdot
```

Controls:

```matlab
[collective; 0; cyclicLong; 0; 0; 0; 0]
```

#### `helicopter_longitudinal`

Use the same unknowns and residuals as legacy, with `elevator=0`. First acceptance case is `betaM=0` only.

#### `airplane_longitudinal`

Unknowns:

```text
theta, collective, elevator
```

Residuals:

```text
udot, wdot, qdot
```

Fix `cyclicLong=0` and all differential/lateral controls to zero. First acceptance case is `betaM=pi/2` only.

#### Conversion

Do not implement a default conversion mixer. A definition that exposes `theta, collective, cyclicLong, elevator` with only three equilibrium residuals must fail explicitly and state that an allocation constraint is required.

Do not infer mode from `betaM` and do not invent angle thresholds.

### 4. Legacy compatibility

Keep the public signature of `trim_symmetric` unchanged.

Preserve its current numerical behavior, including:

- exact-hover collective-only path;
- dimensionless forward-flight search;
- current multistart behavior;
- current residual scales, tolerances, limits, and acceptance rules;
- current GUI/service callers.

Choose the least risky architecture: either retain the legacy solver and add the generic core beside it, or make `trim_symmetric` a wrapper only after proving output identity.

Legacy reports must identify compatibility mode. New endpoint definitions must identify their definition name, unknowns, fixed states/controls, commanded/applied controls, and complete state derivative.

### 5. Numerical boundaries

Do not change:

- physical parameters;
- control limits;
- aerodynamic, rotor, mass, or EOM equations;
- induced-flow solver;
- linearization code;
- solver tolerances or iteration limits;
- GUI or service files.

Do not switch to `fsolve`, Optimization Toolbox solvers, or a new Newton/Jacobian algorithm in this task.

For airplane search variables, an elevator search scale of 2 deg is allowed only as a documented `NUMERICAL` scale, not a physical parameter.

## Allowed files

Keep changes within:

```text
CODEX_TASK.md
analysis/trim_general.m
analysis/trim_symmetric.m
analysis/make_trim_definition.m       # optional
tests/check_trim_mode_framework.m
tests/run_all_checks.m                # registration only
docs/TRIM_MODE_FRAMEWORK_AUDIT.md
```

Do not modify GUI, services, model components, `params_nominal.m`, or the electronic-book method packet.

## Staged validation and runtime

### Stage 0 — baseline

Before editing, run only:

- one existing hover trim;
- one existing `V=20 m/s, betaM=0` trim;
- `run_all_checks` once.

Record outputs and runtime. Stop if the baseline fails.

### Stage 1 — static definition tests

Test invalid counts, duplicate/unsupported names, overlaps, malformed values, vector sizes, and explicit conversion-allocation failure.

### Stage 2 — legacy identity

Compare old-compatible results for:

- exact hover;
- `V=20 m/s, betaM=0, gamma=0`.

Target absolute differences:

```text
states/controls <= 1e-10
residual norm difference <= 1e-10
```

Report the actual worst differences. Do not loosen tolerances to hide a changed solution branch.

### Stage 3 — endpoint definitions

Run only:

- helicopter endpoint: `V=20 m/s, betaM=0, gamma=0`;
- airplane endpoint: first try `V=100 m/s, betaM=pi/2, gamma=0`.

Require finite real outputs, residuals below current tolerance, correct fixed controls, and no violated or active control limit.

If the airplane endpoint cannot converge without changing model parameters, stop and report the best residual and active limitation. Do not tune parameters and do not re-enable cyclic to claim airplane success.

### Stage 4 — regression

Only after focused tests pass, run `run_all_checks` once.

Total expected wall time: about 2–6 minutes. Stop before broad sweeps, continuation maps, dense multistart scans, or Jacobian studies.

The known R2021a shutdown `mwboost::archive::archive_exception` must be reported separately when all test assertions completed first.

## Acceptance criteria

The task passes only if:

1. `trim_symmetric` and all existing callers remain compatible;
2. legacy hover and 20 m/s outputs are preserved;
3. the generic core explicitly maps unknowns, fixed values, and residuals;
4. helicopter and airplane endpoints use the intended actuator sets;
5. an underdetermined conversion definition is rejected;
6. no mixer, flight control, real parameter, GUI, Jacobian, linearization, or inflow work is added;
7. focused tests and `run_all_checks` pass, or an airplane endpoint limitation is honestly documented without tuning.

## Closeout

At completion update the status to:

```text
STATUS: COMPLETE / GENERAL MODE TRIM CORE / HOLD
```

Create or update the Draft PR. Commit and push, but do not merge.

Report modified files, architecture choice, definition schemas, legacy worst differences, endpoint results, test runtimes, MATLAB shutdown warning status, commit SHA, PR link, and clean working tree.
