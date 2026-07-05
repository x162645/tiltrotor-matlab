# Model Validation Evidence Matrix
|runtime_default_protection|P.wing.modelType, fullAngleModelEnabled|INTERNAL_BALANCE|HARD|1|PENDING_GATE0|Hard gate protects production model.|
|trim_closure|residualNorm, fullResidualNorm, convergence|INTERNAL_BALANCE|HARD|1|PENDING_GATE1|Uses existing actual point files, not placeholder rows.|
|component_balance|component Fx/Fy/Fz/Mx/My/Mz|INTERNAL_BALANCE|HARD|1|PENDING_GATE2|No external flight-test claim.|
|rotor_control_power|thrust, torque, power, control derivatives|DERIVATIVE_SIGN|SOFT|0|PENDING_GATE3|External same-variable values are not hard coded.|
|wing_wake_full_angle|CL/CD/Cm range, wake coverage, branch weight|CONTINUITY_CHECK|SEMI_HARD|0|PENDING_GATE4|TM-88373 not used as whole-aircraft trim hard gate.|
|NUAA_fig5a_beta0|collective/pitch trend, vertical pitch not hard|TREND_CHECK|SOFT|0|PARTIAL_COMPARABLE|Control definitions not fully identical.|
|NUAA_fig6a_beta15|15 deg trim control trend|NON_COMPARABLE|NON_COMPARABLE|0|NON_COMPARABLE|pitchCommand allocation differs from cited manipulation method.|
|NUAA_fig6b_beta75|elevator trend only|OWNER_VISUAL_REVIEW_ONLY|SOFT|0|SOFT_COMPARABLE|Owner visual review required.|
|NUAA_fig5b_beta90|elevator trend only|OWNER_VISUAL_REVIEW_ONLY|SOFT|0|SOFT_COMPARABLE|Owner visual review required.|
|linearization_stability|A, B, eigenvalues|INTERNAL_BALANCE|HARD|1|PENDING_GATE6|No stability correctness claim from sign alone.|
|numerical_robustness|step sensitivity, seed/path sensitivity classification|CONTINUITY_CHECK|INTERNAL_ONLY|0|PENDING_GATE7|Long Monte Carlo is not run by this one-stop smoke audit.|
|owner_review_package|hard failures and limitations|OWNER_VISUAL_REVIEW_ONLY|INTERNAL_ONLY|0|PENDING_GATE8|Owner still judges soft comparisons.|













This matrix classifies which model outputs are externally comparable, internally checkable, or non-comparable under current control definitions.

























|Item|Output|Comparison|Strength|Hard Gate|Status|Notes|












|-|-|-|-|-|-|-|
