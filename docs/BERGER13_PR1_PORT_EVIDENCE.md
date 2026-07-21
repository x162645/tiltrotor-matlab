# Berger13 PR1 selective-port evidence

## Frozen references

| Role | Ref | SHA | Use in PR1 |
|---|---|---|---|
| Accepted physical base | `origin/feature/nuaa-equation-17` | `3550e5b855bac1c38e9d275cf3f8e608cb519c70` | Worktree base and retained production physics |
| Research audit source | `origin/codex/lateral-directional-input-audit` | `370c7aef13a5dca98c0436616548729859c399a9` | Selective interface/scaffold reference only |

The audit-source history was not merged, rebased, or cherry-picked. PR #40
through PR #48 and their code/results were not ported.

## Baseline-before-change evidence

Before any PR1 file was created, MATLAB R2021a ran the frozen base from the
isolated implementation worktree:

```text
F:\matlab\R2021a\bin\matlab.exe -batch
  "cd('E:\tiltrotor-berger13-pr1'); startup; summary=run_all_checks;
   assert(summary.allPassed);"
```

Result: all 18 pre-existing checks passed (`summary.allPassed=1`), including
the focused NUAA Eq. (12)/(13)/(16)/(17), rotor, flapping, control,
near-normal wing blend, trim-framework, credibility, and legacy
linearization checks. Recorded MATLAB runtime was 250.105751 seconds. This is
internal regression evidence, not aircraft-type validation.

## Selective implementation inventory

| PR1 file/function | Selective origin | What was retained or changed |
|---|---|---|
| `model/berger13/get_state_names_13x10.m` | research commit `8d8803e` concept | Reviewed 13-state order; rewritten/verified against the reviewed task |
| `model/berger13/get_state_units_13x10.m` | new PR1 evidence | Explicit units paired with every state |
| `model/berger13/get_control_input_names_13x10.m` | research commit `8d8803e` concept | Reviewed 10-input order |
| `model/berger13/get_control_input_units_13x10.m` | new PR1 evidence | Explicit units paired with every input |
| `model/berger13/params_berger13.m` | research commit `8d8803e` concept | Isolated base wrapper; every low-order nacelle value remains `RESEARCH_PLACEHOLDER` |
| `model/berger13/rotor_model_bemt_berger13.m` | physical base `3550e5b`; lateral mapping selectively adapted from `8d8803e` | Namespace-local copy of baseline rotor; only `theta1c=rotDir*lateralCyclic` added |
| `model/berger13/compute_berger13_rotor_loads.m` | research commit `d79858e` concept | Independent left/right rotor replacement, rewritten for base-info compatibility |
| `model/berger13/total_forces_moments_13x10.m` | research commits `8d8803e`/`d79858e` concepts | Legacy mean-angle stack plus isolated rotor correction and limitation diagnostics |
| `model/berger13/tiltrotor_eom_13x10.m` | research commit `8d8803e` concept | First nine rigid-body equations plus reviewed uncoupled placeholder nacelle equation |
| `analysis/berger13/linearize_13x10_numeric.m` | research commit `8d8803e` concept | Reworked with `h/10,h,10h` support, bounds, and reported difference schemes |
| `analysis/berger13/run_berger13_smoke.m` | research commit `8d8803e` concept | Lightweight finite/dimension smoke entry point |
| `tests/check_berger13_interface.m` | rewritten for reviewed PR1 | Names/units, provenance, exact NUAA degradation, independent loads, mirror relation, torque signs, legacy invariants |
| `tests/check_berger13_linearization.m` | rewritten for reviewed PR1 | Three-step stability, endpoint schemes, finiteness, and nonlinear/linear increment convergence |
| `tests/run_all_checks.m` | physical base plus minimal registration | Adds only Berger13 paths and two PR1 checks |

Research-source derivative-report, conditioning, nullspace, trim, GUI,
full-angle, external-comparison, and later-PR files were deliberately excluded.
No historical validation report was copied or modified.

## Regression evidence and acceptance boundaries

The focused PR1 checks require:

- exact state/input names, units, dimensions, and placeholder provenance;
- equal nacelle angles plus zero lateral cyclic to reproduce the frozen
  nine-state NUAA path, with reported force, moment, and first-nine derivative
  differences;
- independent left/right rotor-angle activation and exchange symmetry;
- unchanged legacy seven-input validation and wing blend defaults;
- finite `13x13`/`13x10` matrices at `h/10`, `h`, and `10h`;
- boundary-aware forward/backward nacelle-angle columns;
- decreasing nonlinear-versus-linear local increment error.

At the focused operating point, the symmetric degradation differences were
exactly zero to printed precision for force, moment, and the first nine state
derivatives. Three-step key-column relative variations were `6.525e-09` and
`6.530e-07`; local increment errors at scales `1`, `1/2`, and `1/4` were
`3.863e-06`, `9.657e-07`, and `2.414e-07`. These observations apply only to
the tested internal cases and do not imply formal trim, mode, handling-quality,
or external validation.

The final MATLAB R2021a `run_all_checks` run passed all 20 checks (the 18
frozen-base checks plus two PR1 checks), with
`FINAL_ALL_PASSED=1`, `FINAL_TEST_COUNT=20`, and recorded test runtime
`285.411621` seconds. The namespace smoke check, interface check, linearization
check, and MATLAB `checkcode` scan also completed successfully before the full
suite.

No default physical parameter, control limit, trim tolerance, NUAA equation,
production model file, GUI file, or verification dataset was adjusted to make
these checks pass. The implementation HEAD is recorded in the Draft PR because
the HEAD is created only after this evidence file is committed.

## Remaining physics boundary

Only rotor loads receive independent nacelle angles. Non-rotor aerodynamics
and wing slipstream remain mean-angle approximations. Reaction torque,
moving-mass effects, `I_dot*omega`, gyroscopic/transmission coupling, actuator
closed-loop dynamics, formal 13-state trim, modes, failures, and external
validation remain unimplemented. This is a 13-state research scaffold, not a
Berger 51-state reproduction. PR2 through PR4 were not executed.
