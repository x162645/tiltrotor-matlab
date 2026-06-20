# CODEX_TASK.md

STATUS: COMPLETE / EBOOK METHOD PRIORITY BASELINE / HOLD

Branch: `planning/ebook-method-baseline`

Base branch: `main`

## Purpose

Record the user-approved transition from GUI work to physics-model improvement and define a token-efficient handoff from ChatGPT literature analysis to Codex implementation.

The durable priority list and electronic-book method index are in:

```text
docs/EBOOK_MODEL_UPGRADE_PRIORITY.md
```

## Decisions recorded

- Pause further GUI development.
- Keep the current project as an open-loop aircraft-plant model; no SCAS, autopilot, feedback controller, or flight-control-law design is introduced at this stage.
- Adopt the electronic book's trim organization: flight condition, trimmed degrees of freedom, available actuators, independent constraints, and explicit open-loop actuator allocation when multiple actuators serve one degree of freedom.
- ChatGPT owns full-book reading, literature extraction, method selection, page-range identification, and preparation of short method packets.
- Codex must not scan the full approximately 622-page electronic book unless a future task explicitly authorizes a small page range.
- Work that needs real aircraft-specific mass, inertia, blade, aerodynamic, mixer, RPM, wake, or power data is intentionally lower priority than behavior-preserving interfaces and parameter-free numerical improvements.

## Next implementation task

The next code task remains the already-created Draft PR #8 on branch:

```text
refactor/split-rh-mass-hub
```

Its task file already defines the behavior-preserving split of `RH_mass` and `RH_hub`. Codex should complete that task without reading the electronic book.

After PR #8 is reviewed and merged, ChatGPT will prepare a concise trim-method packet and a new branch-specific `CODEX_TASK.md` for the general mode-dependent trim core.

## Scope of this branch

Documentation only. No `.m` file, physical parameter, solver, GUI file, test, model equation, or control mapping was changed.

## Closeout

This branch is complete and must remain on HOLD until its documentation diff is reviewed. Do not add implementation work to this branch and do not merge without explicit user authorization.
