# NUAA External Source Freeze Notes

## Purpose

This directory records source-freeze requirements for later NUAA Fig.5/Fig.6
trim-trend digitization. It is a provenance scaffold only. It is not validation,
does not compare curves, and does not change the model.

## Current Source Status

Known source currently in the repository:

| Source item | Status | Notes |
|-|-|-|
| `references/NUAA_main_paper.pdf` | Present | Project reference PDF. This scaffold does not parse it or extract data from it. |
| `drones-06-00092(1).pdf` | SOURCE_REQUIRED | Expected standalone file name is not present in this repository. |
| NUAA Fig.5/Fig.6 standalone images | SOURCE_REQUIRED | No committed extracted image files are present for the target figures. |
| NUAA Fig.5/Fig.6 digitized CSVs | SOURCE_REQUIRED | Only templates are provided in `validation/external_digitized_data/nuaa/templates/`. |

## Target Figures

| Figure | Intended future use | Source status |
|-|-|-|
| NUAA Fig.5(a) | Helicopter-mode trim trend digitization | SOURCE_REQUIRED |
| NUAA Fig.5(b) | Airplane-mode trim trend digitization | SOURCE_REQUIRED |
| NUAA Fig.6(a) | Transition trim trend, betaM=15 deg | SOURCE_REQUIRED |
| NUAA Fig.6(b) | Transition trim trend, betaM=75 deg | SOURCE_REQUIRED |

## Rules

- Do not use OCR-derived unreviewed data.
- Do not guess curve values.
- Do not commit undocumented manual points.
- Do not infer trend pass/fail labels from source-freeze artifacts.
- Do not treat digitized data as model agreement.
- Keep `SIGN_CONVENTION_REQUIRED` until the external nacelle-angle, control,
  and plotted-variable definitions are reviewed.

## Future Source Freeze Requirements

Each accepted source item should record:

- PDF filename.
- Page number.
- Figure number and subplot.
- Image extraction method.
- Digitization tool and version, if used.
- Operator.
- Date.
- Axis calibration points.
- Coordinate uncertainty.
- Review status and reviewer.

Trend comparison requires a separate PR after source images or reviewed
digitized CSVs are available.
