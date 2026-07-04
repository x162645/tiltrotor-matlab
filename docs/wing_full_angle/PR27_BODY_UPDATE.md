# PR #27 Body Update

Status: keep this PR open, Draft, and unmerged.

## Owner-Facing Conclusion

可以保留为 Draft 的有限包线研究模型

Recommendation: continue to keep the PR as Draft; do not merge; do not switch the default model.

## Current Gate

`FULL_WING_MODEL_GATE = READY_FOR_LIMITED_ENVELOPE_USE`

Reasons this is not ready to merge or become default:

- `CONTROL_SURFACE_GATE = PARTIAL`; no validated differential aileron aero model was added.
- `BRIDGE_MODEL_GATE = ENVELOPE_PASS`; deep-stall bridge rows remain unvalidated.
- `WAKE_GEOMETRY_GATE = ENVELOPE_PASS`; wake contraction remains an engineering assumption.
- Legacy remains the default model.

## Evidence Summary

- Trim envelope: 84 attempted, 84 completed, 84 converged, 0 timeout, 0 failed, 0 placeholder rows.
- Legacy identity: PASS, max force error 0.000e+00, max moment error 0.000e+00.
- Full-angle opt-in: common coefficient law 1, complete-result branch blend removed 1, branchWeightInNew 0.
- Requested MATLAB checks all passed: 1.

## Owner Review Packet

`docs/wing_full_angle/OWNER_REVIEW_PACKET.md`

## NUAA Trim Trend Visual Overlay

Conclusion: `VISUAL_OVERLAY_READY_FOR_OWNER_REVIEW`.

- NUAA Fig.5(a), Fig.5(b), Fig.6(a), and Fig.6(b) were used as screenshot references only.
- No NUAA curve digitization and no pointwise NUAA-model error calculation were performed.
- Existing legacy/full_angle trim envelope results were reused; no parameter tuning was performed.
- Legacy remains the default model; this PR remains Draft and unmerged.

Report: `docs/wing_full_angle/NUAA_TRIM_TREND_VISUAL_OVERLAY_REPORT.md`

Regression checks:

- `check_wing_legacy_identity`: PASS.
- `run_full_angle_zero_nacelle_validation`: PASS.
- `check_article_trends`: diagnostic run completed; not a strict reproduction proof.
- `run_all_checks`: PASS, 33/33 checks passed.
