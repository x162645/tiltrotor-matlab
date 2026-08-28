# XV-15 V1 pure-M0 hover external-correlation report

## Evidence identity

- Model identity: `M0_PRODUCTION_LOW_ORDER`.
- Production rotor entry: `model/rotor_model_bemt.m`.
- Canonical validation entry: `analysis/run_xv15_v1_baseline_correlation.m`.
- External data: XV-15 original-metal-blade OARF Run 15.
- Data role: `DEVELOPMENT_EXTERNAL_CORRELATION`.
- Independence: `NOT_BLIND_USED_IN_PRIOR_DIAGNOSTICS`.
- Claim boundary: `FROZEN_M0_EXTERNAL_CORRELATION_NOT_XV15_REPRODUCTION_NO_VALIDATION_TARGET_PARAMETER_FIT`.
- Executed environment: MATLAB R2021a on a GitHub-hosted Actions runner.
- First executed workflow evidence run: `33142436573`, head SHA `06c0769af9edc6140f1bf9c19bf36ef9e19a74cb`.

The baseline path excludes the section-aero wrapper, nonzero `alpha0L`, added compressibility correction, Prandtl corrections, Mangler inflow, prescribed wake, and Biot-Savart/nonlocal wake extensions. No production physics or validation-target parameter fit is used to improve agreement.

## Point support

Nine OARF Run 15 points are retained in the result table.

- 0 deg: the solver returns but identifies `UNSUPPORTED_NEGATIVE_THRUST_BRANCH`; the computed CT is negative and the point is not a physically supported validation point.
- 2 deg: `rotor_model_bemt:CoupledSolveNotConverged`.
- 4 deg: `rotor_model_bemt:CoupledSolveNotConverged`.
- 6, 7, 8, 9, 10, and 11 deg: `PHYSICAL_CONVERGED`.

No failed point is deleted. The predeclared fixed reporting window is 6-11 deg and contains six physically converged points.

## Fixed-window errors

| Quantity | MAPE | Mean signed error | Maximum absolute relative error |
| --- | ---: | ---: | ---: |
| CT | 56.4224% | -56.4224% | 66.4540% |
| CP | 62.6130% | -62.6130% | 65.0187% |
| FM | 23.0180% | -23.0180% | 44.4568% |

The negative mean signed errors show that the frozen M0 systematically underpredicts both thrust coefficient and power coefficient over the supported 6-11 deg collective range.

## Residual trend with collective

The relative error decreases in magnitude as collective increases:

| theta_0.75 | CT error | CP error | FM error |
| ---: | ---: | ---: | ---: |
| 6 deg | -66.4540% | -65.0187% | -44.4568% |
| 7 deg | -61.5888% | -64.0579% | -33.7656% |
| 8 deg | -57.5010% | -63.0080% | -25.1016% |
| 9 deg | -53.9457% | -61.9492% | -17.8577% |
| 10 deg | -51.1345% | -61.3359% | -11.6487% |
| 11 deg | -47.9105% | -60.3084% | -5.2774% |

The trend is therefore structured rather than random: M0 remains substantially low in CT/CP, while FM approaches the test value as rotor loading increases.

## Numerical-convergence check

At the 10 deg reference point, increasing radial resolution from 6 to 96 stations gives:

| nRadial | CT | CP |
| ---: | ---: | ---: |
| 6 | 0.00649976 | 0.000531707 |
| 12 | 0.00639600 | 0.000525058 |
| 24 | 0.00637022 | 0.000523427 |
| 48 | 0.00636379 | 0.000523022 |
| 96 | 0.00636219 | 0.000522921 |

At 48 radial stations, changing azimuth stations from 8 to 64 leaves the reported CT and CP unchanged at the printed precision. The large XV-15 mismatch is therefore not explained by the tested radial/azimuth discretization.

## Validation interpretation

This result does **not** demonstrate that M0 reproduces XV-15 hover performance quantitatively. It establishes a narrower and more useful validation statement:

1. the direct production M0 path has a physically supported hover branch for the six 6-11 deg OARF points;
2. the low-collective 0-4 deg region is outside the currently demonstrated physical/numerical support of the model instance;
3. in the supported range, M0 has a strong systematic CT/CP underprediction and a collective-dependent FM bias;
4. the discrepancy remains much larger than the observed numerical-grid sensitivity;
5. the discrepancy is retained as a model-form/applicability result and is not used to trigger parameter tuning or production-model modification.

Previous results produced through `rotor_model_bemt_section_aero` or other post-validation extensions must not be substituted for these pure-M0 baseline metrics.

## Dynamic-validation consequence

NASA TM-86009 has been audited separately. Report-level evidence closes important cruise condition and signal definitions, but no candidate case currently satisfies the `HIGH` matched-condition homology gate because exact test loading/mass properties, rotor-RPM/governor state, and other matched-condition quantities remain unresolved. Strict quantitative V4 dynamic validation is therefore blocked until that evidence gap is closed; forcing a comparison would violate the validation contract.
