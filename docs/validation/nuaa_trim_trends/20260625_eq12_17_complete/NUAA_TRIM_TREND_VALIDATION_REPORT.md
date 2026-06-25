# NUAA Trim Trend Validation Report

## Project Goal Check

This run preserves the component-level mechanistic chain, uses only the current approved conceptual parameters, and evaluates whether the model gives computable, continuous, explainable trim trends. It is not a strict XV-15 or GTRS quantitative validation.

- Git commit: `ec30f6b936d256ec4124a38bffe31a12183faeb2`
- Elapsed seconds: 2435.794
- Primary accepted PASS trim points: 100

## Active Wing Slipstream Chain

This run uses the post-correction wing chain: NUAA Eq. (16) area formula with a separate physical area guard, NUAA Eq. (17) body-axis induced-velocity vector, Eq. (18) aerodynamic-center shift, Eq. (19)/(21) force transformation as a three-dimensional extension, and Eq. (20)/(22) force-arm moment identities. The legacy `P.rotor.wakeFactor` path is deprecated and is not used by production wing force, moment, or local-velocity calculations. Earlier `20260625_eq12_13_16` and `20260625_eq12_13_16_angle_fix` outputs are intermediate diagnostics from before Eq. (17) replaced that legacy path.

## NUAA Section 4 Method Restatement

NUAA Section 4 trims steady conditions by driving state derivatives to zero so that resultant forces and moments balance. It computes helicopter mode, fixed-wing mode, and conversion modes at nacelle angles 15 deg and 75 deg. Figures 5 and 6 compare controls and pitch attitude versus speed. Figure 7 compares fixed-wing trim against GTRS and XV-15 actual trim results. Because complete XV-15 data are unavailable, the paper treats trend agreement and numerical closeness as rationality evidence, then analyzes stability derivatives and eigenvalues at trimmed linearization points. It does not require every open-loop mode to be stable.

This project currently has no complete digitized GTRS/XV-15 data, so the result below is only a NUAA-style trim trend baseline and physical reasonableness check.

## Trend Summary

|mode|pointCount|collectiveEndpointChange_deg|thetaEndpointChange_deg|cyclicEndpointChange_deg|elevatorEndpointChange_deg|collectiveSpearman|thetaSpearman|directionRatioCollective|directionRatioTheta|
|-|-|-|-|-|-|-|-|-|-|
|airplane_lower|12|7.97887527553673|-8.14358465883997|0|12.6328067537384|1|-1|1|1|
|airplane_upper|20|11.2088348737592|-3.11651984423184|0|4.92493687053179|1|-1|1|1|
|conversion15_lower|10|-1.95265651036011|-5.36191640919192|-6.90294631754421|-0.283205284103568|-1|-1|1|1|
|conversion15_upper|10|0.501928955688861|-2.45074924566704|1.31460726534188|0.0539340314902248|0.987878787878788|-1|0.888888888888889|1|
|conversion75_lower|12|8.52405209963607|-7.5683138356215|1.46200140250255|11.6360300897162|1|-1|1|1|
|conversion75_upper|20|12.0588173954602|-3.03155698463304|0.594850729422444|4.73440105775625|1|-1|1|1|
|helicopter_hover_connected|13|-2.4547576786126|1.06123442552588|-1.08298095917759|0|-1|0.0934065934065934|1|0.75|

## Branch Comparison

|mode|betaM_deg|V_mps|branchA|branchB|thetaDiff_deg|collectiveDiff_deg|cyclicDiff_deg|elevatorDiff_deg|significant|
|-|-|-|-|-|-|-|-|-|-|
|helicopter_longitudinal|0|0|helicopter_hover_connected|helicopter_reverse_audit|3.96931349239028e-09|1.16451559506459e-09|1.79030011778977e-09|0|0|
|helicopter_longitudinal|0|5|helicopter_hover_connected|helicopter_reverse_audit|1.55972585194619e-08|9.71205338373693e-11|1.14506504278467e-09|0|0|
|helicopter_longitudinal|0|8|helicopter_9ms_low_branch|helicopter_9ms_high_branch|1.36816336038237e-08|2.22701146412874e-09|4.01450250819835e-09|0|0|
|helicopter_longitudinal|0|9|helicopter_9ms_low_branch|helicopter_9ms_high_branch|2.55859755604604e-09|6.0533977830346e-10|9.32755295224297e-09|0|0|
|helicopter_longitudinal|0|10|helicopter_hover_connected|helicopter_reverse_audit|1.03337778334378e-08|1.34843602950241e-09|2.54204757244025e-09|0|0|
|helicopter_longitudinal|0|15|helicopter_hover_connected|helicopter_reverse_audit|8.70792860041547e-09|8.73704664172692e-10|1.8471737472936e-09|0|0|
|helicopter_longitudinal|0|20|helicopter_hover_connected|helicopter_reverse_audit|3.94229360267673e-09|2.44266296078877e-09|4.11414768919371e-09|0|0|
|helicopter_longitudinal|0|25|helicopter_hover_connected|helicopter_reverse_audit|4.5858208341798e-09|2.05832506594561e-09|2.41977571313612e-09|0|0|
|helicopter_longitudinal|0|30|helicopter_hover_connected|helicopter_reverse_audit|3.57349261292939e-10|1.58804525085543e-09|4.28595070545157e-09|0|0|
|helicopter_longitudinal|0|2.5|helicopter_hover_connected|helicopter_reverse_audit|1.0552417273324e-10|6.39211350517144e-10|3.37139427486477e-10|0|0|
|helicopter_longitudinal|0|7.5|helicopter_hover_connected|helicopter_reverse_audit|6.87548840083707e-09|1.93915994373128e-09|1.3404016785401e-09|0|0|
|helicopter_longitudinal|0|8.5|helicopter_9ms_low_branch|helicopter_9ms_high_branch|1.78768755354497e-09|2.50527776302079e-09|7.6824373529405e-09|0|0|
|helicopter_longitudinal|0|9.5|helicopter_9ms_low_branch|helicopter_9ms_high_branch|1.35191546846158e-09|7.14930337153419e-10|5.37094224650758e-09|0|0|
|helicopter_longitudinal|0|10.5|helicopter_9ms_low_branch|helicopter_9ms_high_branch|1.70222680395682e-09|2.88716606178241e-09|1.40720095576086e-08|0|0|
|helicopter_longitudinal|0|12.5|helicopter_hover_connected|helicopter_reverse_audit|1.54407997499106e-09|6.08263661661113e-10|1.36415980733773e-08|0|0|
|helicopter_longitudinal|0|17.5|helicopter_hover_connected|helicopter_reverse_audit|8.32823077168143e-09|4.54605242339312e-10|1.18533747262006e-08|0|0|
|helicopter_longitudinal|0|22.5|helicopter_hover_connected|helicopter_reverse_audit|4.78353801014464e-10|2.54485676975946e-09|5.77774073029502e-09|0|0|
|helicopter_longitudinal|0|27.5|helicopter_hover_connected|helicopter_reverse_audit|1.04528363742418e-09|1.35342403950744e-09|1.52055992241884e-08|0|0|
|helicopter_longitudinal|0|7.75|helicopter_9ms_low_branch|helicopter_9ms_high_branch|5.47662337702093e-09|8.76045902487022e-10|5.45401501739207e-09|0|0|
|helicopter_longitudinal|0|8.25|helicopter_9ms_low_branch|helicopter_9ms_high_branch|1.54977488620034e-08|1.00812158621011e-09|2.39203190588455e-09|0|0|
|helicopter_longitudinal|0|8.75|helicopter_9ms_low_branch|helicopter_9ms_high_branch|1.37162257107803e-08|4.50453185862898e-09|4.52228303693403e-08|0|0|
|helicopter_longitudinal|0|9.25|helicopter_9ms_low_branch|helicopter_9ms_high_branch|5.36128541561709e-09|3.22932791618769e-09|8.5990500275912e-09|0|0|
|helicopter_longitudinal|0|9.75|helicopter_9ms_low_branch|helicopter_9ms_high_branch|1.10026776578565e-08|1.28167343405039e-09|1.47624477087049e-08|0|0|
|helicopter_longitudinal|0|10.25|helicopter_9ms_low_branch|helicopter_9ms_high_branch|2.63982413706287e-09|3.23776561117484e-10|9.50225675921956e-10|0|0|

## Stability Map Summary

|mode|points|candidate positive roots %|longitudinal %|lateral %|dominant real min/median/max|
|-|-:|-:|-:|-:|-|
|airplane_longitudinal|33|0.0|0.0|0.0|0 / 0 / 0|
|conversion_longitudinal|54|35.2|35.2|18.5|0 / 0 / 0.2248|
|helicopter_longitudinal|13|100.0|100.0|100.0|0.04277 / 0.1196 / 0.2609|

Robustness sample rows: 36

## Figures

- helicopter: `E:\tiltrotor\validation\nuaa_trim_trends\20260625_203546_eq12_17_complete\helicopter_nuaa_fig5a.png`
- airplane: `E:\tiltrotor\validation\nuaa_trim_trends\20260625_203546_eq12_17_complete\airplane_nuaa_fig5b.png`
- conversion15: `E:\tiltrotor\validation\nuaa_trim_trends\20260625_203546_eq12_17_complete\conversion_beta15_nuaa_fig6a.png`
- conversion75: `E:\tiltrotor\validation\nuaa_trim_trends\20260625_203546_eq12_17_complete\conversion_beta75_nuaa_fig6b.png`
- maxReal: `E:\tiltrotor\validation\nuaa_trim_trends\20260625_203546_eq12_17_complete\stability_max_real_by_mode.png`
- coverage: `E:\tiltrotor\validation\nuaa_trim_trends\20260625_203546_eq12_17_complete\stability_long_lateral_coverage.png`

## Project Goal Check

The run keeps the current component force/moment chain and approved parameters. Any continuity, branch, control-margin, low-speed-boundary, or open-loop instability limitations are reported as model limitations. The current results cannot be called strict XV-15/GTRS validation because the parameter set is conceptual, complete public comparison data are not available in this workflow, and the low-order model omits effects such as dynamic inflow and flight-control stabilization.
