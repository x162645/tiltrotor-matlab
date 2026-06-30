# NUAA vs Program Trend Comparison

This directory contains a visual comparison between the NUAA paper trim trend plots and the current program trend plots generated from existing CSV results only.

## Scope

- No trim was rerun.
- No model, parameter, control allocation, limit, trim strategy, or test logic was modified.
- The program curves were redrawn from the existing `20260625_eq12_13_16_angle_fix` CSV files.
- The compared program baseline predates the Eq.(17) wing slipstream replacement. It is an intermediate comparison result, not the final complete wing-slipstream baseline.

## Inputs Read

- `references/NUAA_main_paper.pdf`
  - Extracted raster crops from PDF page 10:
    - Figure 5(a): helicopter mode
    - Figure 5(b): flight mode
    - Figure 6(a): transition mode, nacelle tilt angle 15 deg
    - Figure 6(b): transition mode, nacelle tilt angle 75 deg
- `docs/validation/nuaa_trim_trends/20260625_eq12_13_16_angle_fix/nuaa_trim_points.csv`
  - 139 data rows, 34 columns.
- `docs/validation/nuaa_trim_trends/20260625_eq12_13_16_angle_fix/summary_figure/NUAA_TRIM_POINT_CLEAN.csv`
  - 100 data rows, 22 columns.
  - Used for the plotted program curves.
- `docs/validation/nuaa_trim_trends/20260625_eq12_13_16_angle_fix/summary_figure/NUAA_TRIM_POINT_SUMMARY.csv`
  - 4 data rows, 21 columns.

## Program Curves

The program plots use:

- Velocity: `V_mps`
- Collective: `collective_deg`
- Longitudinal cyclic / vertical pitch: `paperCyclic_deg`
- Elevator: `elevator_deg`
- Pitch angle: `theta_deg`

The horizontal speed ranges were matched to the corresponding NUAA paper modes:

- 0 deg helicopter mode: 0 to 30 m/s
- 15 deg transition mode: 10 to 60 m/s
- 75 deg transition mode: 70 to 150 m/s
- 90 deg flight mode: 70 to 150 m/s

## Qualitative Comparison

- 0 deg helicopter mode: collective trend agrees qualitatively; longitudinal cyclic / vertical-pitch amplitude trend is broadly consistent; pitch-angle direction is opposite.
- 15 deg transition mode: most trends agree qualitatively, but the program collective rises again at the high-speed end.
- 75 deg transition mode: overall qualitative agreement is good.
- 90 deg flight mode: overall qualitative agreement is good.

## Outputs

- `NUAA_vs_PROGRAM_TREND_COMPARISON.png`
- `NUAA_vs_PROGRAM_TREND_COMPARISON.pdf`

The overview figure is arranged as four mode blocks. In each block, the NUAA paper figure is directly above the current program plot.

## MATLAB Run Note

MATLAB R2021a wrote the PNG and PDF outputs successfully. The `-batch` process then emitted an R2021a shutdown-time `mwboost::archive::archive_exception` / `output stream error`. The generated PNG was visually inspected after export.
