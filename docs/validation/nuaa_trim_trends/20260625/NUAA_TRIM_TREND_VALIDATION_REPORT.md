# NUAA Trim Trend Validation Report

## Project Goal Check

This run preserves the component-level mechanistic chain, uses only the current approved conceptual parameters, and evaluates whether the model gives computable, continuous, explainable trim trends. It is not a strict XV-15 or GTRS quantitative validation.

- Git commit: `58252d515ad538cd460d82c3fd536411ac781eac`
- Elapsed seconds: 2050.526
- Primary accepted PASS trim points: 100

## NUAA Section 4 Method Restatement

NUAA Section 4 trims steady conditions by driving state derivatives to zero so that resultant forces and moments balance. It computes helicopter mode, fixed-wing mode, and conversion modes at nacelle angles 15 deg and 75 deg. Figures 5 and 6 compare controls and pitch attitude versus speed. Figure 7 compares fixed-wing trim against GTRS and XV-15 actual trim results. Because complete XV-15 data are unavailable, the paper treats trend agreement and numerical closeness as rationality evidence, then analyzes stability derivatives and eigenvalues at trimmed linearization points. It does not require every open-loop mode to be stable.

This project currently has no complete digitized GTRS/XV-15 data, so the result below is only a NUAA-style trim trend baseline and physical reasonableness check.

## Trend Summary

|mode|pointCount|collectiveEndpointChange_deg|thetaEndpointChange_deg|cyclicEndpointChange_deg|elevatorEndpointChange_deg|collectiveSpearman|thetaSpearman|directionRatioCollective|directionRatioTheta|
|-|-|-|-|-|-|-|-|-|-|
|airplane_lower|12|7.97344313658104|-8.08520595081541|0|12.5552968537614|1|-1|1|1|
|airplane_upper|20|11.208901609312|-3.11093810895991|0|4.9179037909018|1|-1|1|1|
|conversion15_lower|10|-1.36286475087216|-7.44745354802967|-7.81898455291773|-0.32078733338582|-1|-1|1|1|
|conversion15_upper|10|0.373779844871102|-2.97070049234185|1.25701365510755|0.0515711542493127|0.987878787878788|-1|0.888888888888889|1|
|conversion75_lower|12|8.51522444683303|-7.5274673269707|1.45544141368021|11.5838193139985|1|-1|1|1|
|conversion75_upper|20|12.0604461592823|-3.02704746267113|0.594117882703232|4.72856835030377|1|-1|1|1|
|helicopter_hover_connected|13|-2.52788433114138|1.95362702608007|-2.49390670224335|0|-1|0.384615384615385|1|0.75|

## Branch Comparison

|mode|betaM_deg|V_mps|branchA|branchB|thetaDiff_deg|collectiveDiff_deg|cyclicDiff_deg|elevatorDiff_deg|significant|
|-|-|-|-|-|-|-|-|-|-|
|helicopter_longitudinal|0|0|helicopter_hover_connected|helicopter_reverse_audit|7.0436157651161e-09|1.09363895717252e-09|2.69849681518887e-09|0|0|
|helicopter_longitudinal|0|5|helicopter_hover_connected|helicopter_reverse_audit|3.96226718102355e-10|1.29753985333991e-09|1.97713956318069e-09|0|0|
|helicopter_longitudinal|0|8|helicopter_9ms_low_branch|helicopter_9ms_high_branch|4.84317586035843e-10|1.68886771234611e-09|1.40527083303255e-08|0|0|
|helicopter_longitudinal|0|9|helicopter_9ms_low_branch|helicopter_9ms_high_branch|1.24832570946865e-08|1.77655934407994e-09|4.48374082306913e-09|0|0|
|helicopter_longitudinal|0|10|helicopter_hover_connected|helicopter_reverse_audit|9.9393973052031e-09|2.83273848822319e-09|6.1344651580697e-09|0|0|
|helicopter_longitudinal|0|15|helicopter_hover_connected|helicopter_reverse_audit|8.72363603576787e-09|2.56160603839817e-09|5.18662068849096e-09|0|0|
|helicopter_longitudinal|0|20|helicopter_hover_connected|helicopter_reverse_audit|3.48669093597209e-09|1.81356440975833e-09|1.0259316951533e-08|0|0|
|helicopter_longitudinal|0|25|helicopter_hover_connected|helicopter_reverse_audit|2.67666511177822e-09|1.77043268934085e-09|1.76991252764935e-08|0|0|
|helicopter_longitudinal|0|30|helicopter_hover_connected|helicopter_reverse_audit|4.95626761853885e-09|7.74958763827271e-10|1.72947167698112e-09|0|0|
|helicopter_longitudinal|0|2.5|helicopter_hover_connected|helicopter_reverse_audit|5.04756753061386e-09|1.65066538215797e-09|1.33728700890678e-08|0|0|
|helicopter_longitudinal|0|7.5|helicopter_hover_connected|helicopter_reverse_audit|1.3571505030896e-11|1.381987857485e-09|7.07162317592491e-09|0|0|
|helicopter_longitudinal|0|8.5|helicopter_9ms_low_branch|helicopter_9ms_high_branch|1.18843774821187e-08|1.54290447085259e-09|1.2977333985198e-08|0|0|
|helicopter_longitudinal|0|9.5|helicopter_9ms_low_branch|helicopter_9ms_high_branch|3.25854587757135e-09|3.03343838936598e-09|7.1690422487336e-09|0|0|
|helicopter_longitudinal|0|10.5|helicopter_9ms_low_branch|helicopter_9ms_high_branch|7.56715134997421e-10|1.8574262128368e-09|5.0942703389012e-09|0|0|
|helicopter_longitudinal|0|12.5|helicopter_hover_connected|helicopter_reverse_audit|1.73927539037777e-09|1.1705623137459e-09|3.6666296665544e-09|0|0|
|helicopter_longitudinal|0|17.5|helicopter_hover_connected|helicopter_reverse_audit|4.32552216267368e-10|1.14964038289145e-09|3.62863117331358e-09|0|0|
|helicopter_longitudinal|0|22.5|helicopter_hover_connected|helicopter_reverse_audit|3.46872752743366e-09|3.06165937047354e-09|1.13246274580092e-08|0|0|
|helicopter_longitudinal|0|27.5|helicopter_hover_connected|helicopter_reverse_audit|1.76303474042072e-08|6.58521415175528e-09|5.01223773596848e-09|0|0|
|helicopter_longitudinal|0|7.75|helicopter_9ms_low_branch|helicopter_9ms_high_branch|1.63523793256237e-08|2.02201633214827e-09|9.8020551675404e-09|0|0|
|helicopter_longitudinal|0|8.25|helicopter_9ms_low_branch|helicopter_9ms_high_branch|1.07976300123269e-08|1.76342140889574e-09|4.31757252172815e-09|0|0|
|helicopter_longitudinal|0|8.75|helicopter_9ms_low_branch|helicopter_9ms_high_branch|9.94983828661589e-09|1.37790934218174e-09|8.37853242341424e-09|0|0|
|helicopter_longitudinal|0|9.25|helicopter_9ms_low_branch|helicopter_9ms_high_branch|6.2563838554297e-09|2.92601498586009e-09|1.04273989443016e-09|0|0|
|helicopter_longitudinal|0|9.75|helicopter_9ms_low_branch|helicopter_9ms_high_branch|2.76489853234807e-09|1.13574571969366e-09|3.31052518731667e-09|0|0|
|helicopter_longitudinal|0|10.25|helicopter_9ms_low_branch|helicopter_9ms_high_branch|1.90341031824914e-09|4.08025613296559e-10|1.60411173233399e-08|0|0|

## Stability Map Summary

|mode|points|candidate positive roots %|longitudinal %|lateral %|dominant real min/median/max|
|-|-:|-:|-:|-:|-|
|airplane_longitudinal|33|0.0|0.0|0.0|0 / 0 / 0|
|conversion_longitudinal|54|27.8|27.8|25.9|0 / 0 / 0.277|
|helicopter_longitudinal|13|100.0|100.0|100.0|0.04328 / 0.192 / 0.4221|

Robustness sample rows: 36

## Figures

- helicopter: `E:\tiltrotor\validation\nuaa_trim_trends\20260625_091852\helicopter_nuaa_fig5a.png`
- airplane: `E:\tiltrotor\validation\nuaa_trim_trends\20260625_091852\airplane_nuaa_fig5b.png`
- conversion15: `E:\tiltrotor\validation\nuaa_trim_trends\20260625_091852\conversion_beta15_nuaa_fig6a.png`
- conversion75: `E:\tiltrotor\validation\nuaa_trim_trends\20260625_091852\conversion_beta75_nuaa_fig6b.png`
- maxReal: `E:\tiltrotor\validation\nuaa_trim_trends\20260625_091852\stability_max_real_by_mode.png`
- coverage: `E:\tiltrotor\validation\nuaa_trim_trends\20260625_091852\stability_long_lateral_coverage.png`

## Project Goal Check

The run keeps the current component force/moment chain and approved parameters. Any continuity, branch, control-margin, low-speed-boundary, or open-loop instability limitations are reported as model limitations. The current results cannot be called strict XV-15/GTRS validation because the parameter set is conceptual, complete public comparison data are not available in this workflow, and the low-order model omits effects such as dynamic inflow and flight-control stabilization.
