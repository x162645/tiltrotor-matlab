# Berger13 PR1 isolated research scaffold

## Status and frozen ancestry

This namespace is an opt-in research scaffold, not the repository's default
physical model. It is implemented on the accepted NUAA physical baseline
`feature/nuaa-equation-17` at
`3550e5b855bac1c38e9d275cf3f8e608cb519c70`. The selective research reference
is `codex/lateral-directional-input-audit` at
`370c7aef13a5dca98c0436616548729859c399a9`; that source is not promoted to a
physical baseline.

The production entry points remain the nine-state/seven-input NUAA path. PR1
does not change `params_nominal.m`, the NUAA Eq. (12), (13), (16), or (17)
implementations, control limits, trim tolerances, or the legacy wing path. No
full-angle wing option is added or enabled.

## Frozen interface

The state vector is

```text
[u, v, w, p, q, r, phi, theta, psi,
 betaML, betaMR, betaMLdot, betaMRdot]'
```

with units

```text
[m/s, m/s, m/s, rad/s, rad/s, rad/s, rad, rad, rad,
 rad, rad, rad/s, rad/s]'.
```

The input vector is

```text
[collective, diffCollective, cyclicLong, diffCyclic, lateralCyclic,
 aileron, elevator, rudder, nacelleTorqueLeft, nacelleTorqueRight]'
```

with radians for the first eight controls and `N*m` for each nacelle torque.
The project convention is `betaM=0` in helicopter mode and `betaM=pi/2` in
airplane mode.

`diffCyclic` remains the historical code name for differential longitudinal
cyclic. The added `lateralCyclic` is accepted only by the Berger13 namespace.
It is mapped to the rotor cosine harmonic by
`theta1cSide=rotDir*lateralCyclic`; this mapping is tagged
`ASSUMED_MODEL_PARAMETER`, not as published aircraft data.

## Implemented PR1 path

`total_forces_moments_13x10` evaluates the unchanged legacy component stack at
the mean nacelle angle `0.5*(betaML+betaMR)` with the legacy seven inputs. It
then removes the two mean-angle rotor contributions and inserts two
namespace-local rotor evaluations at `betaML` and `betaMR`. Thus only the
left/right rotor loads have independent nacelle angles in PR1.

The local rotor is copied from the frozen NUAA baseline and retains its Eq.
(12)/(13) inflow and first-harmonic flapping implementation. Its only
aerodynamic extension is the namespace-local lateral-cyclic cosine harmonic.
The production `model/rotor_model_bemt.m` remains unchanged.

The nacelle states use the deliberately low-order placeholder equations

```text
beta_dot = betaRate
I*beta_ddot = Qsat - D*betaRate
```

independently for left and right sides. `I`, `D`, `K`, angle/rate bounds, and
torque bounds in `params_berger13.m` are all tagged `RESEARCH_PLACEHOLDER`.
`K=0` is retained for provenance compatibility but stiffness is explicitly
inactive. These values are not Berger, XV-15, NUAA, measured, identified, or
validated aircraft parameters. Finite-difference steps are tagged
`ASSUMED_MODEL_PARAMETER` and are numerical settings, not physical data.

`linearize_13x10_numeric` provides central finite differences at interior
points and one-sided differences at nacelle/control bounds. It reports state
and input names, units, steps, and schemes. Finite matrices and local
increment agreement are internal numerical-consistency evidence only.

## Explicit limitations

- Wing, fuselage, empennage, mass properties, and wing-slipstream diagnostics
  use the mean nacelle angle; the wing has no independent left/right
  slipstream path in PR1.
- Nacelle torque does not react on the fuselage. Moving mass/CG/inertia
  dynamics, `I_dot*omega`, gyroscopic effects, drivetrain/transmission
  coupling, and actuator closed-loop dynamics are absent.
- No formal 13-state trim solver, modal/handling-quality assessment, fault
  study, or external aircraft validation is implemented.
- The scaffold is not a reproduction of Berger's 51-state model and must not
  be described as one.
- Passing regression, finite-value, degradation, or linearization checks does
  not establish NUAA, Berger, or XV-15 model validation.

PR2 through PR4 are not implemented in this change.
