# Stage 2 paper-ready whole-aircraft propagation findings

## Claim boundary

All results in this note are **whole-aircraft propagation/sensitivity evidence for the repository's generic conceptual airframe**. They are **not XV-15 whole-aircraft validation**, and they do not remove the existing requirement for a HIGH-homology external dynamic validation case.

The M1 rotor identity used here is the frozen `M1_EVIDENCE_V1_PROPAGATION` extension. No Stage-2 trim or dynamic result was used to tune M1 rotor physics.

## Evidence discipline

The accepted three-case equilibrium set is B15_V020, B45_V035 and B75_V080. All six M0/M1 accepted centers reproduce as physically converged and physically branch-supported trim points. Dynamic claims are then gated independently for the state Jacobian A and control Jacobian B.

Fixed-endpoint direct and shared branch-tracked audits showed localized M1 flap-closure fragility at some perturbation endpoints. Shared branch tracking did **not** recover those failed endpoints. The unresolved endpoints are therefore retained as numerical-closure evidence; they are not converted into a new physical/model support-domain definition and are not hidden by one-sided derivatives or relaxed solver/model settings.

Accepted dynamic gates:

- **B15_V020:** full two-scale A accepted; full two-scale B blocked. Modal/eigenstructure propagation and the supported B columns are admissible.
- **B45_V035:** full two-scale B accepted; full A blocked at 8/9 state columns. Control-effectiveness propagation is admissible; eigen/modal-shift claims are not.
- **B75_V080:** full two-scale A accepted; full two-scale B blocked because the coarse cyclic family is incomplete. Modal/eigenstructure propagation and common two-scale B columns are admissible; the fine-scale complete B remains diagnostic only.

## MATLAB-native modal reproduction closure

The accepted B15/B75 fine-scale full-A evidence is stored as four exact 81-element blocks under `evidence/full_a/`. The previously assembled combined snapshot was removed after regression exposed that it did not preserve the exact accepted artifact values.

`run_stage2_accepted_modal_matching_reproduction.m` reconstructs the four matrices in base MATLAB R2021a, collapses real systems into real/integrator modes plus the positive-imaginary representative of each conjugate pair, and performs a global same-type assignment using

`normalized eigenvalue distance + (1 - MAC)`.

The frozen accepted modal table is used only after the independent assignment for ordering and regression validation.

Accepted reproduction audit:

- workflow run: `33461020489`
- head SHA: `de4a04c3c2c94bce7b62e346f95603980b31e9bd`
- artifact: `9783164039`
- artifact digest: `sha256:ab45ca38ab8385edf6a655aa2d86afa6f75b02ac6d8228cf03dcbcadcfc8130c`
- MATLAB: R2021a
- accepted A elements: **324/324**
- reproduced collapsed modes: **13**
- validated rows: **13/13**
- maximum numeric absolute regression error: **8.38218383591993e-14**
- all mode-type, top-state, numerical and row gates: **PASS**

This closes the reproducibility gap for the accepted B15/B75 M0-to-M1 modal matching.

## Three-case equilibrium/load propagation

### B15_V020

M1 reaches almost the same required rotor thrust while changing the rotor operating state: collective decreases from **38.4119 deg to 34.8240 deg** (-9.34%), mean rotor torque decreases **8.24%**, mean induced velocity changes only **-0.13%**, and `Hlong` decreases from **1849.97 N to 1543.73 N** (absolute magnitude -16.55%). Pitch attitude changes by only about **-0.00076 deg**.

This is consistent with a change in rotor force/torque production characteristics rather than a wholesale change in the equilibrium airframe attitude requirement.

### B45_V035

The conversion case exhibits the strongest load redistribution. Collective decreases **7.05%**, mean rotor torque decreases **7.22%**, mean rotor thrust decreases **2.85%**, and `Hlong` falls from **3098.29 N to 1462.49 N**, a **52.80%** reduction in magnitude. The accepted trim also shifts pitch attitude by about **-0.888 deg**, longitudinal cyclic by **+3.682 deg**, and elevator by **+2.104 deg**.

Because the M0 and M1 derivatives are evaluated at their respective credible equilibrium trims, this is a propagated equilibrium/control-allocation change and must not be attributed to a single M1 sub-model term in isolation.

### B75_V080

Collective decreases from **51.9493 deg to 50.1017 deg** (-3.56%), mean rotor torque decreases **7.04%**, mean rotor thrust decreases **1.66%**, and induced velocity decreases **1.64%**. `Hlong` remains negative and changes from **-2730.29 N to -2399.38 N**; its absolute magnitude therefore decreases **12.12%**. There is no H-force sign reversal.

Across B15/B45/B75, rotor torque reduction remains approximately **7-8%**, while H-force redistribution is strongly nacelle-regime dependent and is largest in the B45 conversion case.

## Accepted control-effectiveness propagation

The clearest localization is between rotor-mediated and conventional-airframe control channels.

- **B15:** among accepted common two-scale columns, cyclicLong increases **4.61%** and diffCyclicLong **8.28%**. Collective and differential-collective columns remain blocked by fixed-endpoint flap nonconvergence. Aileron/elevator/rudder changes are negligible.
- **B45:** collective, diffCollective, cyclicLong and diffCyclicLong B-column norms increase approximately **37.13%, 35.53%, 35.96% and 45.49%**, respectively. Aileron changes about **10.05%**, while elevator changes **-0.83%** and rudder is unchanged. The full-B M0-to-M1 Frobenius change is **36.08%**, roughly **1.17e4** times the two-scale numerical floor.
- **B75:** accepted collective and diffCollective column norms increase **26.81%** and **29.60%**. Aileron changes **-0.95%**, elevator **-0.073%**, and rudder is unchanged. The coarse cyclic-family columns are blocked and are not promoted from the fine-scale diagnostic B matrix.

The supported evidence therefore shows that M1 propagation is concentrated primarily in **rotor-mediated control channels**, with the largest accepted control-effectiveness redistribution at B45. This is physically coherent with the location of the M1 changes in rotor physics, but it remains a whole-system propagation result at different credible equilibria rather than proof of causal contribution from any single physics enhancement.

## Accepted modal propagation

### B15_V020

The full-A M0-to-M1 relative Frobenius change is **2.4456%**, while the two-scale numerical floor is **1.6314e-6**, giving a signal-to-floor ratio of approximately **1.50e4**. The spectral abscissa changes from **0.082486 s^-1 to 0.081305 s^-1**, and the positive-real eigenvalue count remains **3 to 3**.

Therefore M1 changes the local state dynamics, frequencies/growth rates and modal structure, but it **does not remove the generic-airframe open-loop instability at B15**. No statement of XV-15 flying-qualities improvement follows from this result.

### B75_V080

The full-A M0-to-M1 relative Frobenius change is **0.5551%**, approximately **4562** times the two-scale numerical floor. The spectral abscissa remains **0**, with **0 to 0** positive-real non-integrator roots.

Thus M1 alters the accepted local modal time scales while preserving the absence of an open-loop unstable non-integrator root at this generic-airframe propagation point.

### B45_V035

No M1 full-A eigenstructure or modal-shift result is admissible. The missing state derivative remains unresolved after both direct and shared fixed-endpoint branch-tracked evaluation, so the accepted B45 evidence stops at trim/load, full B, and partial 8/9 state-derivative information.

## Paper mechanism chain

The supported Stage-2 mechanism chain can be stated conservatively as:

**frozen M1 rotor physics -> changed equilibrium rotor force/torque/H-load allocation -> changed rotor-mediated control effectiveness -> measurable whole-aircraft local dynamic propagation where the A/B comparability gate is satisfied.**

The conversion case B45 shows the strongest accepted load and control-effectiveness redistribution, while B15 and B75 provide accepted full-A modal evidence on either side of that conversion point. Together these cases provide a coherent three-regime propagation argument without converting numerical failures into physics changes, without fitting to Stage-2 outcomes, and without claiming XV-15 whole-aircraft validation.

## Primary evidence files

- `STAGE2_PAPER_READY_THREE_CASE_EVIDENCE.csv`
- `STAGE2_ACCEPTED_DYNAMIC_COMPARABILITY.csv`
- `STAGE2_ACCEPTED_CONTROL_COLUMN_COMPARISON.csv`
- `STAGE2_ACCEPTED_MODAL_MATCHING.csv`
- `STAGE2_ACCEPTED_MODAL_REPRODUCTION_AUDIT.csv`
- `full_a/STAGE2_ACCEPTED_A_B15_M0_SCALE05.csv`
- `full_a/STAGE2_ACCEPTED_A_B15_M1_SCALE05.csv`
- `full_a/STAGE2_ACCEPTED_A_B75_M0_SCALE05.csv`
- `full_a/STAGE2_ACCEPTED_A_B75_M1_SCALE05.csv`
