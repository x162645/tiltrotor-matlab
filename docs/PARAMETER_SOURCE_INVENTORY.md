# Parameter Source Inventory

## Scope and counting rules

Static inventory at commit `b9fc139852b18f38bbc9c417432248f569a14b67`. MATLAB was not run. This document inventories all 120 leaf fields defined by `params_nominal.m`, active embedded constants in `model/`, callable analysis defaults, and grouped diagnostic/test-only setting bundles. A vector or matrix assigned as one parameter is one inventory item. Repeated occurrences of the same implementation guard (for example the `1e-8 m/s` zero-speed guard) are one item with all consumers listed. Diagnostic seed/sweep vectors are grouped by file because they are one file-local experiment configuration and do not affect production behavior.

Source-status vocabulary is exactly that required by `CODEX_TASK.md`. `ASSUMED_CONCEPT` means the current value is explicitly a conceptual selection; it does not mean that a future aircraft-specific source is unnecessary. Existing project notes are evidence of code intent only and are never treated as documentary proof.

Consumer abbreviations: `RB` = `model/rotor_model_bemt.m`; `WG` = `model/wing_model.m`; `FU` = `model/fuselage_model.m`; `HT` = `model/horizontal_tail_model.m`; `VT` = `model/vertical_tail_model.m`; `MP` = `model/mass_properties.m`; `TFM` = `model/total_forces_moments.m`; `EOM` = `model/tiltrotor_eom.m`; `TR` = `analysis/trim_symmetric.m`; `LIN` = `analysis/linearize_numeric.m`.

## Inventory

|ID|parameter / constant|current value or expression|SI unit|category|physical or numerical|consumer files/functions|source-status label|source document|exact page/table/equation/line location|derivation or interpretation|confidence|issue severity|blocks later work?|notes|
|-|-|-|-|-|-|-|-|-|-|-|-|-|-|-|
|ENV-001|`P.env.rho`|`1.225`|kg/m^3|environment|physical|RB, WG, FU, HT, VT|ASSUMED_CONCEPT|none|Code: `params_nominal.m:9`|Constant sea-level-like density; no atmosphere model|HIGH|LOW|yes|Blocks sourced performance comparison, not conceptual execution|
|ENV-002|`P.env.g`|`9.80665`|m/s^2|environment|physical|MP-derived checks, RB, EOM, TR scaling|ASSUMED_CONCEPT|none|Code: `params_nominal.m:10`|Constant standard-gravity-like value|HIGH|LOW|no|No repository citation establishes it|
|MAS-001|`P.mass.m`|`6000.0`|kg|mass|physical|MP, RB hover seed, EOM|ASSUMED_CONCEPT|none|Code: `params_nominal.m:13`|Total aircraft mass|HIGH|MEDIUM|yes|NASA sources distinguish several weight states; current value is not mapped to one|
|MAS-002|`P.mass.mNac`|`900.0`|kg|mass|physical|MP|ASSUMED_CONCEPT|none|Code: `params_nominal.m:14-16`|Combined moving mass of both nacelle/rotor assemblies, not per side|HIGH|MEDIUM|yes|Meaning is explicit in code; documentary source and included hardware are absent|
|MAS-003|`P.mass.RH`|`0.75`|m|mass/geometry|physical|MP, RB hub position|AMBIGUOUS_COUPLED|none|Code: `params_nominal.m:17-21`; reads `MP:5-6`, `RB:34-36`|Both moving-mass CG radius and rotor-hub tilt radius|HIGH|HIGH|yes|Must be behavior-preservingly split before independent sourcing|
|MAS-004|`P.mass.I0`|`[18000 0 -800; 0 30000 0; -800 0 45000]`|kg m^2|inertia|physical|MP, input validation, EOM through `mp.I`|ASSUMED_CONCEPT|none|Code: `params_nominal.m:23-25`|Nominal inertia at code `betaM=0`|HIGH|HIGH|yes|NASA TM X-62407 has configuration-specific values, but current matrix is not traced to them|
|MAS-005|`P.mass.KI`|`diag([300 500 400])`|kg m^2/rad|inertia|physical|MP|ASSUMED_CONCEPT|none|Code: `params_nominal.m:27-28`; `MP:10`|Slope in `I=I0-betaM*KI`, explicitly per radian|HIGH|HIGH|yes|Per-degree source data would require a factor of `180/pi`; no source is established|
|ROT-001|`P.rotor.R`|`3.80`|m|rotor geometry|physical|RB, physical checks|ASSUMED_CONCEPT|NASA_TM_X_62407.pdf (candidate only)|PDF 20, printed 17, section 3.7 gives 25.0 ft diameter|Current radius is not the exact SI conversion `25 ft/2 = 3.81 m`|HIGH|MEDIUM|yes|Do not silently round a source value to justify the current value|
|ROT-002|`P.rotor.Nb`|`3`|1|rotor geometry|physical|RB load integration|DOCUMENTED_PRIMARY|NASA_TM_X_62407.pdf; NASA_TM_81244.pdf|X-62407 PDF 20, printed 17, section 3.7; 81244 PDF 4, Design Characteristics paragraph|Three blades per rotor for the documented XV-15 configuration|HIGH|NONE|no|Only current aircraft-specific numeric value confirmed exactly in this pass|
|ROT-003|`P.rotor.Omega`|`62.0`|rad/s|rotor operation|physical|RB throughout|ASSUMED_CONCEPT|NASA_TM_X_62407.pdf; NASA_TM_81244.pdf (conflict context only)|X-62407 PDF 22, printed 19, section 3.8; 81244 PDF 8, airplane-mode flight paragraph|Constant code speed; sources describe 565/458 rpm design and 589/517/458 rpm flight-stage scheduling|HIGH|HIGH|yes|`62 rad/s` is about 592 rpm and is not a universal documented XV-15 setting|
|ROT-004|`P.rotor.chord`|`0.38`|m|rotor geometry|physical|RB blade elements|ASSUMED_CONCEPT|NASA_TM_X_62407.pdf (candidate only)|PDF 20, printed 17, section 3.7; PDF 49, printed 46, section 6.3|Constant chord in code; source states 14 in (`0.3556 m`) steel blade|HIGH|MEDIUM|yes|Current value does not equal cited source|
|ROT-005|`P.rotor.rootCut`|`0.18`|r/R|rotor geometry|physical|RB radial grid and linear twist origin|ASSUMED_CONCEPT|none|Code: `params_nominal.m:35`; `RB:280,298`|Aerodynamic integration starts at `0.18R`; not a hinge offset|HIGH|MEDIUM|yes|Root geometry and valid airfoil region are unsourced|
|ROT-006|`P.rotor.twistTip`|`-6*pi/180`|rad|rotor geometry|physical|RB linear twist|ASSUMED_CONCEPT|NASA_TM_X_62407.pdf; NASA_TM_81244.pdf (candidate/conflict context)|X-62407 PDF 21, printed 18, Fig. 3.7.1; 81244 PDF 4, Design Characteristics says 45 deg root-to-tip|Code uses one linear tip delta from `rootCut`; source figure is nonlinear and blade/configuration interpretation requires review|HIGH|HIGH|yes|Do not equate `-6 deg` with the documented 45 deg root-to-tip statement|
|ROT-007|`P.rotor.liftSlope`|`5.7`|1/rad|rotor airfoil|physical|RB polar|ASSUMED_CONCEPT|none|Code: `params_nominal.m:38`|Linear lift slope inside tanh saturation|HIGH|MEDIUM|yes|Airfoil, Reynolds and Mach dependence absent|
|ROT-008|`P.rotor.CLmax`|`1.35`|1|rotor airfoil|physical|RB polar|ASSUMED_CONCEPT|none|Code: `params_nominal.m:39`|Symmetric tanh lift cap|HIGH|MEDIUM|yes|Not a measured XV-15 polar|
|ROT-009|`P.rotor.CD0`|`0.011`|1|rotor airfoil|physical|RB polar|ASSUMED_CONCEPT|none|Code: `params_nominal.m:40`|Profile drag intercept|HIGH|MEDIUM|yes|No Mach/Reynolds scheduling|
|ROT-010|`P.rotor.kCD`|`0.012`|1|rotor airfoil|physical|RB polar|ASSUMED_CONCEPT|none|Code: `params_nominal.m:41`|Quadratic `CD=CD0+kCD*CL^2` coefficient|HIGH|MEDIUM|yes|Simplified polar|
|ROT-011|`P.rotor.pivotX`|`0.0`|m|rotor geometry|physical|RB hub position|ASSUMED_CONCEPT|none|Code: `params_nominal.m:44`; `RB:34`|Tilt-axis reference x coordinate|HIGH|HIGH|yes|Origin and aircraft station mapping absent|
|ROT-012|`P.rotor.pivotY`|`5.0`|m|rotor geometry|physical|RB hub position|ASSUMED_CONCEPT|NASA_TM_X_62407.pdf (candidate only)|Code: `params_nominal.m:45`; source PDF 15, printed 12 gives 32.17 ft between rotor centerlines|Code half-spacing is not traced to exact source/conversion|HIGH|HIGH|yes|Coordinate origin and tilt-axis definition must be matched|
|ROT-013|`P.rotor.pivotZ`|`0.0`|m|rotor geometry|physical|RB hub position|ASSUMED_CONCEPT|none|Code: `params_nominal.m:46`; `RB:36`|Tilt-axis reference z coordinate|HIGH|HIGH|yes|Three-dimensional station source missing|
|ROT-014|`P.rotor.nRadial`|`12`|1|discretization|numerical|RB radial quadrature|NUMERICAL|none|Code: `params_nominal.m:48`; `RB:281`|Number of radial elements|HIGH|LOW|no|Grid convergence is test-only and limited|
|ROT-015|`P.rotor.nAzimuth`|`16`|1|discretization|numerical|RB Fourier/load averaging|NUMERICAL|none|Code: `params_nominal.m:49`; `RB:340,358`|Azimuth samples|HIGH|LOW|no|Affects load/flap accuracy|
|ROT-016|`P.rotor.inducedMaxIter`|`20`|iteration|solver|numerical|RB coupled solve|NUMERICAL|none|Code: `params_nominal.m:51`; `RB:61`|Maximum outer induced/flap iterations|HIGH|LOW|no||
|ROT-017|`P.rotor.inducedRelax`|`0.45`|1|solver|numerical|RB coupled solve|NUMERICAL|none|Code: `params_nominal.m:52`; `RB:74-75`|Under-relaxation fraction|HIGH|LOW|no||
|ROT-018|`P.rotor.inducedTol`|`1e-4`|relative|solver|numerical|RB convergence|NUMERICAL|none|Code: `params_nominal.m:53`; `RB:76,79`|Relative induced-velocity change tolerance|HIGH|LOW|no||
|ROT-019|`P.rotor.inflowHarmonic`|`1.0`|1|compatibility|physical|none|DEPRECATED_UNUSED|none|Code: `params_nominal.m:54-56`; no read in `model/` or `analysis/`|Legacy placeholder; formal path sets `viField=viMean`|HIGH|INFO|no|Nonuniform inflow is not implemented|
|ROT-020|`P.rotor.flapCyclicGain`|`1.20`|1|compatibility|physical|none|DEPRECATED_UNUSED|none|Code: `params_nominal.m:58-60`; no production read|Legacy empirical disk-tilt gain|HIGH|INFO|no||
|ROT-021|`P.rotor.flapMuGain`|`0.10`|1|compatibility|physical|none|DEPRECATED_UNUSED|none|Code: `params_nominal.m:61`; no production read|Legacy empirical gain|HIGH|INFO|no||
|ROT-022|`P.rotor.flapLatMuGain`|`0.05`|1|compatibility|physical|none|DEPRECATED_UNUSED|none|Code: `params_nominal.m:62`; no production read|Legacy empirical gain|HIGH|INFO|no||
|ROT-023|`P.rotor.flapQGain`|`10.0`|s|compatibility|physical|none|DEPRECATED_UNUSED|none|Code: `params_nominal.m:63`; no production read|Legacy empirical gain; historical unit not safely established|MEDIUM|INFO|no||
|ROT-024|`P.rotor.flapPGain`|`5.0`|s|compatibility|physical|none|DEPRECATED_UNUSED|none|Code: `params_nominal.m:64`; no production read|Legacy empirical gain; historical unit not safely established|MEDIUM|INFO|no||
|ROT-025|`P.rotor.flapMax`|`18*pi/180`|rad|compatibility|physical|none|DEPRECATED_UNUSED|none|Code: `params_nominal.m:65`; no production read|Legacy limit superseded by `flapDivergenceAngle` in formal solver|HIGH|INFO|no||
|ROT-026|`P.rotor.bladeMass`|`45.0`|kg/blade|blade mass|physical|derives `Ib`, `Sblade`|ASSUMED_CONCEPT|none|Code: `params_nominal.m:68-74`|Single-blade conceptual mass|HIGH|HIGH|yes|Steel/composite/advanced blade version not identified|
|ROT-027|`P.rotor.bladeMassDistribution`|`ASSUMED_UNIFORM_FULL_SPAN`|text|blade mass|physical|metadata only; not read by production|ASSUMED_CONCEPT|none|Code: `params_nominal.m:69,72`; no production read|Declares uniform `0<=r<=R` assumption used manually in derivations|HIGH|HIGH|yes|Contradicts aerodynamic root cut as a mass integration boundary unless explicitly intended|
|ROT-028|`P.rotor.Ib`|`bladeMass*R^2/3`|kg m^2|blade inertia|physical|RB flap dynamics|DERIVED|none|Code: `params_nominal.m:73`; `RB:258-259`|Uniform full-span blade second mass moment|HIGH|HIGH|yes|Parents ROT-001 and ROT-026; no hinge offset|
|ROT-029|`P.rotor.Sblade`|`bladeMass*R/2`|kg m|blade first mass moment|physical|RB gravity flap moment|DERIVED|none|Code: `params_nominal.m:74`; `RB:255`|Uniform full-span blade first mass moment|HIGH|HIGH|yes|Parents ROT-001 and ROT-026|
|ROT-030|`P.rotor.flapInitial`|`[0;0;0]`|rad|solver seed|numerical|RB flap solve|NUMERICAL|none|Code: `params_nominal.m:75`; `RB:51`|Initial `[beta0 beta1c beta1s]`|HIGH|LOW|no||
|ROT-031|`P.rotor.flapResidualTol`|`1e-7`|normalized|solver|numerical|RB flap/coupled convergence|NUMERICAL|none|Code: `params_nominal.m:78`; `RB:80,172`|Normalized flap residual tolerance|HIGH|LOW|no||
|ROT-032|`P.rotor.flapMaxIter`|`40`|iteration|solver|numerical|RB Newton solve|NUMERICAL|none|Code: `params_nominal.m:79`; `RB:162`|Maximum Newton iterations|HIGH|LOW|no||
|ROT-033|`P.rotor.flapJacobianStep`|`1e-5`|relative/rad|solver|numerical|RB finite-difference Jacobian|NUMERICAL|none|Code: `params_nominal.m:80`; `RB:223`|Scaled central-difference step|HIGH|MEDIUM|yes|Sensitivity only partly tested|
|ROT-034|`P.rotor.flapNewtonDamping`|`0.5`|1|solver|numerical|RB line search|NUMERICAL|none|Code: `params_nominal.m:81`; `RB:203`|Step reduction factor|HIGH|LOW|no||
|ROT-035|`P.rotor.flapNewtonRegularization`|`1e-8`|matrix-dependent|solver|numerical|RB normal equations|NUMERICAL|none|Code: `params_nominal.m:82`; `RB:187-188`|Diagonal regularization; dimensional interpretation follows normalized Jacobian|MEDIUM|MEDIUM|yes|Unit/scale dependence should be documented before solver changes|
|ROT-036|`P.rotor.flapLineSearchMaxIter`|`18`|iteration|solver|numerical|RB line search|NUMERICAL|none|Code: `params_nominal.m:83`; `RB:192`|Maximum backtracks|HIGH|LOW|no||
|ROT-037|`P.rotor.flapDivergenceAngle`|`80*pi/180`|rad|applicability guard|numerical|RB valid-state check|NUMERICAL|none|Code: `params_nominal.m:84`; `RB:238`|Rejects flap states exceeding 80 deg|HIGH|MEDIUM|yes|Numerical guard, not a physical flap stop|
|ROT-038|`P.rotor.wakeFactor`|`1.60`|1|rotor-wing interference|physical|WG slipstream velocity|ASSUMED_CONCEPT|none|Code: `params_nominal.m:86`; `WG:75`|Multiplier on nonnegative mean induced velocity|HIGH|HIGH|yes|Uniform one-way wake model only|
|ROT-039|`P.rotor.Jpolar`|`0.0`|kg m^2|rotor inertia|physical|RB gyro moment|ASSUMED_CONCEPT|none|Code: `params_nominal.m:88-89`; `RB:106-107`|Zero disables rotor gyroscopic channel|HIGH|HIGH|yes|Needs rotating assembly polar inertia and speed schedule|
|WIN-001|`P.wing.S`|`18.0`|m^2|wing geometry|physical|WG|ASSUMED_CONCEPT|NASA_TM_X_62407.pdf (candidate conflict)|Code: `params_nominal.m:92`; source PDF 15, printed 12 gives 169 ft^2|Total modeled wing area; not equal to exact cited conversion|HIGH|MEDIUM|yes||
|WIN-002|`P.wing.b`|`10.0`|m|wing geometry|physical|sanity/reference only; not WG loads|ASSUMED_CONCEPT|NASA_TM_X_62407.pdf (candidate)|Code: `params_nominal.m:93`; source PDF 15, printed 12 gives 32.17 ft rotor-center span notation|Reference span; production wing force does not consume it|HIGH|MEDIUM|yes|Definition may differ from aerodynamic span|
|WIN-003|`P.wing.c`|`1.50`|m|wing geometry|physical|WG pitch moment|ASSUMED_CONCEPT|NASA_TM_X_62407.pdf (candidate)|Code: `params_nominal.m:94`; source PDF 15, printed 12 has chord/MAC entries|Reference chord|HIGH|MEDIUM|yes||
|WIN-004|`P.wing.xAC`|`0.0`|m|wing station|physical|WG all regions|ASSUMED_CONCEPT|none|Code: `params_nominal.m:96`; `WG:35,46`|AC x relative to nominal CG origin|HIGH|HIGH|yes||
|WIN-005|`P.wing.yFreeAC`|`1.70`|m|wing station|physical|WG free-flow regions|ASSUMED_CONCEPT|none|Code: `params_nominal.m:97`; `WG:36`|Half-wing free-flow resultant station|HIGH|HIGH|yes||
|WIN-006|`P.wing.ySlipAC`|`4.00`|m|wing station|physical|WG slipstream regions|ASSUMED_CONCEPT|none|Code: `params_nominal.m:98`; `WG:47`|Half-wing slipstream resultant station|HIGH|HIGH|yes||
|WIN-007|`P.wing.zAC`|`0.05`|m|wing station|physical|WG all regions|ASSUMED_CONCEPT|none|Code: `params_nominal.m:99`; `WG:37,48`|AC z relative to nominal CG origin|HIGH|HIGH|yes||
|WIN-008|`P.wing.CL0`|`0.15`|1|wing aerodynamics|physical|WG lift-line branch|ASSUMED_CONCEPT|none|Code: `params_nominal.m:101`|Lift intercept|HIGH|MEDIUM|yes||
|WIN-009|`P.wing.CLalpha`|`5.20`|1/rad|wing aerodynamics|physical|WG lift-line branch|ASSUMED_CONCEPT|none|Code: `params_nominal.m:102`|Lift slope|HIGH|HIGH|yes||
|WIN-010|`P.wing.CLmax`|`1.45`|1|wing saturation|physical|WG tanh cap|ASSUMED_CONCEPT|none|Code: `params_nominal.m:103`|Symmetric smooth lift cap|HIGH|HIGH|yes|No flap/nacelle/Re/Mach schedule|
|WIN-011|`P.wing.CD0`|`0.025`|1|wing aerodynamics|physical|WG|ASSUMED_CONCEPT|none|Code: `params_nominal.m:104`|Drag intercept|HIGH|MEDIUM|yes||
|WIN-012|`P.wing.kInduced`|`0.055`|1|wing aerodynamics|physical|WG|ASSUMED_CONCEPT|none|Code: `params_nominal.m:105`|Quadratic induced-drag coefficient|HIGH|MEDIUM|yes||
|WIN-013|`P.wing.CYbeta`|`-0.35`|1/rad|wing aerodynamics|physical|WG|ASSUMED_CONCEPT|none|Code: `params_nominal.m:106`|Side-force derivative|HIGH|MEDIUM|yes||
|WIN-014|`P.wing.Cm0`|`-0.03`|1|wing aerodynamics|physical|WG|ASSUMED_CONCEPT|none|Code: `params_nominal.m:108`|Pitch-moment intercept|HIGH|MEDIUM|yes||
|WIN-015|`P.wing.Cmalpha`|`-0.45`|1/rad|wing aerodynamics|physical|WG|ASSUMED_CONCEPT|none|Code: `params_nominal.m:109`|Pitch-moment slope|HIGH|HIGH|yes||
|WIN-016|`P.wing.CLaileron`|`0.45`|1/rad|wing control derivative|physical|WG|ASSUMED_CONCEPT|none|Code: `params_nominal.m:110`|Side-signed lift increment from aileron|HIGH|HIGH|yes||
|WIN-017|`P.wing.Cmaileron`|`-0.08`|1/rad|wing control derivative|physical|WG|ASSUMED_CONCEPT|none|Code: `params_nominal.m:111`|Side-signed pitch-moment increment|HIGH|MEDIUM|yes||
|WIN-018|`P.wing.SslipMaxHalf`|`4.0`|m^2|wing interaction|physical|WG|ASSUMED_CONCEPT|none|Code: `params_nominal.m:113`|Maximum slipstream area per half-wing|HIGH|HIGH|yes||
|WIN-019|`P.wing.muMax`|`0.35`|1|wing interaction|physical|WG heuristic|ASSUMED_CONCEPT|none|Code: `params_nominal.m:114`; `WG:15`|Advance-ratio normalization for slip-area reduction|HIGH|HIGH|yes||
|WIN-020|`P.wing.CDnormal`|`1.10`|1|wing normal-flow|physical|WG near-normal branch|ASSUMED_CONCEPT|none|Code: `params_nominal.m:115`|Normal-force drag-like coefficient|HIGH|HIGH|yes||
|WIN-021|`P.wing.normalFlowRatio`|`0.35`|`abs(Vx)/V`|applicability/blend|physical|WG|ASSUMED_CONCEPT|none|Code: `params_nominal.m:116-117`; `WG:98`|Blend center|HIGH|HIGH|yes|Code-only applicability boundary|
|WIN-022|`P.wing.normalFlowBlendHalfWidth`|`0.15`|`abs(Vx)/V`|applicability/blend|physical|WG|ASSUMED_CONCEPT|none|Code: `params_nominal.m:118-121`; `WG:102`|Quintic blend half-width|HIGH|HIGH|yes|Continuity choice, not aerodynamic validation|
|FUS-001|`P.fuselage.S`|`8.0`|m^2|fuselage geometry|physical|FU|ASSUMED_CONCEPT|none|Code: `params_nominal.m:124`|Reference area|HIGH|MEDIUM|yes||
|FUS-002|`P.fuselage.b`|`3.0`|m|fuselage geometry|physical|FU rate normalization/moments|ASSUMED_CONCEPT|none|Code: `params_nominal.m:125`|Lateral reference length|HIGH|MEDIUM|yes||
|FUS-003|`P.fuselage.c`|`4.0`|m|fuselage geometry|physical|FU rate normalization/moments|ASSUMED_CONCEPT|none|Code: `params_nominal.m:126`|Longitudinal reference length|HIGH|MEDIUM|yes||
|FUS-004|`P.fuselage.rAC`|`[0.20;0;0.10]`|m|fuselage station|physical|FU|ASSUMED_CONCEPT|none|Code: `params_nominal.m:127`; `FU:8`|AC relative to nominal CG|HIGH|HIGH|yes||
|FUS-005|`P.fuselage.CD0`|`0.08`|1|fuselage aerodynamics|physical|FU|ASSUMED_CONCEPT|none|Code: `params_nominal.m:129`|Drag intercept|HIGH|MEDIUM|yes||
|FUS-006|`P.fuselage.CDalpha2`|`0.50`|1/rad^2|fuselage aerodynamics|physical|FU|ASSUMED_CONCEPT|none|Code: `params_nominal.m:130`|Quadratic alpha drag|HIGH|MEDIUM|yes||
|FUS-007|`P.fuselage.CDbeta2`|`0.40`|1/rad^2|fuselage aerodynamics|physical|FU|ASSUMED_CONCEPT|none|Code: `params_nominal.m:131`|Quadratic beta drag|HIGH|MEDIUM|yes||
|FUS-008|`P.fuselage.CL0`|`0.00`|1|fuselage aerodynamics|physical|FU|ASSUMED_CONCEPT|none|Code: `params_nominal.m:132`|Lift intercept|HIGH|LOW|yes||
|FUS-009|`P.fuselage.CLalpha`|`0.35`|1/rad|fuselage aerodynamics|physical|FU|ASSUMED_CONCEPT|none|Code: `params_nominal.m:133`|Lift slope|HIGH|MEDIUM|yes||
|FUS-010|`P.fuselage.CYbeta`|`-0.55`|1/rad|fuselage aerodynamics|physical|FU|ASSUMED_CONCEPT|none|Code: `params_nominal.m:134`|Side-force derivative|HIGH|HIGH|yes||
|FUS-011|`P.fuselage.Clbeta`|`-0.08`|1/rad|fuselage moment derivative|physical|FU|ASSUMED_CONCEPT|none|Code: `params_nominal.m:136`|Roll due sideslip|HIGH|MEDIUM|yes||
|FUS-012|`P.fuselage.Clp`|`-0.30`|1|fuselage damping|physical|FU|ASSUMED_CONCEPT|none|Code: `params_nominal.m:137`|Roll damping using `p*b/(2V)`|HIGH|HIGH|yes||
|FUS-013|`P.fuselage.Clr`|`0.08`|1|fuselage damping|physical|FU|ASSUMED_CONCEPT|none|Code: `params_nominal.m:138`|Roll due yaw rate|HIGH|MEDIUM|yes||
|FUS-014|`P.fuselage.Cm0`|`0.00`|1|fuselage moment|physical|FU|ASSUMED_CONCEPT|none|Code: `params_nominal.m:139`|Pitch intercept|HIGH|LOW|yes||
|FUS-015|`P.fuselage.Cmalpha`|`-0.20`|1/rad|fuselage moment|physical|FU|ASSUMED_CONCEPT|none|Code: `params_nominal.m:140`|Pitch due alpha|HIGH|HIGH|yes||
|FUS-016|`P.fuselage.Cmq`|`-4.0`|1|fuselage damping|physical|FU|ASSUMED_CONCEPT|none|Code: `params_nominal.m:141`|Pitch damping using `q*c/(2V)`|HIGH|HIGH|yes||
|FUS-017|`P.fuselage.Cnbeta`|`0.12`|1/rad|fuselage moment|physical|FU|ASSUMED_CONCEPT|none|Code: `params_nominal.m:142`|Yaw due sideslip|HIGH|HIGH|yes||
|FUS-018|`P.fuselage.Cnp`|`-0.04`|1|fuselage damping|physical|FU|ASSUMED_CONCEPT|none|Code: `params_nominal.m:143`|Yaw due roll rate|HIGH|MEDIUM|yes||
|FUS-019|`P.fuselage.Cnr`|`-0.30`|1|fuselage damping|physical|FU|ASSUMED_CONCEPT|none|Code: `params_nominal.m:144`|Yaw damping|HIGH|HIGH|yes||
|HT-001|`P.htail.S`|`4.5`|m^2|horizontal-tail geometry|physical|HT|ASSUMED_CONCEPT|none|Code: `params_nominal.m:147`|Reference area|HIGH|MEDIUM|yes||
|HT-002|`P.htail.c`|`1.0`|m|horizontal-tail geometry|physical|HT moment|ASSUMED_CONCEPT|none|Code: `params_nominal.m:148`|Reference chord|HIGH|MEDIUM|yes||
|HT-003|`P.htail.rAC`|`[-5;0;0.15]`|m|horizontal-tail station|physical|HT|ASSUMED_CONCEPT|none|Code: `params_nominal.m:149`|AC relative to nominal CG|HIGH|HIGH|yes||
|HT-004|`P.htail.incidence`|`0*pi/180`|rad|horizontal-tail geometry|physical|HT|ASSUMED_CONCEPT|NASA_TM_X_62407.pdf (candidate)|Code: `params_nominal.m:150`; source PDF 15, printed 12 lists horizontal-tail incidence 0 to +6 deg|Code fixed zero is not mapped to a test configuration|HIGH|MEDIUM|yes||
|HT-005|`P.htail.downwashAlpha`|`0.25`|1|tail interference|physical|HT|ASSUMED_CONCEPT|none|Code: `params_nominal.m:151`|Linear subtraction from CG alpha|HIGH|HIGH|yes||
|HT-006|`P.htail.CL0`|`0`|1|tail aerodynamics|physical|HT|ASSUMED_CONCEPT|none|Code: `params_nominal.m:153`|Lift intercept|HIGH|LOW|yes||
|HT-007|`P.htail.CLalpha`|`4.5`|1/rad|tail aerodynamics|physical|HT|ASSUMED_CONCEPT|none|Code: `params_nominal.m:154`|Lift slope|HIGH|HIGH|yes||
|HT-008|`P.htail.CLmax`|`1.25`|1|tail saturation|physical|HT|ASSUMED_CONCEPT|none|Code: `params_nominal.m:155`|Tanh lift cap|HIGH|HIGH|yes||
|HT-009|`P.htail.CLelevator`|`1.60`|1/rad|tail control derivative|physical|HT|ASSUMED_CONCEPT|none|Code: `params_nominal.m:156`|Elevator lift derivative|HIGH|HIGH|yes||
|HT-010|`P.htail.CD0`|`0.018`|1|tail aerodynamics|physical|HT|ASSUMED_CONCEPT|none|Code: `params_nominal.m:157`|Drag intercept|HIGH|MEDIUM|yes||
|HT-011|`P.htail.kInduced`|`0.060`|1|tail aerodynamics|physical|HT|ASSUMED_CONCEPT|none|Code: `params_nominal.m:158`|Quadratic drag coefficient|HIGH|MEDIUM|yes||
|HT-012|`P.htail.Cm0`|`0`|1|tail moment|physical|HT|ASSUMED_CONCEPT|none|Code: `params_nominal.m:159`|Pitch-moment intercept|HIGH|LOW|yes||
|HT-013|`P.htail.Cmelevator`|`-0.08`|1/rad|tail control derivative|physical|HT|ASSUMED_CONCEPT|none|Code: `params_nominal.m:160`|Direct elevator pitch-moment derivative|HIGH|HIGH|yes||
|VT-001|`P.vtail.SEach`|`1.6`|m^2/fin|vertical-tail geometry|physical|VT|ASSUMED_CONCEPT|none|Code: `params_nominal.m:163`|Area of each of two fins|HIGH|MEDIUM|yes||
|VT-002|`P.vtail.c`|`0.8`|m|vertical-tail geometry|physical|no production read|ASSUMED_CONCEPT|none|Code: `params_nominal.m:164`; no `model/` read|Reference chord retained but unused|HIGH|LOW|yes|Not `DEPRECATED_UNUSED` because no compatibility declaration exists|
|VT-003|`P.vtail.xAC`|`-4.20`|m|vertical-tail station|physical|VT|ASSUMED_CONCEPT|none|Code: `params_nominal.m:165`|Fin AC x|HIGH|HIGH|yes||
|VT-004|`P.vtail.yAC`|`1.10`|m|vertical-tail station|physical|VT|ASSUMED_CONCEPT|none|Code: `params_nominal.m:166`|Absolute fin AC y, side signed in code|HIGH|HIGH|yes||
|VT-005|`P.vtail.zAC`|`-0.20`|m|vertical-tail station|physical|VT|ASSUMED_CONCEPT|none|Code: `params_nominal.m:167`|Fin AC z|HIGH|HIGH|yes||
|VT-006|`P.vtail.CD0`|`0.020`|1|vertical-tail aerodynamics|physical|VT|ASSUMED_CONCEPT|none|Code: `params_nominal.m:169`|Drag intercept per fin|HIGH|MEDIUM|yes||
|VT-007|`P.vtail.CYbeta`|`-2.20`|1/rad|vertical-tail aerodynamics|physical|VT|ASSUMED_CONCEPT|none|Code: `params_nominal.m:170`|Side-force derivative per fin|HIGH|HIGH|yes||
|VT-008|`P.vtail.CYrudder`|`0.70`|1/rad|vertical-tail control derivative|physical|VT|ASSUMED_CONCEPT|none|Code: `params_nominal.m:171`|Rudder side-force derivative per fin|HIGH|HIGH|yes||
|CTL-001|`P.control.collectiveLim`|`[0,70]*pi/180`|rad|control limit|physical|TFM clamp; TR bounds|ASSUMED_CONCEPT|none|Code: `params_nominal.m:174`; `TFM:23-24`|Applied per-side after common/differential allocation|HIGH|HIGH|yes|Not documented mechanical/flight-envelope limit|
|CTL-002|`P.control.cyclicLim`|`[-35,35]*pi/180`|rad|control limit|physical|TFM clamp; TR bound|ASSUMED_CONCEPT|none|Code: `params_nominal.m:175`; `TFM:25-26`|Applied to side longitudinal cyclic|HIGH|HIGH|yes|No sourced nacelle-angle phasing/mixing gain|
|CTL-003|`P.control.aileronLim`|`[-30,30]*pi/180`|rad|control limit|physical|TFM clamp|ASSUMED_CONCEPT|none|Code: `params_nominal.m:176`; `TFM:34`|Conventional surface command envelope|HIGH|MEDIUM|yes||
|CTL-004|`P.control.elevatorLim`|`[-40,40]*pi/180`|rad|control limit|physical|TFM clamp|ASSUMED_CONCEPT|none|Code: `params_nominal.m:177`; `TFM:35`|Conventional surface command envelope|HIGH|MEDIUM|yes||
|CTL-005|`P.control.rudderLim`|`[-30,30]*pi/180`|rad|control limit|physical|TFM clamp|ASSUMED_CONCEPT|none|Code: `params_nominal.m:178`; `TFM:36`|Conventional surface command envelope|HIGH|MEDIUM|yes||
|TRM-001|`P.trim.residualTolerance`|`5e-3`|mixed residual norm|trim solver|numerical|TR and diagnostics/tests|NUMERICAL|none|Code: `params_nominal.m:181`; `TR:129`|Unweighted norm of `[udot,wdot,qdot]` for acceptance|HIGH|MEDIUM|yes|Mixed units make scalar norm interpretation model-specific|
|TRM-002|`P.trim.maxIterations`|`600`|iteration|trim solver|numerical|TR|NUMERICAL|none|Code: `params_nominal.m:182`; `TR:89-90`|`MaxIter`; `MaxFunEvals=10*value`|HIGH|LOW|no||
|TRM-003|`P.trim.display`|`off`|text|trim solver|numerical|TR|NUMERICAL|none|Code: `params_nominal.m:183`; `TR:88`|Optimizer display setting|HIGH|NONE|no||
|TRM-004|`P.trim.variableScale`|`[2;18;2]*pi/180`|rad|trim solver|numerical|TR and Jacobian diagnostics|NUMERICAL|none|Code: `params_nominal.m:184-188`; `TR:81`|Search scales for theta, collective, cyclicLong|HIGH|MEDIUM|yes|Interacts with fminsearch 5% simplex rule|
|LIN-001|`P.linear.dx`|`[.05 .05 .05 1e-3 1e-3 1e-3 1e-4 1e-4 1e-4]'`|state-dependent|linearization|numerical|LIN|NUMERICAL|none|Code: `params_nominal.m:191-193`; `LIN:24`|Central-difference state steps: m/s, rad/s, rad|HIGH|HIGH|yes|Must be sensitivity-tested at each retained trim family|
|LIN-002|`P.linear.du`|`1e-4*ones(7,1)`|rad|linearization|numerical|LIN|NUMERICAL|none|Code: `params_nominal.m:195`; `LIN:25`|Central-difference control steps|HIGH|HIGH|yes|Can cross clamps or branch/applicability regions|
|LIN-003|`P.linear.stabilityTolerance`|`1e-7`|1/s|stability classification|numerical|`run_demo.m:61` -> `stability_report`|NUMERICAL|none|Code: `params_nominal.m:196`|Eigenvalue real-part threshold|HIGH|MEDIUM|yes|Duplicated by callable default `1e-7`|
|EMB-001|degree-to-radian conversion|`d2r=pi/180`|rad/deg|unit conversion|numerical|params, TR, demos/tests|DERIVED|mathematical identity|Multiple code locations|Exact unit conversion|HIGH|NONE|no||
|EMB-002|wing advance-ratio area heuristic|`1-0.25*min(muMean/muMax,1)`|1|wing interaction|physical|WG:15|ASSUMED_CONCEPT|none|Code: `WG:15`|Reduces modeled slip area by at most 25%|HIGH|HIGH|yes|Embedded empirical coefficient|
|EMB-003|wing nacelle-orientation area heuristic|`0.60+0.40*abs(cos(2*betaM))`|1|wing interaction|physical|WG:16|ASSUMED_CONCEPT|none|Code: `WG:16`|Ranges 0.6 to 1; symmetric in endpoint modes|HIGH|HIGH|yes|Embedded empirical coefficients and harmonic|
|EMB-004|vertical-tail quadratic drag increment|`0.02*CY^2`|1|tail aerodynamics|physical|VT:37|ASSUMED_CONCEPT|none|Code: `VT:37`|Additional per-fin drag|HIGH|MEDIUM|yes|No parameter field or source|
|EMB-005|zero/local-speed guard|`V<1e-8`|m/s|numerical guard|numerical|WG:82; FU:12; HT:12; VT:25|NUMERICAL|none|Listed code lines|Returns zero load below threshold|HIGH|LOW|no|Repeated literal, same semantics|
|EMB-006|wing direction/ratio denominator floor|`velocityFloor=1e-8`|m/s|regularization|numerical|WG:91,107,117|NUMERICAL|none|Code: `WG:91`|Regularizes `V` divisions|HIGH|LOW|no||
|EMB-007|quintic smootherstep coefficients|`6t^5-15t^4+10t^3`|1|blend|numerical|WG:182-183|NUMERICAL|none|Code: `WG:183`|C2 endpoint interpolation polynomial|HIGH|NONE|no|Mathematical construction, not aerodynamic evidence|
|EMB-008|rotor initial induced-velocity thrust floor|`max(m*g/2,1)`|N|regularization|numerical|RB:50|NUMERICAL|none|Code: `RB:50`|Prevents zero initial momentum estimate|HIGH|LOW|no||
|EMB-009|rotor momentum denominator floor|`max(denom,1e-8)`|mixed denominator unit|regularization|numerical|RB:72|NUMERICAL|none|Code: `RB:71-72`|Prevents division by zero|MEDIUM|MEDIUM|yes|Absolute floor has implicit units and scale|
|EMB-010|relative induced-error scale floor|`max(1,abs(vi))`|m/s|regularization|numerical|RB:76|NUMERICAL|none|Code: `RB:76`|Absolute below 1 m/s, relative above|HIGH|LOW|no||
|EMB-011|flap Jacobian singularity threshold|`rcond(J'*J)<1e-14`|1|solver guard|numerical|RB:182|NUMERICAL|none|Code: `RB:182`|Rejects ill-conditioned normal equations|HIGH|MEDIUM|yes||
|EMB-012|flap residual scale anchors|`Ib*Omega^2*0.05`, `1`|N m|solver scaling|numerical|RB:269-271|NUMERICAL|none|Code: `RB:269-271`|5% rad-like inertial reference and 1 N m floor|MEDIUM|MEDIUM|yes|`0.05` physical-angle interpretation is undocumented|
|EMB-013|degenerate-flap diagnostic threshold|`all(abs(zFlap)<1e-14)`|rad|diagnostic guard|numerical|RB:313|NUMERICAL|none|Code: `RB:313`|Controls diagnostic only|HIGH|INFO|no||
|EMB-014|inflow-angle tangential floor|`max(abs(UT),1e-8)`|m/s|regularization|numerical|RB:320|NUMERICAL|none|Code: `RB:320`|Removes reverse-flow sign in denominator|HIGH|HIGH|yes|Major reverse-flow/windmill applicability limitation|
|EMB-015|Euler singularity floor|`abs(cos(theta))<1e-6` then signed `1e-6`|1|kinematic guard|numerical|EOM:37-39|NUMERICAL|none|Code: `EOM:37-39`|Regularizes 3-2-1 singularity|HIGH|MEDIUM|yes|Not a physical attitude limit|
|EMB-016|nacelle-angle validation slack|`[-1e-9,pi/2+1e-9]`|rad|input tolerance|numerical|`model/validate_inputs.m:11`|NUMERICAL|none|Code line listed|Allows floating-point endpoint slack|HIGH|LOW|no||
|EMB-017|minimal BEMT grids|`nRadial>=3`, `nAzimuth>=4`|1|applicability guard|numerical|`model/validate_inputs.m:17`|NUMERICAL|none|Code line listed|Parsing/runtime minimum, not accuracy criterion|HIGH|LOW|no||
|EMB-018|control allocation/reconstruction|right=`common+diff`; left=`common-diff`; common=`0.5(R+L)`; diff=`0.5(R-L)`|1|control mapping|physical|TFM:16-20,30-33|DERIVED|none|Code lines listed|Exact algebraic common/differential transform|HIGH|NONE|no|Clamping occurs in side space before reconstruction|
|EMB-019|rotor rotation and cyclic phase mapping|`rotDir=side`; `theta1s=-rotDir*cyclicSide`|1|control/sign mapping|physical|RB:26,126,301|DERIVED|NASA_TM_X_62407.pdf (qualitative support)|PDF 56, printed 53, section 8.1.2 describes differential longitudinal cyclic yaw|Current code convention; source does not establish every sign/axis detail|HIGH|MEDIUM|yes||
|ANA-001|`stability_report` fallback tolerance|`1e-7`|1/s|stability|numerical|`analysis/stability_report.m:4-5`|NUMERICAL|none|Code lines listed|Duplicates LIN-003 when caller omits argument|HIGH|LOW|no||
|ANA-002|trim default seed regimes|`V<1:[0,18,0]`; `betaM<pi/4:[4,16,2]`; else `[4,8,-4]`|m/s, rad, deg input|trim seed|numerical|TR:41-48|NUMERICAL|none|Code lines listed|Speed/nacelle-conditioned seeds, converted deg to rad|HIGH|MEDIUM|yes||
|ANA-003|trim pitch-attitude limit|`thetaLimitDeg=35`|deg -> rad|trim bound|numerical|TR:51-52,85|NUMERICAL|none|Code lines listed|Solver/reporting bound, not aircraft limit|HIGH|MEDIUM|yes||
|ANA-004|trim hover thresholds|`V<1e-9` search mode; `V<1e-10` state mapping|m/s|trim branch|numerical|TR:83,200|NUMERICAL|none|Code lines listed|Two distinct exact-hover thresholds|HIGH|LOW|no||
|ANA-005|trim optimizer limits/tolerances|`MaxFunEvals=10*maxIterations`; `TolX=1e-8`; `TolFun=1e-10`|mixed|solver|numerical|TR:87-92|NUMERICAL|none|Code lines listed|fminsearch/fminbnd settings|HIGH|MEDIUM|yes||
|ANA-006|trim invalid-evaluation cost|`1e30`|objective|solver|numerical|TR:176,184|NUMERICAL|none|Code lines listed|Explicit failed-domain penalty, not exception suppression|HIGH|LOW|no||
|ANA-007|trim residual scaling|`[g;g;1]`|mixed|solver scaling|numerical|TR:101,187|NUMERICAL|none|Code lines listed|Translational residuals divided by g; qdot unscaled|HIGH|MEDIUM|yes||
|ANA-008|trim bound penalties|theta multiplier `10`; bound coefficient `100`|objective|solver|numerical|TR:219,227|NUMERICAL|none|Code lines listed|Soft penalty outside theta/control bounds|HIGH|HIGH|yes|Can affect selected root before hard acceptance reporting|
|ANA-009|trim candidate tie threshold|`abs(cost-bestCost)<1e-14`|objective|solver|numerical|TR:280-281|NUMERICAL|none|Code line listed|Residual norm breaks near-exact cost ties|HIGH|LOW|no||
|ANA-010|trim multistart offsets and fixed seeds|`[+4,+2]`, `[-4,-2]`, `[4,16,2]`, `[6,16,3]`; round 10 digits|deg|trim seed|numerical|TR:312-318|NUMERICAL|none|Code lines listed|Search-only seed construction|HIGH|MEDIUM|yes||
|ANA-011|trim at-limit reporting tolerance|`1e-8`|rad|reporting|numerical|TR:322,339-343|NUMERICAL|none|Code lines listed|At-limit and violation slack|HIGH|LOW|no|Different from sweep `1e-10`|
|ANA-012|trim residual Jacobian default step|`1e-4`|rad|Jacobian|numerical|`analysis/trim_residual_jacobian.m:16-20`|NUMERICAL|none|Code lines listed|Central difference for three trim variables|HIGH|MEDIUM|yes||
|ANA-013|rank/condition threshold|`max(size(J))*eps(smax)`|matrix-dependent|Jacobian reporting|numerical|`analysis/trim_residual_jacobian.m:91-99`|NUMERICAL|none|Code lines listed|SVD rank tolerance|HIGH|LOW|no||
|ANA-014|helicopter sweep defaults bundle|speeds `[0,5,10,15,20]`; seed `[0,18,0]`; rescue matrix; residual floor `1e-6`; Jacobian `1e-4`; jumps `10 deg`; sign flip `0.25 deg`; penalties `1e3/1e6`; limit tol `1e-10`|mixed|diagnostic sweep|numerical|`analysis/trim_sweep_helicopter.m`|NUMERICAL|none|Lines 14-83, 353, 541|Diagnostic defaults; caller-overridable|HIGH|MEDIUM|yes||
|ANA-015|branch diagnostics bundle|seed/sweep/continuity settings in `trim_branch_diagnostics.m`|mixed|diagnostic|numerical|diagnostic only|NUMERICAL|none|Lines 18-35 and downstream defaults|Includes `2.5/1.25/0.25 deg`, `1e-4 rad`, rescue seeds|HIGH|INFO|no||
|ANA-016|local branch diagnostics bundle|`2.5/1.25 deg`; Jacobian steps `[1e-3,3e-4,1e-4,3e-5,1e-5]`; root tolerances `[.02,.02,.02] deg`; branch thresholds `1/2 deg`; fold `1e-3`; speeds `9.05:.01:9.30`|mixed|diagnostic|numerical|diagnostic only|NUMERICAL|none|`analysis/trim_branch_local_diagnostics.m:87-108`|Historical local diagnostic configuration|HIGH|INFO|no||
|ANA-017|focused branch diagnostics bundle|solution tolerance `.02 deg`; same five Jacobian steps; stored low/high seeds|mixed|diagnostic|numerical|diagnostic only|NUMERICAL|none|`analysis/trim_branch_focused_diagnostics.m:16-23`|Historical focused diagnostic configuration|HIGH|INFO|no||
|ANA-018|near-normal diagnostics bundle|speeds `9.04:.01:9.31`; high precision `1e-6`; perturbations `[1e-3,3e-4,1e-4,3e-5,1e-5]`; stored seeds|mixed|diagnostic|numerical|diagnostic only|NUMERICAL|none|`analysis/near_normal_branch_diagnostics.m:80-94`|Historical branch diagnostic configuration|HIGH|INFO|no||
|ANA-019|pseudo-arclength diagnostic bundle|`maxSteps=50`; `V=[8.8,9.7]`; `ds=.025`; optimizer `500/4000/1e-9/1e-12`; local-distance `5ds`; branch `1/2 deg`; connection `.1`|mixed|diagnostic|numerical|diagnostic only|NUMERICAL|none|`analysis/trim_branch_pseudo_arclength_local.m:14-23,88,172-200`|Not production continuation|HIGH|INFO|no||
|ANA-020|wing-blend repair diagnostics bundle|sweeps `0:1:20`, `7:.05:12`, reverse; jumps `2.5/1.25/.25 deg`; Jacobian `1e-4`; stored rescue/multistart seeds; linearization scales `[.5,1,2]`|mixed|diagnostic|numerical|diagnostic only|NUMERICAL|none|`analysis/wing_blend_repair_diagnostics.m:21-74,154-236,333`|Historical repair diagnostic configuration|HIGH|INFO|no||
|TST-001|`check_control_architecture` bundle|`h=1e-4`; stability steps `[1e-3,1e-4,1e-5]`; load sign floors `1e4/1e5`; relative threshold `1e-3`; near-zero `1e-9*scale+1e-6`|mixed|test|numerical|test only|NUMERICAL|none|File lines 24,76-100,122-146,188|Regression thresholds, not aircraft parameters|HIGH|INFO|no||
|TST-002|`check_control_limits` bundle|base `40 m/s`, `betaM=pi/2`, `8 deg` collective; excursions `5 deg`; tolerance `1e-14`|mixed|test|numerical|test only|NUMERICAL|none|File lines 9-41|Limit regression scenario|HIGH|INFO|no||
|TST-003|`check_article_trends` bundle|comparison `1e-4`; steps `[1e-3,1e-4,1e-5]`; limit/zero tolerances `1e-10`; stored Table 2 comparison values|mixed|test/diagnostic|numerical|test only|NUMERICAL|NUAA_main_paper.pdf|File lines 17-21, 191 onward; NUAA PDF 13, printed 13, Tables 1-2|Trend-only comparison; not parameter provenance|HIGH|INFO|no||
|TST-004|`check_aerodynamic_components` bundle|tolerance `2e-9`; synthetic flows/angles; decomposition `1e-10`; blend step `1e-3`; `V=24`; near-zero formula|mixed|test|numerical|test only|NUMERICAL|none|File lines 11-29,112-123,234-327,407|Synthetic regression cases|HIGH|INFO|no||
|TST-005|`check_trim_equations` bundle|three Jacobian steps; search thresholds `1e-9/1e-10`; stored maps/seeds and solve budgets|mixed|test|numerical|test only|NUMERICAL|none|File lines 84-104,178-250|Regression configuration|HIGH|INFO|no||
|TST-006|`check_representative_trim_continuation` bundle|speeds `[0,5,10,15,20]`; seed `[0,18,0]`; sign flip `.25 deg`|mixed|test|numerical|test only|NUMERICAL|none|File lines 13-16,74|Representative diagnostic contract|HIGH|INFO|no||
|TST-007|`check_trim_continuity` bundle|speeds `0:1:20`; jumps `2.5/1.25 deg`; sign flip `.25 deg`; Jacobian `1e-4`|mixed|test|numerical|test only|NUMERICAL|none|File lines 13-24|Continuity regression configuration|HIGH|INFO|no||
|TST-008|`check_rotor_force_moment_chain` bundle|representative modes/loads; synthetic `Jpolar=25`; reverse-flow screen `minUT<0.10*Omega*R`|mixed|test|numerical|test only|NUMERICAL|none|File lines 59-60,134-181,230-267|Synthetic identities and applicability screen|HIGH|INFO|no||
|TST-009|`check_wing_normal_flow_blend` bundle|widths `[.03,.05,.08,current]`; scan expansion `.05`; ratio clamps `.01/.25/.45/.95`; weight tol `1e-12`; derivative step `1e-4`; `V=24`|mixed|test|numerical|test only|NUMERICAL|none|File lines 9,48-49,82-87,156|Blend smoothness regression|HIGH|INFO|no||
|TST-010|`check_mass_inertia_geometry` bundle|angles `[0,pi/4,pi/2]`; derivative `h=1e-5`; tolerances `1e-12/1e-10`; representative state/control|mixed|test|numerical|test only|NUMERICAL|none|File lines 17,60,85-90,143,230-231|Geometry identity regression|HIGH|INFO|no||
|TST-011|`check_flapping_model` bundle|synthetic velocities; tolerances `1e-10,2e-2,2e-3`; grid comparison `20x36` and `8/15%`; speed `0:5:30`; continuity `.5 rad`|mixed|test|numerical|test only|NUMERICAL|none|File lines 61-67,88,144,198-224|Flap/BEMT regression configuration|HIGH|INFO|no||
|TST-012|`check_physical_sanity` bundle|dimensionless plausibility bounds and `0.25R` CG-shift screen|mixed|test|numerical|test only|NUMERICAL|none|`tests/check_physical_sanity.m`|Order-of-magnitude screens, not sources|HIGH|INFO|no||
|TST-013|midpoint diagnostics bundle|`V=7.5/17.5`; root tolerance `1e-4 deg`; near-blend fraction `.10`; stored branch seeds|mixed|test/diagnostic|numerical|diagnostic only|NUMERICAL|none|`tests/diagnose_trim_midpoint_7p5.m:12-27`; `17p5.m:9-18`|Historical diagnosis settings|HIGH|INFO|no||
|TST-014|`run_all_checks` bundle|representative controls/speeds; grid comparison `12x16` versus `20x36`; force scaling scenarios|mixed|test|numerical|test only|NUMERICAL|none|`tests/run_all_checks.m:12,77-191`|Top-level smoke/regression cases|HIGH|INFO|no||
|TST-015|remaining test assertion tolerances|file-local `1e-6` to `1e-14` finite/symmetry/decomposition thresholds|mixed|test|numerical|test only|NUMERICAL|none|All files under `tests/`, as listed above|Non-production assertion settings not otherwise itemized|MEDIUM|INFO|no|No test threshold is treated as physical evidence|

## Source evidence and conflicts

1. `NASA_TM_X_62407.pdf`, PDF 14 (printed page 11) separates basic empty weight `9,076 lb`, research mission empty weight `10,073 lb`, and design gross weight `13,000 lb`. None is silently equated to `P.mass.m=6000 kg`.
2. The same document, PDF 15 (printed page 12), gives airplane/helicopter inertias at `13,000 lb` gross weight in `slug-ft^2`. Text extraction loses part of the table labels and no cross inertia is visible; the table therefore remains a candidate requiring visual/manual review and unit/axis mapping.
3. `NASA_TM_X_62407.pdf`, PDF 20-22 (printed 17-19), documents the steel-blade-era 25 ft, three-bladed, 14 in chord rotor and distinct nominal design speeds: hover/helicopter `740 ft/s, 565 rpm`, cruise/airplane `600 ft/s, 458 rpm`.
4. `NASA_TM_81244.pdf`, PDF 4 describes a three-blade, 25 ft prop-rotor and `45 deg` root-to-tip blade twist. PDF 8 records a flight-stage schedule of `98%/589 rpm`, `86%/517 rpm`, and `76%/458 rpm`, with 517 rpm then used to reduce vibratory loads. These are different operating/configuration statements, not interchangeable values.
5. `NUAA_main_paper.pdf` supports modeling relations and component decomposition, not the current numeric database: PDF 3 equations (1)-(3), PDF 4 equations (4)-(11), PDF 5 equations (13)-(15), PDF 6 equations (17)-(22), PDF 7-8 equations (23)-(36), and PDF 12 equations (37)-(42). Its own conclusion notes incomplete XV-15 data; numeric similarity is not proof.
6. Repository documentation is internally stale for the wing blend width: `AGENTS.md` section 25.2 states `normalFlowBlendHalfWidth=0.20`, while the checked-out branch defines and consumes `0.15` in `params_nominal.m:121`; `docs/PAPER_CODE_MAPPING.md:736` records the later `0.15` value. The inventory follows executable code and flags the documentation mismatch; it does not change either value.

## Summary counts

Counts below are generated from the rows in this document and should be updated together with the table.

|measure|count|
|-|-:|
|inventory rows|174|
|`P.` leaf fields|120|
|active physical/empirical parameter rows|96|
|numerical-setting rows|68|
|deprecated compatibility fields|7|
|other inactive metadata/reference fields|2 (`bladeMassDistribution`, unused `vtail.c`)|

|source-status label|count|
|-|-:|
|DOCUMENTED_PRIMARY|1|
|DOCUMENTED_SECONDARY|0|
|DERIVED|5|
|ASSUMED_CONCEPT|92|
|NUMERICAL|68|
|REFERENCE_PENDING|0|
|AMBIGUOUS_COUPLED|1|
|DEPRECATED_UNUSED|7|
|UNRESOLVED|0|

|issue severity|count|
|-|-:|
|CRITICAL|0|
|HIGH|53|
|MEDIUM|57|
|LOW|30|
|INFO|29|
|NONE|5|

These severity counts were machine-checked from the table. Missing a source alone is not sufficient for `HIGH`; severity reflects model consequence and downstream claims.

## Applicability boundary

The current model has uniform quasi-steady induced flow, no dynamic inflow, no nonuniform inflow harmonic, no inter-rotor interference, a one-way scalar rotor-to-wing wake multiplier, simple static tanh stall caps, no airfoil Reynolds/Mach tables, no explicit windmill/autorotation momentum branch, no blade hinge offset/stiffness/damping, and no rotor-speed or control-phasing schedule. `trim_symmetric` closes only `[udot,ẇ,q̇]=0` with theta, common collective and common longitudinal cyclic while conventional surfaces remain zero. Consequently, transition/airplane trim, dense envelopes, and XV-15 fidelity comparisons are blocked even if the current numerical routines return finite values.
