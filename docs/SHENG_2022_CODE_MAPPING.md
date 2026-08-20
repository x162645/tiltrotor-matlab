# Sheng et al. (2022) -> current code mapping

Status: first-pass equation/assumption audit for paper-oriented model development.

Primary reference: Sheng, H.; Zhang, C.; Xiang, Y. (2022), *Mathematical Modeling and Stability Analysis of Tiltrotor Aircraft*, Drones 6(4):92.

## Scope and evidence rule

This document maps the paper's stated equations/assumptions to the current repository implementation. It does not assume that the paper contains a complete XV-15 database. A match means structural/mathematical correspondence, not aircraft-level validation.

## Nacelle-angle convention warning

The paper is internally inconsistent in presentation: Figure 1 labels helicopter mode as 90 deg and flight mode as 0 deg, while the equations/trim discussion use low nacelle angle as helicopter-like and high nacelle angle as airplane-like. The current code explicitly uses `betaM=0` for helicopter mode and `betaM=pi/2` for airplane mode. All equation-level comparisons below follow the paper's equation/trim convention rather than the Figure-1 label convention.

## Equation mapping

|Paper|Paper model|Current implementation|Status|Research implication|
|---|---|---|---|---|
|Eq. (1)-(2)|CG shift from tilting nacelle mass: `dx ~ sin(betaM)`, `dz ~ 1-cos(betaM)`|`model/mass_properties.m` uses the same functional form with `mNac`, `RH_mass`, total mass|DIRECT STRUCTURAL MATCH|Keep; parameter provenance remains conceptual|
|Eq. (3)|Linear inertia change with nacelle angle|`I = I0 - betaM*KI`, symmetrized and checked positive definite|MATCH + NUMERICAL SAFETY|Keep as low-order law; do not claim real XV-15 inertia without sourced tensors|
|Eq. (4)|Blade flapping differential equation with aerodynamic and gravity moments|`rotor_model_bemt.m` solves steady first-harmonic balance for `beta0,beta1c,beta1s` using inertial restoring, aerodynamic moment and gravity moment|SAME PHYSICS CLASS, DIFFERENT SOLUTION FORM|Current code gives a steady periodic harmonic solution suitable for trim; it is not transient flapping dynamics|
|Eq. (5)|Transform hub flow between body/nacelle/hub/wind axes|Current code constructs `eT,eD,eY`, computes hub local velocity `Vbody+omega x rHub`, and projects onto rotor axes|FUNCTIONAL ANALOGUE|Current vector form is easier to audit; sign/convention equivalence still needs canonical-case proof|
|Eq. (6)|Tangential blade velocity `Omega r + forward-flight harmonic`|`UT = Omega*rMid + VtanTrans`, including longitudinal/lateral advance and rotation direction|GENERALIZED MATCH|Keep; verify sign with canonical forward-flight cases|
|Eq. (7)|Perpendicular blade flow includes axial flow, induced velocity, flapping and forward-flight/flap coupling|`UP = Vaxial + vi - beta*Vrad - betaDot*r`|STRUCTURAL MATCH, SIGN/NORMALIZATION AUDIT PENDING|One of the highest-priority rotor equation checks|
|Eq. (8)-(9)|Blade-element lift/drag from local speed and airfoil coefficients|Current code uses explicit conceptual polar: tanh-limited `CL`, quadratic `CD`|MODEL DEPARTURE|Useful robust closure but not sourced airfoil physics; external rotor validation required|
|Eq. (10)-(11)|Resolve blade-element lift/drag into rotor-normal/in-plane components|Current code computes `dT`, `dH`, and torque `dQ=dH*r`|STRUCTURAL MATCH|Check naming/sign conventions rather than rewrite|
|Eq. (12)-(13)|Quasi-steady induced-velocity iteration with a stated radial/azimuth nonuniform expression|Current model iterates a uniform mean induced velocity from momentum balance; `viField=viMean`|MAJOR INTENTIONAL DEPARTURE|Do not copy paper Eq. (12) blindly; its printed form does not obviously recover axisymmetric hover. Compare both only after physical-limit audit|
|Eq. (14)|Transform rotor force to aircraft body axes|Current uses flapped disk normal plus in-plane H components in body basis|FUNCTIONAL MATCH|Current implementation is explicit and testable|
|Eq. (15)|Rotor torque plus hub-arm moment|Current includes reaction torque + arm moment + optional gyro term|MATCH + EXTENSION|Gyro path exists but `Jpolar=0`, so it is inactive numerically|
|Eq. (16)|Empirical slipstream-area law versus nacelle angle and advance ratio|Current uses heuristic `muFactor * orientationFactor` with `SslipMaxHalf`|MAJOR MODEL DEPARTURE|High-priority baseline reconstruction/validation target|
|Eq. (17)|Slipstream-region local wing velocity = freestream + body-rate local velocity + rotor induced velocity vector|Current uses the same structure but multiplies induced velocity by `wakeFactor=1.60`|STRUCTURAL MATCH + UNSOURCED GAIN|`wakeFactor` cannot remain a hidden tuning parameter in a paper claim|
|Eq. (18)|Wing aerodynamic-center shift relative to moving CG|Current subtracts `cgShift` from free/slip region AC locations|MATCH|Keep|
|Eq. (19)-(20)|Slipstream-region wing force/moment|Current uses common `aero_force_body`, arm moment, aerodynamic pitch moment, and full-angle branch blending|EXTENDED|Candidate contribution, but parameters and normal-flow closure need validation|
|Eq. (21)-(22)|Free-flow wing force/moment; paper describes two free-flow subregions with separate local conditions/AC treatment|Current uses one free-flow region per half-wing|CURRENT CODE IS SIMPLER THAN PAPER|Potential moment/control-distribution error; assess before publication, especially if control surfaces are active|
|Eq. (23)-(24)|Simplified fuselage aerodynamic force/moment, no rotor/wing disturbance|`fuselage_model.m` uses conceptual coefficient model and arm+intrinsic aero moments; no rotor wake|SAME MODEL CLASS|Current rate derivatives are additional conceptual parameters; source or sensitivity analysis required|
|Eq. (25)-(26)|Horizontal-tail fixed-wing-like model; rotor wake neglected|Current follows same class but adds `downwashAlpha*alphaCG` and nonlinear lift saturation|MODEL EXTENSION|`downwashAlpha` is unsourced and should be isolated in sensitivity/validation|
|Eq. (27)-(30)|Twin vertical-tail/rudder force and arm moment|Current twin-fin model uses `CY(beta,rudder)` plus a code-only `0.02*CY^2` drag increment|STRUCTURAL MATCH + EMPIRICAL ADDITION|Name and source the drag term or remove it from publication-critical claims|
|Eq. (31)-(32)|Sum component forces/moments|`total_forces_moments.m` sums two rotors, wing, fuselage, horizontal and vertical tails|DIRECT MATCH|Keep; diagnostics are stronger than paper presentation|
|Eq. (33)|Body translational dynamics|`Vdot=F/m-cross(omega,V)` with gravity added in body axes|DIRECT MATCH|Keep|
|Eq. (34)-(35)|Rigid-body rotational dynamics with inertia tensor|`omegaDot=I\(M-cross(omega,I*omega))`|DIRECT RIGID-BODY MATCH|Keep; inertia-data provenance remains the issue, not the equation|
|Eq. (36)|3-2-1 Euler-angle kinematics|Current uses same 3-2-1 mapping with singularity guard|MATCH + NUMERICAL GUARD|Keep; applicability excludes near pitch +/-90 deg|
|Eq. (37)|Trim equilibrium `f(xe,ue)=0`|`trim_general` solves named residual subsets under explicit state/control constraints, and records the full derivative afterwards|GENERALIZED, NOT IDENTICAL|Publication trim acceptance must explicitly require all physically relevant equilibrium conditions; subset convergence alone is not enough|
|Eq. (38)-(40)|Linear state-space model, 9 states, 7 controls|Current state/control ordering matches the paper conceptually|DIRECT MATCH|Keep|
|Eq. (41)-(42)|A/B Jacobian matrices|Paper uses Simulink linearization; current code uses central finite differences of full nonlinear EOM|INDEPENDENT NUMERICAL IMPLEMENTATION|Potential strength, but step-size convergence and clamp/branch-distance checks are required|

## Assumption mapping

|Paper assumption|Current code|Assessment|
|---|---|---|
|Earth inertial / flat Earth|Effectively same local flight-dynamics scope|Acceptable for present work|
|Rigid aircraft|Same|Acceptable for low-order flight mechanics|
|Blade bending rigid, linear twist|Current blade is rigid with simple linear twist|Same class; geometry is conceptual|
|First-harmonic flapping|Yes, steady first-harmonic harmonic-balance solve|Present; previous claim that project had no flapping was incorrect|
|Small angle of attack/sideslip|Current wing deliberately departs from this through near-normal/full-angle branch|Primary candidate research contribution|
|Ignore rotor downwash on fuselage|Same|Acceptable only within stated scope|
|Ignore left-right rotor aerodynamic interference|Same|Limitation; not first modification unless validation demands it|
|Left-right symmetry|Same nominal architecture|Useful for verification tests|

## Highest-priority findings from the mapping

1. **The project should not be described as a simple reproduction of Sheng 2022.** The rotor harmonic solve, generalized trim framework and full-angle wing branch already depart materially from the paper.
2. **The largest paper-to-code physical divergence is currently the rotor/wing interaction closure**, especially Eq. (16) slipstream area and Eq. (17) induced-velocity strength (`wakeFactor`). This is more important than immediately adding dynamic inflow.
3. **The current wing model is both more capable and, in one geometric sense, simpler than the paper.** It adds full-angle blending, but collapses the paper's multiple free-flow subregions into one region per half-wing. This can affect force application points and moments.
4. **The current rotor flapping is steady harmonic balance, not transient rotor-state dynamics.** This is appropriate for trim-oriented work but limits dynamic-conversion and high-bandwidth handling-quality claims.
5. **Trim is numerically more sophisticated than the paper but must be governed carefully.** `trim_general` can solve selected residuals; every publication trim point should be accepted only after full physically relevant back-substitution checks.
6. **Linearization is not yet validation.** Central differences are a good independent implementation, but A/B matrices need step-size convergence and nonlinear perturbation closure before they are publication evidence.

## Immediate next work packages

### WP1 - exact rotor equation audit
- Prove the current Eq. (5)-(11) sign/axis correspondence with canonical hover and forward-flight cases.
- Derive the normalized equivalence (or non-equivalence) of paper Eq. (7) and current `UP`.
- Keep uniform inflow as baseline until paper Eq. (12) hover-limit behavior is resolved.

### WP2 - reconstruct a true Sheng-style wing baseline
- Implement/evaluate a baseline configuration that uses the paper's small-angle wing assumptions without the full-angle branch.
- Reproduce the paper Eq. (16) slipstream-area law as a **baseline option**, not as unquestioned truth.
- Remove `wakeFactor` from the baseline unless a source justifies it, or explicitly document the mapping from paper induced velocity to wing-plane induced velocity.

### WP3 - applicability map
- Sweep nacelle angle, speed and local wing flow angle.
- Mark where the Sheng-style small-angle assumption is violated.
- Compare baseline versus full-angle force/moment continuity and trim existence.

### WP4 - validation data inventory
- Rotor: dimensionless thrust/torque/power data.
- Rotor/wing: powered/unpowered or rotor-only/rotor+wing interference data.
- Only after these close should parameters such as `wakeFactor`, `SslipMaxHalf`, `CDnormal`, normal-flow blend center/width be calibrated or replaced.

## Claims explicitly prohibited at this stage

- Accurate XV-15 reproduction.
- Validated dynamic conversion maneuver prediction.
- Validated real-aircraft stability modes/handling qualities.
- Physically validated dynamic/nonuniform inflow.
- Experimentally validated rotor/wing interference.
