# Berger13 PR2 formal-trim evidence

## Scope and version

- Base: `codex/berger13-pr1-baseline-port@c1189ee59ddfda7e5b5032867c91a148039c2e30`.
- Head branch: `codex/berger13-pr2-formal-trim`.
- Task-contract commit: `cfffa27bf470248356fce3d3f3685b49c1f5c0b8`.
- Scope: opt-in symmetric 13-state trim, credibility gating, symmetric/differential transforms, and trim-point torque-interface linearization.
- Legacy production equations, parameter values, default trim, GUI, and seven-input interfaces were not changed.

## Mathematical and literature basis

The formal point uses the frozen state order

`[u v w p q r phi theta psi betaML betaMR betaMLdot betaMRdot]^T`

and requires zero rigid-body accelerations plus zero nacelle rates and
accelerations. Static torque inputs are zero because PR1 implements
`I*betaDDot=Q-D*betaDot` with no active stiffness. The coordinate transform is

`betaSym=(betaML+betaMR)/2`, `betaDiff=(betaMR-betaML)/2`,

with the identical map for rates and left/right torque inputs.

Method sources were visually checked in the original PDFs:

- Thomas Berger dissertation, PDF 93-95, printed 58-60, Section 2.1.3.3,
  Figure 2.16 and the state/input lists: 51-state source model, two nacelle
  angle/rate pairs, two nacelle torque inputs, and angle-command PID mapping.
  This PR does not claim to reproduce the omitted 32 blade and 6 inflow states.
- Sheng, Zhang, and Xiang, *Drones* 2022, PDF 12, Section 5,
  Figure 8 and Eqs. (38)-(42): trim before linearization and the source
  nine-state/seven-input arrangement. It is structural support, not 13-state
  parameter validation.
- Dreier, Chinese edition, PDF 348-360, printed 323-335, Chapter 17,
  especially Eqs. (17-13)-(17-19): explicit trim variables, six acceleration
  residuals, numerical Jacobian, and iterative correction. It provides method
  guidance and no nacelle actuator parameter values.

## Credibility gate

Each point reports the solver result, full 13-state derivative, force/moment
balance, command/applied controls, limits, three Jacobian steps, SVD, effective
rank, condition number, minimum singular value, boundary margin, seed
sensitivity, and continuation seed. Classification is one of `CREDIBLE`,
`CONVERGED_BUT_BOUNDARY_LIMITED`, `ILL_CONDITIONED`, `RANK_DEFICIENT`,
`NONPHYSICAL`, or `FAILED`. The formal linearization wrapper rejects every
status except `CREDIBLE`.

## Operating-point grid

The grid is `ASSUMED_RESEARCH_GRID`, chosen to probe current model capability;
it is not a validated conversion corridor.

|Point|betaM|Speed|Status|Residual norm|Condition number|Minimum margin|
|-|-:|-:|-|-:|-:|-:|
|B15_V010|15 deg|10 m/s|CREDIBLE|1.005e-9|68.763|0.2287|
|B15_V020|15 deg|20 m/s|CREDIBLE|4.493e-10|50.880|0.2128|
|B15_V030|15 deg|30 m/s|CREDIBLE|8.768e-10|48.496|0.2028|
|B45_V025|45 deg|25 m/s|CREDIBLE|2.575e-10|71.242|0.1036|
|B45_V035|45 deg|35 m/s|CREDIBLE|6.598e-10|69.160|0.0867|
|B45_V045|45 deg|45 m/s|CREDIBLE|1.219e-9|70.987|0.1197|
|B75_V040|75 deg|40 m/s|FAILED|4.603|144.51|at lower elevator bound|
|B75_V060|75 deg|60 m/s|FAILED|1.315|78.049|at lower elevator bound|
|B75_V080|75 deg|80 m/s|CREDIBLE|1.488e-9|30.234|0.2586|

The two failed points were retained. They were not repaired by changing
physical parameters, control bounds, or convergence tolerances.

## MATLAB evidence

- Pre-change MATLAB R2021a `run_all_checks`: 20/20 passed,
  `BASELINE_ELAPSED_S=249.297` (process wall time 316.4 s).
- Focused `check_berger13_formal_trim`: 9/9 passed, 64.458 s. The representative
  45 deg, 35 m/s point had dynamic residual norm `4.326e-10`, condition number
  `69.16`, and minimum variable margin `0.087`.
- PR2 nine-point database: 7 credible and 2 failed, 263.629 s; all credible
  residual records were finite and real.
- MATLAB `checkcode`: zero findings for all six initial PR2 files and zero for
  `build_berger13_pr2_database.m`.

- Post-change MATLAB R2021a `run_all_checks`: 21/21 passed,
  `FINAL_ALL_PASSED=1`, `FINAL_ELAPSED_S=310.327` (process wall time 319 s).
- Final all-file `checkcode`: zero findings across the seven modified or
  added MATLAB files.

The final head SHA is recorded in the Draft PR description after the
implementation commit exists.

## Claim boundary

Passing these checks establishes internal equilibrium, numerical consistency,
and traceable credibility classification only for the covered research grid.
It does not establish external validation, XV-15 parameter fidelity, Berger
51-state reproduction, or handling-quality compliance.
