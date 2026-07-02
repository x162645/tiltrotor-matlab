# Airfoil Selection and XFOIL Report

Selected airfoil label: NACA 64A223.

Selection basis: it is the candidate tied to the TM-88373 near-vertical wing source chain and has stronger tiltrotor relevance than generic NACA 23012. The exact original 6-series coordinate definition was not recovered in this autonomous pass, so the generated geometry is marked SURROGATE_PARTIAL.

## Candidate Scores

See data/wing_full_angle/airfoil_candidate_scores.csv.

- NACA 64A223: coordinate traceability 2, low-angle calculability 4, full-angle evidence 4, near-90 evidence 5, tiltrotor relevance 5.
- NACA 23012: coordinate traceability 4, low-angle calculability 4, full-angle evidence 2, near-90 evidence 1, tiltrotor relevance 2.

## XFOIL Results

Clean-airfoil XFOIL ran for Re = 0.6e6, 1.0e6, 1.4e6 and Mach = 0, 0.10.

Accepted points: 49, 50, 51, 50, 49, 48; total 297.

Flap deflections 20, 40, 50 and 60 deg are recorded as NOT_ATTEMPTED_GEOMETRY_ROUTE_UNVERIFIED. This avoids inventing a flap-hinge geometry path.

Figure: docs/wing_full_angle/figures/xfoil_clean_cl_grid.png.
