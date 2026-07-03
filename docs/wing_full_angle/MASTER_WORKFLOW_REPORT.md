# Full-Angle Wing Autonomous Workflow Report

Branch: `task/full-wing-model-autonomous-20260702`

Draft PR: #27

## Implemented

- Isolated worktree continued at `E:\tiltrotor-full-wing-model`.
- Legacy wing model remains preserved and default.
- New full-angle model remains opt-in and parallel under `model/wing/`.
- Local reference ZIP was verified and source manifests were updated.
- Standard NACA 64A223 coordinates were generated from a traceable NACA 6A route.
- Formal clean XFOIL grid was regenerated on the standard coordinates.
- TM-88373 selected curves were converted into auditable text-constrained digitization artifacts with rendered source pages, CSV, overlays, repeat digitization and uncertainty.
- A multidimensional full-angle database was rebuilt: `CL/CD/Cm(alpha,Re,Mach,flapDeg)`.
- The production lookup now interpolates continuously across Re, Mach and symmetric plain-flap dimensions.
- CR-114614 wake terms and CR-176970 strip-method evidence were mapped to the production wake geometry.
- The full-angle path uses one coefficient lookup for free-stream and wake strip portions.
- The full-angle path explicitly does not claim validated differential aileron aerodynamics.
- GUI parameter integration and project services remain compatible.

## Validation

- `run_all_checks`: 23/23 PASS.
- Legacy identity: PASS, exact force/moment identity.
- Formal XFOIL accepted rows: 305 raw accepted rows, 299 unique condition-alpha cells, 7 tagged database fill rows.
- Database checks: PASS, 10830 rows, max adjacent L1 jump 0.116990.
- Bridge candidate audit: material differences remain in unsupported deep-stall intervals.
- Wake strip focused check: PASS for software geometry; contraction remains assumed.
- 0-deg nacelle formal sweep: legacy and full-angle both 21/21 converged; `branchWeightInNew = 0`.
- GUI checks: catalog, modified IDs, parameter page and services all PASS.

## Scope Statements

- The model claims standard NACA 64A223, not the unrecovered XV-15 modified airfoil.
- The CR-114614 artifact is a verified local technical extract, not the 268-page original facsimile.
- TM-88373 selected curves are text-constrained; full graphical point-picking is not claimed.
- Positive deep-stall rows are present for full-angle closure and are explicitly tagged unvalidated.
- The wake model is a source-traced strip projection, not a free-wake or CFD method.
- The database plain-flap dimension is not a differential aileron validation.

## Gate

`FULL_WING_MODEL_GATE = READY_FOR_LIMITED_ENVELOPE_USE`

The branch is suitable for limited-envelope opt-in review with legacy still default. It has not reached the point where the only remaining action is to switch the default and merge.
