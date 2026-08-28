# XV-15 OARF Run 14 frozen-M0 external validation

## Validation identity

- Model: `M0_PRODUCTION_LOW_ORDER`.
- Computation path: direct `model/rotor_model_bemt.m`.
- Source: NASA CR-2017-219486 Appendix A Table A-2, original-metal-blade OARF Run 14.
- Collective definition: three-quarter-radius collective.
- Dataset role: `PREVIOUSLY_UNUSED_RUN_LEVEL_EXTERNAL_VALIDATION`.
- Independence boundary: same OARF campaign as Run 15; Run 14 was not used in prior model diagnostics; the analyst saw Run 14 source values during the present source audit, so no blind-validation claim is made.
- Post-audit constraint: no parameter or model-form change after inspection of Run 14 targets.
- Primary reporting window: `PREDECLARED_6_TO_11_DEG`.
- Execution: GitHub-hosted MATLAB R2021a, workflow run `33143148398`, head `784bcbcf70b69da56369d1181446bdab3783472b`.

The validation uses the same frozen XV-15 low-order geometry/control mapping as the Run 15 pure-M0 baseline. It does not introduce `alpha0L`, the section-aero wrapper, additional compressibility, Prandtl/Mangler inflow, prescribed/free wake, Biot-Savart coupling, or any target-driven parameter fit.

## Primary 6–11 deg validation result

All six predeclared reporting points are physically converged.

| Quantity | MAPE | Mean signed error | Maximum absolute relative error |
| --- | ---: | ---: | ---: |
| CT | 56.1864% | -56.1864% | 65.7624% |
| CP | 64.0809% | -64.0809% | 65.8342% |
| FM | 19.1169% | -19.1169% | 41.3640% |

The sign of the mean error shows systematic underprediction of thrust coefficient, power coefficient, and figure of merit over the reporting window.

## Pointwise residual structure

| theta_0.75 | CT error | CP error | FM error | M0 status |
| ---: | ---: | ---: | ---: | --- |
| 6 deg | -65.7624% | -65.8342% | -41.3640% | PHYSICAL_CONVERGED |
| 7 deg | -61.5545% | -65.1644% | -31.5735% | PHYSICAL_CONVERGED |
| 8 deg | -57.1016% | -64.1082% | -21.7143% | PHYSICAL_CONVERGED |
| 9 deg | -53.7536% | -63.6036% | -13.5911% | PHYSICAL_CONVERGED |
| 10 deg | -50.8529% | -63.2054% | -6.3647% | PHYSICAL_CONVERGED |
| 11 deg | -48.0931% | -62.5695% | -0.0936% | PHYSICAL_CONVERGED |

As collective increases, the CT bias becomes less negative and FM approaches the experimental value. CP remains strongly underpredicted across the complete 6–11 deg window.

## Low-collective model-support result

All Run 14 source points are retained rather than filtered for favorable agreement.

- -7, -5, -3 and -1 deg: the production solver returns `UNSUPPORTED_NEGATIVE_THRUST_BRANCH`.
- 1 and 3 deg: `rotor_model_bemt:CoupledSolveNotConverged`.
- 5 through 11 deg: `PHYSICAL_CONVERGED`.

The physical/numerical support boundary therefore remains a formal part of the validation result. In particular, the experimental rotor produces positive thrust over much of the region where the current frozen M0 path either predicts a negative-thrust branch or cannot obtain a coupled solution.

## Comparison with the previously used Run 15 developmental correlation

The frozen Run 15 primary 6–11 deg metrics were:

| Quantity | Run 15 MAPE | Run 14 MAPE | Difference Run14-Run15 |
| --- | ---: | ---: | ---: |
| CT | 56.4224% | 56.1864% | -0.2361 percentage point |
| CP | 62.6130% | 64.0809% | +1.4679 percentage points |
| FM | 23.0180% | 19.1169% | -3.9011 percentage points |

Run 14 and Run 15 therefore exhibit the same dominant error structure despite Run 14 not having been used in the earlier diagnostic/model-direction process: large systematic CT and CP underprediction, reduced CT bias with increasing collective, and FM approaching the measured value at higher collective.

This strengthens the evidence that the observed pure-M0 hover discrepancy is not merely a peculiarity of the previously reused Run 15 data. It does **not** make Run 14 an independent experiment: both runs belong to the same OARF campaign and share the same rotor configuration/source family.

## Scientific conclusion

For XV-15 original-metal-blade hover, the frozen M0 model demonstrates a reproducible qualitative loading trend and a physically converged branch at moderate/high collective, but it does not quantitatively reproduce the measured thrust and power levels. In the predeclared 6–11 deg range, the dominant discrepancy is a persistent approximately 48–66% CT underprediction and approximately 63–66% CP underprediction.

The validation result should therefore be used to define the model's credibility boundary rather than to trigger model retuning. The current evidence supports statements about qualitative trend reproduction, convergence/support range, and systematic model-form discrepancy; it does not support a claim of quantitative XV-15 rotor-performance reproduction.
