# Lateral Cyclic Theta1c Mapping Comparison

## Why This Comparison Exists

The opt-in `lateralCyclic` input currently maps directly to the rotor
first-harmonic cosine pitch term:

```text
theta1c = lateralCyclic
```

The derivative report showed that this path has a nonzero full B column, but
the intended lateral/directional target rows (`v`, `p`, `r` derivatives) are
nearly zero. The nonzero B column mainly appears in longitudinal and pitch
rows such as `u`, `w`, and `q`.

## Candidate Mappings

The comparison workflow evaluates:

```text
current     : theta1c = lateralCyclic
rotDir      : theta1c = rotDir*lateralCyclic
minusRotDir : theta1c = -rotDir*lateralCyclic
```

The nominal model default remains `current` through:

```matlab
P.control.lateralCyclicTheta1cMapping = 'current';
```

This branch only adds a diagnostic switch. It does not change the default
legacy behavior or declare a final production sign convention.

## Metrics

For each mapping and representative condition, the workflow reports:

- `B(vdot/pdot/rdot, lateralCyclic)`.
- The largest row in the full `B(:, lateralCyclic)` column.
- Raw central-difference `dFy`, `dMx`, and `dMz`.
- Left/right derivatives of `theta1c`, `beta1c`, `beta1s`, and `nDisk_y`.
- Whether left/right `beta1s` and `nDisk_y` have the same sign.
- `lateral_target_norm`, `longitudinal_leak_norm`, and their ratio.

## Output

The generated report and CSV are written under:

```text
validation/lateral_cyclic_mapping_comparison/<timestamp>/
```

Only the Markdown report and CSV are intended for submission. No MAT files,
plots, PDFs, or large temporary artifacts are required.

## Interpretation

If `rotDir` or `minusRotDir` aligns left/right `nDisk_y` and materially
increases lateral target response relative to `current`, that candidate should
be carried into a separate implementation branch for review.

If neither candidate wins, the next step is to audit the `psi`, flapping phase,
and `nDisk` definitions before changing the mapping.

In the current diagnostic logic, `rotDir` is preferred over `minusRotDir` when
both remove cancellation because it maps positive `lateralCyclic` to common
positive `nDisk_y` under the current sign convention. This is still an internal
model convention, not external validation.

## Non-goals

- No 13x10 implementation.
- No nacelle torque implementation.
- No independent left/right nacelle states.
- No Berger 51-state reproduction.
- No claim that lateral/directional handling qualities are validated.
- No Berger or XV-15 external validation.
