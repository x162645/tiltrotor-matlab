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

The validation workflow is executed on GitHub-hosted MATLAB R2021a. The first clean Run 15-only closure was workflow run `33142793530` at head `c9e2f5de97fff2fa59fbe61dc14a4524e643752d`.

The subsequent Run 14 + Run 15 execution was:

- workflow: `XV-15 frozen-M0 validation`;
- workflow run: `33143148398`;
- head SHA: `784bcbcf70b69da56369d1181446bdab3783472b`;
- MATLAB release: R2021a;
- job conclusion: `success`;
- artifact: `xv15-validation-evidence`;
- artifact ID: `9674738390`;
- artifact SHA-256 digest: `76cf15a8d2be07694d558db38f4e316b22af5514a60e3a8829634c7c1b823df7`.

This run executed the frozen Run 15 development correlation, the newly added Run 14 run-level external validation, and the TM-86009 homology gate in the same MATLAB job.

## V1 Run 15 development external correlation

For the fixed 6-11 deg OARF Run 15 reporting window, all six points are physically converged.

- CT MAPE: 56.4224287637598%.
- CP MAPE: 62.6130288260114%.
- FM MAPE: 23.0179649410372%.
- CT mean signed error: -56.4224287637598%.
- CP mean signed error: -62.6130288260114%.
- FM mean signed error: -23.0179649410372%.

The 0 deg point is retained as `UNSUPPORTED_NEGATIVE_THRUST_BRANCH`; the 2 deg and 4 deg points are retained as `rotor_model_bemt:CoupledSolveNotConverged`.

Run 15 remains `DEVELOPMENT_EXTERNAL_CORRELATION` because it was used in prior diagnostics.

## V1 Run 14 previously-unused run-level external validation

NASA CR-2017-219486 Appendix A Table A-2 OARF Run 14 was identified as a same-configuration original-metal-blade run not used in the earlier repository diagnostic/model-direction chain.

Its evidence role is deliberately narrower than a blind or independent-experiment claim:

- `datasetRole=PREVIOUSLY_UNUSED_RUN_LEVEL_EXTERNAL_VALIDATION`;
- same OARF campaign as Run 15;
- not used in prior model diagnostics;
- analyst has seen the source data during the current evidence audit;
- no model or parameter change is permitted after that audit.

The primary reporting window was predeclared as 6-11 deg before MATLAB execution. All six reporting points are physically converged.

- CT MAPE: 56.1863655173496%.
- CP MAPE: 64.0808834882906%.
- FM MAPE: 19.1168541328412%.
- CT mean signed error: -56.1863655173496%.
- CP mean signed error: -64.0808834882906%.
- FM mean signed error: -19.1168541328412%.

Low-collective support is also retained:

- -7, -5, -3, -1 deg: `UNSUPPORTED_NEGATIVE_THRUST_BRANCH`;
- 1 and 3 deg: `rotor_model_bemt:CoupledSolveNotConverged`;
- 5 through 11 deg: `PHYSICAL_CONVERGED`.

The Run 14 6-11 deg CT MAPE differs from Run 15 by only -0.2361 percentage point, while CP differs by +1.4679 percentage points and FM by -3.9011 percentage points. The dominant residual structure therefore repeats on a previously unused run from the same OARF campaign.

This substantially strengthens the component-level validation conclusion: the pure-M0 thrust/power underprediction is not merely a peculiarity of the previously reused Run 15 data, although Run 14 and Run 15 are not independent experiments.

## Numerical-convergence interpretation

Run 15 radial-resolution convergence at the 10 deg reference point shows CT/CP approaching stable values as the grid is refined. The approximately 50-65% external CT/CP errors are much larger than the tested radial/azimuth discretization sensitivity.

The validation study therefore records the dominant mismatch as an M0 applicability/model-form limitation rather than a simple grid-resolution artifact.

## TM-86009 dynamic-validation gate

The earlier R2021a CSV-import issue in the gate has been corrected without changing aircraft physics.

The MATLAB gate now stops for the scientifically intended reason:

- `status=BLOCKED`;
- `identifier=audit_tm86009_homology_gate:NoHighHomologyCase`.

The report-level homology audit closes the 170 KIAS, 8000 ft, 0 deg nacelle cruise condition, measured control-surface input definition, principal output channels, SCAS context, and frequency-range evidence. It does not establish exact matched test mass, CG, inertia, rotor-RPM/governor state, test-day density, or every repository axis/sign adapter.

Current case ratings are MEDIUM/LOW/PENDING and none is HIGH. Strict matched-condition quantitative TM-86009/M0 dynamic validation is therefore intentionally blocked rather than forced.

Further review of the public XV-15 flight-dynamics literature also indicates that the available flight-test data do not reliably close all exact matched loading/CG/inertia/configuration quantities needed for strict reproduction. Generic XV-15 design values are not substituted for those missing record-level quantities.

## Current scientific conclusion

The validation-only study now supports three principal conclusions:

1. **Frozen M0 component-level hover validation has been executed against two XV-15 original-metal-blade OARF runs without modifying production physics.** Run 15 is development external correlation; Run 14 is a previously unused run-level external validation from the same campaign.
2. **The dominant M0 hover discrepancy is reproducible across both runs.** In the common 6-11 deg range, CT is underpredicted by roughly 48-66% pointwise and CP by roughly 60-66%, while FM approaches the experiment as collective increases. The low-collective region also exposes a physical-branch/coupled-solve support limitation.
3. **Strict aircraft-dynamics validation using TM-86009 remains inadmissible under the current evidence contract.** The blocker is incomplete matched-condition public evidence, not a software failure and not a reason to change M0.

The next research action should therefore preserve M0 and either locate record-level dynamic test provenance sufficient to pass the HIGH-homology gate, or formalize the current hover-based credibility/applicability statement as the validated scope of the present low-order model.
