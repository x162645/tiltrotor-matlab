# CODEX_TASK.md

STATUS: COMPLETE / EBOOK METHOD PRIORITY BASELINE / HOLD

Branch: `planning/ebook-method-baseline-v2`

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

## Priority status

1. `RH_mass/RH_hub` behavior-preserving split: **COMPLETE AND MERGED** in PR #8.
2. General mode-dependent trim core: **NEXT IMPLEMENTATION TARGET**.
3. Open-loop pitch-actuator allocation constraint: follows the trim core and must remain separable from flight-control-law work.
4. Trim credibility diagnostics.
5. Linearization credibility diagnostics.
6. Robust induced-velocity residual/root solution.

The remaining lower-priority work is tracked in `docs/EBOOK_MODEL_UPGRADE_PRIORITY.md`.

## Next preparation task

Before Codex changes trim code, ChatGPT must create a concise method packet, expected at:

```text
docs/ebook_packets/TRIM_METHOD_PACKET.md
```

That packet must define:

- the exact electronic-book chapter/page scope used;
- trim unknowns and residuals for helicopter, conversion, and airplane configurations;
- the role of collective, longitudinal cyclic, and elevator;
- how unknown/constraint counts remain equal;
- angle conventions and any conversion from the book's mast angle to code `betaM`;
- current-model compatibility requirements;
- prohibited assumptions and prohibited real-aircraft parameter insertion;
- focused MATLAB acceptance tests and runtime budget.

Codex must not read the full electronic book or begin implementation until that packet and a new branch-specific task file are available.

## Scope of this branch

Documentation only. No `.m` file, physical parameter, solver, GUI file, test, model equation, or control mapping is changed.

## Closeout

This branch is complete and must remain on HOLD until its documentation diff is reviewed. Do not add implementation work to this branch and do not merge without explicit user authorization.
