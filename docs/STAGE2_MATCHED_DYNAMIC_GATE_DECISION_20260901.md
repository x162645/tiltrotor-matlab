# Stage-2 matched dynamic gate decision — 2026-09-01

## Decision

The shared fixed-endpoint branch-tracked audit is complete. It was justified because the preceding direct-only audit found the same M1 flap-closure nonconvergence class in B15, B45, and B75, although in different derivative families.

The branch-tracked audit did **not** recover any of the direct-failed fixed endpoints. No physical parameter, endpoint magnitude, solver tolerance, iteration limit, trim/control bound, or DOF was changed. Therefore Stage 2 now stops escalating numerical continuation solely to make every A/B matrix complete.

This is a numerical evidence decision, not a declaration that the failed derivative endpoints are physically impossible. Their local derivatives remain **numerically unresolved under the frozen solver/endpoint contract**.

## Provenance

Workflow run: `33457108284`

Head: `29fc688064565717de20431fe38a85e44a641112`

Artifacts:

- B15_V020: `9781869530`, digest `sha256:1b6a1ea20e9c9f17548a06f03380b2cd67c48cedd78036ca7f9ffe693e9322e1`
- B45_V035: `9781864187`, digest `sha256:1d98d0dc32754c85c679bf4accee3266f170e5772c5d6ccc8ace533047c58e18`
- B75_V080: `9781869365`, digest `sha256:7597b3ac95a1aba9d4eee4889420c01245aa79581326a99e71037e88067170f4`

## Endpoint results

### B15_V020

Final gate at both finite-difference scales:

- full A: **PASS, 9/9 state columns**;
- full B: **BLOCKED, 5/7 control columns**.

Unresolved M1 endpoints:

- collective minus;
- differential-collective plus;
- differential-collective minus.

At scale 1, the failed endpoints were each followed for up to 23 path attempts. At scale 0.5 they were followed for up to 26 path attempts. All remained `FlapNotConverged` at the same fixed endpoints.

Admitted claims:

- matched trim/load propagation;
- full two-scale A and eigenstructure/modal analysis;
- supported partial B columns: cyclic-long, differential-cyclic-long, aileron, elevator, rudder.

Blocked claims:

- full B/control-effectiveness matrix;
- collective and differential-collective effectiveness.

### B45_V035

Final gate at both scales:

- full A: **BLOCKED, 8/9 state columns**;
- full B: **PASS, 7/7 control columns**.

Unresolved M1 endpoints:

- scale 1: `w-`, 27 path attempts;
- scale 0.5: `u+`, 29 path attempts.

This reproduces the previously frozen B45 result rather than changing it.

Admitted claims:

- matched trim/load propagation;
- full two-scale B/control-effectiveness analysis;
- supported 8/9 state-derivative columns as partial derivative evidence.

Blocked claims:

- full A;
- M1 eigenstructure/modal shift at B45.

### B75_V080

State derivative gate:

- full A: **PASS, 9/9 state columns at both scales**.

Control derivative gate:

- scale 1: **5/7**;
- scale 0.5: **7/7**.

Unresolved scale-1 M1 endpoints:

- cyclic-long plus;
- differential-cyclic-long plus;
- differential-cyclic-long minus.

Each was followed for up to 28 path attempts and remained `FlapNotConverged` at the same fixed endpoint.

Admitted claims:

- matched trim/load propagation;
- full two-scale A and eigenstructure/modal analysis;
- two-scale supported partial B columns: collective, differential-collective, aileron, elevator, rudder;
- scale-0.5 full B only as a lower-tier single-scale diagnostic.

Blocked claim:

- complete two-scale B/control-effectiveness matrix.

## Numerical-signal separation

Where full two-scale matrices exist, the M0 -> M1 propagation change is far larger than the corresponding two-scale numerical sensitivity:

- B15 A: relative M0/M1 change `0.0244559`; numerical floor `1.6314e-06`; signal/floor `14990.7`.
- B45 B: relative M0/M1 change `0.360774`; numerical floor `3.08019e-05`; signal/floor `11712.7`.
- B75 A: relative M0/M1 change `0.00555075`; numerical floor `1.21673e-06`; signal/floor `4562.0`.

No result-driven percentage threshold is introduced. The comparison is reported directly against the same-quantity two-scale numerical sensitivity.

## Mainline after this decision

Stage 2 proceeds with a gate-aware paper evidence chain rather than further endpoint forcing:

1. retain the 3/3 matched trim/load comparison;
2. perform eigenvector-aware modal matching and modal interpretation for B15 and B75 only;
3. perform full two-scale control-effectiveness analysis for B45;
4. compare supported partial control derivatives in B15/B75 without filling missing columns;
5. connect equilibrium-load, derivative, and modal changes back to the frozen M1 rotor-physics evidence;
6. preserve the claim boundary: generic-airframe whole-aircraft propagation/sensitivity, not XV-15 whole-aircraft validation.
