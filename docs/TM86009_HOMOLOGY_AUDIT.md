# NASA TM-86009 XV-15 dynamic-validation homology audit

## Purpose

This document is a validation gate for the frozen production low-order model M0. It does not claim that an XV-15 dynamic-validation case is already homologous. Quantitative comparison is prohibited until the corresponding row in `results/xv15_validation_baseline/TM86009_HOMOLOGY_MATRIX.csv` reaches `HIGH` after report-level source audit.

## Source identity

- Report: NASA-TM-86009 / A-9851 / TM-84-A-6.
- Title: *Identification and Verification of Frequency-Domain Models for XV-15 Tilt-Rotor Aircraft Dynamics*.
- Authors: Mark B. Tischler, Joseph G. M. Leung, and Daniel C. Dugan.
- Publication: August 1984.
- NTRS document ID: 19840026374.

The accessible NASA NTRS metadata/abstract establishes that frequency-domain methods were applied to XV-15 flight-test data in cruise at 170 knots, that transfer-function forms were fitted to the extracted frequency responses, and that time-domain step-response matching was used for cruise and hover flight conditions. It also identifies unmodeled rotor-RPM dynamics as a likely cause of at least one cruise response discrepancy.

Current evidence level in this audit is `NTRS_METADATA_ABSTRACT_PLUS_REPORT_LEVEL_DETAIL_PENDING`. No page/table/figure-specific claim is treated as closed yet.

## Why rotor RPM and the control chain are validation gates

TM-86009 is not automatically homologous to the repository simply because both describe XV-15 dynamics. A measured flight-test frequency response is defined by the exact experimental input and output signals. If the report input is upstream of actuators, mixers, swashplate/control-surface dynamics, RPM governor dynamics, or other control-system elements that are absent from M0, then comparing that response directly with an M0 B-column or direct-control step response mixes aircraft-dynamics error with input-chain error.

Rotor-RPM/governor treatment receives an explicit gate because the NTRS abstract itself attributes a reported discrepancy to unmodeled rotor-RPM dynamics. The baseline study must therefore establish whether RPM was effectively fixed, measured and reproduced as an exogenous schedule, or dynamically coupled to the tested response before accepting a quantitative comparison.

## Required homology fields

Every candidate case must freeze the following before a `HIGH` classification is permitted:

1. flight regime and true/equivalent airspeed definition;
2. altitude, atmospheric state, and density;
3. nacelle angle/conversion state;
4. rotor RPM and governor behavior;
5. aircraft mass/weight;
6. center of gravity;
7. inertia tensor or sufficient matched mass-property definition;
8. trim state and steady controls;
9. exact excitation signal and where it is measured in the control chain;
10. actuator, mixer, swashplate, control-surface, and augmentation-system participation;
11. exact response signal;
12. axes, signs, units, and attitude/rate conventions;
13. filtering, differentiation/integration, time alignment, and signal conditioning;
14. frequency-response estimator definition and coherence/usable bandwidth when applicable;
15. exact valid frequency interval for any gain/phase error metric.

## Classification rule

- `HIGH`: test condition and input/output chain are sufficiently matched for quantitative gain/phase or time-history error metrics.
- `MEDIUM`: a limited comparison is defensible, but a known unresolved mismatch affects magnitude/phase; use for trends or bounded claims only.
- `LOW`: material configuration or signal-chain mismatch prevents a quantitative M0 validation claim.
- `INVALID`: the source quantity is not a homologous observable for the requested comparison.
- `PENDING_REPORT_LEVEL_SOURCE_AUDIT`: accessible evidence is not yet sufficient to assign one of the above classes.

No row is currently assigned `HIGH` merely from the NTRS abstract.

## Program-side gate

The repository already contains useful dynamic-analysis infrastructure: a nine-state body-dynamics interface, a thirteen-state nacelle-dynamics extension, symmetric trim, boundary-aware numerical linearization, and direct-control step-response simulation. Their existence is not evidence of experimental homology. `TM86009_PROGRAM_CAPABILITY_MAPPING.csv` records which pieces can be reused and which experimental adapters remain unresolved.

The 13-state command interface currently exposes collective, differential collective, longitudinal cyclic, differential longitudinal cyclic, lateral cyclic, aileron, elevator, rudder, and left/right nacelle-angle commands. These program inputs must not be silently equated to the TM-86009 excitation channels until the report-level signal definition is verified.

## Validation rule after the audit

For each `HIGH` case:

1. map only independently sourced XV-15 configuration and condition data into fields already consumed by the frozen M0 model;
2. obtain the matched trim without fitting to the measured dynamic response;
3. linearize M0 at the matched operating point;
4. construct the exact experimental input/output transfer path, adding only coordinate/unit/signal-definition adapters that do not introduce new aircraft physics;
5. compare over the source-supported frequency band or time window;
6. report gain error, phase error, modal quantities, and/or time-domain residuals together with the case homology record;
7. retain poor agreement as a validation result rather than changing M0 to reduce the error.

If no candidate reaches `HIGH`, the correct conclusion is that currently audited public evidence is insufficient for strict quantitative TM-86009/M0 dynamic validation. A forced comparison is not permitted.
