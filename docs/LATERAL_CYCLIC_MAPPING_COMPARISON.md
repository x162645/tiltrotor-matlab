# Lateral Cyclic Theta1c Mapping Comparison

## Why This Comparison Exists

The opt-in `lateralCyclic` input previously mapped directly to the rotor
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

After this comparison, the opt-in model default is:

```matlab
P.control.lateralCyclicTheta1cMapping = 'rotDir';
```

The legacy 7-input default still remains controlled by
`P.control.enableLateralCyclic = false`. The `current` and `minusRotDir`
options remain available as diagnostic mappings; they are not removed.

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

The resulting internal convention is:

```text
positive lateralCyclic -> common +eY rotor disk-normal tilt
theta1c = rotDir*lateralCyclic
```

The earlier `current` mapping is retained only for diagnostics because it
drives opposite left/right `beta1s` and `nDisk_y` responses and therefore
cancels the intended symmetric lateral cyclic effect.

## Non-goals

- No 13x10 implementation.
- No nacelle torque implementation.
- No independent left/right nacelle states.
- No Berger 51-state reproduction.
- No claim that lateral/directional handling qualities are validated.
- No Berger or XV-15 external validation.
