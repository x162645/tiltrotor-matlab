# M1 Strict-Hover Eq. (12) Limit Audit

## Question

The current low-order rotor path uses the published NUAA Eq. (12)-style first-harmonic induced-velocity field

`vi(r,psi) = vi_bar * (1 + r/R*cos(psi))`.

In strict hover there is no physically distinguished in-plane inflow direction, so a retained fixed `cos(psi)` direction is potentially nonobjective. This audit asks whether that formal issue contaminates integrated hover performance or is cancelled by the simultaneously solved first-harmonic flapping state.

This is a strict-hover applicability audit. It does not invalidate Eq. (12) for forward flight, where an in-plane direction is physically defined.

## Formal MATLAB execution

- MATLAB: R2021a
- workflow run: `33290011132`
- job: `99199885669`
- artifact: `9725672050`
- artifact SHA-256: `974692e39befe0f949e03fe9761d6132396bb92088576e34096be05f4721b0c5`
- fixed collective window: 6--11 deg
- Eq. (12) and uniform-inflow branches: 6/6 physically converged each
- identity gate versus the previously implemented factorial Eq12/uniform diagnostic: maximum CT/CP/FM absolute difference = `0`

No OARF target enters any parameter or audit threshold.

## Main result

The integrated hover solution is effectively invariant to removing the strict-hover Eq. (12) azimuthal harmonic:

- maximum `|Delta CT|/CT`: `4.7544e-08 %`
- maximum `|Delta CP|/CP`: `2.5167e-07 %`
- maximum `|Delta FM|/FM`: `1.8036e-07 %`

The reason is an almost exact kinematic cancellation. With

`beta = beta0 + beta1c*cos(psi) + beta1s*sin(psi)`

and

`UP = vi(r,psi) - betaDot*r`,

the solver produces approximately

`beta1s = -vi_bar/(Omega*R)`.

Across 6--11 deg, the normalized residual of `beta1s + vi_bar/(Omega*R)` is at most `9.147e-07`.

Consequently, although Eq. (12) carries an explicit `cos(psi)` inflow harmonic, the solved flapping velocity nearly removes it from local normal velocity and aerodynamic loading:

- maximum Eq12 local-UP 1/rev / mean ratio: `0.011032 %`
- maximum Eq12 blade-thrust 1/rev / mean ratio: `0.0058066 %`
- uniform-inflow counterparts are numerical zero.

The resulting fixed-axis diagnostic in-plane H force is also negligible: maximum Eq12 magnitude about `0.01628 N`, versus numerical zero for uniform inflow.

## The remaining strict-hover pathology

The cancellation does **not** make the Eq. (12) first-harmonic flap state itself objective.

Eq. (12) produces a nonzero first-harmonic flap magnitude that grows from about `2.892 deg` at 6 deg collective to about `4.118 deg` at 11 deg, almost entirely in `beta1s`. Uniform hover inflow gives first-harmonic flap magnitude at numerical zero (`< 6e-16 deg`).

Thus two representations produce indistinguishable integrated and blade-local aerodynamic loading while assigning radically different first-harmonic flap coordinates. In strict hover, where the azimuth-zero in-plane direction is arbitrary, the Eq. (12)-generated `beta1s` must not be interpreted as a physically objective lateral rotor state.

## Decision

`INTEGRAL_HOVER_PERFORMANCE_ROBUST_BUT_EQ12_FIRST_HARMONIC_FLAP_STATE_IS_STRICT_HOVER_NONOBJECTIVE`

### What remains valid

For the present M0/M1 external hover-correlation evidence, use of Eq. (12) does not materially alter:

- CT;
- CP;
- FM;
- mean induced velocity;
- mean blade loading.

Therefore the M0/M1 hover-performance evidence does not require rollback on this issue.

### What is restricted

At exact/strict hover, do not use the Eq. (12)-generated `beta1c/beta1s` coordinates as externally meaningful first-harmonic physical observables unless a physically defined in-plane direction and corresponding inflow model are supplied.

Likewise, strict-hover lateral/directional dynamics or 1/rev interpretations must not be justified merely from the nonzero Eq. (12) flap harmonic. For an axisymmetric hover reference calculation, uniform hover inflow is the objective reference representation.

### What this audit does not say

It does not show that Eq. (12) is invalid in forward flight or conversion conditions with a physically defined in-plane velocity direction. It also does not validate detailed measured blade flapping, dynamic inflow, or wake harmonics.

## Downstream consequence

The strict-hover Eq. (12) blocker is closed without changing the frozen M0/M1 hover CT/CP/FM evidence. The model documentation must carry an applicability restriction on strict-hover first-harmonic flap-state interpretation. The next remaining audit items are Corrigan `n=1` provenance wording/identity closure and the WADC test-input homology sensitivity.
