# Berger13 PR3 commanded-actuator and independent-wing evidence

## Version and scope

- Base: `codex/berger13-pr2-formal-trim@b96f357b142c4e1cd8c19b9eb39fd49fb74fe94b`.
- Head branch: `codex/berger13-pr3-commanded-actuator-independent-wing`.
- Task-contract commit: `619dd2884c203624e2994a5f8eeaf521078d970e`.
- Added a distinct angle-command input contract, per-side closed-loop actuator,
  observable limits/faults, independent half-wing loads, asymmetric moving-mass
  correction, actuator reaction moment, and parameterized nacelle-rate gyro.
- The PR1 torque interface and all legacy defaults remain separately callable.

## Interface and equations

The torque interface retains inputs 9/10 as `nacelleTorqueLeft` and
`nacelleTorqueRight`. The new function
`tiltrotor_eom_13x10_command` always interprets them as
`betaMLCommand` and `betaMRCommand`; no function switches meaning at runtime.

For each side,

`betaDDot = omegaN^2*(betaCommand-beta)-2*zeta*omegaN*betaDot`,

followed by explicit command-angle, rate, acceleration, and equivalent
internal-torque limits. A positive configured time delay requires an external
`delayedCommand` history value because a true delay is not representable by the
frozen 13 Markov states. Stuck, frozen-command, and rate-degradation states and
every active limit are observable in the output structure.

The command actuator generalized coordinate increases from helicopter toward
airplane mode; its rotation axis is `-eY`. The equal-and-opposite reaction on
the body is therefore recorded along `+eY` for positive applied generalized
torque. The implemented relative tilt-rate rotor angular-momentum term is

`MgyroTilt = -sum(rotDir_i*Jpolar*Omega*betaDot_i*eD_i)`.

The pre-existing body-rate gyro term remains inside each rotor model. The new
term is zero at the current default `Jpolar=0` and becomes active only under an
explicit parameter study.

## Independent wing and mass properties

Each half wing reuses the reviewed NUAA Eq. (16)-(22) region calculation with
its own angle, wake, local rigid-body velocity, area partition, aerodynamic
center, force, aerodynamic moment, and `cross(r,F)` arm moment. Fuselage and
tail loads remain at the average-angle symmetric reference. Cross-rotor wake
interference is not modeled.

Per-side moving masses are derived as one half of the existing combined
moving mass. The asymmetric correction uses

`rCG=sum(m_i*r_i)/sum(m_i)`

and `m*((r'*r)E-r*r')`. The symmetric limit is exactly the legacy mass and
inertia result. Local nacelle inertia tensors are `UNKNOWN`, so no local-tensor
rotation correction is invented.

## Parameter provenance

Berger dissertation PDF 95, printed 60, Section 2.1.3.3 states that a PID maps
two commanded nacelle angles to the required two nacelle torques. It supports
the structure, not this project's numerical values. `omegaN=4 rad/s`,
`zeta=0.8`, acceleration/rate/torque limits, delay, and fault settings remain
`RESEARCH_PLACEHOLDER` or `ASSUMED_MODEL_PARAMETER` and are intended for
sensitivity envelopes only.

## Focused quantitative results

At the internally credible 45 deg, 35 m/s trim, central perturbation of
`betaDiff=(betaMR-betaML)/2` with `h=1e-4 rad` gave:

|Derivative|Value|
|-|-:|
|`dFy/dBetaDiff`|`1.8792866e3 N/rad`|
|`dL/dBetaDiff`|`2.9804176e5 N m/rad`|
|`dN/dBetaDiff`|`-3.8275432e4 N m/rad`|

The near-zero symmetric components were retained as numerical evidence and
not interpreted as coupling. Under the default placeholder actuator, a common
1 deg command step produced initial `betaDDot=0.2792527 rad/s^2` per side and
an actuator reaction `My=139.6263 N m`. For 44/46 deg left/right angles, the
parameterized CG correction relative to 45/45 deg was
`[-1.2116e-5,0,+1.2116e-5] m`; the inertia change Frobenius norm was
`83.3001 kg m^2` and the minimum inertia eigenvalue remained
`1.7740e4 kg m^2`.

## MATLAB evidence

- PR3 pre-change full regression: 21/21 passed,
  `PR3_BASELINE_ALL_PASSED=1`, 312.045 s.
- `checkcode`: zero findings across all 15 initially changed/added MATLAB
  files.
- Joint focused regression: PR1 passed, PR2 passed, PR3 12/12 passed;
  elapsed 89.673 s.
- Focused coverage includes command/torque contract separation, nominal step,
  all four limits, asymmetric bandwidth/damping, explicit delay context,
  stuck/freeze/rate degradation, wing symmetric degradation, betaDiff mirror,
  CG/inertia exchange, gyro parameterization, command trim/A/B, and torque
  interface preservation.

- PR3 post-change full regression: 22/22 passed,
  `PR3_FINAL_ALL_PASSED=1`, 335.152 s (process wall time 343.4 s).
- Final all-file `checkcode`: zero findings.

The final SHA is recorded in the Draft PR after the implementation commit
exists.

## Explicit omissions

`I_dot*omega`, moving-CG velocity/acceleration forces, elastic transmission,
drivetrain torsion, and unidentified local nacelle inertia tensors remain
unimplemented. Their absence is preferable to inserting unsupported constants.
This PR supplies an internally testable low-order research path, not Berger
51-state reproduction, XV-15 validation, or actuator qualification.
