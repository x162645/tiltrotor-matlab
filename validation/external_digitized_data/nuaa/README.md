# NUAA Digitized Data Scaffold

## Purpose

This directory is reserved for manually reviewed NUAA Fig.5/Fig.6 digitized CSV
data. The current commit provides templates only. It does not contain real
digitized figure values, does not compare curves, and is not validation.

## Template Files

Templates live in `validation/external_digitized_data/nuaa/templates/`:

- `nuaa_fig5a_helicopter_trim_template.csv`
- `nuaa_fig5b_airplane_trim_template.csv`
- `nuaa_fig6a_transition_15deg_trim_template.csv`
- `nuaa_fig6b_transition_75deg_trim_template.csv`

Future reviewed data files should use names such as:

- `nuaa_fig5a_helicopter_trim_digitized_v1.csv`
- `nuaa_fig5b_airplane_trim_digitized_v1.csv`
- `nuaa_fig6a_transition_15deg_trim_digitized_v1.csv`
- `nuaa_fig6b_transition_75deg_trim_digitized_v1.csv`

## CSV Schema

| Column | Meaning |
|-|-|
| `source_id` | Identifier matching the provenance record. |
| `paper` | Source paper label or filename. |
| `figure` | Figure ID, for example `NUAA_FIG5A`. |
| `subplot` | Subplot label, for example `a` or `b`. |
| `mode` | Source-defined mode label such as helicopter, airplane, or transition. |
| `betaM_deg` | Source-defined nacelle angle in degrees, if known. |
| `airspeed_mps` | Airspeed converted to m/s only after source units are recorded. |
| `external_variable` | Source plotted variable name. |
| `external_value` | Digitized source value in `external_unit`. |
| `external_unit` | Raw source unit for `external_value`. |
| `digitized_from` | Source image or PDF/page reference used for digitization. |
| `digitizer` | Operator or tool label. |
| `digitized_date` | Date of digitization. |
| `axis_x_label` | Source x-axis label as reviewed. |
| `axis_y_label` | Source y-axis label as reviewed. |
| `sign_convention_status` | Explicit sign status, normally `SIGN_CONVENTION_REQUIRED` until reviewed. |
| `unit_conversion_status` | Explicit unit status, for example `SOURCE_UNIT_RECORDED` or `CONVERSION_REVIEWED`. |
| `notes` | Free-form provenance or ambiguity notes. |

## Data Quality Requirements

- `source_id` must match a provenance entry.
- Unit conversion must be explicit and must not overwrite the raw source unit.
- Sign convention status must be explicit.
- Raw digitized data must not include pass/fail labels.
- `vertical_pitch` is source-defined until a later sign audit maps it to an
  internal control; do not directly equate it with `cyclicLong`.
- Templates contain no guessed values.

## Accepted External Variables

Future CSVs may use source-confirmed variables such as:

- `collective`
- `vertical_pitch`
- `cyclicLong`
- `cyclic_equivalent`
- `pitch_attitude`
- `elevator`
- `other_plotted_variable`

Use `other_plotted_variable` when the source label is known but not yet mapped
to an internal variable.
