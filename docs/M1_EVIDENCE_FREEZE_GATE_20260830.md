# M1 Evidence Freeze Gate — 2026-08-30

## Decision

**PASS WITH DOMAIN CAVEAT — freeze `M1_EVIDENCE_V1` for downstream whole-aircraft propagation.**

This gate freezes an evidence package, not the lowest-OARF-error variant and not a claim that every internal parameter is uniquely validated.

The downstream enhanced rotor identity is:

`M1_HOLDOUT_V1_GENERIC_CORRIGAN_N1`

It preserves the exact numerical identity that was frozen before WADC values were read and subsequently tested in Stage 5. It consists of the source-informed radial chord/nonlinear-twist representation, NASA TP four-region C81 with local Mach lookup, the predeclared in-range Corrigan `n=1` model-form assumption, and the same low-order hover/flapping/inflow equations used in the frozen holdout implementation.

The following are **not** promoted into the frozen downstream model:

- `M1-C_ANNULAR_MOMENTUM`: retained as an incremental diagnostic layer; it gave only modest improvement and was not the Stage-5 frozen holdout identity.
- `M1-D_LOADED_TORSION_PR71`: retained as a negative diagnostic; source-constrained quasi-static flexibility unloads the blade and does not explain the thrust deficit.
- `M1-F_LANDGREBE_BIOT_SAVART`: diagnostic only; the primary fixed-window run did not establish a robust supported model layer.
- `KONING_XV15_N1P8`: non-independent XV-15/OARF-correlated variant; never eligible for independent model selection.
- PR #72 simplified M1-D: invalid/superseded scientific evidence.

## Gate inputs

### 1. Frozen M0 baseline

M0 remains the permanent untuned control:

- branch: `frozen/m0-xv15-hover-v1-20260828`
- commit: `27f40883633ca14acc0e928649b62d7abb855491`
- OARF Run 15, fixed 6–11 deg window: CT/CP/FM MAPE = 56.4224 / 62.6130 / 23.0180%.
- OARF Run 14: CT/CP/FM MAPE = 56.1864 / 64.0809 / 19.1169%.

No M0 parameter was tuned to these errors.

### 2. Stage-1 incremental evidence

On OARF Run 15, fixed 6–11 deg window:

| Layer | CT MAPE | CP MAPE | FM MAPE | Evidence role |
|---|---:|---:|---:|---|
| M0 | 56.4224% | 62.6130% | 23.0180% | frozen baseline |
| scalar-C81 bridge | 42.8716% | 51.1184% | 12.2221% | attribution bridge |
| M1-A source-informed radial geometry + scalar C81 | 33.9549% | 45.2392% | 4.4100% | positive incremental evidence |
| M1-B four-region C81/local Mach | 37.8538% | 50.5150% | 7.5480% | higher-detail but non-monotonic external match |
| M1-C annular momentum | 35.7519% | 47.9006% | 5.9849% | modest incremental diagnostic |

The non-monotonic M1-A→M1-B change is retained as evidence of model-form interaction/error compensation. No layer is selected merely because it has the smallest OARF MAPE.

### 3. Geometry source-fidelity audit

Formal MATLAB R2021a run `33289747465` closed the source-interpretation blocker.

Four legitimate public-source interpretations all retained the same direction of improvement relative to the simpler section representation. CT/CP/FM MAPE across the tested geometry mappings varied by only about 1.5855 / 1.5515 / 0.4322 percentage points. The canonical M1-A identity reproduced with 0 pp drift.

Conclusion: the M1-A geometry contribution is source-contract robust at the tested level, but the wording is limited to **source-informed radial chord and nonlinear-twist representation**, not unqualified “true/real geometry”.

### 4. Strict-hover Eq. (12) limit audit

Formal MATLAB R2021a run `33290011132` showed that Eq. (12) versus uniform-hover inflow changes integrated CT/CP/FM only at numerical-noise level (maximum differences approximately `4.75e-8%`, `2.52e-7%`, `1.80e-7%`).

Eq. (12), however, produces nonzero first-harmonic flapping coordinates in strict hover (`|beta1|` about 2.89–4.12 deg) while uniform inflow gives approximately zero. The induced first-harmonic velocity is almost canceled by flapping velocity, leaving very small local 1/rev normal-velocity/thrust harmonics.

Conclusion: integrated hover-performance conclusions are retained; strict-hover Eq. (12) `beta1c/beta1s` are not validated objective physical observables and must not be used to support hover lateral/1/rev claims without additional evidence.

### 5. Corrigan provenance closure

Formal MATLAB R2021a rerun `33290207290` preserved the numerical results while correcting provenance language:

- M1-B/OFF: 37.8538 / 50.5150 / 7.5480%.
- Corrigan `n=1`: 32.7269 / 45.8943 / 7.5918%.
- XV-15-correlated `n=1.8`: 28.3085 / 41.7309 / 8.0569%.

`n=1` is frozen as a **predeclared in-range model-form assumption**, not a universal literature default. `n=1.8` remains non-independent and is not selected despite lower OARF CT/CP MAPE.

### 6. Stage-5 post-freeze WADC validation

The frozen M1 identity was selected before WADC numerical values were read. No WADC-dependent tuning, offset, gain, model selection or interpolation was performed.

Across all 15 formal WADC Run 1–3 points in the inherited window:

| Model | CT MAPE | CP MAPE | FM MAPE |
|---|---:|---:|---:|
| M0 | 59.1465% | 66.0974% | 23.0497% |
| frozen M1 | 37.8956% | 51.1078% | 9.2559% |

Interpretation: the frozen M1 bundle retains a substantial advantage over M0 at another facility/lower tip Mach. This validates transportability of the bundle within the tested evidence domain; it does not uniquely validate every internal mechanism.

### 7. WADC input-homology sensitivity

Final formal MATLAB R2021a run: `33292823006`.

Artifact:

- ID: `9726500347`
- name: `m1-audit-wadc-input-homology`
- SHA-256: `dc256c45b89fd0343b29e0c182c016f1c52946a49b31a208df89ed3dceb20384`

The original Stage-5 holdout was re-executed and the copied frozen branch reproduced it with maximum absolute identity difference `7.7715611723761e-16`.

Support results:

- frozen `a=340 m/s`, nominal generic rho: 15/15;
- test-reported `Mtip` used via `a=Vtip/Mtip`, nominal rho: 15/15;
- same reported-Mtip sound speed, `0.9*rho`: 14/15;
- same reported-Mtip sound speed, `1.1*rho`: 15/15.

The sole support loss is:

- WADC Run 3, point 9, collective75 = 10 deg;
- `Vtip = 740.9 ft/s`, `Mtip = 0.6636`, derived `a = 340.304882459313 m/s`;
- sensitivity rho = `1.1025 kg/m^3` (`0.9` of the frozen generic value);
- flap solver did not satisfy the physical-convergence gate on the first outer iteration; the failure is retained and no solver tolerance, relaxation, point membership, or model parameter was changed.

The reported-Mtip sound-speed correction itself is negligible at the pooled level: frozen M1 CT/CP/FM MAPE `37.8956 / 51.1078 / 9.2559%` becomes approximately `37.9216 / 51.1372 / 9.2536%`.

On the 14 points jointly supported by every sensitivity branch:

| Variant | M1 CT MAPE | M1 CP MAPE | M1 FM MAPE | M1−M0 CT | M1−M0 CP | M1−M0 FM |
|---|---:|---:|---:|---:|---:|---:|
| frozen A340/rho1.0 | 38.3531% | 51.3325% | 9.2749% | -21.1293 pp | -14.8204 pp | -14.6127 pp |
| reported-Mtip/rho1.0 | 38.3803% | 51.3634% | 9.2725% | -21.1021 pp | -14.7896 pp | -14.6151 pp |
| reported-Mtip/rho0.9 | 38.3803% | 51.3634% | 9.2733% | -21.1021 pp | -14.7896 pp | -14.6143 pp |
| reported-Mtip/rho1.1 | 38.3804% | 51.3634% | 9.2726% | -21.1020 pp | -14.7896 pp | -14.6150 pp |

The audit decision is therefore:

`WADC_ADVANTAGE_ROBUST_ON_COMMON_SUPPORT_WITH_LOW_DENSITY_SUPPORT_LIMITATION`.

This is a **domain caveat**, not a reason to retune or redefine the original 15-point holdout.

## Freeze decision

The M1 physics-enhancement phase has enough evidence to stop adding rotor mechanisms and freeze the current evidence package for the next research stage.

The freeze does **not** assert:

- full XV-15 reproduction;
- aircraft-level validation;
- unique correctness of every M1 parameter;
- validity of strict-hover Eq. (12) first-harmonic states;
- validation of the diagnostic nonlocal-wake implementation;
- exact WADC environmental homology where density is unavailable.

It does support the following bounded claims:

1. the untuned M0 baseline exposes a repeatable large hover-performance deficit;
2. source-informed radial geometry/section-aerodynamic refinements materially change the predicted rotor performance without OARF tuning;
3. adding nominally more detailed physics does not improve external correlation monotonically, revealing model-form interaction/error compensation;
4. several candidate explanations (mass properties, local Prandtl losses, source-constrained quasi-static loaded torsion, strict-hover Eq. (12) for integrated performance) do not explain the main deficit;
5. a predeclared Corrigan `n=1` M1 bundle, frozen before WADC values were read, retains a substantial M0-relative advantage across a second facility;
6. that WADC advantage is insensitive to the reported-Mtip sound-speed correction and remains large on the common support set under the declared ±10% density sensitivity, while one low-density boundary point loses physical support.

## Next research stage

**Do not add another rotor M1-G/M2 correction solely to reduce OARF error.**

The next allowed scientific task is whole-aircraft propagation:

`M0_aircraft` versus `M1_EVIDENCE_V1_aircraft`

across hover → conversion → airplane-mode operating conditions, using the already-developed full-aircraft trim/linearization/control-stability/nacelle-dynamics framework.

Primary question:

> Does the independently strengthened rotor evidence materially change whole-aircraft trim, control demand, power/thrust allocation, linear modes, stability/control conclusions, or nacelle-dynamics conclusions?

All aircraft-level claims must preserve the rotor evidence-domain caveats above.