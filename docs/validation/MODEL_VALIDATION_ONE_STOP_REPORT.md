# Model Validation One-Stop Report

Final conclusion: `MODEL_VALIDATION_PARTIAL_WITH_LIMITATIONS`.

## 1. One-Sentence Conclusion

The current concept model has an automated internal evidence chain, but external trim-trend comparisons remain partial, soft, or non-comparable where control definitions differ.

## 2. What The Current Model Can Validate

- Runtime/default protection, trim closure, component force/moment balance, finite linearization, and selected control derivative signs.
- Full-angle wing opt-in behavior and wake sensitivity as internal/semi-hard evidence.

## 3. What The Current Model Cannot Directly Validate

- Strict XV-15 reproduction, direct NUAA 0/15 deg vertical pitch hard comparisons, or screenshot-only trend matches as PASS/FAIL decisions.

## 4. External Source Inventory

|source_id|relative_path|present|current_status|
|-|-|-|-|
|NASA_CR_114614|references\wing_full_angle\NASA_CR_114614_source_verified_technical_extract_NOT_FACSIMILE.pdf|1|AVAILABLE_OR_OPTIONAL_MISSING|
|NASA_TM_88373|references\wing_full_angle\NASA_TM_88373.pdf|1|AVAILABLE_OR_OPTIONAL_MISSING|
|NASA_TM_X_62407|references\NASA_TM_X_62407.pdf|1|AVAILABLE_OR_OPTIONAL_MISSING|
|NASA_TM_81244|references\NASA_TM_81244.pdf|1|AVAILABLE_OR_OPTIONAL_MISSING|
|NUAA_main_paper|references\NUAA_main_paper.pdf|1|AVAILABLE_OR_OPTIONAL_MISSING|
|Berger_HeliUM_or_handling_qualities|references\Berger_or_HeliUM_placeholder.pdf|0|MISSING_OPTIONAL|

## 5. Evidence Matrix Summary
- Evidence rows: 12.
- Hard evidence rows: 4.
- Non-comparable rows: 1.

## 6. Gate 0-8 Status

|gate_no|gate|status|hard_gate|runtime_s|notes|
|-|-|-|-|-|-|
|0|GATE0_RUNTIME_DEFAULT|PASS|1|3.09224|Gate0 checks passed 6/6.|
|1|GATE1_TRIM_CLOSURE|PASS|1|0.63642|Trim rows read from existing envelope: 84.|
|2|GATE2_COMPONENT_BALANCE|PASS|1|0.433542|Component balance checked on 5 saved trim points.|
|3|GATE3_ROTOR_CONTROL|PASS|0|0.818239|Rotor/control derivatives computed at one representative hover state.|
|4|GATE4_WING_WAKE|PASS|0|0.987771|Full-angle wing path checked without changing defaults.|
|5|GATE5_TRIM_TREND_COMPARABILITY|PASS_WITH_LIMITATIONS|0|0.308967|0 deg partial, 15 deg non-comparable, 75/90 deg soft comparable.|
|6|GATE6_LINEARIZATION_STABILITY|PASS|1|2.83092|Linearization checked on 3 saved trim points.|
|7|GATE7_NUMERICAL_ROBUSTNESS|PASS_WITH_LIMITATIONS|0|3.80024|Local step-size sensitivity completed; broad sweeps are not rerun here.|
|8|GATE8_OWNER_PACKAGE|PASS|0|0.0088478|Owner package manifest generated.|

## 7. Hard Gate Failures

_None._

## 8. Non-Comparable Items

|validation_item|model_case|current_status|notes|
|-|-|-|-|
|NUAA_fig6a_beta15|15 deg conversion_longitudinal|NON_COMPARABLE|pitchCommand allocation differs from cited manipulation method.|

## 9. Soft Reference Items

|validation_item|model_case|current_status|notes|
|-|-|-|-|
|rotor_control_power|hover representative point|PENDING_GATE3|External same-variable values are not hard coded.|
|NUAA_fig5a_beta0|0 deg trim trend|PARTIAL_COMPARABLE|Control definitions not fully identical.|
|NUAA_fig6b_beta75|75 deg trim trend|SOFT_COMPARABLE|Owner visual review required.|
|NUAA_fig5b_beta90|90 deg trim trend|SOFT_COMPARABLE|Owner visual review required.|
|owner_review_package|owner package|PENDING_GATE8|Owner still judges soft comparisons.|

## 10. 0 deg Curvature Handling

Current classification: `PARTIAL_COMPARABLE`. It is a partial trend context, not a hard gate.

## 11. 15 deg NUAA Trim-Angle Non-Comparability

Current classification: `NON_COMPARABLE_OR_UNRESOLVED`. The current conversion_longitudinal pitchCommand allocation is not treated as the same control definition.

## 12. 75/90 deg Screenshot-Level Trend Handling

Current classification: `SOFT_COMPARABLE`. These items require owner visual review and cannot be promoted to automatic PASS.

## 13. Can It Enter Follow-On Handling-Qualities Work

Yes, with limitations: use it as a concept-level component model with internal consistency evidence, not as a validated XV-15 reproduction.

## 14. Owner Must Review

- `hard_gate_failures.csv`
- `non_comparable_items.csv`
- `gate_summary.csv`
- This one-stop report

## 15. Recommended Next Actions

|item|type|status|notes|
|-|-|-|-|
|runtime_default_protection|EVIDENCE_LIMITATION|PENDING_GATE0|Hard gate protects production model.|
|trim_closure|EVIDENCE_LIMITATION|PENDING_GATE1|Uses existing actual point files, not placeholder rows.|
|component_balance|EVIDENCE_LIMITATION|PENDING_GATE2|No external flight-test claim.|
|rotor_control_power|EVIDENCE_LIMITATION|PENDING_GATE3|External same-variable values are not hard coded.|
|wing_wake_full_angle|EVIDENCE_LIMITATION|PENDING_GATE4|TM-88373 not used as whole-aircraft trim hard gate.|
|NUAA_fig5a_beta0|EVIDENCE_LIMITATION|PARTIAL_COMPARABLE|Control definitions not fully identical.|
|NUAA_fig6a_beta15|EVIDENCE_LIMITATION|NON_COMPARABLE|pitchCommand allocation differs from cited manipulation method.|
|NUAA_fig6b_beta75|EVIDENCE_LIMITATION|SOFT_COMPARABLE|Owner visual review required.|
|NUAA_fig5b_beta90|EVIDENCE_LIMITATION|SOFT_COMPARABLE|Owner visual review required.|
|linearization_stability|EVIDENCE_LIMITATION|PENDING_GATE6|No stability correctness claim from sign alone.|
|numerical_robustness|EVIDENCE_LIMITATION|PENDING_GATE7|Long Monte Carlo is not run by this one-stop smoke audit.|
|owner_review_package|EVIDENCE_LIMITATION|PENDING_GATE8|Owner still judges soft comparisons.|
|Berger_HeliUM_or_handling_qualities|SOURCE_LIMITATION|MISSING_OPTIONAL|Optional higher-order handling-quality reference|
