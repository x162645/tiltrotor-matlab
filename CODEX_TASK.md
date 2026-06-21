# CODEX_TASK.md

STATUS: COMPLETE / EBOOK METHOD AND TRIM PACKET BASELINE / HOLD

Branch: `planning/ebook-method-baseline-v2`

Base branch: `main`

## Purpose

Record the user-approved transition from GUI work to physics-model improvement, preserve the priority mainline, and provide the concise trim method packet that Codex will consume instead of reading the full electronic book.

The durable documents are:

```text
docs/EBOOK_MODEL_UPGRADE_PRIORITY.md
docs/ebook_packets/TRIM_METHOD_PACKET.md
```

## Decisions recorded

- Pause further GUI development.
- Keep the current project as an open-loop aircraft-plant model; no SCAS, autopilot, feedback controller, or flight-control-law design is introduced at this stage.
- Adopt the electronic book's trim organization: flight condition, trimmed degrees of freedom, available actuators, independent constraints, and explicit open-loop actuator allocation when multiple actuators serve one degree of freedom.
- ChatGPT owns full-book reading, literature extraction, method selection, page-range identification, and preparation of short method packets.
- Codex must not scan the full approximately 622-page electronic book unless a future task explicitly authorizes a small page range.
- Work that needs real aircraft-specific mass, inertia, blade, aerodynamic, mixer, RPM, wake, or power data is intentionally lower priority than behavior-preserving interfaces and parameter-free numerical improvements.

## Priority status

1. `RH_mass/RH_hub` behavior-preserving split: **COMPLETE AND MERGED** in PR #8.
2. General mode-dependent trim core: **NEXT IMPLEMENTATION TARGET; METHOD PACKET READY**.
3. Open-loop pitch-actuator allocation constraint: follows the trim core and must remain separable from flight-control-law work.
4. Trim credibility diagnostics.
5. Linearization credibility diagnostics.
6. Robust induced-velocity residual/root solution.

The remaining lower-priority work is tracked in `docs/EBOOK_MODEL_UPGRADE_PRIORITY.md`.

## Trim implementation boundary

The prepared method packet requires the next code task to:

- add a generic analysis-layer trim core;
- preserve the current `trim_symmetric` signature and legacy numerical behavior;
- define explicit helicopter and airplane endpoint actuator sets;
- refuse an underdetermined default conversion trim until a later allocation constraint is supplied;
- avoid GUI changes, control-law work, real-aircraft parameter insertion, Jacobian diagnostics, linearization changes, and induced-flow changes.

A new implementation branch and branch-specific `CODEX_TASK.md` must be created only after this documentation baseline is merged.

## Scope of this branch

Documentation only. No `.m` file, physical parameter, solver, GUI file, test, model equation, or control mapping is changed.

## Closeout

This branch is complete and must remain on HOLD until its documentation diff is reviewed. Do not add implementation work to this branch and do not merge without explicit user authorization.
