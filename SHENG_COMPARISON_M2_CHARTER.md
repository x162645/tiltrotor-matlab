# Sheng comparison / M2 nacelle research charter

## 1. Mainline

This branch continues the validated low-order tiltrotor research mainline without modifying frozen M0 or frozen M1:

`freeze identity -> external validation -> retain failures -> mechanism diagnosis -> new model identity -> refreeze -> cross-dataset/facility validation -> credible domain -> next evidence layer`

The research object remains a generic low-order component-level tiltrotor flight-dynamics model. XV-15 provides external evidence; it is not a reverse-fitting target or digital-twin specification.

## 2. Frozen evidence that must not be rewritten

- M0 branch: `frozen/m0-xv15-hover-v1-20260828`
- M0 SHA: `27f40883633ca14acc0e928649b62d7abb855491`
- Frozen M1 holdout: `M1_HOLDOUT_V1 = M1_E1_GENERIC_CORRIGAN_N1`
- M1 cross-facility WADC result and credible-domain conclusions remain unchanged.
- M1-F prescribed-wake work remains model-form diagnostic only.
- Dynamic HIGH-homology gate remains blocked unless a same-run contract is closed.

No OARF/WADC result may be used to retune frozen M0/M1.

## 3. Sheng / NUAA benchmark identity

The repository does not contain Sheng et al.'s original author code. Therefore the only defensible public benchmark identity is:

`S0 = NUAA_PUBLIC_FORMULA_REFERENCE`

S0 means a reproducible implementation of the public mathematical chain in Sheng, Zhang and Xiang (Drones 2022), with every missing closure explicitly classified. It is NOT author-code reproduction, NOT a high-fidelity rotor, and NOT an XV-15 model.

When S0 is instantiated with the same XV-15 geometry/operating-point mapping used for M0, its role is:

`XV15_MAPPED_PUBLIC_FORMULA_MODEL_FORM_DIAGNOSTIC`

This isolates public-formula-chain/model-form behavior from parameter-mapping differences. It is not evidence that the Sheng authors used those XV-15 mapped parameters.

## 4. Scaling diagnostic identity

`S0-N` is not a model.

For a model vector m and external data e, a single least-squares scale factor may be reported:

`k* = (m' e)/(m' m)`

The scaled vector `k*m` is used only to decompose amplitude error from curve-shape/trend error. The scale factor is observed-target dependent and therefore:

`SCALING_ROLE = DIAGNOSTIC_ONLY_NOT_MODEL_NOT_VALIDATION_SCORE`

No scale factor may be fed back into S0, M0, M1, S1 or M2.

## 5. Comparison ladder

### S0 — public-formula reference

`NUAA_PUBLIC_FORMULA_REFERENCE`, with documented closures and no target fitting.

### S0-N — scale/shape decomposition

Post-processing only. Report raw error, k*, scaled RMSE, Pearson trend correlation, Spearman rank correlation, and local ratio dispersion. Never call the scaled curve a validated model.

### S1 — corrected comparison contract

S1 is not "replace all conceptual parameters with XV-15 values". It is an analysis-only comparison layer that applies only previously established definition/correctness corrections, especially paper-specific control/trim definitions where the prior audit found comparison-definition mismatches. It must not silently change production control allocation or frozen model physics.

### M1 — frozen physics-enhanced external-evidence anchor

Use frozen M1 results unchanged as the source-constrained physics-enhanced comparison anchor.

### D13 — existing nacelle-dynamic scaffold

The current 13-state command model already includes left/right nacelle angle and rate states, a second-order commanded actuator, actuator reaction torque, moving-point-mass CG/inertia reconstruction, and nacelle-rate rotor gyroscopic moment.

Its current mechanics boundary is explicitly one-way prescribed coupling. It does NOT yet implement `I_dot*omega`, moving-mass acceleration reactions, external hinge-load feedback, or a mechanically loaded two-way nacelle DOF.

### M2 — future two-way nacelle mechanics

Any implementation adding new mechanical coupling beyond the frozen D13 scaffold is a new model identity, M2. Candidate mechanisms include source/derivation-constrained `I_dot*omega`, moving-mass relative-acceleration terms, hinge load decomposition, and actuator/hinge-load feedback. M2 must receive a new development/validation split and must not inherit the label "validated XV-15 dynamics" without HIGH-homology evidence.

## 6. Stage 9 first executable experiment

The first executable experiment compares, on the fixed OARF Run-15 6--11 deg hover window:

1. `S0_XV15_MAPPED_PUBLIC_FORMULA_REFERENCE`;
2. frozen `M0_PRODUCTION_LOW_ORDER`;
3. frozen `M1_HOLDOUT_V1`.

All use the same publicly documented XV-15 metal-blade operating points. No CT/CP/FM target may choose a model parameter.

For S0 only, produce an S0-N amplitude/shape diagnostic as post-processing. Preserve every unsupported or failed S0 point. Do not redefine the 6--11 deg window after seeing results.

## 7. Hard stop rules

- Do not modify frozen M0.
- Do not modify frozen M1.
- Do not fit OARF/WADC gains, offsets, Corrigan exponent, wake gain, control gain, or nacelle parameters.
- Do not describe S0 as Sheng author code.
- Do not describe S0-N as a physical model or validation result.
- Do not turn generic-vs-XV-15 parameter differences into alleged Sheng mathematical errors.
- Do not hide failed points.
- Do not claim current D13 is full multibody/two-way nacelle dynamics.
- Do not claim M2 XV-15 dynamic validation while HIGH-homology data remain unavailable.
- Do not merge PR #71 or any future M2 PR without explicit user authorization.
