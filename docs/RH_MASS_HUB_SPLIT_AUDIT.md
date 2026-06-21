# RH Mass/Hub Structural Split Audit

## Scope and conclusion

This change resolves only the structural coupling between the equivalent moving-mass CG radius and the rotor-hub tilt radius. It preserves current conceptual behavior and does not establish or insert XV-15 values.

The old active field was `P.mass.RH = 0.75 m`. Production reads were:

- `model/mass_properties.m`: CG-shift equations;
- `model/rotor_model_bemt.m`: absolute hub-position geometry.

The new active fields are:

- `P.mass.RH_mass = 0.75 m`, read only by `mass_properties`;
- `P.rotor.RH_hub = 0.75 m`, read only by `rotor_model_bemt`.

`P.mass.RH` is retained as deprecated compatibility metadata initialized from `P.mass.RH_mass`. Repository production search shows zero reads in `model/` and `analysis/`. Modifying the alias does not affect production results; tests exercise this explicitly.

Repository-wide occurrence review, excluding reference PDFs and `.git`, found:

- old production reads before the split: two CG equations in `model/mass_properties.m` and two hub-coordinate expressions in `model/rotor_model_bemt.m`;
- current old-name test reads: the intentional alias perturbation in `tests/check_mass_inertia_geometry.m`, plus two unchanged compatibility-formula reads in `tests/check_rotor_force_moment_chain.m` (that file is outside this task's modification allowlist);
- current new production reads: two `RH_mass` expressions in `mass_properties` and two `RH_hub` expressions in `rotor_model_bemt`;
- current new-name test reads: analytic identity, decoupling, geometry-helper, and provenance checks in `check_mass_inertia_geometry`;
- documentation occurrences in `CODEX_TASK.md`, the three updated parameter-governance documents, this audit, and historical pre-split audit/correction documents. Historical documents remain unchanged because they are outside the task allowlist; they describe the earlier coupled state rather than active production behavior.

## Formula mapping

Before the split, the CG shift was

```matlab
dx = mNac * RH * sin(betaM) / m;
dz = mNac * RH * (1 - cos(betaM)) / m;
```

and the absolute hub geometry was

```matlab
rHub0 = [pivotX + RH*sin(betaM);
         side*pivotY;
         pivotZ - RH*cos(betaM)];
```

After the split, the formulas, signs, angle convention, CG subtraction, and units are unchanged; only the parameter names differ:

```matlab
dx = mNac * RH_mass * sin(betaM) / m;
dz = mNac * RH_mass * (1 - cos(betaM)) / m;

rHub0 = [pivotX + RH_hub*sin(betaM);
         side*pivotY;
         pivotZ - RH_hub*cos(betaM)];
```

## Targeted verification

`tests/check_mass_inertia_geometry.m` uses `betaM = [0, pi/4, pi/2]` and a `1e-12 m` geometry/decoupling tolerance. It checks:

- unchanged CG shift and absolute hub geometry against the old `0.75 m` formulas;
- finite representative total force/moment outputs at all three angles;
- a synthetic `+0.125 m` `RH_mass` perturbation changes only the analytic CG-radius channel while absolute hub geometry remains governed by `RH_hub`;
- a synthetic `+0.125 m` `RH_hub` perturbation leaves mass properties unchanged while changing hub geometry analytically;
- a synthetic deprecated-alias perturbation leaves mass properties, hub geometry, total forces/moments, and collected representative outputs exactly unchanged;
- all pre-existing mass, inertia, mirror, clearance, component-position, deterministic, and finite checks remain active.

The Stage 0 baseline completed 12/12 test cases in about 14 seconds with 3 `total_forces_moments` calls and 6 `rotor_model_bemt` calls. MATLAB then emitted the known R2021a shutdown-stage `mwboost::archive::archive_exception: output stream error`; this occurred after all test-body assertions passed.

Post-change staged results were:

|stage/check|test-body result|elapsed time|reported model calls|
|-|-|-:|-|
|Stage 1 `check_mass_inertia_geometry`|16/16 PASS|11.623 s|10 `total_forces_moments`, 20 `rotor_model_bemt`|
|Stage 1 `check_rotor_force_moment_chain`|12/12 PASS|11.616 s|8 `total_forces_moments`, 16 `rotor_model_bemt`|
|Stage 1 `check_physical_sanity`|7/7 PASS|11.187 s|not reported by this check|
|Stage 2 `run_all_checks`|13/13 top-level checks PASS|20.067 s|not aggregated; included mass/geometry check reported 10/20 and rotor-chain check reported 8/16|

At the `1e-12 m` tolerance, the worst old-formula errors were `0 m` for CG shift and `4.2909e-18 m` for absolute hub geometry. The synthetic mass-radius perturbation error was `1.7434e-17 m`; all other decoupling geometry errors were `0 m`. The deprecated-alias representative-output comparison was exactly identical with zero norm difference. No test body reported a warning, NaN, Inf, or complex result.

Every MATLAB invocation emitted the known R2021a shutdown-stage `mwboost::archive::archive_exception: output stream error` after its PASS output and final assertion. This shutdown defect is recorded separately and is not reclassified as a model or test-body failure.

## Applicability boundary

Passing these checks proves structural decoupling and preservation of the covered conceptual-model behavior only. Both active values remain `ASSUMED_CONCEPT`; their independent XV-15 target evidence and numeric sourcing remain pending.
