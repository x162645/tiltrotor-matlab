# PR #7 Parameter Classification Correction

## Status

Active documentation-only correction on branch `audit/parameter-source-inventory`.

This task preserves the existing 174-item inventory, gap analysis, source-page findings, and code-use tracing. It corrects the classification model that currently mixes two different questions:

1. where the current conceptual-model value actually came from; and
2. what primary evidence describes a future XV-15 target value or configuration.

NASA or other XV-15 documents may support an XV-15 target value, relation, configuration, or conflict. They do not prove the historical provenance of the current conceptual value unless repository history explicitly shows that the current value was entered from that source.

## Allowed files

Only modify:

- `CODEX_TASK.md`
- `docs/PARAMETER_SOURCE_INVENTORY.md`
- `docs/PARAMETER_GAP_REGISTER.md`
- `docs/PARAMETER_SOURCE_WORKPLAN.md`
- this document only if a clarification is required

Do not create parameter files, data directories, MATLAB files, or tests.

## Forbidden actions

- no MATLAB execution;
- no trim, continuation, Jacobian, or linearization runs;
- no production-code changes;
- no parameter-value changes;
- no test changes;
- no threshold, tolerance, limit, solver, or control-mapping changes;
- no complete rescan or redigitization of the PDF collection;
- no PR merge.

## 1. Correct `PARAMETER_SOURCE_INVENTORY.md`

Preserve all existing 174 entries and their IDs. Do not delete or renumber entries and do not rebuild the inventory from scratch.

Replace the single mixed source/severity structure with separate current-model and XV-15-target layers. Each row must include at least:

```text
ID
parameter / constant
current value or expression
SI unit
category
physical or numerical
consumer files/functions
current model provenance
current provenance evidence
current provenance location
current interpretation
XV-15 target evidence status
XV-15 target source
XV-15 exact page/table/figure/equation
XV-15 target value or relation
XV-15 comparison status
future source required
current concept-model risk
XV-15 reproduction blocker
confidence
notes
```

### Current-model provenance vocabulary

Use exactly:

- `DOCUMENTED_PROJECT_SOURCE`
- `DERIVED`
- `ASSUMED_CONCEPT`
- `NUMERICAL`
- `AMBIGUOUS_COUPLED`
- `DEPRECATED_UNUSED`
- `UNRESOLVED`

Interpretation:

- `DOCUMENTED_PROJECT_SOURCE`: repository history, original project documentation, or explicit historical evidence proves that the current value was entered from a named source;
- `DERIVED`: current value is calculated from current parent parameters; list formula and parent IDs;
- `ASSUMED_CONCEPT`: current value is a conceptual modeling choice with no evidence of historical derivation from a particular aircraft source;
- `NUMERICAL`: solver, discretization, tolerance, regularization, reporting, or test setting;
- `AMBIGUOUS_COUPLED`: one field carries two or more physical meanings;
- `DEPRECATED_UNUSED`: retained for compatibility and proven unused by production paths;
- `UNRESOLVED`: current meaning or historical provenance cannot be classified safely.

### XV-15 target-evidence vocabulary

Use exactly:

- `DOCUMENTED_PRIMARY`
- `DOCUMENTED_SECONDARY`
- `CANDIDATE_PRIMARY`
- `REFERENCE_PENDING`
- `NOT_APPLICABLE`
- `UNRESOLVED`

### XV-15 comparison vocabulary

Use exactly:

- `EXACT_MATCH`
- `APPROXIMATE_MATCH`
- `NUMERIC_CONFLICT`
- `CONFIGURATION_DEPENDENT`
- `REPRESENTATION_INCOMPATIBLE`
- `NO_TARGET_VALUE`
- `NOT_APPLICABLE`
- `UNRESOLVED`

### Required example corrections

#### `P.rotor.Nb = 3`

Unless repository history proves direct sourcing:

```text
current model provenance = ASSUMED_CONCEPT
XV-15 target evidence status = DOCUMENTED_PRIMARY
XV-15 comparison status = EXACT_MATCH
```

#### `P.rotor.R = 3.80 m`

The cited 25 ft diameter corresponds to a 3.81 m radius. Treat the NASA value as XV-15 target evidence only:

```text
current model provenance = ASSUMED_CONCEPT
XV-15 target value = 3.81 m
XV-15 comparison status = APPROXIMATE_MATCH or NUMERIC_CONFLICT
```

Do not use the 25 ft source to prove the historical provenance of the current 3.80 m value.

#### `P.rotor.chord = 0.38 m`

The cited 14 in chord is 0.3556 m:

```text
current model provenance = ASSUMED_CONCEPT
XV-15 comparison status = NUMERIC_CONFLICT
```

#### `P.rotor.Omega = 62 rad/s`

Primary sources describe several design and flight-stage rpm values:

```text
current model provenance = ASSUMED_CONCEPT
XV-15 target evidence status = DOCUMENTED_PRIMARY
XV-15 comparison status = CONFIGURATION_DEPENDENT
```

Do not select one rpm as a universal target.

#### `P.rotor.twistTip = -6 deg`

The documented 45 deg root-to-tip description cannot be represented by the current single linear `twistTip` field without geometry and convention review:

```text
current model provenance = ASSUMED_CONCEPT
XV-15 comparison status = REPRESENTATION_INCOMPATIBLE
```

#### `P.mass.RH`

```text
current model provenance = AMBIGUOUS_COUPLED
current concept-model risk = HIGH
XV-15 reproduction blocker = HIGH
```

## 2. Separate statistics

Regenerate and machine-check these independent summaries:

- current-model provenance counts;
- XV-15 target-evidence counts;
- XV-15 comparison-status counts;
- current concept-model risk counts;
- XV-15 reproduction-blocker counts.

Do not retain a single mixed severity count that could be read as a count of production-code errors.

## 3. Correct `PARAMETER_GAP_REGISTER.md`

Preserve all existing gap IDs and technical content.

For each gap, replace the single severity with:

```text
Current concept-model risk
XV-15 reproduction blocker
```

Both use:

- `CRITICAL`
- `HIGH`
- `MEDIUM`
- `LOW`
- `INFO`
- `NONE`

Definitions:

- `Current concept-model risk`: risk to the internal physical consistency, behavior, and interpretation of the current conceptual model;
- `XV-15 reproduction blocker`: degree to which the issue blocks future XV-15-specific reproduction, validation, or comparison.

The document introduction must state clearly that a `HIGH` label does not by itself mean a confirmed production-code defect. Missing a citation alone is not enough to assign `HIGH`.

Examples:

```text
RH coupled meanings:
current concept-model risk = HIGH
XV-15 reproduction blocker = HIGH

Jpolar = 0:
current concept-model risk = MEDIUM
XV-15 reproduction blocker = MEDIUM or HIGH, based on the documented blocked scope

unsourced numerical tolerance:
current concept-model risk = LOW
XV-15 reproduction blocker = LOW or NONE

missing quantitative control mixing:
current concept-model risk = MEDIUM
XV-15 reproduction blocker = HIGH
```

## 4. Correct `PARAMETER_SOURCE_WORKPLAN.md`

Split the workplan into two independent tracks.

### Track A — current conceptual-model parameter governance

Purpose:

- clarify field semantics;
- resolve coupled meanings;
- centralize embedded constants;
- create replaceable interfaces;
- preserve current numerical behavior initially;
- maintain internal physical consistency.

Include at least:

- behavior-preserving `RH_mass` / `RH_hub` split;
- separation of endpoint inertia data from the interpolation law;
- rotor-speed provider initially returning constant `62 rad/s`;
- separation of blade geometry, mass distribution, polar, flap-axis, spring, and damping structures;
- separation of command convention, side allocation, limits, and mode scheduling;
- extraction of embedded empirical constants into named fields with unchanged initial values.

### Track B — future XV-15 target dataset

Purpose:

- build an independent XV-15 dataset;
- do not overwrite current conceptual parameters directly;
- record source, aircraft configuration, weight state, blade version, rpm mode, coordinate system, and uncertainty;
- map generic model fields to XV-15 dataset fields.

Future artifacts may include:

```text
data/xv15/
docs/XV15_PARAMETER_SOURCES.md
docs/XV15_DATA_GAPS.md
docs/XV15_MODEL_MAPPING.md
```

Do not create these artifacts in this correction task.

The phase order must be:

1. current conceptual-model semantic and interface governance;
2. behavior-preserving structural separation;
3. current-model dedicated regression;
4. independent XV-15 target-dataset construction;
5. manual source/configuration/unit/coordinate verification;
6. generic-model-to-XV-15 mapping;
7. one XV-15 parameter family integrated at a time;
8. family-specific regression;
9. representative operating-point comparison;
10. only then, explicitly limited XV-15 reproduction claims.

## 5. Preserve NASA/XV-15 findings with the correct role

Keep the existing NASA page references, weight-state distinctions, rpm schedules, twist descriptions, geometry differences, and control information.

Relabel them as applicable:

- XV-15 target candidate evidence;
- future comparison context;
- configuration-conflict evidence.

Do not use them as proof of current conceptual-value provenance.

Keep the damaged inertia-table extraction marked:

```text
requires manual visual verification
```

Do not confirm or enter inertia values in this task.

## 6. Static checks

Before closeout, verify:

- all original 174 IDs remain;
- no duplicate IDs exist;
- every entry has a current-model provenance;
- every entry has an XV-15 target-evidence status;
- every entry has both risk dimensions;
- all summary counts match the table;
- `DOCUMENTED_PRIMARY` appears only in the XV-15 target-evidence layer;
- NASA documents are not described as historical proof of current conceptual values.

Do not run MATLAB.

## 7. Closeout

Update `CODEX_TASK.md` to:

```text
STATUS: COMPLETE / CLASSIFICATION CORRECTED / HOLD
```

Record that:

- the original 174 entries were preserved;
- current-model provenance and XV-15 target evidence were separated;
- severity was split into current-model risk and XV-15 reproduction blocker;
- NASA candidate evidence was preserved without being used as current-model provenance;
- MATLAB was not run;
- production code, parameters, and tests were not modified;
- Draft PR #7 awaits human review.

Commit message:

```text
docs: separate concept provenance from XV-15 target evidence
```

Push to `audit/parameter-source-inventory`.

Final report must include:

- commit SHA;
- modified files;
- original and final entry counts;
- all five independent statistics;
- representative reclassifications;
- confirmation of zero MATLAB calls;
- confirmation of no production-code, parameter, or test changes;
- clean working-tree status.

Do not merge Draft PR #7.
