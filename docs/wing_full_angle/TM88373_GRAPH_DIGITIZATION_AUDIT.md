# TM-88373 Figure 6a Graph Digitization Audit

Date: 2026-07-03

Source: `references/wing_full_angle/NASA_TM_88373.pdf`, PDF page 32, original page 28, Figure 6a.

Configuration: basic leading edge, 30% chord plain flap, configuration b. The report defines flap chord ratio by overall flap length.

Flow state: angles of attack near -90 deg, alpha referenced to chord line; nominal Re about 1.0e6. Moment coefficient is about the quarter chord.

Artifacts:

- Source page: `data/wing_full_angle/tm88373_digitized/source_pages/NASA_TM_88373_pdf_page32_figure6a_300dpi.png`
- Crops: `data/wing_full_angle/tm88373_digitized/crops/`
- Axis calibration: `data/wing_full_angle/tm88373_digitized/tm88373_figure6a_axis_calibration.json`
- Pass 1 CSV: `data/wing_full_angle/tm88373_digitized/tm88373_figure6a_graph_digitization_pass1.csv`
- Pass 2 CSV: `data/wing_full_angle/tm88373_digitized/tm88373_figure6a_graph_digitization_pass2.csv`
- Overlay: `data/wing_full_angle/tm88373_digitized/overlays/tm88373_figure6a_digitized_points_overlay.png`
- Repeat statistics: `data/wing_full_angle/tm88373_digitized/tm88373_digitization_uncertainty_summary.csv`

Known limitations:

- The scan is low-resolution and marker centers were selected manually from rendered graph images.
- No smoothing was used; visible local drag changes are retained.
- The production wing path currently queries flapDeg=0. Other Figure 6a flap curves support the symmetric plain-flap database dimension and sensitivity checks, not differential aileron aerodynamics.
