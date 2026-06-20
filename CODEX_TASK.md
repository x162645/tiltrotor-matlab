# CODEX_TASK.md

STATUS: COMPLETE / CLASSIFICATION CORRECTED / HOLD

Branch: `audit/parameter-source-inventory`

Base branch: `main`

## Current task

Read and execute:

```text
docs/PR7_CLASSIFICATION_CORRECTION.md
```

This correction preserves the completed 174-item inventory and fixes only the classification structure that currently mixes:

1. provenance of the current conceptual-model value; and
2. evidence for a future XV-15 target value or configuration.

## Mandatory boundaries

- documentation-only correction;
- no MATLAB execution;
- no trim, continuation, Jacobian, or linearization runs;
- no production-code changes;
- no parameter-value changes;
- no test changes;
- no threshold, tolerance, limit, solver, equation, or control-mapping changes;
- no new parameter/data/MATLAB/test files;
- no PR merge.

## Allowed files

Only modify:

```text
CODEX_TASK.md
docs/PR7_CLASSIFICATION_CORRECTION.md
docs/PARAMETER_SOURCE_INVENTORY.md
docs/PARAMETER_GAP_REGISTER.md
docs/PARAMETER_SOURCE_WORKPLAN.md
```

Follow the vocabularies, examples, static checks, commit message, and closeout requirements in `docs/PR7_CLASSIFICATION_CORRECTION.md` exactly.

When complete, set this file to:

```text
STATUS: COMPLETE / CLASSIFICATION CORRECTED / HOLD
```

Do not merge Draft PR #7.
