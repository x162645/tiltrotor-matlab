# Current Project Baseline

Last reviewed: 2026-06-30

This file records the current authoritative project state for the tiltrotor MATLAB project. When this document conflicts with executable code or reproducible final validation evidence, the code and evidence take precedence.

## 1. Repository and authoritative branches

- Repository: `x162645/tiltrotor-matlab`
- Local project root: `E:\tiltrotor`
- MATLAB: R2021a
- Body axes: `x forward, y right, z down`
- Default branch `main` is frozen at `e93959452b2bbe66b1e75b8c5938842b33842a7a` and is not the current technical baseline.
- Current physical-model and NUAA trend-validation baseline: `feature/nuaa-equation-17`.
- Current GUI work line: `feature/gui-v1.2-parameter-workbench`, tracked by PR #19.
- NUAA task and review rules: `task/nuaa-trim-trend-validation-20260625`, tracked by Issue #24.

The task branch is an instruction source. The physical branch is the implementation and technical-evidence source.

## 2. Current model scope

The aircraft model currently has nine rigid-body states:

```text
u, v, w, p, q, r, phi, theta, psi
```

The direct control vector has seven inputs:

```text
collective
differential collective
longitudinal cyclic
differential cyclic
aileron
elevator
rudder
```

There is no closed-loop SCAS, inner-loop control law, or outer-loop control law in the current project. The conversion-mode `pitchCommand` is an open-loop trim-layer virtual command used to allocate longitudinal cyclic and elevator. It must not be described as a flight-control system.

## 3. Rotor and inflow implementation

The current rotor model includes a steady first-harmonic flapping solution:

```text
beta = beta0 + beta1c*cos(psi) + beta1s*sin(psi)
```

`beta0`, `beta1c`, and `beta1s` are solved from steady flapping moment residuals and are coupled to the induced-velocity iteration. They are not time states in the nine-state aircraft equations. Therefore, the project has a steady flapping model, not a dynamic flapping-state model.

The active inflow implementation includes:

- NUAA Eq. (12) spatial first-harmonic induced-velocity distribution;
- NUAA Eq. (13) steady induced-velocity iteration;
- coupled steady induced-velocity/flapping convergence.

The project does not currently include dynamic inflow differential states such as Pitt-Peters or Peters-He states.

Legacy empirical flapping gains remain only as compatibility metadata and are not used by the active flapping path.

## 4. Wing slipstream and normal-flow treatment

The active wing-slipstream chain follows NUAA Eqs. (16)-(22):

```text
Eq.16 slipstream area
Eq.17 slipstream-region local velocity
Eq.18 aerodynamic-center position relative to current CG
Eq.19/21 force transformation
Eq.20/22 force and moment assembly
```

`P.rotor.wakeFactor` is retained only for compatibility. It is not read by the active production wing-load calculation.

The old hard near-normal/lift-line switch has been removed. The current wing model evaluates both branches and blends them continuously over a finite normal-flow-ratio band using a smooth transition.

Current executable blend parameters are:

```text
P.wing.normalFlowRatio           = 0.35
P.wing.normalFlowBlendHalfWidth  = 0.15
```

The blend half-width is an `ASSUMED_MODEL_PARAMETER` / code-only continuity device. It is not literature or test data and does not validate the wing aerodynamic model.

## 5. Current nominal longitudinal parameters

The current physical baseline uses:

```text
P.wing.Cm0            = -0.03
P.wing.Cmalpha        = 0.00
P.fuselage.Cmalpha    = 0.00
P.htail.incidence     = -2 deg
P.htail.downwashAlpha = 0.40
P.htail.CLelevator    = 2.00
P.control.elevatorLim = [-20, 20] deg
```

These values include conceptual and calibrated effective parameters. They must not be presented as a complete XV-15 parameter database.

## 6. NUAA-style trim and stability evidence

The final Eq. (17) validation run accepted 100 primary trim points and produced helicopter, airplane, 15-degree conversion, and 75-degree conversion trends.

This is a NUAA-style trend, continuity, and physical-reasonableness baseline. It is not strict quantitative validation against XV-15 or GTRS flight-test data.

Current final stability-map summary:

- airplane mode: 33 points, 0% with candidate positive-real-part roots;
- conversion mode: 54 points, 35.2% with candidate positive-real-part roots;
- helicopter mode: 13 points, 100% with candidate positive-real-part roots.

These are open-loop results from the current low-order nine-state model. They must not be directly generalized to a real aircraft, a high-order rotor model, or a closed-loop flight-control system.

## 7. Superseded conclusions

The following old conclusions are invalid for the current baseline and must not be reused:

- empirical algebraic flapping gains are the active rotor-flapping model;
- steady first-harmonic flapping is still unimplemented;
- the old `nearNormal` hard switch still exists;
- a significant multiple-solution branch exists near 9 m/s;
- the 70 m/s airplane trim requires approximately -37 deg elevator;
- `P.wing.Cm0 = 0` is the current nominal value;
- `P.rotor.wakeFactor` is an active wing-slipstream tuning parameter;
- Issue #24 has not yet been technically executed.

The final branch comparison found no significant 9 m/s branch separation under the current model.

## 8. Berger dissertation model-level distinction

The Berger dissertation explicitly documents a 51-state tiltrotor model and a reduced nine-state quasi-steady rigid-body model.

A possible 19-state intermediate structure can be counted as:

```text
9 rigid-body states + 6 inflow states + 4 nacelle states = 19
```

This 19-state count is a candidate intermediate reduction. It must not be described as a separately established and validated Berger model unless direct dissertation evidence is found.

## 9. Nacelle-angle convention

Always state the convention when comparing documents:

```text
Current project / NUAA betaM:
0 deg  = helicopter mode
90 deg = airplane mode

Berger dissertation delta_nac:
90 deg = helicopter mode
0 deg  = airplane mode
```

Failing to distinguish these definitions reverses the physical interpretation of 15-degree and 75-degree conversion conditions.

## 10. GitHub tracking status

PR #19 is the active GUI work line. As of the 2026-06-30 remote-fact audit, PR #19 is open, draft, and points at `feature/gui-v1.2-parameter-workbench`. Its current body has been updated to refer reviewers to this physical baseline, but the branch still needs reconciliation with `feature/nuaa-equation-17` before any merge decision.

PR #10 is a historical GUI-v1.1 line and is superseded by PR #19. As of the same audit, PR #10 is still open, not merged, and not mergeable; it should be treated as development history rather than a merge candidate.

Issue #24 remains open as the NUAA trend-validation task tracker. Its latest 2026-06-30 status comment says the core technical execution is complete on `feature/nuaa-equation-17`; remaining work is review, branch integration, metadata cleanup, and final lifecycle closure.

## 11. Remote fact-audit snapshot

The 2026-06-30 remote-fact audit recorded:

- `origin/main` at `e93959452b2bbe66b1e75b8c5938842b33842a7a`;
- `origin/feature/nuaa-equation-17` at `4045eed7a72c4e16428da681548ec6ec384b9ceb`;
- `origin/feature/gui-v1.2-parameter-workbench` at `ef8b24e7df5d7c2831c21b089fa151788fd7e2dd`;
- `origin/task/nuaa-trim-trend-validation-20260625` at `83776b2f465be20c311432d05d3ef8ace8e8ba4d`;
- `origin/feature/gui-v1.1-trim-diagnostics` still exists at `ce0d54b024b9b8e73cfb94173a5f48120eb56176`.

Branch relationships from the audit:

- `origin/main...origin/feature/nuaa-equation-17 = 0 20`; `main` is the merge-base and is 20 commits behind the physical branch.
- `origin/feature/gui-v1.2-parameter-workbench...origin/feature/nuaa-equation-17 = 0 10`; the GUI v1.2 branch is an ancestor of the physical branch.

Final validation CSV files record actual run commit `ec30f6b936d256ec4124a38bffe31a12183faeb2`. Later branch commits added validation outputs and this baseline document; that difference is not itself a validation error.

## 12. Review rule for future work

Before answering or changing the project, check whether the claim comes from:

1. current executable code on `feature/nuaa-equation-17`;
2. the final Eq. (17) validation report;
3. PR #19 for current GUI work;
4. Issue #24 and its task branch for execution rules;
5. an older branch, intermediate diagnostic, or superseded conversation conclusion.

Older branches and intermediate outputs must not override the current physical baseline.
