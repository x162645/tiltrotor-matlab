# Stage-2 matched-set direct audit — 2026-09-01

## Scope and claim boundary

This record freezes the direct-only evidence obtained after credible M1 trim closure at all three representative Stage-2 cases. It is **whole-aircraft propagation/sensitivity evidence on the generic conceptual airframe**, not XV-15 whole-aircraft validation.

The accepted-center audit does not re-trim. The direct linearization audit uses the same fixed central-difference endpoints and two prescribed scales for all cases:

- states: `dx = [0.05, 0.05, 0.05, 5e-4, 5e-4, 5e-4, 5e-4, 5e-4, 5e-4]` at scale 1;
- controls: `du = 5e-4 rad` at scale 1;
- second scale: 0.5;
- M1 endpoint calls receive only the accepted center left/right converged flap states as initial numerical states;
- no endpoint continuation is used in the direct audit;
- no physics, physical parameter, solver tolerance, iteration limit, trim/control bound, or DOF is changed.

## Matched trim/load set

Workflow run `33456660545`, artifact `9781694541`, digest `sha256:54e11ba906638835a11289259f4bc4475ce9485e9ba109b1a3f5142728729b1e` re-evaluated all six frozen accepted centers directly.

Result:

- reproduced accepted centers: **6/6**;
- physical convergence: **6/6**;
- physical branch support: **6/6**;
- matched M0/M1 comparable cases: **3/3**.

The re-evaluated residuals reproduce the source artifacts to essentially numerical precision. The accepted-center set is therefore a stable common basis for the Stage-2 matched propagation comparison.

Representative M0 -> M1 equilibrium/load changes:

| Case | collective | rotor thrust | rotor torque/power | induced velocity | longitudinal rotor H |
|---|---:|---:|---:|---:|---:|
| B15_V020 | -9.3407% | -0.1604% | -8.2385% | -0.1301% | magnitude -16.55% |
| B45_V035 | -7.0548% | -2.8466% | -7.2182% | -2.8329% | magnitude -52.77% |
| B75_V080 | -3.5564% | -1.6558% | -7.0359% | -1.6413% | magnitude -12.12% |

For B75 the raw `Hlong` remains negative (`-2730.29 -> -2399.38 N`); this is a reduction in magnitude, not a sign reversal.

## Direct fixed-endpoint two-scale A/B results

Workflow run `33456805119`, head `e438eaba5071bdaa0de06a2f285078fbbee5f803`.

### B15_V020

Artifact `9781737622`, digest `sha256:c12863890c26e57a614580df38db7a4a830496ca0592092da002087c7afab57f`.

- M0: 9/9 state columns and 7/7 control columns at both scales.
- M1: **9/9 state columns** at both scales; **5/7 control columns** at both scales.
- M1 A two-scale relative Frobenius difference: `1.6314021e-06`.
- M0 -> M1 A relative Frobenius difference at scale 0.5: `0.0244559091`.
- A signal / numerical-floor ratio: `14990.7`.
- spectral abscissa: M0 `0.082485989`, M1 `0.081305157`.
- unstable-root count: M0 `3`, M1 `3`.

Direct M1 control failures are localized to the collective family:

- collective minus endpoint fails at both scales;
- differential-collective plus and minus endpoints fail at both scales;
- all failures are `m1_evidence_v1_forward_rotor:FlapNotConverged`.

Therefore the B15 full A/eigenstructure comparison is admissible, but a complete two-scale B/control comparison is not yet admitted from the direct audit.

### B45_V035

Artifact `9781745703`, digest `sha256:f7ebe12574ef3ac662fdea539df079bbfd1560b5f5fd244bc1284e556a31d3fa`.

- M0: 9/9 state columns and 7/7 control columns at both scales.
- M1: **8/9 state columns** and **7/7 control columns** at both scales.
- scale 1 missing endpoint: `w-`, `FlapNotConverged`;
- scale 0.5 missing endpoint: `u+`, `FlapNotConverged`.
- M1 B two-scale relative Frobenius difference: `3.0801867e-05`.
- M0 -> M1 B relative Frobenius difference at scale 0.5: `0.3607739120`.
- B signal / numerical-floor ratio: `11712.7`.

This exactly reproduces the previously frozen B45 interpretation: full M1 A/eigenstructure remains blocked, while full M1 B/control effectiveness remains admissible.

### B75_V080

Artifact `9781761914`, digest `sha256:33d7596ee0111e6dd0b3b4ec754ef3399395cdf8fa3ab801cef23376b98d765c`.

- M0: 9/9 state columns and 7/7 control columns at both scales.
- M1: **9/9 state columns** at both scales.
- M1 B: 5/7 at scale 1, but **7/7 at scale 0.5**.
- M1 A two-scale relative Frobenius difference: `1.2167258e-06`.
- M0 -> M1 A relative Frobenius difference at scale 0.5: `0.00555075473`.
- A signal / numerical-floor ratio: `4562.04`.
- spectral abscissa: M0 `0`, M1 `0`.
- unstable-root count: M0 `0`, M1 `0`.

Scale-1 M1 failures are localized to the cyclic family:

- cyclic-long plus endpoint fails;
- differential-cyclic-long plus and minus endpoints fail;
- all failures are `m1_evidence_v1_forward_rotor:FlapNotConverged`.

The B75 full A/eigenstructure comparison is admissible. A complete two-scale B comparison is not yet admitted because the scale-1 M1 B matrix is incomplete, even though scale 0.5 is 7/7.

## Shared numerical finding and decision

The direct audit demonstrates the same **flap-closure nonconvergence class at fixed perturbation endpoints in all three nacelle regimes**, but expressed in different derivative families:

- B15: collective control endpoints;
- B45: translational-state endpoints;
- B75: coarse cyclic-control endpoints.

This satisfies the previously declared condition for reopening numerical work as **shared Stage-2 infrastructure**, rather than B45-only machinery.

A shared branch-tracked fixed-endpoint audit is therefore scientifically justified. Its rules are frozen before reading its results:

1. retain every direct failure as evidence;
2. move from the accepted center to the **same exact derivative endpoint** only after a direct M1 endpoint failure;
3. carry only the last converged left/right flap states;
4. do not change endpoint magnitude, physical parameters, solver tolerances, iteration limits, trim/control bounds, or DOFs;
5. if a fixed endpoint remains unreachable, retain it as an unresolved numerical endpoint and do not manufacture the missing derivative;
6. full A/eigenstructure and full B/control-effectiveness remain independently gated.

The purpose of the shared branch-tracked audit is to distinguish fixed-endpoint branch reachability from direct-seed basin sensitivity, not to force every matrix to become complete.
