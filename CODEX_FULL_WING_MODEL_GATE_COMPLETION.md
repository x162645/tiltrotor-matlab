# FULL_WING_MODEL_GATE_COMPLETION

## Purpose

Continue PR #27 autonomously until the remaining PARTIAL gates have been either resolved with evidence or reduced to clearly documented, non-structural residual limitations. Do not stop to ask the project owner whether to accept the current PARTIAL state. The current state is not the user approval point.

## Immediate corrections from review

1. The NASA CR-114614 source is available now from the official NTRS page and direct PDF endpoint:

   - citation page: `https://ntrs.nasa.gov/citations/19730022217`
   - PDF: `https://ntrs.nasa.gov/api/citations/19730022217/downloads/19730022217.pdf`

   The PDF is 268 pages. The earlier 404 is not a continuing blocker. Download, verify, archive, and extract the rotor-wake/airframe interaction material.

2. `data/wing_full_angle/airfoils/naca64a223_surrogate.dat` is not an acceptable final NACA 64A223 geometry. The current generator explicitly uses a four-digit-like surrogate with `m=0.02`, `p=0.4`, and `t=0.23`. It must remain labeled provisional and must not support a final airfoil-geometry or XFOIL-data PASS.

3. All current XFOIL results and the selected full-angle database that depend on the surrogate geometry are provisional. Do not delete them; move or relabel them as `surrogate_v0` evidence, then regenerate the authoritative path after exact coordinates are obtained.

4. Current wake coverage is only a spanwise interval around `pivotY`. It does not yet implement the source-required dependence on rotor-axis direction, disk-to-wing distance, nacelle/conversion angle, wake angle, and sideslip. `WAKE_STRIP_MODEL = PASS` is therefore only an architecture smoke-test result. Upgrade the geometry before final PASS.

5. Current `wing_full_angle_lookup(alpha,P)` is one-dimensional. Current `wing_local_flow` does not use local Reynolds number or Mach number and applies legacy linear aileron increments outside the database. This does not yet satisfy the intended parameterized `Cl/Cd/Cm(alpha,Re,Mach,delta)` data law. Upgrade or explicitly justify a reduced-dimension production baseline with sensitivity evidence. Do not silently claim multidimensional use.

6. The current zero-nacelle bump comparison is valuable structural evidence, but it was generated with the surrogate airfoil and simplified wake geometry. Keep it as `PROVISIONAL_STRUCTURAL_PASS`; rerun after authoritative coordinates, reconstructed database, and corrected wake geometry.

## Stage A — acquire and extract CR-114614

Download the official PDF, validate `%PDF-`, page count, size, and SHA256, then add it under `references/wing_full_angle/`.

Extract and cite exact PDF and internal report pages for:

- coordinate systems and sign conventions;
- wing-pylon large-negative-angle lift and drag data;
- rotor-wake/wing interaction geometry;
- immersed-area calculation;
- local wake angle of attack;
- local dynamic pressure;
- wake radius/contraction assumptions;
- conversion-angle dependence;
- sideslip dependence;
- left/right wake treatment;
- equations and input-data tables used by the wake interaction model;
- Model 301-specific empirical constants that should not be copied into a generic model.

Update source manifests and `WAKE_SOURCE_TRACEABILITY`.

## Stage B — obtain authoritative NACA 64A223 coordinates

Use primary NASA/NACA sources and documented programs. At minimum examine:

1. NASA TM-X-3069 / Document ID `19740025318` — program to obtain NACA 6- and 6A-series ordinates.
2. NASA TM-4741 / Document ID `19970008124` — later NACA airfoil ordinate computer program.
3. NACA TR-903 / Document ID `19930091970` — theoretical and experimental 6A-series data.
4. NACA TN-4322 or NASA TR R-84 / Document IDs `19930085124` and `19980223594` — ordinate construction and cross-check data.

Implement or compile a traceable 6A-series generator from these sources. Preserve the original algorithm source or a line-by-line documented reimplementation.

For the NACA 64A223 designation, document the exact interpretation of series, design lift coefficient, camber-line definition, and 23-percent thickness. Do not reuse the four-digit thickness/camber formula.

Validate the generated coordinates by:

- reproducing one or more published NACA 6A-series ordinate tables from the same sources;
- reporting maximum and RMS ordinate error;
- checking point order, leading-edge closure, trailing-edge form, self-intersection, thickness ratio, thickness location, camber, and camber location;
- comparing against the TM-88373 section figure as a secondary shape check;
- XFOIL `LOAD` and `PANE` success.

If the exact XV-15 wing used a documented modified version, distinguish:

- exact standard NACA 64A223 used as the full-angle data-chain baseline;
- XV-15 modified implementation geometry, if available.

The project does not require exact XV-15 reproduction. A traceable standard NACA 64A223 is acceptable for the baseline if the modification is not needed for the selected data chain.

Gate target: `AIRFOIL_GEOMETRY = PASS`.

## Stage C — regenerate XFOIL data

After authoritative coordinates pass:

- archive existing surrogate runs under an explicitly provisional path;
- regenerate clean polars for the existing Re/Mach matrix;
- run positive and negative sweeps separately;
- preserve convergence status and retry history;
- compare authoritative-coordinate results against surrogate results;
- update all plots, manifests, hashes, and reports.

Control-surface path:

- derive the plain-flap hinge location and definition from TM-88373;
- use a traceable geometry transformation or XFOIL `GDES/FLAP` procedure;
- validate the transformed geometry before viscous runs;
- run the flap cases that XFOIL can physically and numerically support;
- do not force convergence at extreme deflections;
- use TM-88373 experimental data as the primary high-deflection/high-angle source;
- record unsupported XFOIL cases as out-of-method rather than fabricated failures.

A final PASS does not require XFOIL to predict deep-separated 60-degree-flap flow. It requires an honest, validated division of responsibility between XFOIL and experiment.

## Stage D — full TM-88373 digitization

Replace anchor-only use with curve-level digitization for the configurations actually used by the database.

At minimum digitize:

- `CL(alpha)`;
- `CD(alpha)`;
- `Cm(alpha)`;
- the selected clean or baseline configuration;
- the flap configuration closest to the production control-surface geometry;
- alpha approximately `-75 deg` to `-105 deg`;
- relevant Reynolds-sensitivity curves;
- documented discontinuity/hysteresis regions.

For every curve save:

- page image;
- axes calibration;
- selected points;
- CSV;
- overlay;
- repeated independent digitization;
- RMS and maximum repeat difference;
- uncertainty estimate;
- notes on multivalued or unstable regions.

Do not smooth away physical discontinuities.

Gate target: `TM88373_DIGITIZATION = PASS` for the configurations actually used in the selected database. It is not necessary to digitize every figure in the report.

## Stage E — rebuild the full-angle database

Rebuild from:

- authoritative-coordinate XFOIL data in its reliable range;
- digitized TM-88373 data in its valid near-vertical range;
- explicit, source-tagged bridge models only in data gaps;
- periodic closure with documented physical assumptions.

The current approximate hard-coded anchors and mirrored positive-deep-stall extension must be treated as provisional. Compare at least the already required bridge candidates and select by continuity, bounded slope, physical asymptotes, and minimal unsupported behavior.

For `Cm`, use the digitized quarter-chord data and constrained gap interpolation. Keep untested positive deep-stall behavior clearly classified.

Upgrade the runtime database schema to preserve, at minimum:

- alpha;
- Reynolds number or Reynolds-bin metadata;
- Mach number or Mach-bin metadata;
- control-surface configuration metadata;
- source class and validity range.

The runtime lookup may use a reduced baseline slice only if sensitivity checks show the neglected dimensions are immaterial over the intended first-use envelope. In that case the API and reports must state the reduction explicitly. Otherwise implement multidimensional interpolation.

Gate targets:

- `XFOIL_LOW_ANGLE_DATA = PASS`;
- `POST_STALL_EXTENSION = PASS`;
- `CM_EXTENSION = PASS or PARTIAL only for explicitly untested positive deep-stall intervals`;
- `FULL_ANGLE_DATABASE = PASS`.

## Stage F — upgrade wake geometry and strip model

Replace the span-only interval model with a parameterized geometry that uses:

- rotor hub position;
- rotor axis direction from nacelle/conversion angle;
- disk-to-wing relative position;
- wake centerline propagation to the wing plane;
- wake radius/contraction at the wing plane;
- sideslip and local wake angle where supported;
- left/right wakes separately;
- true strip-area coverage or a convergence-proven geometric approximation.

Use the current rotor-model induced velocity when compatible, but distinguish magnitude, direction, and spatial distribution assumptions.

Add tests showing:

- coverage changes correctly with nacelle angle;
- coverage changes correctly with rotor/wing vertical separation;
- sideslip/asymmetry behavior is physically consistent;
- zero/full/partial coverage limits are continuous;
- no double-counted overlap;
- covered area never exceeds total area;
- grid refinement converges;
- CR-176970 download calculation is reproduced within documented tolerance;
- CR-114614 equations/geometry are reflected or explicitly rejected with reasons.

Only then promote `WAKE_STRIP_MODEL` and `WAKE_SOURCE_TRACEABILITY` to PASS.

## Stage G — production and GUI correction

Keep the legacy default unchanged.

Update the new production path so that:

- local flow calculates alpha, Reynolds number, Mach number, and control-surface state;
- the lookup receives the dimensions actually represented by the selected database;
- legacy linear aileron increments are not silently mixed into a supposedly database-driven control-surface model;
- any retained linear lateral correction is separately named, sourced, and tested;
- source/database version hashes are exposed in diagnostics;
- missing or out-of-range data produce explicit diagnostics, not hidden extrapolation.

Update GUI labels and parameter validation only as required by the corrected model. Do not expose unsupported options as if validated.

## Stage H — rerun validation

After all corrections, rerun:

- authoritative-coordinate XFOIL checks;
- full-angle continuity and derivative checks;
- wake geometry and grid-convergence tests;
- exact legacy identity;
- focused new-model physics tests;
- 0-degree nacelle sweep;
- helicopter, conversion, and airplane representative trims;
- NUAA trend diagnostics;
- linearization smoke tests;
- GUI catalog/service tests;
- `run_all_checks`.

The prior MATLAB results may be cited as historical evidence, but final gates require a fresh run against the corrected HEAD. A prior platform usage limit is not an engineering acceptance result. Retry in the continuing Codex session or a fresh Codex execution environment.

Reclassify the 0-degree result:

- current result: `PROVISIONAL_STRUCTURAL_PASS`;
- final result: PASS only after corrected data and wake geometry reproduce the removal without unrelated parameter tuning.

## Stage I — final reporting and PR update

Update all reports and PR #27 body. Do not create a second PR.

Report:

- exact coordinate source and validation errors;
- surrogate-vs-authoritative XFOIL differences;
- TM digitization uncertainty;
- CR-114614 extraction and adopted/rejected terms;
- final database dimensions and source regions;
- wake geometry equations;
- final MATLAB commands and runtimes;
- legacy identity;
- final bump metrics;
- all gate statuses.

Keep the PR draft and unmerged. Keep the legacy model as default.

## Stop and approval rule

Do not ask the user whether to accept the present PARTIAL gate. Continue automatically.

Ask the user only after the corrected final gate is complete and the only remaining action is one of:

- switch the default model;
- merge the PR;
- choose between two physically different, equally supported model structures that evidence and tests cannot distinguish.
