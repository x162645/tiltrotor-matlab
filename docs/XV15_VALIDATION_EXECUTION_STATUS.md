# XV-15 frozen-M0 validation execution status

Date: 2026-08-28

## Closed baseline

The current branch implements and executes the XV-15 validation-only workflow defined in `XV15_VALIDATION_TASKS.txt`.

Frozen baseline identity:

- model: `M0_PRODUCTION_LOW_ORDER`;
- rotor computation path: direct `model/rotor_model_bemt.m`;
- no section-aero extension;
- no `alpha0L` extension;
- no added compressibility correction;
- no Prandtl/Mangler/prescribed-wake/Biot-Savart extension;
- no validation-target parameter fitting;
- no production-physics modification.

## MATLAB R2021a execution evidence

Final regression workflow on the closed branch state:

- workflow: `XV-15 frozen-M0 validation`;
- workflow run: `33142793530`;
- head SHA: `c9e2f5de97fff2fa59fbe61dc14a4524e643752d`;
- MATLAB release: R2021a;
- job conclusion: `success`;
- artifact: `xv15-validation-evidence`;
- artifact ID: `9674600459`;
- artifact SHA-256 digest: `2e2f9135efdffdd6f7b763ea883cd0ddf292240f295ad382c072484710ef3a15`.

The execution status file reports:

- `status=EXECUTED`;
- `modelIdentity=M0_PRODUCTION_LOW_ORDER`;
- `datasetRole=DEVELOPMENT_EXTERNAL_CORRELATION`;
- `reportWindow=FIXED_REPORT_WINDOW_6_TO_11_DEG`.

## V1 result

For the fixed 6-11 deg OARF Run 15 reporting window, all six points are physically converged.

- CT MAPE: 56.4224287637598%.
- CP MAPE: 62.6130288260114%.
- FM MAPE: 23.0179649410372%.
- CT mean signed error: -56.4224287637598%.
- CP mean signed error: -62.6130288260114%.
- FM mean signed error: -23.0179649410372%.

The 0 deg point is retained as `UNSUPPORTED_NEGATIVE_THRUST_BRANCH`; the 2 deg and 4 deg points are retained as `rotor_model_bemt:CoupledSolveNotConverged`.

The large error is not removed or fitted away. Radial-resolution convergence at the 10 deg reference point shows CT/CP approaching stable values as the grid is refined, so the observed external mismatch is much larger than the tested discretization sensitivity.

## TM-86009 dynamic-validation gate

The earlier R2021a CSV-import issue in the gate has been corrected without changing aircraft physics.

The final MATLAB execution now stops for the scientifically intended reason:

- `status=BLOCKED`;
- `identifier=audit_tm86009_homology_gate:NoHighHomologyCase`.

The report-level homology audit closes the 170 KIAS, 8000 ft, 0 deg nacelle cruise condition, measured control-surface input definition, principal output channels, SCAS context, and frequency-range evidence. It does not establish exact matched test mass, CG, inertia, rotor-RPM/governor state, test-day density, or every repository axis/sign adapter.

Current case ratings are therefore MEDIUM/LOW/PENDING and none is HIGH. Strict matched-condition quantitative TM-86009/M0 dynamic validation is intentionally blocked rather than forced.

## Scientific interpretation

The validation-only study currently supports two conclusions:

1. **Component-level hover external correlation has been executed for the frozen original M0 model.** It shows a strong systematic XV-15 thrust/power underprediction in the physically supported range and a low-collective support/convergence limitation.
2. **Aircraft-dynamics validation using TM-86009 is not yet admissible as strict quantitative validation.** The blocker is incomplete matched-condition public evidence, not a software crash and not a reason to change M0.

The next admissible research action is evidence acquisition/audit: search the detailed XV-15 flight-test sources such as NASA TM-89428 and NASA CR-177406 for record-level mass/CG/inertia/RPM/control-channel provenance. If those sources close all remaining fields for a specific case, that case may be promoted through the HIGH-homology gate and then executed against M0 without tuning.
