# Codex task: implement NUAA equations (12), (13), and (16)

## Goal
Implement the NUAA paper's formula structure. Numerical equality with the authors is not required. Existing missing values may remain explicit `ASSUMED_CONCEPT` or `DERIVED` values. Do not tune parameters to reproduce old curves.

Start from `origin/feature/nuaa-trim-trend-validation` and create `feature/nuaa-equations-12-13-16`. Read `AGENTS.md`, the NUAA PDF, current rotor/wing models, tests, `PAPER_CODE_MAPPING.md`, and `PARAMETER_SOURCE_INVENTORY.md`. Stop on unexpected local changes; do not clean/reset/restore; preserve `validation/`.

## Eq. (12): non-uniform induced velocity
In `model/rotor_model_bemt.m`, replace active uniform inflow

```matlab
viField = viMean;
```

with the paper formula

```matlab
viField = viMean .* (1 + cos(psi).*(rMid/P.rotor.R));
```

using the current spatial convention `psi=0` along `+eD`. Use the same spatial `cos(psi)` field for both rotors; `rotDir` still controls blade motion. Do not add a `mu` multiplier or hover fade-out absent from the paper. Eq. (12) must participate inside every induced-velocity/flapping iteration, not be display-only.

Expose field min, max, azimuth-mean error, and model name `NUAA_EQ12_FIRST_HARMONIC`.

## Eq. (13): equivalent induced velocity
Implement the paper expression explicitly:

```matlab
tipSpeed = P.rotor.Omega*P.rotor.R;
A = pi*P.rotor.R^2;
mu = hypot(Vlong,Vlat)/tipSpeed;
lambda0 = -Vaxial/tipSpeed;
lambda1 = lambda0 - vi/tipSpeed;
CT = max(loads.T,0)/(0.5*P.env.rho*A*tipSpeed^2);
viTarget = tipSpeed*CT/(4*sqrt(lambda1^2 + mu^2));
viNew = 0.5*(vi + viTarget);
```

Use only a small denominator floor. Retain the positive-thrust guard and report when active; do not add windmill/autorotation physics. The `0.5*rho*A*(Omega R)^2` CT definition is a documented derived normalization that makes Eq. (13) algebraically equivalent to the current positive-thrust momentum relation under the current sign convention. Set active `P.rotor.inducedRelax=0.50` or stop using the old `0.45` value.

Expose `CT`, `mu`, `lambda0`, `lambda1`, Eq.13 target, iteration count, guard status, and closure name `NUAA_EQ13`.

The active chain must be:

```text
mean vi -> Eq.12 field -> blade loads -> thrust/CT -> Eq.13 target -> 0.5 average
```

## Eq. (16): wing slipstream-zone area
In `model/wing_model.m`, remove active use of:

```matlab
1 - 0.25*min(mu/muMax,1)
0.60 + 0.40*abs(cos(2*betaM))
```

The paper angle convention is opposite the code. Use:

```matlab
betaPaper = pi/2 - betaM;
angleRaw = sin(1.386*(pi/2-betaPaper)) + ...
           cos(3.114*(pi/2-betaPaper));
muMean = 0.5*(hypot(rotorLeft.muLong,rotorLeft.muLat) + ...
              hypot(rotorRight.muLong,rotorRight.muLat));
muRaw = (P.wing.muMax-muMean)/P.wing.muMax;
SslipRawHalf = P.wing.SslipMaxHalf*angleRaw*muRaw;
upper = min(P.wing.SslipMaxHalf,P.wing.S/2);
S_slip = min(max(SslipRawHalf,0),upper);
S_free = P.wing.S/2-S_slip;
```

Keep `P.wing.SslipMaxHalf=4.0` and `P.wing.muMax=0.35` unchanged and explicitly assumed. The bound is a separately named physical-area guard, not part of Eq. (16). Expose raw/applied area, raw factors, paper angle, advance ratio, upper bound, low/high clamp flags, and model name `NUAA_EQ16_WITH_PHYSICAL_AREA_GUARD`.

Do not change `P.rotor.wakeFactor`; Eq. (17) remains pending.

## Allowed production files
- `model/rotor_model_bemt.m`
- `model/wing_model.m`
- `params_nominal.m`

Add focused tests and update only directly affected old assertions. Do not modify trim strategy, allocation, limits, other physical parameters, EOM, or linearization.

## Required tests
Create focused tests that verify:

1. Eq.12: at `r=0` field equals mean; at `r=R,psi=0` it is `2*mean`; at `r=R,psi=pi` it is zero; azimuth mean equals mean; left/right use the same spatial field.
2. Eq.13: explicit paper expression equals `T/(2*rho*A*sqrt(Vplane^2+(Vaxial+vi)^2))` under the specified definitions; update is exactly 0.5 average; representative rotor calls remain finite and converged.
3. Eq.16: for code angles `0,15,30,45,60,75,90 deg` and `mu=[0,0.5*muMax,muMax,1.2*muMax]`, raw formula is literal, applied area is bounded, clamp flags are correct, free area complements slipstream area, and old 60%/25% schedules are absent.

Then run focused existing rotor/wing tests. Stop on symmetry, sign, convergence, or finite-value failure. Do not tune parameters or blindly update snapshots.

## Trim and regression gates
After focused tests pass, run only:

- helicopter 0 deg at 0 and 20 m/s;
- conversion 15 deg at 35 m/s;
- conversion 75 deg at 100 m/s;
- airplane 90 deg at 100 m/s.

Report convergence, credibility, controls, Eq.12 field range, Eq.13 diagnostics, Eq.16 raw/applied area and clamp state. If any point fails, stop without seed search or tuning.

If all pass, run `run_all_checks`, then rerun NUAA trend validation and summary plotting. Preserve old `20260625` evidence; write new outputs to `docs/validation/nuaa_trim_trends/20260625_eq12_13_16/` and a matching timestamped local `validation/` directory.

## Documentation and Git
Update `PAPER_CODE_MAPPING.md` and `PARAMETER_SOURCE_INVENTORY.md`: Eq12 implemented, Eq13 implemented with derived normalization/sign mapping, Eq16 literal raw formula plus explicit guard, Eq17 pending; assumed area parameters remain assumed; induced averaging is 0.50.

Commit logically, push `origin/feature/nuaa-equations-12-13-16`, and do not create a PR. Final report must include changed files, assumptions, tests, representative trims, whether full trend rerun was reached, output paths, commit SHAs, and clean status.