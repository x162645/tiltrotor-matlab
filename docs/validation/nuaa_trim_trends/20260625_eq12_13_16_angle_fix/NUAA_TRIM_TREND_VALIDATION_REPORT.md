# NUAA Trim Trend Validation Report

## Project Goal Check

This run preserves the component-level mechanistic chain, uses only the current approved conceptual parameters, and evaluates whether the model gives computable, continuous, explainable trim trends. It is not a strict XV-15 or GTRS quantitative validation.

- Git commit: `091c27ac78549ffad68f549c2b49eca990be9613`
- Elapsed seconds: 1472.928
- Primary accepted PASS trim points: 100

## NUAA Section 4 Method Restatement

NUAA Section 4 trims steady conditions by driving state derivatives to zero so that resultant forces and moments balance. It computes helicopter mode, fixed-wing mode, and conversion modes at nacelle angles 15 deg and 75 deg. Figures 5 and 6 compare controls and pitch attitude versus speed. Figure 7 compares fixed-wing trim against GTRS and XV-15 actual trim results. Because complete XV-15 data are unavailable, the paper treats trend agreement and numerical closeness as rationality evidence, then analyzes stability derivatives and eigenvalues at trimmed linearization points. It does not require every open-loop mode to be stable.

This project currently has no complete digitized GTRS/XV-15 data, so the result below is only a NUAA-style trim trend baseline and physical reasonableness check.

## Trend Summary

|mode|pointCount|collectiveEndpointChange_deg|thetaEndpointChange_deg|cyclicEndpointChange_deg|elevatorEndpointChange_deg|collectiveSpearman|thetaSpearman|directionRatioCollective|directionRatioTheta|
|-|-|-|-|-|-|-|-|-|-|
|airplane_lower|12|7.97533937636211|-8.10536415202695|0|12.5817160890444|1|-1|1|1|
|airplane_upper|20|11.209015830899|-3.11227681803873|0|4.9194153273339|1|-1|1|1|
|conversion15_lower|10|-1.90229208570154|-5.94042188855584|-7.03546656140298|-0.288642155779089|-1|-1|1|1|
|conversion15_upper|10|0.465126889441709|-2.54234613272407|1.40430211794375|0.0576139175917839|0.987878787878788|-1|0.888888888888889|1|
|conversion75_lower|12|8.51939507750638|-7.54708828288693|1.45859967218984|11.6089558090705|1|-1|1|1|
|conversion75_upper|20|12.0590964498777|-3.03093576542637|0.594808736484606|4.73406683708628|1|-1|1|1|
|helicopter_hover_connected|13|-2.84865767612755|1.55312759886743|-1.79051874775652|0|-1|0.357142857142857|1|0.75|

## Branch Comparison

|mode|betaM_deg|V_mps|branchA|branchB|thetaDiff_deg|collectiveDiff_deg|cyclicDiff_deg|elevatorDiff_deg|significant|
|-|-|-|-|-|-|-|-|-|-|
|helicopter_longitudinal|0|0|helicopter_hover_connected|helicopter_reverse_audit|5.94496948621431e-09|9.37312449877936e-11|3.80187102394687e-09|0|0|
|helicopter_longitudinal|0|5|helicopter_hover_connected|helicopter_reverse_audit|3.86634169124989e-10|1.61026392220265e-09|4.91715312911367e-09|0|0|
|helicopter_longitudinal|0|8|helicopter_9ms_low_branch|helicopter_9ms_high_branch|4.79286005328206e-09|1.9399948314458e-10|6.99335656051403e-09|0|0|
|helicopter_longitudinal|0|9|helicopter_9ms_low_branch|helicopter_9ms_high_branch|2.99394065095271e-10|1.55676360691359e-09|1.23736414447961e-08|0|0|
|helicopter_longitudinal|0|10|helicopter_hover_connected|helicopter_reverse_audit|1.07897051293548e-08|4.56168436357984e-10|7.02776614680545e-09|0|0|
|helicopter_longitudinal|0|15|helicopter_hover_connected|helicopter_reverse_audit|1.11228319887857e-08|9.96944748976603e-11|6.72151623248851e-09|0|0|
|helicopter_longitudinal|0|20|helicopter_hover_connected|helicopter_reverse_audit|7.09900849216183e-09|2.19779217047744e-09|6.37972341621662e-09|0|0|
|helicopter_longitudinal|0|25|helicopter_hover_connected|helicopter_reverse_audit|1.54530941376407e-08|3.43287887005772e-09|2.45219311523215e-09|0|0|
|helicopter_longitudinal|0|30|helicopter_hover_connected|helicopter_reverse_audit|6.9098353705499e-09|5.35637312282233e-10|2.56101562179367e-09|0|0|
|helicopter_longitudinal|0|2.5|helicopter_hover_connected|helicopter_reverse_audit|9.25704496390622e-09|1.20549259463587e-09|2.67719024726887e-09|0|0|
|helicopter_longitudinal|0|7.5|helicopter_hover_connected|helicopter_reverse_audit|1.13727434136734e-08|1.43429446097798e-09|1.28370314378401e-10|0|0|
|helicopter_longitudinal|0|8.5|helicopter_9ms_low_branch|helicopter_9ms_high_branch|9.57264401080238e-09|1.51811363480192e-09|1.09626849820188e-08|0|0|
|helicopter_longitudinal|0|9.5|helicopter_9ms_low_branch|helicopter_9ms_high_branch|9.82024284112981e-09|1.77177028604092e-09|2.7848316985768e-09|0|0|
|helicopter_longitudinal|0|10.5|helicopter_9ms_low_branch|helicopter_9ms_high_branch|1.79804922062488e-08|2.5286190918905e-09|7.05486269403366e-09|0|0|
|helicopter_longitudinal|0|12.5|helicopter_hover_connected|helicopter_reverse_audit|6.56342491467399e-09|3.55170115540204e-10|4.54408310979204e-09|0|0|
|helicopter_longitudinal|0|17.5|helicopter_hover_connected|helicopter_reverse_audit|8.96800544936127e-09|1.73121605939741e-09|6.24691187667281e-09|0|0|
|helicopter_longitudinal|0|22.5|helicopter_hover_connected|helicopter_reverse_audit|5.95007199066799e-09|3.10821590687738e-10|6.56572796131627e-09|0|0|
|helicopter_longitudinal|0|27.5|helicopter_hover_connected|helicopter_reverse_audit|6.48661457880451e-09|4.71941596913439e-09|1.35418132263254e-08|0|0|
|helicopter_longitudinal|0|7.75|helicopter_9ms_low_branch|helicopter_9ms_high_branch|6.88196847772882e-09|1.15827347713093e-09|2.03635308615446e-09|0|0|
|helicopter_longitudinal|0|8.25|helicopter_9ms_low_branch|helicopter_9ms_high_branch|1.02050706218826e-08|4.93390217570777e-10|1.01791943762919e-08|0|0|
|helicopter_longitudinal|0|8.75|helicopter_9ms_low_branch|helicopter_9ms_high_branch|8.61457916112585e-09|4.14304679452471e-09|1.16215191914293e-08|0|0|
|helicopter_longitudinal|0|9.25|helicopter_9ms_low_branch|helicopter_9ms_high_branch|7.89828202840681e-10|3.30794591718586e-09|1.97400792378843e-08|0|0|
|helicopter_longitudinal|0|9.75|helicopter_9ms_low_branch|helicopter_9ms_high_branch|7.02323332824051e-09|6.27290575039297e-09|9.88068071805515e-09|0|0|
|helicopter_longitudinal|0|10.25|helicopter_9ms_low_branch|helicopter_9ms_high_branch|6.44844178054882e-11|2.49367104743214e-09|3.33618155323734e-09|0|0|

## Stability Map Summary

|mode|points|candidate positive roots %|longitudinal %|lateral %|dominant real min/median/max|
|-|-:|-:|-:|-:|-|
|airplane_longitudinal|33|0.0|0.0|0.0|0 / 0 / 0|
|conversion_longitudinal|54|33.3|33.3|18.5|0 / 0 / 0.2325|
|helicopter_longitudinal|13|100.0|100.0|100.0|0.039 / 0.1219 / 0.3861|

Robustness sample rows: 36

## Figures

- helicopter: `E:\tiltrotor\validation\nuaa_trim_trends\20260625_184407\helicopter_nuaa_fig5a.png`
- airplane: `E:\tiltrotor\validation\nuaa_trim_trends\20260625_184407\airplane_nuaa_fig5b.png`
- conversion15: `E:\tiltrotor\validation\nuaa_trim_trends\20260625_184407\conversion_beta15_nuaa_fig6a.png`
- conversion75: `E:\tiltrotor\validation\nuaa_trim_trends\20260625_184407\conversion_beta75_nuaa_fig6b.png`
- maxReal: `E:\tiltrotor\validation\nuaa_trim_trends\20260625_184407\stability_max_real_by_mode.png`
- coverage: `E:\tiltrotor\validation\nuaa_trim_trends\20260625_184407\stability_long_lateral_coverage.png`

## Project Goal Check

The run keeps the current component force/moment chain and approved parameters. Any continuity, branch, control-margin, low-speed-boundary, or open-loop instability limitations are reported as model limitations. The current results cannot be called strict XV-15/GTRS validation because the parameter set is conceptual, complete public comparison data are not available in this workflow, and the low-order model omits effects such as dynamic inflow and flight-control stabilization.
