# Full-Angle Wing Data Requirement Freeze

Task branch: task/full-wing-model-autonomous-20260702

## Required Data

| Item | Status | Source/Artifact | Notes |
|---|---|---|---|
| Protected legacy baseline manifest | PASS | data/wing_full_angle/protected_baseline_manifest.csv | SHA256 and sizes captured before production edits. |
| TM-88373 near-vertical wing evidence | PARTIAL | references/wing_full_angle/NASA_TM_88373.pdf; data/wing_full_angle/initial_source_anchors.csv | Used as anchor data only; no claim of full-curve OCR recovery. |
| CR-176970 wake method source | PASS | references/wing_full_angle/NASA_CR_176970.pdf | Downloaded and retained for wake-method audit trail. |
| CR-114614 wake source | PARTIAL | data/wing_full_angle/download_manifest_stage2.csv | NTRS direct PDF endpoint returned 404 during retries. |
| Airfoil coordinates | PARTIAL | data/wing_full_angle/airfoils/naca64a223_surrogate.dat | Surrogate NACA 64A223 geometry generated from explicit assumptions; not exact 6-series coordinates. |
| XFOIL clean-airfoil grid | PASS | data/wing_full_angle/xfoil/parsed/xfoil_clean_polars.csv | 297 accepted clean-airfoil points. |
| Flap XFOIL grid | PARTIAL | data/wing_full_angle/xfoil/xfoil_attempt_manifest.csv | Flap cases not attempted because geometry/flap hinge route was not verified. |
| Full-angle coefficient database | PARTIAL | data/wing_full_angle/full_angle_selected/wing_full_angle_database.csv | Continuous database built from XFOIL, anchors, mirrored/bridged extension. |
| Default production selector | PASS | params_nominal.m | P.wing.fullAngleModelEnabled = 0 keeps legacy default. |

No unsupported value in this task should be treated as XV-15 measured data.
