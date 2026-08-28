# NASA TM-86009 XV-15 dynamic-validation homology audit

## Purpose

This document is the evidence gate for dynamic validation of the frozen production low-order model M0. The purpose is not to force a comparison with every published XV-15 response, but to determine whether a report case is sufficiently homologous to M0 for a defensible quantitative validation claim.

Quantitative dynamic validation remains prohibited unless a row in `results/xv15_validation_baseline/TM86009_HOMOLOGY_MATRIX.csv` reaches `HIGH` and explicitly allows `QUANTITATIVE_DYNAMIC_VALIDATION`.

## Source identity

- Report: NASA-TM-86009 / A-9851 / TM-84-A-6.
- Title: *Identification and Verification of Frequency-Domain Models for XV-15 Tilt-Rotor Aircraft Dynamics*.
- Authors: Mark B. Tischler, Joseph G. M. Leung, and Daniel C. Dugan.
- Publication: August 1984.
- NTRS document ID: 19840026374.
- Report-level audit copy: Tenth European Rotorcraft Forum Paper No. 75, same title/authors, 1984.

The report was audited at report level rather than from metadata alone. Page references below use the ERF paper pagination shown as 75-x in the report.

## Closed report-level facts

### Flight condition

Section 3, page 75-4, states the cruise identification condition as:

- indicated airspeed: 170 knots;
- nacelle incidence: 0 deg;
- altitude: 8000 ft.

The same section identifies the primary bare-airframe cruise responses as:

- `q/delta_e`: pitch-rate response to elevator surface deflection;
- `az/delta_e`: normal-acceleration response to elevator surface deflection;
- `p/delta_a`: roll-rate response to aileron surface deflection;
- `beta_cg/delta_r`: sideslip at aircraft CG response to rudder surface deflection.

### Excitation and usable frequency range

Section 2, page 75-2, states that the pilot-generated frequency sweep excites approximately 0.2-6.0 rad/s. Each run begins at trim, includes two approximately 20 s low-frequency cycles, then increases to about 6 rad/s, with an overall duration of approximately 90 s. Repeat runs are concatenated to reduce random-noise effects.

For `q/delta_e`, pages 75-5 through 75-8 show strong coherence over the principal frequency range. The report fits the pitch response over approximately 0.3-10 rad/s, but the commanded sweep range is approximately 0.2-6 rad/s. For repository validation, 0.3-6 rad/s is therefore retained as a conservative overlap range unless a later source provides stronger case-specific evidence.

### Experimental input definition

Page 75-2 explicitly defines the open-loop transfer-function input as the measured **surface deflection**, not merely the pilot stick command. For the longitudinal case, total elevator surface deflection contains both pilot input and SCAS-feedback contributions. Page 75-4 states that elevator surface deflection was measured directly and that longitudinal cruise testing was conducted with SCAS engaged.

For the lateral-directional case, page 75-2 states that correlated SCAS rudder activity prevented the desired SISO extraction from the initial closed-loop runs. The lateral-directional tests were therefore repeated with SCAS disengaged.

This is a major homology improvement relative to the previous metadata-only audit because the repository must compare the report to a surface-deflection input path, not silently equate the experiment to a pilot-command input.

### Output definitions and processing

The report gives the following additional information relevant to adapters:

- page 75-4 reports a regular elevator surface amplitude of approximately 2 deg during the cruise sweeps;
- page 75-4 states that the displayed pitch-rate signal used a 2.5 Hz low-pass filter for presentation only;
- page 75-7 defines `az` as positive downward and uses units of `g/deg-elevator` for the acceleration transfer function;
- page 75-9 states that the sideslip sensor is located approximately 18 ft ahead of the aircraft CG and that `beta_cg` is obtained by correcting the measured signal using yaw rate and airspeed; sensor-dynamics correction was not applied because it was considered insignificant within the identification bandwidth.

These definitions must be reproduced by coordinate/unit/signal adapters before any comparison is promoted beyond a bounded correlation.

### Rotor-RPM limitation identified by the source

Pages 75-8 and 75-16 explicitly identify unmodeled rotor-RPM dynamics as a probable contributor to the cruise normal-acceleration/elevator mismatch. Page 75-8 also mentions rotor inflow dynamics as a possible contributor above approximately 2 rad/s.

This is not permission to add RPM or inflow dynamics to M0 during validation. For the frozen-model study it is evidence that `az/delta_e` has a known model-form/input-chain mismatch and should receive a lower homology rating unless the experiment's RPM behavior can be reproduced without altering M0 physics.

## Evidence still missing for strict matched-condition validation

The audited TM-86009 report does not close the following quantities for the exact tested records:

1. exact test mass or gross weight for the identified cruise records;
2. exact center of gravity;
3. exact inertia tensor;
4. exact rotor RPM for the test records;
5. governor/RPM dynamic behavior or a measured RPM time history suitable for an exogenous adapter;
6. test-day atmospheric density/temperature beyond the reported altitude;
7. a complete sign/axis conversion from the report channels to the repository channels;
8. machine-readable raw flight-test frequency-response/time-history data.

Generic XV-15 design mass, CG, inertia, or RPM values from other documents must not be substituted and relabeled as the TM-86009 test condition unless an explicit same-record provenance link is established.

## Current classification

The report-level audit now supports the following classifications:

- `q/delta_e` in cruise: **MEDIUM**. The flight condition, surface-deflection input, output channel, SCAS context, and conservative frequency range are known, but exact loading, inertia, density, RPM/governor state, and repository sign mapping remain unresolved.
- `az/delta_e` in cruise: **LOW**. In addition to the unresolved matched-condition data, the source itself identifies RPM/inflow dynamics as a material explanation of the observed high-frequency discrepancy.
- `p/delta_a` in cruise: **MEDIUM**. The lateral-directional test was repeated with SCAS disengaged and the surface input/output relation is identifiable, but exact loading/RPM/atmosphere and program-axis mapping remain unresolved.
- `beta_cg/delta_r` in cruise: **MEDIUM**. The source defines the CG sideslip reconstruction, but the same matched-condition gaps remain and a sensor-to-program adapter still requires an explicit audit.
- published cruise step-response plots: **MEDIUM as plot-level correlation evidence only**, not strict quantitative M0 validation, because the raw matched input/output records and full loading state are not published in machine-readable form in TM-86009.
- hover step-response material summarized in TM-86009: **PENDING**, because the detailed hover identification case is delegated to Ref. 3 and has not yet been closed in this branch.

No audited TM-86009 case is currently `HIGH`.

## Consequence for the present study

The correct current conclusion is therefore:

> TM-86009 is a strong external flight-test source for identifying candidate XV-15 dynamic observables and for bounded trend/model-form comparisons, but the currently audited public evidence does not yet support a strict matched-condition quantitative dynamic validation of frozen M0.

This is an evidence limitation, not a reason to alter the production model or to fill missing test-condition data with generic XV-15 values.

## Program-side gate

The repository already contains useful dynamic-analysis infrastructure: nine-state body dynamics, a thirteen-state nacelle extension, symmetric trim, boundary-aware numerical linearization, modal utilities, and direct-control time-response simulation. Their existence is not evidence of experimental homology.

`TM86009_PROGRAM_CAPABILITY_MAPPING.csv` records the reusable program elements and the remaining adapters. In particular, the repository command interface must not be equated to pilot stick inputs because TM-86009's identified open-loop cruise responses use measured surface deflections.

## Validation rule if a future HIGH case is established

For each future `HIGH` case:

1. map only independently sourced XV-15 configuration and matched-condition quantities into fields already consumed by frozen M0;
2. obtain the matched trim without fitting to measured dynamic response data;
3. linearize M0 at the matched operating point;
4. construct the exact experimental input/output path using only coordinate, unit, and signal-definition adapters that introduce no new aircraft physics;
5. compare only over the source-supported frequency/time interval;
6. report gain, phase, modal, and/or time-domain residuals together with the homology record;
7. retain poor agreement as a validation result and do not modify M0 to reduce the error.

If no case reaches `HIGH`, the dynamic-validation stage must remain blocked and the insufficiency of matched public evidence must be reported explicitly.
